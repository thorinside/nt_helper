part of 'disting_cubit.dart';

class _CcNotificationDelegate {
  _CcNotificationDelegate(this._cubit);

  final DistingCubit _cubit;

  CcReverseLookup? _lookup;

  // 14-bit CC accumulation: key = (channel * 256 + cc), value = MSB value
  final Map<int, _Pending14Bit> _pending14BitMsb = {};

  // Feedback suppression: key = (algorithmIndex * 10000 + parameterNumber)
  final Map<int, DateTime> _outboundTimestamps = {};
  static const _feedbackWindow = Duration(milliseconds: 150);
  static const _maxOutboundEntries = 100;
  static const _maxPending14BitEntries = 32;

  // Preset load detection
  final Set<int> _batchParams = {};
  Timer? _batchTimer;
  static const _batchWindow = Duration(milliseconds: 200);
  static const _batchThreshold = 8;

  void start() {
    final state = _cubit.state;
    if (state is! DistingStateSynchronized) return;

    _lookup = CcReverseLookup.build(state.slots);
    if (_lookup!.isEmpty) return;

    _cubit.disting()?.setCcCallback(_onCcReceived);
  }

  void stop() {
    _cubit.disting()?.clearCcCallback();
    _lookup = null;
    _pending14BitMsb.clear();
    _outboundTimestamps.clear();
    _batchParams.clear();
    _batchTimer?.cancel();
    _batchTimer = null;
  }

  void rebuildLookup() {
    final state = _cubit.state;
    if (state is! DistingStateSynchronized) return;

    _lookup = CcReverseLookup.build(state.slots);
  }

  void markOutboundChange(int algorithmIndex, int parameterNumber) {
    final now = DateTime.now();
    _outboundTimestamps[algorithmIndex * 10000 + parameterNumber] = now;

    // Periodically prune expired entries to prevent unbounded growth
    if (_outboundTimestamps.length > _maxOutboundEntries) {
      _outboundTimestamps.removeWhere(
        (_, timestamp) => now.difference(timestamp) > _feedbackWindow,
      );
    }
  }

  void _onCcReceived(int channel, int cc, int value) {
    final lookup = _lookup;
    if (lookup == null) return;

    final targets = lookup.lookup(channel, cc);
    if (targets == null) return;

    for (final target in targets) {
      if (target.is14Bit) {
        _handle14BitCc(channel, cc, value, target);
      } else {
        _handleStandardCc(value, target);
      }
    }
  }

  void _handle14BitCc(int channel, int cc, int value, CcTarget target) {
    final baseCc = cc < 32 ? cc : cc - 32;
    final isMsb = cc < 32;
    final pendingKey = channel * 256 + baseCc;

    if (isMsb) {
      final now = DateTime.now();
      _pending14BitMsb[pendingKey] = _Pending14Bit(value, now);

      // Prune stale pending entries to prevent unbounded growth from
      // orphaned MSBs that never received a matching LSB
      if (_pending14BitMsb.length > _maxPending14BitEntries) {
        _pending14BitMsb.removeWhere(
          (_, pending) =>
              now.difference(pending.timestamp).inMilliseconds > 500,
        );
      }
    } else {
      // LSB arrived — combine with pending MSB
      final pending = _pending14BitMsb.remove(pendingKey);
      if (pending == null) return;

      // Stale MSB check (500ms)
      if (DateTime.now().difference(pending.timestamp).inMilliseconds > 500) {
        return;
      }

      final combined = (pending.msb << 7) | value;
      _applyValue(target, combined);
    }
  }

  void _handleStandardCc(int value, CcTarget target) {
    _applyValue(target, value);
  }

  void _applyValue(CcTarget target, int ccValue) {
    // Check feedback suppression
    final suppressKey =
        target.algorithmIndex * 10000 + target.parameterNumber;
    final lastOutbound = _outboundTimestamps[suppressKey];
    if (lastOutbound != null &&
        DateTime.now().difference(lastOutbound) < _feedbackWindow) {
      return;
    }

    // Convert CC value to parameter value
    final state = _cubit.state;
    if (state is! DistingStateSynchronized) return;

    int? currentValue;
    if (target.algorithmIndex < state.slots.length) {
      final slot = state.slots[target.algorithmIndex];
      if (target.parameterNumber < slot.values.length) {
        currentValue = slot.values[target.parameterNumber].value;
      }
    }

    final paramValue = CcReverseLookup.convertCcToParamValue(
      target,
      ccValue,
      currentParamValue: currentValue,
    );

    // Skip if value hasn't changed
    if (currentValue != null && currentValue == paramValue) return;

    // Track for preset load detection
    _batchParams.add(suppressKey);
    _batchTimer?.cancel();
    _batchTimer = Timer(_batchWindow, _checkBatch);

    // Update cubit state
    if (target.algorithmIndex < state.slots.length) {
      final newValue = ParameterValue(
        algorithmIndex: target.algorithmIndex,
        parameterNumber: target.parameterNumber,
        value: paramValue,
      );

      _cubit._emitState(
        state.copyWith(
          slots: _cubit.updateSlot(
            target.algorithmIndex,
            state.slots,
            (slot) {
              if (target.parameterNumber >= slot.values.length) return slot;
              return slot.copyWith(
                values: _cubit.replaceInList(
                  slot.values,
                  newValue,
                  index: target.parameterNumber,
                ),
              );
            },
          ),
        ),
      );
    }
  }

  void _checkBatch() {
    if (_batchParams.length > _batchThreshold) {
      // Many parameters changed at once — likely a preset load.
      // Trigger a full state refresh instead of individual updates.
      _batchParams.clear();
      _cubit._refreshStateFromManager();
    } else {
      _batchParams.clear();
    }
  }
}

class _Pending14Bit {
  final int msb;
  final DateTime timestamp;
  const _Pending14Bit(this.msb, this.timestamp);
}
