import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/domain/disting_nt_sysex.dart';
import 'package:nt_helper/services/preset_analyzer.dart';

void main() {
  group('PresetAnalyzer.extractPluginPaths', () {
    test('extracts plugin paths from AlgorithmInfo with isPlugin=true', () {
      // Arrange
      final algorithmInfos = [
        AlgorithmInfo(
          algorithmIndex: 0,
          guid: 'MYPLUGIN',
          name: 'My Plugin',
          specifications: const [],
          isPlugin: true,
          filename: 'programs/plug-ins/MyPlugin.elf',
        ),
      ];

      // Act
      final result = PresetAnalyzer.extractPluginPaths(algorithmInfos);

      // Assert
      expect(result, {'MYPLUGIN': 'programs/plug-ins/MyPlugin.elf'});
    });

    test('ignores factory algorithms (isPlugin=false)', () {
      // Arrange
      final algorithmInfos = [
        AlgorithmInfo(
          algorithmIndex: 0,
          guid: 'sdly',
          name: 'SD Multisample',
          specifications: const [],
          isPlugin: false,
          filename: null,
        ),
      ];

      // Act
      final result = PresetAnalyzer.extractPluginPaths(algorithmInfos);

      // Assert
      expect(result, isEmpty);
    });

    test('ignores plugins with null filename', () {
      // Arrange
      final algorithmInfos = [
        AlgorithmInfo(
          algorithmIndex: 0,
          guid: 'PLUGIN1',
          name: 'Plugin Without Path',
          specifications: const [],
          isPlugin: true,
          filename: null,
        ),
      ];

      // Act
      final result = PresetAnalyzer.extractPluginPaths(algorithmInfos);

      // Assert
      expect(result, isEmpty);
    });

    test('ignores plugins with empty filename', () {
      // Arrange
      final algorithmInfos = [
        AlgorithmInfo(
          algorithmIndex: 0,
          guid: 'PLUGIN2',
          name: 'Plugin Empty Path',
          specifications: const [],
          isPlugin: true,
          filename: '',
        ),
      ];

      // Act
      final result = PresetAnalyzer.extractPluginPaths(algorithmInfos);

      // Assert
      expect(result, isEmpty);
    });

    test('extracts multiple plugin paths', () {
      // Arrange
      final algorithmInfos = [
        AlgorithmInfo(
          algorithmIndex: 0,
          guid: 'PLUGIN_A',
          name: 'Plugin A',
          specifications: const [],
          isPlugin: true,
          filename: 'programs/plug-ins/PluginA.elf',
        ),
        AlgorithmInfo(
          algorithmIndex: 1,
          guid: 'sdly',
          name: 'SD Multisample',
          specifications: const [],
          isPlugin: false,
          filename: null,
        ),
        AlgorithmInfo(
          algorithmIndex: 2,
          guid: 'PLUGIN_B',
          name: 'Plugin B',
          specifications: const [],
          isPlugin: true,
          filename: 'programs/plug-ins/subfolder/PluginB.elf',
        ),
      ];

      // Act
      final result = PresetAnalyzer.extractPluginPaths(algorithmInfos);

      // Assert
      expect(result, {
        'PLUGIN_A': 'programs/plug-ins/PluginA.elf',
        'PLUGIN_B': 'programs/plug-ins/subfolder/PluginB.elf',
      });
    });

    test('returns empty map for empty input', () {
      // Arrange
      final algorithmInfos = <AlgorithmInfo>[];

      // Act
      final result = PresetAnalyzer.extractPluginPaths(algorithmInfos);

      // Assert
      expect(result, isEmpty);
    });
  });
}
