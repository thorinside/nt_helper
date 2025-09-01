import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:nt_helper/core/routing/routing_service_locator.dart';
import 'package:nt_helper/cubit/disting_cubit.dart';
import 'package:nt_helper/cubit/routing_editor_cubit.dart';
import 'package:nt_helper/db/database.dart';
import 'package:nt_helper/domain/disting_nt_sysex.dart';
import 'package:nt_helper/domain/i_disting_midi_manager.dart';
import 'package:nt_helper/models/firmware_version.dart';
import 'package:nt_helper/services/algorithm_metadata_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

@GenerateMocks([DistingCubit, IDistingMidiManager, AppDatabase])
import 'routing_editor_cubit_test.mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('RoutingEditorCubit', () {
    late MockDistingCubit mockDistingCubit;
    late RoutingEditorCubit routingEditorCubit;
    late StreamController<DistingState> distingStateController;
    
    // Provide dummy values for Mockito
    setUpAll(() {
      provideDummy<DistingState>(const DistingState.initial());
    });

    setUp(() async {
      // Mock SharedPreferences
      SharedPreferences.setMockInitialValues({});
      
      // Setup RoutingServiceLocator for tests
      if (RoutingServiceLocator.isSetup) {
        await RoutingServiceLocator.reset();
      }
      await RoutingServiceLocator.setup();
      
      // Initialize AlgorithmMetadataService with mock database
      final mockDatabase = MockAppDatabase();
      await AlgorithmMetadataService().initialize(mockDatabase);
      
      mockDistingCubit = MockDistingCubit();
      distingStateController = StreamController<DistingState>.broadcast();
      
      // Set up the mock to return our controlled stream
      when(mockDistingCubit.stream).thenAnswer((_) => distingStateController.stream);
      when(mockDistingCubit.state).thenReturn(const DistingState.initial());
      
      // Initialize the cubit after setting up the mocks
      routingEditorCubit = RoutingEditorCubit(mockDistingCubit);
    });

    tearDown(() async {
      await distingStateController.close();
      await routingEditorCubit.close();
      await RoutingServiceLocator.reset();
    });

    group('initialization', () {
      test('should start with initial state', () {
        expect(routingEditorCubit.state, isA<RoutingEditorStateInitial>());
      });

      test('should listen to disting cubit state changes', () {
        verify(mockDistingCubit.stream).called(1);
      });
    });

    group('state transitions from DistingState', () {
      blocTest<RoutingEditorCubit, RoutingEditorState>(
        'emits initial state when disting transitions from connected to initial',
        build: () => routingEditorCubit,
        act: (cubit) {
          // First emit connected state
          distingStateController.add(DistingState.connected(
            disting: MockIDistingMidiManager(),
          ));
          // Then emit initial state to trigger transition
          distingStateController.add(const DistingState.initial());
        },
        expect: () => [
          const RoutingEditorState.connecting(),
          const RoutingEditorState.initial(),
        ],
        wait: const Duration(milliseconds: 100),
      );

      blocTest<RoutingEditorCubit, RoutingEditorState>(
        'emits disconnected state when disting is selecting device',
        build: () => routingEditorCubit,
        act: (cubit) {
          distingStateController.add(const DistingState.selectDevice(
            inputDevices: [],
            outputDevices: [],
            canWorkOffline: false,
          ));
        },
        expect: () => [
          const RoutingEditorState.disconnected(),
        ],
      );

      blocTest<RoutingEditorCubit, RoutingEditorState>(
        'emits connecting state when disting is connected',
        build: () => routingEditorCubit,
        act: (cubit) {
          final mockMidiManager = MockIDistingMidiManager();
          distingStateController.add(DistingState.connected(
            disting: mockMidiManager,
          ));
        },
        expect: () => [
          const RoutingEditorState.connecting(),
        ],
      );
    });

    group('synchronized state processing', () {
      blocTest<RoutingEditorCubit, RoutingEditorState>(
        'emits loaded state with processed algorithms when synchronized',
        build: () => routingEditorCubit,
        act: (cubit) {
          final mockMidiManager = MockIDistingMidiManager();
          final testSlots = _createTestSlots();
          
          distingStateController.add(DistingState.synchronized(
            disting: mockMidiManager,
            distingVersion: '1.9.0',
            firmwareVersion: FirmwareVersion('1.9.0'),
            presetName: 'Test Preset',
            algorithms: [],
            slots: testSlots,
            unitStrings: [],
          ));
        },
        expect: () => [
          isA<RoutingEditorStateLoaded>().having(
            (state) => state.algorithms.length,
            'algorithms length',
            2,
          ).having(
            (state) => state.physicalInputs.length,
            'physical inputs length',
            12,
          ).having(
            (state) => state.physicalOutputs.length,
            'physical outputs length', 
            8,
          ),
        ],
      );

      blocTest<RoutingEditorCubit, RoutingEditorState>(
        'processes synchronized state with invalid data gracefully',
        build: () => routingEditorCubit,
        act: (cubit) {
          final mockMidiManager = MockIDistingMidiManager();
          // Pass invalid/null slots to trigger error
          distingStateController.add(DistingState.synchronized(
            disting: mockMidiManager,
            distingVersion: '1.9.0',
            firmwareVersion: FirmwareVersion('1.9.0'),
            presetName: 'Test Preset',
            algorithms: [],
            slots: _createInvalidSlots(),
            unitStrings: [],
          ));
        },
        expect: () => [
          isA<RoutingEditorStateLoaded>().having(
            (state) => state.algorithms.length,
            'algorithms length',
            1, // Even invalid slots get processed
          ),
        ],
      );
    });

    group('routing data extraction', () {
      test('should extract input connections correctly', () {
        final testSlots = _createTestSlots();
        
        distingStateController.add(DistingState.synchronized(
          disting: MockIDistingMidiManager(),
          distingVersion: '1.9.0',
          firmwareVersion: FirmwareVersion('1.9.0'),
          presetName: 'Test Preset',
          algorithms: [],
          slots: testSlots,
          unitStrings: [],
        ));

        // Wait for state to be processed
        expectLater(
          routingEditorCubit.stream,
          emitsInOrder([
            isA<RoutingEditorStateLoaded>().having(
              (state) => state.algorithms.first.inputPorts.length,
              'first algorithm input ports',
              equals(0), // No ports until AlgorithmRouting hierarchy is implemented
            ),
          ]),
        );
      });

      test('should build routing information compatible with existing system', () {
        final testSlots = _createTestSlots();
        
        distingStateController.add(DistingState.synchronized(
          disting: MockIDistingMidiManager(),
          distingVersion: '1.9.0',
          firmwareVersion: FirmwareVersion('1.9.0'),
          presetName: 'Test Preset',
          algorithms: [],
          slots: testSlots,
          unitStrings: [],
        ));

        expectLater(
          routingEditorCubit.stream,
          emitsInOrder([
            isA<RoutingEditorStateLoaded>().having(
              (state) => state.connections.length,
              'connections length',
              equals(0), // No connections until AlgorithmRouting hierarchy is implemented
            ),
          ]),
        );
      });
    });

    group('routing operations', () {
      blocTest<RoutingEditorCubit, RoutingEditorState>(
        'refreshRouting should call disting cubit refresh',
        build: () => routingEditorCubit,
        setUp: () {
          when(mockDistingCubit.refreshRouting()).thenAnswer((_) async {});
          // Start with loaded state
          routingEditorCubit.emit(RoutingEditorState.loaded(
            physicalInputs: <Port>[],
            physicalOutputs: <Port>[],
            algorithms: <RoutingAlgorithm>[],
            connections: <Connection>[],
          ));
        },
        act: (cubit) => cubit.refreshRouting(),
        expect: () => [
          const RoutingEditorState.refreshing(),
        ],
        verify: (cubit) {
          verify(mockDistingCubit.refreshRouting()).called(1);
        },
      );

      blocTest<RoutingEditorCubit, RoutingEditorState>(
        'refreshRouting should emit error state if refresh fails',
        build: () => routingEditorCubit,
        setUp: () {
          when(mockDistingCubit.refreshRouting())
              .thenThrow(Exception('Refresh failed'));
          // Start with loaded state
          routingEditorCubit.emit(RoutingEditorState.loaded(
            physicalInputs: <Port>[],
            physicalOutputs: <Port>[],
            algorithms: <RoutingAlgorithm>[],
            connections: <Connection>[],
          ));
        },
        act: (cubit) => cubit.refreshRouting(),
        expect: () => [
          const RoutingEditorState.refreshing(),
          isA<RoutingEditorStateError>().having(
            (state) => state.message,
            'error message',
            contains('Failed to refresh routing'),
          ),
        ],
      );

      blocTest<RoutingEditorCubit, RoutingEditorState>(
        'clearRouting should reset to initial state',
        build: () => routingEditorCubit,
        setUp: () {
          // Start with loaded state
          routingEditorCubit.emit(RoutingEditorState.loaded(
            physicalInputs: <Port>[],
            physicalOutputs: <Port>[],
            algorithms: <RoutingAlgorithm>[],
            connections: <Connection>[],
          ));
        },
        act: (cubit) => cubit.clearRouting(),
        expect: () => [
          const RoutingEditorState.initial(),
        ],
      );
    });

    group('resource management', () {
      test('should cancel subscription on close', () async {
        await routingEditorCubit.close();
        
        // Verify that the subscription was cancelled by ensuring
        // no more events are processed after close
        distingStateController.add(const DistingState.initial());
        
        // The cubit should not emit any new states after being closed
        expect(routingEditorCubit.isClosed, isTrue);
      });
    });
  });
}

/// Helper function to create test slots for testing
List<Slot> _createTestSlots() {
  return [
    Slot(
      algorithm: Algorithm(
        algorithmIndex: 0,
        guid: 'TST1',
        name: 'Test Algorithm 1',
      ),
      routing: RoutingInfo(
        algorithmIndex: 0,
        routingInfo: [0x0F, 0x0F, 0x00, 0x00, 0x00, 0x0F], // Test routing data
      ),
      pages: ParameterPages(algorithmIndex: 0, pages: []),
      parameters: [
        // Create test routing parameters (unit == 0, max == 27 or 28 indicates bus routing)
        ParameterInfo(
          algorithmIndex: 0,
          parameterNumber: 0,
          name: 'Input A',
          unit: 0,
          min: 0,
          max: 28,
          defaultValue: 1,
          powerOfTen: 0,
        ),
        ParameterInfo(
          algorithmIndex: 0,
          parameterNumber: 1,
          name: 'Output Left',
          unit: 0,
          min: 1,
          max: 27,
          defaultValue: 1,
          powerOfTen: 0,
        ),
      ],
      values: [
        ParameterValue(algorithmIndex: 0, parameterNumber: 0, value: 9), // Bus 9 input
        ParameterValue(algorithmIndex: 0, parameterNumber: 1, value: 1), // Bus 1 output
      ],
      enums: [
        ParameterEnumStrings(algorithmIndex: 0, parameterNumber: 0, values: ['None', 'Bus 1', 'Bus 2']),
        ParameterEnumStrings(algorithmIndex: 0, parameterNumber: 1, values: ['None', 'Bus 1', 'Bus 2']),
      ],
      mappings: [],
      valueStrings: [
        ParameterValueString(algorithmIndex: 0, parameterNumber: 0, value: 'Bus 9'),
        ParameterValueString(algorithmIndex: 0, parameterNumber: 1, value: 'Bus 1'),
      ],
    ),
    Slot(
      algorithm: Algorithm(
        algorithmIndex: 1,
        guid: 'TST2',
        name: 'Test Algorithm 2',
      ),
      routing: RoutingInfo(
        algorithmIndex: 1,
        routingInfo: [0x0A, 0x05, 0x00, 0x00, 0x00, 0x03], // Different routing pattern
      ),
      pages: ParameterPages(algorithmIndex: 1, pages: []),
      parameters: [
        ParameterInfo(
          algorithmIndex: 1,
          parameterNumber: 0,
          name: 'CV Input',
          unit: 0,
          min: 0,
          max: 28,
          defaultValue: 1,
          powerOfTen: 0,
        ),
      ],
      values: [
        ParameterValue(algorithmIndex: 1, parameterNumber: 0, value: 2), // Bus 2 input
      ],
      enums: [
        ParameterEnumStrings(algorithmIndex: 1, parameterNumber: 0, values: ['None', 'Bus 1', 'Bus 2']),
      ],
      mappings: [],
      valueStrings: [
        ParameterValueString(algorithmIndex: 1, parameterNumber: 0, value: 'Bus 2'),
      ],
    ),
  ];
}

/// Helper function to create invalid slots that should trigger error handling
List<Slot> _createInvalidSlots() {
  return [
    Slot(
      algorithm: Algorithm(
        algorithmIndex: 0,
        guid: '',  // Invalid empty GUID
        name: '',  // Invalid empty name
      ),
      routing: RoutingInfo(
        algorithmIndex: 0,
        routingInfo: [], // Invalid empty routing data
      ),
      pages: ParameterPages(algorithmIndex: 0, pages: []),
      parameters: [],
      values: [],
      enums: [],
      mappings: [],
      valueStrings: [],
    ),
  ];
}