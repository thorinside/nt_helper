import 'dart:async';

import 'package:drift/drift.dart'; // Import drift for InsertMode
import 'package:flutter/foundation.dart';
import 'package:nt_helper/db/database.dart';
import 'package:nt_helper/db/daos/metadata_dao.dart'; // Import the DAO type
import 'package:nt_helper/domain/disting_nt_sysex.dart'
    show AlgorithmInfo, ParameterInfo;

import 'package:nt_helper/domain/i_disting_midi_manager.dart'
    show IDistingMidiManager;
import 'package:nt_helper/models/firmware_version.dart';
import 'package:nt_helper/services/elf_guid_extractor.dart';
import 'package:nt_helper/interfaces/impl/preset_file_system_impl.dart';

/// Service to synchronize static algorithm metadata from the device to the local database.
class MetadataSyncService {
  final IDistingMidiManager _distingManager;
  final AppDatabase _database;

  MetadataSyncService(this._distingManager, this._database);

  /// Factory GUIDs are lowercase alphanumeric, possibly space-padded to 4 chars
  /// (e.g. `spcn`, `env2`, `lfo `). Community plugins use uppercase (e.g. `TEST`).
  static bool _isFactoryGuid(String guid) =>
      RegExp(r'^[a-z0-9 ]+$').hasMatch(guid);

  Future<FirmwareVersion> _requestFirmwareVersionSafe() async {
    try {
      return FirmwareVersion(await _distingManager.requestVersionString() ?? '');
    } catch (_) {
      return FirmwareVersion('');
    }
  }

  /// Compute spec values for scanning: substitute 1 (clamped) for specs that default to 0.
  List<int> _scanSpecValues(AlgorithmInfo algoInfo) {
    return algoInfo.specifications.map((s) => s.safeDefaultValue).toList();
  }

  /// Poll until the preset count matches [expected], or [maxAttempts] is reached.
  Future<int> _pollPresetCount({
    required int expected,
    required int maxAttempts,
    bool Function()? checkCancel,
  }) async {
    var numInPreset = -1;
    var attempts = 0;
    while (numInPreset != expected &&
        attempts < maxAttempts &&
        !(checkCancel?.call() ?? false)) {
      await Future.delayed(const Duration(milliseconds: 500));
      numInPreset =
          await _distingManager.requestNumAlgorithmsInPreset() ?? -1;
      attempts++;
    }
    return numInPreset;
  }

  /// For plugins, reload AlgorithmInfo after instantiation; otherwise return as-is.
  Future<AlgorithmInfo> _resolveAlgorithmForQuery(
    AlgorithmInfo algoInfo,
  ) async {
    if (!algoInfo.isPlugin) return algoInfo;
    return await _distingManager
            .requestAlgorithmInfo(algoInfo.algorithmIndex) ??
        algoInfo;
  }

  /// Check if an error is a timeout-related error that may require device reboot.
  bool _isTimeoutError(Object error) {
    final errorString = error.toString();
    return errorString.contains('TimeoutException') ||
        errorString.contains('No response after') ||
        error is TimeoutException;
  }

  /// Reboot the device and wait for it to reconnect.
  ///
  /// Sends requestReboot(), waits 30s in 1-second increments (checking cancel),
  /// then wakes the device and verifies communication.
  Future<void> _rebootAndWaitForReconnection({
    void Function(String message)? onStatus,
    bool Function()? checkCancel,
  }) async {
    onStatus?.call('Sending reboot command...');
    try {
      await _distingManager.requestReboot();
    } catch (_) {
      // Fire-and-forget — device may disconnect immediately
    }

    // Wait 30 seconds in 1-second increments
    for (int i = 0; i < 30; i++) {
      if (checkCancel?.call() ?? false) return;
      onStatus?.call('Waiting for device to reboot... ${30 - i}s remaining');
      await Future.delayed(const Duration(seconds: 1));
    }

    if (checkCancel?.call() ?? false) return;

    // Wake the device
    onStatus?.call('Waking device...');
    await _distingManager.requestWake();
    await Future.delayed(const Duration(milliseconds: 500));

    // Verify communication — poll up to 5 times with 2s gaps
    for (int attempt = 0; attempt < 5; attempt++) {
      if (checkCancel?.call() ?? false) return;
      onStatus?.call(
        'Verifying communication... (attempt ${attempt + 1}/5)',
      );
      try {
        final numAlgos = await _distingManager.requestNumberOfAlgorithms();
        if (numAlgos != null && numAlgos > 0) {
          // Communication restored — clear preset
          await _distingManager.requestNewPreset();
          await Future.delayed(const Duration(milliseconds: 500));
          onStatus?.call('Device reconnected successfully.');
          return;
        }
      } catch (_) {
        // Not ready yet
      }
      await Future.delayed(const Duration(seconds: 2));
    }

    throw Exception('Failed to reconnect to device after reboot.');
  }

  /// Try to scan a single algorithm: add → poll → query → remove → poll.
  ///
  /// Returns true on success. Throws on failure.
  Future<void> _tryScanAlgorithm({
    required AlgorithmInfo algoInfo,
    required MetadataDao metadataDao,
    required Map<String, int> unitIdMap,
    required List<String> dbUnitStrings,
    required FirmwareVersion firmwareVersion,
    bool Function()? checkCancel,
  }) async {
    // Load plugin if needed
    if (algoInfo.isPlugin && !algoInfo.isLoaded) {
      await _distingManager.requestLoadPlugin(algoInfo.guid);
      await Future.delayed(const Duration(milliseconds: 1000));
      if (checkCancel?.call() ?? false) return;
    }

    // Add algorithm with scan specs
    final scanSpecs = _scanSpecValues(algoInfo);
    await _distingManager.requestAddAlgorithm(algoInfo, scanSpecs);

    // Poll until added
    final numInPreset = await _pollPresetCount(
      expected: 1,
      maxAttempts: algoInfo.isPlugin ? 15 : 10,
      checkCancel: checkCancel,
    );

    if (checkCancel?.call() ?? false) return;

    if (numInPreset != 1) {
      throw Exception(
        'Failed to add algorithm to preset (expected 1, found $numInPreset).',
      );
    }

    // Query instantiated parameters
    final algorithmToQuery = await _resolveAlgorithmForQuery(algoInfo);
    await _syncInstantiatedAlgorithmParams(
      metadataDao,
      algorithmToQuery,
      unitIdMap,
      dbUnitStrings,
      firmwareVersion,
    );

    // Remove algorithm
    await _distingManager.requestRemoveAlgorithm(0);

    // Poll until removed
    await _pollPresetCount(
      expected: 0,
      maxAttempts: 8,
      checkCancel: checkCancel,
    );
  }

  /// Clean up a failed algorithm from DB and device.
  Future<void> _cleanupFailedAlgorithm(
    MetadataDao metadataDao,
    String guid,
  ) async {
    // DB cleanup
    try {
      await metadataDao.clearAlgorithmMetadata(guid);
      await (metadataDao.delete(
        metadataDao.specifications,
      )..where((s) => s.algorithmGuid.equals(guid))).go();
      await (metadataDao.delete(
        metadataDao.algorithms,
      )..where((a) => a.guid.equals(guid))).go();
    } catch (_) {
      // Best effort
    }

    // Device cleanup
    try {
      await _distingManager.requestNewPreset();
      await Future.delayed(const Duration(milliseconds: 500));
    } catch (_) {
      // Best effort
    }
  }

  /// Fetches all static algorithm metadata from the connected device
  /// by temporarily manipulating a preset, and caches it in the database.
  ///
  /// [onProgress] callback reports progress (0.0-1.0), counts, and messages.
  /// [onError] callback reports errors encountered during the process.
  /// [onCheckpoint] callback saves checkpoint with algorithm name and index.
  /// [resumeFromIndex] optional algorithm index to resume from.
  /// [isCancelled] callback allows checking if cancellation has been requested.
  Future<void> syncAllAlgorithmMetadata({
    Function(
      double progress,
      int processed,
      int total,
      String mainMessage,
      String subMessage,
    )?
    onProgress,
    Function(String error)? onError,
    Future<void> Function(String algorithmName, int algorithmIndex)?
    onCheckpoint,
    int? resumeFromIndex,
    bool Function()? isCancelled,
  }) async {
    final metadataDao = _database.metadataDao;
    int totalAlgorithms = 0;
    int algorithmsProcessed = 0;
    late final FirmwareVersion firmwareVersion;

    void reportProgress(
      String mainMessage,
      String subMessage, {
      bool incrementCount = false,
    }) {
      if (incrementCount) {
        algorithmsProcessed++;
      }
      final progress = totalAlgorithms == 0
          ? 0.0
          : algorithmsProcessed / totalAlgorithms;
      onProgress?.call(
        progress,
        algorithmsProcessed,
        totalAlgorithms,
        mainMessage,
        subMessage,
      );
    }

    // Helper to check cancellation
    bool checkCancel() => isCancelled?.call() ?? false;

    try {
      reportProgress("Initializing Sync", "Starting...");
      if (checkCancel()) return;

      // Ensure device is awake
      reportProgress("Initializing Sync", "Waking device...");
      await _distingManager.requestWake();
      await Future.delayed(const Duration(milliseconds: 200));
      if (checkCancel()) return;

      firmwareVersion = await _requestFirmwareVersionSafe();

      // Clear device preset and DB cache (only if not resuming)
      if (resumeFromIndex == null) {
        reportProgress(
          "Initializing Sync",
          "Clearing device preset and local cache...",
        );
        await metadataDao.clearAllMetadata(); // Clear DB first
        await _distingManager.requestNewPreset(); // Clear on device
        await Future.delayed(
          const Duration(milliseconds: 500),
        ); // Allow device time
        if (checkCancel()) return;
      } else {
        reportProgress("Resuming Sync", "Clearing device preset...");
        await _distingManager.requestNewPreset(); // Clear on device
        await Future.delayed(
          const Duration(milliseconds: 500),
        ); // Allow device time
        if (checkCancel()) return;
      }

      // Verify preset is empty
      var numInPreset =
          await _distingManager.requestNumAlgorithmsInPreset() ?? -1;
      if (numInPreset != 0) {
        throw Exception(
          "Failed to clear device preset (expected 0 algorithms, found $numInPreset).",
        );
      }

      // 1. Sync Unit Strings
      reportProgress(
        "Fetching Prerequisite Data",
        "Requesting unit strings...",
      );
      final unitStrings = await _distingManager.requestUnitStrings() ?? [];
      final unitIdMap = <String, int>{};
      final unitFutures = <Future<void>>[];
      for (final unitStr in unitStrings) {
        if (unitStr.isNotEmpty) {
          unitFutures.add(
            metadataDao.upsertUnit(unitStr).then((id) {
              unitIdMap[unitStr] = id;
            }),
          );
        }
      }
      await Future.wait(unitFutures);
      reportProgress(
        "Fetching Prerequisite Data",
        "Cached ${unitIdMap.length} unit strings.",
      );
      if (checkCancel()) return;

      // --- NEW: Save the ordered list to the cache ---
      try {
        await metadataDao.saveOrderedUnitStrings(unitStrings);
      } catch (e) {
        // Decide if this is a fatal error - maybe not, if reconstruction can fall back?
        // For now, we just log a warning.
      }
      // --- END NEW ---

      // 2. Get All Algorithm Basic Info
      reportProgress(
        "Fetching Algorithm List",
        "Requesting number of algorithms...",
      );
      final numAlgoTypes = await _distingManager.requestNumberOfAlgorithms();
      if (numAlgoTypes == null || numAlgoTypes == 0) {
        reportProgress(
          "Fetching Algorithm List",
          "No algorithm types found on device.",
        );
        throw Exception("No algorithm types found on device.");
      }
      totalAlgorithms = numAlgoTypes;
      reportProgress(
        "Fetching Algorithm List ($totalAlgorithms total)",
        "Requesting basic info...",
      );

      final allAlgorithmInfo = <AlgorithmInfo>[];
      final algoEntries = <AlgorithmEntry>[];
      final specEntries = <SpecificationEntry>[];

      for (
        int globalAlgoIndex = 0;
        globalAlgoIndex < totalAlgorithms;
        globalAlgoIndex++
      ) {
        if (checkCancel()) break;
        final algoInfo = await _distingManager.requestAlgorithmInfo(
          globalAlgoIndex,
        );
        if (algoInfo != null) {
          allAlgorithmInfo.add(algoInfo);
          algoEntries.add(
            AlgorithmEntry(
              guid: algoInfo.guid,
              name: algoInfo.name,
              numSpecifications: algoInfo.numSpecifications,
            ),
          );

          if (algoInfo.specifications.isNotEmpty) {
            specEntries.addAll(
              algoInfo.specifications.asMap().entries.map((entry) {
                final index = entry.key;
                final spec = entry.value;
                return SpecificationEntry(
                  algorithmGuid: algoInfo.guid,
                  specIndex: index,
                  name: spec.name,
                  minValue: spec.min,
                  maxValue: spec.max,
                  defaultValue: spec.defaultValue,
                  type: spec.type,
                );
              }),
            );
          }
        } else {}
        final fetchProgressMsg =
            "Fetched basic info ${globalAlgoIndex + 1}/$totalAlgorithms";
        reportProgress(
          "Fetching Algorithm List ($totalAlgorithms total)",
          fetchProgressMsg,
        );
      }
      if (checkCancel()) return;

      // Upsert basic info *before* instantiation loop
      await metadataDao.upsertAlgorithms(algoEntries);
      await metadataDao.upsertSpecifications(specEntries);
      reportProgress(
        "Fetching Algorithm List ($totalAlgorithms total)",
        "Cached basic info for ${allAlgorithmInfo.length} algorithms.",
      );
      if (checkCancel()) return;

      // Reset processed count before starting instantiation phase
      algorithmsProcessed = resumeFromIndex ?? 0;

      // 3. Process Factory Algorithms (skip community plugins)
      reportProgress(
        "Processing Algorithms",
        "Starting algorithm processing...",
      );

      // Filter to factory algorithms only (lowercase alphanumeric GUIDs).
      // Community plugins (uppercase GUIDs) cause memory issues during sync
      // and are skipped here — their basic info is already cached above.
      final orderedAlgorithms = allAlgorithmInfo
          .where((a) => _isFactoryGuid(a.guid))
          .toList();
      totalAlgorithms = orderedAlgorithms.length;

      final dbUnits = await metadataDao.getAllUnits();
      final dbUnitStrings = dbUnits.map((u) => u.unitString).toList();

      // 4. Process All Algorithms in Single Loop
      final failedPlugins = <AlgorithmInfo>[];

      for (int i = 0; i < orderedAlgorithms.length; i++) {
        if (checkCancel()) break;

        // Skip if resuming and haven't reached resume point
        if (resumeFromIndex != null && i < resumeFromIndex) {
          algorithmsProcessed++;
          continue;
        }

        final algoInfo = orderedAlgorithms[i];
        final mainProgressMsg = algoInfo.name;

        // Save checkpoint before processing each algorithm
        await onCheckpoint?.call(algoInfo.name, i);

        reportProgress(mainProgressMsg, "Starting...", incrementCount: true);

        try {
          await _tryScanAlgorithm(
            algoInfo: algoInfo,
            metadataDao: metadataDao,
            unitIdMap: unitIdMap,
            dbUnitStrings: dbUnitStrings,
            firmwareVersion: firmwareVersion,
            checkCancel: checkCancel,
          );
          reportProgress(mainProgressMsg, "Done.");
        } catch (instantiationError, stackTrace) {
          debugPrintStack(stackTrace: stackTrace);

          if (_isTimeoutError(instantiationError)) {
            // Timeout — auto-reboot and retry
            reportProgress(
              mainProgressMsg,
              "Timeout detected — rebooting device...",
            );
            try {
              await _rebootAndWaitForReconnection(
                onStatus: (msg) => reportProgress(mainProgressMsg, msg),
                checkCancel: checkCancel,
              );
              if (checkCancel()) break;

              reportProgress(mainProgressMsg, "Retrying after reboot...");
              await _tryScanAlgorithm(
                algoInfo: algoInfo,
                metadataDao: metadataDao,
                unitIdMap: unitIdMap,
                dbUnitStrings: dbUnitStrings,
                firmwareVersion: firmwareVersion,
                checkCancel: checkCancel,
              );
              reportProgress(mainProgressMsg, "Retry succeeded.");
            } catch (retryError) {
              // Retry failed — defer to end-of-scan pass
              failedPlugins.add(algoInfo);
              await _cleanupFailedAlgorithm(metadataDao, algoInfo.guid);
              reportProgress(
                mainProgressMsg,
                "Deferred for end-of-scan retry.",
              );
            }
          } else {
            // Non-timeout error — report and clean up
            onError?.call(
              "Error processing ${algoInfo.name}: $instantiationError",
            );
            await _cleanupFailedAlgorithm(metadataDao, algoInfo.guid);
          }
        }
      }

      // 4b. End-of-scan retry pass for failed plugins
      if (failedPlugins.isNotEmpty && !checkCancel()) {
        reportProgress(
          "Retrying Failed Plugins",
          "Rescanning plugins and rebooting...",
        );
        try {
          await _distingManager.requestRescanPlugins();
          // Wait 5 seconds for rescan to complete
          for (int i = 0; i < 5; i++) {
            if (checkCancel()) break;
            await Future.delayed(const Duration(seconds: 1));
          }
          if (!checkCancel()) {
            await _rebootAndWaitForReconnection(
              onStatus: (msg) =>
                  reportProgress("Retrying Failed Plugins", msg),
              checkCancel: checkCancel,
            );
          }
        } catch (e) {
          reportProgress(
            "Retrying Failed Plugins",
            "Rescan/reboot failed: $e",
          );
        }

        if (!checkCancel()) {
          for (final algoInfo in failedPlugins) {
            if (checkCancel()) break;
            final retryMsg = "${algoInfo.name} (final retry)";
            reportProgress(retryMsg, "Starting final retry...");
            try {
              await _tryScanAlgorithm(
                algoInfo: algoInfo,
                metadataDao: metadataDao,
                unitIdMap: unitIdMap,
                dbUnitStrings: dbUnitStrings,
                firmwareVersion: firmwareVersion,
                checkCancel: checkCancel,
              );
              reportProgress(retryMsg, "Final retry succeeded.");
            } catch (finalError) {
              onError?.call(
                "Failed to scan ${algoInfo.name} after all retries: $finalError",
              );
              await _cleanupFailedAlgorithm(metadataDao, algoInfo.guid);
            }
          }
        }
      }

      // 5. Final pass: Retry algorithms with 0 parameters
      if (!checkCancel()) {
        reportProgress(
          "Final Verification",
          "Checking for algorithms with missing parameters...",
        );

        final algorithmsWithZeroParams = <AlgorithmInfo>[];
        try {
          final parameterCounts = await metadataDao
              .getAlgorithmParameterCounts();

          for (final algoInfo in orderedAlgorithms) {
            final paramCount = parameterCounts[algoInfo.guid] ?? 0;
            if (paramCount == 0) {
              algorithmsWithZeroParams.add(algoInfo);
            }
          }
        } catch (e) {
          // Intentionally empty
        }

        if (algorithmsWithZeroParams.isNotEmpty && !checkCancel()) {
          reportProgress(
            "Final Verification",
            "Retrying ${algorithmsWithZeroParams.length} algorithms with missing parameters...",
          );

          for (final algoInfo in algorithmsWithZeroParams) {
            if (checkCancel()) break;

            final mainProgressMsg = "${algoInfo.name} (retry)";
            reportProgress(mainProgressMsg, "Starting retry...");

            try {
              await _tryScanAlgorithm(
                algoInfo: algoInfo,
                metadataDao: metadataDao,
                unitIdMap: unitIdMap,
                dbUnitStrings: dbUnitStrings,
                firmwareVersion: firmwareVersion,
                checkCancel: checkCancel,
              );
              reportProgress(mainProgressMsg, "Retry completed.");
            } catch (retryError, stackTrace) {
              debugPrintStack(stackTrace: stackTrace);

              // Clean up if retry fails
              try {
                await _distingManager.requestNewPreset();
                await Future.delayed(const Duration(milliseconds: 500));
              } catch (cleanupError) {
                // Intentionally empty
              }
            }
          }
        } else {
          reportProgress(
            "Final Verification",
            "All algorithms have parameters - verification complete.",
          );
        }
      }

      // Check cancellation one last time before final success message
      if (checkCancel()) {
        reportProgress("Synchronization Cancelled", "Process stopped by user.");
      } else {
        reportProgress("Synchronization Complete", "Finished all algorithms.");
      }
    } catch (e, stackTrace) {
      final errorMsg = "Synchronization failed: $e";
      debugPrintStack(stackTrace: stackTrace);
      // Avoid reporting progress if cancelled, let the main error handler do it
      if (!checkCancel()) {
        reportProgress("Synchronization Failed", "Error: $e");
      }
      onError?.call(errorMsg);
    }
  }

  // Helper to sync parameters, pages, enums for an algorithm *instantiated at slot 0*
  Future<void> _syncInstantiatedAlgorithmParams(
    MetadataDao metadataDao,
    AlgorithmInfo algoInfo, // Contains the GUID
    Map<String, int> unitIdMap, // Map of unit string -> db id
    List<String> dbUnitStrings, // List of known unit strings
    FirmwareVersion firmwareVersion,
  ) async {
    // Queries use slot index 0
    final numParamsResult = await _distingManager.requestNumberOfParameters(0);
    final numParams = numParamsResult?.numParameters ?? 0;
    if (numParams == 0) {
      return;
    }

    final parameterInfos = <ParameterInfo>[];
    final parameterPagesResult = await _distingManager.requestParameterPages(0);
    final enumStringsMap = <int, List<String>>{};

    // Fetch all parameter info using slot index 0
    for (int pNum = 0; pNum < numParams; pNum++) {
      final paramInfo = await _distingManager.requestParameterInfo(0, pNum);
      if (paramInfo != null) {
        // Use paramInfo.copyWith to ensure algorithmIndex is 0 if needed,
        // though it might not matter for processing if we only use parameterNumber
        parameterInfos.add(paramInfo);
        if (paramInfo.unit == 1) {
          // Skip enum strings for Macro Oscillator Model parameter (firmware bug)
          if (firmwareVersion.isExactly('1.12.0') &&
              algoInfo.guid == 'maco' &&
              pNum == 1) {
            continue;
          }
          final enumsResult = await _distingManager.requestParameterEnumStrings(
            0,
            pNum,
          );
          if (enumsResult != null && enumsResult.values.isNotEmpty) {
            enumStringsMap[pNum] = enumsResult.values;
          }
        }
      } else {}
    }

    // Process and Store Parameter Definitions (using insertOrIgnore)
    final paramEntries = <ParameterEntry>[];
    final uniqueBaseParams =
        <int>{}; // Track parameterNumber already processed for base definition

    for (final paramInfo in parameterInfos) {
      // Assume paramInfo.parameterNumber is the key, even if name is prefixed
      final paramNumKey = paramInfo.parameterNumber;

      // Only process the base definition once per parameterNumber
      if (uniqueBaseParams.contains(paramNumKey)) continue;
      uniqueBaseParams.add(paramNumKey);

      // Preserve the full parameter name including channel prefixes
      // This ensures multi-channel algorithms have distinguishable parameters
      String baseName = paramInfo.name;

      final unitStr = paramInfo.getUnitString(dbUnitStrings);
      final unitId = (unitStr == null) ? null : unitIdMap[unitStr];

      paramEntries.add(
        ParameterEntry(
          algorithmGuid: algoInfo.guid,
          parameterNumber: paramNumKey,
          name: baseName,
          minValue: paramInfo.min,
          maxValue: paramInfo.max,
          defaultValue: paramInfo.defaultValue,
          unitId: unitId,
          powerOfTen: paramInfo.powerOfTen,
          rawUnitIndex: paramInfo.unit,
          ioFlags: paramInfo.ioFlags,
        ),
      );
    }
    // Use insertOrIgnore mode via metadataDao.batch
    await metadataDao.batch((batch) {
      batch.insertAll(
        metadataDao.parameters,
        paramEntries,
        mode: InsertMode.insertOrIgnore,
      );
    });

    // Collect output mode usage data for parameters with isOutputMode flag
    final outputModeUsageEntries = <ParameterOutputModeUsageEntry>[];

    for (final paramInfo in parameterInfos) {
      // Check if this parameter is an output mode control (bit 3 of ioFlags)
      if (paramInfo.isOutputMode) {
        try {
          // Query the hardware for which outputs are affected by this mode parameter
          final outputModeUsage = await _distingManager.requestOutputModeUsage(
            0, // Algorithm is always in slot 0 during sync
            paramInfo.parameterNumber,
          );

          if (outputModeUsage != null &&
              outputModeUsage.affectedParameterNumbers.isNotEmpty) {
            // Store the relationship for database persistence
            outputModeUsageEntries.add(
              ParameterOutputModeUsageEntry(
                algorithmGuid: algoInfo.guid,
                parameterNumber: paramInfo.parameterNumber,
                affectedOutputNumbers: outputModeUsage.affectedParameterNumbers,
              ),
            );
          }
        } catch (e) {
          // Silently ignore output mode query failures
          // This is supplementary metadata, not critical for basic functionality
        }
      }
    }

    // Persist output mode usage data to database
    if (outputModeUsageEntries.isNotEmpty) {
      await metadataDao.upsertOutputModeUsage(outputModeUsageEntries);
    }

    // Upsert Parameter Enums (link to the parameterNumber key)
    final enumEntries = <ParameterEnumEntry>[];
    enumStringsMap.forEach((paramNumKey, strings) {
      // Only add enums if we actually stored this base parameterNumber
      if (uniqueBaseParams.contains(paramNumKey)) {
        strings.asMap().forEach((index, str) {
          enumEntries.add(
            ParameterEnumEntry(
              algorithmGuid: algoInfo.guid,
              parameterNumber: paramNumKey,
              enumIndex: index,
              enumString: str,
            ),
          );
        });
      }
    });
    if (enumEntries.isNotEmpty) {
      // Use insertOrReplace via metadataDao.batch
      await metadataDao.batch((batch) {
        batch.insertAll(
          metadataDao.parameterEnums,
          enumEntries,
          mode: InsertMode.insertOrReplace,
        );
      });
    }

    // Upsert Parameter Pages and Items (link to the parameterNumber key)
    if (parameterPagesResult != null && parameterPagesResult.pages.isNotEmpty) {
      final pageEntries = <ParameterPageEntry>[];
      final pageItemEntries = <ParameterPageItemEntry>[];
      final Set<int> storedParamNumbers = paramEntries
          .map((p) => p.parameterNumber)
          .toSet();

      parameterPagesResult.pages.asMap().forEach((index, page) {
        pageEntries.add(
          ParameterPageEntry(
            algorithmGuid: algoInfo.guid,
            pageIndex: index,
            name: page.name,
          ),
        );
        for (final paramNumKey in page.parameters) {
          // Only add page items for parameters we actually stored a definition for
          if (storedParamNumbers.contains(paramNumKey)) {
            pageItemEntries.add(
              ParameterPageItemEntry(
                algorithmGuid: algoInfo.guid,
                pageIndex: index,
                parameterNumber: paramNumKey,
              ),
            );
          } else {}
        }
      });
      // Use replace mode for pages/items within an algorithm, assuming pages are definitive per sync
      await metadataDao.upsertParameterPages(pageEntries);
      await metadataDao.upsertParameterPageItems(pageItemEntries);
    } else {}
  }

  /// Rescan a single algorithm's parameters
  Future<void> rescanSingleAlgorithm(AlgorithmInfo algoInfo) async {
    final metadataDao = _database.metadataDao;
    final firmwareVersion = await _requestFirmwareVersionSafe();
    final dbUnits = await metadataDao.getAllUnits();
    final dbUnitStrings = dbUnits.map((u) => u.unitString).toList();
    final unitIdMap = <String, int>{};
    for (final unit in dbUnits) {
      unitIdMap[unit.unitString] = unit.id;
    }

    // Clear existing parameter data for this algorithm
    await metadataDao.clearAlgorithmMetadata(algoInfo.guid);

    try {
      await _tryScanAlgorithm(
        algoInfo: algoInfo,
        metadataDao: metadataDao,
        unitIdMap: unitIdMap,
        dbUnitStrings: dbUnitStrings,
        firmwareVersion: firmwareVersion,
      );
    } catch (error) {
      if (_isTimeoutError(error)) {
        // Timeout — reboot and retry once
        await _rebootAndWaitForReconnection();
        await _tryScanAlgorithm(
          algoInfo: algoInfo,
          metadataDao: metadataDao,
          unitIdMap: unitIdMap,
          dbUnitStrings: dbUnitStrings,
          firmwareVersion: firmwareVersion,
        );
      } else {
        rethrow;
      }
    }
  }

  /// Incrementally sync only new algorithms not present in the database
  Future<void> syncNewAlgorithmsOnly({
    Function(
      double progress,
      int processed,
      int total,
      String mainMessage,
      String subMessage,
    )?
    onProgress,
    Function(String error)? onError,
    bool Function()? isCancelled,
  }) async {
    final metadataDao = _database.metadataDao;
    late final FirmwareVersion firmwareVersion;

    void reportProgress(
      String mainMessage,
      String subMessage, {
      int processed = 0,
      int total = 0,
    }) {
      final progress = total == 0 ? 0.0 : processed / total;
      onProgress?.call(progress, processed, total, mainMessage, subMessage);
    }

    // Helper to check cancellation
    bool checkCancel() => isCancelled?.call() ?? false;

    try {
      reportProgress("Checking for New Algorithms", "Connecting to device...");
      if (checkCancel()) return;

      // Ensure device is awake
      await _distingManager.requestWake();
      await Future.delayed(const Duration(milliseconds: 200));
      if (checkCancel()) return;

      firmwareVersion = await _requestFirmwareVersionSafe();

      // Get current algorithm list from device
      reportProgress(
        "Checking for New Algorithms",
        "Getting device algorithm list...",
      );
      final numAlgoTypes = await _distingManager.requestNumberOfAlgorithms();
      if (numAlgoTypes == null || numAlgoTypes == 0) {
        throw Exception("No algorithm types found on device.");
      }

      final deviceAlgorithms = <AlgorithmInfo>[];
      for (int i = 0; i < numAlgoTypes; i++) {
        if (checkCancel()) break;
        final algoInfo = await _distingManager.requestAlgorithmInfo(i);
        if (algoInfo != null) {
          deviceAlgorithms.add(algoInfo);
        }
        reportProgress(
          "Checking for New Algorithms",
          "Found ${deviceAlgorithms.length}/$numAlgoTypes algorithms on device...",
        );
      }
      if (checkCancel()) return;

      // Get current algorithm list from database
      reportProgress(
        "Checking for New Algorithms",
        "Getting local algorithm list...",
      );
      final localAlgorithms = await metadataDao.getAllAlgorithms();
      final localGuids = localAlgorithms.map((a) => a.guid).toSet();

      // Find new algorithms (present on device but not in database)
      final newAlgorithms = deviceAlgorithms
          .where((deviceAlgo) => !localGuids.contains(deviceAlgo.guid))
          .toList();

      if (newAlgorithms.isEmpty) {
        reportProgress(
          "Incremental Sync Complete",
          "No new algorithms found.",
          processed: 0,
          total: 0,
        );
        return;
      }

      for (final _ in newAlgorithms) {}

      // Process community plugins first, then factory algorithms
      final newCommunityAlgorithms = newAlgorithms
          .where((a) => a.isPlugin)
          .toList();
      final newFactoryAlgorithms = newAlgorithms
          .where((a) => !a.isPlugin)
          .toList();
      final orderedNewAlgorithms = [
        ...newCommunityAlgorithms,
        ...newFactoryAlgorithms,
      ];

      // Sync unit strings if needed (in case new algorithms introduce new units)
      reportProgress(
        "Syncing Prerequisites",
        "Updating unit strings...",
        processed: 0,
        total: orderedNewAlgorithms.length,
      );
      final unitStrings = await _distingManager.requestUnitStrings() ?? [];
      final unitIdMap = <String, int>{};
      final unitFutures = <Future<void>>[];
      for (final unitStr in unitStrings) {
        if (unitStr.isNotEmpty) {
          unitFutures.add(
            metadataDao.upsertUnit(unitStr).then((id) {
              unitIdMap[unitStr] = id;
            }),
          );
        }
      }
      await Future.wait(unitFutures);
      if (checkCancel()) return;

      // Get existing units for parameter processing
      final dbUnits = await metadataDao.getAllUnits();
      final dbUnitStrings = dbUnits.map((u) => u.unitString).toList();

      // Clear device preset before starting
      reportProgress(
        "Syncing Prerequisites",
        "Clearing device preset...",
        processed: 0,
        total: orderedNewAlgorithms.length,
      );
      await _distingManager.requestNewPreset();
      await Future.delayed(const Duration(milliseconds: 500));
      if (checkCancel()) return;

      // Process new algorithms
      final failedPlugins = <AlgorithmInfo>[];

      for (int i = 0; i < orderedNewAlgorithms.length; i++) {
        if (checkCancel()) break;

        final algoInfo = orderedNewAlgorithms[i];
        final mainProgressMsg = "${algoInfo.name} (new)";

        reportProgress(
          mainProgressMsg,
          "Starting sync...",
          processed: i,
          total: orderedNewAlgorithms.length,
        );

        try {
          // Store basic algorithm info first
          await metadataDao.upsertAlgorithms([
            AlgorithmEntry(
              guid: algoInfo.guid,
              name: algoInfo.name,
              numSpecifications: algoInfo.numSpecifications,
            ),
          ]);

          if (algoInfo.specifications.isNotEmpty) {
            final specEntries = algoInfo.specifications.asMap().entries.map((
              entry,
            ) {
              final index = entry.key;
              final spec = entry.value;
              return SpecificationEntry(
                algorithmGuid: algoInfo.guid,
                specIndex: index,
                name: spec.name,
                minValue: spec.min,
                maxValue: spec.max,
                defaultValue: spec.defaultValue,
                type: spec.type,
              );
            }).toList();
            await metadataDao.upsertSpecifications(specEntries);
          }

          await _tryScanAlgorithm(
            algoInfo: algoInfo,
            metadataDao: metadataDao,
            unitIdMap: unitIdMap,
            dbUnitStrings: dbUnitStrings,
            firmwareVersion: firmwareVersion,
            checkCancel: checkCancel,
          );

          reportProgress(
            mainProgressMsg,
            "Completed.",
            processed: i + 1,
            total: orderedNewAlgorithms.length,
          );
        } catch (error, stackTrace) {
          debugPrintStack(stackTrace: stackTrace);

          if (_isTimeoutError(error)) {
            // Timeout — auto-reboot and retry
            reportProgress(
              mainProgressMsg,
              "Timeout detected — rebooting device...",
              processed: i,
              total: orderedNewAlgorithms.length,
            );
            try {
              await _rebootAndWaitForReconnection(
                onStatus: (msg) => reportProgress(
                  mainProgressMsg,
                  msg,
                  processed: i,
                  total: orderedNewAlgorithms.length,
                ),
                checkCancel: checkCancel,
              );
              if (checkCancel()) break;

              reportProgress(
                mainProgressMsg,
                "Retrying after reboot...",
                processed: i,
                total: orderedNewAlgorithms.length,
              );
              await _tryScanAlgorithm(
                algoInfo: algoInfo,
                metadataDao: metadataDao,
                unitIdMap: unitIdMap,
                dbUnitStrings: dbUnitStrings,
                firmwareVersion: firmwareVersion,
                checkCancel: checkCancel,
              );
              reportProgress(
                mainProgressMsg,
                "Retry succeeded.",
                processed: i + 1,
                total: orderedNewAlgorithms.length,
              );
            } catch (retryError) {
              // Retry failed — defer to end-of-scan pass
              failedPlugins.add(algoInfo);
              await _cleanupFailedAlgorithm(metadataDao, algoInfo.guid);
              reportProgress(
                mainProgressMsg,
                "Deferred for end-of-scan retry.",
                processed: i,
                total: orderedNewAlgorithms.length,
              );
            }
          } else {
            // Non-timeout error — report and clean up
            onError?.call(
              "Error syncing new algorithm ${algoInfo.name}: $error",
            );
            await _cleanupFailedAlgorithm(metadataDao, algoInfo.guid);
          }
        }
      }

      // End-of-scan retry pass for failed plugins
      if (failedPlugins.isNotEmpty && !checkCancel()) {
        reportProgress(
          "Retrying Failed Plugins",
          "Rescanning plugins and rebooting...",
          processed: orderedNewAlgorithms.length - failedPlugins.length,
          total: orderedNewAlgorithms.length,
        );
        try {
          await _distingManager.requestRescanPlugins();
          for (int i = 0; i < 5; i++) {
            if (checkCancel()) break;
            await Future.delayed(const Duration(seconds: 1));
          }
          if (!checkCancel()) {
            await _rebootAndWaitForReconnection(
              onStatus: (msg) => reportProgress(
                "Retrying Failed Plugins",
                msg,
                processed: orderedNewAlgorithms.length - failedPlugins.length,
                total: orderedNewAlgorithms.length,
              ),
              checkCancel: checkCancel,
            );
          }
        } catch (e) {
          reportProgress(
            "Retrying Failed Plugins",
            "Rescan/reboot failed: $e",
            processed: orderedNewAlgorithms.length - failedPlugins.length,
            total: orderedNewAlgorithms.length,
          );
        }

        if (!checkCancel()) {
          for (final algoInfo in failedPlugins) {
            if (checkCancel()) break;
            final retryMsg = "${algoInfo.name} (final retry)";
            reportProgress(
              retryMsg,
              "Starting final retry...",
              processed: orderedNewAlgorithms.length - failedPlugins.length,
              total: orderedNewAlgorithms.length,
            );
            try {
              await _tryScanAlgorithm(
                algoInfo: algoInfo,
                metadataDao: metadataDao,
                unitIdMap: unitIdMap,
                dbUnitStrings: dbUnitStrings,
                firmwareVersion: firmwareVersion,
                checkCancel: checkCancel,
              );
              reportProgress(
                retryMsg,
                "Final retry succeeded.",
                processed: orderedNewAlgorithms.length,
                total: orderedNewAlgorithms.length,
              );
            } catch (finalError) {
              onError?.call(
                "Failed to scan ${algoInfo.name} after all retries: $finalError",
              );
              await _cleanupFailedAlgorithm(metadataDao, algoInfo.guid);
            }
          }
        }
      }

      if (checkCancel()) {
        reportProgress(
          "Incremental Sync Cancelled",
          "Process stopped by user.",
          processed: orderedNewAlgorithms.length,
          total: orderedNewAlgorithms.length,
        );
      } else {
        reportProgress(
          "Incremental Sync Complete",
          "Synced ${orderedNewAlgorithms.length} new algorithms.",
          processed: orderedNewAlgorithms.length,
          total: orderedNewAlgorithms.length,
        );
      }
    } catch (e, stackTrace) {
      final errorMsg = "Incremental sync failed: $e";
      debugPrintStack(stackTrace: stackTrace);
      if (!checkCancel()) {
        reportProgress("Incremental Sync Failed", "Error: $e");
      }
      onError?.call(errorMsg);
    }
  }

  /// Scan plugin directory and update algorithm records with file paths
  Future<void> scanAndUpdatePluginFilePaths({
    Function(String status)? onProgress,
    Function(String error)? onError,
  }) async {
    try {
      onProgress?.call("Scanning plugin directory...");

      // Create PresetFileSystemImpl with the MIDI manager
      final fileSystem = PresetFileSystemImpl(_distingManager);

      // Scan the plugin directory for .o files and extract GUIDs
      final pluginDirectory = "/programs/plug-ins";
      final guidToFilePathMap = await ElfGuidExtractor.scanPluginDirectory(
        fileSystem,
        pluginDirectory,
      );

      if (guidToFilePathMap.isEmpty) {
        onProgress?.call("No plugin files found.");
        return;
      }

      onProgress?.call("Updating algorithm records...");

      final metadataDao = _database.metadataDao;
      int updatedCount = 0;

      for (final entry in guidToFilePathMap.entries) {
        final guid = entry.key;
        final filePath = entry.value;

        try {
          // Check if algorithm exists in database
          final algorithm = await metadataDao.getAlgorithmByGuid(guid);
          if (algorithm != null) {
            // Update the plugin file path
            await metadataDao.updateAlgorithmPluginFilePath(guid, filePath);
            updatedCount++;
          } else {}
        } catch (e) {
          onError?.call("Error updating algorithm $guid: $e");
        }
      }

      final message =
          "Updated $updatedCount algorithm records with plugin file paths.";
      onProgress?.call(message);
    } catch (e) {
      final errorMsg = "Plugin scan failed: $e";
      onError?.call(errorMsg);
    }
  }
}
