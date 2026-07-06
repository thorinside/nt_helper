import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;

import 'package:nt_helper/domain/i_disting_midi_manager.dart';
import 'package:nt_helper/models/sd_card_file_system.dart';

import 'poly_multisample_models.dart';
import 'poly_multisample_parser.dart';
import 'poly_sample_apply_service.dart';

typedef PolySampleAdditionBytesReader =
    Future<Uint8List> Function(PolySampleFileAddition addition);

const int _sysExUploadChunkSize = 512;

class PolySampleHardwareException implements Exception {
  const PolySampleHardwareException(this.message);

  final String message;

  @override
  String toString() => message;
}

class PolySampleHardwareService {
  const PolySampleHardwareService();

  Future<List<String>> listSampleFolders(IDistingMidiManager manager) async {
    final listing = await manager.requestDirectoryListing('/samples');
    final folders =
        listing?.entries
            .where((entry) => entry.isDirectory)
            .map((entry) => _entryName(entry))
            .where((name) => name.isNotEmpty && !name.startsWith('.'))
            .map((name) => p.posix.join('/samples', name))
            .toList() ??
        <String>[];
    folders.sort();
    return folders;
  }

  Future<PolySampleInstrument> readSampleFolder(
    IDistingMidiManager manager,
    String folderPath,
  ) async {
    final regions = <PolySampleRegion>[];
    await _readFolderRecursive(manager, folderPath, folderPath, regions);
    PolyMultisampleParser.sortRegions(regions);
    return PolySampleInstrument(
      name: p.posix.basename(folderPath),
      sourcePath: folderPath,
      regions: regions,
    );
  }

  Future<Uint8List?> downloadSampleBytes(
    IDistingMidiManager manager,
    String path,
  ) async {
    final parent = p.posix.dirname(path);
    final name = p.posix.basename(path);
    final listing = await manager.requestDirectoryListing(parent);
    if (listing == null) return null;
    DirectoryEntry? entry;
    for (final candidate in listing.entries) {
      if (!candidate.isDirectory && _entryName(candidate) == name) {
        entry = candidate;
        break;
      }
    }
    if (entry == null) return null;

    final buffer = BytesBuilder(copy: false);
    for (var position = 0; position < entry.size;) {
      final nextPosition = position + _sysExUploadChunkSize < entry.size
          ? position + _sysExUploadChunkSize
          : entry.size;
      final count = nextPosition - position;
      final chunk = await manager.requestFileDownloadChunk(
        path,
        position,
        count,
      );
      if (chunk == null || chunk.length != count) return null;
      buffer.add(chunk);
      position = nextPosition;
    }
    if (entry.size == 0) {
      final chunk = await manager.requestFileDownloadChunk(path, 0, 0);
      if (chunk == null || chunk.isNotEmpty) return null;
    }
    return buffer.toBytes();
  }

  PolySampleApplyPlan buildHardwarePlan({
    required List<PolySampleRegion> baselineRegions,
    required List<PolySampleRegion> editedRegions,
    required String targetFolder,
    Set<String> existingPaths = const {},
  }) {
    return const PolySampleApplyService().buildPlan(
      baselineRegions: baselineRegions,
      editedRegions: editedRegions,
      targetFolder: targetFolder,
      existingPaths: existingPaths,
      pathContext: p.posix,
    );
  }

  Future<void> applyPlan(
    IDistingMidiManager manager,
    PolySampleApplyPlan plan, {
    PolySampleAdditionBytesReader? readAdditionBytes,
  }) async {
    if (plan.hasConflicts) {
      throw const PolySampleHardwareException(
        'Cannot apply a hardware plan with conflicts.',
      );
    }

    for (final removal in plan.removals) {
      await _requireSuccess(
        manager.requestFileDelete(removal.path),
        'delete ${removal.path}',
      );
    }

    final stagedRenames = <({String tempPath, PolySampleFileRename rename})>[];
    for (final rename in plan.renames) {
      final tempPath = _hardwareTempPath(rename.fromPath);
      await _ensureHardwareParent(manager, tempPath);
      await _requireSuccess(
        manager.requestFileRename(rename.fromPath, tempPath),
        'rename ${rename.fromPath}',
      );
      stagedRenames.add((tempPath: tempPath, rename: rename));
    }

    for (final staged in stagedRenames) {
      await _ensureHardwareParent(manager, staged.rename.toPath);
      await _requireSuccess(
        manager.requestFileRename(staged.tempPath, staged.rename.toPath),
        'rename ${staged.rename.toPath}',
      );
    }

    for (final addition in plan.additions) {
      await _ensureHardwareParent(manager, addition.toPath);
      final bytes = readAdditionBytes == null
          ? await File(addition.sourcePath).readAsBytes()
          : await readAdditionBytes(addition);
      await _uploadHardwareFile(manager, addition.toPath, bytes);
    }
  }

  Future<void> _uploadHardwareFile(
    IDistingMidiManager manager,
    String path,
    Uint8List bytes,
  ) async {
    if (bytes.isEmpty) {
      await _requireSuccess(
        manager.requestFileUploadChunk(
          path,
          Uint8List(0),
          0,
          createAlways: true,
        ),
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

  Future<void> _readFolderRecursive(
    IDistingMidiManager manager,
    String rootPath,
    String currentPath,
    List<PolySampleRegion> regions,
  ) async {
    final listing = await manager.requestDirectoryListing(currentPath);
    if (listing == null) return;

    for (final entry in listing.entries) {
      final name = _entryName(entry);
      if (name.isEmpty || name.startsWith('.')) continue;
      final childPath = p.posix.join(currentPath, name);
      if (entry.isDirectory) {
        await _readFolderRecursive(manager, rootPath, childPath, regions);
        continue;
      }
      if (_shouldIgnoreFileName(name)) continue;
      if (!PolyMultisampleParser.isSupportedAudioName(name)) continue;
      regions.add(
        PolyMultisampleParser.parsePath(childPath, basePath: rootPath),
      );
    }
  }
}

String _entryName(DirectoryEntry entry) {
  return entry.name.replaceAll(RegExp(r'/+$'), '');
}

bool _shouldIgnoreFileName(String name) {
  return name == '.DS_Store' ||
      name.startsWith('._') ||
      name.endsWith('.asd') ||
      name.endsWith('.reapeaks');
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
    if (current == '/samples') continue;
    final status = await manager.requestDirectoryCreate(current);
    if (status != null && !status.success) {
      throw PolySampleHardwareException(
        'Could not create $current: ${status.message}',
      );
    }
  }
}

Future<void> _requireSuccess(
  Future<SdCardStatus?> future,
  String operation,
) async {
  final status = await future;
  if (status == null || !status.success) {
    throw PolySampleHardwareException(
      'Hardware $operation failed: ${status?.message ?? 'no response'}',
    );
  }
}

String _hardwareTempPath(String sourcePath) {
  final directory = p.posix.dirname(sourcePath);
  final basename = p.posix.basename(sourcePath);
  final suffix = DateTime.now().microsecondsSinceEpoch;
  return p.posix.join(directory, '.$basename.poly-tmp-$suffix');
}
