import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/core/routing/models/routing_state.dart';
import 'package:nt_helper/core/routing/models/port.dart';
import 'package:nt_helper/core/routing/models/connection.dart';

void main() {
  group('RoutingState Model Tests', () {
    late List<Port> testInputPorts;
    late List<Port> testOutputPorts;
    late List<Connection> testConnections;

    setUp(() {
      testInputPorts = [
        const Port(
          id: 'input1',
          name: 'Audio Input 1',
          type: PortType.audio,
          direction: PortDirection.input,
        ),
        const Port(
          id: 'input2',
          name: 'CV Input 1',
          type: PortType.cv,
          direction: PortDirection.input,
        ),
      ];

      testOutputPorts = [
        const Port(
          id: 'output1',
          name: 'Audio Output 1',
          type: PortType.audio,
          direction: PortDirection.output,
        ),
        const Port(
          id: 'output2',
          name: 'Gate Output 1',
          type: PortType.gate,
          direction: PortDirection.output,
        ),
      ];

      testConnections = [
        const Connection(
          id: 'conn1',
          sourcePortId: 'output1',
          destinationPortId: 'input1',
          connectionType: ConnectionType.algorithmToAlgorithm,
          status: ConnectionStatus.active,
        ),
        const Connection(
          id: 'conn2',
          sourcePortId: 'output2',
          destinationPortId: 'input2',
          connectionType: ConnectionType.algorithmToAlgorithm,
          status: ConnectionStatus.error,
        ),
      ];
    });

    test('should create routing state with default values', () {
      const state = RoutingState();

      expect(state.status, equals(RoutingSystemStatus.uninitialized));
      expect(state.inputPorts, isEmpty);
      expect(state.outputPorts, isEmpty);
      expect(state.connections, isEmpty);
      expect(state.isReadOnly, isFalse);
      expect(state.errorMessage, isNull);
    });

    test('should create routing state with all fields', () {
      final now = DateTime.now();
      final state = RoutingState(
        status: RoutingSystemStatus.ready,
        inputPorts: testInputPorts,
        outputPorts: testOutputPorts,
        connections: testConnections,
        errorMessage: 'Test error',
        createdAt: now,
        lastUpdated: now,
        isReadOnly: true,
        configuration: {'setting': 'value'},
        metadata: {'version': '1.0'},
      );

      expect(state.status, equals(RoutingSystemStatus.ready));
      expect(state.inputPorts, equals(testInputPorts));
      expect(state.outputPorts, equals(testOutputPorts));
      expect(state.connections, equals(testConnections));
      expect(state.errorMessage, equals('Test error'));
      expect(state.createdAt, equals(now));
      expect(state.lastUpdated, equals(now));
      expect(state.isReadOnly, isTrue);
      expect(state.configuration?['setting'], equals('value'));
      expect(state.metadata?['version'], equals('1.0'));
    });

    // TODO: Fix JSON serialization for complex nested models
    // test('should serialize to and from JSON correctly', () {
    //   final originalState = RoutingState(
    //     status: RoutingSystemStatus.ready,
    //     inputPorts: testInputPorts,
    //     outputPorts: testOutputPorts,
    //     connections: testConnections,
    //     isReadOnly: true,
    //     configuration: {'test': true},
    //   );

    //   final json = originalState.toJson();
    //   final deserializedState = RoutingState.fromJson(json);

    //   expect(deserializedState, equals(originalState));
    //   expect(deserializedState.status, equals(originalState.status));
    //   expect(deserializedState.inputPorts, equals(originalState.inputPorts));
    //   expect(deserializedState.outputPorts, equals(originalState.outputPorts));
    //   expect(deserializedState.connections, equals(originalState.connections));
    //   expect(deserializedState.isReadOnly, equals(originalState.isReadOnly));
    //   expect(deserializedState.configuration, equals(originalState.configuration));
    // });

    group('Status Check Methods Tests', () {
      test('should correctly identify ready state', () {
        const state = RoutingState(status: RoutingSystemStatus.ready);

        expect(state.isReady, isTrue);
        expect(state.isUpdating, isFalse);
        expect(state.hasError, isFalse);
        expect(state.isInitializing, isFalse);
      });

      test('should correctly identify updating state', () {
        const state = RoutingState(status: RoutingSystemStatus.updating);

        expect(state.isReady, isFalse);
        expect(state.isUpdating, isTrue);
        expect(state.hasError, isFalse);
        expect(state.isInitializing, isFalse);
      });

      test('should correctly identify error state', () {
        const state = RoutingState(status: RoutingSystemStatus.error);

        expect(state.isReady, isFalse);
        expect(state.isUpdating, isFalse);
        expect(state.hasError, isTrue);
        expect(state.isInitializing, isFalse);
      });

      test('should correctly identify initializing state', () {
        const state = RoutingState(status: RoutingSystemStatus.initializing);

        expect(state.isReady, isFalse);
        expect(state.isUpdating, isFalse);
        expect(state.hasError, isFalse);
        expect(state.isInitializing, isTrue);
      });
    });

    group('Port and Connection Access Tests', () {
      late RoutingState state;

      setUp(() {
        state = RoutingState(
          inputPorts: testInputPorts,
          outputPorts: testOutputPorts,
          connections: testConnections,
        );
      });

      test('should return all ports combined', () {
        final allPorts = state.allPorts;

        expect(allPorts.length, equals(4));
        expect(allPorts.contains(testInputPorts[0]), isTrue);
        expect(allPorts.contains(testInputPorts[1]), isTrue);
        expect(allPorts.contains(testOutputPorts[0]), isTrue);
        expect(allPorts.contains(testOutputPorts[1]), isTrue);
      });

      test('should count active connections correctly', () {
        expect(state.activeConnectionCount, equals(1)); // only conn1 is active
      });

      test('should count error connections correctly', () {
        expect(state.errorConnectionCount, equals(1)); // only conn2 has error
      });

      test('should find port by ID', () {
        final foundPort = state.findPortById('input1');
        expect(foundPort, equals(testInputPorts[0]));

        final notFoundPort = state.findPortById('nonexistent');
        expect(notFoundPort, isNull);
      });

      test('should find connection by ID', () {
        final foundConnection = state.findConnectionById('conn1');
        expect(foundConnection, equals(testConnections[0]));

        final notFoundConnection = state.findConnectionById('nonexistent');
        expect(notFoundConnection, isNull);
      });

      test('should get connections for port', () {
        final input1Connections = state.getConnectionsForPort('input1');
        expect(input1Connections.length, equals(1));
        expect(input1Connections[0].id, equals('conn1'));

        final output1Connections = state.getConnectionsForPort('output1');
        expect(output1Connections.length, equals(1));
        expect(output1Connections[0].id, equals('conn1'));

        final noConnections = state.getConnectionsForPort('nonexistent');
        expect(noConnections, isEmpty);
      });

      test('should get input connections for port', () {
        final input1Connections = state.getInputConnectionsForPort('input1');
        expect(input1Connections.length, equals(1));
        expect(input1Connections[0].sourcePortId, equals('output1'));

        final output1Connections = state.getInputConnectionsForPort('output1');
        expect(output1Connections, isEmpty);
      });

      test('should get output connections for port', () {
        final output1Connections = state.getOutputConnectionsForPort('output1');
        expect(output1Connections.length, equals(1));
        expect(output1Connections[0].destinationPortId, equals('input1'));

        final input1Connections = state.getOutputConnectionsForPort('input1');
        expect(input1Connections, isEmpty);
      });
    });

    group('State Modification Tests', () {
      test('withStatus should update status and lastUpdated', () {
        final originalState = RoutingState(
          status: RoutingSystemStatus.uninitialized,
          lastUpdated: DateTime(2023, 1, 1),
        );

        final updatedState = originalState.withStatus(
          RoutingSystemStatus.ready,
          errorMessage: 'Test error',
        );

        expect(updatedState.status, equals(RoutingSystemStatus.ready));
        expect(updatedState.errorMessage, equals('Test error'));
        expect(
          updatedState.lastUpdated,
          isNot(equals(originalState.lastUpdated)),
        );
        expect(
          updatedState.lastUpdated!.isAfter(originalState.lastUpdated!),
          isTrue,
        );
      });

      test(
        'withAddedConnection should add connection and update lastUpdated',
        () {
          const originalState = RoutingState();
          const newConnection = Connection(
            id: 'new_conn',
            sourcePortId: 'src',
            destinationPortId: 'dest',
            connectionType: ConnectionType.algorithmToAlgorithm,
          );

          final updatedState = originalState.withAddedConnection(newConnection);

          expect(updatedState.connections.length, equals(1));
          expect(updatedState.connections[0], equals(newConnection));
          expect(updatedState.lastUpdated, isNotNull);
        },
      );

      test(
        'withRemovedConnection should remove connection and update lastUpdated',
        () {
          final originalState = RoutingState(connections: testConnections);

          final updatedState = originalState.withRemovedConnection('conn1');

          expect(updatedState.connections.length, equals(1));
          expect(updatedState.connections[0].id, equals('conn2'));
          expect(updatedState.lastUpdated, isNotNull);
        },
      );

      test('withUpdatedConnection should update existing connection', () {
        final originalState = RoutingState(connections: testConnections);
        final updatedConnection = testConnections[0].copyWith(
          status: ConnectionStatus.disabled,
        );

        final updatedState = originalState.withUpdatedConnection(
          updatedConnection,
        );

        expect(updatedState.connections.length, equals(2));
        final foundConnection = updatedState.findConnectionById('conn1');
        expect(foundConnection!.status, equals(ConnectionStatus.disabled));
        expect(updatedState.lastUpdated, isNotNull);
      });

      test('withUpdatedPorts should update ports and lastUpdated', () {
        const originalState = RoutingState();
        final newInputPorts = [testInputPorts[0]];
        final newOutputPorts = [testOutputPorts[0]];

        final updatedState = originalState.withUpdatedPorts(
          inputPorts: newInputPorts,
          outputPorts: newOutputPorts,
        );

        expect(updatedState.inputPorts, equals(newInputPorts));
        expect(updatedState.outputPorts, equals(newOutputPorts));
        expect(updatedState.lastUpdated, isNotNull);
      });

      test('withUpdatedPorts should update only specified ports', () {
        final originalState = RoutingState(
          inputPorts: testInputPorts,
          outputPorts: testOutputPorts,
        );
        final newInputPorts = [testInputPorts[0]];

        final updatedState = originalState.withUpdatedPorts(
          inputPorts: newInputPorts,
        );

        expect(updatedState.inputPorts, equals(newInputPorts));
        expect(updatedState.outputPorts, equals(testOutputPorts)); // unchanged
      });
    });

    group('State Validation Tests', () {
      test('should validate valid state', () {
        final state = RoutingState(
          inputPorts: testInputPorts,
          outputPorts: testOutputPorts,
          connections: testConnections,
        );

        expect(state.validateState(), isTrue);
      });

      test('should invalidate state with invalid connections', () {
        const invalidConnections = [
          Connection(
            id: 'invalid',
            sourcePortId: 'nonexistent_source',
            destinationPortId: 'input1',
            connectionType: ConnectionType.algorithmToAlgorithm,
          ),
        ];

        final state = RoutingState(
          inputPorts: testInputPorts,
          outputPorts: testOutputPorts,
          connections: invalidConnections,
        );

        expect(state.validateState(), isFalse);
      });
    });

    group('Routing State Equality Tests', () {
      test('states with same values should be equal', () {
        final state1 = RoutingState(
          status: RoutingSystemStatus.ready,
          inputPorts: testInputPorts,
          outputPorts: testOutputPorts,
        );

        final state2 = RoutingState(
          status: RoutingSystemStatus.ready,
          inputPorts: testInputPorts,
          outputPorts: testOutputPorts,
        );

        expect(state1, equals(state2));
        expect(state1.hashCode, equals(state2.hashCode));
      });

      test('states with different values should not be equal', () {
        final state1 = RoutingState(
          status: RoutingSystemStatus.ready,
          inputPorts: testInputPorts,
        );

        final state2 = RoutingState(
          status: RoutingSystemStatus.error,
          inputPorts: testInputPorts,
        );

        expect(state1, isNot(equals(state2)));
      });
    });
  });
}
