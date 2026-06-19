part of 'disting_cubit.dart';

class _StateRefreshDelegate {
  _StateRefreshDelegate(this._cubit);

  final DistingCubit _cubit;

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

    _cubit._emitState(currentState.copyWith(loading: true));
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
      final slots = await _cubit.fetchSlots(numAlgorithmsInPreset, disting);
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
      _cubit._emitState(currentState.copyWith(loading: false));
    }
  }

  void _diag(String message) {
    debugPrint(
      '[NT_DIAG refresh ${DateTime.now().toIso8601String()}] $message',
    );
  }
}
