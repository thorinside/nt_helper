import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/poly_multisample/poly_audio_preview_service.dart';
import 'package:nt_helper/poly_multisample/poly_multisample_models.dart';
import 'package:nt_helper/poly_multisample/wav_metadata.dart';
import 'package:nt_helper/ui/poly_multisample/poly_multisample_builder_cubit.dart';
import 'package:nt_helper/ui/poly_multisample/widgets/poly_sample_inspector.dart';
import 'package:nt_helper/ui/poly_multisample/widgets/poly_waveform_editor.dart';

void main() {
  testWidgets('shows mapping steppers for the selected sample', (tester) async {
    final cubit = _TestPolyMultisampleBuilderCubit();
    addTearDown(cubit.close);
    cubit.setTestState(_selectedState());

    await _pumpInspector(tester, cubit);

    expect(find.text('Root: C3'), findsOneWidget);
    expect(find.text('Velocity: 1'), findsOneWidget);
    expect(find.byTooltip('Decrease Root'), findsOneWidget);
    expect(find.byTooltip('Increase Root'), findsOneWidget);
    expect(find.byTooltip('Increase Round robin'), findsOneWidget);
  });

  testWidgets('root stepper updates the cubit', (tester) async {
    final cubit = _TestPolyMultisampleBuilderCubit();
    addTearDown(cubit.close);
    cubit.setTestState(_selectedState());

    await _pumpInspector(tester, cubit);
    await tester.tap(find.byTooltip('Increase Root'));
    await tester.pump();

    expect(cubit.state.editedRegions.first.rootMidi, 49);
    expect(find.text('Root: C#3'), findsOneWidget);
  });

  testWidgets('next sample navigates selection', (tester) async {
    final cubit = _TestPolyMultisampleBuilderCubit();
    addTearDown(cubit.close);
    cubit.setTestState(_selectedState());

    await _pumpInspector(tester, cubit);
    await tester.tap(find.byTooltip('Next sample'));
    await tester.pump();

    expect(cubit.state.focusedPath, '/tmp/Piano/Piano_C4.wav');
  });

  testWidgets('shows empty message with no selection', (tester) async {
    final cubit = _TestPolyMultisampleBuilderCubit();
    addTearDown(cubit.close);
    cubit.setTestState(
      const PolyMultisampleBuilderState(
        sourceMode: PolySampleSourceMode.local,
        status: PolyMultisampleLoadStatus.ready,
      ),
    );

    await _pumpInspector(tester, cubit);

    expect(find.text('No sample selected'), findsOneWidget);
  });

  testWidgets('shows empty message when samples exist but selection is empty', (
    tester,
  ) async {
    final cubit = _TestPolyMultisampleBuilderCubit();
    addTearDown(cubit.close);
    cubit.setTestState(
      _selectedState().copyWith(
        selectedPaths: const {},
        clearFocusedPath: true,
      ),
    );

    await _pumpInspector(tester, cubit);

    expect(find.text('No sample selected'), findsOneWidget);
    expect(find.byType(PolyWaveformEditor), findsNothing);
  });

  testWidgets('waveform editing gated for hardware paths', (tester) async {
    final cubit = _TestPolyMultisampleBuilderCubit();
    addTearDown(cubit.close);
    cubit.setTestState(
      const PolyMultisampleBuilderState(
        sourceMode: PolySampleSourceMode.hardware,
        status: PolyMultisampleLoadStatus.ready,
        editedRegions: [
          PolySampleRegion(
            path: '/samples/Piano/Piano_C3.wav',
            fileName: 'Piano_C3.wav',
            displayName: 'Piano_C3.wav',
            rootMidi: 48,
            rootName: 'C3',
          ),
        ],
        selectedPaths: {'/samples/Piano/Piano_C3.wav'},
        focusedPath: '/samples/Piano/Piano_C3.wav',
      ),
    );

    await _pumpInspector(tester, cubit);

    expect(
      find.text('Waveform editing needs a local or mounted WAV file.'),
      findsOneWidget,
    );
  });

  testWidgets('waveform section shows editor and save buttons', (tester) async {
    final cubit = _TestPolyMultisampleBuilderCubit();
    addTearDown(cubit.close);
    cubit.setTestState(
      _selectedState().copyWith(
        waveformSummaries: {'/tmp/Piano/Piano_C3.wav': _overview()},
      ),
    );

    await _pumpInspector(tester, cubit);
    await tester.pumpAndSettle();

    expect(find.text('Waveform'), findsOneWidget);
    expect(find.text('Editing Piano_C3.wav'), findsOneWidget);
    expect(
      find.byTooltip(
        'Click to set trim start/end. Command/Ctrl-click or right-click to set loop start/end.',
      ),
      findsOneWidget,
    );
    expect(find.byType(PolyWaveformEditor), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Save as...'), 300);
    expect(find.text('Save as...'), findsOneWidget);
    expect(find.text('Overwrite'), findsOneWidget);
  });

  testWidgets('waveform nudge buttons keep endpoints ordered', (tester) async {
    final cubit = _TestPolyMultisampleBuilderCubit();
    addTearDown(cubit.close);
    cubit.setTestState(
      _selectedState().copyWith(
        waveformSummaries: {'/tmp/Piano/Piano_C3.wav': _overview()},
        loopDrafts: const {
          '/tmp/Piano/Piano_C3.wav': PolyWaveformDraft(
            loopStart: 400,
            loopEnd: 500,
          ),
        },
        wavEditDrafts: const {
          '/tmp/Piano/Piano_C3.wav': PolyWaveformDraft(
            trimStart: 400,
            trimEnd: 500,
          ),
        },
      ),
    );

    await _pumpInspector(tester, cubit);
    await tester.scrollUntilVisible(
      find.byTooltip('Increase Loop start by 100 frames'),
      300,
    );
    await tester.tap(find.byTooltip('Increase Loop start by 100 frames'));
    await tester.pump();
    await tester.tap(find.byTooltip('Decrease Loop end by 100 frames'));
    await tester.pump();
    await tester.scrollUntilVisible(
      find.byTooltip('Increase Trim start by 100 frames'),
      300,
    );
    await tester.tap(find.byTooltip('Increase Trim start by 100 frames'));
    await tester.pump();
    await tester.tap(find.byTooltip('Decrease Trim end by 100 frames'));
    await tester.pump();

    final loopDraft = cubit.state.loopDrafts['/tmp/Piano/Piano_C3.wav']!;
    final wavDraft = cubit.state.wavEditDrafts['/tmp/Piano/Piano_C3.wav']!;
    expect(loopDraft.loopStart!, lessThan(loopDraft.loopEnd!));
    expect(wavDraft.trimStart!, lessThan(wavDraft.trimEnd!));
    expect(loopDraft.loopStart, 499);
    expect(loopDraft.loopEnd, 500);
    expect(wavDraft.trimStart, 499);
    expect(wavDraft.trimEnd, 500);
  });

  testWidgets('duplicate sample names show a disambiguated edit target', (
    tester,
  ) async {
    final cubit = _TestPolyMultisampleBuilderCubit();
    addTearDown(cubit.close);
    cubit.setTestState(
      _duplicateNameState().copyWith(
        waveformSummaries: {'/tmp/Kit/close/C4.wav': _overview()},
      ),
    );

    await _pumpInspector(tester, cubit);

    expect(find.text('Editing close/C4.wav'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.widgetWithText(FilledButton, 'Overwrite'),
      300,
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Overwrite'));
    await tester.pumpAndSettle();

    expect(find.text('Overwrite close/C4.wav?'), findsOneWidget);
  });

  testWidgets('waveform failure shows live retry status', (tester) async {
    final semantics = tester.ensureSemantics();
    final cubit = _TestPolyMultisampleBuilderCubit();
    addTearDown(cubit.close);
    cubit.setTestState(
      _selectedState().copyWith(
        waveformFailedPaths: const {'/tmp/Piano/Piano_C3.wav'},
      ),
    );

    await _pumpInspector(tester, cubit);

    expect(find.bySemanticsLabel('Waveform loading failed.'), findsOneWidget);
    expect(find.text('Retry waveform'), findsOneWidget);

    semantics.dispose();
  });

  testWidgets('labels preview and destructive edit controls for semantics', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final cubit = _TestPolyMultisampleBuilderCubit();
    addTearDown(cubit.close);
    cubit.setTestState(
      _selectedState().copyWith(
        waveformSummaries: {'/tmp/Piano/Piano_C3.wav': _overview()},
      ),
    );

    await _pumpInspector(tester, cubit);

    expect(find.bySemanticsLabel('Preview gain'), findsOneWidget);
    expect(find.bySemanticsLabel('Root'), findsOneWidget);
    expect(find.bySemanticsLabel('Decrease Root'), findsOneWidget);

    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -420),
    );
    await tester.pumpAndSettle();

    expect(
      find.bySemanticsLabel('Increase Trim start by 1 frame'),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel('Audio gain'), findsOneWidget);
    expect(find.bySemanticsLabel('Normalize peak'), findsOneWidget);
    expect(find.bySemanticsLabel('Fade in length'), findsOneWidget);
    expect(find.text('Fade in curve:'), findsOneWidget);
    expect(find.bySemanticsLabel('Fade in strength'), findsOneWidget);

    semantics.dispose();
  });

  testWidgets('gain slider updates the wav edit draft', (tester) async {
    final cubit = _TestPolyMultisampleBuilderCubit();
    addTearDown(cubit.close);
    cubit.setTestState(
      _selectedState().copyWith(
        waveformSummaries: {'/tmp/Piano/Piano_C3.wav': _overview()},
      ),
    );

    await _pumpInspector(tester, cubit);
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('poly-wav-gain-slider')),
      300,
    );
    await tester.drag(
      find.byKey(const ValueKey('poly-wav-gain-slider')),
      const Offset(120, 0),
    );
    await tester.pump();

    expect(
      cubit.state.wavEditDrafts['/tmp/Piano/Piano_C3.wav']!.gainDb,
      isNot(0),
    );
  });
}

Future<void> _pumpInspector(
  WidgetTester tester,
  PolyMultisampleBuilderCubit cubit,
) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: BlocProvider<PolyMultisampleBuilderCubit>.value(
          value: cubit,
          child:
              BlocBuilder<
                PolyMultisampleBuilderCubit,
                PolyMultisampleBuilderState
              >(
                builder: (context, state) {
                  return PolySampleInspector(state: state, manager: null);
                },
              ),
        ),
      ),
    ),
  );
}

PolyMultisampleBuilderState _selectedState() {
  return const PolyMultisampleBuilderState(
    sourceMode: PolySampleSourceMode.local,
    status: PolyMultisampleLoadStatus.ready,
    currentInstrument: PolySampleInstrument(
      name: 'Piano',
      sourcePath: '/tmp/Piano',
      regions: [
        PolySampleRegion(
          path: '/tmp/Piano/Piano_C3.wav',
          fileName: 'Piano_C3.wav',
          displayName: 'Piano_C3.wav',
          rootMidi: 48,
          rootName: 'C3',
          velocityLayer: 1,
        ),
        PolySampleRegion(
          path: '/tmp/Piano/Piano_C4.wav',
          fileName: 'Piano_C4.wav',
          displayName: 'Piano_C4.wav',
          rootMidi: 60,
          rootName: 'C4',
        ),
      ],
    ),
    editedRegions: [
      PolySampleRegion(
        path: '/tmp/Piano/Piano_C3.wav',
        fileName: 'Piano_C3.wav',
        displayName: 'Piano_C3.wav',
        rootMidi: 48,
        rootName: 'C3',
        velocityLayer: 1,
      ),
      PolySampleRegion(
        path: '/tmp/Piano/Piano_C4.wav',
        fileName: 'Piano_C4.wav',
        displayName: 'Piano_C4.wav',
        rootMidi: 60,
        rootName: 'C4',
      ),
    ],
    selectedPaths: {'/tmp/Piano/Piano_C3.wav'},
    focusedPath: '/tmp/Piano/Piano_C3.wav',
  );
}

PolyMultisampleBuilderState _duplicateNameState() {
  return const PolyMultisampleBuilderState(
    sourceMode: PolySampleSourceMode.local,
    status: PolyMultisampleLoadStatus.ready,
    currentInstrument: PolySampleInstrument(
      name: 'Kit',
      sourcePath: '/tmp/Kit',
      regions: [
        PolySampleRegion(
          path: '/tmp/Kit/close/C4.wav',
          fileName: 'C4.wav',
          displayName: 'C4.wav',
          rootMidi: 60,
          rootName: 'C4',
        ),
        PolySampleRegion(
          path: '/tmp/Kit/room/C4.wav',
          fileName: 'C4.wav',
          displayName: 'C4.wav',
          rootMidi: 60,
          rootName: 'C4',
        ),
      ],
    ),
    editedRegions: [
      PolySampleRegion(
        path: '/tmp/Kit/close/C4.wav',
        fileName: 'C4.wav',
        displayName: 'C4.wav',
        rootMidi: 60,
        rootName: 'C4',
      ),
      PolySampleRegion(
        path: '/tmp/Kit/room/C4.wav',
        fileName: 'C4.wav',
        displayName: 'C4.wav',
        rootMidi: 60,
        rootName: 'C4',
      ),
    ],
    selectedPaths: {'/tmp/Kit/close/C4.wav'},
    focusedPath: '/tmp/Kit/close/C4.wav',
  );
}

WavOverview _overview() {
  return WavOverview(
    sampleRate: 44100,
    frameCount: 1000,
    peaks: List<WavPeak>.filled(40, const WavPeak(min: -0.5, max: 0.5)),
    zeroCrossings: const [0, 250, 500, 750, 999],
  );
}

class _TestPolyMultisampleBuilderCubit extends PolyMultisampleBuilderCubit {
  _TestPolyMultisampleBuilderCubit()
    : super(
        previewService: PolyAudioPreviewService(adapter: _FakePreviewAdapter()),
      );

  void setTestState(PolyMultisampleBuilderState state) {
    emit(state);
  }
}

class _FakePreviewAdapter implements PolyAudioPreviewAdapter {
  @override
  Stream<void> get completed => const Stream.empty();

  @override
  Future<void> play(String path, {required double volume}) async {}

  @override
  Future<void> stop() async {}

  @override
  Future<void> dispose() async {}
}
