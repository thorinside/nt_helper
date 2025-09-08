import '../../../core/routing/models/port.dart';

/// Enum representing the type of bus
enum BusType {
  /// Physical input buses (1-12)
  input,

  /// Physical output buses (13-20)
  output,

  /// Auxiliary buses (21-28)
  auxiliary,
}

/// Utility class for formatting bus numbers into readable labels
///
/// Converts bus numbers to their corresponding display format:
/// - Buses 1-12: "I1" through "I12" (physical inputs)
/// - Buses 13-20: "O1" through "O8" (physical outputs)
/// - Buses 21-28: "A1" through "A8" (auxiliary buses)
class BusLabelFormatter {
  /// Private constructor to prevent instantiation
  BusLabelFormatter._();

  /// Minimum valid bus number
  static const int minBusNumber = 1;

  /// Maximum valid bus number
  static const int maxBusNumber = 28;

  /// Input bus range
  static const int minInputBus = 1;
  static const int maxInputBus = 12;

  /// Output bus range
  static const int minOutputBus = 13;
  static const int maxOutputBus = 20;

  /// Auxiliary bus range
  static const int minAuxBus = 21;
  static const int maxAuxBus = 28;

  /// Formats a bus number into its display label
  ///
  /// Returns:
  /// - "I1" through "I12" for buses 1-12
  /// - "O1" through "O8" for buses 13-20
  /// - "A1" through "A8" for buses 21-28
  /// - null for invalid bus numbers
  static String? formatBusNumber(int? busNumber) {
    if (busNumber == null || !isValidBusNumber(busNumber)) {
      return null;
    }

    final localNumber = getLocalBusNumber(busNumber);
    if (localNumber == null) return null;

    final busType = getBusType(busNumber);
    switch (busType) {
      case BusType.input:
        return 'I$localNumber';
      case BusType.output:
        return 'O$localNumber';
      case BusType.auxiliary:
        return 'A$localNumber';
      case null:
        return null;
    }
  }

  /// Formats a bus number into its display label with optional output mode suffix
  ///
  /// Adds " R" suffix when [outputMode] is [OutputMode.replace] for
  /// both hardware output buses (13-20, "O#") and auxiliary buses
  /// (21-28, "A#"). Input buses (1-12, "I#") ignore the mode.
  ///
  /// Returns:
  /// - "I1" through "I12" for input buses (mode ignored)
  /// - "O1" through "O8" for output buses in add mode or null mode
  /// - "O1 R" through "O8 R" for output buses in replace mode
  /// - "A1" through "A8" for aux buses in add mode or null mode
  /// - "A1 R" through "A8 R" for aux buses in replace mode
  /// - null for invalid bus numbers
  static String? formatBusLabelWithMode(
    int? busNumber,
    OutputMode? outputMode,
  ) {
    if (busNumber == null || !isValidBusNumber(busNumber)) {
      return null;
    }

    final localNumber = getLocalBusNumber(busNumber);
    if (localNumber == null) return null;

    final busType = getBusType(busNumber);
    switch (busType) {
      case BusType.input:
        final baseLabel = 'I$localNumber';
        return outputMode == OutputMode.replace ? '$baseLabel R' : baseLabel;
      case BusType.output:
        final baseLabel = 'O$localNumber';
        return outputMode == OutputMode.replace ? '$baseLabel R' : baseLabel;
      case BusType.auxiliary:
        final baseLabel = 'A$localNumber';
        return outputMode == OutputMode.replace ? '$baseLabel R' : baseLabel;
      case null:
        return null;
    }
  }

  /// Determines the type of bus from its number
  ///
  /// Returns the [BusType] for valid bus numbers, null otherwise
  static BusType? getBusType(int? busNumber) {
    if (busNumber == null) return null;

    if (busNumber >= minInputBus && busNumber <= maxInputBus) {
      return BusType.input;
    } else if (busNumber >= minOutputBus && busNumber <= maxOutputBus) {
      return BusType.output;
    } else if (busNumber >= minAuxBus && busNumber <= maxAuxBus) {
      return BusType.auxiliary;
    }

    return null;
  }

  /// Checks if a bus number is valid
  ///
  /// Valid bus numbers are 1-28 inclusive
  static bool isValidBusNumber(int? busNumber) {
    if (busNumber == null) return false;
    return busNumber >= minBusNumber && busNumber <= maxBusNumber;
  }

  /// Gets the range of bus numbers for a specific bus type
  ///
  /// Returns a list with [min, max] bus numbers for the type
  static List<int> getBusRange(BusType busType) {
    switch (busType) {
      case BusType.input:
        return [minInputBus, maxInputBus];
      case BusType.output:
        return [minOutputBus, maxOutputBus];
      case BusType.auxiliary:
        return [minAuxBus, maxAuxBus];
    }
  }

  /// Converts a global bus number to its local number within its type
  ///
  /// For example:
  /// - Bus 1-12 returns 1-12 (unchanged for inputs)
  /// - Bus 13-20 returns 1-8 (outputs start at 1)
  /// - Bus 21-28 returns 1-8 (aux buses start at 1)
  static int? getLocalBusNumber(int? busNumber) {
    if (busNumber == null || !isValidBusNumber(busNumber)) {
      return null;
    }

    final busType = getBusType(busNumber);
    switch (busType) {
      case BusType.input:
        return busNumber; // Inputs are already 1-based
      case BusType.output:
        return busNumber - (minOutputBus - 1); // Convert 13-20 to 1-8
      case BusType.auxiliary:
        return busNumber - (minAuxBus - 1); // Convert 21-28 to 1-8
      case null:
        return null;
    }
  }
}
