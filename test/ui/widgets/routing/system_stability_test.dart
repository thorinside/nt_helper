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
import 'package:nt_helper/core/routing/models/port.dart';

/// Comprehensive system stability and user experience tests
/// for the universal port widget architecture.
/// 
/// Tests validate:
/// - Complete system stability under various conditions
/// - User experience consistency across all interactions
/// - Error handling and recovery
/// - Accessibility and usability
/// - Real-world usage scenarios
/// - System robustness with edge cases
void main() {
  group('System Stability and User Experience Tests', () {
    
    group('Complete System Integration', () {
      testWidgets('Full routing editor system works end-to-end', (tester) async {
        final mockRoutingCubit = MockRoutingEditorCubit();
        final mockDistingCubit = MockDistingCubit();

        await tester.pumpWidget(
          MaterialApp(
            home: MultiBlocProvider(
              providers: [
                BlocProvider<RoutingEditorCubit>.value(value: mockRoutingCubit),
                BlocProvider<DistingCubit>.value(value: mockDistingCubit),
              ],
              child: Scaffold(
                body: RoutingEditorWidget(
                  canvasSize: const Size(1000, 600),
                  showPhysicalPorts: true,
                  showBusLabels: true,
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // System should start up successfully
        expect(find.byType(RoutingEditorWidget), findsOneWidget);
        expect(mockRoutingCubit.refreshCallCount, equals(1));
        
        // Should handle initial state gracefully
        expect(tester.takeException(), isNull);
      });

      testWidgets('Mixed node types work together seamlessly', (tester) async {
        final Map<String, bool> nodeInteractions = {};

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Stack(
                children: [
                  // Complete routing scenario
                  Positioned(
                    left: 50,
                    top: 100,
                    child: PhysicalInputNode(
                      position: const Offset(50, 100),
                      onPortTapped: (port) => nodeInteractions['physical_input_tap'] = true,
                      onPositionChanged: (pos) => nodeInteractions['physical_input_move'] = true,
                    ),
                  ),
                  Positioned(
                    left: 300,
                    top: 120,
                    child: AlgorithmNodeWidget(
                      algorithmName: 'System Test Algorithm',
                      slotNumber: 1,
                      position: const Offset(300, 120),
                      inputLabels: ['System Input'],
                      outputLabels: ['System Output'],
                      inputPortIds: ['sys_in'],
                      outputPortIds: ['sys_out'],
                      onPositionChanged: (pos) => nodeInteractions['algorithm_move'] = true,
                      onTap: () => nodeInteractions['algorithm_tap'] = true,
                    ),
                  ),
                  Positioned(
                    left: 550,
                    top: 100,
                    child: PhysicalOutputNode(
                      position: const Offset(550, 100),
                      onPortTapped: (port) => nodeInteractions['physical_output_tap'] = true,
                      onPositionChanged: (pos) => nodeInteractions['physical_output_move'] = true,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // All node types should be present and functional
        expect(find.byType(PhysicalInputNode), findsOneWidget);
        expect(find.byType(AlgorithmNodeWidget), findsOneWidget);
        expect(find.byType(PhysicalOutputNode), findsOneWidget);
        expect(find.byType(PortWidget), findsNWidgets(22)); // 12 + 2 + 8

        // Test interactions across all node types
        await tester.tap(find.byType(AlgorithmNodeWidget));
        await tester.pumpAndSettle();
        expect(nodeInteractions['algorithm_tap'], isTrue);

        await tester.dragFrom(
          tester.getCenter(find.byType(PhysicalInputNode)),
          const Offset(25, 25),
        );
        await tester.pumpAndSettle();
        expect(nodeInteractions['physical_input_move'], isTrue);

        await tester.dragFrom(
          tester.getCenter(find.byType(AlgorithmNodeWidget)),
          const Offset(30, 20),
        );
        await tester.pumpAndSettle();
        expect(nodeInteractions['algorithm_move'], isTrue);

        // System should remain stable after multiple interactions
        expect(find.byType(PhysicalInputNode), findsOneWidget);
        expect(find.byType(AlgorithmNodeWidget), findsOneWidget);
        expect(find.byType(PhysicalOutputNode), findsOneWidget);
      });

      testWidgets('System handles complex user workflows', (tester) async {
        final List<String> workflowSteps = [];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Stack(
                children: [
                  Positioned(
                    left: 100,
                    top: 100,
                    child: AlgorithmNodeWidget(
                      algorithmName: 'Workflow Source',
                      slotNumber: 1,
                      position: const Offset(100, 100),
                      outputLabels: ['Source Out'],
                      outputPortIds: ['workflow_source'],
                      onDragStart: () => workflowSteps.add('source_drag_start'),
                      onDragEnd: () => workflowSteps.add('source_drag_end'),
                      onTap: () => workflowSteps.add('source_tap'),
                    ),
                  ),
                  Positioned(
                    left: 350,
                    top: 150,
                    child: AlgorithmNodeWidget(
                      algorithmName: 'Workflow Target',
                      slotNumber: 2,
                      position: const Offset(350, 150),
                      inputLabels: ['Target In'],
                      inputPortIds: ['workflow_target'],
                      onDragStart: () => workflowSteps.add('target_drag_start'),
                      onDragEnd: () => workflowSteps.add('target_drag_end'),
                      onTap: () => workflowSteps.add('target_tap'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Complex workflow: Select, move, connect, adjust
        await tester.tap(find.text('#1 Workflow Source'));
        await tester.pumpAndSettle();

        await tester.dragFrom(
          tester.getCenter(find.text('#1 Workflow Source')),
          const Offset(20, 20),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('#2 Workflow Target'));
        await tester.pumpAndSettle();

        await tester.dragFrom(
          tester.getCenter(find.text('#2 Workflow Target')),
          const Offset(-15, 30),
        );
        await tester.pumpAndSettle();

        // Workflow should complete without errors
        expect(workflowSteps, contains('source_drag_start'));
        expect(workflowSteps, contains('source_drag_end'));
        expect(workflowSteps, contains('target_drag_start'));
        expect(workflowSteps, contains('target_drag_end'));
        expect(workflowSteps.length, greaterThanOrEqualTo(4));

        // System should remain stable
        expect(find.byType(AlgorithmNodeWidget), findsNWidgets(2));
        expect(find.byType(PortWidget), findsNWidgets(2));
      });
    });

    group('Error Handling and Recovery', () {
      testWidgets('System recovers gracefully from rendering errors', (tester) async {
        bool hasError = false;

        // Widget that can trigger errors
        Widget buildErrorProneWidget({required bool shouldError}) {
          return MaterialApp(
            home: Scaffold(
              body: shouldError 
                ? throw FlutterError('Intentional test error')
                : AlgorithmNodeWidget(
                    algorithmName: 'Recovery Test',
                    slotNumber: 1,
                    position: const Offset(100, 100),
                    inputLabels: ['Test Input'],
                  ),
            ),
          );
        }

        // First, render successfully
        await tester.pumpWidget(buildErrorProneWidget(shouldError: false));
        await tester.pumpAndSettle();
        expect(find.byType(AlgorithmNodeWidget), findsOneWidget);

        // Simulate error condition and recovery
        try {
          await tester.pumpWidget(buildErrorProneWidget(shouldError: true));
          await tester.pumpAndSettle();
        } catch (e) {
          hasError = true;
        }

        // System should recover
        await tester.pumpWidget(buildErrorProneWidget(shouldError: false));
        await tester.pumpAndSettle();
        
        expect(find.byType(AlgorithmNodeWidget), findsOneWidget);
        expect(hasError, isTrue); // Error was caught as expected
      });

      testWidgets('Invalid port configurations handled gracefully', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AlgorithmNodeWidget(
                algorithmName: 'Invalid Config Test',
                slotNumber: 1,
                position: const Offset(100, 100),
                inputLabels: ['Input 1', 'Input 2'], // 2 labels
                inputPortIds: ['id1'], // Only 1 ID - mismatched count
                outputLabels: [], // No output labels
                outputPortIds: ['out1', 'out2'], // But 2 output IDs
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Should render without crashing despite mismatched configurations
        expect(find.byType(AlgorithmNodeWidget), findsOneWidget);
        expect(find.byType(PortWidget), findsAtLeastNWidgets(2)); // Should render the labels
        expect(tester.takeException(), isNull);
      });

      testWidgets('System handles null and empty data gracefully', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Stack(
                children: [
                  // Node with minimal data
                  Positioned(
                    left: 100,
                    top: 100,
                    child: AlgorithmNodeWidget(
                      algorithmName: '', // Empty name
                      slotNumber: 0, // Zero slot
                      position: const Offset(100, 100),
                      inputLabels: const [], // Empty lists
                      outputLabels: const [],
                    ),
                  ),
                  // Physical node with null callbacks
                  Positioned(
                    left: 300,
                    top: 100,
                    child: PhysicalInputNode(
                      position: const Offset(300, 100),
                      // All callbacks are null
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Should handle null/empty data without crashing
        expect(find.byType(AlgorithmNodeWidget), findsOneWidget);
        expect(find.byType(PhysicalInputNode), findsOneWidget);
        expect(find.byType(PortWidget), findsNWidgets(12)); // Only physical input ports
        expect(tester.takeException(), isNull);
      });

      testWidgets('Memory pressure scenarios handled correctly', (tester) async {
        // Simulate memory pressure by creating and disposing many widgets rapidly
        for (int iteration = 0; iteration < 5; iteration++) {
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: Column(
                  children: List.generate(10, (index) => AlgorithmNodeWidget(
                    algorithmName: 'Memory Test $iteration-$index',
                    slotNumber: index + 1,
                    position: Offset(0, index * 50.0),
                    inputLabels: ['Input'],
                    outputLabels: ['Output'],
                  )),
                ),
              ),
            ),
          );
          
          await tester.pumpAndSettle();
          
          // Verify widgets are created
          expect(find.byType(AlgorithmNodeWidget), findsNWidgets(10));
          expect(find.byType(PortWidget), findsNWidgets(20)); // 10 × 2 ports each
        }

        // Final cleanup - should dispose all widgets cleanly
        await tester.pumpWidget(const MaterialApp(home: Scaffold(body: SizedBox.shrink())));
        await tester.pumpAndSettle();
        
        expect(find.byType(AlgorithmNodeWidget), findsNothing);
        expect(find.byType(PortWidget), findsNothing);
        expect(tester.takeException(), isNull);
      });
    });

    group('User Experience Consistency', () {
      testWidgets('Drag behavior is consistent across all node types', (tester) async {
        final Map<String, List<String>> dragSequences = {};
        
        void recordDragSequence(String nodeType, String event) {
          dragSequences.putIfAbsent(nodeType, () => []).add(event);
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
                      algorithmName: 'UX Algorithm',
                      slotNumber: 1,
                      position: const Offset(100, 100),
                      onDragStart: () => recordDragSequence('algorithm', 'start'),
                      onDragEnd: () => recordDragSequence('algorithm', 'end'),
                    ),
                  ),
                  Positioned(
                    left: 350,
                    top: 150,
                    child: PhysicalInputNode(
                      position: const Offset(350, 150),
                      onNodeDragStart: () => recordDragSequence('physical_input', 'start'),
                      onNodeDragEnd: () => recordDragSequence('physical_input', 'end'),
                    ),
                  ),
                  Positioned(
                    left: 600,
                    top: 100,
                    child: PhysicalOutputNode(
                      position: const Offset(600, 100),
                      onNodeDragStart: () => recordDragSequence('physical_output', 'start'),
                      onNodeDragEnd: () => recordDragSequence('physical_output', 'end'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Drag each node type with identical gestures
        final dragOffset = const Offset(30, 30);
        
        await tester.dragFrom(tester.getCenter(find.byType(AlgorithmNodeWidget)), dragOffset);
        await tester.pumpAndSettle();
        
        await tester.dragFrom(tester.getCenter(find.byType(PhysicalInputNode)), dragOffset);
        await tester.pumpAndSettle();
        
        await tester.dragFrom(tester.getCenter(find.byType(PhysicalOutputNode)), dragOffset);
        await tester.pumpAndSettle();

        // All node types should have consistent drag event sequences
        expect(dragSequences['algorithm'], equals(['start', 'end']));
        expect(dragSequences['physical_input'], equals(['start', 'end']));
        expect(dragSequences['physical_output'], equals(['start', 'end']));
      });

      testWidgets('Visual feedback is consistent across interactions', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Stack(
                children: [
                  Positioned(
                    left: 100,
                    top: 100,
                    child: AlgorithmNodeWidget(
                      algorithmName: 'Visual Feedback Test',
                      slotNumber: 1,
                      position: const Offset(100, 100),
                      isSelected: false,
                      inputLabels: ['Input'],
                      outputLabels: ['Output'],
                    ),
                  ),
                  Positioned(
                    left: 350,
                    top: 150,
                    child: PhysicalInputNode(position: const Offset(350, 150)),
                  ),
                ],
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Initial state - all widgets should be rendered
        expect(find.byType(AlgorithmNodeWidget), findsOneWidget);
        expect(find.byType(PhysicalInputNode), findsOneWidget);

        // Tap interactions should provide consistent feedback
        await tester.tap(find.byType(AlgorithmNodeWidget));
        await tester.pumpAndSettle();
        expect(find.byType(AlgorithmNodeWidget), findsOneWidget); // Still present

        // Drag interactions should maintain visual consistency
        await tester.dragFrom(
          tester.getCenter(find.byType(PhysicalInputNode)),
          const Offset(25, 25),
        );
        await tester.pumpAndSettle();
        expect(find.byType(PhysicalInputNode), findsOneWidget); // Still present

        // Visual state should be stable after interactions
        expect(find.byType(PortWidget), findsNWidgets(14)); // 2 + 12 ports
      });

      testWidgets('Accessibility features work consistently', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Stack(
                children: [
                  Positioned(
                    left: 100,
                    top: 100,
                    child: PhysicalInputNode(position: const Offset(100, 100)),
                  ),
                  Positioned(
                    left: 350,
                    top: 150,
                    child: AlgorithmNodeWidget(
                      algorithmName: 'Accessible Algorithm',
                      slotNumber: 1,
                      position: const Offset(350, 150),
                      inputLabels: ['Accessible Input'],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify semantic labels are present
        expect(find.bySemanticsLabel('Physical Inputs'), findsOneWidget);
        
        // All interactive elements should be accessible
        final semantics = tester.getSemantics(find.byType(PhysicalInputNode));
        expect(semantics.hasFlag(SemanticsFlag.hasEnabledState), isTrue);
        
        // Algorithm nodes should maintain accessibility
        expect(find.byType(AlgorithmNodeWidget), findsOneWidget);
        expect(find.text('#1 Accessible Algorithm'), findsOneWidget);
      });
    });

    group('Real-World Usage Scenarios', () {
      testWidgets('Complex multi-stage audio processing chain', (tester) async {
        final Map<String, Offset> finalPortPositions = {};

        void trackFinalPosition(String portId, Offset pos, [bool? isInput]) {
          finalPortPositions[portId] = pos;
        }

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Stack(
                children: [
                  // Input stage
                  Positioned(
                    left: 50,
                    top: 150,
                    child: PhysicalInputNode(
                      position: const Offset(50, 150),
                      onPortPositionResolved: (port, pos) => trackFinalPosition(port.id, pos),
                    ),
                  ),
                  // Pre-processing
                  Positioned(
                    left: 200,
                    top: 100,
                    child: AlgorithmNodeWidget(
                      algorithmName: 'High-pass Filter',
                      slotNumber: 1,
                      position: const Offset(200, 100),
                      inputLabels: ['Audio In', 'Cutoff'],
                      outputLabels: ['Filtered'],
                      inputPortIds: ['hpf_in', 'hpf_cutoff'],
                      outputPortIds: ['hpf_out'],
                      onPortPositionResolved: trackFinalPosition,
                    ),
                  ),
                  // Main processing
                  Positioned(
                    left: 350,
                    top: 130,
                    child: AlgorithmNodeWidget(
                      algorithmName: 'Compressor',
                      slotNumber: 2,
                      position: const Offset(350, 130),
                      inputLabels: ['Audio', 'Threshold', 'Ratio'],
                      outputLabels: ['Compressed'],
                      inputPortIds: ['comp_audio', 'comp_thresh', 'comp_ratio'],
                      outputPortIds: ['comp_out'],
                      onPortPositionResolved: trackFinalPosition,
                    ),
                  ),
                  // Effects processing
                  Positioned(
                    left: 500,
                    top: 100,
                    child: AlgorithmNodeWidget(
                      algorithmName: 'Reverb',
                      slotNumber: 3,
                      position: const Offset(500, 100),
                      inputLabels: ['Dry In', 'Room Size'],
                      outputLabels: ['Wet Out', 'Dry Out'],
                      inputPortIds: ['rev_dry', 'rev_room'],
                      outputPortIds: ['rev_wet', 'rev_dry_out'],
                      onPortPositionResolved: trackFinalPosition,
                    ),
                  ),
                  // Output stage
                  Positioned(
                    left: 650,
                    top: 120,
                    child: AlgorithmNodeWidget(
                      algorithmName: 'Output Mixer',
                      slotNumber: 4,
                      position: const Offset(650, 120),
                      inputLabels: ['Wet', 'Dry', 'Level'],
                      outputLabels: ['Mix Out'],
                      inputPortIds: ['mix_wet', 'mix_dry', 'mix_level'],
                      outputPortIds: ['mix_out'],
                      onPortPositionResolved: trackFinalPosition,
                    ),
                  ),
                  // Final output
                  Positioned(
                    left: 800,
                    top: 140,
                    child: PhysicalOutputNode(
                      position: const Offset(800, 140),
                      onPortPositionResolved: (port, pos) => trackFinalPosition(port.id, pos),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        await tester.pump(); // Allow port position callbacks

        // Complex audio chain should be fully functional
        expect(find.byType(PhysicalInputNode), findsOneWidget);
        expect(find.byType(AlgorithmNodeWidget), findsNWidgets(4));
        expect(find.byType(PhysicalOutputNode), findsOneWidget);

        // All ports should be positioned for connection visualization
        expect(finalPortPositions.length, greaterThanOrEqualTo(30)); // Minimum expected ports

        // Should have logical left-to-right signal flow
        final physicalInX = finalPortPositions['hw_in_1']?.dx ?? 0;
        final mixOutX = finalPortPositions['mix_out']?.dx ?? 0;
        final physicalOutX = finalPortPositions['hw_out_1']?.dx ?? 0;

        expect(physicalInX, lessThan(mixOutX));
        expect(mixOutX, lessThan(physicalOutX));

        // System should remain stable with complex configuration
        expect(tester.takeException(), isNull);
      });

      testWidgets('Interactive modulation and control routing', (tester) async {
        final List<String> interactionLog = [];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Stack(
                children: [
                  // Control sources
                  Positioned(
                    left: 50,
                    top: 80,
                    child: AlgorithmNodeWidget(
                      algorithmName: 'LFO 1',
                      slotNumber: 1,
                      position: const Offset(50, 80),
                      outputLabels: ['Triangle', 'Square'],
                      onTap: () => interactionLog.add('lfo1_tap'),
                      onDragEnd: () => interactionLog.add('lfo1_move'),
                    ),
                  ),
                  Positioned(
                    left: 50,
                    top: 200,
                    child: AlgorithmNodeWidget(
                      algorithmName: 'LFO 2',
                      slotNumber: 2,
                      position: const Offset(50, 200),
                      outputLabels: ['Sine', 'Ramp'],
                      onTap: () => interactionLog.add('lfo2_tap'),
                      onDragEnd: () => interactionLog.add('lfo2_move'),
                    ),
                  ),
                  // Modulation targets
                  Positioned(
                    left: 300,
                    top: 100,
                    child: AlgorithmNodeWidget(
                      algorithmName: 'VCF',
                      slotNumber: 3,
                      position: const Offset(300, 100),
                      inputLabels: ['Audio', 'Cutoff CV', 'Res CV'],
                      outputLabels: ['Filtered'],
                      onTap: () => interactionLog.add('vcf_tap'),
                      onDragEnd: () => interactionLog.add('vcf_move'),
                    ),
                  ),
                  Positioned(
                    left: 300,
                    top: 220,
                    child: AlgorithmNodeWidget(
                      algorithmName: 'VCA',
                      slotNumber: 4,
                      position: const Offset(300, 220),
                      inputLabels: ['Audio', 'Level CV'],
                      outputLabels: ['Amplified'],
                      onTap: () => interactionLog.add('vca_tap'),
                      onDragEnd: () => interactionLog.add('vca_move'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // User workflow: Select and position modulation sources and targets
        await tester.tap(find.text('#1 LFO 1'));
        await tester.pumpAndSettle();

        await tester.dragFrom(
          tester.getCenter(find.text('#1 LFO 1')),
          const Offset(20, 10),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('#3 VCF'));
        await tester.pumpAndSettle();

        await tester.dragFrom(
          tester.getCenter(find.text('#4 VCA')),
          const Offset(-15, 20),
        );
        await tester.pumpAndSettle();

        // Interactive workflow should complete successfully
        expect(interactionLog, contains('lfo1_move'));
        expect(interactionLog, contains('vcf_tap'));
        expect(interactionLog.length, greaterThanOrEqualTo(3));

        // All modulation components should remain functional
        expect(find.byType(AlgorithmNodeWidget), findsNWidgets(4));
        expect(find.byType(PortWidget), findsNWidgets(12)); // Total ports from all algorithms
      });

      testWidgets('Live performance scenario with frequent changes', (tester) async {
        int performanceActionCount = 0;
        final Set<String> manipulatedNodes = {};

        Widget buildPerformanceScene(int sceneVersion) {
          return MaterialApp(
            home: Scaffold(
              body: Stack(
                children: [
                  // Dynamic scene that changes based on version
                  if (sceneVersion >= 1)
                    Positioned(
                      left: 100,
                      top: 100,
                      child: AlgorithmNodeWidget(
                        algorithmName: 'Live Source $sceneVersion',
                        slotNumber: 1,
                        position: const Offset(100, 100),
                        outputLabels: ['Live Out'],
                        onPositionChanged: (pos) {
                          performanceActionCount++;
                          manipulatedNodes.add('source');
                        },
                      ),
                    ),
                  if (sceneVersion >= 2)
                    Positioned(
                      left: 300,
                      top: 120,
                      child: AlgorithmNodeWidget(
                        algorithmName: 'Live Effect $sceneVersion',
                        slotNumber: 2,
                        position: const Offset(300, 120),
                        inputLabels: ['Effect In'],
                        outputLabels: ['Effect Out'],
                        onPositionChanged: (pos) {
                          performanceActionCount++;
                          manipulatedNodes.add('effect');
                        },
                      ),
                    ),
                  if (sceneVersion >= 3)
                    Positioned(
                      left: 500,
                      top: 100,
                      child: PhysicalOutputNode(
                        position: const Offset(500, 100),
                        onPositionChanged: (pos) {
                          performanceActionCount++;
                          manipulatedNodes.add('output');
                        },
                      ),
                    ),
                ],
              ),
            ),
          );
        }

        // Simulate live performance with rapid scene changes and interactions
        for (int scene = 1; scene <= 3; scene++) {
          await tester.pumpWidget(buildPerformanceScene(scene));
          await tester.pumpAndSettle();

          // Perform quick manipulations
          if (scene >= 1) {
            await tester.dragFrom(
              tester.getCenter(find.byType(AlgorithmNodeWidget).first),
              Offset(scene * 10.0, scene * 5.0),
            );
            await tester.pump(const Duration(milliseconds: 50)); // Quick succession
          }

          if (scene >= 3) {
            await tester.dragFrom(
              tester.getCenter(find.byType(PhysicalOutputNode)),
              Offset(-scene * 5.0, scene * 8.0),
            );
            await tester.pump(const Duration(milliseconds: 50));
          }
        }

        await tester.pumpAndSettle();

        // Performance scenario should handle rapid changes smoothly
        expect(performanceActionCount, greaterThan(0));
        expect(manipulatedNodes.isNotEmpty, isTrue);
        
        // Final state should be stable
        expect(find.byType(AlgorithmNodeWidget), findsNWidgets(2));
        expect(find.byType(PhysicalOutputNode), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    });

    group('System Robustness', () {
      testWidgets('System maintains stability under stress conditions', (tester) async {
        // Stress test: rapid widget creation/destruction
        for (int cycle = 0; cycle < 3; cycle++) {
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: Stack(
                  children: List.generate(5, (index) => Positioned(
                    left: index * 150.0,
                    top: 100 + cycle * 50.0,
                    child: AlgorithmNodeWidget(
                      algorithmName: 'Stress ${cycle}_$index',
                      slotNumber: index + 1,
                      position: Offset(index * 150.0, 100 + cycle * 50.0),
                      inputLabels: ['In'],
                      outputLabels: ['Out'],
                    ),
                  )),
                ),
              ),
            ),
          );
          
          await tester.pumpAndSettle();
          
          // Verify creation succeeded
          expect(find.byType(AlgorithmNodeWidget), findsNWidgets(5));
          expect(find.byType(PortWidget), findsNWidgets(10));
        }

        // System should remain stable throughout stress test
        expect(tester.takeException(), isNull);
        
        // Clean shutdown
        await tester.pumpWidget(const MaterialApp(home: Scaffold(body: SizedBox.shrink())));
        await tester.pumpAndSettle();
        expect(find.byType(AlgorithmNodeWidget), findsNothing);
      });

      testWidgets('Long-running system maintains performance', (tester) async {
        final performanceTimes = <Duration>[];
        final stopwatch = Stopwatch();

        Widget buildLongRunningScene(int iteration) {
          return MaterialApp(
            home: Scaffold(
              body: Stack(
                children: [
                  Positioned(
                    left: 100 + (iteration % 5) * 10.0,
                    top: 100 + (iteration % 3) * 15.0,
                    child: AlgorithmNodeWidget(
                      algorithmName: 'Long Running $iteration',
                      slotNumber: iteration + 1,
                      position: Offset(
                        100 + (iteration % 5) * 10.0,
                        100 + (iteration % 3) * 15.0,
                      ),
                      inputLabels: ['Persistent Input'],
                      onPortPositionResolved: (portId, pos, isInput) {
                        if (stopwatch.isRunning) {
                          stopwatch.stop();
                          performanceTimes.add(Duration(microseconds: stopwatch.elapsedMicroseconds));
                          stopwatch.reset();
                        }
                      },
                    ),
                  ),
                  Positioned(
                    left: 300,
                    top: 120,
                    child: PhysicalInputNode(position: const Offset(300, 120)),
                  ),
                ],
              ),
            ),
          );
        }

        // Long-running simulation
        for (int i = 0; i < 10; i++) {
          stopwatch.start();
          await tester.pumpWidget(buildLongRunningScene(i));
          await tester.pumpAndSettle();
          await tester.pump();
          
          // Small interaction each iteration
          if (i % 3 == 0) {
            await tester.dragFrom(
              tester.getCenter(find.byType(AlgorithmNodeWidget)),
              Offset(i * 2.0, i * 1.5),
            );
            await tester.pumpAndSettle();
          }
        }

        // Performance should remain consistent over time
        if (performanceTimes.isNotEmpty) {
          final avgTime = performanceTimes
              .map((d) => d.inMicroseconds)
              .reduce((a, b) => a + b) / performanceTimes.length;
          
          expect(avgTime, lessThan(10000), // 10ms average
              reason: 'Long-running performance should remain consistent');
        }

        // System should still be responsive
        expect(find.byType(AlgorithmNodeWidget), findsOneWidget);
        expect(find.byType(PhysicalInputNode), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    });
  });
}

// Mock implementations for system testing
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

  @override
  Future<void> onRemoveAlgorithm(int algorithmIndex) async {
    // Mock implementation
  }
}