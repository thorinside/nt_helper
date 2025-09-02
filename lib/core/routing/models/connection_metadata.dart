import 'package:freezed_annotation/freezed_annotation.dart';

part 'connection_metadata.freezed.dart';
part 'connection_metadata.g.dart';

/// Classification of connection types in the routing system
enum ConnectionClass {
  /// Connection between hardware (physical I/O) and algorithm
  hardware,
  
  /// Connection between two algorithms
  algorithm,
  
  /// User-created direct connection (future feature)
  user,
}

/// Types of signals that can flow through connections
enum SignalType {
  /// Audio signal
  audio,
  
  /// Control voltage signal
  cv,
  
  /// Gate/trigger signal
  gate,
  
  /// Clock/timing signal
  clock,
  
  /// Mixed or unknown signal type
  mixed,
}

/// Type-safe metadata for connections in the routing system.
/// 
/// Stores all semantic information about a connection, allowing the
/// connection ID to remain a simple, opaque identifier.
@freezed
sealed class ConnectionMetadata with _$ConnectionMetadata {
  const factory ConnectionMetadata({
    /// Classification of this connection
    required ConnectionClass connectionClass,
    
    /// Bus number used for this connection (1-28, or 0 for direct)
    required int busNumber,
    
    /// Type of signal flowing through this connection
    required SignalType signalType,
    
    /// Source algorithm ID (for algorithm connections)
    String? sourceAlgorithmId,
    
    /// Target algorithm ID (for algorithm connections)
    String? targetAlgorithmId,
    
    /// Source parameter number (for algorithm connections)
    int? sourceParameterNumber,
    
    /// Target parameter number (for algorithm connections)
    int? targetParameterNumber,
    
    /// Whether this creates a backward edge in the execution graph
    bool? isBackwardEdge,
    
    /// Whether this connection is valid
    bool? isValid,
  }) = _ConnectionMetadata;

  factory ConnectionMetadata.fromJson(Map<String, dynamic> json) => 
      _$ConnectionMetadataFromJson(json);
  
  const ConnectionMetadata._();
  
  /// Helper to check if this is a hardware connection
  bool get isHardwareConnection => connectionClass == ConnectionClass.hardware;
  
  /// Helper to check if this is an algorithm connection
  bool get isAlgorithmConnection => connectionClass == ConnectionClass.algorithm;
  
  /// Helper to check if this is a user connection
  bool get isUserConnection => connectionClass == ConnectionClass.user;
  
  /// Helper to check if validation has been performed
  bool get hasValidation => isValid != null;
}