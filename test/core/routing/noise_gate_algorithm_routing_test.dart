import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/core/routing/models/port.dart';
import 'package:nt_helper/core/routing/noise_gate_algorithm_routing.dart';
import 'package:nt_helper/cubit/disting_cubit.dart';
import 'package:nt_helper/domain/disting_nt_sysex.dart';

void main() {
  group('NoiseGateAlgorithmRouting.canHandle', () {
    test('returns true for nsgt guid', () {
      final slot = _createNoiseGateSlot();
      expect(NoiseGateAlgorithmRouting.canHandle(slot), isTrue);
    });

    test('returns false for non-nsgt guid', () {
      final slot = Slot(
        algorithm: Algorithm(algorithmIndex: 0, guid: 'comp', name: 'Comp'),
        routing: RoutingInfo(
          algorithmIndex: 0,
          routingInfo: List.filled(6, 0),
        ),
        pages: ParameterPages(algorithmIndex: 0, pages: []),
        parameters: const [],
        values: const [],
        enums: const [],
        mappings: const [],
        valueStrings: const [],
      );
      expect(NoiseGateAlgorithmRouting.canHandle(slot), isFalse);
    });
  });

  group('NoiseGateAlgorithmRouting virtual outputs', () {
    test('Left and Right inputs produce virtual replace outputs on same bus',
        () {
      final slot = _createNoiseGateSlot(
        leftBus: 3,
        rightBus: 4,
        sidechainBus: 0,
      );

      final routing = NoiseGateAlgorithmRouting.createFromSlot(
        slot,
        ioParameters: const {},
        algorithmUuid: 'nsgt_test',
      );

      final leftIn = routing.inputPorts.firstWhere(
        (p) => p.name == '1:Left/mono input',
      );
      final rightIn = routing.inputPorts.firstWhere(
        (p) => p.name == '1:Right input',
      );
      expect(leftIn.busValue, equals(3));
      expect(rightIn.busValue, equals(4));

      final bus3Virtuals = routing.outputPorts
          .where((p) => p.busValue == 3 && p.outputMode == OutputMode.replace)
          .toList();
      final bus4Virtuals = routing.outputPorts
          .where((p) => p.busValue == 4 && p.outputMode == OutputMode.replace)
          .toList();
      expect(bus3Virtuals, isNotEmpty);
      expect(bus4Virtuals, isNotEmpty);
    });

    test('Sidechain input does not get a virtual output', () {
      final slot = _createNoiseGateSlot(
        leftBus: 3,
        rightBus: 0,
        sidechainBus: 8,
      );

      final routing = NoiseGateAlgorithmRouting.createFromSlot(
        slot,
        ioParameters: const {},
        algorithmUuid: 'nsgt_test',
      );

      final virtualOnSidechainBus = routing.outputPorts.where(
        (p) => p.busValue == 8 && p.outputMode == OutputMode.replace,
      );
      expect(virtualOnSidechainBus, isEmpty);
    });

    test('Noise gate has no Reduction output port', () {
      final slot = _createNoiseGateSlot(
        leftBus: 3,
        rightBus: 0,
        sidechainBus: 0,
      );

      final routing = NoiseGateAlgorithmRouting.createFromSlot(
        slot,
        ioParameters: const {},
        algorithmUuid: 'nsgt_test',
      );

      final reductionPorts = routing.outputPorts.where(
        (p) => p.name.toLowerCase().contains('reduction'),
      );
      expect(reductionPorts, isEmpty);
    });

    test('Right input on bus 0 produces no virtual output', () {
      final slot = _createNoiseGateSlot(
        leftBus: 3,
        rightBus: 0,
        sidechainBus: 0,
      );

      final routing = NoiseGateAlgorithmRouting.createFromSlot(
        slot,
        ioParameters: const {},
        algorithmUuid: 'nsgt_test',
      );

      final rightVirtual = routing.outputPorts.where(
        (p) =>
            p.name.toLowerCase().contains('right') &&
            p.outputMode == OutputMode.replace,
      );
      expect(rightVirtual, isEmpty);
    });
  });
}

Slot _createNoiseGateSlot({
  int leftBus = 3,
  int rightBus = 0,
  int sidechainBus = 0,
}) {
  final algorithm = Algorithm(
    algorithmIndex: 0,
    guid: 'nsgt',
    name: 'Noise gate',
  );

  final routing = RoutingInfo(
    algorithmIndex: 0,
    routingInfo: List.filled(6, 0),
  );

  final pages = ParameterPages(algorithmIndex: 0, pages: []);

  final parameters = [
    ParameterInfo(
      algorithmIndex: 0,
      parameterNumber: 0,
      min: 0,
      max: 28,
      defaultValue: leftBus,
      unit: 1,
      name: '1:Left/mono input',
      powerOfTen: 0,
      ioFlags: 1,
    ),
    ParameterInfo(
      algorithmIndex: 0,
      parameterNumber: 1,
      min: 0,
      max: 28,
      defaultValue: rightBus,
      unit: 1,
      name: '1:Right input',
      powerOfTen: 0,
      ioFlags: 1,
    ),
    ParameterInfo(
      algorithmIndex: 0,
      parameterNumber: 2,
      min: 0,
      max: 28,
      defaultValue: sidechainBus,
      unit: 1,
      name: '1:Sidechain input',
      powerOfTen: 0,
      ioFlags: 1,
    ),
  ];

  final values = parameters
      .map(
        (p) => ParameterValue(
          algorithmIndex: 0,
          parameterNumber: p.parameterNumber,
          value: p.defaultValue,
        ),
      )
      .toList();

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
