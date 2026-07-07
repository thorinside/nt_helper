import 'package:nt_helper/cubit/disting_cubit.dart';
import 'package:nt_helper/db/daos/presets_dao.dart';
import 'package:nt_helper/db/database.dart';
import 'package:nt_helper/domain/i_disting_midi_manager.dart';
import 'package:nt_helper/ui/metadata_sync/metadata_sync_cubit.dart';
import 'package:nt_helper/ui/template_manager/current_preset_template_source.dart';

/// Persistent "algorithm clipboard" used by the Mod+C / Mod+V slot
/// copy/paste flow.
///
/// The clipboard is backed by a single reserved system template in the
/// database (see [PresetsDao.getClipboardTemplate] and
/// [PresetsDao.saveClipboardTemplate]), so it survives app restarts but is
/// hidden from the Template Manager. Copy snapshots the selected in-memory
/// slots; paste appends the clipboard to the connected device preset via the
/// existing template-injection path.
class AlgorithmClipboardService {
  AlgorithmClipboardService(this._database);

  final AppDatabase _database;

  /// Snapshots the slots at [slotIndices] from the current in-memory Disting
  /// state into the persistent clipboard, replacing any prior clipboard
  /// contents.
  ///
  /// Slots are **always stored in ascending source-slot order**, regardless
  /// of the order of [slotIndices]. This is required for correctness: on the
  /// Disting NT, signals can only flow *down* the algorithm stack (a later
  /// slot's output cannot feed an earlier slot's input). Preserving the
  /// original stack order means that when the clipboard is pasted, the copied
  /// algorithms retain the same relative routing topology (A feeding B is
  /// still A-then-B), rather than being silently reversed.
  ///
  /// Algorithm metadata rows are upserted so the clipboard remains
  /// self-describing even if the source algorithm is later removed from the
  /// local metadata cache.
  ///
  /// Returns the number of slots copied, or `0` when the state is not
  /// synchronized or the selection is empty / out of range.
  Future<int> copyFromDistingState(
    DistingState state,
    List<int> slotIndices,
  ) async {
    if (state is! DistingStateSynchronized) return 0;
    if (slotIndices.isEmpty) return 0;

    final full = fullPresetDetailsFromDistingState(state);
    if (full == null) return 0;

    // Drop out-of-range indices and ALWAYS sort ascending by source slot
    // index. Signals on the Disting NT only flow down the algorithm stack,
    // so the clipboard must preserve the original stack order: copying [2, 0]
    // must store [A(0), C(2)], not [C(2), A(0)], or a paste would reverse
    // A→C into C→A and break the routing topology. The input is a selection
    // set (no deduplication needed).
    final ordered = slotIndices
        .where((i) => i >= 0 && i < full.slots.length)
        .toSet()
        .toList()
      ..sort();
    if (ordered.isEmpty) return 0;

    // Ensure algorithm metadata rows exist locally so the clipboard can be
    // re-applied even after a metadata rescan.
    final missingAlgorithms = <String, AlgorithmEntry>{};
    for (final i in ordered) {
      final algorithm = full.slots[i].algorithm;
      final existing = await _database.metadataDao.getAlgorithmByGuid(
        algorithm.guid,
      );
      if (existing == null) {
        missingAlgorithms[algorithm.guid] = algorithm;
      }
    }
    if (missingAlgorithms.isNotEmpty) {
      await _database.metadataDao.upsertAlgorithms(
        missingAlgorithms.values.toList(growable: false),
      );
    }

    final clipboardDetails = _buildClipboardDetails(full, ordered);
    await _database.presetsDao.saveClipboardTemplate(clipboardDetails);
    return ordered.length;
  }

  /// Number of slots currently held in the clipboard.
  Future<int> clipboardSlotCount() =>
      _database.presetsDao.clipboardSlotCount();

  /// Appends the current clipboard contents to the connected device preset by
  /// delegating to [MetadataSyncCubit.applyTemplateToDevice].
  ///
  /// Throws a [StateError] when the clipboard is empty. Re-throws any error
  /// surfaced by the apply path so callers can present it to the user.
  Future<void> pasteToCurrentDevice(
    MetadataSyncCubit metadataSyncCubit,
    IDistingMidiManager manager,
  ) async {
    final clipboard = await _database.presetsDao.getClipboardTemplate();
    if (clipboard == null || clipboard.slots.isEmpty) {
      throw StateError('Algorithm clipboard is empty.');
    }
    final indices = List<int>.generate(clipboard.slots.length, (i) => i);
    await metadataSyncCubit.applyTemplateToDevice(
      template: clipboard,
      templateSlotIndices: indices,
      manager: manager,
    );
  }

  FullPresetDetails _buildClipboardDetails(
    FullPresetDetails source,
    List<int> orderedIndices,
  ) {
    final slots = <FullPresetSlot>[];
    for (var output = 0; output < orderedIndices.length; output++) {
      slots.add(source.slots[orderedIndices[output]]);
    }
    return FullPresetDetails(
      preset: source.preset,
      slots: slots,
    );
  }
}

/// Human-readable helper used by UI to describe a clipboard state in
/// announcements/snackbars. Kept here so error strings stay consistent.
String describeClipboardCount(int count) {
  return '$count ${count == 1 ? 'algorithm' : 'algorithms'}';
}

/// Generic message string used for the empty-clipboard snackbar.
const String algorithmClipboardEmptyMessage =
    'Algorithm clipboard is empty. Shift-click slot tabs and press Mod+C to copy.';
