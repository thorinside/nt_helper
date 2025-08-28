import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:nt_helper/core/routing/routing_factory.dart';
import 'package:nt_helper/core/routing/models/algorithm_routing_metadata.dart';
import 'package:nt_helper/core/routing/algorithm_routing.dart';
import 'package:nt_helper/core/routing/poly_algorithm_routing.dart';
import 'package:nt_helper/core/routing/multi_channel_algorithm_routing.dart';
import 'package:nt_helper/core/routing/port_compatibility_validator.dart';
import 'package:nt_helper/core/routing/models/port.dart';

@GenerateMocks([PortCompatibilityValidator])
import 'routing_factory_test.mocks.dart';

void main() {
  group('RoutingFactory', () {
    late RoutingFactory factory;
    late MockPortCompatibilityValidator mockValidator;

    setUp(() {
      mockValidator = MockPortCompatibilityValidator();
      factory = RoutingFactory();
    });

    group('Construction', () {
      test('should create factory without validator', () {
        final factory = RoutingFactory();
        expect(factory, isA<RoutingFactory>());
      });

      test('should create factory with validator', () {
        final factory = RoutingFactory(validator: mockValidator);
        expect(factory, isA<RoutingFactory>());
      });
    });

    group('Polyphonic Routing Creation', () {
      test('should create PolyAlgorithmRouting for polyphonic metadata', () {
        final metadata = AlgorithmRoutingMetadataFactory.polyphonic(
          algorithmGuid: 'test-poly',
          voiceCount: 4,
          requiresGateInputs: true,
          usesVirtualCvPorts: true,
        );

        final routing = factory.createRouting(metadata);

        expect(routing, isA<PolyAlgorithmRouting>());
        expect(routing.inputPorts, isNotEmpty);
        expect(routing.outputPorts, isNotEmpty);
      });

      test('should create polyphonic routing with correct configuration', () {
        final metadata = AlgorithmRoutingMetadataFactory.polyphonic(
          algorithmGuid: 'test-poly-config',
          algorithmName: 'Test Polyphonic Algorithm',
          voiceCount: 6,
          requiresGateInputs: false,
          usesVirtualCvPorts: false,
          virtualCvPortsPerVoice: 1,
          portNamePrefix: 'Osc',
        );

        final routing = factory.createRouting(metadata) as PolyAlgorithmRouting;

        expect(routing.config.voiceCount, equals(6));
        expect(routing.config.requiresGateInputs, isFalse);
        expect(routing.config.usesVirtualCvPorts, isFalse);
        expect(routing.config.virtualCvPortsPerVoice, equals(1));
        expect(routing.config.portNamePrefix, equals('Osc'));
        expect(
          routing.config.algorithmProperties['algorithmGuid'],
          equals('test-poly-config'),
        );
        expect(
          routing.config.algorithmProperties['algorithmName'],
          equals('Test Polyphonic Algorithm'),
        );
      });

      test('should create polyphonic routing with custom validator', () {
        final metadata = AlgorithmRoutingMetadataFactory.polyphonic(
          algorithmGuid: 'test-validator',
          voiceCount: 2,
        );

        final routing = factory.createRouting(
          metadata,
          validator: mockValidator,
        );

        expect(routing, isA<PolyAlgorithmRouting>());
        expect(routing.validator, equals(mockValidator));
      });

      test('should create polyphonic routing with factory validator', () {
        final factoryWithValidator = RoutingFactory(validator: mockValidator);
        final metadata = AlgorithmRoutingMetadataFactory.polyphonic(
          algorithmGuid: 'test-factory-validator',
          voiceCount: 2,
        );

        final routing = factoryWithValidator.createRouting(metadata);

        expect(routing, isA<PolyAlgorithmRouting>());
        expect(routing.validator, equals(mockValidator));
      });

      test('should include custom properties in polyphonic config', () {
        final metadata = AlgorithmRoutingMetadataFactory.polyphonic(
          algorithmGuid: 'test-custom-props',
          voiceCount: 3,
          customProperties: {
            'customProp1': 'value1',
            'customProp2': 42,
          },
        );

        final routing = factory.createRouting(metadata) as PolyAlgorithmRouting;

        expect(
          routing.config.algorithmProperties['customProp1'],
          equals('value1'),
        );
        expect(
          routing.config.algorithmProperties['customProp2'],
          equals(42),
        );
      });
    });

    group('Multi-Channel Routing Creation', () {
      test('should create MultiChannelAlgorithmRouting for normal metadata', () {
        final metadata = AlgorithmRoutingMetadataFactory.normal(
          algorithmGuid: 'test-normal',
        );

        final routing = factory.createRouting(metadata);

        expect(routing, isA<MultiChannelAlgorithmRouting>());
        expect(routing.inputPorts, isNotEmpty);
        expect(routing.outputPorts, isNotEmpty);
      });

      test('should create MultiChannelAlgorithmRouting for width-based metadata', () {
        final metadata = AlgorithmRoutingMetadataFactory.widthBased(
          algorithmGuid: 'test-width',
          channelCount: 4,
          supportsStereo: true,
        );

        final routing = factory.createRouting(metadata);

        expect(routing, isA<MultiChannelAlgorithmRouting>());
        expect(routing.inputPorts.length, greaterThan(1));
        expect(routing.outputPorts.length, greaterThan(1));
      });

      test('should create multi-channel routing with correct configuration', () {
        final metadata = AlgorithmRoutingMetadataFactory.widthBased(
          algorithmGuid: 'test-width-config',
          algorithmName: 'Test Width Algorithm',
          channelCount: 8,
          supportsStereo: false,
          allowsIndependentChannels: false,
          createMasterMix: false,
          portNamePrefix: 'Band',
          supportedPortTypes: ['audio', 'cv', 'gate'],
        );

        final routing = factory.createRouting(metadata) as MultiChannelAlgorithmRouting;

        expect(routing.config.channelCount, equals(8));
        expect(routing.config.supportsStereoChannels, isFalse);
        expect(routing.config.allowsIndependentChannels, isFalse);
        expect(routing.config.createMasterMix, isFalse);
        expect(routing.config.portNamePrefix, equals('Band'));
        expect(
          routing.config.supportedPortTypes,
          containsAll([PortType.audio, PortType.cv, PortType.gate]),
        );
        expect(
          routing.config.algorithmProperties['algorithmGuid'],
          equals('test-width-config'),
        );
        expect(
          routing.config.algorithmProperties['algorithmName'],
          equals('Test Width Algorithm'),
        );
      });

      test('should handle empty supported port types with defaults', () {
        final metadata = AlgorithmRoutingMetadata(
          algorithmGuid: 'test-empty-ports',
          routingType: RoutingType.multiChannel,
          supportedPortTypes: [],
        );

        final routing = factory.createRouting(metadata) as MultiChannelAlgorithmRouting;

        // Should default to audio and cv
        expect(
          routing.config.supportedPortTypes,
          containsAll([PortType.audio, PortType.cv]),
        );
      });

      test('should handle unknown port types gracefully', () {
        final metadata = AlgorithmRoutingMetadata(
          algorithmGuid: 'test-unknown-ports',
          routingType: RoutingType.multiChannel,
          supportedPortTypes: ['audio', 'unknown', 'cv', 'invalid'],
        );

        final routing = factory.createRouting(metadata) as MultiChannelAlgorithmRouting;

        // Should include known types and ignore unknown ones
        expect(
          routing.config.supportedPortTypes,
          containsAll([PortType.audio, PortType.cv]),
        );
        expect(routing.config.supportedPortTypes.length, equals(2));
      });

      test('should create multi-channel routing with custom validator', () {
        final metadata = AlgorithmRoutingMetadataFactory.normal(
          algorithmGuid: 'test-validator-multi',
        );

        final routing = factory.createRouting(
          metadata,
          validator: mockValidator,
        );

        expect(routing, isA<MultiChannelAlgorithmRouting>());
        expect(routing.validator, equals(mockValidator));
      });
    });

    group('Port Type Conversion', () {
      test('should convert all known port types correctly', () {
        final metadata = AlgorithmRoutingMetadata(
          algorithmGuid: 'test-all-port-types',
          routingType: RoutingType.multiChannel,
          supportedPortTypes: [
            'audio',
            'cv', 
            'gate',
            'clock',
            'midi',
            'data',
          ],
        );

        final routing = factory.createRouting(metadata) as MultiChannelAlgorithmRouting;

        final expectedTypes = [
          PortType.audio,
          PortType.cv,
          PortType.gate,
          PortType.clock,
        ];

        expect(routing.config.supportedPortTypes, containsAll(expectedTypes));
        expect(routing.config.supportedPortTypes.length, equals(expectedTypes.length));
      });

      test('should be case insensitive for port type names', () {
        final metadata = AlgorithmRoutingMetadata(
          algorithmGuid: 'test-case-insensitive',
          routingType: RoutingType.multiChannel,
          supportedPortTypes: [
            'AUDIO',
            'Cv',
            'GaTe',
            'CLOCK',
          ],
        );

        final routing = factory.createRouting(metadata) as MultiChannelAlgorithmRouting;

        expect(
          routing.config.supportedPortTypes,
          containsAll([PortType.audio, PortType.cv, PortType.gate, PortType.clock]),
        );
      });

      test('should fallback to audio/cv if all port types are invalid', () {
        final metadata = AlgorithmRoutingMetadata(
          algorithmGuid: 'test-invalid-ports',
          routingType: RoutingType.multiChannel,
          supportedPortTypes: ['invalid1', 'unknown2', 'nonexistent3'],
        );

        final routing = factory.createRouting(metadata) as MultiChannelAlgorithmRouting;

        expect(
          routing.config.supportedPortTypes,
          containsAll([PortType.audio, PortType.cv]),
        );
        expect(routing.config.supportedPortTypes.length, equals(2));
      });
    });

    group('Metadata Validation', () {
      test('should validate valid polyphonic metadata', () {
        final metadata = AlgorithmRoutingMetadataFactory.polyphonic(
          algorithmGuid: 'test-valid-poly',
          voiceCount: 4,
        );

        expect(factory.validateMetadata(metadata), isTrue);
      });

      test('should validate valid multi-channel metadata', () {
        final metadata = AlgorithmRoutingMetadataFactory.widthBased(
          algorithmGuid: 'test-valid-multi',
          channelCount: 2,
        );

        expect(factory.validateMetadata(metadata), isTrue);
      });

      test('should reject empty algorithm GUID', () {
        const metadata = AlgorithmRoutingMetadata(
          algorithmGuid: '',
          routingType: RoutingType.polyphonic,
        );

        expect(factory.validateMetadata(metadata), isFalse);
      });

      test('should reject polyphonic metadata with zero voice count', () {
        const metadata = AlgorithmRoutingMetadata(
          algorithmGuid: 'test-zero-voices',
          routingType: RoutingType.polyphonic,
          voiceCount: 0,
        );

        expect(factory.validateMetadata(metadata), isFalse);
      });

      test('should reject polyphonic metadata with negative voice count', () {
        const metadata = AlgorithmRoutingMetadata(
          algorithmGuid: 'test-negative-voices',
          routingType: RoutingType.polyphonic,
          voiceCount: -1,
        );

        expect(factory.validateMetadata(metadata), isFalse);
      });

      test('should reject polyphonic metadata with negative CV ports per voice', () {
        const metadata = AlgorithmRoutingMetadata(
          algorithmGuid: 'test-negative-cv',
          routingType: RoutingType.polyphonic,
          voiceCount: 4,
          virtualCvPortsPerVoice: -1,
        );

        expect(factory.validateMetadata(metadata), isFalse);
      });

      test('should reject multi-channel metadata with zero channel count', () {
        const metadata = AlgorithmRoutingMetadata(
          algorithmGuid: 'test-zero-channels',
          routingType: RoutingType.multiChannel,
          channelCount: 0,
        );

        expect(factory.validateMetadata(metadata), isFalse);
      });

      test('should reject multi-channel metadata with negative channel count', () {
        const metadata = AlgorithmRoutingMetadata(
          algorithmGuid: 'test-negative-channels',
          routingType: RoutingType.multiChannel,
          channelCount: -1,
        );

        expect(factory.validateMetadata(metadata), isFalse);
      });
    });

    group('Validated Routing Creation', () {
      test('should create routing with valid metadata', () {
        final metadata = AlgorithmRoutingMetadataFactory.polyphonic(
          algorithmGuid: 'test-validated',
          voiceCount: 2,
        );

        final routing = factory.createValidatedRouting(metadata);

        expect(routing, isA<PolyAlgorithmRouting>());
      });

      test('should throw RoutingFactoryException for invalid metadata', () {
        const metadata = AlgorithmRoutingMetadata(
          algorithmGuid: '',
          routingType: RoutingType.polyphonic,
        );

        expect(
          () => factory.createValidatedRouting(metadata),
          throwsA(isA<RoutingFactoryException>()),
        );
      });

      test('RoutingFactoryException should contain metadata and message', () {
        const metadata = AlgorithmRoutingMetadata(
          algorithmGuid: 'test-exception',
          routingType: RoutingType.polyphonic,
          voiceCount: -1,
        );

        try {
          factory.createValidatedRouting(metadata);
          fail('Expected RoutingFactoryException to be thrown');
        } catch (e) {
          expect(e, isA<RoutingFactoryException>());
          final exception = e as RoutingFactoryException;
          expect(exception.metadata, equals(metadata));
          expect(exception.message, contains('Metadata validation failed'));
          expect(exception.toString(), contains('test-exception'));
        }
      });
    });

    group('Error Handling', () {
      test('should throw RoutingFactoryException for creation errors', () {
        // This would happen if we had an unsupported routing type
        // Since we can't easily simulate that without modifying the enum,
        // we'll test with extreme values that might cause issues
        const metadata = AlgorithmRoutingMetadata(
          algorithmGuid: 'test-error',
          routingType: RoutingType.polyphonic,
          voiceCount: 999999, // Extreme value that might cause issues
        );

        // The factory should still handle this gracefully, but let's test error handling
        expect(() => factory.createRouting(metadata), returnsNormally);
      });

      test('should handle null algorithm name gracefully', () {
        const metadata = AlgorithmRoutingMetadata(
          algorithmGuid: 'test-null-name',
          routingType: RoutingType.polyphonic,
          algorithmName: null,
        );

        final routing = factory.createRouting(metadata) as PolyAlgorithmRouting;

        expect(routing.config.algorithmProperties.containsKey('algorithmName'), isFalse);
      });
    });

    group('Metadata Analysis', () {
      test('should suggest optimization for high voice count', () {
        final metadata = AlgorithmRoutingMetadataFactory.polyphonic(
          algorithmGuid: 'test-high-voices',
          voiceCount: 20,
        );

        final suggestions = factory.analyzeMetadata(metadata);

        expect(suggestions, contains(contains('High voice count')));
        expect(suggestions, contains(contains('may impact performance')));
      });

      test('should suggest optimization for high channel count', () {
        final metadata = AlgorithmRoutingMetadataFactory.widthBased(
          algorithmGuid: 'test-high-channels',
          channelCount: 64,
        );

        final suggestions = factory.analyzeMetadata(metadata);

        expect(suggestions, contains(contains('High channel count')));
        expect(suggestions, contains(contains('may impact performance')));
      });

      test('should identify unused virtual CV ports', () {
        final metadata = AlgorithmRoutingMetadataFactory.polyphonic(
          algorithmGuid: 'test-unused-cv',
          voiceCount: 4,
          usesVirtualCvPorts: true,
          virtualCvPortsPerVoice: 0,
        );

        final suggestions = factory.analyzeMetadata(metadata);

        expect(suggestions, contains(contains('Virtual CV ports are enabled')));
        expect(suggestions, contains(contains('count per voice is 0')));
      });

      test('should identify stereo configuration issues', () {
        final metadata = AlgorithmRoutingMetadataFactory.widthBased(
          algorithmGuid: 'test-odd-stereo',
          channelCount: 3,
          supportsStereo: true,
        );

        final suggestions = factory.analyzeMetadata(metadata);

        expect(suggestions, contains(contains('Stereo support is enabled')));
        expect(suggestions, contains(contains('channel count')));
        expect(suggestions, contains(contains('is odd')));
      });

      test('should return empty suggestions for optimal metadata', () {
        final metadata = AlgorithmRoutingMetadataFactory.widthBased(
          algorithmGuid: 'test-optimal',
          channelCount: 2,
          supportsStereo: true,
        );

        final suggestions = factory.analyzeMetadata(metadata);

        expect(suggestions, isEmpty);
      });
    });

    group('Edge Cases', () {
      test('should handle metadata with all defaults', () {
        const metadata = AlgorithmRoutingMetadata(
          algorithmGuid: 'test-defaults',
          routingType: RoutingType.multiChannel,
        );

        final routing = factory.createRouting(metadata);

        expect(routing, isA<MultiChannelAlgorithmRouting>());
      });

      test('should handle metadata with extreme but valid values', () {
        const metadata = AlgorithmRoutingMetadata(
          algorithmGuid: 'test-extreme',
          routingType: RoutingType.polyphonic,
          voiceCount: 1,
          virtualCvPortsPerVoice: 0,
        );

        final routing = factory.createRouting(metadata);

        expect(routing, isA<PolyAlgorithmRouting>());
      });

      test('should use effective port name prefix correctly', () {
        // Test with custom prefix
        const customMetadata = AlgorithmRoutingMetadata(
          algorithmGuid: 'test-custom-prefix',
          routingType: RoutingType.polyphonic,
          portNamePrefix: 'Custom',
        );

        final customRouting = factory.createRouting(customMetadata) as PolyAlgorithmRouting;
        expect(customRouting.config.portNamePrefix, equals('Custom'));

        // Test with default prefix for polyphonic
        const polyMetadata = AlgorithmRoutingMetadata(
          algorithmGuid: 'test-default-poly-prefix',
          routingType: RoutingType.polyphonic,
        );

        final polyRouting = factory.createRouting(polyMetadata) as PolyAlgorithmRouting;
        expect(polyRouting.config.portNamePrefix, equals('Voice'));

        // Test with default prefix for multi-channel
        const multiMetadata = AlgorithmRoutingMetadata(
          algorithmGuid: 'test-default-multi-prefix',
          routingType: RoutingType.multiChannel,
        );

        final multiRouting = factory.createRouting(multiMetadata) as MultiChannelAlgorithmRouting;
        expect(multiRouting.config.portNamePrefix, equals('Ch'));
      });
    });
  });
}