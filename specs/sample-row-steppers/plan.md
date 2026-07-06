# Sample row inline steppers implementation plan

Total steps: 2

Read `specs/conventions.md` and `specs/sample-row-steppers/spec.md` completely before starting any step. Execute one numbered step per fresh-context session. Do not implement a later step early.

Program-level verification after STEP 2:

```bash
cd /Users/nealsanche/nosuch/nt_helper
flutter analyze
flutter test
```

## STEP 1 of 2 — Harden cubit mapping edits and add mapping auto-preview

### Goal

Make mapping edit methods clamp values, optionally focus the edited row, and replay feasible previews when Auto Preview is enabled.

### Files to edit

- `lib/ui/poly_multisample/poly_multisample_builder_cubit.dart`
- `test/poly_multisample/poly_multisample_builder_cubit_test.dart`

### Mechanical edits

1. In `lib/ui/poly_multisample/poly_multisample_builder_cubit.dart`, add `int _mappingPreviewRequest = 0;` near the existing `_contentRevision` field.
2. Replace the five public mapping update methods with the exact signatures from `spec.md`:
   - `updateRoot(String path, int midi, {IDistingMidiManager? manager, bool focusRegion = false})`
   - `updateRangeLow(String path, int midi, {IDistingMidiManager? manager, bool focusRegion = false})`
   - `updateRangeHigh(String path, int midi, {IDistingMidiManager? manager, bool focusRegion = false})`
   - `updateVelocity(String path, int layer, {IDistingMidiManager? manager, bool focusRegion = false})`
   - `updateRoundRobin(String path, int lane, {IDistingMidiManager? manager, bool focusRegion = false})`
3. In those methods, apply the clamp rules from `spec.md` before creating the updated region.
4. Change `_updateRegion` to return `bool`.
5. Add optional named parameters to `_updateRegion`: `Set<String>? selectedPaths` and `String? focusedPathOverride`.
6. `_updateRegion` must scan `state.editedRegions`, update only the matching path, record whether a match occurred, call `_replaceEditedRegions` only after a match, and return `true` only after a match.
7. Every public mapping update method must call `_updateRegion` with `selectedPaths: focusRegion ? {path} : null` and `focusedPathOverride: focusRegion ? path : null`.
8. Every public mapping update method must call `_autoPreviewMappingEdit(path, manager: manager)` only when `_updateRegion` returned `true`.
9. Add optional named parameter `String? focusedPathOverride` to `_replaceEditedRegions`.
10. In `_replaceEditedRegions`, compute `focusedPath` with this priority:
    - `focusedPathOverride` when it is non-null and present in `remainingPaths`
    - existing `state.focusedPath` when present in `remainingPaths`
    - `nextSelectedPaths.firstOrNull`
11. Add private method `_autoPreviewMappingEdit(String path, {IDistingMidiManager? manager})` using the behavior in `spec.md`.
12. Add private method `_restartPreviewForMappingEdit(String path, {required int requestId, IDistingMidiManager? manager}) async` using the behavior in `spec.md`.
13. Use the existing `PolySampleHardwareException('Connect to Disting NT to preview hardware samples.')` text for missing hardware manager inside `_restartPreviewForMappingEdit`.
14. In `test/poly_multisample/poly_multisample_builder_cubit_test.dart`, add a test named `mapping edits clamp values and can focus the edited row` near the existing mapping edit tests. The test must:
    - create `_ExposedPolyMultisampleBuilderCubit` with fake preview service
    - set state with two edited WAV regions `/tmp/a.wav` and `/tmp/b.wav`, selected/focused on `/tmp/a.wav`
    - call `updateRoot('/tmp/b.wav', -4, focusRegion: true)`
    - call `updateRangeLow('/tmp/b.wav', -1)`
    - call `updateRangeHigh('/tmp/b.wav', 200)`
    - call `updateVelocity('/tmp/b.wav', 0)`
    - call `updateRoundRobin('/tmp/b.wav', 0)`
    - assert `/tmp/b.wav` is selected and focused
    - assert the edited `/tmp/b.wav` region has `rootMidi` 0, `rootName` `C-1`, `rangeLow` 0, `rangeHigh` 127, `velocityLayer` 1, and `roundRobin` 1
15. Add a test named `auto-preview restarts the edited wav after mapping changes` near the existing auto-preview tests. The test must:
    - create `_FakePreviewAdapter`, `PolyAudioPreviewService`, and `_ExposedPolyMultisampleBuilderCubit`
    - set state with `autoPreview: true`, one edited WAV region `/tmp/a.wav`, selected/focused on `/tmp/a.wav`
    - call `await cubit.playOrStopPreview('/tmp/a.wav')`
    - call `cubit.updateRoot('/tmp/a.wav', 61)`
    - wait with `await Future<void>.delayed(Duration.zero)`
    - assert `adapter.playedPaths` equals `['/tmp/a.wav', '/tmp/a.wav']`
    - assert `adapter.stopCount` is `1`
16. Add a test named `auto-preview stops visible preview for non-wav mapping edits`. The test must:
    - create adapter/service/cubit
    - set state with `autoPreview: true` and one edited AIF region `/tmp/b.aif`
    - call `await cubit.playOrStopPreview('/tmp/a.wav')`
    - call `cubit.updateVelocity('/tmp/b.aif', 2)`
    - wait one zero-duration future
    - assert `adapter.playedPaths` equals `['/tmp/a.wav']`
    - assert `adapter.stopCount` is `1`
17. Add a test named `stale hardware mapping auto-preview request does not play`. The test must:
    - add a new fake class named `_QueuedPreviewHardwareService` near `_PreviewHardwareService`
    - `_QueuedPreviewHardwareService` extends `PolySampleHardwareService`
    - `_QueuedPreviewHardwareService` has `final completers = <Completer<Uint8List?>>[];`
    - `_QueuedPreviewHardwareService.downloadSampleBytes` creates a `Completer<Uint8List?>`, adds it to `completers`, and returns its future
    - `_QueuedPreviewHardwareService.complete(int index, List<int> bytes)` completes `completers[index]` with `Uint8List.fromList(bytes)`
    - create `_MockDistingMidiManager`, `_FakePreviewAdapter`, `_QueuedPreviewHardwareService`, `PolyAudioPreviewService`, and `_ExposedPolyMultisampleBuilderCubit(hardwareService: hardwareService, previewService: previewService)`
    - set cubit state with `sourceMode: PolySampleSourceMode.hardware`, `autoPreview: true`, one edited hardware WAV region using path `/samples/Piano/Piano_C3.wav`, selected/focused on that path
    - call `cubit.updateRoot('/samples/Piano/Piano_C3.wav', 49, manager: manager)`
    - wait one zero-duration future and assert `hardwareService.completers.length` is `1`
    - call `cubit.updateRoot('/samples/Piano/Piano_C3.wav', 50, manager: manager)`
    - wait one zero-duration future and assert `hardwareService.completers.length` is `2`
    - call `hardwareService.complete(1, [2])`
    - wait one zero-duration future
    - call `hardwareService.complete(0, [1])`
    - wait two zero-duration futures
    - assert `adapter.playedPaths.length` is `1`
    - assert `File(adapter.playedPaths.single).readAsBytesSync()` equals `[2]`
    - assert the cubit root is `50`
18. Do not edit UI files in this step.

### Verification commands

```bash
cd /Users/nealsanche/nosuch/nt_helper
dart format lib/ui/poly_multisample/poly_multisample_builder_cubit.dart test/poly_multisample/poly_multisample_builder_cubit_test.dart
flutter analyze
flutter test test/poly_multisample/poly_multisample_builder_cubit_test.dart
rg -n "_mappingPreviewRequest|_autoPreviewMappingEdit|_restartPreviewForMappingEdit|focusRegion" lib/ui/poly_multisample/poly_multisample_builder_cubit.dart test/poly_multisample/poly_multisample_builder_cubit_test.dart
git add lib/ui/poly_multisample/poly_multisample_builder_cubit.dart test/poly_multisample/poly_multisample_builder_cubit_test.dart
git status --short
git commit -m "feat(poly-samples): harden mapping edits and preview changes"
```

### Leftover checks

- No symbols are moved in this step.
- `rg -n "void updateRoot\(|void updateRangeLow\(|void updateRangeHigh\(|void updateVelocity\(|void updateRoundRobin\(" lib/ui/poly_multisample/poly_multisample_builder_cubit.dart` prints one declaration for each method.
- `git status --short` before commit shows only the two files named in this step.

### Commit message

`feat(poly-samples): harden mapping edits and preview changes`

## STEP 2 of 2 — Add inline row steppers and wire editor/sidebar callbacks

### Goal

Render compact Root/Low/High/Vel/RR steppers in each sample row and wire them to the hardened cubit methods.

### Files to edit

- `lib/ui/poly_multisample/widgets/poly_sample_list.dart`
- `test/poly_multisample/widgets/poly_sample_list_test.dart`
- `lib/ui/poly_multisample/poly_samples_editor_view.dart`
- `test/poly_multisample/poly_samples_editor_view_test.dart`
- `lib/ui/poly_multisample/widgets/poly_sample_inspector.dart`
- `test/poly_multisample/widgets/poly_sample_inspector_test.dart`

### Mechanical edits

1. In `lib/ui/poly_multisample/widgets/poly_sample_list.dart`, add imports:
   - `import 'dart:math' as math;`
   - `import 'package:nt_helper/poly_multisample/poly_multisample_parser.dart';`
2. Update `PolySampleList` constructor and fields exactly as specified in `spec.md`.
3. Change `_itemExtent` to `84.0`.
4. In `_PolySampleListState.build`, compute `root`, `low`, `high`, `velocity`, `roundRobin`, `rootLabel`, `lowLabel`, and `highLabel` for each region using the rules in `spec.md`.
5. Replace the current semantics label with the exact expanded label from `spec.md`.
6. Keep `ListTile(dense: true, selected: selected, onTap: () => widget.onSelect(region.path, _selectionMode()))`.
7. Add `size: 20` to the existing leading `Icon`.
8. Change the title to `Text(label, maxLines: 1, overflow: TextOverflow.ellipsis)`.
9. Replace the subtitle `Text(...)` with `Wrap(spacing: 4, runSpacing: 4, children: [...])` containing five `_InlineSampleStepper` widgets in the exact order Root, Low, High, Vel, RR.
10. Use the row step rules from `spec.md` for every `_InlineSampleStepper` callback.
11. Add `_InlineSampleStepper` below `_PolySampleListState` with the exact constructor, fields, semantics label, decoration, button helper, tooltips, button constraints, and icon sizes from `spec.md`.
12. Add top-level helper `_clampMidi(int value) => value.clamp(0, 127).toInt();` below `_InlineSampleStepper`.
13. Remove no existing selection-mode code and remove no preview button behavior.
14. In `lib/ui/poly_multisample/poly_samples_editor_view.dart`, add the five `onUpdate...` callbacks to the `PolySampleList` constructor exactly as specified in `spec.md`.
15. In `lib/ui/poly_multisample/widgets/poly_sample_inspector.dart`, pass `manager: manager` into `_MappingSection` from `PolySampleInspector.build`.
16. Add `final IDistingMidiManager? manager;` to `_MappingSection`.
17. Add `manager: manager` to each `_MappingSection` cubit mapping update call.
18. Do not pass `focusRegion: true` from `_MappingSection`.
19. In `test/poly_multisample/widgets/poly_sample_list_test.dart`, update every `PolySampleList` construction with the five required callbacks. For existing tests, use callbacks that do nothing.
20. Add a local helper in `poly_sample_list_test.dart` named `_pumpList` that accepts regions, optional selected paths, optional callbacks, and pumps a `MaterialApp` with `SizedBox(height: 220, child: PolySampleList(...))`.
21. Add a widget test named `renders inline mapping steppers for each sample row`. It must pump one mapped region with `rootMidi: 48`, `rootName: 'C3'`, `rangeLow: 47`, `rangeHigh: 55`, `velocityLayer: 2`, and `roundRobin: 3`. It must assert visible text `Root C3`, `Low B2`, `High G3`, `Vel 2`, and `RR 3`.
22. Add a widget test named `inline steppers emit clamped mapping updates`. It must:
    - pump one region with root/range values at 0 and velocity/RR at 1
    - tap `Decrease Root for boundary.wav`
    - tap `Decrease Low for boundary.wav`
    - tap `Decrease High for boundary.wav`
    - tap `Decrease Vel for boundary.wav`
    - tap `Decrease RR for boundary.wav`
    - assert the captured update values are root 0, low 0, high 0, velocity 1, and RR 1
23. Add a widget test named `inline stepper semantics name values and actions`. It must:
    - call `tester.ensureSemantics()`
    - pump one mapped region named `mapped.wav`
    - assert `find.bySemanticsLabel('mapped.wav, root C3, low C3, high G3, velocity 2, RR 3')`
    - assert `find.byTooltip('Decrease Root for mapped.wav')`
    - assert `find.byTooltip('Increase RR for mapped.wav')`
    - dispose semantics
24. In `test/poly_multisample/poly_samples_editor_view_test.dart`, add a test named `inline row stepper focuses row and updates inspector`. It must:
    - create `_TestPolyMultisampleBuilderCubit` with `_state()`
    - pump the editor
    - tap `Increase Root for Piano_Unmapped.wav`
    - pump
    - assert `cubit.state.focusedPath` is `/tmp/Piano/Piano_Unmapped.wav`
    - assert `cubit.state.selectedPaths` is `{ '/tmp/Piano/Piano_Unmapped.wav' }`
    - assert `cubit.state.editedRegions` contains the unmapped path with `rootMidi` 61 and `rootName` `C#4`
    - assert the inspector shows `Editing Piano_Unmapped.wav`
25. In `test/poly_multisample/widgets/poly_sample_inspector_test.dart`, add a test named `mapping stepper auto-previews when enabled`. It must:
    - create `_FakePreviewAdapter`, `PolyAudioPreviewService`, and `_TestPolyMultisampleBuilderCubit` using that service
    - set test state from `_selectedState(autoPreview: true)`; add an `autoPreview` optional parameter to `_selectedState` with default `false`
    - pump the inspector
    - tap `Increase Root`
    - wait one zero-duration future and pump
    - assert the fake adapter recorded one play for `/tmp/Piano_C3.wav`
26. Update `_FakePreviewAdapter` in `poly_sample_inspector_test.dart` to store `playedPaths` in a list while preserving existing interface methods.
27. Do not create a reusable public stepper widget in this step.
28. Do not edit parser, models, apply service, waveform editor, or key map files.

### Verification commands

```bash
cd /Users/nealsanche/nosuch/nt_helper
dart format lib/ui/poly_multisample/widgets/poly_sample_list.dart test/poly_multisample/widgets/poly_sample_list_test.dart lib/ui/poly_multisample/poly_samples_editor_view.dart test/poly_multisample/poly_samples_editor_view_test.dart lib/ui/poly_multisample/widgets/poly_sample_inspector.dart test/poly_multisample/widgets/poly_sample_inspector_test.dart
flutter analyze
flutter test test/poly_multisample/widgets/poly_sample_list_test.dart test/poly_multisample/poly_samples_editor_view_test.dart test/poly_multisample/widgets/poly_sample_inspector_test.dart test/poly_multisample/poly_multisample_builder_cubit_test.dart
rg -n "_InlineSampleStepper|Decrease Root for|Increase RR for|focusRegion: true|manager: manager" lib/ui/poly_multisample/widgets/poly_sample_list.dart lib/ui/poly_multisample/poly_samples_editor_view.dart lib/ui/poly_multisample/widgets/poly_sample_inspector.dart test/poly_multisample/widgets/poly_sample_list_test.dart test/poly_multisample/poly_samples_editor_view_test.dart test/poly_multisample/widgets/poly_sample_inspector_test.dart
git add lib/ui/poly_multisample/widgets/poly_sample_list.dart test/poly_multisample/widgets/poly_sample_list_test.dart lib/ui/poly_multisample/poly_samples_editor_view.dart test/poly_multisample/poly_samples_editor_view_test.dart lib/ui/poly_multisample/widgets/poly_sample_inspector.dart test/poly_multisample/widgets/poly_sample_inspector_test.dart
git status --short
git commit -m "feat(poly-samples): add inline sample row steppers"
```

### Leftover checks

- No symbols are moved in this step.
- `rg -n "PolySampleList\(" lib test` shows every constructor call supplies all five `onUpdate...` callbacks.
- `rg -n "_InlineSampleStepper\(" lib/ui/poly_multisample/widgets/poly_sample_list.dart` prints exactly five construction sites plus the class constructor.
- `git status --short` before commit shows only the six files named in this step.

### Commit message

`feat(poly-samples): add inline sample row steppers`
