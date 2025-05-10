/// Suppose you have a Dart model like this:
class RoutingInformation {
  final int algorithmIndex; // same as "slot" in JS
  final List<int>
      routingInfo; // 6 packed 32-bit values: [r0, r1, r2, r3, r4, r5]
  final String algorithmName; // to display in the table

  RoutingInformation({
    required this.algorithmIndex,
    required this.routingInfo,
    required this.algorithmName,
  });

  /// Serializes this RoutingInformation instance to a JSON map.
  Map<String, dynamic> toJson() => {
        'algorithmIndex': algorithmIndex,
        'routingInfo': routingInfo,
        'algorithmName': algorithmName,
      };
}

/// Utility function that replicates netInputMask(r) logic from JS.
int netInputMask(RoutingInformation r, bool showSignals, bool showMappings) {
  final inputMask = r.routingInfo[0];
  final mappingMask = r.routingInfo[5];
  if (showSignals && showMappings) return inputMask | mappingMask;
  if (showSignals) return inputMask;
  if (showMappings) return mappingMask;
  return 0;
}
