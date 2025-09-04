import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/ui/widgets/routing/algorithm_node_widget.dart';
import 'package:nt_helper/ui/widgets/routing/physical_input_node.dart';
import 'package:nt_helper/ui/widgets/routing/physical_output_node.dart';
import 'package:nt_helper/ui/widgets/routing/port_widget.dart';

/// Integration validation test for Task 3 - Universal Port Widget System
/// 
/// This test validates that the universal port widget architecture works
/// correctly across all node types and provides the functionality required
/// for the Physical I/O Node Redesign specification.
void main() {
  group('Task 3 Integration Validation', () {
    
    testWidgets('Universal port widget works across all node types', (tester) async {
      final Map<String, Offset> allPortPositions = {};
      bool algorithmPortCallbackFired = false;
      bool physicalPortCallbackFired = false;

      void trackAlgorithmPort(String portId, Offset position, bool isInput) {
        allPortPositions['algo_$portId'] = position;
        algorithmPortCallbackFired = true;
      }

      void trackPhysicalPort(port, Offset position) {
        allPortPositions['physical_${port.id}'] = position;
        physicalPortCallbackFired = true;
      }

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                // Algorithm node using universal port widget
                Positioned(
                  left: 100,
                  top: 100,
                  child: AlgorithmNodeWidget(
                    algorithmName: 'Test Algorithm',
                    slotNumber: 1,
                    position: const Offset(100, 100),
                    inputLabels: ['Input 1'],
                    outputLabels: ['Output 1'],
                    inputPortIds: ['test_in_1'],
                    outputPortIds: ['test_out_1'],
                    onPortPositionResolved: trackAlgorithmPort,
                  ),
                ),
                // Physical input node using universal port widget
                Positioned(
                  left: 300,
                  top: 150,
                  child: PhysicalInputNode(
                    position: const Offset(300, 150),
                    onPortPositionResolved: trackPhysicalPort,
                  ),
                ),
                // Physical output node using universal port widget
                Positioned(
                  left: 500,
                  top: 100,
                  child: PhysicalOutputNode(
                    position: const Offset(500, 100),
                    onPortPositionResolved: trackPhysicalPort,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      await tester.pump(); // Allow port position callbacks to fire

      // ✅ Validate universal port widget usage
      expect(find.byType(PortWidget), findsNWidgets(22)); // 2 + 12 + 8

      // ✅ Validate algorithm node preservation
      expect(find.byType(AlgorithmNodeWidget), findsOneWidget);
      expect(find.text('#1 Test Algorithm'), findsOneWidget);

      // ✅ Validate physical I/O nodes are present
      expect(find.byType(PhysicalInputNode), findsOneWidget);
      expect(find.byType(PhysicalOutputNode), findsOneWidget);

      // ✅ Validate port position callbacks work
      expect(algorithmPortCallbackFired, isTrue);
      expect(physicalPortCallbackFired, isTrue);
      expect(allPortPositions.isNotEmpty, isTrue);

      // ✅ Validate different port styles
      final portWidgets = tester.widgetList<PortWidget>(find.byType(PortWidget)).toList();
      final dotPorts = portWidgets.where((w) => w.style == PortStyle.dot).length;
      final jackPorts = portWidgets.where((w) => w.style == PortStyle.jack).length;
      
      expect(dotPorts, equals(2)); // Algorithm ports use dots
      expect(jackPorts, equals(20)); // Physical ports use jacks

      // ✅ System stability validation
      expect(tester.takeException(), isNull);
    });

    testWidgets('Physical I/O node movement with connection updates', (tester) async {
      final List<Offset> inputPortHistory = [];
      final List<Offset> outputPortHistory = [];
      
      Offset inputNodePosition = const Offset(100, 100);
      Offset outputNodePosition = const Offset(400, 100);

      Widget buildMovableScene() {
        return MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                Positioned(
                  left: inputNodePosition.dx,
                  top: inputNodePosition.dy,
                  child: PhysicalInputNode(
                    position: inputNodePosition,
                    onPortPositionResolved: (port, pos) {
                      if (port.id == 'hw_in_1') {
                        inputPortHistory.add(pos);
                      }
                    },
                  ),
                ),
                Positioned(
                  left: outputNodePosition.dx,
                  top: outputNodePosition.dy,
                  child: PhysicalOutputNode(
                    position: outputNodePosition,
                    onPortPositionResolved: (port, pos) {
                      if (port.id == 'hw_out_1') {
                        outputPortHistory.add(pos);
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

      // Move input node
      inputNodePosition = const Offset(150, 150);
      await tester.pumpWidget(buildMovableScene());
      await tester.pumpAndSettle();
      await tester.pump();

      // Move output node
      outputNodePosition = const Offset(450, 120);
      await tester.pumpWidget(buildMovableScene());
      await tester.pumpAndSettle();
      await tester.pump();

      // ✅ Validate port positions updated with node movement
      expect(inputPortHistory.length, greaterThanOrEqualTo(2));
      expect(outputPortHistory.length, greaterThanOrEqualTo(2));

      if (inputPortHistory.length >= 2) {
        expect(inputPortHistory.first, isNot(equals(inputPortHistory.last)));
      }

      // ✅ Validate nodes remained functional after movement
      expect(find.byType(PhysicalInputNode), findsOneWidget);
      expect(find.byType(PhysicalOutputNode), findsOneWidget);
      expect(find.byType(PortWidget), findsNWidgets(20)); // 12 + 8

      // ✅ System stability after movement
      expect(tester.takeException(), isNull);
    });

    testWidgets('Cross-node-type connections compatibility', (tester) async {
      final Set<String> allPortIds = {};

      void collectAlgorithmPortId(String portId, Offset position, bool isInput) {
        allPortIds.add('algo_$portId');
      }

      void collectPhysicalPortId(port, Offset position) {
        allPortIds.add('phys_${port.id}');
      }

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                // Source: Physical Input
                Positioned(
                  left: 50,
                  top: 100,
                  child: PhysicalInputNode(
                    position: const Offset(50, 100),
                    onPortPositionResolved: collectPhysicalPortId,
                  ),
                ),
                // Processing: Algorithm
                Positioned(
                  left: 250,
                  top: 120,
                  child: AlgorithmNodeWidget(
                    algorithmName: 'Signal Processor',
                    slotNumber: 1,
                    position: const Offset(250, 120),
                    inputLabels: ['Audio In'],
                    outputLabels: ['Processed Out'],
                    inputPortIds: ['proc_in'],
                    outputPortIds: ['proc_out'],
                    onPortPositionResolved: collectAlgorithmPortId,
                  ),
                ),
                // Target: Physical Output
                Positioned(
                  left: 450,
                  top: 100,
                  child: PhysicalOutputNode(
                    position: const Offset(450, 100),
                    onPortPositionResolved: collectPhysicalPortId,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      await tester.pump();

      // ✅ Validate complete signal chain presence
      expect(find.byType(PhysicalInputNode), findsOneWidget);
      expect(find.byType(AlgorithmNodeWidget), findsOneWidget);
      expect(find.byType(PhysicalOutputNode), findsOneWidget);

      // ✅ Validate all port types are accessible
      expect(allPortIds, contains('phys_hw_in_1'));
      expect(allPortIds, contains('algo_proc_in'));
      expect(allPortIds, contains('algo_proc_out'));
      expect(allPortIds, contains('phys_hw_out_1'));

      // ✅ Validate total port count
      expect(find.byType(PortWidget), findsNWidgets(22)); // 12 + 2 + 8

      // ✅ System provides connection infrastructure
      expect(allPortIds.length, greaterThanOrEqualTo(22));
      expect(tester.takeException(), isNull);
    });

    testWidgets('Performance validation under complex scenarios', (tester) async {
      final stopwatch = Stopwatch()..start();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                // Complex routing scenario
                Positioned(
                  left: 50,
                  top: 100,
                  child: PhysicalInputNode(position: const Offset(50, 100)),
                ),
                ...List.generate(3, (index) => Positioned(
                  left: 200.0 + index * 150,
                  top: 80.0 + index * 40,
                  child: AlgorithmNodeWidget(
                    algorithmName: 'Algorithm ${index + 1}',
                    slotNumber: index + 1,
                    position: Offset(200.0 + index * 150, 80.0 + index * 40),
                    inputLabels: ['In ${index + 1}'],
                    outputLabels: ['Out ${index + 1}'],
                  ),
                )),
                Positioned(
                  left: 650,
                  top: 140,
                  child: PhysicalOutputNode(position: const Offset(650, 140)),
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      stopwatch.stop();

      // ✅ Performance validation
      expect(stopwatch.elapsedMilliseconds, lessThan(2000),
          reason: 'Complex routing scene should render within 2 seconds');

      // ✅ All components present
      expect(find.byType(PhysicalInputNode), findsOneWidget);
      expect(find.byType(AlgorithmNodeWidget), findsNWidgets(3));
      expect(find.byType(PhysicalOutputNode), findsOneWidget);
      expect(find.byType(PortWidget), findsNWidgets(26)); // 12 + 6 + 8

      // ✅ System stability
      expect(tester.takeException(), isNull);
    });

    testWidgets('Complete system stability validation', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                Positioned(
                  left: 100,
                  top: 100,
                  child: AlgorithmNodeWidget(
                    algorithmName: 'Stable Algorithm',
                    slotNumber: 1,
                    position: const Offset(100, 100),
                    inputLabels: ['Stable Input'],
                    outputLabels: ['Stable Output'],
                  ),
                ),
                Positioned(
                  left: 300,
                  top: 150,
                  child: PhysicalInputNode(
                    position: const Offset(300, 150),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      await tester.pump(); // Allow port callbacks

      // ✅ System renders successfully
      expect(find.byType(AlgorithmNodeWidget), findsOneWidget);
      expect(find.byType(PhysicalInputNode), findsOneWidget);
      expect(find.byType(PortWidget), findsNWidgets(14)); // 2 + 12

      // ✅ No exceptions occurred during rendering
      expect(tester.takeException(), isNull);
    });
  });
}