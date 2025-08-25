import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/models/algorithm_port.dart';
import 'package:nt_helper/models/connection.dart';
import 'package:nt_helper/util/routing_validator.dart';

void main() {
  group('RoutingValidator', () {
    late Map<int, List<AlgorithmPort>> algorithmPorts;
    late List<Connection> existingConnections;

    setUp(() {
      algorithmPorts = {
        0: [
          const AlgorithmPort(id: 'audio_out', name: 'Audio Output'),
          const AlgorithmPort(id: 'cv_out', name: 'CV Output'),
        ],
        1: [
          const AlgorithmPort(id: 'audio_in', name: 'Audio Input'),
          const AlgorithmPort(id: 'cv_in', name: 'CV Input'),
        ],
        2: [
          const AlgorithmPort(id: 'audio_in', name: 'Audio Input'),
          const AlgorithmPort(id: 'audio_out', name: 'Audio Output'),
        ],
      };

      existingConnections = [];
    });

    test('should validate compatible audio connection', () {
      final connection = Connection(
        id: 'test',
        sourceAlgorithmIndex: 0,
        sourcePortId: 'audio_out',
        targetAlgorithmIndex: 1,
        targetPortId: 'audio_in',
        assignedBus: 21,
        replaceMode: true,
        isValid: true,
      );

      final result = RoutingValidator.validateConnection(
        proposedConnection: connection,
        existingConnections: existingConnections,
        algorithmPorts: algorithmPorts,
      );

      expect(result.isValid, true);
      expect(result.errors, isEmpty);
    });

    test('should validate compatible CV connection', () {
      final connection = Connection(
        id: 'test',
        sourceAlgorithmIndex: 0,
        sourcePortId: 'cv_out',
        targetAlgorithmIndex: 1,
        targetPortId: 'cv_in',
        assignedBus: 21,
        replaceMode: true,
        isValid: true,
      );

      final result = RoutingValidator.validateConnection(
        proposedConnection: connection,
        existingConnections: existingConnections,
        algorithmPorts: algorithmPorts,
      );

      expect(result.isValid, true);
      expect(result.errors, isEmpty);
    });

    test('should reject self-connection', () {
      final connection = Connection(
        id: 'test',
        sourceAlgorithmIndex: 0,
        sourcePortId: 'audio_out',
        targetAlgorithmIndex: 0,
        targetPortId: 'audio_in',
        assignedBus: 21,
        replaceMode: true,
        isValid: true,
      );

      final result = RoutingValidator.validateConnection(
        proposedConnection: connection,
        existingConnections: existingConnections,
        algorithmPorts: algorithmPorts,
      );

      expect(result.isValid, false);
      expect(result.errors, contains('Cannot connect algorithm to itself'));
    });

    test('should detect cycle in connections', () {
      // Create a cycle: 0 -> 1 -> 2 -> 0
      existingConnections = [
        Connection(
          id: 'conn1',
          sourceAlgorithmIndex: 0,
          sourcePortId: 'audio_out',
          targetAlgorithmIndex: 1,
          targetPortId: 'audio_in',
          assignedBus: 21,
          replaceMode: true,
          isValid: true,
        ),
        Connection(
          id: 'conn2',
          sourceAlgorithmIndex: 1,
          sourcePortId: 'audio_out',
          targetAlgorithmIndex: 2,
          targetPortId: 'audio_in',
          assignedBus: 22,
          replaceMode: true,
          isValid: true,
        ),
      ];

      // This connection would complete the cycle
      final connection = Connection(
        id: 'test',
        sourceAlgorithmIndex: 2,
        sourcePortId: 'audio_out',
        targetAlgorithmIndex: 0,
        targetPortId: 'audio_in',
        assignedBus: 23,
        replaceMode: true,
        isValid: true,
      );

      final result = RoutingValidator.validateConnection(
        proposedConnection: connection,
        existingConnections: existingConnections,
        algorithmPorts: algorithmPorts,
      );

      expect(result.isValid, false);
      expect(
        result.errors,
        contains('Connection would create circular dependency'),
      );
    });

    test('should detect duplicate connection', () {
      existingConnections = [
        Connection(
          id: 'existing',
          sourceAlgorithmIndex: 0,
          sourcePortId: 'audio_out',
          targetAlgorithmIndex: 1,
          targetPortId: 'audio_in',
          assignedBus: 21,
          replaceMode: true,
          isValid: true,
        ),
      ];

      final connection = Connection(
        id: 'test',
        sourceAlgorithmIndex: 0,
        sourcePortId: 'audio_out',
        targetAlgorithmIndex: 1,
        targetPortId: 'audio_in',
        assignedBus: 22,
        replaceMode: true,
        isValid: true,
      );

      final result = RoutingValidator.validateConnection(
        proposedConnection: connection,
        existingConnections: existingConnections,
        algorithmPorts: algorithmPorts,
      );

      expect(result.warnings, contains('Connection already exists'));
    });

    test('should validate graph without cycles', () {
      final connections = [
        Connection(
          id: 'conn1',
          sourceAlgorithmIndex: 0,
          sourcePortId: 'audio_out',
          targetAlgorithmIndex: 1,
          targetPortId: 'audio_in',
          assignedBus: 21,
          replaceMode: true,
          isValid: true,
        ),
        Connection(
          id: 'conn2',
          sourceAlgorithmIndex: 1,
          sourcePortId: 'audio_out',
          targetAlgorithmIndex: 2,
          targetPortId: 'audio_in',
          assignedBus: 22,
          replaceMode: true,
          isValid: true,
        ),
      ];

      final result = RoutingValidator.validateGraph(
        connections: connections,
        algorithmPorts: algorithmPorts,
      );

      expect(result.isValid, true);
      expect(result.errors, isEmpty);
    });

    test('should detect cycle in graph validation', () {
      final connections = [
        Connection(
          id: 'conn1',
          sourceAlgorithmIndex: 0,
          sourcePortId: 'audio_out',
          targetAlgorithmIndex: 1,
          targetPortId: 'audio_in',
          assignedBus: 21,
          replaceMode: true,
          isValid: true,
        ),
        Connection(
          id: 'conn2',
          sourceAlgorithmIndex: 1,
          sourcePortId: 'audio_out',
          targetAlgorithmIndex: 2,
          targetPortId: 'audio_in',
          assignedBus: 22,
          replaceMode: true,
          isValid: true,
        ),
        Connection(
          id: 'conn3',
          sourceAlgorithmIndex: 2,
          sourcePortId: 'audio_out',
          targetAlgorithmIndex: 0,
          targetPortId: 'audio_in',
          assignedBus: 23,
          replaceMode: true,
          isValid: true,
        ),
      ];

      final result = RoutingValidator.validateGraph(
        connections: connections,
        algorithmPorts: algorithmPorts,
      );

      expect(result.isValid, false);
      expect(
        result.errors,
        contains('Circular dependency detected in routing graph'),
      );
    });
  });
}
