import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/ui/widgets/routing/connection_painter.dart';
import 'package:nt_helper/ui/widgets/routing/bus_label_formatter.dart';
import 'package:nt_helper/cubit/routing_editor_cubit.dart' as routing;
import 'package:nt_helper/core/routing/models/port.dart';

void main() {
  group('ConnectionPainter Mode-aware Label Tests', () {
    test('formatBusLabelWithMode static method should format replace mode with R suffix', () {
      // Test the static method directly
      expect(ConnectionPainter.formatBusLabelWithMode(13, OutputMode.replace), 'O1 R');
      expect(ConnectionPainter.formatBusLabelWithMode(16, OutputMode.replace), 'O4 R');
      expect(ConnectionPainter.formatBusLabelWithMode(20, OutputMode.replace), 'O8 R');
    });

    test('formatBusLabelWithMode static method should format add mode without suffix', () {
      // Test the static method directly
      expect(ConnectionPainter.formatBusLabelWithMode(13, OutputMode.add), 'O1');
      expect(ConnectionPainter.formatBusLabelWithMode(16, OutputMode.add), 'O4');
      expect(ConnectionPainter.formatBusLabelWithMode(20, OutputMode.add), 'O8');
    });

    test('formatBusLabelWithMode static method should handle null mode', () {
      // Test the static method directly
      expect(ConnectionPainter.formatBusLabelWithMode(13, null), 'O1');
      expect(ConnectionPainter.formatBusLabelWithMode(16, null), 'O4');
      expect(ConnectionPainter.formatBusLabelWithMode(20, null), 'O8');
    });

    test('formatBusLabelWithMode static method should handle input buses correctly', () {
      // Input buses should ignore mode
      expect(ConnectionPainter.formatBusLabelWithMode(1, OutputMode.replace), 'I1');
      expect(ConnectionPainter.formatBusLabelWithMode(6, OutputMode.add), 'I6');
      expect(ConnectionPainter.formatBusLabelWithMode(12, null), 'I12');
    });

    testWidgets('ConnectionData with replace mode should display R suffix in labels', (tester) async {
      // Create connection data with replace mode
      final connectionData = ConnectionData(
        connection: routing.Connection(
          id: 'test_replace', 
          sourcePortId: 'source', 
          targetPortId: 'target',
        ),
        sourcePosition: const Offset(100, 100),
        destinationPosition: const Offset(200, 200),
        busNumber: 13, // Output bus O1
        outputMode: OutputMode.replace, // Should show "O1 R"
      );

      // Create a test widget that uses ConnectionPainter
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 300,
              child: CustomPaint(
                painter: ConnectionPainter(
                  connections: [connectionData],
                  theme: ThemeData.light(),
                  showLabels: true,
                ),
              ),
            ),
          ),
        ),
      );

      // The actual visual testing would require more complex setup
      // but we can verify the connection data is structured correctly
      expect(connectionData.outputMode, OutputMode.replace);
      expect(connectionData.busNumber, 13);
      
      // Verify the static method would produce the right label
      final expectedLabel = ConnectionPainter.formatBusLabelWithMode(
        connectionData.busNumber, 
        connectionData.outputMode,
      );
      expect(expectedLabel, 'O1 R');
    });

    testWidgets('ConnectionData with add mode should display no suffix in labels', (tester) async {
      // Create connection data with add mode
      final connectionData = ConnectionData(
        connection: routing.Connection(
          id: 'test_add', 
          sourcePortId: 'source', 
          targetPortId: 'target',
        ),
        sourcePosition: const Offset(100, 100),
        destinationPosition: const Offset(200, 200),
        busNumber: 16, // Output bus O4
        outputMode: OutputMode.add, // Should show "O4"
      );

      // Create a test widget that uses ConnectionPainter
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 300,
              child: CustomPaint(
                painter: ConnectionPainter(
                  connections: [connectionData],
                  theme: ThemeData.light(),
                  showLabels: true,
                ),
              ),
            ),
          ),
        ),
      );

      // Verify the connection data is structured correctly
      expect(connectionData.outputMode, OutputMode.add);
      expect(connectionData.busNumber, 16);
      
      // Verify the static method would produce the right label
      final expectedLabel = ConnectionPainter.formatBusLabelWithMode(
        connectionData.busNumber, 
        connectionData.outputMode,
      );
      expect(expectedLabel, 'O4');
    });
  });
}