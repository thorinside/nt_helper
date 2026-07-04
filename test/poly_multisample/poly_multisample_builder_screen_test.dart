import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/poly_multisample/poly_audio_preview_service.dart';
import 'package:nt_helper/poly_multisample/poly_multisample_models.dart';
import 'package:nt_helper/ui/poly_multisample/poly_multisample_builder_cubit.dart';
import 'package:nt_helper/ui/poly_multisample/poly_multisample_builder_screen.dart';

void main() {
  group('PolyMultisampleBuilderScreen', () {
    testWidgets('shows source states and accessible empty controls', (
      tester,
    ) async {
      final cubit = PolyMultisampleBuilderCubit(
        previewService: PolyAudioPreviewService(adapter: _FakePreviewAdapter()),
      );
      addTearDown(cubit.close);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocProvider<PolyMultisampleBuilderCubit>.value(
              value: cubit,
              child: const PolyMultisampleBuilderView(),
            ),
          ),
        ),
      );

      expect(find.text('Samples'), findsOneWidget);
      expect(find.text('NT Hardware'), findsNWidgets(2));
      expect(find.text('Local'), findsNWidgets(2));
      expect(find.text('Import'), findsNWidgets(2));
      expect(find.bySemanticsLabel('Samples workspace'), findsOneWidget);
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

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocProvider<PolyMultisampleBuilderCubit>.value(
              value: cubit,
              child: const PolyMultisampleBuilderView(),
            ),
          ),
        ),
      );

      expect(find.text('No sample folders found on /samples.'), findsOneWidget);
      expect(
        find.bySemanticsLabel('No sample folders found on /samples.'),
        findsOneWidget,
      );
      semantics.dispose();
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

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocProvider<PolyMultisampleBuilderCubit>.value(
              value: cubit,
              child: const PolyMultisampleBuilderView(),
            ),
          ),
        ),
      );

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

    testWidgets('shows a simple keyboard editor with a working back button', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      final cubit = _TestPolyMultisampleBuilderCubit();
      addTearDown(cubit.close);
      cubit.setTestState(
        const PolyMultisampleBuilderState(
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
              ),
            ],
          ),
          baselineRegions: [
            PolySampleRegion(
              path: '/tmp/Piano/Piano_C3.wav',
              fileName: 'Piano_C3.wav',
              displayName: 'Piano_C3.wav',
              rootMidi: 48,
              rootName: 'C3',
            ),
          ],
          editedRegions: [
            PolySampleRegion(
              path: '/tmp/Piano/Piano_C3.wav',
              fileName: 'Piano_C3.wav',
              displayName: 'Piano_C3.wav',
              rootMidi: 48,
              rootName: 'C3',
            ),
          ],
          selectedPaths: {'/tmp/Piano/Piano_C3.wav'},
          focusedPath: '/tmp/Piano/Piano_C3.wav',
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocProvider<PolyMultisampleBuilderCubit>.value(
              value: cubit,
              child: const PolyMultisampleBuilderView(),
            ),
          ),
        ),
      );

      expect(
        find.bySemanticsLabel('Keyboard map with 1 mapped samples'),
        findsOneWidget,
      );
      expect(find.text('Root: C3'), findsOneWidget);
      expect(find.text('Piano_C3.wav'), findsWidgets);

      await tester.tap(find.byTooltip('Back to sample sources'));
      await tester.pump();

      expect(
        find.text('Build or edit a Disting NT multisample folder'),
        findsOneWidget,
      );
      expect(cubit.state.currentInstrument, isNull);
      semantics.dispose();
    });
  });
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
