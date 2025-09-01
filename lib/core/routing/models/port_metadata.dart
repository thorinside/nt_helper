import 'package:freezed_annotation/freezed_annotation.dart';

part 'port_metadata.freezed.dart';
part 'port_metadata.g.dart';

/// Type-safe metadata for ports in the routing system.
/// 
/// Uses a union type to distinguish between hardware ports (physical I/O)
/// and algorithm ports, ensuring type safety and preventing mixing of
/// incompatible metadata.
@freezed
sealed class PortMetadata with _$PortMetadata {
  /// Metadata for hardware (physical) input/output ports.
  /// 
  /// These represent the physical jacks on the Disting NT hardware:
  /// - Input jacks 1-12 (buses 1-12)
  /// - Output jacks 1-8 (buses 13-20)
  const factory PortMetadata.hardware({
    /// Bus number this port is connected to (1-20)
    required int busNumber,
    
    /// Whether this is an input (true) or output (false) port
    required bool isInput,
    
    /// Physical jack number (1-12 for inputs, 1-8 for outputs)
    required int jackNumber,
  }) = HardwarePortMetadata;
  
  /// Metadata for algorithm ports.
  /// 
  /// These represent the inputs and outputs of algorithms loaded into
  /// the Disting NT's slots. Each port is associated with a specific
  /// parameter that controls its bus assignment.
  const factory PortMetadata.algorithm({
    /// Stable UUID of the algorithm instance
    required String algorithmId,
    
    /// Parameter number that controls this port's bus assignment
    required int parameterNumber,
    
    /// Human-readable name of the parameter
    required String parameterName,
    
    /// Current bus assignment (null if not connected)
    int? busNumber,
    
    /// Voice number for polyphonic algorithms
    String? voiceNumber,
    
    /// Channel designation ('left', 'right', 'mono')
    String? channel,
  }) = AlgorithmPortMetadata;

  factory PortMetadata.fromJson(Map<String, dynamic> json) => 
      _$PortMetadataFromJson(json);
}