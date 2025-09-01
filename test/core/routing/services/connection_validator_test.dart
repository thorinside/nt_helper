import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/core/routing/services/connection_validator.dart';
import 'package:nt_helper/cubit/routing_editor_cubit.dart';
import 'package:nt_helper/domain/disting_nt_sysex.dart';

void main() {
  group('ConnectionValidator', () {
    late List<RoutingAlgorithm> testAlgorithms;
    
    setUp(() {
      // Create test algorithms with different slot indices
      testAlgorithms = [
        RoutingAlgorithm(
          id: 'algo_1',
          index: 0, // Slot 1
          algorithm: Algorithm(
            algorithmIndex: 0,
            guid: 'test-guid-1',
            name: 'Test Algorithm 1',
          ),
          inputPorts: [
            const Port(
              id: 'algo_1_port_1',
              name: 'Input 1',
              type: PortType.cv,
              direction: PortDirection.input,
            ),
          ],
          outputPorts: [
            const Port(
              id: 'algo_1_port_2',
              name: 'Output 1',
              type: PortType.audio,
              direction: PortDirection.output,
            ),
          ],
        ),
        RoutingAlgorithm(
          id: 'algo_2',
          index: 1, // Slot 2
          algorithm: Algorithm(
            algorithmIndex: 1,
            guid: 'test-guid-2',
            name: 'Test Algorithm 2',
          ),
          inputPorts: [
            const Port(
              id: 'algo_2_port_1',
              name: 'Input 1',
              type: PortType.audio,
              direction: PortDirection.input,
            ),
          ],
          outputPorts: [
            const Port(
              id: 'algo_2_port_2',
              name: 'Output 1',
              type: PortType.audio,
              direction: PortDirection.output,
            ),
          ],
        ),
        RoutingAlgorithm(
          id: 'algo_3',
          index: 2, // Slot 3
          algorithm: Algorithm(
            algorithmIndex: 2,
            guid: 'test-guid-3',
            name: 'Test Algorithm 3',
          ),
          inputPorts: [
            const Port(
              id: 'algo_3_port_1',
              name: 'Input 1',
              type: PortType.audio,
              direction: PortDirection.input,
            ),
          ],
          outputPorts: [
            const Port(
              id: 'algo_3_port_2',
              name: 'Output 1',
              type: PortType.audio,
              direction: PortDirection.output,
            ),
          ],
        ),
      ];
    });

    group('validateConnections', () {
      test('should mark connection as invalid when source slot > target slot', () {
        // Connection from slot 3 to slot 1 (invalid)
        final connections = [
          const Connection(
            id: 'conn_1',
            sourcePortId: 'algo_3_port_2', // From algo 3 (slot 3)
            targetPortId: 'algo_1_port_1',  // To algo 1 (slot 1)
          ),
        ];

        final validated = ConnectionValidator.validateConnections(
          connections,
          testAlgorithms,
        );

        expect(validated.length, 1);
        expect(validated[0].properties?['isInvalidOrder'], true);
        expect(validated[0].properties?['sourceSlotIndex'], 2);
        expect(validated[0].properties?['targetSlotIndex'], 0);
      });

      test('should not mark connection as invalid when source slot < target slot', () {
        // Connection from slot 1 to slot 2 (valid)
        final connections = [
          const Connection(
            id: 'conn_1',
            sourcePortId: 'algo_1_port_2', // From algo 1 (slot 1)
            targetPortId: 'algo_2_port_1',  // To algo 2 (slot 2)
          ),
        ];

        final validated = ConnectionValidator.validateConnections(
          connections,
          testAlgorithms,
        );

        expect(validated.length, 1);
        expect(validated[0].properties?['isInvalidOrder'], null);
      });

      test('should not mark connection as invalid when source slot == target slot', () {
        // Self-connection within same algorithm (edge case)
        final connections = [
          const Connection(
            id: 'conn_1',
            sourcePortId: 'algo_2_port_2', // From algo 2 (slot 2)
            targetPortId: 'algo_2_port_1',  // To algo 2 (slot 2)
          ),
        ];

        final validated = ConnectionValidator.validateConnections(
          connections,
          testAlgorithms,
        );

        expect(validated.length, 1);
        expect(validated[0].properties?['isInvalidOrder'], null);
      });

      test('should skip validation for physical input connections', () {
        // Connection from physical input
        final connections = [
          const Connection(
            id: 'conn_1',
            sourcePortId: 'hw_in_1',       // Physical input
            targetPortId: 'algo_3_port_1',  // To algo 3 (slot 3)
          ),
        ];

        final validated = ConnectionValidator.validateConnections(
          connections,
          testAlgorithms,
        );

        expect(validated.length, 1);
        expect(validated[0].properties?['isInvalidOrder'], null);
      });

      test('should skip validation for physical output connections', () {
        // Connection to physical output
        final connections = [
          const Connection(
            id: 'conn_1',
            sourcePortId: 'algo_3_port_2',  // From algo 3 (slot 3)
            targetPortId: 'hw_out_1',       // Physical output
          ),
        ];

        final validated = ConnectionValidator.validateConnections(
          connections,
          testAlgorithms,
        );

        expect(validated.length, 1);
        expect(validated[0].properties?['isInvalidOrder'], null);
      });

      test('should preserve existing properties when adding validation flags', () {
        final connections = [
          Connection(
            id: 'conn_1',
            sourcePortId: 'algo_3_port_2',
            targetPortId: 'algo_1_port_1',
            properties: {
              'existingKey': 'existingValue',
              'metadata': {'foo': 'bar'},
            },
          ),
        ];

        final validated = ConnectionValidator.validateConnections(
          connections,
          testAlgorithms,
        );

        expect(validated[0].properties?['existingKey'], 'existingValue');
        expect(validated[0].properties?['metadata'], {'foo': 'bar'});
        expect(validated[0].properties?['isInvalidOrder'], true);
      });

      test('should handle multiple connections with mixed validity', () {
        final connections = [
          const Connection(
            id: 'conn_1',
            sourcePortId: 'algo_1_port_2',  // Valid: 1 -> 2
            targetPortId: 'algo_2_port_1',
          ),
          const Connection(
            id: 'conn_2',
            sourcePortId: 'algo_3_port_2',  // Invalid: 3 -> 1
            targetPortId: 'algo_1_port_1',
          ),
          const Connection(
            id: 'conn_3',
            sourcePortId: 'hw_in_1',        // Physical: always valid
            targetPortId: 'algo_2_port_1',
          ),
          const Connection(
            id: 'conn_4',
            sourcePortId: 'algo_2_port_2',  // Valid: 2 -> 3
            targetPortId: 'algo_3_port_1',
          ),
        ];

        final validated = ConnectionValidator.validateConnections(
          connections,
          testAlgorithms,
        );

        expect(validated.length, 4);
        expect(validated[0].properties?['isInvalidOrder'], null); // Valid
        expect(validated[1].properties?['isInvalidOrder'], true); // Invalid
        expect(validated[2].properties?['isInvalidOrder'], null); // Physical
        expect(validated[3].properties?['isInvalidOrder'], null); // Valid
      });

      test('should handle unknown port IDs gracefully', () {
        final connections = [
          const Connection(
            id: 'conn_1',
            sourcePortId: 'unknown_port_1',
            targetPortId: 'unknown_port_2',
          ),
        ];

        final validated = ConnectionValidator.validateConnections(
          connections,
          testAlgorithms,
        );

        expect(validated.length, 1);
        expect(validated[0].properties?['isInvalidOrder'], null);
      });

      test('should handle empty connections list', () {
        final validated = ConnectionValidator.validateConnections(
          [],
          testAlgorithms,
        );

        expect(validated, isEmpty);
      });

      test('should handle empty algorithms list', () {
        final connections = [
          const Connection(
            id: 'conn_1',
            sourcePortId: 'algo_1_port_2',
            targetPortId: 'algo_2_port_1',
          ),
        ];

        final validated = ConnectionValidator.validateConnections(
          connections,
          [],
        );

        expect(validated.length, 1);
        expect(validated[0].properties?['isInvalidOrder'], null);
      });
    });

    group('isPhysicalConnection', () {
      test('should identify physical input connections', () {
        final connection = const Connection(
          id: 'conn_1',
          sourcePortId: 'hw_in_1',
          targetPortId: 'algo_1_port_1',
        );

        expect(ConnectionValidator.isPhysicalConnection(connection), true);
      });

      test('should identify physical output connections', () {
        final connection = const Connection(
          id: 'conn_1',
          sourcePortId: 'algo_1_port_2',
          targetPortId: 'hw_out_1',
        );

        expect(ConnectionValidator.isPhysicalConnection(connection), true);
      });

      test('should identify non-physical connections', () {
        final connection = const Connection(
          id: 'conn_1',
          sourcePortId: 'algo_1_port_2',
          targetPortId: 'algo_2_port_1',
        );

        expect(ConnectionValidator.isPhysicalConnection(connection), false);
      });
    });

    group('findAlgorithmIndex', () {
      test('should find algorithm index for input port', () {
        final index = ConnectionValidator.findAlgorithmIndex(
          'algo_2_port_1',
          testAlgorithms,
        );

        expect(index, 1);
      });

      test('should find algorithm index for output port', () {
        final index = ConnectionValidator.findAlgorithmIndex(
          'algo_3_port_2',
          testAlgorithms,
        );

        expect(index, 2);
      });

      test('should return null for unknown port', () {
        final index = ConnectionValidator.findAlgorithmIndex(
          'unknown_port',
          testAlgorithms,
        );

        expect(index, null);
      });

      test('should return null for physical port', () {
        final index = ConnectionValidator.findAlgorithmIndex(
          'hw_in_1',
          testAlgorithms,
        );

        expect(index, null);
      });
    });
  });
}