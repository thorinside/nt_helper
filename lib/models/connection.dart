import 'package:freezed_annotation/freezed_annotation.dart';

part 'connection.freezed.dart';
part 'connection.g.dart';

@freezed
sealed class Connection with _$Connection {
  const factory Connection({
    required String id,
    required int sourceAlgorithmIndex,
    required String sourcePortId,
    required int targetAlgorithmIndex,
    required String targetPortId,
    required int assignedBus,  // Bus number (1-28)
    required bool replaceMode,  // true = Replace, false = Add
    @Default(false) bool isValid,
    String? edgeLabel,  // e.g., "A1 R", "O3 A", "I2 R"
  }) = _Connection;

  factory Connection.fromJson(Map<String, dynamic> json) =>
      _$ConnectionFromJson(json);
}

extension ConnectionHelpers on Connection {
  // Helper to generate edge label
  String getEdgeLabel() {
    final busType = assignedBus <= 12 ? 'I' : 
                   assignedBus <= 20 ? 'O' : 'A';
    final busNum = assignedBus <= 12 ? assignedBus :
                   assignedBus <= 20 ? assignedBus - 12 :
                   assignedBus - 20;
    // Omit mode for now since replace/add logic needs to check actual output mode parameters
    return '$busType$busNum';
  }
  
  /// Check if this connection violates execution order
  /// Source must come before target in slot order for signal flow to work
  /// (Disting NT processes algorithms in slot order)
  bool get violatesExecutionOrder => sourceAlgorithmIndex >= targetAlgorithmIndex;
}