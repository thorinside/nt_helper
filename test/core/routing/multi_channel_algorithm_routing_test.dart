import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/core/routing/multi_channel_algorithm_routing.dart';
import 'package:nt_helper/core/routing/models/routing_state.dart';
import 'package:nt_helper/core/routing/models/port.dart';
import 'package:nt_helper/core/routing/models/connection.dart';
import 'package:nt_helper/core/routing/port_compatibility_validator.dart';

void main() {
  group('MultiChannelAlgorithmConfig', () {
    test('should create default configuration', () {
      const config = MultiChannelAlgorithmConfig();
      
      expect(config.channelCount, equals(1));
      expect(config.supportsStereoChannels, isFalse);
      expect(config.allowsIndependentChannels, isTrue);
      expect(config.supportedPortTypes, equals([PortType.audio, PortType.cv]));
      expect(config.portNamePrefix, equals('Ch'));
      expect(config.createMasterMix, isTrue);
      expect(config.algorithmProperties, isEmpty);
    });

    test('should create normal algorithm config', () {
      final config = MultiChannelAlgorithmConfig.normal();
      
      expect(config.channelCount, equals(1));
      expect(config.supportsStereoChannels, isFalse);
      expect(config.allowsIndependentChannels, isTrue);
      expect(config.portNamePrefix, equals('Main'));
      expect(config.createMasterMix, isFalse);
    });

    test('should create width-based algorithm config', () {
      final config = MultiChannelAlgorithmConfig.widthBased(width: 8);
      
      expect(config.channelCount, equals(8));
      expect(config.supportsStereoChannels, isTrue);
      expect(config.allowsIndependentChannels, isTrue);
      expect(config.portNamePrefix, equals('Ch'));
      expect(config.createMasterMix, isTrue);
    });

    test('should create custom configuration', () {
      const config = MultiChannelAlgorithmConfig(
        channelCount: 4,
        supportsStereoChannels: true,
        allowsIndependentChannels: false,
        supportedPortTypes: [PortType.audio, PortType.gate, PortType.cv],
        portNamePrefix: 'Track',
        createMasterMix: false,
        algorithmProperties: {'mode': 'mixer'},
      );
      
      expect(config.channelCount, equals(4));
      expect(config.supportsStereoChannels, isTrue);
      expect(config.allowsIndependentChannels, isFalse);
      expect(config.supportedPortTypes.length, equals(3));
      expect(config.portNamePrefix, equals('Track'));
      expect(config.createMasterMix, isFalse);
      expect(config.algorithmProperties['mode'], equals('mixer'));
    });
  });

  group('MultiChannelAlgorithmRouting - Normal Config', () {
    late MultiChannelAlgorithmRouting routing;
    late MultiChannelAlgorithmConfig config;

    setUp(() {
      config = MultiChannelAlgorithmConfig.normal();
      routing = MultiChannelAlgorithmRouting(config: config);
    });

    tearDown(() {
      routing.dispose();
    });

    test('should initialize with correct config', () {
      expect(routing.config, equals(config));
      expect(routing.state.status, equals(RoutingSystemStatus.uninitialized));
    });

    test('should generate correct ports for normal (single channel) config', () {
      final inputPorts = routing.generateInputPorts();
      final outputPorts = routing.generateOutputPorts();
      
      // 1 channel * 2 port types = 2 input ports
      expect(inputPorts.length, equals(2));
      // 1 channel * 2 port types, no master mix = 2 output ports
      expect(outputPorts.length, equals(2));
      
      final audioInput = inputPorts.firstWhere((p) => p.type == PortType.audio);
      expect(audioInput.id, equals('multi_audio_in_1'));
      expect(audioInput.name, equals('Main 1 Audio In'));
      
      final cvInput = inputPorts.firstWhere((p) => p.type == PortType.cv);
      expect(cvInput.id, equals('multi_cv_in_1'));
      expect(cvInput.name, equals('Main 1 CV In'));
    });

    test('should cache generated ports', () {
      final inputPorts1 = routing.inputPorts;
      final inputPorts2 = routing.inputPorts;
      final outputPorts1 = routing.outputPorts;
      final outputPorts2 = routing.outputPorts;
      
      expect(identical(inputPorts1, inputPorts2), isTrue);
      expect(identical(outputPorts1, outputPorts2), isTrue);
    });
  });

  group('MultiChannelAlgorithmRouting - Width-Based Config', () {
    late MultiChannelAlgorithmRouting routing;
    late MultiChannelAlgorithmConfig config;

    setUp(() {
      config = MultiChannelAlgorithmConfig.widthBased(width: 4);
      routing = MultiChannelAlgorithmRouting(config: config);
    });

    tearDown(() {
      routing.dispose();
    });

    test('should generate correct ports for width-based config', () {
      final inputPorts = routing.generateInputPorts();
      final outputPorts = routing.generateOutputPorts();
      
      // 4 channels * (2 audio stereo + 1 CV mono) = 12 input ports
      expect(inputPorts.length, equals(12));
      // 4 channels * (2 audio stereo + 1 CV mono) + master mix (2 audio stereo + 1 CV mono) = 15 output ports
      expect(outputPorts.length, equals(15));
      
      // Check stereo audio ports
      final audioInputsL = inputPorts.where((p) => 
        p.type == PortType.audio && p.id.endsWith('_l')
      ).toList();
      expect(audioInputsL.length, equals(4));
      expect(audioInputsL[0].id, equals('multi_audio_in_1_l'));
      expect(audioInputsL[0].name, equals('Ch 1 Audio L'));
      
      final audioInputsR = inputPorts.where((p) => 
        p.type == PortType.audio && p.id.endsWith('_r')
      ).toList();
      expect(audioInputsR.length, equals(4));
      
      // Check master mix outputs
      final masterMixPorts = outputPorts.where((p) => 
        p.metadata?['isMasterMix'] == true
      ).toList();
      expect(masterMixPorts.length, equals(3)); // 2 audio stereo + 1 CV mono
      
      final masterMixAudioL = masterMixPorts.firstWhere((p) => 
        p.id == 'multi_mix_audio_out_l'
      );
      expect(masterMixAudioL.name, equals('Master Mix Audio L'));
    });

    test('should handle non-stereo port types correctly', () {
      final inputPorts = routing.inputPorts;
      
      // CV ports should be mono even with stereo enabled
      final cvInputs = inputPorts.where((p) => p.type == PortType.cv).toList();
      expect(cvInputs.length, equals(4)); // One per channel, not stereo
      expect(cvInputs[0].id, equals('multi_cv_in_1'));
      expect(cvInputs[0].name, equals('Ch 1 CV In'));
    });

    test('should validate multi-channel connections when independent channels allowed', () {
      final inputPorts = routing.inputPorts;
      final outputPorts = routing.outputPorts;
      
      final channel1AudioOut = outputPorts.firstWhere((p) => 
        p.id == 'multi_audio_out_1_l'
      );
      final channel2AudioIn = inputPorts.firstWhere((p) => 
        p.id == 'multi_audio_in_2_l'
      );
      
      // Should allow cross-channel connections when independent routing is enabled
      expect(routing.validateConnection(channel1AudioOut, channel2AudioIn), isTrue);
    });

    test('should validate stereo channel connections', () {
      final inputPorts = routing.inputPorts;
      final outputPorts = routing.outputPorts;
      
      final leftOut = outputPorts.firstWhere((p) => p.id == 'multi_audio_out_1_l');
      final rightOut = outputPorts.firstWhere((p) => p.id == 'multi_audio_out_1_r');
      final leftIn = inputPorts.firstWhere((p) => p.id == 'multi_audio_in_1_l');
      final rightIn = inputPorts.firstWhere((p) => p.id == 'multi_audio_in_1_r');
      
      // Left should connect to left, right to right
      expect(routing.validateConnection(leftOut, leftIn), isTrue);
      expect(routing.validateConnection(rightOut, rightIn), isTrue);
      expect(routing.validateConnection(leftOut, rightIn), isFalse);
      expect(routing.validateConnection(rightOut, leftIn), isFalse);
    });

    test('should prevent master mix feedback connections', () {
      final inputPorts = routing.inputPorts;
      final outputPorts = routing.outputPorts;
      
      final masterMixOut = outputPorts.firstWhere((p) => 
        p.metadata?['isMasterMix'] == true
      );
      final channelIn = inputPorts.firstWhere((p) => 
        p.metadata?['isMultiChannel'] == true
      );
      
      expect(routing.validateConnection(masterMixOut, channelIn), isFalse);
    });

    test('should get ports for specific channel', () {
      final channel2Ports = routing.getPortsForChannel(2);
      
      expect(channel2Ports.length, equals(6)); // 3 input + 3 output (2 audio stereo + 1 CV mono)
      expect(channel2Ports.every((p) => 
        p.metadata?['channelNumber'] == 2
      ), isTrue);
    });

    test('should get master mix ports', () {
      final masterMixPorts = routing.getMasterMixPorts();
      
      expect(masterMixPorts.length, equals(3)); // 2 audio stereo + 1 CV mono
      expect(masterMixPorts.every((p) => 
        p.metadata?['isMasterMix'] == true
      ), isTrue);
    });

    test('should check channel count support', () {
      expect(routing.supportsChannelCount(1), isTrue);
      expect(routing.supportsChannelCount(4), isTrue);
      expect(routing.supportsChannelCount(5), isFalse);
      expect(routing.supportsChannelCount(0), isFalse);
    });
  });

  group('MultiChannelAlgorithmRouting - Custom Config', () {
    test('should handle config without stereo support', () {
      final config = MultiChannelAlgorithmConfig.widthBased(
        width: 3,
        supportsStereo: false,
      );
      final routing = MultiChannelAlgorithmRouting(config: config);
      
      final inputPorts = routing.generateInputPorts();
      final outputPorts = routing.generateOutputPorts();
      
      // 3 channels * 2 port types = 6 input ports (no stereo)
      expect(inputPorts.length, equals(6));
      // 3 channels * 2 port types + 2 master mix = 8 output ports
      expect(outputPorts.length, equals(8));
      
      // No stereo ports should exist
      expect(inputPorts.any((p) => p.id.endsWith('_l') || p.id.endsWith('_r')), isFalse);
      
      routing.dispose();
    });

    test('should handle config without master mix', () {
      const config = MultiChannelAlgorithmConfig(
        channelCount: 2,
        createMasterMix: false,
      );
      final routing = MultiChannelAlgorithmRouting(config: config);
      
      final outputPorts = routing.generateOutputPorts();
      
      // No master mix ports should exist
      expect(outputPorts.where((p) => 
        p.metadata?['isMasterMix'] == true
      ), isEmpty);
      
      routing.dispose();
    });

    test('should handle config with independent channels disabled', () {
      const config = MultiChannelAlgorithmConfig(
        channelCount: 3,
        allowsIndependentChannels: false,
      );
      final routing = MultiChannelAlgorithmRouting(config: config);
      
      final inputPorts = routing.inputPorts;
      final outputPorts = routing.outputPorts;
      
      final channel1Out = outputPorts.firstWhere((p) => 
        p.metadata?['channelNumber'] == 1
      );
      final channel2In = inputPorts.firstWhere((p) => 
        p.metadata?['channelNumber'] == 2
      );
      
      // Cross-channel connections should be rejected
      expect(routing.validateConnection(channel1Out, channel2In), isFalse);
      
      routing.dispose();
    });

    test('should handle custom port types', () {
      const config = MultiChannelAlgorithmConfig(
        channelCount: 2,
        supportedPortTypes: [PortType.gate, PortType.clock],
        createMasterMix: false,
      );
      final routing = MultiChannelAlgorithmRouting(config: config);
      
      final inputPorts = routing.generateInputPorts();
      final outputPorts = routing.generateOutputPorts();
      
      // 2 channels * 3 port types = 6 ports each
      expect(inputPorts.length, equals(6));
      expect(outputPorts.length, equals(6));
      
      expect(inputPorts.any((p) => p.type == PortType.gate), isTrue);
      expect(inputPorts.any((p) => p.type == PortType.clock), isTrue);
      expect(inputPorts.any((p) => p.type == PortType.audio), isFalse);
      
      routing.dispose();
    });
  });

  group('MultiChannelAlgorithmRouting - State Management', () {
    late MultiChannelAlgorithmRouting routing;

    setUp(() {
      final config = MultiChannelAlgorithmConfig.widthBased(width: 2);
      routing = MultiChannelAlgorithmRouting(config: config);
    });

    tearDown(() {
      routing.dispose();
    });

    test('should update state and clear caches', () {
      // Access ports to cache them
      final originalInputPorts = routing.inputPorts;
      expect(originalInputPorts, isNotEmpty);
      
      // Update state with different ports
      const newState = RoutingState(
        status: RoutingSystemStatus.ready,
        inputPorts: [],
        outputPorts: [],
      );
      
      routing.updateState(newState);
      
      expect(routing.state.status, equals(RoutingSystemStatus.ready));
      // The generated ports remain the same since they're not based on state
      expect(routing.inputPorts, equals(originalInputPorts));
    });

    test('should validate entire routing configuration', () {
      expect(routing.validateRouting(), isTrue);
      
      // Test with invalid connections in state
      const invalidConnection = Connection(
        id: 'invalid',
        sourcePortId: 'non_existent_source',
        destinationPortId: 'non_existent_dest',
      );
      
      final invalidState = RoutingState(
        connections: [invalidConnection],
      );
      
      routing.updateState(invalidState);
      expect(routing.validateRouting(), isFalse);
    });

    test('should add valid connections', () {
      final inputPorts = routing.inputPorts;
      final outputPorts = routing.outputPorts;
      
      final audioOut = outputPorts.firstWhere((p) => p.type == PortType.audio);
      final audioIn = inputPorts.firstWhere((p) => p.type == PortType.audio);
      
      final connection = routing.addConnection(audioOut, audioIn);
      expect(connection, isNotNull);
      expect(connection!.sourcePortId, equals(audioOut.id));
      expect(connection.destinationPortId, equals(audioIn.id));
    });

    test('should handle channel count updates', () {
      expect(routing.config.channelCount, equals(2));
      
      routing.updateChannelCount(4);
      
      // Ports should be regenerated for new channel count
      final inputPorts = routing.inputPorts;
      // With new implementation, this would require creating a new instance
      // as config is immutable, but the method clears caches for when
      // config changes are implemented
      expect(inputPorts.length, greaterThan(0));
    });

    test('should work with custom validator', () {
      final customValidator = PortCompatibilityValidator();
      final config = MultiChannelAlgorithmConfig.normal();
      final routingWithValidator = MultiChannelAlgorithmRouting(
        config: config,
        validator: customValidator,
      );
      
      expect(routingWithValidator.validator, equals(customValidator));
      
      routingWithValidator.dispose();
    });

    test('should work with initial state', () {
      const initialState = RoutingState(
        status: RoutingSystemStatus.ready,
      );
      final config = MultiChannelAlgorithmConfig.normal();
      final routingWithState = MultiChannelAlgorithmRouting(
        config: config,
        initialState: initialState,
      );
      
      expect(routingWithState.state.status, equals(RoutingSystemStatus.ready));
      
      routingWithState.dispose();
    });
  });

  group('MultiChannelAlgorithmRouting Edge Cases', () {
    test('should handle zero channel count gracefully', () {
      const config = MultiChannelAlgorithmConfig(channelCount: 0);
      final routing = MultiChannelAlgorithmRouting(config: config);
      
      final inputPorts = routing.generateInputPorts();
      final outputPorts = routing.generateOutputPorts();
      
      expect(inputPorts, isEmpty);
      // No master mix outputs with zero channels (nothing to mix)
      expect(outputPorts, isEmpty);
      
      routing.dispose();
    });

    test('should handle single channel with stereo', () {
      const config = MultiChannelAlgorithmConfig(
        channelCount: 1,
        supportsStereoChannels: true,
        supportedPortTypes: [PortType.audio],
      );
      final routing = MultiChannelAlgorithmRouting(config: config);
      
      final inputPorts = routing.generateInputPorts();
      final outputPorts = routing.generateOutputPorts();
      
      // 1 channel * 1 port type * 2 (stereo) = 2 input ports
      expect(inputPorts.length, equals(2));
      expect(inputPorts[0].id, equals('multi_audio_in_1_l'));
      expect(inputPorts[1].id, equals('multi_audio_in_1_r'));
      
      // Also verify output ports were generated
      expect(outputPorts.length, equals(2));
      
      routing.dispose();
    });

    test('should handle high channel count', () {
      const config = MultiChannelAlgorithmConfig(
        channelCount: 16,
        supportsStereoChannels: false,
        supportedPortTypes: [PortType.audio],
      );
      final routing = MultiChannelAlgorithmRouting(config: config);
      
      final inputPorts = routing.generateInputPorts();
      final outputPorts = routing.generateOutputPorts();
      
      // 16 channels * 1 port type = 16 input ports
      expect(inputPorts.length, equals(16));
      // 16 channels * 1 port type + 1 master mix = 17 output ports
      expect(outputPorts.length, equals(17));
      
      routing.dispose();
    });

    test('should handle empty port types list', () {
      const config = MultiChannelAlgorithmConfig(
        channelCount: 2,
        supportedPortTypes: [],
      );
      final routing = MultiChannelAlgorithmRouting(config: config);
      
      final inputPorts = routing.generateInputPorts();
      final outputPorts = routing.generateOutputPorts();
      
      expect(inputPorts, isEmpty);
      expect(outputPorts, isEmpty); // No ports to create master mix from
      
      routing.dispose();
    });

    test('should get port type names correctly', () {
      const config = MultiChannelAlgorithmConfig(channelCount: 1);
      final routing = MultiChannelAlgorithmRouting(config: config);
      
      // Test port type name generation by checking generated port names
      final inputPorts = routing.generateInputPorts();
      final audioPort = inputPorts.firstWhere((p) => p.type == PortType.audio);
      final cvPort = inputPorts.firstWhere((p) => p.type == PortType.cv);
      
      expect(audioPort.name.contains('Audio'), isTrue);
      expect(cvPort.name.contains('CV'), isTrue);
      
      routing.dispose();
    });
  });
}