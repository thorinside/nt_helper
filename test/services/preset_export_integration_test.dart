// End-to-end integration test for preset export.
//
// Drives a real [PresetAnalyzer] + [FileCollector] + [PackageCreator]
// against a fake [PresetFileSystem] backed by an in-memory map. Verifies
// that, given a preset JSON whose dependencies all exist on the (fake)
// SD card, the resulting `.zip` contains every referenced sample,
// wavetable, Lua script, FM bank, and so on at the canonical SD path.
//
// This is the regression guard against silently producing JSON-only
// packages: if any dependency type stops being collected, the unzip
// path-set check below fails.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/interfaces/preset_file_system.dart';
import 'package:nt_helper/models/package_config.dart';
import 'package:nt_helper/services/package_creator.dart';

/// In-memory fake of [PresetFileSystem] driven by a map of relative path
/// to bytes. Directory listings are derived from the map's keyspace.
class _FakeFileSystem implements PresetFileSystem {
  final Map<String, Uint8List> store;

  _FakeFileSystem(this.store);

  @override
  Future<Uint8List?> readFile(String relativePath) async {
    return store[relativePath];
  }

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
}

void main() {
  test('SyncLatchDemo round-trip captures lua + samp triggers + pyms folder',
      () async {
    final presetJson = File('test/fixtures/presets/sync_latch_demo.json')
        .readAsStringSync();
    final presetBytes = Uint8List.fromList(utf8.encode(presetJson));

    // Lay out the fake SD card with every file the preset references.
    final lua = Uint8List.fromList(utf8.encode('-- lua content'));
    final wav = Uint8List.fromList([0x52, 0x49, 0x46, 0x46]); // "RIFF"
    final aif = Uint8List.fromList([0x46, 0x4F, 0x52, 0x4D]); // "FORM"

    final fs = _FakeFileSystem({
      'presets/SyncLatchDemo.json': presetBytes,
      'programs/lua/sync_latch.lua': lua,
      // samp triggers
      'samples/Cheetah_MD16/MD16_BD_Gated_1.wav': wav,
      'samples/DMX606_SamplePack/DMX606_SD1_A.wav': wav,
      'samples/DMX606_SamplePack/DMX606_HHclosed_A.wav': wav,
      'samples/!LABS Soft Pno - PedOn/PedOn_A#-1.wav': wav,
      // pyms multisample folder content (recursively listed)
      'multisamples/LABS Soft Pno - PedOn/A1.aif': aif,
      'multisamples/LABS Soft Pno - PedOn/C2.aif': aif,
    });

    final creator = PackageCreator(fs);
    final result = await creator.createPackage(
      presetFilePath: 'presets/SyncLatchDemo.json',
      config: const PackageConfig(),
    );

    // Decode the zip and check the file list.
    final archive = ZipDecoder().decodeBytes(result.zipBytes);
    final names = archive.files.map((f) => f.name).toSet();

    expect(names, contains('root/presets/SyncLatchDemo.json'));
    expect(names, contains('root/programs/lua/sync_latch.lua'));
    expect(
      names,
      contains('root/samples/Cheetah_MD16/MD16_BD_Gated_1.wav'),
    );
    expect(
      names,
      contains('root/samples/DMX606_SamplePack/DMX606_SD1_A.wav'),
    );
    expect(
      names,
      contains('root/samples/!LABS Soft Pno - PedOn/PedOn_A#-1.wav'),
    );
    expect(
      names,
      contains('root/multisamples/LABS Soft Pno - PedOn/A1.aif'),
    );
    expect(names, contains('manifest.json'));

    // Manifest should report the lua and trigger samples in the
    // included-files list (proving they were actually packaged).
    final manifestEntry = archive.files.firstWhere(
      (f) => f.name == 'manifest.json',
    );
    final manifest = jsonDecode(
      utf8.decode(manifestEntry.content as List<int>),
    ) as Map<String, dynamic>;
    final included = (manifest['package']['includedFiles'] as List).cast<String>();
    expect(included, contains('programs/lua/sync_latch.lua'));
    expect(included, contains('samples/Cheetah_MD16/MD16_BD_Gated_1.wav'));

    // No warnings since every referenced file exists in the fake FS.
    expect(result.warnings, isEmpty);
  });

  test('missing dependencies produce warnings but still write a zip', () async {
    // Same preset, but the SD card is empty except for the preset itself.
    final presetJson = File('test/fixtures/presets/sync_latch_demo.json')
        .readAsStringSync();
    final presetBytes = Uint8List.fromList(utf8.encode(presetJson));

    final fs = _FakeFileSystem({
      'presets/SyncLatchDemo.json': presetBytes,
    });

    final creator = PackageCreator(fs);
    final result = await creator.createPackage(
      presetFilePath: 'presets/SyncLatchDemo.json',
      config: const PackageConfig(),
    );

    expect(result.zipBytes, isNotEmpty);
    expect(result.hasWarnings, isTrue);

    // Warnings should mention the missing Lua script and at least one
    // missing sample so the user sees what's incomplete.
    expect(
      result.warnings.any((w) => w.contains('sync_latch.lua')),
      isTrue,
    );
    expect(
      result.warnings.any((w) => w.contains('MD16_BD_Gated_1.wav')),
      isTrue,
    );
  });
}
