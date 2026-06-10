import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/core/routing/compressor_algorithm_routing.dart';
import 'package:nt_helper/core/routing/models/port.dart';
import 'package:nt_helper/cubit/disting_cubit.dart';
import 'package:nt_helper/domain/disting_nt_sysex.dart';

void main() {
  group('CompressorAlgorithmRouting.canHandle', () {
    test('returns true for Compressor algorithm', () {
      expect(CompressorAlgorithmRouting.canHandle(_compSlot()), isTrue);
    });

    test('returns false for other algorithms', () {
      expect(
        CompressorAlgorithmRouting.canHandle(_slotWithGuid('nsgt')),
        isFalse,
      );
    });
  });

  group('NoiseGateAlgorithmRouting.canHandle', () {
    test('returns true for Noise Gate algorithm', () {
      expect(NoiseGateAlgorithmRouting.canHandle(_nsgtSlot()), isTrue);
    });

    test('returns false for other algorithms', () {
      expect(
        NoiseGateAlgorithmRouting.canHandle(_slotWithGuid('comp')),
        isFalse,
      );
    });
  });

  group('CompressorAlgorithmRouting port generation', () {
    test('Left/mono input with busValue=5 → virtual output on bus 5, Replace',
        () {
      final slot = _compSlot(
        leftBus: 5,
        rightBus: 0,
        sidechainBus: 0,
        reductionBus: 0,
      );
      final routing = CompressorAlgorithmRouting.createFromSlot(
        slot,
        ioParameters: {},
        algorithmUuid: 'comp_t',
      );

      expect(routing.inputPorts.any((p) => p.busValue == 5), isTrue);
      final virtualOut = routing.outputPorts.firstWhere(
        (p) => p.busValue == 5,
        orElse: () => throw Exception('No virtual output on bus 5'),
      );
      expect(virtualOut.outputMode, equals(OutputMode.replace));
      expect(virtualOut.modeParameterNumber, isNull);
      expect(virtualOut.busParam, isNull);
    });

    test('Right input with busValue=6 → virtual output on bus 6', () {
      final slot = _compSlot(
        leftBus: 5,
        rightBus: 6,
        sidechainBus: 0,
        reductionBus: 0,
      );
      final routing = CompressorAlgorithmRouting.createFromSlot(
        slot,
        ioParameters: {},
        algorithmUuid: 'comp_t',
      );

      expect(
        routing.outputPorts.any((p) => p.busValue == 6),
        isTrue,
        reason: 'Right input (bus 6) should produce a virtual output',
      );
    });

    test('Right input with busValue=0 → no virtual output created', () {
      final slot = _compSlot(
        leftBus: 5,
        rightBus: 0,
        sidechainBus: 0,
        reductionBus: 0,
      );
      final routing = CompressorAlgorithmRouting.createFromSlot(
        slot,
        ioParameters: {},
        algorithmUuid: 'comp_t',
      );

      // Only the left input creates a virtual output; right is unassigned
      expect(
        routing.outputPorts
            .where((p) => p.busParam == null && p.busValue == 0)
            .isEmpty,
        isTrue,
        reason: 'Unassigned right input must not produce a virtual output',
      );
    });

    test('Sidechain input → input port only, no virtual output', () {
      final slot = _compSlot(
        leftBus: 5,
        rightBus: 0,
        sidechainBus: 7,
        reductionBus: 0,
      );
      final routing = CompressorAlgorithmRouting.createFromSlot(
        slot,
        ioParameters: {},
        algorithmUuid: 'comp_t',
      );

      // Input port for bus 7 exists
      expect(routing.inputPorts.any((p) => p.busValue == 7), isTrue);
      // No virtual output on bus 7
      expect(
        routing.outputPorts.any(
          (p) => p.busValue == 7 && p.busParam == null,
        ),
        isFalse,
        reason: 'Sidechain must not produce a virtual output',
      );
    });

    test('Reduction output (isOutput) → normal output port with mode', () {
      final slot = _compSlot(
        leftBus: 5,
        rightBus: 0,
        sidechainBus: 0,
        reductionBus: 13,
        reductionMode: 1, // Replace
      );
      final routing = CompressorAlgorithmRouting.createFromSlot(
        slot,
        ioParameters: {},
        algorithmUuid: 'comp_t',
      );

      final reductionOut = routing.outputPorts.firstWhere(
        (p) => p.busParam != null && p.busValue == 13,
        orElse: () => throw Exception('Reduction output not found'),
      );
      expect(reductionOut.outputMode, equals(OutputMode.replace));
      expect(reductionOut.modeParameterNumber, isNotNull);
    });

    test('all virtual outputs have OutputMode.replace', () {
      final slot = _compSlot(
        leftBus: 5,
        rightBus: 6,
        sidechainBus: 0,
        reductionBus: 0,
      );
      final routing = CompressorAlgorithmRouting.createFromSlot(
        slot,
        ioParameters: {},
        algorithmUuid: 'comp_t',
      );

      for (final port in routing.outputPorts.where((p) => p.busParam == null)) {
        expect(port.outputMode, equals(OutputMode.replace));
      }
    });
  });

  group('NoiseGateAlgorithmRouting port generation', () {
    test('Left/mono + Right inputs → virtual outputs; Sidechain → input only',
        () {
      final slot = _nsgtSlot(leftBus: 3, rightBus: 4, sidechainBus: 8);
      final routing = NoiseGateAlgorithmRouting.createFromSlot(
        slot,
        ioParameters: {},
        algorithmUuid: 'nsgt_t',
      );

      expect(routing.outputPorts.any((p) => p.busValue == 3), isTrue);
      expect(routing.outputPorts.any((p) => p.busValue == 4), isTrue);
      expect(
        routing.outputPorts.any(
          (p) => p.busValue == 8 && p.busParam == null,
        ),
        isFalse,
        reason: 'Sidechain must not produce a virtual output',
      );
    });

    test('No isOutput reduction port for Noise Gate', () {
      final slot = _nsgtSlot(leftBus: 3, rightBus: 0, sidechainBus: 0);
      final routing = NoiseGateAlgorithmRouting.createFromSlot(
        slot,
        ioParameters: {},
        algorithmUuid: 'nsgt_t',
      );

      // Only virtual outputs (busParam == null) should exist
      for (final port in routing.outputPorts) {
        expect(
          port.busParam,
          isNull,
          reason: 'Noise Gate has no isOutput parameters',
        );
      }
    });
  });
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Slot _compSlot({
  int leftBus = 5,
  int rightBus = 0,
  int sidechainBus = 0,
  int reductionBus = 0,
  int reductionMode = 0,
}) {
  final parameters = <ParameterInfo>[
    ParameterInfo(
      algorithmIndex: 0,
      parameterNumber: 0,
      name: '1:Left/mono input',
      min: 0,
      max: 28,
      defaultValue: leftBus,
      unit: 1,
      powerOfTen: 0,
      ioFlags: 5, // isInput | isAudio
    ),
    ParameterInfo(
      algorithmIndex: 0,
      parameterNumber: 1,
      name: '1:Right input',
      min: 0,
      max: 28,
      defaultValue: rightBus,
      unit: 1,
      powerOfTen: 0,
      ioFlags: 5, // isInput | isAudio
    ),
    ParameterInfo(
      algorithmIndex: 0,
      parameterNumber: 2,
      name: '1:Sidechain input',
      min: 0,
      max: 28,
      defaultValue: sidechainBus,
      unit: 1,
      powerOfTen: 0,
      ioFlags: 1, // isInput
    ),
  ];

  final values = <ParameterValue>[
    ParameterValue(algorithmIndex: 0, parameterNumber: 0, value: leftBus),
    ParameterValue(algorithmIndex: 0, parameterNumber: 1, value: rightBus),
    ParameterValue(algorithmIndex: 0, parameterNumber: 2, value: sidechainBus),
  ];

  final enums = <ParameterEnumStrings>[];
  final outputModeMap = <int, List<int>>{};

  if (reductionBus > 0) {
    parameters.add(
      ParameterInfo(
        algorithmIndex: 0,
        parameterNumber: 3,
        name: '1:Reduction output',
        min: 0,
        max: 28,
        defaultValue: reductionBus,
        unit: 1,
        powerOfTen: 0,
        ioFlags: 2, // isOutput
      ),
    );
    parameters.add(
      ParameterInfo(
        algorithmIndex: 0,
        parameterNumber: 4,
        name: '1:Reduction mode',
        min: 0,
        max: 1,
        defaultValue: reductionMode,
        unit: 1,
        powerOfTen: 0,
        ioFlags: 8, // isOutputMode
      ),
    );
    values.add(
      ParameterValue(
        algorithmIndex: 0,
        parameterNumber: 3,
        value: reductionBus,
      ),
    );
    values.add(
      ParameterValue(
        algorithmIndex: 0,
        parameterNumber: 4,
        value: reductionMode,
      ),
    );
    enums.add(
      ParameterEnumStrings(
        algorithmIndex: 0,
        parameterNumber: 4,
        values: ['Add', 'Replace'],
      ),
    );
    outputModeMap[4] = [3];
  }

  return Slot(
    algorithm: Algorithm(algorithmIndex: 0, guid: 'comp', name: 'Compressor'),
    routing: RoutingInfo(
      algorithmIndex: 0,
      routingInfo: List.filled(6, 0),
    ),
    pages: ParameterPages(algorithmIndex: 0, pages: []),
    parameters: parameters,
    values: values,
    enums: enums,
    mappings: [],
    valueStrings: [],
    outputModeMap: outputModeMap,
  );
}

Slot _nsgtSlot({int leftBus = 3, int rightBus = 0, int sidechainBus = 0}) {
  final parameters = <ParameterInfo>[
    ParameterInfo(
      algorithmIndex: 0,
      parameterNumber: 0,
      name: '1:Left/mono input',
      min: 0,
      max: 28,
      defaultValue: leftBus,
      unit: 1,
      powerOfTen: 0,
      ioFlags: 5, // isInput | isAudio
    ),
    ParameterInfo(
      algorithmIndex: 0,
      parameterNumber: 1,
      name: '1:Right input',
      min: 0,
      max: 28,
      defaultValue: rightBus,
      unit: 1,
      powerOfTen: 0,
      ioFlags: 5, // isInput | isAudio
    ),
    ParameterInfo(
      algorithmIndex: 0,
      parameterNumber: 2,
      name: '1:Sidechain input',
      min: 0,
      max: 28,
      defaultValue: sidechainBus,
      unit: 1,
      powerOfTen: 0,
      ioFlags: 1, // isInput
    ),
  ];

  final values = <ParameterValue>[
    ParameterValue(algorithmIndex: 0, parameterNumber: 0, value: leftBus),
    ParameterValue(algorithmIndex: 0, parameterNumber: 1, value: rightBus),
    ParameterValue(algorithmIndex: 0, parameterNumber: 2, value: sidechainBus),
  ];

  return Slot(
    algorithm: Algorithm(
      algorithmIndex: 0,
      guid: 'nsgt',
      name: 'Noise Gate',
    ),
    routing: RoutingInfo(
      algorithmIndex: 0,
      routingInfo: List.filled(6, 0),
    ),
    pages: ParameterPages(algorithmIndex: 0, pages: []),
    parameters: parameters,
    values: values,
    enums: [],
    mappings: [],
    valueStrings: [],
  );
}

Slot _slotWithGuid(String guid) {
  return Slot(
    algorithm: Algorithm(algorithmIndex: 0, guid: guid, name: guid),
    routing: RoutingInfo(algorithmIndex: 0, routingInfo: List.filled(6, 0)),
    pages: ParameterPages(algorithmIndex: 0, pages: []),
    parameters: [],
    values: [],
    enums: [],
    mappings: [],
    valueStrings: [],
  );
}
