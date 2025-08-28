import 'package:flutter/foundation.dart';
import 'algorithm_routing.dart';
import 'models/routing_state.dart';
import 'models/port.dart';
import 'models/connection.dart';
import 'port_compatibility_validator.dart';

/// Configuration data for polyphonic algorithm routing.
/// 
/// Defines the properties needed to configure polyphonic routing behavior,
/// including the number of voices and gate/CV requirements.
@immutable
class PolyAlgorithmConfig {
  /// Number of polyphonic voices supported by this algorithm
  final int voiceCount;
  
  /// Whether this algorithm requires gate inputs for each voice
  final bool requiresGateInputs;
  
  /// Whether this algorithm uses virtual CV ports for modulation
  final bool usesVirtualCvPorts;
  
  /// Number of virtual CV ports to generate per voice
  final int virtualCvPortsPerVoice;
  
  /// Base name prefix for generated ports
  final String portNamePrefix;
  
  /// Additional algorithm-specific properties
  final Map<String, dynamic> algorithmProperties;

  const PolyAlgorithmConfig({
    required this.voiceCount,
    this.requiresGateInputs = true,
    this.usesVirtualCvPorts = true,
    this.virtualCvPortsPerVoice = 2,
    this.portNamePrefix = 'Voice',
    this.algorithmProperties = const {},
  });
}

/// Concrete implementation of AlgorithmRouting for polyphonic routing.
/// 
/// This class handles polyphonic routing with gate input and virtual CV ports
/// based on algorithm properties. It dynamically generates ports based on the
/// number of voices and routing requirements of the polyphonic algorithm.
/// 
/// Each voice typically includes:
/// - Audio input/output ports
/// - Gate input for triggering
/// - CV inputs for modulation (if enabled)
/// 
/// Example usage:
/// ```dart
/// final config = PolyAlgorithmConfig(
///   voiceCount: 4,
///   requiresGateInputs: true,
///   usesVirtualCvPorts: true,
/// );
/// 
/// final polyRouting = PolyAlgorithmRouting(config: config);
/// final inputPorts = polyRouting.generateInputPorts();
/// ```
class PolyAlgorithmRouting extends AlgorithmRouting {
  /// Configuration for this polyphonic routing instance
  final PolyAlgorithmConfig config;
  
  /// Current routing state
  RoutingState _state;
  
  /// Cached input ports to avoid regeneration
  List<Port>? _cachedInputPorts;
  
  /// Cached output ports to avoid regeneration  
  List<Port>? _cachedOutputPorts;

  /// Creates a new PolyAlgorithmRouting instance.
  /// 
  /// Parameters:
  /// - [config]: Configuration defining the polyphonic routing behavior
  /// - [validator]: Optional port compatibility validator (uses default if not provided)
  /// - [initialState]: Optional initial routing state
  PolyAlgorithmRouting({
    required this.config,
    PortCompatibilityValidator? validator,
    RoutingState? initialState,
  }) : _state = initialState ?? const RoutingState(),
       super(validator: validator) {
    debugPrint(
      'PolyAlgorithmRouting: Initialized with ${config.voiceCount} voices, '
      'gates: ${config.requiresGateInputs}, CV: ${config.usesVirtualCvPorts}'
    );
  }

  @override
  RoutingState get state => _state;

  @override
  List<Port> get inputPorts => _cachedInputPorts ??= generateInputPorts();

  @override
  List<Port> get outputPorts => _cachedOutputPorts ??= generateOutputPorts();

  @override
  List<Connection> get connections => _state.connections;

  @override
  List<Port> generateInputPorts() {
    final ports = <Port>[];
    
    // Generate ports for each voice
    for (int voice = 0; voice < config.voiceCount; voice++) {
      final voiceNumber = voice + 1; // 1-based voice numbering
      
      // Main audio input for each voice
      ports.add(Port(
        id: 'poly_audio_in_$voiceNumber',
        name: '${config.portNamePrefix} $voiceNumber Audio In',
        type: PortType.audio,
        direction: PortDirection.input,
        description: 'Audio input for voice $voiceNumber',
        metadata: {
          'voiceNumber': voiceNumber,
          'isPolyVoice': true,
        },
      ));
      
      // Gate input if required
      if (config.requiresGateInputs) {
        ports.add(Port(
          id: 'poly_gate_in_$voiceNumber',
          name: '${config.portNamePrefix} $voiceNumber Gate',
          type: PortType.gate,
          direction: PortDirection.input,
          description: 'Gate/trigger input for voice $voiceNumber',
          metadata: {
            'voiceNumber': voiceNumber,
            'isPolyVoice': true,
            'isGateInput': true,
          },
        ));
      }
      
      // Virtual CV inputs if enabled
      if (config.usesVirtualCvPorts) {
        for (int cv = 0; cv < config.virtualCvPortsPerVoice; cv++) {
          final cvNumber = cv + 1;
          ports.add(Port(
            id: 'poly_cv_in_${voiceNumber}_$cvNumber',
            name: '${config.portNamePrefix} $voiceNumber CV$cvNumber',
            type: PortType.cv,
            direction: PortDirection.input,
            description: 'Virtual CV input $cvNumber for voice $voiceNumber',
            metadata: {
              'voiceNumber': voiceNumber,
              'cvNumber': cvNumber,
              'isPolyVoice': true,
              'isVirtualCV': true,
            },
          ));
        }
      }
    }
    
    debugPrint('PolyAlgorithmRouting: Generated ${ports.length} input ports');
    return ports;
  }

  @override
  List<Port> generateOutputPorts() {
    final ports = <Port>[];
    
    // Generate output ports for each voice
    for (int voice = 0; voice < config.voiceCount; voice++) {
      final voiceNumber = voice + 1;
      
      // Main audio output for each voice
      ports.add(Port(
        id: 'poly_audio_out_$voiceNumber',
        name: '${config.portNamePrefix} $voiceNumber Audio Out',
        type: PortType.audio,
        direction: PortDirection.output,
        description: 'Audio output for voice $voiceNumber',
        metadata: {
          'voiceNumber': voiceNumber,
          'isPolyVoice': true,
        },
      ));
      
      // Optional gate output (echo/passthrough)
      if (config.requiresGateInputs) {
        ports.add(Port(
          id: 'poly_gate_out_$voiceNumber',
          name: '${config.portNamePrefix} $voiceNumber Gate Out',
          type: PortType.gate,
          direction: PortDirection.output,
          description: 'Gate output for voice $voiceNumber',
          metadata: {
            'voiceNumber': voiceNumber,
            'isPolyVoice': true,
            'isGateOutput': true,
          },
        ));
      }
    }
    
    // Mixed output (sum of all voices)
    ports.add(Port(
      id: 'poly_mix_out',
      name: 'Poly Mix Out',
      type: PortType.audio,
      direction: PortDirection.output,
      description: 'Mixed output of all polyphonic voices',
      metadata: {
        'isMixedOutput': true,
        'voiceCount': config.voiceCount,
      },
    ));
    
    debugPrint('PolyAlgorithmRouting: Generated ${ports.length} output ports');
    return ports;
  }

  @override
  bool validateConnection(Port source, Port destination) {
    // Gate connections have special rules that override base validation
    if (source.type == PortType.gate || destination.type == PortType.gate) {
      if (!_validateGateConnection(source, destination)) {
        return false;
      }
    }
    // Virtual CV connections need special handling
    else if (_isVirtualCvPort(source) || _isVirtualCvPort(destination)) {
      if (!_validateVirtualCvConnection(source, destination)) {
        return false;
      }
    }
    // For other connections, use base validation
    else if (!super.validateConnection(source, destination)) {
      return false;
    }
    
    // Additional polyphonic-specific validation
    if (_isPolyVoicePort(source) && _isPolyVoicePort(destination)) {
      // Voice-to-voice connections should be between same voice numbers
      final sourceVoice = _getVoiceNumber(source);
      final destVoice = _getVoiceNumber(destination);
      
      if (sourceVoice != null && destVoice != null && sourceVoice != destVoice) {
        debugPrint(
          'PolyAlgorithmRouting: Cross-voice connection attempted between '
          'voice $sourceVoice and voice $destVoice'
        );
        return false;
      }
    }
    
    return true;
  }
  
  @override
  void updateState(RoutingState newState) {
    _state = newState;
    
    // Clear port caches if ports have changed
    if (_state.inputPorts.isNotEmpty || _state.outputPorts.isNotEmpty) {
      _cachedInputPorts = null;
      _cachedOutputPorts = null;
    }
    
    debugPrint('PolyAlgorithmRouting: State updated');
  }
  
  /// Validates gate-specific connections
  bool _validateGateConnection(Port source, Port destination) {
    // Gate outputs can connect to gate inputs
    if (source.type == PortType.gate && destination.type == PortType.gate) {
      return source.isOutput && destination.isInput;
    }
    
    // Gate signals can also trigger CV inputs (gate-to-CV conversion)
    if (source.type == PortType.gate && destination.type == PortType.cv) {
      return source.isOutput && destination.isInput;
    }
    
    // Clock signals can trigger gates
    if (source.type == PortType.clock && destination.type == PortType.gate) {
      return source.isOutput && destination.isInput;
    }
    
    return false;
  }
  
  /// Validates virtual CV connections
  bool _validateVirtualCvConnection(Port source, Port destination) {
    // Virtual CV ports should only connect to CV or audio ports
    if (_isVirtualCvPort(source)) {
      return destination.type == PortType.cv || 
             destination.type == PortType.audio ||
             destination.type == PortType.gate;
    }
    
    if (_isVirtualCvPort(destination)) {
      return source.type == PortType.cv || 
             source.type == PortType.audio ||
             source.type == PortType.gate;
    }
    
    return true;
  }
  
  /// Checks if a port belongs to a polyphonic voice
  bool _isPolyVoicePort(Port port) {
    return port.metadata?['isPolyVoice'] == true;
  }
  
  /// Gets the voice number from a polyphonic voice port
  int? _getVoiceNumber(Port port) {
    return port.metadata?['voiceNumber'] as int?;
  }
  
  /// Checks if a port is a virtual CV port
  bool _isVirtualCvPort(Port port) {
    return port.metadata?['isVirtualCV'] == true;
  }
  
  /// Updates the voice count and regenerates ports
  void updateVoiceCount(int newVoiceCount) {
    if (newVoiceCount != config.voiceCount) {
      // Clear cached ports to force regeneration
      // Note: Config is immutable, so this only clears caches for when
      // a new instance would be created with different config
      _cachedInputPorts = null;
      _cachedOutputPorts = null;
      
      debugPrint(
        'PolyAlgorithmRouting: Voice count updated from ${config.voiceCount} to $newVoiceCount'
      );
    }
  }
  
  @override
  void dispose() {
    super.dispose();
    _cachedInputPorts = null;
    _cachedOutputPorts = null;
    debugPrint('PolyAlgorithmRouting: Disposed');
  }
}