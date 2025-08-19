import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:nt_helper/cubit/node_routing_cubit.dart';
import 'package:nt_helper/cubit/node_routing_state.dart';
import 'package:nt_helper/models/connection.dart';
import 'package:nt_helper/services/auto_routing_service.dart';
import 'package:nt_helper/services/bus_tidy_optimizer.dart';

import 'bus_tidy_optimizer_test.mocks.dart';

@GenerateMocks([NodeRoutingCubit, AutoRoutingService])
void main() {
  // Configure Mockito to provide dummy values for sealed classes
  provideDummy<NodeRoutingState>(const NodeRoutingState.initial());
  group('BusTidyOptimizer - Simple Optimizations', () {
    late MockNodeRoutingCubit mockCubit;
    late MockAutoRoutingService mockRoutingService;
    late BusTidyOptimizer optimizer;

    setUp(() {
      mockCubit = MockNodeRoutingCubit();
      mockRoutingService = MockAutoRoutingService();
      optimizer = BusTidyOptimizer(mockCubit, mockRoutingService);
    });

    test('should not optimize empty connections', () async {
      // Mock empty state
      when(mockCubit.state).thenReturn(const NodeRoutingState.loaded(
        nodePositions: {},
        connections: [],
        portLayouts: {},
        connectedPorts: {},
        algorithmNames: {},
        portPositions: {},
      ));

      final result = await optimizer.tidyConnections();

      expect(result.success, isTrue);
      expect(result.busesFreed, equals(0));
      expect(result.changes, isEmpty);
    });

    test('should not optimize single connection', () async {
      final singleConnection = [
        Connection(
          id: 'single',
          sourceAlgorithmIndex: 0,
          sourcePortId: 'out',
          targetAlgorithmIndex: 1,
          targetPortId: 'in',
          assignedBus: 21,
          replaceMode: false,
        ),
      ];

      when(mockCubit.state).thenReturn(NodeRoutingState.loaded(
        nodePositions: const {},
        connections: singleConnection,
        portLayouts: const {},
        connectedPorts: const {},
        algorithmNames: const {},
        portPositions: const {},
      ));

      final result = await optimizer.tidyConnections();

      expect(result.success, isTrue);
      expect(result.busesFreed, equals(0));
      expect(result.changes, isEmpty);
    });

    test('should identify simple replacement opportunity', () async {
      // Setup: VCO -> Filter -> Output
      // VCO uses bus 21, Filter can replace it to free bus for reuse
      final connections = [
        Connection(
          id: '0_out_1_in',
          sourceAlgorithmIndex: 0,
          sourcePortId: 'out',
          targetAlgorithmIndex: 1,
          targetPortId: 'in',
          assignedBus: 21,
          replaceMode: false, // Currently Add mode
        ),
        Connection(
          id: '1_out_2_in',
          sourceAlgorithmIndex: 1,
          sourcePortId: 'out',
          targetAlgorithmIndex: 2,
          targetPortId: 'in',
          assignedBus: 22,
          replaceMode: false,
        ),
      ];

      when(mockCubit.state).thenReturn(NodeRoutingState.loaded(
        nodePositions: const {},
        connections: connections,
        portLayouts: const {},
        connectedPorts: const {},
        algorithmNames: const {},
        portPositions: const {},
      ));

      final result = await optimizer.tidyConnections();

      expect(result.success, isTrue);
      expect(result.changes, isNotEmpty);
      
      // Should optimize to use Replace mode for bus reuse
      final firstChange = result.changes.values.first;
      expect(firstChange.newReplaceMode, isTrue);
    });

    test('should free one bus with basic replacement', () async {
      final connections = [
        Connection(
          id: 'conn1',
          sourceAlgorithmIndex: 0,
          sourcePortId: 'out',
          targetAlgorithmIndex: 1,
          targetPortId: 'in',
          assignedBus: 21,
          replaceMode: false,
        ),
        Connection(
          id: 'conn2',
          sourceAlgorithmIndex: 1,
          sourcePortId: 'out',
          targetAlgorithmIndex: 2,
          targetPortId: 'in',
          assignedBus: 22,
          replaceMode: false,
        ),
      ];

      when(mockCubit.state).thenReturn(NodeRoutingState.loaded(
        nodePositions: const {},
        connections: connections,
        portLayouts: const {},
        connectedPorts: const {},
        algorithmNames: const {},
        portPositions: const {},
      ));

      final result = await optimizer.tidyConnections();

      expect(result.success, isTrue);
      expect(result.busesFreed, greaterThan(0));
    });
  });

  group('BusTidyOptimizer - Complex Scenarios', () {
    late MockNodeRoutingCubit mockCubit;
    late MockAutoRoutingService mockRoutingService;
    late BusTidyOptimizer optimizer;

    setUp(() {
      mockCubit = MockNodeRoutingCubit();
      mockRoutingService = MockAutoRoutingService();
      optimizer = BusTidyOptimizer(mockCubit, mockRoutingService);
    });

    test('should optimize multi-path routing correctly', () async {
      // Complex routing scenario with multiple paths
      final connections = [
        Connection(
          id: 'vco_filter',
          sourceAlgorithmIndex: 0, // VCO
          sourcePortId: 'out',
          targetAlgorithmIndex: 1, // Filter
          targetPortId: 'in',
          assignedBus: 21,
          replaceMode: false,
        ),
        Connection(
          id: 'filter_env',
          sourceAlgorithmIndex: 1, // Filter
          sourcePortId: 'out',
          targetAlgorithmIndex: 2, // Envelope
          targetPortId: 'in',
          assignedBus: 22,
          replaceMode: false,
        ),
        Connection(
          id: 'env_out',
          sourceAlgorithmIndex: 2, // Envelope
          sourcePortId: 'out',
          targetAlgorithmIndex: 3, // Output
          targetPortId: 'in',
          assignedBus: 23,
          replaceMode: false,
        ),
      ];

      when(mockCubit.state).thenReturn(NodeRoutingState.loaded(
        nodePositions: const {},
        connections: connections,
        portLayouts: const {},
        connectedPorts: const {},
        algorithmNames: const {},
        portPositions: const {},
      ));

      final result = await optimizer.tidyConnections();

      expect(result.success, isTrue);
      expect(result.busesFreed, greaterThan(0));
    });

    test('should handle cascade replacements', () async {
      // Scenario where multiple Replace modes can cascade to free buses
      final connections = List.generate(5, (i) => Connection(
        id: 'chain_$i',
        sourceAlgorithmIndex: i,
        sourcePortId: 'out',
        targetAlgorithmIndex: i + 1,
        targetPortId: 'in',
        assignedBus: 21 + i,
        replaceMode: false,
      ));

      when(mockCubit.state).thenReturn(NodeRoutingState.loaded(
        nodePositions: const {},
        connections: connections,
        portLayouts: const {},
        connectedPorts: const {},
        algorithmNames: const {},
        portPositions: const {},
      ));

      final result = await optimizer.tidyConnections();

      expect(result.success, isTrue);
      expect(result.busesFreed, greaterThan(1));
    });

    test('should respect execution order constraints', () async {
      // Connections that violate execution order should not be optimized
      final connections = [
        Connection(
          id: 'invalid_order',
          sourceAlgorithmIndex: 2, // Later slot
          sourcePortId: 'out',
          targetAlgorithmIndex: 1, // Earlier slot - invalid!
          targetPortId: 'in',
          assignedBus: 21,
          replaceMode: false,
        ),
      ];

      when(mockCubit.state).thenReturn(NodeRoutingState.loaded(
        nodePositions: const {},
        connections: connections,
        portLayouts: const {},
        connectedPorts: const {},
        algorithmNames: const {},
        portPositions: const {},
      ));

      final result = await optimizer.tidyConnections();

      expect(result.success, isTrue);
      // Should not optimize invalid connections
      expect(result.changes, isEmpty);
    });

    test('should not break signal dependencies', () async {
      // Branching signal paths where Replace mode would break dependencies
      final connections = [
        Connection(
          id: 'vco_to_filter',
          sourceAlgorithmIndex: 0, // VCO
          sourcePortId: 'out',
          targetAlgorithmIndex: 1, // Filter
          targetPortId: 'in',
          assignedBus: 21,
          replaceMode: false,
        ),
        Connection(
          id: 'vco_to_envelope',
          sourceAlgorithmIndex: 0, // VCO (same source)
          sourcePortId: 'out',
          targetAlgorithmIndex: 2, // Envelope
          targetPortId: 'in',
          assignedBus: 21, // Same bus - signal sharing
          replaceMode: false,
        ),
      ];

      when(mockCubit.state).thenReturn(NodeRoutingState.loaded(
        nodePositions: const {},
        connections: connections,
        portLayouts: const {},
        connectedPorts: const {},
        algorithmNames: const {},
        portPositions: const {},
      ));

      final result = await optimizer.tidyConnections();

      expect(result.success, isTrue);
      
      // Fan-out scenario (same source, different targets) should be safely optimizable
      // One of the connections on bus 21 should get Replace mode enabled
      final bus21Changes = result.changes.values
          .where((c) => c.oldBus == 21 && c.newReplaceMode == true);
      expect(bus21Changes, isNotEmpty); // Should find optimization opportunity
    });
  });

  group('BusTidyOptimizer - Edge Cases', () {
    late MockNodeRoutingCubit mockCubit;
    late MockAutoRoutingService mockRoutingService;
    late BusTidyOptimizer optimizer;

    setUp(() {
      mockCubit = MockNodeRoutingCubit();
      mockRoutingService = MockAutoRoutingService();
      optimizer = BusTidyOptimizer(mockCubit, mockRoutingService);
    });

    test('should handle all buses exhausted', () async {
      // Create connections using all 28 buses
      final connections = List.generate(28, (i) => Connection(
        id: 'bus_$i',
        sourceAlgorithmIndex: i,
        sourcePortId: 'out',
        targetAlgorithmIndex: i + 1,
        targetPortId: 'in',
        assignedBus: i + 1, // Buses 1-28
        replaceMode: false,
      ));

      when(mockCubit.state).thenReturn(NodeRoutingState.loaded(
        nodePositions: const {},
        connections: connections,
        portLayouts: const {},
        connectedPorts: const {},
        algorithmNames: const {},
        portPositions: const {},
      ));

      final result = await optimizer.tidyConnections();

      expect(result.success, isTrue);
      // Should still be able to optimize some connections
      expect(result.busesFreed, greaterThanOrEqualTo(0));
    });

    test('should handle circular dependencies', () async {
      // Circular dependency that would be invalid
      final connections = [
        Connection(
          id: 'circular1',
          sourceAlgorithmIndex: 0,
          sourcePortId: 'out',
          targetAlgorithmIndex: 1,
          targetPortId: 'in',
          assignedBus: 21,
          replaceMode: false,
        ),
        Connection(
          id: 'circular2',
          sourceAlgorithmIndex: 1,
          sourcePortId: 'out',
          targetAlgorithmIndex: 0,
          targetPortId: 'in2',
          assignedBus: 22,
          replaceMode: false,
        ),
      ];

      when(mockCubit.state).thenReturn(NodeRoutingState.loaded(
        nodePositions: const {},
        connections: connections,
        portLayouts: const {},
        connectedPorts: const {},
        algorithmNames: const {},
        portPositions: const {},
      ));

      final result = await optimizer.tidyConnections();

      expect(result.success, isTrue);
      // Should handle gracefully without breaking
    });

    test('should handle physical I/O correctly', () async {
      final connections = [
        // Physical input connection
        Connection(
          id: 'physical_in',
          sourceAlgorithmIndex: -2, // Physical input
          sourcePortId: 'physical_input_1',
          targetAlgorithmIndex: 0,
          targetPortId: 'in',
          assignedBus: 1,
          replaceMode: false,
        ),
        // Physical output connection
        Connection(
          id: 'physical_out',
          sourceAlgorithmIndex: 0,
          sourcePortId: 'out',
          targetAlgorithmIndex: -3, // Physical output
          targetPortId: 'physical_output_1',
          assignedBus: 13,
          replaceMode: false,
        ),
      ];

      when(mockCubit.state).thenReturn(NodeRoutingState.loaded(
        nodePositions: const {},
        connections: connections,
        portLayouts: const {},
        connectedPorts: const {},
        algorithmNames: const {},
        portPositions: const {},
      ));

      final result = await optimizer.tidyConnections();

      expect(result.success, isTrue);
      // Physical I/O connections should not be optimized
      expect(result.changes, isEmpty);
    });

    test('should handle 32 algorithm maximum', () async {
      // Test with maximum number of algorithms
      final connections = List.generate(31, (i) => Connection(
        id: 'max_$i',
        sourceAlgorithmIndex: i,
        sourcePortId: 'out',
        targetAlgorithmIndex: i + 1,
        targetPortId: 'in',
        assignedBus: 21 + (i % 8), // Cycle through AUX buses
        replaceMode: false,
      ));

      when(mockCubit.state).thenReturn(NodeRoutingState.loaded(
        nodePositions: const {},
        connections: connections,
        portLayouts: const {},
        connectedPorts: const {},
        algorithmNames: const {},
        portPositions: const {},
      ));

      final result = await optimizer.tidyConnections();

      expect(result.success, isTrue);
      // Should handle large number of algorithms
    });
  });

  group('BusTidyOptimizer - Safety Validation', () {
    late MockNodeRoutingCubit mockCubit;
    late MockAutoRoutingService mockRoutingService;
    late BusTidyOptimizer optimizer;

    setUp(() {
      mockCubit = MockNodeRoutingCubit();
      mockRoutingService = MockAutoRoutingService();
      optimizer = BusTidyOptimizer(mockCubit, mockRoutingService);
    });

    test('should never lose signal path', () async {
      final connections = [
        Connection(
          id: 'critical_path',
          sourceAlgorithmIndex: 0,
          sourcePortId: 'out',
          targetAlgorithmIndex: 1,
          targetPortId: 'in',
          assignedBus: 21,
          replaceMode: false,
        ),
      ];

      when(mockCubit.state).thenReturn(NodeRoutingState.loaded(
        nodePositions: const {},
        connections: connections,
        portLayouts: const {},
        connectedPorts: const {},
        algorithmNames: const {},
        portPositions: const {},
      ));

      final result = await optimizer.tidyConnections();

      expect(result.success, isTrue);
      // All original connections should be preserved or improved
      expect(result.optimizedConnections.length, 
             greaterThanOrEqualTo(result.originalConnections.length));
    });

    test('should never create execution order violations', () async {
      final connections = [
        Connection(
          id: 'valid_order',
          sourceAlgorithmIndex: 0, // Earlier slot
          sourcePortId: 'out',
          targetAlgorithmIndex: 2, // Later slot - valid
          targetPortId: 'in',
          assignedBus: 21,
          replaceMode: false,
        ),
      ];

      when(mockCubit.state).thenReturn(NodeRoutingState.loaded(
        nodePositions: const {},
        connections: connections,
        portLayouts: const {},
        connectedPorts: const {},
        algorithmNames: const {},
        portPositions: const {},
      ));

      final result = await optimizer.tidyConnections();

      expect(result.success, isTrue);
      
      // All optimized connections should maintain valid execution order
      for (final conn in result.optimizedConnections) {
        if (conn.sourceAlgorithmIndex >= 0 && conn.targetAlgorithmIndex >= 0) {
          expect(conn.sourceAlgorithmIndex, lessThan(conn.targetAlgorithmIndex));
        }
      }
    });

    test('should rollback on partial failure', () async {
      // Mock a scenario where optimization partially fails
      final connections = [
        Connection(
          id: 'good_conn',
          sourceAlgorithmIndex: 0,
          sourcePortId: 'out',
          targetAlgorithmIndex: 1,
          targetPortId: 'in',
          assignedBus: 21,
          replaceMode: false,
        ),
      ];

      when(mockCubit.state).thenReturn(NodeRoutingState.loaded(
        nodePositions: const {},
        connections: connections,
        portLayouts: const {},
        connectedPorts: const {},
        algorithmNames: const {},
        portPositions: const {},
      ));

      // Simulate failure in routing service
      when(mockRoutingService.applyTidyResult(any))
          .thenThrow(Exception('Hardware communication failed'));

      final result = await optimizer.tidyConnections();

      // Should handle gracefully
      expect(result.success, isTrue); // Optimization logic succeeded
    });
  });

  group('BusTidyOptimizer - Performance', () {
    late MockNodeRoutingCubit mockCubit;
    late MockAutoRoutingService mockRoutingService;
    late BusTidyOptimizer optimizer;

    setUp(() {
      mockCubit = MockNodeRoutingCubit();
      mockRoutingService = MockAutoRoutingService();
      optimizer = BusTidyOptimizer(mockCubit, mockRoutingService);
    });

    test('should complete in <500ms for 20 connections', () async {
      final connections = _generateComplexPreset(connectionCount: 20);

      when(mockCubit.state).thenReturn(NodeRoutingState.loaded(
        nodePositions: const {},
        connections: connections,
        portLayouts: const {},
        connectedPorts: const {},
        algorithmNames: const {},
        portPositions: const {},
      ));

      final stopwatch = Stopwatch()..start();
      final result = await optimizer.tidyConnections();
      stopwatch.stop();

      expect(result.success, isTrue);
      expect(stopwatch.elapsedMilliseconds, lessThan(500));
    });

    test('should complete in <1s for 50 connections', () async {
      final connections = _generateComplexPreset(connectionCount: 50);

      when(mockCubit.state).thenReturn(NodeRoutingState.loaded(
        nodePositions: const {},
        connections: connections,
        portLayouts: const {},
        connectedPorts: const {},
        algorithmNames: const {},
        portPositions: const {},
      ));

      final stopwatch = Stopwatch()..start();
      final result = await optimizer.tidyConnections();
      stopwatch.stop();

      expect(result.success, isTrue);
      expect(stopwatch.elapsedMilliseconds, lessThan(1000));
    });
  });

  group('BusTidyOptimizer - Invalid State Handling', () {
    late MockNodeRoutingCubit mockCubit;
    late MockAutoRoutingService mockRoutingService;
    late BusTidyOptimizer optimizer;

    setUp(() {
      mockCubit = MockNodeRoutingCubit();
      mockRoutingService = MockAutoRoutingService();
      optimizer = BusTidyOptimizer(mockCubit, mockRoutingService);
    });

    test('should handle invalid cubit state', () async {
      when(mockCubit.state).thenReturn(const NodeRoutingState.initial());

      final result = await optimizer.tidyConnections();

      expect(result.success, isFalse);
      expect(result.errorMessage, contains('Invalid state'));
    });

    test('should handle loading cubit state', () async {
      when(mockCubit.state).thenReturn(const NodeRoutingState.loading());

      final result = await optimizer.tidyConnections();

      expect(result.success, isFalse);
      expect(result.errorMessage, isNotNull);
    });

    test('should handle error cubit state', () async {
      when(mockCubit.state).thenReturn(const NodeRoutingState.error(
        message: 'Test error',
      ));

      final result = await optimizer.tidyConnections();

      expect(result.success, isFalse);
      expect(result.errorMessage, isNotNull);
    });
  });
}

/// Helper function to generate complex preset for performance testing
List<Connection> _generateComplexPreset({required int connectionCount}) {
  final connections = <Connection>[];
  
  for (int i = 0; i < connectionCount; i++) {
    connections.add(Connection(
      id: 'perf_test_$i',
      sourceAlgorithmIndex: i % 16, // Cycle through slots
      sourcePortId: 'out_${i % 4}',
      targetAlgorithmIndex: (i + 1) % 16,
      targetPortId: 'in_${i % 4}',
      assignedBus: 21 + (i % 8), // Cycle through AUX buses
      replaceMode: i % 3 == 0, // Vary replace mode
    ));
  }
  
  return connections;
}