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

  // Corrected regex (removed extra ^)
  final RegExp _parameterPrefixRegex = RegExp(r"^([0-9]+|A|B|C|D):\s*");

  // Helper to determine if an algorithm is a factory algorithm (lowercase GUID) 
  // vs community plugin (any uppercase letters in GUID)
  bool _isFactoryAlgorithm(String guid) {
    return guid == guid.toLowerCase();
  }

  /// Fetches all static algorithm metadata from the connected device
  /// by temporarily manipulating a preset, and caches it in the database.
  ///
  /// [onProgress] callback reports progress (0.0-1.0), counts, and messages.
  /// [onError] callback reports errors encountered during the process.
  /// [onContinueRequired] callback prompts user to continue after reboot (returns Future&lt;bool&gt;).
  /// [isCancelled] callback allows checking if cancellation has been requested.
  Future<void> syncAllAlgorithmMetadata({
    Function(double progress, int processed, int total, String mainMessage,
            String subMessage)?
        onProgress,
    Function(String error)? onError,
    Future<bool> Function(String message)? onContinueRequired,
    bool Function()? isCancelled,
  }) async {
    final metadataDao = _database.metadataDao;
    int totalAlgorithms = 0;
    int algorithmsProcessed = 0;

    void reportProgress(String mainMessage, String subMessage,
        {bool incrementCount = false}) {
      if (incrementCount) {
        algorithmsProcessed++;
      }
      final progress =
          totalAlgorithms == 0 ? 0.0 : algorithmsProcessed / totalAlgorithms;
      onProgress?.call(progress, algorithmsProcessed, totalAlgorithms,
          mainMessage, subMessage);
      debugPrint(
          "[MetadataSync] Progress: $algorithmsProcessed/$totalAlgorithms - $mainMessage - $subMessage");
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

      // Clear device preset and DB cache
      reportProgress(
          "Initializing Sync", "Clearing device preset and local cache...");
      await metadataDao.clearAllMetadata(); // Clear DB first
      await _distingManager.requestNewPreset(); // Clear on device
      await Future.delayed(
          const Duration(milliseconds: 500)); // Allow device time
      if (checkCancel()) return;

      // Verify preset is empty
      var numInPreset =
          await _distingManager.requestNumAlgorithmsInPreset() ?? -1;
      if (numInPreset != 0) {
        throw Exception(
            "Failed to clear device preset (expected 0 algorithms, found $numInPreset).");
      }

      // 1. Sync Unit Strings
      reportProgress(
          "Fetching Prerequisite Data", "Requesting unit strings...");
      final unitStrings = await _distingManager.requestUnitStrings() ?? [];
      final unitIdMap = <String, int>{};
      final unitFutures = <Future<void>>[];
      for (final unitStr in unitStrings) {
        if (unitStr.isNotEmpty) {
          unitFutures.add(metadataDao.upsertUnit(unitStr).then((id) {
            unitIdMap[unitStr] = id;
          }));
        }
      }
      await Future.wait(unitFutures);
      reportProgress("Fetching Prerequisite Data",
          "Cached ${unitIdMap.length} unit strings.");
      if (checkCancel()) return;

      // --- NEW: Save the ordered list to the cache ---
      try {
        await metadataDao.saveOrderedUnitStrings(unitStrings);
        debugPrint("[MetadataSync] Saved ordered unit strings to cache.");
      } catch (e) {
        debugPrint(
            "[MetadataSync] Warning: Failed to save ordered unit strings to cache: $e");
        // Decide if this is a fatal error - maybe not, if reconstruction can fall back?
        // For now, we just log a warning.
      }
      // --- END NEW ---

      // 2. Get All Algorithm Basic Info
      reportProgress(
          "Fetching Algorithm List", "Requesting number of algorithms...");
      final numAlgoTypes = await _distingManager.requestNumberOfAlgorithms();
      if (numAlgoTypes == null || numAlgoTypes == 0) {
        reportProgress(
            "Fetching Algorithm List", "No algorithm types found on device.");
        throw Exception("No algorithm types found on device.");
      }
      totalAlgorithms = numAlgoTypes;
      reportProgress("Fetching Algorithm List ($totalAlgorithms total)",
          "Requesting basic info...");

      final allAlgorithmInfo = <AlgorithmInfo>[];
      final algoEntries = <AlgorithmEntry>[];
      final specEntries = <SpecificationEntry>[];

      for (int globalAlgoIndex = 0;
          globalAlgoIndex < totalAlgorithms;
          globalAlgoIndex++) {
        if (checkCancel()) break;
        final algoInfo =
            await _distingManager.requestAlgorithmInfo(globalAlgoIndex);
        if (algoInfo != null) {
          allAlgorithmInfo.add(algoInfo);
          algoEntries.add(AlgorithmEntry(
              guid: algoInfo.guid,
              name: algoInfo.name,
              numSpecifications: algoInfo.numSpecifications));

          if (algoInfo.specifications.isNotEmpty) {
            specEntries
                .addAll(algoInfo.specifications.asMap().entries.map((entry) {
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
            }));
          }
        } else {
          debugPrint(
              "[MetadataSync] Warning: Could not fetch info for global algo index $globalAlgoIndex");
        }
        final fetchProgressMsg =
            "Fetched basic info ${globalAlgoIndex + 1}/$totalAlgorithms";
        reportProgress("Fetching Algorithm List ($totalAlgorithms total)",
            fetchProgressMsg);
      }
      if (checkCancel()) return;

      // Upsert basic info *before* instantiation loop
      await metadataDao.upsertAlgorithms(algoEntries);
      await metadataDao.upsertSpecifications(specEntries);
      reportProgress("Fetching Algorithm List ($totalAlgorithms total)",
          "Cached basic info for ${allAlgorithmInfo.length} algorithms.");
      if (checkCancel()) return;

      // Reset processed count before starting instantiation phase
      algorithmsProcessed = 0;

      // 3. Separate and Prioritize Algorithms
      reportProgress(
          "Processing Algorithms", "Separating factory vs community algorithms...");
      final factoryAlgorithms = <AlgorithmInfo>[];
      final communityAlgorithms = <AlgorithmInfo>[];
      
      for (final algoInfo in allAlgorithmInfo) {
        if (_isFactoryAlgorithm(algoInfo.guid)) {
          factoryAlgorithms.add(algoInfo);
        } else {
          communityAlgorithms.add(algoInfo);
        }
      }
      
      debugPrint("[MetadataSync] Found ${factoryAlgorithms.length} factory algorithms and ${communityAlgorithms.length} community plugins.");
      reportProgress("Processing Algorithms", 
          "Found ${factoryAlgorithms.length} factory, ${communityAlgorithms.length} community");

      final dbUnits = await metadataDao.getAllUnits();
      final dbUnitStrings = dbUnits.map((u) => u.unitString).toList();

      // 4. Process Factory Algorithms First
      reportProgress("Processing Factory Algorithms", "Starting factory algorithm processing...");
      for (final algoInfo in factoryAlgorithms) {
        if (checkCancel()) break;

        // Main message stays consistent for the duration of this algo's processing
        final mainProgressMsg =
            "Processing ${algoInfo.name} (${algorithmsProcessed + 1}/$totalAlgorithms)";

        // Report start, INCREMENTING the count
        reportProgress(mainProgressMsg, "Starting...", incrementCount: true);

        try {
          // A. Add algorithm with default specs to slot 0
          reportProgress(mainProgressMsg, "Adding to preset...");
          if (checkCancel()) break;
          final defaultSpecs =
              algoInfo.specifications.map((s) => s.defaultValue).toList();
          await _distingManager.requestAddAlgorithm(algoInfo, defaultSpecs);
          await Future.delayed(
              const Duration(milliseconds: 600)); // Increased delay
          if (checkCancel()) break;

          // Verify it was added (should be 1 algorithm in preset)
          numInPreset =
              await _distingManager.requestNumAlgorithmsInPreset() ?? -1;
          if (numInPreset != 1) {
            throw Exception(
                "Failed to add algorithm to preset (expected 1, found $numInPreset).");
          }

          // B. Query the instantiated algorithm at slot index 0
          reportProgress(mainProgressMsg, "Querying parameters...");
          if (checkCancel()) break;
          await _syncInstantiatedAlgorithmParams(
              metadataDao, algoInfo, unitIdMap, dbUnitStrings);

          // C. Remove algorithm from slot 0
          reportProgress(mainProgressMsg, "Removing from preset...");
          if (checkCancel()) break;
          await _distingManager.requestRemoveAlgorithm(0);
          await Future.delayed(
              const Duration(milliseconds: 400)); // Increased delay
          if (checkCancel()) break;

          // Verify it was removed (should be 0 algorithms in preset)
          numInPreset =
              await _distingManager.requestNumAlgorithmsInPreset() ?? -1;
          if (numInPreset != 0) {
            // Don't throw, just warn, as we want to continue syncing others
            debugPrint(
                "[MetadataSync] Warning: Failed to remove ${algoInfo.name} cleanly (expected 0, found $numInPreset).");
          }

          reportProgress(mainProgressMsg, "Done."); // Simplified final report
        } catch (instantiationError, stackTrace) {
          // Report the main error first
          final errorMsg =
              "Error processing ${algoInfo.name}: $instantiationError";
          debugPrint("[MetadataSync] $errorMsg");
          debugPrintStack(stackTrace: stackTrace);
          onError?.call(errorMsg);

          // Attempt DB cleanup
          reportProgress(mainProgressMsg, "Attempting DB cleanup...");
          try {
            await metadataDao.clearAlgorithmMetadata(algoInfo.guid);
            // ALSO delete the base algorithm and specification entries
            await (metadataDao.delete(metadataDao.specifications)
                  ..where((s) => s.algorithmGuid.equals(algoInfo.guid)))
                .go();
            await (metadataDao.delete(metadataDao.algorithms)
                  ..where((a) => a.guid.equals(algoInfo.guid)))
                .go();
            reportProgress(
                mainProgressMsg, "DB cleared for failed ${algoInfo.name}.");
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
            reportProgress(mainProgressMsg,
                "Device preset clear failed: $presetClearError");
          }
          // No final "Done" report here, as it failed.
        }
      }

      // 5. Process Community Plugins with Special Loading Strategy
      if (communityAlgorithms.isNotEmpty && !checkCancel()) {
        reportProgress("Processing Community Plugins", 
            "Starting community plugin processing with on-demand loading...");
        
        for (final algoInfo in communityAlgorithms) {
          if (checkCancel()) break;

          final mainProgressMsg =
              "Processing ${algoInfo.name} (${algorithmsProcessed + 1}/$totalAlgorithms)";
          
          reportProgress(mainProgressMsg, "Starting community plugin...", incrementCount: true);

          bool communityPluginSuccess = false;
          int attempts = 0;
          const maxAttempts = 2;

          while (!communityPluginSuccess && attempts < maxAttempts && !checkCancel()) {
            attempts++;
            try {
              // Step 1: Add plugin to empty preset to trigger loading
              reportProgress(mainProgressMsg, 
                  "Adding to preset (attempt $attempts/$maxAttempts)...");
              final defaultSpecs =
                  algoInfo.specifications.map((s) => s.defaultValue).toList();
              await _distingManager.requestAddAlgorithm(algoInfo, defaultSpecs);
              await Future.delayed(const Duration(milliseconds: 1000)); // Longer delay for plugin loading
              
              if (checkCancel()) break;

              // Verify it was added
              var numInPreset = await _distingManager.requestNumAlgorithmsInPreset() ?? -1;
              if (numInPreset != 1) {
                throw Exception("Failed to add community plugin to preset (expected 1, found $numInPreset).");
              }

              // Step 2: Reload algorithm info now that plugin is loaded
              reportProgress(mainProgressMsg, "Reloading algorithm info...");
              final reloadedAlgoInfo = await _distingManager.requestAlgorithmInfo(algoInfo.algorithmIndex);
              if (reloadedAlgoInfo == null) {
                throw Exception("Failed to reload algorithm info after adding to preset.");
              }

              // Step 3: Query the instantiated algorithm parameters
              reportProgress(mainProgressMsg, "Querying parameters...");
              await _syncInstantiatedAlgorithmParams(
                  metadataDao, reloadedAlgoInfo, unitIdMap, dbUnitStrings);

              // Step 4: Remove algorithm from preset
              reportProgress(mainProgressMsg, "Removing from preset...");
              await _distingManager.requestRemoveAlgorithm(0);
              await Future.delayed(const Duration(milliseconds: 600));
              
              if (checkCancel()) break;

              // Verify removal
              numInPreset = await _distingManager.requestNumAlgorithmsInPreset() ?? -1;
              if (numInPreset != 0) {
                debugPrint("[MetadataSync] Warning: Failed to remove ${algoInfo.name} cleanly (expected 0, found $numInPreset).");
              }

              reportProgress(mainProgressMsg, "Done.");
              communityPluginSuccess = true;

            } catch (e, stackTrace) {
              debugPrint("[MetadataSync] Community plugin processing failed (attempt $attempts): $e");
              debugPrintStack(stackTrace: stackTrace);
              
              if (attempts >= maxAttempts) {
                // Final attempt failed - prompt for reboot
                reportProgress(mainProgressMsg, "Failed - requesting device reboot...");
                
                if (onContinueRequired != null) {
                  final shouldContinue = await onContinueRequired(
                      "Community plugin ${algoInfo.name} failed to load. Please reboot your NT device and wait for the file scan to complete, then press Continue.");
                  
                  if (!shouldContinue || checkCancel()) {
                    reportProgress(mainProgressMsg, "Sync cancelled by user.");
                    return;
                  }
                  
                  reportProgress(mainProgressMsg, "Continuing after reboot...");
                  // Clear any potential state issues
                  try {
                    await _distingManager.requestNewPreset();
                    await Future.delayed(const Duration(milliseconds: 500));
                  } catch (cleanupError) {
                    debugPrint("[MetadataSync] Cleanup after reboot failed: $cleanupError");
                  }
                } else {
                  // Fallback to old behavior if no continue callback provided
                  onError?.call("Community plugin ${algoInfo.name} failed to load. Please reboot your NT device.");
                }
              } else {
                // Not final attempt - clean up and retry
                reportProgress(mainProgressMsg, "Retrying after cleanup...");
                try {
                  await _distingManager.requestNewPreset();
                  await Future.delayed(const Duration(milliseconds: 800));
                } catch (cleanupError) {
                  debugPrint("[MetadataSync] Cleanup before retry failed: $cleanupError");
                }
              }
            }
          }

          if (!communityPluginSuccess && !checkCancel()) {
            // Mark as failed in database
            reportProgress(mainProgressMsg, "Marking as failed in database...");
            try {
              await metadataDao.clearAlgorithmMetadata(algoInfo.guid);
              await (metadataDao.delete(metadataDao.specifications)
                    ..where((s) => s.algorithmGuid.equals(algoInfo.guid)))
                  .go();
              await (metadataDao.delete(metadataDao.algorithms)
                    ..where((a) => a.guid.equals(algoInfo.guid)))
                  .go();
            } catch (dbClearError) {
              debugPrint("[MetadataSync] Failed to clear database for failed community plugin: $dbClearError");
            }
          }
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
      List<String> dbUnitStrings // List of known unit strings
      ) async {
    // Queries use slot index 0
    final numParamsResult = await _distingManager.requestNumberOfParameters(0);
    final numParams = numParamsResult?.numParameters ?? 0;
    if (numParams == 0) {
      debugPrint("    - Algo ${algoInfo.guid} instantiated with 0 parameters.");
      return;
    }

    debugPrint(
        "    - Fetching $numParams parameters for slot 0 (${algoInfo.guid})...");

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
          final enumsResult =
              await _distingManager.requestParameterEnumStrings(0, pNum);
          if (enumsResult != null && enumsResult.values.isNotEmpty) {
            enumStringsMap[pNum] = enumsResult.values;
          }
        }
      } else {
        debugPrint(
            "    - Warning: Failed to get param info for slot 0, pNum $pNum.");
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

      // Parse base name (simple prefix removal for now)
      String baseName = paramInfo.name;
      final match = _parameterPrefixRegex.firstMatch(paramInfo.name);
      if (match != null) {
        baseName = paramInfo.name.substring(match.end);
      }

      final unitStr = paramInfo.getUnitString(dbUnitStrings);
      final unitId = (unitStr == null) ? null : unitIdMap[unitStr];

      paramEntries.add(ParameterEntry(
          algorithmGuid: algoInfo.guid,
          parameterNumber: paramNumKey,
          name: baseName,
          minValue: paramInfo.min,
          maxValue: paramInfo.max,
          defaultValue: paramInfo.defaultValue,
          unitId: unitId,
          powerOfTen: paramInfo.powerOfTen,
          rawUnitIndex: paramInfo.unit));
    }
    // Use insertOrIgnore mode via metadataDao.batch
    await metadataDao.batch((batch) {
      batch.insertAll(metadataDao.parameters, paramEntries,
          mode: InsertMode.insertOrIgnore);
    });
    debugPrint(
        "    - Upserted ${paramEntries.length} unique base parameter definitions.");

    // Upsert Parameter Enums (link to the parameterNumber key)
    final enumEntries = <ParameterEnumEntry>[];
    enumStringsMap.forEach((paramNumKey, strings) {
      // Only add enums if we actually stored this base parameterNumber
      if (uniqueBaseParams.contains(paramNumKey)) {
        strings.asMap().forEach((index, str) {
          enumEntries.add(ParameterEnumEntry(
              algorithmGuid: algoInfo.guid,
              parameterNumber: paramNumKey,
              enumIndex: index,
              enumString: str));
        });
      }
    });
    if (enumEntries.isNotEmpty) {
      // Use insertOrReplace via metadataDao.batch
      await metadataDao.batch((batch) {
        batch.insertAll(metadataDao.parameterEnums, enumEntries,
            mode: InsertMode.insertOrReplace);
      });
    }

    // Upsert Parameter Pages and Items (link to the parameterNumber key)
    if (parameterPagesResult != null && parameterPagesResult.pages.isNotEmpty) {
      final pageEntries = <ParameterPageEntry>[];
      final pageItemEntries = <ParameterPageItemEntry>[];
      final Set<int> storedParamNumbers =
          paramEntries.map((p) => p.parameterNumber).toSet();

      parameterPagesResult.pages.asMap().forEach((index, page) {
        pageEntries.add(ParameterPageEntry(
            algorithmGuid: algoInfo.guid, pageIndex: index, name: page.name));
        for (final paramNumKey in page.parameters) {
          // Only add page items for parameters we actually stored a definition for
          if (storedParamNumbers.contains(paramNumKey)) {
            pageItemEntries.add(ParameterPageItemEntry(
                algorithmGuid: algoInfo.guid,
                pageIndex: index,
                parameterNumber: paramNumKey));
          } else {
            debugPrint(
                "    - Warning: Page '${page.name}' references parameter number $paramNumKey for which no base definition was stored. Skipping page item.");
          }
        }
      });
      // Use replace mode for pages/items within an algorithm, assuming pages are definitive per sync
      await metadataDao.upsertParameterPages(pageEntries);
      await metadataDao.upsertParameterPageItems(pageItemEntries);
      debugPrint(
          "    - Cached ${pageEntries.length} pages and ${pageItemEntries.length} page items.");
    } else {
      debugPrint("    - No parameter pages found or fetched for slot 0.");
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
          fileSystem, pluginDirectory);

      if (guidToFilePathMap.isEmpty) {
        debugPrint("[MetadataSync] No plugin files found in $pluginDirectory");
        onProgress?.call("No plugin files found.");
        return;
      }

      onProgress?.call("Updating algorithm records...");
      debugPrint(
          "[MetadataSync] Found ${guidToFilePathMap.length} plugin files, updating database...");

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
                "[MetadataSync] Updated algorithm $guid with file path: $filePath");
          } else {
            debugPrint(
                "[MetadataSync] Algorithm $guid not found in database (plugin-only, not algorithm)");
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
