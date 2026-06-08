/// Direction of a single adjacent slot swap.
///
/// [up] swaps the element at `index` with the one at `index - 1`;
/// [down] swaps it with the one at `index + 1`. These map directly onto
/// `DistingCubit.moveAlgorithmUp` / `moveAlgorithmDown`.
enum SwapDirection { up, down }

/// A single adjacent swap to apply, identified by the moved element's index in
/// the working order just before the step runs.
class SwapStep {
  final int index;
  final SwapDirection direction;

  const SwapStep(this.index, this.direction);

  @override
  bool operator ==(Object other) =>
      other is SwapStep && other.index == index && other.direction == direction;

  @override
  int get hashCode => Object.hash(index, direction);

  @override
  String toString() => 'SwapStep($index, ${direction.name})';
}

/// Plans the adjacent swaps needed to realize a target slot order.
///
/// Reordering on the Disting NT is only available as adjacent swaps
/// (`moveAlgorithmUp` / `moveAlgorithmDown`), so an arbitrary reordering is
/// realized by walking each target element up into place — the same approach
/// the MCP "insert at slot" loop uses. The result is a minimal sequence (its
/// length equals the number of inversions between the two orders).
class SlotReorderPlanner {
  /// Returns the swap steps that transform [currentOrder] into [targetOrder].
  /// Both must be permutations of the same set of ids.
  static List<SwapStep> planSwaps(
    List<String> currentOrder,
    List<String> targetOrder,
  ) {
    assert(currentOrder.length == targetOrder.length);
    final working = List<String>.from(currentOrder);
    final steps = <SwapStep>[];

    for (var i = 0; i < targetOrder.length; i++) {
      final wanted = targetOrder[i];
      var j = working.indexOf(wanted, i);
      assert(j >= 0, 'targetOrder is not a permutation of currentOrder');
      while (j > i) {
        final tmp = working[j];
        working[j] = working[j - 1];
        working[j - 1] = tmp;
        steps.add(SwapStep(j, SwapDirection.up));
        j--;
      }
    }
    return steps;
  }

  /// Applies [steps] to a copy of [order] and returns the result. Useful for
  /// verifying a plan (and round-tripping undo).
  static List<String> applySteps(List<String> order, List<SwapStep> steps) {
    final working = List<String>.from(order);
    for (final step in steps) {
      final i = step.index;
      final swapWith = step.direction == SwapDirection.up ? i - 1 : i + 1;
      final tmp = working[i];
      working[i] = working[swapWith];
      working[swapWith] = tmp;
    }
    return working;
  }
}
