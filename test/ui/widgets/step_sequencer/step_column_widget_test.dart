import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/ui/widgets/step_sequencer/step_column_widget.dart';

void main() {
  group('StepColumnWidget', () {
    testWidgets('displays step number correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StepColumnWidget(
              stepIndex: 0,
              pitchValue: 64,
              velocityValue: 100,
              isActive: false,
            ),
          ),
        ),
      );

      expect(find.text('1'), findsOneWidget); // 1-indexed display
    });

    testWidgets('displays pitch bar', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StepColumnWidget(
              stepIndex: 5,
              pitchValue: 64,
              velocityValue: 100,
              isActive: false,
            ),
          ),
        ),
      );

      expect(find.byType(CustomPaint), findsWidgets); // May find multiple
      expect(find.text('6'), findsOneWidget); // Step 6
    });

    testWidgets('displays velocity indicator', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StepColumnWidget(
              stepIndex: 0,
              pitchValue: 64,
              velocityValue: 100,
              isActive: false,
            ),
          ),
        ),
      );

      expect(find.text('100'), findsOneWidget); // Velocity value
    });

    testWidgets('highlights active step with border', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StepColumnWidget(
              stepIndex: 0,
              pitchValue: 64,
              velocityValue: 100,
              isActive: true,
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(find.byType(Container).first);
      final decoration = container.decoration as BoxDecoration;

      expect(decoration.border, isNotNull);
      expect(decoration.border!.top.width, equals(2.0)); // Active border width
    });

    testWidgets('uses normal border for inactive step', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StepColumnWidget(
              stepIndex: 0,
              pitchValue: 64,
              velocityValue: 100,
              isActive: false,
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(find.byType(Container).first);
      final decoration = container.decoration as BoxDecoration;

      expect(decoration.border, isNotNull);
      expect(decoration.border!.top.width, equals(1.0)); // Inactive border width
    });
  });
}
