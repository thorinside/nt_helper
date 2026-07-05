import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/poly_multisample/poly_audio_preview_service.dart';
import 'package:nt_helper/poly_multisample/poly_multisample_models.dart';
import 'package:nt_helper/ui/poly_multisample/poly_multisample_builder_cubit.dart';
import 'package:nt_helper/ui/poly_multisample/widgets/poly_sample_inspector.dart';

void main() {
  testWidgets('shows mapping steppers for the selected sample', (tester) async {
    final cubit = _TestPolyMultisampleBuilderCubit();
    addTearDown(cubit.close);
    cubit.setTestState(_selectedState());

    await _pumpInspector(tester, cubit);

    expect(find.text('Root: C3'), findsOneWidget);
    expect(find.text('Velocity: 1'), findsOneWidget);
    expect(find.byTooltip('Increase Root'), findsOneWidget);
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

  testWidgets('loop editing gated for hardware paths', (tester) async {
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
    await tester.tap(find.text('Loop points'));
    await tester.pumpAndSettle();

    expect(
      find.text('Loop editing needs a local or mounted folder.'),
      findsOneWidget,
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
