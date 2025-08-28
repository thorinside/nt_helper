import 'package:flutter/foundation.dart';
import 'algorithm_routing.dart';
import 'models/routing_state.dart';
import 'models/port.dart';
import 'models/connection.dart';
import 'port_compatibility_validator.dart';

/// Configuration data for multi-channel algorithm routing.
/// 
/// Defines the properties needed to configure width-based routing behavior,
/// including the number of channels and channel-specific properties.
@immutable
class MultiChannelAlgorithmConfig {
  /// Number of channels supported by this algorithm
  /// Default is 1 for normal algorithms, N for width-based algorithms
  final int channelCount;
  
  /// Whether this algorithm supports stereo channel pairing
  final bool supportsStereoChannels;
  
  /// Whether channels can be independently routed
  final bool allowsIndependentChannels;
  
  /// Port types supported by this algorithm
  final List<PortType> supportedPortTypes;
  
  /// Base name prefix for generated ports
  final String portNamePrefix;
  
  /// Whether to create a master mix output
  final bool createMasterMix;
  
  /// Additional algorithm-specific properties
  final Map<String, dynamic> algorithmProperties;

  const MultiChannelAlgorithmConfig({
    this.channelCount = 1,
    this.supportsStereoChannels = false,
    this.allowsIndependentChannels = true,
    this.supportedPortTypes = const [PortType.audio, PortType.cv],
    this.portNamePrefix = 'Ch',
    this.createMasterMix = true,
    this.algorithmProperties = const {},
  });
  
  /// Factory constructor for normal (single-channel) algorithms
  factory MultiChannelAlgorithmConfig.normal({
    String portNamePrefix = 'Main',
    List<PortType> supportedPortTypes = const [PortType.audio, PortType.cv],
  }) {
    return MultiChannelAlgorithmConfig(
      channelCount: 1,
      supportsStereoChannels: false,
      allowsIndependentChannels: true,
      supportedPortTypes: supportedPortTypes,
      portNamePrefix: portNamePrefix,
      createMasterMix: false,
    );
  }
  
  /// Factory constructor for width-based (multi-channel) algorithms
  factory MultiChannelAlgorithmConfig.widthBased({
    required int width,
    bool supportsStereo = true,
    String portNamePrefix = 'Ch',
    List<PortType> supportedPortTypes = const [PortType.audio, PortType.cv],
  }) {
    return MultiChannelAlgorithmConfig(
      channelCount: width,
      supportsStereoChannels: supportsStereo,
      allowsIndependentChannels: true,
      supportedPortTypes: supportedPortTypes,
      portNamePrefix: portNamePrefix,
      createMasterMix: true,
    );
  }
}

/// Concrete implementation of AlgorithmRouting for multi-channel routing.
/// 
/// This class handles width-based routing with configurable channel count.
/// It supports both normal algorithms (default width=1) and width-based 
/// algorithms with multiple channels.
/// 
/// Channel configurations can include:
/// - Single channel for normal algorithms
/// - Multiple independent channels for width-based algorithms  
/// - Stereo channel pairing when supported
/// - Master mix outputs for multi-channel setups
/// 
/// Example usage:
/// ```dart
/// // Normal single-channel algorithm
/// final normalConfig = MultiChannelAlgorithmConfig.normal();
/// final normalRouting = MultiChannelAlgorithmRouting(config: normalConfig);
/// 
/// // Width-based multi-channel algorithm
/// final widthConfig = MultiChannelAlgorithmConfig.widthBased(width: 4);
/// final widthRouting = MultiChannelAlgorithmRouting(config: widthConfig);
/// ```
class MultiChannelAlgorithmRouting extends AlgorithmRouting {
  /// Configuration for this multi-channel routing instance
  final MultiChannelAlgorithmConfig config;
  
  /// Current routing state
  RoutingState _state;
  
  /// Cached input ports to avoid regeneration
  List<Port>? _cachedInputPorts;
  
  /// Cached output ports to avoid regeneration
  List<Port>? _cachedOutputPorts;

  /// Creates a new MultiChannelAlgorithmRouting instance.
  /// 
  /// Parameters:
  /// - [config]: Configuration defining the multi-channel routing behavior
  /// - [validator]: Optional port compatibility validator (uses default if not provided)
  /// - [initialState]: Optional initial routing state
  MultiChannelAlgorithmRouting({
    required this.config,
    PortCompatibilityValidator? validator,
    RoutingState? initialState,
  }) : _state = initialState ?? const RoutingState(),
       super(validator: validator) {
    debugPrint(
      'MultiChannelAlgorithmRouting: Initialized with ${config.channelCount} channels, '
      'stereo: ${config.supportsStereoChannels}, mix: ${config.createMasterMix}'
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
    
    // Generate ports for each channel
    for (int channel = 0; channel < config.channelCount; channel++) {
      final channelNumber = channel + 1; // 1-based channel numbering
      
      // Generate ports for each supported type
      for (final portType in config.supportedPortTypes) {
        final portTypeName = _getPortTypeName(portType);
        
        if (config.supportsStereoChannels && portType == PortType.audio) {
          // Generate stereo pair for audio channels
          ports.add(Port(
            id: 'multi_${portType.name}_in_${channelNumber}_l',
            name: '${config.portNamePrefix} $channelNumber $portTypeName L',
            type: portType,
            direction: PortDirection.input,
            description: 'Left $portTypeName input for channel $channelNumber',
            metadata: {
              'channelNumber': channelNumber,
              'isMultiChannel': true,
              'isStereoChannel': true,
              'stereoSide': 'left',
            },
          ));
          
          ports.add(Port(
            id: 'multi_${portType.name}_in_${channelNumber}_r',
            name: '${config.portNamePrefix} $channelNumber $portTypeName R',
            type: portType,
            direction: PortDirection.input,
            description: 'Right $portTypeName input for channel $channelNumber',
            metadata: {
              'channelNumber': channelNumber,
              'isMultiChannel': true,
              'isStereoChannel': true,
              'stereoSide': 'right',
            },
          ));
        } else {
          // Generate mono port
          ports.add(Port(
            id: 'multi_${portType.name}_in_$channelNumber',
            name: '${config.portNamePrefix} $channelNumber $portTypeName In',
            type: portType,
            direction: PortDirection.input,
            description: '$portTypeName input for channel $channelNumber',
            metadata: {
              'channelNumber': channelNumber,
              'isMultiChannel': true,
              'isStereoChannel': false,
            },
          ));
        }
      }
    }
    
    debugPrint('MultiChannelAlgorithmRouting: Generated ${ports.length} input ports');
    return ports;
  }

  @override
  List<Port> generateOutputPorts() {
    final ports = <Port>[];
    
    // Generate ports for each channel
    for (int channel = 0; channel < config.channelCount; channel++) {
      final channelNumber = channel + 1;
      
      // Generate ports for each supported type
      for (final portType in config.supportedPortTypes) {
        final portTypeName = _getPortTypeName(portType);
        
        if (config.supportsStereoChannels && portType == PortType.audio) {
          // Generate stereo pair for audio channels
          ports.add(Port(
            id: 'multi_${portType.name}_out_${channelNumber}_l',
            name: '${config.portNamePrefix} $channelNumber $portTypeName L',
            type: portType,
            direction: PortDirection.output,
            description: 'Left $portTypeName output for channel $channelNumber',
            metadata: {
              'channelNumber': channelNumber,
              'isMultiChannel': true,
              'isStereoChannel': true,
              'stereoSide': 'left',
            },
          ));
          
          ports.add(Port(
            id: 'multi_${portType.name}_out_${channelNumber}_r',
            name: '${config.portNamePrefix} $channelNumber $portTypeName R',
            type: portType,
            direction: PortDirection.output,
            description: 'Right $portTypeName output for channel $channelNumber',
            metadata: {
              'channelNumber': channelNumber,
              'isMultiChannel': true,
              'isStereoChannel': true,
              'stereoSide': 'right',
            },
          ));
        } else {
          // Generate mono port
          ports.add(Port(
            id: 'multi_${portType.name}_out_$channelNumber',
            name: '${config.portNamePrefix} $channelNumber $portTypeName Out',
            type: portType,
            direction: PortDirection.output,
            description: '$portTypeName output for channel $channelNumber',
            metadata: {
              'channelNumber': channelNumber,
              'isMultiChannel': true,
              'isStereoChannel': false,
            },
          ));
        }
      }
    }
    
    // Create master mix outputs if enabled and we have multiple channels
    if (config.createMasterMix && config.channelCount > 1) {
      for (final portType in config.supportedPortTypes) {
        final portTypeName = _getPortTypeName(portType);
        
        if (config.supportsStereoChannels && portType == PortType.audio) {
          // Stereo master mix
          ports.add(Port(
            id: 'multi_mix_${portType.name}_out_l',
            name: 'Master Mix $portTypeName L',
            type: portType,
            direction: PortDirection.output,
            description: 'Left master mix $portTypeName output',
            metadata: {
              'isMasterMix': true,
              'channelCount': config.channelCount,
              'stereoSide': 'left',
            },
          ));
          
          ports.add(Port(
            id: 'multi_mix_${portType.name}_out_r',
            name: 'Master Mix $portTypeName R',
            type: portType,
            direction: PortDirection.output,
            description: 'Right master mix $portTypeName output',
            metadata: {
              'isMasterMix': true,
              'channelCount': config.channelCount,
              'stereoSide': 'right',
            },
          ));
        } else {
          // Mono master mix
          ports.add(Port(
            id: 'multi_mix_${portType.name}_out',
            name: 'Master Mix $portTypeName Out',
            type: portType,
            direction: PortDirection.output,
            description: 'Master mix $portTypeName output',
            metadata: {
              'isMasterMix': true,
              'channelCount': config.channelCount,
            },
          ));
        }
      }
    }
    
    debugPrint('MultiChannelAlgorithmRouting: Generated ${ports.length} output ports');
    return ports;
  }

  @override
  bool validateConnection(Port source, Port destination) {
    // First, use the base validation
    if (!super.validateConnection(source, destination)) {
      return false;
    }
    
    // Master mix connections have special rules (check first)
    if (_isMasterMixPort(source) || _isMasterMixPort(destination)) {
      return _validateMasterMixConnection(source, destination);
    }
    
    // Stereo channel validation
    if (_isStereoPort(source) || _isStereoPort(destination)) {
      return _validateStereoConnection(source, destination);
    }
    
    // Additional multi-channel specific validation
    if (_isMultiChannelPort(source) && _isMultiChannelPort(destination)) {
      return _validateMultiChannelConnection(source, destination);
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
    
    debugPrint('MultiChannelAlgorithmRouting: State updated');
  }
  
  /// Validates multi-channel specific connections
  bool _validateMultiChannelConnection(Port source, Port destination) {
    // If both ports are from specific channels, they should be compatible
    final sourceChannel = _getChannelNumber(source);
    final destChannel = _getChannelNumber(destination);
    
    // Allow connections between any channels if independent routing is enabled
    if (config.allowsIndependentChannels) {
      return true;
    }
    
    // Otherwise, channels must match
    if (sourceChannel != null && destChannel != null) {
      return sourceChannel == destChannel;
    }
    
    return true;
  }
  
  /// Validates stereo channel connections
  bool _validateStereoConnection(Port source, Port destination) {
    // If this routing doesn't support stereo, defer to base validation
    if (!config.supportsStereoChannels) {
      return true; // Let base validation handle it
    }
    
    // Stereo sides should match (left-to-left, right-to-right)
    final sourceSide = _getStereoSide(source);
    final destSide = _getStereoSide(destination);
    
    // If both have stereo sides, they must match
    if (sourceSide != null && destSide != null) {
      return sourceSide == destSide;
    }
    
    // Allow mono to stereo connections (source has no side, destination has side)
    // Allow stereo to mono connections (source has side, destination has no side)
    return true;
  }
  
  /// Validates master mix connections
  bool _validateMasterMixConnection(Port source, Port destination) {
    // Master mix outputs should only connect to external destinations
    if (_isMasterMixPort(source) && _isMultiChannelPort(destination)) {
      debugPrint(
        'MultiChannelAlgorithmRouting: Master mix should not connect back to channels'
      );
      return false;
    }
    
    return true;
  }
  
  /// Gets a human-readable name for a port type
  String _getPortTypeName(PortType type) {
    switch (type) {
      case PortType.audio:
        return 'Audio';
      case PortType.cv:
        return 'CV';
      case PortType.gate:
        return 'Gate';
      case PortType.clock:
        return 'Clock';
      case PortType.midi:
        return 'MIDI';
      case PortType.data:
        return 'Data';
    }
  }
  
  /// Checks if a port is a multi-channel port
  bool _isMultiChannelPort(Port port) {
    return port.metadata?['isMultiChannel'] == true;
  }
  
  /// Checks if a port is a stereo port
  bool _isStereoPort(Port port) {
    return port.metadata?['isStereoChannel'] == true;
  }
  
  /// Checks if a port is a master mix port
  bool _isMasterMixPort(Port port) {
    return port.metadata?['isMasterMix'] == true;
  }
  
  /// Gets the channel number from a multi-channel port
  int? _getChannelNumber(Port port) {
    return port.metadata?['channelNumber'] as int?;
  }
  
  /// Gets the stereo side from a stereo port
  String? _getStereoSide(Port port) {
    return port.metadata?['stereoSide'] as String?;
  }
  
  /// Updates the channel count and regenerates ports
  void updateChannelCount(int newChannelCount) {
    if (newChannelCount != config.channelCount && newChannelCount > 0) {
      // Clear cached ports to force regeneration
      _cachedInputPorts = null;
      _cachedOutputPorts = null;
      
      debugPrint(
        'MultiChannelAlgorithmRouting: Channel count updated from '
        '${config.channelCount} to $newChannelCount'
      );
    }
  }
  
  /// Gets all ports for a specific channel
  List<Port> getPortsForChannel(int channelNumber) {
    final allPorts = [...inputPorts, ...outputPorts];
    return allPorts.where((port) => 
      _getChannelNumber(port) == channelNumber
    ).toList();
  }
  
  /// Gets all master mix ports
  List<Port> getMasterMixPorts() {
    return outputPorts.where(_isMasterMixPort).toList();
  }
  
  /// Checks if the configuration supports the given channel count
  bool supportsChannelCount(int channelCount) {
    return channelCount > 0 && channelCount <= config.channelCount;
  }
  
  @override
  void dispose() {
    super.dispose();
    _cachedInputPorts = null;
    _cachedOutputPorts = null;
    debugPrint('MultiChannelAlgorithmRouting: Disposed');
  }
}