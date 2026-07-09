# Plan: improve-the-nt-helper-sample-editor-ux-based-on

Total steps: 3

Read `specs/conventions.md` and `specs/improve-the-nt-helper-sample-editor-ux-based-on/spec.md` completely before starting each step. Execute one numbered step per fresh-context session. Do not start a later step early.

Program-level verification after STEP 3:

```bash
cd /Users/nealsanche/nosuch/nt_helper
flutter analyze
flutter test
```

## STEP 1 of 3 — keep edit order stable and make destructive actions selection-first

### Spec section

`spec.md` → "Decided behavior" items 1, 3, and 6.

### Files to edit

- `lib/ui/poly_multisample/poly_region_math.dart`
- `lib/ui/poly_multisample/poly_multisample_builder_cubit.dart`
- `lib/ui/poly_multisample/poly_samples_editor_view.dart`
- `test/poly_multisample/poly_region_math_test.dart`
- `test/poly_multisample/poly_multisample_builder_cubit_test.dart`
- `test/poly_multisample/poly_samples_editor_view_test.dart`

### Mechanical edits

1. Add a public pure helper named `mappingWarnings(List<PolySampleRegion> regions)` to `lib/ui/poly_multisample/poly_region_math.dart`.
   - The helper returns deterministic warning strings in input order.
   - Emit `Mapping impossible: <displayName> has low <low> above high <high>.` when a region’s effective low is greater than its effective high.
   - Emit `Mapping overlap: <a.displayName> overlaps <b.displayName> on velocity <lane>, RR <rr>.` for every overlapping pair that shares the same velocity lane and round-robin lane.
2. Import `package:nt_helper/ui/poly_multisample/poly_region_math.dart` into `lib/ui/poly_multisample/poly_multisample_builder_cubit.dart`.
3. In `_setInstrument`, append the current `mappingWarnings(instrument.regions)` output to the loaded warnings after stripping any prior `Mapping impossible:` and `Mapping overlap:` entries.
4. In `_replaceEditedRegions`, stop calling `PolyMultisampleParser.sortRegions(regions)`. Preserve the incoming order exactly as passed in. Rebuild warnings with the same strip-and-append rule used by `_setInstrument`.
5. Leave selection and focus pruning in `_replaceEditedRegions` unchanged except for the warning rebuild.
6. In `lib/ui/poly_multisample/poly_samples_editor_view.dart`, make the primary destructive toolbar action selection-sensitive.
   - When `state.selectedPaths.isNotEmpty`, the button text, tooltip, and semantics label are `Unmap selected` and the tap handler calls `cubit.removeSelectedRegions()`.
   - When `state.selectedPaths.isEmpty`, the button text, tooltip, and semantics label are `Discard all` and the tap handler opens a confirmation dialog titled `Discard all?` with body `This reverts every sample in the draft.`.
   - The confirmation dialog has `Cancel` and `Discard all` actions; the confirm action calls `cubit.discardChanges()`.
   - Leave the `Clear all` popup action present and explicit.
7. Add `test('mappingWarnings reports overlap and impossible ranges', ...)` to `test/poly_multisample/poly_region_math_test.dart`.
8. Add `test('edited regions stay in insertion order after mapping edits', ...)` to `test/poly_multisample/poly_multisample_builder_cubit_test.dart`.
9. Add `testWidgets('destructive toolbar action unmaps only the selection when rows are selected', ...)` and `testWidgets('discard all asks for confirmation before resetting the draft', ...)` to `test/poly_multisample/poly_samples_editor_view_test.dart`.

### Verification commands

```bash
cd /Users/nealsanche/nosuch/nt_helper
dart format lib/ui/poly_multisample/poly_region_math.dart lib/ui/poly_multisample/poly_multisample_builder_cubit.dart lib/ui/poly_multisample/poly_samples_editor_view.dart test/poly_multisample/poly_region_math_test.dart test/poly_multisample/poly_multisample_builder_cubit_test.dart test/poly_multisample/poly_samples_editor_view_test.dart
flutter analyze
flutter test test/poly_multisample/poly_region_math_test.dart test/poly_multisample/poly_multisample_builder_cubit_test.dart test/poly_multisample/poly_samples_editor_view_test.dart
rg -n "sortRegions\(regions\)|Mapping impossible:|Mapping overlap:|Unmap selected|Discard all\?" lib/ui/poly_multisample/poly_region_math.dart lib/ui/poly_multisample/poly_multisample_builder_cubit.dart lib/ui/poly_multisample/poly_samples_editor_view.dart test/poly_multisample/poly_region_math_test.dart test/poly_multisample/poly_multisample_builder_cubit_test.dart test/poly_multisample/poly_samples_editor_view_test.dart
git add -A
git status --short
git commit -m "fix(poly-samples): keep edit order stable and selection-first discard"
```

### Leftover checks

- No symbols move in this step.
- `rg -n "sortRegions\(regions\)" lib/ui/poly_multisample/poly_multisample_builder_cubit.dart` prints no hits.
- `rg -n "mappingWarnings\(" lib/ui/poly_multisample/poly_region_math.dart lib/ui/poly_multisample/poly_multisample_builder_cubit.dart` prints at least one hit in both files.
- `git status --short` before commit shows only the files named in this step.

### Commit message

`fix(poly-samples): keep edit order stable and selection-first discard`

## STEP 2 of 3 — add selection-wide mapping controls and root menu

### Spec section

`spec.md` → "Decided behavior" items 4, 5, and 6.

### Files to edit

- `lib/ui/poly_multisample/poly_multisample_builder_cubit.dart`
- `lib/ui/poly_multisample/widgets/poly_sample_inspector.dart`
- `test/poly_multisample/poly_multisample_builder_cubit_test.dart`
- `test/poly_multisample/widgets/poly_sample_inspector_test.dart`

### Mechanical edits

1. Add `void updateSelectedMappings({int? rootMidi, int? rangeLow, int? rangeHigh, int? velocityLayer, int? roundRobin, IDistingMidiManager? manager})` to `PolyMultisampleBuilderCubit`.
   - Return immediately when `state.selectedPaths` is empty.
   - Apply every non-null field to every selected path in one `_replaceEditedRegions` call.
   - Keep `focusedPath` unchanged when it still belongs to the selected set.
   - After the emit, when `state.autoPreview` is true and the focused selected path is a local or mounted WAV, preview that focused path once through the existing auto-preview path.
2. In `lib/ui/poly_multisample/widgets/poly_sample_inspector.dart`, keep the current selected-region lookup and add selection-wide editing rules.
   - When `state.selectedPaths` is non-empty, the mapping controls operate on that set.
   - When `state.selectedPaths` is empty, the controls operate on the focused region only.
   - The root row uses a `PopupMenuButton<int>` with tooltip `Choose root note` and menu items for MIDI 0 through 127, rendered with `PolyMultisampleParser.midiToNoteName`.
   - The visible root value is the uniform selected value or `Mixed`.
   - The visible low, high, velocity, and RR values are the uniform selected values or `Mixed`.
   - Every +/- stepper in the mapping section routes through `updateSelectedMappings`.
3. Keep the existing previous/next sample buttons, preview button, and reveal button unchanged.
4. Update `test/poly_multisample/widgets/poly_sample_inspector_test.dart`.
   - Change `_selectedState` so it accepts optional `selectedPaths` and `focusedPath` parameters.
   - Add `test('updateSelectedMappings applies a note menu choice to every selected sample', ...)`.
   - Add `test('mixed mapping rows show Mixed for a multi-selection', ...)`.
   - Add `test('bulk mapping controls update all selected samples together', ...)`.
5. Update `test/poly_multisample/poly_multisample_builder_cubit_test.dart` with `test('updateSelectedMappings keeps the focused path when it remains selected', ...)`.

### Verification commands

```bash
cd /Users/nealsanche/nosuch/nt_helper
dart format lib/ui/poly_multisample/poly_multisample_builder_cubit.dart lib/ui/poly_multisample/widgets/poly_sample_inspector.dart test/poly_multisample/poly_multisample_builder_cubit_test.dart test/poly_multisample/widgets/poly_sample_inspector_test.dart
flutter analyze
flutter test test/poly_multisample/poly_multisample_builder_cubit_test.dart test/poly_multisample/widgets/poly_sample_inspector_test.dart
rg -n "updateSelectedMappings|Choose root note|Mixed" lib/ui/poly_multisample/poly_multisample_builder_cubit.dart lib/ui/poly_multisample/widgets/poly_sample_inspector.dart test/poly_multisample/poly_multisample_builder_cubit_test.dart test/poly_multisample/widgets/poly_sample_inspector_test.dart
git add -A
git status --short
git commit -m "feat(poly-samples): add selection-wide mapping controls"
```

### Leftover checks

- No symbols move in this step.
- `rg -n "void updateSelectedMappings\(" lib/ui/poly_multisample/poly_multisample_builder_cubit.dart` prints exactly one declaration.
- `rg -n "Choose root note" lib/ui/poly_multisample/widgets/poly_sample_inspector.dart` prints exactly one tooltip.
- `git status --short` before commit shows only the files named in this step.

### Commit message

`feat(poly-samples): add selection-wide mapping controls`

## STEP 3 of 3 — cache waveform previews and show fade curves

### Spec section

`spec.md` → "Decided behavior" items 7 and 8.

### Files to edit

- `lib/ui/poly_multisample/poly_multisample_builder_cubit.dart`
- `lib/ui/poly_multisample/widgets/poly_sample_inspector.dart`
- `lib/ui/poly_multisample/widgets/poly_waveform_editor.dart`
- `test/poly_multisample/poly_multisample_builder_cubit_test.dart`
- `test/poly_multisample/widgets/poly_sample_inspector_test.dart`
- `test/poly_multisample/widgets/poly_waveform_editor_test.dart`

### Mechanical edits

1. Extend `PolyWaveformEditor` with optional fade overlay inputs.
   - Pass the current fade values from the inspector into the widget.
   - In `_PolyWaveformPainter.paint`, draw a visible fade overlay when either fade frame count is non-zero.
   - Add the key `poly-waveform-fade-overlay` to the fade overlay layer.
2. In `lib/ui/poly_multisample/widgets/poly_sample_inspector.dart`, pass `wavEditDraft.fadeInFrames`, `fadeOutFrames`, `fadeInCurve`, `fadeOutCurve`, `fadeInStrength`, and `fadeOutStrength` into `PolyWaveformEditor`.
3. In `lib/ui/poly_multisample/poly_multisample_builder_cubit.dart`, add waveform-preview cache helpers that mirror the existing note-preview cache pattern.
   - Cache the rendered preview path by file path, file stat, and the current preview draft fingerprint.
   - Use `_preparedKeyboardPreviewBytes(path, bytes)` as the source for the cached render.
   - Trigger the cached waveform preview from both `updateLoopDraft` and `updateWavEditDraft` for local or mounted WAV paths with an on-disk file.
   - Keep stale-request protection so a later render replaces an earlier one and the earlier completion cannot overwrite the newer preview state.
   - Clean up cached waveform preview temp roots when the cubit closes or the draft is removed.
4. Add `test('waveform preview cache refreshes when fade settings change', ...)` and `test('stale waveform preview renders do not replace the latest preview', ...)` to `test/poly_multisample/poly_multisample_builder_cubit_test.dart`.
5. Add `testWidgets('waveform editor paints fade overlays', ...)` to `test/poly_multisample/widgets/poly_waveform_editor_test.dart`.
6. Add `testWidgets('fade controls are reflected in the waveform preview overlay', ...)` to `test/poly_multisample/widgets/poly_sample_inspector_test.dart`.

### Verification commands

```bash
cd /Users/nealsanche/nosuch/nt_helper
dart format lib/ui/poly_multisample/poly_multisample_builder_cubit.dart lib/ui/poly_multisample/widgets/poly_sample_inspector.dart lib/ui/poly_multisample/widgets/poly_waveform_editor.dart test/poly_multisample/poly_multisample_builder_cubit_test.dart test/poly_multisample/widgets/poly_sample_inspector_test.dart test/poly_multisample/widgets/poly_waveform_editor_test.dart
flutter analyze
flutter test test/poly_multisample/poly_multisample_builder_cubit_test.dart test/poly_multisample/widgets/poly_sample_inspector_test.dart test/poly_multisample/widgets/poly_waveform_editor_test.dart
rg -n "poly-waveform-fade-overlay|_cachedWaveformPreviewPath|_scheduleWaveformEditPreview|_playWaveformEditPreview" lib/ui/poly_multisample/poly_multisample_builder_cubit.dart lib/ui/poly_multisample/widgets/poly_sample_inspector.dart lib/ui/poly_multisample/widgets/poly_waveform_editor.dart test/poly_multisample/poly_multisample_builder_cubit_test.dart test/poly_multisample/widgets/poly_sample_inspector_test.dart test/poly_multisample/widgets/poly_waveform_editor_test.dart
git add -A
git status --short
git commit -m "feat(poly-samples): cache waveform previews and show fade curves"
```

### Leftover checks

- No symbols move in this step.
- `rg -n "poly-waveform-fade-overlay" lib/ui/poly_multisample/widgets/poly_waveform_editor.dart test/poly_multisample/widgets/poly_waveform_editor_test.dart` prints hits in both files.
- `rg -n "^[[:space:]]*Future<.*> _cachedWaveformPreviewPath\(|^[[:space:]]*Future<.*> _playWaveformEditPreview\(" lib/ui/poly_multisample/poly_multisample_builder_cubit.dart` prints one declaration for each helper.
- `git status --short` before commit shows only the files named in this step.

### Commit message

`feat(poly-samples): cache waveform previews and show fade curves`
