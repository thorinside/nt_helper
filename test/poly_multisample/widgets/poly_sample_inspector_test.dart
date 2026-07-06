import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

    final rootRow = _byStableKey('poly-sidebar-mapping-root-row');
    expect(
      find.descendant(of: rootRow, matching: find.text('Root')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: rootRow, matching: find.text('C3')),
      findsOneWidget,
    );
    final velocityRow = _byStableKey('poly-sidebar-mapping-velocity-row');
    expect(
      find.descendant(of: velocityRow, matching: find.text('Velocity')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: velocityRow, matching: find.text('1')),
      findsOneWidget,
    );
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
    expect(
      find.descendant(
        of: _byStableKey('poly-sidebar-mapping-root-row'),
        matching: find.text('C#3'),
      ),
      findsOneWidget,
    );
  });

  testWidgets(
    'mapping stepper geometry stays fixed across value width changes',
    (tester) async {
      final cubit = _TestPolyMultisampleBuilderCubit();
      addTearDown(cubit.close);
      final base = _selectedState();
      cubit.setTestState(
        base.copyWith(
          editedRegions: [
            base.editedRegions.first.copyWith(
              rootMidi: 48,
              rootName: 'C3',
              velocityLayer: 9,
              roundRobin: 9,
            ),
            base.editedRegions[1],
          ],
        ),
      );

      await _pumpInspector(tester, cubit);
      final before = <String, Rect>{
        for (final key in [
          'poly-sidebar-mapping-root-increase',
          'poly-sidebar-mapping-velocity-increase',
          'poly-sidebar-mapping-round-robin-increase',
          'poly-sidebar-mapping-root-row',
          'poly-sidebar-mapping-velocity-row',
          'poly-sidebar-mapping-round-robin-row',
        ])
          key: _stableRect(tester, key),
      };

      await tester.tap(_byStableKey('poly-sidebar-mapping-root-increase'));
      await tester.pump();
      await tester.tap(_byStableKey('poly-sidebar-mapping-velocity-increase'));
      await tester.pump();
      await tester.tap(
        _byStableKey('poly-sidebar-mapping-round-robin-increase'),
      );
      await tester.pump();

      expect(cubit.state.editedRegions.first.rootMidi, 49);
      expect(cubit.state.editedRegions.first.velocityLayer, 10);
      expect(cubit.state.editedRegions.first.roundRobin, 10);
      for (final entry in before.entries) {
        _expectStableRect(entry.value, _stableRect(tester, entry.key));
      }
    },
  );

  testWidgets(
    'mapping stepper focus and rect stay stable after keyboard activation',
    (tester) async {
      final cubit = _TestPolyMultisampleBuilderCubit();
      addTearDown(cubit.close);
      cubit.setTestState(_selectedState());

      await _pumpInspector(tester, cubit);
      final finder = _byStableKey('poly-sidebar-mapping-velocity-increase');
      await tester.tap(finder);
      await tester.pump();
      for (var i = 0; i < 20 && !_primaryFocusWithin(tester, finder); i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
      }
      expect(_primaryFocusWithin(tester, finder), isTrue);
      final focusBefore = FocusManager.instance.primaryFocus;
      expect(focusBefore, isNotNull);
      final rectBefore = _stableRect(
        tester,
        'poly-sidebar-mapping-velocity-increase',
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();

      expect(cubit.state.editedRegions.first.velocityLayer, 3);
      expect(FocusManager.instance.primaryFocus, same(focusBefore));
      _expectStableRect(
        rectBefore,
        _stableRect(tester, 'poly-sidebar-mapping-velocity-increase'),
      );
    },
  );

  testWidgets('mapping stepper auto-previews when enabled', (tester) async {
    final adapter = _FakePreviewAdapter();
    final previewService = PolyAudioPreviewService(adapter: adapter);
    final cubit = _TestPolyMultisampleBuilderCubit(
      previewService: previewService,
    );
    addTearDown(cubit.close);
    cubit.setTestState(_selectedState(autoPreview: true));

    await _pumpInspector(tester, cubit);
    await tester.tap(find.byTooltip('Increase Root'));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump();

    expect(adapter.playedPaths, ['/tmp/Piano/Piano_C3.wav']);
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

  testWidgets(
    'waveform nudge geometry stays fixed across frame digit changes',
    (tester) async {
      final cubit = _TestPolyMultisampleBuilderCubit();
      addTearDown(cubit.close);
      cubit.setTestState(
        _selectedState().copyWith(
          waveformSummaries: {'/tmp/Piano/Piano_C3.wav': _overview()},
          loopDrafts: const {
            '/tmp/Piano/Piano_C3.wav': PolyWaveformDraft(
              loopStart: 99,
              loopEnd: 900,
            ),
          },
          wavEditDrafts: const {
            '/tmp/Piano/Piano_C3.wav': PolyWaveformDraft(
              trimStart: 99,
              trimEnd: 900,
            ),
          },
        ),
      );

      await _pumpInspector(tester, cubit);
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        _byStableKey('poly-sidebar-frame-loop-start-plus1'),
        300,
      );
      final loopBefore = <String, Rect>{
        for (final key in [
          'poly-sidebar-frame-loop-start-row',
          'poly-sidebar-frame-loop-start-plus1',
          'poly-sidebar-frame-loop-end-minus1',
        ])
          key: _stableRect(tester, key),
      };

      await tester.tap(_byStableKey('poly-sidebar-frame-loop-start-plus1'));
      await tester.pump();

      for (final entry in loopBefore.entries) {
        _expectStableRect(entry.value, _stableRect(tester, entry.key));
      }

      await tester.scrollUntilVisible(
        _byStableKey('poly-sidebar-frame-trim-start-plus1'),
        300,
      );
      final trimBefore = <String, Rect>{
        for (final key in [
          'poly-sidebar-frame-trim-start-row',
          'poly-sidebar-frame-trim-start-plus1',
          'poly-sidebar-frame-trim-end-minus1',
        ])
          key: _stableRect(tester, key),
      };

      await tester.tap(_byStableKey('poly-sidebar-frame-trim-start-plus1'));
      await tester.pump();

      for (final entry in trimBefore.entries) {
        _expectStableRect(entry.value, _stableRect(tester, entry.key));
      }
      expect(cubit.state.loopDrafts['/tmp/Piano/Piano_C3.wav']!.loopStart, 100);
      expect(
        cubit.state.wavEditDrafts['/tmp/Piano/Piano_C3.wav']!.trimStart,
        100,
      );
    },
  );

  testWidgets(
    'waveform slider geometry stays fixed across gain and peak value changes',
    (tester) async {
      final cubit = _TestPolyMultisampleBuilderCubit();
      addTearDown(cubit.close);
      cubit.setTestState(
        _selectedState().copyWith(
          waveformSummaries: {'/tmp/Piano/Piano_C3.wav': _overview()},
          wavEditDrafts: const {
            '/tmp/Piano/Piano_C3.wav': PolyWaveformDraft(
              gainDb: 9.9,
              normalizePeakDb: -9.9,
            ),
          },
        ),
      );

      await _pumpInspector(tester, cubit);
      await tester.scrollUntilVisible(
        _byStableKey('poly-wav-gain-slider'),
        300,
      );
      final gainSliderBefore = _stableRect(tester, 'poly-wav-gain-slider');
      final gainValueBefore = _stableRect(
        tester,
        'poly-sidebar-wav-gain-value',
      );

      cubit.updateWavEditDraft(
        '/tmp/Piano/Piano_C3.wav',
        const PolyWaveformDraft(gainDb: 10.0, normalizePeakDb: -10.0),
      );
      await tester.pump();

      _expectStableRect(
        gainSliderBefore,
        _stableRect(tester, 'poly-wav-gain-slider'),
      );
      _expectStableRect(
        gainValueBefore,
        _stableRect(tester, 'poly-sidebar-wav-gain-value'),
      );

      await tester.scrollUntilVisible(
        _byStableKey('poly-sidebar-normalize-peak-slider'),
        300,
      );
      final peakSliderBefore = _stableRect(
        tester,
        'poly-sidebar-normalize-peak-slider',
      );
      final peakValueBefore = _stableRect(
        tester,
        'poly-sidebar-normalize-peak-value',
      );

      cubit.updateWavEditDraft(
        '/tmp/Piano/Piano_C3.wav',
        const PolyWaveformDraft(gainDb: 10.0, normalizePeakDb: -0.3),
      );
      await tester.pump();

      _expectStableRect(
        peakSliderBefore,
        _stableRect(tester, 'poly-sidebar-normalize-peak-slider'),
      );
      _expectStableRect(
        peakValueBefore,
        _stableRect(tester, 'poly-sidebar-normalize-peak-value'),
      );
    },
  );

  testWidgets(
    'fade geometry stays fixed across curve and strength value changes',
    (tester) async {
      final cubit = _TestPolyMultisampleBuilderCubit();
      addTearDown(cubit.close);
      cubit.setTestState(
        _selectedState().copyWith(
          waveformSummaries: {'/tmp/Piano/Piano_C3.wav': _overview()},
          wavEditDrafts: const {
            '/tmp/Piano/Piano_C3.wav': PolyWaveformDraft(
              fadeInFrames: 441,
              fadeInCurve: WavFadeCurve.linear,
              fadeInStrength: 0.95,
            ),
          },
        ),
      );

      await _pumpInspector(tester, cubit);
      await tester.scrollUntilVisible(
        _byStableKey('poly-sidebar-fade-in-curve-dropdown'),
        300,
      );
      final before = <String, Rect>{
        for (final key in [
          'poly-sidebar-fade-in-curve-dropdown',
          'poly-sidebar-fade-in-strength-row',
          'poly-sidebar-fade-in-strength-value',
        ])
          key: _stableRect(tester, key),
      };

      cubit.updateWavEditDraft(
        '/tmp/Piano/Piano_C3.wav',
        const PolyWaveformDraft(
          fadeInFrames: 882,
          fadeInCurve: WavFadeCurve.equalPower,
          fadeInStrength: 1.0,
        ),
      );
      await tester.pump();

      for (final entry in before.entries) {
        _expectStableRect(entry.value, _stableRect(tester, entry.key));
      }
    },
  );

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
    expect(find.bySemanticsLabel('Preview gain value'), findsOneWidget);
    expect(find.bySemanticsLabel('Root value'), findsOneWidget);
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
    expect(find.bySemanticsLabel('Audio gain value'), findsOneWidget);
    expect(find.bySemanticsLabel('Normalize peak value'), findsOneWidget);
    expect(find.bySemanticsLabel('Fade in length'), findsOneWidget);
    expect(find.bySemanticsLabel('Fade in strength'), findsOneWidget);
    expect(find.bySemanticsLabel('Fade in length value'), findsOneWidget);
    expect(find.bySemanticsLabel('Fade in strength value'), findsOneWidget);

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

PolyMultisampleBuilderState _selectedState({bool autoPreview = false}) {
  return PolyMultisampleBuilderState(
    sourceMode: PolySampleSourceMode.local,
    status: PolyMultisampleLoadStatus.ready,
    autoPreview: autoPreview,
    currentInstrument: const PolySampleInstrument(
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
    editedRegions: const [
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
    selectedPaths: const {'/tmp/Piano/Piano_C3.wav'},
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
  _TestPolyMultisampleBuilderCubit({PolyAudioPreviewService? previewService})
    : super(
        previewService:
            previewService ??
            PolyAudioPreviewService(adapter: _FakePreviewAdapter()),
      );

  void setTestState(PolyMultisampleBuilderState state) {
    emit(state);
  }
}

Finder _byStableKey(String value) => find.byKey(ValueKey(value));

Rect _stableRect(WidgetTester tester, String value) {
  return tester.getRect(_byStableKey(value));
}

void _expectStableRect(Rect before, Rect after) {
  expect(after.topLeft, before.topLeft);
  expect(after.size, before.size);
}

bool _primaryFocusWithin(WidgetTester tester, Finder finder) {
  final root = tester.element(finder);
  final focusedContext = FocusManager.instance.primaryFocus?.context;
  if (focusedContext is! Element) return false;
  if (focusedContext == root) return true;
  var found = false;
  focusedContext.visitAncestorElements((ancestor) {
    if (ancestor == root) {
      found = true;
      return false;
    }
    return true;
  });
  return found;
}

class _FakePreviewAdapter implements PolyAudioPreviewAdapter {
  final playedPaths = <String>[];

  @override
  Stream<void> get completed => const Stream.empty();

  @override
  Future<void> play(String path, {required double volume}) async {
    playedPaths.add(path);
  }

  @override
  Future<void> stop() async {}

  @override
  Future<void> dispose() async {}
}
