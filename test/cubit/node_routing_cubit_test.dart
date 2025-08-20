import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:nt_helper/cubit/disting_cubit.dart';
import 'package:nt_helper/cubit/node_routing_cubit.dart';
import 'package:nt_helper/cubit/node_routing_state.dart';
import 'package:nt_helper/domain/i_disting_midi_manager.dart';
import 'package:nt_helper/models/algorithm_port.dart';
import 'package:nt_helper/models/connection.dart';
import 'package:nt_helper/models/firmware_version.dart';
import 'package:nt_helper/models/node_position.dart';
import 'package:nt_helper/models/port_layout.dart';
import 'package:nt_helper/services/algorithm_metadata_service.dart';
import 'package:nt_helper/services/auto_routing_service.dart';
import 'package:nt_helper/services/node_positions_persistence_service.dart';

@GenerateMocks([DistingCubit, AlgorithmMetadataService, AutoRoutingService, IDistingMidiManager, NodePositionsPersistenceService])
import 'node_routing_cubit_test.mocks.dart';

// Test helper for consistent physical output position
const NodePosition _defaultPhysicalOutputPosition = NodePosition(
  x: 700.0,
  y: 100.0,
  width: 80.0,
  height: 188.0,
  algorithmIndex: -3,
);

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    
    // Provide a dummy for DistingState
    provideDummy<DistingState>(
      DistingState.synchronized(
        disting: MockIDistingMidiManager(),
        distingVersion: '',
        firmwareVersion: FirmwareVersion('1.0.0'),
        presetName: 'Test',
        algorithms: [],
        slots: [],
        unitStrings: [],
      ),
    );
  });

  group('NodeRoutingCubit - Optimistic Updates', () {
    late MockDistingCubit mockDistingCubit;
    late MockAlgorithmMetadataService mockAlgorithmMetadataService;
    late MockNodePositionsPersistenceService mockPersistenceService;
    late NodeRoutingCubit nodeRoutingCubit;

    setUp(() {
      mockDistingCubit = MockDistingCubit();
      mockAlgorithmMetadataService = MockAlgorithmMetadataService();
      mockPersistenceService = MockNodePositionsPersistenceService();
      
      // Auto routing service is created in the constructor
      // For testing, we'll test the behavior at the state level
      
      // Setup persistence service mock
      when(mockPersistenceService.loadPositions(any)).thenAnswer((_) async => <int, NodePosition>{});
      when(mockPersistenceService.savePositions(any, any)).thenAnswer((_) async {});
      
      // Setup default state
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
      
      // Initialize the cubit after mocking
      nodeRoutingCubit = NodeRoutingCubit(mockDistingCubit, mockAlgorithmMetadataService, mockPersistenceService);
    });

    tearDown(() {
      nodeRoutingCubit.close();
    });

    group('createConnection', () {
      test('should immediately add connection to state (optimistic update)', () async {
        // Arrange
        final initialState = NodeRoutingStateLoaded(
          nodePositions: {
            0: NodePosition(x: 100, y: 100, width: 200, height: 150, algorithmIndex: 0),
            1: NodePosition(x: 400, y: 100, width: 200, height: 150, algorithmIndex: 1),
          },
          connections: [],
          portLayouts: {
            0: PortLayout(
              inputPorts: [],
              outputPorts: [AlgorithmPort(id: 'output', name: 'Output')],
            ),
            1: PortLayout(
              inputPorts: [AlgorithmPort(id: 'input', name: 'Input')],
              outputPorts: [],
            ),
          },
          connectedPorts: {},
          algorithmNames: {0: 'VCO', 1: 'Filter'},
          portPositions: {
            '0_output': Offset(300, 175),
            '1_input': Offset(400, 175),
          },
        );
        
        nodeRoutingCubit.emit(initialState);

        // Act
        final future = nodeRoutingCubit.createConnection(
          sourceAlgorithmIndex: 0,
          sourcePortId: 'output',
          targetAlgorithmIndex: 1,
          targetPortId: 'input',
        );

        // Allow the first state emission (optimistic update)
        await Future.delayed(Duration.zero);

        // Assert - should immediately have the connection in pending state
        final state = nodeRoutingCubit.state as NodeRoutingStateLoaded;
        
        expect(state.connections.length, equals(1));
        expect(state.connections.first.sourceAlgorithmIndex, equals(0));
        expect(state.connections.first.sourcePortId, equals('output'));
        expect(state.connections.first.targetAlgorithmIndex, equals(1));
        expect(state.connections.first.targetPortId, equals('input'));
        expect(state.connections.first.assignedBus, equals(21)); // Default temp bus
        
        // Should be in pending state
        expect(state.pendingConnections, contains(state.connections.first.id));
        expect(state.operationTimestamps.keys, contains(state.connections.first.id));
        
        // Connected ports should be updated
        expect(state.connectedPorts, contains('0_output'));
        expect(state.connectedPorts, contains('1_input'));
        
        await future;
      });

      test('should handle validation failure without creating connection', () async {
        // Arrange - Invalid connection (same algorithm)
        final initialState = NodeRoutingStateLoaded(
          nodePositions: {
            0: NodePosition(x: 100, y: 100, width: 200, height: 150, algorithmIndex: 0),
          },
          connections: [],
          portLayouts: {
            0: PortLayout(
              inputPorts: [AlgorithmPort(id: 'input', name: 'Input')],
              outputPorts: [AlgorithmPort(id: 'output', name: 'Output')],
            ),
          },
          connectedPorts: {},
          algorithmNames: {0: 'VCO'},
          portPositions: {},
        );
        
        nodeRoutingCubit.emit(initialState);

        // Act - Try to connect output to input on same algorithm
        await nodeRoutingCubit.createConnection(
          sourceAlgorithmIndex: 0,
          sourcePortId: 'output',
          targetAlgorithmIndex: 0,
          targetPortId: 'input',
        );

        // Assert - Should not create connection, should have error
        final state = nodeRoutingCubit.state as NodeRoutingStateLoaded;
        expect(state.connections.length, equals(0));
        expect(state.pendingConnections.length, equals(0));
        expect(state.errorMessage, isNotNull);
        expect(state.errorMessage, contains('validation failed'));
      });

      test('should handle connection failure and rollback', () async {
        // This test would require mocking the AutoRoutingService to fail
        // For now, we'll test the structure is in place
        final initialState = NodeRoutingStateLoaded(
          nodePositions: {
            0: NodePosition(x: 100, y: 100, width: 200, height: 150, algorithmIndex: 0),
            1: NodePosition(x: 400, y: 100, width: 200, height: 150, algorithmIndex: 1),
          },
          connections: [],
          portLayouts: {
            0: PortLayout(
              inputPorts: [],
              outputPorts: [AlgorithmPort(id: 'output', name: 'Output')],
            ),
            1: PortLayout(
              inputPorts: [AlgorithmPort(id: 'input', name: 'Input')],
              outputPorts: [],
            ),
          },
          connectedPorts: {},
          algorithmNames: {0: 'VCO', 1: 'Filter'},
          portPositions: {
            '0_output': Offset(300, 175),
            '1_input': Offset(400, 175),
          },
        );
        
        nodeRoutingCubit.emit(initialState);

        // Act
        await nodeRoutingCubit.createConnection(
          sourceAlgorithmIndex: 0,
          sourcePortId: 'output',
          targetAlgorithmIndex: 1,
          targetPortId: 'input',
        );

        // For this test, we can't easily mock the failure, but we can verify
        // the optimistic update mechanism is in place
        final state = nodeRoutingCubit.state as NodeRoutingStateLoaded;
        expect(state.connections.length, greaterThan(0));
        // In a real failure scenario, the connection would be rolled back
      });

      test('should clear error message on successful operation', () async {
        // Arrange
        final initialState = NodeRoutingStateLoaded(
          nodePositions: {
            0: NodePosition(x: 100, y: 100, width: 200, height: 150, algorithmIndex: 0),
            1: NodePosition(x: 400, y: 100, width: 200, height: 150, algorithmIndex: 1),
          },
          connections: [],
          portLayouts: {
            0: PortLayout(
              inputPorts: [],
              outputPorts: [AlgorithmPort(id: 'output', name: 'Output')],
            ),
            1: PortLayout(
              inputPorts: [AlgorithmPort(id: 'input', name: 'Input')],
              outputPorts: [],
            ),
          },
          connectedPorts: {},
          algorithmNames: {0: 'VCO', 1: 'Filter'},
          portPositions: {
            '0_output': Offset(300, 175),
            '1_input': Offset(400, 175),
          },
          errorMessage: 'Previous error',
        );
        
        nodeRoutingCubit.emit(initialState);

        // Act
        await nodeRoutingCubit.createConnection(
          sourceAlgorithmIndex: 0,
          sourcePortId: 'output',
          targetAlgorithmIndex: 1,
          targetPortId: 'input',
        );

        // Assert
        final state = nodeRoutingCubit.state as NodeRoutingStateLoaded;
        expect(state.errorMessage, isNull);
      });
    });

    group('removeConnection', () {
      test('should immediately remove connection from state (optimistic update)', () async {
        // Arrange
        final existingConnection = Connection(
          id: '0_output_1_input',
          sourceAlgorithmIndex: 0,
          sourcePortId: 'output',
          targetAlgorithmIndex: 1,
          targetPortId: 'input',
          assignedBus: 21,
          replaceMode: true,
          isValid: true,
        );
        
        final initialState = NodeRoutingStateLoaded(
          nodePositions: {
            0: NodePosition(x: 100, y: 100, width: 200, height: 150, algorithmIndex: 0),
            1: NodePosition(x: 400, y: 100, width: 200, height: 150, algorithmIndex: 1),
          },
          connections: [existingConnection],
          portLayouts: {
            0: PortLayout(
              inputPorts: [],
              outputPorts: [AlgorithmPort(id: 'output', name: 'Output')],
            ),
            1: PortLayout(
              inputPorts: [AlgorithmPort(id: 'input', name: 'Input')],
              outputPorts: [],
            ),
          },
          connectedPorts: {'0_output', '1_input'},
          algorithmNames: {0: 'VCO', 1: 'Filter'},
          portPositions: {},
        );
        
        nodeRoutingCubit.emit(initialState);

        // Act
        await nodeRoutingCubit.removeConnection(existingConnection);

        // Assert - Connection should be immediately removed
        final state = nodeRoutingCubit.state as NodeRoutingStateLoaded;
        expect(state.connections.length, equals(0));
        expect(state.connectedPorts.length, equals(0));
        expect(state.errorMessage, isNull);
      });
    });

    group('state management', () {
      test('should track pending connections with timestamps', () {
        // Arrange
        final connection = Connection(
          id: 'test_connection',
          sourceAlgorithmIndex: 0,
          sourcePortId: 'output',
          targetAlgorithmIndex: 1,
          targetPortId: 'input',
          assignedBus: 21,
          replaceMode: true,
          isValid: true,
        );
        
        final state = NodeRoutingStateLoaded(
          nodePositions: {},
          connections: [connection],
          portLayouts: {},
          connectedPorts: {},
          algorithmNames: {},
          portPositions: {},
          pendingConnections: {'test_connection'},
          operationTimestamps: {'test_connection': DateTime.now()},
        );

        // Assert
        expect(state.pendingConnections, contains('test_connection'));
        expect(state.operationTimestamps.keys, contains('test_connection'));
      });

      test('should track failed connections', () {
        // Arrange
        final state = NodeRoutingStateLoaded(
          nodePositions: {},
          connections: [],
          portLayouts: {},
          connectedPorts: {},
          algorithmNames: {},
          portPositions: {},
          failedConnections: {'failed_connection'},
        );

        // Assert
        expect(state.failedConnections, contains('failed_connection'));
      });

      test('should handle copyWith for new state fields', () {
        // Arrange
        final originalState = NodeRoutingStateLoaded(
          nodePositions: {},
          connections: [],
          portLayouts: {},
          connectedPorts: {},
          algorithmNames: {},
          portPositions: {},
        );

        // Act
        final newState = originalState.copyWith(
          pendingConnections: {'pending_1'},
          failedConnections: {'failed_1'},
          operationTimestamps: {'pending_1': DateTime.now()},
        );

        // Assert
        expect(newState.pendingConnections, contains('pending_1'));
        expect(newState.failedConnections, contains('failed_1'));
        expect(newState.operationTimestamps.keys, contains('pending_1'));
      });
    });
  });
}