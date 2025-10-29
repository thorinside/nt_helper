import 'package:nt_helper/cubit/disting_cubit.dart';
import 'es5_direct_output_algorithm_routing.dart';

/// Specialized routing implementation for the Clock Multiplier algorithm.
///
/// The Clock Multiplier algorithm supports ES-5 direct output routing.
/// See [Es5DirectOutputAlgorithmRouting] for details on the dual-mode behavior.
class ClockMultiplierAlgorithmRouting extends Es5DirectOutputAlgorithmRouting {
  /// Creates a new ClockMultiplierAlgorithmRouting instance.
  ClockMultiplierAlgorithmRouting({
    required super.slot,
    required super.config,
    super.validator,
  });

  @override
  String get algorithmName => 'ClockMultiplierAlgorithmRouting';

  /// Checks if this routing implementation can handle the given slot.
  ///
  /// Returns true only for Clock Multiplier algorithm (guid: 'clkm').
  static bool canHandle(Slot slot) {
    return slot.algorithm.guid == 'clkm';
  }

  /// Creates a ClockMultiplierAlgorithmRouting instance from a slot.
  ///
  /// This factory method creates the specialized routing for Clock Multiplier algorithm.
  /// It processes normal input parameters (Clock input, Run/stop input, etc.) using
  /// the base routing extraction, but customizes output generation for ES-5 support.
  static ClockMultiplierAlgorithmRouting createFromSlot(
    Slot slot, {
    required Map<String, int> ioParameters,
    Map<String, int>? modeParameters,
    Map<String, ({int parameterNumber, int value})>? modeParametersWithNumbers,
    String? algorithmUuid,
  }) {
    final configData = Es5DirectOutputAlgorithmRouting.createConfigFromSlot(
      slot,
      ioParameters: ioParameters,
      modeParameters: modeParameters,
      modeParametersWithNumbers: modeParametersWithNumbers,
      algorithmUuid: algorithmUuid,
      debugName: 'ClockMultiplierAlgorithmRouting',
    );

    return ClockMultiplierAlgorithmRouting(slot: slot, config: configData.config);
  }
}
