# Sample row inline steppers spec

Baseline ref: `HEAD` (`604b8dd4` at spec authoring time)

Hardening policy: realistic-only

Verification command hint: `flutter analyze && flutter test`

## Inventory summary

Inventory was generated with:

```bash
python3 /Users/nealsanche/nosuch/nt_helper/.pi/skills/decision-free-specs/languages/dart/inventory.py \
  lib/ui/poly_multisample/widgets/poly_sample_list.dart \
  lib/ui/poly_multisample/poly_multisample_builder_cubit.dart \
  lib/ui/poly_multisample/widgets/poly_sample_inspector.dart \
  lib/ui/poly_multisample/poly_samples_editor_view.dart \
  test/poly_multisample/widgets/poly_sample_list_test.dart \
  test/poly_multisample/poly_multisample_builder_cubit_test.dart \
  test/poly_multisample/widgets/poly_sample_inspector_test.dart \
  test/poly_multisample/poly_samples_editor_view_test.dart \
  > /tmp/sample_row_steppers_inventory.md
```

Additional model inventory was generated with:

```bash
python3 /Users/nealsanche/nosuch/nt_helper/.pi/skills/decision-free-specs/languages/dart/inventory.py \
  lib/poly_multisample/poly_multisample_models.dart \
  lib/ui/poly_multisample/poly_region_math.dart \
  > /tmp/sample_row_steppers_models_inventory.md
```

Preview-service inventory was generated with:

```bash
python3 /Users/nealsanche/nosuch/nt_helper/.pi/skills/decision-free-specs/languages/dart/inventory.py \
  lib/poly_multisample/poly_audio_preview_service.dart \
  > /tmp/preview_inventory.md
```

Hand check completed for `lib/ui/poly_multisample/widgets/poly_sample_list.dart`: the inventory declaration list matches the file structure around `PolySampleList`, `_PolySampleListState`, `_itemExtent`, `_selectionMode`, `_scheduleFocusScroll`, and `build`.

Relevant inventory facts:

| File | Size | Relevant declarations | Imported by |
|---|---:|---|---|
| `lib/ui/poly_multisample/widgets/poly_sample_list.dart` | 142 lines | `PolySampleList`, `_PolySampleListState` | `lib/ui/poly_multisample/poly_samples_editor_view.dart`, `test/poly_multisample/poly_samples_editor_view_test.dart`, `test/poly_multisample/widgets/poly_sample_list_test.dart` |
| `lib/ui/poly_multisample/poly_multisample_builder_cubit.dart` | 1512 lines | `PolyMultisampleBuilderState`, `PolyMultisampleBuilderCubit`, update methods, preview methods | poly multisample UI, dialogs, and tests |
| `lib/ui/poly_multisample/poly_samples_editor_view.dart` | 316 lines | `PolySamplesEditorView`, `_EditorBody` | `lib/ui/poly_multisample/poly_samples_screen.dart`, `test/poly_multisample/poly_samples_editor_view_test.dart` |
| `lib/ui/poly_multisample/widgets/poly_sample_inspector.dart` | 794 lines | `PolySampleInspector`, `_MappingSection`, `_StepRow` | `lib/ui/poly_multisample/poly_samples_editor_view.dart`, inspector tests |
| `lib/poly_multisample/poly_multisample_models.dart` | 324 lines | `PolySampleRegion`, `currentIssues`, `copyWith` | parser, services, poly multisample UI and tests |
| `lib/ui/poly_multisample/poly_region_math.dart` | 105 lines | `effectiveLow`, `effectiveHigh`, `velocityLanes`, `selectedRegionFor`, `sampleDisplayLabel` | key map, sample list, inspector, tests |
| `lib/poly_multisample/poly_audio_preview_service.dart` | 134 lines | `PolyAudioPreviewService.playOrStopPreview`, `stop` | cubit and preview tests |
| `test/poly_multisample/widgets/poly_sample_list_test.dart` | 162 lines | sample-list widget tests | no imports |
| `test/poly_multisample/poly_multisample_builder_cubit_test.dart` | 1841 lines | cubit integration/unit tests and fake preview adapter | no imports |
| `test/poly_multisample/poly_samples_editor_view_test.dart` | 234 lines | editor widget tests and `_TestPolyMultisampleBuilderCubit` | no imports |
| `test/poly_multisample/widgets/poly_sample_inspector_test.dart` | 443 lines | inspector widget tests | no imports |

## Architecture

Add compact inline mapping steppers to every sample row in `PolySampleList`. The sample list remains a `StatefulWidget` in the same file. The row uses the existing `sampleDisplayLabel`, `effectiveLow`, `effectiveHigh`, and `PolyMultisampleParser.midiToNoteName` helpers, so it displays the same mapping values as the sidebar.

The cubit owns all mapping mutations, clamp rules, focus synchronization, dirty-state updates, and auto-preview side effects. The row widget only computes next values for button taps and forwards them through callbacks. The sidebar continues to expose the same mapping controls and also gains mapping-edit auto-preview through the same cubit methods.

No parser, apply-service, filesystem, hardware service, waveform editor, key map, route, or database changes are part of this program.

### Target file tree

| Path | Action |
|---|---|
| `lib/ui/poly_multisample/poly_multisample_builder_cubit.dart` | Clamp mapping edits, add focus option, add mapping-edit auto-preview helper |
| `test/poly_multisample/poly_multisample_builder_cubit_test.dart` | Add clamp, focus, and auto-preview tests |
| `lib/ui/poly_multisample/widgets/poly_sample_list.dart` | Add inline stepper row UI and callback parameters |
| `test/poly_multisample/widgets/poly_sample_list_test.dart` | Update constructor calls and add inline stepper/a11y tests |
| `lib/ui/poly_multisample/poly_samples_editor_view.dart` | Wire row callbacks to cubit update methods with manager and focus synchronization |
| `test/poly_multisample/poly_samples_editor_view_test.dart` | Add editor integration test for row stepper selection/sidebar sync |
| `lib/ui/poly_multisample/widgets/poly_sample_inspector.dart` | Pass manager through sidebar mapping update calls |
| `test/poly_multisample/widgets/poly_sample_inspector_test.dart` | Verify sidebar mapping edit triggers auto-preview when enabled |
| `specs/README.md` | Program table row added by this spec authoring commit |

### Symbol map

| Symbol | Current location | Destination after implementation | Exported | Notes |
|---|---|---|---|---|
| `PolySampleList` | `lib/ui/poly_multisample/widgets/poly_sample_list.dart` | same file | yes | Constructor gains five required mapping-update callbacks |
| `_PolySampleListState` | `lib/ui/poly_multisample/widgets/poly_sample_list.dart` | same file | no | Build method renders inline steppers |
| `_InlineSampleStepper` | new symbol | `lib/ui/poly_multisample/widgets/poly_sample_list.dart` | no | Private compact chip used only in sample rows |
| `_clampMidi` | new symbol | `lib/ui/poly_multisample/widgets/poly_sample_list.dart` | no | Private UI-side MIDI boundary helper |
| `PolyMultisampleBuilderCubit.updateRoot` | `lib/ui/poly_multisample/poly_multisample_builder_cubit.dart` | same file | yes | Add optional `manager` and `focusRegion` named parameters |
| `PolyMultisampleBuilderCubit.updateRangeLow` | `lib/ui/poly_multisample/poly_multisample_builder_cubit.dart` | same file | yes | Add optional `manager` and `focusRegion` named parameters |
| `PolyMultisampleBuilderCubit.updateRangeHigh` | `lib/ui/poly_multisample/poly_multisample_builder_cubit.dart` | same file | yes | Add optional `manager` and `focusRegion` named parameters |
| `PolyMultisampleBuilderCubit.updateVelocity` | `lib/ui/poly_multisample/poly_multisample_builder_cubit.dart` | same file | yes | Add optional `manager` and `focusRegion` named parameters |
| `PolyMultisampleBuilderCubit.updateRoundRobin` | `lib/ui/poly_multisample/poly_multisample_builder_cubit.dart` | same file | yes | Add optional `manager` and `focusRegion` named parameters |
| `_mappingPreviewRequest` | new symbol | `lib/ui/poly_multisample/poly_multisample_builder_cubit.dart` | no | Private serial token for mapping-edit preview requests |
| `_autoPreviewMappingEdit` | new symbol | `lib/ui/poly_multisample/poly_multisample_builder_cubit.dart` | no | Private synchronous gate for mapping-edit preview |
| `_restartPreviewForMappingEdit` | new symbol | `lib/ui/poly_multisample/poly_multisample_builder_cubit.dart` | no | Private async preview restart with stale-request guard |
| `_updateRegion` | `lib/ui/poly_multisample/poly_multisample_builder_cubit.dart` | same file | no | Return `bool` and accept focus/selection overrides |
| `_replaceEditedRegions` | `lib/ui/poly_multisample/poly_multisample_builder_cubit.dart` | same file | no | Accept `focusedPathOverride` |
| `_MappingSection` | `lib/ui/poly_multisample/widgets/poly_sample_inspector.dart` | same file | no | Constructor gains `manager` and forwards it to cubit updates |

No compatibility re-export is needed because no public symbol moves to a different file.

## Public and private API changes

### `PolySampleList` constructor

Replace the constructor with this required-parameter set:

```dart
const PolySampleList({
  super.key,
  required this.regions,
  required this.selectedPaths,
  required this.focusedPath,
  required this.previewVisiblePath,
  required this.onSelect,
  required this.onPreview,
  required this.onUpdateRoot,
  required this.onUpdateRangeLow,
  required this.onUpdateRangeHigh,
  required this.onUpdateVelocity,
  required this.onUpdateRoundRobin,
});
```

Add fields:

```dart
final void Function(String path, int midi) onUpdateRoot;
final void Function(String path, int midi) onUpdateRangeLow;
final void Function(String path, int midi) onUpdateRangeHigh;
final void Function(String path, int layer) onUpdateVelocity;
final void Function(String path, int lane) onUpdateRoundRobin;
```

### Cubit mapping update signatures

Use these signatures exactly:

```dart
void updateRoot(
  String path,
  int midi, {
  IDistingMidiManager? manager,
  bool focusRegion = false,
})

void updateRangeLow(
  String path,
  int midi, {
  IDistingMidiManager? manager,
  bool focusRegion = false,
})

void updateRangeHigh(
  String path,
  int midi, {
  IDistingMidiManager? manager,
  bool focusRegion = false,
})

void updateVelocity(
  String path,
  int layer, {
  IDistingMidiManager? manager,
  bool focusRegion = false,
})

void updateRoundRobin(
  String path,
  int lane, {
  IDistingMidiManager? manager,
  bool focusRegion = false,
})
```

Clamp rules inside these cubit methods:

| Method | Clamp |
|---|---|
| `updateRoot` | `midi.clamp(0, 127).toInt()` |
| `updateRangeLow` | `midi.clamp(0, 127).toInt()` |
| `updateRangeHigh` | `midi.clamp(0, 127).toInt()` |
| `updateVelocity` | `math.max(1, layer)` |
| `updateRoundRobin` | `math.max(1, lane)` |

`updateRoot` must set both `rootMidi` and `rootName` from the clamped value. `updateRangeLow` and `updateRangeHigh` must store only the clamped MIDI value. `updateVelocity` and `updateRoundRobin` must store the minimum-1 value.

When `focusRegion` is `true`, the edited path becomes the only selected path and `focusedPath` becomes the edited path in the same state change as the mapping value. When the path is not present in `state.editedRegions`, no state change and no preview occurs.

## Exact row layout

`PolySampleList` keeps a `ListView.builder` and increases `_itemExtent` from `56.0` to `84.0`.

Each item remains a `Semantics` wrapper with `selected: selected`. The label becomes:

```dart
'$label, root $rootLabel, low $lowLabel, high $highLabel, velocity $velocity, RR $roundRobin'
```

`rootLabel` is `region.rootName ?? 'unmapped'`. `lowLabel` and `highLabel` are note names from `effectiveLow` and `effectiveHigh`. `velocity` is `region.velocityLayer ?? 1`. `roundRobin` is `region.roundRobin ?? 1`.

Inside the semantics wrapper, keep `ListTile(dense: true, selected: selected, onTap: ...)`. Use:

- `leading`: the existing mapped/warning icon logic, with `size: 20` added to the `Icon`.
- `title`: `Text(label, maxLines: 1, overflow: TextOverflow.ellipsis)`.
- `subtitle`: a `Wrap(spacing: 4, runSpacing: 4, children: [...])` containing exactly five `_InlineSampleStepper` chips in this order: Root, Low, High, Vel, RR.
- `trailing`: the existing preview `IconButton` logic unchanged except formatting from `dart format`.
- `onTap`: unchanged selection behavior using `_selectionMode()`.

The five chips use these visible labels and values:

| Chip order | Visible label | Value |
|---:|---|---|
| 1 | `Root` | `region.rootMidi == null ? 'Unset' : PolyMultisampleParser.midiToNoteName(root)` |
| 2 | `Low` | `PolyMultisampleParser.midiToNoteName(low)` |
| 3 | `High` | `PolyMultisampleParser.midiToNoteName(high)` |
| 4 | `Vel` | `'$velocity'` |
| 5 | `RR` | `'$roundRobin'` |

The row uses `root = region.rootMidi ?? 60`, `low = effectiveLow(region)`, `high = effectiveHigh(region, widget.regions)`, `velocity = region.velocityLayer ?? 1`, and `roundRobin = region.roundRobin ?? 1`.

### `_InlineSampleStepper` widget

Add `_InlineSampleStepper` in `poly_sample_list.dart` below `_PolySampleListState`.

Constructor:

```dart
const _InlineSampleStepper({
  required this.label,
  required this.value,
  required this.sampleLabel,
  required this.onDecrease,
  required this.onIncrease,
});

final String label;
final String value;
final String sampleLabel;
final VoidCallback onDecrease;
final VoidCallback onIncrease;
```

Build tree:

```dart
Semantics(
  container: true,
  label: '$label $value for $sampleLabel',
  child: DecoratedBox(
    decoration: BoxDecoration(
      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      borderRadius: BorderRadius.circular(999),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _inlineIconButton(...decrease...),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text('$label $value', style: Theme.of(context).textTheme.labelSmall),
          ),
          _inlineIconButton(...increase...),
        ],
      ),
    ),
  ),
)
```

The decrease button uses tooltip `Decrease $label for $sampleLabel`, `Icons.remove`, and `onDecrease`. The increase button uses tooltip `Increase $label for $sampleLabel`, `Icons.add`, and `onIncrease`. Both buttons use `visualDensity: VisualDensity.compact`, `padding: EdgeInsets.zero`, `constraints: const BoxConstraints.tightFor(width: 24, height: 24)`, and icon size `14`.

Use a private helper method inside `_InlineSampleStepper` named `_button` with parameters `BuildContext context`, `String tooltip`, `IconData icon`, and `VoidCallback onPressed`.

## Inline edit behavior

For every inline chip button tap, the row callback computes the next value, clamps it locally, and calls the matching callback without calling `onSelect` directly. The editor callback calls the cubit method with `focusRegion: true`, which synchronizes selection/focus/sidebar state in the same cubit emit as the value change.

Row step rules:

| Control | Decrease callback | Increase callback |
|---|---|---|
| Root | `widget.onUpdateRoot(region.path, _clampMidi(root - 1))` | `widget.onUpdateRoot(region.path, _clampMidi(root + 1))` |
| Low | `widget.onUpdateRangeLow(region.path, _clampMidi(low - 1))` | `widget.onUpdateRangeLow(region.path, _clampMidi(low + 1))` |
| High | `widget.onUpdateRangeHigh(region.path, _clampMidi(high - 1))` | `widget.onUpdateRangeHigh(region.path, _clampMidi(high + 1))` |
| Vel | `widget.onUpdateVelocity(region.path, math.max(1, velocity - 1))` | `widget.onUpdateVelocity(region.path, velocity + 1)` |
| RR | `widget.onUpdateRoundRobin(region.path, math.max(1, roundRobin - 1))` | `widget.onUpdateRoundRobin(region.path, roundRobin + 1)` |

Add `import 'dart:math' as math;` and `import 'package:nt_helper/poly_multisample/poly_multisample_parser.dart';` to `poly_sample_list.dart`.

## Editor and sidebar wiring

In `_EditorBody`, pass these callbacks to `PolySampleList`:

```dart
onUpdateRoot: (path, midi) => cubit.updateRoot(
  path,
  midi,
  manager: manager,
  focusRegion: true,
),
onUpdateRangeLow: (path, midi) => cubit.updateRangeLow(
  path,
  midi,
  manager: manager,
  focusRegion: true,
),
onUpdateRangeHigh: (path, midi) => cubit.updateRangeHigh(
  path,
  midi,
  manager: manager,
  focusRegion: true,
),
onUpdateVelocity: (path, layer) => cubit.updateVelocity(
  path,
  layer,
  manager: manager,
  focusRegion: true,
),
onUpdateRoundRobin: (path, lane) => cubit.updateRoundRobin(
  path,
  lane,
  manager: manager,
  focusRegion: true,
),
```

In `PolySampleInspector`, pass `manager` into `_MappingSection`. Add `final IDistingMidiManager? manager;` to `_MappingSection`, and pass `manager: manager` on every mapping update call. Do not set `focusRegion: true` in the sidebar because the sidebar already edits the selected region.

## Auto-preview behavior

Mapping edits to Root, Low, High, Vel, and RR are musical mapping edits. When `state.autoPreview` is `true`, every successful mapping edit previews the edited sample path when the path ends with `.wav`. When the edited path is not a `.wav`, mapping-edit preview stops any visible preview and does not emit an error.

Preview restart behavior:

1. Add private field `int _mappingPreviewRequest = 0;` to `PolyMultisampleBuilderCubit` near `_contentRevision`.
2. Every successful mapping edit calls `_autoPreviewMappingEdit(path, manager: manager)` after `_updateRegion` returns `true`.
3. `_autoPreviewMappingEdit` returns immediately when `state.autoPreview` is `false`.
4. `_autoPreviewMappingEdit` stops preview for non-wav paths when `state.previewState.visiblePath != null`.
5. `_autoPreviewMappingEdit` increments `_mappingPreviewRequest` and starts `_restartPreviewForMappingEdit` with `unawaited`.
6. `_restartPreviewForMappingEdit` catches errors and emits `state.copyWith(error: error.toString())`.
7. `_restartPreviewForMappingEdit` resolves hardware paths with `_cachedHardwarePreviewPath(manager, path)` using the same missing-manager error text as `playOrStopPreview`.
8. After any awaited hardware cache operation, `_restartPreviewForMappingEdit` returns without playing when the request id no longer equals `_mappingPreviewRequest` or `_isClosing` is true.
9. Before playing a path whose `visiblePath` already equals the edited path, `_restartPreviewForMappingEdit` awaits `_previewService.stop()` so the next call starts playback instead of toggling it off.
10. Local paths call `_previewService.playOrStopPreview(path, gainDb: state.previewGainDb)`.
11. Hardware paths call `_previewService.playOrStopPreview(localPath, displayPath: path, gainDb: state.previewGainDb)`.

## Accessibility and keyboard behavior

- The row semantics label includes the sample label and all inline mapping values in one scan-friendly sentence.
- Every stepper chip is a semantics container with label `$label $value for $sampleLabel`.
- Every stepper button has a tooltip and therefore an accessible button label: `Decrease Root for Piano_C3.wav`, `Increase Root for Piano_C3.wav`, `Decrease Low for ...`, `Increase High for ...`, `Decrease Vel for ...`, `Increase RR for ...`.
- The row remains selectable by pointer tap through the existing `ListTile.onTap`.
- Keyboard Tab traversal reaches every inline stepper button and the preview button because they are `IconButton`s.
- Keyboard Enter/Space activates the focused stepper or preview button through Flutter's built-in button behavior.
- No custom arrow-key shortcuts are added. Arrow keys remain available to platform scroll views and assistive technologies.
- Decorative duplicate visual content is not added outside the semantics wrappers named above.

## Decision inventory

| Decision | Rationale | Files affected | Status |
|---|---|---|---|
| Add inline controls to every sample row, not only the selected row | The request prioritizes row scanning and fast manipulation | `poly_sample_list.dart`, sample-list tests | required |
| Use five chips in order Root, Low, High, Vel, RR | These match the existing sidebar mapping controls and requested values | `poly_sample_list.dart`, sample-list tests | required |
| Interpret requested velocity range as the existing `velocityLayer` value shown as `Vel`/`Vn` | The current model has `velocityLayer` and `switchPoint`; it has no velocity-low/velocity-high fields | `poly_sample_list.dart`, cubit tests | required |
| Do not add true velocity-low and velocity-high fields | The app cannot persist or apply fields that do not exist in `PolySampleRegion` | none | out-of-scope |
| Keep row height compact at `84.0` | Allows a title line plus one wrapping chip line without a table redesign | `poly_sample_list.dart`, widget tests | required |
| Keep `ListTile` row selection and preview button behavior | Existing selection modes and preview affordance remain stable | `poly_sample_list.dart` | required |
| Add private `_InlineSampleStepper` in `poly_sample_list.dart` rather than depending on `split-stepper-control/` | The reusable split-stepper program is documented but not implemented in this baseline | `poly_sample_list.dart` | required |
| Clamp MIDI edits to 0..127 in both row callbacks and cubit methods | Repeated boundary taps are a plausible user action and current parser note formatting is not valid for negative MIDI values | `poly_sample_list.dart`, cubit, tests | required |
| Clamp velocity and RR to a minimum of 1 in both row callbacks and cubit methods | Repeated boundary taps are a plausible user action and zero lanes are invalid for filenames and mapping semantics | `poly_sample_list.dart`, cubit, tests | required |
| Inline edits focus and single-select the edited row through `focusRegion: true` | The sidebar must immediately show the row just edited | cubit, editor, editor tests | required |
| Sidebar mapping edits do not change selection | The sidebar already edits the selected row and changing selection there has no user benefit | inspector, tests | required |
| Auto-preview runs for successful Root, Low, High, Vel, and RR edits when Auto Preview is enabled | These are musical mapping changes and the user asked to hear feasible impact | cubit, editor, inspector, tests | required |
| Non-wav mapping edits stop preview and do not error | The existing preview UI disables non-wav playback; stopping stale audio is safer than playing unrelated audio | cubit tests | required |
| Hardware mapping preview uses the existing cached hardware preview path flow and manager parameter | Hardware preview already requires a manager and local cache path | cubit, editor, inspector | required |
| Add stale-request guard for mapping auto-preview | Hardware preview cache/download latency can complete out of order during rapid stepping | cubit, tests | required |
| Do not add file renaming, automatic range repair, or cross-row overlap correction | The request is inline manipulation; persistence/renaming remains in existing Apply flow | none | out-of-scope |
| Do not add success snackbars or debug logging | Repo rules prohibit debug logging and discourage success snackbars | all touched files | required |

## Hardening matrix

| Risk | Plausible path | Chosen handling | Tests required |
|---|---|---|---|
| MIDI value goes below 0 or above 127 | User repeatedly taps Root/Low/High minus or plus at a boundary | Clamp in row and cubit before storing or formatting note names | `poly_sample_list_test.dart` boundary test; `poly_multisample_builder_cubit_test.dart` clamp test |
| Velocity or RR reaches 0 | User repeatedly taps Vel/RR minus | Clamp to minimum 1 in row and cubit | `poly_sample_list_test.dart` boundary test; `poly_multisample_builder_cubit_test.dart` clamp test |
| Sidebar shows a different sample after inline edit | User taps a stepper on a non-selected row | Editor callbacks pass `focusRegion: true`; cubit selects and focuses edited path in the same emit | `poly_samples_editor_view_test.dart` inline row stepper focus test |
| Auto-preview toggles off instead of replaying the edited sample | User edits the same row while it is already previewing | Mapping preview helper stops the current same-path preview before starting it again | `poly_multisample_builder_cubit_test.dart` auto-preview restart test |
| Stale hardware preview plays after a later step | User rapidly taps steppers while hardware cache/download is delayed | `_mappingPreviewRequest` token suppresses stale async playback after awaited cache work | `poly_multisample_builder_cubit_test.dart` stale mapping-preview request test |
| Non-wav stale preview continues after editing a non-wav row | User edits an AIF row while a WAV preview is audible | Mapping edit preview stops current preview and does not start non-wav playback | `poly_multisample_builder_cubit_test.dart` non-wav stop test |
| Button semantics are too noisy or missing labels | Screen reader user tabs through a sample row | Row summary plus per-chip container labels and per-button tooltips | `poly_sample_list_test.dart` semantics/tooltip test |
| Row becomes too tall or visually noisy | A folder has many samples and every row renders controls | Fixed `84.0` extent, compact 24x24 buttons, one Wrap line with wrapping only under narrow widths | `poly_sample_list_test.dart` renders chip labels test |
| File rename or data corruption during inline edits | User changes Root/RR values in the list | No filesystem write occurs until existing Apply flow; this feature edits in-memory `editedRegions` only | Existing apply tests plus new cubit dirty/focus tests |
| Range-low greater than range-high | User increments Low beyond High or decrements High below Low | Existing app already permits explicit range values; automatic repair can change user intent and file output | out-of-scope; no test |

## Acceptance criteria

- Sample rows show inline compact steppers for Root, Low, High, Vel, and RR.
- The row remains scannable: sample name is one line, mapping controls are compact chips, preview remains at the trailing edge.
- Inline steppers update the same cubit fields as the sidebar.
- Inline steppers select/focus the edited row so the sidebar immediately reflects that row.
- Sidebar mapping edits and inline mapping edits use the same clamp and auto-preview behavior.
- Auto Preview replays feasible `.wav` sample previews after Root, Low, High, Vel, and RR edits.
- Non-wav mapping edits do not attempt unsupported playback.
- Widget semantics expose the row summary and every stepper button label.
- `flutter analyze` reports no issues.
- Named tests in `plan.md` pass.
