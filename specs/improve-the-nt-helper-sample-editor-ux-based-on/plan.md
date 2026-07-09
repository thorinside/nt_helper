# Improve sample editor UX implementation plan

Total steps: 3

Read `specs/conventions.md` and `specs/improve-the-nt-helper-sample-editor-ux-based-on/spec.md` completely before starting any step. Execute one numbered step per fresh-context session. Do not implement a later step early.

Program-level verification after STEP 3:

```bash
cd /Users/nealsanche/nosuch/nt_helper
flutter analyze
flutter test
```

## STEP 1 of 3 — Stabilize edit ordering and add selection-scoped mapping state

### Goal

Make mapping edits preserve sample-row order, compute live mapping warnings, and add cubit APIs for selected-row bulk edit, selected-row unmap, and selected-row discard.

### Files to edit

- `lib/ui/poly_multisample/poly_multisample_builder_cubit.dart`
- `test/poly_multisample/poly_multisample_builder_cubit_test.dart`

### Mechanical edits

1. In `PolyMultisampleBuilderState`, add `this.mappingWarnings = const [],` to the constructor parameter list immediately after `this.warnings = const [],`.
2. Add `final List<String> mappingWarnings;` immediately after `final List<String> warnings;`.
3. Add `List<String>? mappingWarnings,` to `copyWith` immediately after the existing `warnings` parameter.
4. In the `PolyMultisampleBuilderState` returned from `copyWith`, set `mappingWarnings: mappingWarnings ?? this.mappingWarnings,` immediately after `warnings: warnings ?? this.warnings,`.
5. In `_setInstrument`, compute `final mappingWarnings = _mappingWarningsFor(regions);` after `regions` is created and before `emit`.
6. In `_setInstrument` state emission, set `mappingWarnings: mappingWarnings,` immediately after `warnings: warnings,`.
7. In `_replaceEditedRegions`, delete the line `PolyMultisampleParser.sortRegions(regions);` and do not replace it with any sort.
8. In `_replaceEditedRegions`, compute `final mappingWarnings = _mappingWarningsFor(regions);` after `remainingPaths` is computed.
9. In `_replaceEditedRegions` state emission, add `mappingWarnings: mappingWarnings,` immediately after `mapRevision: state.mapRevision + 1,`.
10. Add private helper `_selectedOrFocusedPaths()` in `PolyMultisampleBuilderCubit` near `_updateRegion` using the exact rules from `spec.md`.
11. Add private helper `_updateSelectedRegions(PolySampleRegion Function(PolySampleRegion region) update, {IDistingMidiManager? manager})` near `_updateRegion` using the exact rules from `spec.md`.
12. Add public methods with the exact signatures from `spec.md`:
    - `updateSelectedRoot`
    - `updateSelectedRangeLow`
    - `updateSelectedRangeHigh`
    - `updateSelectedVelocity`
    - `updateSelectedRoundRobin`
    - `unmapSelectedRegions`
13. Use the same clamp rules as the existing single-region update methods.
14. `updateSelectedRoot` must set `rootMidi` and `rootName` from the clamped value.
15. `unmapSelectedRegions` must call `_updateSelectedRegions` and use `copyWith(clearRoot: true, clearRangeLow: true, clearRangeHigh: true, clearSwitchPoint: true, clearVelocityLayer: true, clearRoundRobin: true)`.
16. Replace `discardChanges()` with the selection-scoped behavior table from `spec.md`.
17. The selected-row branch of `discardChanges()` must:
    - Build a map of baseline rows by path.
    - Build `nextRegions` by iterating the current `state.editedRegions` order.
    - Replace selected rows that exist in the baseline map with their baseline row.
    - Omit selected rows that do not exist in the baseline map.
    - Leave non-selected rows unchanged.
    - Prune `loopDrafts` and `wavEditDrafts` only for selected paths.
    - Call `_replaceEditedRegions(nextRegions, selectedPaths: nextSelectedPaths)` where `nextSelectedPaths` contains selected paths that remain.
18. Add private helper `_mappingWarningsFor(List<PolySampleRegion> regions)` below `_replaceEditedRegions` with the warning rules and strings from `spec.md`; root-outside-range and overlap checks must skip regions with `rootMidi == null`.
19. Add private helper `_noteLabel(int midi)` below `_mappingWarningsFor`; it returns `PolyMultisampleParser.midiToNoteName(midi)`.
20. Add private helper `_sampleMappingLabel(PolySampleRegion region, List<PolySampleRegion> regions)` below `_noteLabel`; copy the duplicate-display-name logic from `sampleDisplayLabel` in `lib/ui/poly_multisample/poly_region_math.dart` and use existing `package:path/path.dart` import alias `p`.
21. Do not import `poly_region_math.dart` into the cubit.
22. In `returnToSources`, in the state emission that clears `currentInstrument`, `editedRegions`, and draft maps, also set `mappingWarnings: const [],`.
23. In `test/poly_multisample/poly_multisample_builder_cubit_test.dart`, add test `mapping edits preserve editor order` near existing mapping edit tests. It must:
    - Create `_ExposedPolyMultisampleBuilderCubit`.
    - Set state with three edited regions in order `/tmp/z.wav`, `/tmp/a.wav`, `/tmp/m.wav` and roots 72, 48, 60.
    - Call `updateRoot('/tmp/z.wav', 36)`, `updateRangeLow('/tmp/a.wav', 40)`, `updateRangeHigh('/tmp/m.wav', 90)`, `updateVelocity('/tmp/z.wav', 2)`, and `updateRoundRobin('/tmp/a.wav', 3)`.
    - Assert `cubit.state.editedRegions.map((r) => r.path).toList()` remains `['/tmp/z.wav', '/tmp/a.wav', '/tmp/m.wav']`.
24. Add test `mapping warnings report invalid range root outside range and overlaps`. It must:
    - Set state with four regions in editor order: invalid range, root outside range, overlap A, overlap B.
    - Use same velocity and RR for overlap A/B.
    - Assert `mappingWarnings` contains exactly the three strings defined by `spec.md` for those rows.
25. Add test `mapping warnings allow different velocity and rr overlaps`. It must:
    - Set state with overlapping key ranges where one pair differs by velocity and another pair differs by RR.
    - Assert `mappingWarnings` is empty.
26. Add test `selected bulk mapping edits only selected rows`. It must:
    - Set state with three rows, selected paths first and third, focused path first.
    - Call `updateSelectedRoot(61)`, `updateSelectedRangeLow(60)`, `updateSelectedRangeHigh(64)`, `updateSelectedVelocity(4)`, and `updateSelectedRoundRobin(5)`.
    - Assert selected rows have root C#4, low 60, high 64, velocity 4, RR 5.
    - Assert non-selected row remains unchanged.
27. Add test `unmapSelectedRegions clears mapping fields without removing rows`. It must:
    - Set state with two mapped rows, select one row.
    - Call `unmapSelectedRegions()`.
    - Assert row count remains 2.
    - Assert selected row has null `rootMidi`, `rootName`, `rangeLow`, `rangeHigh`, `switchPoint`, `velocityLayer`, and `roundRobin`.
    - Assert non-selected row remains mapped.
28. Add test `discardChanges resets only selected existing rows and removes selected new rows`. It must:
    - Set baseline with `/tmp/a.wav` and `/tmp/b.wav`.
    - Set edited rows with modified `/tmp/a.wav`, modified `/tmp/b.wav`, and new `/tmp/new.wav`.
    - Select `/tmp/a.wav` and `/tmp/new.wav`.
    - Add loop and wav edit drafts for all three paths.
    - Call `discardChanges()`.
    - Assert `/tmp/a.wav` equals baseline values.
    - Assert `/tmp/b.wav` keeps edited values and its drafts remain.
    - Assert `/tmp/new.wav` is absent and its drafts are absent.
29. Add test `discardChanges with no selection keeps full discard behavior`. It must cover current full reset behavior and cleared draft maps.
30. Add test `returnToSources clears mapping warnings`. It must set state with a current instrument, one edited region, and a non-empty `mappingWarnings`, call `await cubit.returnToSources()`, and assert `mappingWarnings` is empty.
31. Do not edit UI files in this step.

### Verification commands

```bash
cd /Users/nealsanche/nosuch/nt_helper
dart format lib/ui/poly_multisample/poly_multisample_builder_cubit.dart test/poly_multisample/poly_multisample_builder_cubit_test.dart
flutter analyze
flutter test test/poly_multisample/poly_multisample_builder_cubit_test.dart
rg -n "mappingWarnings|updateSelectedRoot|updateSelectedRangeLow|updateSelectedRangeHigh|updateSelectedVelocity|updateSelectedRoundRobin|unmapSelectedRegions|_mappingWarningsFor|sortRegions\(regions\)" lib/ui/poly_multisample/poly_multisample_builder_cubit.dart test/poly_multisample/poly_multisample_builder_cubit_test.dart
git add lib/ui/poly_multisample/poly_multisample_builder_cubit.dart test/poly_multisample/poly_multisample_builder_cubit_test.dart
git status --short
git commit -m "feat(poly-samples): stabilize mapping edits and warnings"
```

### Leftover checks

- No symbols are moved in this step.
- `rg -n "PolyMultisampleParser.sortRegions\(regions\)" lib/ui/poly_multisample/poly_multisample_builder_cubit.dart` prints no output.
- `rg -n "final List<String> mappingWarnings|List<String>\? mappingWarnings|mappingWarnings:" lib/ui/poly_multisample/poly_multisample_builder_cubit.dart` prints constructor, field, copyWith, and emission sites.
- `git status --short` before commit shows only the two files named in this step.

### Commit message

`feat(poly-samples): stabilize mapping edits and warnings`

## STEP 2 of 3 — Add root-list, bulk mapping, selected unmap, and selected discard UI

### Goal

Expose the new selection-scoped cubit behavior in the editor toolbar and inspector mapping section.

### Files to edit

- `lib/ui/poly_multisample/poly_samples_editor_view.dart`
- `test/poly_multisample/poly_samples_editor_view_test.dart`
- `lib/ui/poly_multisample/widgets/poly_sample_inspector.dart`
- `test/poly_multisample/widgets/poly_sample_inspector_test.dart`

### Mechanical edits

1. Change `_WarningPanel` so its constructor requires `PageStorageKey<String> storageKey`, stores it in a final field, and uses `key: storageKey` on the `ExpansionTile` instead of the current hard-coded `PageStorageKey<String>('poly-samples-warnings-tile')`.
2. In `PolySamplesEditorView.build`, update the existing warnings block to call `_WarningPanel(title: 'Warnings', messages: state.warnings, storageKey: const PageStorageKey<String>('poly-samples-import-warnings-tile'))`.
3. Directly after that existing warnings block, add a block that renders `_WarningPanel(title: 'Mapping warnings', messages: state.mappingWarnings, storageKey: const PageStorageKey<String>('poly-samples-mapping-warnings-tile'))` when `state.mappingWarnings.isNotEmpty`.
4. In `_Toolbar.build`, compute `final hasSelection = state.selectedPaths.isNotEmpty;` near the existing booleans.
5. Change the discard `TextButton.icon` label to `Text(hasSelection ? 'Discard selected' : 'Discard')`.
6. In the popup menu `onSelected` switch, add case `'unmap_selected': cubit.unmapSelectedRegions(); break;` before `remove_selected`.
7. In the popup menu `itemBuilder`, insert a `PopupMenuItem` before `remove_selected` with value `unmap_selected`, enabled `state.selectedPaths.isNotEmpty`, and child text `Unmap selected`.
8. Change the existing `remove_selected` child text from `Remove selected` to `Remove selected samples`.
9. In `lib/ui/poly_multisample/widgets/poly_sample_inspector.dart`, replace the body of `_MappingSection.build` with the rules from `spec.md` while preserving the existing `_StepRow` controls below the new dropdown rows.
10. Add private class `_SelectionValue<T>` below `_MappingSection` with fields `final T? value; final bool mixed;` and constructors `const _SelectionValue.value(this.value) : mixed = false;` and `const _SelectionValue.mixed() : value = null, mixed = true;`.
11. Add private helper `_selectedRegionsForMapping(PolyMultisampleBuilderState state, PolySampleRegion fallback)` below `_SelectionValue`.
12. Add private helper `_selectionValue<T>(List<PolySampleRegion> regions, T? Function(PolySampleRegion region) valueFor)` below `_selectedRegionsForMapping`.
13. Add private widget `_MappingDropdownRow<T extends Object>` below `_selectionValue`.
14. `_MappingDropdownRow` constructor must have: `Key? dropdownKey`, `required String label`, `required _SelectionValue<T> selected`, `required List<DropdownMenuItem<T>> items`, `required ValueChanged<T?> onChanged`, and `String unsetHint = 'Unset'`.
15. `_MappingDropdownRow.build` must render a `SizedBox(height: PolySampleSidebarLayout.rowHeight)` containing a `Row` with a fixed label width `PolySampleSidebarLayout.mappingLabelWidth`, an expanded `DropdownButton<T>` with key `dropdownKey`, `isExpanded: true`, value `selected.mixed ? null : selected.value`, hint text `selected.mixed ? 'Mixed' : unsetHint`, supplied items, and supplied `onChanged`.
16. Add helper `_noteMenuItems()` returning a list of `DropdownMenuItem<int>` for values 0 through 127 with text from `PolyMultisampleParser.midiToNoteName(value)`.
17. Add helper `_laneMenuItems()` returning a list of `DropdownMenuItem<int>` for values 1 through 32 with text `'$value'`.
18. In `_MappingSection.build`, compute:
    - `final selectedRegions = _selectedRegionsForMapping(state, region);`
    - `final selectedCount = selectedRegions.length;`
    - selection values for root, low, high, velocity, and RR as specified in `spec.md`.
19. Use these dropdown rows in order with exact keys from `spec.md`:
    - Root calls `cubit.updateSelectedRoot(value, manager: manager)` when value is non-null.
    - Low calls `cubit.updateSelectedRangeLow(value, manager: manager)` when value is non-null.
    - High calls `cubit.updateSelectedRangeHigh(value, manager: manager)` when value is non-null.
    - Velocity calls `cubit.updateSelectedVelocity(value, manager: manager)` when value is non-null.
    - RR calls `cubit.updateSelectedRoundRobin(value, manager: manager)` when value is non-null.
20. Add the unmap button from `spec.md` after the dropdown rows and before the existing `_StepRow` controls.
21. The button label must be `Unmap sample` for one selected row and `Unmap selected` for multiple rows.
22. The button must call `cubit.unmapSelectedRegions()`.
23. Preserve all existing waveform UI, preview controls, header row, and step-row code not named in this step.
24. In `test/poly_multisample/poly_samples_editor_view_test.dart`, add test `mapping warnings panel renders separately from import warnings`. It must set state with `warnings: ['Import warning']` and `mappingWarnings: ['Mapping warning: Piano_C3.wav root C3 is outside C4–C5.']`, pump the editor, and assert header texts `Warnings (1)` and `Mapping warnings (1)` are present. The test must not throw duplicate-key exceptions.
25. Add test `toolbar discard label is selection scoped`. It must pump state with selected paths and assert `Discard selected` is present and `Discard` as a standalone button label is absent.
26. Add test `toolbar unmap selected clears mapping without removing sample`. It must pump editor with one selected mapped row, open the `More sample actions` menu, tap `Unmap selected`, pump, and assert row count is unchanged and selected row `rootMidi` is null.
27. In `test/poly_multisample/widgets/poly_sample_inspector_test.dart`, add optional parameters to `_selectedState` for `Set<String> selectedPaths`, `String? focusedPath`, and `List<PolySampleRegion>? editedRegions`. Preserve existing default behavior.
28. Add test `root dropdown assigns selected sample root from note list`. It must pump one selected sample, tap dropdown key `poly-mapping-root-dropdown`, tap text `C#4`, pump, and assert cubit state selected row has `rootMidi` 61 and `rootName` `C#4`.
29. Add test `bulk dropdown edits selected mapping fields only`. It must pump three rows with first and third selected, use dropdowns to set root `D4`, low `C4`, high `E4`, velocity `3`, and RR `4`, then assert only first and third rows changed.
30. Add test `mixed selected values show Mixed hint`. It must pump two selected rows with different roots and assert text `Mixed` appears in the mapping section.
31. Add test `unmap selected button clears mapping fields`. It must pump two selected mapped rows, tap `Unmap selected`, and assert both selected rows have null root/range/velocity/RR fields.
32. Do not edit sample-list, waveform-editor, WAV metadata, or cubit files in this step.

### Verification commands

```bash
cd /Users/nealsanche/nosuch/nt_helper
dart format lib/ui/poly_multisample/poly_samples_editor_view.dart test/poly_multisample/poly_samples_editor_view_test.dart lib/ui/poly_multisample/widgets/poly_sample_inspector.dart test/poly_multisample/widgets/poly_sample_inspector_test.dart
flutter analyze
flutter test test/poly_multisample/poly_samples_editor_view_test.dart test/poly_multisample/widgets/poly_sample_inspector_test.dart test/poly_multisample/poly_multisample_builder_cubit_test.dart
rg -n "Mapping warnings|Discard selected|Unmap selected|Remove selected samples|poly-mapping-root-dropdown|poly-mapping-low-dropdown|poly-mapping-high-dropdown|poly-mapping-velocity-dropdown|poly-mapping-rr-dropdown|_MappingDropdownRow|_SelectionValue" lib/ui/poly_multisample/poly_samples_editor_view.dart lib/ui/poly_multisample/widgets/poly_sample_inspector.dart test/poly_multisample/poly_samples_editor_view_test.dart test/poly_multisample/widgets/poly_sample_inspector_test.dart
git add lib/ui/poly_multisample/poly_samples_editor_view.dart test/poly_multisample/poly_samples_editor_view_test.dart lib/ui/poly_multisample/widgets/poly_sample_inspector.dart test/poly_multisample/widgets/poly_sample_inspector_test.dart
git status --short
git commit -m "feat(poly-samples): add selection mapping controls"
```

### Leftover checks

- No symbols are moved in this step.
- `rg -n "poly-samples-import-warnings-tile|poly-samples-mapping-warnings-tile" lib/ui/poly_multisample/poly_samples_editor_view.dart` prints both distinct warning panel keys.
- `rg -n "Remove selected'|Remove selected\)" lib/ui/poly_multisample/poly_samples_editor_view.dart` prints no old toolbar/menu label.
- `rg -n "DropdownButton<|poly-mapping-root-dropdown|updateSelectedRoot|unmapSelectedRegions" lib/ui/poly_multisample/widgets/poly_sample_inspector.dart` prints the new dropdown and unmap wiring.
- `git status --short` before commit shows only the four files named in this step.

### Commit message

`feat(poly-samples): add selection mapping controls`

## STEP 3 of 3 — Add cached draft playback and fade waveform preview

### Goal

Make loop/fade/trim/gain previews audible through cached rendered WAVs and show fade curves on the waveform.

### Files to edit

- `lib/poly_multisample/wav_metadata.dart`
- `test/poly_multisample/wav_metadata_test.dart`
- `lib/ui/poly_multisample/widgets/poly_waveform_editor.dart`
- `test/poly_multisample/widgets/poly_waveform_editor_test.dart`
- `lib/ui/poly_multisample/widgets/poly_sample_inspector.dart`
- `test/poly_multisample/widgets/poly_sample_inspector_test.dart`
- `lib/ui/poly_multisample/poly_multisample_builder_cubit.dart`
- `test/poly_multisample/poly_multisample_builder_cubit_test.dart`

### Mechanical edits

1. In `lib/poly_multisample/wav_metadata.dart`, add `WavFadeCurvePoint` and `WavFadePreview` after `WavFadeShaper` using the exact API from `spec.md`.
2. In `WavFadePreview.sampleCurve`, implement the exact point-count behavior from `spec.md`.
3. In `test/poly_multisample/wav_metadata_test.dart`, add test `fade preview samples linear endpoints and midpoint`. It must assert linear sample count 3 returns `(0,0)`, `(0.5,0.5)`, `(1,1)`.
4. Add test `fade preview clamps small sample count to endpoints`. It must call `sampleCurve(sampleCount: 1)` and assert two points `(0,0)` and `(1,1)`.
5. Add test `fade preview delegates curve shaping`. It must compare an exponential point at x `0.5` to `WavFadeShaper.apply(0.5, WavFadeCurve.exponential, strength: 0.75)`.
6. In `lib/ui/poly_multisample/widgets/poly_waveform_editor.dart`, add the six fade constructor parameters and fields from `spec.md` to `PolyWaveformEditor`.
7. Pass the six fade values into `_PolyWaveformPainter` from `build`.
8. Add the same six fields to `_PolyWaveformPainter` and its constructor.
9. In `_PolyWaveformPainter.paint`, after loop-region painting and before waveform peak painting, draw fade preview rectangles and curves using the exact painter behavior from `spec.md`.
10. Add private painter helper `_drawFadeCurve(Canvas canvas, Size size, {required int startFrame, required int endFrame, required WavFadeCurve curve, required double strength, required bool fadeIn})` inside `_PolyWaveformPainter`.
11. Use `WavFadePreview.sampleCurve(curve: curve, strength: strength)` in `_drawFadeCurve`.
12. Add all six fade fields to `_PolyWaveformPainter.shouldRepaint` comparisons.
13. In `PolyWaveformEditor.build`, add fade preview semantics exactly as specified in `spec.md` when either fade length is greater than zero.
14. In `test/poly_multisample/widgets/poly_waveform_editor_test.dart`, add test `fade preview semantics describes active fades`. It must pump `PolyWaveformEditor` with fade-in 100, fade-out 200, curves `linear` and `sCurve`, then assert the exact semantics label from `spec.md`.
15. Add test `fade preview changes trigger repaint`. It must pump an editor with fade-in 0, capture `final beforePainter = tester.widget<CustomPaint>(find.byType(CustomPaint).first).painter!;`, pump the same editor with fade-in 100, capture `final afterPainter = tester.widget<CustomPaint>(find.byType(CustomPaint).first).painter!;`, and assert `expect((afterPainter as dynamic).shouldRepaint(beforePainter), isTrue);`.
16. In `lib/ui/poly_multisample/widgets/poly_sample_inspector.dart`, pass `wavDraft.fadeInFrames`, `wavDraft.fadeOutFrames`, `wavDraft.fadeInCurve`, `wavDraft.fadeOutCurve`, `wavDraft.fadeInStrength`, and `wavDraft.fadeOutStrength` to `PolyWaveformEditor` in `_WaveformSection`.
17. In `test/poly_multisample/widgets/poly_sample_inspector_test.dart`, add test `waveform editor receives fade preview values`. It must set a wav edit draft with non-zero fade-in and fade-out, pump inspector, and assert the fade preview semantics text appears.
18. In `lib/ui/poly_multisample/poly_multisample_builder_cubit.dart`, add fields `_samplePreviewCache` and `_samplePreviewRenderInFlight` near `_notePreviewCache` using the exact declarations from `spec.md`.
19. Add private helper `_renderedSamplePreviewPath(String path)` using the exact cache, generation-stale, temp-root, and in-flight cleanup behavior from `spec.md`.
20. Add private helper `_samplePreviewSourcePlayback(String path)` using the exact behavior from `spec.md`.
21. In `playOrStopPreview`, for non-hardware local WAV paths with a loop draft or wav edit draft, use the rendered draft preview behavior table from `spec.md`.
22. Preserve existing hardware path behavior in `playOrStopPreview`.
23. Preserve existing raw-file behavior for local WAV paths with no loop draft and no wav edit draft.
24. In `updateWavEditDraft`, detect changes to trim, fade, gain, or normalize fields. Call `_scheduleLoopEditPreview(path, loopPreviewDraft, overview)` only when the path is local editable, the file exists, an overview exists, and an active loop is available from `state.loopDrafts[path]` or from `overview.loopStart`/`overview.loopEnd`. Build `loopPreviewDraft` with those loop start/end values; do not pass the wav-edit draft directly unless it contains loop start/end values.
25. In `_playLoopEditPreview`, keep existing stale request checks and change the bytes used for rendering so it calls `_preparedKeyboardPreviewBytes(path, bytes)` before loop metadata rendering/extraction.
26. Ensure sample preview temp roots are added to `_notePreviewRoots` so existing close cleanup removes them.
27. In `_cleanupNotePreviewRoots`, clear `_samplePreviewCache` and `_samplePreviewRenderInFlight` together with the existing note preview cache fields.
28. Ensure `_samplePreviewRenderInFlight.remove(cacheKey)` runs in `whenComplete` for every render future, guarded so it only removes the identical future currently stored for that key.
29. In `test/poly_multisample/poly_multisample_builder_cubit_test.dart`, add test `sample preview uses rendered draft cache for wav edits`. It must:
    - Create a temporary WAV file using existing tiny WAV helpers.
    - Set state with that path selected, a loaded waveform overview, and a wav edit draft with `fadeInFrames: 4`.
    - Use `_FakePreviewAdapter` through `PolyAudioPreviewService`.
    - Call `await cubit.playOrStopPreview(path)` twice with a stop between calls.
    - Assert adapter played paths have the same rendered temp path both times and that visible display path is the source path.
30. Add test `sample preview cache invalidates when draft fingerprint changes`. It must change fade-in frames between preview calls and assert the second rendered path differs from the first.
31. Add test `closing cubit cleans rendered sample preview temp roots`. It must render a sample preview, assert the temp file exists, call `await cubit.close()`, and assert the temp file no longer exists.
32. Add test `fade draft schedules audible loop edit preview when loop exists`. It must use `_FakePreviewAdapter` through `PolyAudioPreviewService`, set the waveform overview with non-null `loopStart` and `loopEnd`, call `updateWavEditDraft` with a changed fade field, wait 100 ms for the 80 ms debounce, and assert the fake preview adapter received exactly one played path.
33. Add test `fade draft without loop does not auto schedule audible preview`. It must set a waveform overview with null `loopStart` and `loopEnd`, call `updateWavEditDraft` with a changed fade field, wait 100 ms, and assert the fake preview adapter received no played paths.
34. Do not edit parser, sample-list, editor toolbar, database, MIDI, upload, or hardware service files in this step.

### Verification commands

```bash
cd /Users/nealsanche/nosuch/nt_helper
dart format lib/poly_multisample/wav_metadata.dart test/poly_multisample/wav_metadata_test.dart lib/ui/poly_multisample/widgets/poly_waveform_editor.dart test/poly_multisample/widgets/poly_waveform_editor_test.dart lib/ui/poly_multisample/widgets/poly_sample_inspector.dart test/poly_multisample/widgets/poly_sample_inspector_test.dart lib/ui/poly_multisample/poly_multisample_builder_cubit.dart test/poly_multisample/poly_multisample_builder_cubit_test.dart
flutter analyze
flutter test test/poly_multisample/wav_metadata_test.dart test/poly_multisample/widgets/poly_waveform_editor_test.dart test/poly_multisample/widgets/poly_sample_inspector_test.dart test/poly_multisample/poly_multisample_builder_cubit_test.dart
flutter test
rg -n "WavFadeCurvePoint|WavFadePreview|fadeInFrames|fadeOutFrames|Fade preview:|_samplePreviewCache|_samplePreviewRenderInFlight|_renderedSamplePreviewPath|_samplePreviewSourcePlayback" lib/poly_multisample/wav_metadata.dart lib/ui/poly_multisample/widgets/poly_waveform_editor.dart lib/ui/poly_multisample/widgets/poly_sample_inspector.dart lib/ui/poly_multisample/poly_multisample_builder_cubit.dart test/poly_multisample/wav_metadata_test.dart test/poly_multisample/widgets/poly_waveform_editor_test.dart test/poly_multisample/widgets/poly_sample_inspector_test.dart test/poly_multisample/poly_multisample_builder_cubit_test.dart
git add lib/poly_multisample/wav_metadata.dart test/poly_multisample/wav_metadata_test.dart lib/ui/poly_multisample/widgets/poly_waveform_editor.dart test/poly_multisample/widgets/poly_waveform_editor_test.dart lib/ui/poly_multisample/widgets/poly_sample_inspector.dart test/poly_multisample/widgets/poly_sample_inspector_test.dart lib/ui/poly_multisample/poly_multisample_builder_cubit.dart test/poly_multisample/poly_multisample_builder_cubit_test.dart
git status --short
git commit -m "feat(poly-samples): preview fades on waveform and playback"
```

### Leftover checks

- No symbols are moved in this step.
- `rg -n "PolyWaveformEditor\(" lib test` shows every constructor call compiles with the new optional fade parameters.
- `rg -n "_samplePreviewCache\.clear\(\)|_samplePreviewRenderInFlight\.clear\(\)|_samplePreviewRenderInFlight\.remove" lib/ui/poly_multisample/poly_multisample_builder_cubit.dart` prints the cache cleanup and in-flight cleanup sites.
- `git status --short` before commit shows only the eight files named in this step.

### Commit message

`feat(poly-samples): preview fades on waveform and playback`
