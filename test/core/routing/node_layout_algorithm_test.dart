import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/core/routing/node_layout_algorithm.dart';
import 'package:nt_helper/core/routing/models/port.dart';
import 'package:nt_helper/core/routing/models/connection.dart';
import 'package:nt_helper/cubit/routing_editor_state.dart';
import 'package:nt_helper/domain/disting_nt_sysex.dart';

void main() {
  group('NodeLayoutAlgorithm', () {
    late NodeLayoutAlgorithm layoutAlgorithm;

    setUp(() {
      layoutAlgorithm = NodeLayoutAlgorithm();
    });

    group('calculateLayout', () {
      test('handles empty node list', () {
        final result = layoutAlgorithm.calculateLayout(
          physicalInputs: [],
          physicalOutputs: [],
          algorithms: [],
          connections: [],
        );

        expect(result.algorithmPositions, isEmpty);
        expect(result.physicalInputPositions, isEmpty);
        expect(result.physicalOutputPositions, isEmpty);
      });

      test('positions physical inputs on left side', () {
        final physicalInputs = [
          const Port(
            id: 'hw_in_1',
            name: 'I1',
            type: PortType.cv,
            direction: PortDirection.output,
          ),
          const Port(
            id: 'hw_in_2',
            name: 'I2',
            type: PortType.cv,
            direction: PortDirection.output,
          ),
        ];

        final result = layoutAlgorithm.calculateLayout(
          physicalInputs: physicalInputs,
          physicalOutputs: [],
          algorithms: [],
          connections: [],
        );

        expect(result.physicalInputPositions, hasLength(2));

        // All inputs should be on left side (x = physicalInputX = 50.0)
        for (final position in result.physicalInputPositions.values) {
          expect(position.x, equals(50.0));
        }

        // Should be vertically centered with spacing
        expect(
          result.physicalInputPositions['hw_in_1']!.y,
          lessThan(result.physicalInputPositions['hw_in_2']!.y),
        );
      });

      test('positions physical outputs on right side', () {
        final physicalOutputs = [
          const Port(
            id: 'hw_out_1',
            name: 'O1',
            type: PortType.audio,
            direction: PortDirection.input,
          ),
          const Port(
            id: 'hw_out_2',
            name: 'O2',
            type: PortType.audio,
            direction: PortDirection.input,
          ),
        ];

        final result = layoutAlgorithm.calculateLayout(
          physicalInputs: [],
          physicalOutputs: physicalOutputs,
          algorithms: [],
          connections: [],
        );

        expect(result.physicalOutputPositions, hasLength(2));

        // All outputs should be on right side (x = physicalOutputX = 750.0)
        for (final position in result.physicalOutputPositions.values) {
          expect(position.x, equals(750.0));
        }

        // Should be vertically centered with spacing
        expect(
          result.physicalOutputPositions['hw_out_1']!.y,
          lessThan(result.physicalOutputPositions['hw_out_2']!.y),
        );
      });

      test('positions algorithms in center with slot ordering', () {
        final algorithms = [
          RoutingAlgorithm(
            id: 'algo_1',
            index: 1, // Higher slot number
            algorithm: Algorithm(
              algorithmIndex: 1,
              guid: 'test1',
              name: 'Test Algorithm 1',
            ),
            inputPorts: const [
              Port(
                id: 'algo_1_in',
                name: 'Input',
                type: PortType.cv,
                direction: PortDirection.input,
              ),
            ],
            outputPorts: const [
              Port(
                id: 'algo_1_out',
                name: 'Output',
                type: PortType.cv,
                direction: PortDirection.output,
              ),
            ],
          ),
          RoutingAlgorithm(
            id: 'algo_0',
            index: 0, // Lower slot number
            algorithm: Algorithm(
              algorithmIndex: 0,
              guid: 'test0',
              name: 'Test Algorithm 0',
            ),
            inputPorts: const [
              Port(
                id: 'algo_0_in',
                name: 'Input',
                type: PortType.cv,
                direction: PortDirection.input,
              ),
            ],
            outputPorts: const [
              Port(
                id: 'algo_0_out',
                name: 'Output',
                type: PortType.cv,
                direction: PortDirection.output,
              ),
            ],
          ),
        ];

        final result = layoutAlgorithm.calculateLayout(
          physicalInputs: [],
          physicalOutputs: [],
          algorithms: algorithms,
          connections: [],
        );

        expect(result.algorithmPositions, hasLength(2));

        // Algorithm positions should be in center (x between inputs and outputs)
        for (final position in result.algorithmPositions.values) {
          expect(position.x, greaterThan(0.0));
          expect(position.x, lessThan(NodeLayoutAlgorithm.canvasWidth));
        }

        // Lower slot indices should appear higher (smaller Y values)
        final algo0Position = result.algorithmPositions['algo_0']!;
        final algo1Position = result.algorithmPositions['algo_1']!;
        expect(algo0Position.y, lessThan(algo1Position.y));
      });

      test('reduces connection overlaps with optimal positioning', () {
        final physicalInputs = [
          const Port(
            id: 'hw_in_1',
            name: 'I1',
            type: PortType.cv,
            direction: PortDirection.output,
          ),
        ];

        final physicalOutputs = [
          const Port(
            id: 'hw_out_1',
            name: 'O1',
            type: PortType.audio,
            direction: PortDirection.input,
          ),
        ];

        final algorithms = [
          RoutingAlgorithm(
            id: 'algo_0',
            index: 0,
            algorithm: Algorithm(
              algorithmIndex: 0,
              guid: 'test0',
              name: 'Test Algorithm 0',
            ),
            inputPorts: const [
              Port(
                id: 'algo_0_in',
                name: 'Input',
                type: PortType.cv,
                direction: PortDirection.input,
              ),
            ],
            outputPorts: const [
              Port(
                id: 'algo_0_out',
                name: 'Output',
                type: PortType.cv,
                direction: PortDirection.output,
              ),
            ],
          ),
        ];

        final connections = [
          const Connection(
            id: 'conn_1',
            sourcePortId: 'hw_in_1',
            destinationPortId: 'algo_0_in',
            connectionType: ConnectionType.hardwareInput,
          ),
          const Connection(
            id: 'conn_2',
            sourcePortId: 'algo_0_out',
            destinationPortId: 'hw_out_1',
            connectionType: ConnectionType.hardwareOutput,
          ),
        ];

        final result = layoutAlgorithm.calculateLayout(
          physicalInputs: physicalInputs,
          physicalOutputs: physicalOutputs,
          algorithms: algorithms,
          connections: connections,
        );

        expect(result.algorithmPositions, hasLength(1));
        expect(result.physicalInputPositions, hasLength(1));
        expect(result.physicalOutputPositions, hasLength(1));

        // Algorithm should be positioned between input and output for optimal routing
        final algoPosition = result.algorithmPositions['algo_0']!;
        final inputPosition = result.physicalInputPositions['hw_in_1']!;
        final outputPosition = result.physicalOutputPositions['hw_out_1']!;

        expect(algoPosition.x, greaterThan(inputPosition.x));
        expect(algoPosition.x, lessThan(outputPosition.x));
      });

      test('handles complex routing scenarios', () {
        final physicalInputs = List.generate(
          3,
          (i) => Port(
            id: 'hw_in_${i + 1}',
            name: 'I${i + 1}',
            type: PortType.cv,
            direction: PortDirection.output,
          ),
        );

        final physicalOutputs = List.generate(
          2,
          (i) => Port(
            id: 'hw_out_${i + 1}',
            name: 'O${i + 1}',
            type: PortType.audio,
            direction: PortDirection.input,
          ),
        );

        final algorithms = List.generate(
          5,
          (i) => RoutingAlgorithm(
            id: 'algo_$i',
            index: i,
            algorithm: Algorithm(
              algorithmIndex: i,
              guid: 'test$i',
              name: 'Test Algorithm $i',
            ),
            inputPorts: [
              Port(
                id: 'algo_${i}_in',
                name: 'Input',
                type: PortType.cv,
                direction: PortDirection.input,
              ),
            ],
            outputPorts: [
              Port(
                id: 'algo_${i}_out',
                name: 'Output',
                type: PortType.cv,
                direction: PortDirection.output,
              ),
            ],
          ),
        );

        final connections = [
          const Connection(
            id: 'conn_1',
            sourcePortId: 'hw_in_1',
            destinationPortId: 'algo_0_in',
            connectionType: ConnectionType.hardwareInput,
          ),
          const Connection(
            id: 'conn_2',
            sourcePortId: 'algo_0_out',
            destinationPortId: 'algo_1_in',
            connectionType: ConnectionType.algorithmToAlgorithm,
          ),
          const Connection(
            id: 'conn_3',
            sourcePortId: 'algo_1_out',
            destinationPortId: 'hw_out_1',
            connectionType: ConnectionType.hardwareOutput,
          ),
        ];

        final result = layoutAlgorithm.calculateLayout(
          physicalInputs: physicalInputs,
          physicalOutputs: physicalOutputs,
          algorithms: algorithms,
          connections: connections,
        );

        expect(result.algorithmPositions, hasLength(5));
        expect(result.physicalInputPositions, hasLength(3));
        expect(result.physicalOutputPositions, hasLength(2));

        // All positions should be within canvas bounds
        final allPositions = [
          ...result.physicalInputPositions.values,
          ...result.physicalOutputPositions.values,
          ...result.algorithmPositions.values,
        ];

        for (final position in allPositions) {
          expect(position.x, greaterThanOrEqualTo(0.0));
          expect(
            position.x,
            lessThanOrEqualTo(NodeLayoutAlgorithm.canvasWidth),
          );
          expect(position.y, greaterThanOrEqualTo(0.0));
          expect(
            position.y,
            lessThanOrEqualTo(NodeLayoutAlgorithm.canvasHeight),
          );
        }
      });
    });

    group('detectConnectionOverlaps', () {
      test('detects no overlaps for non-crossing connections', () {
        final connections = [
          const Connection(
            id: 'conn_1',
            sourcePortId: 'source_1',
            destinationPortId: 'dest_1',
            connectionType: ConnectionType.hardwareInput,
          ),
        ];

        final nodePositions = {
          'source_1': const NodePosition(x: 0.0, y: 0.0),
          'dest_1': const NodePosition(x: 100.0, y: 0.0),
        };

        final overlaps = layoutAlgorithm.detectConnectionOverlaps(
          connections,
          nodePositions,
        );
        expect(overlaps, isEmpty);
      });

      test('detects overlaps for crossing connections', () {
        final connections = [
          const Connection(
            id: 'conn_1',
            sourcePortId: 'source_1',
            destinationPortId: 'dest_1',
            connectionType: ConnectionType.hardwareInput,
          ),
          const Connection(
            id: 'conn_2',
            sourcePortId: 'source_2',
            destinationPortId: 'dest_2',
            connectionType: ConnectionType.hardwareInput,
          ),
        ];

        // Create crossing connections
        final nodePositions = {
          'source_1': const NodePosition(x: 0.0, y: 0.0),
          'dest_1': const NodePosition(x: 100.0, y: 100.0),
          'source_2': const NodePosition(x: 0.0, y: 100.0),
          'dest_2': const NodePosition(x: 100.0, y: 0.0),
        };

        final overlaps = layoutAlgorithm.detectConnectionOverlaps(
          connections,
          nodePositions,
        );
        expect(overlaps, isNotEmpty);
        expect(overlaps.length, equals(1));
        expect(overlaps.first.connection1Id, anyOf('conn_1', 'conn_2'));
        expect(overlaps.first.connection2Id, anyOf('conn_1', 'conn_2'));
      });
    });

    group('optimizeNodePositionsForConnections', () {
      test('adjusts positions to minimize connection overlap', () {
        final algorithms = [
          RoutingAlgorithm(
            id: 'algo_0',
            index: 0,
            algorithm: Algorithm(
              algorithmIndex: 0,
              guid: 'test0',
              name: 'Test Algorithm 0',
            ),
            inputPorts: const [
              Port(
                id: 'algo_0_in',
                name: 'Input',
                type: PortType.cv,
                direction: PortDirection.input,
              ),
            ],
            outputPorts: const [
              Port(
                id: 'algo_0_out',
                name: 'Output',
                type: PortType.cv,
                direction: PortDirection.output,
              ),
            ],
          ),
        ];

        final connections = [
          const Connection(
            id: 'conn_1',
            sourcePortId: 'hw_in_1',
            destinationPortId: 'algo_0_in',
            connectionType: ConnectionType.hardwareInput,
          ),
        ];

        final initialPositions = {
          'hw_in_1': const NodePosition(x: 0.0, y: 50.0),
          'algo_0': const NodePosition(x: 200.0, y: 150.0),
        };

        final optimizedPositions = layoutAlgorithm
            .optimizeNodePositionsForConnections(
              algorithms,
              connections,
              initialPositions,
            );

        expect(optimizedPositions, hasLength(2));

        // Positions should be adjusted for better connection flow
        final optimizedAlgoPosition = optimizedPositions['algo_0']!;
        expect(optimizedAlgoPosition.x, greaterThanOrEqualTo(0.0));
        expect(optimizedAlgoPosition.y, greaterThanOrEqualTo(0.0));
      });
    });

    group('edge cases', () {
      test('handles single node', () {
        final algorithms = [
          RoutingAlgorithm(
            id: 'algo_0',
            index: 0,
            algorithm: Algorithm(
              algorithmIndex: 0,
              guid: 'test0',
              name: 'Test Algorithm 0',
            ),
            inputPorts: const [
              Port(
                id: 'algo_0_in',
                name: 'Input',
                type: PortType.cv,
                direction: PortDirection.input,
              ),
            ],
            outputPorts: const [
              Port(
                id: 'algo_0_out',
                name: 'Output',
                type: PortType.cv,
                direction: PortDirection.output,
              ),
            ],
          ),
        ];

        final result = layoutAlgorithm.calculateLayout(
          physicalInputs: [],
          physicalOutputs: [],
          algorithms: algorithms,
          connections: [],
        );

        expect(result.algorithmPositions, hasLength(1));

        final position = result.algorithmPositions['algo_0']!;
        expect(position.x, greaterThanOrEqualTo(0.0));
        expect(position.y, greaterThanOrEqualTo(0.0));
      });

      test('handles no connections', () {
        final algorithms = List.generate(
          3,
          (i) => RoutingAlgorithm(
            id: 'algo_$i',
            index: i,
            algorithm: Algorithm(
              algorithmIndex: i,
              guid: 'test$i',
              name: 'Test Algorithm $i',
            ),
            inputPorts: [
              Port(
                id: 'algo_${i}_in',
                name: 'Input',
                type: PortType.cv,
                direction: PortDirection.input,
              ),
            ],
            outputPorts: [
              Port(
                id: 'algo_${i}_out',
                name: 'Output',
                type: PortType.cv,
                direction: PortDirection.output,
              ),
            ],
          ),
        );

        final result = layoutAlgorithm.calculateLayout(
          physicalInputs: [],
          physicalOutputs: [],
          algorithms: algorithms,
          connections: [],
        );

        expect(result.algorithmPositions, hasLength(3));

        // Should maintain slot ordering even without connections
        final positions = algorithms
            .map((a) => result.algorithmPositions[a.id]!)
            .toList();
        for (int i = 0; i < positions.length - 1; i++) {
          expect(positions[i].y, lessThan(positions[i + 1].y));
        }
      });

      test('handles maximum node count performance', () {
        // Test with 20 nodes (typical maximum)
        final algorithms = List.generate(
          20,
          (i) => RoutingAlgorithm(
            id: 'algo_$i',
            index: i,
            algorithm: Algorithm(
              algorithmIndex: i,
              guid: 'test$i',
              name: 'Test Algorithm $i',
            ),
            inputPorts: [
              Port(
                id: 'algo_${i}_in',
                name: 'Input',
                type: PortType.cv,
                direction: PortDirection.input,
              ),
            ],
            outputPorts: [
              Port(
                id: 'algo_${i}_out',
                name: 'Output',
                type: PortType.cv,
                direction: PortDirection.output,
              ),
            ],
          ),
        );

        final stopwatch = Stopwatch()..start();

        final result = layoutAlgorithm.calculateLayout(
          physicalInputs: [],
          physicalOutputs: [],
          algorithms: algorithms,
          connections: [],
        );

        stopwatch.stop();

        expect(result.algorithmPositions, hasLength(20));
        expect(
          stopwatch.elapsedMilliseconds,
          lessThan(1000),
        ); // Should complete within 1 second
      });
    });
  });
}
