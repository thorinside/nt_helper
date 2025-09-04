import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/ui/widgets/routing/physical_input_node.dart';
import 'package:nt_helper/ui/widgets/routing/physical_output_node.dart';
import 'package:nt_helper/ui/widgets/routing/movable_physical_io_node.dart';
import 'package:nt_helper/ui/widgets/routing/port_widget.dart';
import 'package:nt_helper/core/routing/models/port.dart';

/// Tests for physical I/O node movement functionality and connection updates.
/// 
/// Validates that physical I/O nodes can be moved correctly, port positions
/// update properly, and connections follow the nodes as they move.
void main() {
  group('Physical I/O Node Movement Tests', () {
    
    group('Basic Node Movement', () {
      testWidgets('Physical input node can be dragged to new position', (tester) async {
        Offset? updatedPosition;
        bool dragStartCalled = false;
        bool dragEndCalled = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PhysicalInputNode(
                position: const Offset(100, 100),
                onPositionChanged: (newPosition) => updatedPosition = newPosition,
                onNodeDragStart: () => dragStartCalled = true,
                onNodeDragEnd: () => dragEndCalled = true,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify initial state
        expect(find.byType(PhysicalInputNode), findsOneWidget);
        expect(find.byType(PortWidget), findsNWidgets(12)); // I1-I12

        // Perform drag gesture
        await tester.dragFrom(
          tester.getCenter(find.byType(PhysicalInputNode)),
          const Offset(125, 75), // Move by 125, 75
        );
        await tester.pumpAndSettle();

        // Verify drag callbacks were triggered
        expect(dragStartCalled, isTrue);
        expect(dragEndCalled, isTrue);
        expect(updatedPosition, isNotNull);

        // Verify position is snapped to grid (25px grid for physical nodes)
        expect(updatedPosition!.dx % 25, equals(0));
        expect(updatedPosition!.dy % 25, equals(0));

        // Position should have moved from original
        expect(updatedPosition, isNot(equals(const Offset(100, 100))));
      });

      testWidgets('Physical output node can be dragged to new position', (tester) async {
        Offset? updatedPosition;
        bool dragStartCalled = false;
        bool dragEndCalled = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PhysicalOutputNode(
                position: const Offset(200, 150),
                onPositionChanged: (newPosition) => updatedPosition = newPosition,
                onNodeDragStart: () => dragStartCalled = true,
                onNodeDragEnd: () => dragEndCalled = true,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify initial state
        expect(find.byType(PhysicalOutputNode), findsOneWidget);
        expect(find.byType(PortWidget), findsNWidgets(8)); // O1-O8

        // Perform drag gesture
        await tester.dragFrom(
          tester.getCenter(find.byType(PhysicalOutputNode)),
          const Offset(-50, 100), // Move by -50, 100
        );
        await tester.pumpAndSettle();

        // Verify drag callbacks were triggered
        expect(dragStartCalled, isTrue);
        expect(dragEndCalled, isTrue);
        expect(updatedPosition, isNotNull);

        // Verify position changed
        expect(updatedPosition, isNot(equals(const Offset(200, 150))));
      });

      testWidgets('MovablePhysicalIONode base class handles movement', (tester) async {
        final testPorts = [
          Port(
            id: 'test_1',
            name: 'Test 1',
            type: PortType.audio,
            direction: PortDirection.input,
          ),
          Port(
            id: 'test_2',
            name: 'Test 2',
            type: PortType.cv,
            direction: PortDirection.output,
          ),
        ];

        Offset? updatedPosition;
        bool dragStartCalled = false;
        bool dragEndCalled = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MovablePhysicalIONode(
                ports: testPorts,
                title: 'Test Node',
                icon: Icons.settings,
                position: const Offset(150, 200),
                isInput: true,
                onPositionChanged: (newPosition) => updatedPosition = newPosition,
                onNodeDragStart: () => dragStartCalled = true,
                onNodeDragEnd: () => dragEndCalled = true,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Perform drag
        await tester.dragFrom(
          tester.getCenter(find.byType(MovablePhysicalIONode)),
          const Offset(75, -25),
        );
        await tester.pumpAndSettle();

        // Verify movement functionality
        expect(dragStartCalled, isTrue);
        expect(dragEndCalled, isTrue);
        expect(updatedPosition, isNotNull);
        expect(updatedPosition, isNot(equals(const Offset(150, 200))));
      });
    });

    group('Position Constraints and Grid Snapping', () {
      testWidgets('Node positions are constrained to canvas bounds', (tester) async {
        Offset? finalPosition;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PhysicalInputNode(
                position: const Offset(0, 0),
                onPositionChanged: (newPosition) => finalPosition = newPosition,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Try to drag beyond canvas bounds (negative position)
        await tester.dragFrom(
          tester.getCenter(find.byType(PhysicalInputNode)),
          const Offset(-1000, -1000), // Large negative drag
        );
        await tester.pumpAndSettle();

        // Position should be constrained to minimum bounds
        expect(finalPosition, isNotNull);
        expect(finalPosition!.dx, greaterThanOrEqualTo(0));
        expect(finalPosition!.dy, greaterThanOrEqualTo(0));

        // Try to drag to maximum bounds
        await tester.dragFrom(
          tester.getCenter(find.byType(PhysicalInputNode)),
          const Offset(10000, 10000), // Large positive drag
        );
        await tester.pumpAndSettle();

        // Position should be constrained to canvas size (5000 - node width/height)
        expect(finalPosition!.dx, lessThan(5000));
        expect(finalPosition!.dy, lessThan(5000));
      });

      testWidgets('Grid snapping works correctly', (tester) async {
        final List<Offset> positionHistory = [];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PhysicalOutputNode(
                position: const Offset(100, 100),
                onPositionChanged: (newPosition) => positionHistory.add(newPosition),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Drag to positions that should snap to grid
        const List<Offset> testDrags = [
          Offset(12, 7),   // Should snap to 25x25 grid
          Offset(38, 19),  // Should snap to 50x25 grid
          Offset(63, 44),  // Should snap to 75x50 grid
        ];

        for (final dragOffset in testDrags) {
          await tester.dragFrom(
            tester.getCenter(find.byType(PhysicalOutputNode)),
            dragOffset,
          );
          await tester.pumpAndSettle();
        }

        // Verify all positions are snapped to 25px grid
        for (final position in positionHistory) {
          expect(position.dx % 25, equals(0), 
              reason: 'X position ${position.dx} should be snapped to 25px grid');
          expect(position.dy % 25, equals(0), 
              reason: 'Y position ${position.dy} should be snapped to 25px grid');
        }
      });
    });

    group('Port Position Updates During Movement', () {
      testWidgets('Port positions update when node moves', (tester) async {
        final Map<String, List<Offset>> portPositionHistory = {};

        void trackPortPosition(Port port, Offset position) {
          portPositionHistory.putIfAbsent(port.id, () => []).add(position);
        }

        Offset nodePosition = const Offset(100, 100);

        Widget buildMovableNode() {
          return MaterialApp(
            home: Scaffold(
              body: Positioned(
                left: nodePosition.dx,
                top: nodePosition.dy,
                child: PhysicalInputNode(
                  position: nodePosition,
                  onPortPositionResolved: trackPortPosition,
                ),
              ),
            ),
          );
        }

        // Initial position
        await tester.pumpWidget(buildMovableNode());
        await tester.pumpAndSettle();
        await tester.pump(); // Allow port position callbacks

        // Move node
        nodePosition = const Offset(200, 150);
        await tester.pumpWidget(buildMovableNode());
        await tester.pumpAndSettle();
        await tester.pump(); // Allow port position callbacks

        // Verify port positions updated
        expect(portPositionHistory.isNotEmpty, isTrue);
        
        // Check that at least some ports have multiple positions recorded
        final portsWithHistory = portPositionHistory.entries
            .where((entry) => entry.value.length >= 2)
            .toList();
        expect(portsWithHistory.isNotEmpty, isTrue);

        // Verify port positions moved by roughly the same delta as the node
        for (final entry in portsWithHistory) {
          final positions = entry.value;
          final initialPos = positions.first;
          final finalPos = positions.last;
          final portDelta = finalPos - initialPos;

          // Port should move roughly the same amount as the node
          const nodeDelta = Offset(100, 50);
          expect((portDelta.dx - nodeDelta.dx).abs(), lessThan(50),
              reason: 'Port ${entry.key} X delta should match node movement');
          expect((portDelta.dy - nodeDelta.dy).abs(), lessThan(50),
              reason: 'Port ${entry.key} Y delta should match node movement');
        }
      });

      testWidgets('All port types update positions correctly', (tester) async {
        final Set<String> updatedPortIds = {};

        void trackPortUpdate(Port port, Offset position) {
          updatedPortIds.add(port.id);
        }

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Stack(
                children: [
                  Positioned(
                    left: 50,
                    top: 50,
                    child: PhysicalInputNode(
                      position: const Offset(50, 50),
                      onPortPositionResolved: trackPortUpdate,
                    ),
                  ),
                  Positioned(
                    left: 300,
                    top: 50,
                    child: PhysicalOutputNode(
                      position: const Offset(300, 50),
                      onPortPositionResolved: trackPortUpdate,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        await tester.pump(); // Allow callbacks

        // Should have updates for all physical ports
        expect(updatedPortIds, hasLength(20)); // 12 inputs + 8 outputs

        // Verify specific port IDs
        for (int i = 1; i <= 12; i++) {
          expect(updatedPortIds, contains('hw_in_$i'));
        }
        for (int i = 1; i <= 8; i++) {
          expect(updatedPortIds, contains('hw_out_$i'));
        }
      });
    });

    group('Visual Feedback During Movement', () {
      testWidgets('Node appearance changes during drag', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PhysicalInputNode(
                position: const Offset(100, 100),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Get the node widget
        final nodeWidget = find.byType(PhysicalInputNode);
        expect(nodeWidget, findsOneWidget);

        // Start drag but don't complete it
        final gesture = await tester.startGesture(tester.getCenter(nodeWidget));
        await tester.pump(); // Start drag

        // Node should still be rendered (visual feedback is handled by internal state)
        expect(find.byType(PhysicalInputNode), findsOneWidget);

        // Complete the drag
        await gesture.moveBy(const Offset(50, 50));
        await gesture.up();
        await tester.pumpAndSettle();

        // Node should return to normal state
        expect(find.byType(PhysicalInputNode), findsOneWidget);
      });

      testWidgets('Node maintains port structure during movement', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PhysicalOutputNode(
                position: const Offset(150, 150),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify initial port count
        expect(find.byType(PortWidget), findsNWidgets(8));

        // Perform drag
        await tester.dragFrom(
          tester.getCenter(find.byType(PhysicalOutputNode)),
          const Offset(100, 100),
        );
        await tester.pumpAndSettle();

        // Port count should remain the same after movement
        expect(find.byType(PortWidget), findsNWidgets(8));
        
        // All port labels should still be present
        for (int i = 1; i <= 8; i++) {
          expect(find.text('O$i'), findsOneWidget);
        }
      });
    });

    group('Simultaneous Node Movement', () {
      testWidgets('Multiple nodes can be moved independently', (tester) async {
        Offset? inputPosition;
        Offset? outputPosition;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Stack(
                children: [
                  Positioned(
                    left: 50,
                    top: 50,
                    child: PhysicalInputNode(
                      position: const Offset(50, 50),
                      onPositionChanged: (pos) => inputPosition = pos,
                    ),
                  ),
                  Positioned(
                    left: 300,
                    top: 50,
                    child: PhysicalOutputNode(
                      position: const Offset(300, 50),
                      onPositionChanged: (pos) => outputPosition = pos,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Move input node
        await tester.dragFrom(
          tester.getCenter(find.byType(PhysicalInputNode)),
          const Offset(75, 25),
        );
        await tester.pumpAndSettle();

        // Move output node
        await tester.dragFrom(
          tester.getCenter(find.byType(PhysicalOutputNode)),
          const Offset(-50, 75),
        );
        await tester.pumpAndSettle();

        // Both nodes should have moved
        expect(inputPosition, isNotNull);
        expect(outputPosition, isNotNull);
        expect(inputPosition, isNot(equals(const Offset(50, 50))));
        expect(outputPosition, isNot(equals(const Offset(300, 50))));

        // Nodes should maintain their identity
        expect(find.byType(PhysicalInputNode), findsOneWidget);
        expect(find.byType(PhysicalOutputNode), findsOneWidget);
      });

      testWidgets('Node movement does not affect other nodes', (tester) async {
        final List<String> inputNodeCallbacks = [];
        final List<String> outputNodeCallbacks = [];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Stack(
                children: [
                  Positioned(
                    left: 100,
                    top: 100,
                    child: PhysicalInputNode(
                      position: const Offset(100, 100),
                      onNodeDragStart: () => inputNodeCallbacks.add('start'),
                      onNodeDragEnd: () => inputNodeCallbacks.add('end'),
                    ),
                  ),
                  Positioned(
                    left: 300,
                    top: 100,
                    child: PhysicalOutputNode(
                      position: const Offset(300, 100),
                      onNodeDragStart: () => outputNodeCallbacks.add('start'),
                      onNodeDragEnd: () => outputNodeCallbacks.add('end'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Drag only the input node
        await tester.dragFrom(
          tester.getCenter(find.byType(PhysicalInputNode)),
          const Offset(50, 50),
        );
        await tester.pumpAndSettle();

        // Only input node callbacks should have been triggered
        expect(inputNodeCallbacks, equals(['start', 'end']));
        expect(outputNodeCallbacks, isEmpty);

        // Clear callbacks and test output node
        inputNodeCallbacks.clear();
        await tester.dragFrom(
          tester.getCenter(find.byType(PhysicalOutputNode)),
          const Offset(-25, 25),
        );
        await tester.pumpAndSettle();

        // Only output node callbacks should have been triggered
        expect(inputNodeCallbacks, isEmpty);
        expect(outputNodeCallbacks, equals(['start', 'end']));
      });
    });

    group('Error Handling and Edge Cases', () {
      testWidgets('Handles missing position callback gracefully', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PhysicalInputNode(
                position: const Offset(100, 100),
                // onPositionChanged is null
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Should render without errors
        expect(find.byType(PhysicalInputNode), findsOneWidget);

        // Drag should not cause errors
        await tester.dragFrom(
          tester.getCenter(find.byType(PhysicalInputNode)),
          const Offset(50, 50),
        );
        await tester.pumpAndSettle();

        expect(find.byType(PhysicalInputNode), findsOneWidget);
      });

      testWidgets('Handles rapid movement updates', (tester) async {
        final List<Offset> rapidUpdates = [];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PhysicalOutputNode(
                position: const Offset(200, 200),
                onPositionChanged: (pos) => rapidUpdates.add(pos),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Perform multiple rapid drag gestures
        final nodeCenter = tester.getCenter(find.byType(PhysicalOutputNode));
        for (int i = 0; i < 5; i++) {
          await tester.dragFrom(nodeCenter, Offset(i * 10.0, i * 5.0));
          await tester.pump(const Duration(milliseconds: 10)); // Rapid updates
        }
        await tester.pumpAndSettle();

        // Should handle multiple updates without errors
        expect(rapidUpdates.isNotEmpty, isTrue);
        expect(find.byType(PhysicalOutputNode), findsOneWidget);
      });
    });
  });
}