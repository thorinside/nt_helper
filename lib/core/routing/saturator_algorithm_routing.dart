import 'package:nt_helper/cubit/disting_cubit.dart';
import 'multi_channel_algorithm_routing.dart';

/// Routing implementation for Saturator algorithm.
class SaturatorAlgorithmRouting extends MultiChannelAlgorithmRouting {
  /// The slot containing all algorithm data
  final Slot slot;

  static bool canHandle(Slot slot) {
    return slot.algorithm.guid == 'satu';
  }

  SaturatorAlgorithmRouting({
    required this.slot,
    required super.config,
    super.validator,
  });
}
