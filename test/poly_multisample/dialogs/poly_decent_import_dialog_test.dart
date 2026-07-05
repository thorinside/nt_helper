import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/poly_multisample/decent_sampler_converter.dart';
import 'package:nt_helper/ui/poly_multisample/dialogs/poly_decent_import_dialog.dart';
import 'package:nt_helper/ui/poly_multisample/poly_decent_import_cubit.dart';

void main() {
  testWidgets('shows analysis summary and handling modes', (tester) async {
    final cubit = _TestPolyDecentImportCubit()..setTestState(_readyState());
    addTearDown(cubit.close);

    await _pumpDialogButton(tester, cubit);
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('2 presets, 2 groups, 2 tags'), findsOneWidget);
    expect(find.text('Automatic (recommended)'), findsOneWidget);
    expect(find.text('Map groups by tags'), findsOneWidget);
    expect(find.text('Groups as velocity layers'), findsOneWidget);
    expect(find.text('Groups as manual key ranges'), findsOneWidget);
    expect(find.text('Split groups into separate folders'), findsOneWidget);
    expect(find.text('Import one group only'), findsOneWidget);
    expect(find.text('Import selected tags only'), findsOneWidget);
  });

  testWidgets('selectedTags mode reveals per-tag range steppers', (
    tester,
  ) async {
    final cubit = _TestPolyDecentImportCubit()
      ..setTestState(
        _readyState().copyWith(
          groupHandling: DecentSamplerGroupHandling.selectedTags,
          selectedTagKeys: {'tag:soft'},
        ),
      );
    addTearDown(cubit.close);

    await _pumpDialogButton(tester, cubit);
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('soft'), findsOneWidget);
    expect(find.byTooltip('Increase Low'), findsAtLeastNWidgets(1));
  });

  testWidgets('import disabled while warnings present', (tester) async {
    final cubit = _TestPolyDecentImportCubit()
      ..setTestState(_readyState().copyWith(warnings: ['Ranges overlap']));
    addTearDown(cubit.close);

    await _pumpDialogButton(tester, cubit);
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    final button = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Import'),
    );

    expect(button.onPressed, isNull);
  });
}

Future<void> _pumpDialogButton(
  WidgetTester tester,
  PolyDecentImportCubit cubit,
) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) {
            return TextButton(
              onPressed: () {
                showPolyDecentImportDialog(
                  context,
                  sourcePath: '/tmp/Layered.dspreset',
                  cubit: cubit,
                );
              },
              child: const Text('Open'),
            );
          },
        ),
      ),
    ),
  );
}

PolyDecentImportState _readyState() {
  return PolyDecentImportState(
    status: PolyDecentImportStatus.ready,
    sourcePath: '/tmp/Layered.dspreset',
    analysis: _analysis(),
    groupHandling: DecentSamplerGroupHandling.auto,
    manualGroupRanges: const {
      'group:soft': DecentSamplerTagKeyRange(
        lowMidi: 60,
        rootMidi: 60,
        highMidi: 61,
      ),
      'group:hard': DecentSamplerTagKeyRange(
        lowMidi: 62,
        rootMidi: 62,
        highMidi: 63,
      ),
    },
    tagKeyRanges: const {
      'tag:soft': DecentSamplerTagKeyRange(
        lowMidi: 60,
        rootMidi: 60,
        highMidi: 61,
      ),
      'tag:hard': DecentSamplerTagKeyRange(
        lowMidi: 62,
        rootMidi: 62,
        highMidi: 63,
      ),
    },
    selectedPresetNames: const {'Preset A', 'Preset B'},
  );
}

DecentSamplerImportAnalysis _analysis() {
  return const DecentSamplerImportAnalysis(
    presetName: 'Layered',
    presets: [
      DecentSamplerPresetInfo(
        name: 'Preset A',
        groupCount: 1,
        sampleCount: 2,
        tagCount: 1,
      ),
      DecentSamplerPresetInfo(
        name: 'Preset B',
        groupCount: 1,
        sampleCount: 2,
        tagCount: 1,
      ),
    ],
    groups: [
      DecentSamplerGroupInfo(
        key: 'group:soft',
        name: 'Soft',
        xmlSummary: 'Soft',
        sampleCount: 2,
        rootCount: 2,
        structureSummary: 'C4-D4',
        noteRange: 'C4 - D4',
        velocitySummary: '1-64',
        roundRobinSummary: 'No seqPosition',
        examples: ['soft_c4.wav'],
        defaultLowMidi: 60,
        defaultRootMidi: 60,
        defaultHighMidi: 61,
        defaultVelocityLayer: 1,
      ),
      DecentSamplerGroupInfo(
        key: 'group:hard',
        name: 'Hard',
        xmlSummary: 'Hard',
        sampleCount: 2,
        rootCount: 2,
        structureSummary: 'E4-F4',
        noteRange: 'E4 - F4',
        velocitySummary: '65-127',
        roundRobinSummary: 'No seqPosition',
        examples: ['hard_e4.wav'],
        defaultLowMidi: 62,
        defaultRootMidi: 62,
        defaultHighMidi: 63,
        defaultVelocityLayer: 1,
      ),
    ],
    tags: [
      DecentSamplerTag(
        key: 'tag:soft',
        label: 'soft',
        groupKeys: ['group:soft'],
        sampleCount: 2,
        confidence: 1.0,
        evidence: '',
        structureSummary: 'C4-D4',
        noteRange: 'C4 - D4',
        velocitySummary: '1-64',
        roundRobinSummary: 'No seqPosition',
        defaultLowMidi: 60,
        defaultRootMidi: 60,
        defaultHighMidi: 61,
        defaultVelocityLayer: 1,
      ),
      DecentSamplerTag(
        key: 'tag:hard',
        label: 'hard',
        groupKeys: ['group:hard'],
        sampleCount: 2,
        confidence: 1.0,
        evidence: '',
        structureSummary: 'E4-F4',
        noteRange: 'E4 - F4',
        velocitySummary: '65-127',
        roundRobinSummary: 'No seqPosition',
        defaultLowMidi: 62,
        defaultRootMidi: 62,
        defaultHighMidi: 63,
        defaultVelocityLayer: 1,
      ),
    ],
    hasAmbiguousOverlaps: false,
    structureSummary: '2 presets, 2 groups, 2 tags',
    recommendedGroupHandling: DecentSamplerGroupHandling.auto,
  );
}

class _TestPolyDecentImportCubit extends PolyDecentImportCubit {
  void setTestState(PolyDecentImportState state) {
    emit(state);
  }
}
