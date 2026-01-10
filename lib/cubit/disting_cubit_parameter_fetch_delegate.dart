part of 'disting_cubit.dart';

class _ParameterFetchDelegate {
  _ParameterFetchDelegate(this._cubit);

  final DistingCubit _cubit;

  /// Concurrency limit for per-parameter calls.
  /// Tune this — 4-6 usually keeps the module happy without stalling.
  static const int kParallel = 4;

  // Background retry queue for failed parameter requests
  final List<_ParameterRetryRequest> _parameterRetryQueue = [];

  // Semaphore to ensure retry queue has lower priority than active commands
  int _activeCommandCount = 0;
  final _commandSemaphore = Completer<void>();

  bool get hasQueuedRetries => _parameterRetryQueue.isNotEmpty;

  // Background retry for failed parameter requests
  void _queueParameterRetry(_ParameterRetryRequest request) {
    _parameterRetryQueue.add(request);
  }

  // Acquire semaphore for active commands (blocks retry queue)
  void acquireCommandSemaphore() {
    _activeCommandCount++;
    if (_activeCommandCount == 1) {}
  }

  // Release semaphore for active commands (allows retry queue)
  void releaseCommandSemaphore() {
    _activeCommandCount--;
    if (_activeCommandCount == 0) {
      if (!_commandSemaphore.isCompleted) {
        _commandSemaphore.complete();
      }
    }
    if (_activeCommandCount < 0) {
      _activeCommandCount = 0;
    }
  }

  // Wait for semaphore to be available (no active commands)
  Future<void> _waitForCommandSemaphore() async {
    while (_activeCommandCount > 0) {
      final completer = Completer<void>();
      if (_activeCommandCount == 0) break;

      // Wait for active commands to complete or timeout after reasonable period
      await Future.any([
        completer.future,
        Future.delayed(const Duration(seconds: 5)),
        // Timeout to prevent deadlock
      ]);

      // Brief yield to check again
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  // Process the retry queue in the background with low priority
  Future<void> processParameterRetryQueue(IDistingMidiManager disting) async {
    if (_parameterRetryQueue.isEmpty) return;

    final retryList = List.from(_parameterRetryQueue);
    _parameterRetryQueue.clear();

    // Add initial delay to let any pending operations complete
    await Future.delayed(const Duration(seconds: 2));

    for (int i = 0; i < retryList.length; i++) {
      final request = retryList[i];

      // Wait for semaphore - only proceed when no active commands
      await _waitForCommandSemaphore();

      try {
        // Longer delay between retries to maintain low priority
        await Future.delayed(const Duration(milliseconds: 500));

        // Periodically yield to event loop for longer pauses to allow user operations
        if (i > 0 && i % 3 == 0) {
          await Future.delayed(const Duration(seconds: 1));
        }

        // Wait again before the actual retry request to ensure no commands started
        await _waitForCommandSemaphore();

        // Additional micro-yield to event loop before each request
        await Future.delayed(Duration.zero);

        switch (request.type) {
          case _ParameterRetryType.info:
            final info = await disting.requestParameterInfo(
              request.slotIndex,
              request.paramIndex,
            );
            if (info != null) {
              await _cubit._slotStateDelegate.updateSlotParameterInfo(
                request.slotIndex,
                request.paramIndex,
                info,
              );
            }
            break;
          case _ParameterRetryType.enumStrings:
            final enums = await disting.requestParameterEnumStrings(
              request.slotIndex,
              request.paramIndex,
            );
            if (enums != null) {
              await _cubit._slotStateDelegate.updateSlotParameterEnums(
                request.slotIndex,
                request.paramIndex,
                enums,
              );
            }
            break;
          case _ParameterRetryType.mappings:
            final mappings = await disting.requestMappings(
              request.slotIndex,
              request.paramIndex,
            );
            if (mappings != null) {
              await _cubit._slotStateDelegate.updateSlotParameterMappings(
                request.slotIndex,
                request.paramIndex,
                mappings,
              );
            }
            break;
          case _ParameterRetryType.valueStrings:
            final valueStrings = await disting.requestParameterValueString(
              request.slotIndex,
              request.paramIndex,
            );
            if (valueStrings != null) {
              await _cubit._slotStateDelegate.updateSlotParameterValueStrings(
                request.slotIndex,
                request.paramIndex,
                valueStrings,
              );
            }
            break;
        }
      } catch (e) {
        // Add extra delay after failures to avoid overwhelming the device
        await Future.delayed(const Duration(milliseconds: 200));
      }
    }
  }

  Future<List<Slot>> fetchSlots(
    int numAlgorithmsInPreset,
    IDistingMidiManager disting,
  ) async {
    final stopwatch = Stopwatch()..start();

    final slotsFutures = List.generate(numAlgorithmsInPreset, (
      algorithmIndex,
    ) async {
      return await fetchSlot(disting, algorithmIndex);
    });

    // Finish off the requests
    final slots = await Future.wait(slotsFutures);
    stopwatch.elapsedMilliseconds;
    return slots;
  }

  Future<Slot> fetchSlot(
    IDistingMidiManager disting,
    int algorithmIndex,
  ) async {
    Stopwatch().start();

    /* ------------------------------------------------------------------ *
   * 1-2.  Pages  |  #Parameters  |  Algorithm GUID  |  All Values      *
   * ------------------------------------------------------------------ */
    // Fetch essential info first (these usually don't timeout)
    final essentialResults = await Future.wait([
      disting.requestParameterPages(algorithmIndex),
      disting.requestNumberOfParameters(algorithmIndex),
      disting.requestAlgorithmGuid(algorithmIndex),
    ]);

    final pages =
        (essentialResults[0] as ParameterPages?) ??
        ParameterPages(algorithmIndex: algorithmIndex, pages: []);
    final numParams =
        (essentialResults[1] as NumParameters?)?.numParameters ?? 0;
    final guid = essentialResults[2] as Algorithm?;

    final currentState = _cubit.state;
    final firmware = currentState is DistingStateSynchronized
        ? currentState.firmwareVersion
        : _cubit._lastKnownFirmwareVersion;

    // Try to get parameter values with retry and longer timeout
    List<ParameterValue> allValues;
    try {
      final paramValuesResult = await disting.requestAllParameterValues(
        algorithmIndex,
      );
      allValues =
          paramValuesResult?.values ??
          List<ParameterValue>.generate(
            numParams,
            (_) => ParameterValue.filler(),
          );
    } catch (e) {
      try {
        // Retry with a longer timeout - give it more time to respond
        await Future.delayed(
          const Duration(milliseconds: 500),
        ); // Brief pause before retry
        final retryResult = await disting.requestAllParameterValues(
          algorithmIndex,
        );
        allValues =
            retryResult?.values ??
            List<ParameterValue>.generate(
              numParams,
              (_) => ParameterValue.filler(),
            );
      } catch (retryError) {
        allValues = List<ParameterValue>.generate(
          numParams,
          (_) => ParameterValue.filler(),
        );
      }
    }

    /* Visible-parameter set (built from pages) */
    final visible = pages.pages.expand((p) => p.parameters).toSet();

    /* ------------------------------------------------------------------ *
   * 3. Parameter-info phase (throttled)                                *
   * ------------------------------------------------------------------ */
    final parameters = List<ParameterInfo>.filled(
      numParams,
      ParameterInfo.filler(),
    );
    await _forEachLimited(
      Iterable<int>.generate(numParams),
      (param) async {
        try {
          final info = await disting.requestParameterInfo(
            algorithmIndex,
            param,
          );
          parameters[param] = info ?? ParameterInfo.filler();
          if (info == null) {
            _queueParameterRetry(
              _ParameterRetryRequest(
                slotIndex: algorithmIndex,
                paramIndex: param,
                type: _ParameterRetryType.info,
              ),
            );
          }
        } catch (e) {
          parameters[param] = ParameterInfo.filler();
          _queueParameterRetry(
            _ParameterRetryRequest(
              slotIndex: algorithmIndex,
              paramIndex: param,
              type: _ParameterRetryType.info,
            ),
          );
        }
      },
    );

    /* Pre-calculate which params are enumerated / mappable / string */
    bool isEnum(int i) => parameters[i].unit == 1;
    bool isString(int i) => const {13, 14, 17}.contains(parameters[i].unit);
    bool isMappable(int i) => parameters[i].unit != -1;

    /* ------------------------------------------------------------------ *
   * 4. Enums, Mappings, Value-Strings  (all throttled in parallel)     *
   * ------------------------------------------------------------------ */
    final enums = List<ParameterEnumStrings>.filled(
      numParams,
      ParameterEnumStrings.filler(),
    );
    final mappings = List<Mapping>.filled(numParams, Mapping.filler());
    final valueStrings = List<ParameterValueString>.filled(
      numParams,
      ParameterValueString.filler(),
    );

    // Skip enum strings for known buggy algorithm/parameter combinations
    // Macro Oscillator (maco) param 1 (Model) causes firmware to send truncated
    // SysEx that can corrupt the MIDI stream
    bool shouldSkipEnumStrings(int param) {
      return firmware?.isExactly('1.12.0') == true &&
          guid?.guid == 'maco' &&
          param == 1;
    }

    await Future.wait([
      // Enums
      _forEachLimited(
        Iterable<int>.generate(
          numParams,
        ).where(
              (i) =>
                  visible.contains(i) &&
                  isEnum(i) &&
                  !shouldSkipEnumStrings(i),
            ),
        (param) async {
          try {
            final enumResult = await disting.requestParameterEnumStrings(
              algorithmIndex,
              param,
            );
            enums[param] = enumResult ?? ParameterEnumStrings.filler();
            if (enumResult == null) {
              _queueParameterRetry(
                _ParameterRetryRequest(
                  slotIndex: algorithmIndex,
                  paramIndex: param,
                  type: _ParameterRetryType.enumStrings,
                ),
              );
            }
          } catch (e) {
            enums[param] = ParameterEnumStrings.filler();
            _queueParameterRetry(
              _ParameterRetryRequest(
                slotIndex: algorithmIndex,
                paramIndex: param,
                type: _ParameterRetryType.enumStrings,
              ),
            );
          }
        },
      ),
      // Mappings
      _forEachLimited(
        Iterable<int>.generate(
          numParams,
        ).where((i) => visible.contains(i) && isMappable(i)),
        (param) async {
          try {
            final mappingResult = await disting.requestMappings(
              algorithmIndex,
              param,
            );
            mappings[param] = mappingResult ?? Mapping.filler();
            if (mappingResult == null) {
              _queueParameterRetry(
                _ParameterRetryRequest(
                  slotIndex: algorithmIndex,
                  paramIndex: param,
                  type: _ParameterRetryType.mappings,
                ),
              );
            }
          } catch (e) {
            mappings[param] = Mapping.filler();
            _queueParameterRetry(
              _ParameterRetryRequest(
                slotIndex: algorithmIndex,
                paramIndex: param,
                type: _ParameterRetryType.mappings,
              ),
            );
          }
        },
      ),
      // Value strings
      _forEachLimited(
        Iterable<int>.generate(
          numParams,
        ).where((i) => visible.contains(i) && isString(i)),
        (param) async {
          try {
            final valueStringResult = await disting.requestParameterValueString(
              algorithmIndex,
              param,
            );
            valueStrings[param] =
                valueStringResult ?? ParameterValueString.filler();
            if (valueStringResult == null) {
              _queueParameterRetry(
                _ParameterRetryRequest(
                  slotIndex: algorithmIndex,
                  paramIndex: param,
                  type: _ParameterRetryType.valueStrings,
                ),
              );
            }
          } catch (e) {
            valueStrings[param] = ParameterValueString.filler();
            _queueParameterRetry(
              _ParameterRetryRequest(
                slotIndex: algorithmIndex,
                paramIndex: param,
                type: _ParameterRetryType.valueStrings,
              ),
            );
          }
        },
      ),
    ]);

    /* ------------------------------------------------------------------ *
   * 5. Assemble the Slot                                               *
   * ------------------------------------------------------------------ */

    final outputModeParamNumbers = <int>{};
    for (final param in parameters) {
      if (param.isOutputMode && param.parameterNumber >= 0) {
        outputModeParamNumbers.add(param.parameterNumber);
      }
    }

    final hasAddReplaceEnum = enums.any(
      (paramEnums) =>
          paramEnums.values.contains('Add') &&
          paramEnums.values.contains('Replace'),
    );

    if (outputModeParamNumbers.isEmpty && hasAddReplaceEnum) {
      throw StateError(
        'Output mode parameters missing ioFlags; fallback is not permitted.',
      );
    }


    final outputModeMap = <int, List<int>>{};
    if (outputModeParamNumbers.isNotEmpty) {
      await _forEachLimited(
        outputModeParamNumbers,
        (paramNumber) async {
          try {
            final outputModeUsage = await disting.requestOutputModeUsage(
              algorithmIndex,
              paramNumber,
            );
            if (outputModeUsage != null) {
              outputModeMap[outputModeUsage.parameterNumber] =
                  outputModeUsage.affectedParameterNumbers;
            }
          } catch (e) {
            // Output mode usage is optional; ignore failures.
          }
        },
      );
    }

    if (outputModeMap.isNotEmpty) {
      _cubit._slotStateDelegate.setOutputModeUsageMapForSlot(
        algorithmIndex,
        outputModeMap,
      );
    }

    if (outputModeMap.isNotEmpty) {
      await _forEachLimited(
        outputModeMap.keys,
        (paramNumber) async {
          if (paramNumber < 0 || paramNumber >= allValues.length) {
            return;
          }
          try {
            final value = await disting.requestParameterValue(
              algorithmIndex,
              paramNumber,
            );
            if (value != null) {
              allValues[paramNumber] = value;
            }
          } catch (e) {
            // Output mode values are optional; ignore failures.
          }
        },
      );
    }

    final resolvedOutputModeMap =
        outputModeMap.isNotEmpty
            ? outputModeMap
            : _cubit._slotStateDelegate.outputModeMapForSlot(algorithmIndex);

    return Slot(
      algorithm:
          guid ??
          Algorithm(
            algorithmIndex: algorithmIndex,
            guid: 'ERROR',
            name: 'Error fetching Algorithm',
          ),
      pages: pages,
      parameters: parameters,
      values: allValues,
      enums: enums,
      mappings: mappings,
      valueStrings: valueStrings,
      routing: RoutingInfo.filler(), // unchanged – still skipped
      outputModeMap: resolvedOutputModeMap,
    );
  }

  /* ---------------------------------------------------------------------- *
 * Helper – run tasks with a concurrency cap                              *
 * ---------------------------------------------------------------------- */

  /// Runs [worker] for every element in [items], but never more than
  /// [parallel] tasks are in-flight at once.
  ///
  /// Uses a "batch" strategy: kick off up to [parallel] futures,
  /// `await Future.wait`, then move on to the next batch.  Simpler and
  /// avoids the need for isCompleted / whenComplete gymnastics.
  Future<void> _forEachLimited<T>(
    Iterable<T> items,
    Future<void> Function(T) worker, {
    int parallel = kParallel,
  }) async {
    final iterator = items.iterator;

    while (true) {
      // Collect up to [parallel] tasks for this batch.
      final batch = <Future<void>>[];
      for (var i = 0; i < parallel && iterator.moveNext(); i++) {
        batch.add(worker(iterator.current));
      }

      if (batch.isEmpty) break; // no more work
      await Future.wait(batch); // wait for the batch to finish
    }
  }
}
