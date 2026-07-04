import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/poly_multisample/poly_audio_preview_service.dart';
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
            body: BlocProvider.value(
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
  });
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
