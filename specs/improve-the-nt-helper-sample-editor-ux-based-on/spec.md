# Improve sample editor UX based on sample-mapping feedback

Baseline ref: `5cd35577` at spec authoring time; implementation starts after the spec-program commit
Target language: Dart / Flutter  
Hardening policy: realistic-only  
Program folder: `specs/improve-the-nt-helper-sample-editor-ux-based-on`

## Request

Improve the nt_helper sample editor workflow for persistent sample-row ordering, root-note assignment from a list UI, selection-scoped unmap/discard actions, bulk mapping edits, and loop/fade waveform preview. Product prose uses `disting` lowercase.

## Inventory method

Inventory was generated before reading implementation blocks:

```bash
python3 /Users/nealsanche/nosuch/nt_helper/.pi/skills/decision-free-specs/languages/dart/inventory.py \
  lib/ui/poly_multisample/poly_multisample_builder_cubit.dart \
  lib/ui/poly_multisample/poly_samples_editor_view.dart \
  lib/ui/poly_multisample/widgets/poly_sample_list.dart \
  lib/ui/poly_multisample/widgets/poly_sample_inspector.dart \
  lib/ui/poly_multisample/poly_region_math.dart \
  lib/poly_multisample/poly_audio_preview_service.dart \
  lib/poly_multisample/poly_wav_service.dart \
  lib/poly_multisample/wav_metadata.dart \
  lib/poly_multisample/poly_multisample_models.dart \
  > /tmp/nt_sample_inventory.md
```

Additional widget and test inventory was generated with:

```bash
python3 /Users/nealsanche/nosuch/nt_helper/.pi/skills/decision-free-specs/languages/dart/inventory.py \
  lib/ui/poly_multisample/widgets/poly_waveform_editor.dart \
  test/poly_multisample/poly_multisample_builder_cubit_test.dart \
  test/poly_multisample/widgets/poly_sample_list_test.dart \
  test/poly_multisample/widgets/poly_sample_inspector_test.dart \
  test/poly_multisample/widgets/poly_waveform_editor_test.dart \
  test/poly_multisample/poly_samples_editor_view_test.dart \
  test/poly_multisample/wav_metadata_test.dart \
  > /tmp/nt_sample_tests_inventory.md
```

Parser inventory was generated with:

```bash
python3 /Users/nealsanche/nosuch/nt_helper/.pi/skills/decision-free-specs/languages/dart/inventory.py \
  lib/poly_multisample/poly_multisample_parser.dart \
  > /tmp/parser_inventory.md
```

Hand check completed for `lib/ui/poly_multisample/widgets/poly_sample_list.dart`: the inventory declaration list matches the file structure around `PolySampleList`, `_PolySampleListState`, `_selectionMode`, `_scheduleFocusScroll`, `build`, `_InlineSampleStepper`, and `_clampMidi`.

A second spot check of `lib/ui/poly_multisample/poly_region_math.dart` found the current scanner omits record-return function `midiExtents`. `midiExtents` is not modified by this program. All symbols modified by this program appear in the inventory output or are new symbols named below.

## Source inventory

| File | Current size | Relevant declarations | Imported by |
|---|---:|---|---|
| `lib/ui/poly_multisample/poly_multisample_builder_cubit.dart` | 2485 lines | `PolyMultisampleBuilderState`, `PolyMultisampleBuilderCubit`, `selectRegion`, mapping update methods, `removeSelectedRegions`, `clearDraft`, `discardChanges`, waveform preview methods, `_replaceEditedRegions`, `_setInstrument` | poly multisample UI, dialogs, and tests |
| `lib/ui/poly_multisample/poly_samples_editor_view.dart` | 416 lines | `PolySamplesEditorView`, `_Toolbar`, `_EditorBody`, `_WarningPanel` | `lib/ui/poly_multisample/poly_samples_screen.dart`, editor tests |
| `lib/ui/poly_multisample/widgets/poly_sample_list.dart` | 448 lines | `PolySampleList`, `_PolySampleListState`, `_InlineSampleStepper`, `_clampMidi` | editor view and sample-list tests |
| `lib/ui/poly_multisample/widgets/poly_sample_inspector.dart` | 1020 lines | `PolySampleInspector`, `_HeaderRow`, `_PreviewControls`, `_MappingSection`, `_WaveformSection`, `_FadeRow`, `_StepRow`, `_WaveformLoadingPlaceholder`, `_FrameNudgeRow`, `_curveLabel`, `_isLocalPath`, `_revealFolder` | editor view and inspector tests |
| `lib/ui/poly_multisample/widgets/poly_waveform_editor.dart` | 611 lines | `PolyWaveformEditorMode`, `PolyWaveformEditor`, `_PolyWaveformEditorState`, waveform intents, `_PolyWaveformPainter` | inspector and waveform tests |
| `lib/ui/poly_multisample/poly_region_math.dart` | 105 lines | `effectiveLow`, `effectiveHigh`, `midiExtents`, `velocityLanes`, `selectedRegionFor`, `sampleDisplayLabel` | key map, sample list, inspector, tests |
| `lib/poly_multisample/poly_multisample_models.dart` | 324 lines | `PolySampleIssue`, `PolySampleRegion`, `PolySampleInstrument`, `PolyWaveformDraft`, import/apply model classes | parser, services, poly multisample UI and tests |
| `lib/poly_multisample/poly_multisample_parser.dart` | 160 lines | `PolyMultisampleParser`, `sortRegions`, note conversion helpers | parser users, services, UI, tests |
| `lib/poly_multisample/wav_metadata.dart` | 924 lines | `WavOverview`, `WavPeak`, `WavFadeCurve`, `WavFadeShaper`, `WavRenderOptions`, `WavAudioRenderer`, `WavMetadataWriter` | WAV service, UI, tests |
| `test/poly_multisample/poly_multisample_builder_cubit_test.dart` | 3499 lines | cubit tests, hardware/WAV/preview fakes | no importers |
| `test/poly_multisample/widgets/poly_sample_list_test.dart` | 472 lines | sample-list widget tests | no importers |
| `test/poly_multisample/widgets/poly_sample_inspector_test.dart` | 804 lines | inspector widget tests and test cubit | no importers |
| `test/poly_multisample/widgets/poly_waveform_editor_test.dart` | 618 lines | waveform editor widget tests | no importers |
| `test/poly_multisample/poly_samples_editor_view_test.dart` | 457 lines | editor integration tests and test cubit | no importers |
| `test/poly_multisample/wav_metadata_test.dart` | 407 lines | WAV metadata/rendering tests | no importers |

## Architecture

Pattern: focused state-model extension plus widget rewrites inside the existing poly multisample sample editor. No new route, service layer, database table, MIDI request, parser format, or hardware command is introduced.

The cubit remains the owner of mapping mutations, selection-scoped operations, warning recomputation, preview caches, temp-file cleanup, and async stale-request guards. Widgets render controls and forward explicit commands to the cubit. The sample list keeps the current in-memory order while editing; imports and hardware loads keep their existing service/parser ordering.

No public symbol moves to another file. No compatibility re-export is needed.

### Target file tree

| Path | Action |
|---|---|
| `lib/ui/poly_multisample/poly_multisample_builder_cubit.dart` | Add selection-scoped mapping APIs, selection-scoped discard/unmap behavior, mapping warnings, stable edit ordering, draft-preview cache |
| `test/poly_multisample/poly_multisample_builder_cubit_test.dart` | Add state, warning, ordering, discard/unmap, bulk edit, stale preview, and cache tests |
| `lib/ui/poly_multisample/poly_samples_editor_view.dart` | Show mapping-warning panel, make toolbar discard label selection-scoped, add unmap menu item |
| `test/poly_multisample/poly_samples_editor_view_test.dart` | Add editor integration tests for warnings, toolbar labels, and unmap action |
| `lib/ui/poly_multisample/widgets/poly_sample_inspector.dart` | Add mapping list controls that work for one selected sample or multiple selected samples; wire selection bulk edits; pass fade data to waveform editor |
| `test/poly_multisample/widgets/poly_sample_inspector_test.dart` | Add root-list, multi-selection bulk edit, unmap, and fade-control tests |
| `lib/ui/poly_multisample/widgets/poly_waveform_editor.dart` | Draw fade preview curves on the waveform with accessible summary text |
| `test/poly_multisample/widgets/poly_waveform_editor_test.dart` | Add fade preview semantics and repaint tests |
| `lib/poly_multisample/wav_metadata.dart` | Add small test-visible helper for fade curve points used by the painter |
| `test/poly_multisample/wav_metadata_test.dart` | Add helper tests for fade curve point generation |
| `specs/README.md` | Program table row added by this spec authoring commit |

## Symbol map

| Symbol | Current location | Destination after implementation | Exported | Required action |
|---|---|---|---|---|
| `PolyMultisampleBuilderState` | `lib/ui/poly_multisample/poly_multisample_builder_cubit.dart` | same file | yes | Add `mappingWarnings` field, constructor parameter, `copyWith` parameter, and state equality-free storage like existing fields |
| `PolyMultisampleBuilderCubit.updateRoot` | cubit file | same file | yes | Keep existing signature and behavior; call mapping-warning recomputation through `_replaceEditedRegions` |
| `PolyMultisampleBuilderCubit.updateRangeLow` | cubit file | same file | yes | Keep existing signature and behavior; call mapping-warning recomputation through `_replaceEditedRegions` |
| `PolyMultisampleBuilderCubit.updateRangeHigh` | cubit file | same file | yes | Keep existing signature and behavior; call mapping-warning recomputation through `_replaceEditedRegions` |
| `PolyMultisampleBuilderCubit.updateVelocity` | cubit file | same file | yes | Keep existing signature and behavior; call mapping-warning recomputation through `_replaceEditedRegions` |
| `PolyMultisampleBuilderCubit.updateRoundRobin` | cubit file | same file | yes | Keep existing signature and behavior; call mapping-warning recomputation through `_replaceEditedRegions` |
| `PolyMultisampleBuilderCubit.updateSelectedRoot` | new | cubit file | yes | Set root for every selected path or the focused path fallback |
| `PolyMultisampleBuilderCubit.updateSelectedRangeLow` | new | cubit file | yes | Set low range for every selected path or the focused path fallback |
| `PolyMultisampleBuilderCubit.updateSelectedRangeHigh` | new | cubit file | yes | Set high range for every selected path or the focused path fallback |
| `PolyMultisampleBuilderCubit.updateSelectedVelocity` | new | cubit file | yes | Set velocity layer for every selected path or the focused path fallback |
| `PolyMultisampleBuilderCubit.updateSelectedRoundRobin` | new | cubit file | yes | Set RR lane for every selected path or the focused path fallback |
| `PolyMultisampleBuilderCubit.unmapSelectedRegions` | new | cubit file | yes | Clear root, range, switch point, velocity, and RR for selected paths |
| `PolyMultisampleBuilderCubit.discardChanges` | cubit file | same file | yes | Selection-scoped reset when a selection exists; full reset only with no selection |
| `PolyMultisampleBuilderCubit.removeSelectedRegions` | cubit file | same file | yes | Keep row removal; use stable ordering and mapping-warning recomputation |
| `_replaceEditedRegions` | cubit file | same file | no | Remove the edit-time `PolyMultisampleParser.sortRegions(regions)` call; recompute mapping warnings |
| `_mappingWarningsFor` | new | cubit file | no | Return deterministic warning strings for invalid ranges, root-outside-range, and same velocity/RR overlaps |
| `_selectedOrFocusedPaths` | new | cubit file | no | Return `state.selectedPaths` when non-empty, else focused path when present, else empty set |
| `_updateSelectedRegions` | new | cubit file | no | Apply a region transform to every path from `_selectedOrFocusedPaths` without reordering |
| `_noteLabel` | new | cubit file | no | Convert MIDI values to note names through `PolyMultisampleParser.midiToNoteName` |
| `_sampleMappingLabel` | new | cubit file | no | Return the same duplicate-safe label as `sampleDisplayLabel` without importing `poly_region_math.dart` into the cubit |
| `_samplePreviewCache` | new | cubit file | no | Cache rendered sample preview paths by source path, file stat, and draft fingerprint |
| `_samplePreviewRenderInFlight` | new | cubit file | no | Coalesce concurrent render requests for the same preview cache key |
| `_renderedSamplePreviewPath` | new | cubit file | no | Render loop/fade/trim/gain drafts to a preview WAV for sample preview playback |
| `PolySamplesEditorView` | editor view | same file | yes | Continue as screen root; no signature change |
| `_Toolbar` | editor view | same file | no | Selection-scoped discard label and menu item for unmap selected |
| `_EditorBody` | editor view | same file | no | Pass state to inspector unchanged; no layout redesign |
| `_WarningPanel` | editor view | same file | no | Add a required storage-key parameter so the existing warnings panel and new mapping warnings panel do not share a sibling key |
| `PolySampleInspector` | inspector file | same file | yes | Build mapping controls for one or many selected samples |
| `_MappingSection` | inspector file | same file | no | Replace stepper-only mapping area with dropdown/list controls plus existing step rows |
| `_MappingDropdownRow` | new | inspector file | no | Fixed row for Root/Low/High/Velocity/RR list selection |
| `_SelectionValue` | new | inspector file | no | Private holder for all-same versus mixed selected values |
| `_selectedRegionsForMapping` | new | inspector file | no | Return selected regions, falling back to current region |
| `_selectionValue` | new | inspector file | no | Return shared value or mixed sentinel |
| `_noteMenuItems` | new | inspector file | no | Generate C-1 through G9 dropdown items for MIDI 0 through 127 |
| `_laneMenuItems` | new | inspector file | no | Generate lane dropdown items 1 through 32 |
| `_WaveformSection` | inspector file | same file | no | Pass fade fields to `PolyWaveformEditor`; preview playback uses rendered drafts |
| `PolyWaveformEditor` | waveform editor file | same file | yes | Add fade-related constructor parameters with safe defaults |
| `_PolyWaveformPainter` | waveform editor file | same file | no | Draw fade curves and include them in repaint checks |
| `WavFadeCurvePoint` | new | `lib/poly_multisample/wav_metadata.dart` | yes | Tiny immutable point with `double x` and `double gain` |
| `WavFadePreview` | new | `lib/poly_multisample/wav_metadata.dart` | yes | Static helper that returns sampled fade curve points for UI painting |

## Decision inventory

| Decision | Rationale | Files affected | Status |
|---|---|---|---|
| Keep sample-row order stable after initial load by removing edit-time sorting from `_replaceEditedRegions`. | The user must not lose the active row while changing root/range/velocity/RR values. Import/load order is already sorted before editor entry. | cubit, cubit tests | required |
| Do not change `PolyMultisampleParser.sortRegions` or service load ordering. | Parser/service ordering is useful at load time and outside the mid-edit confusion path. | parser/services out of edit scope | out-of-scope |
| Store mapping warnings separately as `mappingWarnings`, not inside existing `warnings`. | Existing `warnings` contains import/hardware messages; live mapping warnings must clear and recompute on every edit without erasing import warnings. | cubit, editor view, tests | required |
| Treat overlapping ranges as a warning, not as a blocked edit. | Feedback requests a clear warning rather than silent list resorting; users can intentionally create temporary states while editing. | cubit, editor view, tests | required |
| Overlap warnings only compare mapped regions with the same effective velocity layer and same effective RR lane. | Different velocity layers and RR lanes are legitimate multisample overlaps. Same velocity and same RR claims the same playable slot. | cubit, tests | required |
| Invalid range means `effectiveLow(region) > effectiveHigh(region)`. | This is the concrete impossible range state users can create by editing low/high independently. | cubit, tests | required |
| Root-outside-range is a warning for mapped regions only. | A root outside its playable range produces confusing pitching and is a plausible edit mistake; unmapped rows already use existing missing-root issues and must not produce mapping warnings. | cubit, tests | required |
| `discardChanges` resets only selected samples when a selection exists. | The request prefers selection-scoped discard/unmap and reserves full wipe for a deliberate no-selection or explicit clear action. | cubit, editor view, tests | required |
| `clearDraft` remains the intentional full wipe. | Bulk wipe already has an explicit menu action named `Clear all`. | editor view, cubit | required |
| `removeSelectedRegions` keeps deleting selected rows and is labeled as removal, not unmap. | Removing files from the draft and unmapping zones are different workflows. | editor view, tests | required |
| Add `unmapSelectedRegions` for non-destructive unmapping. | The selected sample rows remain present while their mapping fields are cleared. | cubit, editor view, inspector, tests | required |
| Bulk edit controls live in the inspector mapping section. | The inspector already owns mapping details and is visible for selected rows on desktop and narrow layouts. | inspector, tests | required |
| Root/Low/High list controls contain all MIDI notes 0 through 127 with note names from `PolyMultisampleParser.midiToNoteName`. | This satisfies root assignment from a list UI and avoids new note-name rules. | inspector, tests | required |
| Velocity and RR list controls contain integer lanes 1 through 32. | Existing lanes have no hard max; 1 through 32 covers realistic mapping workflows and keeps the list finite. | inspector, tests | required |
| Mixed multi-selection values display `Mixed` as dropdown hint and no selected dropdown value. | Users can see that selected rows differ without the UI inventing a representative value. | inspector, tests | required |
| Setting a dropdown value applies that exact value to every selected row. | This is deterministic and satisfies bulk edit together. | cubit, inspector, tests | required |
| Existing inline steppers remain per-row only. | Row steppers are optimized for the active row and already focus a single row. Bulk edits use inspector dropdowns. | sample list | required |
| Rendered draft sample preview is cached by path, file modified time, size, and draft fingerprint. | Fade/loop/trim preview playback must be reliable across repeated play taps without regenerating the same temp file. | cubit, tests | required |
| Sample preview playback uses rendered draft audio for local WAVs when loop or waveform edits exist. | Users hear loop/fade/trim/gain draft effects before saving destructive changes. | cubit, tests | required |
| Hardware direct preview keeps the existing cached download path and does not render local draft fades. | Hardware samples are not locally editable until downloaded/mounted; local draft rendering requires local file bytes. | cubit | out-of-scope |
| Draw fade curves in `PolyWaveformEditor` using `WavFadePreview.sampleCurve`. | The waveform can show fade shape without duplicating curve math in the painter. | wav metadata, waveform editor, tests | required |
| Do not import `poly_region_math.dart` into the cubit. | `poly_region_math.dart` imports the cubit for `selectedRegionFor`; importing it back into the cubit creates a UI-state library cycle. Duplicate only the tiny display-label logic as `_sampleMappingLabel`. | cubit | required |
| Add accessible fade preview summary text to the waveform editor. | Screen-reader users receive the same fade-state signal as sighted users. | waveform editor, inspector tests | required |
| Do not add audio-engine DSP or real-time streaming. | Existing preview service plays WAV files; cached render-to-temp is the repository pattern for note previews. | audio service out of edit scope | out-of-scope |
| No Strategy registry. | There is only one editor behavior with fixed mapping fields; no behavioral family exists. | all target files | out-of-scope |
| No database, MIDI SysEx, SD-card upload, or parser format changes. | The request is limited to sample editor UI/state and preview behavior. | services/database out of edit scope | out-of-scope |

## Mapping warning rules

Warnings are recomputed every time `_setInstrument` or `_replaceEditedRegions` emits editor-ready state.

Use these helpers inside the cubit:

```dart
int lowFor(PolySampleRegion region) =>
    (region.rangeLow ?? region.switchPoint ?? region.rootMidi ?? 0).clamp(0, 127).toInt();

int highFor(PolySampleRegion region, List<PolySampleRegion> regions) {
  final explicit = region.rangeHigh;
  if (explicit != null) return explicit.clamp(0, 127).toInt();
  final low = lowFor(region);
  final velocity = region.velocityLayer ?? 1;
  final rr = region.roundRobin ?? 1;
  final laterLows = regions
      .where((candidate) =>
          candidate.rootMidi != null &&
          (candidate.velocityLayer ?? 1) == velocity &&
          (candidate.roundRobin ?? 1) == rr &&
          lowFor(candidate) > low)
      .map(lowFor)
      .toList()
    ..sort();
  if (laterLows.isEmpty) return 127;
  return math.max(low, laterLows.first - 1);
}
```

`_mappingWarningsFor(regions)` returns warning strings in this exact order:

1. Iterate `regions` in current editor order and add invalid range warnings.
2. Iterate `regions` in current editor order and add root-outside-range warnings.
3. Iterate pairs `(i, j)` where `i < j` in current editor order and add overlap warnings.

Warning text:

| Condition | Text |
|---|---|
| invalid range | `Mapping warning: <label> has low <lowNote> above high <highNote>.` |
| root outside range | `Mapping warning: <label> root <rootNote> is outside <lowNote>–<highNote>.` |
| same velocity/RR overlap | `Mapping warning: <labelA> and <labelB> overlap on <overlapLowNote>–<overlapHighNote> at velocity <velocity>, RR <rr>.` |

`<label>` values come from new private cubit helper `_sampleMappingLabel(region, regions)`. `_sampleMappingLabel` must copy the current logic from `sampleDisplayLabel` in `lib/ui/poly_multisample/poly_region_math.dart`: use `region.displayName` when it is unique in `regions`, otherwise compute a relative path from the common directory with `package:path/path.dart` as `p` and replace backslashes with `/`. Do not import `poly_region_math.dart` into the cubit. Note names come from `PolyMultisampleParser.midiToNoteName`.

Root-outside-range comparison skips regions with `rootMidi == null`. Overlap comparison skips regions with `rootMidi == null`. Overlap comparison requires `(a.velocityLayer ?? 1) == (b.velocityLayer ?? 1)` and `(a.roundRobin ?? 1) == (b.roundRobin ?? 1)`. Overlap exists when `math.max(lowA, lowB) <= math.min(highA, highB)`.

## Selection-scoped mutation rules

`_selectedOrFocusedPaths()` returns:

1. `state.selectedPaths` when it is non-empty.
2. `{state.focusedPath!}` when `focusedPath` is non-null and present in `state.editedRegions`.
3. Empty set.

`_updateSelectedRegions(update, {IDistingMidiManager? manager})` applies `update` to every region whose path is in `_selectedOrFocusedPaths()`. It calls `_replaceEditedRegions` once. It preserves current editor order. It preserves the same selected paths and focused path when those paths remain. It calls `_autoPreviewMappingEdit` for the focused path when a focused path was updated; otherwise it calls `_autoPreviewMappingEdit` for the first updated path in editor order.

Selection-scoped public methods use these exact signatures:

```dart
void updateSelectedRoot(int midi, {IDistingMidiManager? manager})
void updateSelectedRangeLow(int midi, {IDistingMidiManager? manager})
void updateSelectedRangeHigh(int midi, {IDistingMidiManager? manager})
void updateSelectedVelocity(int layer, {IDistingMidiManager? manager})
void updateSelectedRoundRobin(int lane, {IDistingMidiManager? manager})
void unmapSelectedRegions()
```

Clamp rules match the existing single-row methods: MIDI values clamp to 0 through 127, velocity and RR clamp to minimum 1. `updateSelectedRoot` sets both `rootMidi` and `rootName`. `unmapSelectedRegions` clears root, root name, range low, range high, switch point, velocity layer, and RR lane by calling `copyWith(clearRoot: true, clearRangeLow: true, clearRangeHigh: true, clearSwitchPoint: true, clearVelocityLayer: true, clearRoundRobin: true)`.

`discardChanges()` behavior:

| State | Required behavior |
|---|---|
| `selectedPaths` is empty | Existing full discard behavior: replace edited regions with baseline regions and clear waveform drafts |
| `selectedPaths` is non-empty | For each selected path that exists in `baselineRegions`, replace the edited row with the baseline row at the edited row's current position; for each selected path absent from `baselineRegions`, remove that edited row; clear `loopDrafts` and `wavEditDrafts` entries for selected paths only; preserve non-selected rows and their draft maps |

## Inspector mapping UI rules

`_MappingSection` shows controls for the selected group. The selected group is `state.editedRegions.where((region) => state.selectedPaths.contains(region.path)).toList()`. When that list is empty, it uses `[region]`.

Title and summary:

| Selection count | Header text | Summary text |
|---:|---|---|
| 1 | `Mapping` | no extra summary |
| 2 or more | `Mapping selection` | `<count> samples selected` |

Add these dropdown rows above the existing stepper rows, in this exact order:

1. `Root` note dropdown, key `poly-mapping-root-dropdown`
2. `Low` note dropdown, key `poly-mapping-low-dropdown`
3. `High` note dropdown, key `poly-mapping-high-dropdown`
4. `Velocity` lane dropdown, key `poly-mapping-velocity-dropdown`
5. `RR` lane dropdown, key `poly-mapping-rr-dropdown`

Dropdown value display:

| Selected group values | Dropdown `value` | Hint text |
|---|---|---|
| all selected rows have same value | that shared integer | none |
| at least two selected rows differ | `null` | `Mixed` |
| root/low/high value absent for all rows | `null` | `Unset` for Root, `Mixed` for Low/High |

Selection values use these exact raw/effective fields:

| Dropdown | Value source for `_selectionValue` |
|---|---|
| Root | `region.rootMidi` |
| Low | `region.rangeLow`; if all selected values are null, return `_SelectionValue.value(null)` and use unset hint `Mixed`; if some selected values are null and some non-null, return `_SelectionValue.mixed()` |
| High | `region.rangeHigh`; if all selected values are null, return `_SelectionValue.value(null)` and use unset hint `Mixed`; if some selected values are null and some non-null, return `_SelectionValue.mixed()` |
| Velocity | `region.velocityLayer ?? 1` |
| RR | `region.roundRobin ?? 1` |

Root dropdown items contain all MIDI values 0 through 127. Low and High dropdown items contain all MIDI values 0 through 127. Velocity and RR dropdown items contain all integers 1 through 32. Selecting a dropdown item calls the matching selection-scoped cubit method.

Add an `OutlinedButton.icon` below the dropdowns with key `poly-mapping-unmap-selected`, icon `Icons.link_off`, and label text:

| Selection count | Label |
|---:|---|
| 1 | `Unmap sample` |
| 2 or more | `Unmap selected` |

The button calls `cubit.unmapSelectedRegions()`.

Existing `_StepRow` controls remain visible below the dropdown rows. They continue to edit the single `region` shown in the inspector and do not perform bulk edits.

## Toolbar UI rules

In `_Toolbar`:

- The existing `Discard` button label becomes `Discard selected` when `state.selectedPaths.isNotEmpty`; otherwise it remains `Discard`.
- The discard button calls `cubit.discardChanges` exactly as before.
- The popup menu gains a menu item before `remove_selected`:
  - value `unmap_selected`
  - enabled when `state.selectedPaths.isNotEmpty`
  - child text `Unmap selected`
  - action `cubit.unmapSelectedRegions()`
- Rename the existing `Remove selected` menu item text to `Remove selected samples` without changing its value or action.
- `Clear all` remains the only full wipe menu item.

In `PolySamplesEditorView.build`, render the existing warning panel for `state.warnings` as it does now, but pass it storage key value `poly-samples-import-warnings-tile`. Render a second `_WarningPanel(title: 'Mapping warnings', messages: state.mappingWarnings, storageKey: const PageStorageKey<String>('poly-samples-mapping-warnings-tile'))` directly after the existing warning panel when `state.mappingWarnings.isNotEmpty`. `_WarningPanel` must require a `PageStorageKey<String> storageKey` constructor parameter and use that value as the `ExpansionTile.key`; do not reuse the old hard-coded key for both panels.

## Waveform preview rules

### Rendered draft sample preview cache

Add these fields near the note-preview cache fields in the cubit:

```dart
final _samplePreviewCache = <String, String>{};
final _samplePreviewRenderInFlight = <String, Future<String>>{};
```

`_renderedSamplePreviewPath(String path)`:

1. Capture `final generation = _notePreviewGeneration;` at method entry.
2. Reads `File(path).stat()`.
3. Builds a cache key from normalized path, modified milliseconds, size, and `_previewDraftFingerprint(path)`.
4. Returns the cached path when it exists on disk.
5. Returns the in-flight future when one exists for the same key.
6. Reads bytes from `File(path)`.
7. After every `await`, if `generation != _notePreviewGeneration || _isClosing`, throw `_StaleNotePreviewRequest()`.
8. Runs `_preparedKeyboardPreviewBytes(path, bytes)`.
9. Creates temp root `nt_helper_poly_sample_preview_`.
10. If stale after creating the temp root, delete that root with `_deleteNotePreviewRoot(root.path)` before throwing `_StaleNotePreviewRequest()`.
11. Writes `sample-preview.wav` in the temp root.
12. Stores the temp root in `_notePreviewRoots` so existing cleanup removes it.
13. If stale after writing, remove the temp root from `_notePreviewRoots`, delete it, and throw `_StaleNotePreviewRequest()`.
14. Stores the output path in `_samplePreviewCache[cacheKey]`.
15. Removes the in-flight entry in `whenComplete` only when the stored future is identical to the completed future.

`_cleanupNotePreviewRoots()` also clears `_samplePreviewCache` and `_samplePreviewRenderInFlight` alongside the existing note preview caches.

Local WAV `playOrStopPreview(path)` behavior:

| State | Behavior |
|---|---|
| No loop draft and no wav edit draft for `path` | Existing raw-file `playOrStopPreview(path, gainDb: state.previewGainDb)` behavior |
| A loop draft or wav edit draft exists for `path`, preview visible path already equals `path` | Stop preview through `_previewService.stop()` |
| A loop draft or wav edit draft exists for `path`, preview visible path differs | Await `_renderedSamplePreviewPath(path)` and call `_previewService.restartPreview(renderedPath, displayPath: path, sourcePlayback: await _samplePreviewSourcePlayback(path), gainDb: state.previewGainDb)` |

Add private helper `_samplePreviewSourcePlayback(String path)` with the same playback frame logic as `_keyboardPreviewSourcePlayback`, but `pitchRatio: 1` and `playingMidiNote` omitted.

`updateWavEditDraft` must schedule the existing short loop-edit audible preview when all of these are true: the path is a local editable WAV, the file exists, an overview exists, either fade-in frames, fade-out frames, fade curve, fade strength, trim start/end, gain, or normalize value changed, and an active loop is available from `state.loopDrafts[path]` or the overview (`loopStart` and `loopEnd` both non-null). It uses the same 80 ms debounce and stale request integer as loop edits. If no active loop exists, do not schedule an automatic short preview; the visual fade preview plus the full sample Preview button satisfy fade/trim/gain preview for that state. `_playLoopEditPreview` must call `_preparedKeyboardPreviewBytes` before extracting/rendering the short loop preview so audible preview includes fades and trim/gain edits.

### Fade curves on waveform

Add to `wav_metadata.dart`:

```dart
class WavFadeCurvePoint {
  const WavFadeCurvePoint({required this.x, required this.gain});

  final double x;
  final double gain;
}

class WavFadePreview {
  const WavFadePreview._();

  static List<WavFadeCurvePoint> sampleCurve({
    required WavFadeCurve curve,
    required double strength,
    int sampleCount = 17,
  }) { ... }
}
```

`sampleCurve` returns exactly `sampleCount` points. `sampleCount <= 1` returns two points at x/gain `(0, 0)` and `(1, 1)`. For normal counts, x is `index / (sampleCount - 1)` and gain is `WavFadeShaper.apply(x, curve, strength: strength)`.

Add optional constructor parameters to `PolyWaveformEditor` with these defaults:

```dart
this.fadeInFrames = 0,
this.fadeOutFrames = 0,
this.fadeInCurve = WavFadeCurve.linear,
this.fadeOutCurve = WavFadeCurve.linear,
this.fadeInStrength = 0.5,
this.fadeOutStrength = 0.5,
```

Pass these values to `_PolyWaveformPainter` and include them in `shouldRepaint`.

Painter behavior:

- When `fadeInFrames > 0`, draw a curve from `startFrame` to `min(endFrame, startFrame + fadeInFrames)` using `colorScheme.secondary` and stroke width 2.
- When `fadeOutFrames > 0`, draw a curve from `max(startFrame, endFrame - fadeOutFrames)` to `endFrame` using `colorScheme.secondary` and stroke width 2.
- Fade-in y maps gain `0` to bottom and gain `1` to top within the waveform height.
- Fade-out y maps gain `1` to top at the start of the fade and gain `0` to bottom at the end.
- Draw a translucent secondary rectangle under each fade region with alpha `0.10`.

Add a `Semantics` child or label in `PolyWaveformEditor.build` with this exact text when either fade is active:

`Fade preview: fade in <fadeInFrames> frames using <fadeInCurve.name>, fade out <fadeOutFrames> frames using <fadeOutCurve.name>.`

When both fade lengths are zero, no fade preview semantics is emitted.

`_WaveformSection` passes `wavDraft.fadeInFrames`, `wavDraft.fadeOutFrames`, `wavDraft.fadeInCurve`, `wavDraft.fadeOutCurve`, `wavDraft.fadeInStrength`, and `wavDraft.fadeOutStrength` into `PolyWaveformEditor`.

## Hardening matrix

| Risk | Plausible path | Chosen handling | Tests required |
|---|---|---|---|
| Active sample row jumps after root edit | User changes root from row stepper or inspector and `_replaceEditedRegions` sorts by root | Remove edit-time sorting and assert order remains unchanged after root/range/velocity/RR edits | Cubit test for unchanged path order after mapping edits |
| Overlapping mapping silently changes row order | User creates same velocity/RR overlap to audition mapping | Preserve order and show deterministic `Mapping warnings` panel | Cubit warning test and editor warning panel test |
| Legitimate RR/velocity overlaps falsely warn | User layers velocity or round-robin samples over same key range | Warning comparison skips different velocity or different RR | Cubit test covering no warning for different velocity and different RR |
| Selection-scoped discard deletes all edits | User selects two samples and taps Discard expecting selected reset | `discardChanges` resets selected rows only when selection exists; full discard only when no selection exists | Cubit tests for selected reset and no-selection full reset; toolbar label test |
| Selective unmap accidentally removes sample rows | User selects samples and taps Unmap selected | `unmapSelectedRegions` clears mapping fields and preserves row count/order | Cubit and inspector tests |
| Bulk dropdown edit mutates wrong rows | User multi-selects non-contiguous rows and assigns root/velocity/RR | Cubit updates only selected paths; tests assert non-selected row unchanged | Cubit and inspector tests |
| Mixed multi-selection displays misleading value | User selects samples with different roots | Dropdown value is null and hint is `Mixed` | Inspector widget test |
| Root list omits note values | User needs direct root assignment from list | Root dropdown has 128 note items from MIDI 0 through 127 | Inspector widget test opens dropdown and taps a note |
| Async waveform load completes after selection changes | Existing `loadWaveform` stale guards already check path and request state | Keep existing behavior; no new state path changes it | Existing waveform tests plus full suite |
| Loop/fade preview uses stale rendered temp file | User changes fade repeatedly and presses preview | Cache key includes file stat and draft fingerprint; in-flight cache is keyed the same way | Cubit cache invalidation test |
| Repeated preview taps leak temp roots | User previews many edited drafts | Store sample-preview temp roots in `_notePreviewRoots` and reuse existing cleanup | Cubit close cleanup test for rendered sample preview |
| Hardware preview latency returns out of order | User edits mapping while hardware download is pending | Existing hardware preview request guards remain; local draft rendering is not used for hardware paths | Existing hardware preview stale tests plus full suite |
| Fade curve visual duplicates curve math incorrectly | Painter reimplements shape math differently from renderer | Painter uses `WavFadePreview.sampleCurve`, which delegates to `WavFadeShaper.apply` | WAV helper unit tests and waveform repaint test |
| Screen-reader users miss fade preview state | Fade curve is visual canvas only | Add exact fade preview semantics label when fade is active | Waveform semantics test |
| State the app cannot enter: selected path not present in edited regions | Selection set can become stale after row removal | Existing `_replaceEditedRegions` intersects remaining paths; new selected helper ignores absent focused paths | Covered by discard/unmap tests |
| State the app cannot enter: non-WAV local fade draft from UI | Waveform edit section only appears for local/mounted `.wav` paths | Non-WAV draft rendering remains out of scope | Out-of-scope; no test |

## Acceptance criteria

- Editing root, low, high, velocity, or RR never reorders `state.editedRegions`.
- Creating invalid ranges, root-outside-range, or same velocity/RR overlaps shows clear mapping warnings without reordering rows.
- A single selected sample and a multi-selection can receive Root, Low, High, Velocity, and RR values from list controls.
- `Unmap selected` clears mapping from selected samples only and preserves rows.
- `Discard selected` resets selected rows only; `Clear all` remains the explicit full wipe.
- Loop/fade/trim/gain preview playback uses cached rendered preview WAVs for local edited WAV drafts.
- Fade curves are visible on the waveform and announced through semantics when active.
- Verification passes with `flutter analyze && flutter test`.
