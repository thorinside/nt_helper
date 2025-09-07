import 'package:freezed_annotation/freezed_annotation.dart';

part 'port.freezed.dart';
part 'port.g.dart';

/// Enum representing the different types of ports in the routing system
@JsonEnum()
enum PortType {
  /// Audio signal port
  audio,
  
  /// Control Voltage (CV) port
  cv,
  
  /// Gate/trigger signal port
  gate,
  
  /// Digital/clock signal port
  clock,
}

/// Enum representing the output mode for output ports
@JsonEnum()
enum OutputMode {
  /// Add mode - output is mixed with other outputs on the same bus
  add,
  
  /// Replace mode - output replaces any previous output on the same bus
  replace,
}

/// Enum representing the direction of a port
@JsonEnum()
enum PortDirection {
  /// Input port - receives signals
  input,
  
  /// Output port - sends signals
  output,
  
  /// Bidirectional port - can send and receive
  bidirectional,
}

/// Immutable data class representing a port in the routing system.
/// 
/// A port is a connection point that can send or receive signals.
/// Each port has a unique identifier, name, type, and direction.
/// 
/// Example:
/// ```dart
/// final port = Port(
///   id: 'audio_in_1',
///   name: 'Audio Input 1',
///   type: PortType.audio,
///   direction: PortDirection.input,
/// );
/// ```
@freezed
sealed class Port with _$Port {
  const factory Port({
    /// Unique identifier for this port
    required String id,
    
    /// Human-readable name of the port
    required String name,
    
    /// The type of signal this port handles
    required PortType type,
    
    /// The direction of signal flow for this port
    required PortDirection direction,
    
    /// Optional description of the port's purpose
    String? description,
    
    /// Optional constraints for this port (e.g., voltage range, frequency)
    Map<String, dynamic>? constraints,
    
    /// Whether this port is currently active/enabled
    @Default(true) bool isActive,
    
    /// Optional output mode for output ports (add or replace)
    OutputMode? outputMode,
    
    // Direct properties for polyphonic routing
    /// Whether this port represents a polyphonic voice
    @Default(false) bool isPolyVoice,
    
    /// The voice number for polyphonic ports (1-based indexing)
    int? voiceNumber,
    
    /// Whether this port is a virtual CV port
    @Default(false) bool isVirtualCV,
    
    // Direct properties for multi-channel routing
    /// Whether this port is part of a multi-channel configuration
    @Default(false) bool isMultiChannel,
    
    /// The channel number for multi-channel ports (0-based indexing)
    int? channelNumber,
    
    /// Whether this port is part of a stereo channel pair
    @Default(false) bool isStereoChannel,
    
    /// The stereo side for stereo channel ports ('left' or 'right')
    String? stereoSide,
    
    /// Whether this port represents the master mix output
    @Default(false) bool isMasterMix,
    
    // Direct properties for bus and parameter routing
    /// The bus number this port is connected to (1-20)
    int? busValue,
    
    /// The parameter name associated with this port's bus assignment
    String? busParam,
    
    /// The parameter number associated with this port
    int? parameterNumber,
    
    /// The mode parameter number for this port's output mode (Add/Replace)
    int? modeParameterNumber,
    
    // Direct properties for physical ports
    /// Whether this port represents a physical hardware port
    @Default(false) bool isPhysical,
    
    /// The hardware index for physical ports (1-based)
    int? hardwareIndex,
    
    /// The jack type for physical ports ('input' or 'output')
    String? jackType,
    
    /// The node identifier for grouping related ports
    String? nodeId,
  }) = _Port;

  /// Creates a Port from JSON
  factory Port.fromJson(Map<String, dynamic> json) => _$PortFromJson(json);
  
  const Port._();
  
  /// Returns true if this is an input port
  bool get isInput => direction == PortDirection.input || direction == PortDirection.bidirectional;
  
  /// Returns true if this is an output port  
  bool get isOutput => direction == PortDirection.output || direction == PortDirection.bidirectional;
  
  /// Returns true if this port is connected (has a bus assignment)
  bool get isConnected => busValue != null && busValue! > 0;
  
  /// Returns true if this port can be connected to another port based on direction
  bool canConnectTo(Port other) {
    // Can only connect output to input or bidirectional ports
    if (isOutput && other.isInput) return true;
    if (isInput && other.isOutput) return true;
    
    // Bidirectional ports can connect to any port
    if (direction == PortDirection.bidirectional || other.direction == PortDirection.bidirectional) {
      return true;
    }
    
    return false;
  }
  
  /// Returns true if this port is compatible with another port's type
  bool isCompatibleWith(Port other) {
    // Same types are always compatible
    if (type == other.type) return true;
    
    // CV and audio can be cross-compatible in many cases
    if ((type == PortType.cv && other.type == PortType.audio) ||
        (type == PortType.audio && other.type == PortType.cv)) {
      return true;
    }
    
    // Clock and gate signals can sometimes be compatible
    if ((type == PortType.clock && other.type == PortType.gate) ||
        (type == PortType.gate && other.type == PortType.clock)) {
      return true;
    }
    
    return false;
  }
}