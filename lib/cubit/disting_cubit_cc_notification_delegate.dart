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

    final oldLookup = _lookup;
    _lookup = CcReverseLookup.build(state.slots);

    // If we went from empty (no callback registered) to non-empty,
    // register the callback now. This handles the case where start()
    // returned early because no MIDI mappings existed at sync time,
    // but a mapping was added later.
    if ((oldLookup == null || oldLookup.isEmpty) && !_lookup!.isEmpty) {
      _cubit.disting()?.setCcCallback(_onCcReceived);
    }
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

    // Separate 14-bit and standard targets
    final has14Bit = targets.any((t) => t.is14Bit);

    if (has14Bit) {
      // Handle 14-bit accumulation once for this (channel, cc), then
      // dispatch the combined value to all 14-bit targets.
      final combined = _accumulate14BitCc(channel, cc, value);
      if (combined != null) {
        for (final target in targets) {
          if (target.is14Bit) {
            _applyValue(target, combined);
          }
        }
      }
    }

    for (final target in targets) {
      if (!target.is14Bit) {
        _applyValue(target, value);
      }
    }
  }

  /// Accumulates 14-bit CC values. Returns the combined 14-bit value when
  /// both MSB and LSB have been received, or null if still waiting.
  int? _accumulate14BitCc(int channel, int cc, int value) {
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
      return null;
    } else {
      // LSB arrived — combine with pending MSB
      final pending = _pending14BitMsb.remove(pendingKey);
      if (pending == null) return null;

      // Stale MSB check (500ms)
      if (DateTime.now().difference(pending.timestamp).inMilliseconds > 500) {
        return null;
      }

      return (pending.msb << 7) | value;
    }
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
      final slot = state.slots[target.algorithmIndex];
      final currentPV = target.parameterNumber < slot.values.length
          ? slot.values[target.parameterNumber]
          : null;
      final newValue = ParameterValue(
        algorithmIndex: target.algorithmIndex,
        parameterNumber: target.parameterNumber,
        value: paramValue,
        isDisabled: currentPV?.isDisabled ?? false,
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
