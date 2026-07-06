# Plan: keyboard-note-render-preview

This plan has **5 steps**. Execute exactly one step per session, in order.
Every step must leave `flutter analyze` clean and the named tests passing.
`specs/keyboard-note-render-preview/spec.md` is the authoritative design.
`specs/conventions.md` gives the default verification commands and recovery rules.

Prerequisites: none outside this repo.

Program-level verification after STEP 5:

```bash
flutter analyze && flutter test
```

---

## STEP 1 of 5 — add pitched WAV rendering

Spec sections: `WavAudioRenderer.renderPitchedPreview`, hardening rows for invalid WAV and output format.

Files:

- `lib/poly_multisample/wav_metadata.dart`
- `test/poly_multisample/wav_metadata_test.dart`

Implementation tasks:

1. Add the static method `WavAudioRenderer.renderPitchedPreview(Uint8List bytes, {required double pitchRatio})` exactly as specified.
2. Reuse existing private helpers in `wav_metadata.dart`: `_readChunks`, `WavMetadataReader._readFmt`, `WavMetadataReader._readSample`, `_isSupportedFormat`, and `WavMetadataWriter._u32`.
3. Add a private helper inside `WavAudioRenderer` named `_buildPcm16Wave` with signature:

   ```dart
   static Uint8List _buildPcm16Wave({
     required int sampleRate,
     required int channels,
     required List<double> samples,
   })
   ```

   It writes only `RIFF`, `fmt `, and `data` chunks, PCM format `1`, 16 bits per sample, little-endian.
4. Extend `test/poly_multisample/wav_metadata_test.dart` with these tests in the existing top-level test group:
   - `test('renderPitchedPreview doubles pitch by halving frame count', ...)`
   - `test('renderPitchedPreview lowers pitch by extending frame count', ...)`
   - `test('renderPitchedPreview falls back to unity for invalid ratios', ...)`
   - `test('renderPitchedPreview rejects invalid wav bytes', ...)`
5. Use the existing `_pcm16Wav` fixture in that test file. Parse rendered bytes with `WavMetadataReader.parse` and assert frame counts: source 8 frames with ratio `2.0` renders 4 frames; ratio `0.5` renders 16 frames; ratio `double.nan` renders 8 frames. For invalid bytes, expect `throwsFormatException`.

Verification commands:

```bash
dart format lib/poly_multisample/wav_metadata.dart test/poly_multisample/wav_metadata_test.dart
flutter analyze
flutter test test/poly_multisample/wav_metadata_test.dart
git add -A && git status --short
```

Leftover checks:

```bash
rg -n "renderPitchedPreview|_buildPcm16Wave" lib/poly_multisample/wav_metadata.dart test/poly_multisample/wav_metadata_test.dart
```

Expected status output may list only the two files named in this step.

Commit message: `feat(poly): render pitched WAV note previews`

---

## STEP 2 of 5 — add restart-only audio preview playback

Spec section: `PolyAudioPreviewService.restartPreview`.

Files:

- `lib/poly_multisample/poly_audio_preview_service.dart`
- `test/poly_multisample/poly_audio_preview_service_test.dart`

Implementation tasks:

1. Add `Future<void> restartPreview(String path, {double gainDb = 0, String? displayPath})` to `PolyAudioPreviewService` exactly as specified.
2. Use `_ensureAdapter()` and `_volumeFromGainDb(gainDb)` just like `playOrStopPreview`.
3. When `state.isPlaying` is true, await `adapter.stop()` before `adapter.play(...)`.
4. Always call `adapter.play(...)`; never compare `state.visiblePath` for toggling in this method.
5. Set state to `PolyAudioPreviewState(playingPath: path, displayPath: displayPath, gainDb: gainDb)` after `adapter.play` completes.
6. Extend `test/poly_multisample/poly_audio_preview_service_test.dart` with `test('restartPreview restarts the same visible path without toggling', ...)`:
   - Create `_FakePreviewAdapter` and service.
   - Call `restartPreview('/tmp/rendered-a.wav', displayPath: '/tmp/source.wav')`.
   - Call `restartPreview('/tmp/rendered-a.wav', displayPath: '/tmp/source.wav')` again.
   - Assert `adapter.playedPaths` has two entries, `adapter.stopCount == 1`, and `service.state.visiblePath == '/tmp/source.wav'`.

Verification commands:

```bash
dart format lib/poly_multisample/poly_audio_preview_service.dart test/poly_multisample/poly_audio_preview_service_test.dart
flutter analyze
flutter test test/poly_multisample/poly_audio_preview_service_test.dart
git add -A && git status --short
```

Leftover checks:

```bash
rg -n "restartPreview" lib/poly_multisample/poly_audio_preview_service.dart test/poly_multisample/poly_audio_preview_service_test.dart
```

Expected status output may list only the two files named in this step.

Commit message: `feat(poly): restart audio previews without toggling`

---

## STEP 3 of 5 — add cubit keyboard-note preview orchestration

Spec sections: `PolyMultisampleBuilderCubit.selectRegion`, `PolyMultisampleBuilderCubit.playKeyboardNotePreview`, hardening matrix rows for races, file errors, hardware paths, non-WAV, overlap, velocity, RR, cache, cleanup, and auto-preview.

Files:

- `lib/ui/poly_multisample/poly_multisample_builder_cubit.dart`
- `test/poly_multisample/poly_multisample_builder_cubit_test.dart`

Implementation tasks:

1. Add `import 'dart:typed_data';` because the renderer constructor parameter uses `Uint8List`.
2. Extend the cubit constructor with `FutureOr<Uint8List> Function(Uint8List bytes, double pitchRatio)? notePreviewRenderer` and store the default renderer exactly as specified.
3. Extend `selectRegion` with `bool autoPreviewSelection = true` as an optional named parameter. Wrap the existing auto-preview block so it runs only when `autoPreviewSelection` is true. Existing callers remain unchanged.
4. Add the five private fields listed in the spec: `_notePreviewCache`, `_notePreviewRenderInFlight`, `_notePreviewRoots`, `_notePreviewRoundRobinCursor`, and `_notePreviewRequest`.
5. Add the private `_KeyboardNotePreviewMatch` class at top level near the other private cubit helper classes at the bottom of the file.
6. Add `Future<void> playKeyboardNotePreview(int midi)` exactly as specified.
7. Add the private helpers named in the spec. Keep them private in `poly_multisample_builder_cubit.dart`; do not import `poly_region_math.dart` into the cubit.
8. `_renderedKeyboardNotePreviewPath` must:
   - Stat the source file before using the cache.
   - Build cache key from `p.normalize(region.path)`, `stat.modified.millisecondsSinceEpoch`, `stat.size`, `region.rootMidi`, and target MIDI.
   - Return cached path when it exists and `File(cachedPath).exists()` is true.
   - Use `_notePreviewRenderInFlight.putIfAbsent(cacheKey, () async { ... }())` pattern or equivalent map logic that removes the key in `whenComplete`.
   - Create a temp root with prefix `nt_helper_poly_note_preview_`, append it to `_notePreviewRoots`, render via `_notePreviewRenderer(bytes, pitchRatio)`, and write `preview.wav` under that root.
9. Pitch ratio is `math.pow(2, (midi - region.rootMidi!) / 12).toDouble()`.
10. `playKeyboardNotePreview` must call `_previewService.restartPreview(renderedPath, displayPath: region.path, gainDb: state.previewGainDb)`.
11. Increment the RR cursor only after stale-token checks pass and before calling `restartPreview`.
12. Call `await _cleanupNotePreviewRoots()` in `close()` after `_cleanupHardwarePreviewRoots()`.
13. Call `await _cleanupNotePreviewRoots()` in `returnToSources()` after `_cleanupHardwarePreviewRoots()`.
14. Do not change existing normal preview or hardware normal preview behavior.
15. Extend `test/poly_multisample/poly_multisample_builder_cubit_test.dart` with these tests in the existing cubit group:
    - `test('keyboard note preview selects and plays a rendered local wav', ...)`
    - `test('keyboard note preview rotates same-range round robins', ...)`
    - `test('keyboard note preview prefers the most specific overlapping range', ...)`
    - `test('keyboard note preview uses focused velocity lane before lane one', ...)`
    - `test('keyboard note preview rejects direct hardware paths without download', ...)`
    - `test('keyboard note preview ignores non-WAV mappings', ...)`
    - `test('keyboard note preview reports missing WAV file', ...)`
    - `test('keyboard note preview ignores stale render completion', ...)`
    - `test('keyboard note preview single-flights identical renders', ...)`
    - `test('keyboard note preview invalidates cache when source file changes', ...)`
    - `test('keyboard note preview cleans temp files on close', ...)`
    - `test('keyboard note preview with auto-preview enabled plays only rendered audio', ...)`
    - `test('keyboard note preview reports adapter failures', ...)`
16. Reuse the existing `_FakePreviewAdapter` where possible. Add a `_ThrowingPreviewAdapter` private test class implementing `PolyAudioPreviewAdapter` for the adapter failure test.
17. Add a `_writeTinyPreviewWav(File file, {int frames = 8})` helper in the test file that writes a minimal 16-bit PCM WAV. Use existing test helper style and imports.
18. Add a `_QueuedNotePreviewRenderer` private test class with `calls`, `ratios`, and `completers`. Its `render(Uint8List bytes, double pitchRatio)` method records inputs and returns the next completer future.
19. For stale render completion, inject `_QueuedNotePreviewRenderer.render`, start preview for C4, start preview for D4 before completing the first completer, complete the second completer with valid rendered WAV bytes, complete the first completer, await both futures, and assert adapter played exactly one path with `state.previewState.visiblePath` equal to the D4 region path.
20. For single-flight, inject `_QueuedNotePreviewRenderer.render`, call `playKeyboardNotePreview(60)` twice before completing the first completer, assert renderer call count is `1`, complete the completer, await both futures, and assert adapter played twice from the same rendered temp path.
21. For direct hardware paths, set state to `sourceMode: PolySampleSourceMode.hardware` with a slash-rooted WAV region and call `playKeyboardNotePreview`. Assert adapter played paths is empty and `state.error == 'Keyboard note preview is only available for local or mounted WAV files.'`.
22. For non-WAV mappings, use only `.aif` region covering the note. Assert adapter played paths is empty and `state.error == 'No local WAV sample is mapped to C4.'` for MIDI 60.
23. For auto-preview, set `autoPreview: true`, use a valid local WAV, call `playKeyboardNotePreview(60)`, and assert the adapter played path is not the source path and only one play occurred.

Verification commands:

```bash
dart format lib/ui/poly_multisample/poly_multisample_builder_cubit.dart test/poly_multisample/poly_multisample_builder_cubit_test.dart
flutter analyze
flutter test test/poly_multisample/poly_multisample_builder_cubit_test.dart
git add -A && git status --short
```

Leftover checks:

```bash
rg -n "playKeyboardNotePreview|_KeyboardNotePreviewMatch|_notePreview" lib/ui/poly_multisample/poly_multisample_builder_cubit.dart test/poly_multisample/poly_multisample_builder_cubit_test.dart
```

Expected status output may list only the two files named in this step.

Commit message: `feat(poly): play keyboard note previews from mapped samples`

---

## STEP 4 of 5 — expose keyboard-note tap and semantics in PolyKeyMap

Spec section: `PolyKeyMap`.

Files:

- `lib/ui/poly_multisample/widgets/poly_key_map.dart`
- `test/poly_multisample/widgets/poly_key_map_test.dart`

Implementation tasks:

1. Add optional constructor parameter and field `ValueChanged<int>? onPreviewNote` to `PolyKeyMap`. Preserve existing required parameters and defaults.
2. Add helper `_midiAtKeyboardPosition(Offset position, Size size, int minMidi, int maxMidi)` exactly as specified.
3. In the existing `GestureDetector.onTapUp` around `CustomPaint`:
   - First test `_regionAtPosition` exactly as today. When it returns a region, call `widget.onSelect(region)` and return.
   - Then test `_midiAtKeyboardPosition`. When it returns a MIDI note, call `widget.onPreviewNote?.call(midi)` and return.
   - Outside both areas, do nothing.
4. Add a private `_noteSemanticTargets(Size canvasSize, int minMidi, int maxMidi)` method returning an empty list when `widget.onPreviewNote == null`.
5. `_noteSemanticTargets` must create one `Positioned.fromRect` per visible MIDI note, covering that key's keyboard-strip rectangle. Each target uses `FocusableActionDetector`, Enter/Space `ActivateIntent`, `GestureDetector`, and `Semantics(button: true, label: 'Preview <NOTE>', onTap: ...)` matching the region semantic target pattern.
6. Add `_noteSemanticTargets(...)` to the `Stack` after region semantic targets so screen readers can reach piano keys.
7. Add the container hint `Tap sample ranges to select. Tap piano keys to preview notes.` while preserving the label `Keyboard map with <N> mapped samples`.
8. Extend `test/poly_multisample/widgets/poly_key_map_test.dart`:
   - Existing tests continue to pass without passing `onPreviewNote` except new tests that need it.
   - Add `testWidgets('tap on keyboard strip previews the tapped midi note', ...)`: pump width `800`, height `200`, one region spanning `0..127`, pass `onPreviewNote` recorder, tap MIDI 60 using x `16 + ((60.5) / 128) * (800 - 32)` and y `176`, assert recorded note `60` and selected region remains null.
   - Add `testWidgets('tap on mapped zone still selects without previewing', ...)`: pass both callbacks, tap the existing mapped-zone point from the current selection test, assert selected region set and preview note remains null.
   - Add `testWidgets('exposes piano note preview semantics', ...)`: ensure semantics, pass `onPreviewNote`, pump a range that includes C4, assert `find.bySemanticsLabel('Preview C4')` finds one widget.

Verification commands:

```bash
dart format lib/ui/poly_multisample/widgets/poly_key_map.dart test/poly_multisample/widgets/poly_key_map_test.dart
flutter analyze
flutter test test/poly_multisample/widgets/poly_key_map_test.dart
git add -A && git status --short
```

Leftover checks:

```bash
rg -n "onPreviewNote|Preview C4|_midiAtKeyboardPosition|_noteSemanticTargets" lib/ui/poly_multisample/widgets/poly_key_map.dart test/poly_multisample/widgets/poly_key_map_test.dart
```

Expected status output may list only the two files named in this step.

Commit message: `feat(poly): expose keyboard note preview taps`

---

## STEP 5 of 5 — wire keyboard-note preview into the sample editor

Spec sections: `PolySamplesEditorView`, acceptance criteria.

Files:

- `lib/ui/poly_multisample/poly_samples_editor_view.dart`
- `test/poly_multisample/poly_samples_editor_view_test.dart`

Implementation tasks:

1. In `_EditorBody.build`, pass `onPreviewNote: cubit.playKeyboardNotePreview` to the wide `PolyKeyMap` instance assigned to `keyMap`.
2. In the narrow-layout inline `PolyKeyMap`, pass the same `onPreviewNote: cubit.playKeyboardNotePreview`.
3. Do not add visible controls, snackbars, or text.
4. In `test/poly_multisample/poly_samples_editor_view_test.dart`, extend `_TestPolyMultisampleBuilderCubit` with:

   ```dart
   final previewedNotes = <int>[];

   @override
   Future<void> playKeyboardNotePreview(int midi) async {
     previewedNotes.add(midi);
   }
   ```

5. Add `testWidgets('keyboard note semantics invokes cubit note preview', ...)`:
   - Use `_state()` as the test state.
   - Pump the editor.
   - Tap `find.bySemanticsLabel('Preview C4')`.
   - Pump once.
   - Assert `cubit.previewedNotes` equals `[60]`.
6. Add `testWidgets('keyboard map semantics explains note preview affordance', ...)`:
   - Ensure semantics.
   - Pump the editor.
   - Assert a semantics node exists with label `Keyboard map with 1 mapped samples` and hint `Tap sample ranges to select. Tap piano keys to preview notes.` using `SemanticsTester` or `find.bySemanticsLabel` plus tester semantics inspection.

Verification commands:

```bash
dart format lib/ui/poly_multisample/poly_samples_editor_view.dart test/poly_multisample/poly_samples_editor_view_test.dart
flutter analyze
flutter test test/poly_multisample/poly_samples_editor_view_test.dart
flutter test test/poly_multisample/wav_metadata_test.dart test/poly_multisample/poly_audio_preview_service_test.dart test/poly_multisample/poly_multisample_builder_cubit_test.dart test/poly_multisample/widgets/poly_key_map_test.dart test/poly_multisample/poly_samples_editor_view_test.dart
git add -A && git status --short
```

Leftover checks:

```bash
rg -n "onPreviewNote: cubit.playKeyboardNotePreview|previewedNotes|Preview C4" lib/ui/poly_multisample/poly_samples_editor_view.dart test/poly_multisample/poly_samples_editor_view_test.dart
```

Expected status output may list only the two files named in this step.

Commit message: `feat(poly): wire keyboard preview into sample editor`
