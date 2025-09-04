import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/core/routing/connection_discovery_service.dart';
import 'package:nt_helper/core/routing/algorithm_routing.dart';
import 'package:nt_helper/core/routing/models/connection.dart';
import 'package:nt_helper/core/routing/models/port.dart';
import 'package:nt_helper/ui/widgets/routing/connection_painter.dart';
import 'package:nt_helper/ui/widgets/routing/algorithm_node_widget.dart';
import 'package:nt_helper/ui/widgets/routing/physical_input_node.dart';
import 'package:nt_helper/ui/widgets/routing/physical_output_node.dart';
import 'package:nt_helper/ui/widgets/routing/port_widget.dart';

/// Tests to validate connection discovery and visualization systems
/// work correctly with the universal port widget architecture.
/// 
/// Validates:
/// - Connection discovery between different node types
/// - Visual connection rendering with updated port positions
/// - Bus-based connection detection
/// - Port compatibility validation
/// - Connection visualization updates when nodes move
void main() {
  group('Connection Discovery and Visualization Tests', () {
    
    group('Connection Discovery Integration', () {
      test('Connection discovery structure validation', () {
        // Create mock algorithm routings with compatible ports
        final sourceAlgorithm = MockAlgorithmRouting(
          mockAlgorithmId: 'source',
          mockIndex: 0,
          inputPorts: [],
          outputPorts: [
            Port(
              id: 'source_out',
              name: 'Output',
              type: PortType.audio,
              direction: PortDirection.output,
              metadata: {
                'busValue': 5,
                'busParam': 'output_bus',
                'parameterNumber': 30,
              },
            ),
          ],
        );

        final targetAlgorithm = MockAlgorithmRouting(
          mockAlgorithmId: 'target',
          mockIndex: 1,
          inputPorts: [
            Port(
              id: 'target_in',
              name: 'Input',
              type: PortType.audio,
              direction: PortDirection.input,
              metadata: {
                'busValue': 5, // Same bus as source
                'busParam': 'input_bus',
                'parameterNumber': 20,
              },
            ),
          ],
          outputPorts: [],
        );

        // Verify mock structure for potential connection discovery
        expect(sourceAlgorithm.outputPorts, hasLength(1));
        expect(targetAlgorithm.inputPorts, hasLength(1));
        
        final sourceOutput = sourceAlgorithm.outputPorts.first;
        final targetInput = targetAlgorithm.inputPorts.first;
        
        // Verify bus compatibility for connection discovery
        expect(sourceOutput.metadata['busValue'], equals(targetInput.metadata['busValue']));
        expect(sourceOutput.type, equals(targetInput.type));
        expect(sourceOutput.id, equals('source_out'));
        expect(targetInput.id, equals('target_in'));
      });

      test('Hardware connection port validation', () {
        final algorithm = MockAlgorithmRouting(
          mockAlgorithmId: 'hw_connected',
          mockIndex: 0,
          inputPorts: [
            Port(
              id: 'hw_input',
              name: 'HW Input',
              type: PortType.audio,
              direction: PortDirection.input,
              metadata: {
                'busValue': 1, // Hardware input bus I1
                'busParam': 'input_bus',
                'parameterNumber': 20,
              },
            ),
          ],
          outputPorts: [
            Port(
              id: 'hw_output',
              name: 'HW Output',
              type: PortType.audio,
              direction: PortDirection.output,
              metadata: {
                'busValue': 13, // Hardware output bus O1
                'busParam': 'output_bus',
                'parameterNumber': 30,
              },
              outputMode: OutputMode.replace,
            ),
          ],
        );

        // Verify hardware connection structure
        expect(algorithm.inputPorts, hasLength(1));
        expect(algorithm.outputPorts, hasLength(1));
        
        final input = algorithm.inputPorts.first;
        final output = algorithm.outputPorts.first;
        
        // Hardware input bus range (1-12)
        expect(input.metadata['busValue'], equals(1));
        expect(input.metadata['busValue'], greaterThanOrEqualTo(1));
        expect(input.metadata['busValue'], lessThanOrEqualTo(12));
        
        // Hardware output bus range (13-20)  
        expect(output.metadata['busValue'], equals(13));
        expect(output.metadata['busValue'], greaterThanOrEqualTo(13));
        expect(output.metadata['busValue'], lessThanOrEqualTo(20));
        expect(output.outputMode, equals(OutputMode.replace));
      });

      test('Connection discovery creates partial connections for unmatched ports', () {
        final algorithm = MockAlgorithmRouting(
          mockAlgorithmId: 'partial_test',
          mockIndex: 0,
          inputPorts: [
            Port(
              id: 'partial_input',
              name: 'Unmatched Input',
              type: PortType.cv,
              direction: PortDirection.input,
              metadata: {
                'busValue': 21, // Aux bus A1
                'busParam': 'input_bus',
                'parameterNumber': 20,
              },
            ),
          ],
          outputPorts: [
            Port(
              id: 'partial_output',
              name: 'Unmatched Output', 
              type: PortType.audio,
              direction: PortDirection.output,
              metadata: {
                'busValue': 28, // Aux bus A8
                'busParam': 'output_bus',
                'parameterNumber': 30,
              },
            ),
          ],
        );

        final connections = ConnectionDiscoveryService.discoverConnections([algorithm]);

        expect(connections, hasLength(2)); // Two partial connections

        final partialConnections = connections.where((c) => c.isPartial).toList();
        expect(partialConnections, hasLength(2));

        // Partial input connection
        final partialInput = partialConnections.firstWhere(
          (c) => c.connectionType == ConnectionType.partialBusToInput
        );
        expect(partialInput.sourcePortId, equals('bus_21_endpoint'));
        expect(partialInput.destinationPortId, equals('partial_input'));
        expect(partialInput.busLabel, equals('A1'));

        // Partial output connection
        final partialOutput = partialConnections.firstWhere(
          (c) => c.connectionType == ConnectionType.partialOutputToBus
        );
        expect(partialOutput.sourcePortId, equals('partial_output'));
        expect(partialOutput.destinationPortId, equals('bus_28_endpoint'));
        expect(partialOutput.busLabel, equals('A8'));
      });

      test('Bus label generation works correctly', () {
        final testCases = [
          {'busValue': 1, 'expectedLabel': 'I1'},    // Input bus 1
          {'busValue': 12, 'expectedLabel': 'I12'},  // Input bus 12
          {'busValue': 13, 'expectedLabel': 'O1'},   // Output bus 1
          {'busValue': 20, 'expectedLabel': 'O8'},   // Output bus 8
          {'busValue': 21, 'expectedLabel': 'A1'},   // Aux bus 1
          {'busValue': 28, 'expectedLabel': 'A8'},   // Aux bus 8
        ];

        for (final testCase in testCases) {
          final busValue = testCase['busValue'] as int;
          final expectedLabel = testCase['expectedLabel'] as String;

          final algorithm = MockAlgorithmRouting(
            mockAlgorithmId: 'label_test_$busValue',
            mockIndex: 0,
            inputPorts: [],
            outputPorts: [
              Port(
                id: 'test_output_$busValue',
                name: 'Test Output',
                type: PortType.audio,
                direction: PortDirection.output,
                metadata: {
                  'busValue': busValue,
                  'busParam': 'output_bus',
                  'parameterNumber': 30,
                },
              ),
            ],
          );

          final connections = ConnectionDiscoveryService.discoverConnections([algorithm]);

          if (busValue >= 13 && busValue <= 20) {
            // Hardware output connection
            final hwConnection = connections.firstWhere(
              (c) => c.connectionType == ConnectionType.hardwareOutput
            );
            expect(hwConnection.busNumber, equals(busValue));
          } else {
            // Partial connection
            final partialConnection = connections.firstWhere((c) => c.isPartial);
            expect(partialConnection.busLabel, equals(expectedLabel),
              reason: 'Bus $busValue should generate label $expectedLabel');
          }
        }
      });
    });

    group('Visual Connection Rendering', () {
      testWidgets('Connection painter can access port positions', (tester) async {
        final Map<String, Offset> portPositions = {};

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Stack(
                children: [
                  Positioned(
                    left: 100,
                    top: 100,
                    child: AlgorithmNodeWidget(
                      algorithmName: 'Source',
                      slotNumber: 1,
                      position: const Offset(100, 100),
                      outputLabels: ['Output'],
                      outputPortIds: ['visual_out'],
                      onPortPositionResolved: (portId, pos, isInput) {
                        portPositions[portId] = pos;
                      },
                    ),
                  ),
                  Positioned(
                    left: 350,
                    top: 150,
                    child: AlgorithmNodeWidget(
                      algorithmName: 'Target',
                      slotNumber: 2,
                      position: const Offset(350, 150),
                      inputLabels: ['Input'],
                      inputPortIds: ['visual_in'],
                      onPortPositionResolved: (portId, pos, isInput) {
                        portPositions[portId] = pos;
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

        // Port positions should be available for connection rendering
        expect(portPositions.containsKey('visual_out'), isTrue);
        expect(portPositions.containsKey('visual_in'), isTrue);

        final sourcePos = portPositions['visual_out']!;
        final targetPos = portPositions['visual_in']!;

        // Positions should be valid for drawing connections
        expect(sourcePos.dx, greaterThan(0));
        expect(sourcePos.dy, greaterThan(0));
        expect(targetPos.dx, greaterThan(sourcePos.dx)); // Target to the right
        
        // Should have reasonable distance between ports
        final distance = (targetPos - sourcePos).distance;
        expect(distance, greaterThan(50)); // Sufficient space for connection line
      });

      testWidgets('Physical I/O port positions are accessible for connections', (tester) async {
        final Map<String, Offset> physicalPortPositions = {};

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Stack(
                children: [
                  Positioned(
                    left: 50,
                    top: 100,
                    child: PhysicalInputNode(
                      position: const Offset(50, 100),
                      onPortPositionResolved: (port, pos) {
                        physicalPortPositions[port.id] = pos;
                      },
                    ),
                  ),
                  Positioned(
                    left: 500,
                    top: 100,
                    child: PhysicalOutputNode(
                      position: const Offset(500, 100),
                      onPortPositionResolved: (port, pos) {
                        physicalPortPositions[port.id] = pos;
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

        // Should have all physical port positions
        expect(physicalPortPositions.length, equals(20)); // 12 inputs + 8 outputs

        // Verify specific port IDs exist
        expect(physicalPortPositions.containsKey('hw_in_1'), isTrue);
        expect(physicalPortPositions.containsKey('hw_in_12'), isTrue);
        expect(physicalPortPositions.containsKey('hw_out_1'), isTrue);
        expect(physicalPortPositions.containsKey('hw_out_8'), isTrue);

        // Input ports should be to the left of output ports
        final inputX = physicalPortPositions['hw_in_1']!.dx;
        final outputX = physicalPortPositions['hw_out_1']!.dx;
        expect(inputX, lessThan(outputX));
      });

      testWidgets('Mixed node types provide compatible connection points', (tester) async {
        final Map<String, Offset> allPortPositions = {};

        void trackAlgorithmPort(String portId, Offset pos, bool isInput) {
          allPortPositions[portId] = pos;
        }

        void trackPhysicalPort(Port port, Offset pos) {
          allPortPositions[port.id] = pos;
        }

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Stack(
                children: [
                  // Physical input (leftmost)
                  Positioned(
                    left: 50,
                    top: 150,
                    child: PhysicalInputNode(
                      position: const Offset(50, 150),
                      onPortPositionResolved: trackPhysicalPort,
                    ),
                  ),
                  // Algorithm in middle
                  Positioned(
                    left: 300,
                    top: 170,
                    child: AlgorithmNodeWidget(
                      algorithmName: 'Processor',
                      slotNumber: 1,
                      position: const Offset(300, 170),
                      inputLabels: ['In'],
                      outputLabels: ['Out'],
                      inputPortIds: ['proc_in'],
                      outputPortIds: ['proc_out'],
                      onPortPositionResolved: trackAlgorithmPort,
                    ),
                  ),
                  // Physical output (rightmost)
                  Positioned(
                    left: 550,
                    top: 150,
                    child: PhysicalOutputNode(
                      position: const Offset(550, 150),
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

        // Should have positions for all port types
        final physicalInputCount = allPortPositions.keys
            .where((id) => id.startsWith('hw_in_'))
            .length;
        final physicalOutputCount = allPortPositions.keys
            .where((id) => id.startsWith('hw_out_'))
            .length;
        final algorithmCount = allPortPositions.keys
            .where((id) => id.startsWith('proc_'))
            .length;

        expect(physicalInputCount, equals(12));
        expect(physicalOutputCount, equals(8));
        expect(algorithmCount, equals(2));

        // Verify logical left-to-right flow for connections
        final physicalInX = allPortPositions['hw_in_1']!.dx;
        final algorithmInX = allPortPositions['proc_in']!.dx;
        final algorithmOutX = allPortPositions['proc_out']!.dx;
        final physicalOutX = allPortPositions['hw_out_1']!.dx;

        expect(physicalInX, lessThan(algorithmInX));
        expect(algorithmInX, lessThan(algorithmOutX));
        expect(algorithmOutX, lessThan(physicalOutX));
      });
    });

    group('Connection Updates with Node Movement', () {
      testWidgets('Port positions update when nodes move for connection tracking', (tester) async {
        final List<Map<String, Offset>> positionSnapshots = [];

        void capturePositions(String portId, Offset pos, bool isInput) {
          final currentSnapshot = positionSnapshots.isNotEmpty 
              ? Map<String, Offset>.from(positionSnapshots.last)
              : <String, Offset>{};
          currentSnapshot[portId] = pos;
          if (positionSnapshots.isEmpty || 
              !_mapsEqual(positionSnapshots.last, currentSnapshot)) {
            positionSnapshots.add(currentSnapshot);
          }
        }

        Offset nodePosition = const Offset(200, 200);

        Widget buildMovableScene() {
          return MaterialApp(
            home: Scaffold(
              body: Stack(
                children: [
                  Positioned(
                    left: nodePosition.dx,
                    top: nodePosition.dy,
                    child: AlgorithmNodeWidget(
                      algorithmName: 'Movable Connection Test',
                      slotNumber: 1,
                      position: nodePosition,
                      inputLabels: ['Movable In'],
                      outputLabels: ['Movable Out'],
                      inputPortIds: ['mov_in'],
                      outputPortIds: ['mov_out'],
                      onPortPositionResolved: capturePositions,
                    ),
                  ),
                  // Static reference node
                  Positioned(
                    left: 500,
                    top: 220,
                    child: AlgorithmNodeWidget(
                      algorithmName: 'Static Reference',
                      slotNumber: 2,
                      position: const Offset(500, 220),
                      inputLabels: ['Static In'],
                      inputPortIds: ['static_in'],
                      onPortPositionResolved: capturePositions,
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

        // Move the movable node
        nodePosition = const Offset(150, 300);
        await tester.pumpWidget(buildMovableScene());
        await tester.pumpAndSettle();
        await tester.pump();

        // Should have captured position updates
        expect(positionSnapshots.length, greaterThanOrEqualTo(2));

        if (positionSnapshots.length >= 2) {
          final initialPositions = positionSnapshots.first;
          final finalPositions = positionSnapshots.last;

          // Movable ports should have changed position
          if (initialPositions.containsKey('mov_in') && finalPositions.containsKey('mov_in')) {
            expect(finalPositions['mov_in'], isNot(equals(initialPositions['mov_in'])));
          }

          // Static port should remain in same position (approximately)
          if (initialPositions.containsKey('static_in') && finalPositions.containsKey('static_in')) {
            final staticInitial = initialPositions['static_in']!;
            final staticFinal = finalPositions['static_in']!;
            expect((staticFinal - staticInitial).distance, lessThan(5.0));
          }
        }
      });

      testWidgets('Physical I/O node movement updates connection anchor points', (tester) async {
        final List<Offset> physicalPortHistory = [];
        final List<Offset> algorithmPortHistory = [];

        Offset physicalPosition = const Offset(100, 100);

        Widget buildMovablePhysicalScene() {
          return MaterialApp(
            home: Scaffold(
              body: Stack(
                children: [
                  Positioned(
                    left: physicalPosition.dx,
                    top: physicalPosition.dy,
                    child: PhysicalInputNode(
                      position: physicalPosition,
                      onPortPositionResolved: (port, pos) {
                        if (port.id == 'hw_in_1') {
                          physicalPortHistory.add(pos);
                        }
                      },
                    ),
                  ),
                  // Static algorithm node for comparison
                  Positioned(
                    left: 400,
                    top: 150,
                    child: AlgorithmNodeWidget(
                      algorithmName: 'Static Target',
                      slotNumber: 1,
                      position: const Offset(400, 150),
                      inputLabels: ['Target'],
                      inputPortIds: ['target_in'],
                      onPortPositionResolved: (portId, pos, isInput) {
                        if (portId == 'target_in') {
                          algorithmPortHistory.add(pos);
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
        await tester.pumpWidget(buildMovablePhysicalScene());
        await tester.pumpAndSettle();
        await tester.pump();

        // Move physical node
        physicalPosition = const Offset(150, 200);
        await tester.pumpWidget(buildMovablePhysicalScene());
        await tester.pumpAndSettle();
        await tester.pump();

        // Physical port should have moved, algorithm port should stay put
        expect(physicalPortHistory.length, greaterThanOrEqualTo(2));
        expect(algorithmPortHistory.length, greaterThanOrEqualTo(1));

        if (physicalPortHistory.length >= 2) {
          final initialPhysical = physicalPortHistory.first;
          final movedPhysical = physicalPortHistory.last;
          expect(movedPhysical, isNot(equals(initialPhysical)));
        }

        // Algorithm port positions should be stable
        if (algorithmPortHistory.length >= 2) {
          final positions = algorithmPortHistory;
          final maxDistance = positions
              .map((pos) => positions.first)
              .map((basePos) => positions.map((p) => (p - basePos).distance).reduce((a, b) => a > b ? a : b))
              .reduce((a, b) => a > b ? a : b);
          expect(maxDistance, lessThan(10.0)); // Should be relatively stable
        }
      });
    });

    group('Complex Connection Scenarios', () {
      testWidgets('Full routing chain maintains connection integrity', (tester) async {
        final Map<String, Offset> allPortPositions = {};

        void trackAllPorts(String portId, Offset pos, [bool? isInput]) {
          allPortPositions[portId] = pos;
        }

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Stack(
                children: [
                  // Full chain: Physical Input -> Algorithm 1 -> Algorithm 2 -> Physical Output
                  Positioned(
                    left: 50,
                    top: 150,
                    child: PhysicalInputNode(
                      position: const Offset(50, 150),
                      onPortPositionResolved: (port, pos) => trackAllPorts(port.id, pos),
                    ),
                  ),
                  Positioned(
                    left: 250,
                    top: 130,
                    child: AlgorithmNodeWidget(
                      algorithmName: 'Filter',
                      slotNumber: 1,
                      position: const Offset(250, 130),
                      inputLabels: ['Audio In'],
                      outputLabels: ['Filtered'],
                      inputPortIds: ['filt_in'],
                      outputPortIds: ['filt_out'],
                      onPortPositionResolved: (portId, pos, isInput) => trackAllPorts(portId, pos, isInput),
                    ),
                  ),
                  Positioned(
                    left: 450,
                    top: 160,
                    child: AlgorithmNodeWidget(
                      algorithmName: 'Reverb',
                      slotNumber: 2,
                      position: const Offset(450, 160),
                      inputLabels: ['Audio In'],
                      outputLabels: ['Wet Out'],
                      inputPortIds: ['rev_in'],
                      outputPortIds: ['rev_out'],
                      onPortPositionResolved: (portId, pos, isInput) => trackAllPorts(portId, pos, isInput),
                    ),
                  ),
                  Positioned(
                    left: 650,
                    top: 140,
                    child: PhysicalOutputNode(
                      position: const Offset(650, 140),
                      onPortPositionResolved: (port, pos) => trackAllPorts(port.id, pos),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        await tester.pump();

        // Verify complete signal chain positioning
        expect(allPortPositions.isNotEmpty, isTrue);

        // Should have all expected port types
        final physicalInputPorts = allPortPositions.keys.where((id) => id.startsWith('hw_in_')).length;
        final physicalOutputPorts = allPortPositions.keys.where((id) => id.startsWith('hw_out_')).length;
        final algorithmPorts = allPortPositions.keys.where((id) => id.startsWith('filt_') || id.startsWith('rev_')).length;

        expect(physicalInputPorts, equals(12));
        expect(physicalOutputPorts, equals(8));
        expect(algorithmPorts, equals(4)); // 2 inputs + 2 outputs

        // Verify logical left-to-right positioning
        final physicalInX = allPortPositions['hw_in_1']?.dx ?? 0;
        final filterInX = allPortPositions['filt_in']?.dx ?? 0;
        final filterOutX = allPortPositions['filt_out']?.dx ?? 0;
        final reverbInX = allPortPositions['rev_in']?.dx ?? 0;
        final reverbOutX = allPortPositions['rev_out']?.dx ?? 0;
        final physicalOutX = allPortPositions['hw_out_1']?.dx ?? 0;

        expect(physicalInX, lessThan(filterInX));
        expect(filterOutX, lessThan(reverbInX));
        expect(reverbOutX, lessThan(physicalOutX));
      });

      test('Complex connection discovery with mixed bus types', () {
        final algorithms = [
          // Algorithm 1: Hardware input to internal bus
          MockAlgorithmRouting(
            mockAlgorithmId: 'input_stage',
            mockIndex: 0,
            inputPorts: [
              Port(
                id: 'input_hw',
                name: 'Hardware In',
                type: PortType.audio,
                direction: PortDirection.input,
                metadata: {'busValue': 1, 'busParam': 'input_bus', 'parameterNumber': 20},
              ),
            ],
            outputPorts: [
              Port(
                id: 'input_proc',
                name: 'Processed',
                type: PortType.audio,
                direction: PortDirection.output,
                metadata: {'busValue': 5, 'busParam': 'output_bus', 'parameterNumber': 30},
              ),
            ],
          ),
          // Algorithm 2: Internal bus to internal bus
          MockAlgorithmRouting(
            mockAlgorithmId: 'middle_stage',
            mockIndex: 1,
            inputPorts: [
              Port(
                id: 'middle_in',
                name: 'Middle In',
                type: PortType.audio,
                direction: PortDirection.input,
                metadata: {'busValue': 5, 'busParam': 'input_bus', 'parameterNumber': 20},
              ),
            ],
            outputPorts: [
              Port(
                id: 'middle_out',
                name: 'Middle Out',
                type: PortType.audio,
                direction: PortDirection.output,
                metadata: {'busValue': 6, 'busParam': 'output_bus', 'parameterNumber': 30},
              ),
            ],
          ),
          // Algorithm 3: Internal bus to hardware output
          MockAlgorithmRouting(
            mockAlgorithmId: 'output_stage',
            mockIndex: 2,
            inputPorts: [
              Port(
                id: 'output_in',
                name: 'Output In',
                type: PortType.audio,
                direction: PortDirection.input,
                metadata: {'busValue': 6, 'busParam': 'input_bus', 'parameterNumber': 20},
              ),
            ],
            outputPorts: [
              Port(
                id: 'output_hw',
                name: 'Hardware Out',
                type: PortType.audio,
                direction: PortDirection.output,
                metadata: {'busValue': 13, 'busParam': 'output_bus', 'parameterNumber': 30},
                outputMode: OutputMode.replace,
              ),
            ],
          ),
        ];

        final connections = ConnectionDiscoveryService.discoverConnections(algorithms);

        // Should discover complete chain: HW Input -> Algo1 -> Algo2 -> Algo3 -> HW Output
        expect(connections, hasLength(5));

        // Hardware input connection
        final hwInput = connections.where((c) => c.connectionType == ConnectionType.hardwareInput);
        expect(hwInput, hasLength(1));
        expect(hwInput.first.sourcePortId, equals('hw_in_1'));
        expect(hwInput.first.destinationPortId, equals('input_hw'));

        // Algorithm-to-algorithm connections
        final algoConnections = connections.where((c) => c.connectionType == ConnectionType.algorithmToAlgorithm);
        expect(algoConnections, hasLength(2));

        // Hardware output connection
        final hwOutput = connections.where((c) => c.connectionType == ConnectionType.hardwareOutput);
        expect(hwOutput, hasLength(1));
        expect(hwOutput.first.sourcePortId, equals('output_hw'));
        expect(hwOutput.first.destinationPortId, equals('hw_out_1'));
      });
    });
  });
}

// Helper function for map comparison
bool _mapsEqual<K, V>(Map<K, V> map1, Map<K, V> map2) {
  if (map1.length != map2.length) return false;
  for (final key in map1.keys) {
    if (!map2.containsKey(key) || map1[key] != map2[key]) {
      return false;
    }
  }
  return true;
}

/// Mock implementation of AlgorithmRouting for testing
class MockAlgorithmRouting {
  final String mockAlgorithmId;
  final int mockIndex;
  final List<Port> inputPorts;
  final List<Port> outputPorts;

  MockAlgorithmRouting({
    required this.mockAlgorithmId,
    required this.mockIndex,
    required this.inputPorts,
    required this.outputPorts,
  });
}