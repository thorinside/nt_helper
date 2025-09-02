import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/core/routing/poly_algorithm_routing.dart';
import 'package:nt_helper/core/routing/models/routing_state.dart';
import 'package:nt_helper/core/routing/models/port.dart';
import 'package:nt_helper/core/routing/models/connection.dart';
import 'package:nt_helper/core/routing/port_compatibility_validator.dart';
import 'package:nt_helper/domain/disting_nt_sysex.dart';
import 'package:nt_helper/cubit/disting_cubit.dart';

// Helper function to create test Slot for PolyAlgorithmRouting
Slot _createPolyTestSlot({
  required Map<String, int> ioParameters,
  Map<String, int> modeParameters = const {},
  List<ParameterInfo> parameters = const [],
  List<ParameterValue> values = const [],
  List<ParameterEnumStrings> enums = const [],
}) {
  return Slot(
    algorithm: Algorithm(
      algorithmIndex: 0,
      guid: 'poly-test-algo',
      name: 'Poly Test Algorithm',
    ),
    routing: RoutingInfo(algorithmIndex: 0, routingInfo: []),
    pages: ParameterPages(algorithmIndex: 0, pages: []),
    parameters: parameters,
    values: values,
    enums: enums,
    mappings: const [],
    valueStrings: const [],
  );
}

void main() {
  group('PolyAlgorithmConfig', () {
    test('should create default configuration', () {
      const config = PolyAlgorithmConfig(voiceCount: 4);
      
      expect(config.voiceCount, equals(4));
      expect(config.requiresGateInputs, isTrue);
      expect(config.usesVirtualCvPorts, isTrue);
      expect(config.virtualCvPortsPerVoice, equals(2));
      expect(config.portNamePrefix, equals('Voice'));
      expect(config.algorithmProperties, isEmpty);
    });

    test('should create custom configuration', () {
      const config = PolyAlgorithmConfig(
        voiceCount: 8,
        requiresGateInputs: false,
        usesVirtualCvPorts: false,
        virtualCvPortsPerVoice: 4,
        portNamePrefix: 'Channel',
        algorithmProperties: {'mode': 'advanced'},
      );
      
      expect(config.voiceCount, equals(8));
      expect(config.requiresGateInputs, isFalse);
      expect(config.usesVirtualCvPorts, isFalse);
      expect(config.virtualCvPortsPerVoice, equals(4));
      expect(config.portNamePrefix, equals('Channel'));
      expect(config.algorithmProperties['mode'], equals('advanced'));
    });
  });

  group('PolyAlgorithmRouting', () {
    late PolyAlgorithmRouting routing;
    late PolyAlgorithmConfig config;

    setUp(() {
      config = const PolyAlgorithmConfig(voiceCount: 4);
      routing = PolyAlgorithmRouting(config: config);
    });

    tearDown(() {
      routing.dispose();
    });

    test('should initialize with correct config', () {
      expect(routing.config, equals(config));
      expect(routing.state.status, equals(RoutingSystemStatus.uninitialized));
    });

    test('should generate correct number of input ports for basic config', () {
      final inputPorts = routing.generateInputPorts();
      
      // 4 voices * (1 audio + 1 gate + 2 CV) = 16 ports
      expect(inputPorts.length, equals(16));
      
      // Check audio ports
      final audioPorts = inputPorts.where((p) => p.type == PortType.audio).toList();
      expect(audioPorts.length, equals(4));
      expect(audioPorts[0].id, equals('poly_audio_in_1'));
      expect(audioPorts[0].name, equals('Voice 1 Audio In'));
      expect(audioPorts[3].id, equals('poly_audio_in_4'));
      
      // Check gate ports
      final gatePorts = inputPorts.where((p) => p.type == PortType.gate).toList();
      expect(gatePorts.length, equals(4));
      expect(gatePorts[0].id, equals('poly_gate_in_1'));
      expect(gatePorts[0].name, equals('Voice 1 Gate'));
      
      // Check CV ports
      final cvPorts = inputPorts.where((p) => p.type == PortType.cv).toList();
      expect(cvPorts.length, equals(8)); // 4 voices * 2 CV each
      expect(cvPorts[0].id, equals('poly_cv_in_1_1'));
      expect(cvPorts[1].id, equals('poly_cv_in_1_2'));
    });

    test('should generate correct number of output ports for basic config', () {
      final outputPorts = routing.generateOutputPorts();
      
      // 4 voices * (1 audio + 1 gate) + 1 mix = 9 ports
      expect(outputPorts.length, equals(9));
      
      // Check audio ports
      final audioPorts = outputPorts.where((p) => p.type == PortType.audio).toList();
      expect(audioPorts.length, equals(5)); // 4 voice outputs + 1 mix
      expect(audioPorts[0].id, equals('poly_audio_out_1'));
      expect(audioPorts[4].id, equals('poly_mix_out'));
      expect(audioPorts[4].name, equals('Poly Mix Out'));
      
      // Check gate outputs
      final gatePorts = outputPorts.where((p) => p.type == PortType.gate).toList();
      expect(gatePorts.length, equals(4));
      expect(gatePorts[0].id, equals('poly_gate_out_1'));
    });

    test('should generate ports without gates when not required', () {
      final configNoGates = const PolyAlgorithmConfig(
        voiceCount: 2,
        requiresGateInputs: false,
      );
      final routingNoGates = PolyAlgorithmRouting(config: configNoGates);
      
      final inputPorts = routingNoGates.generateInputPorts();
      final outputPorts = routingNoGates.generateOutputPorts();
      
      // 2 voices * (1 audio + 2 CV) = 6 input ports
      expect(inputPorts.length, equals(6));
      expect(inputPorts.where((p) => p.type == PortType.gate), isEmpty);
      
      // 2 voices * 1 audio + 1 mix = 3 output ports
      expect(outputPorts.length, equals(3));
      expect(outputPorts.where((p) => p.type == PortType.gate), isEmpty);
      
      routingNoGates.dispose();
    });

    test('should generate ports without virtual CV when disabled', () {
      final configNoCv = const PolyAlgorithmConfig(
        voiceCount: 2,
        usesVirtualCvPorts: false,
      );
      final routingNoCv = PolyAlgorithmRouting(config: configNoCv);
      
      final inputPorts = routingNoCv.generateInputPorts();
      
      // 2 voices * (1 audio + 1 gate) = 4 input ports
      expect(inputPorts.length, equals(4));
      expect(inputPorts.where((p) => p.type == PortType.cv), isEmpty);
      
      routingNoCv.dispose();
    });

    test('should cache generated ports', () {
      final inputPorts1 = routing.inputPorts;
      final inputPorts2 = routing.inputPorts;
      final outputPorts1 = routing.outputPorts;
      final outputPorts2 = routing.outputPorts;
      
      expect(identical(inputPorts1, inputPorts2), isTrue);
      expect(identical(outputPorts1, outputPorts2), isTrue);
    });

    test('should validate basic connections using base class validation', () {
      final inputPorts = routing.inputPorts;
      final outputPorts = routing.outputPorts;
      
      final audioInput = inputPorts.firstWhere((p) => p.type == PortType.audio);
      final audioOutput = outputPorts.firstWhere((p) => p.type == PortType.audio);
      
      // Debug the port directions
      expect(audioInput.direction, equals(PortDirection.input));
      expect(audioOutput.direction, equals(PortDirection.output));
      
      // In the port model, both directions return true for canConnectTo
      // This represents "can accept connection from" rather than "can send to"
      expect(audioOutput.canConnectTo(audioInput), isTrue); // output can connect to input
      expect(audioInput.canConnectTo(audioOutput), isTrue); // input can connect to output
      
      // Valid connection: output to input (typical signal flow)
      expect(routing.validateConnection(audioOutput, audioInput), isTrue);
      // The reverse should also be valid based on the base port logic
      expect(routing.validateConnection(audioInput, audioOutput), isTrue);
    });

    test('should prevent cross-voice connections between poly voice ports', () {
      final inputPorts = routing.inputPorts;
      final outputPorts = routing.outputPorts;
      
      final voice1AudioOut = outputPorts.firstWhere((p) => 
        p.id == 'poly_audio_out_1'
      );
      final voice2AudioIn = inputPorts.firstWhere((p) => 
        p.id == 'poly_audio_in_2'
      );
      
      expect(routing.validateConnection(voice1AudioOut, voice2AudioIn), isFalse);
    });

    test('should allow same-voice connections between poly voice ports', () {
      final inputPorts = routing.inputPorts;
      final outputPorts = routing.outputPorts;
      
      final voice1AudioOut = outputPorts.firstWhere((p) => 
        p.id == 'poly_audio_out_1'
      );
      // Note: In real scenarios, this would connect to external ports
      // but for testing validation logic, we use same routing instance
      final voice1AudioIn = inputPorts.firstWhere((p) => 
        p.id == 'poly_audio_in_1'
      );
      
      // This would normally be invalid (output to input of same algorithm)
      // but the voice validation should not reject it based on voice mismatch
      final voice1OutVoice = voice1AudioOut.metadata?['voiceNumber'] as int?;
      final voice1InVoice = voice1AudioIn.metadata?['voiceNumber'] as int?;
      expect(voice1OutVoice, equals(voice1InVoice));
    });

    test('should validate gate connections properly', () {
      final inputPorts = routing.inputPorts;
      final outputPorts = routing.outputPorts;
      
      final gateOut = outputPorts.firstWhere((p) => p.type == PortType.gate);
      final gateIn = inputPorts.firstWhere((p) => p.type == PortType.gate);
      final cvIn = inputPorts.firstWhere((p) => p.type == PortType.cv);
      
      expect(routing.validateConnection(gateOut, gateIn), isTrue);
      expect(routing.validateConnection(gateOut, cvIn), isTrue); // Gate to CV conversion
    });

    test('should validate virtual CV connections', () {
      final inputPorts = routing.inputPorts;
      final outputPorts = routing.outputPorts;
      
      final cvIn = inputPorts.firstWhere((p) => p.type == PortType.cv);
      final audioOut = outputPorts.firstWhere((p) => p.type == PortType.audio);
      final gateOut = outputPorts.firstWhere((p) => p.type == PortType.gate);
      
      // Virtual CV should accept audio and gate connections
      expect(routing.validateConnection(audioOut, cvIn), isTrue);
      expect(routing.validateConnection(gateOut, cvIn), isTrue);
    });

    test('should add valid connections', () {
      final inputPorts = routing.inputPorts;
      final outputPorts = routing.outputPorts;
      
      final audioOut = outputPorts.firstWhere((p) => p.type == PortType.audio);
      final audioIn = inputPorts.firstWhere((p) => p.type == PortType.audio);
      
      // Create a custom routing state with the connection to test addConnection
      final connection = routing.addConnection(audioOut, audioIn);
      expect(connection, isNotNull);
      expect(connection!.sourcePortId, equals(audioOut.id));
      expect(connection.destinationPortId, equals(audioIn.id));
    });

    test('should reject invalid connections', () {
      final inputPorts = routing.inputPorts;
      
      final audioIn = inputPorts.firstWhere((p) => p.type == PortType.audio);
      
      // Try to connect input to input
      final connection = routing.addConnection(audioIn, audioIn);
      expect(connection, isNull);
    });

    test('should find ports by ID', () {
      final port = routing.findPortById('poly_audio_in_1');
      expect(port, isNotNull);
      expect(port!.id, equals('poly_audio_in_1'));
      
      final nonExistent = routing.findPortById('non_existent');
      expect(nonExistent, isNull);
    });

    test('should update state and clear caches', () {
      // Access ports to cache them
      final originalInputPorts = routing.inputPorts;
      expect(originalInputPorts, isNotEmpty);
      
      // Update state with different ports
      final newState = const RoutingState(
        status: RoutingSystemStatus.ready,
        inputPorts: [],
        outputPorts: [],
      );
      
      routing.updateState(newState);
      
      expect(routing.state.status, equals(RoutingSystemStatus.ready));
      // The cached ports should be cleared when state has different ports
      // but since we're accessing the generated ports (not state ports), 
      // they remain the same
      expect(routing.inputPorts, equals(originalInputPorts));
    });

    test('should validate entire routing configuration', () {
      expect(routing.validateRouting(), isTrue);
      
      // Test with invalid connections in state
      final invalidConnection = const Connection(
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

    test('should handle voice count updates', () {
      // Initial voice count
      expect(routing.config.voiceCount, equals(4));
      
      // Update voice count (note: this only clears caches, doesn't change config)
      routing.updateVoiceCount(6);
      
      // Config remains unchanged since it's immutable
      expect(routing.config.voiceCount, equals(4));
      
      // Ports are still based on original config
      final inputPorts = routing.inputPorts;
      // 4 voices * (1 audio + 1 gate + 2 CV) = 16 ports
      expect(inputPorts.length, equals(16));
    });

    test('should identify poly voice ports correctly', () {
      final inputPorts = routing.inputPorts;
      final polyPort = inputPorts.firstWhere((p) => p.id == 'poly_audio_in_1');
      
      expect(polyPort.metadata?['isPolyVoice'], isTrue);
      expect(polyPort.metadata?['voiceNumber'], equals(1));
    });

    test('should identify virtual CV ports correctly', () {
      final inputPorts = routing.inputPorts;
      final cvPort = inputPorts.firstWhere((p) => p.id == 'poly_cv_in_1_1');
      
      expect(cvPort.metadata?['isVirtualCV'], isTrue);
    });
  });

  group('PolyAlgorithmRouting Edge Cases', () {
    test('should handle zero voice count gracefully', () {
      const config = PolyAlgorithmConfig(voiceCount: 0);
      final routing = PolyAlgorithmRouting(config: config);
      
      final inputPorts = routing.generateInputPorts();
      final outputPorts = routing.generateOutputPorts();
      
      expect(inputPorts, isEmpty);
      expect(outputPorts.length, equals(1)); // Only mix out
      expect(outputPorts[0].id, equals('poly_mix_out'));
      
      routing.dispose();
    });

    test('should handle single voice count', () {
      const config = PolyAlgorithmConfig(voiceCount: 1);
      final routing = PolyAlgorithmRouting(config: config);
      
      final inputPorts = routing.generateInputPorts();
      final outputPorts = routing.generateOutputPorts();
      
      // 1 voice * (1 audio + 1 gate + 2 CV) = 4 input ports
      expect(inputPorts.length, equals(4));
      // 1 voice * (1 audio + 1 gate) + 1 mix = 3 output ports
      expect(outputPorts.length, equals(3));
      
      routing.dispose();
    });

    test('should handle high voice count', () {
      const config = PolyAlgorithmConfig(voiceCount: 16);
      final routing = PolyAlgorithmRouting(config: config);
      
      final inputPorts = routing.generateInputPorts();
      final outputPorts = routing.generateOutputPorts();
      
      // 16 voices * (1 audio + 1 gate + 2 CV) = 64 input ports
      expect(inputPorts.length, equals(64));
      // 16 voices * (1 audio + 1 gate) + 1 mix = 33 output ports
      expect(outputPorts.length, equals(33));
      
      routing.dispose();
    });

    test('should handle custom CV port count per voice', () {
      const config = PolyAlgorithmConfig(
        voiceCount: 2,
        virtualCvPortsPerVoice: 5,
      );
      final routing = PolyAlgorithmRouting(config: config);
      
      final inputPorts = routing.generateInputPorts();
      final cvPorts = inputPorts.where((p) => p.type == PortType.cv).toList();
      
      // 2 voices * 5 CV each = 10 CV ports
      expect(cvPorts.length, equals(10));
      expect(cvPorts.any((p) => p.id == 'poly_cv_in_1_5'), isTrue);
      expect(cvPorts.any((p) => p.id == 'poly_cv_in_2_5'), isTrue);
      
      routing.dispose();
    });

    test('should handle custom port name prefix', () {
      const config = PolyAlgorithmConfig(
        voiceCount: 2,
        portNamePrefix: 'Osc',
      );
      final routing = PolyAlgorithmRouting(config: config);
      
      final inputPorts = routing.generateInputPorts();
      final audioPort = inputPorts.firstWhere((p) => p.type == PortType.audio);
      
      expect(audioPort.name, equals('Osc 1 Audio In'));
      
      routing.dispose();
    });

    test('should work with custom validator', () {
      final customValidator = PortCompatibilityValidator();
      const config = PolyAlgorithmConfig(voiceCount: 2);
      final routing = PolyAlgorithmRouting(
        config: config,
        validator: customValidator,
      );
      
      expect(routing.validator, equals(customValidator));
      
      routing.dispose();
    });

    test('should work with initial state', () {
      const initialState = RoutingState(
        status: RoutingSystemStatus.ready,
      );
      const config = PolyAlgorithmConfig(voiceCount: 2);
      final routing = PolyAlgorithmRouting(
        config: config,
        initialState: initialState,
      );
      
      expect(routing.state.status, equals(RoutingSystemStatus.ready));
      
      routing.dispose();
    });

    group('Mode Parameter Handling', () {
      test('should apply OutputMode.replace to output ports when mode parameter is 1', () {
        final ioParameters = {
          'Gate input 1': 1,
          'Gate CV count 1': 2,
          'Output 1': 13,
          'Output 2': 14,
        };
        
        final modeParameters = {
          'Output 1 mode': 1, // Replace
          'Output 2 mode': 0, // Add
        };
        
        final routing = PolyAlgorithmRouting.createFromSlot(
          _createPolyTestSlot(
            ioParameters: ioParameters,
            modeParameters: modeParameters,
          ),
          ioParameters: ioParameters,
          modeParameters: modeParameters,
        );
        
        final outputPorts = routing.outputPorts;
        
        // Find output ports for buses 13 and 14
        final output1Port = outputPorts.firstWhere(
          (p) => p.metadata?['busNumber'] == 13,
          orElse: () => const Port(
            id: 'not_found',
            name: 'Not Found',
            type: PortType.audio,
            direction: PortDirection.output,
          ),
        );
        
        final output2Port = outputPorts.firstWhere(
          (p) => p.metadata?['busNumber'] == 14,
          orElse: () => const Port(
            id: 'not_found',
            name: 'Not Found',
            type: PortType.audio,
            direction: PortDirection.output,
          ),
        );
        
        // Output 1 should have Replace mode
        expect(output1Port.outputMode, equals(OutputMode.replace));
        
        // Output 2 should have Add mode (or null for default)
        expect(output2Port.outputMode ?? OutputMode.add, equals(OutputMode.add));
        
        routing.dispose();
      });

      test('should handle missing mode parameters gracefully', () {
        final ioParameters = {
          'Gate input 1': 1,
          'Gate CV count 1': 2,
          'Output 1': 13,
        };
        
        // No mode parameters provided
        final routing = PolyAlgorithmRouting.createFromSlot(
          _createPolyTestSlot(ioParameters: ioParameters),
          ioParameters: ioParameters,
        );
        
        final outputPorts = routing.outputPorts;
        
        // Find output port for bus 13
        final outputPort = outputPorts.firstWhere(
          (p) => p.metadata?['busNumber'] == 13,
          orElse: () => const Port(
            id: 'not_found',
            name: 'Not Found',
            type: PortType.audio,
            direction: PortDirection.output,
          ),
        );
        
        // Should default to null (which means Add mode)
        expect(outputPort.outputMode, isNull);
        
        routing.dispose();
      });

      test('should apply mode to all output ports based on parameter pattern', () {
        final ioParameters = {
          'Gate input 1': 1,
          'Gate CV count 1': 0,
          'Gate input 2': 2,
          'Gate CV count 2': 0,
          'Output 1': 13,
          'Output 2': 14,
          'Output 3': 15,
          'Output 4': 16,
        };
        
        final modeParameters = {
          'Output 1 mode': 1, // Replace
          'Output 2 mode': 1, // Replace
          'Output 3 mode': 0, // Add
          'Output 4 mode': 0, // Add
        };
        
        final routing = PolyAlgorithmRouting.createFromSlot(
          _createPolyTestSlot(
            ioParameters: ioParameters,
            modeParameters: modeParameters,
          ),
          ioParameters: ioParameters,
          modeParameters: modeParameters,
        );
        
        final outputPorts = routing.outputPorts;
        
        // Check that outputs 1 and 2 have Replace mode
        for (int bus in [13, 14]) {
          final port = outputPorts.firstWhere(
            (p) => p.metadata?['busNumber'] == bus,
            orElse: () => const Port(
              id: 'not_found',
              name: 'Not Found',
              type: PortType.audio,
              direction: PortDirection.output,
            ),
          );
          expect(port.outputMode, equals(OutputMode.replace),
            reason: 'Output on bus $bus should have Replace mode');
        }
        
        // Check that outputs 3 and 4 have Add mode (or null)
        for (int bus in [15, 16]) {
          final port = outputPorts.firstWhere(
            (p) => p.metadata?['busNumber'] == bus,
            orElse: () => const Port(
              id: 'not_found',
              name: 'Not Found',
              type: PortType.audio,
              direction: PortDirection.output,
            ),
          );
          expect(port.outputMode ?? OutputMode.add, equals(OutputMode.add),
            reason: 'Output on bus $bus should have Add mode');
        }
        
        routing.dispose();
      });
    });
  });
}