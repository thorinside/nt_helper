import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/models/flash_progress.dart';
import 'package:nt_helper/models/flash_stage.dart';
import 'package:nt_helper/ui/firmware/firmware_flow_diagram.dart';

Future<void> _pump(
  WidgetTester tester, {
  required FlashProgress progress,
  bool reduceMotion = false,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: reduceMotion),
        child: Scaffold(
          body: Center(
            child: SizedBox(
              width: 600,
              height: 150,
              child: FirmwareFlowDiagram(progress: progress),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 16));
}

void main() {
  group('FirmwareFlowDiagram', () {
    testWidgets(
        'renders at the documented 600x150 size for every FlashStage without throwing',
        (tester) async {
      for (final stage in FlashStage.values) {
        await _pump(
          tester,
          progress: FlashProgress(stage: stage, percent: 50, message: ''),
        );

        expect(tester.takeException(), isNull,
            reason: 'should not throw for stage $stage');

        final paintFinder = find.descendant(
          of: find.byType(FirmwareFlowDiagram),
          matching: find.byType(CustomPaint),
        );
        expect(paintFinder, findsWidgets,
            reason: 'CustomPaint should be present for stage $stage');

        final size =
            tester.getSize(find.byType(FirmwareFlowDiagram));
        expect(size, const Size(600, 150),
            reason: 'widget should fill its 600x150 container for stage $stage');
      }
    });

    testWidgets('renders the error variant without overflow', (tester) async {
      await _pump(
        tester,
        progress: FlashProgress(
          stage: FlashStage.write,
          percent: 75,
          message: 'flashing',
          isError: true,
        ),
      );

      expect(tester.takeException(), isNull);
      expect(
        tester.getSize(find.byType(FirmwareFlowDiagram)),
        const Size(600, 150),
      );
    });

    testWidgets('renders the reduced-motion (static) variant',
        (tester) async {
      await _pump(
        tester,
        progress: FlashProgress(
          stage: FlashStage.sdpUpload,
          percent: 25,
          message: '',
        ),
        reduceMotion: true,
      );

      expect(tester.takeException(), isNull);
      expect(
        tester.getSize(find.byType(FirmwareFlowDiagram)),
        const Size(600, 150),
      );
    });
  });
}
