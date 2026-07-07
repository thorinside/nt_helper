# Algorithm Clipboard — Shift-click copy + Mod+C / Mod+V paste

## Context

Users want to grab a few algorithms (with all their parameter values, mappings,
and routings) from one preset and drop them onto the end of another — or the
same — preset, without going through the full Template Manager flow. The
operation should feel like a clipboard: copy, switch presets, paste.

This is intentionally **separate from the Template Manager feature**, but is
inspired by its implementation. In fact, the clipboard is persisted as a single
reserved *system template* row in the database, so it survives app restarts and
reuses the proven template-injection path for pasting.

## Approach

### Storage: a reserved system template

The clipboard is a single row in `Presets` with:

- `isTemplate = true`
- `name = Constants.algorithmClipboardPresetName` (`'__algorithm_clipboard__'`)
- `category = Constants.algorithmClipboardCategory` (`'__algorithm_clipboard__'`)

`PresetsDao.getTemplates()` excludes this category, so the clipboard is
invisible in the Template Manager and is never returned by normal template
listings, exports, or shares.

New DAO methods (`lib/db/daos/presets_dao.dart`):

- `getClipboardTemplate()` — loads the clipboard as `FullPresetDetails?`.
- `clipboardSlotCount()` — slot count (0 when empty).
- `saveClipboardTemplate(FullPresetDetails)` — upserts by reserved name,
  reindexing source slots to `0..n-1` and pinning name/category.
- `clearClipboardTemplate()` — deletes the row (no-op when empty).

### Copy: `AlgorithmClipboardService.copyFromDistingState`

`lib/services/algorithm_clipboard_service.dart` snapshots the selected
in-memory slots from `DistingStateSynchronized` into the persistent
clipboard. It:

1. Builds a `FullPresetDetails` from the live state (reuses
   `fullPresetDetailsFromDistingState`).
2. De-duplicates the selection while preserving first-seen order.
3. Upserts any algorithm metadata rows not yet in the local cache, so the
   clipboard remains self-describing.
4. Calls `saveClipboardTemplate`.

### Paste: `AlgorithmClipboardService.pasteToCurrentDevice`

Loads the clipboard and delegates to `MetadataSyncCubit.applyTemplateToDevice`
(all slot indices, appended to the end). This reuses the exact, battle-tested
template-injection path: preflight metadata, slot-limit check, per-slot
`requestAddAlgorithm`, then parameter/mapping/name writes, then a cubit refresh.

### Selection: shift-click multi-select via the gesture arena

Slot tabs (desktop only — the slot tab bar is the persistent top chrome there;
mobile collapses it) are wrapped in a `RawGestureDetector` using a new
`ShiftClickGestureRecognizer` (`lib/ui/widgets/shift_click_gesture_recognizer.dart`).

On pointer-down:

- **Shift held** → the recognizer fires `onShiftTap` (toggles the slot in a
  `ValueNotifier<Set<int>>` `_clipboardSelection`) and immediately resolves the
  gesture arena as **accepted**. Winning the arena rejects the TabBar's own tap
  recognizer, so the active tab does **not** switch while multi-selecting, and
  the in-flight tap gesture is never torn down (no "deactivated widget"
  crashes).
- **Shift not held** → the recognizer resolves as **rejected**, yielding the
  arena so normal tab selection proceeds unchanged.

The selection indicator (a top border on the tab) is rendered by a
`ValueListenableBuilder` leaf, so toggling rebuilds only the indicator, not the
`GestureDetector`/`Tab` above it.

### Shortcuts

`lib/services/key_binding_service.dart` adds `CopyAlgorithmsIntent` (Mod+C)
and `PasteAlgorithmsIntent` (Mod+V), both with Ctrl and Meta variants, wired
into `buildGlobalActions` and documented in the shortcut help overlay.

### UI handlers (`lib/ui/synchronized_screen.dart`)

- `_handleCopyAlgorithmsToClipboard` — sorts the selection, copies, announces,
  clears the on-screen selection. Snackbars for empty selection / failures.
- `_handlePasteAlgorithmsFromClipboard` — empty-clipboard snackbar when
  applicable, otherwise runs the injection via a transient `MetadataSyncCubit`
  and announces progress/result. Errors surface as snackbars.

## Critical Files

| File | Change |
|---|---|
| `lib/constants.dart` | Reserved clipboard name/category sentinels |
| `lib/db/daos/presets_dao.dart` | Clipboard DAO methods; exclude clipboard from `getTemplates` |
| `lib/services/algorithm_clipboard_service.dart` | New: copy/paste/clipboard-count service |
| `lib/services/key_binding_service.dart` | `CopyAlgorithmsIntent` / `PasteAlgorithmsIntent` + bindings + actions |
| `lib/ui/widgets/shift_click_gesture_recognizer.dart` | New: arena-winning shift-click recognizer |
| `lib/ui/synchronized_screen.dart` | `_clipboardSelection` notifier, shift-click tab wiring, Mod+C/Mod+V handlers, selection indicator |
| `lib/ui/widgets/shortcut_help_overlay.dart` | Document Mod+C / Mod+V |

## No changes to

- `MetadataSyncCubit.applyTemplateToDevice` — reused as-is.
- `current_preset_template_source.dart` — reused as-is.
- Template Manager UI — clipboard is hidden, not exposed.

## Verification

- `flutter analyze` — zero issues.
- `flutter test` — all tests pass, including new:
  - `test/db/daos/algorithm_clipboard_dao_test.dart`
  - `test/services/algorithm_clipboard_service_test.dart`
  - `test/ui/synchronized_screen_clipboard_test.dart`
  - `test/services/key_binding_service_test.dart` (extended)

## Acceptance

- Shift-click (desktop) toggles slots into a multi-selection with a visible
  indicator; shift-click again deselects. The active tab does not jump.
- Mod+C copies the selected slots (with all values/mappings/routings) into the
  persistent clipboard and clears the selection.
- Switch presets (or stay); Mod+V appends the clipboard to the end of the
  current device preset, reusing the template-injection path.
- Empty selection / empty clipboard surface as guidance snackbars.
- Clipboard is hidden from the Template Manager and survives app restarts.
