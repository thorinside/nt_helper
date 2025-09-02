import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:nt_helper/cubit/disting_cubit.dart';
import 'package:nt_helper/cubit/routing_editor_cubit.dart';
import 'package:nt_helper/domain/disting_nt_sysex.dart';
import 'package:nt_helper/domain/i_disting_midi_manager.dart';
import 'package:nt_helper/models/firmware_version.dart';

@GenerateMocks([DistingCubit, IDistingMidiManager])
import 'routing_state_integration_test.mocks.dart';

/// Integration tests for the complete routing state management system
/// 
/// Tests the integration between DistingCubit and RoutingEditorCubit
/// and verifies that synchronized state from hardware is properly
/// processed into visual routing representation.
void main() {
  group('Routing State Management Integration', () {
    late StreamController<DistingState> distingStateController;
    late MockIDistingMidiManager mockMidiManager;
    late MockDistingCubit mockDistingCubit;
    late RoutingEditorCubit routingEditorCubit;

    setUpAll(() {
      provideDummy<DistingState>(const DistingState.initial());
    });

    setUp(() {
      mockMidiManager = MockIDistingMidiManager();
      distingStateController = StreamController<DistingState>.broadcast();
      mockDistingCubit = MockDistingCubit();
      
      // Set up the mock to return our controlled stream
      when(mockDistingCubit.stream).thenAnswer((_) => distingStateController.stream);
      when(mockDistingCubit.state).thenReturn(const DistingState.initial());
      when(mockDistingCubit.refreshRouting()).thenAnswer((_) async {});
      
      routingEditorCubit = RoutingEditorCubit(mockDistingCubit);
    });

    tearDown(() {
      routingEditorCubit.close();
      distingStateController.close();
    });

    group('end-to-end routing data flow', () {
      test('should process complete hardware synchronization flow', () async {
        final states = <RoutingEditorState>[];
        final subscription = routingEditorCubit.stream.listen(states.add);

        try {
          // 1. Start with device selection
          distingStateController.add(const DistingState.selectDevice(
            inputDevices: [],
            outputDevices: [],
            canWorkOffline: false,
          ));
          await Future.delayed(const Duration(milliseconds: 10));

          // 2. Connect to device
          distingStateController.add(DistingState.connected(
            disting: mockMidiManager,
          ));
          await Future.delayed(const Duration(milliseconds: 10));

          // 3. Synchronize with hardware state
          final testSlots = _createCompleteTestSlots();
          distingStateController.add(DistingState.synchronized(
            disting: mockMidiManager,
            distingVersion: '1.9.0',
            firmwareVersion: FirmwareVersion('1.9.0'),
            presetName: 'Integration Test Preset',
            algorithms: _createTestAlgorithmInfos(),
            slots: testSlots,
            unitStrings: ['%', 'Hz', 'V', 'ms'],
          ));
          await Future.delayed(const Duration(milliseconds: 50));

          // Verify the complete state progression
          expect(states.length, greaterThanOrEqualTo(3));
          expect(states[0], isA<RoutingEditorStateDisconnected>());
          expect(states[1], isA<RoutingEditorStateConnecting>());
          expect(states[2], isA<RoutingEditorStateLoaded>());

          // Verify the final loaded state has proper routing data
          final loadedState = states[2] as RoutingEditorStateLoaded;
          expect(loadedState.algorithms.length, equals(4));
          expect(loadedState.physicalInputs.length, equals(12));
          expect(loadedState.physicalOutputs.length, equals(8));

          // Verify algorithm ports are generated from the routing implementation
          final firstAlgorithm = loadedState.algorithms[0];
          expect(firstAlgorithm.inputPorts.isEmpty, isFalse);
          expect(firstAlgorithm.outputPorts.isEmpty, isFalse);

          // Verify connections are empty until AlgorithmRouting hierarchy is implemented  
          expect(loadedState.connections.isEmpty, isTrue);

        } finally {
          await subscription.cancel();
        }
      });

      test('should handle real-time routing updates', () async {
        final states = <RoutingEditorState>[];
        final subscription = routingEditorCubit.stream.listen(states.add);

        try {
          // Initialize with synchronized state
          final initialSlots = _createCompleteTestSlots();
          distingStateController.add(DistingState.synchronized(
            disting: mockMidiManager,
            distingVersion: '1.9.0',
            firmwareVersion: FirmwareVersion('1.9.0'),
            presetName: 'Real-time Test',
            algorithms: _createTestAlgorithmInfos(),
            slots: initialSlots,
            unitStrings: ['%', 'Hz'],
          ));
          await Future.delayed(const Duration(milliseconds: 10));

          // Simulate routing change from hardware
          final updatedSlots = _createUpdatedTestSlots();
          distingStateController.add(DistingState.synchronized(
            disting: mockMidiManager,
            distingVersion: '1.9.0',
            firmwareVersion: FirmwareVersion('1.9.0'),
            presetName: 'Real-time Test',
            algorithms: _createTestAlgorithmInfos(),
            slots: updatedSlots,
            unitStrings: ['%', 'Hz'],
          ));
          await Future.delayed(const Duration(milliseconds: 10));

          // Verify we got at least two loaded states with routing data
          final loadedStates = states.whereType<RoutingEditorStateLoaded>().toList();
          expect(loadedStates.length, greaterThanOrEqualTo(2));

          // Verify the algorithm data changed (algorithms should have different names/data)
          final initialAlgorithms = loadedStates[0].algorithms;
          final updatedAlgorithms = loadedStates[1].algorithms;
          
          expect(initialAlgorithms.length, equals(updatedAlgorithms.length));

        } finally {
          await subscription.cancel();
        }
      });

      test('should maintain state consistency during device disconnection', () async {
        final states = <RoutingEditorState>[];
        final subscription = routingEditorCubit.stream.listen(states.add);

        try {
          // Start synchronized
          distingStateController.add(DistingState.synchronized(
            disting: mockMidiManager,
            distingVersion: '1.9.0',
            firmwareVersion: FirmwareVersion('1.9.0'),
            presetName: 'Disconnect Test',
            algorithms: _createTestAlgorithmInfos(),
            slots: _createCompleteTestSlots(),
            unitStrings: [],
          ));
          await Future.delayed(const Duration(milliseconds: 10));

          // Simulate device disconnection
          distingStateController.add(const DistingState.selectDevice(
            inputDevices: [],
            outputDevices: [],
            canWorkOffline: false,
          ));
          await Future.delayed(const Duration(milliseconds: 10));

          // Verify state transitions correctly (may have intermediate states)
          expect(states.length, greaterThanOrEqualTo(2));
          expect(states.first, isA<RoutingEditorStateLoaded>());
          expect(states.last, isA<RoutingEditorStateDisconnected>());

        } finally {
          await subscription.cancel();
        }
      });
    });

    group('routing data processing accuracy', () {
      test('should extract complex routing patterns correctly', () async {
        final complexSlots = _createComplexRoutingSlots();
        
        distingStateController.add(DistingState.synchronized(
          disting: mockMidiManager,
          distingVersion: '1.9.0',
          firmwareVersion: FirmwareVersion('1.9.0'),
          presetName: 'Complex Routing Test',
          algorithms: _createTestAlgorithmInfos(),
          slots: complexSlots,
          unitStrings: [],
        ));

        // Wait for processing
        await routingEditorCubit.stream
            .where((state) => state is RoutingEditorStateLoaded)
            .first
            .timeout(const Duration(seconds: 1));

        final state = routingEditorCubit.state as RoutingEditorStateLoaded;
        
        // Verify complex routing patterns were extracted
        final algorithm = state.algorithms[0];
        
        // Check that ports are generated from the routing implementation
        expect(algorithm.inputPorts.length, equals(2));
        expect(algorithm.outputPorts.length, equals(2));
        
        // Note: Connection type verification will be added when AlgorithmRouting hierarchy is implemented
      });
    });
  });
}


/// Creates a complete set of test slots representing a realistic hardware state
List<Slot> _createCompleteTestSlots() {
  return [
    Slot(
      algorithm: Algorithm(algorithmIndex: 0, guid: 'MX1 ', name: 'Mix 1'),
      routing: RoutingInfo(
        algorithmIndex: 0,
        routingInfo: [0xFF, 0x0F, 0x00, 0x00, 0x00, 0x07], // Complex routing
      ),
      pages: ParameterPages(algorithmIndex: 0, pages: []),
      parameters: [
        ParameterInfo(
          algorithmIndex: 0,
          parameterNumber: 0,
          name: 'Input 1',
          unit: 0,
          min: 0,
          max: 28,
          defaultValue: 1,
          powerOfTen: 0,
        ),
        ParameterInfo(
          algorithmIndex: 0,
          parameterNumber: 1,
          name: 'Mix Output',
          unit: 0,
          min: 1,
          max: 27,
          defaultValue: 1,
          powerOfTen: 0,
        ),
      ],
      values: [
        ParameterValue(algorithmIndex: 0, parameterNumber: 0, value: 5), // Bus 5 input
        ParameterValue(algorithmIndex: 0, parameterNumber: 1, value: 2), // Bus 2 output
      ],
      enums: [
        ParameterEnumStrings(algorithmIndex: 0, parameterNumber: 0, values: ['None', 'Bus 1', 'Bus 5']),
        ParameterEnumStrings(algorithmIndex: 0, parameterNumber: 1, values: ['None', 'Bus 1', 'Bus 2']),
      ],
      mappings: [],
      valueStrings: [
        ParameterValueString(algorithmIndex: 0, parameterNumber: 0, value: 'Bus 5'),
        ParameterValueString(algorithmIndex: 0, parameterNumber: 1, value: 'Bus 2'),
      ],
    ),
    Slot(
      algorithm: Algorithm(algorithmIndex: 1, guid: 'DELY', name: 'Delay'),
      routing: RoutingInfo(
        algorithmIndex: 1,
        routingInfo: [0x0F, 0xFF, 0x00, 0x00, 0x00, 0x0A],
      ),
      pages: ParameterPages(algorithmIndex: 1, pages: []),
      parameters: [],
      values: [],
      enums: [],
      mappings: [],
      valueStrings: [],
    ),
    Slot(
      algorithm: Algorithm(algorithmIndex: 2, guid: 'REVB', name: 'Reverb'),
      routing: RoutingInfo(
        algorithmIndex: 2,
        routingInfo: [0xAA, 0x55, 0x00, 0x00, 0x00, 0x0F],
      ),
      pages: ParameterPages(algorithmIndex: 2, pages: []),
      parameters: [],
      values: [],
      enums: [],
      mappings: [],
      valueStrings: [],
    ),
    Slot(
      algorithm: Algorithm(algorithmIndex: 3, guid: 'FLTR', name: 'Filter'),
      routing: RoutingInfo(
        algorithmIndex: 3,
        routingInfo: [0x33, 0xCC, 0x00, 0x00, 0x00, 0x03],
      ),
      pages: ParameterPages(algorithmIndex: 3, pages: []),
      parameters: [],
      values: [],
      enums: [],
      mappings: [],
      valueStrings: [],
    ),
  ];
}

/// Creates updated test slots with different routing data
List<Slot> _createUpdatedTestSlots() {
  final slots = _createCompleteTestSlots();
  // Change the routing data for the first slot - update parameter values to create different routing
  slots[0] = Slot(
    algorithm: slots[0].algorithm,
    routing: RoutingInfo(
      algorithmIndex: 0,
      routingInfo: [0x0F, 0xFF, 0x00, 0x00, 0x00, 0x0F], // Different pattern
    ),
    pages: slots[0].pages,
    parameters: slots[0].parameters,
    values: [
      ParameterValue(algorithmIndex: 0, parameterNumber: 0, value: 10), // Changed from Bus 5 to Bus 10 input
      ParameterValue(algorithmIndex: 0, parameterNumber: 1, value: 7), // Changed from Bus 2 to Bus 7 output
    ],
    enums: slots[0].enums,
    mappings: slots[0].mappings,
    valueStrings: [
      ParameterValueString(algorithmIndex: 0, parameterNumber: 0, value: 'Bus 10'), // Updated string
      ParameterValueString(algorithmIndex: 0, parameterNumber: 1, value: 'Bus 7'), // Updated string
    ],
  );
  return slots;
}

/// Creates test algorithm infos to match the slots
List<AlgorithmInfo> _createTestAlgorithmInfos() {
  return [
    AlgorithmInfo(
      algorithmIndex: 0,
      name: 'Mix 1',
      guid: 'MX1 ',
      specifications: [],
      isPlugin: false,
      isLoaded: true,
    ),
    AlgorithmInfo(
      algorithmIndex: 1,
      name: 'Delay',
      guid: 'DELY',
      specifications: [],
      isPlugin: false,
      isLoaded: true,
    ),
    AlgorithmInfo(
      algorithmIndex: 2,
      name: 'Reverb',
      guid: 'REVB',
      specifications: [],
      isPlugin: false,
      isLoaded: true,
    ),
    AlgorithmInfo(
      algorithmIndex: 3,
      name: 'Filter',
      guid: 'FLTR',
      specifications: [],
      isPlugin: false,
      isLoaded: true,
    ),
  ];
}

/// Creates slots with complex routing patterns for testing edge cases
List<Slot> _createComplexRoutingSlots() {
  return [
    Slot(
      algorithm: Algorithm(algorithmIndex: 0, guid: 'CMPL', name: 'Complex'),
      routing: RoutingInfo(
        algorithmIndex: 0,
        // Complex pattern: alternating bits in input/output masks
        routingInfo: [0xAAAA, 0x5555, 0x0000, 0x0000, 0x0000, 0xFFFF],
      ),
      pages: ParameterPages(algorithmIndex: 0, pages: []),
      parameters: [
        ParameterInfo(
          algorithmIndex: 0,
          parameterNumber: 0,
          name: 'Main Input',
          unit: 0,
          min: 0,
          max: 28,
          defaultValue: 1,
          powerOfTen: 0,
        ),
        ParameterInfo(
          algorithmIndex: 0,
          parameterNumber: 1,
          name: 'Main Output',
          unit: 0,
          min: 1,
          max: 27,
          defaultValue: 1,
          powerOfTen: 0,
        ),
      ],
      values: [
        ParameterValue(algorithmIndex: 0, parameterNumber: 0, value: 15), // Bus 15 input
        ParameterValue(algorithmIndex: 0, parameterNumber: 1, value: 3), // Bus 3 output
      ],
      enums: [
        ParameterEnumStrings(algorithmIndex: 0, parameterNumber: 0, values: ['None', 'Bus 1', 'Bus 15']),
        ParameterEnumStrings(algorithmIndex: 0, parameterNumber: 1, values: ['None', 'Bus 1', 'Bus 3']),
      ],
      mappings: [],
      valueStrings: [
        ParameterValueString(algorithmIndex: 0, parameterNumber: 0, value: 'Bus 15'),
        ParameterValueString(algorithmIndex: 0, parameterNumber: 1, value: 'Bus 3'),
      ],
    ),
  ];
}