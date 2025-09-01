import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/cubit/routing_editor_cubit.dart';
import 'package:nt_helper/ui/widgets/routing/connection_painter.dart';
import 'package:nt_helper/domain/disting_nt_sysex.dart';
import 'package:nt_helper/core/routing/services/connection_validator.dart';

void main() {
  group('RoutingEditor Connection Validation Integration', () {
    testWidgets('ConnectionData correctly extracts isInvalidOrder from connection properties', (tester) async {
      // Test the integration between Connection properties and ConnectionData isInvalidOrder getter
      
      // Create a connection with invalid order flag
      final invalidConnection = Connection(
        id: 'invalid_conn_1',
        sourcePortId: 'algo_1_out_1',
        targetPortId: 'algo_0_in_1',
        properties: {
          'isInvalidOrder': true,
          'sourceSlotIndex': 1,
          'targetSlotIndex': 0,
        },
      );

      // Create ConnectionData using the connection
      final connectionData = ConnectionData(
        connection: invalidConnection,
        sourcePosition: const Offset(100, 100),
        destinationPosition: const Offset(200, 200),
      );

      // Verify the isInvalidOrder getter works correctly
      expect(connectionData.isInvalidOrder, isTrue);
      expect(connectionData.connection.properties?['isInvalidOrder'], isTrue);
    });

    testWidgets('ConnectionData defaults isInvalidOrder to false when flag is missing', (tester) async {
      // Create a connection without invalid order flag
      final validConnection = Connection(
        id: 'valid_conn_1',
        sourcePortId: 'algo_0_out_1',
        targetPortId: 'algo_1_in_1',
        // No properties or isInvalidOrder flag
      );

      // Create ConnectionData using the connection
      final connectionData = ConnectionData(
        connection: validConnection,
        sourcePosition: const Offset(100, 100),
        destinationPosition: const Offset(200, 200),
      );

      // Verify the isInvalidOrder getter defaults to false
      expect(connectionData.isInvalidOrder, isFalse);
      expect(connectionData.connection.properties?['isInvalidOrder'], isNull);
    });

    testWidgets('ConnectionData handles null properties gracefully', (tester) async {
      // Create a connection with null properties
      final connection = Connection(
        id: 'conn_1',
        sourcePortId: 'algo_0_out_1',
        targetPortId: 'algo_1_in_1',
        properties: null,
      );

      // Create ConnectionData using the connection
      final connectionData = ConnectionData(
        connection: connection,
        sourcePosition: const Offset(100, 100),
        destinationPosition: const Offset(200, 200),
      );

      // Verify the isInvalidOrder getter handles null properties
      expect(connectionData.isInvalidOrder, isFalse);
      expect(connectionData.connection.properties, isNull);
    });

    testWidgets('ConnectionData handles empty properties gracefully', (tester) async {
      // Create a connection with empty properties
      final connection = Connection(
        id: 'conn_1',
        sourcePortId: 'algo_0_out_1',
        targetPortId: 'algo_1_in_1',
        properties: {},
      );

      // Create ConnectionData using the connection
      final connectionData = ConnectionData(
        connection: connection,
        sourcePosition: const Offset(100, 100),
        destinationPosition: const Offset(200, 200),
      );

      // Verify the isInvalidOrder getter handles empty properties
      expect(connectionData.isInvalidOrder, isFalse);
      expect(connectionData.connection.properties?['isInvalidOrder'], isNull);
    });

    testWidgets('ConnectionPainter correctly groups invalid connections', (tester) async {
      // Create test connections with mixed validity
      final validConnection = Connection(
        id: 'valid_conn_1',
        sourcePortId: 'algo_0_out_1',
        targetPortId: 'algo_1_in_1',
      );

      final invalidConnection = Connection(
        id: 'invalid_conn_1',
        sourcePortId: 'algo_1_out_1',
        targetPortId: 'algo_0_in_1',
        properties: {
          'isInvalidOrder': true,
          'sourceSlotIndex': 1,
          'targetSlotIndex': 0,
        },
      );

      // Create ConnectionData objects
      final connectionDataList = [
        ConnectionData(
          connection: validConnection,
          sourcePosition: const Offset(100, 100),
          destinationPosition: const Offset(200, 200),
        ),
        ConnectionData(
          connection: invalidConnection,
          sourcePosition: const Offset(300, 300),
          destinationPosition: const Offset(400, 400),
        ),
      ];

      // Create ConnectionPainter
      final painter = ConnectionPainter(
        connections: connectionDataList,
        theme: ThemeData(),
      );

      // Verify the painter receives the connections
      expect(painter.connections, hasLength(2));
      
      // Verify one connection is valid and one is invalid
      final validConnections = painter.connections.where((conn) => !conn.isInvalidOrder).toList();
      final invalidConnections = painter.connections.where((conn) => conn.isInvalidOrder).toList();
      
      expect(validConnections, hasLength(1));
      expect(invalidConnections, hasLength(1));
      
      expect(validConnections.first.connection.id, equals('valid_conn_1'));
      expect(invalidConnections.first.connection.id, equals('invalid_conn_1'));
    });

    testWidgets('ConnectionPainter handles multiple invalid connections', (tester) async {
      // Create multiple invalid connections
      final invalidConnection1 = Connection(
        id: 'invalid_conn_1',
        sourcePortId: 'algo_2_out_1',
        targetPortId: 'algo_0_in_1',
        properties: {
          'isInvalidOrder': true,
          'sourceSlotIndex': 2,
          'targetSlotIndex': 0,
        },
      );

      final invalidConnection2 = Connection(
        id: 'invalid_conn_2',
        sourcePortId: 'algo_2_out_2',
        targetPortId: 'algo_1_in_1',
        properties: {
          'isInvalidOrder': true,
          'sourceSlotIndex': 2,
          'targetSlotIndex': 1,
        },
      );

      // Create ConnectionData objects
      final connectionDataList = [
        ConnectionData(
          connection: invalidConnection1,
          sourcePosition: const Offset(100, 100),
          destinationPosition: const Offset(200, 200),
        ),
        ConnectionData(
          connection: invalidConnection2,
          sourcePosition: const Offset(300, 300),
          destinationPosition: const Offset(400, 400),
        ),
      ];

      // Create ConnectionPainter
      final painter = ConnectionPainter(
        connections: connectionDataList,
        theme: ThemeData(),
      );

      // Verify all connections are marked as invalid
      expect(painter.connections, hasLength(2));
      expect(painter.connections.every((conn) => conn.isInvalidOrder), isTrue);
      
      // Verify connection IDs
      final connectionIds = painter.connections.map((conn) => conn.connection.id).toList();
      expect(connectionIds, contains('invalid_conn_1'));
      expect(connectionIds, contains('invalid_conn_2'));
    });

    test('Integration: ConnectionValidator -> ConnectionData -> ConnectionPainter flow', () {
      // Test the complete data flow from validator to painter
      
      // Create test algorithms
      final algorithms = [
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
              id: 'algo_1_in_1',
              name: 'Input 1',
              type: PortType.cv,
              direction: PortDirection.input,
            ),
          ],
          outputPorts: [
            const Port(
              id: 'algo_1_out_1',
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
              id: 'algo_2_in_1',
              name: 'Input 1',
              type: PortType.audio,
              direction: PortDirection.input,
            ),
          ],
          outputPorts: [
            const Port(
              id: 'algo_2_out_1',
              name: 'Output 1',
              type: PortType.audio,
              direction: PortDirection.output,
            ),
          ],
        ),
      ];

      // Create a connection that violates slot ordering (slot 2 -> slot 1)
      final invalidConnection = Connection(
        id: 'test_connection',
        sourcePortId: 'algo_2_out_1', // From slot 2 (index 1)
        targetPortId: 'algo_1_in_1',  // To slot 1 (index 0)
      );

      // Step 1: ConnectionValidator marks the connection as invalid
      final validatedConnections = ConnectionValidator.validateConnections(
        [invalidConnection],
        algorithms,
      );

      // Verify validator marked the connection as invalid
      expect(validatedConnections, hasLength(1));
      final validatedConnection = validatedConnections.first;
      expect(validatedConnection.properties?['isInvalidOrder'], isTrue);
      expect(validatedConnection.properties?['sourceSlotIndex'], equals(1));
      expect(validatedConnection.properties?['targetSlotIndex'], equals(0));

      // Step 2: ConnectionData extracts the flag correctly
      final connectionData = ConnectionData(
        connection: validatedConnection,
        sourcePosition: const Offset(100, 100),
        destinationPosition: const Offset(200, 200),
      );

      expect(connectionData.isInvalidOrder, isTrue);

      // Step 3: ConnectionPainter receives the invalid connection
      final painter = ConnectionPainter(
        connections: [connectionData],
        theme: ThemeData(),
      );

      expect(painter.connections, hasLength(1));
      expect(painter.connections.first.isInvalidOrder, isTrue);
      expect(painter.connections.first.connection.id, equals('test_connection'));
    });

    test('Integration: Valid connection flow remains unchanged', () {
      // Test that valid connections are not affected by the validation system
      
      // Create test algorithms
      final algorithms = [
        RoutingAlgorithm(
          id: 'algo_1',
          index: 0, // Slot 1
          algorithm: Algorithm(
            algorithmIndex: 0,
            guid: 'test-guid-1',
            name: 'Test Algorithm 1',
          ),
          inputPorts: [],
          outputPorts: [
            const Port(
              id: 'algo_1_out_1',
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
              id: 'algo_2_in_1',
              name: 'Input 1',
              type: PortType.audio,
              direction: PortDirection.input,
            ),
          ],
          outputPorts: [],
        ),
      ];

      // Create a valid connection (slot 1 -> slot 2)
      final validConnection = Connection(
        id: 'test_connection',
        sourcePortId: 'algo_1_out_1', // From slot 1 (index 0)
        targetPortId: 'algo_2_in_1',  // To slot 2 (index 1)
      );

      // Step 1: ConnectionValidator processes the connection
      final validatedConnections = ConnectionValidator.validateConnections(
        [validConnection],
        algorithms,
      );

      // Verify validator left the connection unchanged
      expect(validatedConnections, hasLength(1));
      final validatedConnection = validatedConnections.first;
      expect(validatedConnection.properties?['isInvalidOrder'], isNull);

      // Step 2: ConnectionData extracts the flag correctly
      final connectionData = ConnectionData(
        connection: validatedConnection,
        sourcePosition: const Offset(100, 100),
        destinationPosition: const Offset(200, 200),
      );

      expect(connectionData.isInvalidOrder, isFalse);

      // Step 3: ConnectionPainter receives the valid connection
      final painter = ConnectionPainter(
        connections: [connectionData],
        theme: ThemeData(),
      );

      expect(painter.connections, hasLength(1));
      expect(painter.connections.first.isInvalidOrder, isFalse);
      expect(painter.connections.first.connection.id, equals('test_connection'));
    });
  });
}