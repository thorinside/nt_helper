/// Centralized bus ranges and helpers for the Disting NT routing domain.
///
/// Keep all numeric ranges in one place to avoid drift between
/// discovery, formatting, UI prechecks, and bus assignment policies.
class BusSpec {
  // Global valid range (includes ES-5 expansion)
  static const int min = 1;
  static const int max = 30;

  // Extended max for firmware 1.15+ (44 AUX buses: 21-64)
  static const int extendedMax = 64;

  // Physical input buses (wired from hardware inputs)
  static const int inputMin = 1;
  static const int inputMax = 12;

  // Physical output buses (wired to hardware outputs)
  static const int outputMin = 13;
  static const int outputMax = 20;

  // Auxiliary internal buses
  static const int auxMin = 21;
  static const int auxMax = 28;

  // Extended auxiliary buses (firmware 1.15+)
  static const int auxMaxExtended = 64;

  // ES-5 expansion (treated as physical output buses for edge mapping)
  static const int es5Min = 29;
  static const int es5Max = 30;

  static bool isValid(int? n) => n != null && n >= min && n <= extendedMax;
  static bool isPhysicalInput(int n) => n >= inputMin && n <= inputMax;
  static bool isPhysicalOutput(int n) => n >= outputMin && n <= outputMax;
  static bool isAux(int n) =>
      n >= auxMin && n <= auxMaxExtended && !isEs5(n);
  static bool isEs5(int n) => n >= es5Min && n <= es5Max;

  /// Whether a parameter max value indicates a bus assignment parameter.
  /// Accepts all known bus ceilings: 27, 28, 30 (old firmware), 64 (1.15+).
  static bool isBusParameterMaxValue(int max) =>
      max >= inputMax && max <= extendedMax;

  /// Returns the AUX bus ceiling based on firmware capability.
  static int auxMaxForFirmware({required bool hasExtendedAuxBuses}) =>
      hasExtendedAuxBuses ? auxMaxExtended : auxMax;

  /// Returns the local (1-based) index for a given global bus number
  /// within its category, or null if invalid.
  static int? toLocalNumber(int? n) {
    if (!isValid(n)) return null;
    final v = n!;
    if (isPhysicalInput(v)) return v;
    if (isPhysicalOutput(v)) return v - (outputMin - 1);
    if (isAux(v)) return v - (auxMin - 1);
    if (isEs5(v)) return v - (es5Min - 1);
    return null;
  }
}
