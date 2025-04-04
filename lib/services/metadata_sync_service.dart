import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:nt_helper/db/database.dart';
import 'package:nt_helper/db/daos/metadata_dao.dart'; // Import the DAO type
import 'package:nt_helper/domain/disting_midi_manager.dart';
import 'package:nt_helper/domain/disting_nt_sysex.dart';

/// Service to synchronize static algorithm metadata from the device to the local database.
class MetadataSyncService {
  final IDistingMidiManager _distingManager;
  final AppDatabase _database;

  MetadataSyncService(this._distingManager, this._database);

  /// Fetches all static algorithm metadata from the connected device
  /// by temporarily manipulating a preset, and caches it in the database.
  ///
  /// [onProgress] callback reports progress (0.0-1.0) and current message.
  /// [onError] callback reports errors encountered during the process.
  Future<void> syncAllAlgorithmMetadata({
    Function(double progress, String message)? onProgress, // Updated signature
    Function(String error)? onError, // Added onError
  }) async {
    final metadataDao = _database.metadataDao;
    String? originalPresetName;
    int totalAlgorithms = 0;
    int algorithmsProcessed = 0;

    // Updated helper to use the new onProgress signature
    void _reportProgress(String message) {
      final progress =
          totalAlgorithms == 0 ? 0.0 : algorithmsProcessed / totalAlgorithms;
      onProgress?.call(progress, message);
      debugPrint("[MetadataSync] $message");
    }

    try {
      _reportProgress("Starting metadata sync...");

      // Optional: Clear previous metadata for a full refresh
      // Consider adding a flag if you want incremental updates later
      debugPrint("[MetadataSync] Clearing existing metadata...");
      // await metadataDao.clearAllMetadata(); // Be careful! Uncomment if full wipe needed.

      // 1. Sync Unit Strings
      debugPrint("[MetadataSync] Fetching unit strings...");
      final unitStrings = await _distingManager.requestUnitStrings() ?? [];
      final unitIdMap = <String, int>{};
      final unitFutures = <Future<int>>[];

      for (final unitStr in unitStrings) {
        if (unitStr.isNotEmpty) {
          // Collect futures to run upserts potentially in parallel
          unitFutures.add(metadataDao.upsertUnit(unitStr).then((id) {
            unitIdMap[unitStr] = id;
            return id;
          }));
        }
      }
      await Future.wait(unitFutures); // Wait for all unit upserts
      debugPrint("[MetadataSync] Cached ${unitIdMap.length} unit strings.");

      // 2. Get Total Number of Algorithms
      debugPrint("[MetadataSync] Fetching number of algorithms...");
      final numAlgorithms = await _distingManager.requestNumberOfAlgorithms();
      if (numAlgorithms == null || numAlgorithms == 0) {
        debugPrint("[MetadataSync] No algorithms found on device.");
        return;
      }
      totalAlgorithms = numAlgorithms;
      debugPrint("[MetadataSync] Found $numAlgorithms algorithms. Syncing...");

      // 3. Loop Through Each Algorithm
      for (int algoIndex = 0; algoIndex < numAlgorithms; algoIndex++) {
        algorithmsProcessed++;
        _reportProgress(
            "Processing algorithm index $algoIndex/$numAlgorithms...");

        final algoInfo = await _distingManager.requestAlgorithmInfo(algoIndex);
        if (algoInfo == null) {
          debugPrint(
              "[MetadataSync] Failed: Could not get info for algorithm index $algoIndex. Skipping.");
          continue;
        }

        // Sync metadata for this specific algorithm
        await _syncSingleAlgorithmMetadata(metadataDao, algoInfo, unitIdMap);
        debugPrint(
            "[MetadataSync] Synced: ${algoInfo.name} (GUID: ${algoInfo.guid}) index $algoIndex");
      }

      _reportProgress("Metadata synchronization complete.");
    } catch (e, stackTrace) {
      final errorMsg = "Synchronization failed: $e";
      debugPrint("[MetadataSync] $errorMsg");
      debugPrintStack(stackTrace: stackTrace);
      onError?.call(errorMsg); // Report final error
      // Don't rethrow, allow completion with error reported
    }
  }

  // Helper to sync metadata for a single algorithm
  Future<void> _syncSingleAlgorithmMetadata(
    MetadataDao metadataDao,
    AlgorithmInfo algoInfo,
    Map<String, int> unitIdMap, // Map of unit string -> db id
  ) async {
    // 1. Upsert Algorithm
    await metadataDao.upsertAlgorithms([
      AlgorithmEntry(
          guid: algoInfo.guid,
          name: algoInfo.name,
          numSpecifications: algoInfo.numSpecifications)
    ]);

    // 2. Upsert Specifications
    if (algoInfo.specifications.isNotEmpty) {
      final specEntries = algoInfo.specifications.asMap().entries.map((entry) {
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

    // Fetch detailed info needed for caching (Parameters, Pages, Enums)
    // Use algoInfo.algorithmIndex to query device for static info
    final numParamsResult = await _distingManager
        .requestNumberOfParameters(algoInfo.algorithmIndex);
    final numParams = numParamsResult?.numParameters ?? 0;
    if (numParams == 0) {
      debugPrint("    - Algo ${algoInfo.guid} has no parameters.");
      return; // No parameters to cache
    }
    debugPrint("    - Fetching $numParams parameters...");

    final parameterInfos = <ParameterInfo>[];
    final parameterPagesResult =
        await _distingManager.requestParameterPages(algoInfo.algorithmIndex);
    final enumStringsMap =
        <int, List<String>>{}; // parameterNumber -> List<String>

    // Fetch all parameter info and identify enums
    for (int pNum = 0; pNum < numParams; pNum++) {
      final paramInfo = await _distingManager.requestParameterInfo(
          algoInfo.algorithmIndex, pNum);
      if (paramInfo != null) {
        parameterInfos.add(paramInfo);
        // If it's an enum (unit == 1), fetch its strings
        // Note: Check unit == 1 assumes this convention holds.
        if (paramInfo.unit == 1) {
          final enumsResult = await _distingManager.requestParameterEnumStrings(
              algoInfo.algorithmIndex, pNum);
          if (enumsResult != null && enumsResult.values.isNotEmpty) {
            enumStringsMap[pNum] = enumsResult.values;
          } else {
            debugPrint(
                "    - Warning: Failed to get enum strings for Param $pNum, or list was empty.");
          }
        }
      } else {
        debugPrint(
            "    - Warning: Failed to get parameter info for Param $pNum.");
      }
    }
    debugPrint("    - Fetched info for ${parameterInfos.length} parameters.");

    // 3. Upsert Parameters
    final paramEntries = <ParameterEntry>[];
    final dbUnits = await metadataDao
        .getAllUnits(); // Get all units from DB for getUnitString
    final dbUnitStrings = dbUnits.map((u) => u.unitString).toList();

    for (final paramInfo in parameterInfos) {
      final unitStr = paramInfo.getUnitString(dbUnitStrings);
      final unitId = (unitStr == null)
          ? null
          : unitIdMap[unitStr]; // Use the pre-populated map

      paramEntries.add(ParameterEntry(
          algorithmGuid: algoInfo.guid,
          parameterNumber: paramInfo.parameterNumber,
          name: paramInfo.name,
          minValue: paramInfo.min,
          maxValue: paramInfo.max,
          defaultValue: paramInfo.defaultValue,
          unitId: unitId,
          powerOfTen: paramInfo.powerOfTen));
    }
    await metadataDao.upsertParameters(paramEntries);

    // 4. Upsert Parameter Enums
    final enumEntries = <ParameterEnumEntry>[];
    enumStringsMap.forEach((paramNum, strings) {
      strings.asMap().forEach((index, str) {
        enumEntries.add(ParameterEnumEntry(
            algorithmGuid: algoInfo.guid,
            parameterNumber: paramNum,
            enumIndex: index,
            enumString: str));
      });
    });
    if (enumEntries.isNotEmpty) {
      await metadataDao.upsertParameterEnums(enumEntries);
    }

    // 5. Upsert Parameter Pages and Items
    if (parameterPagesResult != null && parameterPagesResult.pages.isNotEmpty) {
      final pageEntries = <ParameterPageEntry>[];
      final pageItemEntries = <ParameterPageItemEntry>[];
      parameterPagesResult.pages.asMap().forEach((index, page) {
        pageEntries.add(ParameterPageEntry(
            algorithmGuid: algoInfo.guid, pageIndex: index, name: page.name));
        for (final paramNum in page.parameters) {
          // Ensure the parameter actually exists before adding item
          if (parameterInfos.any((p) => p.parameterNumber == paramNum)) {
            pageItemEntries.add(ParameterPageItemEntry(
                algorithmGuid: algoInfo.guid,
                pageIndex: index,
                parameterNumber: paramNum));
          } else {
            debugPrint(
                "    - Warning: Page '${page.name}' references non-existent parameter number $paramNum. Skipping page item.");
          }
        }
      });
      await metadataDao.upsertParameterPages(pageEntries);
      await metadataDao.upsertParameterPageItems(pageItemEntries);
      debugPrint(
          "    - Cached ${pageEntries.length} pages and ${pageItemEntries.length} page items.");
    } else {
      debugPrint("    - No parameter pages found or fetched.");
    }
  }
}
