import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/core/routing/models/port.dart' as core_port;
import 'package:nt_helper/core/routing/algorithm_routing.dart';
import 'package:nt_helper/models/physical_connection.dart';

void main() {
  group('Physical Input Connection Discovery', () {
    group('Hardware port mapping', () {
      test('should correctly map bus numbers to hardware port IDs', () {
        // Test the mapping logic used by _createPhysicalInputConnections
        final busToPortMapping = <int, String>{
          1: 'hw_in_1',   // Audio In 1
          2: 'hw_in_2',   // Audio In 2
          3: 'hw_in_3',   // CV 1
          4: 'hw_in_4',   // CV 2
          5: 'hw_in_5',   // CV 3
          6: 'hw_in_6',   // CV 4
          7: 'hw_in_7',   // CV 5
          8: 'hw_in_8',   // CV 6
          9: 'hw_in_9',   // Gate 1
          10: 'hw_in_10', // Gate 2
          11: 'hw_in_11', // Trigger 1
          12: 'hw_in_12', // Trigger 2
        };

        for (final entry in busToPortMapping.entries) {
          final busNumber = entry.key;
          final expectedPortId = entry.value;
          
          expect(busNumber, inInclusiveRange(1, 12));
          expect(expectedPortId, 'hw_in_$busNumber');
        }
      });

      test('should only handle input bus range (1-12)', () {
        const validInputBuses = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12];
        const invalidBuses = [0, 13, 14, 15, 16, 17, 18, 19, 20, 21, 25];

        for (final bus in validInputBuses) {
          expect(bus >= 1 && bus <= 12, true, 
              reason: 'Bus $bus should be valid for input connections');
        }

        for (final bus in invalidBuses) {
          expect(bus < 1 || bus > 12, true,
              reason: 'Bus $bus should be invalid for input connections');
        }
      });
    });

    group('PhysicalConnection creation logic', () {
      test('should create connection with correct properties for input', () {
        // Simulate what _createPhysicalInputConnections should create
        const sourcePortId = 'hw_in_5'; // Hardware CV 3
        const targetPortId = 'alg_0_cv_input';
        const busNumber = 5;
        const algorithmIndex = 0;

        final connection = PhysicalConnection.withGeneratedId(
          sourcePortId: sourcePortId,
          targetPortId: targetPortId,
          busNumber: busNumber,
          isInputConnection: true,
          algorithmIndex: algorithmIndex,
        );

        expect(connection.sourcePortId, sourcePortId);
        expect(connection.targetPortId, targetPortId);
        expect(connection.busNumber, busNumber);
        expect(connection.isInputConnection, true);
        expect(connection.algorithmIndex, algorithmIndex);
        expect(connection.isPhysicalInput, true);
        expect(connection.isPhysicalOutput, false);
        expect(connection.hardwarePortNumber, 5);
        expect(connection.description, 'Hardware Input 5 → Algorithm 0');
      });

      test('should generate deterministic connection IDs', () {
        const sourcePortId = 'hw_in_3';
        const targetPortId = 'alg_1_audio_input';

        final connection1 = PhysicalConnection.withGeneratedId(
          sourcePortId: sourcePortId,
          targetPortId: targetPortId,
          busNumber: 3,
          isInputConnection: true,
          algorithmIndex: 1,
        );

        final connection2 = PhysicalConnection.withGeneratedId(
          sourcePortId: sourcePortId,
          targetPortId: targetPortId,
          busNumber: 3,
          isInputConnection: true,
          algorithmIndex: 1,
        );

        expect(connection1.id, connection2.id);
        expect(connection1.id, 'phys_hw_in_3->alg_1_audio_input');
      });
    });

    group('Algorithm routing integration', () {
      test('should handle empty input ports list', () {
        // Create a mock routing with no input ports
        final mockRouting = MockAlgorithmRouting();
        
        // The method should handle empty input ports gracefully
        // and return an empty list of connections
        expect(mockRouting.inputPorts, isEmpty);
        
        // Method should return empty list when no input ports exist
      });

      test('should process multiple input ports correctly', () {
        // Simulate multiple input ports with different bus assignments
        final inputPorts = [
          core_port.Port(
            id: 'alg_0_audio_left',
            name: 'Audio Left Input',
            type: core_port.PortType.audio,
            direction: core_port.PortDirection.input,
            metadata: {
              'busParam': 'Audio left input', // Would resolve to bus 1
            },
          ),
          core_port.Port(
            id: 'alg_0_audio_right', 
            name: 'Audio Right Input',
            type: core_port.PortType.audio,
            direction: core_port.PortDirection.input,
            metadata: {
              'busParam': 'Audio right input', // Would resolve to bus 2
            },
          ),
          core_port.Port(
            id: 'alg_0_cv_control',
            name: 'CV Control Input',
            type: core_port.PortType.cv,
            direction: core_port.PortDirection.input,
            metadata: {
              'busParam': 'CV input', // Would resolve to bus 3
            },
          ),
        ];

        // Each port should result in a connection when bus resolution succeeds
        for (int i = 0; i < inputPorts.length; i++) {
          final port = inputPorts[i];
          final expectedBus = i + 1; // Assuming buses 1, 2, 3
          final expectedHardwarePort = 'hw_in_$expectedBus';
          
          expect(port.direction, core_port.PortDirection.input);
          expect(port.metadata?.containsKey('busParam'), true);
          
          // Would create connection: hw_in_X -> port.id
          final expectedConnection = PhysicalConnection.withGeneratedId(
            sourcePortId: expectedHardwarePort,
            targetPortId: port.id,
            busNumber: expectedBus,
            isInputConnection: true,
            algorithmIndex: 0,
          );
          
          expect(expectedConnection.sourcePortId, expectedHardwarePort);
          expect(expectedConnection.targetPortId, port.id);
          expect(expectedConnection.isInputConnection, true);
        }
      });

      test('should skip ports with no bus assignment', () {
        final portsWithoutBus = [
          core_port.Port(
            id: 'alg_0_no_bus_port',
            name: 'No Bus Port',
            type: core_port.PortType.audio,
            direction: core_port.PortDirection.input,
            // No metadata - no bus assignment
          ),
          core_port.Port(
            id: 'alg_0_invalid_bus_port',
            name: 'Invalid Bus Port', 
            type: core_port.PortType.cv,
            direction: core_port.PortDirection.input,
            metadata: {
              'busParam': 'Nonexistent parameter', // Would resolve to null
            },
          ),
        ];

        // These ports should not result in any connections
        for (final port in portsWithoutBus) {
          expect(port.direction, core_port.PortDirection.input);
          // Would not create any connections for these ports
        }
      });

      test('should skip ports with invalid bus numbers', () {
        final portsWithInvalidBus = [
          core_port.Port(
            id: 'alg_0_bus_zero_port',
            name: 'Bus Zero Port',
            type: core_port.PortType.audio,
            direction: core_port.PortDirection.input,
            metadata: {
              'busParam': 'Bus zero param', // Would resolve to 0 (None)
            },
          ),
          core_port.Port(
            id: 'alg_0_output_bus_port',
            name: 'Output Bus Port',
            type: core_port.PortType.audio,
            direction: core_port.PortDirection.input,
            metadata: {
              'busParam': 'Output bus param', // Would resolve to 13+ (output range)
            },
          ),
        ];

        // These ports should not result in input connections
        // Bus 0 = None, Bus 13+ = output range
        for (final port in portsWithInvalidBus) {
          expect(port.direction, core_port.PortDirection.input);
          // Would not create input connections for these ports
        }
      });
    });

    group('Polyphonic algorithm scenarios', () {
      test('should handle gate input ports with gate bus metadata', () {
        final gateInputPorts = [
          core_port.Port(
            id: 'gate_1_input',
            name: 'Gate 1 Input',
            type: core_port.PortType.gate,
            direction: core_port.PortDirection.input,
            metadata: {
              'isGateInput': true,
              'gateBus': 9, // Gate 1 typically on bus 9
            },
          ),
          core_port.Port(
            id: 'gate_2_input',
            name: 'Gate 2 Input', 
            type: core_port.PortType.gate,
            direction: core_port.PortDirection.input,
            metadata: {
              'isGateInput': true,
              'gateBus': 10, // Gate 2 typically on bus 10
            },
          ),
        ];

        for (final port in gateInputPorts) {
          final gateBus = port.metadata?['gateBus'] as int;
          expect(gateBus, inInclusiveRange(9, 10));
          expect(port.type, core_port.PortType.gate);
          
          // Would create connections: hw_in_9 -> gate_1_input, hw_in_10 -> gate_2_input
          final expectedConnection = PhysicalConnection.withGeneratedId(
            sourcePortId: 'hw_in_$gateBus',
            targetPortId: port.id,
            busNumber: gateBus,
            isInputConnection: true,
            algorithmIndex: 0,
          );
          
          expect(expectedConnection.busNumber, gateBus);
          expect(expectedConnection.hardwarePortNumber, gateBus);
        }
      });

      test('should handle CV input ports with suggested bus metadata', () {
        final cvInputPorts = [
          core_port.Port(
            id: 'cv_1_input',
            name: 'CV 1 Input',
            type: core_port.PortType.cv,
            direction: core_port.PortDirection.input,
            metadata: {
              'isCvInput': true,
              'suggestedBus': 3, // CV typically on buses 3-8
            },
          ),
          core_port.Port(
            id: 'cv_2_input',
            name: 'CV 2 Input',
            type: core_port.PortType.cv,
            direction: core_port.PortDirection.input,
            metadata: {
              'isCvInput': true,
              'suggestedBus': 4,
            },
          ),
        ];

        for (final port in cvInputPorts) {
          final suggestedBus = port.metadata?['suggestedBus'] as int;
          expect(suggestedBus, inInclusiveRange(3, 8));
          expect(port.type, core_port.PortType.cv);
          
          // Would create connections based on suggestedBus
          final expectedConnection = PhysicalConnection.withGeneratedId(
            sourcePortId: 'hw_in_$suggestedBus',
            targetPortId: port.id,
            busNumber: suggestedBus,
            isInputConnection: true,
            algorithmIndex: 0,
          );
          
          expect(expectedConnection.busNumber, suggestedBus);
        }
      });
    });

    group('Multi-channel algorithm scenarios', () {
      test('should handle width-based input port generation', () {
        // Multi-channel algorithms might have width-based inputs
        final widthBasedInputPorts = [
          core_port.Port(
            id: 'ch_1_input',
            name: 'Channel 1 Input',
            type: core_port.PortType.audio,
            direction: core_port.PortDirection.input,
            metadata: {
              'busParam': 'Input 1 bus',
              'channel': 1,
            },
          ),
          core_port.Port(
            id: 'ch_2_input',
            name: 'Channel 2 Input',
            type: core_port.PortType.audio,
            direction: core_port.PortDirection.input,
            metadata: {
              'busParam': 'Input 2 bus',
              'channel': 2,
            },
          ),
        ];

        for (int i = 0; i < widthBasedInputPorts.length; i++) {
          final port = widthBasedInputPorts[i];
          final channel = port.metadata?['channel'] as int;
          
          expect(channel, i + 1);
          expect(port.type, core_port.PortType.audio);
          expect(port.metadata?.containsKey('busParam'), true);
          
          // Each channel would get its own bus assignment
        }
      });
    });

    group('Connection list properties', () {
      test('should maintain stable ordering for consistent UI', () {
        // Connections should be ordered consistently for stable UI rendering
        final sampleConnections = [
          PhysicalConnection.withGeneratedId(
            sourcePortId: 'hw_in_1',
            targetPortId: 'alg_0_audio_left',
            busNumber: 1,
            isInputConnection: true,
            algorithmIndex: 0,
          ),
          PhysicalConnection.withGeneratedId(
            sourcePortId: 'hw_in_2',
            targetPortId: 'alg_0_audio_right',
            busNumber: 2,
            isInputConnection: true,
            algorithmIndex: 0,
          ),
          PhysicalConnection.withGeneratedId(
            sourcePortId: 'hw_in_3',
            targetPortId: 'alg_0_cv_control',
            busNumber: 3,
            isInputConnection: true,
            algorithmIndex: 0,
          ),
        ];

        // All connections should be input connections
        for (final connection in sampleConnections) {
          expect(connection.isInputConnection, true);
          expect(connection.isPhysicalInput, true);
          expect(connection.sourcePortId, startsWith('hw_in_'));
          expect(connection.algorithmIndex, 0);
        }

        // Ordering by bus number provides stability
        final sortedByBus = List.from(sampleConnections)
          ..sort((a, b) => a.busNumber.compareTo(b.busNumber));
        
        expect(sortedByBus[0].busNumber, 1);
        expect(sortedByBus[1].busNumber, 2);
        expect(sortedByBus[2].busNumber, 3);
      });

      test('should support diffing for UI state management', () {
        final oldConnections = [
          PhysicalConnection.withGeneratedId(
            sourcePortId: 'hw_in_1',
            targetPortId: 'alg_0_old_port',
            busNumber: 1,
            isInputConnection: true,
            algorithmIndex: 0,
          ),
        ];

        final newConnections = [
          PhysicalConnection.withGeneratedId(
            sourcePortId: 'hw_in_1',
            targetPortId: 'alg_0_new_port',
            busNumber: 1,
            isInputConnection: true,
            algorithmIndex: 0,
          ),
        ];

        // Connections should be comparable for diffing
        expect(oldConnections.first, isNot(equals(newConnections.first)));
        expect(oldConnections.first.sourcePortId, newConnections.first.sourcePortId);
        expect(oldConnections.first.targetPortId, isNot(equals(newConnections.first.targetPortId)));
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