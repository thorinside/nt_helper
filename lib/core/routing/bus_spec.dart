/// Centralized bus ranges and helpers for the Disting NT routing domain.
///
/// Keep all numeric ranges in one place to avoid drift between
/// discovery, formatting, UI prechecks, and bus assignment policies.
class BusSpec {
  // Global valid range (includes ES-5 expansion)
  static const int min = 1;
  static const int max = 30;

  // Extended max for firmware 1.15+ (44 AUX buses: 21-64, ES-5 at 65-66)
  static const int extendedMax = 66;

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

  // ES-5 expansion — legacy position (pre-1.15 firmware)
  static const int es5Min = 29;
  static const int es5Max = 30;

  // ES-5 expansion — extended position (firmware 1.15+)
  static const int es5MinExtended = 65;
  static const int es5MaxExtended = 66;

  static bool isValid(int? n) => n != null && n >= min && n <= extendedMax;
  static bool isPhysicalInput(int n) => n >= inputMin && n <= inputMax;
  static bool isPhysicalOutput(int n) => n >= outputMin && n <= outputMax;

  /// Legacy ES-5 check (buses 29-30). Use [isEs5ForFirmware] when firmware
  /// context is available.
  static bool isEs5(int n) => n >= es5Min && n <= es5Max;

  /// Extended ES-5 check (buses 65-66, firmware 1.15+).
  static bool isEs5Extended(int n) => n >= es5MinExtended && n <= es5MaxExtended;

  /// Firmware-aware ES-5 check.
  /// On 1.15+, ES-5 is at 65-66; on older firmware, at 29-30.
  static bool isEs5ForFirmware(
    int n, {
    required bool hasExtendedAuxBuses,
  }) =>
      hasExtendedAuxBuses ? isEs5Extended(n) : isEs5(n);

  /// Legacy aux check — excludes legacy ES-5 (29-30).
  /// Use [isAuxForFirmware] when firmware context is available.
  static bool isAux(int n) =>
      n >= auxMin && n <= auxMaxExtended && !isEs5(n);

  /// Firmware-aware aux check.
  /// On 1.15+, 29-30 are regular aux buses and ES-5 is at 65-66.
  static bool isAuxForFirmware(
    int n, {
    required bool hasExtendedAuxBuses,
  }) =>
      n >= auxMin && n <= auxMaxExtended &&
      !isEs5ForFirmware(n, hasExtendedAuxBuses: hasExtendedAuxBuses);

  /// Whether a parameter max value indicates a bus assignment parameter.
  /// Accepts all known bus ceilings: 27, 28, 30 (old firmware), 64, 66 (1.15+).
  static bool isBusParameterMaxValue(int max) =>
      max >= inputMax && max <= extendedMax;

  /// Returns the AUX bus ceiling based on firmware capability.
  static int auxMaxForFirmware({required bool hasExtendedAuxBuses}) =>
      hasExtendedAuxBuses ? auxMaxExtended : auxMax;

  /// Returns the local (1-based) index for a given global bus number
  /// within its category, or null if invalid.
  /// Uses legacy ES-5 (29-30). See [toLocalNumberForFirmware] for
  /// firmware-aware variant.
  static int? toLocalNumber(int? n) {
    if (!isValid(n)) return null;
    final v = n!;
    if (isPhysicalInput(v)) return v;
    if (isPhysicalOutput(v)) return v - (outputMin - 1);
    if (isEs5(v)) return v - (es5Min - 1);
    if (isEs5Extended(v)) return v - (es5MinExtended - 1);
    if (isAux(v)) return v - (auxMin - 1);
    return null;
  }

  /// Firmware-aware local number conversion.
  /// On 1.15+, buses 29-30 are aux (local 9-10) and 65-66 are ES-5 (local 1-2).
  static int? toLocalNumberForFirmware(
    int? n, {
    required bool hasExtendedAuxBuses,
  }) {
    if (!isValid(n)) return null;
    final v = n!;
    if (isPhysicalInput(v)) return v;
    if (isPhysicalOutput(v)) return v - (outputMin - 1);
    if (isEs5ForFirmware(v, hasExtendedAuxBuses: hasExtendedAuxBuses)) {
      return hasExtendedAuxBuses
          ? v - (es5MinExtended - 1)
          : v - (es5Min - 1);
    }
    if (isAuxForFirmware(v, hasExtendedAuxBuses: hasExtendedAuxBuses)) {
      return v - (auxMin - 1);
    }
    return null;
  }
}
