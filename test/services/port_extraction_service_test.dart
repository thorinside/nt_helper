import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:nt_helper/models/algorithm_metadata.dart';
import 'package:nt_helper/models/algorithm_parameter.dart';
import 'package:nt_helper/models/algorithm_port.dart';
import 'package:nt_helper/services/algorithm_metadata_service.dart';
import 'package:nt_helper/services/port_extraction_service.dart';

@GenerateMocks([AlgorithmMetadataService])
import 'port_extraction_service_test.mocks.dart';

void main() {
  group('PortExtractionService', () {
    late MockAlgorithmMetadataService mockMetadataService;
    late PortExtractionService service;

    setUp(() {
      mockMetadataService = MockAlgorithmMetadataService();
      service = PortExtractionService(mockMetadataService);
    });

    group('extractPorts with new format', () {
      test(
        'should extract ports from algorithm with input_ports and output_ports',
        () {
          // Arrange
          const algorithmGuid = 'mix1';
          final metadata = AlgorithmMetadata(
            guid: algorithmGuid,
            name: 'Mixer Mono',
            categories: const ['Mixer'],
            description: 'A mono mixer',
            inputPorts: const [
              AlgorithmPort(
                id: 'in_channel',
                name: 'Channel Input',
                description: 'Mono input for a mixer channel',
                busIdRef: 'Input',
              ),
            ],
            outputPorts: const [
              AlgorithmPort(
                id: 'out_main',
                name: 'Main Output',
                description: 'Main mono mix output',
                busIdRef: 'Output',
              ),
              AlgorithmPort(
                id: 'out_send',
                name: 'Send Output',
                description: 'Mono aux send output',
                busIdRef: 'Send Destination',
              ),
            ],
            parameters: const [
              AlgorithmParameter(
                name: 'Input',
                unit: 'bus',
                defaultValue: 1,
                min: 0,
                max: 28,
              ),
              AlgorithmParameter(
                name: 'Output',
                unit: 'bus',
                defaultValue: 13,
                min: 0,
                max: 28,
              ),
            ],
          );

          when(
            mockMetadataService.getAlgorithmByGuid(algorithmGuid),
          ).thenReturn(metadata);

          // Act
          final result = service.extractPorts(algorithmGuid);

          // Assert
          expect(result.inputPorts, hasLength(1));
          expect(result.outputPorts, hasLength(2));
          expect(result.inputPorts[0].name, equals('Channel Input'));
          expect(result.outputPorts[0].name, equals('Main Output'));
          expect(result.outputPorts[1].name, equals('Send Output'));
          expect(result.portBusAssignments['in_channel'], equals(1));
          expect(result.portBusAssignments['out_main'], equals(13));
        },
      );

      test('should handle per-channel ports', () {
        // Arrange
        const algorithmGuid = 'multi_osc';
        final metadata = AlgorithmMetadata(
          guid: algorithmGuid,
          name: 'Multi Oscillator',
          categories: const ['Oscillator'],
          description: 'Multiple oscillators',
          outputPorts: const [
            AlgorithmPort(
              id: 'osc_out',
              name: 'Oscillator Output',
              description: 'Per-channel oscillator output',
              busIdRef: 'Output',
              isPerChannel: true,
            ),
          ],
          parameters: const [
            AlgorithmParameter(
              name: 'Output',
              unit: 'bus',
              defaultValue: 13,
              isPerChannel: true,
            ),
          ],
        );

        when(
          mockMetadataService.getAlgorithmByGuid(algorithmGuid),
        ).thenReturn(metadata);

        // Act
        final result = service.extractPorts(algorithmGuid);

        // Assert
        expect(result.outputPorts, hasLength(1));
        expect(result.outputPorts[0].isPerChannel, isTrue);
        expect(result.outputPorts[0].name, equals('Oscillator Output'));
      });
    });

    group('extractPorts with old format (parameter-based)', () {
      test('should extract ports from parameters with unit=bus', () {
        // Arrange
        const algorithmGuid = 'old_algo';
        final metadata = AlgorithmMetadata(
          guid: algorithmGuid,
          name: 'Old Algorithm',
          categories: const ['Legacy'],
          description: 'Algorithm without port arrays',
          inputPorts: const [], // Empty - uses old format
          outputPorts: const [],
        );

        final parameters = [
          const AlgorithmParameter(
            name: 'Input Bus',
            unit: 'bus',
            defaultValue: 1,
            min: 0,
            max: 12,
          ),
          const AlgorithmParameter(
            name: 'Output Bus',
            unit: 'bus',
            defaultValue: 13,
            min: 13,
            max: 24,
          ),
          const AlgorithmParameter(
            name: 'Send Output',
            unit: 'bus',
            defaultValue: 21,
            min: 21,
            max: 28,
          ),
        ];

        when(
          mockMetadataService.getAlgorithmByGuid(algorithmGuid),
        ).thenReturn(metadata);
        when(
          mockMetadataService.getExpandedParameters(algorithmGuid),
        ).thenReturn(parameters);

        // Act
        final result = service.extractPorts(algorithmGuid);

        // Assert
        expect(result.inputPorts, hasLength(1));
        expect(result.outputPorts, hasLength(2));
        expect(result.inputPorts[0].name, equals('Input Bus'));
        expect(result.outputPorts[0].name, equals('Output Bus'));
        expect(result.outputPorts[1].name, equals('Send Output'));
      });

      test('should extract ports from parameters with type=bus', () {
        // Arrange
        const algorithmGuid = 'type_bus_algo';
        final metadata = AlgorithmMetadata(
          guid: algorithmGuid,
          name: 'Type Bus Algorithm',
          categories: const ['Test'],
          description: 'Uses type=bus instead of unit=bus',
          inputPorts: const [],
          outputPorts: const [],
        );

        final parameters = [
          const AlgorithmParameter(
            name: 'Input Channel',
            type: 'bus',
            defaultValue: 2,
          ),
          const AlgorithmParameter(
            name: 'Main Output',
            type: 'bus',
            defaultValue: 14,
          ),
        ];

        when(
          mockMetadataService.getAlgorithmByGuid(algorithmGuid),
        ).thenReturn(metadata);
        when(
          mockMetadataService.getExpandedParameters(algorithmGuid),
        ).thenReturn(parameters);

        // Act
        final result = service.extractPorts(algorithmGuid);

        // Assert
        expect(result.inputPorts, hasLength(1));
        expect(result.outputPorts, hasLength(1));
        expect(result.inputPorts[0].name, equals('Input Channel'));
        expect(result.outputPorts[0].name, equals('Main Output'));
      });
    });

    group('extractPorts fallback scenarios', () {
      test('should return empty ports when algorithm not found', () {
        // Arrange
        const algorithmGuid = 'nonexistent';
        when(
          mockMetadataService.getAlgorithmByGuid(algorithmGuid),
        ).thenReturn(null);

        // Act
        final result = service.extractPorts(algorithmGuid);

        // Assert
        expect(result.inputPorts, isEmpty);
        expect(result.outputPorts, isEmpty);
        expect(result.portBusAssignments, isEmpty);
      });

      test(
        'should return default ports when no ports or bus parameters found',
        () {
          // Arrange
          const algorithmGuid = 'no_ports_algo';
          final metadata = AlgorithmMetadata(
            guid: algorithmGuid,
            name: 'No Ports Algorithm',
            categories: const ['Test'],
            description: 'Algorithm with no ports',
            inputPorts: const [],
            outputPorts: const [],
          );

          final parameters = [
            const AlgorithmParameter(name: 'Gain', unit: 'dB', defaultValue: 0),
            const AlgorithmParameter(
              name: 'Frequency',
              unit: 'Hz',
              defaultValue: 440,
            ),
          ];

          when(
            mockMetadataService.getAlgorithmByGuid(algorithmGuid),
          ).thenReturn(metadata);
          when(
            mockMetadataService.getExpandedParameters(algorithmGuid),
          ).thenReturn(parameters);

          // Act
          final result = service.extractPorts(algorithmGuid);

          // Assert
          expect(result.inputPorts, hasLength(2));
          expect(result.outputPorts, hasLength(2));
          expect(result.inputPorts[0].name, equals('Input 1'));
          expect(result.inputPorts[1].name, equals('Input 2'));
          expect(result.outputPorts[0].name, equals('Output 1'));
          expect(result.outputPorts[1].name, equals('Output 2'));
        },
      );
    });

    group('port type detection', () {
      test('should correctly identify input parameters', () {
        // This test verifies the _isInputParameter logic indirectly
        const algorithmGuid = 'input_test';
        final metadata = AlgorithmMetadata(
          guid: algorithmGuid,
          name: 'Input Test',
          categories: const ['Test'],
          description: 'Test input detection',
          inputPorts: const [],
          outputPorts: const [],
        );

        final parameters = [
          const AlgorithmParameter(
            name: 'Audio Input',
            unit: 'bus',
            defaultValue: 1,
          ),
          const AlgorithmParameter(
            name: 'Receive Bus',
            unit: 'bus',
            defaultValue: 2,
          ),
          const AlgorithmParameter(
            name: 'In Channel',
            unit: 'bus',
            defaultValue: 3,
          ),
        ];

        when(
          mockMetadataService.getAlgorithmByGuid(algorithmGuid),
        ).thenReturn(metadata);
        when(
          mockMetadataService.getExpandedParameters(algorithmGuid),
        ).thenReturn(parameters);

        // Act
        final result = service.extractPorts(algorithmGuid);

        // Assert
        expect(result.inputPorts, hasLength(3));
        expect(result.outputPorts, isEmpty);
      });

      test('should correctly identify output parameters', () {
        // This test verifies the _isOutputParameter logic indirectly
        const algorithmGuid = 'output_test';
        final metadata = AlgorithmMetadata(
          guid: algorithmGuid,
          name: 'Output Test',
          categories: const ['Test'],
          description: 'Test output detection',
          inputPorts: const [],
          outputPorts: const [],
        );

        final parameters = [
          const AlgorithmParameter(
            name: 'Audio Output',
            unit: 'bus',
            defaultValue: 13,
          ),
          const AlgorithmParameter(
            name: 'Send Bus',
            unit: 'bus',
            defaultValue: 21,
          ),
          const AlgorithmParameter(
            name: 'Out Channel',
            unit: 'bus',
            defaultValue: 14,
          ),
        ];

        when(
          mockMetadataService.getAlgorithmByGuid(algorithmGuid),
        ).thenReturn(metadata);
        when(
          mockMetadataService.getExpandedParameters(algorithmGuid),
        ).thenReturn(parameters);

        // Act
        final result = service.extractPorts(algorithmGuid);

        // Assert
        expect(result.inputPorts, isEmpty);
        expect(result.outputPorts, hasLength(3));
      });
    });

    group('bus assignment extraction', () {
      test('should extract correct bus numbers from parameters', () {
        // Arrange
        const algorithmGuid = 'bus_test';
        final metadata = AlgorithmMetadata(
          guid: algorithmGuid,
          name: 'Bus Test',
          categories: const ['Test'],
          description: 'Test bus assignments',
          inputPorts: const [
            AlgorithmPort(
              id: 'in1',
              name: 'Input 1',
              busIdRef: 'Input Channel 1',
            ),
          ],
          outputPorts: const [
            AlgorithmPort(
              id: 'out1',
              name: 'Output 1',
              busIdRef: 'Output Channel 1',
            ),
          ],
          parameters: const [
            AlgorithmParameter(
              name: 'Input Channel 1',
              unit: 'bus',
              defaultValue: 5,
            ),
            AlgorithmParameter(
              name: 'Output Channel 1',
              unit: 'bus',
              defaultValue: 15,
            ),
          ],
        );

        when(
          mockMetadataService.getAlgorithmByGuid(algorithmGuid),
        ).thenReturn(metadata);

        // Act
        final result = service.extractPorts(algorithmGuid);

        // Assert
        expect(result.portBusAssignments['in1'], equals(5));
        expect(result.portBusAssignments['out1'], equals(15));
      });
    });
  });
}
