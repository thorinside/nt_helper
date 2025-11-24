import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/cubit/disting_cubit.dart';
import 'package:nt_helper/domain/disting_nt_sysex.dart';
import 'package:nt_helper/services/step_sequencer_params.dart';

void main() {
  group('StepSequencerParams - AC1: Parameter Discovery Validation', () {
    late Slot testSlot;

    setUp(() {
      // Create test slot with all 10 parameter types for 2 steps (to keep test small)
      testSlot = Slot(
        algorithm: Algorithm(
          algorithmIndex: 0,
          guid: 'spsq',
          name: 'Step Sequencer',
        ),
        routing: RoutingInfo(algorithmIndex: 0, routingInfo: const []),
        pages: ParameterPages(algorithmIndex: 0, pages: const []),
        parameters: [
          // Step 1 parameters
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
            min: 1,
            max: 127,
            defaultValue: 64,
            unit: 0,
            powerOfTen: 0,
          ),
          ParameterInfo(
            algorithmIndex: 0,
            parameterNumber: 2,
            name: '1:Mod',
            min: 0,
            max: 127,
            defaultValue: 64,
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
          ParameterInfo(
            algorithmIndex: 0,
            parameterNumber: 4,
            name: '1:Pattern',
            min: 0,
            max: 255,
            defaultValue: 0,
            unit: 0,
            powerOfTen: 0,
          ),
          ParameterInfo(
            algorithmIndex: 0,
            parameterNumber: 5,
            name: '1:Ties',
            min: 0,
            max: 255,
            defaultValue: 0,
            unit: 0,
            powerOfTen: 0,
          ),
          // Step 2 parameters
          ParameterInfo(
            algorithmIndex: 0,
            parameterNumber: 6,
            name: '2:Pitch',
            min: 0,
            max: 127,
            defaultValue: 60,
            unit: 0,
            powerOfTen: 0,
          ),
          ParameterInfo(
            algorithmIndex: 0,
            parameterNumber: 7,
            name: '2:Velocity',
            min: 1,
            max: 127,
            defaultValue: 64,
            unit: 0,
            powerOfTen: 0,
          ),
          // Global parameters
          ParameterInfo(
            algorithmIndex: 0,
            parameterNumber: 8,
            name: 'Direction',
            min: 0,
            max: 6,
            defaultValue: 0,
            unit: 0,
            powerOfTen: 0,
          ),
          ParameterInfo(
            algorithmIndex: 0,
            parameterNumber: 9,
            name: 'Start',
            min: 1,
            max: 16,
            defaultValue: 1,
            unit: 0,
            powerOfTen: 0,
          ),
          ParameterInfo(
            algorithmIndex: 0,
            parameterNumber: 10,
            name: 'End',
            min: 1,
            max: 16,
            defaultValue: 16,
            unit: 0,
            powerOfTen: 0,
          ),
        ],
        values: [
          ParameterValue(algorithmIndex: 0, parameterNumber: 0, value: 60),
          ParameterValue(algorithmIndex: 0, parameterNumber: 1, value: 64),
          ParameterValue(algorithmIndex: 0, parameterNumber: 2, value: 64),
          ParameterValue(algorithmIndex: 0, parameterNumber: 3, value: 0),
          ParameterValue(algorithmIndex: 0, parameterNumber: 4, value: 255),
          ParameterValue(algorithmIndex: 0, parameterNumber: 5, value: 0),
          ParameterValue(algorithmIndex: 0, parameterNumber: 6, value: 62),
          ParameterValue(algorithmIndex: 0, parameterNumber: 7, value: 80),
          ParameterValue(algorithmIndex: 0, parameterNumber: 8, value: 0),
          ParameterValue(algorithmIndex: 0, parameterNumber: 9, value: 1),
          ParameterValue(algorithmIndex: 0, parameterNumber: 10, value: 16),
        ],
        enums: const [],
        mappings: const [],
        valueStrings: const [],
      );
    });

    test('discovers correct number of steps from parameter names', () {
      final params = StepSequencerParams.fromSlot(testSlot);
      expect(params.numSteps, equals(2));
    });

    test('discovers all per-step Pitch parameters', () {
      final params = StepSequencerParams.fromSlot(testSlot);
      expect(params.getPitch(1), equals(0));
      expect(params.getPitch(2), equals(6));
      expect(params.getPitch(3), isNull); // Not in test data
    });

    test('discovers all per-step Velocity parameters', () {
      final params = StepSequencerParams.fromSlot(testSlot);
      expect(params.getVelocity(1), equals(1));
      expect(params.getVelocity(2), equals(7));
      expect(params.getVelocity(3), isNull);
    });

    test('discovers all per-step Mod parameters', () {
      final params = StepSequencerParams.fromSlot(testSlot);
      expect(params.getMod(1), equals(2));
      expect(params.getMod(3), isNull);
    });

    test('discovers all per-step Division parameters', () {
      final params = StepSequencerParams.fromSlot(testSlot);
      expect(params.getDivision(1), equals(3));
      expect(params.getDivision(3), isNull);
    });

    test('discovers all per-step Pattern parameters', () {
      final params = StepSequencerParams.fromSlot(testSlot);
      expect(params.getPattern(1), equals(4));
      expect(params.getPattern(3), isNull);
    });

    test('discovers all per-step Ties parameters', () {
      final params = StepSequencerParams.fromSlot(testSlot);
      expect(params.getTies(1), equals(5));
      expect(params.getTies(3), isNull);
    });

    test('discovers global Direction parameter', () {
      final params = StepSequencerParams.fromSlot(testSlot);
      expect(params.direction, equals(8));
    });

    test('discovers global Start Step parameter', () {
      final params = StepSequencerParams.fromSlot(testSlot);
      expect(params.startStep, equals(9));
    });

    test('discovers global End Step parameter', () {
      final params = StepSequencerParams.fromSlot(testSlot);
      expect(params.endStep, equals(10));
    });

    test('returns null for missing parameters', () {
      final params = StepSequencerParams.fromSlot(testSlot);
      expect(params.getStepParam(99, 'Pitch'), isNull);
      expect(params.gateLength, isNull); // Not in test slot
    });
  });

  group('StepSequencerParams - Parameter Range Validation', () {
    late Slot testSlot;

    setUp(() {
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
            min: 1,
            max: 127,
            defaultValue: 64,
            unit: 0,
            powerOfTen: 0,
          ),
          ParameterInfo(
            algorithmIndex: 0,
            parameterNumber: 2,
            name: '1:Division',
            min: 0,
            max: 14,
            defaultValue: 0,
            unit: 0,
            powerOfTen: 0,
          ),
          ParameterInfo(
            algorithmIndex: 0,
            parameterNumber: 3,
            name: '1:Pattern',
            min: 0,
            max: 255,
            defaultValue: 0,
            unit: 0,
            powerOfTen: 0,
          ),
        ],
        values: [
          ParameterValue(algorithmIndex: 0, parameterNumber: 0, value: 64),
          ParameterValue(algorithmIndex: 0, parameterNumber: 1, value: 64),
          ParameterValue(algorithmIndex: 0, parameterNumber: 2, value: 7),
          ParameterValue(algorithmIndex: 0, parameterNumber: 3, value: 255),
        ],
        enums: const [],
        mappings: const [],
        valueStrings: const [],
      );
    });

    test('Pitch parameter has correct min/max range (0-127)', () {
      expect(testSlot.parameters[0].min, equals(0));
      expect(testSlot.parameters[0].max, equals(127));
    });

    test('Velocity parameter has correct min/max range (1-127)', () {
      expect(testSlot.parameters[1].min, equals(1));
      expect(testSlot.parameters[1].max, equals(127));
    });

    test('Division parameter has correct min/max range (0-14)', () {
      expect(testSlot.parameters[2].min, equals(0));
      expect(testSlot.parameters[2].max, equals(14));
    });

    test('Pattern and Ties parameters have correct min/max range (0-255)', () {
      expect(testSlot.parameters[3].min, equals(0));
      expect(testSlot.parameters[3].max, equals(255));
    });
  });

  group('StepSequencerParams - Edge Cases', () {
    test('handles empty parameter list', () {
      final testSlot = Slot(
        algorithm: Algorithm(
          algorithmIndex: 0,
          guid: 'spsq',
          name: 'Step Sequencer',
        ),
        routing: RoutingInfo(algorithmIndex: 0, routingInfo: const []),
        pages: ParameterPages(algorithmIndex: 0, pages: const []),
        parameters: const [],
        values: const [],
        enums: const [],
        mappings: const [],
        valueStrings: const [],
      );

      final params = StepSequencerParams.fromSlot(testSlot);
      expect(params.numSteps, equals(16)); // Default when no params found
    });

    test('handles maximum step count discovery', () {
      final testSlot = Slot(
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
            name: '16:Pitch',
            min: 0,
            max: 127,
            defaultValue: 60,
            unit: 0,
            powerOfTen: 0,
          ),
        ],
        values: [
          ParameterValue(algorithmIndex: 0, parameterNumber: 0, value: 60),
        ],
        enums: const [],
        mappings: const [],
        valueStrings: const [],
      );

      final params = StepSequencerParams.fromSlot(testSlot);
      expect(params.numSteps, equals(16));
    });
  });

  group('StepSequencerParams - AC1: Probability Parameter Discovery', () {
    late Slot testSlot;

    setUp(() {
      // Create test slot with probability parameters for steps 1 and 2
      testSlot = Slot(
        algorithm: Algorithm(
          algorithmIndex: 0,
          guid: 'spsq',
          name: 'Step Sequencer',
        ),
        routing: RoutingInfo(algorithmIndex: 0, routingInfo: const []),
        pages: ParameterPages(algorithmIndex: 0, pages: const []),
        parameters: [
          // Step 1 probability parameters
          ParameterInfo(
            algorithmIndex: 0,
            parameterNumber: 0,
            name: '1:Mute',
            min: 0,
            max: 127,
            defaultValue: 0,
            unit: 0,
            powerOfTen: 0,
          ),
          ParameterInfo(
            algorithmIndex: 0,
            parameterNumber: 1,
            name: '1:Skip',
            min: 0,
            max: 127,
            defaultValue: 0,
            unit: 0,
            powerOfTen: 0,
          ),
          ParameterInfo(
            algorithmIndex: 0,
            parameterNumber: 2,
            name: '1:Reset',
            min: 0,
            max: 127,
            defaultValue: 0,
            unit: 0,
            powerOfTen: 0,
          ),
          ParameterInfo(
            algorithmIndex: 0,
            parameterNumber: 3,
            name: '1:Repeat',
            min: 0,
            max: 127,
            defaultValue: 0,
            unit: 0,
            powerOfTen: 0,
          ),
          // Step 2 probability parameters
          ParameterInfo(
            algorithmIndex: 0,
            parameterNumber: 4,
            name: '2:Mute',
            min: 0,
            max: 127,
            defaultValue: 0,
            unit: 0,
            powerOfTen: 0,
          ),
          ParameterInfo(
            algorithmIndex: 0,
            parameterNumber: 5,
            name: '2:Skip',
            min: 0,
            max: 127,
            defaultValue: 0,
            unit: 0,
            powerOfTen: 0,
          ),
          ParameterInfo(
            algorithmIndex: 0,
            parameterNumber: 6,
            name: '2:Reset',
            min: 0,
            max: 127,
            defaultValue: 0,
            unit: 0,
            powerOfTen: 0,
          ),
          ParameterInfo(
            algorithmIndex: 0,
            parameterNumber: 7,
            name: '2:Repeat',
            min: 0,
            max: 127,
            defaultValue: 0,
            unit: 0,
            powerOfTen: 0,
          ),
        ],
        values: [
          ParameterValue(algorithmIndex: 0, parameterNumber: 0, value: 0),
          ParameterValue(algorithmIndex: 0, parameterNumber: 1, value: 0),
          ParameterValue(algorithmIndex: 0, parameterNumber: 2, value: 0),
          ParameterValue(algorithmIndex: 0, parameterNumber: 3, value: 0),
          ParameterValue(algorithmIndex: 0, parameterNumber: 4, value: 0),
          ParameterValue(algorithmIndex: 0, parameterNumber: 5, value: 0),
          ParameterValue(algorithmIndex: 0, parameterNumber: 6, value: 0),
          ParameterValue(algorithmIndex: 0, parameterNumber: 7, value: 0),
        ],
        enums: const [],
        mappings: const [],
        valueStrings: const [],
      );
    });

    test('discovers Mute parameter for each step', () {
      final params = StepSequencerParams.fromSlot(testSlot);
      expect(params.getMute(1), equals(0));
      expect(params.getMute(2), equals(4));
    });

    test('discovers Skip parameter for each step', () {
      final params = StepSequencerParams.fromSlot(testSlot);
      expect(params.getSkip(1), equals(1));
      expect(params.getSkip(2), equals(5));
    });

    test('discovers Reset parameter for each step', () {
      final params = StepSequencerParams.fromSlot(testSlot);
      expect(params.getReset(1), equals(2));
      expect(params.getReset(2), equals(6));
    });

    test('discovers Repeat parameter for each step', () {
      final params = StepSequencerParams.fromSlot(testSlot);
      expect(params.getRepeat(1), equals(3));
      expect(params.getRepeat(2), equals(7));
    });

    test('returns null for missing probability parameters', () {
      final params = StepSequencerParams.fromSlot(testSlot);
      // Step 3 has no parameters
      expect(params.getMute(3), isNull);
      expect(params.getSkip(3), isNull);
      expect(params.getReset(3), isNull);
      expect(params.getRepeat(3), isNull);
    });
  });
}
