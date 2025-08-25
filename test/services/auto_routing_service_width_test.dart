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
import 'auto_routing_service_width_test.mocks.dart';

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

  group('AutoRoutingService - Width-Aware Algorithms', () {
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

    group('VCF Stereo Connection Tests', () {
      test('should assign consecutive buses for width=2 (stereo) algorithm', () async {
        // Setup: VCF with width=2 (stereo mode)
        when(mockCubit.state).thenReturn(
          DistingState.synchronized(
            disting: mockDisting,
            distingVersion: '',
            firmwareVersion: FirmwareVersion('1.0.0'),
            presetName: 'Test',
            algorithms: [],
            slots: [
              // Slot 0 - Source algorithm (e.g., Oscillator)
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
                algorithm: Algorithm(algorithmIndex: 1, guid: 'vcf', name: 'VCF'),
                routing: RoutingInfo(algorithmIndex: 1, routingInfo: []),
                pages: ParameterPages(algorithmIndex: 1, pages: []),
                parameters: [
                  // Width parameter set to 2 (stereo)
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
                  // Width is set to 2
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

        // Execute: Create connection from oscillator to VCF
        final result = await service.assignBusForConnection(
          sourceAlgorithmIndex: 0,
          sourcePortId: '0', // Output parameter number
          targetAlgorithmIndex: 1,
          targetPortId: '1', // Audio Input parameter number
          existingConnections: [],
        );

        // Verify: Should assign consecutive buses for stereo connection
        expect(result.channelCount, equals(2));
        expect(result.assignedBuses.length, equals(2));
        expect(result.assignedBuses[0], equals(21)); // First aux bus
        expect(result.assignedBuses[1], equals(22)); // Next consecutive bus
        
        // Should have parameter updates for the target
        expect(result.parameterUpdates.length, greaterThanOrEqualTo(1));
        
        // The base bus assignment should be the first bus
        expect(result.sourceBus, equals(21));
      });

      test('should avoid using occupied buses when finding consecutive buses', () async {
        // Setup: VCF with width=2, but some buses are already in use
        when(mockCubit.state).thenReturn(
          DistingState.synchronized(
            disting: mockDisting,
            distingVersion: '',
            firmwareVersion: FirmwareVersion('1.0.0'),
            presetName: 'Test',
            algorithms: [],
            slots: [
              // Slot 0 - Source
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
              // Slot 1 - VCF with width=2
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
                    value: 2, // Width = 2
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

        // Existing connections using bus 21 and 23 (22 is free but not consecutive with anything)
        final existingConnections = [
          Connection(
            id: 'existing1',
            sourceAlgorithmIndex: 2,
            sourcePortId: 'out',
            targetAlgorithmIndex: 3,
            targetPortId: 'in',
            assignedBus: 21,
            replaceMode: false,
            isValid: true,
          ),
          Connection(
            id: 'existing2',
            sourceAlgorithmIndex: 4,
            sourcePortId: 'out',
            targetAlgorithmIndex: 5,
            targetPortId: 'in',
            assignedBus: 23,
            replaceMode: false,
            isValid: true,
          ),
        ];

        // Execute
        final result = await service.assignBusForConnection(
          sourceAlgorithmIndex: 0,
          sourcePortId: '0',
          targetAlgorithmIndex: 1,
          targetPortId: '1',
          existingConnections: existingConnections,
        );

        // Verify: Should find consecutive buses starting at 24
        expect(result.channelCount, equals(2));
        expect(result.assignedBuses[0], equals(24));
        expect(result.assignedBuses[1], equals(25));
      });

      test('should handle mono to stereo connection by duplicating source', () async {
        // Setup: Mono source to stereo VCF
        when(mockCubit.state).thenReturn(
          DistingState.synchronized(
            disting: mockDisting,
            distingVersion: '',
            firmwareVersion: FirmwareVersion('1.0.0'),
            presetName: 'Test',
            algorithms: [],
            slots: [
              // Slot 0 - Mono source (width=1 or no width parameter)
              Slot(
                algorithm: Algorithm(algorithmIndex: 0, guid: 'mono', name: 'Mono Source'),
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
              // Slot 1 - Stereo VCF
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

        // Execute
        final result = await service.assignBusForConnection(
          sourceAlgorithmIndex: 0,
          sourcePortId: '0',
          targetAlgorithmIndex: 1,
          targetPortId: '1',
          existingConnections: [],
        );

        // Verify
        expect(result.channelCount, equals(2));
        expect(result.assignedBuses.length, equals(2));
        
        // Should have multiple parameter updates to duplicate mono source
        final sourceUpdates = result.parameterUpdates
            .where((u) => u.algorithmIndex == 0)
            .toList();
        expect(sourceUpdates.length, greaterThanOrEqualTo(1));
      });

      test('should throw InsufficientBusesException when not enough consecutive buses available', () async {
        // Setup: VCF with width=3, but only 2 consecutive buses available
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
              Slot(
                algorithm: Algorithm(algorithmIndex: 1, guid: 'vcf3', name: 'VCF 3-Channel'),
                routing: RoutingInfo(algorithmIndex: 1, routingInfo: []),
                pages: ParameterPages(algorithmIndex: 1, pages: []),
                parameters: [
                  ParameterInfo(
                    algorithmIndex: 1,
                    parameterNumber: 0,
                    name: 'Width',
                    min: 1,
                    max: 4,
                    defaultValue: 3,
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
                    value: 3, // Width = 3
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

        // Fill up buses to leave only 2 consecutive slots
        final existingConnections = <Connection>[];
        for (int i = 1; i <= 28; i++) {
          // Leave only buses 27-28 free (2 consecutive)
          if (i < 27) {
            existingConnections.add(Connection(
              id: 'conn$i',
              sourceAlgorithmIndex: 10,
              sourcePortId: 'out',
              targetAlgorithmIndex: 11,
              targetPortId: 'in',
              assignedBus: i,
              replaceMode: false,
              isValid: true,
            ));
          }
        }

        // Execute & Verify
        expect(
          () => service.assignBusForConnection(
            sourceAlgorithmIndex: 0,
            sourcePortId: '0',
            targetAlgorithmIndex: 1,
            targetPortId: '1',
            existingConnections: existingConnections,
          ),
          throwsA(isA<InsufficientBusesException>()),
        );
      });
    });
  });
}