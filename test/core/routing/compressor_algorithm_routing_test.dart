import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/core/routing/compressor_algorithm_routing.dart';
import 'package:nt_helper/core/routing/models/port.dart';
import 'package:nt_helper/cubit/disting_cubit.dart';
import 'package:nt_helper/domain/disting_nt_sysex.dart';

void main() {
  group('CompressorAlgorithmRouting.canHandle', () {
    test('returns true for comp guid', () {
      final slot = _createCompressorSlot();
      expect(CompressorAlgorithmRouting.canHandle(slot), isTrue);
    });

    test('returns false for non-comp guid', () {
      final algorithm = Algorithm(algorithmIndex: 0, guid: 'mixr', name: 'X');
      final slot = Slot(
        algorithm: algorithm,
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
      expect(CompressorAlgorithmRouting.canHandle(slot), isFalse);
    });
  });

  group('CompressorAlgorithmRouting virtual outputs', () {
    test('Left/mono input on bus 5 produces virtual replace output on bus 5',
        () {
      final slot = _createCompressorSlot(
        leftBus: 5,
        rightBus: 0,
        sidechainBus: 0,
      );

      final routing = CompressorAlgorithmRouting.createFromSlot(
        slot,
        ioParameters: const {},
        algorithmUuid: 'comp_test',
      );

      final leftIn = routing.inputPorts.firstWhere(
        (p) => p.name == '1:Left/mono input',
      );
      expect(leftIn.busValue, equals(5));

      final virtualOuts = routing.outputPorts
          .where((p) => p.busValue == 5 && p.outputMode == OutputMode.replace)
          .toList();
      expect(
        virtualOuts,
        isNotEmpty,
        reason: 'Left/mono input should get a virtual replace output on bus 5',
      );
    });

    test('Right input on bus 6 produces virtual replace output on bus 6', () {
      final slot = _createCompressorSlot(
        leftBus: 5,
        rightBus: 6,
        sidechainBus: 0,
      );

      final routing = CompressorAlgorithmRouting.createFromSlot(
        slot,
        ioParameters: const {},
        algorithmUuid: 'comp_test',
      );

      final rightVirtuals = routing.outputPorts
          .where((p) => p.busValue == 6 && p.outputMode == OutputMode.replace)
          .toList();
      expect(
        rightVirtuals,
        isNotEmpty,
        reason: 'Right input should get a virtual replace output on bus 6',
      );
    });

    test('Right input on bus 0 produces no virtual output', () {
      final slot = _createCompressorSlot(
        leftBus: 5,
        rightBus: 0,
        sidechainBus: 0,
      );

      final routing = CompressorAlgorithmRouting.createFromSlot(
        slot,
        ioParameters: const {},
        algorithmUuid: 'comp_test',
      );

      // No virtual output should reference a Right input
      final rightVirtual = routing.outputPorts.where(
        (p) =>
            p.name.toLowerCase().contains('right') &&
            p.outputMode == OutputMode.replace,
      );
      expect(rightVirtual, isEmpty);
    });

    test('Sidechain input does not get a virtual output', () {
      final slot = _createCompressorSlot(
        leftBus: 5,
        rightBus: 0,
        sidechainBus: 7,
      );

      final routing = CompressorAlgorithmRouting.createFromSlot(
        slot,
        ioParameters: const {},
        algorithmUuid: 'comp_test',
      );

      // Sidechain input port should exist
      final sidechainIn = routing.inputPorts.firstWhere(
        (p) => p.name.toLowerCase().contains('sidechain'),
      );
      expect(sidechainIn.busValue, equals(7));

      // No virtual output on bus 7 (where sidechain is)
      final virtualOnSidechainBus = routing.outputPorts.where(
        (p) => p.busValue == 7 && p.outputMode == OutputMode.replace,
      );
      expect(
        virtualOnSidechainBus,
        isEmpty,
        reason: 'Sidechain input must not produce a virtual output',
      );
    });

    test('Reduction output is preserved as a normal output port', () {
      final slot = _createCompressorSlot(
        leftBus: 5,
        rightBus: 0,
        sidechainBus: 0,
        reductionOutputBus: 13,
        reductionMode: 1, // Replace
      );

      final routing = CompressorAlgorithmRouting.createFromSlot(
        slot,
        ioParameters: const {},
        algorithmUuid: 'comp_test',
      );

      final reduction = routing.outputPorts.firstWhere(
        (p) => p.name == '1:Reduction output',
      );
      expect(reduction.busValue, equals(13));
      expect(reduction.outputMode, equals(OutputMode.replace));
      expect(reduction.modeParameterNumber, isNotNull);
    });
  });
}

/// Creates a single-channel Compressor slot with configurable bus values.
Slot _createCompressorSlot({
  int leftBus = 5,
  int rightBus = 0,
  int sidechainBus = 0,
  int reductionOutputBus = 0,
  int reductionMode = 0,
}) {
  final algorithm = Algorithm(
    algorithmIndex: 0,
    guid: 'comp',
    name: 'Compressor',
  );

  final routing = RoutingInfo(
    algorithmIndex: 0,
    routingInfo: List.filled(6, 0),
  );

  final pages = ParameterPages(algorithmIndex: 0, pages: []);

  // Single channel "1:" with three inputs + reduction output + reduction mode
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
      ioFlags: 1, // isInput
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
      ioFlags: 1, // isInput
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
      ioFlags: 1, // isInput
    ),
    ParameterInfo(
      algorithmIndex: 0,
      parameterNumber: 3,
      min: 0,
      max: 28,
      defaultValue: reductionOutputBus,
      unit: 1,
      name: '1:Reduction output',
      powerOfTen: 0,
      ioFlags: 2, // isOutput
    ),
    ParameterInfo(
      algorithmIndex: 0,
      parameterNumber: 4,
      min: 0,
      max: 1,
      defaultValue: reductionMode,
      unit: 1,
      name: '1:Reduction mode',
      powerOfTen: 0,
      ioFlags: 8, // isOutputMode
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

  final enums = [
    ParameterEnumStrings(
      algorithmIndex: 0,
      parameterNumber: 4,
      values: const ['Add', 'Replace'],
    ),
  ];

  return Slot(
    algorithm: algorithm,
    routing: routing,
    pages: pages,
    parameters: parameters,
    values: values,
    enums: enums,
    mappings: const [],
    valueStrings: const [],
    outputModeMap: const {
      4: [3],
    },
  );
}
