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

  group('AutoRoutingService', () {
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

    group('Output to Input Routing', () {
      test(
        'should detect and use Output bus when source is already configured to use it',
        () async {
          // This is the real use case: Lua Script V/Oct parameter is set to Output 4 in the preset,
          // When connecting to VCO Pitch input, it should use Output 4 (bus 16), not a new Aux bus

          // Mock the state to show Lua Script V/Oct is configured to Output 4
          // In real scenario, parameter 31 (V/Oct) has value 16 (Output 4)
          when(mockCubit.state).thenReturn(
            DistingState.synchronized(
              disting: mockDisting,
              distingVersion: '',
              firmwareVersion: FirmwareVersion('1.0.0'),
              presetName: 'Test',
              algorithms: [],
              slots: [
                // Slot 0 - empty
                Slot(
                  algorithm: Algorithm(algorithmIndex: 0, guid: '', name: ''),
                  routing: RoutingInfo(algorithmIndex: 0, routingInfo: []),
                  pages: ParameterPages(algorithmIndex: 0, pages: []),
                  parameters: [],
                  values: [],
                  enums: [],
                  mappings: [],
                  valueStrings: [],
                ),
                // Slot 1 - Lua Script
                Slot(
                  algorithm: Algorithm(
                    algorithmIndex: 1,
                    guid: 'lua ',
                    name: 'Lua Script',
                  ),
                  routing: RoutingInfo(algorithmIndex: 1, routingInfo: []),
                  pages: ParameterPages(algorithmIndex: 1, pages: []),
                  parameters: [
                    // V/Oct input parameter
                    ParameterInfo(
                      algorithmIndex: 1,
                      parameterNumber: 30,
                      name: 'V/Oct',
                      min: 0,
                      max: 28,
                      defaultValue: 1, // Input 1 - this makes it an INPUT
                      unit: 1, // enum/bus type
                      powerOfTen: 0,
                    ),
                    // V/Oct output parameter
                    ParameterInfo(
                      algorithmIndex: 1,
                      parameterNumber: 31,
                      name: 'V/Oct',
                      min: 0,
                      max: 28,
                      defaultValue: 16, // Output 4 - this makes it an OUTPUT
                      unit: 1, // enum/bus type
                      powerOfTen: 0,
                    ),
                  ],
                  values: [
                    ParameterValue(
                      algorithmIndex: 1,
                      parameterNumber: 30,
                      value: 1, // Input 1
                    ),
                    ParameterValue(
                      algorithmIndex: 1,
                      parameterNumber: 31,
                      value: 16, // Output 4
                    ),
                  ],
                  enums: [],
                  mappings: [],
                  valueStrings: [],
                ),
                // Slot 2 - will be VCO
                Slot(
                  algorithm: Algorithm(algorithmIndex: 2, guid: '', name: ''),
                  routing: RoutingInfo(algorithmIndex: 2, routingInfo: []),
                  pages: ParameterPages(algorithmIndex: 2, pages: []),
                  parameters: [],
                  values: [],
                  enums: [],
                  mappings: [],
                  valueStrings: [],
                ),
              ],
              unitStrings: [],
            ),
          );

          // No existing connections - relying on preset state
          var existingConnections = <Connection>[];

          // Create connection: Lua V/Oct (already set to Output 4) -> VCO Pitch Input
          var result = await service.assignBusForConnection(
            sourceAlgorithmIndex: 1, // Lua Script
            sourcePortId: '31', // V/Oct output parameter #31
            targetAlgorithmIndex: 2, // VCO
            targetPortId: 'pitch_input',
            existingConnections: existingConnections,
          );

          // Should detect Output 4 (bus 16) from preset and use it
          expect(result.sourceBus, equals(16)); // Output 4

          // Edge label should indicate it's an Output bus
          expect(result.edgeLabel, equals('O4 R')); // Output 4 Replace mode
        },
      );

      test(
        'should correctly disambiguate V/Oct input vs output with same names',
        () async {
          // Set up the mock state for this test
          when(mockCubit.state).thenReturn(
            DistingState.synchronized(
              disting: mockDisting,
              distingVersion: '',
              firmwareVersion: FirmwareVersion('1.0.0'),
              presetName: 'Test',
              algorithms: [],
              unitStrings: [],
              slots: [
                // Slot 0 - empty
                Slot(
                  algorithm: Algorithm(algorithmIndex: 0, guid: '', name: ''),
                  routing: RoutingInfo(algorithmIndex: 0, routingInfo: []),
                  pages: ParameterPages(algorithmIndex: 0, pages: []),
                  parameters: [],
                  values: [],
                  enums: [],
                  mappings: [],
                  valueStrings: [],
                ),
                // Slot 1 - Lua Script with both V/Oct parameters
                Slot(
                  algorithm: Algorithm(
                    algorithmIndex: 1,
                    guid: 'lua ',
                    name: 'Lua Script',
                  ),
                  routing: RoutingInfo(algorithmIndex: 1, routingInfo: []),
                  pages: ParameterPages(algorithmIndex: 1, pages: []),
                  parameters: [
                    // V/Oct input parameter
                    ParameterInfo(
                      algorithmIndex: 1,
                      parameterNumber: 30,
                      name: 'V/Oct',
                      min: 0,
                      max: 28,
                      defaultValue: 1, // Input 1
                      unit: 1,
                      powerOfTen: 0,
                    ),
                    // V/Oct output parameter
                    ParameterInfo(
                      algorithmIndex: 1,
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
                      algorithmIndex: 1,
                      parameterNumber: 30,
                      value: 0, // Not connected
                    ),
                    ParameterValue(
                      algorithmIndex: 1,
                      parameterNumber: 31,
                      value: 16, // Set to Output 4
                    ),
                  ],
                  enums: [],
                  mappings: [],
                  valueStrings: [],
                ),
                // Slot 2 - VCO for target
                Slot(
                  algorithm: Algorithm(
                    algorithmIndex: 2,
                    guid: 'vco ',
                    name: 'VCO',
                  ),
                  routing: RoutingInfo(algorithmIndex: 2, routingInfo: []),
                  pages: ParameterPages(algorithmIndex: 2, pages: []),
                  parameters: [],
                  values: [],
                  enums: [],
                  mappings: [],
                  valueStrings: [],
                ),
              ],
            ),
          );
          // Test connecting TO a V/Oct input (should find parameter #30, not #31)
          var result = await service.assignBusForConnection(
            sourceAlgorithmIndex: -2, // Physical input
            sourcePortId: 'physical_input_4',
            targetAlgorithmIndex: 1, // Lua Script
            targetPortId: '30', // Parameter #30 is the INPUT V/Oct
            existingConnections: [],
          );

          // Should use Input 4 (bus 4) for physical connection
          expect(result.sourceBus, equals(4)); // Input 4

          // Test connecting FROM a V/Oct output (should find parameter #31, not #30)
          result = await service.assignBusForConnection(
            sourceAlgorithmIndex: 1, // Lua Script
            sourcePortId: '31', // Parameter #31 is the OUTPUT V/Oct
            targetAlgorithmIndex: 2, // VCO
            targetPortId: 'pitch_input',
            existingConnections: [],
          );

          // Should detect and use Output 4 (bus 16)
          expect(result.sourceBus, equals(16)); // Output 4
        },
      );

      test(
        'should prefer Output buses when source is already using one',
        () async {
          // If a source algorithm already outputs to an Output bus,
          // connections from that source should use the same Output bus

          // Simulate that Lua Script is already outputting to Output 4 (bus 16)
          var existingConnections = [
            const Connection(
              id: 'lua_gate_out',
              sourceAlgorithmIndex: 1,
              sourcePortId: 'gate_output',
              targetAlgorithmIndex: -1, // External output
              targetPortId: 'output_3',
              assignedBus: 15, // Output 3
              replaceMode: true,
              isValid: true,
            ),
          ];

          // Now connect V/Oct which is also going to an Output
          var result = await service.assignBusForConnection(
            sourceAlgorithmIndex: 1,
            sourcePortId: '31', // V/Oct output parameter
            targetAlgorithmIndex: -1, // External output
            targetPortId: 'output_4',
            existingConnections: existingConnections,
          );

          // Should get Output 4 (bus 16)
          expect(result.sourceBus, equals(16));

          // Now when we connect from this output to an internal input
          existingConnections.add(
            Connection(
              id: 'lua_voct_out',
              sourceAlgorithmIndex: 1,
              sourcePortId: '31', // V/Oct output parameter
              targetAlgorithmIndex: -1,
              targetPortId: 'output_4',
              assignedBus: 16,
              replaceMode: true,
              isValid: true,
            ),
          );

          // Connect from same source to VCO input - should reuse Output 4 bus
          result = await service.assignBusForConnection(
            sourceAlgorithmIndex: 1,
            sourcePortId: '31', // V/Oct output parameter
            targetAlgorithmIndex: 2,
            targetPortId: 'pitch_input',
            existingConnections: existingConnections,
          );

          // Should reuse bus 16 (Output 4) for signal routing
          expect(result.sourceBus, equals(16));
        },
      );
    });

    group('Bus Sharing for Same Source', () {
      test(
        'should REUSE same bus when connecting same source to multiple targets (VCO -> Reverb L/R)',
        () async {
          // This is the key use case: VCO mono output feeding both L and R inputs of reverb
          // Both connections should use the SAME bus for proper signal routing

          // First connection: VCO Output -> Reverb Left Input
          var existingConnections = <Connection>[];
          var result = await service.assignBusForConnection(
            sourceAlgorithmIndex: 0, // VCO
            sourcePortId: 'output',
            targetAlgorithmIndex: 1, // Reverb
            targetPortId: 'left_input',
            existingConnections: existingConnections,
          );
          expect(result.sourceBus, equals(21)); // Gets first aux bus

          // Add first connection to existing
          existingConnections.add(
            Connection(
              id: 'vco_to_reverb_left',
              sourceAlgorithmIndex: 0,
              sourcePortId: 'output',
              targetAlgorithmIndex: 1,
              targetPortId: 'left_input',
              assignedBus: 21,
              replaceMode: true,
              isValid: true,
            ),
          );

          // Second connection: SAME VCO Output -> Reverb Right Input
          result = await service.assignBusForConnection(
            sourceAlgorithmIndex: 0, // Same VCO
            sourcePortId: 'output', // Same output
            targetAlgorithmIndex: 1, // Same Reverb
            targetPortId: 'right_input', // Different input
            existingConnections: existingConnections,
          );

          // Should REUSE bus 21 because it's the same source
          expect(
            result.sourceBus,
            equals(21),
            reason:
                'Same source feeding multiple targets should use the same bus',
          );
        },
      );

      test(
        'should use different buses for different sources even to same target',
        () async {
          // Opposite case: different sources to same target need different buses
          var existingConnections = <Connection>[];

          // First connection: VCO1 -> Mixer Input 1
          var result = await service.assignBusForConnection(
            sourceAlgorithmIndex: 0, // VCO1
            sourcePortId: 'output',
            targetAlgorithmIndex: 2, // Mixer
            targetPortId: 'input1',
            existingConnections: existingConnections,
          );
          expect(result.sourceBus, equals(21));

          existingConnections.add(
            Connection(
              id: 'vco1_to_mixer',
              sourceAlgorithmIndex: 0,
              sourcePortId: 'output',
              targetAlgorithmIndex: 2,
              targetPortId: 'input1',
              assignedBus: 21,
              replaceMode: true,
              isValid: true,
            ),
          );

          // Second connection: VCO2 -> Mixer Input 2
          result = await service.assignBusForConnection(
            sourceAlgorithmIndex: 1, // Different VCO
            sourcePortId: 'output',
            targetAlgorithmIndex: 2, // Same Mixer
            targetPortId: 'input2',
            existingConnections: existingConnections,
          );

          // Should get DIFFERENT bus because source is different
          expect(
            result.sourceBus,
            equals(22),
            reason: 'Different sources should use different buses',
          );
        },
      );
    });

    group('Bus Exclusivity', () {
      test('each new connection should get a unique bus', () async {
        // Start with no connections
        var existingConnections = <Connection>[];

        // Create first connection
        var result = await service.assignBusForConnection(
          sourceAlgorithmIndex: 0,
          sourcePortId: 'output',
          targetAlgorithmIndex: 1,
          targetPortId: 'input',
          existingConnections: existingConnections,
        );
        expect(result.sourceBus, equals(21));

        // Add it to existing connections
        existingConnections.add(
          Connection(
            id: 'conn1',
            sourceAlgorithmIndex: 0,
            sourcePortId: 'output',
            targetAlgorithmIndex: 1,
            targetPortId: 'input',
            assignedBus: 21,
            replaceMode: true,
            isValid: true,
          ),
        );

        // Create second connection - should get different bus
        result = await service.assignBusForConnection(
          sourceAlgorithmIndex: 2,
          sourcePortId: 'output',
          targetAlgorithmIndex: 3,
          targetPortId: 'input',
          existingConnections: existingConnections,
        );
        expect(result.sourceBus, equals(22));
        expect(result.sourceBus, isNot(equals(21))); // Different from first
      });

      test(
        'should reuse bus when connecting same source port to different targets',
        () async {
          // This test has been updated to match the VCO -> Reverb L/R use case
          // Existing connection from A->B using bus 21
          final existingConnections = [
            const Connection(
              id: 'conn1',
              sourceAlgorithmIndex: 0,
              sourcePortId: 'output',
              targetAlgorithmIndex: 1,
              targetPortId: 'input',
              assignedBus: 21,
              replaceMode: true,
              isValid: true,
            ),
          ];

          // Connect same source A to different target C
          final result = await service.assignBusForConnection(
            sourceAlgorithmIndex: 0, // Same source
            sourcePortId: 'output', // Same output port
            targetAlgorithmIndex: 2, // Different target
            targetPortId: 'input',
            existingConnections: existingConnections,
          );

          // Should REUSE bus 21 for same source
          expect(result.sourceBus, equals(21));
        },
      );

      test(
        'should reuse bus only for duplicate connection (same source and target)',
        () async {
          // Existing connection
          final existingConnections = [
            const Connection(
              id: 'conn1',
              sourceAlgorithmIndex: 0,
              sourcePortId: 'output',
              targetAlgorithmIndex: 1,
              targetPortId: 'input',
              assignedBus: 21,
              replaceMode: true,
              isValid: true,
            ),
          ];

          // Reconnect SAME source to SAME target
          final result = await service.assignBusForConnection(
            sourceAlgorithmIndex: 0,
            sourcePortId: 'output',
            targetAlgorithmIndex: 1,
            targetPortId: 'input',
            existingConnections: existingConnections,
          );

          // Should reuse the same bus for duplicate
          expect(result.sourceBus, equals(21));
        },
      );
    });

    group('Bus Priority', () {
      test('should prefer aux buses (21-28) first', () async {
        final result = await service.assignBusForConnection(
          sourceAlgorithmIndex: 0,
          sourcePortId: 'output',
          targetAlgorithmIndex: 1,
          targetPortId: 'input',
          existingConnections: [],
        );

        expect(result.sourceBus, greaterThanOrEqualTo(21));
        expect(result.sourceBus, lessThanOrEqualTo(28));
      });

      test(
        'should use output buses (13-20) when aux buses exhausted',
        () async {
          // Fill all aux buses
          final existingConnections = <Connection>[];
          for (int i = 21; i <= 28; i++) {
            existingConnections.add(
              Connection(
                id: 'aux_$i',
                sourceAlgorithmIndex: i - 21,
                sourcePortId: 'out',
                targetAlgorithmIndex: i - 20,
                targetPortId: 'in',
                assignedBus: i,
                replaceMode: true,
                isValid: true,
              ),
            );
          }

          final result = await service.assignBusForConnection(
            sourceAlgorithmIndex: 10,
            sourcePortId: 'output',
            targetAlgorithmIndex: 11,
            targetPortId: 'input',
            existingConnections: existingConnections,
          );

          expect(result.sourceBus, greaterThanOrEqualTo(13));
          expect(result.sourceBus, lessThanOrEqualTo(20));
        },
      );

      test('should use input buses (1-12) as last resort', () async {
        // Fill aux and output buses
        final existingConnections = <Connection>[];
        for (int i = 13; i <= 28; i++) {
          existingConnections.add(
            Connection(
              id: 'bus_$i',
              sourceAlgorithmIndex: i,
              sourcePortId: 'out',
              targetAlgorithmIndex: i + 50,
              targetPortId: 'in',
              assignedBus: i,
              replaceMode: true,
              isValid: true,
            ),
          );
        }

        final result = await service.assignBusForConnection(
          sourceAlgorithmIndex: 50,
          sourcePortId: 'output',
          targetAlgorithmIndex: 51,
          targetPortId: 'input',
          existingConnections: existingConnections,
        );

        expect(result.sourceBus, greaterThanOrEqualTo(1));
        expect(result.sourceBus, lessThanOrEqualTo(12));
      });
    });

    group('Parameter Updates', () {
      test('should always update BOTH source and target parameters', () async {
        final result = await service.assignBusForConnection(
          sourceAlgorithmIndex: 0,
          sourcePortId: 'output',
          targetAlgorithmIndex: 1,
          targetPortId: 'input',
          existingConnections: [],
        );

        // Should have exactly 2 updates
        expect(result.parameterUpdates, hasLength(2));

        // Both should have the same bus value
        expect(result.parameterUpdates[0].value, equals(result.sourceBus));
        expect(result.parameterUpdates[1].value, equals(result.sourceBus));

        // Should update correct algorithms
        expect(result.parameterUpdates[0].algorithmIndex, equals(0));
        expect(result.parameterUpdates[1].algorithmIndex, equals(1));
      });
    });

    group('Complex Scenarios', () {
      test(
        'should handle adding, removing, and re-adding connections',
        () async {
          var existingConnections = <Connection>[];

          // Add connection 1 (gets bus 21)
          var result = await service.assignBusForConnection(
            sourceAlgorithmIndex: 0,
            sourcePortId: 'output',
            targetAlgorithmIndex: 1,
            targetPortId: 'input',
            existingConnections: existingConnections,
          );
          expect(result.sourceBus, equals(21));
          existingConnections.add(
            Connection(
              id: 'conn1',
              sourceAlgorithmIndex: 0,
              sourcePortId: 'output',
              targetAlgorithmIndex: 1,
              targetPortId: 'input',
              assignedBus: 21,
              replaceMode: true,
              isValid: true,
            ),
          );

          // Add connection 2 (gets bus 22)
          result = await service.assignBusForConnection(
            sourceAlgorithmIndex: 2,
            sourcePortId: 'output',
            targetAlgorithmIndex: 3,
            targetPortId: 'input',
            existingConnections: existingConnections,
          );
          expect(result.sourceBus, equals(22));
          existingConnections.add(
            Connection(
              id: 'conn2',
              sourceAlgorithmIndex: 2,
              sourcePortId: 'output',
              targetAlgorithmIndex: 3,
              targetPortId: 'input',
              assignedBus: 22,
              replaceMode: true,
              isValid: true,
            ),
          );

          // Add connection 3 (gets bus 23)
          result = await service.assignBusForConnection(
            sourceAlgorithmIndex: 4,
            sourcePortId: 'output',
            targetAlgorithmIndex: 5,
            targetPortId: 'input',
            existingConnections: existingConnections,
          );
          expect(result.sourceBus, equals(23));
          existingConnections.add(
            Connection(
              id: 'conn3',
              sourceAlgorithmIndex: 4,
              sourcePortId: 'output',
              targetAlgorithmIndex: 5,
              targetPortId: 'input',
              assignedBus: 23,
              replaceMode: true,
              isValid: true,
            ),
          );

          // Remove connection 2 (frees bus 22)
          existingConnections.removeWhere((c) => c.id == 'conn2');

          // Add new connection (should reuse freed bus 22)
          result = await service.assignBusForConnection(
            sourceAlgorithmIndex: 6,
            sourcePortId: 'output',
            targetAlgorithmIndex: 7,
            targetPortId: 'input',
            existingConnections: existingConnections,
          );
          expect(result.sourceBus, equals(22)); // Reuses freed bus
        },
      );

      test('should handle signal splitting and rerouting', () async {
        // Start with A->B using bus 21
        var existingConnections = [
          const Connection(
            id: 'conn1',
            sourceAlgorithmIndex: 0,
            sourcePortId: 'output',
            targetAlgorithmIndex: 1,
            targetPortId: 'input',
            assignedBus: 21,
            replaceMode: true,
            isValid: true,
          ),
        ];

        // Add A->C while A->B still exists (signal splitting)
        // Should REUSE bus 21 since same source
        var result = await service.assignBusForConnection(
          sourceAlgorithmIndex: 0,
          sourcePortId: 'output',
          targetAlgorithmIndex: 2, // Different target
          targetPortId: 'input',
          existingConnections: existingConnections,
        );
        expect(result.sourceBus, equals(21)); // Reuses bus for signal splitting

        // Now remove A->B connection, keeping only A->C
        existingConnections = [
          const Connection(
            id: 'conn2',
            sourceAlgorithmIndex: 0,
            sourcePortId: 'output',
            targetAlgorithmIndex: 2,
            targetPortId: 'input',
            assignedBus: 21, // Still using bus 21
            replaceMode: true,
            isValid: true,
          ),
        ];

        // Now connect B->C to a different input (bus 21 is still in use by A->C)
        result = await service.assignBusForConnection(
          sourceAlgorithmIndex: 1,
          sourcePortId: 'output',
          targetAlgorithmIndex: 2,
          targetPortId: 'input2', // Different input port
          existingConnections: existingConnections,
        );
        expect(result.sourceBus, equals(22)); // Gets new bus since 21 is in use
      });
    });

    group('Edge Labels', () {
      test('should generate correct labels for different bus types', () async {
        // Test aux bus label
        var result = await service.assignBusForConnection(
          sourceAlgorithmIndex: 0,
          sourcePortId: 'output',
          targetAlgorithmIndex: 1,
          targetPortId: 'input',
          existingConnections: [],
        );
        expect(result.edgeLabel, equals('A1 R')); // Aux 1 Replace

        // Fill aux buses to test output bus label
        final existingConnections = <Connection>[];
        for (int i = 21; i <= 28; i++) {
          existingConnections.add(
            Connection(
              id: 'aux_$i',
              sourceAlgorithmIndex: i - 21,
              sourcePortId: 'out',
              targetAlgorithmIndex: i - 20,
              targetPortId: 'in',
              assignedBus: i,
              replaceMode: true,
              isValid: true,
            ),
          );
        }

        result = await service.assignBusForConnection(
          sourceAlgorithmIndex: 10,
          sourcePortId: 'output',
          targetAlgorithmIndex: 11,
          targetPortId: 'input',
          existingConnections: existingConnections,
        );
        expect(result.edgeLabel, equals('O1 R')); // Output 1 Replace
      });
    });

    group('Error Handling', () {
      test(
        'should throw InsufficientBusesException when all buses exhausted',
        () {
          // Fill all buses
          final existingConnections = <Connection>[];
          for (int i = 1; i <= 28; i++) {
            existingConnections.add(
              Connection(
                id: 'bus_$i',
                sourceAlgorithmIndex: i,
                sourcePortId: 'out',
                targetAlgorithmIndex: i + 100,
                targetPortId: 'in',
                assignedBus: i,
                replaceMode: true,
                isValid: true,
              ),
            );
          }

          expect(
            () => service.assignBusForConnection(
              sourceAlgorithmIndex: 50,
              sourcePortId: 'output',
              targetAlgorithmIndex: 51,
              targetPortId: 'input',
              existingConnections: existingConnections,
            ),
            throwsA(isA<InsufficientBusesException>()),
          );
        },
      );
    });
  });
}
