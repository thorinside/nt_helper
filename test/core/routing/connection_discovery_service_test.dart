import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/core/routing/connection_discovery_service.dart';
import 'package:nt_helper/core/routing/algorithm_routing.dart';
import 'package:nt_helper/core/routing/models/port.dart';
import 'package:nt_helper/core/routing/models/connection.dart';
import 'package:nt_helper/core/routing/models/routing_state.dart';
import 'package:nt_helper/cubit/disting_cubit.dart';
import 'package:nt_helper/domain/disting_nt_sysex.dart';

// Mock routing implementation for testing
class _TestRouting extends AlgorithmRouting {
  final List<Port> _inputPorts;
  final List<Port> _outputPorts;
  RoutingState _state = const RoutingState();

  _TestRouting({
    required List<Port> inputPorts,
    required List<Port> outputPorts,
    String? algorithmUuid,
  })  : _inputPorts = inputPorts,
        _outputPorts = outputPorts,
        super(algorithmUuid: algorithmUuid);

  @override
  RoutingState get state => _state;

  @override
  List<Connection> get connections => _state.connections;

  @override
  List<Port> get inputPorts => _inputPorts;

  @override
  List<Port> get outputPorts => _outputPorts;

  @override
  List<Port> generateInputPorts() => inputPorts;

  @override
  List<Port> generateOutputPorts() => outputPorts;

  @override
  bool validateConnection(Port source, Port destination) => true;

  @override
  void updateState(RoutingState newState) {
    _state = newState;
  }
}

void main() {
  group('ConnectionDiscoveryService Duplicate Algorithm Tests', () {
    test('should handle duplicate algorithms with stable IDs', () {
      // Create test data for duplicate algorithms
      final algorithm = Algorithm(
        algorithmIndex: 100,
        guid: 'duplicate_algo',
        name: 'Duplicate Test Algorithm',
      );

      // Create parameter definitions for bus routing
      final parameters = [
        ParameterInfo(
          algorithmIndex: 100,
          parameterNumber: 1,
          name: 'Input 1',
          unit: 1, // enum type for bus parameter
          min: 0,
          max: 27,
          defaultValue: 0,
          powerOfTen: 0,
        ),
        ParameterInfo(
          algorithmIndex: 100,
          parameterNumber: 2,
          name: 'Output 1',
          unit: 1,
          min: 0,
          max: 27,
          defaultValue: 0,
          powerOfTen: 0,
        ),
      ];

      // Create two slots with the same algorithm
      final slot1 = Slot(
        algorithm: algorithm,
        routing: RoutingInfo(algorithmIndex: 100, routingInfo: []),
        pages: ParameterPages(algorithmIndex: 100, pages: []),
        parameters: parameters,
        values: [
          ParameterValue(algorithmIndex: 100, parameterNumber: 1, value: 3), // Bus 3
          ParameterValue(algorithmIndex: 100, parameterNumber: 2, value: 15), // Bus 15
        ],
        enums: [],
        mappings: [],
        valueStrings: [],
      );

      final slot2 = Slot(
        algorithm: algorithm,
        routing: RoutingInfo(algorithmIndex: 100, routingInfo: []),
        pages: ParameterPages(algorithmIndex: 100, pages: []),
        parameters: parameters,
        values: [
          ParameterValue(algorithmIndex: 100, parameterNumber: 1, value: 4), // Bus 4
          ParameterValue(algorithmIndex: 100, parameterNumber: 2, value: 16), // Bus 16
        ],
        enums: [],
        mappings: [],
        valueStrings: [],
      );

      // Create AlgorithmRouting instances with stable IDs
      final routing1 = AlgorithmRouting.fromSlot(
        slot1,
        algorithmUuid: 'slot_0_duplicate_algo',
      );
      final routing2 = AlgorithmRouting.fromSlot(
        slot2,
        algorithmUuid: 'slot_1_duplicate_algo',
      );

      // This test should FAIL initially because ConnectionDiscoveryService
      // uses hashCode fallback instead of stable algorithmUuid
      // After the fix, it should PASS
      
      // Attempt to discover connections
      final connections = ConnectionDiscoveryService.discoverConnections([
        routing1,
        routing2,
      ]);

      // Verify that the service doesn't get stuck in an infinite loop
      // (The bug causes hashCode to be unstable, leading to mismatched port IDs)
      expect(connections, isNotNull);
      
      // Verify that both algorithms are properly identified
      // This will fail with the current implementation because hashCode changes
      final routing1Ports = routing1.inputPorts + routing1.outputPorts;
      final routing2Ports = routing2.inputPorts + routing2.outputPorts;
      
      // Check that port IDs use stable algorithm UUIDs
      for (final port in routing1Ports) {
        expect(
          port.id,
          contains('slot_0_duplicate_algo'),
          reason: 'Port ID should contain stable algorithm UUID for slot 0',
        );
      }
      
      for (final port in routing2Ports) {
        expect(
          port.id,
          contains('slot_1_duplicate_algo'),
          reason: 'Port ID should contain stable algorithm UUID for slot 1',
        );
      }
    });

    test('should maintain unique connections for duplicate algorithms', () {
      // Create a more complex scenario with shared buses
      final algorithm = Algorithm(
        algorithmIndex: 101,
        guid: 'multi_instance',
        name: 'Multi Instance Algorithm',
      );

      final parameters = [
        ParameterInfo(
          algorithmIndex: 101,
          parameterNumber: 1,
          name: 'Input A',
          unit: 1,
          min: 0,
          max: 27,
          defaultValue: 0,
          powerOfTen: 0,
        ),
        ParameterInfo(
          algorithmIndex: 101,
          parameterNumber: 2,
          name: 'Output X',
          unit: 1,
          min: 0,
          max: 27,
          defaultValue: 0,
          powerOfTen: 0,
        ),
      ];

      // Slot 1 outputs to bus 20, Slot 2 reads from bus 20
      final slot1 = Slot(
        algorithm: algorithm,
        routing: RoutingInfo(algorithmIndex: 101, routingInfo: []),
        pages: ParameterPages(algorithmIndex: 101, pages: []),
        parameters: parameters,
        values: [
          ParameterValue(algorithmIndex: 101, parameterNumber: 1, value: 1), // Hardware input
          ParameterValue(algorithmIndex: 101, parameterNumber: 2, value: 20), // Internal bus
        ],
        enums: [],
        mappings: [],
        valueStrings: [],
      );

      final slot2 = Slot(
        algorithm: algorithm,
        routing: RoutingInfo(algorithmIndex: 101, routingInfo: []),
        pages: ParameterPages(algorithmIndex: 101, pages: []),
        parameters: parameters,
        values: [
          ParameterValue(algorithmIndex: 101, parameterNumber: 1, value: 20), // From slot1
          ParameterValue(algorithmIndex: 101, parameterNumber: 2, value: 13), // Hardware output
        ],
        enums: [],
        mappings: [],
        valueStrings: [],
      );

      final routing1 = AlgorithmRouting.fromSlot(
        slot1,
        algorithmUuid: 'instance_1',
      );
      final routing2 = AlgorithmRouting.fromSlot(
        slot2,
        algorithmUuid: 'instance_2',
      );

      final connections = ConnectionDiscoveryService.discoverConnections([
        routing1,
        routing2,
      ]);

      // Should find the connection between the two instances via bus 20
      // Look for algorithm-to-algorithm connections
      final algorithmConnections = connections.where((c) =>
        c.connectionType == ConnectionType.algorithmToAlgorithm
      ).toList();

      expect(
        algorithmConnections,
        isNotEmpty,
        reason: 'Should find connection between duplicate algorithm instances',
      );

      // Verify the connection is between the correct instances
      // The connection should be from instance_1's output to instance_2's input
      if (algorithmConnections.isNotEmpty) {
        final connection = algorithmConnections.first;
        // Source should be an output from instance 1, destination should be input to instance 2
        expect(
          connection.sourcePortId,
          contains('instance_1'),
          reason: 'Source should be from instance 1',
        );
        expect(
          connection.destinationPortId,
          contains('instance_2'),
          reason: 'Destination should be to instance 2',
        );
      }
    });

    test('should complete discovery quickly with multiple duplicates', () {
      // Performance test: should handle 8 duplicate algorithms in < 100ms
      final algorithm = Algorithm(
        algorithmIndex: 102,
        guid: 'performance_test',
        name: 'Performance Test',
      );

      final parameters = [
        ParameterInfo(
          algorithmIndex: 102,
          parameterNumber: 1,
          name: 'Input',
          unit: 1,
          min: 0,
          max: 27,
          defaultValue: 0,
          powerOfTen: 0,
        ),
        ParameterInfo(
          algorithmIndex: 102,
          parameterNumber: 2,
          name: 'Output',
          unit: 1,
          min: 0,
          max: 27,
          defaultValue: 0,
          powerOfTen: 0,
        ),
      ];

      final routings = <AlgorithmRouting>[];
      for (int i = 0; i < 8; i++) {
        final slot = Slot(
          algorithm: algorithm,
          routing: RoutingInfo(algorithmIndex: 102, routingInfo: []),
          pages: ParameterPages(algorithmIndex: 102, pages: []),
          parameters: parameters,
          values: [
            ParameterValue(algorithmIndex: 102, parameterNumber: 1, value: i + 1),
            ParameterValue(algorithmIndex: 102, parameterNumber: 2, value: i + 13),
          ],
          enums: [],
          mappings: [],
          valueStrings: [],
        );

        routings.add(
          AlgorithmRouting.fromSlot(
            slot,
            algorithmUuid: 'instance_$i',
          ),
        );
      }

      final stopwatch = Stopwatch()..start();
      final connections = ConnectionDiscoveryService.discoverConnections(routings);
      stopwatch.stop();

      expect(connections, isNotNull);
      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(100),
        reason: 'Discovery should complete in less than 100ms for 8 duplicates',
      );
    });
  });
}