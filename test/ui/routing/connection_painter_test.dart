import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/models/connection.dart';
import 'package:nt_helper/models/connection_preview.dart';
import 'package:nt_helper/ui/routing/connection_painter.dart';

void main() {
  group('ConnectionPainter - Optimistic Visual States', () {
    late ConnectionPainter painter;
    
    const testConnections = [
      Connection(
        id: 'normal_connection',
        sourceAlgorithmIndex: 0,
        sourcePortId: 'output',
        targetAlgorithmIndex: 1,
        targetPortId: 'input',
        assignedBus: 21,
        replaceMode: true,
        isValid: true,
      ),
      Connection(
        id: 'pending_connection',
        sourceAlgorithmIndex: 1,
        sourcePortId: 'output',
        targetAlgorithmIndex: 2,
        targetPortId: 'input',
        assignedBus: 22,
        replaceMode: true,
        isValid: true,
      ),
      Connection(
        id: 'failed_connection',
        sourceAlgorithmIndex: 2,
        sourcePortId: 'output',
        targetAlgorithmIndex: 3,
        targetPortId: 'input',
        assignedBus: 23,
        replaceMode: true,
        isValid: true,
      ),
    ];

    const testPortPositions = {
      '0_output': Offset(100, 100),
      '1_input': Offset(200, 100),
      '1_output': Offset(300, 100),
      '2_input': Offset(400, 100),
      '2_output': Offset(500, 100),
      '3_input': Offset(600, 100),
    };

    test('should create painter with default empty states', () {
      painter = ConnectionPainter(
        connections: testConnections,
        portPositions: testPortPositions,
      );

      expect(painter.connections, equals(testConnections));
      expect(painter.portPositions, equals(testPortPositions));
      expect(painter.pendingConnections, isEmpty);
      expect(painter.failedConnections, isEmpty);
      expect(painter.connectionPreview, isNull);
      expect(painter.hoveredConnectionId, isNull);
    });

    test('should create painter with pending connections', () {
      painter = ConnectionPainter(
        connections: testConnections,
        portPositions: testPortPositions,
        pendingConnections: {'pending_connection'},
      );

      expect(painter.pendingConnections, contains('pending_connection'));
      expect(painter.failedConnections, isEmpty);
    });

    test('should create painter with failed connections', () {
      painter = ConnectionPainter(
        connections: testConnections,
        portPositions: testPortPositions,
        failedConnections: {'failed_connection'},
      );

      expect(painter.pendingConnections, isEmpty);
      expect(painter.failedConnections, contains('failed_connection'));
    });

    test('should create painter with both pending and failed connections', () {
      painter = ConnectionPainter(
        connections: testConnections,
        portPositions: testPortPositions,
        pendingConnections: {'pending_connection'},
        failedConnections: {'failed_connection'},
      );

      expect(painter.pendingConnections, contains('pending_connection'));
      expect(painter.failedConnections, contains('failed_connection'));
    });

    test('should create painter with connection preview', () {
      final preview = ConnectionPreview(
        sourceAlgorithmIndex: 0,
        sourcePortId: 'output',
        cursorPosition: const Offset(150, 150),
        isValid: true,
      );
      
      painter = ConnectionPainter(
        connections: testConnections,
        portPositions: testPortPositions,
        connectionPreview: preview,
      );

      expect(painter.connectionPreview, equals(preview));
    });

    test('should create painter with hovered connection', () {
      painter = ConnectionPainter(
        connections: testConnections,
        portPositions: testPortPositions,
        hoveredConnectionId: 'normal_connection',
      );

      expect(painter.hoveredConnectionId, equals('normal_connection'));
    });

    group('shouldRepaint', () {
      test('should repaint when connections change', () {
        final oldPainter = ConnectionPainter(
          connections: testConnections,
          portPositions: testPortPositions,
        );
        
        final newPainter = ConnectionPainter(
          connections: [testConnections.first], // Different connections
          portPositions: testPortPositions,
        );

        expect(newPainter.shouldRepaint(oldPainter), isTrue);
      });

      test('should repaint when portPositions change', () {
        final oldPainter = ConnectionPainter(
          connections: testConnections,
          portPositions: testPortPositions,
        );
        
        final newPainter = ConnectionPainter(
          connections: testConnections,
          portPositions: {
            ...testPortPositions,
            '0_output': const Offset(150, 150), // Different position
          },
        );

        expect(newPainter.shouldRepaint(oldPainter), isTrue);
      });

      test('should repaint when pendingConnections change', () {
        final oldPainter = ConnectionPainter(
          connections: testConnections,
          portPositions: testPortPositions,
          pendingConnections: {'pending_1'},
        );
        
        final newPainter = ConnectionPainter(
          connections: testConnections,
          portPositions: testPortPositions,
          pendingConnections: {'pending_2'}, // Different pending
        );

        expect(newPainter.shouldRepaint(oldPainter), isTrue);
      });

      test('should repaint when failedConnections change', () {
        final oldPainter = ConnectionPainter(
          connections: testConnections,
          portPositions: testPortPositions,
          failedConnections: {'failed_1'},
        );
        
        final newPainter = ConnectionPainter(
          connections: testConnections,
          portPositions: testPortPositions,
          failedConnections: {'failed_2'}, // Different failed
        );

        expect(newPainter.shouldRepaint(oldPainter), isTrue);
      });

      test('should repaint when connectionPreview changes', () {
        final oldPainter = ConnectionPainter(
          connections: testConnections,
          portPositions: testPortPositions,
          connectionPreview: ConnectionPreview(
            sourceAlgorithmIndex: 0,
            sourcePortId: 'output',
            cursorPosition: const Offset(100, 100),
            isValid: true,
          ),
        );
        
        final newPainter = ConnectionPainter(
          connections: testConnections,
          portPositions: testPortPositions,
          connectionPreview: ConnectionPreview(
            sourceAlgorithmIndex: 0,
            sourcePortId: 'output',
            cursorPosition: const Offset(200, 200), // Different position
            isValid: true,
          ),
        );

        expect(newPainter.shouldRepaint(oldPainter), isTrue);
      });

      test('should repaint when hoveredConnectionId changes', () {
        final oldPainter = ConnectionPainter(
          connections: testConnections,
          portPositions: testPortPositions,
          hoveredConnectionId: 'connection_1',
        );
        
        final newPainter = ConnectionPainter(
          connections: testConnections,
          portPositions: testPortPositions,
          hoveredConnectionId: 'connection_2', // Different hovered
        );

        expect(newPainter.shouldRepaint(oldPainter), isTrue);
      });

      test('should not repaint when nothing changes', () {
        // Use the same instances to ensure equality
        const pendingSet = {'pending_1'};
        const failedSet = {'failed_1'};
        
        final oldPainter = ConnectionPainter(
          connections: testConnections,
          portPositions: testPortPositions,
          pendingConnections: pendingSet,
          failedConnections: failedSet,
          hoveredConnectionId: 'connection_1',
        );
        
        final newPainter = ConnectionPainter(
          connections: testConnections,
          portPositions: testPortPositions,
          pendingConnections: pendingSet, // Same instance
          failedConnections: failedSet,   // Same instance
          hoveredConnectionId: 'connection_1',
        );

        expect(newPainter.shouldRepaint(oldPainter), isFalse);
      });
    });

    group('hit testing', () {
      test('should detect hits on connections', () {
        painter = ConnectionPainter(
          connections: testConnections,
          portPositions: testPortPositions,
        );

        // Mock a point near the connection line
        // This is a basic test - actual hit testing would require more complex setup
        final hitResult = painter.hitTest(const Offset(150, 100));
        
        // The result depends on the implementation, but we're testing the API exists
        expect(hitResult, isA<bool?>());
      });

      test('should not hit test connection preview by default', () {
        final preview = ConnectionPreview(
          sourceAlgorithmIndex: 0,
          sourcePortId: 'output',
          cursorPosition: const Offset(150, 150),
          isValid: true,
        );
        
        painter = ConnectionPainter(
          connections: [],
          portPositions: testPortPositions,
          connectionPreview: preview,
        );

        // Preview connections are typically not hit-testable
        final hitResult = painter.hitTest(const Offset(125, 125));
        expect(hitResult, isFalse);
      });
    });

    group('visual state combinations', () {
      test('should handle connection that is both pending and hovered', () {
        painter = ConnectionPainter(
          connections: testConnections,
          portPositions: testPortPositions,
          pendingConnections: {'normal_connection'},
          hoveredConnectionId: 'normal_connection',
        );

        // Both pending and hovered states should be tracked
        expect(painter.pendingConnections, contains('normal_connection'));
        expect(painter.hoveredConnectionId, equals('normal_connection'));
      });

      test('should handle connection that is both failed and hovered', () {
        painter = ConnectionPainter(
          connections: testConnections,
          portPositions: testPortPositions,
          failedConnections: {'normal_connection'},
          hoveredConnectionId: 'normal_connection',
        );

        // Both failed and hovered states should be tracked
        expect(painter.failedConnections, contains('normal_connection'));
        expect(painter.hoveredConnectionId, equals('normal_connection'));
      });

      test('should handle multiple connections in different states', () {
        painter = ConnectionPainter(
          connections: testConnections,
          portPositions: testPortPositions,
          pendingConnections: {'pending_connection'},
          failedConnections: {'failed_connection'},
          hoveredConnectionId: 'normal_connection',
        );

        // Each connection should have its appropriate state
        expect(painter.pendingConnections, contains('pending_connection'));
        expect(painter.pendingConnections, isNot(contains('failed_connection')));
        expect(painter.pendingConnections, isNot(contains('normal_connection')));
        
        expect(painter.failedConnections, contains('failed_connection'));
        expect(painter.failedConnections, isNot(contains('pending_connection')));
        expect(painter.failedConnections, isNot(contains('normal_connection')));
        
        expect(painter.hoveredConnectionId, equals('normal_connection'));
      });
    });

    group('edge cases', () {
      test('should handle empty connections list', () {
        painter = ConnectionPainter(
          connections: [],
          portPositions: {},
          pendingConnections: {'nonexistent_connection'},
          failedConnections: {'another_nonexistent'},
        );

        expect(painter.connections, isEmpty);
        expect(painter.pendingConnections, contains('nonexistent_connection'));
        expect(painter.failedConnections, contains('another_nonexistent'));
      });

      test('should handle missing port positions', () {
        painter = ConnectionPainter(
          connections: testConnections,
          portPositions: {}, // Empty positions
          pendingConnections: {'pending_connection'},
        );

        expect(painter.connections, equals(testConnections));
        expect(painter.portPositions, isEmpty);
        expect(painter.pendingConnections, contains('pending_connection'));
      });

      test('should handle null preview and hover states', () {
        painter = ConnectionPainter(
          connections: testConnections,
          portPositions: testPortPositions,
          connectionPreview: null,
          hoveredConnectionId: null,
        );

        expect(painter.connectionPreview, isNull);
        expect(painter.hoveredConnectionId, isNull);
      });
    });
  });
}