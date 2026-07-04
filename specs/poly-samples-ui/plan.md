# Plan: poly-samples-ui

This plan has **14 steps**. Execute exactly one step per session, in order.
Every step must leave `flutter analyze` clean and the named tests passing.
`specs/poly-samples-ui/spec.md` is the authoritative design — read the
section named by each step before editing. `specs/conventions.md` gives the
verification commands and recovery rules.

Prerequisites: none outside this repo. The fork checkout at
`/tmp/nt_helper_nymph_next_fix.4a28r5/repo` is reference-only; never edit it,
and only read the file a step explicitly names.

Steps 1–5 are pure cubit/model work (no UI). Steps 6–11 build leaf widgets
bottom-up, each with its own test file. Steps 12–13 assemble the views and
screen. Step 14 rewires navigation and deletes the old screen.

---

## STEP 1 of 14 — extend PolyWaveformDraft with fade curve/strength

Spec section: "Step 1 — PolyWaveformDraft new fields".

Files: `lib/poly_multisample/poly_multisample_models.dart`,
`lib/ui/poly_multisample/poly_multisample_builder_cubit.dart`,
`test/poly_multisample/poly_multisample_builder_cubit_test.dart`.

1. Add the four fields + defaults to `PolyWaveformDraft` and the twelve-field
   `copyWith` with the five clear-flags, exactly as the spec's table states.
   Add `import 'wav_metadata.dart';` to the models file.
2. In `PolyMultisampleBuilderCubit.saveDestructiveWav`, pass the four new
   draft fields into `WavRenderOptions` as the spec shows.
3. Append one test to the existing `group` in the cubit test file:
   `test('saveDestructiveWav forwards fade curve and strength', ...)` —
   construct a `PolyWaveformDraft(fadeInCurve: WavFadeCurve.sCurve,
   fadeOutCurve: WavFadeCurve.equalPower, fadeInStrength: 0.8,
   fadeOutStrength: 0.2)` and assert `copyWith()` preserves all four, and
   `copyWith(clearNormalize: true)` nulls `normalizePeakDb` while keeping
   the fades. (A pure model test — no file IO.)

Verify per conventions; test file:
`flutter test test/poly_multisample/poly_multisample_builder_cubit_test.dart`.

Leftover check: `rg -n "fadeInCurve" lib/poly_multisample/poly_multisample_models.dart lib/ui/poly_multisample/poly_multisample_builder_cubit.dart`
must show hits in BOTH files.

Commit message: `feat(poly): add fade curve and strength to PolyWaveformDraft`

---

## STEP 2 of 14 — wire PolySamplePreferencesService into the builder cubit

Spec section: "Step 2 — preferences wiring".

Files: `lib/ui/poly_multisample/poly_multisample_builder_cubit.dart`,
`test/poly_multisample/poly_multisample_builder_cubit_test.dart`.

1. Add the optional `preferencesService` constructor param, `_prefs()`
   memoizer, `_loadPreferences()` startup call, the three persistence hooks,
   and the two `remember*` methods — exactly per the spec. Import
   `package:nt_helper/poly_multisample/poly_sample_preferences_service.dart`.
2. Tests (append to the existing group; use
   `SharedPreferences.setMockInitialValues({...})` from
   `package:shared_preferences/shared_preferences.dart` and construct the
   service via `PolySamplePreferencesService.create()`):
   - `test('loads remembered folders into state on construction', ...)` —
     seed `{'poly_multisample.lastLocalFolder': '/tmp/a',
     'poly_multisample.lastWavExportFolder': '/tmp/b'}`, build the cubit
     with the created service, `await Future<void>.delayed(Duration.zero);`,
     assert `state.lastLocalFolder == '/tmp/a'` and
     `state.lastWavExportFolder == '/tmp/b'`.
   - `test('rememberSourceFolder persists and emits', ...)` — empty seed,
     call `await cubit.rememberSourceFolder('/tmp/src')`, assert
     `state.lastSourceFolder == '/tmp/src'` and the service getter returns it.

Verify; test file:
`flutter test test/poly_multisample/poly_multisample_builder_cubit_test.dart`.

Commit message: `feat(poly): remember sample folders via PolySamplePreferencesService`

---

## STEP 3 of 14 — adoptStagedImport / addStagedRegions on the builder cubit

Spec section: "Step 3 — staged-import adoption".

Files: `lib/ui/poly_multisample/poly_multisample_builder_cubit.dart`,
`test/poly_multisample/poly_multisample_builder_cubit_test.dart`.

1. Implement both methods exactly per the spec; refactor `_stageImport`'s
   success path to call `adoptStagedImport`.
2. Tests (append; build `PolyStagedImport` values inline with fake regions —
   `PolySampleRegion(path: ..., fileName: ..., displayName: ...)`):
   - `test('adoptStagedImport sets an import draft instrument', ...)` —
     staged with 2 regions and one warning; assert `sourceMode ==
     PolySampleSourceMode.importDraft`, `editedRegions.length == 2`,
     `warnings` contains the warning, `currentInstrument!.name == staged.name`.
   - `test('addStagedRegions merges without duplicating paths', ...)` —
     first `adoptStagedImport` with regions A,B; then `addStagedRegions`
     with regions B,C; assert `editedRegions` paths == {A,B,C} and length 3.
   - `test('addStagedRegions is a no-op without an instrument', ...)` —
     fresh cubit, call it, assert state unchanged
     (`currentInstrument == null`, `editedRegions` empty).

Verify; test file:
`flutter test test/poly_multisample/poly_multisample_builder_cubit_test.dart`.

Commit message: `feat(poly): adopt and merge staged imports in builder cubit`

---

## STEP 4 of 14 — extract public region math (poly_region_math.dart)

Spec section: "Step 4 — poly_region_math.dart".

Files: NEW `lib/ui/poly_multisample/poly_region_math.dart`,
NEW `test/poly_multisample/poly_region_math_test.dart`.

1. Copy the five private helpers from the BOTTOM of
   `lib/ui/poly_multisample/poly_multisample_builder_screen.dart`
   (`_selectedRegionFor`, `_effectiveLow`, `_effectiveHigh`, `_midiExtents`,
   `_velocityLanes`) into the new file with the public names from the spec's
   table. Bodies verbatim except renaming internal cross-calls to the public
   names. Do NOT edit the old screen file.
2. Test file: group `'poly region math'` with:
   - `test('effectiveLow falls back through switchPoint and root', ...)` —
     three regions covering `rangeLow` set, only `switchPoint` set, only
     `rootMidi` set; assert each.
   - `test('effectiveHigh uses next lane low minus one', ...)` — two mapped
     regions same velocity lane, lows 48 and 60, no explicit highs; assert
     `effectiveHigh(first, regions) == 59` and second == 127.
   - `test('midiExtents returns null for unmapped regions', ...)`.
   - `test('velocityLanes returns descending distinct lanes', ...)` —
     regions with layers 1,2,2,null (null counts as 1); expect `[2, 1]`.
   - `test('selectedRegionFor prefers focusedPath', ...)` — build a
     `PolyMultisampleBuilderState` with two edited regions, `focusedPath`
     on the second; assert it wins; with no focus and a selectedPaths entry,
     that wins; with neither, the first region.

Verify; test file:
`flutter test test/poly_multisample/poly_region_math_test.dart`.

Symbol count: the new file declares exactly 5 public functions.

Commit message: `refactor(poly): extract shared region math helpers`

---

## STEP 5 of 14 — full DecentSamplerConvertOptions surface on PolyDecentImportCubit

Spec section: "Step 5 — PolyDecentImportCubit full options".

Files: `lib/ui/poly_multisample/poly_decent_import_cubit.dart`,
`test/poly_multisample/poly_decent_import_cubit_test.dart`.

1. Add the ten state fields, ten mutator methods, `analyzeSource` seeding,
   tag-overlap warnings, and the full `continueImport` options object —
   exactly per the spec's tables.
2. Tests (append to the existing group, reusing the file's existing
   `_FakeImportService` fixture — read the test file first). Add a field
   `DecentSamplerConvertOptions? lastOptions;` to `_FakeImportService` and
   set `lastOptions = options;` inside its `stageDecentSource` override.
   The existing `_overlappingAnalysis()` fixture has `tags: []`; for the tag
   tests below, build a second fixture `_taggedAnalysis()` — copy
   `_overlappingAnalysis()` and give it two `DecentSamplerTag` entries
   (keys `'tag:soft'`, `'tag:hard'`, labels `'soft'`/`'hard'`, each with
   `groupKeys` naming one group, `sampleCount: 2`, `confidence: 1.0`,
   `evidence: ''`, the same structure/note/velocity/RR summary strings
   as the groups, defaults low 60 / root 60 / high 61, velocity layer 1) and
   `recommendedGroupHandling: DecentSamplerGroupHandling.selectedTags`.
   Tests:
   - `test('analyzeSource seeds tag ranges and preset selection', ...)`.
   - `test('setTagRange recomputes overlap warnings under selectedTags', ...)`
     — two selected tags with overlapping ranges → non-empty warnings;
     disjoint → empty.
   - `test('continueImport forwards the full option set', ...)` — use
     `_taggedAnalysis()` with non-overlapping tag ranges, set
     `preserveXmlMapping`/`addUnmapped` true, select one tag, set one tag
     round-robin; after `continueImport`, assert those four values on
     `service.lastOptions!`.

Verify; test file:
`flutter test test/poly_multisample/poly_decent_import_cubit_test.dart`.

Commit message: `feat(poly): expose full Decent Sampler options in import cubit`

---

## STEP 6 of 14 — PolyKeyMap widget

Spec section: "Step 6 — PolyKeyMap".

Files: NEW `lib/ui/poly_multisample/widgets/poly_key_map.dart`,
NEW `test/poly_multisample/widgets/poly_key_map_test.dart`.

1. Build the widget per the spec. The painter/layout/hit-test code is COPIED
   from `_SimpleKeyboardPainter`, `_KeyboardLayout`, and
   `_regionAtKeyboardPosition` in
   `lib/ui/poly_multisample/poly_multisample_builder_screen.dart` (renamed
   per the spec; rewired to `poly_region_math.dart`). Do not edit the old
   file.
2. Tests (pump inside `MaterialApp(home: Scaffold(body: SizedBox(width: 800,
   height: 200, child: PolyKeyMap(height: 200, ...))))` — pass `height: 200`
   explicitly so the tap math below is exact):
   - `testWidgets('exposes a keyboard map semantics label', ...)` — two
     mapped regions → `find.bySemanticsLabel('Keyboard map with 2 mapped
     samples')` (use `tester.ensureSemantics()`).
   - `testWidgets('tap on a mapped zone selects the region', ...)` — one
     region rooted at C3 spanning the full range (rangeLow 0, rangeHigh
     127). Compute the tap point from the layout constants rather than the
     widget center: with the copied `_PolyKeyMapLayout(size, const [1])`
     the zone strip runs from `zoneTop` (24) to `zoneBottom`
     (`height - 42 - 8`), so tap at
     `tester.getTopLeft(find.byType(PolyKeyMap)) + Offset(width / 2,
     (24 + (height - 50)) / 2)` where width/height are the SizedBox
     dimensions from the pump (800×200). Assert the `onSelect` callback
     received that region.
   - `testWidgets('renders without mapped regions', ...)` — empty list, no
     exceptions, one `CustomPaint` under `find.byType(PolyKeyMap)`.

Verify; test file:
`flutter test test/poly_multisample/widgets/poly_key_map_test.dart`.

Commit message: `feat(poly): add PolyKeyMap keyboard map widget`

---

## STEP 7 of 14 — PolySampleList widget

Spec section: "Step 7 — PolySampleList".

Files: NEW `lib/ui/poly_multisample/widgets/poly_sample_list.dart`,
NEW `test/poly_multisample/widgets/poly_sample_list_test.dart`.

1. Build per the spec (info-only rows, modifier-key selection modes,
   scroll-to-focus, preview button).
2. Tests:
   - `testWidgets('renders region info and selected semantics', ...)` — two
     regions, one selected; assert subtitle text contains
     `'Root C3'` for the mapped one and `'Root unmapped'` for the other;
     with `tester.ensureSemantics()` assert the selected row's semantics
     label `'<displayName>, root C3'` exists.
   - `testWidgets('plain tap emits replace mode', ...)` — tap a row, assert
     callback got `PolyRegionSelectionMode.replace`.
   - `testWidgets('preview button disabled for non-wav files', ...)` — a
     region with path ending `.aif`; the trailing IconButton's `onPressed`
     is null.

Verify; test file:
`flutter test test/poly_multisample/widgets/poly_sample_list_test.dart`.

Commit message: `feat(poly): add PolySampleList widget`

---

## STEP 8 of 14 — PolySampleInspector (header, preview, mapping, loop points)

Spec section: "Step 8 — PolySampleInspector" (sections 1–4 only; section 5
is step 9).

Files: NEW `lib/ui/poly_multisample/widgets/poly_sample_inspector.dart`,
NEW `test/poly_multisample/widgets/poly_sample_inspector_test.dart`.

1. Build sections 1–4 per the spec. Where step 9's 'Edit audio' tile would
   go, leave nothing (it is added in step 9 — do not scaffold it).
2. Tests: pump with a real `PolyMultisampleBuilderCubit` provided via
   `BlocProvider.value` — copy the `_TestPolyMultisampleBuilderCubit` +
   `_FakePreviewAdapter` pattern from
   `test/poly_multisample/poly_multisample_builder_screen_test.dart`
   (define local copies in this test file; do not import that test file).
   Seed a state with one local instrument of two regions (roots C3, C4),
   `selectedPaths`/`focusedPath` on the first.
   - `testWidgets('shows mapping steppers for the selected sample', ...)` —
     `find.text('Root: C3')`, `find.text('Velocity: 1')`,
     `find.byTooltip('Increase Root')` each `findsOneWidget`.
   - `testWidgets('root stepper updates the cubit', ...)` — tap
     `'Increase Root'`, assert the cubit's edited region rootMidi is 49
     and `find.text('Root: C#3')` appears after `pump`.
   - `testWidgets('next sample navigates selection', ...)` — tap tooltip
     `'Next sample'`, assert `state.focusedPath` is the second region's path.
   - `testWidgets('shows empty message with no selection', ...)` — state
     with no regions → `find.text('No sample selected')`.
   - `testWidgets('loop editing gated for hardware paths', ...)` — hardware
     sourceMode + path starting `/samples/` → expand the `'Loop points'`
     tile → `find.text('Loop editing needs a local or mounted folder.')`.

Verify; test file:
`flutter test test/poly_multisample/widgets/poly_sample_inspector_test.dart`.

Commit message: `feat(poly): add PolySampleInspector with mapping and loop sections`

---

## STEP 9 of 14 — PolyWaveformEditor + 'Edit audio' section

Spec sections: "Step 9 — PolyWaveformEditor" and inspector section 5.

Files: NEW `lib/ui/poly_multisample/widgets/poly_waveform_editor.dart`,
`lib/ui/poly_multisample/widgets/poly_sample_inspector.dart` (add section 5),
NEW `test/poly_multisample/widgets/poly_waveform_editor_test.dart`,
`test/poly_multisample/widgets/poly_sample_inspector_test.dart` (append).

1. Build `PolyWaveformEditor` per the spec, then add the 'Edit audio'
   `ExpansionTile` to the inspector per spec section 5.
2. Waveform editor tests (construct a `WavOverview` directly:
   `sampleRate: 44100, frameCount: 1000, peaks: [40 × WavPeak(min: -0.5,
   max: 0.5)], zeroCrossings: [0, 250, 500, 750, 999]`):
   - `testWidgets('drag near start handle emits snapped frames', ...)` —
     trim mode, start 0, end 999, width 400: drag from x≈0 to x≈100;
     assert `onChanged` was called and the final startFrame is one of the
     zeroCrossings values (snapping) and < endFrame.
   - `testWidgets('has waveform editor semantics', ...)` —
     `find.bySemanticsLabel('Waveform editor')`.
3. Inspector test additions:
   - `testWidgets('edit audio section shows editor and save buttons', ...)`
     — seed `waveformSummaries` with the fake overview for the selected
     path, expand `'Edit audio'`; expect `find.byType(PolyWaveformEditor)`,
     `find.text('Save as…')`, `find.text('Overwrite')`.
   - `testWidgets('gain slider updates the wav edit draft', ...)` — drag the
     Gain slider; assert `state.wavEditDrafts[path]!.gainDb != 0`.

Verify; test files:
`flutter test test/poly_multisample/widgets/poly_waveform_editor_test.dart test/poly_multisample/widgets/poly_sample_inspector_test.dart`.

Commit message: `feat(poly): add waveform editor and destructive edit section`

---

## STEP 10 of 14 — loose WAV import dialog

Spec section: "Step 10 — loose WAV dialog".

Files: NEW `lib/ui/poly_multisample/dialogs/poly_loose_wav_import_dialog.dart`,
NEW `test/poly_multisample/dialogs/poly_loose_wav_import_dialog_test.dart`.

1. Build per the spec.
2. Tests (open via a test button that calls
   `showPolyLooseWavImportDialog`; paths need not exist on disk for
   selection/mapping tests):
   - `testWidgets('lists files and mapping modes', ...)` — two paths;
     expect both basenames, all five mode labels, `'All'`, `'None'`.
   - `testWidgets('start note row appears for chromatic mode', ...)` —
     select `'Spread chromatically from start note'`; expect
     `find.textContaining('Start note: C4')` (default startMidi 60 → `'C4'`
     per `PolyMultisampleParser.midiToNoteName(60)`).
   - `testWidgets('cancel returns null', ...)` — tap `'Cancel'`, assert the
     awaited result is null.

Verify; test file:
`flutter test test/poly_multisample/dialogs/poly_loose_wav_import_dialog_test.dart`.

Commit message: `feat(poly): add loose WAV import dialog`

---

## STEP 11 of 14 — Decent Sampler import dialog

Spec section: "Step 11 — Decent dialog".

Files: NEW `lib/ui/poly_multisample/dialogs/poly_decent_import_dialog.dart`,
NEW `test/poly_multisample/dialogs/poly_decent_import_dialog_test.dart`.

1. Build per the spec. The dialog reads everything from
   `PolyDecentImportCubit`; the optional `previewCubit` drives row preview
   buttons only.
2. Tests: drive the cubit directly — provide the dialog's content widget
   (`_PolyDecentImportDialog` is private; instead pump
   `showPolyDecentImportDialog` with a fake import service injected...).
   Since `showPolyDecentImportDialog` constructs its own cubit, add an
   optional param `@visibleForTesting PolyDecentImportCubit? cubit` to the
   function; when non-null use `BlocProvider.value(value: cubit)` and skip
   `analyzeSource`. Tests then use a test cubit subclass with a public
   `setTestState` (same pattern as earlier steps) seeded with a
   `DecentSamplerImportAnalysis` fixture (2 presets, 2 groups, 2 tags —
   construct inline with minimal string fields).
   - `testWidgets('shows analysis summary and handling modes', ...)` —
     expect the structure summary text and all seven handling labels.
   - `testWidgets('selectedTags mode reveals per-tag range steppers', ...)`
     — set handling `selectedTags` and one tag selected; expect that tag's
     Low/Root/High steppers (`find.byTooltip('Increase Low')` at least one).
   - `testWidgets('import disabled while warnings present', ...)` — state
     with a warning; the `'Import'` `FilledButton`'s `onPressed` is null.

Verify; test file:
`flutter test test/poly_multisample/dialogs/poly_decent_import_dialog_test.dart`.

Commit message: `feat(poly): add Decent Sampler import dialog`

---

## STEP 12 of 14 — landing and editor views

Spec section: "Step 12 — landing + editor views".

Files: NEW `lib/ui/poly_multisample/poly_samples_landing_view.dart`,
NEW `lib/ui/poly_multisample/poly_samples_editor_view.dart`,
NEW `test/poly_multisample/poly_samples_editor_view_test.dart`.

1. Build `PolySamplesLandingView`, `PolyHardwareFolderList`,
   `PolyLargeFolderView`, and `PolySamplesEditorView` per the spec.
2. Tests (editor view; same test-cubit pattern as step 8; wide surface —
   wrap in `SizedBox(width: 1200, height: 800)`):
   - `testWidgets('shows toolbar stats, key map, list and inspector', ...)`
     — local instrument, 2 regions, one mapped; expect `'2 samples'`,
     `'1 mapped'`, `find.byType(PolyKeyMap)`, `find.byType(PolySampleList)`,
     `find.byType(PolySampleInspector)` each present.
   - `testWidgets('draft mode shows Save As instead of Apply', ...)` —
     `sourceMode: PolySampleSourceMode.importDraft` → `find.text('Save As…')`
     and `find.text('Apply')` findsNothing.
   - `testWidgets('dirty state enables Apply and Discard', ...)` — local
     mode with `baselineRegions` differing from `editedRegions`; both
     buttons enabled (`onPressed != null`); `find.text('Unsaved changes')`.
   - `testWidgets('landing shows three source cards and empty draft', ...)`
     — pump `PolySamplesLandingView` with a default state; expect
     `'NT Hardware'`, `'Local Folder'`, `'Import Files'`,
     `'Start empty draft'`, and the header
     `'Build or edit a Disting NT multisample folder'`.

Verify; test file:
`flutter test test/poly_multisample/poly_samples_editor_view_test.dart`.

Commit message: `feat(poly): add samples landing and editor views`

---

## STEP 13 of 14 — PolySamplesScreen

Spec section: "Step 13 — PolySamplesScreen".

Files: NEW `lib/ui/poly_multisample/poly_samples_screen.dart`,
NEW `test/poly_multisample/poly_samples_screen_test.dart`.

1. Build the screen per the spec (BlocConsumer with the verbatim
   listener copy, PopScope dirty guard, body dispatch, flow helpers).
2. Tests. Mock `DistingCubit` with mocktail
   (`class MockDistingCubit extends Mock implements DistingCubit {}`) and
   stub `disting()` to return null. Provide the builder cubit via
   `BlocProvider.value` around `PolySamplesView` (same injection style as
   the current screen test). Port these four tests from
   `test/poly_multisample/poly_multisample_builder_screen_test.dart`,
   adapted to the new widget names (read that file first; keep the assertion
   logic identical unless a label changed in the spec):
   - the stale-announcement test (`'does not re-announce stale success when
     clearing an error'`) — verbatim port, pumping `PolySamplesView`.
   - the hardware-empty-state test — same expectation
     (`'No sample folders found on /samples.'`).
   - a landing test replacing the old `'shows source states...'` test:
     expect AppBar title `'Samples'` and the three landing cards.
   - a keyboard-editor test replacing the old back-button test: seed the
     Piano state from the old test; expect
     `find.bySemanticsLabel('Keyboard map with 1 mapped samples')` and
     `find.text('Root: C3')`; tap tooltip `'Back to sample sources'`;
     expect the landing header and `state.currentInstrument == null`.
   Plus one new test:
   - `testWidgets('pop is guarded while dirty', ...)` — push the view onto a
     navigator, seed a dirty state (baseline ≠ edited), trigger a system
     back (`(tester.state(find.byType(Navigator)) as NavigatorState)
     .maybePop()`), pump, expect `find.text('Discard changes?')`; tap
     `'Cancel'`; the view is still present.

Verify; test file:
`flutter test test/poly_multisample/poly_samples_screen_test.dart`.

Commit message: `feat(poly): add standalone PolySamplesScreen`

---

## STEP 14 of 14 — rewire navigation, delete the old screen

Spec section: "Step 14 — navigation rewire". This step edits
`lib/ui/synchronized_screen.dart`, deletes two files, and edits one test
file — nothing else.

Files: `lib/ui/synchronized_screen.dart`,
`test/ui/synchronized_screen_bottom_bar_test.dart`,
DELETE `lib/ui/poly_multisample/poly_multisample_builder_screen.dart`,
DELETE `test/poly_multisample/poly_multisample_builder_screen_test.dart`.

1. Apply spec items 1–7 to `synchronized_screen.dart` in order (enum,
   imports, build-method cleanup, method deletion, segmented button, new
   IconButton, switch arm).
2. Delete the two files (spec item 8).
3. Update the bottom-bar test per spec item 9.
4. Leftover check — ALL of these must print nothing:

   ```bash
   rg -n "EditMode.samples" lib test
   rg -n "PolyMultisampleBuilderScreen|PolyMultisampleBuilderView" lib test
   rg -n "_buildSamplesWorkspace|showSamplesWorkspace" lib
   ```

Verify per conventions; test files:
`flutter test test/ui/synchronized_screen_bottom_bar_test.dart test/poly_multisample`.

Commit message: `feat(poly)!: move Samples to a standalone screen and drop EditMode.samples`
