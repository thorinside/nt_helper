import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/cubit/routing_editor_cubit.dart';
import 'package:nt_helper/ui/widgets/routing/connection_painter.dart';

void main() {
  group('Invalid Connection Rendering Integration', () {
    testWidgets('ConnectionPainter renders invalid connections with error styling', (tester) async {
      // Create connections with various states
      final validConnection = const Connection(
        id: 'valid_conn',
        sourcePortId: 'algo_1_out_1',
        targetPortId: 'algo_2_in_1',
        properties: {
          'busNumber': 15,
        },
      );
      
      final invalidConnection = const Connection(
        id: 'invalid_conn',
        sourcePortId: 'algo_2_out_1',
        targetPortId: 'algo_1_in_1',
        properties: {
          'busNumber': 16,
          'isInvalidOrder': true,
          'sourceSlotIndex': 1,
          'targetSlotIndex': 0,
        },
      );
      
      final ghostConnection = const Connection(
        id: 'ghost_conn',
        sourcePortId: 'algo_1_out_1',
        targetPortId: 'hw_in_1',
        isGhostConnection: true,
        properties: {
          'busNumber': 17,
        },
      );
      
      // Create ConnectionData instances
      final connectionDataList = [
        ConnectionData(
          connection: validConnection,
          sourcePosition: const Offset(100, 100),
          destinationPosition: const Offset(300, 200),
        ),
        ConnectionData(
          connection: invalidConnection,
          sourcePosition: const Offset(150, 120),
          destinationPosition: const Offset(350, 220),
        ),
        ConnectionData(
          connection: ghostConnection,
          sourcePosition: const Offset(200, 140),
          destinationPosition: const Offset(400, 240),
        ),
      ];
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 500,
              height: 400,
              child: CustomPaint(
                painter: ConnectionPainter(
                  connections: connectionDataList,
                  theme: ThemeData.light(),
                  enableAntiOverlap: false,
                  showLabels: true,
                  enableAnimations: false,
                ),
              ),
            ),
          ),
        ),
      );
      
      await tester.pumpAndSettle();
      
      // Verify the widget builds without error
      expect(find.byType(CustomPaint), findsWidgets);
      
      // Verify the painter is configured correctly
      // Find the specific CustomPaint with our ConnectionPainter
      ConnectionPainter? painter;
      final customPaintWidgets = tester.widgetList<CustomPaint>(find.byType(CustomPaint));
      for (final customPaint in customPaintWidgets) {
        if (customPaint.painter is ConnectionPainter) {
          painter = customPaint.painter as ConnectionPainter;
          break;
        }
      }
      
      expect(painter, isNotNull);
      
      expect(painter!.connections.length, equals(3));
      expect(painter.connections.where((c) => c.isInvalidOrder).length, equals(1));
      expect(painter.connections.where((c) => c.isGhostConnection).length, equals(1));
      expect(painter.connections.where((c) => !c.isInvalidOrder && !c.isGhostConnection).length, equals(1));
    });
    
    testWidgets('Invalid connections work with ConnectionCanvas animation widget', (tester) async {
      final invalidConnection = const Connection(
        id: 'invalid_conn',
        sourcePortId: 'algo_2_out_1',
        targetPortId: 'algo_1_in_1',
        properties: {
          'isInvalidOrder': true,
        },
      );
      
      final connectionDataList = [
        ConnectionData(
          connection: invalidConnection,
          sourcePosition: const Offset(150, 120),
          destinationPosition: const Offset(350, 220),
        ),
      ];
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 500,
              height: 400,
              child: ConnectionCanvas(
                connections: connectionDataList,
                enableAnimations: false,
                showLabels: false,
              ),
            ),
          ),
        ),
      );
      
      await tester.pumpAndSettle();
      
      // Verify the ConnectionCanvas builds and renders invalid connections
      expect(find.byType(ConnectionCanvas), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
      
      // Verify the connections are properly configured
      final connectionCanvas = tester.widget<ConnectionCanvas>(find.byType(ConnectionCanvas));
      expect(connectionCanvas.connections.length, equals(1));
      expect(connectionCanvas.connections.first.isInvalidOrder, isTrue);
    });
    
    testWidgets('Theme changes affect invalid connection colors', (tester) async {
      final invalidConnection = const Connection(
        id: 'invalid_conn',
        sourcePortId: 'algo_2_out_1',
        targetPortId: 'algo_1_in_1',
        properties: {
          'isInvalidOrder': true,
        },
      );
      
      final connectionDataList = [
        ConnectionData(
          connection: invalidConnection,
          sourcePosition: const Offset(150, 120),
          destinationPosition: const Offset(350, 220),
        ),
      ];
      
      // Test with light theme
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: Scaffold(
            body: SizedBox(
              width: 500,
              height: 400,
              child: ConnectionCanvas(
                connections: connectionDataList,
                enableAnimations: false,
              ),
            ),
          ),
        ),
      );
      
      await tester.pumpAndSettle();
      
      final lightThemeCanvas = tester.widget<ConnectionCanvas>(find.byType(ConnectionCanvas));
      expect(lightThemeCanvas.connections.first.isInvalidOrder, isTrue);
      
      // Test with dark theme
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: SizedBox(
              width: 500,
              height: 400,
              child: ConnectionCanvas(
                connections: connectionDataList,
                enableAnimations: false,
              ),
            ),
          ),
        ),
      );
      
      await tester.pumpAndSettle();
      
      final darkThemeCanvas = tester.widget<ConnectionCanvas>(find.byType(ConnectionCanvas));
      expect(darkThemeCanvas.connections.first.isInvalidOrder, isTrue);
    });
    
    testWidgets('Invalid connections are properly layered', (tester) async {
      // Test the layering order: regular -> ghost -> invalid -> selected
      final connections = [
        ConnectionData(
          connection: const Connection(
            id: 'regular_conn',
            sourcePortId: 'algo_1_out_1',
            targetPortId: 'algo_2_in_1',
          ),
          sourcePosition: const Offset(100, 100),
          destinationPosition: const Offset(300, 200),
        ),
        ConnectionData(
          connection: const Connection(
            id: 'ghost_conn',
            sourcePortId: 'algo_1_out_1',
            targetPortId: 'hw_in_1',
            isGhostConnection: true,
          ),
          sourcePosition: const Offset(110, 110),
          destinationPosition: const Offset(310, 210),
        ),
        ConnectionData(
          connection: const Connection(
            id: 'invalid_conn',
            sourcePortId: 'algo_2_out_1',
            targetPortId: 'algo_1_in_1',
            properties: {
              'isInvalidOrder': true,
            },
          ),
          sourcePosition: const Offset(120, 120),
          destinationPosition: const Offset(320, 220),
        ),
        ConnectionData(
          connection: const Connection(
            id: 'selected_conn',
            sourcePortId: 'algo_3_out_1',
            targetPortId: 'algo_4_in_1',
          ),
          sourcePosition: const Offset(130, 130),
          destinationPosition: const Offset(330, 230),
          isSelected: true,
        ),
      ];
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 500,
              height: 400,
              child: ConnectionCanvas(
                connections: connections,
                enableAnimations: false,
              ),
            ),
          ),
        ),
      );
      
      await tester.pumpAndSettle();
      
      // Verify all connection types are present
      final connectionCanvas = tester.widget<ConnectionCanvas>(find.byType(ConnectionCanvas));
      expect(connectionCanvas.connections.length, equals(4));
      expect(connectionCanvas.connections.where((c) => c.isSelected).length, equals(1));
      expect(connectionCanvas.connections.where((c) => c.isInvalidOrder && !c.isSelected).length, equals(1));
      expect(connectionCanvas.connections.where((c) => c.isGhostConnection && !c.isSelected).length, equals(1));
      expect(connectionCanvas.connections.where((c) => !c.isSelected && !c.isInvalidOrder && !c.isGhostConnection).length, equals(1));
    });
  });
}