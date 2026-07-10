# Plan: poly-sample-firmware-mapping

This plan has **7 steps**. Execute exactly one step per fresh-context session,
in order. `specs/poly-sample-firmware-mapping/spec.md` is authoritative;
`specs/conventions.md` supplies repo-wide formatting, import, accessibility,
failure, and recovery rules.

Every step must leave `flutter analyze` clean, its focused tests passing, and
the full `flutter test` suite passing before the exact step commit is created.
Completing STEP 1-6 does not complete this plan.

Prerequisites: none outside this repo. The official manuals linked by the spec
are read-only authority. Do not edit generated files.

Program-level final verification after STEP 7:

```bash
flutter analyze && flutter test
```

Expected completion commits, exactly one per step in this order:

1. `feat(poly-samples): model firmware automatic mappings`
2. `fix(poly-samples): recognize firmware automatic notes`
3. `fix(poly-samples): resolve sample mappings in Cubit state`
4. `fix(poly-samples): render resolved keyboard mappings`
5. `fix(poly-samples): show resolved sample rows`
6. `fix(poly-samples): expose automatic mappings in editor`
7. `fix(poly-samples): persist firmware-shaped mapping edits`

---

## STEP 1 of 7 - add the pure firmware mapping resolver

Spec sections: `Official authority and exact interpretation`, `Deterministic
resolver contract`, `New domain interfaces`.

Files:

- NEW `lib/poly_multisample/poly_sample_mapping_resolver.dart`
- NEW `test/poly_multisample/poly_sample_mapping_resolver_test.dart`

Mechanical edits:

1. Create the resolver file with exactly the five exported top-level
   declarations from the spec: `PolySampleMappingIssueKind`,
   `PolySampleMappingIssue`, `PolySampleResolvedMapping`,
   `PolySampleMappingResolution`, and `PolySampleMappingResolver`.
2. Use exactly the three imports listed in the spec. Do not import the parser,
   Cubit, Flutter, or UI helpers.
3. Implement the rootless-family key procedure literally. Strip `_Vn` and
   `_RRn`; do not strip `_SWn`; preserve relative parent paths; sort by
   case-folded key then exact key. Resolver input order must not affect family
   ordinals.
4. Assign rootless families `48 + ordinal`; explicit roots do not consume an
   ordinal and occupied notes are not skipped. Keep natural values above 127
   in `naturalMidi`, set their Low/High null, mark them unplayable, and add
   `naturalOutOfMidiRange`.
5. Implement `automaticSwitchPoint` from the exact intervening-gap formula.
   Throw `ArgumentError` for non-increasing naturals.
6. Resolve global distinct-natural neighbours. Do not partition the switch
   calculation by velocity or RR.
7. Apply explicit `switchPoint` before automatic Low without clamping parsed
   values. For the preceding natural, use one less than the next group's
   minimum resolved Low. Leave impossible `low > high` values intact.
8. Generate the six issue kinds in the exact three-phase ordering required by
   the spec. Emit each pair issue once with the lower source index as
   `mapping`, and make `issuesForPath` return it for both participants.
9. Keep `mappings` in source-list order and expose an unmodifiable by-path map,
   per-path issues, playable list, count, warning count, descending velocity
   lanes, and MIDI extents.
10. Reject duplicate paths with the exact `ArgumentError` message from the
    spec; add test `duplicate region paths are rejected`.
11. Create tests with these exact names and assertions:
    - `automatic switch matches manual gaps zero through six`: parameterize
      lower 60 and intervening gaps 0-6; expect higher naturals
      61-67, Lows `[61, 61, 61, 61, 62, 62, 63]`, and lower Highs
      `[60, 60, 60, 60, 61, 61, 62]`.
    - `first automatic Low is zero and final High is 127`: one rooted sample
      at 60 resolves 0-127.
    - `explicit SW overrides automatic Low and previous High`: roots 60/67,
      higher `switchPoint: 65`; expect lower High 64 and higher Low 65.
    - `EVOS A1 resolves to F1 through B1`: use all ten naturals from the spec;
      assert all Low/High arrays and A1 29-35.
    - `rootless families receive deterministic naturals from C3`: reverse
      input `Tom.wav`, `Snare.wav`, `Kick.wav`; expect Kick/Snare/Tom 48/49/50.
    - `rootless V and RR variants share one natural`: Snare V1/V2 RR1/RR2 all
      48; Tom V1 is 49.
    - `SW remains part of a rootless family key`: `Snare_SW40_V1.wav` and
      `Snare_SW41_V1.wav` receive different automatic naturals.
    - `explicit roots do not consume rootless ordinals`: explicit C3 plus
      rootless Kick gives both natural 48 and an overlap issue.
    - `switch neighbours are global across incomplete velocity layers`: use
      roots 60 V1, 67 V2, 72 V1 and assert the root-67 Low is the same global
      boundary it would have without velocity tags.
    - `automatic natural above MIDI 127 is unresolved`: create 81 unique
      rootless families; ordinal 79 is natural 127/playable, ordinal 80 is
      natural 128 with null Low/High and an out-of-range issue.
    - `different switch values at one natural report variant mismatch`.
    - `same velocity and RR overlap reports an overlap issue`.
    - `out-of-range parsed SW is preserved and reported`: use SW 999; assert
      resolved Low 999 and the exact `switchOutOfMidiRange` issue.
    - `issue order and pair membership are stable`: create single-mapping,
      mismatch, and overlap issues; assert exact kind order and that
      `issuesForPath` returns each pair issue for both paths.

Verification commands:

```bash
cd /Users/nealsanche/nosuch/nt_helper
dart format lib/poly_multisample/poly_sample_mapping_resolver.dart test/poly_multisample/poly_sample_mapping_resolver_test.dart
flutter analyze
flutter test test/poly_multisample/poly_sample_mapping_resolver_test.dart
flutter test
git add lib/poly_multisample/poly_sample_mapping_resolver.dart test/poly_multisample/poly_sample_mapping_resolver_test.dart && git status --short
```

Leftover checks:

```bash
python3 .agents/skills/decision-free-specs/languages/dart/inventory.py lib/poly_multisample/poly_sample_mapping_resolver.dart > /tmp/poly_sample_mapping_resolver_inventory.md
rg -n "PolySampleMappingIssueKind|PolySampleMappingIssue|PolySampleResolvedMapping|PolySampleMappingResolution|PolySampleMappingResolver" /tmp/poly_sample_mapping_resolver_inventory.md
```

The inventory must list exactly 5 exported top-level declarations. No other
file may be dirty.

Commit message: `feat(poly-samples): model firmware automatic mappings`

---

## STEP 2 of 7 - recognize rootless samples and automatic import mode

Spec sections: `Architectural decisions`, `Rootless family key`, `Toolbar/import
terminology`.

Files:

- `lib/poly_multisample/poly_multisample_models.dart`
- `lib/poly_multisample/poly_multisample_parser.dart`
- `lib/poly_multisample/poly_sample_import_service.dart`
- `lib/ui/poly_multisample/dialogs/poly_loose_wav_import_dialog.dart`
- `test/poly_multisample/poly_multisample_parser_test.dart`
- `test/poly_multisample/poly_sample_import_service_test.dart`
- `test/poly_multisample/dialogs/poly_loose_wav_import_dialog_test.dart`

Mechanical edits:

1. Remove `missingRootNote` from `PolySampleIssue` and remove the missing-root
   branch from `PolySampleRegion.currentIssues`.
2. Remove parser creation of a missing-root issue. Keep raw `rootMidi` and
   `rootName` null for rootless files.
3. Rename only `PolyLooseWavMappingMode.unmapped` to
   `PolyLooseWavMappingMode.automaticNotes`.
4. In `_applyLooseMapping`, the `automaticNotes` branch clears only root and
   switch. It preserves parsed velocity and RR tags.
5. Import the resolver in the parser. Rewrite `sortRegions` to resolve once,
   then compare: playable mappings before unresolved/unsupported; resolved
   natural ascending; velocity ascending; RR ascending; case-folded
   `displayName`; exact `displayName`; path. Do not materialize resolved values
   into regions.
6. Change the loose-dialog label for `automaticNotes` to exactly
   `Use Disting automatic notes from C3`; it still hides the start-note row.
7. Replace parser test `flags audio files without root notes` with
   `accepts audio files that use automatic naturals`: expect raw root null and
   `currentIssues` empty.
8. Replace `clears missing-root issue after manual root edit` with
   `manual root edit replaces an automatic natural`: raw edit becomes B3 and
   issues stay empty.
9. Add parser test `sortRegions uses resolved naturals for rootless families`:
   input Snare V2 RR2, Kick, Snare V1 RR1 in that order; sorted paths are Kick,
   Snare V1 RR1, Snare V2 RR2.
10. Rename the import-service test wording from `unmapped` to `automatic`.
    Import the resolver and assert raw roots remain null while resolved naturals
    are 48 and 49 and issues are empty.
11. Update the dialog test to expect the exact new visible label and no
    `Leave unmapped` text.

Verification commands:

```bash
cd /Users/nealsanche/nosuch/nt_helper
dart format lib/poly_multisample/poly_multisample_models.dart lib/poly_multisample/poly_multisample_parser.dart lib/poly_multisample/poly_sample_import_service.dart lib/ui/poly_multisample/dialogs/poly_loose_wav_import_dialog.dart test/poly_multisample/poly_multisample_parser_test.dart test/poly_multisample/poly_sample_import_service_test.dart test/poly_multisample/dialogs/poly_loose_wav_import_dialog_test.dart
flutter analyze
flutter test test/poly_multisample/poly_multisample_parser_test.dart test/poly_multisample/poly_sample_import_service_test.dart test/poly_multisample/dialogs/poly_loose_wav_import_dialog_test.dart
flutter test
git add lib/poly_multisample/poly_multisample_models.dart lib/poly_multisample/poly_multisample_parser.dart lib/poly_multisample/poly_sample_import_service.dart lib/ui/poly_multisample/dialogs/poly_loose_wav_import_dialog.dart test/poly_multisample/poly_multisample_parser_test.dart test/poly_multisample/poly_sample_import_service_test.dart test/poly_multisample/dialogs/poly_loose_wav_import_dialog_test.dart && git status --short
```

Leftover checks:

```bash
rg -n "missingRootNote|PolyLooseWavMappingMode\.unmapped|Leave unmapped" lib/poly_multisample lib/ui/poly_multisample test/poly_multisample || true
```

Output must be empty. No other file may be dirty.

Commit message: `fix(poly-samples): recognize firmware automatic notes`

---

## STEP 3 of 7 - store resolution in Cubit state and use it for preview

Spec sections: `Cubit/state integration`, `Preview integration`, `Build/debug
reports`, `Issue rules`.

Files:

- `lib/ui/poly_multisample/poly_multisample_builder_cubit.dart`
- `lib/ui/poly_multisample/poly_region_math.dart`
- `lib/debug_poly_sample_upload_command.dart`
- `test/poly_multisample/poly_multisample_builder_cubit_test.dart`
- `test/poly_multisample/poly_region_math_test.dart`

Mechanical edits:

1. Add the resolver import, state field/default/copyWith contract, optional
   Cubit dependency, private field, and initializer exactly as specified.
2. In `_setInstrument` and `_replaceEditedRegions`, resolve the final region
   list once and emit it with
   `mappingWarningMessages(regions, resolution)`.
3. Explicitly clear the resolution in hardware-list loading, large-folder
   empty state, and `returnToSources`. Keep `mappingWarnings` empty at the
   same time.
4. In `poly_region_math.dart`, replace the body/export name
   `mappingWarnings(List<PolySampleRegion>)` with
   `mappingWarningMessages(List<PolySampleRegion>,
   PolySampleMappingResolution)`. Prepend the exact unsupported-file messages,
   then format all six resolver issue kinds in resolver order. Keep the old
   effective-range/extents/lane helpers temporarily for unmigrated widgets;
   STEP 7 deletes them.
5. Migrate all keyboard-note preview selection, hardware-candidate checking,
   RR grouping, pitch ratio, source playback, and render caching exactly as
   the spec says. Delete `_notePreviewEffectiveLow` and
   `_notePreviewEffectiveHigh` in this step.
6. Update `_KeyboardNotePreviewMatch` to require
   `PolySampleResolvedMapping resolvedMapping`; all raw region access goes
   through `resolvedMapping.region`.
7. Update `_writeBuildReport` to use one resolver result and the exact output
   format from the spec. Do not write derived values to filenames or regions.
8. Update the debug upload command to construct one resolution, construct one
   `mappingWarningMessages(instrument.regions, resolution)` list, and print
   that list's length.
9. In `_ExposedPolyMultisampleBuilderCubit.setTestState`, resolve
   `next.editedRegions`, compute issue messages, and emit a copy containing
   both. Add the resolver import to the test.
10. Replace Cubit test
    `mapping warnings report invalid range root outside range and overlaps`
    with `mapping warnings use structured firmware resolution`. Use roots 60
    and 67 with explicit switches 70 and 65 to produce impossible/natural
    outside messages, plus two same-root/same-V/same-RR mappings for overlap;
    assert the exact formatted messages in resolver issue order. Rewrite
    `mapping warnings allow different velocity and rr overlaps` with
    same-natural variants whose V or RR differ and expect no overlap message.
    Add `raw unsupported warning precedes mapping warnings`: include one
    unsupported region and one parsed SW 999 region; assert the exact two
    leading messages and `state.mappingWarnings.length`.
11. In the keyboard-preview test block, remove `rangeLow`/`rangeHigh` from
    single-sample fixtures; a single mapping covers 0-127. For multi-root
    fixtures, use roots and explicit `switchPoint` only. Replace test
    `keyboard note preview prefers the most specific overlapping range` with
    `keyboard note preview honors an explicit switch boundary`: roots 48 and
    60, higher SW 54; note 53 selects the lower file, note 54 selects higher.
12. Add test `keyboard note preview uses automatic natural for rootless wav`:
    create `Kick.wav`, use `_ImmediateNotePreviewRenderer`, play MIDI 60, and
    assert selected path Kick, renderer pitch ratio 2.0, and source playback
    pitch ratio 2.0 (natural is MIDI 48).
13. Add test `keyboard note preview follows EVOS contextual boundary`: create
    local A1 and E2 WAVs plus enough in-memory neighbouring regions to produce
    the spec fixture; note 35 selects A1 and note 36 selects E2.
14. Keep the existing same-range RR rotation test, but make its raw filenames
    rootless `Snare_RR1.wav`/`Snare_RR2.wav`; assert rotation still occurs.
15. Replace region-math tests for the old effective helpers only when their
    assertions concern warnings. Add exact tests:
    - `mappingWarningMessages formats resolved overlap`;
    - `mappingWarningMessages formats automatic natural overflow`.
    Keep tests for `selectedRegionFor` and `sampleDisplayLabel` unchanged.

Verification commands:

```bash
cd /Users/nealsanche/nosuch/nt_helper
dart format lib/ui/poly_multisample/poly_multisample_builder_cubit.dart lib/ui/poly_multisample/poly_region_math.dart lib/debug_poly_sample_upload_command.dart test/poly_multisample/poly_multisample_builder_cubit_test.dart test/poly_multisample/poly_region_math_test.dart
flutter analyze
flutter test test/poly_multisample/poly_multisample_builder_cubit_test.dart test/poly_multisample/poly_region_math_test.dart
flutter test
git add lib/ui/poly_multisample/poly_multisample_builder_cubit.dart lib/ui/poly_multisample/poly_region_math.dart lib/debug_poly_sample_upload_command.dart test/poly_multisample/poly_multisample_builder_cubit_test.dart test/poly_multisample/poly_region_math_test.dart && git status --short
```

Leftover checks:

```bash
rg -n "_notePreviewEffectiveLow|_notePreviewEffectiveHigh" lib/ui/poly_multisample test/poly_multisample || true
rg -n "mappingResolution|mappingWarningMessages|resolvedMapping" lib/ui/poly_multisample/poly_multisample_builder_cubit.dart lib/ui/poly_multisample/poly_region_math.dart test/poly_multisample/poly_multisample_builder_cubit_test.dart
```

The first grep is empty; the second has hits in every named file except the
debug command. No other file may be dirty.

Commit message: `fix(poly-samples): resolve sample mappings in Cubit state`

---

## STEP 4 of 7 - migrate the keyboard map to stored resolution

Spec section: `PolyKeyMap`.

Files:

- `lib/ui/poly_multisample/widgets/poly_key_map.dart`
- `lib/ui/poly_multisample/poly_samples_editor_view.dart`
- `test/poly_multisample/widgets/poly_key_map_test.dart`
- `test/poly_multisample/poly_samples_editor_view_test.dart`
- `test/poly_multisample/poly_samples_screen_test.dart`

Mechanical edits:

1. Add required `mappingResolution` to `PolyKeyMap`. Import the resolver and
   pass `state.mappingResolution` from `_EditorBody`.
2. Change all seven geometry/filter/semantic paths listed in the spec to use
   the supplied resolution. Resolve nothing in this file.
3. `_scheduleSelectedScroll` looks up the selected path and scrolls to
   `naturalMidi` only when the resolved mapping is playable.
4. `_regionSemanticTargets`, hit testing, and painter loops iterate
   `playableMappings`; no raw-root filter remains.
5. `_regionRect` accepts `PolySampleResolvedMapping` and reads non-null
   Low/High. `_regionSemanticLabel` emits the automatic qualifier exactly.
6. `_PolyKeyMapPainter` receives the resolution plus existing raw-region
   identity/revision inputs needed by `shouldRepaint`; do not resolve during
   `paint`.
7. Update every direct `PolyKeyMap` test construction with a resolver result.
   Put this in the existing pump helper instead of repeating it per test.
8. In `poly_key_map_test.dart`, replace every `rangeLow:` fixture with
   `switchPoint:` unless that constructor already supplies `switchPoint:`, in
   which case delete the `rangeLow:` line. Delete every `rangeHigh:` fixture.
   Update existing explicit-root geometry and semantic range expectations to
   contextual resolver values; do not preserve synthetic High overrides or
   next-root-minus-one expectations.
9. Add widget test `rootless zones are mapped focusable and selectable` with
   Kick/Snare raw roots null. Assert summary semantics
   `Keyboard map with 2 mapped samples`, exact Kick semantic label from the
   spec, semantics tap action, and callback selection of Kick.
10. Add widget test `EVOS A1 semantic range is F1 through B1`: use the ten
    region fixture; expect exact A1 semantic label containing
    `range F1 to B1`.
11. In editor/screen test-only Cubit `setTestState` helpers and direct `_state`
    fixtures, populate `mappingResolution` from `editedRegions`. Add resolver
    imports. Do not change production behavior in those tests.
12. Keep the existing keyboard preview semantics hint exactly unchanged.

Verification commands:

```bash
cd /Users/nealsanche/nosuch/nt_helper
dart format lib/ui/poly_multisample/widgets/poly_key_map.dart lib/ui/poly_multisample/poly_samples_editor_view.dart test/poly_multisample/widgets/poly_key_map_test.dart test/poly_multisample/poly_samples_editor_view_test.dart test/poly_multisample/poly_samples_screen_test.dart
flutter analyze
flutter test test/poly_multisample/widgets/poly_key_map_test.dart test/poly_multisample/poly_samples_editor_view_test.dart test/poly_multisample/poly_samples_screen_test.dart
flutter test
git add lib/ui/poly_multisample/widgets/poly_key_map.dart lib/ui/poly_multisample/poly_samples_editor_view.dart test/poly_multisample/widgets/poly_key_map_test.dart test/poly_multisample/poly_samples_editor_view_test.dart test/poly_multisample/poly_samples_screen_test.dart && git status --short
```

Leftover checks:

```bash
rg -n "rootMidi != null|rootMidi == null|effectiveLow\(|effectiveHigh\(|midiExtents\(|velocityLanes\(" lib/ui/poly_multisample/widgets/poly_key_map.dart || true
rg -n "rangeLow|rangeHigh" lib/ui/poly_multisample/widgets/poly_key_map.dart test/poly_multisample/widgets/poly_key_map_test.dart || true
rg -n "mappingResolution" lib/ui/poly_multisample/widgets/poly_key_map.dart lib/ui/poly_multisample/poly_samples_editor_view.dart test/poly_multisample/widgets/poly_key_map_test.dart test/poly_multisample/poly_samples_editor_view_test.dart test/poly_multisample/poly_samples_screen_test.dart
```

The first two greps are empty. The final grep has hits in all five named files.
No other file may be dirty.

Commit message: `fix(poly-samples): render resolved keyboard mappings`

---

## STEP 5 of 7 - migrate sample rows and make High read-only

Spec section: `PolySampleList`.

Files:

- `lib/ui/poly_multisample/poly_multisample_builder_cubit.dart`
- `lib/ui/poly_multisample/widgets/poly_sample_list.dart`
- `lib/ui/poly_multisample/poly_samples_editor_view.dart`
- `test/poly_multisample/widgets/poly_sample_list_test.dart`
- `test/poly_multisample/poly_samples_editor_view_test.dart`

Mechanical edits:

1. Add required `mappingResolution` to `PolySampleList`; the editor passes
   `state.mappingResolution`.
2. Rename public callback `onUpdateRangeLow` to `onUpdateSwitchPoint` and
   remove `onUpdateRangeHigh`. Update the editor construction accordingly,
   calling `cubit.updateSwitchPoint(..., focusRegion: true)`. Add
   `updateSwitchPoint` in the Cubit now as the final switch-point writer from
   the spec. Keep old range methods temporarily for the inspector until
   STEP 7.
3. Resolve each row by path from the supplied resolution. Unsupported or
   unresolved rows display `Unresolved` and disable Root/Low stepping.
4. Root uses resolved natural and displays `Auto <note>` when automatic.
   Clicking +/- writes an explicit root relative to the resolved natural.
5. Low uses resolved Low and calls `onUpdateSwitchPoint`.
   Display `Auto <note>` before an explicit switch edit and `<note>` after it;
   row semantics use `low <note>, automatic` for the former.
6. Replace the interactive High `_InlineSampleStepper` with new private
   stateless `_InlineSampleValue`; use the exact semantic label/hint from the
   spec and no buttons/callbacks.
7. Row mapped/warning icon and row semantics use resolution/issues, not a
   missing raw root.
8. Update `_pumpList` to build/pass resolution and rename/remove callbacks.
   In `poly_sample_list_test.dart`, replace every `rangeLow:` fixture with
   `switchPoint:` unless a switch is already present, and delete every
   `rangeHigh:` fixture. Adjust expected High values to resolver output.
9. Replace rootless expectation `Root Unset` with `Root Auto C3`; assert exact
   automatic row semantics.
10. Replace the High-callback test with
    `High is read-only and explains its derived value`: no Increase/Decrease
    High tooltip exists and the exact High semantic node exists.
11. Rename Low callback test variables and assertions to switch point.
12. Update editor test `inline row stepper focuses row and updates inspector`:
    the rootless region's automatic natural is C3, so Increase Root writes
    MIDI 49/C#3, not MIDI 61/C#4.
13. Add editor test `inline Low stepper writes a Disting switch point`: tap
    Increase Low on a selected automatic row and assert raw `switchPoint`
    equals resolved Low plus one and the recomputed mapping has
    `switchIsAutomatic == false`.

Verification commands:

```bash
cd /Users/nealsanche/nosuch/nt_helper
dart format lib/ui/poly_multisample/widgets/poly_sample_list.dart lib/ui/poly_multisample/poly_samples_editor_view.dart lib/ui/poly_multisample/poly_multisample_builder_cubit.dart test/poly_multisample/widgets/poly_sample_list_test.dart test/poly_multisample/poly_samples_editor_view_test.dart
flutter analyze
flutter test test/poly_multisample/widgets/poly_sample_list_test.dart test/poly_multisample/poly_samples_editor_view_test.dart test/poly_multisample/poly_multisample_builder_cubit_test.dart
flutter test
git add lib/ui/poly_multisample/widgets/poly_sample_list.dart lib/ui/poly_multisample/poly_samples_editor_view.dart lib/ui/poly_multisample/poly_multisample_builder_cubit.dart test/poly_multisample/widgets/poly_sample_list_test.dart test/poly_multisample/poly_samples_editor_view_test.dart && git status --short
```

Leftover checks:

```bash
rg -n "onUpdateRangeLow|onUpdateRangeHigh|Increase High|Decrease High|Root Unset|root .*unmapped" lib/ui/poly_multisample/widgets/poly_sample_list.dart lib/ui/poly_multisample/poly_samples_editor_view.dart test/poly_multisample/widgets/poly_sample_list_test.dart test/poly_multisample/poly_samples_editor_view_test.dart || true
rg -n "rangeLow|rangeHigh" lib/ui/poly_multisample/widgets/poly_sample_list.dart test/poly_multisample/widgets/poly_sample_list_test.dart || true
rg -n "onUpdateSwitchPoint|_InlineSampleValue|calculated from the next sample switch point" lib/ui/poly_multisample/widgets/poly_sample_list.dart test/poly_multisample/widgets/poly_sample_list_test.dart
```

The first two greps are empty; the final grep has source and test hits. No
other file may be dirty.

Commit message: `fix(poly-samples): show resolved sample rows`

---

## STEP 6 of 7 - migrate inspector, toolbar counts, and reset action

Spec sections: `PolySampleInspector`, `Toolbar/import terminology`,
`Persistable editing contract`.

Files:

- `lib/ui/poly_multisample/poly_multisample_builder_cubit.dart`
- `lib/ui/poly_multisample/poly_samples_editor_view.dart`
- `lib/ui/poly_multisample/widgets/poly_sample_inspector.dart`
- `test/poly_multisample/poly_multisample_builder_cubit_test.dart`
- `test/poly_multisample/poly_samples_editor_view_test.dart`
- `test/poly_multisample/widgets/poly_sample_inspector_test.dart`

Mechanical edits:

1. Add `switchPoint` to `updateSelectedMappings`, with clamping and copyWith
   behavior parallel to root. Keep legacy range parameters only until STEP 7.
2. Add `updateSelectedSwitchPoint` with the final signature.
3. Add `resetSelectedToAutomaticNotes`. During this transition it clears root,
   switch, and legacy range fields so no stale override survives, but it
   preserves velocity and RR. STEP 7 removes references to legacy fields.
4. Keep `unmapSelectedRegions` as a temporary forwarding alias only so no
   unmigrated test fails mid-step. STEP 7 deletes it.
5. In `_MappingSection`, use `state.mappingResolution` for all focused and
   selected Root/Low/High values.
6. Root aggregation compares `(naturalMidi, naturalIsAutomatic)` as specified.
   A single automatic root displays `Auto C3`; equal explicit/automatic mix is
   `Mixed`. Apply the exact popup initial-value rule from the spec.
7. Low aggregation compares `(lowMidi, switchIsAutomatic)`. Apply the exact
   null-value/`Auto <note>` hint rule, and make dropdown/stepper actions call
   `updateSelectedSwitchPoint`.
8. Delete the High dropdown and High `_StepRow`; add
   `_MappingReadOnlyRow(key: ValueKey('poly-mapping-high-value'), label:
   'High', ...)` with the exact aggregation, visible-value, semantic-value,
   and hint rules from the spec.
9. Replace inspector Unmap button with the exact single/multi automatic labels
   and `Icons.auto_fix_high`, then call `resetSelectedToAutomaticNotes`.
10. In the toolbar, use `state.mappingResolution.mappedCount` and
    `state.mappingWarnings.length`; do not use instrument getters or
    `mappingResolution.warningCount` for the total warning count.
11. Replace selected destructive label/action with `Use automatic notes` and
    the new Cubit method. Use `Icons.auto_fix_high` for selected state and
    `Icons.restore` for no-selection state. Keep the no-selection `Discard all`
    dialog unchanged.
12. Update test helper `setTestState`/fixture resolution in inspector and editor
    tests. In both test files, replace remaining `rangeLow:` fixtures with
    `switchPoint:` unless a switch is already present, delete every
    `rangeHigh:` fixture, and replace all legacy range assertions/actions as
    specified below. Production inspector/editor files must also have no
    `rangeLow`, `rangeHigh`, or High-mutation callback left.
13. Replace inspector test `bulk dropdown edits selected mapping fields only`
    with `bulk dropdown edits persistable mapping fields on selected samples
    only`. Remove the High-dropdown lookup/change. Set fixture switches to
    their old Low values. After choosing root 3, Low 60, velocity 3, and RR 4,
    assert selected indices 0 and 2 have root 3, `switchPoint == 60`, velocity
    3, RR 4; assert unselected index 1 keeps root 60, `switchPoint == 60`,
    velocity 2, RR 2.
14. Replace inspector test
    `bulk mapping controls update all selected samples together` with
    `bulk persistable steppers update all selected samples together`. Remove
    the `Increase High` tap. Set fixture switches to their old Low values.
    After the remaining Root, Low, Velocity, and Round robin increments,
    assert selected indices 0 and 1 have root 49, `switchPoint == 49`,
    velocity 2, RR 2; assert unselected index 2 remains root 52,
    `switchPoint == 52`, velocity 2, RR 2.
15. Add inspector test `single EVOS A1 shows firmware contextual Low and High`:
    use the full fixture; select A1; expect Root A1, Low `Auto F1`, High B1,
    and no `Mixed` text.
16. Add inspector test `rootless sample shows automatic natural`: select Kick
    in a Kick/Snare fixture; expect `Auto C3`, no `Unset`, and Root semantics
    value `Auto C3`.
17. Add inspector test `High aggregation is exact`: use the
    `poly-mapping-high-value` key in three pumps. Two variants at one playable
    natural display their common note; two selected playable naturals with
    different Highs display `Mixed`; one selected unsupported region displays
    `Unresolved`. In every case assert the High semantic value equals the
    visible value. Also assert no high dropdown key or High +/- tooltip exists
    and the exact read-only hint is present.
18. Replace unmap test with
    `Use automatic notes clears root and switch but preserves V and RR`.
19. Update editor tests:
    - toolbar reports all supported rootless samples mapped from resolution;
    - an unsupported region contributes one warning and its exact raw warning
      message;
    - selected action text is `Use automatic notes`;
    - tapping it keeps both rows, clears raw root/switch on selected rows,
      preserves V/RR, and key-map summary still reports them mapped.
20. Add Cubit unit test with the same reset-field assertions.

Verification commands:

```bash
cd /Users/nealsanche/nosuch/nt_helper
dart format lib/ui/poly_multisample/poly_multisample_builder_cubit.dart lib/ui/poly_multisample/poly_samples_editor_view.dart lib/ui/poly_multisample/widgets/poly_sample_inspector.dart test/poly_multisample/poly_multisample_builder_cubit_test.dart test/poly_multisample/poly_samples_editor_view_test.dart test/poly_multisample/widgets/poly_sample_inspector_test.dart
flutter analyze
flutter test test/poly_multisample/poly_multisample_builder_cubit_test.dart test/poly_multisample/poly_samples_editor_view_test.dart test/poly_multisample/widgets/poly_sample_inspector_test.dart
flutter test
git add lib/ui/poly_multisample/poly_multisample_builder_cubit.dart lib/ui/poly_multisample/poly_samples_editor_view.dart lib/ui/poly_multisample/widgets/poly_sample_inspector.dart test/poly_multisample/poly_multisample_builder_cubit_test.dart test/poly_multisample/poly_samples_editor_view_test.dart test/poly_multisample/widgets/poly_sample_inspector_test.dart && git status --short
```

Leftover checks:

```bash
rg -n "Unmap selected|Unmap sample|root .*unmapped|Root.*Unset" lib/ui/poly_multisample/poly_samples_editor_view.dart lib/ui/poly_multisample/widgets/poly_sample_inspector.dart test/poly_multisample/poly_samples_editor_view_test.dart test/poly_multisample/widgets/poly_sample_inspector_test.dart || true
rg -n "rangeLow|rangeHigh|poly-mapping-high-dropdown|Increase High|Decrease High" lib/ui/poly_multisample/poly_samples_editor_view.dart lib/ui/poly_multisample/widgets/poly_sample_inspector.dart test/poly_multisample/poly_samples_editor_view_test.dart test/poly_multisample/widgets/poly_sample_inspector_test.dart || true
rg -n "Use automatic note|updateSelectedSwitchPoint|_MappingReadOnlyRow|Calculated from the next sample switch point" lib/ui/poly_multisample test/poly_multisample/widgets/poly_sample_inspector_test.dart test/poly_multisample/poly_samples_editor_view_test.dart
```

The first two greps are empty. The final grep includes Cubit,
inspector/editor, and test hits. No other file may be dirty.

Commit message: `fix(poly-samples): expose automatic mappings in editor`

---

## STEP 7 of 7 - remove synthetic ranges and prove filename persistence

Spec sections: `Persistable editing contract`, `Exhaustive mapping symbol map`,
`Acceptance criteria`.

Files:

- `lib/poly_multisample/poly_multisample_models.dart`
- `lib/ui/poly_multisample/poly_multisample_builder_cubit.dart`
- `lib/ui/poly_multisample/poly_region_math.dart`
- `test/poly_multisample/poly_multisample_builder_cubit_test.dart`
- `test/poly_multisample/poly_region_math_test.dart`
- `test/poly_multisample/poly_sample_apply_service_test.dart`
- `test/poly_multisample/poly_sample_upload_service_test.dart`

Mechanical edits:

1. Remove `rangeLow`, `rangeHigh`, their constructor fields, copyWith
   parameters, clear flags, and copyWithIssues forwarding from
   `PolySampleRegion`.
2. Remove `PolySampleRegion.isMapped`, `PolySampleInstrument.mappedCount`, and
   `PolySampleInstrument.warningCount`. Do not replace them with another
   context-free getter.
3. From the Cubit remove:
   - `updateRangeLow`, `updateRangeHigh`;
   - `updateSelectedRangeLow`, `updateSelectedRangeHigh`;
   - range parameters/clamps/clear flags in `updateSelectedMappings`;
   - temporary `unmapSelectedRegions` alias;
   - range values in `_fingerprintRegions`.
4. Simplify `resetSelectedToAutomaticNotes` to clear only root and switch.
5. In `poly_region_math.dart`, delete declarations of `effectiveLow`,
   `effectiveHigh`, `midiExtents`, and `velocityLanes`. Keep only
   `mappingWarningMessages`, `_noteLabel`, `selectedRegionFor`,
   `sampleDisplayLabel`, and `_commonDirectory`.
6. In the Cubit test, mechanically migrate remaining setup/assertions:
   - replace every remaining `rangeLow:` fixture field with `switchPoint:`;
     when that same constructor already has `switchPoint:`, delete the legacy
     `rangeLow:` line instead;
   - delete every `rangeHigh:` fixture field;
   - replace range mutation tests with switch-point mutation tests;
   - include `updateSwitchPoint clamps editor values to MIDI`: inputs -1 and
     999 store 0 and 127 respectively;
   - remove assertions/calls for editable High;
   - keep warning tests using explicit switches, natural-outside-range, and
     overlap issue fixtures from the resolver.
7. In `poly_region_math_test`, delete tests of removed effective/extents/lane
   helpers. Keep issue-message, selection, and display-label tests.
8. Add apply-service test
   `automatic root remains absent from target filename`: parse `Kick.wav`,
   resolve it to prove natural 48, call `buildTargetFileName`, and expect
   exactly `Kick.wav` (no `_C3`).
9. Add apply-service test `explicit Low is serialized as SW`: region rooted C3
   with `switchPoint: 55`; expect filename ending `_C3_SW55.wav`.
10. Add apply-service test
    `out-of-range parsed SW round trips until explicitly edited`: parse
    `Piano_C3_SW999.wav`, resolve it and assert the switch warning, then expect
    `buildTargetFileName` to preserve `_SW999.wav`.
11. Add upload-service test `automatic rootless upload preserves raw filename`:
    build upload files for rootless `Kick.wav`; expect hardware target
    `/multisamples/Drums/Kick.wav` and no note token.
12. Ensure every file migrated in STEP 4-6 already has no legacy range token;
    do not edit additional files to invent replacements.

Verification commands:

```bash
cd /Users/nealsanche/nosuch/nt_helper
dart format lib/poly_multisample/poly_multisample_models.dart lib/ui/poly_multisample/poly_multisample_builder_cubit.dart lib/ui/poly_multisample/poly_region_math.dart test/poly_multisample/poly_multisample_builder_cubit_test.dart test/poly_multisample/poly_region_math_test.dart test/poly_multisample/poly_sample_apply_service_test.dart test/poly_multisample/poly_sample_upload_service_test.dart
flutter analyze
flutter test test/poly_multisample/poly_sample_mapping_resolver_test.dart test/poly_multisample/poly_multisample_builder_cubit_test.dart test/poly_multisample/poly_region_math_test.dart test/poly_multisample/poly_sample_apply_service_test.dart test/poly_multisample/poly_sample_upload_service_test.dart
flutter test test/poly_multisample
flutter test
git add lib/poly_multisample/poly_multisample_models.dart lib/ui/poly_multisample/poly_multisample_builder_cubit.dart lib/ui/poly_multisample/poly_region_math.dart test/poly_multisample/poly_multisample_builder_cubit_test.dart test/poly_multisample/poly_region_math_test.dart test/poly_multisample/poly_sample_apply_service_test.dart test/poly_multisample/poly_sample_upload_service_test.dart && git status --short
```

Final leftover checks (all must print no matches):

```bash
rg -n "rangeLow|rangeHigh|updateRangeLow|updateRangeHigh|updateSelectedRangeLow|updateSelectedRangeHigh|unmapSelectedRegions" lib/poly_multisample lib/ui/poly_multisample test/poly_multisample || true
rg -n "int effectiveLow|int effectiveHigh|midiExtents\(|velocityLanes\(" lib/ui/poly_multisample test/poly_multisample || true
rg -n "missingRootNote|PolyLooseWavMappingMode\.unmapped|Leave unmapped|Unmap selected|Unmap sample" lib/poly_multisample lib/ui/poly_multisample test/poly_multisample || true
rg -n "bool get isMapped|int get mappedCount|int get warningCount" lib/poly_multisample/poly_multisample_models.dart || true
```

Completion inventory:

```bash
python3 .agents/skills/decision-free-specs/languages/dart/inventory.py lib/poly_multisample/poly_sample_mapping_resolver.dart lib/ui/poly_multisample/poly_region_math.dart > /tmp/poly_sample_mapping_final_inventory.md
rg -n "PolySampleMappingIssueKind|PolySampleMappingIssue|PolySampleResolvedMapping|PolySampleMappingResolution|PolySampleMappingResolver|mappingWarningMessages|selectedRegionFor|sampleDisplayLabel" /tmp/poly_sample_mapping_final_inventory.md
```

The resolver still has exactly 5 exported top-level declarations.
`poly_region_math.dart` has exactly 3 exported functions:
`mappingWarningMessages`, `selectedRegionFor`, and `sampleDisplayLabel`.
No file outside the seven named files may be dirty.

Commit message: `fix(poly-samples): persist firmware-shaped mapping edits`
