import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;

import 'package:nt_helper/domain/i_disting_midi_manager.dart';
import 'package:nt_helper/models/sd_card_file_system.dart';
import 'package:nt_helper/poly_multisample/poly_multisample_models.dart';
import 'package:nt_helper/poly_multisample/poly_sample_apply_service.dart';

typedef PolySampleUploadProgress = void Function(String message);

class PolySampleUploadException implements Exception {
  const PolySampleUploadException(this.message);

  final String message;

  @override
  String toString() => message;
}

class PolySampleUploadFile {
  const PolySampleUploadFile({
    required this.sourcePath,
    required this.targetPath,
    required this.displayName,
  });

  final String sourcePath;
  final String targetPath;
  final String displayName;
}

class PolySampleUploadResult {
  const PolySampleUploadResult({
    required this.filesUploaded,
    required this.bytesUploaded,
    required this.correctedFiles,
  });

  final int filesUploaded;
  final int bytesUploaded;
  final int correctedFiles;
}

const int _sysExUploadChunkSize = 512;

class PolySampleUploadService {
  const PolySampleUploadService({
    PolySampleApplyService applyService = const PolySampleApplyService(),
  }) : _applyService = applyService;

  final PolySampleApplyService _applyService;

  List<PolySampleUploadFile> buildUploadFiles({
    required List<PolySampleRegion> regions,
    required String targetFolder,
    p.Context? pathContext,
  }) {
    final paths = pathContext ?? p.context;
    final includeVelocity = regions.any(
      (region) => (region.velocityLayer ?? 1) > 1,
    );
    final includeRoundRobin = regions.any(
      (region) => (region.roundRobin ?? 1) > 1,
    );
    final files = <PolySampleUploadFile>[];
    final targets = <String>{};

    for (final region in regions) {
      final fileName = _applyService.buildTargetFileName(
        region,
        includeVelocity: includeVelocity,
        includeRoundRobin: includeRoundRobin,
        pathContext: paths,
      );
      final targetPath = paths.normalize(paths.join(targetFolder, fileName));
      if (!targets.add(targetPath)) {
        throw PolySampleUploadException(
          'Multiple samples target ${paths.basename(targetPath)}.',
        );
      }
      files.add(
        PolySampleUploadFile(
          sourcePath: region.path,
          targetPath: targetPath,
          displayName: region.displayName,
        ),
      );
    }

    return files;
  }

  Future<PolySampleUploadResult> uploadMountedSd({
    required List<PolySampleRegion> regions,
    required String destinationFolder,
    PolySampleUploadProgress? onProgress,
  }) async {
    final files = buildUploadFiles(
      regions: regions,
      targetFolder: destinationFolder,
    );
    var filesUploaded = 0;
    var bytesUploaded = 0;

    for (final file in files) {
      onProgress?.call('Uploading ${file.displayName}...');
      final source = File(file.sourcePath);
      final targetPath = p.normalize(file.targetPath);
      final sourcePath = p.normalize(source.path);
      final sourceLength = await source.length();
      if (sourcePath == targetPath) {
        filesUploaded++;
        bytesUploaded += sourceLength;
        continue;
      }

      final target = File(targetPath);
      final parent = Directory(p.dirname(targetPath));
      await parent.create(recursive: true);
      final tempPath = _uniqueTempPath(targetPath);
      final temp = File(tempPath);
      try {
        await source.copy(tempPath);
        if (await target.exists()) {
          await target.delete();
        }
        await temp.rename(targetPath);
      } catch (_) {
        try {
          if (await temp.exists()) {
            await temp.delete();
          }
        } on FileSystemException {
          // Best-effort cleanup only.
        }
        rethrow;
      }
      filesUploaded++;
      bytesUploaded += sourceLength;
    }

    return PolySampleUploadResult(
      filesUploaded: filesUploaded,
      bytesUploaded: bytesUploaded,
      correctedFiles: 0,
    );
  }

  Future<PolySampleUploadResult> uploadSysEx({
    required IDistingMidiManager manager,
    required List<PolySampleRegion> regions,
    required String hardwareFolder,
    PolySampleUploadProgress? onProgress,
  }) async {
    final files = buildUploadFiles(
      regions: regions,
      targetFolder: hardwareFolder,
      pathContext: p.posix,
    );
    var filesUploaded = 0;
    var bytesUploaded = 0;
    var correctedFiles = 0;

    for (final file in files) {
      onProgress?.call('Uploading ${file.displayName}...');
      await _ensureHardwareParent(manager, file.targetPath);
      final bytes = await File(file.sourcePath).readAsBytes();
      await _uploadHardwareFile(manager, file.targetPath, bytes);
      filesUploaded++;
      bytesUploaded += bytes.length;

      final firstDownload = await manager.requestFileDownload(file.targetPath);
      if (_bytesEqual(firstDownload, bytes)) continue;

      await _uploadHardwareFile(manager, file.targetPath, bytes);
      correctedFiles++;
      final secondDownload = await manager.requestFileDownload(file.targetPath);
      if (!_bytesEqual(secondDownload, bytes)) {
        throw PolySampleUploadException(
          'Verification failed for ${file.targetPath}.',
        );
      }
    }

    return PolySampleUploadResult(
      filesUploaded: filesUploaded,
      bytesUploaded: bytesUploaded,
      correctedFiles: correctedFiles,
    );
  }
}

Future<void> _uploadHardwareFile(
  IDistingMidiManager manager,
  String path,
  Uint8List bytes,
) async {
  if (bytes.isEmpty) {
    await _requireSuccess(
      manager.requestFileUploadChunk(path, Uint8List(0), 0, createAlways: true),
      'upload chunk at 0 for $path',
    );
    return;
  }

  for (var position = 0; position < bytes.length;) {
    final nextPosition = position + _sysExUploadChunkSize < bytes.length
        ? position + _sysExUploadChunkSize
        : bytes.length;
    final chunk = bytes.sublist(position, nextPosition);
    await _requireSuccess(
      manager.requestFileUploadChunk(
        path,
        chunk,
        position,
        createAlways: position == 0,
      ),
      'upload chunk at $position for $path',
    );
    position = nextPosition;
  }
}

Future<void> _ensureHardwareParent(
  IDistingMidiManager manager,
  String path,
) async {
  final parent = p.posix.dirname(path);
  if (parent == '.' || parent == '/' || parent.isEmpty) return;
  final segments = parent.split('/').where((segment) => segment.isNotEmpty);
  var current = '';
  for (final segment in segments) {
    current = current.isEmpty ? '/$segment' : p.posix.join(current, segment);
    if (_knownHardwareRoots.contains(current)) continue;
    await _requireSuccess(
      manager.requestDirectoryCreate(current),
      'mkdir $current',
    );
  }
}

const _knownHardwareRoots = {'/samples', '/multisamples'};

Future<void> _requireSuccess(
  Future<SdCardStatus?> future,
  String operation,
) async {
  final status = await future;
  if (status == null || !status.success) {
    throw PolySampleUploadException(
      'Hardware $operation failed: ${status?.message ?? 'no response'}',
    );
  }
}

bool _bytesEqual(Uint8List? actual, Uint8List expected) {
  if (actual == null) return false;
  if (actual.length != expected.length) return false;
  for (var index = 0; index < expected.length; index++) {
    if (actual[index] != expected[index]) return false;
  }
  return true;
}

String _uniqueTempPath(String targetPath) {
  final directory = p.dirname(targetPath);
  final basename = p.basename(targetPath);
  for (var attempt = 0; attempt < 1000; attempt++) {
    final suffix = DateTime.now().microsecondsSinceEpoch + attempt;
    final candidate = p.join(directory, '.$basename.poly-upload-tmp-$suffix');
    if (!File(candidate).existsSync()) return candidate;
  }
  final fallback = DateTime.now().millisecondsSinceEpoch;
  return p.join(directory, '.$basename.poly-upload-tmp-$fallback');
}
