import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/core/routing/algorithm_routing.dart';
import 'package:nt_helper/core/routing/models/port.dart';
import 'package:nt_helper/core/routing/multi_channel_algorithm_routing.dart';
import 'package:nt_helper/cubit/disting_cubit.dart';
import 'package:nt_helper/domain/disting_nt_sysex.dart';

void main() {
  group('Case A — always-replace output algorithms', () {
    test('quan: all output ports have OutputMode.replace', () {
      final slot = _createQuantizerSlot();
      final routing = AlgorithmRouting.fromSlot(slot, algorithmUuid: 'quan_t');

      expect(routing.outputPorts, isNotEmpty);
      for (final port in routing.outputPorts) {
        expect(
          port.outputMode,
          equals(OutputMode.replace),
          reason: 'Quantizer output "${port.name}" must be Replace',
        );
      }
    });

    test('cali: output port has OutputMode.replace', () {
      final slot = _createCaliSlot();
      final routing = AlgorithmRouting.fromSlot(slot, algorithmUuid: 'cali_t');

      expect(routing.outputPorts, isNotEmpty);
      for (final port in routing.outputPorts) {
        expect(
          port.outputMode,
          equals(OutputMode.replace),
          reason: 'Auto-calibrator output "${port.name}" must be Replace',
        );
      }
    });

    test('defaultOutputMode does not override a port already in outputModeMap',
        () {
      // A slot where one output IS in outputModeMap set to Add (value 0).
      final slot = _createQuantizerSlotWithModeMap(modeValue: 0);
      final routing = AlgorithmRouting.fromSlot(slot, algorithmUuid: 'q_mm');

      // The port controlled by the modeMap should keep Add, not be overridden
      // to Replace by defaultOutputMode.
      final controlledPort = routing.outputPorts.firstWhere(
        (p) => p.modeParameterNumber != null,
        orElse: () => throw Exception('Expected a controlled port'),
      );
      expect(controlledPort.outputMode, equals(OutputMode.add));
    });

    test('defaultOutputMode: null leaves outputMode null (existing behaviour)',
        () {
      final slot = _createSimpleOutputSlot(guid: 'mixr');
      final routing = MultiChannelAlgorithmRouting.createFromSlot(
        slot,
        ioParameters: AlgorithmRouting.extractIOParameters(slot),
        defaultOutputMode: null,
      );
      // No mode map, no mode params, no defaultOutputMode → null
      for (final port in routing.outputPorts) {
        expect(port.outputMode, isNull);
      }
    });

    test('defaultOutputMode does not affect input ports', () {
      final slot = _createQuantizerSlot();
      final routing = AlgorithmRouting.fromSlot(slot, algorithmUuid: 'q_in');

      for (final port in routing.inputPorts) {
        expect(port.outputMode, isNull);
      }
    });
  });
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Slot _makeSlot({
  required String guid,
  required String name,
  required List<ParameterInfo> parameters,
  List<ParameterValue>? values,
  List<ParameterEnumStrings>? enums,
  Map<int, List<int>>? outputModeMap,
}) {
  final algorithm = Algorithm(algorithmIndex: 0, guid: guid, name: name);
  final routing = RoutingInfo(
    algorithmIndex: 0,
    routingInfo: List.filled(6, 0),
  );
  final pages = ParameterPages(algorithmIndex: 0, pages: []);
  final vals =
      values ??
      parameters
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
    values: vals,
    enums: enums ?? [],
    mappings: [],
    valueStrings: [],
    outputModeMap: outputModeMap ?? {},
  );
}

ParameterInfo _busParam({
  required int num,
  required String name,
  required int defaultValue,
  required int ioFlags,
}) => ParameterInfo(
  algorithmIndex: 0,
  parameterNumber: num,
  name: name,
  min: 0,
  max: 28,
  defaultValue: defaultValue,
  unit: 1,
  powerOfTen: 0,
  ioFlags: ioFlags,
);

Slot _createQuantizerSlot() {
  return _makeSlot(
    guid: 'quan',
    name: 'Quantizer',
    parameters: [
      _busParam(num: 0, name: 'Input', defaultValue: 1, ioFlags: 1),
      _busParam(num: 1, name: 'CV output', defaultValue: 13, ioFlags: 2),
      _busParam(num: 2, name: 'Gate output', defaultValue: 14, ioFlags: 2),
      _busParam(num: 3, name: 'Change output', defaultValue: 15, ioFlags: 2),
    ],
  );
}

Slot _createCaliSlot() {
  return _makeSlot(
    guid: 'cali',
    name: 'Auto-calibrator',
    parameters: [
      _busParam(num: 0, name: 'Input', defaultValue: 1, ioFlags: 1),
      _busParam(num: 1, name: 'Output', defaultValue: 13, ioFlags: 2),
    ],
  );
}

Slot _createQuantizerSlotWithModeMap({required int modeValue}) {
  // Mimics a quan slot but with one output controlled by a mode parameter
  // set to Add (value=0) — defaultOutputMode must NOT override this.
  final parameters = [
    _busParam(num: 0, name: 'Input', defaultValue: 1, ioFlags: 1),
    _busParam(num: 1, name: 'CV output', defaultValue: 13, ioFlags: 2),
    ParameterInfo(
      algorithmIndex: 0,
      parameterNumber: 10,
      name: 'CV output mode',
      min: 0,
      max: 1,
      defaultValue: modeValue,
      unit: 1,
      powerOfTen: 0,
      ioFlags: 8,
    ),
  ];
  return _makeSlot(
    guid: 'quan',
    name: 'Quantizer',
    parameters: parameters,
    enums: [
      ParameterEnumStrings(
        algorithmIndex: 0,
        parameterNumber: 10,
        values: ['Add', 'Replace'],
      ),
    ],
    outputModeMap: {
      10: [1],
    },
    values: [
      ParameterValue(algorithmIndex: 0, parameterNumber: 0, value: 1),
      ParameterValue(algorithmIndex: 0, parameterNumber: 1, value: 13),
      ParameterValue(
        algorithmIndex: 0,
        parameterNumber: 10,
        value: modeValue,
      ),
    ],
  );
}

Slot _createSimpleOutputSlot({required String guid}) {
  return _makeSlot(
    guid: guid,
    name: 'Simple',
    parameters: [
      _busParam(num: 0, name: 'Input', defaultValue: 1, ioFlags: 1),
      _busParam(num: 1, name: 'Output', defaultValue: 13, ioFlags: 2),
    ],
  );
}
