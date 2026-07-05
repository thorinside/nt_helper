import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nt_helper/cubit/disting_cubit.dart';
import 'package:nt_helper/poly_multisample/poly_audio_preview_service.dart';
import 'package:nt_helper/poly_multisample/poly_multisample_models.dart';
import 'package:nt_helper/ui/poly_multisample/poly_multisample_builder_cubit.dart';
import 'package:nt_helper/ui/poly_multisample/poly_samples_screen.dart';

class MockDistingCubit extends Mock implements DistingCubit {}

void main() {
  group('PolySamplesView', () {
    late MockDistingCubit distingCubit;

    setUp(() {
      distingCubit = MockDistingCubit();
      when(() => distingCubit.disting()).thenReturn(null);
    });

    testWidgets('does not re-announce stale success when clearing an error', (
      tester,
    ) async {
      final accessibilityMessages = <Object?>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockDecodedMessageHandler<Object?>(SystemChannels.accessibility, (
            Object? message,
          ) async {
            accessibilityMessages.add(message);
            return null;
          });
      addTearDown(() {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockDecodedMessageHandler<Object?>(
              SystemChannels.accessibility,
              null,
            );
      });
      final cubit = _TestPolyMultisampleBuilderCubit();
      addTearDown(cubit.close);

      await _pumpView(tester, cubit, distingCubit);

      cubit.setTestState(
        const PolyMultisampleBuilderState(
          status: PolyMultisampleLoadStatus.ready,
          effect: 'Saved custom sample draft.',
          effectId: 1,
        ),
      );
      await tester.pump();
      cubit.setTestState(
        const PolyMultisampleBuilderState(
          status: PolyMultisampleLoadStatus.failure,
          effect: 'Saved custom sample draft.',
          effectId: 1,
          error: 'Apply failed.',
        ),
      );
      await tester.pump();
      cubit.setTestState(
        const PolyMultisampleBuilderState(
          status: PolyMultisampleLoadStatus.loading,
          effect: 'Saved custom sample draft.',
          effectId: 1,
        ),
      );
      await tester.pump();

      final payload = accessibilityMessages.map((m) => m.toString()).join('\n');
      expect(payload, contains('Saved custom sample draft.'));
      expect(payload, contains('Apply failed.'));
      expect(
        RegExp('Saved custom sample draft.').allMatches(payload),
        hasLength(1),
      );
    });

    testWidgets('shows a hardware-specific empty folder state', (tester) async {
      final semantics = tester.ensureSemantics();
      final cubit = _TestPolyMultisampleBuilderCubit();
      addTearDown(cubit.close);
      cubit.setTestState(
        const PolyMultisampleBuilderState(
          sourceMode: PolySampleSourceMode.hardware,
          status: PolyMultisampleLoadStatus.ready,
          hardwareFolders: [],
        ),
      );

      await _pumpView(tester, cubit, distingCubit);

      expect(find.text('No sample folders found on /samples.'), findsOneWidget);
      expect(
        find.bySemanticsLabel('No sample folders found on /samples.'),
        findsOneWidget,
      );
      semantics.dispose();
    });

    testWidgets('shows landing source cards', (tester) async {
      final cubit = _TestPolyMultisampleBuilderCubit();
      addTearDown(cubit.close);

      await _pumpView(tester, cubit, distingCubit);

      expect(find.text('Samples'), findsOneWidget);
      expect(find.text('NT Hardware'), findsOneWidget);
      expect(find.text('Local Folder'), findsOneWidget);
      expect(find.text('Import Files'), findsOneWidget);
    });

    testWidgets('shows a keyboard editor with a working back button', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      final cubit = _TestPolyMultisampleBuilderCubit();
      addTearDown(cubit.close);
      cubit.setTestState(_pianoState());

      await _pumpView(tester, cubit, distingCubit);

      expect(
        find.bySemanticsLabel('Keyboard map with 1 mapped samples'),
        findsOneWidget,
      );
      expect(find.text('Root: C3'), findsOneWidget);

      await tester.tap(find.byTooltip('Back to sample sources'));
      await tester.pumpAndSettle();

      expect(
        find.text('Build or edit a Disting NT multisample folder'),
        findsOneWidget,
      );
      expect(cubit.state.currentInstrument, isNull);
      semantics.dispose();
    });

    testWidgets('pop is guarded while dirty', (tester) async {
      final cubit = _TestPolyMultisampleBuilderCubit();
      addTearDown(cubit.close);
      cubit.setTestState(_pianoState(dirty: true));

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) {
                        return BlocProvider<PolyMultisampleBuilderCubit>.value(
                          value: cubit,
                          child: PolySamplesView(distingCubit: distingCubit),
                        );
                      },
                    ),
                  );
                },
                child: const Text('Open'),
              );
            },
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await (tester.state(find.byType(Navigator)) as NavigatorState).maybePop();
      await tester.pumpAndSettle();

      expect(find.text('Discard changes?'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Samples'), findsOneWidget);
    });
  });
}

Future<void> _pumpView(
  WidgetTester tester,
  PolyMultisampleBuilderCubit cubit,
  DistingCubit distingCubit,
) async {
  await tester.pumpWidget(
    MaterialApp(
      home: BlocProvider<PolyMultisampleBuilderCubit>.value(
        value: cubit,
        child: PolySamplesView(distingCubit: distingCubit),
      ),
    ),
  );
}

PolyMultisampleBuilderState _pianoState({bool dirty = false}) {
  final baseline = dirty
      ? const [
          PolySampleRegion(
            path: '/tmp/Piano/Piano_C3.wav',
            fileName: 'Piano_C3.wav',
            displayName: 'Piano_C3.wav',
            rootMidi: 47,
            rootName: 'B2',
          ),
        ]
      : const [
          PolySampleRegion(
            path: '/tmp/Piano/Piano_C3.wav',
            fileName: 'Piano_C3.wav',
            displayName: 'Piano_C3.wav',
            rootMidi: 48,
            rootName: 'C3',
          ),
        ];
  return PolyMultisampleBuilderState(
    sourceMode: PolySampleSourceMode.local,
    status: PolyMultisampleLoadStatus.ready,
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
        ),
      ],
    ),
    baselineRegions: baseline,
    editedRegions: const [
      PolySampleRegion(
        path: '/tmp/Piano/Piano_C3.wav',
        fileName: 'Piano_C3.wav',
        displayName: 'Piano_C3.wav',
        rootMidi: 48,
        rootName: 'C3',
      ),
    ],
    selectedPaths: const {'/tmp/Piano/Piano_C3.wav'},
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
