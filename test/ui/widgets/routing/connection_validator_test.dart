import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/core/routing/models/port.dart';
import 'package:nt_helper/ui/widgets/routing/connection_validator.dart';

void main() {
  group('ConnectionValidator', () {
    // Helper function to create physical input port
    Port createPhysicalInput(int index) {
      return Port(
        id: 'hw_in_$index',
        name: 'Input $index',
        type: PortType.audio,
        direction: PortDirection.output, // Physical inputs are sources
        metadata: {
          'isPhysical': true,
          'hardwareIndex': index,
          'jackType': 'input',
        },
      );
    }

    // Helper function to create physical output port
    Port createPhysicalOutput(int index) {
      return Port(
        id: 'hw_out_$index',
        name: 'Output $index',
        type: PortType.audio,
        direction: PortDirection.input, // Physical outputs are targets
        metadata: {
          'isPhysical': true,
          'hardwareIndex': index,
          'jackType': 'output',
        },
      );
    }

    // Helper function to create algorithm input port
    Port createAlgorithmInput(String nodeId, int index) {
      return Port(
        id: '${nodeId}_in_$index',
        name: 'Input $index',
        type: PortType.audio,
        direction: PortDirection.input,
        metadata: {
          'isPhysical': false,
        },
      );
    }

    // Helper function to create algorithm output port
    Port createAlgorithmOutput(String nodeId, int index) {
      return Port(
        id: '${nodeId}_out_$index',
        name: 'Output $index',
        type: PortType.audio,
        direction: PortDirection.output,
        metadata: {
          'isPhysical': false,
        },
      );
    }

    group('Valid Connections', () {
      test('allows physical input to algorithm input', () {
        final source = createPhysicalInput(1);
        final target = createAlgorithmInput('node_1', 1);

        expect(ConnectionValidator.isValidConnection(source, target), isTrue);
        expect(ConnectionValidator.isGhostConnection(source, target), isFalse);
        expect(
          ConnectionValidator.getConnectionDescription(source, target),
          equals('Hardware input to algorithm'),
        );
      });

      test('allows algorithm output to physical output', () {
        final source = createAlgorithmOutput('node_1', 1);
        final target = createPhysicalOutput(1);

        expect(ConnectionValidator.isValidConnection(source, target), isTrue);
        expect(ConnectionValidator.isGhostConnection(source, target), isFalse);
        expect(
          ConnectionValidator.getConnectionDescription(source, target),
          equals('Algorithm output to hardware'),
        );
      });

      test('allows algorithm output to algorithm input', () {
        final source = createAlgorithmOutput('node_1', 1);
        final target = createAlgorithmInput('node_2', 1);

        expect(ConnectionValidator.isValidConnection(source, target), isTrue);
        expect(ConnectionValidator.isGhostConnection(source, target), isFalse);
        expect(
          ConnectionValidator.getConnectionDescription(source, target),
          equals('Algorithm to algorithm routing'),
        );
      });

      test('allows algorithm output to physical input (ghost connection)', () {
        final source = createAlgorithmOutput('node_1', 1);
        final target = createPhysicalInput(1);

        expect(ConnectionValidator.isValidConnection(source, target), isTrue);
        expect(ConnectionValidator.isGhostConnection(source, target), isTrue);
        expect(
          ConnectionValidator.getConnectionDescription(source, target),
          equals('Ghost signal on physical input 1 - available to other algorithms'),
        );
      });
    });

    group('Invalid Connections', () {
      test('prevents physical input to physical output', () {
        final source = createPhysicalInput(1);
        final target = createPhysicalOutput(1);

        expect(ConnectionValidator.isValidConnection(source, target), isFalse);
        expect(
          ConnectionValidator.getValidationError(source, target),
          contains('Direct physical-to-physical connections are not supported'),
        );
      });

      test('prevents physical output to physical input', () {
        final source = createPhysicalOutput(1);
        final target = createPhysicalInput(1);

        expect(ConnectionValidator.isValidConnection(source, target), isFalse);
        expect(
          ConnectionValidator.getValidationError(source, target),
          contains('Direct physical-to-physical connections are not supported'),
        );
      });

      test('prevents physical output to physical output', () {
        final source = createPhysicalOutput(1);
        final target = createPhysicalOutput(2);

        expect(ConnectionValidator.isValidConnection(source, target), isFalse);
        expect(
          ConnectionValidator.getValidationError(source, target),
          contains('Direct physical-to-physical connections are not supported'),
        );
      });

      test('prevents physical input to physical input', () {
        final source = createPhysicalInput(1);
        final target = createPhysicalInput(2);

        expect(ConnectionValidator.isValidConnection(source, target), isFalse);
        expect(
          ConnectionValidator.getValidationError(source, target),
          contains('Direct physical-to-physical connections are not supported'),
        );
      });

      test('prevents same node connections (feedback loops)', () {
        final source = createAlgorithmOutput('node_1', 1);
        final target = createAlgorithmInput('node_1', 1);

        expect(ConnectionValidator.isValidConnection(source, target), isFalse);
        expect(
          ConnectionValidator.getValidationError(source, target),
          contains('Cannot connect a node to itself'),
        );
      });

      test('prevents input to input connections', () {
        final source = createAlgorithmInput('node_1', 1);
        final target = createAlgorithmInput('node_2', 1);

        expect(ConnectionValidator.isValidConnection(source, target), isFalse);
        expect(
          ConnectionValidator.getValidationError(source, target),
          contains('Port directions are incompatible'),
        );
      });

      test('prevents output to output connections (non-ghost)', () {
        final source = createAlgorithmOutput('node_1', 1);
        final target = createAlgorithmOutput('node_2', 1);

        expect(ConnectionValidator.isValidConnection(source, target), isFalse);
        expect(
          ConnectionValidator.getValidationError(source, target),
          contains('Port directions are incompatible'),
        );
      });
    });

    group('Ghost Connection Detection', () {
      test('identifies algorithm to physical input as ghost connection', () {
        final source = createAlgorithmOutput('node_1', 1);
        final target = createPhysicalInput(3);

        expect(ConnectionValidator.isGhostConnection(source, target), isTrue);
        expect(
          ConnectionValidator.getConnectionDescription(source, target),
          contains('Ghost signal on physical input 3'),
        );
      });

      test('does not identify algorithm to physical output as ghost connection', () {
        final source = createAlgorithmOutput('node_1', 1);
        final target = createPhysicalOutput(2);

        expect(ConnectionValidator.isGhostConnection(source, target), isFalse);
        expect(
          ConnectionValidator.getConnectionDescription(source, target),
          equals('Algorithm output to hardware'),
        );
      });

      test('does not identify physical to algorithm as ghost connection', () {
        final source = createPhysicalInput(1);
        final target = createAlgorithmInput('node_1', 1);

        expect(ConnectionValidator.isGhostConnection(source, target), isFalse);
      });

      test('does not identify algorithm to algorithm as ghost connection', () {
        final source = createAlgorithmOutput('node_1', 1);
        final target = createAlgorithmInput('node_2', 1);

        expect(ConnectionValidator.isGhostConnection(source, target), isFalse);
      });
    });

    group('Port Type Compatibility', () {
      test('allows audio to audio connections', () {
        final source = Port(
          id: 'node_1_out_1',
          name: 'Audio Out',
          type: PortType.audio,
          direction: PortDirection.output,
        );
        final target = Port(
          id: 'node_2_in_1',
          name: 'Audio In',
          type: PortType.audio,
          direction: PortDirection.input,
        );

        expect(ConnectionValidator.arePortTypesCompatible(source, target), isTrue);
      });

      test('allows CV to audio connections', () {
        final source = Port(
          id: 'node_1_out_1',
          name: 'CV Out',
          type: PortType.cv,
          direction: PortDirection.output,
        );
        final target = Port(
          id: 'node_2_in_1',
          name: 'Audio In',
          type: PortType.audio,
          direction: PortDirection.input,
        );

        expect(ConnectionValidator.arePortTypesCompatible(source, target), isTrue);
      });

      test('allows gate to clock connections', () {
        final source = Port(
          id: 'node_1_out_1',
          name: 'Gate Out',
          type: PortType.gate,
          direction: PortDirection.output,
        );
        final target = Port(
          id: 'node_2_in_1',
          name: 'Clock In',
          type: PortType.clock,
          direction: PortDirection.input,
        );

        expect(ConnectionValidator.arePortTypesCompatible(source, target), isTrue);
      });
    });

    group('Edge Cases', () {
      test('handles ports with missing metadata', () {
        final source = Port(
          id: 'test_out',
          name: 'Test Output',
          type: PortType.audio,
          direction: PortDirection.output,
        );
        final target = Port(
          id: 'test_in',
          name: 'Test Input',
          type: PortType.audio,
          direction: PortDirection.input,
        );

        // Should treat as algorithm ports (non-physical)
        expect(ConnectionValidator.isValidConnection(source, target), isTrue);
        expect(ConnectionValidator.isGhostConnection(source, target), isFalse);
      });

      test('handles bidirectional ports', () {
        final source = Port(
          id: 'node_1_bi_1',
          name: 'Bidirectional',
          type: PortType.audio,
          direction: PortDirection.bidirectional,
        );
        final target = createAlgorithmInput('node_2', 1);

        expect(ConnectionValidator.isValidConnection(source, target), isTrue);
      });

      test('validates all 12 physical inputs', () {
        for (int i = 1; i <= 12; i++) {
          final input = createPhysicalInput(i);
          final algorithmInput = createAlgorithmInput('node_1', 1);
          
          expect(
            ConnectionValidator.isValidConnection(input, algorithmInput),
            isTrue,
            reason: 'Physical input $i should connect to algorithm input',
          );
        }
      });

      test('validates all 8 physical outputs', () {
        for (int i = 1; i <= 8; i++) {
          final output = createPhysicalOutput(i);
          final algorithmOutput = createAlgorithmOutput('node_1', 1);
          
          expect(
            ConnectionValidator.isValidConnection(algorithmOutput, output),
            isTrue,
            reason: 'Algorithm output should connect to physical output $i',
          );
        }
      });
    });

    group('Error Messages', () {
      test('provides clear error for physical-to-physical attempts', () {
        final source = createPhysicalInput(1);
        final target = createPhysicalOutput(1);
        
        final error = ConnectionValidator.getValidationError(source, target);
        expect(error, contains('Direct physical-to-physical'));
        expect(error, contains('routed through algorithms'));
      });

      test('provides clear error for feedback loop attempts', () {
        final source = createAlgorithmOutput('node_1', 1);
        final target = createAlgorithmInput('node_1', 2);
        
        final error = ConnectionValidator.getValidationError(source, target);
        expect(error, contains('feedback loop'));
      });

      test('provides clear error for incompatible directions', () {
        final source = createAlgorithmInput('node_1', 1);
        final target = createAlgorithmInput('node_2', 1);
        
        final error = ConnectionValidator.getValidationError(source, target);
        expect(error, contains('Port directions are incompatible'));
      });
    });
  });
}