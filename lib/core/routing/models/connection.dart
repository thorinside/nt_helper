import 'package:freezed_annotation/freezed_annotation.dart';

part 'connection.freezed.dart';
part 'connection.g.dart';

/// Enum representing the status of a connection
@JsonEnum()
enum ConnectionStatus {
  /// Connection is active and working
  active,
  
  /// Connection is temporarily disabled
  disabled,
  
  /// Connection has an error
  error,
  
  /// Connection is being established
  connecting,
}

/// Immutable data class representing a connection between two ports.
/// 
/// A connection represents a signal path from a source port to a destination port.
/// It includes metadata about the connection status, signal properties, and any
/// transformation applied to the signal.
/// 
/// Example:
/// ```dart
/// final connection = Connection(
///   id: 'audio_in_1_to_audio_out_1',
///   sourcePortId: 'audio_in_1',
///   destinationPortId: 'audio_out_1',
///   status: ConnectionStatus.active,
/// );
/// ```
@freezed
sealed class Connection with _$Connection {
  const factory Connection({
    /// Unique identifier for this connection
    required String id,
    
    /// ID of the source port
    required String sourcePortId,
    
    /// ID of the destination port
    required String destinationPortId,
    
    /// Current status of the connection
    @Default(ConnectionStatus.active) ConnectionStatus status,
    
    /// Optional name for the connection
    String? name,
    
    /// Optional description of what this connection does
    String? description,
    
    /// Signal gain/attenuation factor (1.0 = no change)
    @Default(1.0) double gain,
    
    /// Whether the connection is muted
    @Default(false) bool isMuted,
    
    /// Whether the connection is inverted
    @Default(false) bool isInverted,
    
    /// Optional delay in milliseconds
    @Default(0.0) double delayMs,
    
    /// Additional connection properties
    Map<String, dynamic>? properties,
    
    /// Timestamp when the connection was created
    DateTime? createdAt,
    
    /// Timestamp when the connection was last modified
    DateTime? modifiedAt,
  }) = _Connection;

  /// Creates a Connection from JSON
  factory Connection.fromJson(Map<String, dynamic> json) => _$ConnectionFromJson(json);
  
  const Connection._();
  
  /// Returns true if the connection is currently active
  bool get isActive => status == ConnectionStatus.active;
  
  /// Returns true if the connection has an error
  bool get hasError => status == ConnectionStatus.error;
  
  /// Returns true if the connection is currently being established
  bool get isConnecting => status == ConnectionStatus.connecting;
  
  /// Returns true if the connection is disabled
  bool get isDisabled => status == ConnectionStatus.disabled;
  
  /// Returns the effective gain (considering mute state)
  double get effectiveGain {
    if (isMuted) return 0.0;
    return isInverted ? -gain : gain;
  }
  
  /// Creates a copy of this connection with a new status
  Connection withStatus(ConnectionStatus newStatus) {
    return copyWith(
      status: newStatus,
      modifiedAt: DateTime.now(),
    );
  }
  
  /// Creates a copy of this connection with updated properties
  Connection withProperties(Map<String, dynamic> newProperties) {
    return copyWith(
      properties: newProperties,
      modifiedAt: DateTime.now(),
    );
  }
  
  /// Creates a copy of this connection with updated gain
  Connection withGain(double newGain) {
    return copyWith(
      gain: newGain,
      modifiedAt: DateTime.now(),
    );
  }
}