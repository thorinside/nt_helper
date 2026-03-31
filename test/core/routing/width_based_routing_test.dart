import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/core/routing/multi_channel_algorithm_routing.dart';
import 'package:nt_helper/core/routing/algorithm_routing.dart';
import 'package:nt_helper/cubit/disting_cubit.dart';
import 'package:nt_helper/domain/disting_nt_sysex.dart';

void main() {
  // DJ Filter (guid: 'djfi') parameters from firmware:
  //   paramNumber 1: "Input"  ioFlags=5 (isInput|isAudio)
  //   paramNumber 2: "Width"  ioFlags=0
  //   paramNumber 3: "Output" ioFlags=6 (isOutput|isAudio)

  group('Width-based routing — DJ Filter (Width=1)', () {
    test('produces 1 input and 1 output port', () {
      final slot = _createDjFilterSlot(input: 7, width: 1, output: 13);
      final routing = _createRouting(slot);

      expect(routing.inputPorts.length, equals(1));
      expect(routing.outputPorts.length, equals(1));
    });

    test('input port has correct bus value and name', () {
      final slot = _createDjFilterSlot(input: 7, width: 1, output: 13);
      final routing = _createRouting(slot);

      expect(routing.inputPorts[0].name, equals('Input'));
      expect(routing.inputPorts[0].busValue, equals(7));
    });

    test('output port has correct bus value and name', () {
      final slot = _createDjFilterSlot(input: 7, width: 1, output: 13);
      final routing = _createRouting(slot);

      expect(routing.outputPorts[0].name, equals('Output'));
      expect(routing.outputPorts[0].busValue, equals(13));
    });
  });

  group('Width-based routing — DJ Filter (Width=2)', () {
    test('produces 2 input ports and 2 output ports', () {
      final slot = _createDjFilterSlot(input: 7, width: 2, output: 13);
      final routing = _createRouting(slot);

      expect(routing.inputPorts.length, equals(2));
      expect(routing.outputPorts.length, equals(2));
    });

    test('input ports have sequential bus values starting from Input', () {
      final slot = _createDjFilterSlot(input: 7, width: 2, output: 13);
      final routing = _createRouting(slot);

      expect(routing.inputPorts[0].busValue, equals(7));
      expect(routing.inputPorts[1].busValue, equals(8));
    });

    test('output ports have sequential bus values starting from Output', () {
      final slot = _createDjFilterSlot(input: 7, width: 2, output: 13);
      final routing = _createRouting(slot);

      expect(routing.outputPorts[0].busValue, equals(13));
      expect(routing.outputPorts[1].busValue, equals(14));
    });

    test('virtual input port has correct name suffix', () {
      final slot = _createDjFilterSlot(input: 7, width: 2, output: 13);
      final routing = _createRouting(slot);

      expect(routing.inputPorts[0].name, equals('Input'));
      expect(routing.inputPorts[1].name, equals('Input 2'));
    });

    test('virtual output port has correct name suffix', () {
      final slot = _createDjFilterSlot(input: 7, width: 2, output: 13);
      final routing = _createRouting(slot);

      expect(routing.outputPorts[0].name, equals('Output'));
      expect(routing.outputPorts[1].name, equals('Output 2'));
    });

    test('virtual ports have negative parameterNumber', () {
      final slot = _createDjFilterSlot(input: 7, width: 2, output: 13);
      final routing = _createRouting(slot);

      expect(routing.inputPorts[1].parameterNumber, lessThan(0));
      expect(routing.outputPorts[1].parameterNumber, lessThan(0));
    });

    test('original ports have non-negative parameterNumber', () {
      final slot = _createDjFilterSlot(input: 7, width: 2, output: 13);
      final routing = _createRouting(slot);

      expect(routing.inputPorts[0].parameterNumber, greaterThanOrEqualTo(0));
      expect(routing.outputPorts[0].parameterNumber, greaterThanOrEqualTo(0));
    });
  });

  group('Width-based routing — DJ Filter (Width=4)', () {
    test('produces 4 input ports and 4 output ports', () {
      final slot = _createDjFilterSlot(input: 1, width: 4, output: 13);
      final routing = _createRouting(slot);

      expect(routing.inputPorts.length, equals(4));
      expect(routing.outputPorts.length, equals(4));
    });

    test('input buses are consecutive from base', () {
      final slot = _createDjFilterSlot(input: 1, width: 4, output: 13);
      final routing = _createRouting(slot);

      for (int i = 0; i < 4; i++) {
        expect(routing.inputPorts[i].busValue, equals(1 + i));
      }
    });

    test('output buses are consecutive from base', () {
      final slot = _createDjFilterSlot(input: 1, width: 4, output: 13);
      final routing = _createRouting(slot);

      for (int i = 0; i < 4; i++) {
        expect(routing.outputPorts[i].busValue, equals(13 + i));
      }
    });
  });

  group('Width-based routing — regression: Filter Bank uses "Audio input" name', () {
    test('Filter Bank with Width=2 still produces 2 inputs and 2 outputs', () {
      final slot = _createFilterBankSlot(audioInput: 3, width: 2, output: 13);
      final routing = _createRouting(slot);

      expect(routing.inputPorts.length, equals(2));
      expect(routing.outputPorts.length, equals(2));
    });

    test('Filter Bank virtual input port name includes original name', () {
      final slot = _createFilterBankSlot(audioInput: 3, width: 2, output: 13);
      final routing = _createRouting(slot);

      expect(routing.inputPorts[0].name, equals('Audio input'));
      expect(routing.inputPorts[1].name, equals('Audio input 2'));
    });

    test('Filter Bank virtual input bus values are sequential', () {
      final slot = _createFilterBankSlot(audioInput: 3, width: 2, output: 13);
      final routing = _createRouting(slot);

      expect(routing.inputPorts[0].busValue, equals(3));
      expect(routing.inputPorts[1].busValue, equals(4));
    });
  });
}

MultiChannelAlgorithmRouting _createRouting(Slot slot) {
  final ioParameters = AlgorithmRouting.extractIOParameters(slot);
  return MultiChannelAlgorithmRouting.createFromSlot(
    slot,
    ioParameters: ioParameters,
    algorithmUuid: 'test_uuid',
  );
}

Slot _createDjFilterSlot({
  required int input,
  required int width,
  required int output,
  int algorithmIndex = 0,
}) {
  const guid = 'djfi';
  final algorithm = Algorithm(
    algorithmIndex: algorithmIndex,
    guid: guid,
    name: 'DJ Filter',
  );

  final parameters = [
    ParameterInfo(
      algorithmIndex: algorithmIndex,
      parameterNumber: 1,
      name: 'Input',
      min: 1,
      max: 64,
      defaultValue: 1,
      unit: 1,
      powerOfTen: 0,
      ioFlags: 5, // isInput | isAudio
    ),
    ParameterInfo(
      algorithmIndex: algorithmIndex,
      parameterNumber: 2,
      name: 'Width',
      min: 1,
      max: 8,
      defaultValue: 1,
      unit: 0,
      powerOfTen: 0,
      ioFlags: 0,
    ),
    ParameterInfo(
      algorithmIndex: algorithmIndex,
      parameterNumber: 3,
      name: 'Output',
      min: 1,
      max: 64,
      defaultValue: 13,
      unit: 1,
      powerOfTen: 0,
      ioFlags: 6, // isOutput | isAudio
    ),
  ];

  final values = [
    ParameterValue(
      algorithmIndex: algorithmIndex,
      parameterNumber: 1,
      value: input,
    ),
    ParameterValue(
      algorithmIndex: algorithmIndex,
      parameterNumber: 2,
      value: width,
    ),
    ParameterValue(
      algorithmIndex: algorithmIndex,
      parameterNumber: 3,
      value: output,
    ),
  ];

  return Slot(
    algorithm: algorithm,
    routing: RoutingInfo(
      algorithmIndex: algorithmIndex,
      routingInfo: List.filled(6, 0),
    ),
    pages: ParameterPages(algorithmIndex: algorithmIndex, pages: []),
    parameters: parameters,
    values: values,
    enums: const [],
    mappings: const [],
    valueStrings: const [],
  );
}

// Filter Bank (fbnk) uses "Audio input" as its input parameter name.
// This is a regression guard: the old code only worked for this name.
Slot _createFilterBankSlot({
  required int audioInput,
  required int width,
  required int output,
  int algorithmIndex = 0,
}) {
  const guid = 'fbnk';
  final algorithm = Algorithm(
    algorithmIndex: algorithmIndex,
    guid: guid,
    name: 'Filter Bank',
  );

  final parameters = [
    ParameterInfo(
      algorithmIndex: algorithmIndex,
      parameterNumber: 1,
      name: 'Audio input',
      min: 1,
      max: 64,
      defaultValue: 1,
      unit: 1,
      powerOfTen: 0,
      ioFlags: 5, // isInput | isAudio
    ),
    ParameterInfo(
      algorithmIndex: algorithmIndex,
      parameterNumber: 2,
      name: 'Width',
      min: 1,
      max: 8,
      defaultValue: 1,
      unit: 0,
      powerOfTen: 0,
      ioFlags: 0,
    ),
    ParameterInfo(
      algorithmIndex: algorithmIndex,
      parameterNumber: 3,
      name: 'Output',
      min: 0,
      max: 64,
      defaultValue: 13,
      unit: 1,
      powerOfTen: 0,
      ioFlags: 6, // isOutput | isAudio
    ),
  ];

  final values = [
    ParameterValue(
      algorithmIndex: algorithmIndex,
      parameterNumber: 1,
      value: audioInput,
    ),
    ParameterValue(
      algorithmIndex: algorithmIndex,
      parameterNumber: 2,
      value: width,
    ),
    ParameterValue(
      algorithmIndex: algorithmIndex,
      parameterNumber: 3,
      value: output,
    ),
  ];

  return Slot(
    algorithm: algorithm,
    routing: RoutingInfo(
      algorithmIndex: algorithmIndex,
      routingInfo: List.filled(6, 0),
    ),
    pages: ParameterPages(algorithmIndex: algorithmIndex, pages: []),
    parameters: parameters,
    values: values,
    enums: const [],
    mappings: const [],
    valueStrings: const [],
  );
}
