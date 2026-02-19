/// Bus mapping utilities for MCP tools
/// Maps between bus numbers and semantic names for easier routing configuration
class BusMapping {
  static const Map<int, String> _busToName = {
    0: 'None',
    1: 'Input 1',
    2: 'Input 2',
    3: 'Input 3',
    4: 'Input 4',
    5: 'Input 5',
    6: 'Input 6',
    7: 'Input 7',
    8: 'Input 8',
    9: 'Input 9',
    10: 'Input 10',
    11: 'Input 11',
    12: 'Input 12',
    13: 'Output 1',
    14: 'Output 2',
    15: 'Output 3',
    16: 'Output 4',
    17: 'Output 5',
    18: 'Output 6',
    19: 'Output 7',
    20: 'Output 8',
    21: 'Aux 1',
    22: 'Aux 2',
    23: 'Aux 3',
    24: 'Aux 4',
    25: 'Aux 5',
    26: 'Aux 6',
    27: 'Aux 7',
    28: 'Aux 8',
  };

  static const Map<String, int> _nameToBus = {
    'None': 0,
    'Input 1': 1,
    'Input 2': 2,
    'Input 3': 3,
    'Input 4': 4,
    'Input 5': 5,
    'Input 6': 6,
    'Input 7': 7,
    'Input 8': 8,
    'Input 9': 9,
    'Input 10': 10,
    'Input 11': 11,
    'Input 12': 12,
    'Output 1': 13,
    'Output 2': 14,
    'Output 3': 15,
    'Output 4': 16,
    'Output 5': 17,
    'Output 6': 18,
    'Output 7': 19,
    'Output 8': 20,
    'Aux 1': 21,
    'Aux 2': 22,
    'Aux 3': 23,
    'Aux 4': 24,
    'Aux 5': 25,
    'Aux 6': 26,
    'Aux 7': 27,
    'Aux 8': 28,
  };

  /// Convert bus number to semantic name
  static String? busToName(int busNumber) {
    return _busToName[busNumber];
  }

  /// Convert semantic name to bus number
  static int? nameToBus(String name) {
    // Case-insensitive lookup
    final normalizedName = name.trim().toLowerCase();
    for (final entry in _nameToBus.entries) {
      if (entry.key.toLowerCase() == normalizedName) {
        return entry.value;
      }
    }
    return null;
  }

  /// Get all available bus names
  static List<String> get allBusNames => _busToName.values.toList();

  /// Get all available bus numbers
  static List<int> get allBusNumbers => _busToName.keys.toList();

  /// Check if a bus number is valid
  static bool isValidBusNumber(int busNumber) {
    return _busToName.containsKey(busNumber);
  }

  /// Check if a bus name is valid
  static bool isValidBusName(String name) {
    return nameToBus(name) != null;
  }

  /// Format bus for display (includes both number and name)
  static String formatBus(int busNumber) {
    final name = busToName(busNumber);
    return name != null ? '$name ($busNumber)' : 'Unknown ($busNumber)';
  }

  /// Parse bus from either number or name string
  static int? parseBus(dynamic value) {
    if (value is int) {
      return isValidBusNumber(value) ? value : null;
    } else if (value is String) {
      // Try parsing as number first
      final asNumber = int.tryParse(value);
      if (asNumber != null && isValidBusNumber(asNumber)) {
        return asNumber;
      }
      // Try as name
      return nameToBus(value);
    }
    return null;
  }

  /// Get a human-readable routing description
  static String describeRouting(int fromBus, int toBus) {
    final from = busToName(fromBus) ?? 'Unknown';
    final to = busToName(toBus) ?? 'Unknown';
    return '$from → $to';
  }
}