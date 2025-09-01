import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/core/routing/models/connection_metadata.dart';

void main() {
  group('ConnectionMetadata', () {
    test('creates hardware connection metadata', () {
      const metadata = ConnectionMetadata(
        connectionClass: ConnectionClass.hardware,
        busNumber: 5,
        signalType: SignalType.audio,
      );

      expect(metadata.connectionClass, ConnectionClass.hardware);
      expect(metadata.busNumber, 5);
      expect(metadata.signalType, SignalType.audio);
      expect(metadata.sourceAlgorithmId, isNull);
      expect(metadata.targetAlgorithmId, isNull);
      expect(metadata.sourceParameterNumber, isNull);
      expect(metadata.targetParameterNumber, isNull);
      expect(metadata.isBackwardEdge, isNull);
      expect(metadata.isValid, isNull);
    });

    test('creates algorithm connection metadata with all fields', () {
      const metadata = ConnectionMetadata(
        connectionClass: ConnectionClass.algorithm,
        busNumber: 15,
        signalType: SignalType.cv,
        sourceAlgorithmId: 'algo_abc123_inst1',
        targetAlgorithmId: 'algo_xyz789_inst2',
        sourceParameterNumber: 23,
        targetParameterNumber: 45,
        isBackwardEdge: false,
        isValid: true,
      );

      expect(metadata.connectionClass, ConnectionClass.algorithm);
      expect(metadata.busNumber, 15);
      expect(metadata.signalType, SignalType.cv);
      expect(metadata.sourceAlgorithmId, 'algo_abc123_inst1');
      expect(metadata.targetAlgorithmId, 'algo_xyz789_inst2');
      expect(metadata.sourceParameterNumber, 23);
      expect(metadata.targetParameterNumber, 45);
      expect(metadata.isBackwardEdge, false);
      expect(metadata.isValid, true);
    });

    test('creates user connection metadata', () {
      const metadata = ConnectionMetadata(
        connectionClass: ConnectionClass.user,
        busNumber: 0, // User connections may not use buses
        signalType: SignalType.mixed,
      );

      expect(metadata.connectionClass, ConnectionClass.user);
      expect(metadata.busNumber, 0);
      expect(metadata.signalType, SignalType.mixed);
    });

    group('Signal types', () {
      test('supports all signal types', () {
        const audioMeta = ConnectionMetadata(
          connectionClass: ConnectionClass.hardware,
          busNumber: 1,
          signalType: SignalType.audio,
        );
        expect(audioMeta.signalType, SignalType.audio);

        const cvMeta = ConnectionMetadata(
          connectionClass: ConnectionClass.hardware,
          busNumber: 2,
          signalType: SignalType.cv,
        );
        expect(cvMeta.signalType, SignalType.cv);

        const gateMeta = ConnectionMetadata(
          connectionClass: ConnectionClass.hardware,
          busNumber: 3,
          signalType: SignalType.gate,
        );
        expect(gateMeta.signalType, SignalType.gate);

        const clockMeta = ConnectionMetadata(
          connectionClass: ConnectionClass.hardware,
          busNumber: 4,
          signalType: SignalType.clock,
        );
        expect(clockMeta.signalType, SignalType.clock);

        const mixedMeta = ConnectionMetadata(
          connectionClass: ConnectionClass.hardware,
          busNumber: 5,
          signalType: SignalType.mixed,
        );
        expect(mixedMeta.signalType, SignalType.mixed);
      });
    });

    group('Validation helpers', () {
      test('isHardwareConnection returns true for hardware class', () {
        const metadata = ConnectionMetadata(
          connectionClass: ConnectionClass.hardware,
          busNumber: 1,
          signalType: SignalType.audio,
        );

        expect(metadata.isHardwareConnection, true);
        expect(metadata.isAlgorithmConnection, false);
        expect(metadata.isUserConnection, false);
      });

      test('isAlgorithmConnection returns true for algorithm class', () {
        const metadata = ConnectionMetadata(
          connectionClass: ConnectionClass.algorithm,
          busNumber: 15,
          signalType: SignalType.cv,
        );

        expect(metadata.isHardwareConnection, false);
        expect(metadata.isAlgorithmConnection, true);
        expect(metadata.isUserConnection, false);
      });

      test('isUserConnection returns true for user class', () {
        const metadata = ConnectionMetadata(
          connectionClass: ConnectionClass.user,
          busNumber: 0,
          signalType: SignalType.mixed,
        );

        expect(metadata.isHardwareConnection, false);
        expect(metadata.isAlgorithmConnection, false);
        expect(metadata.isUserConnection, true);
      });

      test('hasValidation returns true when isValid is set', () {
        const validMeta = ConnectionMetadata(
          connectionClass: ConnectionClass.algorithm,
          busNumber: 15,
          signalType: SignalType.audio,
          isValid: true,
        );

        expect(validMeta.hasValidation, true);
        expect(validMeta.isValid, true);

        const invalidMeta = ConnectionMetadata(
          connectionClass: ConnectionClass.algorithm,
          busNumber: 15,
          signalType: SignalType.audio,
          isValid: false,
        );

        expect(invalidMeta.hasValidation, true);
        expect(invalidMeta.isValid, false);

        const noValidationMeta = ConnectionMetadata(
          connectionClass: ConnectionClass.algorithm,
          busNumber: 15,
          signalType: SignalType.audio,
        );

        expect(noValidationMeta.hasValidation, false);
        expect(noValidationMeta.isValid, null);
      });
    });

    group('Equality and hashing', () {
      test('metadata with same values are equal', () {
        const metadata1 = ConnectionMetadata(
          connectionClass: ConnectionClass.algorithm,
          busNumber: 10,
          signalType: SignalType.gate,
          sourceAlgorithmId: 'algo_1',
          targetAlgorithmId: 'algo_2',
          sourceParameterNumber: 5,
          targetParameterNumber: 10,
          isBackwardEdge: false,
          isValid: true,
        );

        const metadata2 = ConnectionMetadata(
          connectionClass: ConnectionClass.algorithm,
          busNumber: 10,
          signalType: SignalType.gate,
          sourceAlgorithmId: 'algo_1',
          targetAlgorithmId: 'algo_2',
          sourceParameterNumber: 5,
          targetParameterNumber: 10,
          isBackwardEdge: false,
          isValid: true,
        );

        expect(metadata1, equals(metadata2));
        expect(metadata1.hashCode, equals(metadata2.hashCode));
      });

      test('metadata with different values are not equal', () {
        const metadata1 = ConnectionMetadata(
          connectionClass: ConnectionClass.algorithm,
          busNumber: 10,
          signalType: SignalType.gate,
        );

        const metadata2 = ConnectionMetadata(
          connectionClass: ConnectionClass.hardware,
          busNumber: 10,
          signalType: SignalType.gate,
        );

        expect(metadata1, isNot(equals(metadata2)));
      });

      test('copyWith creates new instance with updated values', () {
        const original = ConnectionMetadata(
          connectionClass: ConnectionClass.algorithm,
          busNumber: 10,
          signalType: SignalType.audio,
          isValid: true,
        );

        final updated = original.copyWith(
          busNumber: 15,
          isValid: false,
        );

        expect(updated.connectionClass, ConnectionClass.algorithm);
        expect(updated.busNumber, 15);
        expect(updated.signalType, SignalType.audio);
        expect(updated.isValid, false);
        expect(original.busNumber, 10);
        expect(original.isValid, true);
      });
    });
  });
}