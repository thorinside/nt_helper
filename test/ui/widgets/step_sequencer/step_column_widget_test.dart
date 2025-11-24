import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nt_helper/cubit/disting_cubit.dart';
import 'package:nt_helper/domain/disting_nt_sysex.dart';
import 'package:nt_helper/ui/widgets/step_sequencer/step_column_widget.dart';

// Mock classes
class MockDistingCubit extends Mock implements DistingCubit {}

void main() {
  late MockDistingCubit mockCubit;
  late Slot testSlot;

  setUp(() {
    mockCubit = MockDistingCubit();

    // Create test slot with mock parameters matching Step Sequencer format
    testSlot = Slot(
      algorithm: Algorithm(
        algorithmIndex: 0,
        guid: 'spsq',
        name: 'Step Sequencer',
      ),
      routing: RoutingInfo(algorithmIndex: 0, routingInfo: const []),
      pages: ParameterPages(algorithmIndex: 0, pages: const []),
      parameters: [
        ParameterInfo(
          algorithmIndex: 0,
          parameterNumber: 0,
          name: '1:Pitch',
          min: 0,
          max: 127,
          defaultValue: 60,
          unit: 0,
          powerOfTen: 0,
        ),
        ParameterInfo(
          algorithmIndex: 0,
          parameterNumber: 1,
          name: '1:Velocity',
          min: 0,
          max: 127,
          defaultValue: 64,
          unit: 0,
          powerOfTen: 0,
        ),
      ],
      values: [
        ParameterValue(algorithmIndex: 0, parameterNumber: 0, value: 64),
        ParameterValue(algorithmIndex: 0, parameterNumber: 1, value: 100),
      ],
      enums: const [],
      mappings: const [],
      valueStrings: const [],
    );
  });

  Widget makeTestableWidget(Widget child) {
    return BlocProvider<DistingCubit>.value(
      value: mockCubit,
      child: MaterialApp(
        home: Scaffold(
          body: child,
        ),
      ),
    );
  }

  group('StepColumnWidget', () {
    testWidgets('displays step number correctly', (tester) async {
      await tester.pumpWidget(
        makeTestableWidget(
          StepColumnWidget(
            stepIndex: 0,
            pitchValue: 64,
            velocityValue: 100,
            isActive: false,
            slotIndex: 0,
            slot: testSlot,
            snapEnabled: false,
            selectedScale: 'Major',
            rootNote: 0,
            activeParameter: StepParameter.pitch,
          ),
        ),
      );

      expect(find.text('1'), findsOneWidget); // 1-indexed display
    });

    testWidgets('displays pitch bar', (tester) async {
      await tester.pumpWidget(
        makeTestableWidget(
          StepColumnWidget(
            stepIndex: 5,
            pitchValue: 64,
            velocityValue: 100,
            isActive: false,
            slotIndex: 0,
            slot: testSlot,
            snapEnabled: false,
            selectedScale: 'Major',
            rootNote: 0,
            activeParameter: StepParameter.pitch,
          ),
        ),
      );

      expect(find.byType(CustomPaint), findsWidgets); // May find multiple
      expect(find.text('6'), findsOneWidget); // Step 6
    });

    testWidgets('displays formatted pitch value', (tester) async {
      await tester.pumpWidget(
        makeTestableWidget(
          StepColumnWidget(
            stepIndex: 0,
            pitchValue: 64,
            velocityValue: 100,
            isActive: false,
            slotIndex: 0,
            slot: testSlot,
            snapEnabled: false,
            selectedScale: 'Major',
            rootNote: 0,
            activeParameter: StepParameter.pitch,
          ),
        ),
      );

      // Pitch values are formatted as note names (e.g., "E4")
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('displays bit pattern editor in Ties mode', (tester) async {
      // Add Ties parameter to test slot
      testSlot = Slot(
        algorithm: Algorithm(
          algorithmIndex: 0,
          guid: 'spsq',
          name: 'Step Sequencer',
        ),
        routing: RoutingInfo(algorithmIndex: 0, routingInfo: const []),
        pages: ParameterPages(algorithmIndex: 0, pages: const []),
        parameters: [
          ParameterInfo(
            algorithmIndex: 0,
            parameterNumber: 0,
            name: '1:Pitch',
            min: 0,
            max: 127,
            defaultValue: 60,
            unit: 0,
            powerOfTen: 0,
          ),
          ParameterInfo(
            algorithmIndex: 0,
            parameterNumber: 1,
            name: '1:Velocity',
            min: 0,
            max: 127,
            defaultValue: 64,
            unit: 0,
            powerOfTen: 0,
          ),
          ParameterInfo(
            algorithmIndex: 0,
            parameterNumber: 2,
            name: '1:Ties',
            min: 0,
            max: 255,
            defaultValue: 0,
            unit: 0,
            powerOfTen: 0,
          ),
        ],
        values: [
          ParameterValue(algorithmIndex: 0, parameterNumber: 0, value: 64),
          ParameterValue(algorithmIndex: 0, parameterNumber: 1, value: 100),
          ParameterValue(algorithmIndex: 0, parameterNumber: 2, value: 170), // 0b10101010
        ],
        enums: const [],
        mappings: const [],
        valueStrings: const [],
      );

      await tester.pumpWidget(
        makeTestableWidget(
          StepColumnWidget(
            stepIndex: 0,
            pitchValue: 64,
            velocityValue: 100,
            isActive: false,
            slotIndex: 0,
            slot: testSlot,
            snapEnabled: false,
            selectedScale: 'Major',
            rootNote: 0,
            activeParameter: StepParameter.ties,
          ),
        ),
      );

      // In Ties mode, the bar should be displayed with bit pattern visualization
      expect(find.byType(CustomPaint), findsWidgets);

      // Verify bit pattern editor shows on tap
      await tester.tap(find.byType(CustomPaint).first);
      await tester.pumpAndSettle();

      expect(find.text('Edit Ties Bit Pattern'), findsOneWidget);
    });

    testWidgets('displays bit pattern editor in Pattern mode', (tester) async {
      // Add Pattern parameter to test slot
      testSlot = Slot(
        algorithm: Algorithm(
          algorithmIndex: 0,
          guid: 'spsq',
          name: 'Step Sequencer',
        ),
        routing: RoutingInfo(algorithmIndex: 0, routingInfo: const []),
        pages: ParameterPages(algorithmIndex: 0, pages: const []),
        parameters: [
          ParameterInfo(
            algorithmIndex: 0,
            parameterNumber: 0,
            name: '1:Pitch',
            min: 0,
            max: 127,
            defaultValue: 60,
            unit: 0,
            powerOfTen: 0,
          ),
          ParameterInfo(
            algorithmIndex: 0,
            parameterNumber: 1,
            name: '1:Velocity',
            min: 0,
            max: 127,
            defaultValue: 64,
            unit: 0,
            powerOfTen: 0,
          ),
          ParameterInfo(
            algorithmIndex: 0,
            parameterNumber: 2,
            name: '1:Pattern',
            min: 0,
            max: 255,
            defaultValue: 0,
            unit: 0,
            powerOfTen: 0,
          ),
          ParameterInfo(
            algorithmIndex: 0,
            parameterNumber: 3,
            name: '1:Division',
            min: 0,
            max: 14,
            defaultValue: 0,
            unit: 0,
            powerOfTen: 0,
          ),
        ],
        values: [
          ParameterValue(algorithmIndex: 0, parameterNumber: 0, value: 64),
          ParameterValue(algorithmIndex: 0, parameterNumber: 1, value: 100),
          ParameterValue(algorithmIndex: 0, parameterNumber: 2, value: 10), // 0b00001010 (bits 1 and 3 set)
          ParameterValue(algorithmIndex: 0, parameterNumber: 3, value: 3), // Division = 3 (4 substeps)
        ],
        enums: const [],
        mappings: const [],
        valueStrings: const [],
      );

      await tester.pumpWidget(
        makeTestableWidget(
          StepColumnWidget(
            stepIndex: 0,
            pitchValue: 64,
            velocityValue: 100,
            isActive: false,
            slotIndex: 0,
            slot: testSlot,
            snapEnabled: false,
            selectedScale: 'Major',
            rootNote: 0,
            activeParameter: StepParameter.pattern,
          ),
        ),
      );

      // In Pattern mode, the bar should be displayed with bit pattern visualization
      expect(find.byType(CustomPaint), findsWidgets);

      // Verify bit pattern editor shows on tap
      await tester.tap(find.byType(CustomPaint).first);
      await tester.pumpAndSettle();

      expect(find.text('Edit Pattern Bit Pattern'), findsOneWidget);
      // Verify help text for Pattern semantics
      expect(
        find.textContaining('substep plays'),
        findsWidgets,
      );
    });

    testWidgets('highlights active step with border', (tester) async {
      await tester.pumpWidget(
        makeTestableWidget(
          StepColumnWidget(
            stepIndex: 0,
            pitchValue: 64,
            velocityValue: 100,
            isActive: true,
            slotIndex: 0,
            slot: testSlot,
            snapEnabled: false,
            selectedScale: 'Major',
            rootNote: 0,
            activeParameter: StepParameter.pitch,
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
        makeTestableWidget(
          StepColumnWidget(
            stepIndex: 0,
            pitchValue: 64,
            velocityValue: 100,
            isActive: false,
            slotIndex: 0,
            slot: testSlot,
            snapEnabled: false,
            selectedScale: 'Major',
            rootNote: 0,
            activeParameter: StepParameter.pitch,
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
