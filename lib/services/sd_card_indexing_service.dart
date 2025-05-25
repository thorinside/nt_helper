import 'package:drift/drift.dart'; // Added for Value and absent
import 'package:nt_helper/db/daos/indexed_preset_files_dao.dart';
import 'package:nt_helper/db/daos/sd_cards_dao.dart';
import 'package:nt_helper/db/database.dart';
import 'package:nt_helper/models/parsed_preset_data.dart'; // Assuming this model exists

class SdCardIndexingService {
  final SdCardsDao _sdCardsDao;
  final IndexedPresetFilesDao _indexedPresetFilesDao;

  SdCardIndexingService(AppDatabase db)
      : _sdCardsDao = db.sdCardsDao,
        _indexedPresetFilesDao = db.indexedPresetFilesDao;

  Future<void> indexPresets({
    required String sdCardUserLabel, // User-defined label for the SD card
    String? sdCardSystemIdentifier, // Optional system identifier
    required List<ParsedPresetData> parsedPresets,
  }) async {
    // 1. Get or create SdCardEntry
    SdCardEntry? sdCard =
        await _sdCardsDao.getSdCardByUserLabel(sdCardUserLabel);
    int sdCardId;

    if (sdCard == null) {
      final newSdCardCompanion = SdCardsCompanion.insert(
        userLabel: sdCardUserLabel,
        systemIdentifier: sdCardSystemIdentifier != null
            ? Value(sdCardSystemIdentifier)
            : const Value.absent(),
      );
      sdCardId = await _sdCardsDao.insertSdCard(newSdCardCompanion);
    } else {
      // Optionally update system identifier if it's newly provided or changed
      if (sdCardSystemIdentifier != null &&
          sdCard.systemIdentifier != sdCardSystemIdentifier) {
        await _sdCardsDao.updateSdCard(sdCard
            .toCompanion(false)
            .copyWith(systemIdentifier: Value(sdCardSystemIdentifier)));
      }
      sdCardId = sdCard.id;
    }

    // 2. Process each parsed preset
    for (final presetData in parsedPresets) {
      final existingFile = await _indexedPresetFilesDao
          .getIndexedPresetFilesBySdCardIdAndRelativePath(
              sdCardId, presetData.relativePath);

      final now = DateTime.now().toUtc();

      if (existingFile == null) {
        // Insert new entry
        final newPresetFile = IndexedPresetFilesCompanion.insert(
          sdCardId: sdCardId,
          relativePath: presetData.relativePath,
          fileName: presetData.fileName,
          absolutePathAtScanTime: presetData.absolutePathAtScanTime,
          algorithmNameFromPreset: Value(presetData.algorithmName),
          notesFromPreset: Value(presetData.notes),
          otherExtractedMetadataJson: Value(presetData.otherMetadataJson),
          lastSeenUtc: now,
        );
        await _indexedPresetFilesDao.insertIndexedPresetFile(newPresetFile);
      } else {
        // Update existing entry
        final updatedPresetFile = existingFile.toCompanion(false).copyWith(
              fileName: Value(presetData
                  .fileName), // In case filename changed (though relativePath is key)
              absolutePathAtScanTime: Value(presetData.absolutePathAtScanTime),
              algorithmNameFromPreset: Value(presetData.algorithmName),
              notesFromPreset: Value(presetData.notes),
              otherExtractedMetadataJson: Value(presetData.otherMetadataJson),
              lastSeenUtc: Value(now),
            );
        await _indexedPresetFilesDao.updateIndexedPresetFile(updatedPresetFile);
      }
    }
    // TODO: Consider adding logic to remove presets not found in the current scan (pruning)
  }
}
