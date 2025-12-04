import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/models/preset_dependencies.dart';

void main() {
  group('PresetDependencies', () {
    test('pluginPaths is empty by default', () {
      // Arrange & Act
      final deps = PresetDependencies();

      // Assert
      expect(deps.pluginPaths, isEmpty);
    });

    test('pluginPaths can be populated', () {
      // Arrange
      final deps = PresetDependencies();

      // Act
      deps.pluginPaths['MYPLUGIN'] = 'programs/plug-ins/MyPlugin.elf';
      deps.pluginPaths['OTHER'] = 'programs/plug-ins/Other.elf';

      // Assert
      expect(deps.pluginPaths.length, 2);
      expect(deps.pluginPaths['MYPLUGIN'], 'programs/plug-ins/MyPlugin.elf');
      expect(deps.pluginPaths['OTHER'], 'programs/plug-ins/Other.elf');
    });

    test('hasCommunityPlugins returns true when pluginPaths is not empty', () {
      // Arrange
      final deps = PresetDependencies();
      deps.pluginPaths['PLUGIN'] = 'path/to/plugin.elf';

      // Act & Assert
      expect(deps.hasCommunityPlugins, true);
    });

    test(
      'hasCommunityPlugins returns true when communityPlugins is not empty',
      () {
        // Arrange
        final deps = PresetDependencies();
        deps.communityPlugins.add('SOMEPLUGIN');

        // Act & Assert
        expect(deps.hasCommunityPlugins, true);
      },
    );

    test('hasCommunityPlugins returns true when both sets are populated', () {
      // Arrange
      final deps = PresetDependencies();
      deps.communityPlugins.add('PLUGIN1');
      deps.pluginPaths['PLUGIN2'] = 'path/to/plugin2.elf';

      // Act & Assert
      expect(deps.hasCommunityPlugins, true);
    });

    test(
      'hasCommunityPlugins returns false when both are empty',
      () {
        // Arrange
        final deps = PresetDependencies();

        // Act & Assert
        expect(deps.hasCommunityPlugins, false);
      },
    );

    test('pluginPaths does not affect totalCount', () {
      // Arrange
      final deps = PresetDependencies();
      deps.pluginPaths['PLUGIN'] = 'path/to/plugin.elf';

      // Act & Assert
      // pluginPaths is additional data, not counted in totalCount
      // totalCount only counts the sets
      expect(deps.totalCount, 0);
    });

    test('addAll works with pluginPaths', () {
      // Arrange
      final deps = PresetDependencies();
      final paths = {
        'PLUGIN_A': 'path/a.elf',
        'PLUGIN_B': 'path/b.elf',
      };

      // Act
      deps.pluginPaths.addAll(paths);

      // Assert
      expect(deps.pluginPaths.length, 2);
      expect(deps.pluginPaths['PLUGIN_A'], 'path/a.elf');
      expect(deps.pluginPaths['PLUGIN_B'], 'path/b.elf');
    });
  });
}
