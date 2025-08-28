import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/core/routing/models/connection.dart';

void main() {
  group('Connection Model Tests', () {
    test('should create connection with required fields', () {
      const connection = Connection(
        id: 'test_connection',
        sourcePortId: 'source_port',
        destinationPortId: 'dest_port',
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
        status: ConnectionStatus.disabled,
        name: 'Test Connection',
        description: 'A test connection',
        gain: 0.8,
        isMuted: true,
        isInverted: true,
        delayMs: 10.5,
        properties: {'custom': 'value'},
        createdAt: now,
        modifiedAt: now,
      );

      expect(connection.name, equals('Test Connection'));
      expect(connection.description, equals('A test connection'));
      expect(connection.gain, equals(0.8));
      expect(connection.isMuted, isTrue);
      expect(connection.isInverted, isTrue);
      expect(connection.delayMs, equals(10.5));
      expect(connection.properties?['custom'], equals('value'));
      expect(connection.createdAt, equals(now));
      expect(connection.modifiedAt, equals(now));
    });

    test('should serialize to and from JSON correctly', () {
      final now = DateTime.now();
      final originalConnection = Connection(
        id: 'test_connection',
        sourcePortId: 'source_port',
        destinationPortId: 'dest_port',
        status: ConnectionStatus.error,
        name: 'Test Connection',
        gain: 0.5,
        isMuted: false,
        isInverted: true,
        delayMs: 5.0,
        properties: {'test': true},
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
      expect(deserializedConnection.properties, equals(originalConnection.properties));
    });

    group('Connection Status Tests', () {
      test('should correctly identify active connection', () {
        const connection = Connection(
          id: 'test',
          sourcePortId: 'src',
          destinationPortId: 'dest',
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

      test('withProperties should update properties and modifiedAt', () {
        final originalConnection = Connection(
          id: 'test',
          sourcePortId: 'src',
          destinationPortId: 'dest',
          properties: {'old': 'value'},
          modifiedAt: DateTime(2023, 1, 1),
        );

        final newProperties = {'new': 'value', 'another': 42};
        final updatedConnection = originalConnection.withProperties(newProperties);

        expect(updatedConnection.properties, equals(newProperties));
        expect(updatedConnection.modifiedAt, isNot(equals(originalConnection.modifiedAt)));
        expect(updatedConnection.modifiedAt!.isAfter(originalConnection.modifiedAt!), isTrue);
      });

      test('withGain should update gain and modifiedAt', () {
        final originalConnection = Connection(
          id: 'test',
          sourcePortId: 'src',
          destinationPortId: 'dest',
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
          gain: 0.8,
        );

        const connection2 = Connection(
          id: 'test',
          sourcePortId: 'src',
          destinationPortId: 'dest',
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
        );

        const connection2 = Connection(
          id: 'test2',
          sourcePortId: 'src',
          destinationPortId: 'dest',
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
  });
}