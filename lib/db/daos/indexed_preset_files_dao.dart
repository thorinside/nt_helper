import 'package:drift/drift.dart';
import 'package:nt_helper/db/database.dart';
import 'package:nt_helper/db/tables.dart';

part 'indexed_preset_files_dao.g.dart';

@DriftAccessor(tables: [IndexedPresetFiles])
class IndexedPresetFilesDao extends DatabaseAccessor<AppDatabase>
    with _$IndexedPresetFilesDaoMixin {
  IndexedPresetFilesDao(AppDatabase db) : super(db);

  Future<List<IndexedPresetFileEntry>> getAllIndexedPresetFiles() =>
      select(indexedPresetFiles).get();

  Future<List<IndexedPresetFileEntry>> getIndexedPresetFilesBySdCardId(
          int sdCardId) =>
      (select(indexedPresetFiles)
            ..where((tbl) => tbl.sdCardId.equals(sdCardId)))
          .get();

  Future<IndexedPresetFileEntry?> getIndexedPresetFileById(int id) =>
      (select(indexedPresetFiles)..where((tbl) => tbl.id.equals(id)))
          .getSingleOrNull();

  Future<int> insertIndexedPresetFile(IndexedPresetFilesCompanion presetFile) =>
      into(indexedPresetFiles).insert(presetFile);

  Future<bool> updateIndexedPresetFile(
          IndexedPresetFilesCompanion presetFile) =>
      update(indexedPresetFiles).replace(presetFile);

  Future<int> deleteIndexedPresetFile(int id) =>
      (delete(indexedPresetFiles)..where((tbl) => tbl.id.equals(id))).go();

  /// Deletes all indexed preset files associated with a given sdCardId.
  Future<int> deletePresetsForSdCard(int sdCardId) =>
      (delete(indexedPresetFiles)
            ..where((tbl) => tbl.sdCardId.equals(sdCardId)))
          .go();

  Future<IndexedPresetFileEntry?>
      getIndexedPresetFilesBySdCardIdAndRelativePath(
    int sdCardId,
    String relativePath,
  ) {
    return (select(indexedPresetFiles)
          ..where((tbl) => tbl.sdCardId.equals(sdCardId))
          ..where((tbl) => tbl.relativePath.equals(relativePath)))
        .getSingleOrNull();
  }

  // Example of a more complex query: Find presets by algorithm name
  Future<List<IndexedPresetFileEntry>> findPresetsByAlgorithmName(
      String algorithmName) {
    return (select(indexedPresetFiles)
          ..where(
              (tbl) => tbl.algorithmNameFromPreset.like('%$algorithmName%')))
        .get();
  }

  // Example: Find presets by a keyword in notes
  Future<List<IndexedPresetFileEntry>> findPresetsByNotesKeyword(
      String keyword) {
    return (select(indexedPresetFiles)
          ..where((tbl) => tbl.notesFromPreset.like('%$keyword%')))
        .get();
  }
}
