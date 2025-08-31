import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/models/algorithm_connection.dart';

void main() {
  group('AlgorithmConnection', () {
    group('constructor and basic properties', () {
      test('creates instance with required fields', () {
        const connection = AlgorithmConnection(
          id: 'alg_0_main_output->alg_1_audio_input_bus_5',
          sourceAlgorithmIndex: 0,
          sourcePortId: 'main_output',
          targetAlgorithmIndex: 1,
          targetPortId: 'audio_input',
          busNumber: 5,
          connectionType: AlgorithmConnectionType.audioSignal,
        );

        expect(connection.id, 'alg_0_main_output->alg_1_audio_input_bus_5');
        expect(connection.sourceAlgorithmIndex, 0);
        expect(connection.sourcePortId, 'main_output');
        expect(connection.targetAlgorithmIndex, 1);
        expect(connection.targetPortId, 'audio_input');
        expect(connection.busNumber, 5);
        expect(connection.connectionType, AlgorithmConnectionType.audioSignal);
        expect(connection.isValid, true); // Default value
        expect(connection.validationMessage, null);
        expect(connection.edgeLabel, null);
      });

      test('creates instance with optional fields', () {
        const connection = AlgorithmConnection(
          id: 'test_connection',
          sourceAlgorithmIndex: 2,
          sourcePortId: 'cv_output',
          targetAlgorithmIndex: 3,
          targetPortId: 'cv_input',
          busNumber: 10,
          connectionType: AlgorithmConnectionType.controlVoltage,
          isValid: false,
          validationMessage: 'Test validation error',
          edgeLabel: 'CV 10',
        );

        expect(connection.isValid, false);
        expect(connection.validationMessage, 'Test validation error');
        expect(connection.edgeLabel, 'CV 10');
      });
    });

    group('withGeneratedId factory constructor', () {
      test('creates connection with auto-generated deterministic ID', () {
        final connection = AlgorithmConnection.withGeneratedId(
          sourceAlgorithmIndex: 0,
          sourcePortId: 'gate_output',
          targetAlgorithmIndex: 2,
          targetPortId: 'trigger_input',
          busNumber: 8,
          connectionType: AlgorithmConnectionType.gateTrigger,
        );

        expect(connection.id, 'alg_0_gate_output->alg_2_trigger_input_bus_8');
        expect(connection.sourceAlgorithmIndex, 0);
        expect(connection.sourcePortId, 'gate_output');
        expect(connection.targetAlgorithmIndex, 2);
        expect(connection.targetPortId, 'trigger_input');
        expect(connection.busNumber, 8);
        expect(connection.connectionType, AlgorithmConnectionType.gateTrigger);
        expect(connection.isValid, true); // Default
      });

      test('generates consistent IDs for same parameters', () {
        final connection1 = AlgorithmConnection.withGeneratedId(
          sourceAlgorithmIndex: 1,
          sourcePortId: 'clock_out',
          targetAlgorithmIndex: 4,
          targetPortId: 'clock_in',
          busNumber: 12,
          connectionType: AlgorithmConnectionType.clockTiming,
        );

        final connection2 = AlgorithmConnection.withGeneratedId(
          sourceAlgorithmIndex: 1,
          sourcePortId: 'clock_out',
          targetAlgorithmIndex: 4,
          targetPortId: 'clock_in',
          busNumber: 12,
          connectionType: AlgorithmConnectionType.clockTiming,
        );

        expect(connection1.id, connection2.id);
        expect(connection1.id, 'alg_1_clock_out->alg_4_clock_in_bus_12');
      });

      test('generates different IDs for different parameters', () {
        final connection1 = AlgorithmConnection.withGeneratedId(
          sourceAlgorithmIndex: 0,
          sourcePortId: 'output_1',
          targetAlgorithmIndex: 1,
          targetPortId: 'input_1',
          busNumber: 5,
          connectionType: AlgorithmConnectionType.audioSignal,
        );

        final connection2 = AlgorithmConnection.withGeneratedId(
          sourceAlgorithmIndex: 0,
          sourcePortId: 'output_2',
          targetAlgorithmIndex: 1,
          targetPortId: 'input_1',
          busNumber: 5,
          connectionType: AlgorithmConnectionType.audioSignal,
        );

        final connection3 = AlgorithmConnection.withGeneratedId(
          sourceAlgorithmIndex: 0,
          sourcePortId: 'output_1',
          targetAlgorithmIndex: 2,
          targetPortId: 'input_1',
          busNumber: 5,
          connectionType: AlgorithmConnectionType.audioSignal,
        );

        expect(connection1.id, 'alg_0_output_1->alg_1_input_1_bus_5');
        expect(connection2.id, 'alg_0_output_2->alg_1_input_1_bus_5');
        expect(connection3.id, 'alg_0_output_1->alg_2_input_1_bus_5');

        // Ensure they're all different
        expect(connection1.id, isNot(equals(connection2.id)));
        expect(connection1.id, isNot(equals(connection3.id)));
        expect(connection2.id, isNot(equals(connection3.id)));
      });

      test('accepts optional parameters', () {
        final connection = AlgorithmConnection.withGeneratedId(
          sourceAlgorithmIndex: 3,
          sourcePortId: 'audio_out',
          targetAlgorithmIndex: 5,
          targetPortId: 'audio_in',
          busNumber: 22,
          connectionType: AlgorithmConnectionType.audioSignal,
          isValid: false,
          validationMessage: 'Custom validation message',
          edgeLabel: 'A2',
        );

        expect(connection.isValid, false);
        expect(connection.validationMessage, 'Custom validation message');
        expect(connection.edgeLabel, 'A2');
      });
    });

    group('connection type display names', () {
      test('returns correct display names for all connection types', () {
        const testCases = [
          (AlgorithmConnectionType.audioSignal, 'Audio'),
          (AlgorithmConnectionType.controlVoltage, 'CV'),
          (AlgorithmConnectionType.gateTrigger, 'Gate'),
          (AlgorithmConnectionType.clockTiming, 'Clock'),
          (AlgorithmConnectionType.mixed, 'Mixed'),
        ];

        for (final (type, expectedName) in testCases) {
          final connection = AlgorithmConnection(
            id: 'test',
            sourceAlgorithmIndex: 0,
            sourcePortId: 'out',
            targetAlgorithmIndex: 1,
            targetPortId: 'in',
            busNumber: 5,
            connectionType: type,
          );

          expect(connection.connectionTypeDisplayName, expectedName,
              reason: 'Type $type should display as "$expectedName"');
        }
      });
    });

    group('bus type detection and labeling', () {
      test('correctly identifies input buses (1-12)', () {
        for (int bus = 1; bus <= 12; bus++) {
          final connection = AlgorithmConnection(
            id: 'test_$bus',
            sourceAlgorithmIndex: 0,
            sourcePortId: 'cv_out',
            targetAlgorithmIndex: 1,
            targetPortId: 'cv_in',
            busNumber: bus,
            connectionType: AlgorithmConnectionType.controlVoltage,
          );

          expect(connection.usesInputBus, true, reason: 'Bus $bus should be input bus');
          expect(connection.usesOutputBus, false, reason: 'Bus $bus should not be output bus');
          expect(connection.usesAudioBus, false, reason: 'Bus $bus should not be audio bus');
          expect(connection.busLabel, 'I$bus', reason: 'Bus $bus should have label "I$bus"');
        }
      });

      test('correctly identifies output buses (13-20)', () {
        for (int bus = 13; bus <= 20; bus++) {
          final expectedLabel = 'O${bus - 12}';
          final connection = AlgorithmConnection(
            id: 'test_$bus',
            sourceAlgorithmIndex: 0,
            sourcePortId: 'audio_out',
            targetAlgorithmIndex: 1,
            targetPortId: 'audio_in',
            busNumber: bus,
            connectionType: AlgorithmConnectionType.audioSignal,
          );

          expect(connection.usesInputBus, false, reason: 'Bus $bus should not be input bus');
          expect(connection.usesOutputBus, true, reason: 'Bus $bus should be output bus');
          expect(connection.usesAudioBus, false, reason: 'Bus $bus should not be audio bus');
          expect(connection.busLabel, expectedLabel, reason: 'Bus $bus should have label "$expectedLabel"');
        }
      });

      test('correctly identifies audio buses (21-28)', () {
        for (int bus = 21; bus <= 28; bus++) {
          final expectedLabel = 'A${bus - 20}';
          final connection = AlgorithmConnection(
            id: 'test_$bus',
            sourceAlgorithmIndex: 0,
            sourcePortId: 'audio_out',
            targetAlgorithmIndex: 1,
            targetPortId: 'audio_in',
            busNumber: bus,
            connectionType: AlgorithmConnectionType.audioSignal,
          );

          expect(connection.usesInputBus, false, reason: 'Bus $bus should not be input bus');
          expect(connection.usesOutputBus, false, reason: 'Bus $bus should not be output bus');
          expect(connection.usesAudioBus, true, reason: 'Bus $bus should be audio bus');
          expect(connection.busLabel, expectedLabel, reason: 'Bus $bus should have label "$expectedLabel"');
        }
      });

      test('handles edge cases for bus labeling', () {
        // Invalid bus numbers should still produce fallback labels
        final testCases = [0, 29, 50];
        
        for (final bus in testCases) {
          final connection = AlgorithmConnection(
            id: 'test_$bus',
            sourceAlgorithmIndex: 0,
            sourcePortId: 'out',
            targetAlgorithmIndex: 1,
            targetPortId: 'in',
            busNumber: bus,
            connectionType: AlgorithmConnectionType.mixed,
          );

          expect(connection.busLabel, 'Bus $bus');
          expect(connection.usesInputBus, false);
          expect(connection.usesOutputBus, false);
          expect(connection.usesAudioBus, false);
        }
      });
    });

    group('edge label generation', () {
      test('returns custom edge label when provided', () {
        const connection = AlgorithmConnection(
          id: 'test',
          sourceAlgorithmIndex: 0,
          sourcePortId: 'out',
          targetAlgorithmIndex: 1,
          targetPortId: 'in',
          busNumber: 5,
          connectionType: AlgorithmConnectionType.controlVoltage,
          edgeLabel: 'Custom Label',
        );

        expect(connection.getEdgeLabel(), 'Custom Label');
      });

      test('returns bus label when no custom edge label provided', () {
        const connection = AlgorithmConnection(
          id: 'test',
          sourceAlgorithmIndex: 0,
          sourcePortId: 'out',
          targetAlgorithmIndex: 1,
          targetPortId: 'in',
          busNumber: 7,
          connectionType: AlgorithmConnectionType.controlVoltage,
        );

        expect(connection.getEdgeLabel(), 'I7');
      });
    });

    group('execution order validation', () {
      test('detects execution order violations', () {
        // Bus-mediated connections are valid in both directions
        // Only self-connections are invalid
        const forwardConnection = AlgorithmConnection(
          id: 'forward',
          sourceAlgorithmIndex: 0,
          sourcePortId: 'out',
          targetAlgorithmIndex: 2,
          targetPortId: 'in',
          busNumber: 5,
          connectionType: AlgorithmConnectionType.audioSignal,
        );

        const selfConnection = AlgorithmConnection(
          id: 'self',
          sourceAlgorithmIndex: 1,
          sourcePortId: 'out',
          targetAlgorithmIndex: 1,
          targetPortId: 'in',
          busNumber: 5,
          connectionType: AlgorithmConnectionType.audioSignal,
        );

        const reverseOrderConnection = AlgorithmConnection(
          id: 'reverse',
          sourceAlgorithmIndex: 3,
          sourcePortId: 'out',
          targetAlgorithmIndex: 1,
          targetPortId: 'in',
          busNumber: 5,
          connectionType: AlgorithmConnectionType.audioSignal,
        );

        expect(forwardConnection.violatesExecutionOrder, false);
        expect(selfConnection.violatesExecutionOrder, true);
        expect(reverseOrderConnection.violatesExecutionOrder, false); // Bus connections valid both ways
      });
      
      test('identifies forward and backward edges correctly', () {
        const forwardConnection = AlgorithmConnection(
          id: 'forward',
          sourceAlgorithmIndex: 1,
          sourcePortId: 'out',
          targetAlgorithmIndex: 3,
          targetPortId: 'in',
          busNumber: 5,
          connectionType: AlgorithmConnectionType.audioSignal,
        );

        const backwardConnection = AlgorithmConnection(
          id: 'backward',
          sourceAlgorithmIndex: 5,
          sourcePortId: 'out',
          targetAlgorithmIndex: 2,
          targetPortId: 'in',
          busNumber: 10,
          connectionType: AlgorithmConnectionType.controlVoltage,
        );

        const sameSlotConnection = AlgorithmConnection(
          id: 'same_slot',
          sourceAlgorithmIndex: 4,
          sourcePortId: 'out',
          targetAlgorithmIndex: 4,
          targetPortId: 'in',
          busNumber: 15,
          connectionType: AlgorithmConnectionType.gateTrigger,
        );

        // Forward edge: source < target
        expect(forwardConnection.isForwardEdge, true);
        expect(forwardConnection.isBackwardEdge, false);

        // Backward edge: source > target
        expect(backwardConnection.isForwardEdge, false);
        expect(backwardConnection.isBackwardEdge, true);

        // Same slot: source == target (backward edge)
        expect(sameSlotConnection.isForwardEdge, false);
        expect(sameSlotConnection.isBackwardEdge, true);
      });
      
      test('correctly identifies physical output connections', () {
        const physicalOutputConnection = AlgorithmConnection(
          id: 'physical_out',
          sourceAlgorithmIndex: 2,
          sourcePortId: 'output',
          targetAlgorithmIndex: -3, // Physical output
          targetPortId: 'physical_output_15',
          busNumber: 15,
          connectionType: AlgorithmConnectionType.audioSignal,
        );

        // Physical output connections
        expect(physicalOutputConnection.isPhysicalOutput, true);
        expect(physicalOutputConnection.isForwardEdge, false); // Physical outputs don't use forward edge logic
        expect(physicalOutputConnection.isBackwardEdge, false); // Physical outputs are always "forward"
      });
    });

    group('description generation', () {
      test('generates human-readable descriptions', () {
        const connection = AlgorithmConnection(
          id: 'test',
          sourceAlgorithmIndex: 2,
          sourcePortId: 'main_output',
          targetAlgorithmIndex: 5,
          targetPortId: 'audio_input',
          busNumber: 15,
          connectionType: AlgorithmConnectionType.audioSignal,
        );

        expect(connection.description, 'Algorithm 2:main_output → Algorithm 5:audio_input');
      });
    });

    group('validation', () {
      test('validates correct connections', () {
        const connection = AlgorithmConnection(
          id: 'valid',
          sourceAlgorithmIndex: 0,
          sourcePortId: 'output',
          targetAlgorithmIndex: 3,
          targetPortId: 'input',
          busNumber: 10,
          connectionType: AlgorithmConnectionType.controlVoltage,
        );

        final validation = connection.validate();

        expect(validation.isValid, true);
        expect(validation.errors, isEmpty);
        expect(validation.warnings, isEmpty);
      });

      test('detects self-connection errors', () {
        const connection = AlgorithmConnection(
          id: 'self_connection',
          sourceAlgorithmIndex: 2,
          sourcePortId: 'output',
          targetAlgorithmIndex: 2,
          targetPortId: 'input',
          busNumber: 10,
          connectionType: AlgorithmConnectionType.audioSignal,
        );

        final validation = connection.validate();

        expect(validation.isValid, false);
        expect(validation.errors, hasLength(1));
        expect(validation.errors.first, contains('Algorithm cannot connect to itself'));
      });

      test('detects invalid bus numbers', () {
        const connection = AlgorithmConnection(
          id: 'invalid_bus',
          sourceAlgorithmIndex: 0,
          sourcePortId: 'output',
          targetAlgorithmIndex: 1,
          targetPortId: 'input',
          busNumber: 30, // Invalid bus number
          connectionType: AlgorithmConnectionType.audioSignal,
        );

        final validation = connection.validate();

        expect(validation.isValid, false);
        expect(validation.errors, hasLength(1));
        expect(validation.errors.first, contains('Bus number 30 is outside valid range (1-28)'));
      });

      test('detects invalid algorithm indices', () {
        const connection = AlgorithmConnection(
          id: 'invalid_algorithms',
          sourceAlgorithmIndex: 8, // Invalid: > 7
          sourcePortId: 'output',
          targetAlgorithmIndex: -1, // Invalid: < 0
          targetPortId: 'input',
          busNumber: 5,
          connectionType: AlgorithmConnectionType.audioSignal,
        );

        final validation = connection.validate();

        expect(validation.isValid, false);
        expect(validation.errors, hasLength(2)); // 2 invalid indices only
        expect(validation.errors, contains(contains('Source algorithm index 8 is outside valid range (0-7)')));
        expect(validation.errors, contains(contains('Target algorithm index -1 is outside valid range (0-7)')));
      });

      test('generates warnings for self-connections', () {
        const connection = AlgorithmConnection(
          id: 'self_connection',
          sourceAlgorithmIndex: 2,
          sourcePortId: 'output',
          targetAlgorithmIndex: 2,
          targetPortId: 'input',
          busNumber: 5,
          connectionType: AlgorithmConnectionType.audioSignal,
        );

        final validation = connection.validate();

        expect(validation.isValid, false); // Execution order violation
        expect(validation.warnings, hasLength(1));
        expect(validation.warnings.first, contains('Algorithm is connecting to itself'));
      });

      test('validation summary messages work correctly', () {
        // Valid connection
        const validConnection = AlgorithmConnection(
          id: 'valid',
          sourceAlgorithmIndex: 0,
          sourcePortId: 'output',
          targetAlgorithmIndex: 1,
          targetPortId: 'input',
          busNumber: 5,
          connectionType: AlgorithmConnectionType.audioSignal,
        );

        expect(validConnection.validate().summaryMessage, 'Connection is valid');

        // Connection with errors
        const errorConnection = AlgorithmConnection(
          id: 'error',
          sourceAlgorithmIndex: 2,
          sourcePortId: 'output',
          targetAlgorithmIndex: 1,
          targetPortId: 'input',
          busNumber: 0, // Invalid bus number
          connectionType: AlgorithmConnectionType.audioSignal,
        );

        final errorValidation = errorConnection.validate();
        expect(errorValidation.summaryMessage, errorValidation.errors.first);

        // Connection with only warnings
        const warningConnection = AlgorithmConnection(
          id: 'warning',
          sourceAlgorithmIndex: 2,
          sourcePortId: 'output_a',
          targetAlgorithmIndex: 2,
          targetPortId: 'input_b',
          busNumber: 0, // Invalid bus, but algorithm self-connection error should show
          connectionType: AlgorithmConnectionType.mixed,
        );

        final warningValidation = warningConnection.validate();
        // This will have errors (self-connection + bus number) so errors take precedence
        expect(warningValidation.summaryMessage, warningValidation.errors.first);
      });
    });

    group('JSON serialization', () {
      test('serializes to JSON correctly', () {
        const connection = AlgorithmConnection(
          id: 'test_serialization',
          sourceAlgorithmIndex: 1,
          sourcePortId: 'audio_output',
          targetAlgorithmIndex: 3,
          targetPortId: 'audio_input',
          busNumber: 22,
          connectionType: AlgorithmConnectionType.audioSignal,
          isValid: false,
          validationMessage: 'Test error',
          edgeLabel: 'A2',
        );

        final json = connection.toJson();

        expect(json['id'], 'test_serialization');
        expect(json['sourceAlgorithmIndex'], 1);
        expect(json['sourcePortId'], 'audio_output');
        expect(json['targetAlgorithmIndex'], 3);
        expect(json['targetPortId'], 'audio_input');
        expect(json['busNumber'], 22);
        expect(json['connectionType'], 'audioSignal');
        expect(json['isValid'], false);
        expect(json['validationMessage'], 'Test error');
        expect(json['edgeLabel'], 'A2');
      });

      test('deserializes from JSON correctly', () {
        final json = {
          'id': 'test_deserialization',
          'sourceAlgorithmIndex': 2,
          'sourcePortId': 'cv_output',
          'targetAlgorithmIndex': 4,
          'targetPortId': 'cv_input',
          'busNumber': 8,
          'connectionType': 'controlVoltage',
          'isValid': true,
          'validationMessage': null,
          'edgeLabel': 'I8',
        };

        final connection = AlgorithmConnection.fromJson(json);

        expect(connection.id, 'test_deserialization');
        expect(connection.sourceAlgorithmIndex, 2);
        expect(connection.sourcePortId, 'cv_output');
        expect(connection.targetAlgorithmIndex, 4);
        expect(connection.targetPortId, 'cv_input');
        expect(connection.busNumber, 8);
        expect(connection.connectionType, AlgorithmConnectionType.controlVoltage);
        expect(connection.isValid, true);
        expect(connection.validationMessage, null);
        expect(connection.edgeLabel, 'I8');
      });

      test('round-trip serialization preserves data', () {
        const original = AlgorithmConnection(
          id: 'round_trip_test',
          sourceAlgorithmIndex: 0,
          sourcePortId: 'gate_out',
          targetAlgorithmIndex: 7,
          targetPortId: 'trigger_in',
          busNumber: 12,
          connectionType: AlgorithmConnectionType.gateTrigger,
          isValid: true,
          validationMessage: null,
          edgeLabel: null,
        );

        final json = original.toJson();
        final deserialized = AlgorithmConnection.fromJson(json);

        expect(deserialized, equals(original));
      });

      test('handles missing optional fields in JSON', () {
        final json = {
          'id': 'minimal_json',
          'sourceAlgorithmIndex': 0,
          'sourcePortId': 'out',
          'targetAlgorithmIndex': 1,
          'targetPortId': 'in',
          'busNumber': 5,
          'connectionType': 'mixed',
          // isValid, validationMessage, edgeLabel omitted
        };

        final connection = AlgorithmConnection.fromJson(json);

        expect(connection.id, 'minimal_json');
        expect(connection.isValid, true); // Default value
        expect(connection.validationMessage, null);
        expect(connection.edgeLabel, null);
      });
    });

    group('equality and hashCode', () {
      test('equal objects have same hashCode', () {
        const connection1 = AlgorithmConnection(
          id: 'test',
          sourceAlgorithmIndex: 0,
          sourcePortId: 'output',
          targetAlgorithmIndex: 1,
          targetPortId: 'input',
          busNumber: 5,
          connectionType: AlgorithmConnectionType.audioSignal,
        );

        const connection2 = AlgorithmConnection(
          id: 'test',
          sourceAlgorithmIndex: 0,
          sourcePortId: 'output',
          targetAlgorithmIndex: 1,
          targetPortId: 'input',
          busNumber: 5,
          connectionType: AlgorithmConnectionType.audioSignal,
        );

        expect(connection1, equals(connection2));
        expect(connection1.hashCode, equals(connection2.hashCode));
      });

      test('different objects are not equal', () {
        const connection1 = AlgorithmConnection(
          id: 'test1',
          sourceAlgorithmIndex: 0,
          sourcePortId: 'output',
          targetAlgorithmIndex: 1,
          targetPortId: 'input',
          busNumber: 5,
          connectionType: AlgorithmConnectionType.audioSignal,
        );

        const connection2 = AlgorithmConnection(
          id: 'test2',
          sourceAlgorithmIndex: 0,
          sourcePortId: 'output',
          targetAlgorithmIndex: 1,
          targetPortId: 'input',
          busNumber: 5,
          connectionType: AlgorithmConnectionType.audioSignal,
        );

        expect(connection1, isNot(equals(connection2)));
      });

      test('supports stable diffing for connection lists', () {
        const connections1 = [
          AlgorithmConnection(
            id: 'alg_0_out->alg_1_in_bus_5',
            sourceAlgorithmIndex: 0,
            sourcePortId: 'audio_output',
            targetAlgorithmIndex: 1,
            targetPortId: 'audio_input',
            busNumber: 5,
            connectionType: AlgorithmConnectionType.audioSignal,
          ),
          AlgorithmConnection(
            id: 'alg_1_cv->alg_2_mod_bus_3',
            sourceAlgorithmIndex: 1,
            sourcePortId: 'cv_output',
            targetAlgorithmIndex: 2,
            targetPortId: 'modulation_input',
            busNumber: 3,
            connectionType: AlgorithmConnectionType.controlVoltage,
          ),
        ];

        const connections2 = [
          AlgorithmConnection(
            id: 'alg_0_out->alg_1_in_bus_5',
            sourceAlgorithmIndex: 0,
            sourcePortId: 'audio_output',
            targetAlgorithmIndex: 1,
            targetPortId: 'audio_input',
            busNumber: 5,
            connectionType: AlgorithmConnectionType.audioSignal,
          ),
          AlgorithmConnection(
            id: 'alg_1_cv->alg_2_mod_bus_3',
            sourceAlgorithmIndex: 1,
            sourcePortId: 'cv_output',
            targetAlgorithmIndex: 2,
            targetPortId: 'modulation_input',
            busNumber: 3,
            connectionType: AlgorithmConnectionType.controlVoltage,
          ),
        ];

        // Lists with same content should be considered equal for diffing
        expect(connections1, equals(connections2));
      });
    });
  });

  group('AlgorithmConnectionType', () {
    test('has expected enum values', () {
      const expectedTypes = [
        AlgorithmConnectionType.audioSignal,
        AlgorithmConnectionType.controlVoltage,
        AlgorithmConnectionType.gateTrigger,
        AlgorithmConnectionType.clockTiming,
        AlgorithmConnectionType.mixed,
      ];

      expect(AlgorithmConnectionType.values, containsAll(expectedTypes));
      expect(AlgorithmConnectionType.values, hasLength(5));
    });
  });

  group('AlgorithmConnectionValidation', () {
    test('creates validation result with all fields', () {
      const validation = AlgorithmConnectionValidation(
        isValid: false,
        errors: ['Error 1', 'Error 2'],
        warnings: ['Warning 1'],
      );

      expect(validation.isValid, false);
      expect(validation.errors, ['Error 1', 'Error 2']);
      expect(validation.warnings, ['Warning 1']);
      expect(validation.allMessages, ['Error 1', 'Error 2', 'Warning 1']);
    });

    test('summary message prioritizes errors over warnings', () {
      const validationWithErrors = AlgorithmConnectionValidation(
        isValid: false,
        errors: ['First error', 'Second error'],
        warnings: ['Warning message'],
      );

      expect(validationWithErrors.summaryMessage, 'First error');
    });

    test('summary message shows warnings when no errors', () {
      const validationWithWarnings = AlgorithmConnectionValidation(
        isValid: true,
        errors: [],
        warnings: ['Warning message', 'Another warning'],
      );

      expect(validationWithWarnings.summaryMessage, 'Warning message');
    });

    test('summary message for valid connection', () {
      const validValidation = AlgorithmConnectionValidation(
        isValid: true,
        errors: [],
        warnings: [],
      );

      expect(validValidation.summaryMessage, 'Connection is valid');
    });
  });
}