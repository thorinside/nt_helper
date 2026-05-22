# Multi-Algorithm Template System

## Context

Today's "template" feature is binary: every preset marked `isTemplate = true` (`lib/db/tables.dart:136`) is treated as an indivisible kit. Users can either:

- **Load** the whole template into the device (replaces preset state via `loadPresetToDevice` / `loadPresetOffline`), or
- **Inject** the whole template into the device, appending every slot of the template after the current slots (`MetadataSyncCubit.injectTemplateToDevice`, `lib/ui/metadata_sync/metadata_sync_cubit.dart:689`).

Both flows are all-or-nothing. A user with a 10-slot template containing a delay, a chorus, and a reverb cannot ask for "just the delay and reverb." They cannot organize their library beyond the alphabetical order of preset names. They cannot annotate a template with its purpose or author.

The goal of this spec is to make templates **partially applicable** (pick which slots), **organizable** (category + structured metadata), and **scriptable** (an MCP tool that mirrors `injectTemplateToDevice` but accepts a slot selection). The full-template injection path (`injectTemplateToDevice`) stays as a no-arg degenerate case.

All work happens against the schema described in `lib/db/database.dart` (schema version 11 today, targeting 12) and the DAO surface in `lib/db/daos/presets_dao.dart`.

---

## Approach

### 1. Database — schema v12

**File:** `lib/db/tables.dart` (table definition) + `lib/db/database.dart` (migration step)

Add two columns to `Presets`:

```dart
@DataClassName('PresetEntry')
class Presets extends Table {
  IntColumn  get id            => integer().autoIncrement()();
  TextColumn get name          => text()();
  DateTimeColumn get lastModified => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get isTemplate    => boolean().withDefault(const Constant(false))();
  TextColumn get category      => text().nullable()();             // NEW
  TextColumn get templateMetadata => text().nullable()();          // NEW — JSON text
}
```

- `category` is a free-form short string ("Drums", "Voice", "Generative", …). Nullable. Empty string normalized to null on write. SQLite has no enum so we keep it free-form; the UI suggests existing categories via autocomplete.
- `templateMetadata` is JSON serialized as text (SQLite has no `jsonb`). Schema:
  ```json
  {
    "description": "string?",
    "tags": ["string"],
    "author": "string?",
    "createdAt": "ISO-8601 string?",   // distinct from lastModified; survives renames
    "schemaVersion": 1                  // internal — for forward evolution
  }
  ```
  Unknown top-level keys are preserved on read by stashing them on the `TemplateMetadata.extras` field; on write, `extras` are merged back into the JSON object. Reads behave as follows:
  - **`null` or empty string** → `TemplateMetadata.empty()` (no log).
  - **Valid JSON but missing keys** → known keys default to null/empty list; unknown keys go to `extras`.
  - **Malformed JSON** → return `TemplateMetadata.empty()` (no `extras` recovery — the bytes are lost). Emit a single `debugPrint` per offending preset id per process (debounced via a small in-memory set on the converter).
  All values are UTF-8; the database column is `TEXT` which Drift treats as UTF-8 by default. Strings round-trip including null bytes and high-codepoint characters.

Both columns are **only meaningful when `isTemplate = true`**. We do not enforce that constraint at the DB level (it would complicate the upgrade); the UI surfaces them in the Template Manager only.

#### Migration step (database.dart `onUpgrade`)

```dart
if (from <= 11) {
  try { await m.addColumn(presets, presets.category); } catch (_) {}
  try { await m.addColumn(presets, presets.templateMetadata); } catch (_) {}
}
```

Both columns are nullable with no default, so existing rows remain untouched. Bump `schemaVersion` to `12`. The `try/catch (_)` pattern matches the prevailing style for resilience against partial upgrades.

Add a Drift schema test mirroring `test/db/io_flags_migration_test.dart` that:

- Asserts `schemaVersion == 12`.
- Verifies a fresh DB has both columns and they accept `null`.
- Verifies a v11 → v12 in-place upgrade preserves existing template rows and adds the columns. (Use Drift's `m.runMigrationSteps` with a manually-constructed v11 schema or the existing schema snapshot tooling if present; if not, the freshly created v12 schema is sufficient and we note the limitation.)

### 2. DAO — `applyTemplateSlots`

**File:** `lib/db/daos/presets_dao.dart`

Add the partial-application method. The DAO-side name keeps the "Slots" suffix (it operates on slot rows); cubit-side names use "ToPreset" / "ToDevice" (they describe outcomes). The two layers are intentionally named differently to make the layering obvious in code search.

```dart
Future<ApplyTemplateSlotsResult> applyTemplateSlots({
  required int templateId,
  required int targetPresetId,
  required List<int> templateSlotIndices,   // 0-based positions WITHIN the template
  required int insertionOffset,             // target slot index where the first copied slot lands
  bool overwrite = false,                   // false = insert and shift; true = replace at offset
});
```

Return value:

```dart
class ApplyTemplateSlotsResult {
  final int targetPresetId;
  final List<int> insertedSlotIndices;          // new slotIndex values in the target preset
  final List<int> skippedTemplateSlotIndices;   // requested but not applied (e.g., missing algorithm)
  final String? warning;                        // user-facing, non-fatal
}
```

#### Semantics

- **Argument validation (pre-transaction).**
  - Empty `templateSlotIndices` → throw `ArgumentError` (UI must prevent this).
  - Any index outside `[0, template.slots.length)` → `ArgumentError`.
  - Negative `insertionOffset` → `ArgumentError`.
  - `templateSlotIndices` may contain duplicates; duplicates expand to multiple copies in output order.
- **Transactional snapshot (first DB read inside `transaction()`).** Even when `templateId != targetPresetId`, read the source template's slots, params, strings, mappings, and routings into memory **first**, so subsequent writes to the target cannot disturb the data being copied. This snapshot is also what self-application uses.
- **Space check (after snapshot, before any writes).** Read all `PresetSlots` for `targetPresetId`. Let `existing = count`. The applied count is `templateSlotIndices.length`. In `overwrite = false` (insert) mode, `existing + applied` must be ≤ 32. In `overwrite = true` (replace) mode, `max(existing, insertionOffset + applied)` must be ≤ 32. If either limit is exceeded, throw `TemplateSpaceException` with the diagnostic numbers (current/applied/total/limit). The UI catches and renders.
- **Algorithm availability.** Every template slot's `algorithmGuid` must exist in the local `algorithms` table. Missing guids cause that slot to be added to `skippedTemplateSlotIndices` with the warning string populated; the rest still apply. (Mirrors the metadata-availability check in `injectTemplateToDevice`.) The applied count for the space check uses `templateSlotIndices.length - skippedCount`.
- **Insertion offset clamping.** `insertionOffset` is clamped to `[0, existing]` based on the **pre-write** `existing` count. In insert mode, values past `existing` effectively append.
- **Insert mode (`overwrite = false`).** Shift any existing target slots with `slotIndex >= insertionOffset` upward by `applied` (= non-skipped count). Then insert the copied slots starting at `insertionOffset`.
- **Replace mode (`overwrite = true`).** For each `i` in `0..applied-1`, the target slot at `insertionOffset + i` is replaced. If a position is empty, just insert. No shifting.
- **Explicit child-row cleanup in replace mode.** The current schema declares `onDelete: KeyAction.cascade` only on `PresetParameterValues` and `PresetParameterStringValues` (`lib/db/tables.dart:156, 172`); `PresetMappings` and `PresetRoutings` do **not** cascade. So replace-mode deletion of a target `PresetSlots` row must be preceded by explicit `delete()` calls on both non-cascading child tables, scoped to that slot id. The implementation reuses the same `batch.deleteWhere` pattern already in `saveFullPreset` (`lib/db/daos/presets_dao.dart:284–296`) and extends it to include `presetRoutings`.
- **Slot copy fidelity.** Each copied slot duplicates:
  - `algorithmGuid`, `customName` (verbatim — including null);
  - all `PresetParameterValues` rows;
  - all `PresetParameterStringValues` rows;
  - all `PresetMappings` rows (including `perfPageIndex`);
  - `PresetRoutings` row, if present.
  New rows reference the newly-inserted slot's `id`. All packed mapping bytes round-trip via the existing `PackedMappingDataConverter` — we never decode/re-encode. `customName` strings are copied verbatim; we do not truncate or validate length (the firmware imposes its own limit, which the existing send-slot-name path already handles).
- **Atomicity.** The whole operation runs in a single `transaction()`. On any exception, no partial mutation is visible. `lastModified` on the target preset is bumped to `DateTime.now()`.
- **Idempotency.** Repeated calls with the same arguments append additional copies — they are not deduplicated. The UI must guard against double-clicks (loading state on the dialog, button disabled during apply).

#### `TemplateSpaceException`

A dedicated exception type so the cubit/UI can distinguish space failures from generic errors. Defined in `lib/db/daos/presets_dao.dart` alongside the DAO.

```dart
class TemplateSpaceException implements Exception {
  final int current;
  final int applied;
  final int limit;
  TemplateSpaceException({required this.current, required this.applied, this.limit = 32});
  @override String toString() => 'Cannot apply: $current + $applied > $limit slots';
}
```

#### Unit tests (`test/db/daos/presets_dao_test.dart`)

- Apply 3 of 5 template slots, insert mode, into an empty target → target has 3 slots in indices 0..2 with correct params/mappings.
- Apply into the middle of a 4-slot target → shifts subsequent slots correctly; their `id` and child rows survive.
- Replace mode at offset 2 of a 4-slot target → slots 2..N replaced; the previously-present `PresetMappings` and `PresetRoutings` rows for the replaced slots are gone (regression guard for the explicit child-row cleanup).
- Apply 30 slots into a 5-slot target → throws `TemplateSpaceException`, no mutation (asserted via row counts on every involved table).
- Apply a template containing an algorithm whose guid is not in `algorithms` → that slot is skipped, others succeed, warning populated, space check uses non-skipped count.
- Self-application: `templateId == targetPresetId`, all slots → produces 2× slot count with correctly copied params/mappings (the in-memory snapshot pattern is the unit under test).
- Apply with duplicate indices `[2, 2, 2]` → produces 3 identical copies of slot 2 in the target.
- Apply with `insertionOffset = 999` into a 4-slot target, insert mode → clamps to append; target has 4 + applied slots.
- Empty `templateSlotIndices` → throws `ArgumentError`; we treat empty selection as a programmer error since the UI must prevent it.

### 3. Cubit — wiring

**File:** `lib/ui/metadata_sync/metadata_sync_cubit.dart`

Add two thin orchestration methods that wrap the DAO and (where applicable) the device:

```dart
Future<ApplyTemplateSlotsResult> applyTemplateToPreset({
  required int templateId,
  required int targetPresetId,
  required List<int> templateSlotIndices,
  required int insertionOffset,
  bool overwrite = false,
});

Future<void> applyTemplateToDevice({
  required FullPresetDetails template,
  required List<int> templateSlotIndices,
  required IDistingMidiManager manager,
});
```

- `applyTemplateToPreset` calls the new DAO method and emits `viewingLocalData` on success. The DAO `ApplyTemplateSlotsResult` flows out unchanged so the UI can render `skippedTemplateSlotIndices` and any `warning`. A `TemplateSpaceException` is caught at this layer and re-emitted as `metadataSyncFailure(formattedMessage)`. The DAO transaction is not cancellable; the UI disables the apply button for the duration and surfaces a spinner.
- `applyTemplateToDevice` is a **refactor of the existing `injectTemplateToDevice` body** to take an explicit slot-index list:
  - The existing `_isInjectionCancelled` flag, initialization, and check sites stay. Setting `_isInjectionCancelled = false` at entry means a previously-cancelled state from a prior run does not bleed into the next call.
  - The method is **not re-entrant**: a guard at the top short-circuits with a thrown exception if a prior `applyTemplateToDevice` is still running (tracked by a new private `_isInjectionRunning` boolean, paired with a `try/finally`). The UI disables the button in any case; this guard catches MCP/UI races.
  - Stale-template guard: `FullPresetDetails template` is captured by value at call time; the method does not re-fetch the template from the DB during the apply. Any concurrent edit to the source template is invisible to the in-flight apply (consistent with current behavior).
  - Progress emission: between algorithm-add operations, emit a new state `MetadataSyncState.injectingTemplate(applied, total)` (added to the state union) so the dialog can render `Adding 2 of 5…`. Existing `loadingPreset` is replaced by the first `injectingTemplate(0, total)` emission. The final success path still emits `presetLoadSuccess`.
  - Per-slot device error: if a single `requestAddAlgorithm` / `setParameterValue` call throws, the method throws as today; the caught error message includes how many slots were applied before the failure (so the user knows the device is in a partially-modified state). No automatic rollback — the device is not transactional.
  - The existing `injectTemplateToDevice(template, manager)` becomes a one-liner that calls the new method with `[0..template.slots.length-1]`. Its public signature, callers, and existing tests remain valid.

This is the minimum surface change to support partial injection without forking the device protocol.

### 4. UI — Template Manager view

**File:** `lib/ui/template_manager/template_manager_screen.dart` (new) + small entry points in `lib/ui/metadata_sync/metadata_sync_page.dart` and `lib/disting_app.dart`.

The existing **Templates** tab in `metadata_sync_page.dart` (line 821, `_TemplateListView`) **stays**. It is the quick "load / inject / delete" surface. We add a new full-screen route — the *Template Manager* — for organization and partial application.

#### Entry points

- A new menu item under the existing settings/template menu: "Template Manager…" pushes `MaterialPageRoute(builder: (_) => const TemplateManagerScreen())`.
- An icon button in the Templates tab header that opens the same route.

#### Layout

A two-pane screen (single column on narrow):

- **Left pane — template list.** `FutureBuilder` over `presetsDao.getTemplates()`. Grouped by `category` (templates with null category fall under "Uncategorized"). Each row shows name, slot count, and a small badge with the first tag. Selecting a template populates the right pane. A toolbar above the list offers: New from current preset, Edit metadata, Delete, Refresh.
- **Right pane — template detail + apply.**
  - Header: name (editable inline), category dropdown (suggestions from existing categories + free-text), description text field, tags chip input, author text field.
  - Slot table: `slotIndex`, algorithm name, customName, parameter count, mapping count. Each row has a leading checkbox. "Select all" and "Select none" controls live in the table header. Search field filters by algorithm name.
  - Apply controls:
    - **Target** dropdown: "Current device preset", "New local preset…", or any existing non-template preset.
    - **Insertion offset** numeric field (default = current target slot count = append). Hidden when target is "New local preset…".
    - **Mode** segmented control: Insert (default) / Replace.
    - **Apply selected** button (disabled when zero checked or space check would fail). A small live readout shows `selected × current + selected ≤ 32 ✓` style status.

#### Apply flow

`TemplateApplyDialog.show(context, …)` confirms the action and routes:

- Target = current device → `metadataSyncCubit.applyTemplateToDevice(template, selectedIndices, manager)`.
- Target = existing local preset → `metadataSyncCubit.applyTemplateToPreset(templateId, targetId, selectedIndices, offset, overwrite)`.
- Target = new local preset → creates an empty preset via `presetsDao.saveFullPreset` with an empty slot list, then applies.

The dialog handles four states (idle / loading-with-progress / partial-success / error):

- **Idle** — confirmation summary with selected count, target, offset, and mode.
- **Loading-with-progress** — `BlocBuilder` over `MetadataSyncState.injectingTemplate(applied, total)` renders a linear progress bar with `applied / total`. A **Cancel** button calls `metadataSyncCubit.cancelInjection()` for the device path; for the preset path the button is hidden because the DAO transaction is not interruptible.
- **Partial-success** — surfaced when `ApplyTemplateSlotsResult.skippedTemplateSlotIndices` is non-empty: shows the warning string and an enumerated list of skipped algorithm names. The user explicitly dismisses; the apply already committed.
- **Error** — shows the formatted message. `TemplateSpaceException` is rendered with the diagnostic numbers prominently.

Apply-button safeguards (to address rapid double-tap / re-entrance):

- The button is disabled the moment the user taps it; re-enabled only after the operation resolves (success, partial, or error). Tracked via local `bool _inFlight` state.
- A `PopScope(canPop: !_inFlight)` blocks back-button dismissal while the device apply is running (preset apply completes in a single transaction and is fast — no special handling needed).
- If the route pops while the device apply is still running (e.g., the dialog hosts a long-running apply and the user force-closes via navigator), the cancel flag is set in `dispose()` so the cubit terminates cleanly. The user sees the partial-success or error state on the underlying screen via the `MetadataSyncState` listener.

#### Create-template dialog

`CreateTemplateFromPresetDialog.show(context, sourcePreset)` is a separate dialog reached from the toolbar's "New from current preset" action. It:

1. Loads the source preset details at open time:
   - If the source is the live device, it calls the existing read path used by `synchronized_screen` to materialize a `FullPresetDetails` snapshot **once at open**. Subsequent live edits to the device while the dialog is open are not reflected. A small "Refresh" button at the top of the slot list re-snapshots on demand. (We accept staleness as the cost of letting the user think — the alternative is a constantly-shifting checkbox list.)
   - If the source is a saved local preset, it calls `presetsDao.getFullPresetDetails`.
2. Shows a slot table with checkboxes (re-using the same widget as the manager's slot table — extracted into `TemplateSlotSelectionList`).
3. Prompts for name, category, description, tags, author.
4. On confirm, deep-copies the selected slots into a new `PresetEntry` with `isTemplate = true` and the entered metadata, via the existing `saveFullPreset(... isTemplate: true)`. The new `category` and `templateMetadata` columns are set via the `PresetEntry` companion (Drift regenerates `PresetsCompanion` to include them once `build_runner` runs in the worktree — running `dart run build_runner build --delete-conflicting-outputs` is a prerequisite before `flutter analyze`, per CLAUDE.md).

The `TemplateSlotSelectionList` widget is the partial-selection analogue of `CollectionExpansionPanel` (`lib/ui/widgets/collection_expansion_panel.dart`): search field, select-all/none, checkbox rows. It is extracted because both the Template Manager right pane and the Create-from-preset dialog use the exact same slot picker; inlining the same ~100 lines twice would invite drift between the two callers.

#### Widget tests

`test/ui/template_manager/`:

- `template_manager_screen_test.dart` — renders, groups by category, filters by search.
- `template_slot_selection_list_test.dart` — checkbox toggling, select all / none, space-check readout.
- `template_apply_dialog_test.dart` — happy path, space failure, cancellation.
- `create_template_from_preset_dialog_test.dart` — emits expected `FullPresetDetails` payload to a captured DAO mock.

### 5. MCP tool — `apply_template_to_preset`

**Files:** `lib/mcp/tools/disting_tools.dart` (handler) + `lib/mcp/tool_registry.dart` (registration in `_registerPresetTools()` or a new `_registerTemplateTools()`).

Input schema:

```json
{
  "type": "object",
  "properties": {
    "template_id":    {"type": "integer", "description": "Template preset id."},
    "template_name":  {"type": "string",  "description": "Alternative to template_id; resolved by exact match, then case-insensitive."},
    "slot_indices":   {"type": "array",  "items": {"type": "integer", "minimum": 0}, "description": "Which template slots to apply. Omit to apply all."},
    "target":         {"type": "string", "enum": ["device", "preset"], "description": "Where to apply. Default: device."},
    "target_preset_id":   {"type": "integer", "description": "Required when target is 'preset'."},
    "target_preset_name": {"type": "string",  "description": "Alternative to target_preset_id."},
    "insertion_offset":   {"type": "integer", "description": "Slot index in target. Default: append (device) or 0 (new preset)."},
    "overwrite":      {"type": "boolean", "description": "Replace target slots starting at insertion_offset. Default: false."}
  },
  "required": []
}
```

Handler:

- Resolves the template:
  - `template_id` → looked up directly; row must have `isTemplate = true` or error.
  - else `template_name` → case-sensitive exact match first; if zero matches, fall back to case-insensitive exact match; if zero or more than one match, return an error listing the candidate names and asking the caller to use `template_id`.
  - Returns the standard `MCPUtils.buildError` envelope on failure.
- Validates `slot_indices` are within `[0, template.slots.length)`. Default = all. Duplicates allowed (pass through to DAO).
- Branches by `target`:
  - `device`: calls `metadataSyncCubit.applyTemplateToDevice(template, selectedIndices, manager)` after refusing offline mode (returns an error explaining that device mode is required).
  - `preset`: resolves target preset by id or name (same algorithm as template resolution; `isTemplate` constraint reversed — target preset must have `isTemplate = false`, unless the target is the same id as the source for self-extension). Calls `applyTemplateToPreset`. Cross-template application via MCP is forbidden for simplicity.
- Response payload mirrors the DAO result. Field names in the response are the snake_case of the Dart fields, but `inserted_slot_indices.length` is also surfaced as `applied_slot_count` for ergonomics:
  ```json
  {
    "success": true,
    "target": "device|preset",
    "target_preset_id": 42,
    "applied_slot_count": 3,
    "inserted_slot_indices": [5, 6, 7],
    "skipped_template_slot_indices": [1],
    "warning": "Slot 1 (guid abc) skipped: algorithm metadata missing locally."
  }
  ```
  On `TemplateSpaceException`: `{"success": false, "error": "space", "current": N, "applied": M, "limit": 32}` so the caller can reason about it without parsing prose.
- All keys via `convertToSnakeCaseKeys`. Timeout: 30 s for `target == "preset"` (matches `edit_preset`/`new`); 120 s for `target == "device"` because each algorithm-add can take 0.5–10 s for community plugins.
- Partial-success on device: if the device path throws mid-apply, return `{"success": false, "error": "partial_apply", "applied_slot_count": N, "message": "..."}`. The caller is expected to inspect the device state via `show_preset` to confirm.

MCP doc updates:

- Append a section to `docs/mcp-api-guide.md` describing the new tool.
- Cross-link from `docs/mcp-mapping-guide.md` if relevant.

### 6. Existing-behavior shims & migration safety

- `injectTemplateToDevice` keeps its public signature. Internally it becomes:
  ```dart
  Future<void> injectTemplateToDevice(template, manager) =>
      applyTemplateToDevice(
        template: template,
        templateSlotIndices: List.generate(template.slots.length, (i) => i),
        manager: manager,
      );
  ```
- `TemplatePreviewDialog` and the `_TemplateListView` "Inject Template" path keep working unchanged.
- `saveFullPreset` keeps its current signature; the new columns are pulled from `details.preset` via the standard companion path (Drift regenerates the companions to include `category` and `templateMetadata` after `build_runner` runs in the worktree).

---

## Critical Files

| File | Change |
|---|---|
| `lib/db/tables.dart` | Add `category` + `templateMetadata` to `Presets`. |
| `lib/db/database.dart` | Bump `schemaVersion` to 12. Add migration step. |
| `lib/db/daos/presets_dao.dart` | Add `applyTemplateSlots`, `ApplyTemplateSlotsResult`, `TemplateSpaceException`. |
| `lib/models/template_metadata.dart` (new) | `TemplateMetadata` data class: `description`, `tags`, `author`, `createdAt`, `extras` map. Includes `fromJsonString(String?)` / `toJsonString()` static helpers used by callers when reading/writing the `templateMetadata` text column. No Drift `TypeConverter` — the column stores raw JSON text so existing queries and the schema test work without converter wiring, and the conversion happens at the cubit/DAO call sites. |
| `lib/ui/metadata_sync/metadata_sync_cubit.dart` | Add `applyTemplateToPreset` + `applyTemplateToDevice`. Refactor `injectTemplateToDevice` to delegate. |
| `lib/ui/template_manager/template_manager_screen.dart` (new) | Two-pane template manager. |
| `lib/ui/template_manager/template_slot_selection_list.dart` (new) | Reusable slot picker widget. |
| `lib/ui/template_manager/template_apply_dialog.dart` (new) | Apply confirmation + progress dialog. |
| `lib/ui/template_manager/create_template_from_preset_dialog.dart` (new) | Create-from-current dialog. |
| `lib/ui/metadata_sync/metadata_sync_page.dart` | Add toolbar button entry to Template Manager. |
| `lib/disting_app.dart` | Add menu route. |
| `lib/mcp/tools/disting_tools.dart` | Add `applyTemplateToPreset` handler. |
| `lib/mcp/tool_registry.dart` | Register `apply_template_to_preset`. |
| `docs/mcp-api-guide.md` | Document the new tool. |
| `test/db/migrations/v11_to_v12_template_metadata_test.dart` (new) | Schema test. |
| `test/db/daos/presets_dao_test.dart` | Add `applyTemplateSlots` cases. |
| `test/ui/template_manager/*` (new) | Widget tests for new dialogs/screen. |
| `test/mcp/tools/apply_template_tool_test.dart` (new) | Tool happy path + error envelopes. |

## No changes to

- `lib/cubit/disting_cubit.dart` and any of its delegates/mixins. Templates remain a metadata-sync surface; the main cubit orchestrates the device, not template application.
- `lib/core/routing/` — the copy preserves routing rows verbatim; no routing logic touched.
- `lib/services/mcp_server_service.dart` other than picking up the new entry from the registry.
- The existing `_TemplateListView` Inject / Load / Delete buttons — no behavioral changes.

---

## Open questions (documented, not punted)

1. **Category vs. tags.** We keep both. `category` is a single string for grouping in the manager left pane; `tags` is a flexible list inside `templateMetadata`. If user feedback shows they overlap, we can collapse later — additive design now.
2. **Cross-device portability.** Out of scope. Templates remain device-local. Exporting templates to JSON/file is a follow-up.
3. **Schema-versioning the metadata JSON.** Included a `schemaVersion: 1` field so we can evolve without another DB migration.
4. **Worktree generated files.** `dart run build_runner build --delete-conflicting-outputs` must be run in the worktree before `flutter analyze` / `flutter test`, both for the Drift companions (new `category` / `templateMetadata` columns) and the Mockito mocks for the new cubit method. This is the same constraint already documented in `CLAUDE.md` — repeating it here so the executing engineer doesn't trip over Drift "column not found" errors on first build.
5. **No cancellation for the preset path.** `applyTemplateToPreset` runs inside a Drift transaction and cannot be cancelled mid-flight. This is deliberate: SQLite operations on this workload are sub-second, and adding cooperative cancellation would couple the DAO to UI lifecycle. If a future preset becomes very large (>1000 slots — implausible given the 32-slot device limit), revisit.

## Out of scope

- Multi-template merge (applying slots from N templates at once). The UI applies one template at a time.
- Reordering / renumbering slots within a template (the existing preset editor handles that on the saved-as-template preset).
- Template export/import as JSON files.
- Sharing templates across users / cloud storage.
- Changes to the existing `_TemplateListView` Inject button (still applies the whole template).
- Performance pages — the perf-page index is preserved per-slot via the existing `PackedMappingData` round-trip; no new perf-page logic.
