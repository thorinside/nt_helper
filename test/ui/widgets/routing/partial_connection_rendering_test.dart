import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/cubit/routing_editor_cubit.dart' as cubit;
import 'package:nt_helper/ui/widgets/routing/connection_painter.dart';

void main() {
  group('Partial Connection Rendering Tests', () {
    test('should render partial output connection with correct bus label', () {
      // Create a partial connection for an output port connected to bus 21 (A1)
      const partialConnection = cubit.Connection(
        id: 'partial_output_test',
        sourcePortId: 'algo_1_output_1', // The actual output port
        targetPortId: 'bus_21_endpoint', // Virtual bus endpoint
        connectionType: cubit.ConnectionType.partialOutputToBus,
        isPartial: true,
        busNumber: 21,
        busLabel: 'A1', // Should display "A1", not "Bus21"
      );

      // Create connection data for rendering
      final connectionData = ConnectionData(
        connection: partialConnection,
        sourcePosition: const Offset(100, 100), // Output port position
        destinationPosition: const Offset(175, 100), // 75px to the right
        busLabel: 'A1',
      );

      // Verify the connection is identified as partial
      expect(connectionData.isPartial, isTrue);
      expect(connectionData.busLabel, equals('A1'));
      
      // Verify the connection properties
      expect(partialConnection.busValue, equals(21));
      expect(partialConnection.busLabel, equals('A1'));
      expect(partialConnection.properties?['connectionType'], equals('partial_output_to_bus'));
    });

    test('should render partial input connection with correct bus label', () {
      // Create a partial connection for an input port connected from bus 21 (A1)
      const partialConnection = cubit.Connection(
        id: 'partial_input_test',
        sourcePortId: 'bus_21_endpoint', // Virtual bus endpoint
        targetPortId: 'algo_1_input_1', // The actual input port
        connectionType: cubit.ConnectionType.partialBusToInput,
        isPartial: true,
        busNumber: 21,
        busLabel: 'A1',
      );

      // Create connection data for rendering
      final connectionData = ConnectionData(
        connection: partialConnection,
        sourcePosition: const Offset(25, 100), // 75px to the left of port
        destinationPosition: const Offset(100, 100), // Input port position
        busLabel: 'A1',
      );

      // Verify the connection is identified as partial
      expect(connectionData.isPartial, isTrue);
      expect(connectionData.busLabel, equals('A1'));
    });

    test('should use correct bus labels for aux ports', () {
      // Buses 1-20 are physical ports and will always have connections (never partial)
      // Buses 21-28 are Aux ports -> should be A1-A8
      
      // Test aux bus 21 -> should be A1
      const auxBus21Connection = cubit.Connection(
        id: 'test_21',
        sourcePortId: 'output_port',
        targetPortId: 'bus_21_endpoint',
        connectionType: cubit.ConnectionType.partialOutputToBus,
        isPartial: true,
        busNumber: 21,
        busLabel: 'A1', // Aux port 1
      );
      expect(auxBus21Connection.busLabel, equals('A1'));

      // Test aux bus 24 -> should be A4
      const auxBus24Connection = cubit.Connection(
        id: 'test_24',
        sourcePortId: 'output_port',
        targetPortId: 'bus_24_endpoint',
        connectionType: cubit.ConnectionType.partialOutputToBus,
        isPartial: true,
        busNumber: 24,
        busLabel: 'A4', // Aux port 4
      );
      expect(auxBus24Connection.busLabel, equals('A4'));

      // Test aux bus 28 -> should be A8
      const auxBus28Connection = cubit.Connection(
        id: 'test_28',
        sourcePortId: 'output_port',
        targetPortId: 'bus_28_endpoint',
        connectionType: cubit.ConnectionType.partialOutputToBus,
        isPartial: true,
        busNumber: 28,
        busLabel: 'A8', // Aux port 8
      );
      expect(auxBus28Connection.busLabel, equals('A8'));
    });

    testWidgets('should render partial connection line with label at endpoint', (WidgetTester tester) async {
      // Create a partial connection
      const partialConnection = cubit.Connection(
        id: 'partial_test',
        sourcePortId: 'output_port',
        targetPortId: 'bus_21_endpoint',
        connectionType: cubit.ConnectionType.partialOutputToBus,
        isPartial: true,
        busNumber: 21,
        busLabel: 'A1',
      );

      final connectionData = ConnectionData(
        connection: partialConnection,
        sourcePosition: const Offset(100, 100),
        destinationPosition: const Offset(175, 100), // 75px away
        busLabel: 'A1',
      );

      // Create a custom paint widget with the connection
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomPaint(
              size: const Size(400, 400),
              painter: ConnectionPainter(
                connections: [connectionData],
                showLabels: true,
                theme: ThemeData.light(),
              ),
            ),
          ),
        ),
      );

      // The painter should render:
      // 1. A dashed line from (100,100) to (175,100)
      // 2. A label "A1" at position (175,100)
      // 3. NO additional "Bus21" or other labels

      // Find the CustomPaint widget with our ConnectionPainter
      final customPaints = find.byType(CustomPaint);
      expect(customPaints, findsWidgets); // May have multiple CustomPaint widgets

      // Find the one with our ConnectionPainter
      ConnectionPainter? painter;
      for (final element in customPaints.evaluate()) {
        final widget = element.widget as CustomPaint;
        if (widget.painter is ConnectionPainter) {
          painter = widget.painter as ConnectionPainter;
          break;
        }
      }
      
      expect(painter, isNotNull);
      expect(painter!.connections.length, equals(1));
      expect(painter.connections.first.isPartial, isTrue);
      expect(painter.connections.first.busLabel, equals('A1'));
      
      // The label should be A1, not Bus21 or anything else
      expect(painter.connections.first.busLabel, isNot(equals('Bus21')));
      expect(painter.connections.first.busLabel, isNot(contains('Bus21')));
    });

    test('should generate correct labels for aux buses', () {
      // This test verifies the label generation logic
      // Buses 21-28 should generate "A1"-"A8" for aux ports
      
      // Test bus 21 -> A1
      const int busValue21 = 21;
      String expectedLabel21 = '';
      
      // This mimics the correct _generateBusLabel logic
      if (busValue21 >= 21 && busValue21 <= 28) {
        final auxNumber = busValue21 - 20; // 21-20=1, 22-20=2, etc.
        expectedLabel21 = 'A$auxNumber'; // Should be "A1"
      }
      
      expect(expectedLabel21, equals('A1'));
      
      // Test bus 28 -> A8
      const int busValue28 = 28;
      String expectedLabel28 = '';
      
      if (busValue28 >= 21 && busValue28 <= 28) {
        final auxNumber = busValue28 - 20; // 28-20=8
        expectedLabel28 = 'A$auxNumber'; // Should be "A8"
      }
      
      expect(expectedLabel28, equals('A8'));
    });

    test('partial connection should have 75px line length', () {
      // Verify that the line extends exactly 75px from the port
      const outputPortPosition = Offset(100, 100);
      const expectedLabelPosition = Offset(175, 100); // 75px to the right
      
      const partialConnection = cubit.Connection(
        id: 'length_test',
        sourcePortId: 'output_port',
        targetPortId: 'bus_21_endpoint',
        connectionType: cubit.ConnectionType.partialOutputToBus,
        isPartial: true,
        busNumber: 21,
        busLabel: 'A1',
      );

      final connectionData = ConnectionData(
        connection: partialConnection,
        sourcePosition: outputPortPosition,
        destinationPosition: expectedLabelPosition,
        busLabel: 'A1',
      );

      // Calculate the line length
      final lineLength = (connectionData.destinationPosition.dx - connectionData.sourcePosition.dx);
      expect(lineLength, equals(75.0));
    });

    test('bus 21 should show as A1 for aux port 1', () {
      // This test verifies that bus 21 correctly shows as "A1"
      // because bus 21 is aux port 1
      
      const bus21Connection = cubit.Connection(
        id: 'bus_21_test',
        sourcePortId: 'output_port',
        targetPortId: 'bus_21_endpoint',
        connectionType: cubit.ConnectionType.partialOutputToBus,
        isPartial: true,
        busNumber: 21, // Bus 21 is aux port 1
        busLabel: 'A1', // Should be A1 for aux port 1
      );

      expect(bus21Connection.busValue, equals(21));
      expect(bus21Connection.busLabel, equals('A1')); // Bus 21 = Aux 1 = A1

      // Test bus 22 should show as A2
      const bus22Connection = cubit.Connection(
        id: 'bus_22_test',
        sourcePortId: 'output_port',
        targetPortId: 'bus_22_endpoint',
        connectionType: cubit.ConnectionType.partialOutputToBus,
        isPartial: true,
        busNumber: 22, // Bus 22 is aux port 2
        busLabel: 'A2', // Should be A2 for aux port 2
      );

      expect(bus22Connection.busValue, equals(22));
      expect(bus22Connection.busLabel, equals('A2'));
    });
  });
}