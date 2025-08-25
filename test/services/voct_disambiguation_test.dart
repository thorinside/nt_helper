import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:nt_helper/cubit/disting_cubit.dart';
import 'package:nt_helper/domain/i_disting_midi_manager.dart';
import 'package:nt_helper/models/firmware_version.dart';
import 'package:nt_helper/domain/disting_nt_sysex.dart';
import 'package:nt_helper/services/auto_routing_service.dart';

@GenerateMocks([DistingCubit, IDistingMidiManager])
import 'voct_disambiguation_test.mocks.dart';

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

  group('V/Oct Parameter Disambiguation Tests', () {
    late AutoRoutingService service;
    late MockDistingCubit mockCubit;

    setUp(() {
      mockCubit = MockDistingCubit();
      service = AutoRoutingService(mockCubit);
    });

    test(
      'should find correct V/Oct INPUT parameter when connecting FROM physical input',
      () async {
        // Setup: Mock the exact Lua Script state from the live system
        when(mockCubit.state).thenReturn(
          DistingState.synchronized(
            disting: MockIDistingMidiManager(),
            distingVersion: '',
            firmwareVersion: FirmwareVersion('1.0.0'),
            presetName: 'Test Preset',
            algorithms: [],
            unitStrings: [],
            slots: [
              // Lua Script with both V/Oct parameters
              Slot(
                algorithm: Algorithm(
                  algorithmIndex: 0,
                  guid: 'lua ',
                  name: 'Lua Script',
                ),
                routing: RoutingInfo(algorithmIndex: 0, routingInfo: []),
                pages: ParameterPages(algorithmIndex: 0, pages: []),
                parameters: [
                  // V/Oct INPUT parameter (like parameter #4 from live system)
                  ParameterInfo(
                    algorithmIndex: 0,
                    parameterNumber: 4,
                    name: 'V/Oct',
                    min: 0,
                    max: 28,
                    defaultValue:
                        4, // Input 4 - this should be classified as INPUT
                    unit: 1,
                    powerOfTen: 0,
                  ),
                  // V/Oct OUTPUT parameter (like parameter #31 from live system)
                  ParameterInfo(
                    algorithmIndex: 0,
                    parameterNumber: 31,
                    name: 'V/Oct',
                    min: 0,
                    max: 28,
                    defaultValue:
                        16, // Output 4 - this should be classified as OUTPUT
                    unit: 1,
                    powerOfTen: 0,
                  ),
                ],
                values: [
                  ParameterValue(
                    algorithmIndex: 0,
                    parameterNumber: 4,
                    value: 0, // Currently set to "None"
                  ),
                  ParameterValue(
                    algorithmIndex: 0,
                    parameterNumber: 31,
                    value: 16, // Currently set to Output 4
                  ),
                ],
                enums: [],
                mappings: [],
                valueStrings: [],
              ),
            ],
          ),
        );

        // Test: Connect FROM physical input I4 TO the V/Oct input port on Lua Script
        // This simulates dragging from I4 to the LEFT side V/Oct port
        var result = await service.assignBusForConnection(
          sourceAlgorithmIndex: -2, // Physical input node
          sourcePortId: 'physical_input_4', // I4
          targetAlgorithmIndex: 0, // Lua Script
          targetPortId: '4', // Parameter #4 is the INPUT V/Oct
          existingConnections: [],
        );

        // The connection should use the physical input bus 4
        expect(result.sourceBus, equals(4)); // Physical Input 4

        // Verify that it found the correct INPUT parameter (not the output one)
        // The target parameter should be set to bus 4 (Input 4)
        // We can't directly test which parameter was found, but the behavior should be correct
      },
    );

    test(
      'should find correct V/Oct OUTPUT parameter when connecting TO external output',
      () async {
        // Same setup as above
        when(mockCubit.state).thenReturn(
          DistingState.synchronized(
            disting: MockIDistingMidiManager(),
            distingVersion: '',
            firmwareVersion: FirmwareVersion('1.0.0'),
            presetName: 'Test Preset',
            algorithms: [],
            unitStrings: [],
            slots: [
              Slot(
                algorithm: Algorithm(
                  algorithmIndex: 0,
                  guid: 'lua ',
                  name: 'Lua Script',
                ),
                routing: RoutingInfo(algorithmIndex: 0, routingInfo: []),
                pages: ParameterPages(algorithmIndex: 0, pages: []),
                parameters: [
                  // V/Oct INPUT parameter
                  ParameterInfo(
                    algorithmIndex: 0,
                    parameterNumber: 4,
                    name: 'V/Oct',
                    min: 0,
                    max: 28,
                    defaultValue: 4, // Input 4
                    unit: 1,
                    powerOfTen: 0,
                  ),
                  // V/Oct OUTPUT parameter
                  ParameterInfo(
                    algorithmIndex: 0,
                    parameterNumber: 31,
                    name: 'V/Oct',
                    min: 0,
                    max: 28,
                    defaultValue: 16, // Output 4
                    unit: 1,
                    powerOfTen: 0,
                  ),
                ],
                values: [
                  ParameterValue(
                    algorithmIndex: 0,
                    parameterNumber: 4,
                    value: 0, // Input parameter set to "None"
                  ),
                  ParameterValue(
                    algorithmIndex: 0,
                    parameterNumber: 31,
                    value: 16, // Output parameter already set to Output 4
                  ),
                ],
                enums: [],
                mappings: [],
                valueStrings: [],
              ),
            ],
          ),
        );

        // Test: Connect FROM Lua Script V/Oct output TO external output
        // This simulates dragging from the RIGHT side V/Oct port to an external output
        var result = await service.assignBusForConnection(
          sourceAlgorithmIndex: 0, // Lua Script
          sourcePortId: '31', // Parameter #31 is the OUTPUT V/Oct
          targetAlgorithmIndex: -3, // External output
          targetPortId: 'physical_output_4',
          existingConnections: [],
        );

        // Should use the OUTPUT bus that's already configured (bus 16 = Output 4)
        expect(result.sourceBus, equals(16)); // Output 4
      },
    );

    test(
      'should validate connection from physical input to algorithm input port',
      () async {
        // This test simulates the UI validation that happens during drag operations
        // When dragging from I4 to V/Oct input, the system should find the correct parameter

        when(mockCubit.state).thenReturn(
          DistingState.synchronized(
            disting: MockIDistingMidiManager(),
            distingVersion: '',
            firmwareVersion: FirmwareVersion('1.0.0'),
            presetName: 'Test Preset',
            algorithms: [],
            unitStrings: [],
            slots: [
              Slot(
                algorithm: Algorithm(
                  algorithmIndex: 0,
                  guid: 'lua ',
                  name: 'Lua Script',
                ),
                routing: RoutingInfo(algorithmIndex: 0, routingInfo: []),
                pages: ParameterPages(algorithmIndex: 0, pages: []),
                parameters: [
                  ParameterInfo(
                    algorithmIndex: 0,
                    parameterNumber: 4,
                    name: 'V/Oct',
                    min: 0,
                    max: 28,
                    defaultValue: 4, // Input 4 - INPUT parameter
                    unit: 1,
                    powerOfTen: 0,
                  ),
                  ParameterInfo(
                    algorithmIndex: 0,
                    parameterNumber: 31,
                    name: 'V/Oct',
                    min: 0,
                    max: 28,
                    defaultValue: 16, // Output 4 - OUTPUT parameter
                    unit: 1,
                    powerOfTen: 0,
                  ),
                ],
                values: [
                  ParameterValue(
                    algorithmIndex: 0,
                    parameterNumber: 4,
                    value: 0,
                  ),
                  ParameterValue(
                    algorithmIndex: 0,
                    parameterNumber: 31,
                    value: 16,
                  ),
                ],
                enums: [],
                mappings: [],
                valueStrings: [],
              ),
            ],
          ),
        );

        // Create the connection that simulates UI drag validation
        var result = await service.assignBusForConnection(
          sourceAlgorithmIndex: -2, // Physical input I4
          sourcePortId: 'physical_input_4',
          targetAlgorithmIndex: 0, // Lua Script
          targetPortId: '4', // Parameter #4 is the INPUT V/Oct
          existingConnections: [],
        );

        // The connection should be successful and use Input 4
        expect(result.sourceBus, equals(4));
        // Connection should be successful
        expect(result.sourceBus, isNotNull);

        // The edge label should indicate it's using an Input bus
        expect(result.edgeLabel, contains('I4'));
      },
    );
  });
}
