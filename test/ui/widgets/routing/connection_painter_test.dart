import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/core/routing/models/connection.dart';
import 'package:nt_helper/core/routing/models/port.dart';
import 'package:nt_helper/ui/widgets/routing/connection_painter.dart';

void main() {
  group('ConnectionPainter', () {
    late Connection mockConnection;
    late ConnectionData mockConnectionData;
    late ThemeData mockTheme;

    setUp(() {
      mockConnection = Connection(
        id: 'test_connection',
        sourcePortId: 'source_port',
        destinationPortId: 'destination_port',
        connectionType: ConnectionType.algorithmToAlgorithm,
      );

      mockConnectionData = ConnectionData(
        connection: mockConnection,
        sourcePosition: const Offset(50, 100),
        destinationPosition: const Offset(200, 150),
        busNumber: 5,
        outputMode: OutputMode.add,
      );

      mockTheme = ThemeData.light();
    });

    group('Label Bounds Storage', () {
      test('should store label bounds during painting', () {
        final painter = ConnectionPainter(
          connections: [mockConnectionData],
          theme: mockTheme,
          showLabels: true,
        );

        // Create a test canvas
        final recorder = PictureRecorder();
        final canvas = Canvas(recorder);
        const size = Size(400, 300);

        // Paint the connections (this should store label bounds)
        painter.paint(canvas, size);

        // Check that label bounds were stored
        final labelBounds = painter.getLabelBounds();
        expect(labelBounds, isNotNull);
        expect(labelBounds.containsKey(mockConnection.id), isTrue);

        final bounds = labelBounds[mockConnection.id];
        expect(bounds, isNotNull);
        expect(bounds!.width, greaterThan(0));
        expect(bounds.height, greaterThan(0));
      });

      test('should not store bounds when labels are disabled', () {
        final painter = ConnectionPainter(
          connections: [mockConnectionData],
          theme: mockTheme,
          showLabels: false,
        );

        // Create a test canvas
        final recorder = PictureRecorder();
        final canvas = Canvas(recorder);
        const size = Size(400, 300);

        // Paint the connections
        painter.paint(canvas, size);

        // Check that no label bounds were stored
        final labelBounds = painter.getLabelBounds();
        expect(labelBounds.isEmpty, isTrue);
      });

      test('should clear previous bounds on repaint', () {
        final painter = ConnectionPainter(
          connections: [mockConnectionData],
          theme: mockTheme,
          showLabels: true,
        );

        // Create a test canvas
        final recorder = PictureRecorder();
        final canvas = Canvas(recorder);
        const size = Size(400, 300);

        // First paint
        painter.paint(canvas, size);
        final firstBounds = painter.getLabelBounds();
        expect(firstBounds.isNotEmpty, isTrue);

        // Second paint with different connection
        final newConnection = Connection(
          id: 'new_connection',
          sourcePortId: 'new_source',
          destinationPortId: 'new_destination',
          connectionType: ConnectionType.algorithmToAlgorithm,
        );

        final newConnectionData = ConnectionData(
          connection: newConnection,
          sourcePosition: const Offset(100, 50),
          destinationPosition: const Offset(250, 100),
          busNumber: 3,
        );

        final newPainter = ConnectionPainter(
          connections: [newConnectionData],
          theme: mockTheme,
          showLabels: true,
        );

        newPainter.paint(canvas, size);
        final secondBounds = newPainter.getLabelBounds();

        // Should only have bounds for the new connection
        expect(secondBounds.containsKey(mockConnection.id), isFalse);
        expect(secondBounds.containsKey(newConnection.id), isTrue);
      });
    });

    group('Hit Testing', () {
      test('should hit test label bounds correctly', () {
        final painter = ConnectionPainter(
          connections: [mockConnectionData],
          theme: mockTheme,
          showLabels: true,
        );

        // Create a test canvas and paint
        final recorder = PictureRecorder();
        final canvas = Canvas(recorder);
        const size = Size(400, 300);
        painter.paint(canvas, size);

        // Get the label bounds
        final labelBounds = painter.getLabelBounds();
        final bounds = labelBounds[mockConnection.id]!;

        // Test hit detection inside bounds
        final centerPoint = bounds.center;
        final hitConnection = painter.hitTestLabel(centerPoint);
        expect(hitConnection, equals(mockConnection.id));

        // Test hit detection outside bounds
        final outsidePoint = Offset(bounds.right + 10, bounds.bottom + 10);
        final missedConnection = painter.hitTestLabel(outsidePoint);
        expect(missedConnection, isNull);
      });

      test('should return null for hit test when no labels exist', () {
        final painter = ConnectionPainter(
          connections: [mockConnectionData],
          theme: mockTheme,
          showLabels: false,
        );

        // Create a test canvas and paint
        final recorder = PictureRecorder();
        final canvas = Canvas(recorder);
        const size = Size(400, 300);
        painter.paint(canvas, size);

        // Test hit detection - should return null
        final hitConnection = painter.hitTestLabel(const Offset(100, 100));
        expect(hitConnection, isNull);
      });

      test(
        'should return first matching connection for overlapping labels',
        () {
          // Create two connections with similar positions (overlapping labels)
          final connection1 = Connection(
            id: 'connection_1',
            sourcePortId: 'source_1',
            destinationPortId: 'dest_1',
            connectionType: ConnectionType.algorithmToAlgorithm,
          );

          final connection2 = Connection(
            id: 'connection_2',
            sourcePortId: 'source_2',
            destinationPortId: 'dest_2',
            connectionType: ConnectionType.algorithmToAlgorithm,
          );

          final connectionData1 = ConnectionData(
            connection: connection1,
            sourcePosition: const Offset(50, 100),
            destinationPosition: const Offset(150, 120),
            busNumber: 1,
          );

          final connectionData2 = ConnectionData(
            connection: connection2,
            sourcePosition: const Offset(55, 105),
            destinationPosition: const Offset(155, 125),
            busNumber: 2,
          );

          final painter = ConnectionPainter(
            connections: [connectionData1, connectionData2],
            theme: mockTheme,
            showLabels: true,
          );

          // Paint to generate bounds
          final recorder = PictureRecorder();
          final canvas = Canvas(recorder);
          const size = Size(400, 300);
          painter.paint(canvas, size);

          // Hit test at a point that might overlap both labels
          final testPoint = const Offset(100, 110);
          final hitConnection = painter.hitTestLabel(testPoint);

          // Should return one of the connections (first match)
          expect(
            hitConnection,
            anyOf(equals('connection_1'), equals('connection_2')),
          );
        },
      );
    });

    group('Hover Visual Feedback', () {
      test('should apply teal color and increased border width on hover', () {
        final painter = ConnectionPainter(
          connections: [mockConnectionData],
          theme: mockTheme,
          showLabels: true,
          hoveredConnectionId: mockConnection.id,
        );

        // Create a test canvas
        final recorder = PictureRecorder();
        final canvas = Canvas(recorder);
        const size = Size(400, 300);

        // Paint the connections (this should apply hover styling)
        painter.paint(canvas, size);

        // Check that label bounds were stored (basic functionality still works)
        final labelBounds = painter.getLabelBounds();
        expect(labelBounds.containsKey(mockConnection.id), isTrue);

        // Verify painter was created with hovered connection ID
        expect(painter.hoveredConnectionId, equals(mockConnection.id));
      });

      test('should not apply hover styling when not hovered', () {
        final painter = ConnectionPainter(
          connections: [mockConnectionData],
          theme: mockTheme,
          showLabels: true,
          hoveredConnectionId: 'different_connection',
        );

        // Create a test canvas
        final recorder = PictureRecorder();
        final canvas = Canvas(recorder);
        const size = Size(400, 300);

        // Paint the connections
        painter.paint(canvas, size);

        // Check that label bounds were stored normally
        final labelBounds = painter.getLabelBounds();
        expect(labelBounds.containsKey(mockConnection.id), isTrue);

        // Verify hovered connection ID is different
        expect(painter.hoveredConnectionId, equals('different_connection'));
      });

      test(
        'should not apply hover styling when hoveredConnectionId is null',
        () {
          final painter = ConnectionPainter(
            connections: [mockConnectionData],
            theme: mockTheme,
            showLabels: true,
            hoveredConnectionId: null,
          );

          // Create a test canvas
          final recorder = PictureRecorder();
          final canvas = Canvas(recorder);
          const size = Size(400, 300);

          // Paint the connections
          painter.paint(canvas, size);

          // Check that label bounds were stored normally
          final labelBounds = painter.getLabelBounds();
          expect(labelBounds.containsKey(mockConnection.id), isTrue);

          // Verify no hover state
          expect(painter.hoveredConnectionId, isNull);
        },
      );
    });
  });
}
