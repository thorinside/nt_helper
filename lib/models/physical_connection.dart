import 'package:freezed_annotation/freezed_annotation.dart';

part 'physical_connection.freezed.dart';
part 'physical_connection.g.dart';

/// Immutable data class representing a physical connection between hardware I/O
/// and algorithm ports.
/// 
/// Physical connections are derived from algorithm parameter bus assignments and
/// represent the signal routing from physical hardware jacks to algorithm inputs
/// and from algorithm outputs to physical hardware jacks.
/// 
/// These connections are read-only and automatically discovered based on the
/// current parameter values in each algorithm slot.
/// 
/// Example:
/// ```dart
/// final connection = PhysicalConnection(
///   id: 'phys_hw_in_1->alg_0_audio_input',
///   sourcePortId: 'hw_in_1',
///   targetPortId: 'alg_0_audio_input',
///   busNumber: 1,
///   isInputConnection: true,
///   algorithmIndex: 0,
/// );
/// ```
@freezed
sealed class PhysicalConnection with _$PhysicalConnection {
  const factory PhysicalConnection({
    /// Unique identifier for this connection using format: phys_${sourcePortId}->${targetPortId}
    required String id,
    
    /// ID of the source port (e.g., 'hw_in_1', 'alg_0_audio_output')
    required String sourcePortId,
    
    /// ID of the target port (e.g., 'alg_0_audio_input', 'hw_out_1')
    required String targetPortId,
    
    /// Bus number this connection uses (1-12 for inputs, 13-20 for outputs)
    required int busNumber,
    
    /// True if this is a connection from physical input to algorithm input,
    /// false if this is a connection from algorithm output to physical output
    required bool isInputConnection,
    
    /// Index of the algorithm involved in this connection
    required int algorithmIndex,
  }) = _PhysicalConnection;

  /// Creates a PhysicalConnection from JSON
  factory PhysicalConnection.fromJson(Map<String, dynamic> json) => 
      _$PhysicalConnectionFromJson(json);
  
  const PhysicalConnection._();
  
  /// Returns true if this connection involves a physical input (buses 1-12)
  bool get isPhysicalInput => busNumber >= 1 && busNumber <= 12;
  
  /// Returns true if this connection involves a physical output (buses 13-20)
  bool get isPhysicalOutput => busNumber >= 13 && busNumber <= 20;
  
  /// Returns the hardware port number (1-12 for inputs, 1-8 for outputs)
  int get hardwarePortNumber {
    if (isPhysicalInput) {
      return busNumber; // Bus 1-12 maps to hardware input 1-12
    } else if (isPhysicalOutput) {
      return busNumber - 12; // Bus 13-20 maps to hardware output 1-8
    } else {
      throw ArgumentError('Invalid bus number $busNumber for physical connection');
    }
  }
  
  /// Returns a human-readable description of this connection
  String get description {
    if (isInputConnection) {
      return 'Hardware Input $hardwarePortNumber → Algorithm $algorithmIndex';
    } else {
      return 'Algorithm $algorithmIndex → Hardware Output $hardwarePortNumber';
    }
  }
  
  /// Creates a deterministic ID from source and target port IDs
  static String generateId(String sourcePortId, String targetPortId) {
    return 'phys_$sourcePortId->$targetPortId';
  }
  
  /// Creates a PhysicalConnection with auto-generated deterministic ID
  factory PhysicalConnection.withGeneratedId({
    required String sourcePortId,
    required String targetPortId,
    required int busNumber,
    required bool isInputConnection,
    required int algorithmIndex,
  }) {
    return PhysicalConnection(
      id: generateId(sourcePortId, targetPortId),
      sourcePortId: sourcePortId,
      targetPortId: targetPortId,
      busNumber: busNumber,
      isInputConnection: isInputConnection,
      algorithmIndex: algorithmIndex,
    );
  }
}