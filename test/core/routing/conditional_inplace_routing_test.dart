import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/core/routing/algorithm_routing.dart';
import 'package:nt_helper/core/routing/models/port.dart';
import 'package:nt_helper/cubit/disting_cubit.dart';
import 'package:nt_helper/domain/disting_nt_sysex.dart';

void main() {
  group('Case C — conditional in-place replace (Output=None → Replace)', () {
    test(
      'attn: Input=5, Output=0 → virtual replace output on bus 5, no mode param',
      () {
        final slot = _makeAttnSlot(inputBus: 5, outputBus: 0);
        final routing = AlgorithmRouting.fromSlot(
          slot,
          algorithmUuid: 'attn_t',
        );

        expect(routing.outputPorts.length, equals(1));
        final out = routing.outputPorts.first;
        expect(out.busValue, equals(5));
        expect(out.outputMode, equals(OutputMode.replace));
        expect(out.modeParameterNumber, isNull);
        expect(out.busParam, isNull);
      },
    );

    test('attn: Input=5, Output=7 → normal output on bus 7 with mode', () {
      final slot = _makeAttnSlot(inputBus: 5, outputBus: 7, modeValue: 0);
      final routing = AlgorithmRouting.fromSlot(slot, algorithmUuid: 'attn_t2');

      final out = routing.outputPorts.firstWhere(
        (p) => p.busValue == 7,
        orElse: () => throw Exception('Expected output on bus 7'),
      );
      // Has a bus parameter (real output), not virtual
      expect(out.busParam, isNotNull);
    });

    test('attn: Input=0, Output=0 → no output port shown', () {
      final slot = _makeAttnSlot(inputBus: 0, outputBus: 0);
      final routing = AlgorithmRouting.fromSlot(slot, algorithmUuid: 'attn_t3');

      // Both input and output are unassigned — nothing to show
      expect(routing.outputPorts, isEmpty);
    });

    test('vcam: Input=3, Output=0 → virtual replace output on bus 3', () {
      final slot = _makeSimpleInPlaceSlot(guid: 'vcam', inputBus: 3);
      final routing = AlgorithmRouting.fromSlot(slot, algorithmUuid: 'vcam_t');

      expect(routing.outputPorts.length, equals(1));
      expect(routing.outputPorts.first.busValue, equals(3));
      expect(routing.outputPorts.first.outputMode, equals(OutputMode.replace));
    });

    test(
      'non-inplace algorithm (mixr): Output=0 produces disconnected output port (unchanged)',
      () {
        final slot = _makeSimpleInPlaceSlot(guid: 'mixr', inputBus: 5);
        final routing = AlgorithmRouting.fromSlot(
          slot,
          algorithmUuid: 'mixr_t',
        );

        // mixr is not in _conditionalInPlaceGuids → output port stays with busValue=0
        final out = routing.outputPorts.firstWhere(
          (p) => p.busParam != null,
          orElse: () => throw Exception('Expected a real output port'),
        );
        expect(out.busValue, equals(0));
        expect(out.outputMode, isNull);
      },
    );

    test('all _conditionalInPlaceGuids dispatch correctly', () {
      const guids = ['attn', 'absv', 'vcam', 'enfo', 'slew', 'debo', 'eqpa'];
      for (final guid in guids) {
        final slot = _makeAttnSlot(
          inputBus: 5,
          outputBus: 0,
          guid: guid,
        );
        final routing = AlgorithmRouting.fromSlot(slot, algorithmUuid: guid);

        expect(
          routing.outputPorts.any(
            (p) => p.busValue == 5 && p.outputMode == OutputMode.replace,
          ),
          isTrue,
          reason: '$guid should produce a virtual replace output on bus 5',
        );
      }
    });
  });
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Slot _makeAttnSlot({
  required int inputBus,
  required int outputBus,
  int? modeValue,
  String guid = 'attn',
}) {
  final parameters = <ParameterInfo>[
    ParameterInfo(
      algorithmIndex: 0,
      parameterNumber: 0,
      name: 'Input',
      min: 0,
      max: 28,
      defaultValue: inputBus,
      unit: 1,
      powerOfTen: 0,
      ioFlags: 1, // isInput
    ),
    ParameterInfo(
      algorithmIndex: 0,
      parameterNumber: 1,
      name: 'Output',
      min: 0,
      max: 28,
      defaultValue: outputBus,
      unit: 1,
      powerOfTen: 0,
      ioFlags: 2, // isOutput
    ),
  ];

  final values = <ParameterValue>[
    ParameterValue(algorithmIndex: 0, parameterNumber: 0, value: inputBus),
    ParameterValue(algorithmIndex: 0, parameterNumber: 1, value: outputBus),
  ];

  final enums = <ParameterEnumStrings>[];
  final outputModeMap = <int, List<int>>{};

  if (modeValue != null) {
    parameters.add(
      ParameterInfo(
        algorithmIndex: 0,
        parameterNumber: 2,
        name: 'Output mode',
        min: 0,
        max: 1,
        defaultValue: modeValue,
        unit: 1,
        powerOfTen: 0,
        ioFlags: 8,
      ),
    );
    values.add(
      ParameterValue(
        algorithmIndex: 0,
        parameterNumber: 2,
        value: modeValue,
      ),
    );
    enums.add(
      ParameterEnumStrings(
        algorithmIndex: 0,
        parameterNumber: 2,
        values: ['Add', 'Replace'],
      ),
    );
    outputModeMap[2] = [1];
  }

  return Slot(
    algorithm: Algorithm(algorithmIndex: 0, guid: guid, name: guid),
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

/// Minimal slot with Input (isInput) and Output=0 (isOutput) for any GUID.
Slot _makeSimpleInPlaceSlot({required String guid, required int inputBus}) {
  return Slot(
    algorithm: Algorithm(algorithmIndex: 0, guid: guid, name: guid),
    routing: RoutingInfo(
      algorithmIndex: 0,
      routingInfo: List.filled(6, 0),
    ),
    pages: ParameterPages(algorithmIndex: 0, pages: []),
    parameters: [
      ParameterInfo(
        algorithmIndex: 0,
        parameterNumber: 0,
        name: 'Input',
        min: 0,
        max: 28,
        defaultValue: inputBus,
        unit: 1,
        powerOfTen: 0,
        ioFlags: 1,
      ),
      ParameterInfo(
        algorithmIndex: 0,
        parameterNumber: 1,
        name: 'Output',
        min: 0,
        max: 28,
        defaultValue: 0,
        unit: 1,
        powerOfTen: 0,
        ioFlags: 2,
      ),
    ],
    values: [
      ParameterValue(algorithmIndex: 0, parameterNumber: 0, value: inputBus),
      ParameterValue(algorithmIndex: 0, parameterNumber: 1, value: 0),
    ],
    enums: [],
    mappings: [],
    valueStrings: [],
  );
}
