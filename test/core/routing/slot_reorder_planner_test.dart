import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/core/routing/slot_reorder_planner.dart';

void main() {
  group('SlotReorderPlanner.planSwaps', () {
    test('no swaps when already in target order', () {
      expect(
        SlotReorderPlanner.planSwaps(['a', 'b', 'c'], ['a', 'b', 'c']),
        isEmpty,
      );
    });

    test('single adjacent swap', () {
      final steps = SlotReorderPlanner.planSwaps(['a', 'b'], ['b', 'a']);
      expect(steps, [const SwapStep(1, SwapDirection.up)]);
      expect(SlotReorderPlanner.applySteps(['a', 'b'], steps), ['b', 'a']);
    });

    test('walks an element up to the front', () {
      final steps = SlotReorderPlanner.planSwaps(
        ['a', 'b', 'c'],
        ['c', 'a', 'b'],
      );
      expect(steps, [
        const SwapStep(2, SwapDirection.up),
        const SwapStep(1, SwapDirection.up),
      ]);
      expect(
        SlotReorderPlanner.applySteps(['a', 'b', 'c'], steps),
        ['c', 'a', 'b'],
      );
    });

    test('step count equals the number of inversions', () {
      // Full reversal of 4 elements -> 6 inversions.
      final steps = SlotReorderPlanner.planSwaps(
        ['a', 'b', 'c', 'd'],
        ['d', 'c', 'b', 'a'],
      );
      expect(steps, hasLength(6));
      expect(
        SlotReorderPlanner.applySteps(['a', 'b', 'c', 'd'], steps),
        ['d', 'c', 'b', 'a'],
      );
    });

    test('plans realize many random permutations and undo round-trips', () {
      final ids = ['a', 'b', 'c', 'd', 'e', 'f'];
      // Deterministic set of shuffles.
      final targets = [
        ['f', 'e', 'd', 'c', 'b', 'a'],
        ['b', 'a', 'd', 'c', 'f', 'e'],
        ['c', 'f', 'a', 'e', 'b', 'd'],
        ['a', 'c', 'e', 'b', 'd', 'f'],
      ];
      for (final target in targets) {
        final forward = SlotReorderPlanner.planSwaps(ids, target);
        expect(SlotReorderPlanner.applySteps(ids, forward), target);

        // Undo: plan back from target to the original order.
        final back = SlotReorderPlanner.planSwaps(target, ids);
        expect(SlotReorderPlanner.applySteps(target, back), ids);
      }
    });
  });
}
