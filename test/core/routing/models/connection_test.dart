import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/core/routing/models/connection.dart';

void main() {
  group('Connection Model Tests', () {
    test('should create connection with required fields', () {
      const connection = Connection(
        id: 'test_connection',
        sourcePortId: 'source_port',
        destinationPortId: 'dest_port',
        connectionType: ConnectionType.algorithmToAlgorithm,
      );

      expect(connection.id, equals('test_connection'));
      expect(connection.sourcePortId, equals('source_port'));
      expect(connection.destinationPortId, equals('dest_port'));
      expect(connection.status, equals(ConnectionStatus.active)); // default
      expect(connection.gain, equals(1.0)); // default
      expect(connection.isMuted, isFalse); // default
      expect(connection.isInverted, isFalse); // default
      expect(connection.delayMs, equals(0.0)); // default
    });

    test('should create connection with all optional fields', () {
      final now = DateTime.now();
      final connection = Connection(
        id: 'test_connection',
        sourcePortId: 'source_port',
        destinationPortId: 'dest_port',
        connectionType: ConnectionType.algorithmToAlgorithm,
        status: ConnectionStatus.disabled,
        name: 'Test Connection',
        description: 'A test connection',
        gain: 0.8,
        isMuted: true,
        isInverted: true,
        delayMs: 10.5,
        createdAt: now,
        modifiedAt: now,
      );

      expect(connection.name, equals('Test Connection'));
      expect(connection.description, equals('A test connection'));
      expect(connection.gain, equals(0.8));
      expect(connection.isMuted, isTrue);
      expect(connection.isInverted, isTrue);
      expect(connection.delayMs, equals(10.5));
      // Properties field removed from Connection model
      expect(connection.createdAt, equals(now));
      expect(connection.modifiedAt, equals(now));
    });

    test('should serialize to and from JSON correctly', () {
      final now = DateTime.now();
      final originalConnection = Connection(
        id: 'test_connection',
        sourcePortId: 'source_port',
        destinationPortId: 'dest_port',
        connectionType: ConnectionType.algorithmToAlgorithm,
        status: ConnectionStatus.error,
        name: 'Test Connection',
        gain: 0.5,
        isMuted: false,
        isInverted: true,
        delayMs: 5.0,
        createdAt: now,
        modifiedAt: now,
      );

      final json = originalConnection.toJson();
      final deserializedConnection = Connection.fromJson(json);

      expect(deserializedConnection, equals(originalConnection));
      expect(deserializedConnection.id, equals(originalConnection.id));
      expect(deserializedConnection.sourcePortId, equals(originalConnection.sourcePortId));
      expect(deserializedConnection.destinationPortId, equals(originalConnection.destinationPortId));
      expect(deserializedConnection.status, equals(originalConnection.status));
      expect(deserializedConnection.gain, equals(originalConnection.gain));
      expect(deserializedConnection.isMuted, equals(originalConnection.isMuted));
      expect(deserializedConnection.isInverted, equals(originalConnection.isInverted));
      expect(deserializedConnection.delayMs, equals(originalConnection.delayMs));
    });

    group('Connection Status Tests', () {
      test('should correctly identify active connection', () {
        const connection = Connection(
          id: 'test',
          sourcePortId: 'src',
          destinationPortId: 'dest',
          connectionType: ConnectionType.algorithmToAlgorithm,
          status: ConnectionStatus.active,
        );

        expect(connection.isActive, isTrue);
        expect(connection.hasError, isFalse);
        expect(connection.isConnecting, isFalse);
        expect(connection.isDisabled, isFalse);
      });

      test('should correctly identify error connection', () {
        const connection = Connection(
          id: 'test',
          sourcePortId: 'src',
          destinationPortId: 'dest',
          connectionType: ConnectionType.algorithmToAlgorithm,
          status: ConnectionStatus.error,
        );

        expect(connection.isActive, isFalse);
        expect(connection.hasError, isTrue);
        expect(connection.isConnecting, isFalse);
        expect(connection.isDisabled, isFalse);
      });

      test('should correctly identify connecting connection', () {
        const connection = Connection(
          id: 'test',
          sourcePortId: 'src',
          destinationPortId: 'dest',
          connectionType: ConnectionType.algorithmToAlgorithm,
          status: ConnectionStatus.connecting,
        );

        expect(connection.isActive, isFalse);
        expect(connection.hasError, isFalse);
        expect(connection.isConnecting, isTrue);
        expect(connection.isDisabled, isFalse);
      });

      test('should correctly identify disabled connection', () {
        const connection = Connection(
          id: 'test',
          sourcePortId: 'src',
          destinationPortId: 'dest',
          connectionType: ConnectionType.algorithmToAlgorithm,
          status: ConnectionStatus.disabled,
        );

        expect(connection.isActive, isFalse);
        expect(connection.hasError, isFalse);
        expect(connection.isConnecting, isFalse);
        expect(connection.isDisabled, isTrue);
      });
    });

    group('Effective Gain Tests', () {
      test('should return actual gain when not muted or inverted', () {
        const connection = Connection(
          id: 'test',
          sourcePortId: 'src',
          destinationPortId: 'dest',
          connectionType: ConnectionType.algorithmToAlgorithm,
          gain: 0.8,
          isMuted: false,
          isInverted: false,
        );

        expect(connection.effectiveGain, equals(0.8));
      });

      test('should return zero gain when muted', () {
        const connection = Connection(
          id: 'test',
          sourcePortId: 'src',
          destinationPortId: 'dest',
          connectionType: ConnectionType.algorithmToAlgorithm,
          gain: 0.8,
          isMuted: true,
          isInverted: false,
        );

        expect(connection.effectiveGain, equals(0.0));
      });

      test('should return negative gain when inverted', () {
        const connection = Connection(
          id: 'test',
          sourcePortId: 'src',
          destinationPortId: 'dest',
          connectionType: ConnectionType.algorithmToAlgorithm,
          gain: 0.8,
          isMuted: false,
          isInverted: true,
        );

        expect(connection.effectiveGain, equals(-0.8));
      });

      test('should return zero when both muted and inverted', () {
        const connection = Connection(
          id: 'test',
          sourcePortId: 'src',
          destinationPortId: 'dest',
          connectionType: ConnectionType.algorithmToAlgorithm,
          gain: 0.8,
          isMuted: true,
          isInverted: true,
        );

        expect(connection.effectiveGain, equals(0.0));
      });
    });

    group('Connection Helper Methods Tests', () {
      test('withStatus should update status and modifiedAt', () {
        final originalConnection = Connection(
          id: 'test',
          sourcePortId: 'src',
          destinationPortId: 'dest',
          connectionType: ConnectionType.algorithmToAlgorithm,
          status: ConnectionStatus.active,
          modifiedAt: DateTime(2023, 1, 1),
        );

        final updatedConnection = originalConnection.withStatus(ConnectionStatus.error);

        expect(updatedConnection.status, equals(ConnectionStatus.error));
        expect(updatedConnection.modifiedAt, isNot(equals(originalConnection.modifiedAt)));
        expect(updatedConnection.modifiedAt!.isAfter(originalConnection.modifiedAt!), isTrue);
        
        // Other fields should remain the same
        expect(updatedConnection.id, equals(originalConnection.id));
        expect(updatedConnection.sourcePortId, equals(originalConnection.sourcePortId));
        expect(updatedConnection.destinationPortId, equals(originalConnection.destinationPortId));
      });

      // withProperties method was removed in the Connection refactor

      test('withGain should update gain and modifiedAt', () {
        final originalConnection = Connection(
          id: 'test',
          sourcePortId: 'src',
          destinationPortId: 'dest',
          connectionType: ConnectionType.algorithmToAlgorithm,
          gain: 1.0,
          modifiedAt: DateTime(2023, 1, 1),
        );

        final updatedConnection = originalConnection.withGain(0.5);

        expect(updatedConnection.gain, equals(0.5));
        expect(updatedConnection.modifiedAt, isNot(equals(originalConnection.modifiedAt)));
        expect(updatedConnection.modifiedAt!.isAfter(originalConnection.modifiedAt!), isTrue);
      });
    });

    group('Connection Equality Tests', () {
      test('connections with same values should be equal', () {
        const connection1 = Connection(
          id: 'test',
          sourcePortId: 'src',
          destinationPortId: 'dest',
          connectionType: ConnectionType.algorithmToAlgorithm,
          gain: 0.8,
        );

        const connection2 = Connection(
          id: 'test',
          sourcePortId: 'src',
          destinationPortId: 'dest',
          connectionType: ConnectionType.algorithmToAlgorithm,
          gain: 0.8,
        );

        expect(connection1, equals(connection2));
        expect(connection1.hashCode, equals(connection2.hashCode));
      });

      test('connections with different values should not be equal', () {
        const connection1 = Connection(
          id: 'test1',
          sourcePortId: 'src',
          destinationPortId: 'dest',
          connectionType: ConnectionType.algorithmToAlgorithm,
        );

        const connection2 = Connection(
          id: 'test2',
          sourcePortId: 'src',
          destinationPortId: 'dest',
          connectionType: ConnectionType.algorithmToAlgorithm,
        );

        expect(connection1, isNot(equals(connection2)));
      });
    });

    group('Connection Copy Tests', () {
      test('should create modified copy with copyWith', () {
        const originalConnection = Connection(
          id: 'original',
          sourcePortId: 'src',
          destinationPortId: 'dest',
          connectionType: ConnectionType.algorithmToAlgorithm,
          status: ConnectionStatus.active,
          gain: 1.0,
          isMuted: false,
        );

        final modifiedConnection = originalConnection.copyWith(
          status: ConnectionStatus.disabled,
          gain: 0.5,
          isMuted: true,
        );

        expect(modifiedConnection.id, equals(originalConnection.id));
        expect(modifiedConnection.sourcePortId, equals(originalConnection.sourcePortId));
        expect(modifiedConnection.destinationPortId, equals(originalConnection.destinationPortId));
        expect(modifiedConnection.status, equals(ConnectionStatus.disabled));
        expect(modifiedConnection.gain, equals(0.5));
        expect(modifiedConnection.isMuted, isTrue);
      });
    });

    group('Partial Connection Tests', () {
      test('should create partial connection with bus endpoint', () {
        const connection = Connection(
          id: 'partial_connection',
          sourcePortId: 'output_port',
          destinationPortId: '', // Empty indicates bus label endpoint
          connectionType: ConnectionType.partialOutputToBus,
          isPartial: true,
          busNumber: 5, // Bus A5
        );

        expect(connection.id, equals('partial_connection'));
        expect(connection.sourcePortId, equals('output_port'));
        expect(connection.destinationPortId, equals(''));
        expect(connection.isPartial, isTrue);
        expect(connection.busNumber, equals(5));
      });

      test('should identify partial connections correctly', () {
        const fullConnection = Connection(
          id: 'full',
          sourcePortId: 'src',
          destinationPortId: 'dest',
          connectionType: ConnectionType.algorithmToAlgorithm,
        );

        const partialConnection = Connection(
          id: 'partial',
          sourcePortId: 'src',
          destinationPortId: '',
          connectionType: ConnectionType.partialOutputToBus,
          isPartial: true,
          busNumber: 3,
        );

        expect(fullConnection.isPartial, isFalse);
        expect(partialConnection.isPartial, isTrue);
      });

      test('should serialize partial connection to JSON correctly', () {
        const originalConnection = Connection(
          id: 'partial_test',
          sourcePortId: 'port1',
          destinationPortId: '',
          connectionType: ConnectionType.partialOutputToBus,
          isPartial: true,
          busNumber: 7,
          busLabel: 'A7',
        );

        final json = originalConnection.toJson();
        final deserializedConnection = Connection.fromJson(json);

        expect(deserializedConnection, equals(originalConnection));
        expect(deserializedConnection.isPartial, isTrue);
        expect(deserializedConnection.busNumber, equals(7));
        expect(deserializedConnection.busLabel, equals('A7'));
      });

      test('should handle partial connection with input port', () {
        const connection = Connection(
          id: 'partial_input',
          sourcePortId: '', // Empty for bus label source
          destinationPortId: 'input_port',
          connectionType: ConnectionType.partialBusToInput,
          isPartial: true,
          busNumber: 12,
          busLabel: 'B4',
        );

        expect(connection.sourcePortId, equals(''));
        expect(connection.destinationPortId, equals('input_port'));
        expect(connection.isPartial, isTrue);
        expect(connection.busNumber, equals(12));
        expect(connection.busLabel, equals('B4'));
      });

      test('should maintain partial status through copyWith', () {
        const originalConnection = Connection(
          id: 'partial',
          sourcePortId: 'src',
          destinationPortId: '',
          connectionType: ConnectionType.partialOutputToBus,
          isPartial: true,
          busNumber: 4,
        );

        final modifiedConnection = originalConnection.copyWith(
          gain: 0.8,
        );

        expect(modifiedConnection.isPartial, isTrue);
        expect(modifiedConnection.busNumber, equals(4));
        expect(modifiedConnection.gain, equals(0.8));
      });

      test('should handle bus label for rendering', () {
        const connection = Connection(
          id: 'partial_with_label',
          sourcePortId: 'output',
          destinationPortId: '',
          connectionType: ConnectionType.partialOutputToBus,
          isPartial: true,
          busNumber: 15,
          busLabel: 'Out3',
        );

        expect(connection.busLabel, equals('Out3'));
        expect(connection.hasUnconnectedBus, isTrue);
      });

      test('should differentiate between partial and full connections in equality', () {
        const partialConnection = Connection(
          id: 'test',
          sourcePortId: 'src',
          destinationPortId: '',
          connectionType: ConnectionType.partialOutputToBus,
          isPartial: true,
          busNumber: 5,
        );

        const fullConnection = Connection(
          id: 'test',
          sourcePortId: 'src',
          destinationPortId: 'dest',
          connectionType: ConnectionType.algorithmToAlgorithm,
          isPartial: false,
        );

        expect(partialConnection, isNot(equals(fullConnection)));
      });
    });
  });
}