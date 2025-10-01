import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:nt_helper/cubit/disting_cubit.dart';
import 'package:nt_helper/db/database.dart';
import 'package:nt_helper/db/daos/metadata_dao.dart';
import 'package:nt_helper/domain/disting_nt_sysex.dart';
import 'package:nt_helper/domain/i_disting_midi_manager.dart';
import 'package:nt_helper/models/firmware_version.dart';
import 'package:nt_helper/models/packed_mapping_data.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'performance_page_mapping_test.mocks.dart';

@GenerateMocks([AppDatabase, IDistingMidiManager, MetadataDao])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DistingCubit - Performance Page Mapping Optimistic Update', () {
    late DistingCubit cubit;
    late MockAppDatabase mockDatabase;
    late MockIDistingMidiManager mockMidiManager;
    late MockMetadataDao mockMetadataDao;

    setUp(() async {
      // Initialize SharedPreferences for testing
      SharedPreferences.setMockInitialValues({});

      mockDatabase = MockAppDatabase();
      mockMidiManager = MockIDistingMidiManager();
      mockMetadataDao = MockMetadataDao();

      // Mock the metadataDao getter
      when(mockDatabase.metadataDao).thenReturn(mockMetadataDao);

      cubit = DistingCubit(mockDatabase);
    });

    tearDown(() {
      cubit.close();
    });

    test('should perform optimistic update immediately', () async {
      // Arrange: Create a synchronized state with a slot containing mappings
      final testSlot = Slot(
        algorithm: Algorithm(
          algorithmIndex: 0,
          guid: 'test-guid',
          name: 'Test Algorithm',
        ),
        routing: RoutingInfo(
          algorithmIndex: 0,
          routingInfo: List.filled(6, 0),
        ),
        pages: ParameterPages(
          algorithmIndex: 0,
          pages: [],
        ),
        parameters: [
          ParameterInfo(
            algorithmIndex: 0,
            parameterNumber: 0,
            defaultValue: 0,
            name: 'Test Param',
            unit: 0,
            min: 0,
            max: 100,
            powerOfTen: 0,
          ),
        ],
        values: [
          ParameterValue(
            algorithmIndex: 0,
            parameterNumber: 0,
            value: 50,
          ),
        ],
        enums: [],
        mappings: [
          Mapping(
            algorithmIndex: 0,
            parameterNumber: 0,
            packedMappingData: PackedMappingData(
              source: 0,
              cvInput: 0,
              isUnipolar: false,
              isGate: false,
              volts: 0,
              delta: 0,
              midiChannel: 0,
              midiMappingType: MidiMappingType.cc,
              midiCC: 0,
              isMidiEnabled: false,
              isMidiSymmetric: false,
              isMidiRelative: false,
              midiMin: 0,
              midiMax: 127,
              i2cCC: 0,
              isI2cEnabled: false,
              isI2cSymmetric: false,
              i2cMin: 0,
              i2cMax: 100,
              perfPageIndex: 0, // Initially not assigned
              version: 5,
            ),
          ),
        ],
        valueStrings: [],
      );

      // Emit a synchronized state
      cubit.emit(
        DistingState.synchronized(
          disting: mockMidiManager,
          distingVersion: '1.0.0',
          firmwareVersion: FirmwareVersion('1.0.0'),
          presetName: 'Test Preset',
          algorithms: [],
          slots: [testSlot],
          unitStrings: const [],
          inputDevice: null,
          outputDevice: null,
          screenshot: null,
          loading: false,
          demo: false,
          offline: false,
        ),
      );

      // Mock the MIDI manager methods
      when(mockMidiManager.setPerformancePageMapping(any, any, any))
          .thenAnswer((_) async {});

      when(mockMidiManager.requestMappings(any, any)).thenAnswer(
        (_) async => Mapping(
          algorithmIndex: 0,
          parameterNumber: 0,
          packedMappingData: PackedMappingData(
            source: 0,
            cvInput: 0,
            isUnipolar: false,
            isGate: false,
            volts: 0,
            delta: 0,
            midiChannel: 0,
            midiMappingType: MidiMappingType.cc,
            midiCC: 0,
            isMidiEnabled: false,
            isMidiSymmetric: false,
            isMidiRelative: false,
            midiMin: 0,
            midiMax: 127,
            i2cCC: 0,
            isI2cEnabled: false,
            isI2cSymmetric: false,
            i2cMin: 0,
            i2cMax: 100,
            perfPageIndex: 5, // Hardware confirms the value
            version: 5,
          ),
        ),
      );

      // Act: Set performance page mapping to page 5
      await cubit.setPerformancePageMapping(0, 0, 5);

      // Assert: Verify optimistic update happened immediately
      final currentState = cubit.state;
      expect(currentState, isA<DistingStateSynchronized>());

      final syncState = currentState as DistingStateSynchronized;
      expect(syncState.slots.length, equals(1));
      expect(syncState.slots[0].mappings.length, equals(1));
      expect(
        syncState.slots[0].mappings[0].packedMappingData.perfPageIndex,
        equals(5),
      );

      // Verify MIDI manager was called to send update to hardware
      verify(mockMidiManager.setPerformancePageMapping(0, 0, 5)).called(1);

      // Verify MIDI manager was called to verify the mapping
      verify(mockMidiManager.requestMappings(0, 0)).called(1);
    });

    test('should handle hardware mismatch and update UI with hardware value',
        () async {
      // Arrange
      final testSlot = Slot(
        algorithm: Algorithm(
          algorithmIndex: 0,
          guid: 'test-guid',
          name: 'Test Algorithm',
        ),
        routing: RoutingInfo(
          algorithmIndex: 0,
          routingInfo: List.filled(6, 0),
        ),
        pages: ParameterPages(
          algorithmIndex: 0,
          pages: [],
        ),
        parameters: [
          ParameterInfo(
            algorithmIndex: 0,
            parameterNumber: 0,
            defaultValue: 0,
            name: 'Test Param',
            unit: 0,
            min: 0,
            max: 100,
            powerOfTen: 0,
          ),
        ],
        values: [
          ParameterValue(
            algorithmIndex: 0,
            parameterNumber: 0,
            value: 50,
          ),
        ],
        enums: [],
        mappings: [
          Mapping(
            algorithmIndex: 0,
            parameterNumber: 0,
            packedMappingData: PackedMappingData(
              source: 0,
              cvInput: 0,
              isUnipolar: false,
              isGate: false,
              volts: 0,
              delta: 0,
              midiChannel: 0,
              midiMappingType: MidiMappingType.cc,
              midiCC: 0,
              isMidiEnabled: false,
              isMidiSymmetric: false,
              isMidiRelative: false,
              midiMin: 0,
              midiMax: 127,
              i2cCC: 0,
              isI2cEnabled: false,
              isI2cSymmetric: false,
              i2cMin: 0,
              i2cMax: 100,
              perfPageIndex: 0,
              version: 5,
            ),
          ),
        ],
        valueStrings: [],
      );

      cubit.emit(
        DistingState.synchronized(
          disting: mockMidiManager,
          distingVersion: '1.0.0',
          firmwareVersion: FirmwareVersion('1.0.0'),
          presetName: 'Test Preset',
          algorithms: [],
          slots: [testSlot],
          unitStrings: const [],
          inputDevice: null,
          outputDevice: null,
          screenshot: null,
          loading: false,
          demo: false,
          offline: false,
        ),
      );

      // Mock hardware to return a different value than requested
      when(mockMidiManager.setPerformancePageMapping(any, any, any))
          .thenAnswer((_) async {});

      when(mockMidiManager.requestMappings(any, any)).thenAnswer(
        (_) async => Mapping(
          algorithmIndex: 0,
          parameterNumber: 0,
          packedMappingData: PackedMappingData(
            source: 0,
            cvInput: 0,
            isUnipolar: false,
            isGate: false,
            volts: 0,
            delta: 0,
            midiChannel: 0,
            midiMappingType: MidiMappingType.cc,
            midiCC: 0,
            isMidiEnabled: false,
            isMidiSymmetric: false,
            isMidiRelative: false,
            midiMin: 0,
            midiMax: 127,
            i2cCC: 0,
            isI2cEnabled: false,
            isI2cSymmetric: false,
            i2cMin: 0,
            i2cMax: 100,
            perfPageIndex: 3, // Hardware returns different value!
            version: 5,
          ),
        ),
      );

      // Act: Request page 5 but hardware will return page 3
      await cubit.setPerformancePageMapping(0, 0, 5);

      // Assert: UI should be updated with hardware value (3), not optimistic value (5)
      final currentState = cubit.state;
      expect(currentState, isA<DistingStateSynchronized>());

      final syncState = currentState as DistingStateSynchronized;
      expect(
        syncState.slots[0].mappings[0].packedMappingData.perfPageIndex,
        equals(3), // Hardware wins!
      );
    });

    test('should not trigger full preset refresh', () async {
      // Arrange
      final testSlot = Slot(
        algorithm: Algorithm(
          algorithmIndex: 0,
          guid: 'test-guid',
          name: 'Test Algorithm',
        ),
        routing: RoutingInfo(
          algorithmIndex: 0,
          routingInfo: List.filled(6, 0),
        ),
        pages: ParameterPages(
          algorithmIndex: 0,
          pages: [],
        ),
        parameters: [
          ParameterInfo(
            algorithmIndex: 0,
            parameterNumber: 0,
            defaultValue: 0,
            name: 'Test Param',
            unit: 0,
            min: 0,
            max: 100,
            powerOfTen: 0,
          ),
        ],
        values: [
          ParameterValue(
            algorithmIndex: 0,
            parameterNumber: 0,
            value: 50,
          ),
        ],
        enums: [],
        mappings: [
          Mapping(
            algorithmIndex: 0,
            parameterNumber: 0,
            packedMappingData: PackedMappingData(
              source: 0,
              cvInput: 0,
              isUnipolar: false,
              isGate: false,
              volts: 0,
              delta: 0,
              midiChannel: 0,
              midiMappingType: MidiMappingType.cc,
              midiCC: 0,
              isMidiEnabled: false,
              isMidiSymmetric: false,
              isMidiRelative: false,
              midiMin: 0,
              midiMax: 127,
              i2cCC: 0,
              isI2cEnabled: false,
              isI2cSymmetric: false,
              i2cMin: 0,
              i2cMax: 100,
              perfPageIndex: 0,
              version: 5,
            ),
          ),
        ],
        valueStrings: [],
      );

      cubit.emit(
        DistingState.synchronized(
          disting: mockMidiManager,
          distingVersion: '1.0.0',
          firmwareVersion: FirmwareVersion('1.0.0'),
          presetName: 'Test Preset',
          algorithms: [],
          slots: [testSlot],
          unitStrings: const [],
          inputDevice: null,
          outputDevice: null,
          screenshot: null,
          loading: false,
          demo: false,
          offline: false,
        ),
      );

      when(mockMidiManager.setPerformancePageMapping(any, any, any))
          .thenAnswer((_) async {});

      when(mockMidiManager.requestMappings(any, any)).thenAnswer(
        (_) async => Mapping(
          algorithmIndex: 0,
          parameterNumber: 0,
          packedMappingData: PackedMappingData(
            source: 0,
            cvInput: 0,
            isUnipolar: false,
            isGate: false,
            volts: 0,
            delta: 0,
            midiChannel: 0,
            midiMappingType: MidiMappingType.cc,
            midiCC: 0,
            isMidiEnabled: false,
            isMidiSymmetric: false,
            isMidiRelative: false,
            midiMin: 0,
            midiMax: 127,
            i2cCC: 0,
            isI2cEnabled: false,
            isI2cSymmetric: false,
            i2cMin: 0,
            i2cMax: 100,
            perfPageIndex: 5,
            version: 5,
          ),
        ),
      );

      // Act
      await cubit.setPerformancePageMapping(0, 0, 5);

      // Assert: Verify that ONLY the specific mapping was requested
      // NOT the entire preset (requestNumAlgorithmsInPreset, requestPresetName, etc.)
      verify(mockMidiManager.requestMappings(0, 0)).called(1);
      verifyNever(mockMidiManager.requestNumAlgorithmsInPreset());
      verifyNever(mockMidiManager.requestPresetName());
    });

    test('should handle invalid slot index gracefully', () async {
      // Arrange
      cubit.emit(
        DistingState.synchronized(
          disting: mockMidiManager,
          distingVersion: '1.0.0',
          firmwareVersion: FirmwareVersion('1.0.0'),
          presetName: 'Test Preset',
          algorithms: [],
          slots: [], // Empty slots
          unitStrings: const [],
          inputDevice: null,
          outputDevice: null,
          screenshot: null,
          loading: false,
          demo: false,
          offline: false,
        ),
      );

      // Act: Try to set performance page on non-existent slot
      await cubit.setPerformancePageMapping(0, 0, 5);

      // Assert: Should not call MIDI manager
      verifyNever(mockMidiManager.setPerformancePageMapping(any, any, any));
      verifyNever(mockMidiManager.requestMappings(any, any));
    });

    test('should revert to original value when all verification attempts fail',
        () async {
      // Arrange
      final testSlot = Slot(
        algorithm: Algorithm(
          algorithmIndex: 0,
          guid: 'test-guid',
          name: 'Test Algorithm',
        ),
        routing: RoutingInfo(
          algorithmIndex: 0,
          routingInfo: List.filled(6, 0),
        ),
        pages: ParameterPages(
          algorithmIndex: 0,
          pages: [],
        ),
        parameters: [
          ParameterInfo(
            algorithmIndex: 0,
            parameterNumber: 0,
            defaultValue: 0,
            name: 'Test Param',
            unit: 0,
            min: 0,
            max: 100,
            powerOfTen: 0,
          ),
        ],
        values: [
          ParameterValue(
            algorithmIndex: 0,
            parameterNumber: 0,
            value: 50,
          ),
        ],
        enums: [],
        mappings: [
          Mapping(
            algorithmIndex: 0,
            parameterNumber: 0,
            packedMappingData: PackedMappingData(
              source: 0,
              cvInput: 0,
              isUnipolar: false,
              isGate: false,
              volts: 0,
              delta: 0,
              midiChannel: 0,
              midiMappingType: MidiMappingType.cc,
              midiCC: 0,
              isMidiEnabled: false,
              isMidiSymmetric: false,
              isMidiRelative: false,
              midiMin: 0,
              midiMax: 127,
              i2cCC: 0,
              isI2cEnabled: false,
              isI2cSymmetric: false,
              i2cMin: 0,
              i2cMax: 100,
              perfPageIndex: 0, // Original value
              version: 5,
            ),
          ),
        ],
        valueStrings: [],
      );

      cubit.emit(
        DistingState.synchronized(
          disting: mockMidiManager,
          distingVersion: '1.0.0',
          firmwareVersion: FirmwareVersion('1.0.0'),
          presetName: 'Test Preset',
          algorithms: [],
          slots: [testSlot],
          unitStrings: const [],
          inputDevice: null,
          outputDevice: null,
          screenshot: null,
          loading: false,
          demo: false,
          offline: false,
        ),
      );

      when(mockMidiManager.setPerformancePageMapping(any, any, any))
          .thenAnswer((_) async {});

      // Mock hardware to return null for all attempts (persistent failure)
      when(mockMidiManager.requestMappings(any, any))
          .thenAnswer((_) async => null);

      // Act: Should revert to original value after all attempts fail
      await cubit.setPerformancePageMapping(0, 0, 5);

      // Assert: Should have reverted to original value (0), not optimistic value (5)
      final currentState = cubit.state;
      expect(currentState, isA<DistingStateSynchronized>());

      final syncState = currentState as DistingStateSynchronized;
      expect(
        syncState.slots[0].mappings[0].packedMappingData.perfPageIndex,
        equals(0), // Reverted to original value
      );

      // Verify 4 retry attempts were made
      verify(mockMidiManager.requestMappings(0, 0)).called(4);
    });

    test('should retry verification when hardware is slow to update', () async {
      // Arrange
      final testSlot = Slot(
        algorithm: Algorithm(
          algorithmIndex: 0,
          guid: 'test-guid',
          name: 'Test Algorithm',
        ),
        routing: RoutingInfo(
          algorithmIndex: 0,
          routingInfo: List.filled(6, 0),
        ),
        pages: ParameterPages(
          algorithmIndex: 0,
          pages: [],
        ),
        parameters: [
          ParameterInfo(
            algorithmIndex: 0,
            parameterNumber: 0,
            defaultValue: 0,
            name: 'Test Param',
            unit: 0,
            min: 0,
            max: 100,
            powerOfTen: 0,
          ),
        ],
        values: [
          ParameterValue(
            algorithmIndex: 0,
            parameterNumber: 0,
            value: 50,
          ),
        ],
        enums: [],
        mappings: [
          Mapping(
            algorithmIndex: 0,
            parameterNumber: 0,
            packedMappingData: PackedMappingData(
              source: 0,
              cvInput: 0,
              isUnipolar: false,
              isGate: false,
              volts: 0,
              delta: 0,
              midiChannel: 0,
              midiMappingType: MidiMappingType.cc,
              midiCC: 0,
              isMidiEnabled: false,
              isMidiSymmetric: false,
              isMidiRelative: false,
              midiMin: 0,
              midiMax: 127,
              i2cCC: 0,
              isI2cEnabled: false,
              isI2cSymmetric: false,
              i2cMin: 0,
              i2cMax: 100,
              perfPageIndex: 0,
              version: 5,
            ),
          ),
        ],
        valueStrings: [],
      );

      cubit.emit(
        DistingState.synchronized(
          disting: mockMidiManager,
          distingVersion: '1.0.0',
          firmwareVersion: FirmwareVersion('1.0.0'),
          presetName: 'Test Preset',
          algorithms: [],
          slots: [testSlot],
          unitStrings: const [],
          inputDevice: null,
          outputDevice: null,
          screenshot: null,
          loading: false,
          demo: false,
          offline: false,
        ),
      );

      when(mockMidiManager.setPerformancePageMapping(any, any, any))
          .thenAnswer((_) async {});

      // Simulate hardware being slow: first 2 attempts return old value, 3rd returns new value
      var attemptCount = 0;
      when(mockMidiManager.requestMappings(any, any)).thenAnswer((_) async {
        attemptCount++;
        if (attemptCount <= 2) {
          // First two attempts: hardware hasn't updated yet
          return Mapping(
            algorithmIndex: 0,
            parameterNumber: 0,
            packedMappingData: PackedMappingData(
              source: 0,
              cvInput: 0,
              isUnipolar: false,
              isGate: false,
              volts: 0,
              delta: 0,
              midiChannel: 0,
              midiMappingType: MidiMappingType.cc,
              midiCC: 0,
              isMidiEnabled: false,
              isMidiSymmetric: false,
              isMidiRelative: false,
              midiMin: 0,
              midiMax: 127,
              i2cCC: 0,
              isI2cEnabled: false,
              isI2cSymmetric: false,
              i2cMin: 0,
              i2cMax: 100,
              perfPageIndex: 0, // Still old value
              version: 5,
            ),
          );
        } else {
          // Third attempt: hardware has updated
          return Mapping(
            algorithmIndex: 0,
            parameterNumber: 0,
            packedMappingData: PackedMappingData(
              source: 0,
              cvInput: 0,
              isUnipolar: false,
              isGate: false,
              volts: 0,
              delta: 0,
              midiChannel: 0,
              midiMappingType: MidiMappingType.cc,
              midiCC: 0,
              isMidiEnabled: false,
              isMidiSymmetric: false,
              isMidiRelative: false,
              midiMin: 0,
              midiMax: 127,
              i2cCC: 0,
              isI2cEnabled: false,
              isI2cSymmetric: false,
              i2cMin: 0,
              i2cMax: 100,
              perfPageIndex: 5, // Updated value
              version: 5,
            ),
          );
        }
      });

      // Act
      await cubit.setPerformancePageMapping(0, 0, 5);

      // Assert: Should have retried and eventually gotten correct value
      expect(attemptCount, equals(3)); // Should have made 3 attempts
      verify(mockMidiManager.requestMappings(0, 0)).called(3);

      final currentState = cubit.state;
      expect(currentState, isA<DistingStateSynchronized>());

      final syncState = currentState as DistingStateSynchronized;
      expect(
        syncState.slots[0].mappings[0].packedMappingData.perfPageIndex,
        equals(5), // Final value matches hardware
      );
    });

    test('should retry when hardware returns null then eventually succeeds',
        () async {
      // Arrange
      final testSlot = Slot(
        algorithm: Algorithm(
          algorithmIndex: 0,
          guid: 'test-guid',
          name: 'Test Algorithm',
        ),
        routing: RoutingInfo(
          algorithmIndex: 0,
          routingInfo: List.filled(6, 0),
        ),
        pages: ParameterPages(
          algorithmIndex: 0,
          pages: [],
        ),
        parameters: [
          ParameterInfo(
            algorithmIndex: 0,
            parameterNumber: 0,
            defaultValue: 0,
            name: 'Test Param',
            unit: 0,
            min: 0,
            max: 100,
            powerOfTen: 0,
          ),
        ],
        values: [
          ParameterValue(
            algorithmIndex: 0,
            parameterNumber: 0,
            value: 50,
          ),
        ],
        enums: [],
        mappings: [
          Mapping(
            algorithmIndex: 0,
            parameterNumber: 0,
            packedMappingData: PackedMappingData(
              source: 0,
              cvInput: 0,
              isUnipolar: false,
              isGate: false,
              volts: 0,
              delta: 0,
              midiChannel: 0,
              midiMappingType: MidiMappingType.cc,
              midiCC: 0,
              isMidiEnabled: false,
              isMidiSymmetric: false,
              isMidiRelative: false,
              midiMin: 0,
              midiMax: 127,
              i2cCC: 0,
              isI2cEnabled: false,
              isI2cSymmetric: false,
              i2cMin: 0,
              i2cMax: 100,
              perfPageIndex: 0,
              version: 5,
            ),
          ),
        ],
        valueStrings: [],
      );

      cubit.emit(
        DistingState.synchronized(
          disting: mockMidiManager,
          distingVersion: '1.0.0',
          firmwareVersion: FirmwareVersion('1.0.0'),
          presetName: 'Test Preset',
          algorithms: [],
          slots: [testSlot],
          unitStrings: const [],
          inputDevice: null,
          outputDevice: null,
          screenshot: null,
          loading: false,
          demo: false,
          offline: false,
        ),
      );

      when(mockMidiManager.setPerformancePageMapping(any, any, any))
          .thenAnswer((_) async {});

      // Simulate hardware being temporarily unavailable then recovering
      var attemptCount = 0;
      when(mockMidiManager.requestMappings(any, any)).thenAnswer((_) async {
        attemptCount++;
        if (attemptCount == 1) {
          return null; // First attempt fails
        } else {
          // Second attempt succeeds
          return Mapping(
            algorithmIndex: 0,
            parameterNumber: 0,
            packedMappingData: PackedMappingData(
              source: 0,
              cvInput: 0,
              isUnipolar: false,
              isGate: false,
              volts: 0,
              delta: 0,
              midiChannel: 0,
              midiMappingType: MidiMappingType.cc,
              midiCC: 0,
              isMidiEnabled: false,
              isMidiSymmetric: false,
              isMidiRelative: false,
              midiMin: 0,
              midiMax: 127,
              i2cCC: 0,
              isI2cEnabled: false,
              isI2cSymmetric: false,
              i2cMin: 0,
              i2cMax: 100,
              perfPageIndex: 5,
              version: 5,
            ),
          );
        }
      });

      // Act
      await cubit.setPerformancePageMapping(0, 0, 5);

      // Assert: Should have retried after null response
      expect(attemptCount, equals(2));
      verify(mockMidiManager.requestMappings(0, 0)).called(2);

      final currentState = cubit.state;
      final syncState = currentState as DistingStateSynchronized;
      expect(
        syncState.slots[0].mappings[0].packedMappingData.perfPageIndex,
        equals(5),
      );
    });
  });
}
