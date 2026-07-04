# Poly Samples UI — standalone screen with fork feature parity

## Context

The multisample ("Samples") editor was ported from the fork at
`/tmp/nt_helper_nymph_next_fix.4a28r5/repo` (branch UI: 8 `part` files,
~10,700 lines, setState-based). This repo has the well-tested cubit/service
port (`PolyMultisampleBuilderCubit` + `lib/poly_multisample/` services, all
green under `test/poly_multisample/`), but the UI
(`lib/ui/poly_multisample/poly_multisample_builder_screen.dart`, 1133 lines)
covers only a fraction of the fork's features, and it is embedded as a third
`EditMode` inside `SynchronizedScreen`'s IndexedStack, where mode switching is
broken and there is no real "back".

This program rebuilds the UI as a **standalone pushed screen** (same
navigation pattern as `PluginGalleryScreen`) with **feature parity to the
fork** but a calmer, progressive-disclosure layout, and removes
`EditMode.samples` from `SynchronizedScreen` entirely.

## Architectural decisions (all made — do not revisit)

1. **Standalone screen.** `PolySamplesScreen` is pushed with
   `Navigator.push(context, MaterialPageRoute(...))` from a new `Samples`
   icon button in `SynchronizedScreen`'s bottom app bar quick-action row
   (desktop only, like today's Samples mode). The screen owns a `Scaffold`
   with an `AppBar` titled `'Samples'`; the framework back button pops it.
   `EditMode.samples` and everything that supported it is deleted.
2. **Keep `PolyMultisampleBuilderCubit` as the single source of truth.** It
   is extended additively (new optional constructor params, new methods, new
   model fields). No existing method signature changes. All existing tests in
   `test/poly_multisample/` keep passing untouched through every step except
   where a step explicitly names them.
3. **The screen receives the `DistingCubit`** (`required DistingCubit
   distingCubit`) and calls `distingCubit.disting()` (returns
   `IDistingMidiManager?`) at each call site that needs a manager — never a
   captured manager instance.
4. **Progressive disclosure over the fork's wall-of-controls.** The sample
   list shows information only; ALL per-sample editing (root/low/high/
   velocity/round-robin steppers, loop points, destructive audio edit) lives
   in a single inspector panel for the selected sample, with 'Loop points'
   and 'Edit audio' as initially-collapsed `ExpansionTile`s. This is the key
   accessibility/overwhelm fix and is intentional — do not put steppers back
   on list rows.
5. **Copy, don't move, from the old screen file.** New widgets that reuse
   logic from `poly_multisample_builder_screen.dart` (keyboard painter,
   region math) receive **copies** with public names. The old file stays
   byte-identical until step 14 deletes it. Temporary duplication between
   steps 4–13 is accepted by decision.
6. **Dirty guard on pop.** `PopScope` asks for confirmation when leaving with
   unsaved work. "Unsaved work" is exactly:
   `state.isDirty || ((state.sourceMode == PolySampleSourceMode.importDraft || state.sourceMode == PolySampleSourceMode.customDraft) && state.editedRegions.isNotEmpty)`.
7. **Import dialogs are powered by the existing import cubits.**
   `PolyLooseWavImportCubit` is used as-is. `PolyDecentImportCubit` is
   extended to the full `DecentSamplerConvertOptions` surface. Each dialog
   returns a `PolyStagedImport?`; the caller hands it to the builder cubit
   (`adoptStagedImport` for a fresh draft, `addStagedRegions` to merge into
   the current instrument).

### Negative decisions (recorded so the executor does not invent them)

- **No Strategy registry, no new cubits.** The two import cubits and the
  builder cubit are the complete cubit set.
- **No inline steppers on sample list rows** (see decision 4).
- **No waveform zoom.** The waveform editor is fixed-scale with drag handles
  plus ±1/±100 frame nudge buttons. The fork's zoomable editor is not ported.
- **"Save As" of an edited WAV exports a file only** — it does not add the
  exported file back into the instrument (the fork did; users can use
  'Add files' afterwards).
- **The fork's "Copy to…" action is dropped** — `saveCustomDraft` ("Save
  As…") covers it.
- **No per-group audio preview inside the Decent dialog beyond a single
  play/stop button per row**, enabled only when
  `previewSourcePath != null && previewSourcePath!.toLowerCase().endsWith('.wav')`.
- **Failure states show the landing/current body plus the error snackbar**
  (already emitted by the listener). No dedicated full-screen error view.
- **Navigation entry point is the bottom app bar only.** No app-bar overflow
  menu item, no keyboard shortcut for Samples.
- **`_cachedSampleBuilder`-style caching (fork) is not recreated** — the
  screen is a pushed route; its cubit lives and dies with the route.

## Source material (read-only references)

| What | Where |
|---|---|
| Fork UI (feature checklist source) | `/tmp/nt_helper_nymph_next_fix.4a28r5/repo/lib/ui/poly_multisample/` |
| Current screen (to be replaced) | `lib/ui/poly_multisample/poly_multisample_builder_screen.dart` |
| Builder cubit (extend) | `lib/ui/poly_multisample/poly_multisample_builder_cubit.dart` |
| Import cubits | `lib/ui/poly_multisample/poly_decent_import_cubit.dart`, `poly_loose_wav_import_cubit.dart` |
| Models/services | `lib/poly_multisample/` (all files) |
| Navigation host | `lib/ui/synchronized_screen.dart` |
| Pushed-screen pattern | `lib/ui/plugin_gallery_screen.dart` |

## Target file tree

```
lib/ui/poly_multisample/
  poly_multisample_builder_cubit.dart      (extended, steps 1–3)
  poly_decent_import_cubit.dart            (extended, step 5)
  poly_loose_wav_import_cubit.dart         (unchanged)
  poly_region_math.dart                    (NEW, step 4)
  poly_samples_screen.dart                 (NEW, step 13)
  poly_samples_landing_view.dart           (NEW, step 12)
  poly_samples_editor_view.dart            (NEW, step 12)
  widgets/poly_key_map.dart                (NEW, step 6)
  widgets/poly_sample_list.dart            (NEW, step 7)
  widgets/poly_sample_inspector.dart       (NEW, step 8, extended step 9)
  widgets/poly_waveform_editor.dart        (NEW, step 9)
  dialogs/poly_loose_wav_import_dialog.dart (NEW, step 10)
  dialogs/poly_decent_import_dialog.dart   (NEW, step 11)
  poly_multisample_builder_screen.dart     (DELETED, step 14)

lib/poly_multisample/
  poly_multisample_models.dart             (extended, step 1: PolyWaveformDraft fields)

test/poly_multisample/
  poly_multisample_builder_cubit_test.dart (extended, steps 1–3)
  poly_decent_import_cubit_test.dart       (extended, step 5)
  poly_region_math_test.dart               (NEW, step 4)
  widgets/poly_key_map_test.dart           (NEW, step 6)
  widgets/poly_sample_list_test.dart       (NEW, step 7)
  widgets/poly_sample_inspector_test.dart  (NEW, step 8, extended step 9)
  widgets/poly_waveform_editor_test.dart   (NEW, step 9)
  dialogs/poly_loose_wav_import_dialog_test.dart (NEW, step 10)
  dialogs/poly_decent_import_dialog_test.dart    (NEW, step 11)
  poly_samples_editor_view_test.dart       (NEW, step 12)
  poly_samples_screen_test.dart            (NEW, step 13)
  poly_multisample_builder_screen_test.dart (DELETED, step 14 — a11y tests are
                                            re-homed into poly_samples_screen_test.dart in step 13)

test/ui/
  synchronized_screen_bottom_bar_test.dart (edited, step 14)
```

## Feature-parity checklist (fork → new home)

| Fork feature | New home |
|---|---|
| NT SD folder browse + load | Landing → hardware folder list (cubit `loadHardwareFolderList`/`loadHardwareFolder`) |
| Local folder open (+ scan progress, large-folder guard) | Landing card + cubit `loadLocalFolder` (already implemented) |
| Import loose WAVs w/ quick mapping (5 modes + start note) | `poly_loose_wav_import_dialog.dart` |
| Import folder (Decent detection) | `_addFolder` flow in editor view + landing import flow |
| Decent Sampler import: preset selection, 7 handling modes, per-group/tag ranges + velocity + RR, preserve-XML, add-unmapped, per-row preview | `poly_decent_import_dialog.dart` + extended `PolyDecentImportCubit` |
| Custom draft: start empty, add files, add folder, clear all, remove selected, Save As (+ build report) | Editor toolbar + cubit (`startEmptyDraft`, `addStagedRegions`, `clearDraft`, `removeSelectedRegions`, `saveCustomDraft`) |
| Apply/discard to local folder and NT hardware | Editor toolbar (`applyChanges`, `discardChanges`) |
| Multi-lane keyboard map, tap-select, h-scroll, auto-scroll-to-focus | `poly_key_map.dart` |
| Sample list, multi-select (click/ctrl/shift), scroll-to-selection | `poly_sample_list.dart` |
| Root/low/high/velocity/RR editing | Inspector 'Mapping' section |
| Audio preview (incl. hardware download+cache), gain, auto-preview | Inspector header row (cubit `playOrStopPreview`, `setPreviewGain`, `setAutoPreview`) |
| Loop metadata: view/enable/drag/nudge/save/remove | Inspector 'Loop points' section (cubit loop draft + `saveLoopMetadata`) |
| Destructive WAV edit: trim, fades (curve+strength), gain, normalize, save/save-as w/ overwrite confirm | Inspector 'Edit audio' section + `poly_waveform_editor.dart` (step 1 extends draft model) |
| Reveal sample folder in OS file manager | Inspector overflow icon (local paths only) |
| Prev/next sample navigation | Inspector header chevrons |
| Stats (files/mapped/vel layers/warnings) + dirty chip | Editor toolbar |
| Remembered folders (local/source/import-output/custom-output/wav-export) | Step 2 wires `PolySamplePreferencesService` into the cubit; pickers pass `initialDirectory` |
| Accessibility announcements (effect/error, no stale re-announce) | `PolySamplesScreen` BlocConsumer — same `effectId` logic as the current screen, verbatim |

## Interface tables

### Step 1 — `PolyWaveformDraft` new fields (`lib/poly_multisample/poly_multisample_models.dart`)

Add to the existing class (constructor: optional named, with these defaults):

| Field | Type | Default |
|---|---|---|
| `fadeInCurve` | `WavFadeCurve` | `WavFadeCurve.linear` |
| `fadeOutCurve` | `WavFadeCurve` | `WavFadeCurve.linear` |
| `fadeInStrength` | `double` | `0.5` |
| `fadeOutStrength` | `double` | `0.5` |

Requires `import 'wav_metadata.dart';` in the models file. Also add a
`copyWith` to `PolyWaveformDraft` covering **all twelve** fields, with
`bool clearLoopStart = false, clearLoopEnd = false, clearTrimStart = false,
clearTrimEnd = false, clearNormalize = false` flags for the five nullable
fields (`loopStart`, `loopEnd`, `trimStart`, `trimEnd`, `normalizePeakDb`).

In `PolyMultisampleBuilderCubit.saveDestructiveWav`, extend the
`WavRenderOptions(...)` construction with
`fadeInCurve: draft.fadeInCurve, fadeOutCurve: draft.fadeOutCurve,
fadeInStrength: draft.fadeInStrength, fadeOutStrength: draft.fadeOutStrength,`.

### Step 2 — preferences wiring (`PolyMultisampleBuilderCubit`)

- New optional constructor param `PolySamplePreferencesService? preferencesService`
  stored as `PolySamplePreferencesService? _preferencesService`.
- New private `Future<PolySamplePreferencesService> _prefs()` — returns
  `_preferencesService ??= await PolySamplePreferencesService.create()`
  (memoize; guard with a local since `??=` on an awaited value needs a temp).
- In the constructor body, call `unawaited(_loadPreferences());` where
  `_loadPreferences` reads the five getters and emits them into the five
  matching state fields (only emit non-null values, using `copyWith`).
  Import `dart:async` is already present.
- `loadLocalFolder` additionally calls
  `unawaited(_prefs().then((s) => s.setLastLocalFolder(path)))`.
- `saveCustomDraft` additionally persists `setLastCustomOutputFolder(outputFolder)`.
- `saveDestructiveWav` additionally persists
  `setLastWavExportFolder(p.dirname(targetPath))`.
- New public methods `Future<void> rememberSourceFolder(String path)` and
  `Future<void> rememberImportOutputFolder(String path)` — each persists via
  the service AND emits the matching state field.

### Step 3 — staged-import adoption (`PolyMultisampleBuilderCubit`)

```dart
Future<void> adoptStagedImport(PolyStagedImport staged)
```
Exactly the tail of `_stageImport` after a successful `stage()` call:
`await _replaceOwnedTempRoots(staged.tempRoots);` then `_setInstrument(...)`
with the identical `PolySampleInstrument` construction, `sourceMode:
PolySampleSourceMode.importDraft`, `warnings: staged.warnings`. Refactor
`_stageImport` to call `adoptStagedImport` so the logic exists once.

```dart
Future<void> addStagedRegions(PolyStagedImport staged)
```
- No-op (`return`) when `state.currentInstrument == null`.
- `_ownedTempRoots.addAll(staged.tempRoots);` (additive — do NOT call
  `_replaceOwnedTempRoots`).
- Merge: `final existing = state.editedRegions.map((r) => r.path).toSet();`
  new list = `[...state.editedRegions, ...staged.regions.where((r) => !existing.contains(r.path))]`.
- Call `_replaceEditedRegions(next)` then, if `staged.warnings.isNotEmpty`,
  `emit(state.copyWith(warnings: [...state.warnings, ...staged.warnings]))`.

### Step 4 — `lib/ui/poly_multisample/poly_region_math.dart`

Public copies (verbatim bodies, renamed) of the private helpers currently at
the bottom of `poly_multisample_builder_screen.dart`:

| New public symbol | Copied from (old private) |
|---|---|
| `int effectiveLow(PolySampleRegion region)` | `_effectiveLow` |
| `int effectiveHigh(PolySampleRegion region, List<PolySampleRegion> regions)` | `_effectiveHigh` |
| `(int, int)? midiExtents(List<PolySampleRegion> regions)` | `_midiExtents` |
| `List<int> velocityLanes(List<PolySampleRegion> regions)` | `_velocityLanes` |
| `PolySampleRegion? selectedRegionFor(PolyMultisampleBuilderState state)` | `_selectedRegionFor` |

`selectedRegionFor` needs `import 'package:nt_helper/ui/poly_multisample/poly_multisample_builder_cubit.dart';`.
Internal cross-references inside the copied bodies are renamed to the new
public names. The old file is NOT edited.

### Step 5 — `PolyDecentImportCubit` full options

New state fields on `PolyDecentImportState` (constructor defaults shown),
all covered by `copyWith`:

| Field | Type | Default |
|---|---|---|
| `selectedPresetNames` | `Set<String>` | `const {}` |
| `selectedGroupKey` | `String?` | `null` |
| `selectedTagKeys` | `Set<String>` | `const {}` |
| `groupVelocityLayers` | `Map<String, int>` | `const {}` |
| `groupRoundRobins` | `Map<String, int>` | `const {}` |
| `tagKeyRanges` | `Map<String, DecentSamplerTagKeyRange>` | `const {}` |
| `tagVelocityLayers` | `Map<String, int>` | `const {}` |
| `tagRoundRobins` | `Map<String, int>` | `const {}` |
| `preserveXmlMapping` | `bool` | `false` |
| `addUnmapped` | `bool` | `false` |

New cubit methods (each emits via `copyWith` + `clearError: true`; the range
mutators also recompute warnings):

```dart
void togglePreset(String name);
void setSelectedGroup(String? key);
void toggleTag(String key);
void setGroupVelocity(String groupKey, int layer);
void setGroupRoundRobin(String groupKey, int lane);
void setTagRange(String tagKey, DecentSamplerTagKeyRange range);
void setTagVelocity(String tagKey, int layer);
void setTagRoundRobin(String tagKey, int lane);
void setPreserveXmlMapping(bool enabled);
void setAddUnmapped(bool enabled);
```

`analyzeSource` additionally seeds `tagKeyRanges` from `analysis.tags` (same
shape as the existing group seeding, using each tag's `defaultLowMidi/
defaultRootMidi/defaultHighMidi`) and `selectedPresetNames` from
`{for (final preset in analysis.presets) preset.name}`.

Overlap warnings: the existing `_warningsFor` gains tag support — compute
overlap warnings for `groupHandling == DecentSamplerGroupHandling.keyRanges`
(group ranges, existing behavior) and for
`DecentSamplerGroupHandling.selectedTags` (over `tagKeyRanges`, restricted to
keys in `selectedTagKeys`). All other modes: `const []`.

`continueImport` builds the full options object:

```dart
DecentSamplerConvertOptions(
  groupHandling: state.groupHandling,
  selectedPresetNames: state.selectedPresetNames.toList(),
  selectedGroupKey: state.selectedGroupKey,
  selectedTagKeys: state.selectedTagKeys.toList(),
  groupVelocityLayers: state.groupVelocityLayers,
  groupKeyRanges: state.manualGroupRanges,
  groupRoundRobins: state.groupRoundRobins,
  tagVelocityLayers: state.tagVelocityLayers,
  tagKeyRanges: state.tagKeyRanges,
  tagRoundRobins: state.tagRoundRobins,
  preserveXmlMapping: state.preserveXmlMapping,
  addUnmapped: state.addUnmapped,
)
```

### Step 6 — `PolyKeyMap` (`widgets/poly_key_map.dart`)

Stateful widget (needs a `ScrollController`).

| Param | Type |
|---|---|
| `regions` | `List<PolySampleRegion>` (required) |
| `selectedPath` | `String?` (required) |
| `onSelect` | `ValueChanged<PolySampleRegion>` (required) |
| `height` | `double` (default `180`) |

Behavior: horizontal `SingleChildScrollView` whose canvas width is
`math.max(constraints.maxWidth, (maxMidi - minMidi) * 14.0 + 80)`. `minMidi`/
`maxMidi` from `midiExtents` padded ±6 and clamped 0–127 (24/96 when null) —
same arithmetic as the current `_KeyMap`. Painter, layout class, and
tap-hit-testing are **copies** of `_SimpleKeyboardPainter`, `_KeyboardLayout`,
and `_regionAtKeyboardPosition` from the old screen file, renamed
`_PolyKeyMapPainter`, `_PolyKeyMapLayout`, `_regionAtPosition`, and rewired to
the step-4 public math helpers. When `selectedPath` changes
(`didUpdateWidget`), auto-scroll so the selected region's root-note x is
visible (jump to `rootX - viewportWidth / 2`, clamped to scroll extents; skip
when already within the viewport). Mouse-wheel scrolling maps vertical wheel
delta to horizontal offset via a `Listener` `onPointerSignal` (copy the
fork's `_scrollHorizontally` shape from
`/tmp/.../poly_multisample_builder_mapping.dart`, `_KeyMapSectionState`).
Root semantics: `Semantics(container: true, label: 'Keyboard map with
$mappedCount mapped samples')` where `mappedCount` counts regions with
non-null `rootMidi`.

### Step 7 — `PolySampleList` (`widgets/poly_sample_list.dart`)

Stateful widget (`ScrollController` + scroll-to-selection).

| Param | Type |
|---|---|
| `regions` | `List<PolySampleRegion>` (required) |
| `selectedPaths` | `Set<String>` (required) |
| `focusedPath` | `String?` (required) |
| `previewVisiblePath` | `String?` (required) |
| `onSelect` | `void Function(String path, PolyRegionSelectionMode mode)` (required) |
| `onPreview` | `ValueChanged<String>` (required) |

- `ListView.builder` with `itemExtent: 56`.
- Row: `ListTile(dense: true, selected: selectedPaths.contains(region.path))`,
  leading icon `Icons.graphic_eq` when `region.currentIssues.isEmpty` else
  `Icons.warning_amber` (`semanticLabel:` `'Mapped sample'` /
  `'Sample warning'`), title `region.displayName`, subtitle joining with
  `'  '`: `'Root ${region.rootName ?? 'unmapped'}'`, then when non-null
  `'V${region.velocityLayer}'`, `'RR${region.roundRobin}'`, then when issues
  non-empty `'Issues: ${issues.map((i) => i.name).join(', ')}'` (same strings
  as the current `_SampleRegionTile`).
- Trailing preview `IconButton` — play/stop icon by
  `previewVisiblePath == region.path`, tooltip `'Preview sample'` /
  `'Stop preview'`, enabled only when
  `region.path.toLowerCase().endsWith('.wav')`; calls `onPreview(region.path)`.
- Selection mode on tap, computed from
  `HardwareKeyboard.instance.logicalKeysPressed`: shift (`shiftLeft`/
  `shiftRight`) → `PolyRegionSelectionMode.range`; ctrl or meta (`controlLeft`,
  `controlRight`, `metaLeft`, `metaRight`) → `PolyRegionSelectionMode.toggle`;
  otherwise `PolyRegionSelectionMode.replace`.
- Row semantics: wrap the tile in `Semantics(selected: ..., label:
  '${region.displayName}, root ${region.rootName ?? 'unmapped'}')` (same as
  today's tile).
- `didUpdateWidget`: when `focusedPath` changed and non-null, jump the scroll
  offset so `index * 56` is within the viewport (skip when already visible).

### Step 8 — `PolySampleInspector` (`widgets/poly_sample_inspector.dart`)

Stateless. Reads the cubit with `context.read<PolyMultisampleBuilderCubit>()`.

| Param | Type |
|---|---|
| `state` | `PolyMultisampleBuilderState` (required) |
| `manager` | `IDistingMidiManager?` (required) |

Selected region = `selectedRegionFor(state)` (step 4). When null, render
`Center(child: Text('No sample selected'))`.

Layout (a `ListView` with `padding: EdgeInsets.all(12)`):

1. **Header row**: `IconButton` chevron_left / chevron_right (tooltips
   `'Previous sample'` / `'Next sample'`; disabled at list ends; on press
   `cubit.selectRegion(<adjacent region path>, PolyRegionSelectionMode.replace)`),
   `Expanded(Text(region.displayName, style: titleSmall, overflow: ellipsis))`
   wrapped in `Semantics(header: true)`, preview `IconButton.filledTonal`
   (same enable/tooltip rules as list rows; calls
   `cubit.playOrStopPreview(region.path, manager: manager)`), and an
   `IconButton` `Icons.folder_open` tooltip `'Reveal in file manager'` —
   enabled only when `!region.path.startsWith('/')` is **false**… precisely:
   enabled when the path is local, i.e.
   `!(state.sourceMode == PolySampleSourceMode.hardware && region.path.startsWith('/'))`;
   on press run the private helper `_revealFolder` (copy of the fork's
   `_openSampleFolder` Process.run logic: `explorer.exe` on Windows, `open`
   on macOS, `xdg-open` otherwise, on the dirname; failures show a snackbar
   `'Could not open folder: $e'`).
2. **Preview controls row**: `Row` of label `Text('Auto-preview')`, a
   `Switch(value: state.autoPreview, onChanged: (v) => cubit.setAutoPreview(v))`,
   `Icon(Icons.volume_down)`, `Expanded(Slider(min: -36, max: 6,
   divisions: 42, value: state.previewGainDb, label:
   '${state.previewGainDb.round()} dB', onChanged: cubit.setPreviewGain))`,
   and `Text('${state.previewGainDb.round()} dB')`.
3. **'Mapping' section** — plain `Column` under a
   `Semantics(header: true, child: Text('Mapping', style: titleSmall))`.
   Five `_StepRow`s (private widget in this file):

   | Label | Value shown | minus/plus actions |
   |---|---|---|
   | `'Root'` | `region.rootMidi == null ? 'Unset' : PolyMultisampleParser.midiToNoteName(root)` where `root = region.rootMidi ?? 60` | `cubit.updateRoot(path, root ∓ 1)` |
   | `'Low'` | `PolyMultisampleParser.midiToNoteName(low)` where `low = effectiveLow(region)` | `cubit.updateRangeLow(path, low ∓ 1)` |
   | `'High'` | `PolyMultisampleParser.midiToNoteName(high)` where `high = effectiveHigh(region, state.editedRegions)` | `cubit.updateRangeHigh(path, high ∓ 1)` |
   | `'Velocity'` | `'${region.velocityLayer ?? 1}'` | `cubit.updateVelocity(path, math.max(1, v - 1))` / `cubit.updateVelocity(path, v + 1)` |
   | `'Round robin'` | `'${region.roundRobin ?? 1}'` | `cubit.updateRoundRobin(path, math.max(1, r - 1))` / `cubit.updateRoundRobin(path, r + 1)` |

   `_StepRow(label, value, onMinus, onPlus)` renders
   `Semantics(label: '$label $value', child: Row(...))` containing
   `Text('$label: $value')` and two compact `IconButton`s with tooltips
   `'Decrease $label'` / `'Increase $label'` (same shape as the current
   `_StepControl` — copy it and rename).
4. **'Loop points' `ExpansionTile`** (`initiallyExpanded: false`,
   title `Text('Loop points')`). Body only when the sample is a local
   `.wav` (hardware paths get
   `Text('Loop editing needs a local or mounted folder.')` instead —
   condition identical to the reveal-folder rule plus the `.wav` check).
   Body content:
   - On first expansion, if `state.waveformSummaries[path] == null`, call
     `cubit.loadWaveform(path)` (use `onExpansionChanged`; guard with the
     null check so it fires once).
   - While the summary is null show `LinearProgressIndicator()`.
   - With `overview` available: current draft
     `final draft = state.loopDrafts[path] ?? PolyWaveformDraft(loopStart: overview.loopStart, loopEnd: overview.loopEnd);`
   - `SwitchListTile(title: Text('Loop enabled'), value: draft.loopStart != null && draft.loopEnd != null, ...)` —
     turning ON sets `cubit.updateLoopDraft(path, draft.copyWith(loopStart:
     overview.loopStart ?? 0, loopEnd: overview.loopEnd ?? overview.frameCount - 1))`;
     turning OFF sets `cubit.updateLoopDraft(path, draft.copyWith(clearLoopStart: true, clearLoopEnd: true))`.
   - Two `_FrameNudgeRow`s (`'Loop start'`, `'Loop end'`) — each shows the
     frame value and four compact IconButtons: −100, −1, +1, +100 (tooltips
     `'$label -100 frames'` etc.), clamped to `0..overview.frameCount - 1`,
     emitting via `cubit.updateLoopDraft` with `copyWith`. Visible only when
     the loop is enabled.
   - `FilledButton` `'Save loop'` — enabled when the draft's
     loopStart/loopEnd differ from `overview.loopStart`/`overview.loopEnd`;
     on press `await cubit.saveLoopMetadata(path)`.

Step 9 adds section 5 to this same file:

5. **'Edit audio' `ExpansionTile`** (`initiallyExpanded: false`, title
   `Text('Edit audio')`, same local-`.wav`-only rule with message
   `Text('Audio editing needs a local or mounted folder.')`). With
   `overview` loaded (same lazy-load pattern as Loop points):
   - `final draft = state.wavEditDrafts[path] ?? PolyWaveformDraft(trimStart: 0, trimEnd: overview.frameCount - 1);`
     All edits go through `cubit.updateWavEditDraft(path, draft.copyWith(...))`.
   - `PolyWaveformEditor` (step 9 widget) in trim mode showing trim handles.
   - `_FrameNudgeRow`s for `'Trim start'` / `'Trim end'` (same ±1/±100 shape).
   - Two fade rows (`'Fade in'`, `'Fade out'`): a `Slider(min: 0, max: 5000,
     divisions: 100)` of milliseconds where
     `frames = (ms / 1000 * overview.sampleRate).round()` and
     `ms = frames / overview.sampleRate * 1000` for display; a
     `DropdownButton<WavFadeCurve>` over all four values labeled `'Linear'`,
     `'Equal power'`, `'Exponential'`, `'S-curve'`; a strength
     `Slider(min: 0, max: 1, divisions: 20)`.
   - Gain row: `Slider(min: -24, max: 24, divisions: 96,
     value: draft.gainDb)` labeled `'Gain'` with a trailing dB text.
   - Normalize row: `Switch` (on = `normalizePeakDb: -0.3`, off =
     `copyWith(clearNormalize: true)`) + `Slider(min: -24, max: 0,
     divisions: 48)` enabled only while on.
   - Buttons row: `OutlinedButton` `'Save as…'` and `FilledButton`
     `'Overwrite'`. `'Save as…'` → `FilePicker.saveFile(dialogTitle:
     'Save edited WAV as', fileName: p.basename(path), initialDirectory:
     state.lastWavExportFolder, type: FileType.custom, allowedExtensions:
     const ['wav'])`; when non-null `await cubit.saveDestructiveWav(path,
     target, true);`. `'Overwrite'` → confirmation `AlertDialog` (title
     `'Overwrite ${p.basename(path)}?'`, content
     `'This permanently changes the audio file.'`, actions `'Cancel'` /
     `'Overwrite'`); on confirm `await cubit.saveDestructiveWav(path, path,
     true); await cubit.loadWaveform(path);`.

### Step 9 — `PolyWaveformEditor` (`widgets/poly_waveform_editor.dart`)

Stateful widget, fixed `height` (default `120`).

| Param | Type |
|---|---|
| `overview` | `WavOverview` (required) |
| `mode` | `PolyWaveformEditorMode` (required; `enum PolyWaveformEditorMode { loop, trim }` declared in this file) |
| `startFrame` | `int?` (required — loopStart or trimStart) |
| `endFrame` | `int?` (required) |
| `onChanged` | `void Function(int startFrame, int endFrame)` (required) |
| `height` | `double` (default `120`) |

- `CustomPaint` painter `_PolyWaveformPainter`: draws each `WavPeak` as a
  vertical line from `min` to `max` scaled to the height, color
  `colorScheme.primary`; the region between the two handles is tinted
  `colorScheme.tertiary.withValues(alpha: 0.25)` (loop mode) or the OUTSIDE
  is tinted `colorScheme.onSurface.withValues(alpha: 0.25)` (trim mode);
  handles are 2-px vertical lines in `colorScheme.tertiary`.
- Horizontal drag: on start, grab whichever handle's x is within 24 px of
  the pointer (nearest wins; no handle → ignore drag). On update, convert x
  to frame (`x / width * frameCount`), snap with
  `overview.nearestZeroCrossing(frame)`, clamp to keep
  `startFrame < endFrame`, call `onChanged`.
- Semantics: `Semantics(label: 'Waveform editor', child: ...)`.

### Step 10 — loose WAV dialog (`dialogs/poly_loose_wav_import_dialog.dart`)

```dart
Future<PolyStagedImport?> showPolyLooseWavImportDialog(
  BuildContext context, {
  required List<String> paths,
})
```

`showDialog<PolyStagedImport>` whose builder wraps a private
`_PolyLooseWavImportDialog` in
`BlocProvider(create: (_) => PolyLooseWavImportCubit()..setFiles(paths))`.
Dialog (`AlertDialog`, title `'Import WAV files'`, content width 520,
height 480):

- `CheckboxListTile(dense: true)` per path — title `p.basename(path)`,
  subtitle `p.dirname(path)`, value from `state.selectedPaths`, toggle via
  `cubit.toggleSelection(path)`. Above the list: `TextButton('All')` →
  `cubit.selectAll()`, `TextButton('None')` → `cubit.clearSelection()`.
- Mapping modes: wrap five `RadioListTile<PolyLooseWavMappingMode>(value: m,
  title: Text(label), dense: true)` tiles in a
  `RadioGroup<PolyLooseWavMappingMode>(groupValue: state.mappingOptions.mode,
  onChanged: (m) => cubit.setMappingOptions(PolyLooseWavMappingOptions(mode:
  m!, startMidi: state.mappingOptions.startMidi)), child: Column(...))`.
  (This Flutter version uses the `RadioGroup` API — do NOT pass
  `groupValue`/`onChanged` to the tiles themselves; see
  `lib/ui/add_algorithm_screen.dart` for the in-repo pattern.) Labels:

  | Mode | Label |
  |---|---|
  | `preserve` | `'Use note names from file names'` |
  | `unmapped` | `'Leave unmapped'` |
  | `chromaticSpread` | `'Spread chromatically from start note'` |
  | `roundRobinStack` | `'Stack as round robins on one note'` |
  | `velocityLayers` | `'Stack as velocity layers on one note'` |

- Start-note stepper row (visible for the last three modes): label
  `'Start note: ${PolyMultisampleParser.midiToNoteName(startMidi)}'` with
  ∓1 IconButtons (tooltips `'Decrease start note'` / `'Increase start
  note'`, clamp 0–127), emitting `setMappingOptions` with the new
  `startMidi`.
- Actions: `TextButton('Cancel')` pops null. `FilledButton('Import')` —
  disabled while `status == staging` or `!state.canContinue`; on press
  `await cubit.continueImport();` then if
  `cubit.state.status == PolyLooseWavImportStatus.completed` pop
  `cubit.state.stagedImport`.
- A `BlocListener` is unnecessary; the button awaits.
- When `state.error != null` show it as `Text(state.error!,
  style: TextStyle(color: colorScheme.error))` above the actions.

### Step 11 — Decent dialog (`dialogs/poly_decent_import_dialog.dart`)

```dart
Future<PolyStagedImport?> showPolyDecentImportDialog(
  BuildContext context, {
  required String sourcePath,
  PolyMultisampleBuilderCubit? previewCubit,
  @visibleForTesting PolyDecentImportCubit? cubit,
})
```

`showDialog<PolyStagedImport>` wrapping `_PolyDecentImportDialog` in
`BlocProvider(create: (_) => PolyDecentImportCubit()..analyzeSource(sourcePath))`
— or, when the test-only `cubit` param is non-null,
`BlocProvider.value(value: cubit)` with no `analyzeSource` call
(`@visibleForTesting` comes from `package:flutter/foundation.dart`).
`AlertDialog`, title `'Import Decent Sampler'`, content width 640, height 560,
body is a `ListView` switching on status:

- `analyzing` → centered `CircularProgressIndicator` +
  `Text('Analyzing Decent source…')` in a `Semantics(liveRegion: true)`.
- `failure` → `Text(state.error ?? 'Analysis failed.')`.
- `ready`/`staging` → sections:
  1. Summary: `Text(analysis.structureSummary)`.
  2. **Presets** (only when `analysis.presets.length > 1`): header
     `Semantics(header: true, child: Text('Presets'))`;
     `CheckboxListTile(dense: true)` per preset — title `preset.name`,
     subtitle `'${preset.groupCount} groups, ${preset.sampleCount} samples'`,
     toggle `cubit.togglePreset(preset.name)`.
  3. **Handling** header `Text('Group handling')`; a
     `RadioGroup<DecentSamplerGroupHandling>(groupValue: state.groupHandling,
     onChanged: (v) => cubit.setGroupHandling(v!), child: Column(...))` of
     seven `RadioListTile<DecentSamplerGroupHandling>(value: v, title:
     Text(label), dense: true)` tiles:

     | Value | Label |
     |---|---|
     | `auto` | `'Automatic (recommended)'` |
     | `tagMapping` | `'Map groups by tags'` |
     | `velocityLayers` | `'Groups as velocity layers'` |
     | `keyRanges` | `'Groups as manual key ranges'` |
     | `splitFolders` | `'Split groups into separate folders'` |
     | `selectedGroup` | `'Import one group only'` |
     | `selectedTags` | `'Import selected tags only'` |

     (change handling lives on the enclosing `RadioGroup`, not the tiles).
  4. **Mode-dependent editor** (exactly one, by `state.groupHandling`):
     - `velocityLayers`: per group a row — `Text(group.name)` +
       `_IntStepper('Velocity', state.groupVelocityLayers[group.key] ?? group.defaultVelocityLayer, ...)`
       calling `cubit.setGroupVelocity`.
     - `keyRanges`: per group — `Text(group.name)`, an enabled `Checkbox`
       (range `enabled` flag, via `cubit.updateGroupRange` with
       `DecentSamplerTagKeyRange(..., enabled: v)`), three note steppers
       Low/Root/High (∓1, clamped 0–127, note-name labels via
       `PolyMultisampleParser.midiToNoteName`) calling
       `cubit.updateGroupRange`, and an `_IntStepper('RR',
       state.groupRoundRobins[group.key] ?? 1)` calling
       `cubit.setGroupRoundRobin`.
     - `selectedGroup`: a `RadioGroup<String?>(groupValue:
       state.selectedGroupKey, onChanged: cubit.setSelectedGroup, child:
       Column(...))` of `RadioListTile<String?>(value: group.key, title:
       Text(group.name), subtitle: Text(group.structureSummary))` tiles.
     - `selectedTags`/`tagMapping`: per tag a `CheckboxListTile` (title
       `tag.label`, subtitle `'${tag.sampleCount} samples  ${tag.noteRange}'`,
       toggle `cubit.toggleTag(tag.key)`); when checked AND handling is
       `selectedTags`, an indented row of the same Low/Root/High steppers
       (via `cubit.setTagRange`) plus `_IntStepper('Velocity', ...)`
       (`setTagVelocity`) and `_IntStepper('RR', ...)` (`setTagRoundRobin`).
     - `auto`/`splitFolders`: `Text('No further options.')`.
     Each group/tag row also gets a preview `IconButton` (play/stop by
     comparing `previewCubit?.state.previewState.visiblePath` to the row's
     `previewSourcePath`) — enabled per the negative-decision rule; on press
     `previewCubit!.playOrStopPreview(previewSourcePath)`. Omit the button
     entirely when `previewCubit == null`.
  5. **Switches**: `SwitchListTile(title: Text('Preserve XML mapping'),
     value: state.preserveXmlMapping, onChanged: cubit.setPreserveXmlMapping)`
     and `SwitchListTile(title: Text('Include unmapped samples'),
     value: state.addUnmapped, onChanged: cubit.setAddUnmapped)`.
  6. Warnings: when `state.warnings` non-empty, a
     `Semantics(liveRegion: true)` column of warning `Text`s in
     `colorScheme.error`.
- Actions: `TextButton('Cancel')` pops null; `FilledButton('Import')` —
  disabled while staging or `!state.canContinue`; awaits
  `cubit.continueImport()` and pops `stagedImport` on `completed`.

`_IntStepper(label, value, onChanged)` is a private widget: `Text('$label:
$value')` + ∓ IconButtons (min 1, tooltips `'Decrease $label'` /
`'Increase $label'`).

### Step 12 — landing + editor views

`poly_samples_landing_view.dart` — `PolySamplesLandingView` (stateless):

| Param | Type |
|---|---|
| `state` | `PolyMultisampleBuilderState` (required) |
| `onOpenHardware` | `VoidCallback` (required) |
| `onOpenLocal` | `VoidCallback` (required) |
| `onImport` | `VoidCallback` (required) |
| `onOpenRecent` | `VoidCallback?` (required — null hides the button) |
| `onStartEmptyDraft` | `VoidCallback` (required) |

Renders (centered, `maxWidth: 720`):
- `Semantics(header: true, child: Text('Build or edit a Disting NT multisample folder', style: headlineSmall))`
- Three `_SourceCard`s (private; `Card` + `InkWell`, icon 40, title, one-line
  description, min size 180×140):

  | Icon | Title | Description |
  |---|---|---|
  | `Icons.sd_storage` | `'NT Hardware'` | `'Browse /samples on the connected module'` |
  | `Icons.folder_open` | `'Local Folder'` | `'Open a multisample folder on this computer'` |
  | `Icons.file_upload` | `'Import Files'` | `'Stage WAVs or a Decent Sampler preset'` |

- Under the cards: when `onOpenRecent != null`, `TextButton.icon(icon:
  Icon(Icons.history), label: Text('Recent: ${p.basename(state.lastLocalFolder!)}'))`;
  always a `TextButton('Start empty draft')` → `onStartEmptyDraft`.

Also in this file: `PolyHardwareFolderList` (stateless; params
`folders: List<String>`, `onOpen: ValueChanged<String>`, `onBack:
VoidCallback`) — a heading row (`IconButton` back arrow tooltip
`'Back to sample sources'` + `Semantics(header: true, child:
Text('Sample folders on /samples'))`) above a `ListView.separated` of
`ListTile(leading: Icon(Icons.folder), title: Text(folder))`; and
`PolyLargeFolderView` (params `messages: List<String>`,
`onChooseSmaller: VoidCallback`, `onImportSubset: VoidCallback`) — warning
panel copying today's `_WarningPanel` shape with title
`'Large sample folder'` plus two buttons `'Choose smaller folder'` /
`'Import subset'`.

`poly_samples_editor_view.dart` — `PolySamplesEditorView` (stateless):

| Param | Type |
|---|---|
| `state` | `PolyMultisampleBuilderState` (required) |
| `manager` | `IDistingMidiManager?` (required) |
| `onAddFiles` | `VoidCallback` (required) |
| `onAddFolder` | `VoidCallback` (required) |
| `onSaveAs` | `VoidCallback` (required) |
| `onBackToSources` | `VoidCallback` (required) |

Layout:
- **Toolbar** (`Padding` 16/12): `Wrap(spacing: 8, runSpacing: 8)` of:
  back `IconButton` (tooltip `'Back to sample sources'`, calls
  `onBackToSources`); `Semantics(header: true, child:
  Text(instrument.name, style: titleMedium))`; plain `Text` stats
  `'${instrument.regions.length} samples'`, `'${instrument.mappedCount} mapped'`,
  and when > 0 `'${instrument.warningCount} warnings'`; when `state.isDirty`
  a `Chip(label: Text('Unsaved changes'))`; then trailing actions:
  - primary: draft modes (`importDraft`/`customDraft`) get
    `FilledButton.icon(Icons.save_as, 'Save As…')` → `onSaveAs`, enabled
    when `editedRegions.isNotEmpty && activeOperation !=
    PolyMultisampleActiveOperation.saving`; other modes get
    `FilledButton.icon(Icons.check, 'Apply')` → `cubit.applyChanges(manager)`,
    enabled when `state.isDirty && activeOperation !=
    PolyMultisampleActiveOperation.applying` (show a 16-px
    `CircularProgressIndicator` as the icon while applying — same shape as
    the current header).
  - `TextButton.icon(Icons.undo, 'Discard')` → `cubit.discardChanges()`,
    enabled when `state.isDirty`.
  - `PopupMenuButton<String>` (tooltip `'More sample actions'`, icon
    `Icons.more_horiz`) with items: `'add_files'` → `'Add files…'`,
    `'add_folder'` → `'Add folder…'`, `'remove_selected'` →
    `'Remove selected'` (enabled when `selectedPaths.isNotEmpty`; calls
    `cubit.removeSelectedRegions()`), `'clear_all'` → `'Clear all'`
    (enabled when `editedRegions.isNotEmpty`; calls `cubit.clearDraft()`).
- Warnings: when `state.warnings.isNotEmpty`, the `_WarningPanel` copy
  (title `'Warnings'`).
- **Body** in a `LayoutBuilder`: when `maxWidth >= 900`, `Row` of
  `Expanded(Column(PolyKeyMap, Expanded(PolySampleList)))` and a
  `SizedBox(width: 320, child: PolySampleInspector)`; otherwise a `Column`
  of `PolyKeyMap(height: 140)`, `Expanded(flex: 3, PolySampleList)`,
  `Divider(height: 1)`, `Expanded(flex: 2, PolySampleInspector)`.
- Wiring: `PolyKeyMap(regions: state.editedRegions, selectedPath:
  selectedRegionFor(state)?.path, onSelect: (r) => cubit.selectRegion(r.path,
  PolyRegionSelectionMode.replace))`; `PolySampleList(regions:
  state.editedRegions, selectedPaths: state.selectedPaths, focusedPath:
  state.focusedPath, previewVisiblePath: state.previewState.visiblePath,
  onSelect: cubit.selectRegion, onPreview: (path) =>
  cubit.playOrStopPreview(path, manager: manager))`.

### Step 13 — `PolySamplesScreen` (`poly_samples_screen.dart`)

```dart
class PolySamplesScreen extends StatelessWidget {
  const PolySamplesScreen({super.key, required this.distingCubit});
  final DistingCubit distingCubit;
  // build: BlocProvider(create: (_) => PolyMultisampleBuilderCubit(),
  //   child: PolySamplesView(distingCubit: distingCubit));
}

class PolySamplesView extends StatelessWidget {
  const PolySamplesView({super.key, required this.distingCubit});
  final DistingCubit distingCubit;
}
```

`PolySamplesView.build` is a
`BlocConsumer<PolyMultisampleBuilderCubit, PolyMultisampleBuilderState>`:

- `listenWhen`/`listener`: **verbatim copy** of the current
  `PolyMultisampleBuilderView` listener (effectId comparison, error snackbar,
  `SemanticsService.sendAnnouncement` for error and effect).
- `builder`: `PopScope(canPop: !hasUnsavedWork, onPopInvokedWithResult: ...)`
  where `hasUnsavedWork` is the decision-6 expression; when a pop is blocked
  show an `AlertDialog` (title `'Discard changes?'`, content
  `'You have unsaved sample changes. Discard them?'`, actions
  `TextButton('Cancel')` and `FilledButton('Discard')`); on Discard call
  `Navigator.of(context).pop()` on the screen's context.
  Inside: `Scaffold(appBar: AppBar(title: const Text('Samples')), body: _body(...))`.
- `_body` dispatch, in this order:
  1. `state.status == PolyMultisampleLoadStatus.loading` → centered
     progress: verbatim copy of the current loading block
     (`Semantics(liveRegion: true, label: state.progressText ?? 'Loading
     samples', ...)`).
  2. `state.status == PolyMultisampleLoadStatus.largeFolder` →
     `PolyLargeFolderView(messages: state.warnings, onChooseSmaller:
     _openLocal, onImportSubset: _import)`.
  3. `state.hardwareFolders.isNotEmpty && state.currentInstrument == null`
     → `PolyHardwareFolderList(folders: ..., onOpen: (folder) { final m =
     distingCubit.disting(); if (m != null)
     cubit.loadHardwareFolder(m, folder); }, onBack: cubit.returnToSources)`.
  4. hardware mode, ready, no instrument → verbatim copy of the current
     `_HardwareEmptyState` (`'No sample folders found on /samples.'`).
  5. `state.currentInstrument == null` → `PolySamplesLandingView(...)`
     wired: `onOpenHardware: () => _openHardware(context)`, `onOpenLocal:
     () => _openLocal(context)`, `onImport: () => _import(context)`,
     `onStartEmptyDraft: cubit.startEmptyDraft`, and `onOpenRecent:
     state.lastLocalFolder == null ? null : () =>
     cubit.loadLocalFolder(state.lastLocalFolder!)`.
  6. otherwise → `PolySamplesEditorView(state: state, manager:
     distingCubit.disting(), onAddFiles: ..., onAddFolder: ...,
     onSaveAs: ..., onBackToSources: cubit.returnToSources)`.

Private flow helpers in this file (all take `BuildContext` first and read
the builder cubit with `context.read`):

- `_openHardware`: `final m = distingCubit.disting();` — when null, snackbar
  `'Connect to Disting NT to browse samples.'`; else
  `cubit.loadHardwareFolderList(m)`.
- `_openLocal`: `FilePicker.getDirectoryPath(dialogTitle: 'Open sample
  folder', initialDirectory: cubit.state.lastLocalFolder)`; on non-null +
  mounted → `cubit.loadLocalFolder(path)`.
- `_import`: `FilePicker.pickFiles(dialogTitle: 'Import samples',
  allowMultiple: true, type: FileType.custom, allowedExtensions: const
  ['wav', 'aif', 'aiff', 'dspreset', 'dslibrary', 'zip'])`; collect
  non-null paths. If exactly one path and it ends (lowercased) with
  `.dspreset`/`.dslibrary`/`.zip` → `await cubit.rememberSourceFolder(
  p.dirname(path));` then `showPolyDecentImportDialog(context, sourcePath:
  path, previewCubit: cubit)`; else filter to supported audio names and
  `showPolyLooseWavImportDialog(context, paths: audioPaths)`. A non-null
  staged result → `cubit.adoptStagedImport(staged)`.
- `_addFiles` (editor): same picker restricted to
  `['wav', 'aif', 'aiff']` → loose dialog → non-null →
  `cubit.addStagedRegions(staged)`.
- `_addFolder` (editor): `getDirectoryPath` → if the directory contains a
  top-level `*.dspreset` file (`Directory(path).listSync()` scan, non-
  recursive) → Decent dialog on the folder path; else list supported audio
  files recursively (`Directory(path).list(recursive: true)` filtered by
  `isSupportedAudioName(p.basename(...))` from the models file) → loose
  dialog. Non-null staged → `cubit.addStagedRegions(staged)`.
- `_saveAs` (editor): `getDirectoryPath(dialogTitle: 'Save samples to
  folder', initialDirectory: cubit.state.lastCustomOutputFolder)` → on
  non-null `cubit.saveCustomDraft(path)`.

### Step 14 — navigation rewire (`lib/ui/synchronized_screen.dart`)

All anchors are symbols/strings, not line numbers.

1. Change `enum EditMode { parameters, routing, samples, both }` →
   `enum EditMode { parameters, routing, both }`.
2. Delete the import of
   `package:nt_helper/ui/poly_multisample/poly_multisample_builder_screen.dart`;
   add `import 'package:nt_helper/ui/poly_multisample/poly_samples_screen.dart';`.
3. In `build`: delete the `showSamplesWorkspace` local and the
   `if (_currentMode == EditMode.samples && !showSamplesWorkspace)` fallback
   block; change the `workspaceIndex` expression to
   `final workspaceIndex = _currentMode == EditMode.routing ? 1 : 0;`;
   in BOTH `IndexedStack` children lists delete the
   `if (showSamplesWorkspace) _buildSamplesWorkspace(),` entry.
4. Delete the whole `Widget _buildSamplesWorkspace()` method.
5. In `_buildBottomAppBar`'s `SegmentedButton<EditMode>`: delete the
   `if (!isMobile) ButtonSegment(value: EditMode.samples, ...)` segment, and
   replace the `onSelectionChanged` closure body with:

   ```dart
   setState(() {
     final previousMode = _currentMode;
     if (modes.length == 2 &&
         modes.contains(EditMode.parameters) &&
         modes.contains(EditMode.routing) &&
         _canShowSplitScreen(screenWidth)) {
       _currentMode = EditMode.both;
     } else if (modes.length == 2) {
       // Can't split - keep only the newly clicked one
       final newMode = modes.firstWhere(
         (m) =>
             m !=
             (previousMode == EditMode.both
                 ? EditMode.parameters
                 : previousMode),
         orElse: () => modes.first,
       );
       _currentMode = newMode;
     } else if (modes.length == 1) {
       _currentMode = modes.first;
     }
   });
   ```
6. In the quick-action `Row` (the one containing the `'Plugin Manager'`
   IconButton), insert directly after the Plugin Manager `if (!kPlayStoreBuild)
   IconButton(...)` block:

   ```dart
   if (!isMobile)
     IconButton(
       tooltip: 'Samples',
       icon: const Icon(Icons.piano, semanticLabel: 'Samples'),
       onPressed: widget.loading
           ? null
           : () {
               final distingCubit = context.read<DistingCubit>();
               Navigator.push(
                 context,
                 MaterialPageRoute(
                   builder: (_) =>
                       PolySamplesScreen(distingCubit: distingCubit),
                 ),
               );
             },
     ),
   ```

   Note this `Row` is inside a `BlocBuilder` whose builder context is named
   `context`; `isMobile` is already in scope in `_buildBottomAppBar`.
7. In the `switch (_currentMode)` inside the FAB/actions builder
   (`EditMode.parameters => _buildParameterModeActions(cubit)` etc.), delete
   the `EditMode.samples => const <Widget>[],` arm.
8. Delete `lib/ui/poly_multisample/poly_multisample_builder_screen.dart` and
   `test/poly_multisample/poly_multisample_builder_screen_test.dart` (its
   still-relevant tests were re-homed in step 13).
9. Update `test/ui/synchronized_screen_bottom_bar_test.dart`:
   - Delete the tests named `'Samples workspace mode appears on desktop
     only'`, `'Parameters and Routing remain reachable after Samples'`, and
     `'Samples workspace mode is absent on mobile'`.
   - Add two tests (reusing the file's existing `createTestWidget` helper):
     `'Samples button pushes PolySamplesScreen on desktop'` — pump with
     `isMobile: false`, `expect(find.byTooltip('Samples'), findsOneWidget)`,
     tap it, `pumpAndSettle`, `expect(find.byType(PolySamplesScreen),
     findsOneWidget)`; and `'Samples button is absent on mobile'` — pump
     with `isMobile: true`, `expect(find.byTooltip('Samples'),
     findsNothing)`. Import
     `package:nt_helper/ui/poly_multisample/poly_samples_screen.dart`.

## Compatibility notes (from the import graph)

- `PolyMultisampleBuilderScreen`/`PolyMultisampleBuilderView` are imported
  ONLY by `lib/ui/synchronized_screen.dart` and
  `test/poly_multisample/poly_multisample_builder_screen_test.dart`; both
  references are removed in step 14, so no re-export is needed.
- `PolyMultisampleBuilderCubit`, its state class, and its enums are imported
  by tests — their names, file path, and existing signatures must not change.
- All cubit/model changes in steps 1–3 and 5 are strictly additive so the
  old screen file keeps compiling until deletion.

## Acceptance criteria

1. `flutter analyze` reports `No issues found!` after every step.
2. `flutter test test/poly_multisample test/ui/synchronized_screen_bottom_bar_test.dart`
   passes after every step.
3. After step 14: `rg -n "EditMode.samples" lib test` prints nothing;
   `rg -n "PolyMultisampleBuilderScreen" lib test` prints nothing.
4. The Samples screen is reachable via the bottom-bar piano icon on desktop,
   absent on mobile, and pops back with the AppBar back button; leaving with
   unsaved changes asks for confirmation.
5. Every feature row in the parity checklist has a working UI path.
6. Screen-reader affordances: headers marked, live regions for progress/
   warnings/effects, icon-only buttons all have tooltips + semantic labels,
   list rows expose `selected` state — as specified per widget above.
