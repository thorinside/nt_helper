import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:nt_helper/cubit/disting_cubit.dart';
import 'package:nt_helper/cubit/node_routing_cubit.dart';
import 'package:nt_helper/cubit/node_routing_state.dart';
import 'package:nt_helper/domain/i_disting_midi_manager.dart';
import 'package:nt_helper/models/connection.dart';
import 'package:nt_helper/models/firmware_version.dart';
import 'package:nt_helper/models/node_position.dart';
import 'package:nt_helper/models/port_layout.dart';
import 'package:nt_helper/models/tidy_result.dart';
import 'package:nt_helper/services/algorithm_metadata_service.dart';
import 'package:nt_helper/services/auto_routing_service.dart';
import 'package:nt_helper/services/bus_tidy_optimizer.dart';
import 'package:nt_helper/services/node_positions_persistence_service.dart';

import 'tidy_routing_test.mocks.dart';

@GenerateMocks([DistingCubit, AlgorithmMetadataService, NodePositionsPersistenceService, AutoRoutingService, BusTidyOptimizer, IDistingMidiManager])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  // Configure Mockito to provide dummy values for sealed classes
  provideDummy<NodeRoutingState>(const NodeRoutingState.initial());
  provideDummy<DistingState>(const DistingState.initial());

  group('NodeRoutingCubit - Tidy Integration', () {
    late NodeRoutingCubit cubit;
    late MockDistingCubit mockDistingCubit;
    late MockAlgorithmMetadataService mockAlgorithmService;
    late MockNodePositionsPersistenceService mockPersistenceService;
    // late MockAutoRoutingService mockRoutingService; // Not used in current phase
    late MockBusTidyOptimizer mockOptimizer;

    setUp(() {
      mockDistingCubit = MockDistingCubit();
      mockAlgorithmService = MockAlgorithmMetadataService();
      mockPersistenceService = MockNodePositionsPersistenceService();
      // mockRoutingService = MockAutoRoutingService(); // Not used in current phase
      mockOptimizer = MockBusTidyOptimizer();
      
      // Mock the DistingCubit stream
      when(mockDistingCubit.stream).thenAnswer((_) => Stream.empty());
      when(mockDistingCubit.state).thenReturn(
        DistingState.synchronized(
          disting: MockIDistingMidiManager(),
          distingVersion: '1.0',
          firmwareVersion: FirmwareVersion('1.0.0'),
          presetName: 'Test Preset',
          algorithms: [],
          slots: [],
          unitStrings: [],
        ),
      );
      
      cubit = NodeRoutingCubit(
        mockDistingCubit, 
        mockAlgorithmService, 
        mockPersistenceService,
        busTidyOptimizer: mockOptimizer,
      );
    });

    test('should have tidy operation available when loaded', () {
      // Set up loaded state
      final connections = [
        Connection(
          id: 'test_conn',
          sourceAlgorithmIndex: 0,
          sourcePortId: 'out',
          targetAlgorithmIndex: 1,
          targetPortId: 'in',
          assignedBus: 21,
          replaceMode: false,
        ),
      ];

      cubit.emit(NodeRoutingState.loaded(
        nodePositions: const {},
        connections: connections,
        portLayouts: const {},
        connectedPorts: const {},
        algorithmNames: const {},
        portPositions: const {},
      ));

      expect(cubit.state, isA<NodeRoutingStateLoaded>());
      expect(cubit.canPerformTidy, isTrue);
    });

    test('should not allow tidy operation when not loaded', () {
      cubit.emit(const NodeRoutingState.loading());
      expect(cubit.canPerformTidy, isFalse);

      cubit.emit(const NodeRoutingState.initial());
      expect(cubit.canPerformTidy, isFalse);

      cubit.emit(const NodeRoutingState.error(message: 'Test error'));
      expect(cubit.canPerformTidy, isFalse);
    });

    test('should perform tidy operation successfully', () async {
      // Set up initial state
      final originalConnections = [
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

      cubit.emit(NodeRoutingState.loaded(
        nodePositions: const {},
        connections: originalConnections,
        portLayouts: const {},
        connectedPorts: const {},
        algorithmNames: const {},
        portPositions: const {},
      ));

      // Mock successful optimization
      final optimizedConnections = [
        originalConnections[0].copyWith(replaceMode: true),
        originalConnections[1],
      ];

      final tidyResult = TidyResult.success(
        originalConnections: originalConnections,
        optimizedConnections: optimizedConnections,
        busesFreed: 1,
        changes: {
          'conn1': BusChange(
            connectionId: 'conn1',
            oldBus: 21,
            newBus: 21,
            oldReplaceMode: false,
            newReplaceMode: true,
            reason: 'Optimization test',
          ),
        },
      );

      when(mockOptimizer.tidyConnections(any)).thenAnswer((_) async => tidyResult);

      // Perform tidy operation
      final result = await cubit.performTidy();

      expect(result.success, isTrue);
      expect(result.busesFreed, equals(1));
      
      // State should be updated with optimized connections
      final currentState = cubit.state as NodeRoutingStateLoaded;
      expect(currentState.connections, equals(optimizedConnections));
      expect(currentState.lastTidyResult, equals(tidyResult));
    });

    test('should handle tidy operation failure gracefully', () async {
      final connections = [
        Connection(
          id: 'test_conn',
          sourceAlgorithmIndex: 0,
          sourcePortId: 'out',
          targetAlgorithmIndex: 1,
          targetPortId: 'in',
          assignedBus: 21,
          replaceMode: false,
        ),
      ];

      cubit.emit(NodeRoutingState.loaded(
        nodePositions: const {},
        connections: connections,
        portLayouts: const {},
        connectedPorts: const {},
        algorithmNames: const {},
        portPositions: const {},
      ));

      // Mock failed optimization
      final failedResult = TidyResult.failed('Optimization failed');
      when(mockOptimizer.tidyConnections(any)).thenAnswer((_) async => failedResult);

      final result = await cubit.performTidy();

      expect(result.success, isFalse);
      expect(result.errorMessage, equals('Optimization failed'));
      
      // State should remain unchanged
      final currentState = cubit.state as NodeRoutingStateLoaded;
      expect(currentState.connections, equals(connections));
    });

    test('should track optimization statistics', () async {
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
      ];

      cubit.emit(NodeRoutingState.loaded(
        nodePositions: const {},
        connections: connections,
        portLayouts: const {},
        connectedPorts: const {},
        algorithmNames: const {},
        portPositions: const {},
      ));

      final tidyResult = TidyResult.success(
        originalConnections: connections,
        optimizedConnections: connections,
        busesFreed: 2,
        changes: {},
      );

      when(mockOptimizer.tidyConnections(any)).thenAnswer((_) async => tidyResult);

      await cubit.performTidy();

      final currentState = cubit.state as NodeRoutingStateLoaded;
      expect(currentState.lastTidyResult, isNotNull);
      expect(currentState.lastTidyResult!.busesFreed, equals(2));
      expect(currentState.totalBusesFreed, equals(2));
    });

    test('should accumulate buses freed over multiple tidy operations', () async {
      final connections = [
        Connection(
          id: 'test_conn',
          sourceAlgorithmIndex: 0,
          sourcePortId: 'out',
          targetAlgorithmIndex: 1,
          targetPortId: 'in',
          assignedBus: 21,
          replaceMode: false,
        ),
      ];

      cubit.emit(NodeRoutingState.loaded(
        nodePositions: const {},
        connections: connections,
        portLayouts: const {},
        connectedPorts: const {},
        algorithmNames: const {},
        portPositions: const {},
        totalBusesFreed: 3, // Previous optimizations
      ));

      final tidyResult = TidyResult.success(
        originalConnections: connections,
        optimizedConnections: connections,
        busesFreed: 2, // New optimization
        changes: {},
      );

      when(mockOptimizer.tidyConnections(any)).thenAnswer((_) async => tidyResult);

      await cubit.performTidy();

      final currentState = cubit.state as NodeRoutingStateLoaded;
      expect(currentState.totalBusesFreed, equals(5)); // 3 + 2
    });

    test('should not allow concurrent tidy operations', () async {
      final connections = [
        Connection(
          id: 'test_conn',
          sourceAlgorithmIndex: 0,
          sourcePortId: 'out',
          targetAlgorithmIndex: 1,
          targetPortId: 'in',
          assignedBus: 21,
          replaceMode: false,
        ),
      ];

      cubit.emit(NodeRoutingState.loaded(
        nodePositions: const {},
        connections: connections,
        portLayouts: const {},
        connectedPorts: const {},
        algorithmNames: const {},
        portPositions: const {},
      ));

      // Mock slow operation
      when(mockOptimizer.tidyConnections(any)).thenAnswer((_) async {
        await Future.delayed(const Duration(milliseconds: 100));
        return TidyResult.success(
          originalConnections: connections,
          optimizedConnections: connections,
          busesFreed: 1,
          changes: {},
        );
      });

      // Start first operation
      final future1 = cubit.performTidy();
      
      // Try to start second operation immediately
      final future2 = cubit.performTidy();

      final results = await Future.wait([future1, future2]);

      // One should succeed, other should fail with concurrent operation error
      expect(results.where((r) => r.success).length, equals(1));
      expect(results.where((r) => !r.success).length, equals(1));
      
      final failedResult = results.firstWhere((r) => !r.success);
      expect(failedResult.errorMessage, contains('concurrent'));
    });

    test('should preserve existing state properties during tidy', () async {
      final originalNodePositions = {0: const NodePosition(algorithmIndex: 0, x: 100, y: 200)};
      final originalPortLayouts = {0: const PortLayout(inputPorts: [], outputPorts: [])};
      final originalConnectedPorts = <String>{'test'};
      final originalAlgorithmNames = {0: 'TestAlgorithm'};
      final originalPortPositions = {'test': const Offset(50, 75)};

      final connections = [
        Connection(
          id: 'test_conn',
          sourceAlgorithmIndex: 0,
          sourcePortId: 'out',
          targetAlgorithmIndex: 1,
          targetPortId: 'in',
          assignedBus: 21,
          replaceMode: false,
        ),
      ];

      cubit.emit(NodeRoutingState.loaded(
        nodePositions: originalNodePositions,
        connections: connections,
        portLayouts: originalPortLayouts,
        connectedPorts: originalConnectedPorts,
        algorithmNames: originalAlgorithmNames,
        portPositions: originalPortPositions,
      ));

      final tidyResult = TidyResult.success(
        originalConnections: connections,
        optimizedConnections: connections,
        busesFreed: 1,
        changes: {},
      );

      when(mockOptimizer.tidyConnections(any)).thenAnswer((_) async => tidyResult);

      await cubit.performTidy();

      final currentState = cubit.state as NodeRoutingStateLoaded;
      expect(currentState.nodePositions, equals(originalNodePositions));
      expect(currentState.portLayouts, equals(originalPortLayouts));
      expect(currentState.connectedPorts, equals(originalConnectedPorts));
      expect(currentState.algorithmNames, equals(originalAlgorithmNames));
      expect(currentState.portPositions, equals(originalPortPositions));
    });

    test('should emit loading state during tidy operation', () async {
      final connections = [
        Connection(
          id: 'test_conn',
          sourceAlgorithmIndex: 0,
          sourcePortId: 'out',
          targetAlgorithmIndex: 1,
          targetPortId: 'in',
          assignedBus: 21,
          replaceMode: false,
        ),
      ];

      cubit.emit(NodeRoutingState.loaded(
        nodePositions: const {},
        connections: connections,
        portLayouts: const {},
        connectedPorts: const {},
        algorithmNames: const {},
        portPositions: const {},
      ));

      // Track state changes
      final stateChanges = <NodeRoutingState>[];
      cubit.stream.listen(stateChanges.add);

      when(mockOptimizer.tidyConnections(any)).thenAnswer((_) async {
        await Future.delayed(const Duration(milliseconds: 50));
        return TidyResult.success(
          originalConnections: connections,
          optimizedConnections: connections,
          busesFreed: 1,
          changes: {},
        );
      });

      await cubit.performTidy();

      // Should have emitted optimizing state during operation
      expect(stateChanges.any((s) => s is NodeRoutingStateOptimizing), isTrue);
    });
  });

  group('NodeRoutingState - Tidy Properties', () {
    test('should include tidy-related properties in loaded state', () {
      final tidyResult = TidyResult.success(
        originalConnections: [],
        optimizedConnections: [],
        busesFreed: 3,
        changes: {},
      );

      final state = NodeRoutingState.loaded(
        nodePositions: const {},
        connections: const [],
        portLayouts: const {},
        connectedPorts: const {},
        algorithmNames: const {},
        portPositions: const {},
        lastTidyResult: tidyResult,
        totalBusesFreed: 5,
      ) as NodeRoutingStateLoaded;

      expect(state.lastTidyResult, equals(tidyResult));
      expect(state.totalBusesFreed, equals(5));
    });

    test('should support optimizing state', () {
      const state = NodeRoutingState.optimizing();
      expect(state, isA<NodeRoutingStateOptimizing>());
    });

    test('should calculate optimization efficiency', () {
      final connections = List.generate(10, (i) => Connection(
        id: 'conn_$i',
        sourceAlgorithmIndex: i,
        sourcePortId: 'out',
        targetAlgorithmIndex: i + 1,
        targetPortId: 'in',
        assignedBus: 21 + i,
        replaceMode: false,
      ));

      final state = NodeRoutingState.loaded(
        nodePositions: const {},
        connections: connections,
        portLayouts: const {},
        connectedPorts: const {},
        algorithmNames: const {},
        portPositions: const {},
        totalBusesFreed: 3,
      ) as NodeRoutingStateLoaded;

      // Should calculate efficiency based on total connections vs buses freed
      expect(state.optimizationEfficiency, equals(0.3)); // 3/10
    });
  });
}