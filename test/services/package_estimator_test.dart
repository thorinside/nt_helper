import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/interfaces/preset_file_system.dart';
import 'package:nt_helper/models/preset_dependencies.dart';
import 'package:nt_helper/services/package_estimator.dart';

class _FakeFs implements PresetFileSystem {
  final Map<String, Uint8List> store;
  _FakeFs(this.store);

  @override
  Future<Uint8List?> readFile(String relativePath) async => store[relativePath];

  @override
  Future<List<String>> listFiles(
    String directoryPath, {
    bool recursive = false,
  }) async {
    final prefix = directoryPath.endsWith('/')
        ? directoryPath
        : '$directoryPath/';
    return store.keys.where((k) => k.startsWith(prefix)).toList();
  }

  @override
  Future<List<FileEntryInfo>> listEntries(
    String directoryPath, {
    bool recursive = false,
  }) async {
    final paths = await listFiles(directoryPath, recursive: recursive);
    return [
      for (final p in paths)
        FileEntryInfo(path: p, size: store[p]?.length ?? 0),
    ];
  }

  @override
  Future<int?> getFileSize(String relativePath) async =>
      store[relativePath]?.length;
}

void main() {
  test('estimate sums folder bytes and counts files', () async {
    final fs = _FakeFs({
      'samples/Kit/a.wav': Uint8List(100),
      'samples/Kit/b.wav': Uint8List(250),
      'samples/Kit/c.wav': Uint8List(50),
    });

    final deps = PresetDependencies();
    deps.sampleFolders.add('Kit');

    final est = await PackageEstimator(fs).estimate(deps);

    expect(est.totalBytes, 400);
    expect(est.fileCount, 3);
    expect(est.folders, hasLength(1));
    expect(est.warnings, isEmpty);
  });

  test('estimate handles missing folder by warning, not throwing', () async {
    final fs = _FakeFs({});

    final deps = PresetDependencies();
    deps.sampleFolders.add('NoSuchKit');

    final est = await PackageEstimator(fs).estimate(deps);

    expect(est.totalBytes, 0);
    expect(est.warnings, isNotEmpty);
    expect(est.isComplete, isFalse);
  });

  test('estimate sizes single files via getFileSize', () async {
    final fs = _FakeFs({
      'programs/lua/myscript.lua': Uint8List(123),
    });

    final deps = PresetDependencies();
    deps.luaScripts.add('myscript.lua');

    final est = await PackageEstimator(fs).estimate(deps);

    expect(est.totalBytes, 123);
    expect(est.fileCount, 1);
  });

  test('estimate filters MIDI tree by extension', () async {
    final fs = _FakeFs({
      'MIDI/Demo/song.mid': Uint8List(500),
      'MIDI/Demo/notes.txt': Uint8List(99), // should be excluded
    });

    final deps = PresetDependencies();
    deps.bundleMidiTree = true;

    final est = await PackageEstimator(fs).estimate(deps);

    expect(est.totalBytes, 500);
    expect(est.fileCount, 1);
  });
}
