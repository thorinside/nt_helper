import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:nt_helper/cubit/disting_cubit.dart';
import 'package:nt_helper/domain/i_disting_midi_manager.dart';
import 'package:nt_helper/domain/disting_nt_sysex.dart';
import 'package:nt_helper/models/connection.dart';
import 'package:nt_helper/models/firmware_version.dart';
import 'package:nt_helper/services/auto_routing_service.dart';

@GenerateMocks([DistingCubit, IDistingMidiManager])
import 'auto_routing_real_scenarios_test.mocks.dart';

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

  group('AutoRoutingService - Real World Scenarios', () {
    late MockDistingCubit mockCubit;
    late AutoRoutingService service;
    late MockIDistingMidiManager mockDisting;

    setUp(() {
      mockCubit = MockDistingCubit();
      service = AutoRoutingService(mockCubit);
      mockDisting = MockIDistingMidiManager();
    });

    group('Poly Multisample to Stereo VCF', () {
      test('should correctly connect Poly Multisample outputs to stereo VCF inputs', () async {
        // This test replicates the real scenario where Poly Multisample outputs
        // should connect to VCF stereo inputs, not to physical outputs
        
        when(mockCubit.state).thenReturn(
          DistingState.synchronized(
            disting: mockDisting,
            distingVersion: '',
            firmwareVersion: FirmwareVersion('1.0.0'),
            presetName: 'Test',
            algorithms: [],
            slots: [
              // Slot 0 - Poly Multisample (pyms)
              Slot(
                algorithm: Algorithm(algorithmIndex: 0, guid: 'pyms', name: 'Poly Multisample'),
                routing: RoutingInfo(algorithmIndex: 0, routingInfo: []),
                pages: ParameterPages(algorithmIndex: 0, pages: []),
                parameters: [
                  // Poly Multisample typically has multiple output parameters
                  // Main Output L
                  ParameterInfo(
                    algorithmIndex: 0,
                    parameterNumber: 20,
                    name: 'Main Output L',
                    min: 0,
                    max: 28,
                    defaultValue: 0,
                    unit: 1, // bus type
                    powerOfTen: 0,
                  ),
                  // Main Output R
                  ParameterInfo(
                    algorithmIndex: 0,
                    parameterNumber: 21,
                    name: 'Main Output R',
                    min: 0,
                    max: 28,
                    defaultValue: 0,
                    unit: 1, // bus type
                    powerOfTen: 0,
                  ),
                ],
                values: [],
                enums: [],
                mappings: [],
                valueStrings: [],
              ),
              // Slot 1 - VCF with width=2
              Slot(
                algorithm: Algorithm(algorithmIndex: 1, guid: 'vcf2', name: 'VCF'),
                routing: RoutingInfo(algorithmIndex: 1, routingInfo: []),
                pages: ParameterPages(algorithmIndex: 1, pages: []),
                parameters: [
                  // Width parameter
                  ParameterInfo(
                    algorithmIndex: 1,
                    parameterNumber: 0,
                    name: 'Width',
                    min: 1,
                    max: 4,
                    defaultValue: 2,
                    unit: 0,
                    powerOfTen: 0,
                  ),
                  // Audio Input parameter
                  ParameterInfo(
                    algorithmIndex: 1,
                    parameterNumber: 1,
                    name: 'Audio Input',
                    min: 0,
                    max: 28,
                    defaultValue: 0,
                    unit: 1, // bus type
                    powerOfTen: 0,
                  ),
                ],
                values: [
                  ParameterValue(
                    algorithmIndex: 1,
                    parameterNumber: 0,
                    value: 2, // Width = 2 (stereo)
                  ),
                ],
                enums: [],
                mappings: [],
                valueStrings: [],
              ),
            ],
            unitStrings: [],
          ),
        );

        // Test connecting left output to VCF
        final resultLeft = await service.assignBusForConnection(
          sourceAlgorithmIndex: 0,
          sourcePortId: '20', // Main Output L parameter
          targetAlgorithmIndex: 1,
          targetPortId: '1', // Audio Input parameter
          existingConnections: [],
        );

        // Verify it assigns to aux buses, NOT physical outputs
        expect(resultLeft.sourceBus, greaterThanOrEqualTo(21)); // Should be aux bus
        expect(resultLeft.sourceBus, lessThanOrEqualTo(28));
        
        // Should recognize this is a stereo target and assign consecutive buses
        expect(resultLeft.channelCount, equals(2));
        expect(resultLeft.assignedBuses.length, equals(2));
        
        // Left output connection: Bus and channels verified
        // Assigned buses verified
      });

      test('should handle explicit stereo output to stereo input connection', () async {
        // When both source and target are stereo-capable
        
        when(mockCubit.state).thenReturn(
          DistingState.synchronized(
            disting: mockDisting,
            distingVersion: '',
            firmwareVersion: FirmwareVersion('1.0.0'),
            presetName: 'Test',
            algorithms: [],
            slots: [
              // Slot 0 - Stereo source (e.g., another VCF or effect)
              Slot(
                algorithm: Algorithm(algorithmIndex: 0, guid: 'efx2', name: 'Stereo Effect'),
                routing: RoutingInfo(algorithmIndex: 0, routingInfo: []),
                pages: ParameterPages(algorithmIndex: 0, pages: []),
                parameters: [
                  // Width parameter
                  ParameterInfo(
                    algorithmIndex: 0,
                    parameterNumber: 0,
                    name: 'Width',
                    min: 1,
                    max: 2,
                    defaultValue: 2,
                    unit: 0,
                    powerOfTen: 0,
                  ),
                  // Output bus parameter
                  ParameterInfo(
                    algorithmIndex: 0,
                    parameterNumber: 10,
                    name: 'Output',
                    min: 0,
                    max: 28,
                    defaultValue: 0,
                    unit: 1,
                    powerOfTen: 0,
                  ),
                ],
                values: [
                  ParameterValue(
                    algorithmIndex: 0,
                    parameterNumber: 0,
                    value: 2, // Stereo
                  ),
                ],
                enums: [],
                mappings: [],
                valueStrings: [],
              ),
              // Slot 1 - Stereo VCF
              Slot(
                algorithm: Algorithm(algorithmIndex: 1, guid: 'vcf2', name: 'VCF'),
                routing: RoutingInfo(algorithmIndex: 1, routingInfo: []),
                pages: ParameterPages(algorithmIndex: 1, pages: []),
                parameters: [
                  ParameterInfo(
                    algorithmIndex: 1,
                    parameterNumber: 0,
                    name: 'Width',
                    min: 1,
                    max: 4,
                    defaultValue: 2,
                    unit: 0,
                    powerOfTen: 0,
                  ),
                  ParameterInfo(
                    algorithmIndex: 1,
                    parameterNumber: 1,
                    name: 'Audio Input',
                    min: 0,
                    max: 28,
                    defaultValue: 0,
                    unit: 1,
                    powerOfTen: 0,
                  ),
                ],
                values: [
                  ParameterValue(
                    algorithmIndex: 1,
                    parameterNumber: 0,
                    value: 2, // Stereo
                  ),
                ],
                enums: [],
                mappings: [],
                valueStrings: [],
              ),
            ],
            unitStrings: [],
          ),
        );

        // Connect stereo to stereo
        final result = await service.assignBusForConnection(
          sourceAlgorithmIndex: 0,
          sourcePortId: '10', // Output parameter
          targetAlgorithmIndex: 1,
          targetPortId: '1', // Audio Input parameter
          existingConnections: [],
        );

        // Should handle stereo-to-stereo properly
        expect(result.channelCount, equals(2));
        expect(result.assignedBuses[0], greaterThanOrEqualTo(21)); // Aux bus
        expect(result.assignedBuses[1], equals(result.assignedBuses[0] + 1)); // Consecutive
        
        // Should have appropriate parameter updates
        expect(result.parameterUpdates.length, greaterThanOrEqualTo(2));
      });

      test('should not mistakenly route to physical outputs when target is algorithm', () async {
        // This specifically tests the bug where connections go to physical outputs
        // instead of the intended algorithm input
        
        when(mockCubit.state).thenReturn(
          DistingState.synchronized(
            disting: mockDisting,
            distingVersion: '',
            firmwareVersion: FirmwareVersion('1.0.0'),
            presetName: 'Test',
            algorithms: [],
            slots: [
              // Source algorithm
              Slot(
                algorithm: Algorithm(algorithmIndex: 0, guid: 'src', name: 'Source'),
                routing: RoutingInfo(algorithmIndex: 0, routingInfo: []),
                pages: ParameterPages(algorithmIndex: 0, pages: []),
                parameters: [
                  ParameterInfo(
                    algorithmIndex: 0,
                    parameterNumber: 0,
                    name: 'Output',
                    min: 0,
                    max: 28,
                    defaultValue: 0,
                    unit: 1,
                    powerOfTen: 0,
                  ),
                ],
                values: [],
                enums: [],
                mappings: [],
                valueStrings: [],
              ),
              // Target algorithm (NOT physical output)
              Slot(
                algorithm: Algorithm(algorithmIndex: 1, guid: 'tgt', name: 'Target'),
                routing: RoutingInfo(algorithmIndex: 1, routingInfo: []),
                pages: ParameterPages(algorithmIndex: 1, pages: []),
                parameters: [
                  ParameterInfo(
                    algorithmIndex: 1,
                    parameterNumber: 0,
                    name: 'Input',
                    min: 0,
                    max: 28,
                    defaultValue: 0,
                    unit: 1,
                    powerOfTen: 0,
                  ),
                ],
                values: [],
                enums: [],
                mappings: [],
                valueStrings: [],
              ),
            ],
            unitStrings: [],
          ),
        );

        final result = await service.assignBusForConnection(
          sourceAlgorithmIndex: 0,
          sourcePortId: '0',
          targetAlgorithmIndex: 1, // This is an algorithm, not -3 (physical output)
          targetPortId: '0',
          existingConnections: [],
        );

        // Verify bus assignment is NOT in the physical output range (13-20)
        expect(result.sourceBus, isNot(inInclusiveRange(13, 20)));
        
        // Should prefer aux buses for algorithm-to-algorithm connections
        expect(result.sourceBus, greaterThanOrEqualTo(21));
        expect(result.sourceBus, lessThanOrEqualTo(28));
      });
    });

    group('Port ID Matching Issues', () {
      test('should correctly match port IDs for width-aware algorithms', () async {
        // Test that port IDs are correctly interpreted when width is involved
        
        when(mockCubit.state).thenReturn(
          DistingState.synchronized(
            disting: mockDisting,
            distingVersion: '',
            firmwareVersion: FirmwareVersion('1.0.0'),
            presetName: 'Test',
            algorithms: [],
            slots: [
              // Algorithm with specific port naming
              Slot(
                algorithm: Algorithm(algorithmIndex: 0, guid: 'algo', name: 'Algorithm'),
                routing: RoutingInfo(algorithmIndex: 0, routingInfo: []),
                pages: ParameterPages(algorithmIndex: 0, pages: []),
                parameters: [
                  // Port IDs might be parameter numbers or processed IDs
                  ParameterInfo(
                    algorithmIndex: 0,
                    parameterNumber: 15,
                    name: 'Audio Output',
                    min: 0,
                    max: 28,
                    defaultValue: 0,
                    unit: 1,
                    powerOfTen: 0,
                  ),
                ],
                values: [],
                enums: [],
                mappings: [],
                valueStrings: [],
              ),
              Slot(
                algorithm: Algorithm(algorithmIndex: 1, guid: 'vcf', name: 'VCF'),
                routing: RoutingInfo(algorithmIndex: 1, routingInfo: []),
                pages: ParameterPages(algorithmIndex: 1, pages: []),
                parameters: [
                  ParameterInfo(
                    algorithmIndex: 1,
                    parameterNumber: 0,
                    name: 'Width',
                    min: 1,
                    max: 4,
                    defaultValue: 2,
                    unit: 0,
                    powerOfTen: 0,
                  ),
                  ParameterInfo(
                    algorithmIndex: 1,
                    parameterNumber: 3,
                    name: 'Audio Input',
                    min: 0,
                    max: 28,
                    defaultValue: 0,
                    unit: 1,
                    powerOfTen: 0,
                  ),
                ],
                values: [
                  ParameterValue(
                    algorithmIndex: 1,
                    parameterNumber: 0,
                    value: 2,
                  ),
                ],
                enums: [],
                mappings: [],
                valueStrings: [],
              ),
            ],
            unitStrings: [],
          ),
        );

        // Test with various port ID formats
        final result = await service.assignBusForConnection(
          sourceAlgorithmIndex: 0,
          sourcePortId: '15', // Parameter number as port ID
          targetAlgorithmIndex: 1,
          targetPortId: '3', // Different parameter number
          existingConnections: [],
        );

        // Should successfully find and connect the ports
        expect(result.parameterUpdates.length, greaterThan(0));
        
        // Check that correct parameters are being updated
        final targetUpdate = result.parameterUpdates
            .firstWhere((u) => u.algorithmIndex == 1);
        expect(targetUpdate.parameterNumber, equals(3));
      });

      test('should handle port IDs with channel suffixes', () async {
        // When UI adds channel suffixes like _L, _R, _1, _2
        
        when(mockCubit.state).thenReturn(
          DistingState.synchronized(
            disting: mockDisting,
            distingVersion: '',
            firmwareVersion: FirmwareVersion('1.0.0'),
            presetName: 'Test',
            algorithms: [],
            slots: [
              Slot(
                algorithm: Algorithm(algorithmIndex: 0, guid: 'src', name: 'Source'),
                routing: RoutingInfo(algorithmIndex: 0, routingInfo: []),
                pages: ParameterPages(algorithmIndex: 0, pages: []),
                parameters: [
                  ParameterInfo(
                    algorithmIndex: 0,
                    parameterNumber: 10,
                    name: 'Output L',
                    min: 0,
                    max: 28,
                    defaultValue: 0,
                    unit: 1,
                    powerOfTen: 0,
                  ),
                  ParameterInfo(
                    algorithmIndex: 0,
                    parameterNumber: 11,
                    name: 'Output R',
                    min: 0,
                    max: 28,
                    defaultValue: 0,
                    unit: 1,
                    powerOfTen: 0,
                  ),
                ],
                values: [],
                enums: [],
                mappings: [],
                valueStrings: [],
              ),
              Slot(
                algorithm: Algorithm(algorithmIndex: 1, guid: 'tgt', name: 'Target'),
                routing: RoutingInfo(algorithmIndex: 1, routingInfo: []),
                pages: ParameterPages(algorithmIndex: 1, pages: []),
                parameters: [
                  ParameterInfo(
                    algorithmIndex: 1,
                    parameterNumber: 0,
                    name: 'Input',
                    min: 0,
                    max: 28,
                    defaultValue: 0,
                    unit: 1,
                    powerOfTen: 0,
                  ),
                ],
                values: [],
                enums: [],
                mappings: [],
                valueStrings: [],
              ),
            ],
            unitStrings: [],
          ),
        );

        // Test with channel suffix
        final result = await service.assignBusForConnection(
          sourceAlgorithmIndex: 0,
          sourcePortId: '10_L', // Port ID with channel suffix
          targetAlgorithmIndex: 1,
          targetPortId: '0',
          existingConnections: [],
        );

        // Should handle the suffix and find the correct parameter
        expect(result.parameterUpdates.length, greaterThan(0));
      });
    });

    group('Complex Multi-Algorithm Scenarios', () {
      test('should handle chain of width-aware algorithms', () async {
        // Source -> Stereo Effect -> Stereo VCF -> Output
        
        when(mockCubit.state).thenReturn(
          DistingState.synchronized(
            disting: mockDisting,
            distingVersion: '',
            firmwareVersion: FirmwareVersion('1.0.0'),
            presetName: 'Test',
            algorithms: [],
            slots: [
              // Slot 0 - Mono source
              Slot(
                algorithm: Algorithm(algorithmIndex: 0, guid: 'osc', name: 'Oscillator'),
                routing: RoutingInfo(algorithmIndex: 0, routingInfo: []),
                pages: ParameterPages(algorithmIndex: 0, pages: []),
                parameters: [
                  ParameterInfo(
                    algorithmIndex: 0,
                    parameterNumber: 0,
                    name: 'Output',
                    min: 0,
                    max: 28,
                    defaultValue: 0,
                    unit: 1,
                    powerOfTen: 0,
                  ),
                ],
                values: [],
                enums: [],
                mappings: [],
                valueStrings: [],
              ),
              // Slot 1 - Stereo effect
              Slot(
                algorithm: Algorithm(algorithmIndex: 1, guid: 'efx', name: 'Effect'),
                routing: RoutingInfo(algorithmIndex: 1, routingInfo: []),
                pages: ParameterPages(algorithmIndex: 1, pages: []),
                parameters: [
                  ParameterInfo(
                    algorithmIndex: 1,
                    parameterNumber: 0,
                    name: 'Width',
                    min: 1,
                    max: 2,
                    defaultValue: 2,
                    unit: 0,
                    powerOfTen: 0,
                  ),
                  ParameterInfo(
                    algorithmIndex: 1,
                    parameterNumber: 1,
                    name: 'Input',
                    min: 0,
                    max: 28,
                    defaultValue: 0,
                    unit: 1,
                    powerOfTen: 0,
                  ),
                  ParameterInfo(
                    algorithmIndex: 1,
                    parameterNumber: 2,
                    name: 'Output',
                    min: 0,
                    max: 28,
                    defaultValue: 0,
                    unit: 1,
                    powerOfTen: 0,
                  ),
                ],
                values: [
                  ParameterValue(
                    algorithmIndex: 1,
                    parameterNumber: 0,
                    value: 2, // Stereo
                  ),
                ],
                enums: [],
                mappings: [],
                valueStrings: [],
              ),
              // Slot 2 - Stereo VCF
              Slot(
                algorithm: Algorithm(algorithmIndex: 2, guid: 'vcf', name: 'VCF'),
                routing: RoutingInfo(algorithmIndex: 2, routingInfo: []),
                pages: ParameterPages(algorithmIndex: 2, pages: []),
                parameters: [
                  ParameterInfo(
                    algorithmIndex: 2,
                    parameterNumber: 0,
                    name: 'Width',
                    min: 1,
                    max: 4,
                    defaultValue: 2,
                    unit: 0,
                    powerOfTen: 0,
                  ),
                  ParameterInfo(
                    algorithmIndex: 2,
                    parameterNumber: 1,
                    name: 'Audio Input',
                    min: 0,
                    max: 28,
                    defaultValue: 0,
                    unit: 1,
                    powerOfTen: 0,
                  ),
                ],
                values: [
                  ParameterValue(
                    algorithmIndex: 2,
                    parameterNumber: 0,
                    value: 2, // Stereo
                  ),
                ],
                enums: [],
                mappings: [],
                valueStrings: [],
              ),
            ],
            unitStrings: [],
          ),
        );

        // Connect mono to stereo effect
        final result1 = await service.assignBusForConnection(
          sourceAlgorithmIndex: 0,
          sourcePortId: '0',
          targetAlgorithmIndex: 1,
          targetPortId: '1',
          existingConnections: [],
        );

        expect(result1.channelCount, equals(2)); // Should expand to stereo
        expect(result1.assignedBuses.length, equals(2));

        // Connect stereo effect to stereo VCF
        final result2 = await service.assignBusForConnection(
          sourceAlgorithmIndex: 1,
          sourcePortId: '2',
          targetAlgorithmIndex: 2,
          targetPortId: '1',
          existingConnections: [
            // Include the first connection
            Connection(
              id: 'conn1',
              sourceAlgorithmIndex: 0,
              sourcePortId: '0',
              targetAlgorithmIndex: 1,
              targetPortId: '1',
              assignedBus: result1.sourceBus,
              replaceMode: false,
              isValid: true,
            ),
          ],
        );

        expect(result2.channelCount, equals(2)); // Stereo to stereo
        // Should use different buses than the first connection
        expect(result2.assignedBuses[0], isNot(equals(result1.assignedBuses[0])));
      });
    });
  });
}