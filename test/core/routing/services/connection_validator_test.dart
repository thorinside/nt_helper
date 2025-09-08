import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/core/routing/models/connection.dart';
import 'package:nt_helper/core/routing/services/connection_validator.dart';
import 'package:nt_helper/cubit/routing_editor_state.dart';
import 'package:nt_helper/domain/disting_nt_sysex.dart';
import 'package:nt_helper/core/routing/models/port.dart';

void main() {
  group('ConnectionValidator Tests', () {
    late List<RoutingAlgorithm> testAlgorithms;
    
    setUp(() {
      // Create test algorithms with various slot configurations
      testAlgorithms = [
        RoutingAlgorithm(
          id: 'alg_1',
          index: 0,
          algorithm: Algorithm(
            algorithmIndex: 0,
            guid: 'test-guid-1',
            name: 'Algorithm 1',
          ),
          inputPorts: [
            Port(
              id: 'alg_1_input_1',
              name: 'Input 1',
              type: PortType.cv,
              direction: PortDirection.input,
            ),
          ],
          outputPorts: [
            Port(
              id: 'alg_1_output_1',
              name: 'Output 1',
              type: PortType.cv,
              direction: PortDirection.output,
            ),
          ],
        ),
        RoutingAlgorithm(
          id: 'alg_2',
          index: 1,
          algorithm: Algorithm(
            algorithmIndex: 1,
            guid: 'test-guid-2',
            name: 'Algorithm 2',
          ),
          inputPorts: [
            Port(
              id: 'alg_2_input_1',
              name: 'Input 1',
              type: PortType.audio,
              direction: PortDirection.input,
            ),
          ],
          outputPorts: [
            Port(
              id: 'alg_2_output_1',
              name: 'Output 1',
              type: PortType.audio,
              direction: PortDirection.output,
            ),
          ],
        ),
        RoutingAlgorithm(
          id: 'alg_3',
          index: 2,
          algorithm: Algorithm(
            algorithmIndex: 2,
            guid: 'test-guid-3',
            name: 'Algorithm 3',
          ),
          inputPorts: [
            Port(
              id: 'alg_3_input_1',
              name: 'Input 1',
              type: PortType.gate,
              direction: PortDirection.input,
            ),
          ],
          outputPorts: [
            Port(
              id: 'alg_3_output_1',
              name: 'Output 1',
              type: PortType.gate,
              direction: PortDirection.output,
            ),
          ],
        ),
      ];
    });

    group('validateConnections', () {
      test('should mark connection as invalid when source slot > destination slot', () {
        final connections = [
          Connection(
            id: 'invalid_connection',
            sourcePortId: 'alg_2_output_1', // Algorithm at index 1
            destinationPortId: 'alg_1_input_1', // Algorithm at index 0
            connectionType: ConnectionType.algorithmToAlgorithm,
          ),
        ];

        final validatedConnections = ConnectionValidator.validateConnections(
          connections,
          testAlgorithms,
        );

        expect(validatedConnections.length, equals(1));
        expect(validatedConnections.first.isBackwardEdge, isTrue);
      });

      test('should keep connection as valid when source slot <= destination slot', () {
        final connections = [
          Connection(
            id: 'valid_connection',
            sourcePortId: 'alg_1_output_1', // Algorithm at index 0
            destinationPortId: 'alg_2_input_1', // Algorithm at index 1
            connectionType: ConnectionType.algorithmToAlgorithm,
          ),
        ];

        final validatedConnections = ConnectionValidator.validateConnections(
          connections,
          testAlgorithms,
        );

        expect(validatedConnections.length, equals(1));
        expect(validatedConnections.first.isBackwardEdge, isFalse);
      });

      test('should handle same-slot connections as valid', () {
        final connections = [
          Connection(
            id: 'same_slot_connection',
            sourcePortId: 'alg_1_output_1', // Algorithm at index 0
            destinationPortId: 'alg_1_input_1', // Same algorithm at index 0
            connectionType: ConnectionType.algorithmToAlgorithm,
          ),
        ];

        final validatedConnections = ConnectionValidator.validateConnections(
          connections,
          testAlgorithms,
        );

        expect(validatedConnections.length, equals(1));
        expect(validatedConnections.first.isBackwardEdge, isFalse);
      });

      test('should leave physical connections unchanged and valid', () {
        final connections = [
          Connection(
            id: 'hw_input_connection',
            sourcePortId: 'hw_in_1',
            destinationPortId: 'alg_1_input_1',
            connectionType: ConnectionType.hardwareInput,
          ),
          Connection(
            id: 'hw_output_connection',
            sourcePortId: 'alg_1_output_1',
            destinationPortId: 'hw_out_1',
            connectionType: ConnectionType.hardwareOutput,
          ),
        ];

        final validatedConnections = ConnectionValidator.validateConnections(
          connections,
          testAlgorithms,
        );

        expect(validatedConnections.length, equals(2));
        for (final connection in validatedConnections) {
          expect(connection.isBackwardEdge, isFalse);
        }
      });

      test('should handle connections with unknown ports as valid', () {
        final connections = [
          Connection(
            id: 'unknown_port_connection',
            sourcePortId: 'unknown_port_1',
            destinationPortId: 'alg_1_input_1',
            connectionType: ConnectionType.algorithmToAlgorithm,
          ),
        ];

        final validatedConnections = ConnectionValidator.validateConnections(
          connections,
          testAlgorithms,
        );

        expect(validatedConnections.length, equals(1));
        expect(validatedConnections.first.isBackwardEdge, isFalse);
      });

      test('should handle mixed valid and invalid connections', () {
        final connections = [
          Connection(
            id: 'valid_connection',
            sourcePortId: 'alg_1_output_1', // Index 0 -> Index 1 (valid)
            destinationPortId: 'alg_2_input_1',
            connectionType: ConnectionType.algorithmToAlgorithm,
          ),
          Connection(
            id: 'invalid_connection',
            sourcePortId: 'alg_3_output_1', // Index 2 -> Index 0 (invalid)
            destinationPortId: 'alg_1_input_1',
            connectionType: ConnectionType.algorithmToAlgorithm,
          ),
          Connection(
            id: 'physical_connection',
            sourcePortId: 'hw_in_1',
            destinationPortId: 'alg_1_input_1',
            connectionType: ConnectionType.hardwareInput,
          ),
        ];

        final validatedConnections = ConnectionValidator.validateConnections(
          connections,
          testAlgorithms,
        );

        expect(validatedConnections.length, equals(3));
        
        final validConnection = validatedConnections.firstWhere((c) => c.id == 'valid_connection');
        final invalidConnection = validatedConnections.firstWhere((c) => c.id == 'invalid_connection');
        final physicalConnection = validatedConnections.firstWhere((c) => c.id == 'physical_connection');
        
        expect(validConnection.isBackwardEdge, isFalse);
        expect(invalidConnection.isBackwardEdge, isTrue);
        expect(physicalConnection.isBackwardEdge, isFalse);
      });

      test('should preserve all original connection properties', () {
        final originalConnection = Connection(
          id: 'test_connection',
          sourcePortId: 'alg_2_output_1',
          destinationPortId: 'alg_1_input_1',
          connectionType: ConnectionType.algorithmToAlgorithm,
          status: ConnectionStatus.disabled,
          name: 'Test Connection',
          gain: 0.8,
          isMuted: true,
          isInverted: true,
        );

        final validatedConnections = ConnectionValidator.validateConnections(
          [originalConnection],
          testAlgorithms,
        );

        final validatedConnection = validatedConnections.first;
        
        // Should be marked invalid due to slot ordering
        expect(validatedConnection.isBackwardEdge, isTrue);
        
        // All other properties should be preserved
        expect(validatedConnection.id, equals(originalConnection.id));
        expect(validatedConnection.sourcePortId, equals(originalConnection.sourcePortId));
        expect(validatedConnection.destinationPortId, equals(originalConnection.destinationPortId));
        expect(validatedConnection.connectionType, equals(originalConnection.connectionType));
        expect(validatedConnection.status, equals(originalConnection.status));
        expect(validatedConnection.name, equals(originalConnection.name));
        expect(validatedConnection.gain, equals(originalConnection.gain));
        expect(validatedConnection.isMuted, equals(originalConnection.isMuted));
        expect(validatedConnection.isInverted, equals(originalConnection.isInverted));
      });
    });

    group('isPhysicalConnection', () {
      test('should identify hardware input connections', () {
        const connection = Connection(
          id: 'hw_input',
          sourcePortId: 'hw_in_1',
          destinationPortId: 'alg_1_input_1',
          connectionType: ConnectionType.hardwareInput,
        );

        expect(ConnectionValidator.isPhysicalConnection(connection), isTrue);
      });

      test('should identify hardware output connections', () {
        const connection = Connection(
          id: 'hw_output',
          sourcePortId: 'alg_1_output_1',
          destinationPortId: 'hw_out_1',
          connectionType: ConnectionType.hardwareOutput,
        );

        expect(ConnectionValidator.isPhysicalConnection(connection), isTrue);
      });

      test('should identify algorithm-to-algorithm connections as non-physical', () {
        const connection = Connection(
          id: 'alg_connection',
          sourcePortId: 'alg_1_output_1',
          destinationPortId: 'alg_2_input_1',
          connectionType: ConnectionType.algorithmToAlgorithm,
        );

        expect(ConnectionValidator.isPhysicalConnection(connection), isFalse);
      });
    });

    group('findAlgorithmIndex', () {
      test('should find algorithm index for input port', () {
        final index = ConnectionValidator.findAlgorithmIndex(
          'alg_2_input_1',
          testAlgorithms,
        );

        expect(index, equals(1));
      });

      test('should find algorithm index for output port', () {
        final index = ConnectionValidator.findAlgorithmIndex(
          'alg_3_output_1',
          testAlgorithms,
        );

        expect(index, equals(2));
      });

      test('should return null for unknown port', () {
        final index = ConnectionValidator.findAlgorithmIndex(
          'unknown_port',
          testAlgorithms,
        );

        expect(index, isNull);
      });

      test('should return null for physical port', () {
        final index = ConnectionValidator.findAlgorithmIndex(
          'hw_in_1',
          testAlgorithms,
        );

        expect(index, isNull);
      });
    });

    group('edge cases', () {
      test('should handle empty connections list', () {
        final validatedConnections = ConnectionValidator.validateConnections(
          [],
          testAlgorithms,
        );

        expect(validatedConnections, isEmpty);
      });

      test('should handle empty algorithms list', () {
        final connections = [
          Connection(
            id: 'test_connection',
            sourcePortId: 'alg_1_output_1',
            destinationPortId: 'alg_2_input_1',
            connectionType: ConnectionType.algorithmToAlgorithm,
          ),
        ];

        final validatedConnections = ConnectionValidator.validateConnections(
          connections,
          [],
        );

        expect(validatedConnections.length, equals(1));
        expect(validatedConnections.first.isBackwardEdge, isFalse);
      });

      test('should handle partial connections as non-physical', () {
        const connection = Connection(
          id: 'partial_connection',
          sourcePortId: 'alg_1_output_1',
          destinationPortId: '',
          connectionType: ConnectionType.partialOutputToBus,
          isPartial: true,
          busNumber: 5,
        );

        // Partial connections should be validated like algorithm connections
        expect(ConnectionValidator.isPhysicalConnection(connection), isFalse);
      });
    });
  });
}