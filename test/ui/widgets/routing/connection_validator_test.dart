import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/core/routing/models/port.dart';
import 'package:nt_helper/ui/widgets/routing/connection_validator.dart';

void main() {
  group('ConnectionValidator physical port bi-directionality', () {
    // Physical input ports have PortDirection.output because they are signal sources
    final physicalInput = Port(
      id: 'hw_in_1',
      name: 'Input 1',
      type: PortType.cv,
      direction: PortDirection.output,
      isPhysical: true,
      hardwareIndex: 1,
      jackType: 'input',
    );

    // Physical output ports have PortDirection.input because they are signal sinks
    final physicalOutput = Port(
      id: 'hw_out_1',
      name: 'Output 1',
      type: PortType.cv,
      direction: PortDirection.input,
      isPhysical: true,
      hardwareIndex: 1,
      jackType: 'output',
    );

    final algorithmInput = Port(
      id: 'node_1_in_1',
      name: 'Algo Input 1',
      type: PortType.cv,
      direction: PortDirection.input,
    );

    final algorithmOutput = Port(
      id: 'node_2_out_1',
      name: 'Algo Output 1',
      type: PortType.cv,
      direction: PortDirection.output,
    );

    test('physical input -> algorithm input is valid', () {
      expect(
        ConnectionValidator.isValidConnection(physicalInput, algorithmInput),
        isTrue,
      );
    });

    test('algorithm output -> physical output is valid', () {
      expect(
        ConnectionValidator.isValidConnection(algorithmOutput, physicalOutput),
        isTrue,
      );
    });

    test('algorithm output -> physical input (ghost connection) is valid', () {
      expect(
        ConnectionValidator.isValidConnection(algorithmOutput, physicalInput),
        isTrue,
      );
    });

    test('algorithm output -> algorithm input is valid', () {
      expect(
        ConnectionValidator.isValidConnection(algorithmOutput, algorithmInput),
        isTrue,
      );
    });

    test('physical input -> physical output is invalid', () {
      expect(
        ConnectionValidator.isValidConnection(physicalInput, physicalOutput),
        isFalse,
      );
    });

    test('physical output -> physical input is invalid', () {
      expect(
        ConnectionValidator.isValidConnection(physicalOutput, physicalInput),
        isFalse,
      );
    });

    test('physical output -> algorithm input is valid', () {
      expect(
        ConnectionValidator.isValidConnection(physicalOutput, algorithmInput),
        isTrue,
      );
    });

    test('algorithm input -> algorithm output is invalid', () {
      expect(
        ConnectionValidator.isValidConnection(algorithmInput, algorithmOutput),
        isFalse,
      );
    });

    test('ghost connection is correctly identified', () {
      expect(
        ConnectionValidator.isGhostConnection(algorithmOutput, physicalInput),
        isTrue,
      );
    });

    test('algorithm output -> physical output is not a ghost connection', () {
      expect(
        ConnectionValidator.isGhostConnection(algorithmOutput, physicalOutput),
        isFalse,
      );
    });
  });

  group('ConnectionValidator drag direction resolution', () {
    // These tests verify that for any valid connection, at least one of
    // isValidConnection(a, b) or isValidConnection(b, a) returns true,
    // which is what the drag handlers rely on to resolve direction.

    final physicalInput = Port(
      id: 'hw_in_1',
      name: 'Input 1',
      type: PortType.cv,
      direction: PortDirection.output,
      isPhysical: true,
      hardwareIndex: 1,
      jackType: 'input',
    );

    final physicalOutput = Port(
      id: 'hw_out_1',
      name: 'Output 1',
      type: PortType.cv,
      direction: PortDirection.input,
      isPhysical: true,
      hardwareIndex: 1,
      jackType: 'output',
    );

    final algorithmInput = Port(
      id: 'node_1_in_1',
      name: 'Algo Input 1',
      type: PortType.cv,
      direction: PortDirection.input,
    );

    final algorithmOutput = Port(
      id: 'node_2_out_1',
      name: 'Algo Output 1',
      type: PortType.cv,
      direction: PortDirection.output,
    );

    test('dragging from algorithm output to physical input resolves', () {
      final forward = ConnectionValidator.isValidConnection(
        algorithmOutput,
        physicalInput,
      );
      final reverse = ConnectionValidator.isValidConnection(
        physicalInput,
        algorithmOutput,
      );
      expect(forward || reverse, isTrue,
          reason: 'Ghost connection should be valid in at least one direction');
      expect(forward, isTrue,
          reason: 'Algorithm output should be the source');
    });

    test('dragging from physical input to algorithm output resolves', () {
      // User drags from physical input to algorithm output — reverse ordering
      // should be valid (algorithm output as source)
      final forward = ConnectionValidator.isValidConnection(
        physicalInput,
        algorithmOutput,
      );
      final reverse = ConnectionValidator.isValidConnection(
        algorithmOutput,
        physicalInput,
      );
      expect(forward || reverse, isTrue,
          reason: 'Should resolve via reverse ordering');
    });

    test('dragging from physical output to algorithm input resolves', () {
      final forward = ConnectionValidator.isValidConnection(
        physicalOutput,
        algorithmInput,
      );
      final reverse = ConnectionValidator.isValidConnection(
        algorithmInput,
        physicalOutput,
      );
      expect(forward || reverse, isTrue,
          reason: 'Physical output -> algorithm input is valid');
      expect(forward, isTrue,
          reason: 'Physical output should be the source');
    });

    test('dragging from algorithm input to physical output resolves', () {
      // User drags from algorithm input to physical output — reverse ordering
      // should be valid (physical output as source)
      final forward = ConnectionValidator.isValidConnection(
        algorithmInput,
        physicalOutput,
      );
      final reverse = ConnectionValidator.isValidConnection(
        physicalOutput,
        algorithmInput,
      );
      expect(forward || reverse, isTrue,
          reason: 'Should resolve via reverse ordering');
    });

    test('dragging from algorithm output to physical output resolves', () {
      final forward = ConnectionValidator.isValidConnection(
        algorithmOutput,
        physicalOutput,
      );
      final reverse = ConnectionValidator.isValidConnection(
        physicalOutput,
        algorithmOutput,
      );
      expect(forward || reverse, isTrue,
          reason: 'Algorithm output -> physical output is valid');
      expect(forward, isTrue);
    });
  });
}
