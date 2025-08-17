import 'package:flutter/painting.dart';

class ConnectionPreview {
  final int sourceAlgorithmIndex;
  final String sourcePortId;
  final Offset cursorPosition;
  final bool isValid;
  final String? hoveredTargetPortId;
  final int? hoveredTargetAlgorithmIndex;
  final bool violatesExecutionOrder;

  const ConnectionPreview({
    required this.sourceAlgorithmIndex,
    required this.sourcePortId,
    required this.cursorPosition,
    required this.isValid,
    this.hoveredTargetPortId,
    this.hoveredTargetAlgorithmIndex,
    this.violatesExecutionOrder = false,
  });

  ConnectionPreview copyWith({
    int? sourceAlgorithmIndex,
    String? sourcePortId,
    Offset? cursorPosition,
    bool? isValid,
    String? hoveredTargetPortId,
    int? hoveredTargetAlgorithmIndex,
    bool? violatesExecutionOrder,
  }) {
    return ConnectionPreview(
      sourceAlgorithmIndex: sourceAlgorithmIndex ?? this.sourceAlgorithmIndex,
      sourcePortId: sourcePortId ?? this.sourcePortId,
      cursorPosition: cursorPosition ?? this.cursorPosition,
      isValid: isValid ?? this.isValid,
      hoveredTargetPortId: hoveredTargetPortId ?? this.hoveredTargetPortId,
      hoveredTargetAlgorithmIndex: hoveredTargetAlgorithmIndex ?? this.hoveredTargetAlgorithmIndex,
      violatesExecutionOrder: violatesExecutionOrder ?? this.violatesExecutionOrder,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ConnectionPreview &&
      other.sourceAlgorithmIndex == sourceAlgorithmIndex &&
      other.sourcePortId == sourcePortId &&
      other.cursorPosition == cursorPosition &&
      other.isValid == isValid &&
      other.hoveredTargetPortId == hoveredTargetPortId &&
      other.hoveredTargetAlgorithmIndex == hoveredTargetAlgorithmIndex;
  }

  @override
  int get hashCode {
    return Object.hash(
      sourceAlgorithmIndex,
      sourcePortId,
      cursorPosition,
      isValid,
      hoveredTargetPortId,
      hoveredTargetAlgorithmIndex,
    );
  }
}