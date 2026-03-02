import 'package:nt_helper/core/routing/bus_spec.dart';
import 'package:nt_helper/domain/disting_nt_sysex.dart' show ParameterInfo;

/// Dynamic bus mapping utilities for MCP tools.
/// Maps between bus numbers and human-friendly names using [BusSpec].
class BusMapping {
  /// Convert bus number to human-friendly name.
  /// Returns "None" for 0, "Input 1"-"Input 12", "Output 1"-"Output 8",
  /// "Aux 1"-"Aux N", "ES-5 L"/"ES-5 R", or "Unknown (N)" for unrecognized.
  static String busToName(
    int busNumber, {
    required bool hasExtendedAuxBuses,
  }) {
    if (busNumber == 0) return 'None';
    if (BusSpec.isPhysicalInput(busNumber)) {
      return 'Input $busNumber';
    }
    if (BusSpec.isPhysicalOutput(busNumber)) {
      return 'Output ${busNumber - (BusSpec.outputMin - 1)}';
    }
    if (BusSpec.isEs5ForFirmware(busNumber,
        hasExtendedAuxBuses: hasExtendedAuxBuses)) {
      final local = hasExtendedAuxBuses
          ? busNumber - (BusSpec.es5MinExtended - 1)
          : busNumber - (BusSpec.es5Min - 1);
      return local == 1 ? 'ES-5 L' : 'ES-5 R';
    }
    if (BusSpec.isAuxForFirmware(busNumber,
        hasExtendedAuxBuses: hasExtendedAuxBuses)) {
      return 'Aux ${busNumber - (BusSpec.auxMin - 1)}';
    }
    return 'Unknown ($busNumber)';
  }

  static final _namePattern = RegExp(
    r'^(input|output|aux|es-5|none)\s*(\d+|l|r)?$',
    caseSensitive: false,
  );

  /// Convert human-friendly name to bus number.
  /// Case-insensitive. Returns null for unrecognized names.
  static int? nameToBus(
    String name, {
    required bool hasExtendedAuxBuses,
  }) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return null;

    final match = _namePattern.firstMatch(trimmed);
    if (match == null) return null;

    final category = match.group(1)!.toLowerCase();
    final suffix = match.group(2)?.toLowerCase();

    switch (category) {
      case 'none':
        return 0;
      case 'input':
        if (suffix == null) return null;
        final n = int.tryParse(suffix);
        if (n == null || n < 1 || n > BusSpec.inputMax) return null;
        return n;
      case 'output':
        if (suffix == null) return null;
        final n = int.tryParse(suffix);
        if (n == null || n < 1 || n > 8) return null;
        return BusSpec.outputMin - 1 + n;
      case 'aux':
        if (suffix == null) return null;
        final n = int.tryParse(suffix);
        if (n == null || n < 1) return null;
        final bus = BusSpec.auxMin - 1 + n;
        final auxMax =
            BusSpec.auxMaxForFirmware(hasExtendedAuxBuses: hasExtendedAuxBuses);
        // Skip over legacy ES-5 range on old firmware
        if (!hasExtendedAuxBuses && bus >= BusSpec.es5Min && bus <= BusSpec.es5Max) {
          return null;
        }
        if (bus > auxMax) return null;
        return bus;
      case 'es-5':
        if (suffix == null) return null;
        final int local;
        if (suffix == 'l') {
          local = 1;
        } else if (suffix == 'r') {
          local = 2;
        } else {
          return null;
        }
        return hasExtendedAuxBuses
            ? BusSpec.es5MinExtended - 1 + local
            : BusSpec.es5Min - 1 + local;
      default:
        return null;
    }
  }

  /// Parse bus from either a name string or raw integer.
  /// Accepts "Aux 1", "Input 5", "None", or integer bus numbers.
  static int? parseBus(
    dynamic value, {
    required bool hasExtendedAuxBuses,
  }) {
    if (value is int) {
      if (value == 0) return 0;
      return BusSpec.isValid(value) ? value : null;
    }
    if (value is String) {
      // Try as integer first
      final asInt = int.tryParse(value);
      if (asInt != null) {
        if (asInt == 0) return 0;
        return BusSpec.isValid(asInt) ? asInt : null;
      }
      return nameToBus(value, hasExtendedAuxBuses: hasExtendedAuxBuses);
    }
    return null;
  }

  /// Detect whether a parameter is a bus assignment parameter.
  /// Bus params have unit==1 (enum), min of 0 or 1, and a max value
  /// matching known bus ceilings.
  static bool isBusParameter(ParameterInfo param) {
    return param.unit == 1 &&
        (param.min == 0 || param.min == 1) &&
        BusSpec.isBusParameterMaxValue(param.max);
  }

}
