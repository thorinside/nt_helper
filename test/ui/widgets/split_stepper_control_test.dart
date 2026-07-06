import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/ui/widgets/split_stepper_control.dart';

void main() {
  testWidgets(
    'compact split stepper renders two semantic buttons and fires callbacks',
    (tester) async {
      final semantics = tester.ensureSemantics();
      var decrementCount = 0;
      var incrementCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SplitStepperControl(
                label: 'Root',
                valueLabel: 'C3',
                onDecrement: () => decrementCount++,
                onIncrement: () => incrementCount++,
              ),
            ),
          ),
        ),
      );

      expect(find.byTooltip('Decrease Root'), findsOneWidget);
      expect(find.byTooltip('Increase Root'), findsOneWidget);
      expect(find.bySemanticsLabel('Root'), findsOneWidget);
      expect(tester.getSemantics(find.bySemanticsLabel('Root')).value, 'C3');
      expect(
        tester
            .getSemantics(find.bySemanticsLabel('Decrease Root'))
            .getSemanticsData()
            .hasAction(SemanticsAction.tap),
        isTrue,
      );

      await tester.tap(find.byTooltip('Decrease Root'));
      await tester.tap(find.byTooltip('Increase Root'));

      expect(decrementCount, 1);
      expect(incrementCount, 1);
      semantics.dispose();
    },
  );

  testWidgets('large and small split stepper renders four ordered actions', (
    tester,
  ) async {
    final deltas = <int>[];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SplitStepperControl.largeAndSmall(
              label: 'Trim start',
              valueLabel: '400 frames',
              smallStepLabel: '1',
              largeStepLabel: '100',
              smallStepSemanticsLabel: '1 frame',
              largeStepSemanticsLabel: '100 frames',
              onLargeDecrement: () => deltas.add(-100),
              onSmallDecrement: () => deltas.add(-1),
              onSmallIncrement: () => deltas.add(1),
              onLargeIncrement: () => deltas.add(100),
            ),
          ),
        ),
      ),
    );

    expect(find.text('−100'), findsOneWidget);
    expect(find.text('−1'), findsOneWidget);
    expect(find.text('+1'), findsOneWidget);
    expect(find.text('+100'), findsOneWidget);
    expect(find.byTooltip('Decrease Trim start by 100 frames'), findsOneWidget);
    expect(find.byTooltip('Decrease Trim start by 1 frame'), findsOneWidget);
    expect(find.byTooltip('Increase Trim start by 1 frame'), findsOneWidget);
    expect(find.byTooltip('Increase Trim start by 100 frames'), findsOneWidget);

    await tester.tap(find.byTooltip('Decrease Trim start by 100 frames'));
    await tester.tap(find.byTooltip('Decrease Trim start by 1 frame'));
    await tester.tap(find.byTooltip('Increase Trim start by 1 frame'));
    await tester.tap(find.byTooltip('Increase Trim start by 100 frames'));

    expect(deltas, [-100, -1, 1, 100]);
  });

  testWidgets('split stepper supports keyboard focus activation', (
    tester,
  ) async {
    var decrementCount = 0;
    var incrementCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SplitStepperControl(
              label: 'Root',
              valueLabel: 'C3',
              onDecrement: () => decrementCount++,
              onIncrement: () => incrementCount++,
            ),
          ),
        ),
      ),
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);

    expect(decrementCount, 1);
    expect(incrementCount, 1);
  });
}
