import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/poly_multisample/decent_sampler_converter.dart';
import 'package:nt_helper/poly_multisample/poly_multisample_models.dart';
import 'package:nt_helper/poly_multisample/poly_sample_import_service.dart';

void main() {
  group('PolySampleImportService', () {
    late Directory tempRoot;

    setUp(() {
      tempRoot = Directory.systemTemp.createTempSync(
        'poly_sample_import_service_test_',
      );
    });

    tearDown(() {
      if (tempRoot.existsSync()) {
        tempRoot.deleteSync(recursive: true);
      }
    });

    test('analyzes Decent sources before staging', () async {
      final preset = await _writeOverlappingDecentPreset(tempRoot);

      final analysis = await PolySampleImportService().analyzeDecentSource(
        preset.path,
      );

      expect(analysis.presets.single.name, 'Layered');
      expect(analysis.groups.map((group) => group.name), [
        'Group 1',
        'Group 2',
      ]);
      expect(analysis.hasAmbiguousOverlaps, isTrue);
      expect(analysis.structureSummary, isNotEmpty);
    });

    test('stages Decent sources into tracked temp roots', () async {
      final preset = await _writeOverlappingDecentPreset(tempRoot);

      final staged = await PolySampleImportService().stageDecentSource(
        preset.path,
        options: const DecentSamplerConvertOptions(
          groupHandling: DecentSamplerGroupHandling.velocityLayers,
        ),
      );

      expect(staged.name, 'Layered');
      expect(staged.tempRoots, hasLength(1));
      expect(Directory(staged.tempRoots.single).existsSync(), isTrue);
      expect(staged.regions, hasLength(4));
      expect(staged.regions.map((region) => region.velocityLayer), [
        1,
        2,
        1,
        2,
      ]);
    });

    test(
      'maps loose WAV files using chromatic, RR, velocity, and unmapped modes',
      () async {
        final c = File('${tempRoot.path}/Loose_C3.wav')..writeAsBytesSync([0]);
        final d = File('${tempRoot.path}/Loose_D3.wav')..writeAsBytesSync([0]);
        final service = PolySampleImportService();

        final chromatic = await service.stageLooseFiles(
          [c.path, d.path],
          const PolyLooseWavMappingOptions(
            mode: PolyLooseWavMappingMode.chromaticSpread,
            startMidi: 60,
          ),
        );
        expect(chromatic.regions.map((region) => region.rootMidi), [60, 61]);

        final roundRobin = await service.stageLooseFiles(
          [c.path, d.path],
          const PolyLooseWavMappingOptions(
            mode: PolyLooseWavMappingMode.roundRobinStack,
            startMidi: 60,
          ),
        );
        expect(roundRobin.regions.map((region) => region.rootMidi), [60, 60]);
        expect(roundRobin.regions.map((region) => region.roundRobin), [1, 2]);

        final velocity = await service.stageLooseFiles(
          [c.path, d.path],
          const PolyLooseWavMappingOptions(
            mode: PolyLooseWavMappingMode.velocityLayers,
            startMidi: 60,
          ),
        );
        expect(velocity.regions.map((region) => region.rootMidi), [60, 60]);
        expect(velocity.regions.map((region) => region.velocityLayer), [1, 2]);

        final unmapped = await service.stageLooseFiles(
          [c.path, d.path],
          const PolyLooseWavMappingOptions(
            mode: PolyLooseWavMappingMode.unmapped,
          ),
        );
        expect(unmapped.regions.map((region) => region.rootMidi), [null, null]);
        expect(
          unmapped.regions.every(
            (region) =>
                region.currentIssues.contains(PolySampleIssue.missingRootNote),
          ),
          isTrue,
        );
      },
    );
  });
}

Future<File> _writeOverlappingDecentPreset(Directory root) async {
  final samples = Directory('${root.path}/Samples')..createSync();
  File('${samples.path}/soft_c4.wav').writeAsBytesSync(_dummyWav);
  File('${samples.path}/soft_d4.wav').writeAsBytesSync(_dummyWav);
  File('${samples.path}/hard_c4.wav').writeAsBytesSync(_dummyWav);
  File('${samples.path}/hard_d4.wav').writeAsBytesSync(_dummyWav);
  final preset = File('${root.path}/Layered.dspreset');
  await preset.writeAsString('''
<DecentSampler>
  <groups>
    <group name="Group 1">
      <sample path="Samples/soft_c4.wav" rootNote="C4" loNote="C4" hiNote="C4"/>
      <sample path="Samples/soft_d4.wav" rootNote="D4" loNote="D4" hiNote="D4"/>
    </group>
    <group name="Group 2">
      <sample path="Samples/hard_c4.wav" rootNote="C4" loNote="C4" hiNote="C4"/>
      <sample path="Samples/hard_d4.wav" rootNote="D4" loNote="D4" hiNote="D4"/>
    </group>
  </groups>
</DecentSampler>
''');
  return preset;
}

const _dummyWav = <int>[
  0x52,
  0x49,
  0x46,
  0x46,
  0x24,
  0x00,
  0x00,
  0x00,
  0x57,
  0x41,
  0x56,
  0x45,
  0x66,
  0x6d,
  0x74,
  0x20,
  0x10,
  0x00,
  0x00,
  0x00,
  0x01,
  0x00,
  0x01,
  0x00,
  0x44,
  0xac,
  0x00,
  0x00,
  0x88,
  0x58,
  0x01,
  0x00,
  0x02,
  0x00,
  0x10,
  0x00,
  0x64,
  0x61,
  0x74,
  0x61,
  0x00,
  0x00,
  0x00,
  0x00,
];
