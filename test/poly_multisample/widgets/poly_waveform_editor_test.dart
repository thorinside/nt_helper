import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/poly_multisample/wav_metadata.dart';
import 'package:nt_helper/ui/poly_multisample/widgets/poly_waveform_editor.dart';

void main() {
  testWidgets('drag near start handle emits snapped frames', (tester) async {
    int? startFrame;
    int? endFrame;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 400,
            child: PolyWaveformEditor(
              overview: _overview(),
              mode: PolyWaveformEditorMode.trim,
              startFrame: 0,
              endFrame: 999,
              onChanged: (start, end) {
                startFrame = start;
                endFrame = end;
              },
            ),
          ),
        ),
      ),
    );

    final topLeft = tester.getTopLeft(find.byType(PolyWaveformEditor));
    await tester.dragFrom(topLeft + const Offset(1, 60), const Offset(100, 0));

    expect(startFrame, isNotNull);
    expect(_overview().zeroCrossings, contains(startFrame));
    expect(startFrame!, lessThan(endFrame!));
  });

  testWidgets('has waveform editor semantics', (tester) async {
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PolyWaveformEditor(
            overview: _overview(),
            mode: PolyWaveformEditorMode.trim,
            startFrame: 0,
            endFrame: 999,
            onChanged: (_, _) {},
          ),
        ),
      ),
    );

    expect(find.bySemanticsLabel('Waveform editor'), findsOneWidget);
    semantics.dispose();
  });
}

WavOverview _overview() {
  return WavOverview(
    sampleRate: 44100,
    frameCount: 1000,
    peaks: List<WavPeak>.filled(40, const WavPeak(min: -0.5, max: 0.5)),
    zeroCrossings: const [0, 250, 500, 750, 999],
  );
}
