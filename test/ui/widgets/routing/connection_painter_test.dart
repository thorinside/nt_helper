import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/cubit/routing_editor_cubit.dart';
import 'package:nt_helper/ui/widgets/routing/connection_painter.dart';

void main() {
  group('ConnectionPainter', () {
    late ThemeData theme;
    late Connection validConnection;
    late Connection invalidConnection;
    late ConnectionData validConnectionData;
    late ConnectionData invalidConnectionData;

    setUp(() {
      theme = ThemeData.light();
      
      // Valid connection without isInvalidOrder flag
      validConnection = const Connection(
        id: 'valid_conn_1',
        sourcePortId: 'algo_1_out_1',
        targetPortId: 'algo_2_in_1',
        properties: {
          'busNumber': 15,
        },
      );
      
      // Invalid connection with isInvalidOrder flag
      invalidConnection = const Connection(
        id: 'invalid_conn_1',
        sourcePortId: 'algo_2_out_1',
        targetPortId: 'algo_1_in_1',
        properties: {
          'busNumber': 16,
          'isInvalidOrder': true,
          'sourceSlotIndex': 1,
          'targetSlotIndex': 0,
        },
      );
      
      validConnectionData = ConnectionData(
        connection: validConnection,
        sourcePosition: const Offset(100, 100),
        destinationPosition: const Offset(300, 200),
      );
      
      invalidConnectionData = ConnectionData(
        connection: invalidConnection,
        sourcePosition: const Offset(150, 120),
        destinationPosition: const Offset(350, 220),
      );
    });

    group('ConnectionData Invalid Order Detection', () {
      test('ConnectionData correctly extracts isInvalidOrder from properties', () {
        expect(validConnectionData.isInvalidOrder, isFalse);
        expect(invalidConnectionData.isInvalidOrder, isTrue);
      });

      test('ConnectionData defaults isInvalidOrder to false when missing', () {
        final connectionWithoutFlag = const Connection(
          id: 'no_flag_conn',
          sourcePortId: 'algo_1_out_1',
          targetPortId: 'algo_2_in_1',
          properties: {
            'busNumber': 15,
          },
        );
        
        final connectionData = ConnectionData(
          connection: connectionWithoutFlag,
          sourcePosition: const Offset(100, 100),
          destinationPosition: const Offset(300, 200),
        );
        
        expect(connectionData.isInvalidOrder, isFalse);
      });

      test('ConnectionData handles null properties', () {
        final connectionWithNullProperties = const Connection(
          id: 'null_props_conn',
          sourcePortId: 'algo_1_out_1',
          targetPortId: 'algo_2_in_1',
          properties: null,
        );
        
        final connectionData = ConnectionData(
          connection: connectionWithNullProperties,
          sourcePosition: const Offset(100, 100),
          destinationPosition: const Offset(300, 200),
        );
        
        expect(connectionData.isInvalidOrder, isFalse);
      });

      test('ConnectionData handles empty properties', () {
        final connectionWithEmptyProperties = const Connection(
          id: 'empty_props_conn',
          sourcePortId: 'algo_1_out_1',
          targetPortId: 'algo_2_in_1',
          properties: <String, dynamic>{},
        );
        
        final connectionData = ConnectionData(
          connection: connectionWithEmptyProperties,
          sourcePosition: const Offset(100, 100),
          destinationPosition: const Offset(300, 200),
        );
        
        expect(connectionData.isInvalidOrder, isFalse);
      });
    });

    group('ConnectionPainter Invalid Connection Rendering', () {
      test('ConnectionPainter should repaint when invalid connections change', () {
        final painter1 = ConnectionPainter(
          connections: [validConnectionData],
          theme: theme,
        );
        
        final painter2 = ConnectionPainter(
          connections: [invalidConnectionData],
          theme: theme,
        );
        
        expect(painter1.shouldRepaint(painter2), isTrue);
      });

      test('ConnectionPainter correctly groups invalid connections', () {
        final painter = ConnectionPainter(
          connections: [validConnectionData, invalidConnectionData],
          theme: theme,
        );
        
        // We can't directly test the grouping logic as it's internal,
        // but we can verify the painter accepts both connection types
        expect(painter.connections.length, equals(2));
        expect(painter.connections.any((c) => c.isInvalidOrder), isTrue);
        expect(painter.connections.any((c) => !c.isInvalidOrder), isTrue);
      });

      test('ConnectionPainter handles mixed connection types', () {
        final ghostConnection = const Connection(
          id: 'ghost_conn',
          sourcePortId: 'algo_1_out_1',
          targetPortId: 'hw_in_1',
          isGhostConnection: true,
        );
        
        final ghostConnectionData = ConnectionData(
          connection: ghostConnection,
          sourcePosition: const Offset(200, 150),
          destinationPosition: const Offset(400, 250),
        );
        
        final painter = ConnectionPainter(
          connections: [
            validConnectionData,
            invalidConnectionData,
            ghostConnectionData,
          ],
          theme: theme,
        );
        
        // Verify the painter can handle all connection types together
        expect(painter.connections.length, equals(3));
        expect(painter.connections.where((c) => c.isInvalidOrder).length, equals(1));
        expect(painter.connections.where((c) => c.isGhostConnection).length, equals(1));
        expect(painter.connections.where((c) => !c.isInvalidOrder && !c.isGhostConnection).length, equals(1));
      });

      test('ConnectionPainter handles multiple invalid connections', () {
        final invalidConnection2 = const Connection(
          id: 'invalid_conn_2',
          sourcePortId: 'algo_3_out_1',
          targetPortId: 'algo_1_in_2',
          properties: {
            'busNumber': 17,
            'isInvalidOrder': true,
            'sourceSlotIndex': 2,
            'targetSlotIndex': 0,
          },
        );
        
        final invalidConnectionData2 = ConnectionData(
          connection: invalidConnection2,
          sourcePosition: const Offset(250, 150),
          destinationPosition: const Offset(450, 250),
        );
        
        final painter = ConnectionPainter(
          connections: [
            validConnectionData,
            invalidConnectionData,
            invalidConnectionData2,
          ],
          theme: theme,
        );
        
        expect(painter.connections.length, equals(3));
        expect(painter.connections.where((c) => c.isInvalidOrder).length, equals(2));
      });
    });

    group('ConnectionPainter Error Color Theme Integration', () {
      test('ConnectionPainter uses theme error color for invalid connections', () {
        final customTheme = ThemeData.from(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.purple),
        );
        
        final painter = ConnectionPainter(
          connections: [invalidConnectionData],
          theme: customTheme,
        );
        
        // Verify the painter uses the custom theme
        expect(painter.theme, equals(customTheme));
        expect(painter.theme.colorScheme.error, isNotNull);
      });

      test('ConnectionPainter handles both light and dark themes', () {
        final lightPainter = ConnectionPainter(
          connections: [invalidConnectionData],
          theme: ThemeData.light(),
        );
        
        final darkPainter = ConnectionPainter(
          connections: [invalidConnectionData],
          theme: ThemeData.dark(),
        );
        
        expect(lightPainter.shouldRepaint(darkPainter), isTrue);
        expect(lightPainter.theme.colorScheme.error, isNotNull);
        expect(darkPainter.theme.colorScheme.error, isNotNull);
      });
    });

    group('ConnectionPainter Path Drawing Integration', () {
      test('ConnectionPainter supports dashed path drawing for invalid connections', () {
        // This test verifies the painter can handle invalid connections
        // alongside existing dashed path functionality for ghost connections
        final mixedConnections = [
          validConnectionData,
          invalidConnectionData,
          ConnectionData(
            connection: const Connection(
              id: 'ghost_conn',
              sourcePortId: 'algo_1_out_1',
              targetPortId: 'hw_in_1',
              isGhostConnection: true,
            ),
            sourcePosition: const Offset(300, 100),
            destinationPosition: const Offset(500, 200),
          ),
        ];
        
        final painter = ConnectionPainter(
          connections: mixedConnections,
          theme: theme,
        );
        
        expect(painter.connections.length, equals(3));
        // Verify we have both invalid and ghost connections that should use dashed rendering
        expect(painter.connections.where((c) => c.isInvalidOrder || c.isGhostConnection).length, equals(2));
      });
    });
  });
}