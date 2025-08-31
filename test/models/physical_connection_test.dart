import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/models/physical_connection.dart';

void main() {
  group('PhysicalConnection', () {
    group('constructor and basic properties', () {
      test('creates instance with required fields', () {
        const connection = PhysicalConnection(
          id: 'phys_hw_in_1->alg_0_audio_input',
          sourcePortId: 'hw_in_1',
          targetPortId: 'alg_0_audio_input',
          busNumber: 1,
          isInputConnection: true,
          algorithmIndex: 0,
        );

        expect(connection.id, 'phys_hw_in_1->alg_0_audio_input');
        expect(connection.sourcePortId, 'hw_in_1');
        expect(connection.targetPortId, 'alg_0_audio_input');
        expect(connection.busNumber, 1);
        expect(connection.isInputConnection, true);
        expect(connection.algorithmIndex, 0);
      });

      test('creates instance for output connection', () {
        const connection = PhysicalConnection(
          id: 'phys_alg_2_audio_output->hw_out_3',
          sourcePortId: 'alg_2_audio_output',
          targetPortId: 'hw_out_3',
          busNumber: 15, // Bus 15 = Hardware output 3
          isInputConnection: false,
          algorithmIndex: 2,
        );

        expect(connection.id, 'phys_alg_2_audio_output->hw_out_3');
        expect(connection.sourcePortId, 'alg_2_audio_output');
        expect(connection.targetPortId, 'hw_out_3');
        expect(connection.busNumber, 15);
        expect(connection.isInputConnection, false);
        expect(connection.algorithmIndex, 2);
      });
    });

    group('withGeneratedId factory constructor', () {
      test('creates connection with auto-generated deterministic ID', () {
        final connection = PhysicalConnection.withGeneratedId(
          sourcePortId: 'hw_in_5',
          targetPortId: 'alg_1_cv_input',
          busNumber: 5,
          isInputConnection: true,
          algorithmIndex: 1,
        );

        expect(connection.id, 'phys_hw_in_5->alg_1_cv_input');
        expect(connection.sourcePortId, 'hw_in_5');
        expect(connection.targetPortId, 'alg_1_cv_input');
        expect(connection.busNumber, 5);
        expect(connection.isInputConnection, true);
        expect(connection.algorithmIndex, 1);
      });

      test('generates consistent IDs for same port combinations', () {
        const sourcePortId = 'hw_in_2';
        const targetPortId = 'alg_0_gate_input';

        final connection1 = PhysicalConnection.withGeneratedId(
          sourcePortId: sourcePortId,
          targetPortId: targetPortId,
          busNumber: 2,
          isInputConnection: true,
          algorithmIndex: 0,
        );

        final connection2 = PhysicalConnection.withGeneratedId(
          sourcePortId: sourcePortId,
          targetPortId: targetPortId,
          busNumber: 2,
          isInputConnection: true,
          algorithmIndex: 0,
        );

        expect(connection1.id, connection2.id);
        expect(connection1.id, 'phys_hw_in_2->alg_0_gate_input');
      });
    });

    group('generateId static method', () {
      test('generates deterministic ID from port IDs', () {
        final id = PhysicalConnection.generateId('hw_in_1', 'alg_0_audio_input');
        expect(id, 'phys_hw_in_1->alg_0_audio_input');
      });

      test('generates different IDs for different port combinations', () {
        final id1 = PhysicalConnection.generateId('hw_in_1', 'alg_0_audio_input');
        final id2 = PhysicalConnection.generateId('hw_in_2', 'alg_0_audio_input');
        final id3 = PhysicalConnection.generateId('hw_in_1', 'alg_1_audio_input');

        expect(id1, 'phys_hw_in_1->alg_0_audio_input');
        expect(id2, 'phys_hw_in_2->alg_0_audio_input');
        expect(id3, 'phys_hw_in_1->alg_1_audio_input');

        // Ensure they're all different
        expect(id1, isNot(equals(id2)));
        expect(id1, isNot(equals(id3)));
        expect(id2, isNot(equals(id3)));
      });

      test('handles output connections', () {
        final id = PhysicalConnection.generateId('alg_1_output', 'hw_out_4');
        expect(id, 'phys_alg_1_output->hw_out_4');
      });
    });

    group('bus type detection', () {
      test('correctly identifies physical input connections (buses 1-12)', () {
        for (int bus = 1; bus <= 12; bus++) {
          final connection = PhysicalConnection(
            id: 'test_$bus',
            sourcePortId: 'hw_in_$bus',
            targetPortId: 'alg_0_input',
            busNumber: bus,
            isInputConnection: true,
            algorithmIndex: 0,
          );

          expect(connection.isPhysicalInput, true, reason: 'Bus $bus should be physical input');
          expect(connection.isPhysicalOutput, false, reason: 'Bus $bus should not be physical output');
        }
      });

      test('correctly identifies physical output connections (buses 13-20)', () {
        for (int bus = 13; bus <= 20; bus++) {
          final connection = PhysicalConnection(
            id: 'test_$bus',
            sourcePortId: 'alg_0_output',
            targetPortId: 'hw_out_${bus - 12}',
            busNumber: bus,
            isInputConnection: false,
            algorithmIndex: 0,
          );

          expect(connection.isPhysicalInput, false, reason: 'Bus $bus should not be physical input');
          expect(connection.isPhysicalOutput, true, reason: 'Bus $bus should be physical output');
        }
      });

      test('handles edge cases for bus detection', () {
        // Bus 0 (None) - should not be physical I/O
        final connection0 = PhysicalConnection(
          id: 'test_0',
          sourcePortId: 'test',
          targetPortId: 'test',
          busNumber: 0,
          isInputConnection: true,
          algorithmIndex: 0,
        );
        expect(connection0.isPhysicalInput, false);
        expect(connection0.isPhysicalOutput, false);

        // Bus 21+ (AUX) - should not be physical I/O
        final connection21 = PhysicalConnection(
          id: 'test_21',
          sourcePortId: 'test',
          targetPortId: 'test',
          busNumber: 21,
          isInputConnection: false,
          algorithmIndex: 0,
        );
        expect(connection21.isPhysicalInput, false);
        expect(connection21.isPhysicalOutput, false);
      });
    });

    group('hardware port number calculation', () {
      test('correctly maps input buses to hardware port numbers (1-12)', () {
        for (int bus = 1; bus <= 12; bus++) {
          final connection = PhysicalConnection(
            id: 'test_$bus',
            sourcePortId: 'hw_in_$bus',
            targetPortId: 'alg_0_input',
            busNumber: bus,
            isInputConnection: true,
            algorithmIndex: 0,
          );

          expect(connection.hardwarePortNumber, bus, 
              reason: 'Bus $bus should map to hardware input $bus');
        }
      });

      test('correctly maps output buses to hardware port numbers (13-20 -> 1-8)', () {
        for (int bus = 13; bus <= 20; bus++) {
          final expectedHardwarePort = bus - 12; // 13->1, 14->2, ..., 20->8
          final connection = PhysicalConnection(
            id: 'test_$bus',
            sourcePortId: 'alg_0_output',
            targetPortId: 'hw_out_$expectedHardwarePort',
            busNumber: bus,
            isInputConnection: false,
            algorithmIndex: 0,
          );

          expect(connection.hardwarePortNumber, expectedHardwarePort,
              reason: 'Bus $bus should map to hardware output $expectedHardwarePort');
        }
      });

      test('throws ArgumentError for invalid bus numbers', () {
        final invalidBuses = [0, 21, 22, 25, 28, 50, -1];
        
        for (final bus in invalidBuses) {
          final connection = PhysicalConnection(
            id: 'test_$bus',
            sourcePortId: 'test',
            targetPortId: 'test',
            busNumber: bus,
            isInputConnection: true,
            algorithmIndex: 0,
          );

          expect(
            () => connection.hardwarePortNumber,
            throwsA(isA<ArgumentError>()),
            reason: 'Bus $bus should throw ArgumentError',
          );
        }
      });
    });

    group('description generation', () {
      test('generates correct description for input connections', () {
        final connection = PhysicalConnection(
          id: 'test',
          sourcePortId: 'hw_in_3',
          targetPortId: 'alg_1_cv_input',
          busNumber: 3,
          isInputConnection: true,
          algorithmIndex: 1,
        );

        expect(connection.description, 'Hardware Input 3 → Algorithm 1');
      });

      test('generates correct description for output connections', () {
        final connection = PhysicalConnection(
          id: 'test',
          sourcePortId: 'alg_2_audio_output',
          targetPortId: 'hw_out_5',
          busNumber: 17, // Bus 17 = Hardware output 5
          isInputConnection: false,
          algorithmIndex: 2,
        );

        expect(connection.description, 'Algorithm 2 → Hardware Output 5');
      });
    });

    group('JSON serialization', () {
      test('serializes to JSON correctly', () {
        const connection = PhysicalConnection(
          id: 'phys_hw_in_1->alg_0_audio_input',
          sourcePortId: 'hw_in_1',
          targetPortId: 'alg_0_audio_input',
          busNumber: 1,
          isInputConnection: true,
          algorithmIndex: 0,
        );

        final json = connection.toJson();

        expect(json['id'], 'phys_hw_in_1->alg_0_audio_input');
        expect(json['sourcePortId'], 'hw_in_1');
        expect(json['targetPortId'], 'alg_0_audio_input');
        expect(json['busNumber'], 1);
        expect(json['isInputConnection'], true);
        expect(json['algorithmIndex'], 0);
      });

      test('deserializes from JSON correctly', () {
        final json = {
          'id': 'phys_alg_1_output->hw_out_2',
          'sourcePortId': 'alg_1_output',
          'targetPortId': 'hw_out_2',
          'busNumber': 14,
          'isInputConnection': false,
          'algorithmIndex': 1,
        };

        final connection = PhysicalConnection.fromJson(json);

        expect(connection.id, 'phys_alg_1_output->hw_out_2');
        expect(connection.sourcePortId, 'alg_1_output');
        expect(connection.targetPortId, 'hw_out_2');
        expect(connection.busNumber, 14);
        expect(connection.isInputConnection, false);
        expect(connection.algorithmIndex, 1);
      });

      test('round-trip serialization preserves data', () {
        const original = PhysicalConnection(
          id: 'phys_hw_in_6->alg_3_gate_input',
          sourcePortId: 'hw_in_6',
          targetPortId: 'alg_3_gate_input',
          busNumber: 6,
          isInputConnection: true,
          algorithmIndex: 3,
        );

        final json = original.toJson();
        final deserialized = PhysicalConnection.fromJson(json);

        expect(deserialized, equals(original));
      });
    });

    group('equality and hashCode', () {
      test('equal objects have same hashCode', () {
        const connection1 = PhysicalConnection(
          id: 'test',
          sourcePortId: 'source',
          targetPortId: 'target',
          busNumber: 1,
          isInputConnection: true,
          algorithmIndex: 0,
        );

        const connection2 = PhysicalConnection(
          id: 'test',
          sourcePortId: 'source',
          targetPortId: 'target',
          busNumber: 1,
          isInputConnection: true,
          algorithmIndex: 0,
        );

        expect(connection1, equals(connection2));
        expect(connection1.hashCode, equals(connection2.hashCode));
      });

      test('different objects are not equal', () {
        const connection1 = PhysicalConnection(
          id: 'test1',
          sourcePortId: 'source',
          targetPortId: 'target',
          busNumber: 1,
          isInputConnection: true,
          algorithmIndex: 0,
        );

        const connection2 = PhysicalConnection(
          id: 'test2',
          sourcePortId: 'source',
          targetPortId: 'target',
          busNumber: 1,
          isInputConnection: true,
          algorithmIndex: 0,
        );

        expect(connection1, isNot(equals(connection2)));
      });

      test('supports stable diffing for connection lists', () {
        const connections1 = [
          PhysicalConnection(
            id: 'phys_hw_in_1->alg_0_input',
            sourcePortId: 'hw_in_1',
            targetPortId: 'alg_0_input',
            busNumber: 1,
            isInputConnection: true,
            algorithmIndex: 0,
          ),
          PhysicalConnection(
            id: 'phys_alg_0_output->hw_out_1',
            sourcePortId: 'alg_0_output',
            targetPortId: 'hw_out_1',
            busNumber: 13,
            isInputConnection: false,
            algorithmIndex: 0,
          ),
        ];

        const connections2 = [
          PhysicalConnection(
            id: 'phys_hw_in_1->alg_0_input',
            sourcePortId: 'hw_in_1',
            targetPortId: 'alg_0_input',
            busNumber: 1,
            isInputConnection: true,
            algorithmIndex: 0,
          ),
          PhysicalConnection(
            id: 'phys_alg_0_output->hw_out_1',
            sourcePortId: 'alg_0_output',
            targetPortId: 'hw_out_1',
            busNumber: 13,
            isInputConnection: false,
            algorithmIndex: 0,
          ),
        ];

        // Lists with same content should be considered equal for diffing
        expect(connections1, equals(connections2));
      });
    });
  });
}