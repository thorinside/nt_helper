import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/cubit/routing_editor_cubit.dart';
import 'package:nt_helper/cubit/routing_editor_state.dart';
import 'package:nt_helper/core/routing/services/connection_validator.dart';
import 'package:nt_helper/core/routing/models/connection.dart';
import 'package:nt_helper/domain/disting_nt_sysex.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('RoutingEditorCubit Integration Tests', () {
    late RoutingEditorCubit routingEditorCubit;

    setUp(() {
      // Create cubit without DistingCubit dependency for unit testing
      routingEditorCubit = RoutingEditorCubit(null);
    });

    tearDown(() {
      routingEditorCubit.close();
    });

    group('Connection Validation Integration', () {
      test('should initialize with initial state', () {
        expect(routingEditorCubit.state, isA<RoutingEditorStateInitial>());
      });

      test('should maintain initial state when no disting cubit provided', () async {
        // Wait a bit to ensure no state changes occur
        await Future.delayed(Duration.zero);
        expect(routingEditorCubit.state, isA<RoutingEditorStateInitial>());
      });
    });

    group('ConnectionValidator Integration Tests', () {
      test('should correctly validate connections with slot ordering', () {
        // Create test algorithms
        final algorithms = [
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
        ];

        // Test connections - both valid and invalid
        final connections = [
          // Valid connection: slot 0 -> slot 1
          Connection(
            id: 'valid_connection',
            sourcePortId: 'alg_1_output_1',
            destinationPortId: 'alg_2_input_1',
            connectionType: ConnectionType.algorithmToAlgorithm,
          ),
          // Invalid connection: slot 1 -> slot 0
          Connection(
            id: 'invalid_connection',
            sourcePortId: 'alg_2_output_1',
            destinationPortId: 'alg_1_input_1',
            connectionType: ConnectionType.algorithmToAlgorithm,
          ),
        ];

        // Validate connections using the same logic as RoutingEditorCubit
        final validatedConnections = ConnectionValidator.validateConnections(
          connections,
          algorithms,
        );

        expect(validatedConnections.length, equals(2));

        // Find the connections
        final validConnection = validatedConnections
            .firstWhere((c) => c.id == 'valid_connection');
        final invalidConnection = validatedConnections
            .firstWhere((c) => c.id == 'invalid_connection');

        // Verify validation results
        expect(validConnection.isBackwardEdge, isFalse);
        expect(invalidConnection.isBackwardEdge, isTrue);
      });

      test('should handle physical connections correctly', () {
        final algorithms = [
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
        ];

        final connections = [
          // Physical input connection
          Connection(
            id: 'hw_input',
            sourcePortId: 'hw_in_1',
            destinationPortId: 'alg_1_input_1',
            connectionType: ConnectionType.hardwareInput,
          ),
          // Physical output connection
          Connection(
            id: 'hw_output',
            sourcePortId: 'alg_1_output_1',
            destinationPortId: 'hw_out_1',
            connectionType: ConnectionType.hardwareOutput,
          ),
        ];

        final validatedConnections = ConnectionValidator.validateConnections(
          connections,
          algorithms,
        );

        expect(validatedConnections.length, equals(2));

        // All physical connections should remain valid
        for (final connection in validatedConnections) {
          expect(connection.isBackwardEdge, isFalse);
        }
      });

      test('should generate stable port IDs', () {
        const algorithmId = 'test-algorithm-uuid-123';
        const parameterNumber = 42;
        const portType = 'input';

        final portId = routingEditorCubit.generatePortId(
          algorithmId: algorithmId,
          parameterNumber: parameterNumber,
          portType: portType,
        );

        expect(portId, equals('${algorithmId}_port_$parameterNumber'));
        
        // Should be consistent on repeated calls
        final portId2 = routingEditorCubit.generatePortId(
          algorithmId: algorithmId,
          parameterNumber: parameterNumber,
          portType: portType,
        );
        
        expect(portId, equals(portId2));
      });
    });

    group('Algorithm Reordering Validation', () {
      test('should validate connections when algorithm indices change', () {
        // Create two algorithm configurations - before and after reordering
        final algorithmsBeforeReorder = [
          RoutingAlgorithm(
            id: 'alg_1',
            index: 0, // Originally at index 0
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
            index: 1, // Originally at index 1
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
        ];

        final algorithmsAfterReorder = [
          RoutingAlgorithm(
            id: 'alg_2',
            index: 0, // Moved to index 0
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
            id: 'alg_1',
            index: 1, // Moved to index 1
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
        ];

        // Connection that goes from alg_2 to alg_1
        final connection = Connection(
          id: 'test_connection',
          sourcePortId: 'alg_2_output_1',
          destinationPortId: 'alg_1_input_1',
          connectionType: ConnectionType.algorithmToAlgorithm,
        );

        // Before reordering: alg_2 (index 1) -> alg_1 (index 0) = INVALID
        final beforeReorderValidated = ConnectionValidator.validateConnections(
          [connection],
          algorithmsBeforeReorder,
        );
        expect(beforeReorderValidated.first.isBackwardEdge, isTrue);

        // After reordering: alg_2 (index 0) -> alg_1 (index 1) = VALID
        final afterReorderValidated = ConnectionValidator.validateConnections(
          [connection],
          algorithmsAfterReorder,
        );
        expect(afterReorderValidated.first.isBackwardEdge, isFalse);
      });
    });
  });
}