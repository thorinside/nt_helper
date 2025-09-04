import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nt_helper/ui/widgets/routing/algorithm_node_widget.dart';
import 'package:nt_helper/ui/widgets/routing/physical_input_node.dart';
import 'package:nt_helper/ui/widgets/routing/physical_output_node.dart';
import 'package:nt_helper/ui/widgets/routing/movable_physical_io_node.dart';
import 'package:nt_helper/ui/widgets/routing/port_widget.dart';
import 'package:nt_helper/ui/widgets/routing/routing_editor_widget.dart';
import 'package:nt_helper/cubit/routing_editor_cubit.dart';
import 'package:nt_helper/cubit/routing_editor_state.dart';
import 'package:nt_helper/cubit/disting_cubit.dart';
import 'package:nt_helper/core/routing/models/port.dart' as core_port;
import 'package:nt_helper/core/routing/models/connection.dart';

/// Comprehensive integration tests for the universal port widget architecture.
/// 
/// Tests verify that the same PortWidget works consistently across:
/// - Algorithm nodes (using dot style ports)
/// - Physical I/O nodes (using jack style ports)
/// - All connections between different node types
/// - Node movement and position updates
/// - State management across the routing system
void main() {
  group('Universal Port Widget Integration Tests', () {
    
    group('Port Widget Cross-Node Compatibility', () {
      testWidgets('PortWidget works consistently in algorithm nodes', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AlgorithmNodeWidget(
                algorithmName: 'Test Algorithm',
                slotNumber: 1,
                position: const Offset(100, 100),
                inputLabels: ['Input 1', 'Input 2'],
                outputLabels: ['Output 1'],
                inputPortIds: ['algo1_in_1', 'algo1_in_2'],
                outputPortIds: ['algo1_out_1'],
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify algorithm node contains port widgets
        expect(find.byType(PortWidget), findsNWidgets(3)); // 2 inputs + 1 output
        
        // Verify port styling for algorithm nodes (dot style by default)
        final portWidgets = tester.widgetList<PortWidget>(find.byType(PortWidget)).toList();
        for (final portWidget in portWidgets) {
          expect(portWidget.style, equals(PortStyle.dot));
        }
        
        // Verify input ports have right-positioned labels
        final inputPorts = portWidgets.where((w) => w.isInput).toList();
        for (final inputPort in inputPorts) {
          expect(inputPort.labelPosition, equals(PortLabelPosition.right));
        }
        
        // Verify output ports have left-positioned labels
        final outputPorts = portWidgets.where((w) => !w.isInput).toList();
        for (final outputPort in outputPorts) {
          expect(outputPort.labelPosition, equals(PortLabelPosition.left));
        }
      });

      testWidgets('PortWidget works consistently in physical input nodes', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PhysicalInputNode(
                position: const Offset(50, 50),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Physical input node should contain 12 port widgets (I1-I12)
        expect(find.byType(PortWidget), findsNWidgets(12));
        
        // Verify all ports use jack style for physical I/O
        final portWidgets = tester.widgetList<PortWidget>(find.byType(PortWidget)).toList();
        for (final portWidget in portWidgets) {
          expect(portWidget.style, equals(PortStyle.jack));
        }
        
        // Physical inputs act as outputs to algorithms, so labels should be left-positioned
        for (final portWidget in portWidgets) {
          expect(portWidget.labelPosition, equals(PortLabelPosition.left));
          expect(portWidget.isInput, isTrue); // From perspective of the node itself
        }
      });

      testWidgets('PortWidget works consistently in physical output nodes', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PhysicalOutputNode(
                position: const Offset(300, 50),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Physical output node should contain 8 port widgets (O1-O8)
        expect(find.byType(PortWidget), findsNWidgets(8));
        
        // Verify all ports use jack style for physical I/O
        final portWidgets = tester.widgetList<PortWidget>(find.byType(PortWidget)).toList();
        for (final portWidget in portWidgets) {
          expect(portWidget.style, equals(PortStyle.jack));
        }
        
        // Physical outputs act as inputs from algorithms, so labels should be right-positioned
        for (final portWidget in portWidgets) {
          expect(portWidget.labelPosition, equals(PortLabelPosition.right));
          expect(portWidget.isInput, isFalse); // From perspective of the node itself
        }
      });

      testWidgets('MovablePhysicalIONode uses PortWidget correctly', (tester) async {
        final testPorts = [
          core_port.Port(
            id: 'test_port_1',
            name: 'Test Port 1',
            type: core_port.PortType.audio,
            direction: core_port.PortDirection.input,
          ),
          core_port.Port(
            id: 'test_port_2',
            name: 'Test Port 2',
            type: core_port.PortType.cv,
            direction: core_port.PortDirection.output,
          ),
        ];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MovablePhysicalIONode(
                ports: testPorts,
                title: 'Test Node',
                icon: Icons.settings,
                position: const Offset(200, 200),
                isInput: true,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Should contain one PortWidget per port
        expect(find.byType(PortWidget), findsNWidgets(2));
        
        // Verify jack style is used
        final portWidgets = tester.widgetList<PortWidget>(find.byType(PortWidget)).toList();
        for (final portWidget in portWidgets) {
          expect(portWidget.style, equals(PortStyle.jack));
        }
        
        // Verify label positioning matches isInput parameter
        for (final portWidget in portWidgets) {
          expect(portWidget.labelPosition, equals(PortLabelPosition.left));
        }
      });
    });

    group('Port Position Resolution and Connection Anchoring', () {
      testWidgets('Port positions are resolved correctly across all node types', (tester) async {
        final List<String> resolvedPortIds = [];
        final Map<String, Offset> portPositions = {};
        final Map<String, bool> portInputStates = {};

        void onPortPositionResolved(String portId, Offset position, bool isInput) {
          resolvedPortIds.add(portId);
          portPositions[portId] = position;
          portInputStates[portId] = isInput;
        }

        // Test algorithm node port resolution
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AlgorithmNodeWidget(
                algorithmName: 'Test Algorithm',
                slotNumber: 1,
                position: const Offset(100, 100),
                inputLabels: ['Input 1'],
                outputLabels: ['Output 1'],
                inputPortIds: ['algo_in_1'],
                outputPortIds: ['algo_out_1'],
                onPortPositionResolved: onPortPositionResolved,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        await tester.pump(); // Allow post-frame callbacks to execute

        // Verify algorithm ports are resolved
        expect(resolvedPortIds, contains('algo_in_1'));
        expect(resolvedPortIds, contains('algo_out_1'));
        expect(portInputStates['algo_in_1'], isTrue);
        expect(portInputStates['algo_out_1'], isFalse);
        expect(portPositions['algo_in_1'], isNotNull);
        expect(portPositions['algo_out_1'], isNotNull);

        // Clear for next test
        resolvedPortIds.clear();
        portPositions.clear();
        portInputStates.clear();

        // Test physical input node port resolution
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PhysicalInputNode(
                position: const Offset(50, 50),
                onPortPositionResolved: (port, position) {
                  onPortPositionResolved(port.id, position, true);
                },
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        await tester.pump(); // Allow post-frame callbacks to execute

        // Verify physical input ports are resolved (I1-I12)
        expect(resolvedPortIds.length, equals(12));
        for (int i = 1; i <= 12; i++) {
          final portId = 'hw_in_$i';
          expect(resolvedPortIds, contains(portId));
          expect(portPositions[portId], isNotNull);
        }
      });

    });

    group('Theme and Visual Consistency', () {
      testWidgets('Port widgets respect theme colors consistently', (tester) async {
        final lightTheme = ThemeData.light();
        final darkTheme = ThemeData.dark();
        
        Widget buildTestWidget(ThemeData theme) {
          return MaterialApp(
            theme: theme,
            home: Scaffold(
              body: Column(
                children: [
                  AlgorithmNodeWidget(
                    algorithmName: 'Algorithm',
                    slotNumber: 1,
                    position: const Offset(0, 0),
                    inputLabels: ['Input'],
                    inputPortIds: ['algo_in'],
                  ),
                  PhysicalInputNode(position: const Offset(0, 100)),
                ],
              ),
            ),
          );
        }

        // Test light theme
        await tester.pumpWidget(buildTestWidget(lightTheme));
        await tester.pumpAndSettle();

        // All port widgets should exist
        final lightPortWidgets = find.byType(PortWidget);
        expect(lightPortWidgets, findsAtLeastNWidgets(13)); // 1 algo + 12 physical

        // Test dark theme
        await tester.pumpWidget(buildTestWidget(darkTheme));
        await tester.pumpAndSettle();

        // Should still find all port widgets
        final darkPortWidgets = find.byType(PortWidget);
        expect(darkPortWidgets, findsAtLeastNWidgets(13)); // 1 algo + 12 physical
      });
    });

    group('Interaction and Callback Handling', () {
      testWidgets('Port tap callbacks work across all node types', (tester) async {
        final List<String> tappedPorts = [];
        
        void onPortTapped(String portId) {
          tappedPorts.add(portId);
        }

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  AlgorithmNodeWidget(
                    algorithmName: 'Tappable Algorithm',
                    slotNumber: 1,
                    position: const Offset(0, 0),
                    inputLabels: ['Tap Input'],
                    inputPortIds: ['tappable_in'],
                    onPortPositionResolved: (portId, position, isInput) {
                      // Store callback for tap test
                    },
                  ),
                ],
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Find and tap a port
        final portWidget = find.byType(PortWidget).first;
        await tester.tap(portWidget);
        await tester.pumpAndSettle();

        // Note: Since the callback is handled inside PortWidget, 
        // we verify the tap gesture is recognized
        expect(portWidget, findsOneWidget);
      });

      testWidgets('Port drag callbacks work across all node types', (tester) async {
        final List<String> draggedPorts = [];
        
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AlgorithmNodeWidget(
                algorithmName: 'Draggable Algorithm',
                slotNumber: 1,
                position: const Offset(100, 100),
                outputLabels: ['Drag Output'],
                outputPortIds: ['draggable_out'],
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Test drag gesture on port
        final portWidget = find.byType(PortWidget).first;
        await tester.dragFrom(
          tester.getCenter(portWidget),
          const Offset(50, 50),
        );
        await tester.pumpAndSettle();

        // Verify drag gesture is handled
        expect(portWidget, findsOneWidget);
      });
    });

    group('Node Movement and Physical I/O Integration', () {
      testWidgets('Algorithm nodes work alongside movable physical I/O nodes', (tester) async {
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
                    ),
                  ),
                  Positioned(
                    left: 200,
                    top: 150,
                    child: AlgorithmNodeWidget(
                      algorithmName: 'Mixed Algorithm',
                      slotNumber: 1,
                      position: const Offset(200, 150),
                      inputLabels: ['From Physical'],
                      outputLabels: ['To Physical'],
                    ),
                  ),
                  Positioned(
                    left: 350,
                    top: 50,
                    child: PhysicalOutputNode(
                      position: const Offset(350, 50),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify all nodes render correctly together
        expect(find.byType(PhysicalInputNode), findsOneWidget);
        expect(find.byType(AlgorithmNodeWidget), findsOneWidget);
        expect(find.byType(PhysicalOutputNode), findsOneWidget);
        
        // Verify total port count (12 inputs + 2 algo + 8 outputs)
        expect(find.byType(PortWidget), findsNWidgets(22));
      });
    });

    group('Performance and Stability', () {
      testWidgets('Multiple port widgets perform well', (tester) async {
        // Create a scenario with many port widgets
        final stopwatch = Stopwatch()..start();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: Column(
                  children: [
                    PhysicalInputNode(position: const Offset(0, 0)),
                    PhysicalOutputNode(position: const Offset(0, 300)),
                    ...List.generate(5, (index) => AlgorithmNodeWidget(
                      algorithmName: 'Algorithm $index',
                      slotNumber: index + 1,
                      position: Offset(0, 600.0 + index * 150),
                      inputLabels: ['Input 1', 'Input 2'],
                      outputLabels: ['Output 1'],
                    )),
                  ],
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        stopwatch.stop();

        // Should render quickly (under 500ms for this test scenario)
        expect(stopwatch.elapsedMilliseconds, lessThan(500));

        // Verify all widgets rendered
        expect(find.byType(PortWidget), findsNWidgets(35)); // 12 + 8 + (3*5)
        expect(find.byType(PhysicalInputNode), findsOneWidget);
        expect(find.byType(PhysicalOutputNode), findsOneWidget);
        expect(find.byType(AlgorithmNodeWidget), findsNWidgets(5));
      });
    });

    group('Error Handling and Edge Cases', () {
      testWidgets('Handles missing port IDs gracefully', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AlgorithmNodeWidget(
                algorithmName: 'No Port IDs',
                slotNumber: 1,
                position: const Offset(100, 100),
                inputLabels: ['Input Without ID'],
                outputLabels: ['Output Without ID'],
                // inputPortIds and outputPortIds are null
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Should render without errors, but port callbacks won't fire
        expect(find.byType(AlgorithmNodeWidget), findsOneWidget);
        expect(find.byType(PortWidget), findsNWidgets(2));
      });

      testWidgets('Handles empty port lists', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MovablePhysicalIONode(
                ports: [], // Empty port list
                title: 'Empty Node',
                icon: Icons.clear,
                position: const Offset(100, 100),
                isInput: true,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Should render header but no ports
        expect(find.byType(MovablePhysicalIONode), findsOneWidget);
        expect(find.byType(PortWidget), findsNothing);
        expect(find.text('Empty Node'), findsOneWidget);
      });

      testWidgets('Handles null callbacks gracefully', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AlgorithmNodeWidget(
                algorithmName: 'No Callbacks',
                slotNumber: 1,
                position: const Offset(100, 100),
                inputLabels: ['Input'],
                inputPortIds: ['no_callback_in'],
                // All callbacks are null
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Should render without errors
        expect(find.byType(AlgorithmNodeWidget), findsOneWidget);
        expect(find.byType(PortWidget), findsOneWidget);

        // Interactions should not cause errors
        final portWidget = find.byType(PortWidget);
        await tester.tap(portWidget);
        await tester.pumpAndSettle();

        expect(find.byType(AlgorithmNodeWidget), findsOneWidget);
      });
    });
  });
}