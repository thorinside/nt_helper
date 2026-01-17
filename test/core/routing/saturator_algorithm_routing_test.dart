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
