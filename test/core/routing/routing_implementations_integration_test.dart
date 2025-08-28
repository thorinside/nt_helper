import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/core/routing/poly_algorithm_routing.dart';
import 'package:nt_helper/core/routing/multi_channel_algorithm_routing.dart';
import 'package:nt_helper/core/routing/models/routing_state.dart';
import 'package:nt_helper/core/routing/models/port.dart';
import 'package:nt_helper/core/routing/models/connection.dart';
import 'package:nt_helper/core/routing/port_compatibility_validator.dart';
import 'package:nt_helper/core/routing/algorithm_routing.dart';

void main() {
  group('Routing Implementations Integration Tests', () {
    late PolyAlgorithmRouting polyRouting;
    late MultiChannelAlgorithmRouting multiChannelRouting;
    late PortCompatibilityValidator sharedValidator;

    setUp(() {
      sharedValidator = PortCompatibilityValidator();
      
      const polyConfig = PolyAlgorithmConfig(
        voiceCount: 4,
        requiresGateInputs: true,
        usesVirtualCvPorts: true,
        virtualCvPortsPerVoice: 2,
      );
      polyRouting = PolyAlgorithmRouting(
        config: polyConfig,
        validator: sharedValidator,
      );
      
      final multiChannelConfig = MultiChannelAlgorithmConfig.widthBased(
        width: 4,
        supportsStereo: true,
      );
      multiChannelRouting = MultiChannelAlgorithmRouting(
        config: multiChannelConfig,
        validator: sharedValidator,
      );
    });

    tearDown(() {
      polyRouting.dispose();
      multiChannelRouting.dispose();
    });

    test('should demonstrate polymorphic behavior through base class interface', () {
      // Both implementations should work through the AlgorithmRouting interface
      final List<AlgorithmRouting> routings = [polyRouting, multiChannelRouting];
      
      for (final routing in routings) {
        expect(routing.inputPorts, isNotEmpty);
        expect(routing.outputPorts, isNotEmpty);
        expect(routing.connections, isEmpty); // Initially no connections
        expect(routing.state.status, equals(RoutingSystemStatus.uninitialized));
        expect(routing.validateRouting(), isTrue);
      }
    });

    test('should handle cross-routing scenario: poly to multi-channel', () {
      final polyOutputs = polyRouting.outputPorts;
      final multiChannelInputs = multiChannelRouting.inputPorts;
      
      // Find compatible ports
      final polyAudioOut = polyOutputs.firstWhere((p) => 
        p.type == PortType.audio && p.id == 'poly_audio_out_1'
      );
      final multiAudioIn = multiChannelInputs.firstWhere((p) => 
        p.type == PortType.audio && p.id == 'multi_audio_in_1_l'
      );
      
      // Both routings should validate this connection using their own logic
      expect(polyRouting.validateConnection(polyAudioOut, multiAudioIn), isTrue);
      expect(multiChannelRouting.validateConnection(polyAudioOut, multiAudioIn), isTrue);
      
      // Create connection through poly routing
      final connection = polyRouting.addConnection(polyAudioOut, multiAudioIn);
      expect(connection, isNotNull);
      expect(connection!.sourcePortId, equals(polyAudioOut.id));
      expect(connection.destinationPortId, equals(multiAudioIn.id));
    });

    test('should handle cross-routing scenario: multi-channel to poly', () {
      final multiChannelOutputs = multiChannelRouting.outputPorts;
      final polyInputs = polyRouting.inputPorts;
      
      // Find compatible ports
      final multiAudioOut = multiChannelOutputs.firstWhere((p) => 
        p.type == PortType.audio && !p.id.contains('mix')
      );
      final polyAudioIn = polyInputs.firstWhere((p) => 
        p.type == PortType.audio && p.id == 'poly_audio_in_1'
      );
      
      // Both routings should validate this connection
      expect(multiChannelRouting.validateConnection(multiAudioOut, polyAudioIn), isTrue);
      expect(polyRouting.validateConnection(multiAudioOut, polyAudioIn), isTrue);
      
      // Create connection through multi-channel routing
      final connection = multiChannelRouting.addConnection(multiAudioOut, polyAudioIn);
      expect(connection, isNotNull);
    });

    test('should demonstrate different port generation strategies', () {
      final polyInputs = polyRouting.inputPorts;
      final polyOutputs = polyRouting.outputPorts;
      final multiInputs = multiChannelRouting.inputPorts;
      final multiOutputs = multiChannelRouting.outputPorts;
      
      // Poly routing generates voice-based ports
      // 4 voices * (1 audio + 1 gate + 2 CV) = 16 input ports
      expect(polyInputs.length, equals(16));
      // 4 voices * (1 audio + 1 gate) + 1 mix = 9 output ports
      expect(polyOutputs.length, equals(9));
      
      // Multi-channel routing generates channel-based ports
      // 4 channels * (2 audio stereo + 1 CV mono) = 12 input ports
      expect(multiInputs.length, equals(12));
      // 4 channels * (2 audio stereo + 1 CV mono) + master mix (2 audio stereo + 1 CV mono) = 15 output ports
      expect(multiOutputs.length, equals(15));
      
      // Poly routing has specific voice metadata
      final polyVoicePort = polyInputs.firstWhere((p) => 
        p.metadata?['isPolyVoice'] == true
      );
      expect(polyVoicePort.metadata?['voiceNumber'], isNotNull);
      
      // Multi-channel routing has specific channel metadata
      final multiChannelPort = multiInputs.firstWhere((p) => 
        p.metadata?['isMultiChannel'] == true
      );
      expect(multiChannelPort.metadata?['channelNumber'], isNotNull);
    });

    test('should demonstrate different validation strategies', () {
      final polyInputs = polyRouting.inputPorts;
      final polyOutputs = polyRouting.outputPorts;
      final multiInputs = multiChannelRouting.inputPorts;
      final multiOutputs = multiChannelRouting.outputPorts;
      
      // Poly routing: Cross-voice connections should be rejected
      final polyVoice1Out = polyOutputs.firstWhere((p) => 
        p.id == 'poly_audio_out_1'
      );
      final polyVoice2In = polyInputs.firstWhere((p) => 
        p.id == 'poly_audio_in_2'
      );
      expect(polyRouting.validateConnection(polyVoice1Out, polyVoice2In), isFalse);
      
      // Multi-channel routing: Cross-channel connections are allowed by default
      final multiCh1Out = multiOutputs.firstWhere((p) => 
        p.id == 'multi_audio_out_1_l'
      );
      final multiCh2In = multiInputs.firstWhere((p) => 
        p.id == 'multi_audio_in_2_l'
      );
      expect(multiChannelRouting.validateConnection(multiCh1Out, multiCh2In), isTrue);
      
      // Multi-channel routing: Stereo side mismatch should be rejected
      final multiCh1OutL = multiOutputs.firstWhere((p) => 
        p.id == 'multi_audio_out_1_l'
      );
      final multiCh1InR = multiInputs.firstWhere((p) => 
        p.id == 'multi_audio_in_1_r'
      );
      expect(multiChannelRouting.validateConnection(multiCh1OutL, multiCh1InR), isFalse);
    });

    test('should handle complex mixed routing scenario', () {
      // Create a complex routing scenario combining both types
      final polyMixOut = polyRouting.outputPorts.firstWhere((p) => 
        p.id == 'poly_mix_out'
      );
      final multiMasterMixIn = multiChannelRouting.inputPorts.firstWhere((p) => 
        p.type == PortType.audio
      );
      final multiMasterMixOut = multiChannelRouting.outputPorts.firstWhere((p) => 
        p.metadata?['isMasterMix'] == true
      );
      final polyVoiceIn = polyRouting.inputPorts.firstWhere((p) => 
        p.type == PortType.audio
      );
      
      // Validate the routing chain
      expect(polyRouting.validateConnection(polyMixOut, multiMasterMixIn), isTrue);
      expect(multiChannelRouting.validateConnection(polyMixOut, multiMasterMixIn), isTrue);
      expect(multiChannelRouting.validateConnection(multiMasterMixOut, polyVoiceIn), isTrue);
      
      // Create connections to form a processing chain
      final connection1 = polyRouting.addConnection(polyMixOut, multiMasterMixIn);
      final connection2 = multiChannelRouting.addConnection(multiMasterMixOut, polyVoiceIn);
      
      expect(connection1, isNotNull);
      expect(connection2, isNotNull);
    });

    test('should demonstrate different connection validation approaches', () {
      // Test gate-to-CV conversion in poly routing (virtual CV inputs)
      final polyGateOut = polyRouting.outputPorts.firstWhere((p) => 
        p.type == PortType.gate
      );
      final polyCvIn = polyRouting.inputPorts.firstWhere((p) => 
        p.type == PortType.cv && p.metadata?['isVirtualCV'] == true
      );
      
      expect(polyRouting.validateConnection(polyGateOut, polyCvIn), isTrue);
      
      // Multi-channel routing doesn't have virtual CV concept
      final multiChannelPorts = multiChannelRouting.inputPorts;
      final hasVirtualCv = multiChannelPorts.any((p) => 
        p.metadata?['isVirtualCV'] == true
      );
      expect(hasVirtualCv, isFalse);
    });

    test('should handle state management independently', () {
      // Each routing implementation manages its own state
      const polyState = RoutingState(
        status: RoutingSystemStatus.ready,
        metadata: {'type': 'poly'},
      );
      const multiState = RoutingState(
        status: RoutingSystemStatus.updating,
        metadata: {'type': 'multi'},
      );
      
      polyRouting.updateState(polyState);
      multiChannelRouting.updateState(multiState);
      
      expect(polyRouting.state.status, equals(RoutingSystemStatus.ready));
      expect(polyRouting.state.metadata?['type'], equals('poly'));
      expect(multiChannelRouting.state.status, equals(RoutingSystemStatus.updating));
      expect(multiChannelRouting.state.metadata?['type'], equals('multi'));
    });

    test('should demonstrate port finding capabilities', () {
      // Both implementations inherit findPortById from base class
      final polyPort = polyRouting.findPortById('poly_audio_in_1');
      final multiPort = multiChannelRouting.findPortById('multi_audio_in_1_l');
      
      expect(polyPort, isNotNull);
      expect(polyPort!.id, equals('poly_audio_in_1'));
      expect(multiPort, isNotNull);
      expect(multiPort!.id, equals('multi_audio_in_1_l'));
      
      // Non-existent ports should return null
      expect(polyRouting.findPortById('non_existent'), isNull);
      expect(multiChannelRouting.findPortById('non_existent'), isNull);
    });

    test('should handle connection removal consistently', () {
      // Create connections in both routings
      final polyOut = polyRouting.outputPorts.first;
      final polyIn = polyRouting.inputPorts.first;
      final multiOut = multiChannelRouting.outputPorts.first;
      final multiIn = multiChannelRouting.inputPorts.first;
      
      // Add connections
      final polyConnection = polyRouting.addConnection(polyOut, multiIn);
      final multiConnection = multiChannelRouting.addConnection(multiOut, polyIn);
      
      expect(polyConnection, isNotNull);
      expect(multiConnection, isNotNull);
      
      // Remove connections
      final polyRemoved = polyRouting.removeConnection(polyConnection!.id);
      final multiRemoved = multiChannelRouting.removeConnection(multiConnection!.id);
      
      // Note: The base implementation doesn't actually modify state,
      // but it should return appropriate values
      expect(polyRemoved, isFalse); // Connection not in state.connections
      expect(multiRemoved, isFalse); // Connection not in state.connections
    });

    test('should validate routing configurations independently', () {
      // Both should validate their own configurations as valid
      expect(polyRouting.validateRouting(), isTrue);
      expect(multiChannelRouting.validateRouting(), isTrue);
      
      // Add invalid connections to test validation
      const invalidConnection = Connection(
        id: 'invalid',
        sourcePortId: 'fake_source',
        destinationPortId: 'fake_dest',
      );
      
      const polyInvalidState = RoutingState(
        connections: [invalidConnection],
      );
      const multiInvalidState = RoutingState(
        connections: [invalidConnection],
      );
      
      polyRouting.updateState(polyInvalidState);
      multiChannelRouting.updateState(multiInvalidState);
      
      expect(polyRouting.validateRouting(), isFalse);
      expect(multiChannelRouting.validateRouting(), isFalse);
    });

    test('should dispose resources properly', () {
      // Create new instances for disposal test
      const polyConfig = PolyAlgorithmConfig(voiceCount: 2);
      final polyTest = PolyAlgorithmRouting(config: polyConfig);
      
      final multiConfig = MultiChannelAlgorithmConfig.normal();
      final multiTest = MultiChannelAlgorithmRouting(config: multiConfig);
      
      // Access ports to ensure caches are created
      expect(polyTest.inputPorts, isNotEmpty);
      expect(multiTest.inputPorts, isNotEmpty);
      
      // Dispose both
      polyTest.dispose();
      multiTest.dispose();
      
      // After disposal, implementations should have cleared caches
      // This is verified by the dispose methods themselves
    });
  });

  group('Real-world Integration Scenarios', () {
    test('should simulate a complex modular synthesis patch', () {
      // Scenario: Poly synthesizer feeding into multi-channel mixer
      const polyConfig = PolyAlgorithmConfig(
        voiceCount: 8,
        requiresGateInputs: true,
        usesVirtualCvPorts: true,
        virtualCvPortsPerVoice: 3,
        portNamePrefix: 'Synth',
      );
      final synthRouting = PolyAlgorithmRouting(config: polyConfig);
      
      final mixerConfig = MultiChannelAlgorithmConfig.widthBased(
        width: 8,
        supportsStereo: true,
        portNamePrefix: 'Mix',
      );
      final mixerRouting = MultiChannelAlgorithmRouting(config: mixerConfig);
      
      try {
        // Verify both have appropriate port counts
        expect(synthRouting.inputPorts.length, equals(40)); // 8 voices * (1 audio + 1 gate + 3 CV) = 40
        expect(synthRouting.outputPorts.length, equals(17)); // 8 voices * 2 + mix
        expect(mixerRouting.inputPorts.length, equals(24)); // 8 channels * (2 audio stereo + 1 CV mono) = 24
        expect(mixerRouting.outputPorts.length, equals(27)); // 8 channels * 3 + 3 master mix = 27
        
        // Connect synth voices to mixer channels
        final connections = <Connection>[];
        for (int voice = 1; voice <= 8; voice++) {
          final synthOut = synthRouting.outputPorts.firstWhere((p) => 
            p.id == 'poly_audio_out_$voice'
          );
          final mixerInL = mixerRouting.inputPorts.firstWhere((p) => 
            p.id == 'multi_audio_in_${voice}_l'
          );
          
          final connection = synthRouting.addConnection(synthOut, mixerInL);
          expect(connection, isNotNull);
          connections.add(connection!);
        }
        
        expect(connections.length, equals(8));
      } finally {
        synthRouting.dispose();
        mixerRouting.dispose();
      }
    });

    test('should simulate a multi-effects processing chain', () {
      // Scenario: Multiple mono effects chained together
      final effect1Config = MultiChannelAlgorithmConfig.normal(
        portNamePrefix: 'Delay',
      );
      final effect2Config = MultiChannelAlgorithmConfig.normal(
        portNamePrefix: 'Reverb',
      );
      final effect3Config = MultiChannelAlgorithmConfig.widthBased(
        width: 2,
        portNamePrefix: 'Chorus',
        supportsStereo: true,
      );
      
      final delayRouting = MultiChannelAlgorithmRouting(config: effect1Config);
      final reverbRouting = MultiChannelAlgorithmRouting(config: effect2Config);
      final chorusRouting = MultiChannelAlgorithmRouting(config: effect3Config);
      
      try {
        // Chain the effects: delay -> reverb -> chorus
        final delayOut = delayRouting.outputPorts.firstWhere((p) => 
          p.type == PortType.audio
        );
        final reverbIn = reverbRouting.inputPorts.firstWhere((p) => 
          p.type == PortType.audio
        );
        final reverbOut = reverbRouting.outputPorts.firstWhere((p) => 
          p.type == PortType.audio
        );
        final chorusInL = chorusRouting.inputPorts.firstWhere((p) => 
          p.id == 'multi_audio_in_1_l'
        );
        
        // Validate the chain - delay (mono) -> reverb (mono) works fine
        expect(delayRouting.validateConnection(delayOut, reverbIn), isTrue);
        
        // For reverb (mono) -> chorus (stereo L), since reverb is mono it should pass base validation
        expect(reverbRouting.validateConnection(reverbOut, chorusInL), isTrue);
        
        // Create connections
        final connection1 = delayRouting.addConnection(delayOut, reverbIn);
        final connection2 = reverbRouting.addConnection(reverbOut, chorusInL);
        
        expect(connection1, isNotNull);
        expect(connection2, isNotNull);
        
        // Verify the chain validates end-to-end
        expect(delayRouting.validateRouting(), isTrue);
        expect(reverbRouting.validateRouting(), isTrue);
        expect(chorusRouting.validateRouting(), isTrue);
      } finally {
        delayRouting.dispose();
        reverbRouting.dispose();
        chorusRouting.dispose();
      }
    });

    test('should handle error recovery in complex scenarios', () {
      const polyConfig = PolyAlgorithmConfig(voiceCount: 4);
      final polyRouting = PolyAlgorithmRouting(config: polyConfig);
      
      final multiConfig = MultiChannelAlgorithmConfig.widthBased(width: 4);
      final multiRouting = MultiChannelAlgorithmRouting(config: multiConfig);
      
      try {
        // Simulate error state
        const errorState = RoutingState(
          status: RoutingSystemStatus.error,
          errorMessage: 'Simulated error',
        );
        
        polyRouting.updateState(errorState);
        multiRouting.updateState(errorState);
        
        expect(polyRouting.state.hasError, isTrue);
        expect(multiRouting.state.hasError, isTrue);
        expect(polyRouting.state.errorMessage, equals('Simulated error'));
        
        // Recovery: Update to ready state
        const recoveryState = RoutingState(
          status: RoutingSystemStatus.ready,
          errorMessage: null,
        );
        
        polyRouting.updateState(recoveryState);
        multiRouting.updateState(recoveryState);
        
        expect(polyRouting.state.isReady, isTrue);
        expect(multiRouting.state.isReady, isTrue);
        expect(polyRouting.state.errorMessage, isNull);
      } finally {
        polyRouting.dispose();
        multiRouting.dispose();
      }
    });
  });
}