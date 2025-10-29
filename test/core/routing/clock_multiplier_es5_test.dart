import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/core/routing/clock_multiplier_algorithm_routing.dart';
import 'package:nt_helper/core/routing/models/port.dart';
import 'package:nt_helper/cubit/disting_cubit.dart';
import 'package:nt_helper/domain/disting_nt_sysex.dart';

void main() {
  group('Clock Multiplier ES-5 Direct Routing Tests', () {
    // Helper function to create Clock Multiplier test slot
    Slot createClockMultiplierSlot({
      required int es5Expander,
      required int es5Output,
      required int output,
      int algorithmIndex = 0,
    }) {
      final parameters = <ParameterInfo>[];
      final values = <ParameterValue>[];

      // Clock input (param 0)
      parameters.add(
        ParameterInfo(
          algorithmIndex: algorithmIndex,
          parameterNumber: 0,
          name: 'Clock input',
          min: 1,
          max: 12,
          defaultValue: 1,
          unit: 1,
          powerOfTen: 0,
        ),
      );
      values.add(
        ParameterValue(
          algorithmIndex: algorithmIndex,
          parameterNumber: 0,
          value: 1,
        ),
      );

      // Output (param 6)
      parameters.add(
        ParameterInfo(
          algorithmIndex: algorithmIndex,
          parameterNumber: 6,
          name: 'Output',
          min: 13,
          max: 20,
          defaultValue: 13,
          unit: 1,
          powerOfTen: 0,
        ),
      );
      values.add(
        ParameterValue(
          algorithmIndex: algorithmIndex,
          parameterNumber: 6,
          value: output,
        ),
      );

      // ES-5 Expander (param 7) - no channel prefix for Clock Multiplier
      parameters.add(
        ParameterInfo(
          algorithmIndex: algorithmIndex,
          parameterNumber: 7,
          name: 'ES-5 Expander',
          min: 0,
          max: 6,
          defaultValue: 0,
          unit: 1,
          powerOfTen: 0,
        ),
      );
      values.add(
        ParameterValue(
          algorithmIndex: algorithmIndex,
          parameterNumber: 7,
          value: es5Expander,
        ),
      );

      // ES-5 Output (param 8)
      parameters.add(
        ParameterInfo(
          algorithmIndex: algorithmIndex,
          parameterNumber: 8,
          name: 'ES-5 Output',
          min: 1,
          max: 8,
          defaultValue: 1,
          unit: 1,
          powerOfTen: 0,
        ),
      );
      values.add(
        ParameterValue(
          algorithmIndex: algorithmIndex,
          parameterNumber: 8,
          value: es5Output,
        ),
      );

      return Slot(
        algorithm: Algorithm(
          algorithmIndex: algorithmIndex,
          guid: 'clkm',
          name: 'Clock Multiplier',
        ),
        routing: RoutingInfo(algorithmIndex: algorithmIndex, routingInfo: []),
        pages: ParameterPages(algorithmIndex: algorithmIndex, pages: []),
        parameters: parameters,
        values: values,
        enums: const [],
        mappings: const [],
        valueStrings: const [],
      );
    }

    group('ES-5 Mode Tests', () {
      test('ES-5 mode: creates ES-5 direct output port when Expander = 1', () {
        final slot = createClockMultiplierSlot(
          es5Expander: 1,
          es5Output: 3,
          output: 13,
        );

        final routing = ClockMultiplierAlgorithmRouting.createFromSlot(
          slot,
          ioParameters: {'Clock input': 1}, // Bus assignment value
          algorithmUuid: 'test-uuid-clkm',
        );

        final outputPorts = routing.outputPorts;

        expect(outputPorts, hasLength(1));
        expect(outputPorts[0].name, equals('Ch1 → ES-5 3'));
        expect(outputPorts[0].busParam, equals('es5_direct'));
        expect(outputPorts[0].channelNumber, equals(3));
        expect(outputPorts[0].type, equals(PortType.gate));
        expect(outputPorts[0].direction, equals(PortDirection.output));
      });

      test('ES-5 mode: creates ES-5 direct output port when Expander = 6', () {
        final slot = createClockMultiplierSlot(
          es5Expander: 6,
          es5Output: 8,
          output: 15,
        );

        final routing = ClockMultiplierAlgorithmRouting.createFromSlot(
          slot,
          ioParameters: {'Clock input': 1}, // Bus assignment value
          algorithmUuid: 'test-uuid-clkm',
        );

        final outputPorts = routing.outputPorts;

        expect(outputPorts, hasLength(1));
        expect(outputPorts[0].name, equals('Ch1 → ES-5 8'));
        expect(outputPorts[0].busParam, equals('es5_direct'));
        expect(outputPorts[0].channelNumber, equals(8));
      });

      test('ES-5 mode: Output parameter is ignored', () {
        final slot = createClockMultiplierSlot(
          es5Expander: 1,
          es5Output: 3,
          output: 20, // Should be ignored
        );

        final routing = ClockMultiplierAlgorithmRouting.createFromSlot(
          slot,
          ioParameters: {'Clock input': 1}, // Bus assignment value
          algorithmUuid: 'test-uuid-clkm',
        );

        final outputPorts = routing.outputPorts;

        expect(outputPorts, hasLength(1));
        // Should use ES-5 Output (3), not Output (20)
        expect(outputPorts[0].name, equals('Ch1 → ES-5 3'));
        expect(outputPorts[0].busParam, equals('es5_direct'));
        expect(outputPorts[0].channelNumber, equals(3));
        // busValue should NOT be set in ES-5 mode
        expect(outputPorts[0].busValue, isNull);
      });
    });

    group('Normal Mode Tests', () {
      test('Normal mode: creates normal output port when Expander = 0', () {
        final slot = createClockMultiplierSlot(
          es5Expander: 0,
          es5Output: 3,
          output: 13,
        );

        final routing = ClockMultiplierAlgorithmRouting.createFromSlot(
          slot,
          ioParameters: {'Clock input': 1}, // Bus assignment value
          algorithmUuid: 'test-uuid-clkm',
        );

        final outputPorts = routing.outputPorts;

        expect(outputPorts, hasLength(1));
        expect(outputPorts[0].name, equals('Output')); // Single-channel uses parameter name
        expect(outputPorts[0].busValue, equals(13));
        expect(outputPorts[0].type, equals(PortType.gate));
        expect(outputPorts[0].direction, equals(PortDirection.output));
        // busParam should NOT be set in normal mode
        expect(outputPorts[0].busParam, isNull);
      });

      test('Normal mode: uses Output parameter for bus assignment', () {
        final slot = createClockMultiplierSlot(
          es5Expander: 0,
          es5Output: 8, // Should be ignored
          output: 20,
        );

        final routing = ClockMultiplierAlgorithmRouting.createFromSlot(
          slot,
          ioParameters: {'Clock input': 1}, // Bus assignment value
          algorithmUuid: 'test-uuid-clkm',
        );

        final outputPorts = routing.outputPorts;

        expect(outputPorts, hasLength(1));
        expect(outputPorts[0].name, equals('Output')); // Single-channel uses parameter name
        expect(outputPorts[0].busValue, equals(20));
        expect(outputPorts[0].channelNumber, equals(1));
      });
    });

    group('Input Port Tests', () {
      test('Creates input port for Clock input', () {
        final slot = createClockMultiplierSlot(
          es5Expander: 0,
          es5Output: 1,
          output: 13,
        );

        final routing = ClockMultiplierAlgorithmRouting.createFromSlot(
          slot,
          ioParameters: {'Clock input': 1}, // Bus assignment value
          algorithmUuid: 'test-uuid-clkm',
        );

        final inputPorts = routing.inputPorts;

        expect(inputPorts, hasLength(1));
        expect(inputPorts[0].name, equals('Clock input'));
        expect(inputPorts[0].busValue, equals(1));
        expect(inputPorts[0].type, equals(PortType.clock));
        expect(inputPorts[0].direction, equals(PortDirection.input));
      });
    });

    group('Connection Discovery Tests', () {
      test('ES-5 mode: connections discovered via es5_direct bus param', () {
        // Create Clock Multiplier outputting to ES-5 port 3
        final clkmSlot = createClockMultiplierSlot(
          es5Expander: 1,
          es5Output: 3,
          output: 13,
          algorithmIndex: 0,
        );

        final clkmRouting = ClockMultiplierAlgorithmRouting.createFromSlot(
          clkmSlot,
          ioParameters: {'Clock input': 1}, // Bus assignment value
          algorithmUuid: 'clkm-uuid',
        );

        // Verify output port has es5_direct marker
        final outputPorts = clkmRouting.outputPorts;
        expect(outputPorts, hasLength(1));
        expect(outputPorts[0].busParam, equals('es5_direct'));
        expect(outputPorts[0].channelNumber, equals(3));
      });
    });

    group('Factory Method Tests', () {
      test('canHandle returns true for Clock Multiplier (clkm)', () {
        final slot = createClockMultiplierSlot(
          es5Expander: 0,
          es5Output: 1,
          output: 13,
        );

        expect(ClockMultiplierAlgorithmRouting.canHandle(slot), isTrue);
      });

      test('canHandle returns false for other algorithms', () {
        final slot = Slot(
          algorithm: Algorithm(
            algorithmIndex: 0,
            guid: 'clck',
            name: 'Clock',
          ),
          routing: RoutingInfo(algorithmIndex: 0, routingInfo: []),
          pages: ParameterPages(algorithmIndex: 0, pages: []),
          parameters: [],
          values: [],
          enums: const [],
          mappings: const [],
          valueStrings: const [],
        );

        expect(ClockMultiplierAlgorithmRouting.canHandle(slot), isFalse);
      });
    });
  });
}
