import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/poly_multisample/decent_sampler_converter.dart';
import 'package:nt_helper/poly_multisample/poly_multisample_models.dart';
import 'package:nt_helper/poly_multisample/poly_sample_import_service.dart';
import 'package:nt_helper/ui/poly_multisample/poly_decent_import_cubit.dart';

void main() {
  group('PolyDecentImportCubit', () {
    test('blocks manual continuation when group ranges overlap', () async {
      final service = _FakeImportService(_overlappingAnalysis());
      final cubit = PolyDecentImportCubit(importService: service);
      addTearDown(cubit.close);

      await cubit.analyzeSource('/tmp/Layered.dspreset');
      cubit.setGroupHandling(DecentSamplerGroupHandling.keyRanges);

      expect(cubit.state.status, PolyDecentImportStatus.ready);
      expect(cubit.state.canContinue, isFalse);
      expect(cubit.state.warnings.single, contains('overlap'));

      await cubit.continueImport();

      expect(service.stageCallCount, 0);
      expect(cubit.state.error, contains('overlap'));
    });

    test('manual range edits do not auto-shift other rows', () async {
      final service = _FakeImportService(_overlappingAnalysis());
      final cubit = PolyDecentImportCubit(importService: service);
      addTearDown(cubit.close);

      await cubit.analyzeSource('/tmp/Layered.dspreset');
      cubit.setGroupHandling(DecentSamplerGroupHandling.keyRanges);
      cubit.updateGroupRange(
        'group:1:Group 2',
        const DecentSamplerTagKeyRange(lowMidi: 62, rootMidi: 62, highMidi: 62),
      );

      expect(cubit.state.manualGroupRanges['group:0:Group 1']!.lowMidi, 60);
      expect(cubit.state.manualGroupRanges['group:0:Group 1']!.highMidi, 61);
      expect(cubit.state.canContinue, isTrue);

      await cubit.continueImport();

      expect(service.stageCallCount, 1);
      expect(cubit.state.status, PolyDecentImportStatus.completed);
    });
  });
}

class _FakeImportService extends PolySampleImportService {
  _FakeImportService(this.analysis);

  final DecentSamplerImportAnalysis analysis;
  int stageCallCount = 0;

  @override
  Future<DecentSamplerImportAnalysis> analyzeDecentSource(String path) async {
    return analysis;
  }

  @override
  Future<PolyStagedImport> stageDecentSource(
    String path, {
    DecentSamplerConvertOptions options = const DecentSamplerConvertOptions(),
    String? outputParentPath,
  }) async {
    stageCallCount++;
    return const PolyStagedImport(
      name: 'Layered',
      sourceLabel: '/tmp/Layered.dspreset',
      regions: [],
    );
  }
}

DecentSamplerImportAnalysis _overlappingAnalysis() {
  return const DecentSamplerImportAnalysis(
    presetName: 'Layered',
    presets: [
      DecentSamplerPresetInfo(
        name: 'Layered',
        groupCount: 2,
        sampleCount: 4,
        tagCount: 0,
      ),
    ],
    groups: [
      DecentSamplerGroupInfo(
        key: 'group:0:Group 1',
        name: 'Group 1',
        xmlSummary: 'Group 1',
        sampleCount: 2,
        rootCount: 2,
        structureSummary: 'C4-D4',
        noteRange: 'C4 - D4',
        velocitySummary: '1-127',
        roundRobinSummary: 'No seqPosition',
        examples: ['soft_c4.wav'],
        defaultLowMidi: 60,
        defaultRootMidi: 60,
        defaultHighMidi: 61,
        defaultVelocityLayer: 1,
      ),
      DecentSamplerGroupInfo(
        key: 'group:1:Group 2',
        name: 'Group 2',
        xmlSummary: 'Group 2',
        sampleCount: 2,
        rootCount: 2,
        structureSummary: 'C4-D4',
        noteRange: 'C4 - D4',
        velocitySummary: '1-127',
        roundRobinSummary: 'No seqPosition',
        examples: ['hard_c4.wav'],
        defaultLowMidi: 60,
        defaultRootMidi: 60,
        defaultHighMidi: 61,
        defaultVelocityLayer: 1,
      ),
    ],
    tags: [],
    hasAmbiguousOverlaps: true,
    structureSummary: '2 overlapping groups',
    recommendedGroupHandling: DecentSamplerGroupHandling.keyRanges,
  );
}
