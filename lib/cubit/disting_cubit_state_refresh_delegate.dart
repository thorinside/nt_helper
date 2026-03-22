part of 'disting_cubit.dart';

class _StateRefreshDelegate {
  _StateRefreshDelegate(this._cubit);

  final DistingCubit _cubit;

  Future<void> refreshStateFromManager({
    Duration delay = const Duration(milliseconds: 50),
  }) async {
    final currentState = _cubit.state;
    if (currentState is! DistingStateSynchronized) {
      return;
    }

    _cubit._emitState(currentState.copyWith(loading: true));
    await Future.delayed(delay);

    final disting = currentState.disting; // Could be online or offline

    try {
      final numAlgorithmsInPreset =
          (await disting.requestNumAlgorithmsInPreset()) ?? 0;
      final presetName = await disting.requestPresetName() ?? "Error";
      final slots = await _cubit.fetchSlots(numAlgorithmsInPreset, disting);

      // Re-fetch perf page items if firmware supports them (v1.16+)
      List<PerformancePageItem>? perfPageItems;
      if (currentState.firmwareVersion.hasPerfPageItems) {
        perfPageItems = await _cubit._perfPageDelegate
            .fetchAllPerfPageItems(disting);
      }

      _cubit._emitState(
        currentState.copyWith(
          loading: false,
          presetName: presetName,
          slots: slots,
          perfPageItems: perfPageItems ?? currentState.perfPageItems,
        ),
      );

      // Rebuild CC notification lookup since slots may have changed
      _cubit._ccNotificationDelegate.rebuildLookup();
    } catch (e, stackTrace) {
      debugPrintStack(stackTrace: stackTrace);
      _cubit._emitState(currentState.copyWith(loading: false));
    }
  }
}

