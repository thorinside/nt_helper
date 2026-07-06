import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_midi_command/flutter_midi_command.dart';
import 'package:nt_helper/domain/disting_midi_manager.dart';
import 'package:nt_helper/domain/midi_command_factory.dart';
import 'package:nt_helper/poly_multisample/poly_sample_folder_service.dart';
import 'package:nt_helper/poly_multisample/poly_sample_upload_service.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

const String debugPolySampleUploadFlag = '--debug-poly-sample-upload';

bool isDebugPolySampleUploadCommand(List<String> args) {
  return args.any(
    (arg) =>
        arg == debugPolySampleUploadFlag ||
        arg.startsWith('$debugPolySampleUploadFlag='),
  );
}

Future<int> runDebugPolySampleUploadCommand(List<String> args) async {
  if (kReleaseMode) {
    stderr.writeln(
      'Debug poly sample upload is not available in release mode.',
    );
    return 64;
  }

  final options = _DebugPolySampleUploadOptions.parse(args);
  stdout.writeln('Debug poly sample upload');
  stdout.writeln('  source: ${options.sourceFolder}');
  stdout.writeln('  target: ${options.hardwareFolder}');
  stdout.writeln(
    '  mode: ${options.validateOnly ? 'validate existing upload' : 'upload'}',
  );
  if (!options.validateOnly) {
    stdout.writeln('  verify: ${options.verifyAfterUpload ? 'yes' : 'no'}');
  } else {
    stdout.writeln(
      '  content: ${options.validateContent ? 'yes' : 'no, names and sizes'}',
    );
  }

  final sourceDir = Directory(options.sourceFolder);
  if (!await sourceDir.exists()) {
    stderr.writeln('Source folder does not exist: ${options.sourceFolder}');
    return 66;
  }

  final scan = await const PolySampleFolderService().scanLocalFolder(
    sourceDir.path,
    includeLargeFolders: true,
    useIsolate: false,
    onProgress: (progress) {
      if (progress.scannedItemCount % 25 == 0) {
        stdout.writeln(
          'Scanning: ${progress.audioFileCount} audio, '
          '${progress.ignoredFileCount} ignored...',
        );
      }
    },
  );
  final instrument = scan.instrument;
  if (instrument == null || instrument.regions.isEmpty) {
    stderr.writeln('No supported audio files found in ${sourceDir.path}.');
    return 65;
  }
  stdout.writeln(
    'Found ${instrument.regions.length} sample(s); '
    '${instrument.warningCount} mapping warning(s).',
  );

  final midi = createNativeMidiCommand();
  final devices = await _waitForMidiDevices(midi);
  if (devices.isEmpty) {
    stderr.writeln('No MIDI devices found.');
    return 69;
  }

  final prefs = await SharedPreferences.getInstance();
  final input = _selectDevice(
    devices,
    requestedName: options.inputDeviceName,
    savedName: prefs.getString('selectedInputMidiDevice'),
    requiresInput: true,
  );
  final output = _selectDevice(
    devices,
    requestedName: options.outputDeviceName,
    savedName: prefs.getString('selectedOutputMidiDevice'),
    requiresOutput: true,
  );
  final sysExId = options.sysExId ?? prefs.getInt('selectedSysExId') ?? 0;

  if (input == null || output == null) {
    stderr.writeln('Unable to select Disting NT MIDI ports.');
    stderr.writeln('Visible devices:');
    for (final device in devices) {
      stderr.writeln(
        '  ${device.name} '
        '(id=${device.id}, inputs=${device.inputPorts.length}, '
        'outputs=${device.outputPorts.length})',
      );
    }
    return 69;
  }

  stdout.writeln('Opening MIDI input: ${input.name}');
  await midi.connectToDevice(input);
  if (input.id != output.id) {
    stdout.writeln('Opening MIDI output: ${output.name}');
    await midi.connectToDevice(output);
  }

  final manager = DistingMidiManager(
    midiCommand: midi,
    inputDevice: input,
    outputDevice: output,
    sysExId: sysExId,
  );
  try {
    final version = await manager.requestVersionString();
    stdout.writeln('Connected to Disting NT firmware: ${version ?? 'unknown'}');
    final progressPrinter = _ProgressPrinter();
    if (options.validateOnly) {
      final result = await const PolySampleUploadService().validateSysEx(
        manager: manager,
        regions: instrument.regions,
        hardwareFolder: options.hardwareFolder,
        verifyContent: options.validateContent,
        onProgress: progressPrinter.write,
      );
      stdout.writeln(
        'Validation finished: ${result.filesChecked} file(s), '
        '${_formatBytes(result.bytesChecked)}, '
        '${result.failedFiles} mismatch(es).',
      );
      return result.failedFiles == 0 ? 0 : 70;
    }

    final result = await const PolySampleUploadService().uploadSysEx(
      manager: manager,
      regions: instrument.regions,
      hardwareFolder: options.hardwareFolder,
      verifyAfterUpload: options.verifyAfterUpload,
      onProgress: progressPrinter.write,
    );
    stdout.writeln(
      'Upload finished: ${result.filesUploaded} file(s), '
      '${_formatBytes(result.bytesUploaded)}, '
      '${result.correctedFiles} corrected, '
      '${result.failedVerificationFiles} verification failure(s).',
    );
    return result.failedVerificationFiles == 0 ? 0 : 70;
  } finally {
    manager.dispose();
    midi.disconnectDevice(input);
    if (input.id != output.id) {
      midi.disconnectDevice(output);
    }
  }
}

class _ProgressPrinter {
  static final _filePattern = RegExp(r'^Uploading (\d+/\d+) ');

  final Stopwatch _stopwatch = Stopwatch()..start();
  Duration _lastPrint = Duration.zero;
  String? _lastFileToken;

  void write(String message) {
    final fileToken = _filePattern.firstMatch(message)?.group(1);
    final isNewFile = fileToken != null && fileToken != _lastFileToken;
    final shouldPrint =
        _lastPrint == Duration.zero ||
        isNewFile ||
        message.contains('finishing now') ||
        _stopwatch.elapsed - _lastPrint >= const Duration(seconds: 15);

    if (!shouldPrint) return;
    _lastPrint = _stopwatch.elapsed;
    if (fileToken != null) _lastFileToken = fileToken;
    stdout.writeln(message);
  }
}

Future<List<MidiDevice>> _waitForMidiDevices(MidiCommand midi) async {
  for (var attempt = 0; attempt < 5; attempt++) {
    final devices = await midi.devices ?? const <MidiDevice>[];
    if (devices.isNotEmpty) {
      devices.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );
      return devices;
    }
    await Future<void>.delayed(const Duration(milliseconds: 250));
  }
  return const <MidiDevice>[];
}

MidiDevice? _selectDevice(
  List<MidiDevice> devices, {
  required String? requestedName,
  required String? savedName,
  bool requiresInput = false,
  bool requiresOutput = false,
}) {
  bool usable(MidiDevice device) {
    if (requiresInput && device.inputPorts.isEmpty) return false;
    if (requiresOutput && device.outputPorts.isEmpty) return false;
    return true;
  }

  MidiDevice? byName(String? name) {
    if (name == null || name.isEmpty) return null;
    for (final device in devices) {
      if (usable(device) && device.name == name) return device;
    }
    final lower = name.toLowerCase();
    for (final device in devices) {
      if (usable(device) && device.name.toLowerCase().contains(lower)) {
        return device;
      }
    }
    return null;
  }

  return byName(requestedName) ??
      byName(savedName) ??
      _firstDeviceWhere(devices, (device) {
        return usable(device) && device.name.toLowerCase().contains('disting');
      }) ??
      _firstDeviceWhere(devices, usable);
}

MidiDevice? _firstDeviceWhere(
  List<MidiDevice> devices,
  bool Function(MidiDevice device) test,
) {
  for (final device in devices) {
    if (test(device)) return device;
  }
  return null;
}

class _DebugPolySampleUploadOptions {
  const _DebugPolySampleUploadOptions({
    required this.sourceFolder,
    required this.hardwareFolder,
    required this.verifyAfterUpload,
    required this.validateOnly,
    required this.validateContent,
    this.inputDeviceName,
    this.outputDeviceName,
    this.sysExId,
  });

  final String sourceFolder;
  final String hardwareFolder;
  final bool verifyAfterUpload;
  final bool validateOnly;
  final bool validateContent;
  final String? inputDeviceName;
  final String? outputDeviceName;
  final int? sysExId;

  static _DebugPolySampleUploadOptions parse(List<String> args) {
    final values = <String, String>{};
    var sourceFolder = _defaultSourceFolder();
    var verifyAfterUpload = false;
    var validateOnly = false;
    var validateContent = false;

    for (var index = 0; index < args.length; index++) {
      final arg = args[index];
      if (arg == debugPolySampleUploadFlag) {
        if (index + 1 < args.length && !args[index + 1].startsWith('--')) {
          sourceFolder = args[++index];
        }
        continue;
      }
      if (arg.startsWith('$debugPolySampleUploadFlag=')) {
        sourceFolder = arg.substring(debugPolySampleUploadFlag.length + 1);
        continue;
      }
      if (arg == '--verify' || arg == '--verify-after-upload') {
        verifyAfterUpload = true;
        continue;
      }
      if (arg == '--validate' || arg == '--validate-only') {
        validateOnly = true;
        continue;
      }
      if (arg == '--validate-content') {
        validateOnly = true;
        validateContent = true;
        continue;
      }
      if (arg.startsWith('--')) {
        final separator = arg.indexOf('=');
        if (separator > 2) {
          values[arg.substring(2, separator)] = arg.substring(separator + 1);
        }
      }
    }

    sourceFolder = p.normalize(sourceFolder);
    final folderName = _safeHardwareFolderName(p.basename(sourceFolder));
    return _DebugPolySampleUploadOptions(
      sourceFolder: sourceFolder,
      hardwareFolder: values['hardware-folder'] ?? '/multisamples/$folderName',
      verifyAfterUpload: verifyAfterUpload,
      validateOnly: validateOnly,
      validateContent: validateContent,
      inputDeviceName: values['input'],
      outputDeviceName: values['output'],
      sysExId: int.tryParse(values['sysex-id'] ?? ''),
    );
  }
}

String _defaultSourceFolder() {
  final home = Platform.environment['HOME'];
  if (home == null || home.isEmpty) return 'EVOS';
  return p.join(home, 'Desktop', 'EVOS');
}

String _safeHardwareFolderName(String name) {
  final sanitized = name.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_').trim();
  return sanitized.isEmpty ? 'Untitled' : sanitized;
}

String _formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  final kib = bytes / 1024;
  if (kib < 1024) return '${kib.toStringAsFixed(kib < 10 ? 1 : 0)} KB';
  final mib = kib / 1024;
  return '${mib.toStringAsFixed(mib < 10 ? 1 : 0)} MB';
}
