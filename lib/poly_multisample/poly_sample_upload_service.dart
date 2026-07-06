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
    this.failedVerificationFiles = 0,
  });

  final int filesUploaded;
  final int bytesUploaded;
  final int correctedFiles;
  final int failedVerificationFiles;
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
    bool verifyAfterUpload = false,
    PolySampleUploadProgress? onProgress,
  }) async {
    final files = buildUploadFiles(
      regions: regions,
      targetFolder: hardwareFolder,
      pathContext: p.posix,
    );
    var filesUploaded = 0;
    var bytesUploaded = 0;
    final uploadedFiles = <_UploadedHardwareFile>[];
    var totalBytes = 0;
    for (final file in files) {
      totalBytes += await File(file.sourcePath).length();
    }
    final progress = _TransferProgress(
      totalBytes: totalBytes * (verifyAfterUpload ? 2 : 1),
      onProgress: onProgress,
    );

    for (var index = 0; index < files.length; index++) {
      final file = files[index];
      onProgress?.call(
        'Uploading ${index + 1}/${files.length} ${file.displayName}...',
      );
      await _ensureHardwareParent(manager, file.targetPath);
      final bytes = await File(file.sourcePath).readAsBytes();
      await _uploadHardwareFile(
        manager,
        file.targetPath,
        bytes,
        onChunkTransferred: (byteCount) {
          progress.advance(
            bytes: byteCount,
            action: 'Uploading',
            displayName: file.displayName,
            fileIndex: index + 1,
            fileCount: files.length,
          );
        },
      );
      filesUploaded++;
      bytesUploaded += bytes.length;
      uploadedFiles.add(
        _UploadedHardwareFile(file: file, byteLength: bytes.length),
      );
    }

    final verification = verifyAfterUpload
        ? await _verifyHardwareFiles(manager, uploadedFiles, progress)
        : const _HardwareVerificationResult(correctedFiles: 0, failedFiles: 0);

    return PolySampleUploadResult(
      filesUploaded: filesUploaded,
      bytesUploaded: bytesUploaded,
      correctedFiles: verification.correctedFiles,
      failedVerificationFiles: verification.failedFiles,
    );
  }
}

class _UploadedHardwareFile {
  const _UploadedHardwareFile({required this.file, required this.byteLength});

  final PolySampleUploadFile file;
  final int byteLength;
}

class _TransferProgress {
  _TransferProgress({required this.totalBytes, required this.onProgress})
    : _stopwatch = Stopwatch()..start();

  int totalBytes;
  int completedBytes = 0;
  final PolySampleUploadProgress? onProgress;
  final Stopwatch _stopwatch;
  Duration _lastProgressEmit = Duration.zero;

  void addWork(int bytes) {
    totalBytes += bytes;
  }

  void advance({
    required int bytes,
    required String action,
    required String displayName,
    required int fileIndex,
    required int fileCount,
  }) {
    completedBytes += bytes;
    final elapsed = _stopwatch.elapsed;
    final shouldEmit =
        onProgress != null &&
        (completedBytes >= totalBytes ||
            _lastProgressEmit == Duration.zero ||
            elapsed - _lastProgressEmit >= const Duration(seconds: 1));
    if (!shouldEmit) return;
    _lastProgressEmit = elapsed;
    onProgress?.call(
      '$action $fileIndex/$fileCount $displayName '
      '(${_formatBytes(completedBytes)} of ${_formatBytes(totalBytes)}, '
      '${_percent()}, ${_etaText()})',
    );
  }

  String _percent() {
    if (totalBytes <= 0) return '100%';
    final percent = (completedBytes / totalBytes * 100).clamp(0, 100);
    return '${percent.toStringAsFixed(percent < 10 ? 1 : 0)}%';
  }

  String _etaText() {
    if (completedBytes <= 0) return 'estimating time remaining';
    final elapsed = _stopwatch.elapsed;
    if (elapsed.inMilliseconds <= 0) return 'estimating time remaining';
    final bytesPerMs = completedBytes / elapsed.inMilliseconds;
    if (bytesPerMs <= 0) return 'estimating time remaining';
    final remainingBytes = totalBytes - completedBytes;
    if (remainingBytes <= 0) return 'finishing now';
    final remaining = Duration(
      milliseconds: (remainingBytes / bytesPerMs).round(),
    );
    return 'about ${_formatDuration(remaining)} remaining';
  }
}

class _HardwareVerificationResult {
  const _HardwareVerificationResult({
    required this.correctedFiles,
    required this.failedFiles,
  });

  final int correctedFiles;
  final int failedFiles;
}

Future<_HardwareVerificationResult> _verifyHardwareFiles(
  IDistingMidiManager manager,
  List<_UploadedHardwareFile> files,
  _TransferProgress progress,
) async {
  if (files.isEmpty) {
    return const _HardwareVerificationResult(correctedFiles: 0, failedFiles: 0);
  }

  progress.onProgress?.call('Verifying uploaded samples...');
  final mismatches = await _findMismatches(manager, files, progress);
  if (mismatches.isEmpty) {
    return const _HardwareVerificationResult(correctedFiles: 0, failedFiles: 0);
  }

  var correctedFiles = 0;
  for (var index = 0; index < mismatches.length; index++) {
    final mismatch = mismatches[index];
    progress.addWork(mismatch.byteLength * 2);
    progress.onProgress?.call('Correcting ${mismatch.file.displayName}...');
    final bytes = await File(mismatch.file.sourcePath).readAsBytes();
    await _uploadHardwareFile(
      manager,
      mismatch.file.targetPath,
      bytes,
      onChunkTransferred: (byteCount) {
        progress.advance(
          bytes: byteCount,
          action: 'Correcting',
          displayName: mismatch.file.displayName,
          fileIndex: index + 1,
          fileCount: mismatches.length,
        );
      },
    );
    correctedFiles++;
  }

  progress.onProgress?.call('Verifying corrections...');
  final failedFiles = await _findMismatches(manager, mismatches, progress);
  return _HardwareVerificationResult(
    correctedFiles: correctedFiles,
    failedFiles: failedFiles.length,
  );
}

Future<List<_UploadedHardwareFile>> _findMismatches(
  IDistingMidiManager manager,
  List<_UploadedHardwareFile> files,
  _TransferProgress progress,
) async {
  final mismatches = <_UploadedHardwareFile>[];
  for (var index = 0; index < files.length; index++) {
    final file = files[index];
    final fileIndex = index + 1;
    if (!await _downloadMatchesSource(
      manager,
      file,
      progress,
      fileIndex,
      files.length,
    )) {
      mismatches.add(file);
    }
  }
  return mismatches;
}

Future<bool> _downloadMatchesSource(
  IDistingMidiManager manager,
  _UploadedHardwareFile file,
  _TransferProgress progress,
  int fileIndex,
  int fileCount,
) async {
  final source = await File(file.file.sourcePath).readAsBytes();
  for (var position = 0; position < source.length;) {
    final nextPosition = position + _sysExUploadChunkSize < source.length
        ? position + _sysExUploadChunkSize
        : source.length;
    final expected = source.sublist(position, nextPosition);
    final actual = await manager.requestFileDownloadChunk(
      file.file.targetPath,
      position,
      expected.length,
    );
    if (!_bytesEqual(actual, expected)) return false;
    progress.advance(
      bytes: expected.length,
      action: 'Verifying',
      displayName: file.file.displayName,
      fileIndex: fileIndex,
      fileCount: fileCount,
    );
    position = nextPosition;
  }
  if (source.isNotEmpty) return true;
  final actual = await manager.requestFileDownloadChunk(
    file.file.targetPath,
    0,
    0,
  );
  return _bytesEqual(actual, source);
}

Future<void> _uploadHardwareFile(
  IDistingMidiManager manager,
  String path,
  Uint8List bytes, {
  void Function(int byteCount)? onChunkTransferred,
}) async {
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
    onChunkTransferred?.call(chunk.length);
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
    final status = await manager.requestDirectoryCreate(current);
    if (status != null && status.success) continue;
    if (await _hardwareDirectoryExists(manager, current)) continue;
    throw PolySampleUploadException(
      'Hardware mkdir $current failed: ${status?.message ?? 'no response'}',
    );
  }
}

const _knownHardwareRoots = {'/samples', '/multisamples'};

Future<bool> _hardwareDirectoryExists(
  IDistingMidiManager manager,
  String path,
) async {
  final parent = p.posix.dirname(path);
  final name = p.posix.basename(path);
  final listing = await manager.requestDirectoryListing(parent);
  if (listing == null) return false;
  for (final entry in listing.entries) {
    if (!entry.isDirectory) continue;
    final entryName = entry.name.replaceAll(RegExp(r'/+$'), '');
    if (entryName == name) return true;
  }
  return false;
}

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

String _formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  final kib = bytes / 1024;
  if (kib < 1024) return '${kib.toStringAsFixed(kib < 10 ? 1 : 0)} KB';
  final mib = kib / 1024;
  return '${mib.toStringAsFixed(mib < 10 ? 1 : 0)} MB';
}

String _formatDuration(Duration duration) {
  final seconds = duration.inSeconds;
  if (seconds < 60) return '${seconds}s';
  final minutes = duration.inMinutes;
  final remainingSeconds = seconds % 60;
  if (minutes < 60) return '${minutes}m ${remainingSeconds}s';
  final hours = duration.inHours;
  final remainingMinutes = minutes % 60;
  return '${hours}h ${remainingMinutes}m';
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
