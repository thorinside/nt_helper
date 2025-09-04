import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/core/routing/connection_discovery_service.dart';
import 'package:nt_helper/core/routing/algorithm_routing.dart';
import 'package:nt_helper/core/routing/models/connection.dart';
import 'package:nt_helper/core/routing/models/port.dart';

/// Mock implementation of AlgorithmRouting for testing
class MockAlgorithmRouting implements AlgorithmRouting {
  final String mockAlgorithmId;
  final int mockIndex;
  @override
  final List<Port> inputPorts;
  @override
  final List<Port> outputPorts;

  MockAlgorithmRouting({
    required this.mockAlgorithmId,
    required this.mockIndex,
    required this.inputPorts,
    required this.outputPorts,
  });
}

void main() {
  group('ConnectionDiscoveryService', () {
    test('should create full connections between matching bus values', () {
      // Create two algorithms with matching bus assignments
      final algo1 = MockAlgorithmRouting(
        mockAlgorithmId: 'algo1',
        mockIndex: 0,
        inputPorts: [],
        outputPorts: [
          Port(
            id: 'algo1_output_1',
            name: 'Output 1',
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

      final algo2 = MockAlgorithmRouting(
        mockAlgorithmId: 'algo2',
        mockIndex: 1,
        inputPorts: [
          Port(
            id: 'algo2_input_1',
            name: 'Input 1',
            type: PortType.audio,
            direction: PortDirection.input,
            metadata: {
              'busValue': 5,
              'busParam': 'input_bus',
              'parameterNumber': 20,
            },
          ),
        ],
        outputPorts: [],
      );

      final connections = ConnectionDiscoveryService.discoverConnections([algo1, algo2]);

      // Should create one full connection between the algorithms
      final fullConnections = connections.where((c) => !c.isPartial).toList();
      expect(fullConnections, hasLength(1));

      final connection = fullConnections.first;
      expect(connection.connectionType, equals(ConnectionType.algorithmToAlgorithm));
      expect(connection.sourcePortId, equals('algo1_output_1'));
      expect(connection.destinationPortId, equals('algo2_input_1'));
      expect(connection.busNumber, equals(5));
      expect(connection.isPartial, isFalse);
    });

    test('should create partial connections for unmatched outputs', () {
      // Create algorithm with output that has no matching input
      final algo1 = MockAlgorithmRouting(
        mockAlgorithmId: 'algo1',
        mockIndex: 0,
        inputPorts: [],
        outputPorts: [
          Port(
            id: 'algo1_output_1',
            name: 'Output 1',
            type: PortType.audio,
            direction: PortDirection.output,
            metadata: {
              'busValue': 21, // Aux bus A1
              'busParam': 'output_bus',
              'parameterNumber': 30,
            },
          ),
        ],
      );

      final connections = ConnectionDiscoveryService.discoverConnections([algo1]);

      // Should create one partial connection
      final partialConnections = connections.where((c) => c.isPartial).toList();
      expect(partialConnections, hasLength(1));

      final connection = partialConnections.first;
      expect(connection.connectionType, equals(ConnectionType.partialOutputToBus));
      expect(connection.sourcePortId, equals('algo1_output_1'));
      expect(connection.destinationPortId, equals('bus_21_endpoint'));
      expect(connection.busNumber, equals(21));
      expect(connection.busLabel, equals('A1'));
      expect(connection.isPartial, isTrue);
    });

    test('should create partial connections for unmatched inputs', () {
      // Create algorithm with input that has no matching output
      final algo1 = MockAlgorithmRouting(
        mockAlgorithmId: 'algo1',
        mockIndex: 0,
        inputPorts: [
          Port(
            id: 'algo1_input_1',
            name: 'Input 1',
            type: PortType.cv,
            direction: PortDirection.input,
            metadata: {
              'busValue': 15, // Output bus O3
              'busParam': 'input_bus',
              'parameterNumber': 20,
            },
          ),
        ],
        outputPorts: [],
      );

      final connections = ConnectionDiscoveryService.discoverConnections([algo1]);

      // Should create one partial connection
      final partialConnections = connections.where((c) => c.isPartial).toList();
      expect(partialConnections, hasLength(1));

      final connection = partialConnections.first;
      expect(connection.connectionType, equals(ConnectionType.partialBusToInput));
      expect(connection.sourcePortId, equals('bus_15_endpoint'));
      expect(connection.destinationPortId, equals('algo1_input_1'));
      expect(connection.busNumber, equals(15));
      expect(connection.busLabel, equals('O3'));
      expect(connection.isPartial, isTrue);
    });

    test('should create hardware input connections for bus 1-12', () {
      // Create algorithm with input on hardware input bus
      final algo1 = MockAlgorithmRouting(
        mockAlgorithmId: 'algo1',
        mockIndex: 0,
        inputPorts: [
          Port(
            id: 'algo1_input_1',
            name: 'Input 1',
            type: PortType.audio,
            direction: PortDirection.input,
            metadata: {
              'busValue': 3, // Hardware input I3
              'busParam': 'input_bus',
              'parameterNumber': 20,
            },
          ),
        ],
        outputPorts: [],
      );

      final connections = ConnectionDiscoveryService.discoverConnections([algo1]);

      // Should create one hardware input connection
      final hwConnections = connections.where((c) => 
        c.connectionType == ConnectionType.hardwareInput
      ).toList();
      expect(hwConnections, hasLength(1));

      final connection = hwConnections.first;
      expect(connection.sourcePortId, equals('hw_in_3'));
      expect(connection.destinationPortId, equals('algo1_input_1'));
      expect(connection.busNumber, equals(3));
      expect(connection.isPartial, isFalse);
    });

    test('should create hardware output connections for bus 13-20', () {
      // Create algorithm with output on hardware output bus
      final algo1 = MockAlgorithmRouting(
        mockAlgorithmId: 'algo1',
        mockIndex: 0,
        inputPorts: [],
        outputPorts: [
          Port(
            id: 'algo1_output_1',
            name: 'Output 1',
            type: PortType.audio,
            direction: PortDirection.output,
            metadata: {
              'busValue': 15, // Hardware output O3
              'busParam': 'output_bus',
              'parameterNumber': 30,
            },
            outputMode: OutputMode.replace,
          ),
        ],
      );

      final connections = ConnectionDiscoveryService.discoverConnections([algo1]);

      // Should create one hardware output connection
      final hwConnections = connections.where((c) => 
        c.connectionType == ConnectionType.hardwareOutput
      ).toList();
      expect(hwConnections, hasLength(1));

      final connection = hwConnections.first;
      expect(connection.sourcePortId, equals('algo1_output_1'));
      expect(connection.destinationPortId, equals('hw_out_3'));
      expect(connection.busNumber, equals(15));
      expect(connection.outputMode, equals(OutputMode.replace));
      expect(connection.isPartial, isFalse);
    });

    test('should ignore ports with zero bus values', () {
      // Create algorithm with zero bus value (unconnected)
      final algo1 = MockAlgorithmRouting(
        mockAlgorithmId: 'algo1',
        mockIndex: 0,
        inputPorts: [
          Port(
            id: 'algo1_input_1',
            name: 'Input 1',
            type: PortType.audio,
            direction: PortDirection.input,
            metadata: {
              'busValue': 0, // Zero means unconnected
              'busParam': 'input_bus',
              'parameterNumber': 20,
            },
          ),
        ],
        outputPorts: [
          Port(
            id: 'algo1_output_1',
            name: 'Output 1',
            type: PortType.audio,
            direction: PortDirection.output,
            metadata: {
              'busValue': 0, // Zero means unconnected
              'busParam': 'output_bus',
              'parameterNumber': 30,
            },
          ),
        ],
      );

      final connections = ConnectionDiscoveryService.discoverConnections([algo1]);

      // Should create no connections for zero bus values
      expect(connections, isEmpty);
    });

    test('should generate correct bus labels for different bus ranges', () {
      // Test different bus ranges
      final testCases = [
        // Input buses (1-12)
        {'busValue': 1, 'expectedLabel': 'I1'},
        {'busValue': 12, 'expectedLabel': 'I12'},
        // Output buses (13-20) 
        {'busValue': 13, 'expectedLabel': 'O1'},
        {'busValue': 20, 'expectedLabel': 'O8'},
        // Aux buses (21-28)
        {'busValue': 21, 'expectedLabel': 'A1'},
        {'busValue': 28, 'expectedLabel': 'A8'},
      ];

      for (final testCase in testCases) {
        final busValue = testCase['busValue'] as int;
        final expectedLabel = testCase['expectedLabel'] as String;

        final algo = MockAlgorithmRouting(
          mockAlgorithmId: 'test_algo',
          mockIndex: 0,
          inputPorts: [],
          outputPorts: [
            Port(
              id: 'test_output',
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

        final connections = ConnectionDiscoveryService.discoverConnections([algo]);
        
        // For hardware buses, check hardware connections
        if (busValue >= 13 && busValue <= 20) {
          final hwConnection = connections.firstWhere(
            (c) => c.connectionType == ConnectionType.hardwareOutput
          );
          expect(hwConnection.busNumber, equals(busValue));
        } else {
          // For other buses, check partial connections
          final partialConnection = connections.firstWhere((c) => c.isPartial);
          expect(partialConnection.busLabel, equals(expectedLabel),
            reason: 'Bus $busValue should generate label $expectedLabel');
        }
      }
    });

    test('should handle complex scenarios with mixed connection types', () {
      // Create a complex scenario with multiple algorithms and mixed connection types
      final algo1 = MockAlgorithmRouting(
        mockAlgorithmId: 'algo1',
        mockIndex: 0,
        inputPorts: [
          Port(
            id: 'algo1_input_hw',
            name: 'HW Input',
            type: PortType.audio,
            direction: PortDirection.input,
            metadata: {
              'busValue': 1, // Hardware input
              'busParam': 'input_bus',
              'parameterNumber': 20,
            },
          ),
        ],
        outputPorts: [
          Port(
            id: 'algo1_output_to_algo2',
            name: 'To Algo2',
            type: PortType.audio,
            direction: PortDirection.output,
            metadata: {
              'busValue': 5, // Connects to algo2
              'busParam': 'output_bus',
              'parameterNumber': 30,
            },
          ),
          Port(
            id: 'algo1_output_unconnected',
            name: 'Unconnected',
            type: PortType.cv,
            direction: PortDirection.output,
            metadata: {
              'busValue': 21, // Partial connection to A1
              'busParam': 'output_bus_2',
              'parameterNumber': 31,
            },
          ),
        ],
      );

      final algo2 = MockAlgorithmRouting(
        mockAlgorithmId: 'algo2',
        mockIndex: 1,
        inputPorts: [
          Port(
            id: 'algo2_input_from_algo1',
            name: 'From Algo1',
            type: PortType.audio,
            direction: PortDirection.input,
            metadata: {
              'busValue': 5, // Connects from algo1
              'busParam': 'input_bus',
              'parameterNumber': 20,
            },
          ),
        ],
        outputPorts: [
          Port(
            id: 'algo2_output_hw',
            name: 'HW Output',
            type: PortType.audio,
            direction: PortDirection.output,
            metadata: {
              'busValue': 13, // Hardware output O1
              'busParam': 'output_bus',
              'parameterNumber': 30,
            },
            outputMode: OutputMode.add,
          ),
        ],
      );

      final connections = ConnectionDiscoveryService.discoverConnections([algo1, algo2]);

      // Should have 4 connections: hw input, algo-to-algo, hw output, partial
      expect(connections, hasLength(4));

      // Check hardware input connection
      final hwInput = connections.firstWhere((c) => 
        c.connectionType == ConnectionType.hardwareInput
      );
      expect(hwInput.sourcePortId, equals('hw_in_1'));
      expect(hwInput.destinationPortId, equals('algo1_input_hw'));

      // Check algorithm-to-algorithm connection
      final algoConnection = connections.firstWhere((c) => 
        c.connectionType == ConnectionType.algorithmToAlgorithm
      );
      expect(algoConnection.sourcePortId, equals('algo1_output_to_algo2'));
      expect(algoConnection.destinationPortId, equals('algo2_input_from_algo1'));

      // Check hardware output connection
      final hwOutput = connections.firstWhere((c) => 
        c.connectionType == ConnectionType.hardwareOutput
      );
      expect(hwOutput.sourcePortId, equals('algo2_output_hw'));
      expect(hwOutput.destinationPortId, equals('hw_out_1'));
      expect(hwOutput.outputMode, equals(OutputMode.add));

      // Check partial connection
      final partialConnection = connections.firstWhere((c) => c.isPartial);
      expect(partialConnection.connectionType, equals(ConnectionType.partialOutputToBus));
      expect(partialConnection.sourcePortId, equals('algo1_output_unconnected'));
      expect(partialConnection.busLabel, equals('A1'));
    });

    test('should detect backward edge connections correctly', () {
      // Create two algorithms where later algorithm connects to earlier algorithm
      final algo1 = MockAlgorithmRouting(
        mockAlgorithmId: 'algo1',
        mockIndex: 0,
        inputPorts: [
          Port(
            id: 'algo1_input_1',
            name: 'Input 1',
            type: PortType.audio,
            direction: PortDirection.input,
            metadata: {
              'busValue': 5,
              'busParam': 'input_bus',
              'parameterNumber': 20,
            },
          ),
        ],
        outputPorts: [],
      );

      final algo2 = MockAlgorithmRouting(
        mockAlgorithmId: 'algo2',
        mockIndex: 1, // Later algorithm
        inputPorts: [],
        outputPorts: [
          Port(
            id: 'algo2_output_1',
            name: 'Output 1',
            type: PortType.audio,
            direction: PortDirection.output,
            metadata: {
              'busValue': 5, // Same bus as algo1 input
              'busParam': 'output_bus',
              'parameterNumber': 30,
            },
          ),
        ],
      );

      final connections = ConnectionDiscoveryService.discoverConnections([algo1, algo2]);

      // Should create one algorithm connection with backward edge flag
      final algoConnections = connections.where((c) => 
        c.connectionType == ConnectionType.algorithmToAlgorithm
      ).toList();
      expect(algoConnections, hasLength(1));

      final connection = algoConnections.first;
      expect(connection.isBackwardEdge, isTrue);
      expect(connection.sourcePortId, equals('algo2_output_1'));
      expect(connection.destinationPortId, equals('algo1_input_1'));
    });

    test('should handle missing bus metadata gracefully', () {
      // Create algorithm with port missing bus metadata
      final algo1 = MockAlgorithmRouting(
        mockAlgorithmId: 'algo1',
        mockIndex: 0,
        inputPorts: [],
        outputPorts: [
          Port(
            id: 'algo1_output_1',
            name: 'Output 1',
            type: PortType.audio,
            direction: PortDirection.output,
            metadata: {
              // No busValue - should be skipped
              'parameterNumber': 30,
            },
          ),
        ],
      );

      final connections = ConnectionDiscoveryService.discoverConnections([algo1]);

      // Should create no connections when bus metadata is missing
      expect(connections, isEmpty);
    });
  });
}