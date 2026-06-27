import 'dart:io';

import 'package:nt_helper/domain/i_disting_midi_manager.dart';
import 'package:path/path.dart' as p;

import 'poly_multisample_models.dart';

class PolyMultisampleParser {
  static final RegExp _notePattern = RegExp(
    r'(?:^|[_\-\s])([A-Ga-g](?:#|b)?-?\d+)(?=$|[_\-\s])',
  );
  static final RegExp _switchPattern = RegExp(r'(?:^|_)SW(\d+)(?=$|_)');
  static final RegExp _velocityPattern = RegExp(r'(?:^|_)V(\d+)(?=$|_)');
  static final RegExp _roundRobinPattern = RegExp(r'(?:^|_)RR(\d+)(?=$|_)');

  static const _noteOffsets = <String, int>{
    'C': 0,
    'C#': 1,
    'DB': 1,
    'D': 2,
    'D#': 3,
    'EB': 3,
    'E': 4,
    'F': 5,
    'F#': 6,
    'GB': 6,
    'G': 7,
    'G#': 8,
    'AB': 8,
    'A': 9,
    'A#': 10,
    'BB': 10,
    'B': 11,
  };

  static const _sharpNames = [
    'C',
    'C#',
    'D',
    'D#',
    'E',
    'F',
    'F#',
    'G',
    'G#',
    'A',
    'A#',
    'B',
  ];

  static PolySampleRegion parseFile(File file, {String? basePath}) {
    final fileName = p.basename(file.path);
    final displayName = basePath == null
        ? fileName
        : p.relative(file.path, from: basePath);
    return _parseAudioPath(
      path: file.path,
      fileName: fileName,
      displayName: displayName,
    );
  }

  static PolySampleRegion parsePath(String path, {String? basePath}) {
    final normalized = path.replaceAll('\\', '/');
    final normalizedBase = basePath?.replaceAll('\\', '/');
    final fileName = p.posix.basename(normalized);
    final displayName = normalizedBase == null
        ? fileName
        : p.posix.relative(normalized, from: normalizedBase);
    return _parseAudioPath(
      path: normalized,
      fileName: fileName,
      displayName: displayName,
    );
  }

  static bool isSupportedAudioName(String fileName) {
    final extension = p.extension(fileName).toLowerCase();
    return extension == '.wav' || extension == '.aif' || extension == '.aiff';
  }

  static PolySampleRegion _parseAudioPath({
    required String path,
    required String fileName,
    required String displayName,
  }) {
    final stem = p.basenameWithoutExtension(fileName).trim();
    final issues = <PolySampleIssue>[];
    final supported = isSupportedAudioName(fileName);
    if (!supported) {
      issues.add(PolySampleIssue.unsupportedFileType);
    }

    final rootName = _findRootName(stem);
    final rootMidi = rootName == null ? null : noteNameToMidi(rootName);
    if (rootMidi == null && supported) {
      issues.add(PolySampleIssue.missingRootNote);
    }

    return PolySampleRegion(
      path: path,
      fileName: fileName,
      displayName: displayName,
      rootMidi: rootMidi,
      rootName: rootMidi == null ? null : midiToNoteName(rootMidi),
      switchPoint: _parseIntTag(_switchPattern, stem),
      velocityLayer: _parseIntTag(_velocityPattern, stem),
      roundRobin: _parseIntTag(_roundRobinPattern, stem),
      issues: issues,
    );
  }

  static String? _findRootName(String stem) {
    final normalized = stem.replaceAll(RegExp(r'\s+'), '_');
    final matches = _notePattern.allMatches(normalized).toList();
    if (matches.isEmpty) return null;
    return matches.last.group(1);
  }

  static int? _parseIntTag(RegExp pattern, String stem) {
    final normalized = stem.toUpperCase();
    final match = pattern.firstMatch(normalized);
    if (match == null) return null;
    return int.tryParse(match.group(1)!);
  }

  static int? noteNameToMidi(String? noteName) {
    if (noteName == null) return null;
    final match = RegExp(r'^([A-Ga-g])([#b]?)(-?\d+)$').firstMatch(noteName);
    if (match == null) return null;
    final note =
        '${match.group(1)!.toUpperCase()}${match.group(2)!.toUpperCase()}';
    final octave = int.tryParse(match.group(3)!);
    final offset = _noteOffsets[note];
    if (octave == null || offset == null) return null;
    return (octave + 1) * 12 + offset;
  }

  static String midiToNoteName(int midi) {
    final note = _sharpNames[midi % 12];
    final octave = midi ~/ 12 - 1;
    return '$note$octave';
  }
}

class PolyMultisampleFolderReader {
  static Future<PolySampleInstrument> readDirectory(
    String directoryPath,
  ) async {
    final dir = Directory(directoryPath);
    final regions = <PolySampleRegion>[];

    await for (final entity in dir.list(recursive: true, followLinks: false)) {
      if (entity is! File) continue;
      final name = p.basename(entity.path);
      if (name.startsWith('._') || name == '.DS_Store') continue;
      if (!PolyMultisampleParser.isSupportedAudioName(name)) continue;
      regions.add(
        PolyMultisampleParser.parseFile(entity, basePath: directoryPath),
      );
    }

    sortRegions(regions);

    return PolySampleInstrument(
      name: PolySampleInstrument.nameFromDirectory(directoryPath),
      sourcePath: directoryPath,
      regions: regions,
    );
  }

  static void sortRegions(List<PolySampleRegion> regions) {
    regions.sort((a, b) {
      final rootCompare = (a.rootMidi ?? 999).compareTo(b.rootMidi ?? 999);
      if (rootCompare != 0) return rootCompare;
      final velocityCompare = (a.velocityLayer ?? 1).compareTo(
        b.velocityLayer ?? 1,
      );
      if (velocityCompare != 0) return velocityCompare;
      final rrCompare = (a.roundRobin ?? 1).compareTo(b.roundRobin ?? 1);
      if (rrCompare != 0) return rrCompare;
      return a.displayName.compareTo(b.displayName);
    });
  }
}

class PolyMultisampleSdReader {
  static Future<List<String>> listSampleFolders(
    IDistingMidiManager manager,
  ) async {
    final listing = await manager.requestDirectoryListing('/samples');
    final folders =
        listing?.entries
            .where((entry) => entry.isDirectory)
            .map((entry) => entry.name.replaceAll(RegExp(r'/+$'), ''))
            .where((name) => name.isNotEmpty && !name.startsWith('.'))
            .toList() ??
        <String>[];
    folders.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return folders.map((name) => '/samples/$name').toList();
  }

  static Future<PolySampleInstrument> readDirectory(
    IDistingMidiManager manager,
    String directoryPath,
  ) async {
    final normalized = _normalizePath(directoryPath);
    final regions = <PolySampleRegion>[];
    await _collectAudioFiles(manager, normalized, normalized, regions);
    PolyMultisampleFolderReader.sortRegions(regions);
    return PolySampleInstrument(
      name: PolySampleInstrument.nameFromDirectory(normalized),
      sourcePath: '$normalized (Disting NT)',
      regions: regions,
    );
  }

  static Future<void> _collectAudioFiles(
    IDistingMidiManager manager,
    String path,
    String basePath,
    List<PolySampleRegion> regions,
  ) async {
    final listing = await manager.requestDirectoryListing(path);
    for (final entry in listing?.entries ?? const []) {
      final name = entry.name.replaceAll(RegExp(r'/+$'), '');
      if (name.isEmpty || name.startsWith('._') || name == '.DS_Store') {
        continue;
      }
      final childPath = '$path/$name';
      if (entry.isDirectory) {
        await _collectAudioFiles(manager, childPath, basePath, regions);
        continue;
      }
      if (!PolyMultisampleParser.isSupportedAudioName(name)) continue;
      regions.add(
        PolyMultisampleParser.parsePath(childPath, basePath: basePath),
      );
    }
  }

  static String _normalizePath(String path) {
    final normalized = path
        .replaceAll('\\', '/')
        .replaceAll(RegExp(r'/+$'), '');
    return normalized.startsWith('/') ? normalized : '/$normalized';
  }
}
