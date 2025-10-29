import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/core/routing/poly_algorithm_routing.dart';
import 'package:nt_helper/cubit/disting_cubit.dart';
import 'package:nt_helper/domain/disting_nt_sysex.dart';

void main() {
  group('Poly CV ES-5 Direct Routing Tests', () {
    // Helper function to create Poly CV test slot
    Slot createPolyCvSlot({
      required int voices,
      required int gateOutputs,
      required int pitchOutputs,
      required int velocityOutputs,
      required int firstOutput,
      required int es5Expander,
      required int es5Output,
      int algorithmIndex = 0,
    }) {
      final parameters = <ParameterInfo>[];
      final values = <ParameterValue>[];

      int paramNum = 0;

      // Voices parameter (23)
      parameters.add(
        ParameterInfo(
          algorithmIndex: algorithmIndex,
          parameterNumber: 23,
          name: 'Voices',
          min: 1,
          max: 14,
          defaultValue: 1,
          unit: 1,
          powerOfTen: 0,
        ),
      );
      values.add(
        ParameterValue(
          algorithmIndex: algorithmIndex,
          parameterNumber: 23,
          value: voices,
        ),
      );

      // First output parameter
      parameters.add(
        ParameterInfo(
          algorithmIndex: algorithmIndex,
          parameterNumber: paramNum++,
          name: 'First output',
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
          parameterNumber: parameters.last.parameterNumber,
          value: firstOutput,
        ),
      );

      // Gate outputs parameter
      parameters.add(
        ParameterInfo(
          algorithmIndex: algorithmIndex,
          parameterNumber: paramNum++,
          name: 'Gate outputs',
          min: 0,
          max: 1,
          defaultValue: 1,
          unit: 1,
          powerOfTen: 0,
        ),
      );
      values.add(
        ParameterValue(
          algorithmIndex: algorithmIndex,
          parameterNumber: parameters.last.parameterNumber,
          value: gateOutputs,
        ),
      );

      // Pitch outputs parameter
      parameters.add(
        ParameterInfo(
          algorithmIndex: algorithmIndex,
          parameterNumber: paramNum++,
          name: 'Pitch outputs',
          min: 0,
          max: 1,
          defaultValue: 1,
          unit: 1,
          powerOfTen: 0,
        ),
      );
      values.add(
        ParameterValue(
          algorithmIndex: algorithmIndex,
          parameterNumber: parameters.last.parameterNumber,
          value: pitchOutputs,
        ),
      );

      // Velocity outputs parameter
      parameters.add(
        ParameterInfo(
          algorithmIndex: algorithmIndex,
          parameterNumber: paramNum++,
          name: 'Velocity outputs',
          min: 0,
          max: 1,
          defaultValue: 0,
          unit: 1,
          powerOfTen: 0,
        ),
      );
      values.add(
        ParameterValue(
          algorithmIndex: algorithmIndex,
          parameterNumber: parameters.last.parameterNumber,
          value: velocityOutputs,
        ),
      );

      // ES-5 Expander parameter (53)
      parameters.add(
        ParameterInfo(
          algorithmIndex: algorithmIndex,
          parameterNumber: 53,
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
          parameterNumber: 53,
          value: es5Expander,
        ),
      );

      // ES-5 Output parameter (54)
      parameters.add(
        ParameterInfo(
          algorithmIndex: algorithmIndex,
          parameterNumber: 54,
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
          parameterNumber: 54,
          value: es5Output,
        ),
      );

      return Slot(
        algorithm: Algorithm(
          algorithmIndex: algorithmIndex,
          guid: 'pycv',
          name: 'Poly CV',
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

    group('Multi-Voice ES-5 Tests', () {
      test('Voice count = 1, ES-5 active → 1 gate to ES-5', () {
        final slot = createPolyCvSlot(
          voices: 1,
          gateOutputs: 1,
          pitchOutputs: 0,
          velocityOutputs: 0,
          firstOutput: 13,
          es5Expander: 1,
          es5Output: 1,
        );

        final routing = PolyAlgorithmRouting.createFromSlot(
          slot,
          ioParameters: {
            'Voices': 1,
            'First output': 13,
            'Gate outputs': 1,
            'Pitch outputs': 0,
            'Velocity outputs': 0,
            'ES-5 Expander': 1,
            'ES-5 Output': 1,
          },
          algorithmUuid: 'test-uuid-pycv',
        );

        final outputPorts = routing.outputPorts;

        // Filter out the ES-5 Output parameter port (it's a parameter, not a real output)
        final gatePorts = outputPorts
            .where((p) => p.name.contains('Gate'))
            .toList();

        expect(gatePorts, hasLength(1));
        expect(gatePorts[0].name, equals('Voice 1 Gate → ES-5 1'));
        expect(gatePorts[0].busParam, equals('es5_direct'));
        expect(
          gatePorts[0].channelNumber,
          equals(1),
        ); // ES-5 port number stored in channelNumber
      });

      test('Voice count = 4, ES-5 active → 4 gates to ES-5', () {
        final slot = createPolyCvSlot(
          voices: 4,
          gateOutputs: 1,
          pitchOutputs: 0,
          velocityOutputs: 0,
          firstOutput: 13,
          es5Expander: 1,
          es5Output: 1,
        );

        final routing = PolyAlgorithmRouting.createFromSlot(
          slot,
          ioParameters: {
            'Voices': 4,
            'First output': 13,
            'Gate outputs': 1,
            'Pitch outputs': 0,
            'Velocity outputs': 0,
            'ES-5 Expander': 1,
            'ES-5 Output': 1,
          },
          algorithmUuid: 'test-uuid-pycv',
        );

        final outputPorts = routing.outputPorts;

        // Filter out the ES-5 Output parameter port
        final gatePorts = outputPorts
            .where((p) => p.name.contains('Gate'))
            .toList();

        expect(gatePorts, hasLength(4));
        for (int i = 0; i < 4; i++) {
          expect(
            gatePorts[i].name,
            equals('Voice ${i + 1} Gate → ES-5 ${i + 1}'),
          );
          expect(gatePorts[i].busParam, equals('es5_direct'));
        }
      });

      test('Voice count = 8, ES-5 active → 8 gates to ES-5', () {
        final slot = createPolyCvSlot(
          voices: 8,
          gateOutputs: 1,
          pitchOutputs: 0,
          velocityOutputs: 0,
          firstOutput: 13,
          es5Expander: 1,
          es5Output: 1,
        );

        final routing = PolyAlgorithmRouting.createFromSlot(
          slot,
          ioParameters: {
            'Voices': 8,
            'First output': 13,
            'Gate outputs': 1,
            'Pitch outputs': 0,
            'Velocity outputs': 0,
            'ES-5 Expander': 1,
            'ES-5 Output': 1,
          },
          algorithmUuid: 'test-uuid-pycv',
        );

        final outputPorts = routing.outputPorts;

        // Filter out the ES-5 Output parameter port
        final gatePorts = outputPorts
            .where((p) => p.name.contains('Gate'))
            .toList();

        expect(gatePorts, hasLength(8));
        for (int i = 0; i < 8; i++) {
          expect(gatePorts[i].name, contains('Voice ${i + 1} Gate'));
          expect(gatePorts[i].name, contains('ES-5 ${i + 1}'));
          expect(gatePorts[i].busParam, equals('es5_direct'));
        }
      });
    });

    group('Mixed Routing Tests', () {
      test('Gates to ES-5, Pitch CVs to normal buses', () {
        final slot = createPolyCvSlot(
          voices: 4,
          gateOutputs: 1,
          pitchOutputs: 1,
          velocityOutputs: 0,
          firstOutput: 13,
          es5Expander: 1,
          es5Output: 1,
        );

        final routing = PolyAlgorithmRouting.createFromSlot(
          slot,
          ioParameters: {
            'Voices': 4,
            'First output': 13,
            'Gate outputs': 1,
            'Pitch outputs': 1,
            'Velocity outputs': 0,
            'ES-5 Expander': 1,
            'ES-5 Output': 1,
          },
          algorithmUuid: 'test-uuid-pycv',
        );

        final outputPorts = routing.outputPorts;

        // Filter out the ES-5 Output parameter port
        final realPorts = outputPorts
            .where((p) => !p.name.contains('ES-5 Output'))
            .toList();

        // Should have 4 gates (ES-5) + 4 pitch CVs (normal)
        expect(realPorts, hasLength(8));

        // Check gates go to ES-5
        final gatePorts = realPorts
            .where((p) => p.name.contains('Gate'))
            .toList();
        expect(gatePorts, hasLength(4));
        for (final port in gatePorts) {
          expect(port.busParam, equals('es5_direct'));
          expect(port.name, contains('ES-5'));
        }

        // Check pitch CVs use normal buses
        final pitchPorts = realPorts
            .where((p) => p.name.contains('Pitch'))
            .toList();
        expect(pitchPorts, hasLength(4));
        for (final port in pitchPorts) {
          // Pitch ports have busParam set to 'Pitch output' but use busValue for routing
          expect(port.busParam, isNot(equals('es5_direct')));
          expect(port.busValue, isNotNull);
          expect(port.busValue! >= 13, isTrue);
        }
      });

      test('Gates to ES-5, Pitch + Velocity CVs to normal buses', () {
        final slot = createPolyCvSlot(
          voices: 2,
          gateOutputs: 1,
          pitchOutputs: 1,
          velocityOutputs: 1,
          firstOutput: 13,
          es5Expander: 1,
          es5Output: 1,
        );

        final routing = PolyAlgorithmRouting.createFromSlot(
          slot,
          ioParameters: {
            'Voices': 2,
            'First output': 13,
            'Gate outputs': 1,
            'Pitch outputs': 1,
            'Velocity outputs': 1,
            'ES-5 Expander': 1,
            'ES-5 Output': 1,
          },
          algorithmUuid: 'test-uuid-pycv',
        );

        final outputPorts = routing.outputPorts;

        // Filter out the ES-5 Output parameter port
        final realPorts = outputPorts
            .where((p) => !p.name.contains('ES-5 Output'))
            .toList();

        // Should have 2 gates (ES-5) + 2 pitch CVs + 2 velocity CVs (normal)
        expect(realPorts, hasLength(6));

        // Check gates go to ES-5
        final gatePorts = realPorts
            .where((p) => p.name.contains('Gate'))
            .toList();
        expect(gatePorts, hasLength(2));
        for (final port in gatePorts) {
          expect(port.busParam, equals('es5_direct'));
        }

        // Check CVs use normal buses (not ES-5)
        final cvPorts = realPorts
            .where(
              (p) => p.name.contains('Pitch') || p.name.contains('Velocity'),
            )
            .toList();
        expect(cvPorts, hasLength(4));
        for (final port in cvPorts) {
          // CV ports have busParam set but use busValue for routing
          expect(port.busParam, isNot(equals('es5_direct')));
          expect(port.busValue, isNotNull);
        }
      });
    });

    group('Normal Mode Tests', () {
      test('ES-5 Expander = 0: all outputs use normal buses', () {
        final slot = createPolyCvSlot(
          voices: 4,
          gateOutputs: 1,
          pitchOutputs: 1,
          velocityOutputs: 0,
          firstOutput: 13,
          es5Expander: 0,
          es5Output: 1,
        );

        final routing = PolyAlgorithmRouting.createFromSlot(
          slot,
          ioParameters: {
            'Voices': 4,
            'First output': 13,
            'Gate outputs': 1,
            'Pitch outputs': 1,
            'Velocity outputs': 0,
            'ES-5 Expander': 0,
            'ES-5 Output': 1,
          },
          algorithmUuid: 'test-uuid-pycv',
        );

        final outputPorts = routing.outputPorts;

        // Filter out the ES-5 Output parameter port
        final realPorts = outputPorts
            .where((p) => !p.name.contains('ES-5 Output'))
            .toList();

        // All ports should use normal buses (no ES-5)
        for (final port in realPorts) {
          expect(port.busParam, isNot(equals('es5_direct')));
          expect(port.busValue, isNotNull);
          expect(port.busValue! >= 13, isTrue);
        }
      });
    });

    group('Factory Method Tests', () {
      test('canHandle returns true for Poly CV (pycv)', () {
        final slot = createPolyCvSlot(
          voices: 1,
          gateOutputs: 1,
          pitchOutputs: 0,
          velocityOutputs: 0,
          firstOutput: 13,
          es5Expander: 0,
          es5Output: 1,
        );

        expect(PolyAlgorithmRouting.canHandle(slot), isTrue);
      });

      test('canHandle returns false for other algorithms', () {
        final slot = Slot(
          algorithm: Algorithm(algorithmIndex: 0, guid: 'clck', name: 'Clock'),
          routing: RoutingInfo(algorithmIndex: 0, routingInfo: []),
          pages: ParameterPages(algorithmIndex: 0, pages: []),
          parameters: [],
          values: [],
          enums: const [],
          mappings: const [],
          valueStrings: const [],
        );

        expect(PolyAlgorithmRouting.canHandle(slot), isFalse);
      });
    });
  });
}
