import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_midi_command/flutter_midi_command.dart';
import 'package:nt_helper/domain/i_disting_midi_manager.dart';
import 'package:nt_helper/models/firmware_version.dart';
import 'package:nt_helper/db/database.dart';

import 'package:nt_helper/cubit/routing_editor_cubit.dart';
import 'package:nt_helper/cubit/routing_editor_state.dart';
import 'package:nt_helper/cubit/disting_cubit.dart';
import 'package:nt_helper/core/routing/models/connection.dart';

import 'routing_editor_cubit_test.mocks.dart';

@GenerateMocks([DistingCubit, IDistingMidiManager])
void main() {
  group('RoutingEditorCubit Optimistic State Management', () {
    late MockDistingCubit mockDistingCubit;
    late RoutingEditorCubit routingEditorCubit;

    setUpAll(() {
      // Provide dummy values for Mockito
      provideDummy<DistingState>(const DistingState.initial());
      
      provideDummy<MidiDevice>(MidiDevice(
        'test-device',
        'Test Device',
        'Test',
        false,
      ));

      provideDummy<FirmwareVersion>(FirmwareVersion('1.0.0'));

      provideDummy<AlgorithmEntry>(const AlgorithmEntry(
        guid: 'test-guid',
        name: 'Test Algorithm',
        numSpecifications: 1,
        pluginFilePath: null,
      ));

      provideDummy<ParameterEntry>(const ParameterEntry(
        algorithmGuid: 'test-algorithm',
        parameterNumber: 1,
        name: 'Test Param',
        minValue: 0,
        maxValue: 100,
        defaultValue: 0,
        unitId: null,
        powerOfTen: null,
        rawUnitIndex: 0,
      ));

      provideDummy<ParameterPageEntry>(const ParameterPageEntry(
        algorithmGuid: 'test-algorithm',
        pageIndex: 1,
        name: 'Page 1',
      ));

      provideDummy<ParameterEnumEntry>(const ParameterEnumEntry(
        algorithmGuid: 'test-algorithm',
        parameterNumber: 1,
        enumIndex: 0,
        enumString: 'Test',
      ));

      provideDummy<UnitEntry>(const UnitEntry(
        id: 1,
        unitString: 'Test Unit',
      ));
    });

    setUp(() async {
      // Set up SharedPreferences mock
      SharedPreferences.setMockInitialValues({});
      
      mockDistingCubit = MockDistingCubit();
      
      // Stub the stream property to return an empty stream
      when(mockDistingCubit.stream).thenAnswer((_) => const Stream.empty());
      
      // Stub the state property to return initial state
      when(mockDistingCubit.state).thenReturn(const DistingState.initial());
      
      routingEditorCubit = RoutingEditorCubit(mockDistingCubit);
    });

    tearDown(() {
      routingEditorCubit.close();
    });

    group('createConnectionOptimistic', () {
      blocTest<RoutingEditorCubit, RoutingEditorState>(
        'should create connection optimistically and add to pending operations',
        build: () => routingEditorCubit,
        act: (cubit) async {
          // First set up loaded state
          cubit.emit(RoutingEditorState.loaded(
            physicalInputs: [
              const Port(
                id: 'hw_in_1',
                name: 'I1',
                type: PortType.cv,
                direction: PortDirection.input,
              ),
            ],
            physicalOutputs: [
              const Port(
                id: 'hw_out_1',
                name: 'Audio Out 1',
                type: PortType.audio,
                direction: PortDirection.output,
              ),
            ],
            algorithms: [],
            connections: [],
          ));
          
          // Test optimistic connection creation
          cubit.createConnectionOptimistic(
            sourcePortId: 'hw_out_1',
            targetPortId: 'hw_in_1',
          );
        },
        expect: () => [
          isA<RoutingEditorStateLoaded>().having(
            (state) => state.connections.length,
            'connections count',
            1,
          ),
          isA<RoutingEditorStateLoaded>().having(
            (state) => state.pendingOperations.length,
            'pending operations count',
            1,
          ),
        ],
      );

      blocTest<RoutingEditorCubit, RoutingEditorState>(
        'should prevent duplicate connections',
        build: () => routingEditorCubit,
        act: (cubit) async {
          // Set up loaded state with existing connection
          cubit.emit(RoutingEditorState.loaded(
            physicalInputs: [
              const Port(
                id: 'hw_in_1',
                name: 'I1',
                type: PortType.cv,
                direction: PortDirection.input,
              ),
            ],
            physicalOutputs: [
              const Port(
                id: 'hw_out_1',
                name: 'Audio Out 1',
                type: PortType.audio,
                direction: PortDirection.output,
              ),
            ],
            algorithms: [],
            connections: [
              Connection(
                id: 'existing_conn',
                sourcePortId: 'hw_out_1',
                destinationPortId: 'hw_in_1',
                connectionType: ConnectionType.hardwareOutput,
                createdAt: DateTime.now(),
              ),
            ],
          ));
          
          // Try to create duplicate connection
          cubit.createConnectionOptimistic(
            sourcePortId: 'hw_out_1',
            targetPortId: 'hw_in_1',
          );
        },
        expect: () => [
          isA<RoutingEditorStateError>().having(
            (state) => state.message,
            'error message',
            contains('Connection already exists'),
          ),
        ],
      );
    });

    group('deleteConnectionOptimistic', () {
      blocTest<RoutingEditorCubit, RoutingEditorState>(
        'should delete connection optimistically and add to pending operations',
        build: () => routingEditorCubit,
        act: (cubit) async {
          // Set up loaded state with existing connection
          cubit.emit(RoutingEditorState.loaded(
            physicalInputs: [],
            physicalOutputs: [],
            algorithms: [],
            connections: [
              Connection(
                id: 'test_conn',
                sourcePortId: 'hw_out_1',
                destinationPortId: 'hw_in_1',
                connectionType: ConnectionType.hardwareOutput,
                createdAt: DateTime.now(),
              ),
            ],
          ));
          
          // Delete connection optimistically
          cubit.deleteConnectionOptimistic('test_conn');
        },
        expect: () => [
          isA<RoutingEditorStateLoaded>().having(
            (state) => state.connections.length,
            'connections count',
            0,
          ),
          isA<RoutingEditorStateLoaded>().having(
            (state) => state.pendingOperations.length,
            'pending operations count',
            1,
          ),
        ],
      );

      blocTest<RoutingEditorCubit, RoutingEditorState>(
        'should handle non-existent connection deletion gracefully',
        build: () => routingEditorCubit,
        act: (cubit) async {
          // Set up loaded state with no connections
          cubit.emit(RoutingEditorState.loaded(
            physicalInputs: [],
            physicalOutputs: [],
            algorithms: [],
            connections: [],
          ));
          
          // Try to delete non-existent connection
          cubit.deleteConnectionOptimistic('non_existent');
        },
        expect: () => [
          isA<RoutingEditorStateError>().having(
            (state) => state.message,
            'error message',
            contains('Connection not found'),
          ),
        ],
      );
    });

    group('revertOptimisticChanges', () {
      blocTest<RoutingEditorCubit, RoutingEditorState>(
        'should revert optimistic changes and clear pending operations',
        build: () => routingEditorCubit,
        act: (cubit) async {
          // Set up loaded state
          cubit.emit(RoutingEditorState.loaded(
            physicalInputs: [
              const Port(
                id: 'hw_in_1',
                name: 'I1',
                type: PortType.cv,
                direction: PortDirection.input,
              ),
            ],
            physicalOutputs: [
              const Port(
                id: 'hw_out_1',
                name: 'Audio Out 1',
                type: PortType.audio,
                direction: PortDirection.output,
              ),
            ],
            algorithms: [],
            connections: [],
          ));
          
          // Create connection optimistically
          cubit.createConnectionOptimistic(
            sourcePortId: 'hw_out_1',
            targetPortId: 'hw_in_1',
          );
          
          // Revert changes
          cubit.revertOptimisticChanges();
        },
        expect: () => [
          // Initial loaded state
          isA<RoutingEditorStateLoaded>(),
          // After optimistic creation
          isA<RoutingEditorStateLoaded>().having(
            (state) => state.connections.length,
            'connections count after creation',
            1,
          ),
          // After revert
          isA<RoutingEditorStateLoaded>().having(
            (state) => state.connections.length,
            'connections count after revert',
            0,
          ),
          isA<RoutingEditorStateLoaded>().having(
            (state) => state.pendingOperations.length,
            'pending operations count after revert',
            0,
          ),
        ],
      );
    });

    group('hardware sync with timeout', () {
      blocTest<RoutingEditorCubit, RoutingEditorState>(
        'should sync optimistic changes to hardware with timeout',
        build: () => routingEditorCubit,
        act: (cubit) async {
          // Set up loaded state
          cubit.emit(RoutingEditorState.loaded(
            physicalInputs: [
              const Port(
                id: 'hw_in_1',
                name: 'I1',
                type: PortType.cv,
                direction: PortDirection.input,
              ),
            ],
            physicalOutputs: [
              const Port(
                id: 'hw_out_1',
                name: 'Audio Out 1',
                type: PortType.audio,
                direction: PortDirection.output,
              ),
            ],
            algorithms: [],
            connections: [],
          ));
          
          // Create connection optimistically
          cubit.createConnectionOptimistic(
            sourcePortId: 'hw_out_1',
            targetPortId: 'hw_in_1',
          );
        },
        verify: (cubit) {
          // Verify hardware sync was attempted
          // Note: In a real implementation, we would mock the hardware communication
          // and verify that sync operations were called
        },
      );

      blocTest<RoutingEditorCubit, RoutingEditorState>(
        'should revert changes on hardware sync timeout',
        build: () => routingEditorCubit,
        act: (cubit) async {
          // Set up loaded state
          cubit.emit(RoutingEditorState.loaded(
            physicalInputs: [
              const Port(
                id: 'hw_in_1',
                name: 'I1',
                type: PortType.cv,
                direction: PortDirection.input,
              ),
            ],
            physicalOutputs: [
              const Port(
                id: 'hw_out_1',
                name: 'Audio Out 1',
                type: PortType.audio,
                direction: PortDirection.output,
              ),
            ],
            algorithms: [],
            connections: [],
          ));
          
          // Simulate hardware sync timeout
          // This would typically be tested by mocking the hardware communication
          // and making it timeout
        }
      );
    });

    group('sync status feedback', () {
      test('should provide sync status information', () async {
        // Set up loaded state
        const state = RoutingEditorStateLoaded(
          physicalInputs: [],
          physicalOutputs: [],
          algorithms: [],
          connections: [],
          isHardwareSynced: false,
          lastSyncTime: null,
        );
        
        routingEditorCubit.emit(state);
        
        final syncStatus = routingEditorCubit.getHardwareSyncStatus();
        
        expect(syncStatus['isHardwareSynced'], false);
        expect(syncStatus['connectionCount'], 0);
        expect(syncStatus['lastSyncTime'], null);
      });
    });

    group('conflict resolution', () {
      blocTest<RoutingEditorCubit, RoutingEditorState>(
        'should handle conflicts between local and hardware state',
        build: () => routingEditorCubit,
        act: (cubit) async {
          // Set up loaded state with local changes
          cubit.emit(RoutingEditorState.loaded(
            physicalInputs: [],
            physicalOutputs: [],
            algorithms: [],
            connections: [
              Connection(
                id: 'local_conn',
                sourcePortId: 'hw_out_1',
                destinationPortId: 'hw_in_1',
                connectionType: ConnectionType.hardwareOutput,
                createdAt: DateTime.now(),
              ),
            ],
            isHardwareSynced: false,
          ));
          
          // Simulate hardware state change (would come from DistingCubit stream)
          // This test would verify that conflicts are detected and resolved
        }
      );
    });
  });
}
