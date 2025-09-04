import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nt_helper/ui/widgets/routing/algorithm_node_widget.dart';
import 'package:nt_helper/ui/widgets/routing/physical_input_node.dart';
import 'package:nt_helper/ui/widgets/routing/physical_output_node.dart';
import 'package:nt_helper/ui/widgets/routing/routing_editor_widget.dart';
import 'package:nt_helper/ui/widgets/routing/port_widget.dart';
import 'package:nt_helper/cubit/routing_editor_cubit.dart';
import 'package:nt_helper/cubit/routing_editor_state.dart';
import 'package:nt_helper/cubit/disting_cubit.dart';
import 'package:nt_helper/core/routing/models/port.dart';
import 'package:nt_helper/core/routing/models/connection.dart';
import 'package:nt_helper/core/routing/models/algorithm_routing_metadata.dart';

/// Tests for cross-node-type connections between algorithm nodes and physical I/O nodes.
/// 
/// Validates that connections work correctly between:
/// - Physical inputs → Algorithm inputs
/// - Algorithm outputs → Physical outputs  
/// - Algorithm outputs → Algorithm inputs (via virtual buses)
/// - Port compatibility across different node types
/// - Connection visualization and interaction
void main() {
  group('Cross-Node Connection Tests', () {
    
    group('Physical Input to Algorithm Node Connections', () {
      testWidgets('Physical input can connect to algorithm input', (tester) async {
        final Map<String, Offset> allPortPositions = {};
        bool portTapped = false;
        
        void trackPortPosition(String portId, Offset position, bool isInput) {
          allPortPositions[portId] = position;
        }
        
        void trackPhysicalPortPosition(Port port, Offset position) {
          allPortPositions[port.id] = position;
        }

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Stack(
                children: [
                  // Physical input node (acts as output source)
                  Positioned(
                    left: 50,
                    top: 100,
                    child: PhysicalInputNode(
                      position: const Offset(50, 100),
                      onPortPositionResolved: trackPhysicalPortPosition,
                      onPortTapped: (port) => portTapped = true,
                    ),
                  ),
                  // Algorithm node (receives input from physical)
                  Positioned(
                    left: 300,
                    top: 150,
                    child: AlgorithmNodeWidget(
                      algorithmName: 'VCA',
                      slotNumber: 1,
                      position: const Offset(300, 150),
                      inputLabels: ['Audio In', 'CV In'],
                      inputPortIds: ['vca_audio', 'vca_cv'],
                      onPortPositionResolved: trackPortPosition,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        await tester.pump(); // Allow port position callbacks

        // Verify both node types are present
        expect(find.byType(PhysicalInputNode), findsOneWidget);
        expect(find.byType(AlgorithmNodeWidget), findsOneWidget);

        // Verify port positions were resolved
        expect(allPortPositions.isNotEmpty, isTrue);
        
        // Should have physical input ports (hw_in_1 through hw_in_12)
        expect(allPortPositions.keys.where((id) => id.startsWith('hw_in_')), 
               hasLength(12));
        
        // Should have algorithm input ports
        expect(allPortPositions.containsKey('vca_audio'), isTrue);
        expect(allPortPositions.containsKey('vca_cv'), isTrue);

        // Test port interaction
        final physicalPorts = find.byType(PortWidget);
        expect(physicalPorts, findsAtLeastNWidgets(14)); // 12 physical + 2 algorithm

        // Tap a physical input port
        final firstPhysicalPort = physicalPorts.first;
        await tester.tap(firstPhysicalPort);
        await tester.pumpAndSettle();

        expect(portTapped, isTrue);
      });

      testWidgets('Port positions are correctly spaced between node types', (tester) async {
        final Map<String, Offset> physicalPortPositions = {};
        final Map<String, Offset> algorithmPortPositions = {};

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
                      onPortPositionResolved: (port, position) {
                        physicalPortPositions[port.id] = position;
                      },
                    ),
                  ),
                  Positioned(
                    left: 400,
                    top: 120,
                    child: AlgorithmNodeWidget(
                      algorithmName: 'Test Algorithm',
                      slotNumber: 1,
                      position: const Offset(400, 120),
                      inputLabels: ['Input 1', 'Input 2'],
                      inputPortIds: ['algo_in1', 'algo_in2'],
                      onPortPositionResolved: (portId, position, isInput) {
                        algorithmPortPositions[portId] = position;
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        await tester.pump();

        // Verify reasonable spacing between node types
        expect(physicalPortPositions.isNotEmpty, isTrue);
        expect(algorithmPortPositions.isNotEmpty, isTrue);

        // Physical ports should be to the left of algorithm ports
        final avgPhysicalX = physicalPortPositions.values
            .map((pos) => pos.dx)
            .reduce((a, b) => a + b) / physicalPortPositions.length;
        final avgAlgorithmX = algorithmPortPositions.values
            .map((pos) => pos.dx)
            .reduce((a, b) => a + b) / algorithmPortPositions.length;

        expect(avgPhysicalX, lessThan(avgAlgorithmX),
            reason: 'Physical inputs should be positioned left of algorithm inputs');
      });
    });

    group('Algorithm to Physical Output Connections', () {
      testWidgets('Algorithm output can connect to physical output', (tester) async {
        final Map<String, Offset> allPortPositions = {};

        void trackAlgorithmPort(String portId, Offset position, bool isInput) {
          allPortPositions[portId] = position;
        }
        
        void trackPhysicalPort(Port port, Offset position) {
          allPortPositions[port.id] = position;
        }

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Stack(
                children: [
                  // Algorithm node (output source)
                  Positioned(
                    left: 100,
                    top: 150,
                    child: AlgorithmNodeWidget(
                      algorithmName: 'Oscillator',
                      slotNumber: 2,
                      position: const Offset(100, 150),
                      outputLabels: ['Audio Out', 'CV Out'],
                      outputPortIds: ['osc_audio', 'osc_cv'],
                      onPortPositionResolved: trackAlgorithmPort,
                    ),
                  ),
                  // Physical output node (receives output from algorithm)
                  Positioned(
                    left: 400,
                    top: 100,
                    child: PhysicalOutputNode(
                      position: const Offset(400, 100),
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

        // Verify both node types are present
        expect(find.byType(AlgorithmNodeWidget), findsOneWidget);
        expect(find.byType(PhysicalOutputNode), findsOneWidget);

        // Verify port positions were resolved
        expect(allPortPositions.isNotEmpty, isTrue);
        
        // Should have algorithm output ports
        expect(allPortPositions.containsKey('osc_audio'), isTrue);
        expect(allPortPositions.containsKey('osc_cv'), isTrue);
        
        // Should have physical output ports (hw_out_1 through hw_out_8)
        expect(allPortPositions.keys.where((id) => id.startsWith('hw_out_')), 
               hasLength(8));

        // Algorithm outputs should be to the left of physical outputs
        final algoOutputX = allPortPositions['osc_audio']!.dx;
        final physicalOutputs = allPortPositions.entries
            .where((entry) => entry.key.startsWith('hw_out_'))
            .toList();
        final avgPhysicalOutputX = physicalOutputs
            .map((entry) => entry.value.dx)
            .reduce((a, b) => a + b) / physicalOutputs.length;

        expect(algoOutputX, lessThan(avgPhysicalOutputX),
            reason: 'Algorithm outputs should be left of physical outputs');
      });

      testWidgets('Port styles are consistent across node types', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Stack(
                children: [
                  Positioned(
                    left: 50,
                    top: 50,
                    child: AlgorithmNodeWidget(
                      algorithmName: 'Style Test',
                      slotNumber: 1,
                      position: const Offset(50, 50),
                      inputLabels: ['Input'],
                      outputLabels: ['Output'],
                    ),
                  ),
                  Positioned(
                    left: 300,
                    top: 50,
                    child: PhysicalInputNode(
                      position: const Offset(300, 50),
                    ),
                  ),
                  Positioned(
                    left: 500,
                    top: 50,
                    child: PhysicalOutputNode(
                      position: const Offset(500, 50),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        final allPortWidgets = tester.widgetList<PortWidget>(find.byType(PortWidget)).toList();
        expect(allPortWidgets, hasLength(22)); // 2 algo + 12 input + 8 output

        // Algorithm ports should use dot style
        final algorithmPorts = allPortWidgets.take(2).toList();
        for (final port in algorithmPorts) {
          expect(port.style, equals(PortStyle.dot));
        }

        // Physical ports should use jack style
        final physicalPorts = allPortWidgets.skip(2).toList();
        for (final port in physicalPorts) {
          expect(port.style, equals(PortStyle.jack));
        }
      });
    });

    group('Algorithm to Algorithm Connections', () {
      testWidgets('Algorithm nodes can connect to each other', (tester) async {
        final Map<String, Offset> portPositions = {};

        void trackPortPosition(String portId, Offset position, bool isInput) {
          portPositions[portId] = position;
        }

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Stack(
                children: [
                  // Source algorithm
                  Positioned(
                    left: 100,
                    top: 100,
                    child: AlgorithmNodeWidget(
                      algorithmName: 'LFO',
                      slotNumber: 1,
                      position: const Offset(100, 100),
                      outputLabels: ['Triangle', 'Square'],
                      outputPortIds: ['lfo_tri', 'lfo_sqr'],
                      onPortPositionResolved: trackPortPosition,
                    ),
                  ),
                  // Destination algorithm
                  Positioned(
                    left: 350,
                    top: 130,
                    child: AlgorithmNodeWidget(
                      algorithmName: 'Filter',
                      slotNumber: 2,
                      position: const Offset(350, 130),
                      inputLabels: ['Audio In', 'Cutoff CV'],
                      inputPortIds: ['filt_audio', 'filt_cv'],
                      onPortPositionResolved: trackPortPosition,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        await tester.pump();

        // Verify both algorithm nodes are present
        expect(find.byType(AlgorithmNodeWidget), findsNWidgets(2));

        // Verify all expected ports are resolved
        expect(portPositions.containsKey('lfo_tri'), isTrue);
        expect(portPositions.containsKey('lfo_sqr'), isTrue);
        expect(portPositions.containsKey('filt_audio'), isTrue);
        expect(portPositions.containsKey('filt_cv'), isTrue);

        // LFO outputs should be to the left of Filter inputs
        final lfoOutputX = portPositions['lfo_tri']!.dx;
        final filterInputX = portPositions['filt_audio']!.dx;
        expect(lfoOutputX, lessThan(filterInputX),
            reason: 'LFO outputs should be left of Filter inputs for logical connection flow');

        // Verify port counts
        expect(find.byType(PortWidget), findsNWidgets(4)); // 2 outputs + 2 inputs
      });

      testWidgets('Complex multi-algorithm chain positioning', (tester) async {
        final Map<String, Offset> allPortPositions = {};

        void trackPosition(String portId, Offset position, bool isInput) {
          allPortPositions[portId] = position;
        }

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Stack(
                children: [
                  // Chain: LFO → Filter → VCA
                  Positioned(
                    left: 50,
                    top: 100,
                    child: AlgorithmNodeWidget(
                      algorithmName: 'LFO',
                      slotNumber: 1,
                      position: const Offset(50, 100),
                      outputLabels: ['CV Out'],
                      outputPortIds: ['lfo_out'],
                      onPortPositionResolved: trackPosition,
                    ),
                  ),
                  Positioned(
                    left: 250,
                    top: 120,
                    child: AlgorithmNodeWidget(
                      algorithmName: 'Filter',
                      slotNumber: 2,
                      position: const Offset(250, 120),
                      inputLabels: ['Cutoff CV'],
                      outputLabels: ['Audio Out'],
                      inputPortIds: ['filt_cv'],
                      outputPortIds: ['filt_out'],
                      onPortPositionResolved: trackPosition,
                    ),
                  ),
                  Positioned(
                    left: 450,
                    top: 140,
                    child: AlgorithmNodeWidget(
                      algorithmName: 'VCA',
                      slotNumber: 3,
                      position: const Offset(450, 140),
                      inputLabels: ['Audio In'],
                      outputLabels: ['Audio Out'],
                      inputPortIds: ['vca_in'],
                      outputPortIds: ['vca_out'],
                      onPortPositionResolved: trackPosition,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        await tester.pump();

        // Verify logical left-to-right flow
        final lfoX = allPortPositions['lfo_out']!.dx;
        final filterInX = allPortPositions['filt_cv']!.dx;
        final filterOutX = allPortPositions['filt_out']!.dx;
        final vcaInX = allPortPositions['vca_in']!.dx;
        
        expect(lfoX, lessThan(filterInX));
        expect(filterOutX, lessThan(vcaInX));
        
        // Verify all three algorithms are present
        expect(find.byType(AlgorithmNodeWidget), findsNWidgets(3));
        expect(find.byType(PortWidget), findsNWidgets(5)); // 1+1+1 inputs, 1+1+1 outputs
      });
    });

    group('Mixed Connection Scenarios', () {
      testWidgets('Full signal chain: Physical Input → Algorithm → Physical Output', (tester) async {
        final Map<String, Offset> allPortPositions = {};

        void trackAlgorithmPort(String portId, Offset position, bool isInput) {
          allPortPositions[portId] = position;
        }
        
        void trackPhysicalPort(Port port, Offset position) {
          allPortPositions[port.id] = position;
        }

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Stack(
                children: [
                  // Input chain: Physical Input → Algorithm → Physical Output
                  Positioned(
                    left: 50,
                    top: 150,
                    child: PhysicalInputNode(
                      position: const Offset(50, 150),
                      onPortPositionResolved: trackPhysicalPort,
                    ),
                  ),
                  Positioned(
                    left: 280,
                    top: 180,
                    child: AlgorithmNodeWidget(
                      algorithmName: 'Processor',
                      slotNumber: 1,
                      position: const Offset(280, 180),
                      inputLabels: ['Audio In'],
                      outputLabels: ['Audio Out'],
                      inputPortIds: ['proc_in'],
                      outputPortIds: ['proc_out'],
                      onPortPositionResolved: trackAlgorithmPort,
                    ),
                  ),
                  Positioned(
                    left: 500,
                    top: 150,
                    child: PhysicalOutputNode(
                      position: const Offset(500, 150),
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

        // Verify complete signal chain is present
        expect(find.byType(PhysicalInputNode), findsOneWidget);
        expect(find.byType(AlgorithmNodeWidget), findsOneWidget);
        expect(find.byType(PhysicalOutputNode), findsOneWidget);

        // Verify logical positioning: Physical Input < Algorithm < Physical Output
        final physicalInputs = allPortPositions.entries
            .where((entry) => entry.key.startsWith('hw_in_'))
            .toList();
        final physicalOutputs = allPortPositions.entries
            .where((entry) => entry.key.startsWith('hw_out_'))
            .toList();

        final avgInputX = physicalInputs.isNotEmpty
            ? physicalInputs.map((e) => e.value.dx).reduce((a, b) => a + b) / physicalInputs.length
            : 0.0;
        final avgOutputX = physicalOutputs.isNotEmpty
            ? physicalOutputs.map((e) => e.value.dx).reduce((a, b) => a + b) / physicalOutputs.length
            : 0.0;
        final algorithmInX = allPortPositions['proc_in']?.dx ?? 0.0;
        final algorithmOutX = allPortPositions['proc_out']?.dx ?? 0.0;

        expect(avgInputX, lessThan(algorithmInX));
        expect(algorithmOutX, lessThan(avgOutputX));

        // Total port count: 12 physical inputs + 2 algorithm + 8 physical outputs
        expect(find.byType(PortWidget), findsNWidgets(22));
      });

      testWidgets('Complex routing with multiple algorithms and physical I/O', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Stack(
                children: [
                  // Physical inputs
                  Positioned(
                    left: 50,
                    top: 100,
                    child: PhysicalInputNode(position: const Offset(50, 100)),
                  ),
                  // Algorithm chain
                  Positioned(
                    left: 280,
                    top: 80,
                    child: AlgorithmNodeWidget(
                      algorithmName: 'LFO',
                      slotNumber: 1,
                      position: const Offset(280, 80),
                      outputLabels: ['CV'],
                      outputPortIds: ['lfo_cv'],
                    ),
                  ),
                  Positioned(
                    left: 280,
                    top: 180,
                    child: AlgorithmNodeWidget(
                      algorithmName: 'VCA',
                      slotNumber: 2,
                      position: const Offset(280, 180),
                      inputLabels: ['Audio', 'CV'],
                      outputLabels: ['Audio'],
                      inputPortIds: ['vca_audio', 'vca_cv'],
                      outputPortIds: ['vca_out'],
                    ),
                  ),
                  Positioned(
                    left: 450,
                    top: 140,
                    child: AlgorithmNodeWidget(
                      algorithmName: 'Reverb',
                      slotNumber: 3,
                      position: const Offset(450, 140),
                      inputLabels: ['Audio'],
                      outputLabels: ['Wet', 'Dry'],
                      inputPortIds: ['rev_in'],
                      outputPortIds: ['rev_wet', 'rev_dry'],
                    ),
                  ),
                  // Physical outputs
                  Positioned(
                    left: 650,
                    top: 100,
                    child: PhysicalOutputNode(position: const Offset(650, 100)),
                  ),
                ],
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify complete complex setup
        expect(find.byType(PhysicalInputNode), findsOneWidget);
        expect(find.byType(AlgorithmNodeWidget), findsNWidgets(3));
        expect(find.byType(PhysicalOutputNode), findsOneWidget);

        // Total expected ports: 12 + 1 + 3 + 3 + 8 = 27
        expect(find.byType(PortWidget), findsNWidgets(27));

        // Verify all nodes render without errors
        expect(find.text('#1 LFO'), findsOneWidget);
        expect(find.text('#2 VCA'), findsOneWidget);
        expect(find.text('#3 Reverb'), findsOneWidget);
      });
    });

    group('Port Compatibility and Interaction', () {
      testWidgets('Different port styles can coexist', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Row(
                children: [
                  // Dot-style ports (algorithm)
                  AlgorithmNodeWidget(
                    algorithmName: 'Dot Style',
                    slotNumber: 1,
                    position: const Offset(0, 0),
                    inputLabels: ['Dot Input'],
                    outputLabels: ['Dot Output'],
                  ),
                  const SizedBox(width: 50),
                  // Jack-style ports (physical)
                  PhysicalInputNode(position: const Offset(200, 0)),
                ],
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        final portWidgets = tester.widgetList<PortWidget>(find.byType(PortWidget)).toList();
        
        // Should have mix of dot and jack styles
        final dotPorts = portWidgets.where((w) => w.style == PortStyle.dot).toList();
        final jackPorts = portWidgets.where((w) => w.style == PortStyle.jack).toList();

        expect(dotPorts, hasLength(2)); // Algorithm ports
        expect(jackPorts, hasLength(12)); // Physical input ports
        expect(dotPorts.length + jackPorts.length, equals(portWidgets.length));
      });

      testWidgets('Port tap interactions work across node types', (tester) async {
        final List<String> tappedPorts = [];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Stack(
                children: [
                  Positioned(
                    left: 100,
                    top: 100,
                    child: AlgorithmNodeWidget(
                      algorithmName: 'Tappable',
                      slotNumber: 1,
                      position: const Offset(100, 100),
                      inputLabels: ['Tap Input'],
                      inputPortIds: ['tap_in'],
                    ),
                  ),
                  Positioned(
                    left: 300,
                    top: 100,
                    child: PhysicalInputNode(
                      position: const Offset(300, 100),
                      onPortTapped: (port) => tappedPorts.add(port.id),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Tap ports from both node types
        final allPorts = find.byType(PortWidget);
        expect(allPorts, findsAtLeastNWidgets(13)); // 1 algo + 12 physical

        // Tap the first physical port
        final physicalPorts = tester.widgetList<PortWidget>(allPorts)
            .where((w) => w.style == PortStyle.jack)
            .toList();
        
        if (physicalPorts.isNotEmpty) {
          await tester.tap(find.byWidget(physicalPorts.first));
          await tester.pumpAndSettle();
          
          expect(tappedPorts, hasLength(1));
          expect(tappedPorts.first, startsWith('hw_in_'));
        }
      });
    });

    group('Connection Visualization Compatibility', () {
      testWidgets('Port positions enable connection line drawing', (tester) async {
        final Map<String, Offset> sourcePositions = {};
        final Map<String, Offset> targetPositions = {};

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Stack(
                children: [
                  // Source: Algorithm output
                  Positioned(
                    left: 100,
                    top: 150,
                    child: AlgorithmNodeWidget(
                      algorithmName: 'Source',
                      slotNumber: 1,
                      position: const Offset(100, 150),
                      outputLabels: ['Out'],
                      outputPortIds: ['source_out'],
                      onPortPositionResolved: (portId, pos, isInput) {
                        sourcePositions[portId] = pos;
                      },
                    ),
                  ),
                  // Target: Physical output
                  Positioned(
                    left: 400,
                    top: 100,
                    child: PhysicalOutputNode(
                      position: const Offset(400, 100),
                      onPortPositionResolved: (port, pos) {
                        targetPositions[port.id] = pos;
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        await tester.pump();

        // Verify positions are available for connection drawing
        expect(sourcePositions.isNotEmpty, isTrue);
        expect(targetPositions.isNotEmpty, isTrue);

        final sourcePos = sourcePositions['source_out'];
        final targetPos = targetPositions['hw_out_1']; // First physical output

        expect(sourcePos, isNotNull);
        expect(targetPos, isNotNull);

        // Positions should be reasonable for drawing connections
        expect(sourcePos!.dx, greaterThan(0));
        expect(sourcePos.dy, greaterThan(0));
        expect(targetPos!.dx, greaterThan(sourcePos.dx)); // Target should be to the right
      });

      testWidgets('Port positions update correctly when nodes move', (tester) async {
        final List<Offset> algorithmPortHistory = [];
        final List<Offset> physicalPortHistory = [];

        Offset algorithmPosition = const Offset(150, 150);

        Widget buildMovableScene() {
          return MaterialApp(
            home: Scaffold(
              body: Stack(
                children: [
                  Positioned(
                    left: algorithmPosition.dx,
                    top: algorithmPosition.dy,
                    child: AlgorithmNodeWidget(
                      algorithmName: 'Movable',
                      slotNumber: 1,
                      position: algorithmPosition,
                      outputLabels: ['Out'],
                      outputPortIds: ['mov_out'],
                      onPortPositionResolved: (portId, pos, isInput) {
                        if (portId == 'mov_out') {
                          algorithmPortHistory.add(pos);
                        }
                      },
                    ),
                  ),
                  Positioned(
                    left: 400,
                    top: 100,
                    child: PhysicalOutputNode(
                      position: const Offset(400, 100),
                      onPortPositionResolved: (port, pos) {
                        if (port.id == 'hw_out_1') {
                          physicalPortHistory.add(pos);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // Initial position
        await tester.pumpWidget(buildMovableScene());
        await tester.pumpAndSettle();
        await tester.pump();

        // Move algorithm node
        algorithmPosition = const Offset(200, 200);
        await tester.pumpWidget(buildMovableScene());
        await tester.pumpAndSettle();
        await tester.pump();

        // Algorithm port should have moved, physical port should stay same
        expect(algorithmPortHistory.length, greaterThanOrEqualTo(2));
        expect(physicalPortHistory.length, greaterThanOrEqualTo(1));

        if (algorithmPortHistory.length >= 2) {
          final initialAlgoPos = algorithmPortHistory.first;
          final movedAlgoPos = algorithmPortHistory.last;
          expect(movedAlgoPos, isNot(equals(initialAlgoPos)));
        }
      });
    });
  });
}