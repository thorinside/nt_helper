import 'package:drift/drift.dart';
import 'package:nt_helper/db/database.dart';
import 'package:nt_helper/db/tables.dart';

part 'sd_cards_dao.g.dart';

// Data class to hold SdCardEntry and its preset count
class SdCardWithPresetCount {
  final SdCardEntry sdCard;
  final int presetCount;

  SdCardWithPresetCount({required this.sdCard, required this.presetCount});
}

@DriftAccessor(tables: [SdCards, IndexedPresetFiles])
class SdCardsDao extends DatabaseAccessor<AppDatabase> with _$SdCardsDaoMixin {
  SdCardsDao(super.db);

  Future<List<SdCardEntry>> getAllSdCards() => select(sdCards).get();

  Future<List<SdCardWithPresetCount>> getAllSdCardsWithPresetCounts() async {
    // Expression for counting presets
    final presetCountExp = db.indexedPresetFiles.id.count();

    final query = select(sdCards).join([
      leftOuterJoin(db.indexedPresetFiles,
          db.indexedPresetFiles.sdCardId.equalsExp(sdCards.id))
    ])
      ..groupBy([sdCards.id])
      ..addColumns(
          [presetCountExp]); // Add the count expression to the select list

    final result = await query.map((row) {
      return SdCardWithPresetCount(
        sdCard: row.readTable(sdCards),
        presetCount: row.read(presetCountExp) ??
            0, // Default to 0 if count is null (e.g., no presets)
      );
    }).get();

    return result;
  }

  Future<SdCardEntry?> getSdCardById(int id) =>
      (select(sdCards)..where((tbl) => tbl.id.equals(id))).getSingleOrNull();

  Future<SdCardEntry?> getSdCardByUserLabel(String label) =>
      (select(sdCards)..where((tbl) => tbl.userLabel.equals(label)))
          .getSingleOrNull();

  Future<SdCardEntry?> getSdCardBySystemIdentifier(String identifier) =>
      (select(sdCards)..where((tbl) => tbl.systemIdentifier.equals(identifier)))
          .getSingleOrNull();

  Future<int> insertSdCard(SdCardsCompanion sdCard) =>
      into(sdCards).insert(sdCard);

  Future<bool> updateSdCard(SdCardsCompanion sdCard) =>
      update(sdCards).replace(sdCard);

  Future<int> deleteSdCard(int id) =>
      (delete(sdCards)..where((tbl) => tbl.id.equals(id))).go();
}
