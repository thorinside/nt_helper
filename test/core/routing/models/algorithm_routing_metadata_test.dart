import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/core/routing/models/algorithm_routing_metadata.dart';

void main() {
  group('AlgorithmRoutingMetadata', () {
    group('Construction', () {
      test('should create with required fields only', () {
        const metadata = AlgorithmRoutingMetadata(
          algorithmGuid: 'test-algorithm',
          routingType: RoutingType.polyphonic,
        );

        expect(metadata.algorithmGuid, equals('test-algorithm'));
        expect(metadata.routingType, equals(RoutingType.polyphonic));
        expect(metadata.voiceCount, equals(1)); // default
        expect(metadata.channelCount, equals(1)); // default
        expect(metadata.requiresGateInputs, isFalse); // default
        expect(metadata.usesVirtualCvPorts, isFalse); // default
        expect(metadata.customProperties, isEmpty);
        expect(metadata.routingConstraints, isEmpty);
      });

      test('should create with all fields specified', () {
        final customProps = {'testProp': 'value'};
        final constraints = {'maxConnections': 8};
        
        final metadata = AlgorithmRoutingMetadata(
          algorithmGuid: 'complex-algorithm',
          routingType: RoutingType.multiChannel,
          algorithmName: 'Complex Algorithm',
          voiceCount: 4,
          requiresGateInputs: true,
          usesVirtualCvPorts: true,
          virtualCvPortsPerVoice: 3,
          channelCount: 2,
          supportsStereo: true,
          allowsIndependentChannels: false,
          createMasterMix: false,
          supportedPortTypes: ['audio', 'cv', 'gate'],
          portNamePrefix: 'Custom',
          customProperties: customProps,
          routingConstraints: constraints,
        );

        expect(metadata.algorithmGuid, equals('complex-algorithm'));
        expect(metadata.routingType, equals(RoutingType.multiChannel));
        expect(metadata.algorithmName, equals('Complex Algorithm'));
        expect(metadata.voiceCount, equals(4));
        expect(metadata.requiresGateInputs, isTrue);
        expect(metadata.usesVirtualCvPorts, isTrue);
        expect(metadata.virtualCvPortsPerVoice, equals(3));
        expect(metadata.channelCount, equals(2));
        expect(metadata.supportsStereo, isTrue);
        expect(metadata.allowsIndependentChannels, isFalse);
        expect(metadata.createMasterMix, isFalse);
        expect(metadata.supportedPortTypes, equals(['audio', 'cv', 'gate']));
        expect(metadata.portNamePrefix, equals('Custom'));
        expect(metadata.customProperties, equals(customProps));
        expect(metadata.routingConstraints, equals(constraints));
      });
    });

    group('Extension Methods', () {
      test('isPolyphonic should return correct value', () {
        const polyMetadata = AlgorithmRoutingMetadata(
          algorithmGuid: 'poly-test',
          routingType: RoutingType.polyphonic,
        );
        
        const multiMetadata = AlgorithmRoutingMetadata(
          algorithmGuid: 'multi-test',
          routingType: RoutingType.multiChannel,
        );

        expect(polyMetadata.isPolyphonic, isTrue);
        expect(polyMetadata.isMultiChannel, isFalse);
        expect(multiMetadata.isPolyphonic, isFalse);
        expect(multiMetadata.isMultiChannel, isTrue);
      });

      test('hasMultipleChannelsOrVoices should work correctly', () {
        const singleVoicePoly = AlgorithmRoutingMetadata(
          algorithmGuid: 'mono-poly',
          routingType: RoutingType.polyphonic,
          voiceCount: 1,
        );
        
        const multiVoicePoly = AlgorithmRoutingMetadata(
          algorithmGuid: 'multi-poly',
          routingType: RoutingType.polyphonic,
          voiceCount: 4,
        );
        
        const singleChannelMulti = AlgorithmRoutingMetadata(
          algorithmGuid: 'mono-multi',
          routingType: RoutingType.multiChannel,
          channelCount: 1,
        );
        
        const multiChannelMulti = AlgorithmRoutingMetadata(
          algorithmGuid: 'stereo-multi',
          routingType: RoutingType.multiChannel,
          channelCount: 2,
        );

        expect(singleVoicePoly.hasMultipleChannelsOrVoices, isFalse);
        expect(multiVoicePoly.hasMultipleChannelsOrVoices, isTrue);
        expect(singleChannelMulti.hasMultipleChannelsOrVoices, isFalse);
        expect(multiChannelMulti.hasMultipleChannelsOrVoices, isTrue);
      });

      test('effectivePortNamePrefix should provide fallbacks', () {
        const polyWithPrefix = AlgorithmRoutingMetadata(
          algorithmGuid: 'poly-with-prefix',
          routingType: RoutingType.polyphonic,
          portNamePrefix: 'Custom',
        );
        
        const polyWithoutPrefix = AlgorithmRoutingMetadata(
          algorithmGuid: 'poly-no-prefix',
          routingType: RoutingType.polyphonic,
        );
        
        const multiWithoutPrefix = AlgorithmRoutingMetadata(
          algorithmGuid: 'multi-no-prefix',
          routingType: RoutingType.multiChannel,
        );

        expect(polyWithPrefix.effectivePortNamePrefix, equals('Custom'));
        expect(polyWithoutPrefix.effectivePortNamePrefix, equals('Voice'));
        expect(multiWithoutPrefix.effectivePortNamePrefix, equals('Ch'));
      });

      test('getConstraint should work with type casting', () {
        const metadata = AlgorithmRoutingMetadata(
          algorithmGuid: 'test-constraints',
          routingType: RoutingType.polyphonic,
          routingConstraints: {
            'maxConnections': 8,
            'requiresClockInput': true,
            'latencyMs': 5.5,
            'name': 'TestAlgo',
          },
        );

        expect(metadata.getConstraint<int>('maxConnections'), equals(8));
        expect(metadata.getConstraint<bool>('requiresClockInput'), isTrue);
        expect(metadata.getConstraint<double>('latencyMs'), equals(5.5));
        expect(metadata.getConstraint<String>('name'), equals('TestAlgo'));
        
        // Wrong type should return null
        expect(metadata.getConstraint<String>('maxConnections'), isNull);
        expect(metadata.getConstraint<int>('requiresClockInput'), isNull);
        
        // Non-existent key should return null
        expect(metadata.getConstraint<int>('nonExistent'), isNull);
      });

      test('getCustomProperty should work with type casting', () {
        const metadata = AlgorithmRoutingMetadata(
          algorithmGuid: 'test-custom',
          routingType: RoutingType.multiChannel,
          customProperties: {
            'bufferSize': 1024,
            'useHighQuality': true,
            'sampleRate': 48000.0,
            'algorithmVersion': '2.1.0',
          },
        );

        expect(metadata.getCustomProperty<int>('bufferSize'), equals(1024));
        expect(metadata.getCustomProperty<bool>('useHighQuality'), isTrue);
        expect(metadata.getCustomProperty<double>('sampleRate'), equals(48000.0));
        expect(metadata.getCustomProperty<String>('algorithmVersion'), equals('2.1.0'));
        
        // Wrong type should return null
        expect(metadata.getCustomProperty<String>('bufferSize'), isNull);
        expect(metadata.getCustomProperty<int>('useHighQuality'), isNull);
        
        // Non-existent key should return null
        expect(metadata.getCustomProperty<int>('nonExistent'), isNull);
      });

      test('needsGateSupport should detect gate requirements', () {
        const explicitGates = AlgorithmRoutingMetadata(
          algorithmGuid: 'explicit-gates',
          routingType: RoutingType.polyphonic,
          requiresGateInputs: true,
        );
        
        const gatesInPortTypes = AlgorithmRoutingMetadata(
          algorithmGuid: 'gates-in-ports',
          routingType: RoutingType.multiChannel,
          supportedPortTypes: ['audio', 'gate'],
        );
        
        const clockConstraint = AlgorithmRoutingMetadata(
          algorithmGuid: 'clock-constraint',
          routingType: RoutingType.polyphonic,
          routingConstraints: {'requiresClockInput': true},
        );
        
        const noGates = AlgorithmRoutingMetadata(
          algorithmGuid: 'no-gates',
          routingType: RoutingType.multiChannel,
          supportedPortTypes: ['audio', 'cv'],
        );

        expect(explicitGates.needsGateSupport, isTrue);
        expect(gatesInPortTypes.needsGateSupport, isTrue);
        expect(clockConstraint.needsGateSupport, isTrue);
        expect(noGates.needsGateSupport, isFalse);
      });

      test('usesCvModulation should detect CV usage', () {
        const explicitCv = AlgorithmRoutingMetadata(
          algorithmGuid: 'explicit-cv',
          routingType: RoutingType.polyphonic,
          usesVirtualCvPorts: true,
        );
        
        const cvInPortTypes = AlgorithmRoutingMetadata(
          algorithmGuid: 'cv-in-ports',
          routingType: RoutingType.multiChannel,
          supportedPortTypes: ['audio', 'cv'],
        );
        
        const noCv = AlgorithmRoutingMetadata(
          algorithmGuid: 'no-cv',
          routingType: RoutingType.multiChannel,
          supportedPortTypes: ['audio'],
        );

        expect(explicitCv.usesCvModulation, isTrue);
        expect(cvInPortTypes.usesCvModulation, isTrue);
        expect(noCv.usesCvModulation, isFalse);
      });

      test('totalPortUnits should return correct count', () {
        const polyMetadata = AlgorithmRoutingMetadata(
          algorithmGuid: 'poly-test',
          routingType: RoutingType.polyphonic,
          voiceCount: 8,
        );
        
        const multiMetadata = AlgorithmRoutingMetadata(
          algorithmGuid: 'multi-test',
          routingType: RoutingType.multiChannel,
          channelCount: 4,
        );

        expect(polyMetadata.totalPortUnits, equals(8));
        expect(multiMetadata.totalPortUnits, equals(4));
      });
    });

    group('Factory Methods', () {
      test('polyphonic factory should create correct metadata', () {
        final metadata = AlgorithmRoutingMetadataFactory.polyphonic(
          algorithmGuid: 'test-poly',
          algorithmName: 'Test Polyphonic',
          voiceCount: 6,
          requiresGateInputs: false,
          usesVirtualCvPorts: false,
          virtualCvPortsPerVoice: 1,
          portNamePrefix: 'Osc',
          supportedPortTypes: ['audio', 'gate'],
          customProperties: {'testProp': 'value'},
          routingConstraints: {'maxConnections': 12},
        );

        expect(metadata.algorithmGuid, equals('test-poly'));
        expect(metadata.algorithmName, equals('Test Polyphonic'));
        expect(metadata.routingType, equals(RoutingType.polyphonic));
        expect(metadata.voiceCount, equals(6));
        expect(metadata.requiresGateInputs, isFalse);
        expect(metadata.usesVirtualCvPorts, isFalse);
        expect(metadata.virtualCvPortsPerVoice, equals(1));
        expect(metadata.portNamePrefix, equals('Osc'));
        expect(metadata.supportedPortTypes, equals(['audio', 'gate']));
        expect(metadata.customProperties, equals({'testProp': 'value'}));
        expect(metadata.routingConstraints, equals({'maxConnections': 12}));
      });

      test('normal factory should create correct metadata', () {
        final metadata = AlgorithmRoutingMetadataFactory.normal(
          algorithmGuid: 'test-normal',
          algorithmName: 'Test Normal',
          portNamePrefix: 'Input',
          supportedPortTypes: ['audio'],
          customProperties: {'mono': true},
          routingConstraints: {'bypassable': true},
        );

        expect(metadata.algorithmGuid, equals('test-normal'));
        expect(metadata.algorithmName, equals('Test Normal'));
        expect(metadata.routingType, equals(RoutingType.multiChannel));
        expect(metadata.channelCount, equals(1));
        expect(metadata.supportsStereo, isFalse);
        expect(metadata.createMasterMix, isFalse);
        expect(metadata.portNamePrefix, equals('Input'));
        expect(metadata.supportedPortTypes, equals(['audio']));
        expect(metadata.customProperties, equals({'mono': true}));
        expect(metadata.routingConstraints, equals({'bypassable': true}));
      });

      test('widthBased factory should create correct metadata', () {
        final metadata = AlgorithmRoutingMetadataFactory.widthBased(
          algorithmGuid: 'test-width',
          algorithmName: 'Test Width-Based',
          channelCount: 8,
          supportsStereo: false,
          allowsIndependentChannels: false,
          createMasterMix: false,
          portNamePrefix: 'Band',
          supportedPortTypes: ['audio', 'cv', 'gate'],
          customProperties: {'eqBands': 8},
          routingConstraints: {'requiresAnalysis': true},
        );

        expect(metadata.algorithmGuid, equals('test-width'));
        expect(metadata.algorithmName, equals('Test Width-Based'));
        expect(metadata.routingType, equals(RoutingType.multiChannel));
        expect(metadata.channelCount, equals(8));
        expect(metadata.supportsStereo, isFalse);
        expect(metadata.allowsIndependentChannels, isFalse);
        expect(metadata.createMasterMix, isFalse);
        expect(metadata.portNamePrefix, equals('Band'));
        expect(metadata.supportedPortTypes, equals(['audio', 'cv', 'gate']));
        expect(metadata.customProperties, equals({'eqBands': 8}));
        expect(metadata.routingConstraints, equals({'requiresAnalysis': true}));
      });
    });

    group('JSON Serialization', () {
      test('should serialize and deserialize correctly', () {
        final original = AlgorithmRoutingMetadata(
          algorithmGuid: 'json-test',
          routingType: RoutingType.polyphonic,
          algorithmName: 'JSON Test Algorithm',
          voiceCount: 4,
          requiresGateInputs: true,
          usesVirtualCvPorts: true,
          virtualCvPortsPerVoice: 3,
          channelCount: 2,
          supportsStereo: true,
          allowsIndependentChannels: false,
          createMasterMix: true,
          supportedPortTypes: ['audio', 'cv', 'gate'],
          portNamePrefix: 'Test',
          customProperties: {
            'stringProp': 'value',
            'intProp': 42,
            'boolProp': true,
            'doubleProp': 3.14,
          },
          routingConstraints: {
            'maxConnections': 8,
            'requiresClockInput': false,
          },
        );

        final json = original.toJson();
        final restored = AlgorithmRoutingMetadata.fromJson(json);

        expect(restored.algorithmGuid, equals(original.algorithmGuid));
        expect(restored.routingType, equals(original.routingType));
        expect(restored.algorithmName, equals(original.algorithmName));
        expect(restored.voiceCount, equals(original.voiceCount));
        expect(restored.requiresGateInputs, equals(original.requiresGateInputs));
        expect(restored.usesVirtualCvPorts, equals(original.usesVirtualCvPorts));
        expect(restored.virtualCvPortsPerVoice, equals(original.virtualCvPortsPerVoice));
        expect(restored.channelCount, equals(original.channelCount));
        expect(restored.supportsStereo, equals(original.supportsStereo));
        expect(restored.allowsIndependentChannels, equals(original.allowsIndependentChannels));
        expect(restored.createMasterMix, equals(original.createMasterMix));
        expect(restored.supportedPortTypes, equals(original.supportedPortTypes));
        expect(restored.portNamePrefix, equals(original.portNamePrefix));
        expect(restored.customProperties, equals(original.customProperties));
        expect(restored.routingConstraints, equals(original.routingConstraints));
      });

      test('should handle missing optional fields in JSON', () {
        final json = {
          'algorithmGuid': 'minimal-test',
          'routingType': 'polyphonic',
        };

        final metadata = AlgorithmRoutingMetadata.fromJson(json);

        expect(metadata.algorithmGuid, equals('minimal-test'));
        expect(metadata.routingType, equals(RoutingType.polyphonic));
        expect(metadata.algorithmName, isNull);
        expect(metadata.voiceCount, equals(1)); // default
        expect(metadata.customProperties, isEmpty); // default
        expect(metadata.routingConstraints, isEmpty); // default
      });
    });

    group('Equality and Hash', () {
      test('should be equal for same content', () {
        const metadata1 = AlgorithmRoutingMetadata(
          algorithmGuid: 'equal-test',
          routingType: RoutingType.polyphonic,
          voiceCount: 4,
        );
        
        const metadata2 = AlgorithmRoutingMetadata(
          algorithmGuid: 'equal-test',
          routingType: RoutingType.polyphonic,
          voiceCount: 4,
        );

        expect(metadata1, equals(metadata2));
        expect(metadata1.hashCode, equals(metadata2.hashCode));
      });

      test('should not be equal for different content', () {
        const metadata1 = AlgorithmRoutingMetadata(
          algorithmGuid: 'test1',
          routingType: RoutingType.polyphonic,
        );
        
        const metadata2 = AlgorithmRoutingMetadata(
          algorithmGuid: 'test2',
          routingType: RoutingType.polyphonic,
        );

        expect(metadata1, isNot(equals(metadata2)));
      });
    });

    group('Edge Cases', () {
      test('should handle empty collections', () {
        const metadata = AlgorithmRoutingMetadata(
          algorithmGuid: 'empty-test',
          routingType: RoutingType.multiChannel,
          supportedPortTypes: [],
          customProperties: {},
          routingConstraints: {},
        );

        expect(metadata.supportedPortTypes, isEmpty);
        expect(metadata.customProperties, isEmpty);
        expect(metadata.routingConstraints, isEmpty);
        expect(metadata.getConstraint<int>('anything'), isNull);
        expect(metadata.getCustomProperty<String>('anything'), isNull);
      });

      test('should handle zero voice/channel counts', () {
        const metadata = AlgorithmRoutingMetadata(
          algorithmGuid: 'zero-test',
          routingType: RoutingType.polyphonic,
          voiceCount: 0,
          channelCount: 0,
        );

        expect(metadata.voiceCount, equals(0));
        expect(metadata.channelCount, equals(0));
        expect(metadata.hasMultipleChannelsOrVoices, isFalse);
        expect(metadata.totalPortUnits, equals(0));
      });
    });
  });
}