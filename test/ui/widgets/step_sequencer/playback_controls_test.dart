import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/cubit/disting_cubit.dart' show Slot;
import 'package:nt_helper/domain/disting_nt_sysex.dart';
import 'package:nt_helper/services/step_sequencer_params.dart';

void main() {
  late Slot testSlot;
  late StepSequencerParams params;

  setUp(() {
    // Create test slot with global playback parameters
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
          name: 'Direction',
          min: 0,
          max: 6,
          defaultValue: 0,
          unit: 0,
          powerOfTen: 0,
        ),
        ParameterInfo(
          algorithmIndex: 0,
          parameterNumber: 1,
          name: 'Start',
          min: 1,
          max: 16,
          defaultValue: 1,
          unit: 0,
          powerOfTen: 0,
        ),
        ParameterInfo(
          algorithmIndex: 0,
          parameterNumber: 2,
          name: 'End',
          min: 1,
          max: 16,
          defaultValue: 16,
          unit: 0,
          powerOfTen: 0,
        ),
        ParameterInfo(
          algorithmIndex: 0,
          parameterNumber: 3,
          name: 'Gate length',
          min: 1,
          max: 127,
          defaultValue: 50,
          unit: 0,
          powerOfTen: 0,
        ),
        ParameterInfo(
          algorithmIndex: 0,
          parameterNumber: 4,
          name: 'Trigger length',
          min: 1,
          max: 100,
          defaultValue: 10,
          unit: 0,
          powerOfTen: 0,
        ),
        ParameterInfo(
          algorithmIndex: 0,
          parameterNumber: 5,
          name: 'Glide',
          min: 0,
          max: 127,
          defaultValue: 0,
          unit: 0,
          powerOfTen: 0,
        ),
      ],
      values: [
        ParameterValue(algorithmIndex: 0, parameterNumber: 0, value: 0),
        ParameterValue(algorithmIndex: 0, parameterNumber: 1, value: 1),
        ParameterValue(algorithmIndex: 0, parameterNumber: 2, value: 16),
        ParameterValue(algorithmIndex: 0, parameterNumber: 3, value: 50),
        ParameterValue(algorithmIndex: 0, parameterNumber: 4, value: 10),
        ParameterValue(algorithmIndex: 0, parameterNumber: 5, value: 0),
      ],
      enums: const [],
      mappings: const [],
      valueStrings: const [],
    );

    params = StepSequencerParams.fromSlot(testSlot);
  });

  group('PlaybackControls - AC6: Global Parameter Controls Discovery', () {
    test('discovers Direction parameter correctly', () {
      expect(params.direction, isNotNull);
      expect(params.direction, equals(0));
    });

    test('discovers Start Step parameter correctly', () {
      expect(params.startStep, isNotNull);
      expect(params.startStep, equals(1));
    });

    test('discovers End Step parameter correctly', () {
      expect(params.endStep, isNotNull);
      expect(params.endStep, equals(2));
    });

    test('discovers Gate Length parameter correctly', () {
      expect(params.gateLength, isNotNull);
      expect(params.gateLength, equals(3));
    });

    test('discovers Trigger Length parameter correctly', () {
      expect(params.triggerLength, isNotNull);
      expect(params.triggerLength, equals(4));
    });

    test('discovers Glide parameter correctly', () {
      expect(params.glideTime, isNotNull);
      expect(params.glideTime, equals(5));
    });

    test('Direction parameter has correct value range (0-6)', () {
      final directionParam = testSlot.parameters[0];
      expect(directionParam.min, equals(0));
      expect(directionParam.max, equals(6));
    });

    test('Start/End Step parameters have correct value range (1-16)', () {
      final startParam = testSlot.parameters[1];
      final endParam = testSlot.parameters[2];
      expect(startParam.min, equals(1));
      expect(startParam.max, equals(16));
      expect(endParam.min, equals(1));
      expect(endParam.max, equals(16));
    });

    test('Gate Length parameter has correct value range (1-127)', () {
      final gateLengthParam = testSlot.parameters[3];
      expect(gateLengthParam.min, equals(1));
      expect(gateLengthParam.max, equals(127));
    });

    test('Trigger Length parameter has correct value range (1-100)', () {
      final triggerLengthParam = testSlot.parameters[4];
      expect(triggerLengthParam.min, equals(1));
      expect(triggerLengthParam.max, equals(100));
    });

    test('Glide Time parameter has correct value range (0-127)', () {
      final glideParam = testSlot.parameters[5];
      expect(glideParam.min, equals(0));
      expect(glideParam.max, equals(127));
    });

    test('handles missing global parameters gracefully', () {
      // Create slot with no Direction parameter
      final slotNoDirection = Slot(
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
            name: 'Start',
            min: 1,
            max: 16,
            defaultValue: 1,
            unit: 0,
            powerOfTen: 0,
          ),
        ],
        values: [
          ParameterValue(algorithmIndex: 0, parameterNumber: 0, value: 1),
        ],
        enums: const [],
        mappings: const [],
        valueStrings: const [],
      );

      final paramsNoDirection = StepSequencerParams.fromSlot(slotNoDirection);

      // Direction should be null when not found
      expect(paramsNoDirection.direction, isNull);
      // But Start should still be discoverable
      expect(paramsNoDirection.startStep, isNotNull);
    });
  });
}
