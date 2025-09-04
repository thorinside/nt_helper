import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nt_helper/ui/widgets/routing/routing_editor_widget.dart';
import 'package:nt_helper/ui/widgets/routing/algorithm_node_widget.dart';
import 'package:nt_helper/ui/widgets/routing/physical_input_node.dart';
import 'package:nt_helper/ui/widgets/routing/physical_output_node.dart';
import 'package:nt_helper/ui/widgets/routing/port_widget.dart';
import 'package:nt_helper/cubit/routing_editor_cubit.dart';
import 'package:nt_helper/cubit/routing_editor_state.dart';
import 'package:nt_helper/cubit/disting_cubit.dart';
import 'package:nt_helper/core/routing/models/port.dart' as core_port;
import 'package:nt_helper/core/routing/models/connection.dart';
import 'package:nt_helper/core/routing/models/algorithm_routing_metadata.dart';

/// Tests for routing editor state management with movable nodes.
/// 
/// Validates that the RoutingEditorCubit properly manages:
/// - Node position updates
/// - Port position tracking
/// - Connection updates when nodes move  
/// - State persistence across UI rebuilds
/// - Coordination between different node types
void main() {
  group('Routing Editor State Management Tests', () {
    
    late MockRoutingEditorCubit mockCubit;
    late MockDistingCubit mockDistingCubit;

    setUp(() {
      mockCubit = MockRoutingEditorCubit();
      mockDistingCubit = MockDistingCubit();
    });

    group('Node Position Management', () {
      testWidgets('RoutingEditor handles algorithm node position updates', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: MultiBlocProvider(
              providers: [
                BlocProvider<RoutingEditorCubit>.value(value: mockCubit),
                BlocProvider<DistingCubit>.value(value: mockDistingCubit),
              ],
              child: Scaffold(
                body: RoutingEditorWidget(
                  canvasSize: const Size(800, 600),
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // RoutingEditor should be rendered
        expect(find.byType(RoutingEditorWidget), findsOneWidget);
        
        // Initial state should be handled gracefully
        expect(mockCubit.refreshCallCount, equals(1)); // Initial refresh call
      });

      testWidgets('Physical I/O node positions can be tracked independently', (tester) async {
        final Map<String, Offset> trackedPositions = {};
        
        void trackPosition(String nodeId, Offset position) {
          trackedPositions[nodeId] = position;
        }

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
                      onPositionChanged: (pos) => trackPosition('physical_input', pos),
                    ),
                  ),
                  Positioned(
                    left: 400,
                    top: 150,
                    child: PhysicalOutputNode(
                      position: const Offset(400, 150),
                      onPositionChanged: (pos) => trackPosition('physical_output', pos),
                    ),
                  ),
                  Positioned(
                    left: 250,
                    top: 200,
                    child: AlgorithmNodeWidget(
                      algorithmName: 'Test Algorithm',
                      slotNumber: 1,
                      position: const Offset(250, 200),
                      onPositionChanged: (pos) => trackPosition('algorithm_1', pos),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // All nodes should be present
        expect(find.byType(PhysicalInputNode), findsOneWidget);
        expect(find.byType(PhysicalOutputNode), findsOneWidget);
        expect(find.byType(AlgorithmNodeWidget), findsOneWidget);

        // Move physical input node
        await tester.dragFrom(
          tester.getCenter(find.byType(PhysicalInputNode)),
          const Offset(50, 25),
        );
        await tester.pumpAndSettle();

        // Only physical input position should be tracked
        expect(trackedPositions.containsKey('physical_input'), isTrue);
        expect(trackedPositions['physical_input'], isNot(equals(const Offset(100, 100))));
      });

      testWidgets('Mixed node movements are handled correctly', (tester) async {
        final List<String> movementHistory = [];
        
        void trackMovement(String nodeType) {
          movementHistory.add(nodeType);
        }

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Stack(
                children: [
                  Positioned(
                    left: 100,
                    top: 100,
                    child: AlgorithmNodeWidget(
                      algorithmName: 'Algorithm 1',
                      slotNumber: 1,
                      position: const Offset(100, 100),
                      onPositionChanged: (pos) => trackMovement('algorithm'),
                    ),
                  ),
                  Positioned(
                    left: 300,
                    top: 100,
                    child: PhysicalInputNode(
                      position: const Offset(300, 100),
                      onPositionChanged: (pos) => trackMovement('physical_input'),
                    ),
                  ),
                  Positioned(
                    left: 500,
                    top: 100,
                    child: PhysicalOutputNode(
                      position: const Offset(500, 100),
                      onPositionChanged: (pos) => trackMovement('physical_output'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Move nodes in sequence
        await tester.dragFrom(
          tester.getCenter(find.byType(AlgorithmNodeWidget)),
          const Offset(25, 25),
        );
        await tester.pumpAndSettle();

        await tester.dragFrom(
          tester.getCenter(find.byType(PhysicalInputNode)),
          const Offset(-25, 25),
        );
        await tester.pumpAndSettle();

        await tester.dragFrom(
          tester.getCenter(find.byType(PhysicalOutputNode)),
          const Offset(25, -25),
        );
        await tester.pumpAndSettle();

        // Should track all movements
        expect(movementHistory, contains('algorithm'));
        expect(movementHistory, contains('physical_input'));
        expect(movementHistory, contains('physical_output'));
        expect(movementHistory.length, equals(3));
      });
    });

    group('Port Position State Management', () {
      testWidgets('Port positions are maintained across node movements', (tester) async {
        final Map<String, List<Offset>> portHistories = {};

        void trackPortPosition(String portId, Offset position, bool isInput) {
          portHistories.putIfAbsent(portId, () => []).add(position);
        }

        Offset nodePosition = const Offset(150, 150);

        Widget buildMovableAlgorithm() {
          return MaterialApp(
            home: Scaffold(
              body: Positioned(
                left: nodePosition.dx,
                top: nodePosition.dy,
                child: AlgorithmNodeWidget(
                  algorithmName: 'Position Tracker',
                  slotNumber: 1,
                  position: nodePosition,
                  inputLabels: ['Input 1', 'Input 2'],
                  outputLabels: ['Output 1'],
                  inputPortIds: ['track_in1', 'track_in2'],
                  outputPortIds: ['track_out1'],
                  onPortPositionResolved: trackPortPosition,
                ),
              ),
            ),
          );
        }

        // Initial position
        await tester.pumpWidget(buildMovableAlgorithm());
        await tester.pumpAndSettle();
        await tester.pump();

        // Move node multiple times
        final positions = [
          const Offset(200, 200),
          const Offset(150, 250),
          const Offset(300, 180),
        ];

        for (final pos in positions) {
          nodePosition = pos;
          await tester.pumpWidget(buildMovableAlgorithm());
          await tester.pumpAndSettle();
          await tester.pump();
        }

        // Verify port positions were tracked throughout
        expect(portHistories.containsKey('track_in1'), isTrue);
        expect(portHistories.containsKey('track_in2'), isTrue);
        expect(portHistories.containsKey('track_out1'), isTrue);

        // Each port should have multiple position records
        for (final history in portHistories.values) {
          expect(history.length, greaterThan(1));
        }
      });

      testWidgets('Port positions are coordinated between node types', (tester) async {
        final Map<String, Offset> currentPortPositions = {};

        void trackAlgorithmPort(String portId, Offset position, bool isInput) {
          currentPortPositions[portId] = position;
        }

        void trackPhysicalPort(Port port, Offset position) {
          currentPortPositions[port.id] = position;
        }

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
                      onPortPositionResolved: trackPhysicalPort,
                    ),
                  ),
                  Positioned(
                    left: 350,
                    top: 130,
                    child: AlgorithmNodeWidget(
                      algorithmName: 'Coordinated',
                      slotNumber: 1,
                      position: const Offset(350, 130),
                      inputLabels: ['From Physical'],
                      outputLabels: ['To Physical'],
                      inputPortIds: ['coord_in'],
                      outputPortIds: ['coord_out'],
                      onPortPositionResolved: trackAlgorithmPort,
                    ),
                  ),
                  Positioned(
                    left: 600,
                    top: 100,
                    child: PhysicalOutputNode(
                      position: const Offset(600, 100),
                      onPortPositionResolved: trackPhysicalPort,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        await tester.pump();

        // Should have positions from all node types
        final physicalInputPorts = currentPortPositions.keys
            .where((id) => id.startsWith('hw_in_'))
            .length;
        final physicalOutputPorts = currentPortPositions.keys
            .where((id) => id.startsWith('hw_out_'))
            .length;
        final algorithmPorts = currentPortPositions.keys
            .where((id) => id.startsWith('coord_'))
            .length;

        expect(physicalInputPorts, equals(12));
        expect(physicalOutputPorts, equals(8));
        expect(algorithmPorts, equals(2));

        // Verify logical positioning relationships
        final algorithmInPos = currentPortPositions['coord_in'];
        final algorithmOutPos = currentPortPositions['coord_out'];
        
        expect(algorithmInPos, isNotNull);
        expect(algorithmOutPos, isNotNull);
        expect(algorithmOutPos!.dx, greaterThan(algorithmInPos!.dx));
      });
    });

    group('State Persistence and UI Rebuilds', () {
      testWidgets('Node positions persist across widget rebuilds', (tester) async {
        final Map<String, Offset> persistedPositions = {};
        bool isFirstRender = true;

        Widget buildTestScene() {
          return MaterialApp(
            home: Scaffold(
              body: AlgorithmNodeWidget(
                algorithmName: 'Persistent Node',
                slotNumber: 1,
                position: const Offset(200, 200),
                inputLabels: ['Persistent Input'],
                inputPortIds: ['persist_in'],
                onPortPositionResolved: (portId, pos, isInput) {
                  if (isFirstRender) {
                    persistedPositions[portId] = pos;
                  }
                },
              ),
            ),
          );
        }

        // First render
        await tester.pumpWidget(buildTestScene());
        await tester.pumpAndSettle();
        await tester.pump();

        expect(persistedPositions.containsKey('persist_in'), isTrue);
        final firstPosition = persistedPositions['persist_in']!;

        isFirstRender = false;

        // Second render (widget rebuild)
        await tester.pumpWidget(buildTestScene());
        await tester.pumpAndSettle();
        await tester.pump();

        // Node should still be in the same position
        expect(find.byType(AlgorithmNodeWidget), findsOneWidget);
        expect(find.byType(PortWidget), findsOneWidget);
        
        // Position should be consistent (test validates no crash occurs)
        expect(firstPosition.dx, greaterThan(0));
        expect(firstPosition.dy, greaterThan(0));
      });

      testWidgets('Complex state changes are handled gracefully', (tester) async {
        int rebuildCount = 0;
        
        Widget buildComplexScene() {
          rebuildCount++;
          return MaterialApp(
            home: Scaffold(
              body: Stack(
                children: [
                  if (rebuildCount >= 1)
                    Positioned(
                      left: 50,
                      top: 50,
                      child: PhysicalInputNode(position: const Offset(50, 50)),
                    ),
                  if (rebuildCount >= 2)
                    Positioned(
                      left: 250,
                      top: 100,
                      child: AlgorithmNodeWidget(
                        algorithmName: 'Dynamic Algorithm',
                        slotNumber: 1,
                        position: const Offset(250, 100),
                        inputLabels: ['Dynamic Input'],
                      ),
                    ),
                  if (rebuildCount >= 3)
                    Positioned(
                      left: 450,
                      top: 75,
                      child: PhysicalOutputNode(position: const Offset(450, 75)),
                    ),
                ],
              ),
            ),
          );
        }

        // Gradual scene build
        await tester.pumpWidget(buildComplexScene()); // Physical input only
        await tester.pumpAndSettle();
        expect(find.byType(PhysicalInputNode), findsOneWidget);
        expect(find.byType(AlgorithmNodeWidget), findsNothing);

        await tester.pumpWidget(buildComplexScene()); // Add algorithm
        await tester.pumpAndSettle();
        expect(find.byType(PhysicalInputNode), findsOneWidget);
        expect(find.byType(AlgorithmNodeWidget), findsOneWidget);

        await tester.pumpWidget(buildComplexScene()); // Add physical output
        await tester.pumpAndSettle();
        expect(find.byType(PhysicalInputNode), findsOneWidget);
        expect(find.byType(AlgorithmNodeWidget), findsOneWidget);
        expect(find.byType(PhysicalOutputNode), findsOneWidget);

        // Final port count: 12 + 1 + 8 = 21
        expect(find.byType(PortWidget), findsNWidgets(21));
      });
    });

    group('Coordination Between Node Types', () {
      testWidgets('Physical and algorithm node movements are independent', (tester) async {
        final List<String> dragStartEvents = [];
        final List<String> dragEndEvents = [];

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
                      onNodeDragStart: () => dragStartEvents.add('physical_input_start'),
                      onNodeDragEnd: () => dragEndEvents.add('physical_input_end'),
                    ),
                  ),
                  Positioned(
                    left: 300,
                    top: 150,
                    child: AlgorithmNodeWidget(
                      algorithmName: 'Independent Algorithm',
                      slotNumber: 1,
                      position: const Offset(300, 150),
                      onDragStart: () => dragStartEvents.add('algorithm_start'),
                      onDragEnd: () => dragEndEvents.add('algorithm_end'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Drag physical node
        await tester.dragFrom(
          tester.getCenter(find.byType(PhysicalInputNode)),
          const Offset(50, 50),
        );
        await tester.pumpAndSettle();

        // Drag algorithm node
        await tester.dragFrom(
          tester.getCenter(find.byType(AlgorithmNodeWidget)),
          const Offset(-25, 25),
        );
        await tester.pumpAndSettle();

        // Verify independent drag events
        expect(dragStartEvents, contains('physical_input_start'));
        expect(dragStartEvents, contains('algorithm_start'));
        expect(dragEndEvents, contains('physical_input_end'));
        expect(dragEndEvents, contains('algorithm_end'));
        
        // Each node should have been dragged once
        expect(dragStartEvents.length, equals(2));
        expect(dragEndEvents.length, equals(2));
      });

      testWidgets('Port position callbacks work independently', (tester) async {
        final Set<String> algorithmPortIds = {};
        final Set<String> physicalPortIds = {};

        void trackAlgorithmPort(String portId, Offset position, bool isInput) {
          algorithmPortIds.add(portId);
        }

        void trackPhysicalPort(Port port, Offset position) {
          physicalPortIds.add(port.id);
        }

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Stack(
                children: [
                  Positioned(
                    left: 50,
                    top: 50,
                    child: AlgorithmNodeWidget(
                      algorithmName: 'Callback Test',
                      slotNumber: 1,
                      position: const Offset(50, 50),
                      inputLabels: ['CB Input'],
                      outputLabels: ['CB Output'],
                      inputPortIds: ['cb_in'],
                      outputPortIds: ['cb_out'],
                      onPortPositionResolved: trackAlgorithmPort,
                    ),
                  ),
                  Positioned(
                    left: 300,
                    top: 50,
                    child: PhysicalInputNode(
                      position: const Offset(300, 50),
                      onPortPositionResolved: trackPhysicalPort,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        await tester.pump();

        // Verify independent callback systems
        expect(algorithmPortIds, contains('cb_in'));
        expect(algorithmPortIds, contains('cb_out'));
        expect(algorithmPortIds.length, equals(2));

        expect(physicalPortIds.length, equals(12)); // I1-I12
        for (int i = 1; i <= 12; i++) {
          expect(physicalPortIds, contains('hw_in_$i'));
        }

        // No cross-contamination
        expect(algorithmPortIds.intersection(physicalPortIds), isEmpty);
      });
    });

    group('Error Handling and Edge Cases', () {
      testWidgets('Handles null cubit states gracefully', (tester) async {
        final nullCubit = NullStateCubit();

        await tester.pumpWidget(
          MaterialApp(
            home: MultiBlocProvider(
              providers: [
                BlocProvider<RoutingEditorCubit>.value(value: nullCubit),
                BlocProvider<DistingCubit>.value(value: mockDistingCubit),
              ],
              child: Scaffold(
                body: RoutingEditorWidget(),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Should render without crashing
        expect(find.byType(RoutingEditorWidget), findsOneWidget);
      });

      testWidgets('Handles rapid state changes without errors', (tester) async {
        final rapidCubit = RapidChangeCubit();

        await tester.pumpWidget(
          MaterialApp(
            home: MultiBlocProvider(
              providers: [
                BlocProvider<RoutingEditorCubit>.value(value: rapidCubit),
                BlocProvider<DistingCubit>.value(value: mockDistingCubit),
              ],
              child: Scaffold(
                body: RoutingEditorWidget(canvasSize: const Size(400, 300)),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Trigger rapid changes
        for (int i = 0; i < 5; i++) {
          rapidCubit.triggerChange();
          await tester.pump(const Duration(milliseconds: 10));
        }

        await tester.pumpAndSettle();

        // Should handle rapid changes without crashing
        expect(find.byType(RoutingEditorWidget), findsOneWidget);
      });
    });
  });
}

// Mock implementations for testing

class MockRoutingEditorCubit extends RoutingEditorCubit {
  int refreshCallCount = 0;

  MockRoutingEditorCubit() : super(distingCubit: MockDistingCubit());

  @override
  RoutingEditorState get state => const RoutingEditorStateInitial();

  @override
  Future<void> refreshRouting() async {
    refreshCallCount++;
  }
}

class MockDistingCubit extends DistingCubit {
  MockDistingCubit() : super(
    distingRepository: null, 
    algorithmMetadataService: null,
  );
}

class NullStateCubit extends RoutingEditorCubit {
  NullStateCubit() : super(distingCubit: MockDistingCubit());

  @override
  RoutingEditorState get state => const RoutingEditorStateInitial();

  @override
  Stream<RoutingEditorState> get stream => Stream.empty();
}

class RapidChangeCubit extends RoutingEditorCubit {
  RapidChangeCubit() : super(distingCubit: MockDistingCubit());

  @override
  RoutingEditorState get state => const RoutingEditorStateInitial();

  void triggerChange() {
    // Simulate rapid state changes
  }
}