import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nt_helper/db/database.dart';
import 'package:nt_helper/db/daos/metadata_dao.dart';
import 'package:nt_helper/interfaces/preset_file_system.dart';
import 'package:nt_helper/models/package_config.dart';
import 'package:nt_helper/models/preset_dependencies.dart';
import 'package:nt_helper/services/file_collector.dart';

class MockPresetFileSystem extends Mock implements PresetFileSystem {}

class MockAppDatabase extends Mock implements AppDatabase {}

class MockMetadataDao extends Mock implements MetadataDao {}

void main() {
  late MockPresetFileSystem mockFileSystem;
  late MockAppDatabase mockDatabase;
  late MockMetadataDao mockMetadataDao;
  late FileCollector fileCollector;

  setUp(() {
    mockFileSystem = MockPresetFileSystem();
    mockDatabase = MockAppDatabase();
    mockMetadataDao = MockMetadataDao();

    when(() => mockDatabase.metadataDao).thenReturn(mockMetadataDao);

    fileCollector = FileCollector(mockFileSystem, mockDatabase);
  });

  group('FileCollector - pluginPaths', () {
    test('uses pluginPaths for direct SD card reads when provided', () async {
      // Arrange
      final deps = PresetDependencies();
      deps.pluginPaths['MYPLUGIN'] = 'programs/plug-ins/MyPlugin.elf';

      final pluginBytes = Uint8List.fromList([0x7F, 0x45, 0x4C, 0x46]); // ELF
      when(
        () => mockFileSystem.readFile('programs/plug-ins/MyPlugin.elf'),
      ).thenAnswer((_) async => pluginBytes);

      final config = const PackageConfig(includeCommunityPlugins: true);

      // Act
      final result = await fileCollector.collectDependencies(
        deps,
        config: config,
      );

      // Assert
      expect(result.files.length, 1);
      expect(result.files.first.relativePath, 'programs/plug-ins/MyPlugin.elf');
      expect(result.files.first.bytes, pluginBytes);

      // Should NOT call database lookup since we have direct paths
      verifyNever(
        () => mockMetadataDao.getPluginFilePathsByGuids(any()),
      );
    });

    test('falls back to database for plugins not in pluginPaths', () async {
      // Arrange
      final deps = PresetDependencies();
      deps.communityPlugins.add('OTHERPLUGIN');
      // Note: pluginPaths is empty, so database lookup should be used

      final pluginBytes = Uint8List.fromList([0x7F, 0x45, 0x4C, 0x46]);
      when(
        () => mockMetadataDao.getPluginFilePathsByGuids({'OTHERPLUGIN'}),
      ).thenAnswer(
        (_) async => {'OTHERPLUGIN': 'programs/plug-ins/Other.elf'},
      );
      when(
        () => mockFileSystem.readFile('programs/plug-ins/Other.elf'),
      ).thenAnswer((_) async => pluginBytes);

      final config = const PackageConfig(includeCommunityPlugins: true);

      // Act
      final result = await fileCollector.collectDependencies(
        deps,
        config: config,
      );

      // Assert
      expect(result.files.length, 1);
      expect(result.files.first.relativePath, 'programs/plug-ins/Other.elf');

      // Should call database lookup for plugins without direct paths
      verify(
        () => mockMetadataDao.getPluginFilePathsByGuids({'OTHERPLUGIN'}),
      ).called(1);
    });

    test('handles missing plugin file gracefully (returns null)', () async {
      // Arrange
      final deps = PresetDependencies();
      deps.pluginPaths['MISSING'] = 'programs/plug-ins/Missing.elf';

      when(
        () => mockFileSystem.readFile('programs/plug-ins/Missing.elf'),
      ).thenAnswer((_) async => null); // File not found

      final config = const PackageConfig(includeCommunityPlugins: true);

      // Act
      final result = await fileCollector.collectDependencies(
        deps,
        config: config,
      );

      // Assert - should continue without adding the file
      expect(result.files, isEmpty);
    });

    test('handles file read error gracefully', () async {
      // Arrange
      final deps = PresetDependencies();
      deps.pluginPaths['ERROR'] = 'programs/plug-ins/Error.elf';

      when(
        () => mockFileSystem.readFile('programs/plug-ins/Error.elf'),
      ).thenThrow(Exception('Read error'));

      final config = const PackageConfig(includeCommunityPlugins: true);

      // Act
      final result = await fileCollector.collectDependencies(
        deps,
        config: config,
      );

      // Assert - should handle error and continue
      expect(result.files, isEmpty);
    });

    test('collects from both pluginPaths and communityPlugins', () async {
      // Arrange
      final deps = PresetDependencies();
      deps.pluginPaths['DIRECT_PLUGIN'] = 'programs/plug-ins/Direct.elf';
      deps.communityPlugins.add('DB_PLUGIN');

      final directBytes = Uint8List.fromList([1, 2, 3, 4]);
      final dbBytes = Uint8List.fromList([5, 6, 7, 8]);

      when(
        () => mockFileSystem.readFile('programs/plug-ins/Direct.elf'),
      ).thenAnswer((_) async => directBytes);

      when(
        () => mockMetadataDao.getPluginFilePathsByGuids({'DB_PLUGIN'}),
      ).thenAnswer(
        (_) async => {'DB_PLUGIN': 'programs/plug-ins/DbPlugin.elf'},
      );
      when(
        () => mockFileSystem.readFile('programs/plug-ins/DbPlugin.elf'),
      ).thenAnswer((_) async => dbBytes);

      final config = const PackageConfig(includeCommunityPlugins: true);

      // Act
      final result = await fileCollector.collectDependencies(
        deps,
        config: config,
      );

      // Assert
      expect(result.files.length, 2);

      final paths = result.files.map((f) => f.relativePath).toSet();
      expect(paths, contains('programs/plug-ins/Direct.elf'));
      expect(paths, contains('programs/plug-ins/DbPlugin.elf'));
    });

    test('skips plugin collection when includeCommunityPlugins is false', () async {
      // Arrange
      final deps = PresetDependencies();
      deps.pluginPaths['PLUGIN'] = 'programs/plug-ins/Plugin.elf';

      final config = const PackageConfig(includeCommunityPlugins: false);

      // Act
      final result = await fileCollector.collectDependencies(
        deps,
        config: config,
      );

      // Assert
      expect(result.files, isEmpty);

      // Should never try to read the plugin file
      verifyNever(() => mockFileSystem.readFile(any()));
    });

    test('avoids duplicate collection when GUID is in both sets', () async {
      // Arrange
      final deps = PresetDependencies();
      // Same GUID in both - direct path should take priority
      deps.pluginPaths['SAMEGUID'] = 'programs/plug-ins/Same.elf';
      deps.communityPlugins.add('SAMEGUID');

      final pluginBytes = Uint8List.fromList([1, 2, 3]);
      when(
        () => mockFileSystem.readFile('programs/plug-ins/Same.elf'),
      ).thenAnswer((_) async => pluginBytes);

      final config = const PackageConfig(includeCommunityPlugins: true);

      // Act
      final result = await fileCollector.collectDependencies(
        deps,
        config: config,
      );

      // Assert - should only collect once
      expect(result.files.length, 1);
      expect(result.files.first.relativePath, 'programs/plug-ins/Same.elf');

      // Should NOT call database lookup since direct path was used
      verifyNever(() => mockMetadataDao.getPluginFilePathsByGuids(any()));
    });
  });

  group('FileCollector - PackageConfig flags', () {
    test('excludes wavetables when includeWavetables is false', () async {
      final deps = PresetDependencies();
      deps.wavetables.add('MySaw');

      final config = const PackageConfig(includeWavetables: false);

      final result = await fileCollector.collectDependencies(
        deps,
        config: config,
      );

      expect(result.files, isEmpty);
      verifyNever(() => mockFileSystem.readFile(any()));
    });

    test('excludes sample folders when includeSamples is false', () async {
      final deps = PresetDependencies();
      deps.sampleFolders.add('Drums');

      final config = const PackageConfig(includeSamples: false);

      final result = await fileCollector.collectDependencies(
        deps,
        config: config,
      );

      expect(result.files, isEmpty);
      verifyNever(
        () => mockFileSystem.listFiles(any(), recursive: any(named: 'recursive')),
      );
    });

    test('excludes multisample folders when includeSamples is false', () async {
      final deps = PresetDependencies();
      deps.multisampleFolders.add('Piano');

      final config = const PackageConfig(includeSamples: false);

      final result = await fileCollector.collectDependencies(
        deps,
        config: config,
      );

      expect(result.files, isEmpty);
      verifyNever(
        () => mockFileSystem.listFiles(any(), recursive: any(named: 'recursive')),
      );
    });

    test('excludes FM banks when includeFMBanks is false', () async {
      final deps = PresetDependencies();
      deps.fmBanks.add('bank.syx');

      final config = const PackageConfig(includeFMBanks: false);

      final result = await fileCollector.collectDependencies(
        deps,
        config: config,
      );

      expect(result.files, isEmpty);
      verifyNever(() => mockFileSystem.readFile(any()));
    });

    test('excludes Three Pot programs when includeThreePot is false', () async {
      final deps = PresetDependencies();
      deps.threePotPrograms.add('prog.pot');

      final config = const PackageConfig(includeThreePot: false);

      final result = await fileCollector.collectDependencies(
        deps,
        config: config,
      );

      expect(result.files, isEmpty);
      verifyNever(() => mockFileSystem.readFile(any()));
    });

    test('excludes Lua scripts when includeLua is false', () async {
      final deps = PresetDependencies();
      deps.luaScripts.add('script.lua');

      final config = const PackageConfig(includeLua: false);

      final result = await fileCollector.collectDependencies(
        deps,
        config: config,
      );

      expect(result.files, isEmpty);
      verifyNever(() => mockFileSystem.readFile(any()));
    });

    test('collects all non-plugin types when config is null', () async {
      final deps = PresetDependencies();
      deps.wavetables.add('MySaw');
      deps.fmBanks.add('bank.syx');
      deps.threePotPrograms.add('prog.pot');
      deps.luaScripts.add('script.lua');

      final wtBytes = Uint8List.fromList([1]);
      final fmBytes = Uint8List.fromList([2]);
      final potBytes = Uint8List.fromList([3]);
      final luaBytes = Uint8List.fromList([4]);

      // Wavetable: folder enumeration returns empty, so the collector
      // falls back to a single-file <name>.wav at the root.
      when(
        () => mockFileSystem.listFiles(
          'wavetables/MySaw',
          recursive: any(named: 'recursive'),
        ),
      ).thenAnswer((_) async => <String>[]);
      when(() => mockFileSystem.readFile('wavetables/MySaw.wav'))
          .thenAnswer((_) async => wtBytes);
      when(() => mockFileSystem.readFile('FMSYX/bank.syx'))
          .thenAnswer((_) async => fmBytes);
      when(() => mockFileSystem.readFile('programs/three_pot/prog.pot'))
          .thenAnswer((_) async => potBytes);
      when(() => mockFileSystem.readFile('programs/lua/script.lua'))
          .thenAnswer((_) async => luaBytes);

      final result = await fileCollector.collectDependencies(deps);

      expect(result.files.length, 4);
      final paths = result.files.map((f) => f.relativePath).toSet();
      expect(paths, contains('wavetables/MySaw.wav'));
      expect(paths, contains('FMSYX/bank.syx'));
      expect(paths, contains('programs/three_pot/prog.pot'));
      expect(paths, contains('programs/lua/script.lua'));
    });
  });

  group('FileCollector - new dependency types', () {
    test('collects trigger-style sampleFiles under /samples/', () async {
      final deps = PresetDependencies();
      deps.sampleFiles.add('Cheetah_MD16/MD16_BD_Gated_1.wav');
      deps.sampleFiles.add('DMX606_SamplePack/DMX606_SD1_A.wav');

      final bdBytes = Uint8List.fromList([0xAA]);
      final sdBytes = Uint8List.fromList([0xBB]);

      when(
        () => mockFileSystem.readFile(
          'samples/Cheetah_MD16/MD16_BD_Gated_1.wav',
        ),
      ).thenAnswer((_) async => bdBytes);
      when(
        () => mockFileSystem.readFile(
          'samples/DMX606_SamplePack/DMX606_SD1_A.wav',
        ),
      ).thenAnswer((_) async => sdBytes);

      final result = await fileCollector.collectDependencies(deps);

      final paths = result.files.map((f) => f.relativePath).toSet();
      expect(paths, contains('samples/Cheetah_MD16/MD16_BD_Gated_1.wav'));
      expect(paths, contains('samples/DMX606_SamplePack/DMX606_SD1_A.wav'));
      expect(result.warnings, isEmpty);
    });

    test('collects granulator samples under /samples/', () async {
      final deps = PresetDependencies();
      deps.granulatorSamples.add('kick.wav');

      when(() => mockFileSystem.readFile('samples/kick.wav'))
          .thenAnswer((_) async => Uint8List.fromList([1, 2, 3]));

      final result = await fileCollector.collectDependencies(deps);

      expect(
        result.files.map((f) => f.relativePath),
        contains('samples/kick.wav'),
      );
    });

    test('emits a warning when a sample is missing from the SD card', () async {
      final deps = PresetDependencies();
      deps.sampleFiles.add('drums/missing.wav');

      when(() => mockFileSystem.readFile('samples/drums/missing.wav'))
          .thenAnswer((_) async => null);

      final result = await fileCollector.collectDependencies(deps);

      expect(result.files, isEmpty);
      expect(result.warnings, isNotEmpty);
      expect(result.warnings.first, contains('drums/missing.wav'));
    });

    test('skips oversized files and warns', () async {
      final deps = PresetDependencies();
      deps.granulatorSamples.add('huge.wav');

      // 51 MB — over the 50 MB cap
      final huge = Uint8List(51 * 1024 * 1024);
      when(() => mockFileSystem.readFile('samples/huge.wav'))
          .thenAnswer((_) async => huge);

      final result = await fileCollector.collectDependencies(deps);

      expect(result.files, isEmpty);
      expect(
        result.warnings.any((w) => w.contains('oversized')),
        isTrue,
      );
    });

    test('excludes sample files when includeSamples is false', () async {
      final deps = PresetDependencies();
      deps.sampleFiles.add('drums/kick.wav');
      deps.granulatorSamples.add('grain.wav');

      final config = const PackageConfig(includeSamples: false);

      final result = await fileCollector.collectDependencies(
        deps,
        config: config,
      );

      expect(result.files, isEmpty);
      verifyNever(() => mockFileSystem.readFile(any()));
    });
  });
}
