part of 'disting_cubit.dart';

class _StateRefreshDelegate {
  _StateRefreshDelegate(this._cubit);

  final DistingCubit _cubit;
  int _refreshGeneration = 0;

  Future<void> refreshStateFromManager({
    Duration delay = const Duration(milliseconds: 50),
  }) async {
    final stopwatch = Stopwatch()..start();
    _diag('refresh start delay=${delay.inMilliseconds}ms');
    final currentState = _cubit.state;
    if (currentState is! DistingStateSynchronized) {
      _diag('refresh skipped state=${currentState.runtimeType}');
      return;
    }

    final generation = ++_refreshGeneration;
    _cubit._emitState(currentState.copyWith(loading: true));
    final guardedState = _cubit.state;
    await Future.delayed(delay);

    final disting = currentState.disting; // Could be online or offline

    try {
      _diag('refresh requestNumAlgorithmsInPreset start');
      final numAlgorithmsInPreset =
          (await disting.requestNumAlgorithmsInPreset()) ?? 0;
      _diag(
        'refresh requestNumAlgorithmsInPreset done count=$numAlgorithmsInPreset',
      );
      _diag('refresh requestPresetName start');
      final presetName = await disting.requestPresetName() ?? "Error";
      _diag('refresh requestPresetName done name="$presetName"');
      _diag('refresh fetchSlots start count=$numAlgorithmsInPreset');
      final fetchedSlots = await _cubit.fetchSlots(
        numAlgorithmsInPreset,
        disting,
      );
      final slots = _cubit._preserveKnownSlotSpecificationsForRefresh(
        previousState: currentState,
        refreshedDisting: disting,
        refreshedPresetName: presetName,
        refreshedSlots: fetchedSlots,
      );
      _diag(
        'refresh fetchSlots done fetched=${slots.length} '
        'elapsed=${stopwatch.elapsedMilliseconds}ms',
      );

      // Re-fetch perf page items if firmware supports them (v1.16+)
      List<PerformancePageItem>? perfPageItems;
      if (currentState.firmwareVersion.hasPerfPageItems) {
        _diag('refresh perfPageItems start');
        perfPageItems = await _cubit._perfPageDelegate.fetchAllPerfPageItems(
          disting,
        );
        _diag(
          'refresh perfPageItems done count=${perfPageItems.length} '
          'elapsed=${stopwatch.elapsedMilliseconds}ms',
        );
      }

      if (!_isCurrentRefresh(generation, guardedState, disting)) {
        _diag('refresh discarded because newer state superseded it');
        _clearLoadingIfOwned(generation, disting);
        return;
      }

      _cubit._emitState(
        currentState.copyWith(
          loading: false,
          presetName: presetName,
          slots: slots,
          perfPageItems: perfPageItems ?? currentState.perfPageItems,
          isDirty: false,
        ),
      );

      // Rebuild CC notification lookup since slots may have changed
      _cubit._ccNotificationDelegate.rebuildLookup();
      _diag('refresh done elapsed=${stopwatch.elapsedMilliseconds}ms');
    } catch (e, stackTrace) {
      _diag(
        'refresh failed elapsed=${stopwatch.elapsedMilliseconds}ms '
        'error=$e',
      );
      debugPrintStack(stackTrace: stackTrace);
      if (_isCurrentRefresh(generation, guardedState, disting)) {
        _cubit._emitState(currentState.copyWith(loading: false));
      } else {
        _clearLoadingIfOwned(generation, disting);
      }
    }
  }

  bool _isCurrentRefresh(
    int generation,
    DistingState guardedState,
    IDistingMidiManager disting,
  ) {
    if (generation != _refreshGeneration ||
        !identical(_cubit.state, guardedState)) {
      return false;
    }
    final state = _cubit.state;
    return state is DistingStateSynchronized &&
        identical(state.disting, disting);
  }

  void _clearLoadingIfOwned(int generation, IDistingMidiManager disting) {
    if (generation != _refreshGeneration) return;
    final state = _cubit.state;
    if (state is DistingStateSynchronized &&
        identical(state.disting, disting) &&
        state.loading) {
      _cubit._emitState(state.copyWith(loading: false));
    }
  }

  void _diag(String message) {
    debugPrint(
      '[NT_DIAG refresh ${DateTime.now().toIso8601String()}] $message',
    );
  }
}
