import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:nt_helper/cubit/disting_cubit.dart';
import 'package:nt_helper/domain/i_disting_midi_manager.dart';
import 'package:nt_helper/models/firmware_version.dart';
import 'package:nt_helper/services/auto_routing_service.dart';

@GenerateMocks([DistingCubit, IDistingMidiManager])
import 'auto_routing_service_test.mocks.dart';

void main() {
  setUpAll(() {
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

  group('AutoRoutingService - Physical Node Connections', () {
    late MockDistingCubit mockCubit;
    late AutoRoutingService service;
    late MockIDistingMidiManager mockDisting;

    setUp(() {
      mockCubit = MockDistingCubit();
      service = AutoRoutingService(mockCubit);
      mockDisting = MockIDistingMidiManager();
      
      // Default mock for state when not specifically mocked
      when(mockCubit.state).thenReturn(
        DistingState.synchronized(
          disting: mockDisting,
          distingVersion: '',
          firmwareVersion: FirmwareVersion('1.0.0'),
          presetName: 'Test',
          algorithms: [],
          slots: [],
          unitStrings: [],
        ),
      );
    });

    group('physical node connection handling', () {
      test('should handle physical input ports I1-I12 without RangeError', () async {
        // Test all 12 physical input ports can be disconnected without error
        for (int i = 1; i <= 12; i++) {
          // This should not throw RangeError
          await service.removeConnection(
            sourceAlgorithmIndex: -2, // Physical input node
            sourcePortId: 'physical_input_$i',
            targetAlgorithmIndex: 0, // Algorithm in slot 0
            targetPortId: 'input',
          );
        }
        
        // If we reach here, no RangeError was thrown
        expect(true, isTrue);
      });

      test('should handle physical output ports O1-O8 without RangeError', () async {
        // Test all 8 physical output ports can be disconnected without error
        for (int i = 1; i <= 8; i++) {
          // This should not throw RangeError
          await service.removeConnection(
            sourceAlgorithmIndex: 0, // Algorithm in slot 0
            sourcePortId: 'output',
            targetAlgorithmIndex: -3, // Physical output node
            targetPortId: 'physical_output_$i',
          );
        }
        
        // If we reach here, no RangeError was thrown
        expect(true, isTrue);
      });
    });

    group('removeConnection with physical nodes', () {
      test('should clear algorithm parameter when removing physical input to algorithm connection', () async {
        // Test removing connection from physical input I4 to algorithm
        // Should clear algorithm's input parameter but skip physical node
        
        await service.removeConnection(
          sourceAlgorithmIndex: -2, // Physical input node
          sourcePortId: 'physical_input_4',
          targetAlgorithmIndex: 0, // Algorithm in slot 0
          targetPortId: 'input',
        );
        
        // Verify algorithm's input parameter was cleared (source is physical, so only target cleared)
        verify(mockCubit.updateParameterValue(
          algorithmIndex: 0, // Target algorithm
          parameterNumber: 1, // Fallback parameter number for input
          value: 0,
          userIsChangingTheValue: true,
        )).called(1);
        
        // Verify only one updateParameterValue call happened (for the algorithm)
        verify(mockCubit.state).called(greaterThan(0)); // Allow state access
        verifyNever(mockCubit.updateParameterValue(
          algorithmIndex: -2, // Physical source should not be updated
          parameterNumber: anyNamed('parameterNumber'),
          value: anyNamed('value'),
          userIsChangingTheValue: anyNamed('userIsChangingTheValue'),
        ));
      });

      test('should clear algorithm parameter when removing algorithm to physical output connection', () async {
        // Test removing connection from algorithm to physical output O1
        // Should clear algorithm's output parameter but skip physical node
        
        await service.removeConnection(
          sourceAlgorithmIndex: 0, // Algorithm in slot 0
          sourcePortId: 'output',
          targetAlgorithmIndex: -3, // Physical output node
          targetPortId: 'physical_output_1',
        );
        
        // Verify algorithm's output parameter was cleared (target is physical, so only source cleared)
        verify(mockCubit.updateParameterValue(
          algorithmIndex: 0, // Source algorithm
          parameterNumber: 0, // Fallback parameter number for output
          value: 0,
          userIsChangingTheValue: true,
        )).called(1);
        
        // Verify only one updateParameterValue call happened (for the algorithm)
        verify(mockCubit.state).called(greaterThan(0)); // Allow state access
        verifyNever(mockCubit.updateParameterValue(
          algorithmIndex: -3, // Physical target should not be updated
          parameterNumber: anyNamed('parameterNumber'),
          value: anyNamed('value'),
          userIsChangingTheValue: anyNamed('userIsChangingTheValue'),
        ));
      });

      test('should skip all parameters when removing physical input to physical output connection', () async {
        // Test removing connection from physical input to physical output
        // Should skip both parameters since both are physical nodes
        
        await service.removeConnection(
          sourceAlgorithmIndex: -2, // Physical input node
          sourcePortId: 'physical_input_1',
          targetAlgorithmIndex: -3, // Physical output node
          targetPortId: 'physical_output_1',
        );
        
        // Verify no parameter updates were called (both are physical nodes)
        verifyNever(mockCubit.updateParameterValue(
          algorithmIndex: anyNamed('algorithmIndex'),
          parameterNumber: anyNamed('parameterNumber'),
          value: anyNamed('value'),
          userIsChangingTheValue: anyNamed('userIsChangingTheValue'),
        ));
      });
    });

    group('createConnection with physical nodes', () {
      test('should update algorithm parameter when creating physical input to algorithm connection', () async {
        // Test creating connection from physical input I4 to algorithm
        // Should update algorithm's input parameter but skip physical node
        
        final result = await service.assignBusForConnection(
          sourceAlgorithmIndex: -2, // Physical input node
          sourcePortId: 'physical_input_4',
          targetAlgorithmIndex: 0, // Algorithm in slot 0
          targetPortId: 'clock',
          existingConnections: [],
        );
        
        // Verify the bus assignment uses fixed bus 4 for I4
        expect(result.sourceBus, equals(4));
        
        // Verify algorithm's input parameter update is included
        expect(result.parameterUpdates, hasLength(1));
        expect(result.parameterUpdates.first.algorithmIndex, equals(0)); // Target algorithm
        expect(result.parameterUpdates.first.value, equals(4)); // Bus 4 for I4
        
        // No physical source parameter update (negative index skipped)
        expect(result.parameterUpdates.where((p) => p.algorithmIndex == -2), isEmpty);
      });

      test('should update algorithm parameter when creating algorithm to physical output connection', () async {
        // Test creating connection from algorithm to physical output O1
        // Should update algorithm's output parameter but skip physical node
        
        final result = await service.assignBusForConnection(
          sourceAlgorithmIndex: 0, // Algorithm in slot 0
          sourcePortId: 'output',
          targetAlgorithmIndex: -3, // Physical output node
          targetPortId: 'physical_output_1',
          existingConnections: [],
        );
        
        // Verify the bus assignment uses fixed bus 13 for O1 (12 + 1)
        expect(result.sourceBus, equals(13));
        
        // Verify algorithm's output parameter update is included
        expect(result.parameterUpdates, hasLength(1));
        expect(result.parameterUpdates.first.algorithmIndex, equals(0)); // Source algorithm
        expect(result.parameterUpdates.first.value, equals(13)); // Bus 13 for O1
        
        // No physical target parameter update (negative index skipped)
        expect(result.parameterUpdates.where((p) => p.algorithmIndex == -3), isEmpty);
      });

      test('should skip all parameters when creating physical input to physical output connection', () async {
        // Test creating connection from physical input to physical output
        // Should skip both parameters since both are physical nodes
        
        final result = await service.assignBusForConnection(
          sourceAlgorithmIndex: -2, // Physical input node
          sourcePortId: 'physical_input_1',
          targetAlgorithmIndex: -3, // Physical output node
          targetPortId: 'physical_output_1',
          existingConnections: [],
        );
        
        // Verify the bus assignment uses fixed bus 1 for I1
        expect(result.sourceBus, equals(1));
        
        // Verify no parameter updates (both are physical nodes)
        expect(result.parameterUpdates, isEmpty);
      });
    });

    group('edge cases and boundary conditions', () {
      test('should not throw RangeError with negative indices in non-synchronized state', () async {
        // Mock non-synchronized state
        when(mockCubit.state).thenReturn(DistingState.initial());
        
        // This should not throw even when not synchronized
        await service.removeConnection(
          sourceAlgorithmIndex: -2, // Physical input node
          sourcePortId: 'physical_input_1',
          targetAlgorithmIndex: 0,
          targetPortId: 'input',
        );
        
        // If we reach here, no RangeError was thrown
        expect(true, isTrue);
      });

      test('should handle mixed physical/algorithm connection removal gracefully', () async {
        // Test scenario where we have mixed connection types in batch operations
        // Each should be handled according to its type
        
        // Physical input to algorithm - should clear algorithm parameter only
        await service.removeConnection(
          sourceAlgorithmIndex: -2,
          sourcePortId: 'physical_input_1',
          targetAlgorithmIndex: 0,
          targetPortId: 'input',
        );
        
        // Verify algorithm's input parameter was cleared (physical source skipped)
        verify(mockCubit.updateParameterValue(
          algorithmIndex: 0,
          parameterNumber: 1, // Fallback for input
          value: 0,
          userIsChangingTheValue: true,
        )).called(1);
      });
    });
  });
}