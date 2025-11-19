import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/core/routing/port_compatibility_validator.dart';
import 'package:nt_helper/core/routing/models/port.dart';
import 'package:nt_helper/core/routing/models/connection.dart';

void main() {
  group('PortCompatibilityValidator Tests', () {
    late PortCompatibilityValidator validator;
    late Port audioInputPort;
    late Port audioOutputPort;
    late Port cvInputPort;
    late Port cvOutputPort;
    late Port midiInputPort;
    // late Port midiOutputPort;
    late Port inactivePort;

    setUp(() {
      validator = PortCompatibilityValidator();

      audioInputPort = const Port(
        id: 'audio_in',
        name: 'Audio Input',
        type: PortType.audio,
        direction: PortDirection.input,
      );

      audioOutputPort = const Port(
        id: 'audio_out',
        name: 'Output',
        type: PortType.audio,
        direction: PortDirection.output,
      );

      cvInputPort = const Port(
        id: 'cv_in',
        name: 'CV Input',
        type: PortType.cv,
        direction: PortDirection.input,
      );

      cvOutputPort = const Port(
        id: 'cv_out',
        name: 'CV Output',
        type: PortType.cv,
        direction: PortDirection.output,
      );

      midiInputPort = const Port(
        id: 'midi_in',
        name: 'MIDI Input',
        type: PortType.cv,
        direction: PortDirection.input,
      );

      // midiOutputPort = const Port(
      //   id: 'midi_out',
      //   name: 'MIDI Output',
      //   type: ,
      //   direction: PortDirection.output,
      // );

      inactivePort = const Port(
        id: 'inactive',
        name: 'Inactive Port',
        type: PortType.audio,
        direction: PortDirection.input,
        isActive: false,
      );
    });

    group('Basic Validation Tests', () {
      test('should validate compatible audio connection', () {
        final result = validator.validateConnection(
          audioOutputPort,
          audioInputPort,
        );

        expect(result.isValid, isTrue);
        expect(result.errors, isEmpty);
      });

      test(
        'should validate cross-compatible audio to CV connection with warning',
        () {
          final result = validator.validateConnection(
            audioOutputPort,
            cvInputPort,
          );

          expect(result.isValid, isTrue);
          expect(result.errors, isEmpty);
          expect(result.warnings.length, equals(1));
          expect(result.warnings[0].message, contains('Cross-type connection'));
        },
      );

      test('should accept all type connections (Eurorack voltage)', () {
        final result = validator.validateConnection(
          audioOutputPort,
          midiInputPort,
        );

        // All types are now compatible since everything is voltage in Eurorack
        expect(result.isValid, isTrue);
        expect(result.errors, isEmpty);
        // Should have a warning about cross-type connection
        expect(result.warnings.length, equals(1));
        expect(result.warnings[0].message, contains('Cross-type connection'));
      });

      test('should reject connection from input to input', () {
        final result = validator.validateConnection(
          audioInputPort,
          cvInputPort,
        );

        expect(result.isValid, isFalse);
        expect(result.errors.length, equals(1));
        expect(
          result.errors[0].type,
          equals(ValidationErrorType.incompatibleDirection),
        );
        expect(
          result.errors[0].message,
          contains('Cannot connect input port to input port'),
        );
      });

      test('should reject connection from output to output', () {
        final result = validator.validateConnection(
          audioOutputPort,
          cvOutputPort,
        );

        expect(result.isValid, isFalse);
        expect(result.errors.length, equals(1));
        expect(
          result.errors[0].type,
          equals(ValidationErrorType.incompatibleDirection),
        );
        expect(
          result.errors[0].message,
          contains('Cannot connect output port to output port'),
        );
      });
    });

    group('Port Activity Validation Tests', () {
      test('should reject connection with inactive source port', () {
        final result = validator.validateConnection(
          inactivePort,
          audioInputPort,
        );

        expect(result.isValid, isFalse);
        expect(
          result.errors.any(
            (error) => error.type == ValidationErrorType.inactiveSourcePort,
          ),
          isTrue,
        );
      });

      test('should reject connection with inactive destination port', () {
        final result = validator.validateConnection(
          audioOutputPort,
          inactivePort,
        );

        expect(result.isValid, isFalse);
        expect(
          result.errors.any(
            (error) =>
                error.type == ValidationErrorType.inactiveDestinationPort,
          ),
          isTrue,
        );
      });

      test('should reject connection with both ports inactive', () {
        const inactiveOutput = Port(
          id: 'inactive_out',
          name: 'Inactive Output',
          type: PortType.audio,
          direction: PortDirection.output,
          isActive: false,
        );

        final result = validator.validateConnection(
          inactiveOutput,
          inactivePort,
        );

        expect(result.isValid, isFalse);
        expect(result.errors.length, equals(2));
        expect(
          result.errors.any(
            (error) => error.type == ValidationErrorType.inactiveSourcePort,
          ),
          isTrue,
        );
        expect(
          result.errors.any(
            (error) =>
                error.type == ValidationErrorType.inactiveDestinationPort,
          ),
          isTrue,
        );
      });
    });

    group('Constraint Validation Tests', () {
      test('should validate compatible voltage ranges', () {
        const sourceWithRange = Port(
          id: 'source',
          name: 'Source',
          type: PortType.cv,
          direction: PortDirection.output,
          constraints: {
            'voltageRange': {'min': -5, 'max': 5},
          },
        );

        const destWithRange = Port(
          id: 'dest',
          name: 'Destination',
          type: PortType.cv,
          direction: PortDirection.input,
          constraints: {
            'voltageRange': {'min': -10, 'max': 10},
          },
        );

        final result = validator.validateConnection(
          sourceWithRange,
          destWithRange,
        );

        expect(result.isValid, isTrue);
        expect(result.errors, isEmpty);
      });

      test('should reject incompatible voltage ranges', () {
        const sourceWithRange = Port(
          id: 'source',
          name: 'Source',
          type: PortType.cv,
          direction: PortDirection.output,
          constraints: {
            'voltageRange': {'min': 5, 'max': 10},
          },
        );

        const destWithRange = Port(
          id: 'dest',
          name: 'Destination',
          type: PortType.cv,
          direction: PortDirection.input,
          constraints: {
            'voltageRange': {'min': -5, 'max': 3},
          },
        );

        final result = validator.validateConnection(
          sourceWithRange,
          destWithRange,
        );

        expect(result.isValid, isFalse);
        expect(
          result.errors.any(
            (error) => error.type == ValidationErrorType.constraintViolation,
          ),
          isTrue,
        );
      });
    });

    group('Existing Connections Tests', () {
      test('should warn about existing connections on ports', () {
        const existingConnections = [
          Connection(
            id: 'existing1',
            sourcePortId: 'audio_out',
            destinationPortId: 'other_input',
            connectionType: ConnectionType.algorithmToAlgorithm,
          ),
          Connection(
            id: 'existing2',
            sourcePortId: 'other_output',
            destinationPortId: 'audio_in',
            connectionType: ConnectionType.algorithmToAlgorithm,
          ),
        ];

        final result = validator.validateConnection(
          audioOutputPort,
          audioInputPort,
          existingConnections: existingConnections,
        );

        expect(result.isValid, isTrue);
        expect(result.warnings.length, equals(2));
        expect(
          result.warnings.any(
            (warning) =>
                warning.message.contains('Source port audio_out already has'),
          ),
          isTrue,
        );
        expect(
          result.warnings.any(
            (warning) => warning.message.contains(
              'Destination port audio_in already has',
            ),
          ),
          isTrue,
        );
      });
    });

    group('Custom Rules Tests', () {
      test('should apply custom validation rules', () {
        // Add a custom rule that rejects connections between specific port types
        validator.addCustomRule((source, destination) {
          if (source.type == PortType.audio &&
              destination.type == PortType.cv) {
            return const ValidationResult.failure([
              ValidationError(
                type: ValidationErrorType.customRuleFailed,
                message: 'Custom rule: Audio to CV not allowed',
              ),
            ]);
          }
          return const ValidationResult.success();
        });

        final result = validator.validateConnection(
          audioOutputPort,
          cvInputPort,
        );

        expect(result.isValid, isFalse);
        expect(
          result.errors.any(
            (error) => error.type == ValidationErrorType.customRuleFailed,
          ),
          isTrue,
        );
        expect(
          result.errors.any((error) => error.message.contains('Custom rule')),
          isTrue,
        );
      });

      test('should handle custom rule exceptions gracefully', () {
        // Add a custom rule that throws an exception
        validator.addCustomRule((source, destination) {
          throw Exception('Test exception');
        });

        final result = validator.validateConnection(
          audioOutputPort,
          audioInputPort,
        );

        expect(result.isValid, isFalse);
        expect(
          result.errors.any(
            (error) => error.type == ValidationErrorType.customRuleFailed,
          ),
          isTrue,
        );
        expect(
          result.errors.any(
            (error) => error.message.contains('Custom validation rule failed'),
          ),
          isTrue,
        );
      });

      test('should clear custom rules', () {
        // Add a custom rule
        validator.addCustomRule((source, destination) {
          return const ValidationResult.failure([
            ValidationError(
              type: ValidationErrorType.customRuleFailed,
              message: 'Always fail',
            ),
          ]);
        });

        // Verify rule is applied
        var result = validator.validateConnection(
          audioOutputPort,
          audioInputPort,
        );
        expect(result.isValid, isFalse);

        // Clear rules and verify they're no longer applied
        validator.clearCustomRules();
        result = validator.validateConnection(audioOutputPort, audioInputPort);
        expect(result.isValid, isTrue);
      });
    });

    group('ValidationResult Tests', () {
      test('should create successful validation result', () {
        const warnings = [ValidationWarning(message: 'Test warning')];
        const result = ValidationResult.success(warnings: warnings);

        expect(result.isValid, isTrue);
        expect(result.errors, isEmpty);
        expect(result.warnings, equals(warnings));
      });

      test('should create failed validation result', () {
        const errors = [
          ValidationError(
            type: ValidationErrorType.incompatibleType,
            message: 'Test error',
          ),
        ];
        const result = ValidationResult.failure(errors);

        expect(result.isValid, isFalse);
        expect(result.errors, equals(errors));
        expect(result.warnings, isEmpty);
      });

      test('ValidationResult equality should work correctly', () {
        const result1 = ValidationResult.success();
        const result2 = ValidationResult.success();

        expect(result1, equals(result2));
        expect(result1.hashCode, equals(result2.hashCode));

        const errors = [
          ValidationError(
            type: ValidationErrorType.incompatibleType,
            message: 'Error',
          ),
        ];
        const result3 = ValidationResult.failure(errors);
        const result4 = ValidationResult.failure(errors);

        expect(result3, equals(result4));
        expect(result1, isNot(equals(result3)));
      });
    });

    group('ValidationError Tests', () {
      test('should create validation error with all fields', () {
        const error = ValidationError(
          type: ValidationErrorType.incompatibleType,
          message: 'Test error message',
          sourcePortId: 'source_id',
          destinationPortId: 'dest_id',
          details: {'key': 'value'},
        );

        expect(error.type, equals(ValidationErrorType.incompatibleType));
        expect(error.message, equals('Test error message'));
        expect(error.sourcePortId, equals('source_id'));
        expect(error.destinationPortId, equals('dest_id'));
        expect(error.details?['key'], equals('value'));
      });

      test('ValidationError equality should work correctly', () {
        const error1 = ValidationError(
          type: ValidationErrorType.incompatibleType,
          message: 'Test',
        );
        const error2 = ValidationError(
          type: ValidationErrorType.incompatibleType,
          message: 'Test',
        );

        expect(error1, equals(error2));
        expect(error1.hashCode, equals(error2.hashCode));
      });
    });

    group('ValidationWarning Tests', () {
      test('should create validation warning with all fields', () {
        const warning = ValidationWarning(
          message: 'Test warning message',
          sourcePortId: 'source_id',
          destinationPortId: 'dest_id',
          details: {'key': 'value'},
        );

        expect(warning.message, equals('Test warning message'));
        expect(warning.sourcePortId, equals('source_id'));
        expect(warning.destinationPortId, equals('dest_id'));
        expect(warning.details?['key'], equals('value'));
      });

      test('ValidationWarning equality should work correctly', () {
        const warning1 = ValidationWarning(message: 'Test');
        const warning2 = ValidationWarning(message: 'Test');

        expect(warning1, equals(warning2));
        expect(warning1.hashCode, equals(warning2.hashCode));
      });
    });
  });
}
