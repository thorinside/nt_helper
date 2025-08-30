import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/core/routing/models/port.dart';
import 'package:nt_helper/ui/widgets/routing/connection_line.dart';
import 'package:nt_helper/ui/widgets/routing/jack_connection_widget.dart';
import 'package:nt_helper/ui/widgets/routing/physical_input_node.dart';
import 'package:nt_helper/ui/widgets/routing/physical_output_node.dart';
import 'package:nt_helper/ui/widgets/routing/connection_validator.dart';

void main() {
  group('Physical I/O Integration Tests', () {
    testWidgets('should render physical input and output nodes', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: const [
                Positioned(
                  left: 50,
                  top: 100,
                  child: PhysicalInputNode(),
                ),
                Positioned(
                  right: 50,
                  top: 100,
                  child: PhysicalOutputNode(),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(PhysicalInputNode), findsOneWidget);
      expect(find.byType(PhysicalOutputNode), findsOneWidget);
    });

    testWidgets('should create connections between nodes', (WidgetTester tester) async {
      // Create test ports
      const algorithmOutput = Port(
        id: 'alg_out_1',
        name: 'Algorithm Output',
        type: PortType.audio,
        direction: PortDirection.output,
        metadata: {'isPhysical': false},
      );
      
      const physicalOutput = Port(
        id: 'hw_out_1',
        name: 'Physical Output 1',
        type: PortType.audio,
        direction: PortDirection.input,
        metadata: {'isPhysical': true, 'jackType': 'output'},
      );

      final connection = Connection(
        sourcePort: algorithmOutput,
        destinationPort: physicalOutput,
        sourcePosition: const Offset(100, 200),
        destinationPosition: const Offset(300, 200),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                ConnectionLine(connection: connection),
                const Positioned(
                  left: 50,
                  top: 100,
                  child: PhysicalInputNode(),
                ),
                const Positioned(
                  right: 50,
                  top: 100,
                  child: PhysicalOutputNode(),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(ConnectionLine), findsOneWidget);
      expect(find.byType(PhysicalInputNode), findsOneWidget);
      expect(find.byType(PhysicalOutputNode), findsOneWidget);
    });

    testWidgets('should handle ghost connections properly', (WidgetTester tester) async {
      // Create ghost connection test ports
      const algorithmOutput = Port(
        id: 'alg_out_1',
        name: 'Algorithm Output',
        type: PortType.audio,
        direction: PortDirection.output,
        metadata: {'isPhysical': false},
      );
      
      const physicalInput = Port(
        id: 'hw_in_1',
        name: 'Physical Input 1',
        type: PortType.audio,
        direction: PortDirection.output, // Physical inputs act as sources
        metadata: {'isPhysical': true, 'jackType': 'input'},
      );

      final ghostConnection = Connection(
        sourcePort: algorithmOutput,
        destinationPort: physicalInput,
        sourcePosition: const Offset(100, 200),
        destinationPosition: const Offset(50, 180),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                ConnectionLine(connection: ghostConnection),
                const Positioned(
                  left: 50,
                  top: 100,
                  child: PhysicalInputNode(),
                ),
              ],
            ),
          ),
        ),
      );

      // Verify ghost connection is properly identified
      expect(ghostConnection.isGhostConnection, isTrue);
      expect(ConnectionValidator.isGhostConnection(algorithmOutput, physicalInput), isTrue);
      
      // Verify ghost connection tooltip
      expect(find.byType(Tooltip), findsOneWidget);
    });

    testWidgets('should validate connections correctly', (WidgetTester tester) async {
      const physicalInput = Port(
        id: 'hw_in_1',
        name: 'Physical Input 1',
        type: PortType.audio,
        direction: PortDirection.output,
        metadata: {'isPhysical': true, 'jackType': 'input'},
      );
      
      const physicalOutput = Port(
        id: 'hw_out_1',
        name: 'Physical Output 1',
        type: PortType.audio,
        direction: PortDirection.input,
        metadata: {'isPhysical': true, 'jackType': 'output'},
      );

      // Test invalid connection (physical to physical)
      expect(ConnectionValidator.isValidConnection(physicalInput, physicalOutput), isFalse);
      
      // Test connection description
      final errorMessage = ConnectionValidator.getValidationError(physicalInput, physicalOutput);
      expect(errorMessage, contains('Direct physical-to-physical connections are not supported'));
    });

    testWidgets('should render jack widgets with proper accessibility', (WidgetTester tester) async {
      const testPort = Port(
        id: 'test_port',
        name: 'Test Audio Port',
        type: PortType.audio,
        direction: PortDirection.input,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: JackConnectionWidget(port: testPort),
          ),
        ),
      );

      // Check accessibility properties
      final semantics = tester.getSemantics(find.byType(JackConnectionWidget));
      expect(semantics.label, contains('Test Audio Port'));
      expect(semantics.label, contains('audio'));
      expect(semantics.label, contains('input'));
      expect(semantics.hint, contains('Tap to select'));
    });

    testWidgets('should handle keyboard navigation in jack widgets', (WidgetTester tester) async {
      const testPort = Port(
        id: 'test_port',
        name: 'Test Audio Port',
        type: PortType.audio,
        direction: PortDirection.input,
      );

      bool tapCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: JackConnectionWidget(
              port: testPort,
              onTap: () => tapCalled = true,
            ),
          ),
        ),
      );

      // Focus the widget
      await tester.tap(find.byType(JackConnectionWidget));
      await tester.pump();

      // Test keyboard activation
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();

      expect(tapCalled, isTrue);
    });

    group('Performance Tests', () {
      testWidgets('should handle multiple connections efficiently', (WidgetTester tester) async {
        final connections = <Connection>[];
        
        // Create multiple test connections
        for (int i = 0; i < 10; i++) {
          final sourcePort = Port(
            id: 'source_$i',
            name: 'Source $i',
            type: PortType.audio,
            direction: PortDirection.output,
          );
          
          final destPort = Port(
            id: 'dest_$i',
            name: 'Destination $i',
            type: PortType.audio,
            direction: PortDirection.input,
          );
          
          connections.add(Connection(
            sourcePort: sourcePort,
            destinationPort: destPort,
            sourcePosition: Offset(50 + i * 10, 100),
            destinationPosition: Offset(200 + i * 10, 150),
          ));
        }

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Stack(
                children: [
                  ConnectionLineManager(connections: connections),
                  const Positioned(
                    left: 50,
                    top: 100,
                    child: PhysicalInputNode(),
                  ),
                  const Positioned(
                    right: 50,
                    top: 100,
                    child: PhysicalOutputNode(),
                  ),
                ],
              ),
            ),
          ),
        );

        expect(find.byType(ConnectionLineManager), findsOneWidget);
        expect(find.byType(ConnectionLine), findsNWidgets(10));
      });
    });
  });
}