import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:nt_helper/cubit/disting_cubit.dart';
import 'package:nt_helper/domain/i_disting_midi_manager.dart';
import 'package:nt_helper/domain/disting_nt_sysex.dart';
import 'package:nt_helper/models/firmware_version.dart';
import 'package:nt_helper/services/auto_routing_service.dart';

@GenerateMocks([DistingCubit, IDistingMidiManager])
import 'auto_routing_port_id_test.mocks.dart';

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

  group('AutoRoutingService - Port ID Suffix Handling', () {
    late MockDistingCubit mockCubit;
    late AutoRoutingService service;
    late MockIDistingMidiManager mockDisting;

    setUp(() {
      mockCubit = MockDistingCubit();
      service = AutoRoutingService(mockCubit);
      mockDisting = MockIDistingMidiManager();
    });

    test(
      'should handle stereo VCF port IDs with L/R suffixes from UI',
      () async {
        // This test simulates what happens when the UI passes port IDs
        // with suffixes like "1_L" or "1_R" for stereo algorithms

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
                algorithm: Algorithm(
                  algorithmIndex: 0,
                  guid: 'src',
                  name: 'Source',
                ),
                routing: RoutingInfo(algorithmIndex: 0, routingInfo: []),
                pages: ParameterPages(algorithmIndex: 0, pages: []),
                parameters: [
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
                values: [],
                enums: [],
                mappings: [],
                valueStrings: [],
              ),
              // VCF with width=2
              Slot(
                algorithm: Algorithm(
                  algorithmIndex: 1,
                  guid: 'vcf',
                  name: 'VCF',
                ),
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

        // Test with suffixed port ID as the UI would provide
        final result = await service.assignBusForConnection(
          sourceAlgorithmIndex: 0,
          sourcePortId: '10',
          targetAlgorithmIndex: 1,
          targetPortId: '1_L', // UI provides suffixed port ID for left channel
          existingConnections: [],
        );

        // Result for 1_L port ID:
        // Source bus, channel count, and parameter updates

        // Should still work correctly even with suffixed port ID
        expect(result.channelCount, equals(2));
        expect(result.assignedBuses.length, equals(2));
        expect(
          result.sourceBus,
          greaterThanOrEqualTo(21),
        ); // Should use aux bus
      },
    );

    test(
      'should handle UI dragging to specific channel of stereo target',
      () async {
        // When user drags specifically to the R channel of a stereo input

        when(mockCubit.state).thenReturn(
          DistingState.synchronized(
            disting: mockDisting,
            distingVersion: '',
            firmwareVersion: FirmwareVersion('1.0.0'),
            presetName: 'Test',
            algorithms: [],
            slots: [
              Slot(
                algorithm: Algorithm(
                  algorithmIndex: 0,
                  guid: 'src',
                  name: 'Source',
                ),
                routing: RoutingInfo(algorithmIndex: 0, routingInfo: []),
                pages: ParameterPages(algorithmIndex: 0, pages: []),
                parameters: [
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
                values: [],
                enums: [],
                mappings: [],
                valueStrings: [],
              ),
              Slot(
                algorithm: Algorithm(
                  algorithmIndex: 1,
                  guid: 'vcf',
                  name: 'VCF',
                ),
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

        // User drags to right channel specifically
        final result = await service.assignBusForConnection(
          sourceAlgorithmIndex: 0,
          sourcePortId: '10',
          targetAlgorithmIndex: 1,
          targetPortId: '1_R', // Right channel port ID
          existingConnections: [],
        );

        // Should still create both channel connections
        expect(result.channelCount, equals(2));
        expect(result.assignedBuses.length, equals(2));
      },
    );

    test(
      'should not confuse algorithm input with physical output when port ID has suffix',
      () async {
        // This tests the specific bug where suffixed port IDs might cause
        // the system to route to physical outputs instead

        when(mockCubit.state).thenReturn(
          DistingState.synchronized(
            disting: mockDisting,
            distingVersion: '',
            firmwareVersion: FirmwareVersion('1.0.0'),
            presetName: 'Test',
            algorithms: [],
            slots: [
              Slot(
                algorithm: Algorithm(
                  algorithmIndex: 0,
                  guid: 'pyms',
                  name: 'Poly Multisample',
                ),
                routing: RoutingInfo(algorithmIndex: 0, routingInfo: []),
                pages: ParameterPages(algorithmIndex: 0, pages: []),
                parameters: [
                  ParameterInfo(
                    algorithmIndex: 0,
                    parameterNumber: 20,
                    name: 'Main Output L',
                    min: 0,
                    max: 28,
                    defaultValue: 0,
                    unit: 1,
                    powerOfTen: 0,
                  ),
                  ParameterInfo(
                    algorithmIndex: 0,
                    parameterNumber: 21,
                    name: 'Main Output R',
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
                algorithm: Algorithm(
                  algorithmIndex: 1,
                  guid: 'vcf',
                  name: 'VCF',
                ),
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
                    parameterNumber: 3, // Different parameter number
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

        // Connect with suffixed port ID
        final result = await service.assignBusForConnection(
          sourceAlgorithmIndex: 0,
          sourcePortId: '20', // Poly Multisample L output
          targetAlgorithmIndex: 1, // VCF algorithm, NOT physical output (-3)
          targetPortId: '3_L', // Suffixed port ID
          existingConnections: [],
        );

        // Verify it's NOT using physical output buses (13-20)
        expect(result.sourceBus, isNot(inInclusiveRange(13, 20)));
        // Should use aux buses
        expect(result.sourceBus, greaterThanOrEqualTo(21));
        expect(result.sourceBus, lessThanOrEqualTo(28));

        // Verify the target is being set correctly
        final targetUpdates = result.parameterUpdates
            .where((u) => u.algorithmIndex == 1)
            .toList();
        expect(targetUpdates, isNotEmpty);
        expect(
          targetUpdates.first.algorithmIndex,
          equals(1),
        ); // VCF, not physical
      },
    );

    test('should strip channel suffix when finding base parameter', () async {
      // Test that we correctly handle stripping _L, _R, _1, _2 suffixes

      when(mockCubit.state).thenReturn(
        DistingState.synchronized(
          disting: mockDisting,
          distingVersion: '',
          firmwareVersion: FirmwareVersion('1.0.0'),
          presetName: 'Test',
          algorithms: [],
          slots: [
            Slot(
              algorithm: Algorithm(
                algorithmIndex: 0,
                guid: 'src',
                name: 'Source',
              ),
              routing: RoutingInfo(algorithmIndex: 0, routingInfo: []),
              pages: ParameterPages(algorithmIndex: 0, pages: []),
              parameters: [
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
              values: [],
              enums: [],
              mappings: [],
              valueStrings: [],
            ),
            Slot(
              algorithm: Algorithm(
                algorithmIndex: 1,
                guid: 'mult',
                name: 'Multi-channel',
              ),
              routing: RoutingInfo(algorithmIndex: 1, routingInfo: []),
              pages: ParameterPages(algorithmIndex: 1, pages: []),
              parameters: [
                ParameterInfo(
                  algorithmIndex: 1,
                  parameterNumber: 0,
                  name: 'Width',
                  min: 1,
                  max: 4,
                  defaultValue: 4,
                  unit: 0,
                  powerOfTen: 0,
                ),
                ParameterInfo(
                  algorithmIndex: 1,
                  parameterNumber: 5,
                  name: 'Input',
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
                  value: 4, // 4 channels
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

      // Test various suffixes
      final testCases = [
        '5_1', // Channel 1
        '5_2', // Channel 2
        '5_3', // Channel 3
        '5_4', // Channel 4
      ];

      for (final portId in testCases) {
        final result = await service.assignBusForConnection(
          sourceAlgorithmIndex: 0,
          sourcePortId: '10',
          targetAlgorithmIndex: 1,
          targetPortId: portId,
          existingConnections: [],
        );

        // Testing port ID $portId:
        // Channel count and buses assigned

        // Should recognize width=4 and assign 4 consecutive buses
        expect(result.channelCount, equals(4));
        expect(result.assignedBuses.length, equals(4));
      }
    });
  });
}
