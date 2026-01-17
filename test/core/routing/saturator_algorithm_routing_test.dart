import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/cubit/disting_cubit.dart';
import 'package:nt_helper/core/routing/models/port.dart';
import 'package:nt_helper/core/routing/saturator_algorithm_routing.dart';
import 'package:nt_helper/domain/disting_nt_sysex.dart';

void main() {
  group('SaturatorAlgorithmRouting.canHandle', () {
    test('returns true for Saturator algorithm', () {
      final slot = _createSaturatorSlot();
      expect(SaturatorAlgorithmRouting.canHandle(slot), true);
    });

    test('returns false for non-Saturator algorithm', () {
      final slot = _createNonSaturatorSlot();
      expect(SaturatorAlgorithmRouting.canHandle(slot), false);
    });
  });

  group('SaturatorAlgorithmRouting Port Generation (Mono)', () {
    test('generates 1 input and 1 output port for width=1', () {
      final slot = _createSaturatorSlot(
        channelConfigs: [(channel: 1, input: 5, width: 1)],
      );

      final routing = SaturatorAlgorithmRouting.createFromSlot(
        slot,
        ioParameters: {},
        algorithmUuid: 'satu_test',
      );

      // Should have 1 input port
      expect(routing.inputPorts.length, equals(1));
      final inputPort = routing.inputPorts[0];
      expect(inputPort.name, equals('1:Input'));
      expect(inputPort.busValue, equals(5));
      expect(inputPort.direction, equals(PortDirection.input));

      // Should have 1 output port
      expect(routing.outputPorts.length, equals(1));
      final outputPort = routing.outputPorts[0];
      expect(outputPort.name, equals('1:Output'));
      expect(outputPort.busValue, equals(5));
      expect(outputPort.direction, equals(PortDirection.output));
      expect(outputPort.outputMode, equals(OutputMode.replace));
    });

    test('output port has same busValue as input port', () {
      final slot = _createSaturatorSlot(
        channelConfigs: [(channel: 1, input: 10, width: 1)],
      );

      final routing = SaturatorAlgorithmRouting.createFromSlot(
        slot,
        ioParameters: {},
        algorithmUuid: 'satu_test',
      );

      final inputPort = routing.inputPorts[0];
      final outputPort = routing.outputPorts[0];

      expect(outputPort.busValue, equals(inputPort.busValue));
      expect(outputPort.busValue, equals(10));
    });

    test('output port always has OutputMode.replace', () {
      final slot = _createSaturatorSlot(
        channelConfigs: [(channel: 1, input: 7, width: 1)],
      );

      final routing = SaturatorAlgorithmRouting.createFromSlot(
        slot,
        ioParameters: {},
        algorithmUuid: 'satu_test',
      );

      final outputPort = routing.outputPorts[0];
      expect(outputPort.outputMode, equals(OutputMode.replace));
    });
  });

  group('SaturatorAlgorithmRouting Port Generation (Width)', () {
    test('generates 3 input and 3 output ports for width=3', () {
      final slot = _createSaturatorSlot(
        channelConfigs: [(channel: 1, input: 5, width: 3)],
      );

      final routing = SaturatorAlgorithmRouting.createFromSlot(
        slot,
        ioParameters: {},
        algorithmUuid: 'satu_test',
      );

      // Should have 3 input ports
      expect(routing.inputPorts.length, equals(3));

      // Verify input port names and bus values
      expect(routing.inputPorts[0].name, equals('1:Input 1'));
      expect(routing.inputPorts[0].busValue, equals(5));

      expect(routing.inputPorts[1].name, equals('1:Input 2'));
      expect(routing.inputPorts[1].busValue, equals(6));

      expect(routing.inputPorts[2].name, equals('1:Input 3'));
      expect(routing.inputPorts[2].busValue, equals(7));

      // Should have 3 output ports
      expect(routing.outputPorts.length, equals(3));

      // Verify output port names and bus values
      expect(routing.outputPorts[0].name, equals('1:Output 1'));
      expect(routing.outputPorts[0].busValue, equals(5));
      expect(routing.outputPorts[0].outputMode, equals(OutputMode.replace));

      expect(routing.outputPorts[1].name, equals('1:Output 2'));
      expect(routing.outputPorts[1].busValue, equals(6));
      expect(routing.outputPorts[1].outputMode, equals(OutputMode.replace));

      expect(routing.outputPorts[2].name, equals('1:Output 3'));
      expect(routing.outputPorts[2].busValue, equals(7));
      expect(routing.outputPorts[2].outputMode, equals(OutputMode.replace));
    });

    test('width=1 produces single port without numeric suffix', () {
      final slot = _createSaturatorSlot(
        channelConfigs: [(channel: 1, input: 8, width: 1)],
      );

      final routing = SaturatorAlgorithmRouting.createFromSlot(
        slot,
        ioParameters: {},
        algorithmUuid: 'satu_test',
      );

      // Should have 1 input and 1 output
      expect(routing.inputPorts.length, equals(1));
      expect(routing.outputPorts.length, equals(1));

      // Names should NOT have numeric suffix
      expect(routing.inputPorts[0].name, equals('1:Input'));
      expect(routing.outputPorts[0].name, equals('1:Output'));
    });

    test('consecutive bus values for width > 1', () {
      final slot = _createSaturatorSlot(
        channelConfigs: [(channel: 1, input: 10, width: 4)],
      );

      final routing = SaturatorAlgorithmRouting.createFromSlot(
        slot,
        ioParameters: {},
        algorithmUuid: 'satu_test',
      );

      // Verify consecutive bus values: 10, 11, 12, 13
      for (int i = 0; i < 4; i++) {
        expect(routing.inputPorts[i].busValue, equals(10 + i));
        expect(routing.outputPorts[i].busValue, equals(10 + i));
      }
    });

    test('all output ports have replace mode for width > 1', () {
      final slot = _createSaturatorSlot(
        channelConfigs: [(channel: 1, input: 5, width: 5)],
      );

      final routing = SaturatorAlgorithmRouting.createFromSlot(
        slot,
        ioParameters: {},
        algorithmUuid: 'satu_test',
      );

      // All 5 outputs should have replace mode
      for (final outputPort in routing.outputPorts) {
        expect(outputPort.outputMode, equals(OutputMode.replace));
      }
    });
  });

  group('SaturatorAlgorithmRouting Port Generation (Multi-Channel)', () {
    test('generates ports for 2 channels with different widths', () {
      final slot = _createSaturatorSlot(
        channelConfigs: [
          (channel: 1, input: 5, width: 2),
          (channel: 2, input: 10, width: 1),
        ],
      );

      final routing = SaturatorAlgorithmRouting.createFromSlot(
        slot,
        ioParameters: {},
        algorithmUuid: 'satu_test',
      );

      // Channel 1: width=2 → 2 input + 2 output ports
      // Channel 2: width=1 → 1 input + 1 output port
      // Total: 3 inputs, 3 outputs
      expect(routing.inputPorts.length, equals(3));
      expect(routing.outputPorts.length, equals(3));

      // Verify channel 1 ports (width=2, buses 5-6)
      expect(routing.inputPorts[0].name, equals('1:Input 1'));
      expect(routing.inputPorts[0].busValue, equals(5));

      expect(routing.inputPorts[1].name, equals('1:Input 2'));
      expect(routing.inputPorts[1].busValue, equals(6));

      expect(routing.outputPorts[0].name, equals('1:Output 1'));
      expect(routing.outputPorts[0].busValue, equals(5));

      expect(routing.outputPorts[1].name, equals('1:Output 2'));
      expect(routing.outputPorts[1].busValue, equals(6));

      // Verify channel 2 ports (width=1, bus 10)
      expect(routing.inputPorts[2].name, equals('2:Input'));
      expect(routing.inputPorts[2].busValue, equals(10));

      expect(routing.outputPorts[2].name, equals('2:Output'));
      expect(routing.outputPorts[2].busValue, equals(10));
    });

    test('handles 3 channels with varying widths', () {
      final slot = _createSaturatorSlot(
        channelConfigs: [
          (channel: 1, input: 1, width: 1),
          (channel: 2, input: 5, width: 3),
          (channel: 3, input: 15, width: 2),
        ],
      );

      final routing = SaturatorAlgorithmRouting.createFromSlot(
        slot,
        ioParameters: {},
        algorithmUuid: 'satu_test',
      );

      // Total: 1 + 3 + 2 = 6 inputs and 6 outputs
      expect(routing.inputPorts.length, equals(6));
      expect(routing.outputPorts.length, equals(6));

      // Verify channel prefixes are correct
      expect(routing.inputPorts[0].name, equals('1:Input'));
      expect(routing.inputPorts[1].name, equals('2:Input 1'));
      expect(routing.inputPorts[2].name, equals('2:Input 2'));
      expect(routing.inputPorts[3].name, equals('2:Input 3'));
      expect(routing.inputPorts[4].name, equals('3:Input 1'));
      expect(routing.inputPorts[5].name, equals('3:Input 2'));
    });

    test('each channel processes independently with its own width', () {
      final slot = _createSaturatorSlot(
        channelConfigs: [
          (channel: 1, input: 3, width: 4),
          (channel: 2, input: 20, width: 2),
        ],
      );

      final routing = SaturatorAlgorithmRouting.createFromSlot(
        slot,
        ioParameters: {},
        algorithmUuid: 'satu_test',
      );

      // Channel 1: buses 3, 4, 5, 6
      expect(routing.inputPorts[0].busValue, equals(3));
      expect(routing.inputPorts[1].busValue, equals(4));
      expect(routing.inputPorts[2].busValue, equals(5));
      expect(routing.inputPorts[3].busValue, equals(6));

      // Channel 2: buses 20, 21
      expect(routing.inputPorts[4].busValue, equals(20));
      expect(routing.inputPorts[5].busValue, equals(21));

      // Verify outputs match inputs
      for (int i = 0; i < routing.inputPorts.length; i++) {
        expect(
          routing.outputPorts[i].busValue,
          equals(routing.inputPorts[i].busValue),
        );
      }
    });
  });
}

Slot _createSaturatorSlot({
  List<({int channel, int input, int width})> channelConfigs = const [],
  int algorithmIndex = 0,
}) {
  final algorithm = Algorithm(
    algorithmIndex: algorithmIndex,
    guid: 'satu',
    name: 'Saturator',
  );

  final routing = RoutingInfo(
    algorithmIndex: algorithmIndex,
    routingInfo: List.filled(6, 0),
  );

  final pages = ParameterPages(algorithmIndex: algorithmIndex, pages: []);

  final parameters = <ParameterInfo>[];
  final values = <ParameterValue>[];

  int paramNum = 0;

  // Create parameters for each channel
  for (final config in channelConfigs) {
    final channel = config.channel;
    final inputParamNum = paramNum++;
    final widthParamNum = paramNum++;

    // Create Input parameter
    parameters.add(
      ParameterInfo(
        algorithmIndex: algorithmIndex,
        parameterNumber: inputParamNum,
        name: '$channel:Input',
        min: 1,
        max: 28,
        defaultValue: 1,
        unit: 1,
        powerOfTen: 0,
      ),
    );

    // Create Width parameter
    parameters.add(
      ParameterInfo(
        algorithmIndex: algorithmIndex,
        parameterNumber: widthParamNum,
        name: '$channel:Width',
        min: 1,
        max: 12,
        defaultValue: 1,
        unit: 1,
        powerOfTen: 0,
      ),
    );

    // Create values
    values.add(
      ParameterValue(
        algorithmIndex: algorithmIndex,
        parameterNumber: inputParamNum,
        value: config.input,
      ),
    );

    values.add(
      ParameterValue(
        algorithmIndex: algorithmIndex,
        parameterNumber: widthParamNum,
        value: config.width,
      ),
    );
  }

  return Slot(
    algorithm: algorithm,
    routing: routing,
    pages: pages,
    parameters: parameters,
    values: values,
    enums: const [],
    mappings: const [],
    valueStrings: const [],
  );
}

Slot _createNonSaturatorSlot() {
  final algorithm = Algorithm(algorithmIndex: 0, guid: 'mixr', name: 'Mixer');

  final routing = RoutingInfo(
    algorithmIndex: 0,
    routingInfo: List.filled(6, 0),
  );

  final pages = ParameterPages(algorithmIndex: 0, pages: []);

  return Slot(
    algorithm: algorithm,
    routing: routing,
    pages: pages,
    parameters: const [],
    values: const [],
    enums: const [],
    mappings: const [],
    valueStrings: const [],
  );
}
