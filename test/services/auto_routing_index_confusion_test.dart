import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:nt_helper/cubit/disting_cubit.dart';
import 'package:nt_helper/domain/i_disting_midi_manager.dart';
import 'package:nt_helper/domain/disting_nt_sysex.dart';
import 'package:nt_helper/models/firmware_version.dart';
import 'package:nt_helper/services/auto_routing_service.dart';

@GenerateMocks([DistingCubit, IDistingMidiManager])
import 'auto_routing_index_confusion_test.mocks.dart';

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

  group('AutoRoutingService - Algorithm Index Confusion', () {
    late MockDistingCubit mockCubit;
    late AutoRoutingService service;
    late MockIDistingMidiManager mockDisting;

    setUp(() {
      mockCubit = MockDistingCubit();
      service = AutoRoutingService(mockCubit);
      mockDisting = MockIDistingMidiManager();
    });

    test('should distinguish between algorithm index and physical node index', () async {
      // Physical nodes have negative indices:
      // -2 = Physical Inputs
      // -3 = Physical Outputs
      // -1 = External Output
      // Algorithm indices are >= 0
      
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
            // Slot 1 - Target (algorithm, not physical)
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
            // Slot 2 - Another algorithm  
            Slot(
              algorithm: Algorithm(algorithmIndex: 2, guid: 'alg2', name: 'Algorithm 2'),
              routing: RoutingInfo(algorithmIndex: 2, routingInfo: []),
              pages: ParameterPages(algorithmIndex: 2, pages: []),
              parameters: [
                ParameterInfo(
                  algorithmIndex: 2,
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
            // Slot 3 - Yet another (to test if index 3 gets confused with -3)
            Slot(
              algorithm: Algorithm(algorithmIndex: 3, guid: 'alg3', name: 'Algorithm 3'),
              routing: RoutingInfo(algorithmIndex: 3, routingInfo: []),
              pages: ParameterPages(algorithmIndex: 3, pages: []),
              parameters: [
                ParameterInfo(
                  algorithmIndex: 3,
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

      // Test algorithm to algorithm (index 0 to 1)
      final result1 = await service.assignBusForConnection(
        sourceAlgorithmIndex: 0,
        sourcePortId: '10',
        targetAlgorithmIndex: 1, // Algorithm, not physical
        targetPortId: '0',
        existingConnections: [],
      );

      // Algorithm 0 to Algorithm 1:
      // Bus should be aux bus (21-28)
      
      // Should use aux bus for algorithm-to-algorithm
      expect(result1.sourceBus, greaterThanOrEqualTo(21));
      expect(result1.sourceBus, lessThanOrEqualTo(28));

      // Test to physical output (negative index)
      final result2 = await service.assignBusForConnection(
        sourceAlgorithmIndex: 0,
        sourcePortId: '10',
        targetAlgorithmIndex: -3, // Physical output
        targetPortId: 'physical_output_1',
        existingConnections: [],
      );

      // Algorithm 0 to Physical Output:
      // Bus should be output bus 13 (O1)
      
      // Should use fixed output bus
      expect(result2.sourceBus, equals(13)); // Output 1 = bus 13

      // Test algorithm index 3 (should NOT be confused with -3)
      final result3 = await service.assignBusForConnection(
        sourceAlgorithmIndex: 0,
        sourcePortId: '10',
        targetAlgorithmIndex: 3, // Algorithm 3, NOT physical output -3
        targetPortId: '0',
        existingConnections: [],
      );

      // Algorithm 0 to Algorithm 3:
      // Bus should be aux bus (21-28), NOT output bus
      
      // Should use aux bus, NOT output bus
      expect(result3.sourceBus, isNot(inInclusiveRange(13, 20)));
      expect(result3.sourceBus, greaterThanOrEqualTo(21));
      expect(result3.sourceBus, lessThanOrEqualTo(28));
    });

    test('should handle VCF at various slot positions without confusing with physical nodes', () async {
      // Test VCF in different slot positions to ensure no confusion
      
      for (int vcfSlot in [0, 1, 2, 3, 4, 5]) {
        // Testing VCF in slot $vcfSlot
        
        final slots = <Slot>[];
        
        // Add source before VCF
        if (vcfSlot > 0) {
          slots.add(Slot(
            algorithm: Algorithm(algorithmIndex: 0, guid: 'src', name: 'Source'),
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
          ));
        }
        
        // Add VCF at specified slot
        slots.add(Slot(
          algorithm: Algorithm(algorithmIndex: vcfSlot, guid: 'vcf', name: 'VCF'),
          routing: RoutingInfo(algorithmIndex: vcfSlot, routingInfo: []),
          pages: ParameterPages(algorithmIndex: vcfSlot, pages: []),
          parameters: [
            ParameterInfo(
              algorithmIndex: vcfSlot,
              parameterNumber: 0,
              name: 'Width',
              min: 1,
              max: 4,
              defaultValue: 2,
              unit: 0,
              powerOfTen: 0,
            ),
            ParameterInfo(
              algorithmIndex: vcfSlot,
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
              algorithmIndex: vcfSlot,
              parameterNumber: 0,
              value: 2, // Stereo
            ),
          ],
          enums: [],
          mappings: [],
          valueStrings: [],
        ));
        
        // Add algorithms after VCF to fill slots
        for (int i = slots.length; i <= 5; i++) {
          slots.add(Slot(
            algorithm: Algorithm(algorithmIndex: i, guid: 'fill$i', name: 'Filler $i'),
            routing: RoutingInfo(algorithmIndex: i, routingInfo: []),
            pages: ParameterPages(algorithmIndex: i, pages: []),
            parameters: [],
            values: [],
            enums: [],
            mappings: [],
            valueStrings: [],
          ));
        }
        
        when(mockCubit.state).thenReturn(
          DistingState.synchronized(
            disting: mockDisting,
            distingVersion: '',
            firmwareVersion: FirmwareVersion('1.0.0'),
            presetName: 'Test',
            algorithms: [],
            slots: slots,
            unitStrings: [],
          ),
        );
        
        // Connect to VCF
        final sourceIndex = vcfSlot > 0 ? 0 : vcfSlot + 1;
        final result = await service.assignBusForConnection(
          sourceAlgorithmIndex: sourceIndex,
          sourcePortId: '10',
          targetAlgorithmIndex: vcfSlot, // VCF algorithm index
          targetPortId: '1',
          existingConnections: [],
        );
        
        // VCF at index $vcfSlot -> Bus ${result.sourceBus}
        // Should be aux bus (21-28), not output bus (13-20)
        
        // Should always use aux bus, never physical output bus
        expect(result.sourceBus, isNot(inInclusiveRange(13, 20)), 
            reason: 'VCF at slot $vcfSlot incorrectly routed to physical output bus');
        expect(result.sourceBus, greaterThanOrEqualTo(21),
            reason: 'VCF at slot $vcfSlot should use aux bus');
      }
    });

    test('should correctly interpret port IDs that might look like physical outputs', () async {
      // Some port IDs might accidentally match patterns for physical outputs
      
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
                // Parameter number 13 might be confused with output bus 13
                ParameterInfo(
                  algorithmIndex: 0,
                  parameterNumber: 13,
                  name: 'Some Output',
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
                // Parameter numbers that might be confused with bus numbers
                ParameterInfo(
                  algorithmIndex: 1,
                  parameterNumber: 14,
                  name: 'Some Input',
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
        sourcePortId: '13', // Parameter 13, not bus 13
        targetAlgorithmIndex: 1,
        targetPortId: '14', // Parameter 14, not bus 14
        existingConnections: [],
      );

      // Connection with parameter numbers 13->14:
      // Bus assigned should be aux bus, not confused with output buses 13-14
      
      // Should not be confused and use output buses
      expect(result.sourceBus, greaterThanOrEqualTo(21));
      expect(result.sourceBus, lessThanOrEqualTo(28));
    });
  });
}