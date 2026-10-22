part of 'disting_cubit.dart';

/// Smoke-tests a plug-in on live hardware: appends it to the end of the
/// current preset, checks that the slot answers, samples its CPU, and then
/// removes the slot again unless asked to keep it.
///
/// The preset is never saved. Rollback removes only the appended slot and
/// confirms the original slot lineup with the device. Only when that removal
/// cannot be confirmed does it fall back to reloading the last saved preset
/// from the SD card, and only automatically when the preset had no unsaved
/// edits.
class _PluginSmokeTestDelegate {
  _PluginSmokeTestDelegate(this._cubit);

  final DistingCubit _cubit;

  /// Runs the smoke test for the plug-in [guid] with [options].
  ///
  /// Throws [PluginSmokeTestRefused] before touching the preset when there
  /// is no live session, [guid] is unknown or built in, every slot is in
  /// use, or the plug-in cannot be loaded. Every other outcome, including
  /// device errors, is returned as a [PluginSmokeTestReport].
  Future<PluginSmokeTestReport> smokeTestPlugin(
    String guid,
    PluginSmokeTestOptions options,
  ) async {
    final start = _requireLiveSession();
    var algorithm = _findPlugin(start, guid);
    if (start.slots.length >= DistingLimits.maxPresetSlots) {
      throw PluginSmokeTestRefused(
        PluginSmokeTestRefusal.presetFull,
        'All ${DistingLimits.maxPresetSlots} slots are in use, so there is '
        'no free slot to append the test slot to. Remove a slot first.',
        {'max_slots': DistingLimits.maxPresetSlots},
      );
    }

    final loadedPlugin = !algorithm.isLoaded;
    if (loadedPlugin) {
      final loaded = await _cubit._pluginDelegate.loadPlugin(guid);
      if (loaded == null || !loaded.isLoaded) {
        throw PluginSmokeTestRefused(
          PluginSmokeTestRefusal.loadFailed,
          'The plug-in $guid did not report loaded. Check the device screen '
          'for a load error. The preset was not changed.',
        );
      }
      algorithm = loaded;
    }

    final baseline = _requireLiveSession();
    final run = _SmokeRun(
      cubit: _cubit,
      options: options,
      algorithm: algorithm,
      disting: baseline.disting,
      slotIndex: baseline.slots.length,
      baselineGuids: [for (final s in baseline.slots) s.algorithm.guid],
      presetName: baseline.presetName,
      wasDirty: baseline.isDirty,
      checkpoint: _cubit._checkpointDelegate.createCheckpoint(
        label: 'smoke_test_plugin $guid',
      ),
      loadedPlugin: loadedPlugin,
    );
    try {
      return await run.execute();
    } finally {
      final checkpoint = run.checkpoint;
      if (checkpoint != null) {
        _cubit._checkpointDelegate.removeCheckpoint(checkpoint);
      }
    }
  }

  DistingStateSynchronized _requireLiveSession() {
    final state = _cubit.state;
    if (state is! DistingStateSynchronized) {
      throw const PluginSmokeTestRefused(
        PluginSmokeTestRefusal.notConnected,
        'No Disting NT is connected and synchronized.',
      );
    }
    if (state.demo) {
      throw const PluginSmokeTestRefused(
        PluginSmokeTestRefusal.demo,
        'Demo mode has no device to test on. Connect a Disting NT.',
      );
    }
    if (state.offline) {
      throw const PluginSmokeTestRefused(
        PluginSmokeTestRefusal.offline,
        'Offline mode has no device to test on. Connect a Disting NT.',
      );
    }
    return state;
  }

  AlgorithmInfo _findPlugin(DistingStateSynchronized state, String guid) {
    final algorithm = state.algorithms.where((a) => a.guid == guid).firstOrNull;
    if (algorithm == null) {
      throw PluginSmokeTestRefused(
        PluginSmokeTestRefusal.unknownGuid,
        'No algorithm with GUID $guid is installed. Install it with '
        'install_plugin, or check the GUID with search_algorithms.',
      );
    }
    if (!algorithm.isPlugin) {
      throw PluginSmokeTestRefused(
        PluginSmokeTestRefusal.notAPlugin,
        '$guid is the built-in algorithm ${algorithm.name}; '
        'smoke_test_plugin tests plug-ins only.',
      );
    }
    return algorithm;
  }
}

/// State for one smoke test, from the appended slot to the rollback.
class _SmokeRun {
  _SmokeRun({
    required this.cubit,
    required this.options,
    required this.algorithm,
    required this.disting,
    required this.slotIndex,
    required this.baselineGuids,
    required this.presetName,
    required this.wasDirty,
    required this.checkpoint,
    required this.loadedPlugin,
  });

  final DistingCubit cubit;
  final PluginSmokeTestOptions options;
  final AlgorithmInfo algorithm;
  final IDistingMidiManager disting;
  final int slotIndex;
  final List<String> baselineGuids;
  final String presetName;
  final bool wasDirty;
  final PresetCheckpoint? checkpoint;
  final bool loadedPlugin;

  final checks = <PluginSmokeCheck>[];
  PluginSmokeCpuReport? cpu;

  Future<PluginSmokeTestReport> execute() async {
    _SmokeFailure? failure;
    var slotAdded = false;
    try {
      slotAdded = await _addSlot();
      if (!slotAdded) {
        failure = const _SmokeFailure(
          PluginSmokeTestFailure.addFailed,
          'The device did not confirm the new slot.',
        );
      } else {
        await Future<void>.delayed(options.settle);
        failure = await _checkParameters() ?? await _checkCpu();
      }
    } catch (e) {
      failure = _SmokeFailure(
        PluginSmokeTestFailure.internalError,
        'The test stopped unexpectedly: $e',
      );
    }

    if (failure != null &&
        failure.code != PluginSmokeTestFailure.deviceUnresponsive &&
        await _readSlotCount() == null) {
      failure = _SmokeFailure(
        PluginSmokeTestFailure.deviceUnresponsive,
        '${failure.detail} The device then stopped answering slot-count '
        'reads.',
      );
    }

    if (failure == null && options.keep) {
      return _report(null, PluginSmokeTestRollback.kept);
    }

    final rollback = await _rollBack(slotAdded: slotAdded);
    if (failure == null && !rollback.status.restoredLineup) {
      failure = const _SmokeFailure(
        PluginSmokeTestFailure.rollbackFailed,
        'Every check passed, but removing the test slot was not confirmed.',
      );
    }
    return _report(
      failure,
      rollback.status,
      rollbackError: rollback.error,
      restoredParameterValues: rollback.restoredParameterValues,
    );
  }

  /// Appends the plug-in and waits for the device to confirm it.
  Future<bool> _addSlot() async {
    final specs =
        options.specifications ??
        [for (final s in algorithm.specifications) s.defaultValue];
    try {
      await cubit.onAlgorithmSelected(algorithm, specs);
    } on AlgorithmAddFailedException {
      checks.add(
        const PluginSmokeCheck(
          'slot_added',
          passed: false,
          detail: 'The slot count did not increase.',
        ),
      );
      return false;
    }
    checks.add(
      PluginSmokeCheck(
        'slot_added',
        passed: true,
        detail: 'Appended as slot $slotIndex.',
      ),
    );
    return true;
  }

  /// Checks that the new slot answers with the plug-in's GUID and at least
  /// one parameter, plus the optional stricter count and name checks.
  Future<_SmokeFailure?> _checkParameters() async {
    final reported = await _read(
      () => disting.requestAlgorithmGuid(
        slotIndex,
        timeout: options.requestTimeout,
        maxRetries: 1,
      ),
    );
    final count = await _read(
      () => disting.requestNumberOfParameters(slotIndex),
    );
    if (reported == null ||
        count == null ||
        count.algorithmIndex != slotIndex) {
      checks.add(
        PluginSmokeCheck(
          'slot_responds',
          passed: false,
          detail:
              'Slot $slotIndex did not answer the '
              '${reported == null ? 'GUID' : 'parameter-count'} read.',
        ),
      );
      return _SmokeFailure(
        PluginSmokeTestFailure.parametersUnavailable,
        'Slot $slotIndex did not answer within '
        '${options.requestTimeout.inMilliseconds} ms.',
      );
    }
    checks.add(const PluginSmokeCheck('slot_responds', passed: true));

    if (reported.guid != algorithm.guid) {
      checks.add(
        PluginSmokeCheck(
          'algorithm_guid',
          passed: false,
          detail: 'Expected ${algorithm.guid}, got ${reported.guid}.',
        ),
      );
      return _SmokeFailure(
        PluginSmokeTestFailure.parameterMismatch,
        'Slot $slotIndex holds ${reported.guid}, not ${algorithm.guid}.',
      );
    }
    checks.add(const PluginSmokeCheck('algorithm_guid', passed: true));

    final expectedCount = options.expectedParameterCount;
    final countOk = expectedCount == null
        ? count.numParameters >= 1
        : count.numParameters == expectedCount;
    checks.add(
      PluginSmokeCheck(
        'parameter_count',
        passed: countOk,
        detail:
            'Reported ${count.numParameters}; expected '
            '${expectedCount ?? 'at least 1'}.',
      ),
    );
    if (!countOk) {
      return _SmokeFailure(
        PluginSmokeTestFailure.parameterMismatch,
        'Slot $slotIndex reports ${count.numParameters} parameter(s); '
        'expected ${expectedCount ?? 'at least 1'}.',
      );
    }

    final expectedNames = options.expectedParameterNames;
    if (expectedNames == null || expectedNames.isEmpty) return null;
    final actualNames = <String>[];
    for (var i = 0; i < expectedNames.length; i++) {
      final info = i < count.numParameters
          ? await _read(() => disting.requestParameterInfo(slotIndex, i))
          : null;
      if (info == null && i < count.numParameters) {
        checks.add(
          PluginSmokeCheck(
            'parameter_names',
            passed: false,
            detail: 'Parameter $i did not answer.',
          ),
        );
        return _SmokeFailure(
          PluginSmokeTestFailure.parametersUnavailable,
          'Parameter $i of slot $slotIndex did not answer.',
        );
      }
      actualNames.add(info?.name.trim() ?? '');
    }
    final namesOk = const ListEquality<String>().equals(actualNames, [
      for (final n in expectedNames) n.trim(),
    ]);
    checks.add(
      PluginSmokeCheck(
        'parameter_names',
        passed: namesOk,
        detail: 'Expected $expectedNames, got $actualNames.',
      ),
    );
    return namesOk
        ? null
        : _SmokeFailure(
            PluginSmokeTestFailure.parameterMismatch,
            'Parameter names differ: expected $expectedNames, got '
            '$actualNames.',
          );
  }

  /// Samples CPU [PluginSmokeTestOptions.cpuSamples] times and judges the
  /// test slot's peak, and both cores' peak when a ceiling is set.
  Future<_SmokeFailure?> _checkCpu() async {
    final slotSamples = <int>[];
    final coreSamples = <int>[];
    cpu = PluginSmokeCpuReport(
      budgetPercent: options.cpuBudgetPercent,
      maxCorePercent: options.maxCorePercent,
      slotSamples: slotSamples,
      coreSamples: coreSamples,
    );
    for (var i = 0; i < options.cpuSamples; i++) {
      if (i > 0) await Future<void>.delayed(options.cpuSampleInterval);
      final usage = await _read(cubit.getCpuUsage);
      if (usage == null || usage.slotUsages.length <= slotIndex) {
        final why = usage == null
            ? 'CPU sample ${i + 1} did not arrive.'
            : 'CPU sample ${i + 1} covers ${usage.slotUsages.length} slot(s), '
                  'not slot $slotIndex.';
        checks.add(PluginSmokeCheck('cpu', passed: false, detail: why));
        return _SmokeFailure(PluginSmokeTestFailure.cpuUnavailable, why);
      }
      slotSamples.add(usage.slotUsages[slotIndex]);
      coreSamples.add(usage.cpu1 > usage.cpu2 ? usage.cpu1 : usage.cpu2);
    }

    final slotPeak = cpu!.slotPeak!;
    final slotOk = slotPeak <= options.cpuBudgetPercent;
    checks.add(
      PluginSmokeCheck(
        'slot_cpu',
        passed: slotOk,
        detail:
            'Peak $slotPeak% over ${slotSamples.length} sample(s); budget '
            '${options.cpuBudgetPercent}%.',
      ),
    );

    final maxCore = options.maxCorePercent;
    final corePeak = cpu!.corePeak!;
    final coreOk = maxCore == null || corePeak <= maxCore;
    if (maxCore != null) {
      checks.add(
        PluginSmokeCheck(
          'core_cpu',
          passed: coreOk,
          detail: 'Peak core $corePeak%; ceiling $maxCore%.',
        ),
      );
    }

    if (!slotOk) {
      return _SmokeFailure(
        PluginSmokeTestFailure.cpuOverBudget,
        'Slot $slotIndex peaked at $slotPeak% CPU; the budget is '
        '${options.cpuBudgetPercent}%.',
      );
    }
    if (!coreOk) {
      return _SmokeFailure(
        PluginSmokeTestFailure.coreCpuOverBudget,
        'A core peaked at $corePeak% CPU; the ceiling is $maxCore%.',
      );
    }
    return null;
  }

  /// Puts the preset back to [baselineGuids]: removes the test slot, and
  /// when that cannot be confirmed, reloads the saved preset if allowed.
  Future<_SmokeRollback> _rollBack({required bool slotAdded}) async {
    final count = await _readSlotCount();
    // An add that was not confirmed in time may still land afterwards.
    final slotPresent = slotAdded || (count != null && count == slotIndex + 1);

    String? error;
    if (slotPresent) {
      final removed = await cubit.removeAlgorithmConfirmed(
        slotIndex,
        pollInterval: options.removePollInterval,
        pollAttempts: options.removePollAttempts,
        requestTimeout: options.requestTimeout,
      );
      if (!removed) {
        error =
            'Removing slot $slotIndex was not confirmed within '
            '${options.removePollAttempts} slot-count read(s).';
      }
    }
    error ??= await _lineupError();
    if (error == null) {
      _restoreDirtyFlag();
      return _SmokeRollback(
        slotPresent
            ? PluginSmokeTestRollback.removedSlot
            : PluginSmokeTestRollback.notNeeded,
      );
    }

    if (wasDirty && !options.reloadSavedOnFailure) {
      return _SmokeRollback(
        PluginSmokeTestRollback.failed,
        error:
            '$error The preset has unsaved edits, so it was not reloaded '
            'from the SD card. Remove slot $slotIndex on the device, or '
            'call smoke_test_plugin with reload_saved_on_failure to allow '
            'the reload. If the device is not answering, power-cycle it; it '
            'starts with the last saved preset.',
      );
    }

    try {
      await cubit
          .loadPreset('/presets/$presetName.json', false)
          .timeout(options.reloadTimeout);
    } catch (e) {
      return _SmokeRollback(
        PluginSmokeTestRollback.failed,
        error:
            '$error Reloading /presets/$presetName.json also failed: $e. '
            'Remove slot $slotIndex on the device, or power-cycle it.',
      );
    }
    final reloadError = await _lineupError();
    if (reloadError != null) {
      return _SmokeRollback(
        PluginSmokeTestRollback.failed,
        error: '$error After reloading /presets/$presetName.json: $reloadError',
      );
    }
    final restored = wasDirty && checkpoint != null
        ? await cubit._checkpointDelegate.restoreCheckpoint(checkpoint!)
        : null;
    return _SmokeRollback(
      PluginSmokeTestRollback.reloadedSavedPreset,
      error: wasDirty
          ? '$error Reloaded the saved preset; unsaved edits other than '
                'parameter values were discarded.'
          : '$error Reloaded the saved preset, which had no unsaved edits.',
      restoredParameterValues: restored,
    );
  }

  /// Null when the device reports exactly [baselineGuids], otherwise why
  /// not.
  Future<String?> _lineupError() async {
    final count = await _readSlotCount();
    if (count == null) return 'The device did not answer a slot-count read.';
    if (count != baselineGuids.length) {
      return 'The device reports $count slot(s); expected '
          '${baselineGuids.length}.';
    }
    for (var i = 0; i < baselineGuids.length; i++) {
      final reported = await _read(
        () => disting.requestAlgorithmGuid(
          i,
          timeout: options.requestTimeout,
          maxRetries: 1,
        ),
      );
      if (reported?.guid != baselineGuids[i]) {
        return 'Slot $i holds ${reported?.guid ?? 'no answer'}; expected '
            '${baselineGuids[i]}.';
      }
    }
    return null;
  }

  /// The confirmed removal restores the original preset, so the dirty flag
  /// the add raised goes back to what it was.
  void _restoreDirtyFlag() {
    final state = cubit.state;
    if (state is DistingStateSynchronized && state.isDirty != wasDirty) {
      cubit._emitState(state.copyWith(isDirty: wasDirty));
    }
  }

  Future<int?> _readSlotCount() => _read(
    () => disting.requestNumAlgorithmsInPreset(
      timeout: options.requestTimeout,
      maxRetries: 1,
    ),
  );

  /// Runs [request] with a deadline; null on timeout or error.
  Future<T?> _read<T>(Future<T?> Function() request) async {
    try {
      return await request().timeout(options.requestTimeout * 2);
    } catch (_) {
      return null;
    }
  }

  PluginSmokeTestReport _report(
    _SmokeFailure? failure,
    PluginSmokeTestRollback rollback, {
    String? rollbackError,
    int? restoredParameterValues,
  }) => PluginSmokeTestReport(
    guid: algorithm.guid,
    name: algorithm.name,
    slotIndex: slotIndex,
    loadedPlugin: loadedPlugin,
    checks: List.unmodifiable(checks),
    cpu: cpu,
    failure: failure?.code,
    failureDetail: failure?.detail,
    rollback: rollback,
    rollbackError: rollbackError,
    restoredParameterValues: restoredParameterValues,
  );
}

class _SmokeFailure {
  const _SmokeFailure(this.code, this.detail);

  final PluginSmokeTestFailure code;
  final String detail;
}

class _SmokeRollback {
  const _SmokeRollback(this.status, {this.error, this.restoredParameterValues});

  final PluginSmokeTestRollback status;
  final String? error;
  final int? restoredParameterValues;
}
