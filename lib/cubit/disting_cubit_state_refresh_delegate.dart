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

      _cubit._emitState(
        currentState.copyWith(
          loading: false,
          presetName: presetName,
          slots: slots,
          // Keep other fields like disting, version, algorithms, units, offline status
        ),
      );
    } catch (e, stackTrace) {
      debugPrintStack(stackTrace: stackTrace);
      _cubit._emitState(currentState.copyWith(loading: false));
    }
  }
}

