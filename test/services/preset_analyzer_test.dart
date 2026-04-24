import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/domain/disting_nt_sysex.dart';
import 'package:nt_helper/services/preset_analyzer.dart';

Map<String, dynamic> _loadFixture(String name) {
  final file = File('test/fixtures/presets/$name');
  return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
}

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

  // ---------------------------------------------------------------------------
  // analyzeDependencies — exercises against real preset JSON fixtures captured
  // from the distingNT reference repo. Each fixture is a complete `.json` file
  // as the firmware would emit, so these tests guard against regressions in
  // the GUID/field-name conventions emitted by real hardware.
  // ---------------------------------------------------------------------------
  group('PresetAnalyzer.analyzeDependencies', () {
    test('Granulated Piano: pyms multisample folder', () {
      final preset = _loadFixture('granulated_piano.json');

      final deps = PresetAnalyzer.analyzeDependencies(preset);

      // pyms timbre folder → multisample
      expect(deps.multisampleFolders, contains('LABS Soft Pno - PedOn'));
      // gran has an empty `sample` field; analyzer should ignore it.
      expect(deps.granulatorSamples, isEmpty);
      // No Lua, 3pot, or wavetable in this preset
      expect(deps.luaScripts, isEmpty);
      expect(deps.threePotPrograms, isEmpty);
      expect(deps.wavetables, isEmpty);
      // No community plugins (all factory algorithms)
      expect(deps.communityPlugins, isEmpty);
    });

    test('SyncLatchDemo: lua program + samp triggers + pyms folder', () {
      final preset = _loadFixture('sync_latch_demo.json');

      final deps = PresetAnalyzer.analyzeDependencies(preset);

      // Lua slot has guid 'lua ' (with trailing space) and field `program` —
      // the previous (broken) check looked at guid=='lua' and field 'script',
      // so this case is the regression guard.
      expect(deps.luaScripts, contains('sync_latch.lua'));

      // samp slot has 8 trigger entries — only unique paths survive in the Set
      expect(
        deps.sampleFiles,
        containsAll([
          'Cheetah_MD16/MD16_BD_Gated_1.wav',
          'DMX606_SamplePack/DMX606_SD1_A.wav',
          'DMX606_SamplePack/DMX606_HHclosed_A.wav',
          '!LABS Soft Pno - PedOn/PedOn_A#-1.wav',
        ]),
      );
      // Four distinct sample paths after dedup
      expect(deps.sampleFiles.length, 4);

      // pyms timbre folder
      expect(deps.multisampleFolders, contains('LABS Soft Pno - PedOn'));
    });

    test('Automatronic: pyfm banks + waos wavetable', () {
      final preset = _loadFixture('automatronic.json');

      final deps = PresetAnalyzer.analyzeDependencies(preset);

      expect(
        deps.fmBanks,
        containsAll([
          '!ROM1B.syx',
          '!ROM2A.syx',
        ]),
      );
      expect(deps.wavetables, contains('warm-squ'));
      // No community plugins
      expect(deps.communityPlugins, isEmpty);
    });

    test('FM banks: built-in synth banks are skipped (no file on SD)', () {
      // The pyfm `bank` field can be `<built-in N>` for firmware-
      // synthesized ROMs that have no corresponding /FMSYX/ file.
      // Including them as deps would generate spurious warnings on
      // export. Real preset: presets/Community/Play in time.json.
      final preset = {
        'slots': [
          {
            'guid': 'pyfm',
            'timbres': [
              {'bank': '<built-in 2>', 'voice': 'BELL C    '},
              {'bank': '!ROM1A.syx', 'voice': 'PIANO 1   '},
            ],
          },
        ],
      };

      final deps = PresetAnalyzer.analyzeDependencies(preset);

      expect(deps.fmBanks, {'!ROM1A.syx'});
    });

    test('community plugin GUID detection preserves trailing space', () {
      // Synthetic preset to verify the analyzer:
      //  - detects uppercase GUIDs as community plugins
      //  - preserves the original (un-trimmed) GUID for path lookup
      final preset = {
        'slots': [
          {'guid': 'MyPlu', 'name': 'Community plugin'},
        ],
      };

      final deps = PresetAnalyzer.analyzeDependencies(preset);

      expect(deps.communityPlugins, contains('MyPlu'));
    });

    test('lua field "program" matches even when guid has trailing space', () {
      final preset = {
        'slots': [
          {'guid': 'lua ', 'program': 'my_script.lua'},
        ],
      };

      final deps = PresetAnalyzer.analyzeDependencies(preset);

      expect(deps.luaScripts, {'my_script.lua'});
    });

    test('granulator slot collects sample when populated', () {
      final preset = {
        'slots': [
          {'guid': 'gran', 'sample': 'kick.wav'},
        ],
      };

      final deps = PresetAnalyzer.analyzeDependencies(preset);

      expect(deps.granulatorSamples, {'kick.wav'});
    });
  });
}
