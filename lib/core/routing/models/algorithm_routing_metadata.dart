import 'package:freezed_annotation/freezed_annotation.dart';

part 'algorithm_routing_metadata.freezed.dart';
part 'algorithm_routing_metadata.g.dart';

/// Enumeration defining the type of routing strategy an algorithm requires.
/// This determines which routing implementation will be instantiated.
enum RoutingType {
  /// Polyphonic routing for algorithms with multiple independent voices
  polyphonic,
  
  /// Multi-channel routing for width-based or single-channel algorithms  
  multiChannel;
}

/// Metadata that defines the routing requirements for an algorithm.
/// 
/// This model is decoupled from specific routing implementations and provides
/// the information needed by the RoutingFactory to determine which routing
/// type to instantiate. It focuses purely on algorithm characteristics that
/// affect routing behavior.
/// 
/// Example usage:
/// ```dart
/// // For a polyphonic algorithm
/// final polyMetadata = AlgorithmRoutingMetadata(
///   algorithmGuid: 'poly-synth-v1',
///   routingType: RoutingType.polyphonic,
///   voiceCount: 8,
///   requiresGateInputs: true,
/// );
/// 
/// // For a width-based algorithm
/// final multiMetadata = AlgorithmRoutingMetadata(
///   algorithmGuid: 'stereo-delay-v1',
///   routingType: RoutingType.multiChannel,
///   channelCount: 2,
///   supportsStereo: true,
/// );
/// ```
@freezed
sealed class AlgorithmRoutingMetadata with _$AlgorithmRoutingMetadata {
  const factory AlgorithmRoutingMetadata({
    /// Unique identifier for the algorithm
    required String algorithmGuid,
    
    /// The type of routing this algorithm requires
    required RoutingType routingType,
    
    /// Human-readable name for debugging/logging
    String? algorithmName,
    
    // === Polyphonic Algorithm Properties ===
    
    /// Number of polyphonic voices (relevant for polyphonic routing)
    /// Default: 1 (monophonic)
    @Default(1) int voiceCount,
    
    /// Whether the algorithm requires gate/trigger inputs for each voice
    @Default(false) bool requiresGateInputs,
    
    /// Whether the algorithm uses virtual CV ports for modulation
    @Default(false) bool usesVirtualCvPorts,
    
    /// Number of virtual CV ports per voice (when usesVirtualCvPorts is true)
    @Default(2) int virtualCvPortsPerVoice,
    
    // === Multi-Channel Algorithm Properties ===
    
    /// Number of channels (relevant for multi-channel routing)
    /// For normal algorithms: 1, for width-based algorithms: N
    @Default(1) int channelCount,
    
    /// Whether the algorithm supports stereo channel pairing
    @Default(false) bool supportsStereo,
    
    /// Whether channels can be independently routed
    @Default(true) bool allowsIndependentChannels,
    
    /// Whether to create master mix outputs for multi-channel algorithms
    @Default(true) bool createMasterMix,
    
    // === Common Properties ===
    
    /// Port types that this algorithm supports
    @Default([]) List<String> supportedPortTypes,
    
    /// Base name prefix for generated ports
    String? portNamePrefix,
    
    /// Additional algorithm-specific properties for extensibility
    /// 
    /// This map allows for future routing requirements without breaking
    /// the existing interface. New routing implementations can check for
    /// specific keys in this map to enable additional behavior.
    @Default({}) Map<String, dynamic> customProperties,
    
    /// Routing constraints or special requirements
    /// 
    /// Examples:
    /// - 'maxConnections': 8
    /// - 'requiresClockInput': true  
    /// - 'bypassable': true
    @Default({}) Map<String, dynamic> routingConstraints,
  }) = _AlgorithmRoutingMetadata;

  factory AlgorithmRoutingMetadata.fromJson(Map<String, dynamic> json) =>
      _$AlgorithmRoutingMetadataFromJson(json);
}

/// Extension methods for convenient metadata access
extension AlgorithmRoutingMetadataX on AlgorithmRoutingMetadata {
  /// Whether this algorithm is polyphonic
  bool get isPolyphonic => routingType == RoutingType.polyphonic;
  
  /// Whether this algorithm is multi-channel
  bool get isMultiChannel => routingType == RoutingType.multiChannel;
  
  /// Whether this algorithm has multiple channels or voices
  bool get hasMultipleChannelsOrVoices => 
      (isPolyphonic && voiceCount > 1) || 
      (isMultiChannel && channelCount > 1);
  
  /// Get the effective port name prefix, falling back to defaults
  String get effectivePortNamePrefix => 
      portNamePrefix ?? 
      (isPolyphonic ? 'Voice' : 'Ch');
  
  /// Get a constraint value with optional type casting
  T? getConstraint<T>(String key) {
    final value = routingConstraints[key];
    if (value is T) {
      return value;
    }
    return null;
  }
  
  /// Get a custom property value with optional type casting
  T? getCustomProperty<T>(String key) {
    final value = customProperties[key];
    if (value is T) {
      return value;
    }
    return null;
  }
  
  /// Whether this algorithm requires special gate handling
  bool get needsGateSupport => 
      requiresGateInputs || 
      supportedPortTypes.contains('gate') ||
      getConstraint<bool>('requiresClockInput') == true;
  
  /// Whether this algorithm uses CV modulation
  bool get usesCvModulation => 
      usesVirtualCvPorts || 
      supportedPortTypes.contains('cv');
  
  /// Get the total number of channels or voices for port generation
  int get totalPortUnits => isPolyphonic ? voiceCount : channelCount;
}

/// Factory methods for common algorithm types
extension AlgorithmRoutingMetadataFactory on AlgorithmRoutingMetadata {
  /// Create metadata for a standard polyphonic algorithm
  static AlgorithmRoutingMetadata polyphonic({
    required String algorithmGuid,
    String? algorithmName,
    required int voiceCount,
    bool requiresGateInputs = true,
    bool usesVirtualCvPorts = true,
    int virtualCvPortsPerVoice = 2,
    String portNamePrefix = 'Voice',
    List<String> supportedPortTypes = const ['audio', 'gate', 'cv'],
    Map<String, dynamic> customProperties = const {},
    Map<String, dynamic> routingConstraints = const {},
  }) {
    return AlgorithmRoutingMetadata(
      algorithmGuid: algorithmGuid,
      algorithmName: algorithmName,
      routingType: RoutingType.polyphonic,
      voiceCount: voiceCount,
      requiresGateInputs: requiresGateInputs,
      usesVirtualCvPorts: usesVirtualCvPorts,
      virtualCvPortsPerVoice: virtualCvPortsPerVoice,
      portNamePrefix: portNamePrefix,
      supportedPortTypes: supportedPortTypes,
      customProperties: customProperties,
      routingConstraints: routingConstraints,
    );
  }

  /// Create metadata for a normal (single-channel) algorithm
  static AlgorithmRoutingMetadata normal({
    required String algorithmGuid,
    String? algorithmName,
    String portNamePrefix = 'Main',
    List<String> supportedPortTypes = const ['audio', 'cv'],
    Map<String, dynamic> customProperties = const {},
    Map<String, dynamic> routingConstraints = const {},
  }) {
    return AlgorithmRoutingMetadata(
      algorithmGuid: algorithmGuid,
      algorithmName: algorithmName,
      routingType: RoutingType.multiChannel,
      channelCount: 1,
      supportsStereo: false,
      allowsIndependentChannels: true,
      createMasterMix: false,
      portNamePrefix: portNamePrefix,
      supportedPortTypes: supportedPortTypes,
      customProperties: customProperties,
      routingConstraints: routingConstraints,
    );
  }

  /// Create metadata for a width-based (multi-channel) algorithm
  static AlgorithmRoutingMetadata widthBased({
    required String algorithmGuid,
    String? algorithmName,
    required int channelCount,
    bool supportsStereo = true,
    bool allowsIndependentChannels = true,
    bool createMasterMix = true,
    String portNamePrefix = 'Ch',
    List<String> supportedPortTypes = const ['audio', 'cv'],
    Map<String, dynamic> customProperties = const {},
    Map<String, dynamic> routingConstraints = const {},
  }) {
    return AlgorithmRoutingMetadata(
      algorithmGuid: algorithmGuid,
      algorithmName: algorithmName,
      routingType: RoutingType.multiChannel,
      channelCount: channelCount,
      supportsStereo: supportsStereo,
      allowsIndependentChannels: allowsIndependentChannels,
      createMasterMix: createMasterMix,
      portNamePrefix: portNamePrefix,
      supportedPortTypes: supportedPortTypes,
      customProperties: customProperties,
      routingConstraints: routingConstraints,
    );
  }
}