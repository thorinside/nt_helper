import 'dart:async';

import 'package:drift/drift.dart'; // Import drift for InsertMode
import 'package:flutter/foundation.dart';
import 'package:nt_helper/db/database.dart';
import 'package:nt_helper/db/daos/metadata_dao.dart'; // Import the DAO type
import 'package:nt_helper/domain/disting_nt_sysex.dart'
    show AlgorithmInfo, ParameterInfo;

import 'package:nt_helper/domain/i_disting_midi_manager.dart'
    show IDistingMidiManager;
import 'package:nt_helper/services/elf_guid_extractor.dart';
import 'package:nt_helper/interfaces/impl/preset_file_system_impl.dart';

/// Service to synchronize static algorithm metadata from the device to the local database.
class MetadataSyncService {
  final IDistingMidiManager _distingManager;
  final AppDatabase _database;

  MetadataSyncService(this._distingManager, this._database);

  /// Fetches all static algorithm metadata from the connected device
  /// by temporarily manipulating a preset, and caches it in the database.
  ///
  /// [onProgress] callback reports progress (0.0-1.0), counts, and messages.
  /// [onError] callback reports errors encountered during the process.
  /// [onContinueRequired] callback prompts user to continue after reboot (returns Future&lt;bool&gt;).
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
    Future<bool> Function(String message)? onContinueRequired,
    Future<void> Function(String algorithmName, int algorithmIndex)?
    onCheckpoint,
    int? resumeFromIndex,
    bool Function()? isCancelled,
  }) async {
    final metadataDao = _database.metadataDao;
    int totalAlgorithms = 0;
    int algorithmsProcessed = 0;

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
      debugPrint(
        "[MetadataSync] Progress: $algorithmsProcessed/$totalAlgorithms - $mainMessage - $subMessage",
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
        debugPrint("[MetadataSync] Saved ordered unit strings to cache.");
      } catch (e) {
        debugPrint(
          "[MetadataSync] Warning: Failed to save ordered unit strings to cache: $e",
        );
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
        } else {
          debugPrint(
            "[MetadataSync] Warning: Could not fetch info for global algo index $globalAlgoIndex",
          );
        }
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

      // 3. Process All Algorithms (Community First, then Factory)
      reportProgress(
        "Processing Algorithms",
        "Starting algorithm processing...",
      );

      // Separate but keep original order within each type
      final communityAlgorithms = <AlgorithmInfo>[];
      final factoryAlgorithms = <AlgorithmInfo>[];

      for (final algoInfo in allAlgorithmInfo) {
        if (algoInfo.isPlugin) {
          communityAlgorithms.add(algoInfo);
        } else {
          factoryAlgorithms.add(algoInfo);
        }
      }

      // Process community first for faster testing, then factory
      final orderedAlgorithms = [...communityAlgorithms, ...factoryAlgorithms];

      debugPrint(
        "[MetadataSync] Processing ${communityAlgorithms.length} community plugins, then ${factoryAlgorithms.length} factory algorithms.",
      );

      final dbUnits = await metadataDao.getAllUnits();
      final dbUnitStrings = dbUnits.map((u) => u.unitString).toList();

      // 4. Process All Algorithms in Single Loop
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
          // A. Load plugin if it's a community plugin that needs loading
          if (algoInfo.isPlugin && !algoInfo.isLoaded) {
            reportProgress(mainProgressMsg, "Loading plugin...");
            if (checkCancel()) break;
            await _distingManager.requestLoadPlugin(algoInfo.guid);
            await Future.delayed(
              const Duration(milliseconds: 1000),
            ); // Wait for plugin to load
            if (checkCancel()) break;
          }

          // B. Add algorithm with default specs to slot 0
          reportProgress(mainProgressMsg, "Adding to preset...");
          if (checkCancel()) break;
          final defaultSpecs = algoInfo.specifications
              .map((s) => s.defaultValue)
              .toList();
          await _distingManager.requestAddAlgorithm(algoInfo, defaultSpecs);

          // C. Poll until algorithm is added to preset
          reportProgress(
            mainProgressMsg,
            "Waiting for algorithm to be added...",
          );
          if (checkCancel()) break;

          var numInPreset = 0;
          var attempts = 0;
          final maxAttempts = algoInfo.isPlugin
              ? 15
              : 10; // More time for plugins

          while (numInPreset != 1 && attempts < maxAttempts && !checkCancel()) {
            await Future.delayed(const Duration(milliseconds: 500));
            numInPreset =
                await _distingManager.requestNumAlgorithmsInPreset() ?? -1;
            attempts++;

            if (numInPreset != 1) {
              debugPrint(
                "[MetadataSync] Waiting for ${algoInfo.name} to be added (attempt $attempts/$maxAttempts, found $numInPreset algorithms)",
              );
            }
          }

          if (checkCancel()) break;

          if (numInPreset != 1) {
            throw Exception(
              "Failed to add algorithm to preset after $attempts attempts (expected 1, found $numInPreset).",
            );
          }

          // D. Query the instantiated algorithm parameters
          reportProgress(mainProgressMsg, "Querying parameters...");
          if (checkCancel()) break;

          // For community plugins, reload algorithm info after adding
          final algorithmToQuery = algoInfo.isPlugin
              ? (await _distingManager.requestAlgorithmInfo(
                      algoInfo.algorithmIndex,
                    ) ??
                    algoInfo)
              : algoInfo;

          await _syncInstantiatedAlgorithmParams(
            metadataDao,
            algorithmToQuery,
            unitIdMap,
            dbUnitStrings,
          );

          // E. Remove algorithm from slot 0
          reportProgress(mainProgressMsg, "Removing from preset...");
          if (checkCancel()) break;
          await _distingManager.requestRemoveAlgorithm(0);

          // Poll until algorithm is removed from preset
          reportProgress(
            mainProgressMsg,
            "Waiting for algorithm to be removed...",
          );
          attempts = 0;
          const maxRemoveAttempts = 8;

          while (numInPreset != 0 &&
              attempts < maxRemoveAttempts &&
              !checkCancel()) {
            await Future.delayed(const Duration(milliseconds: 500));
            numInPreset =
                await _distingManager.requestNumAlgorithmsInPreset() ?? -1;
            attempts++;

            if (numInPreset != 0) {
              debugPrint(
                "[MetadataSync] Waiting for ${algoInfo.name} to be removed (attempt $attempts/$maxRemoveAttempts, found $numInPreset algorithms)",
              );
            }
          }

          if (numInPreset != 0) {
            debugPrint(
              "[MetadataSync] Warning: Failed to remove ${algoInfo.name} cleanly after $attempts attempts (expected 0, found $numInPreset).",
            );
          }

          reportProgress(mainProgressMsg, "Done.");
        } catch (instantiationError, stackTrace) {
          // Report the main error first
          final errorMsg =
              "Error processing ${algoInfo.name}: $instantiationError";
          debugPrint("[MetadataSync] $errorMsg");
          debugPrintStack(stackTrace: stackTrace);

          // Check if this is a timeout-related error that requires device reboot
          final errorString = instantiationError.toString();
          final isTimeoutError =
              errorString.contains('TimeoutException') ||
              errorString.contains('No response after') ||
              instantiationError is TimeoutException;

          if (isTimeoutError && onContinueRequired != null) {
            // Timeout detected - prompt for reboot
            reportProgress(
              mainProgressMsg,
              "Timeout detected - requesting device reboot...",
            );

            final shouldContinue = await onContinueRequired(
              "Algorithm ${algoInfo.name} failed with timeout errors. This may indicate the device needs a reboot. Please reboot your NT device and wait for it to fully start, then press Continue.",
            );

            if (!shouldContinue || checkCancel()) {
              reportProgress(mainProgressMsg, "Sync cancelled by user.");
              return;
            }

            reportProgress(mainProgressMsg, "Continuing after reboot...");
            // Clear any potential state issues
            try {
              await _distingManager.requestNewPreset();
              await Future.delayed(const Duration(milliseconds: 500));

              // Test communication after reboot
              final numAlgos = await _distingManager
                  .requestNumberOfAlgorithms();
              if (numAlgos == null || numAlgos != totalAlgorithms) {
                debugPrint(
                  "[MetadataSync] Communication test failed after reboot: expected $totalAlgorithms algorithms, got $numAlgos",
                );
              }
            } catch (cleanupError) {
              debugPrint(
                "[MetadataSync] Cleanup after reboot failed: $cleanupError",
              );
            }
          } else {
            onError?.call(errorMsg);
          }

          // Attempt DB cleanup
          reportProgress(mainProgressMsg, "Attempting DB cleanup...");
          try {
            await metadataDao.clearAlgorithmMetadata(algoInfo.guid);
            await (metadataDao.delete(
              metadataDao.specifications,
            )..where((s) => s.algorithmGuid.equals(algoInfo.guid))).go();
            await (metadataDao.delete(
              metadataDao.algorithms,
            )..where((a) => a.guid.equals(algoInfo.guid))).go();
            reportProgress(
              mainProgressMsg,
              "DB cleared for failed ${algoInfo.name}.",
            );
          } catch (dbClearError) {
            reportProgress(mainProgressMsg, "DB cleanup failed: $dbClearError");
          }

          // Attempt device cleanup
          reportProgress(mainProgressMsg, "Attempting device preset clear...");
          try {
            await _distingManager.requestNewPreset();
            await Future.delayed(const Duration(milliseconds: 500));
            reportProgress(mainProgressMsg, "Device preset cleared.");
          } catch (presetClearError) {
            reportProgress(
              mainProgressMsg,
              "Device preset clear failed: $presetClearError",
            );
          }
        }
      }

      // 5. Final pass: Retry algorithms with 0 parameters
      if (!checkCancel()) {
        reportProgress(
          "Final Verification",
          "Checking for algorithms with missing parameters...",
        );

        // Find algorithms with 0 parameters that should have been processed
        final algorithmsWithZeroParams = <AlgorithmInfo>[];
        try {
          final parameterCounts = await metadataDao
              .getAlgorithmParameterCounts();

          for (final algoInfo in orderedAlgorithms) {
            final paramCount = parameterCounts[algoInfo.guid] ?? 0;
            if (paramCount == 0) {
              algorithmsWithZeroParams.add(algoInfo);
              debugPrint(
                "[MetadataSync] Found algorithm with 0 parameters: ${algoInfo.name} (${algoInfo.guid})",
              );
            }
          }
        } catch (e) {
          debugPrint("[MetadataSync] Error checking parameter counts: $e");
        }

        if (algorithmsWithZeroParams.isNotEmpty && !checkCancel()) {
          debugPrint(
            "[MetadataSync] Retrying ${algorithmsWithZeroParams.length} algorithms with 0 parameters",
          );
          reportProgress(
            "Final Verification",
            "Retrying ${algorithmsWithZeroParams.length} algorithms with missing parameters...",
          );

          for (final algoInfo in algorithmsWithZeroParams) {
            if (checkCancel()) break;

            final mainProgressMsg = "${algoInfo.name} (retry)";
            reportProgress(mainProgressMsg, "Starting retry...");

            try {
              // A. Load plugin if it's a community plugin that needs loading
              if (algoInfo.isPlugin && !algoInfo.isLoaded) {
                reportProgress(mainProgressMsg, "Loading plugin...");
                await _distingManager.requestLoadPlugin(algoInfo.guid);
                await Future.delayed(const Duration(milliseconds: 1000));
                if (checkCancel()) break;
              }

              // B. Add algorithm with default specs to slot 0
              reportProgress(mainProgressMsg, "Adding to preset...");
              final defaultSpecs = algoInfo.specifications
                  .map((s) => s.defaultValue)
                  .toList();
              await _distingManager.requestAddAlgorithm(algoInfo, defaultSpecs);

              // C. Poll until algorithm is added to preset
              reportProgress(
                mainProgressMsg,
                "Waiting for algorithm to be added...",
              );
              var numInPreset = 0;
              var attempts = 0;
              final maxAttempts = algoInfo.isPlugin ? 15 : 10;

              while (numInPreset != 1 &&
                  attempts < maxAttempts &&
                  !checkCancel()) {
                await Future.delayed(const Duration(milliseconds: 500));
                numInPreset =
                    await _distingManager.requestNumAlgorithmsInPreset() ?? -1;
                attempts++;
              }

              if (checkCancel()) break;

              if (numInPreset == 1) {
                // D. Query the instantiated algorithm parameters
                reportProgress(
                  mainProgressMsg,
                  "Querying parameters (retry)...",
                );

                // For community plugins, reload algorithm info after adding
                final algorithmToQuery = algoInfo.isPlugin
                    ? (await _distingManager.requestAlgorithmInfo(
                            algoInfo.algorithmIndex,
                          ) ??
                          algoInfo)
                    : algoInfo;

                await _syncInstantiatedAlgorithmParams(
                  metadataDao,
                  algorithmToQuery,
                  unitIdMap,
                  dbUnitStrings,
                );

                // E. Remove algorithm from slot 0
                reportProgress(mainProgressMsg, "Removing from preset...");
                await _distingManager.requestRemoveAlgorithm(0);

                // Poll until algorithm is removed
                attempts = 0;
                const maxRemoveAttempts = 8;

                while (numInPreset != 0 &&
                    attempts < maxRemoveAttempts &&
                    !checkCancel()) {
                  await Future.delayed(const Duration(milliseconds: 500));
                  numInPreset =
                      await _distingManager.requestNumAlgorithmsInPreset() ??
                      -1;
                  attempts++;
                }

                reportProgress(mainProgressMsg, "Retry completed.");
                debugPrint(
                  "[MetadataSync] Successfully retried ${algoInfo.name}",
                );
              } else {
                debugPrint(
                  "[MetadataSync] Failed to add ${algoInfo.name} during retry",
                );
              }
            } catch (retryError, stackTrace) {
              debugPrint(
                "[MetadataSync] Retry failed for ${algoInfo.name}: $retryError",
              );
              debugPrintStack(stackTrace: stackTrace);

              // Clean up if retry fails
              try {
                await _distingManager.requestNewPreset();
                await Future.delayed(const Duration(milliseconds: 500));
              } catch (cleanupError) {
                debugPrint(
                  "[MetadataSync] Cleanup after retry failure: $cleanupError",
                );
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
      debugPrint("[MetadataSync] $errorMsg");
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
  ) async {
    // Queries use slot index 0
    final numParamsResult = await _distingManager.requestNumberOfParameters(0);
    final numParams = numParamsResult?.numParameters ?? 0;
    if (numParams == 0) {
      debugPrint("    - Algo ${algoInfo.guid} instantiated with 0 parameters.");
      return;
    }

    debugPrint(
      "    - Fetching $numParams parameters for slot 0 (${algoInfo.guid})...",
    );

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
          final enumsResult = await _distingManager.requestParameterEnumStrings(
            0,
            pNum,
          );
          if (enumsResult != null && enumsResult.values.isNotEmpty) {
            enumStringsMap[pNum] = enumsResult.values;
          }
        }
      } else {
        debugPrint(
          "    - Warning: Failed to get param info for slot 0, pNum $pNum.",
        );
      }
    }
    debugPrint("    - Fetched info for ${parameterInfos.length} parameters.");

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
    debugPrint(
      "    - Upserted ${paramEntries.length} unique base parameter definitions.",
    );

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
          } else {
            debugPrint(
              "    - Warning: Page '${page.name}' references parameter number $paramNumKey for which no base definition was stored. Skipping page item.",
            );
          }
        }
      });
      // Use replace mode for pages/items within an algorithm, assuming pages are definitive per sync
      await metadataDao.upsertParameterPages(pageEntries);
      await metadataDao.upsertParameterPageItems(pageItemEntries);
      debugPrint(
        "    - Cached ${pageEntries.length} pages and ${pageItemEntries.length} page items.",
      );
    } else {
      debugPrint("    - No parameter pages found or fetched for slot 0.");
    }
  }

  /// Rescan a single algorithm's parameters
  Future<void> rescanSingleAlgorithm(AlgorithmInfo algoInfo) async {
    final dbUnits = await _database.metadataDao.getAllUnits();
    final dbUnitStrings = dbUnits.map((u) => u.unitString).toList();
    final unitIdMap = <String, int>{};
    for (final unit in dbUnits) {
      unitIdMap[unit.unitString] = unit.id;
    }

    // Clear existing parameter data for this algorithm
    await _database.metadataDao.clearAlgorithmMetadata(algoInfo.guid);

    // Load plugin if needed
    if (algoInfo.isPlugin && !algoInfo.isLoaded) {
      await _distingManager.requestLoadPlugin(algoInfo.guid);
      await Future.delayed(const Duration(milliseconds: 1000));
    }

    // Add to preset
    final defaultSpecs = algoInfo.specifications
        .map((s) => s.defaultValue)
        .toList();
    await _distingManager.requestAddAlgorithm(algoInfo, defaultSpecs);

    // Poll until added
    var numInPreset = 0;
    var attempts = 0;
    final maxAttempts = algoInfo.isPlugin ? 15 : 10;

    while (numInPreset != 1 && attempts < maxAttempts) {
      await Future.delayed(const Duration(milliseconds: 500));
      numInPreset = await _distingManager.requestNumAlgorithmsInPreset() ?? -1;
      attempts++;
    }

    if (numInPreset != 1) {
      throw Exception("Failed to add algorithm to preset");
    }

    // For community plugins, reload algorithm info after adding
    final algorithmToQuery = algoInfo.isPlugin
        ? (await _distingManager.requestAlgorithmInfo(
                algoInfo.algorithmIndex,
              ) ??
              algoInfo)
        : algoInfo;

    // Query parameters
    await _syncInstantiatedAlgorithmParams(
      _database.metadataDao,
      algorithmToQuery,
      unitIdMap,
      dbUnitStrings,
    );

    // Remove from preset
    await _distingManager.requestRemoveAlgorithm(0);

    // Poll until removed
    attempts = 0;
    const maxRemoveAttempts = 8;

    while (numInPreset != 0 && attempts < maxRemoveAttempts) {
      await Future.delayed(const Duration(milliseconds: 500));
      numInPreset = await _distingManager.requestNumAlgorithmsInPreset() ?? -1;
      attempts++;
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
    Future<bool> Function(String message)? onContinueRequired,
    bool Function()? isCancelled,
  }) async {
    final metadataDao = _database.metadataDao;

    void reportProgress(
      String mainMessage,
      String subMessage, {
      int processed = 0,
      int total = 0,
    }) {
      final progress = total == 0 ? 0.0 : processed / total;
      onProgress?.call(progress, processed, total, mainMessage, subMessage);
      debugPrint(
        "[MetadataSync] Incremental: $processed/$total - $mainMessage - $subMessage",
      );
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

      debugPrint(
        "[MetadataSync] Found ${newAlgorithms.length} new algorithms to sync:",
      );
      for (final algo in newAlgorithms) {
        debugPrint("  - ${algo.name} (${algo.guid})");
      }

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

          // Load plugin if needed
          if (algoInfo.isPlugin && !algoInfo.isLoaded) {
            reportProgress(
              mainProgressMsg,
              "Loading plugin...",
              processed: i,
              total: orderedNewAlgorithms.length,
            );
            await _distingManager.requestLoadPlugin(algoInfo.guid);
            await Future.delayed(const Duration(milliseconds: 1000));
            if (checkCancel()) break;
          }

          // Add algorithm with default specs to slot 0
          reportProgress(
            mainProgressMsg,
            "Adding to preset...",
            processed: i,
            total: orderedNewAlgorithms.length,
          );
          final defaultSpecs = algoInfo.specifications
              .map((s) => s.defaultValue)
              .toList();
          await _distingManager.requestAddAlgorithm(algoInfo, defaultSpecs);

          // Poll until algorithm is added to preset
          reportProgress(
            mainProgressMsg,
            "Waiting for algorithm to be added...",
            processed: i,
            total: orderedNewAlgorithms.length,
          );
          var numInPreset = 0;
          var attempts = 0;
          final maxAttempts = algoInfo.isPlugin ? 15 : 10;

          while (numInPreset != 1 && attempts < maxAttempts && !checkCancel()) {
            await Future.delayed(const Duration(milliseconds: 500));
            numInPreset =
                await _distingManager.requestNumAlgorithmsInPreset() ?? -1;
            attempts++;
          }

          if (checkCancel()) break;

          if (numInPreset != 1) {
            throw Exception(
              "Failed to add algorithm to preset after $attempts attempts.",
            );
          }

          // Query parameters
          reportProgress(
            mainProgressMsg,
            "Querying parameters...",
            processed: i,
            total: orderedNewAlgorithms.length,
          );

          // For community plugins, reload algorithm info after adding
          final algorithmToQuery = algoInfo.isPlugin
              ? (await _distingManager.requestAlgorithmInfo(
                      algoInfo.algorithmIndex,
                    ) ??
                    algoInfo)
              : algoInfo;

          await _syncInstantiatedAlgorithmParams(
            metadataDao,
            algorithmToQuery,
            unitIdMap,
            dbUnitStrings,
          );

          // Remove algorithm from slot 0
          reportProgress(
            mainProgressMsg,
            "Removing from preset...",
            processed: i,
            total: orderedNewAlgorithms.length,
          );
          await _distingManager.requestRemoveAlgorithm(0);

          // Poll until algorithm is removed
          attempts = 0;
          const maxRemoveAttempts = 8;

          while (numInPreset != 0 &&
              attempts < maxRemoveAttempts &&
              !checkCancel()) {
            await Future.delayed(const Duration(milliseconds: 500));
            numInPreset =
                await _distingManager.requestNumAlgorithmsInPreset() ?? -1;
            attempts++;
          }

          reportProgress(
            mainProgressMsg,
            "Completed.",
            processed: i + 1,
            total: orderedNewAlgorithms.length,
          );
        } catch (error, stackTrace) {
          final errorMsg =
              "Error syncing new algorithm ${algoInfo.name}: $error";
          debugPrint("[MetadataSync] $errorMsg");
          debugPrintStack(stackTrace: stackTrace);

          // Clean up on error
          try {
            await metadataDao.clearAlgorithmMetadata(algoInfo.guid);
            await _distingManager.requestNewPreset();
            await Future.delayed(const Duration(milliseconds: 500));
          } catch (cleanupError) {
            debugPrint("[MetadataSync] Cleanup failed: $cleanupError");
          }

          onError?.call(errorMsg);
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
      debugPrint("[MetadataSync] $errorMsg");
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
        debugPrint("[MetadataSync] No plugin files found in $pluginDirectory");
        onProgress?.call("No plugin files found.");
        return;
      }

      onProgress?.call("Updating algorithm records...");
      debugPrint(
        "[MetadataSync] Found ${guidToFilePathMap.length} plugin files, updating database...",
      );

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
            debugPrint(
              "[MetadataSync] Updated algorithm $guid with file path: $filePath",
            );
          } else {
            debugPrint(
              "[MetadataSync] Algorithm $guid not found in database (plugin-only, not algorithm)",
            );
          }
        } catch (e) {
          debugPrint("[MetadataSync] Error updating algorithm $guid: $e");
          onError?.call("Error updating algorithm $guid: $e");
        }
      }

      final message =
          "Updated $updatedCount algorithm records with plugin file paths.";
      debugPrint("[MetadataSync] $message");
      onProgress?.call(message);
    } catch (e) {
      final errorMsg = "Plugin scan failed: $e";
      debugPrint("[MetadataSync] $errorMsg");
      onError?.call(errorMsg);
    }
  }
}
