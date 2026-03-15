class PerformancePageItem {
  final int itemIndex;
  final bool enabled;
  final int slotIndex;
  final int parameterNumber;
  final int min;
  final int max;
  final String upperLabel;
  final String lowerLabel;

  const PerformancePageItem({
    required this.itemIndex,
    required this.enabled,
    this.slotIndex = 0,
    this.parameterNumber = 0,
    this.min = 0,
    this.max = 0,
    this.upperLabel = '',
    this.lowerLabel = '',
  });

  factory PerformancePageItem.empty(int itemIndex) {
    return PerformancePageItem(itemIndex: itemIndex, enabled: false);
  }

  PerformancePageItem copyWith({
    int? itemIndex,
    bool? enabled,
    int? slotIndex,
    int? parameterNumber,
    int? min,
    int? max,
    String? upperLabel,
    String? lowerLabel,
  }) {
    return PerformancePageItem(
      itemIndex: itemIndex ?? this.itemIndex,
      enabled: enabled ?? this.enabled,
      slotIndex: slotIndex ?? this.slotIndex,
      parameterNumber: parameterNumber ?? this.parameterNumber,
      min: min ?? this.min,
      max: max ?? this.max,
      upperLabel: upperLabel ?? this.upperLabel,
      lowerLabel: lowerLabel ?? this.lowerLabel,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PerformancePageItem &&
        other.itemIndex == itemIndex &&
        other.enabled == enabled &&
        other.slotIndex == slotIndex &&
        other.parameterNumber == parameterNumber &&
        other.min == min &&
        other.max == max &&
        other.upperLabel == upperLabel &&
        other.lowerLabel == lowerLabel;
  }

  @override
  int get hashCode => Object.hash(
        itemIndex,
        enabled,
        slotIndex,
        parameterNumber,
        min,
        max,
        upperLabel,
        lowerLabel,
      );

  @override
  String toString() =>
      'PerformancePageItem(item=$itemIndex, enabled=$enabled, slot=$slotIndex, '
      'param=$parameterNumber, min=$min, max=$max, '
      'upper="$upperLabel", lower="$lowerLabel")';
}
