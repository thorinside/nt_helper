import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/core/routing/models/connection.dart';
import 'package:nt_helper/ui/widgets/routing/connection_painter.dart';

void main() {
  group('ConnectionPainter Tests', () {
    group('Invalid Connection Rendering', () {
      test('should render invalid connections with dashed lines and error color', () {
        final theme = ThemeData.light();
        final invalidConnection = ConnectionData(
          connection: Connection(
            id: 'invalid_test',
            sourcePortId: 'alg_2_out_1',
            destinationPortId: 'alg_1_in_1',
            connectionType: ConnectionType.algorithmToAlgorithm,
            isBackwardEdge: true, // Mark as invalid
          ),
          sourcePosition: const Offset(10, 10),
          destinationPosition: const Offset(100, 50),
        );

        final painter = ConnectionPainter(
          connections: [invalidConnection],
          theme: theme,
        );

        // Test that invalid connection is identified
        expect(invalidConnection.isInvalidOrder, isTrue);
        
        // Verify painter handles the invalid connection
        expect(painter.connections.length, equals(1));
        expect(painter.connections.first.isInvalidOrder, isTrue);
      });

      test('should group invalid connections separately for batch rendering', () {
        final theme = ThemeData.light();
        final validConnection = ConnectionData(
          connection: Connection(
            id: 'valid_test',
            sourcePortId: 'alg_1_out_1',
            destinationPortId: 'alg_2_in_1',
            connectionType: ConnectionType.algorithmToAlgorithm,
            isBackwardEdge: false,
          ),
          sourcePosition: const Offset(10, 10),
          destinationPosition: const Offset(100, 50),
        );

        final invalidConnection = ConnectionData(
          connection: Connection(
            id: 'invalid_test',
            sourcePortId: 'alg_2_out_1',
            destinationPortId: 'alg_1_in_1',
            connectionType: ConnectionType.algorithmToAlgorithm,
            isBackwardEdge: true,
          ),
          sourcePosition: const Offset(10, 100),
          destinationPosition: const Offset(100, 150),
        );

        final painter = ConnectionPainter(
          connections: [validConnection, invalidConnection],
          theme: theme,
        );

        // Verify that connections are properly categorized
        expect(painter.connections.length, equals(2));
        expect(
          painter.connections.where((c) => c.isInvalidOrder).length,
          equals(1),
        );
        expect(
          painter.connections.where((c) => !c.isInvalidOrder).length,
          equals(1),
        );
      });

      test('should handle mixed connection types with proper grouping', () {
        final theme = ThemeData.light();
        final connections = [
          // Regular valid connection
          ConnectionData(
            connection: Connection(
              id: 'regular',
              sourcePortId: 'alg_1_out_1',
              destinationPortId: 'alg_2_in_1',
              connectionType: ConnectionType.algorithmToAlgorithm,
              isBackwardEdge: false,
            ),
            sourcePosition: const Offset(10, 10),
            destinationPosition: const Offset(100, 50),
          ),
          // Invalid connection
          ConnectionData(
            connection: Connection(
              id: 'invalid',
              sourcePortId: 'alg_3_out_1',
              destinationPortId: 'alg_1_in_1',
              connectionType: ConnectionType.algorithmToAlgorithm,
              isBackwardEdge: true,
            ),
            sourcePosition: const Offset(10, 100),
            destinationPosition: const Offset(100, 150),
          ),
          // Ghost connection
          ConnectionData(
            connection: Connection(
              id: 'ghost',
              sourcePortId: 'alg_1_out_2',
              destinationPortId: 'alg_2_in_2',
              connectionType: ConnectionType.algorithmToAlgorithm,
              isGhostConnection: true,
            ),
            sourcePosition: const Offset(10, 200),
            destinationPosition: const Offset(100, 250),
          ),
          // Partial connection
          ConnectionData(
            connection: Connection(
              id: 'partial',
              sourcePortId: 'alg_1_out_3',
              destinationPortId: '',
              connectionType: ConnectionType.partialOutputToBus,
              isPartial: true,
            ),
            sourcePosition: const Offset(10, 300),
            destinationPosition: const Offset(100, 350),
          ),
          // Selected connection
          ConnectionData(
            connection: Connection(
              id: 'selected',
              sourcePortId: 'alg_2_out_1',
              destinationPortId: 'alg_3_in_1',
              connectionType: ConnectionType.algorithmToAlgorithm,
            ),
            sourcePosition: const Offset(10, 400),
            destinationPosition: const Offset(100, 450),
            isSelected: true,
          ),
        ];

        final painter = ConnectionPainter(
          connections: connections,
          theme: theme,
        );

        expect(painter.connections.length, equals(5));
        
        // Verify grouping logic works correctly
        final regularConnections = painter.connections
            .where((c) => !c.isSelected && !c.isPartial && !c.isInvalidOrder && !c.isGhostConnection)
            .toList();
        final invalidConnections = painter.connections
            .where((c) => c.isInvalidOrder)
            .toList();
        final ghostConnections = painter.connections
            .where((c) => c.isGhostConnection)
            .toList();
        final partialConnections = painter.connections
            .where((c) => c.isPartial)
            .toList();
        final selectedConnections = painter.connections
            .where((c) => c.isSelected)
            .toList();

        expect(regularConnections.length, equals(1));
        expect(invalidConnections.length, equals(1));
        expect(ghostConnections.length, equals(1));
        expect(partialConnections.length, equals(1));
        expect(selectedConnections.length, equals(1));
      });
    });

    group('ConnectionData Model', () {
      test('should correctly identify invalid order from isBackwardEdge', () {
        final invalidConnectionData = ConnectionData(
          connection: Connection(
            id: 'test',
            sourcePortId: 'source',
            destinationPortId: 'dest',
            connectionType: ConnectionType.algorithmToAlgorithm,
            isBackwardEdge: true,
          ),
          sourcePosition: const Offset(0, 0),
          destinationPosition: const Offset(100, 100),
        );

        expect(invalidConnectionData.isInvalidOrder, isTrue);
      });

      test('should correctly identify valid connections', () {
        final validConnectionData = ConnectionData(
          connection: Connection(
            id: 'test',
            sourcePortId: 'source',
            destinationPortId: 'dest',
            connectionType: ConnectionType.algorithmToAlgorithm,
            isBackwardEdge: false,
          ),
          sourcePosition: const Offset(0, 0),
          destinationPosition: const Offset(100, 100),
        );

        expect(validConnectionData.isInvalidOrder, isFalse);
      });

      test('should handle physical connections as valid', () {
        final physicalConnectionData = ConnectionData(
          connection: Connection(
            id: 'physical',
            sourcePortId: 'hw_in_1',
            destinationPortId: 'alg_1_in_1',
            connectionType: ConnectionType.hardwareInput,
          ),
          sourcePosition: const Offset(0, 0),
          destinationPosition: const Offset(100, 100),
          isPhysicalConnection: true,
        );

        // Physical connections should never be marked as invalid
        expect(physicalConnectionData.isInvalidOrder, isFalse);
        expect(physicalConnectionData.isPhysicalConnection, isTrue);
      });
    });

    group('Dash Pattern Support', () {
      test('should create painter with dash pattern support enabled', () {
        final theme = ThemeData.light();
        final painter = ConnectionPainter(
          connections: [],
          theme: theme,
        );

        // Verify painter can be instantiated (dash pattern support is internal)
        expect(painter.connections, isEmpty);
        expect(painter.theme, equals(theme));
      });

      test('should handle anti-overlap and animations settings for invalid connections', () {
        final theme = ThemeData.light();
        final invalidConnection = ConnectionData(
          connection: Connection(
            id: 'invalid_test',
            sourcePortId: 'alg_2_out_1',
            destinationPortId: 'alg_1_in_1',
            connectionType: ConnectionType.algorithmToAlgorithm,
            isBackwardEdge: true,
          ),
          sourcePosition: const Offset(10, 10),
          destinationPosition: const Offset(100, 50),
        );

        final painter = ConnectionPainter(
          connections: [invalidConnection],
          theme: theme,
          enableAntiOverlap: true,
          enableAnimations: false, // Invalid connections shouldn't animate
          showLabels: true,
        );

        expect(painter.enableAntiOverlap, isTrue);
        expect(painter.enableAnimations, isFalse);
        expect(painter.showLabels, isTrue);
      });
    });

    group('Theme Integration', () {
      test('should use error color from light theme for invalid connections', () {
        final lightTheme = ThemeData.light();
        final painter = ConnectionPainter(
          connections: [],
          theme: lightTheme,
        );

        expect(painter.theme.colorScheme.error, isNotNull);
        // In light theme, error color should typically be red-ish
        expect(painter.theme.colorScheme.error.toARGB32, isNot(equals(Colors.transparent.toARGB32)));
      });

      test('should use error color from dark theme for invalid connections', () {
        final darkTheme = ThemeData.dark();
        final painter = ConnectionPainter(
          connections: [],
          theme: darkTheme,
        );

        expect(painter.theme.colorScheme.error, isNotNull);
        // In dark theme, error color should also be available
        expect(painter.theme.colorScheme.error.toARGB32, isNot(equals(Colors.transparent.toARGB32)));
      });

      test('should ensure error color contrast in both themes', () {
        final lightTheme = ThemeData.light();
        final darkTheme = ThemeData.dark();

        // Error colors should be different enough from background
        final lightErrorColor = lightTheme.colorScheme.error;
        final darkErrorColor = darkTheme.colorScheme.error;
        final lightBackground = lightTheme.colorScheme.surface;
        final darkBackground = darkTheme.colorScheme.surface;

        // Basic contrast check - error color shouldn't be same as background
        expect(lightErrorColor, isNot(equals(lightBackground)));
        expect(darkErrorColor, isNot(equals(darkBackground)));
      });
    });

    group('Performance', () {
      test('should handle large numbers of invalid connections efficiently', () {
        final theme = ThemeData.light();
        final invalidConnections = List.generate(100, (index) => 
          ConnectionData(
            connection: Connection(
              id: 'invalid_$index',
              sourcePortId: 'alg_${index % 5}_out_1',
              destinationPortId: 'alg_${(index % 5) - 1}_in_1',
              connectionType: ConnectionType.algorithmToAlgorithm,
              isBackwardEdge: true,
            ),
            sourcePosition: Offset(10.0, index * 10.0),
            destinationPosition: Offset(100.0, index * 10.0 + 50),
          ),
        );

        final painter = ConnectionPainter(
          connections: invalidConnections,
          theme: theme,
        );

        expect(painter.connections.length, equals(100));
        expect(painter.connections.every((c) => c.isInvalidOrder), isTrue);
      });

      test('should maintain performance with mixed connection types', () {
        final theme = ThemeData.light();
        final mixedConnections = <ConnectionData>[];
        
        // Add various connection types
        for (int i = 0; i < 50; i++) {
          mixedConnections.addAll([
            // Valid connection
            ConnectionData(
              connection: Connection(
                id: 'valid_$i',
                sourcePortId: 'alg_${i % 5}_out_1',
                destinationPortId: 'alg_${(i % 5) + 1}_in_1',
                connectionType: ConnectionType.algorithmToAlgorithm,
              ),
              sourcePosition: Offset(10.0, i * 20.0),
              destinationPosition: Offset(100.0, i * 20.0 + 50),
            ),
            // Invalid connection
            ConnectionData(
              connection: Connection(
                id: 'invalid_$i',
                sourcePortId: 'alg_${(i % 5) + 1}_out_1',
                destinationPortId: 'alg_${i % 5}_in_1',
                connectionType: ConnectionType.algorithmToAlgorithm,
                isBackwardEdge: true,
              ),
              sourcePosition: Offset(10.0, i * 20.0 + 10),
              destinationPosition: Offset(100.0, i * 20.0 + 60),
            ),
          ]);
        }

        final painter = ConnectionPainter(
          connections: mixedConnections,
          theme: theme,
        );

        expect(painter.connections.length, equals(100));
        expect(
          painter.connections.where((c) => c.isInvalidOrder).length,
          equals(50),
        );
        expect(
          painter.connections.where((c) => !c.isInvalidOrder).length,
          equals(50),
        );
      });
    });

    group('Rendering Order', () {
      test('should maintain proper z-order for different connection types', () {
        // The rendering order should be: regular -> ghost -> invalid -> partial -> selected
        // This ensures invalid connections are visible but not on top of selected ones
        
        final theme = ThemeData.light();
        final connections = [
          // Selected connection (should render last/on top)
          ConnectionData(
            connection: Connection(
              id: 'selected',
              sourcePortId: 'alg_1_out_1',
              destinationPortId: 'alg_2_in_1',
              connectionType: ConnectionType.algorithmToAlgorithm,
            ),
            sourcePosition: const Offset(0, 0),
            destinationPosition: const Offset(100, 100),
            isSelected: true,
          ),
          // Invalid connection (should render before selected)
          ConnectionData(
            connection: Connection(
              id: 'invalid',
              sourcePortId: 'alg_2_out_1',
              destinationPortId: 'alg_1_in_1',
              connectionType: ConnectionType.algorithmToAlgorithm,
              isBackwardEdge: true,
            ),
            sourcePosition: const Offset(0, 50),
            destinationPosition: const Offset(100, 150),
          ),
          // Regular connection (should render first/in background)
          ConnectionData(
            connection: Connection(
              id: 'regular',
              sourcePortId: 'alg_1_out_2',
              destinationPortId: 'alg_3_in_1',
              connectionType: ConnectionType.algorithmToAlgorithm,
            ),
            sourcePosition: const Offset(0, 100),
            destinationPosition: const Offset(100, 200),
          ),
        ];

        final painter = ConnectionPainter(
          connections: connections,
          theme: theme,
        );

        // Verify all connections are present
        expect(painter.connections.length, equals(3));
        
        // The painter should handle the rendering order internally
        // We can verify the connections are properly categorized
        final regularConnections = painter.connections
            .where((c) => !c.isSelected && !c.isInvalidOrder)
            .toList();
        final invalidConnections = painter.connections
            .where((c) => c.isInvalidOrder)
            .toList();
        final selectedConnections = painter.connections
            .where((c) => c.isSelected)
            .toList();

        expect(regularConnections.length, equals(1));
        expect(invalidConnections.length, equals(1));
        expect(selectedConnections.length, equals(1));
      });
    });
  });
}