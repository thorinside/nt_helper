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
      expect(result.length, 1);
      expect(result.first.relativePath, 'programs/plug-ins/MyPlugin.elf');
      expect(result.first.bytes, pluginBytes);

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
      expect(result.length, 1);
      expect(result.first.relativePath, 'programs/plug-ins/Other.elf');

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
      expect(result, isEmpty);
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
      expect(result, isEmpty);
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
      expect(result.length, 2);

      final paths = result.map((f) => f.relativePath).toSet();
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
      expect(result, isEmpty);

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
      expect(result.length, 1);
      expect(result.first.relativePath, 'programs/plug-ins/Same.elf');

      // Should NOT call database lookup since direct path was used
      verifyNever(() => mockMetadataDao.getPluginFilePathsByGuids(any()));
    });
  });
}
