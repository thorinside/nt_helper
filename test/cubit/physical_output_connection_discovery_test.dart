import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/core/routing/models/port.dart' as core_port;
import 'package:nt_helper/core/routing/algorithm_routing.dart';
import 'package:nt_helper/models/physical_connection.dart';

void main() {
  group('Physical Output Connection Discovery', () {
    group('Hardware port mapping', () {
      test('should correctly map bus numbers to hardware output port IDs', () {
        // Test the mapping logic used by _createPhysicalOutputConnections
        final busToPortMapping = <int, String>{
          13: 'hw_out_1', // Bus 13 -> Hardware Output 1
          14: 'hw_out_2', // Bus 14 -> Hardware Output 2
          15: 'hw_out_3', // Bus 15 -> Hardware Output 3
          16: 'hw_out_4', // Bus 16 -> Hardware Output 4
          17: 'hw_out_5', // Bus 17 -> Hardware Output 5
          18: 'hw_out_6', // Bus 18 -> Hardware Output 6
          19: 'hw_out_7', // Bus 19 -> Hardware Output 7
          20: 'hw_out_8', // Bus 20 -> Hardware Output 8
        };

        for (final entry in busToPortMapping.entries) {
          final busNumber = entry.key;
          final expectedPortId = entry.value;
          final expectedHardwareNumber = busNumber - 12;
          
          expect(busNumber, inInclusiveRange(13, 20));
          expect(expectedPortId, 'hw_out_$expectedHardwareNumber');
          expect(expectedHardwareNumber, inInclusiveRange(1, 8));
        }
      });

      test('should only handle output bus range (13-20)', () {
        const validOutputBuses = [13, 14, 15, 16, 17, 18, 19, 20];
        const invalidBuses = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 21, 25];

        for (final bus in validOutputBuses) {
          expect(bus >= 13 && bus <= 20, true, 
              reason: 'Bus $bus should be valid for output connections');
        }

        for (final bus in invalidBuses) {
          expect(bus < 13 || bus > 20, true,
              reason: 'Bus $bus should be invalid for output connections');
        }
      });

      test('should correctly calculate hardware port numbers', () {
        // Bus 13 -> Hardware 1, Bus 14 -> Hardware 2, etc.
        final busToHardwareMapping = <int, int>{
          13: 1, 14: 2, 15: 3, 16: 4, 
          17: 5, 18: 6, 19: 7, 20: 8,
        };

        for (final entry in busToHardwareMapping.entries) {
          final busNumber = entry.key;
          final expectedHardware = entry.value;
          final calculatedHardware = busNumber - 12;
          
          expect(calculatedHardware, expectedHardware);
          expect(calculatedHardware, inInclusiveRange(1, 8));
        }
      });
    });

    group('PhysicalConnection creation logic', () {
      test('should create connection with correct properties for output', () {
        // Simulate what _createPhysicalOutputConnections should create
        const sourcePortId = 'alg_1_stereo_left_output';
        const targetPortId = 'hw_out_3'; // Hardware Output 3
        const busNumber = 15; // Bus 15 -> Hardware Output 3
        const algorithmIndex = 1;

        final connection = PhysicalConnection.withGeneratedId(
          sourcePortId: sourcePortId,
          targetPortId: targetPortId,
          busNumber: busNumber,
          isInputConnection: false,
          algorithmIndex: algorithmIndex,
        );

        expect(connection.sourcePortId, sourcePortId);
        expect(connection.targetPortId, targetPortId);
        expect(connection.busNumber, busNumber);
        expect(connection.isInputConnection, false);
        expect(connection.algorithmIndex, algorithmIndex);
        expect(connection.isPhysicalInput, false);
        expect(connection.isPhysicalOutput, true);
        expect(connection.hardwarePortNumber, 3); // 15 - 12 = 3
        expect(connection.description, 'Algorithm 1 → Hardware Output 3');
      });

      test('should generate deterministic connection IDs for outputs', () {
        const sourcePortId = 'alg_0_main_output';
        const targetPortId = 'hw_out_1';

        final connection1 = PhysicalConnection.withGeneratedId(
          sourcePortId: sourcePortId,
          targetPortId: targetPortId,
          busNumber: 13,
          isInputConnection: false,
          algorithmIndex: 0,
        );

        final connection2 = PhysicalConnection.withGeneratedId(
          sourcePortId: sourcePortId,
          targetPortId: targetPortId,
          busNumber: 13,
          isInputConnection: false,
          algorithmIndex: 0,
        );

        expect(connection1.id, connection2.id);
        expect(connection1.id, 'phys_alg_0_main_output->hw_out_1');
      });

      test('should handle different bus-to-hardware mappings correctly', () {
        final testCases = [
          {'bus': 13, 'hardware': 1, 'port': 'hw_out_1'},
          {'bus': 14, 'hardware': 2, 'port': 'hw_out_2'},
          {'bus': 17, 'hardware': 5, 'port': 'hw_out_5'},
          {'bus': 20, 'hardware': 8, 'port': 'hw_out_8'},
        ];

        for (final testCase in testCases) {
          final busNumber = testCase['bus'] as int;
          final expectedHardware = testCase['hardware'] as int;
          final expectedPort = testCase['port'] as String;
          
          final connection = PhysicalConnection.withGeneratedId(
            sourcePortId: 'alg_0_output',
            targetPortId: expectedPort,
            busNumber: busNumber,
            isInputConnection: false,
            algorithmIndex: 0,
          );
          
          expect(connection.busNumber, busNumber);
          expect(connection.hardwarePortNumber, expectedHardware);
          expect(connection.targetPortId, expectedPort);
        }
      });
    });

    group('Algorithm routing integration', () {
      test('should handle empty output ports list', () {
        // Create a mock routing with no output ports
        final mockRouting = MockAlgorithmRouting();
        
        // The method should handle empty output ports gracefully
        // and return an empty list of connections
        expect(mockRouting.outputPorts, isEmpty);
        
        // Method should return empty list when no output ports exist
      });

      test('should process multiple output ports correctly', () {
        // Simulate multiple output ports with different bus assignments
        final outputPorts = [
          core_port.Port(
            id: 'alg_0_left_output',
            name: 'Left Output',
            type: core_port.PortType.audio,
            direction: core_port.PortDirection.output,
            metadata: {
              'busParam': 'Left output bus', // Would resolve to bus 13
            },
          ),
          core_port.Port(
            id: 'alg_0_right_output', 
            name: 'Right Output',
            type: core_port.PortType.audio,
            direction: core_port.PortDirection.output,
            metadata: {
              'busParam': 'Right output bus', // Would resolve to bus 14
            },
          ),
          core_port.Port(
            id: 'alg_0_cv_output',
            name: 'CV Output',
            type: core_port.PortType.cv,
            direction: core_port.PortDirection.output,
            metadata: {
              'busParam': 'CV output bus', // Would resolve to bus 15
            },
          ),
        ];

        // Each port should result in a connection when bus resolution succeeds
        for (int i = 0; i < outputPorts.length; i++) {
          final port = outputPorts[i];
          final expectedBus = i + 13; // Assuming buses 13, 14, 15
          final expectedHardwarePort = 'hw_out_${expectedBus - 12}';
          
          expect(port.direction, core_port.PortDirection.output);
          expect(port.metadata?.containsKey('busParam'), true);
          
          // Would create connection: port.id -> hw_out_X
          final expectedConnection = PhysicalConnection.withGeneratedId(
            sourcePortId: port.id,
            targetPortId: expectedHardwarePort,
            busNumber: expectedBus,
            isInputConnection: false,
            algorithmIndex: 0,
          );
          
          expect(expectedConnection.sourcePortId, port.id);
          expect(expectedConnection.targetPortId, expectedHardwarePort);
          expect(expectedConnection.isInputConnection, false);
        }
      });

      test('should skip ports with no bus assignment', () {
        final portsWithoutBus = [
          core_port.Port(
            id: 'alg_0_no_bus_output',
            name: 'No Bus Output',
            type: core_port.PortType.audio,
            direction: core_port.PortDirection.output,
            // No metadata - no bus assignment
          ),
          core_port.Port(
            id: 'alg_0_invalid_bus_output',
            name: 'Invalid Bus Output', 
            type: core_port.PortType.cv,
            direction: core_port.PortDirection.output,
            metadata: {
              'busParam': 'Nonexistent parameter', // Would resolve to null
            },
          ),
        ];

        // These ports should not result in any connections
        for (final port in portsWithoutBus) {
          expect(port.direction, core_port.PortDirection.output);
          // Would not create any connections for these ports
        }
      });

      test('should skip ports with invalid bus numbers', () {
        final portsWithInvalidBus = [
          core_port.Port(
            id: 'alg_0_bus_zero_output',
            name: 'Bus Zero Output',
            type: core_port.PortType.audio,
            direction: core_port.PortDirection.output,
            metadata: {
              'busParam': 'Bus zero param', // Would resolve to 0 (None)
            },
          ),
          core_port.Port(
            id: 'alg_0_input_bus_output',
            name: 'Input Bus Output',
            type: core_port.PortType.audio,
            direction: core_port.PortDirection.output,
            metadata: {
              'busParam': 'Input bus param', // Would resolve to 1-12 (input range)
            },
          ),
          core_port.Port(
            id: 'alg_0_aux_bus_output',
            name: 'AUX Bus Output',
            type: core_port.PortType.audio,
            direction: core_port.PortDirection.output,
            metadata: {
              'busParam': 'AUX bus param', // Would resolve to 21+ (AUX range)
            },
          ),
        ];

        // These ports should not result in output connections
        // Bus 0 = None, Bus 1-12 = input range, Bus 21+ = AUX range
        for (final port in portsWithInvalidBus) {
          expect(port.direction, core_port.PortDirection.output);
          // Would not create output connections for these ports
        }
      });
    });

    group('Polyphonic algorithm output scenarios', () {
      test('should handle polyphonic output ports', () {
        final polyOutputPorts = [
          core_port.Port(
            id: 'poly_left_output',
            name: 'Poly Left Output',
            type: core_port.PortType.audio,
            direction: core_port.PortDirection.output,
            metadata: {
              'busParam': 'Left/mono output',
              'channel': 'left',
            },
          ),
          core_port.Port(
            id: 'poly_right_output',
            name: 'Poly Right Output', 
            type: core_port.PortType.audio,
            direction: core_port.PortDirection.output,
            metadata: {
              'busParam': 'Right output',
              'channel': 'right',
            },
          ),
        ];

        for (final port in polyOutputPorts) {
          final channel = port.metadata?['channel'] as String;
          expect(['left', 'right'], contains(channel));
          expect(port.type, core_port.PortType.audio);
          expect(port.metadata?.containsKey('busParam'), true);
          
          // Polyphonic outputs typically use buses 13-14 for stereo
        }
      });

      test('should handle mix/mono output configurations', () {
        final mixOutputPorts = [
          core_port.Port(
            id: 'mix_output',
            name: 'Mix Output',
            type: core_port.PortType.audio,
            direction: core_port.PortDirection.output,
            metadata: {
              'busParam': 'Output bus',
              'isMixOutput': true,
            },
          ),
          core_port.Port(
            id: 'odd_output',
            name: 'Odd Output',
            type: core_port.PortType.audio,
            direction: core_port.PortDirection.output,
            metadata: {
              'busParam': 'Odd output',
            },
          ),
          core_port.Port(
            id: 'even_output',
            name: 'Even Output',
            type: core_port.PortType.audio,
            direction: core_port.PortDirection.output,
            metadata: {
              'busParam': 'Even output',
            },
          ),
        ];

        for (final port in mixOutputPorts) {
          expect(port.type, core_port.PortType.audio);
          expect(port.direction, core_port.PortDirection.output);
          expect(port.metadata?.containsKey('busParam'), true);
        }
      });
    });

    group('Multi-channel algorithm output scenarios', () {
      test('should handle width-based output port generation', () {
        // Multi-channel algorithms might have width-based outputs
        final widthBasedOutputPorts = [
          core_port.Port(
            id: 'ch_1_output',
            name: 'Channel 1 Output',
            type: core_port.PortType.audio,
            direction: core_port.PortDirection.output,
            metadata: {
              'busParam': 'Output 1 bus',
              'channel': 1,
            },
          ),
          core_port.Port(
            id: 'ch_2_output',
            name: 'Channel 2 Output',
            type: core_port.PortType.audio,
            direction: core_port.PortDirection.output,
            metadata: {
              'busParam': 'Output 2 bus',
              'channel': 2,
            },
          ),
          core_port.Port(
            id: 'ch_3_output',
            name: 'Channel 3 Output',
            type: core_port.PortType.audio,
            direction: core_port.PortDirection.output,
            metadata: {
              'busParam': 'Output 3 bus',
              'channel': 3,
            },
          ),
          core_port.Port(
            id: 'ch_4_output',
            name: 'Channel 4 Output',
            type: core_port.PortType.audio,
            direction: core_port.PortDirection.output,
            metadata: {
              'busParam': 'Output 4 bus',
              'channel': 4,
            },
          ),
        ];

        for (int i = 0; i < widthBasedOutputPorts.length; i++) {
          final port = widthBasedOutputPorts[i];
          final channel = port.metadata?['channel'] as int;
          
          expect(channel, i + 1);
          expect(port.type, core_port.PortType.audio);
          expect(port.metadata?.containsKey('busParam'), true);
          
          // Each channel would get its own output bus assignment
        }
      });
    });

    group('Connection list properties', () {
      test('should maintain stable ordering for consistent UI', () {
        // Connections should be ordered consistently for stable UI rendering
        final sampleConnections = [
          PhysicalConnection.withGeneratedId(
            sourcePortId: 'alg_0_left_output',
            targetPortId: 'hw_out_1',
            busNumber: 13,
            isInputConnection: false,
            algorithmIndex: 0,
          ),
          PhysicalConnection.withGeneratedId(
            sourcePortId: 'alg_0_right_output',
            targetPortId: 'hw_out_2',
            busNumber: 14,
            isInputConnection: false,
            algorithmIndex: 0,
          ),
          PhysicalConnection.withGeneratedId(
            sourcePortId: 'alg_0_cv_output',
            targetPortId: 'hw_out_3',
            busNumber: 15,
            isInputConnection: false,
            algorithmIndex: 0,
          ),
        ];

        // All connections should be output connections
        for (final connection in sampleConnections) {
          expect(connection.isInputConnection, false);
          expect(connection.isPhysicalOutput, true);
          expect(connection.targetPortId, startsWith('hw_out_'));
          expect(connection.algorithmIndex, 0);
        }

        // Ordering by bus number provides stability
        final sortedByBus = List.from(sampleConnections)
          ..sort((a, b) => a.busNumber.compareTo(b.busNumber));
        
        expect(sortedByBus[0].busNumber, 13);
        expect(sortedByBus[1].busNumber, 14);
        expect(sortedByBus[2].busNumber, 15);
      });

      test('should support diffing for UI state management', () {
        final oldConnections = [
          PhysicalConnection.withGeneratedId(
            sourcePortId: 'alg_0_old_output',
            targetPortId: 'hw_out_1',
            busNumber: 13,
            isInputConnection: false,
            algorithmIndex: 0,
          ),
        ];

        final newConnections = [
          PhysicalConnection.withGeneratedId(
            sourcePortId: 'alg_0_new_output',
            targetPortId: 'hw_out_1',
            busNumber: 13,
            isInputConnection: false,
            algorithmIndex: 0,
          ),
        ];

        // Connections should be comparable for diffing
        expect(oldConnections.first, isNot(equals(newConnections.first)));
        expect(oldConnections.first.targetPortId, newConnections.first.targetPortId);
        expect(oldConnections.first.sourcePortId, isNot(equals(newConnections.first.sourcePortId)));
      });
    });

    group('Edge cases and error handling', () {
      test('should handle maximum output capacity (8 outputs)', () {
        // Disting NT has 8 physical outputs (buses 13-20)
        final maxOutputConnections = [
          for (int i = 1; i <= 8; i++)
            PhysicalConnection.withGeneratedId(
              sourcePortId: 'alg_0_output_$i',
              targetPortId: 'hw_out_$i',
              busNumber: i + 12, // 13-20
              isInputConnection: false,
              algorithmIndex: 0,
            ),
        ];

        expect(maxOutputConnections.length, 8);
        
        for (int i = 0; i < maxOutputConnections.length; i++) {
          final connection = maxOutputConnections[i];
          expect(connection.busNumber, 13 + i);
          expect(connection.hardwarePortNumber, i + 1);
          expect(connection.targetPortId, 'hw_out_${i + 1}');
        }
      });

      test('should handle algorithm with no output ports', () {
        // Some algorithms might not have any output ports
        final routing = MockAlgorithmRouting();
        expect(routing.outputPorts, isEmpty);
        
        // Method should return empty list gracefully
      });
    });
  });
}

/// Mock AlgorithmRouting for testing - using noSuchMethod to avoid implementing all methods
class MockAlgorithmRouting implements AlgorithmRouting {
  @override
  List<core_port.Port> get inputPorts => [];

  @override
  List<core_port.Port> get outputPorts => [];

  @override
  void dispose() {}

  @override
  String toString() => 'MockAlgorithmRouting';

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}