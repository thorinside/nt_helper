import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/core/routing/models/port_metadata.dart';

void main() {
  group('PortMetadata', () {
    group('HardwarePortMetadata', () {
      test('creates hardware input metadata correctly', () {
        const metadata = PortMetadata.hardware(
          busNumber: 1,
          isInput: true,
          jackNumber: 1,
        );

        expect(metadata, isA<HardwarePortMetadata>());
        metadata.when(
          hardware: (busNumber, isInput, jackNumber) {
            expect(busNumber, 1);
            expect(isInput, true);
            expect(jackNumber, 1);
          },
          algorithm: (_, __, ___, ____, _____, ______) {
            fail('Should be hardware metadata');
          },
        );
      });

      test('creates hardware output metadata correctly', () {
        const metadata = PortMetadata.hardware(
          busNumber: 13,
          isInput: false,
          jackNumber: 1,
        );

        expect(metadata, isA<HardwarePortMetadata>());
        metadata.when(
          hardware: (busNumber, isInput, jackNumber) {
            expect(busNumber, 13);
            expect(isInput, false);
            expect(jackNumber, 1);
          },
          algorithm: (_, __, ___, ____, _____, ______) {
            fail('Should be hardware metadata');
          },
        );
      });
    });

    group('AlgorithmPortMetadata', () {
      test('creates algorithm metadata with all fields', () {
        const metadata = PortMetadata.algorithm(
          algorithmId: 'algo_abc123_inst1',
          parameterNumber: 23,
          parameterName: 'Left output',
          busNumber: 15,
          voiceNumber: '1',
          channel: 'left',
        );

        expect(metadata, isA<AlgorithmPortMetadata>());
        metadata.when(
          hardware: (_, __, ___) {
            fail('Should be algorithm metadata');
          },
          algorithm: (algorithmId, parameterNumber, parameterName, busNumber, voiceNumber, channel) {
            expect(algorithmId, 'algo_abc123_inst1');
            expect(parameterNumber, 23);
            expect(parameterName, 'Left output');
            expect(busNumber, 15);
            expect(voiceNumber, '1');
            expect(channel, 'left');
          },
        );
      });

      test('creates algorithm metadata with optional fields null', () {
        const metadata = PortMetadata.algorithm(
          algorithmId: 'algo_xyz789_inst2',
          parameterNumber: 45,
          parameterName: 'Gate input 1',
        );

        expect(metadata, isA<AlgorithmPortMetadata>());
        metadata.when(
          hardware: (_, __, ___) {
            fail('Should be algorithm metadata');
          },
          algorithm: (algorithmId, parameterNumber, parameterName, busNumber, voiceNumber, channel) {
            expect(algorithmId, 'algo_xyz789_inst2');
            expect(parameterNumber, 45);
            expect(parameterName, 'Gate input 1');
            expect(busNumber, isNull);
            expect(voiceNumber, isNull);
            expect(channel, isNull);
          },
        );
      });
    });

    group('Pattern matching', () {
      test('can match on hardware metadata type', () {
        const metadata = PortMetadata.hardware(
          busNumber: 5,
          isInput: true,
          jackNumber: 5,
        );

        final result = metadata.when(
          hardware: (busNumber, isInput, jackNumber) => 'hardware:$busNumber',
          algorithm: (_, __, ___, ____, _____, ______) => 'algorithm',
        );

        expect(result, 'hardware:5');
      });

      test('can match on algorithm metadata type', () {
        const metadata = PortMetadata.algorithm(
          algorithmId: 'algo_test',
          parameterNumber: 10,
          parameterName: 'Test param',
        );

        final result = metadata.when(
          hardware: (_, __, ___) => 'hardware',
          algorithm: (algorithmId, _, __, ___, ____, _____) => 'algorithm:$algorithmId',
        );

        expect(result, 'algorithm:algo_test');
      });

      test('can use maybeWhen for partial matching', () {
        const hwMetadata = PortMetadata.hardware(
          busNumber: 3,
          isInput: false,
          jackNumber: 3,
        );

        final hwResult = hwMetadata.maybeWhen(
          hardware: (busNumber, _, __) => 'bus:$busNumber',
          orElse: () => 'other',
        );

        expect(hwResult, 'bus:3');

        const algoMetadata = PortMetadata.algorithm(
          algorithmId: 'test',
          parameterNumber: 1,
          parameterName: 'Test',
        );

        final algoResult = algoMetadata.maybeWhen(
          hardware: (_, __, ___) => 'hardware',
          orElse: () => 'other',
        );

        expect(algoResult, 'other');
      });
    });

    group('Equality and hashing', () {
      test('hardware metadata with same values are equal', () {
        const metadata1 = PortMetadata.hardware(
          busNumber: 7,
          isInput: true,
          jackNumber: 7,
        );

        const metadata2 = PortMetadata.hardware(
          busNumber: 7,
          isInput: true,
          jackNumber: 7,
        );

        expect(metadata1, equals(metadata2));
        expect(metadata1.hashCode, equals(metadata2.hashCode));
      });

      test('hardware metadata with different values are not equal', () {
        const metadata1 = PortMetadata.hardware(
          busNumber: 7,
          isInput: true,
          jackNumber: 7,
        );

        const metadata2 = PortMetadata.hardware(
          busNumber: 8,
          isInput: true,
          jackNumber: 8,
        );

        expect(metadata1, isNot(equals(metadata2)));
      });

      test('algorithm metadata with same values are equal', () {
        const metadata1 = PortMetadata.algorithm(
          algorithmId: 'algo_1',
          parameterNumber: 10,
          parameterName: 'Test',
          busNumber: 5,
        );

        const metadata2 = PortMetadata.algorithm(
          algorithmId: 'algo_1',
          parameterNumber: 10,
          parameterName: 'Test',
          busNumber: 5,
        );

        expect(metadata1, equals(metadata2));
        expect(metadata1.hashCode, equals(metadata2.hashCode));
      });

      test('different metadata types are not equal', () {
        const hwMetadata = PortMetadata.hardware(
          busNumber: 1,
          isInput: true,
          jackNumber: 1,
        );

        const algoMetadata = PortMetadata.algorithm(
          algorithmId: 'algo_1',
          parameterNumber: 1,
          parameterName: 'Test',
          busNumber: 1,
        );

        expect(hwMetadata, isNot(equals(algoMetadata)));
      });
    });
  });
}