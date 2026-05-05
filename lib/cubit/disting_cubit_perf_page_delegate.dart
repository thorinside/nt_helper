part of 'disting_cubit.dart';

class _PerfPageDelegate {
  _PerfPageDelegate(this._cubit);

  final DistingCubit _cubit;

  /// Fetch all 30 performance page items via SysEx 0x57.
  Future<List<PerformancePageItem>> fetchAllPerfPageItems(
    IDistingMidiManager disting,
  ) async {
    final items = <PerformancePageItem>[];
    for (var i = 0; i < 30; i++) {
      final item = await disting.requestPerfPageItem(i);
      items.add(item ?? PerformancePageItem.empty(i));
    }
    return items;
  }

  /// Set a performance page item via SysEx 0x58 with optimistic update + verify.
  Future<void> setPerfPageItem(PerformancePageItem item) async {
    final currentState = _cubit.state;
    if (currentState is! DistingStateSynchronized) return;

    final disting = _cubit.requireDisting();

    // Optimistic update
    final updatedItems = List<PerformancePageItem>.from(
      currentState.perfPageItems,
    );
    if (item.itemIndex >= 0 && item.itemIndex < updatedItems.length) {
      updatedItems[item.itemIndex] = item;
    }
    _cubit._emitState(
      currentState.copyWith(perfPageItems: updatedItems, isDirty: true),
    );

    // Send to hardware
    disting.setPerfPageItem(item).catchError((e, s) {
      debugPrintStack(stackTrace: s);
    });

    // Verify with retry
    const maxRetries = 4;
    const baseDelay = Duration(milliseconds: 100);

    for (int attempt = 0; attempt < maxRetries; attempt++) {
      await Future.delayed(baseDelay * (1 << attempt));
      try {
        final actual = await disting.requestPerfPageItem(item.itemIndex);
        if (actual == null) continue;

        if (actual != item) {
          // On last attempt, accept hardware value
          if (attempt == maxRetries - 1) {
            final verifyState = _cubit.state;
            if (verifyState is DistingStateSynchronized) {
              final fixedItems = List<PerformancePageItem>.from(
                verifyState.perfPageItems,
              );
              if (item.itemIndex < fixedItems.length) {
                fixedItems[item.itemIndex] = actual;
              }
              _cubit._emitState(
                verifyState.copyWith(
                  perfPageItems: fixedItems,
                  isDirty: true,
                ),
              );
            }
          }
          continue;
        }
        return; // Verified
      } catch (e) {
        if (attempt == maxRetries - 1) break;
      }
    }
  }

  /// Remove a performance page item (set to disabled).
  Future<void> removePerfPageItem(int itemIndex) async {
    await setPerfPageItem(PerformancePageItem.empty(itemIndex));
  }

  /// Reorder performance page items by re-sending with updated indices.
  Future<void> reorderPerfPageItems(
    List<PerformancePageItem> reorderedItems,
  ) async {
    for (var i = 0; i < reorderedItems.length; i++) {
      final item = reorderedItems[i].copyWith(itemIndex: i);
      await setPerfPageItem(item);
    }
  }
}
