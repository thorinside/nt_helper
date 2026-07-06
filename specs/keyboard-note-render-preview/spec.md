# Keyboard-note render preview for poly multisample sample editor

## Request summary

Add keyboard-note tap preview in the poly multisample/sample editor. Tapping a piano key in the key map selects the mapped WAV region for that note, renders the sample at the tapped pitch, and restarts audio playback. Local files and mounted filesystem WAV files are supported. Direct Disting NT hardware paths are out of scope for pitched rendering because the current local renderer needs a filesystem WAV and the hardware path requires a SysEx download before each uncached render.

Hardening policy: **realistic-only**. Required hardening maps to visible user actions, async races, filesystem failures, audio-player failures, and temp-file cleanup paths present in this repo.

Baseline ref: `HEAD` (`6110ab2a` during spec authoring).

## Inventory method

Inventory was produced before source reading with:

```bash
python3 /Users/nealsanche/nosuch/nt_helper/.pi/skills/decision-free-specs/languages/dart/inventory.py $(find lib/poly_multisample lib/ui/poly_multisample test/poly_multisample -name '*.dart' | sort) > /tmp/keyboard-note-render-preview-inventory.md
python3 /Users/nealsanche/nosuch/nt_helper/.pi/skills/decision-free-specs/languages/dart/inventory.py lib/poly_multisample/wav_metadata.dart >> /tmp/keyboard-note-render-preview-inventory.md
```

A hand-check was performed against `lib/poly_multisample/poly_audio_preview_service.dart`; the inventory's class and method list matches the source.

## Current code inventory

| Area | File | Lines | Current symbols/signals | Imported by |
|---|---:|---:|---|---|
| Playback adapter/state | `lib/poly_multisample/poly_audio_preview_service.dart` | 134 | `PolyAudioPreviewAdapter.play/stop/dispose`, `AudioplayersPreviewAdapter`, `PolyAudioPreviewState`, `PolyAudioPreviewService.playOrStopPreview`, `stop` | cubit, dialog tests, editor tests, service tests |
| Sample region model | `lib/poly_multisample/poly_multisample_models.dart` | 324 | `PolySampleRegion` fields `path`, `fileName`, `rootMidi`, `rangeLow`, `rangeHigh`, `velocityLayer`, `roundRobin`; `isSupportedAudioName` accepts wav/aif/aiff | parser, services, widgets, tests |
| Note parser/sorter | `lib/poly_multisample/poly_multisample_parser.dart` | 160 | `PolyMultisampleParser.midiToNoteName`, `noteNameToMidi`, `sortRegions` sorts root, velocity, RR, display | services, widgets, tests |
| WAV file service | `lib/poly_multisample/poly_wav_service.dart` | 63 | Reads WAV overview, writes loop metadata, writes destructive WAV via `WavAudioRenderer.render` | cubit, tests |
| WAV parsing/rendering | `lib/poly_multisample/wav_metadata.dart` | 757 | `WavMetadataReader.parse`, `WavAudioRenderer.render`, private `_FmtChunk`, `_DataChunk`, `_readSample`, `_encodeAudio`, `_rebuildWave`; supports PCM 8/16/24/32 and float32 | models, wav service, waveform widget, tests |
| Builder cubit | `lib/ui/poly_multisample/poly_multisample_builder_cubit.dart` | 1844 | Selection, waveform loading, normal preview, auto-preview, hardware preview cache, temp root cleanup, source resets | editor view, screen tests, cubit tests |
| Region math | `lib/ui/poly_multisample/poly_region_math.dart` | 105 | `effectiveLow`, `effectiveHigh`, `midiExtents`, `velocityLanes`, `selectedRegionFor`, `sampleDisplayLabel` | editor view, key map, tests |
| Editor assembly | `lib/ui/poly_multisample/poly_samples_editor_view.dart` | 377 | Constructs `PolyKeyMap`, sample list, inspector; key map currently only calls `selectRegion` | editor tests |
| Key map widget | `lib/ui/poly_multisample/widgets/poly_key_map.dart` | 514 | Renders ranges and piano strip; current hit test selects region zones only; semantic targets exist per region | editor view, widget tests |
| Preview service tests | `test/poly_multisample/poly_audio_preview_service_test.dart` | 81 | Fake adapter records paths/volumes/stops; tests toggle and display path | none |
| Cubit tests | `test/poly_multisample/poly_multisample_builder_cubit_test.dart` | 2481 | Existing fake preview adapter, queued hardware service, fake WAV service, temp root fixtures | none |
| Key map tests | `test/poly_multisample/widgets/poly_key_map_test.dart` | 203 | Semantics label, tap mapped zone, keyboard focus, duplicate names, empty rendering | none |
| Editor tests | `test/poly_multisample/poly_samples_editor_view_test.dart` | 317 | Test cubit subclass, editor pump, toolbar/list/inspector assertions | none |
| WAV tests | `test/poly_multisample/wav_metadata_test.dart` | 315 | PCM fixtures and loop/render tests | none |

## Architectural decisions

1. **Existing audio playback mechanism.** Use `PolyAudioPreviewService` and its existing `AudioplayersPreviewAdapter`/`DeviceFileSource` playback path. Add a restart-only service method for generated previews. No new audio plugin and no MIDI note playback.
2. **Render a temporary pitched WAV file before playback.** Add a `WavAudioRenderer.renderPitchedPreview` static method in `wav_metadata.dart`. It reads supported RIFF/WAVE PCM or float32 input with the existing private parser helpers, linearly resamples sample frames at a pitch ratio, and writes a new 16-bit PCM RIFF/WAVE with the source sample rate and channel count.
3. **No time-stretching.** Pitched preview changes duration. Higher notes are shorter; lower notes are longer. This is the only local behavior implemented.
4. **Local and mounted WAV only.** A supported preview source is a `.wav` path that is not `sourceMode == hardware && path.startsWith('/')`. Mounted SD-card files opened through the filesystem are local paths and are supported. `.aif`/`.aiff` pitched preview is out of scope.
5. **Direct hardware paths out of scope.** For `PolySampleSourceMode.hardware` with slash-rooted paths, keyboard-note preview selects no region and emits `Keyboard note preview is only available for local or mounted WAV files.` Existing normal preview remains unchanged.
6. **Keyboard strip is the preview affordance.** Tapping painted region rectangles keeps the existing select-only behavior. Tapping the piano-key strip calls the new note preview method. Screen-reader keyboard-note semantic buttons call the same note preview method.
7. **Manual note preview overrides auto-preview.** Tapping a piano key does not trigger normal auto-preview. It selects the region and then plays the rendered pitched WAV. The cubit adds an optional `autoPreviewSelection` named parameter to `selectRegion`, default `true`, and note preview calls it with `false`.
8. **Repeat taps restart playback.** Generated note previews use `PolyAudioPreviewService.restartPreview`, never `playOrStopPreview`, so a second tap of the same note restarts audio instead of toggling it off.
9. **Visible preview path remains the sample path.** The temp WAV path is stored in `playingPath`; the source sample path is passed as `displayPath`. Existing row preview highlighting continues to use `state.previewState.visiblePath == region.path`.
10. **Region matching lives in the cubit.** Add private cubit helpers for note-preview matching instead of importing `poly_region_math.dart`, because `poly_region_math.dart` imports the cubit for `selectedRegionFor` and a cubit import back into it creates a cycle.
11. **Overlapping ranges use deterministic specificity.** For a tapped MIDI note, WAV candidates must have `rootMidi != null`, cover the note via effective low/high, and pass the local/mounted WAV rule. Velocity lane filtering runs first, then overlap ranking sorts by smaller span, higher low bound, closer root to tapped note, lower round-robin number, then `displayName`.
12. **Velocity default.** The velocity lane is selected as follows: focused region lane when that region is a WAV candidate covering the note; otherwise the first selected path's lane when it is a WAV candidate covering the note; otherwise lane `1` when lane 1 has candidates; otherwise the lowest numeric candidate lane.
13. **Round robin rotation.** After velocity and overlap ranking, the primary candidate defines a range group by `effectiveLow/effectiveHigh/velocityLayer`. All candidates in the same range group are sorted by `(roundRobin ?? 1)`, then `displayName`, then `path`. A cursor keyed by `low:high:velocity` selects `cursor % group.length` and increments only after a local/mounted WAV temp render has completed and playback is about to start. This rotates same-range round robins across taps.
14. **No preview for unmapped notes.** When no local/mounted WAV candidate covers the note, leave selection unchanged, stop no audio, and emit `No local WAV sample is mapped to <NOTE>.` where `<NOTE>` comes from `PolyMultisampleParser.midiToNoteName`.
15. **Temp cache and cleanup.** Rendered note previews are cached by normalized path, file modified milliseconds, file length, source root MIDI, and target MIDI. Files are written under `Directory.systemTemp.createTemp('nt_helper_poly_note_preview_')`. All note-preview temp roots are deleted best-effort in `close()` and `returnToSources()`.
16. **Latest tap wins.** Add `_notePreviewRequest` token. Every await in note-preview rendering checks the token and `_isClosing`; stale completions leave cached files in place but never play audio or change selection after the newer tap.
17. **Single-flight per render key.** Add `_notePreviewRenderInFlight` map from render cache key to `Future<String>`. Concurrent taps needing the same render await the same future. Different render keys may render concurrently; only the latest request plays.
18. **Inject renderer for deterministic tests.** Add a cubit constructor parameter for a `FutureOr<Uint8List> Function(Uint8List bytes, double pitchRatio)` renderer. Production default calls `WavAudioRenderer.renderPitchedPreview`; tests use queued render completions to verify latest-wins and single-flight behavior without timing sleeps.
19. **No success snackbar.** Successful preview produces no snackbar/effect. Failures use existing cubit `error` behavior.
20. **Accessibility.** The key map container label gains a hint that piano keys preview notes. Each visible piano key gets a semantic button label `Preview <NOTE>`. The semantic action calls the same `onPreviewNote` callback as pointer taps. Existing region semantic labels remain unchanged.

## Decision inventory

| Decision | Rationale | Files affected | Required/optional/out-of-scope |
|---|---|---|---|
| Use `PolyAudioPreviewService`/audioplayers | Already present, tested, and supports device files | `poly_audio_preview_service.dart`, cubit tests | Required |
| Add restart-only preview API | Repeat taps must restart, not toggle off | `poly_audio_preview_service.dart`, `poly_audio_preview_service_test.dart` | Required |
| Render temp WAV files | audioplayers path accepts files; repo has WAV parser and no raw buffer playback API | `wav_metadata.dart`, cubit | Required |
| Output pitched previews as 16-bit PCM WAV | Smallest deterministic render format playable by audioplayers | `wav_metadata.dart`, `wav_metadata_test.dart` | Required |
| Linear interpolation resampling | Sufficient for preview and implementable with current utilities | `wav_metadata.dart` | Required |
| No looped sustain in note preview | No note-off UI exists and loop playback would need a transport model | none | Out-of-scope |
| No AIF/AIFF pitched preview | Current local renderer only parses RIFF/WAVE | cubit | Out-of-scope |
| No direct hardware pitched preview | Hardware path requires transfer before local render; user allowed this scope cut | cubit, tests | Out-of-scope |
| Piano strip triggers preview; region rectangles select only | Preserves current region editing behavior and adds a precise note target | `poly_key_map.dart`, key map tests | Required |
| Optional `onPreviewNote` callback on `PolyKeyMap` | Keeps widget usable in tests and read-only contexts | `poly_key_map.dart`, editor view | Required |
| Optional `autoPreviewSelection` parameter on `selectRegion` | Manual note preview must not start raw auto-preview first | cubit, tests | Required |
| Visible path is source sample path | Existing sample list preview indicator keeps working | cubit | Required |
| Velocity default as focused/selected/lane1/lowest | Deterministic behavior without velocity input from a key tap | cubit, tests | Required |
| Overlap ranking by narrowest range then deterministic fields | Predictable selection for overlapping mappings | cubit, tests | Required |
| RR cursor per low/high/velocity | Implements same-range round-robin rotation | cubit, tests | Required |
| Latest-wins token and per-key render single-flight | Prevents stale audio playback after rapid taps | cubit, tests | Required |
| Renderer injection for tests | Makes async race tests deterministic without production timing hooks | cubit, tests | Required |
| Temp cache invalidated by file stat | Handles mounted/local file edits without expensive hashes | cubit, tests | Required |
| Best-effort temp root cleanup on close/source reset | Prevents temp-file accumulation during normal app use | cubit, tests | Required |
| No new visible toolbar control | Preview is directly on the keyboard; no extra mode toggle | editor view | Required |
| No Strategy registry | There is one behavior path: local WAV pitched render | none | Out-of-scope |

## Hardening matrix

| Risk | Plausible path | Chosen handling | Tests required |
|---|---|---|---|
| Same-note repeat toggles audio off | Existing `playOrStopPreview` toggles when visible path matches | Use `restartPreview` for keyboard-note previews | Preview service test: `restartPreview restarts the same visible path without toggling` |
| Rapid taps play stale note after newer note | User taps C4 then D4 while first render awaits disk IO | `_notePreviewRequest` token checked after every await; stale render does not call playback | Cubit test: `keyboard note preview ignores stale render completion` |
| Duplicate rendering for same temp key | Double tap while first render for the same source/note is still running | `_notePreviewRenderInFlight` shares one future per cache key | Cubit test: `keyboard note preview single-flights identical renders` |
| File deleted between matching and render | Local or mounted sample removed while user taps key | Catch `FileSystemException`, emit error text, no playback | Cubit test with deleted file: `keyboard note preview reports missing WAV file` |
| Invalid or unsupported WAV | User imports corrupt `.wav` or unsupported bit depth | `renderPitchedPreview` throws `FormatException`; cubit emits error | WAV renderer test for invalid bytes; cubit error test |
| Hardware source path tapped | User opened NT hardware folder and taps keyboard | Emit `Keyboard note preview is only available for local or mounted WAV files.` and do not download | Cubit test: `keyboard note preview rejects direct hardware paths without download` |
| AIF/AIFF mapped note tapped | Existing models support AIF but local renderer cannot parse AIF | Treat as no local WAV candidate; emit no-local-WAV error | Cubit test: `keyboard note preview ignores non-WAV mappings` |
| Overlapping note ranges | User has two regions covering the same note | Filter velocity, rank smaller span first, deterministic tie-breakers | Cubit test: `keyboard note preview prefers the most specific overlapping range` |
| No velocity value from key tap | Piano key has pitch only | Apply focused/selected/lane1/lowest lane rule | Cubit tests for focused lane and lane1 fallback |
| Round robins never rotate | Same note range has RR1/RR2 samples | Cursor keyed by low/high/velocity rotates after successful render | Cubit test: `keyboard note preview rotates same-range round robins` |
| Source file changed but cache path reused | User edits or overwrites WAV after first preview | Cache key includes modified milliseconds and file length | Cubit test: overwrite file, second preview uses a different rendered path |
| Temp files accumulate | User previews many notes then closes or returns to sources | Best-effort recursive deletion of note-preview temp roots in `close` and `returnToSources` | Cubit test: temp preview directory removed after close or source reset |
| Existing region tap behavior regresses | New keyboard note hit targets overlap region area | Pointer note hit only accepts keyboard strip; region zone code remains select-only | Key map test: existing mapped-zone tap still selects and does not call note callback |
| Screen-reader users cannot trigger note preview | Piano strip is painted custom UI | Add semantic button targets labeled `Preview <NOTE>` | Key map semantics test for `Preview C4` action |
| Auto-preview double-plays raw and pitched sample | Auto-preview enabled, note tap changes selection | Note preview calls selection with `autoPreviewSelection: false` | Cubit test: auto-preview enabled note tap plays only rendered temp path |
| Audio player rejects temp file | Adapter throws during restart | Catch in cubit and emit error, leave state consistent | Cubit test with fake adapter throwing on play |

No additional hardening is required for note-off, sustained playback, network paths, or hardware transfer retries because this feature only produces one-shot local temp WAV playback.

## Target file tree

```text
lib/poly_multisample/
  poly_audio_preview_service.dart       (extend)
  wav_metadata.dart                     (extend)

lib/ui/poly_multisample/
  poly_multisample_builder_cubit.dart   (extend)
  poly_samples_editor_view.dart         (extend)
  widgets/poly_key_map.dart             (extend)

test/poly_multisample/
  poly_audio_preview_service_test.dart  (extend)
  poly_multisample_builder_cubit_test.dart (extend)
  wav_metadata_test.dart                (extend)
  poly_samples_editor_view_test.dart    (extend)
  widgets/poly_key_map_test.dart        (extend)
```

## Interface tables

### `WavAudioRenderer.renderPitchedPreview`

Add this static method to `WavAudioRenderer` in `lib/poly_multisample/wav_metadata.dart`:

```dart
static Uint8List renderPitchedPreview(
  Uint8List bytes, {
  required double pitchRatio,
})
```

Behavior:

| Input/field | Rule |
|---|---|
| `bytes` | Must be RIFF/WAVE with `fmt ` and `data` chunks. Reuse existing parser helpers. |
| Format support | Same as `WavAudioRenderer.render`: PCM 8/16/24/32 or IEEE float32. |
| `pitchRatio` | Clamp non-finite and `<= 0` values to `1.0`. Values above zero are used directly. |
| Output sample rate | Same as source sample rate. |
| Output channels | Same as source channel count. |
| Output bit depth | Always PCM 16-bit little-endian. |
| Output frame count | `max(1, (sourceFrameCount / safePitchRatio).ceil())`. |
| Resampling | For each output frame and channel, source position is `outputFrame * safePitchRatio`; linearly interpolate floor/ceil source frames; clamp source indexes to last frame. |
| Metadata | Do not copy `smpl` loop metadata or non-audio chunks. Output contains only `RIFF`, `fmt `, and `data`. |
| Errors | Throw `FormatException` with existing style messages for too-small, non-WAVE, missing chunks, unsupported format, or zero-frame audio. |

### `PolyAudioPreviewService.restartPreview`

Add this public method:

```dart
Future<void> restartPreview(
  String path, {
  double gainDb = 0,
  String? displayPath,
})
```

Behavior:

| State | Rule |
|---|---|
| No current playback | Play `path` at `_volumeFromGainDb(gainDb)`, then set state with `playingPath: path`, `displayPath: displayPath`, `gainDb: gainDb`. |
| Current playback exists | Await adapter `stop()`, then play `path`, then set state. |
| Same `visiblePath` as current state | Still stop and play; never toggle off. |
| Completion stream | Existing completion subscription clears state exactly as before. |

### `PolyMultisampleBuilderCubit.selectRegion`

Extend the signature only by adding one optional named parameter with default:

```dart
void selectRegion(
  String path,
  PolyRegionSelectionMode mode, {
  IDistingMidiManager? manager,
  bool autoPreviewSelection = true,
})
```

Behavior change: all current auto-preview logic inside `selectRegion` runs only when `autoPreviewSelection` is `true`. Existing callers do not pass the parameter and preserve current behavior.

### `PolyMultisampleBuilderCubit.playKeyboardNotePreview`

Add this public method:

```dart
Future<void> playKeyboardNotePreview(int midi)
```

Behavior:

1. Clamp `midi` to `0..127`.
2. Increment `_notePreviewRequest` and store request id.
3. Resolve the preview region with the velocity, overlap, and RR rules in this spec.
4. On no region, emit `error: 'No local WAV sample is mapped to <NOTE>.'` and return.
5. Call `selectRegion(region.path, PolyRegionSelectionMode.replace, autoPreviewSelection: false)`.
6. Render or reuse a cached temp WAV for the selected region and target MIDI.
7. After each await, return without playback when request id is stale or cubit is closing.
8. Just before playback, increment the RR cursor for the selected range group.
9. Call `_previewService.restartPreview(renderedPath, displayPath: region.path, gainDb: state.previewGainDb)`.
10. Catch `FileSystemException`, `FormatException`, and adapter errors by emitting `error: error.toString()`.

Extend the cubit constructor with this optional parameter:

```dart
FutureOr<Uint8List> Function(Uint8List bytes, double pitchRatio)? notePreviewRenderer,
```

Store it in:

```dart
final FutureOr<Uint8List> Function(Uint8List bytes, double pitchRatio)
_notePreviewRenderer;
```

Production default:

```dart
_notePreviewRenderer = notePreviewRenderer ??
    ((bytes, pitchRatio) => WavAudioRenderer.renderPitchedPreview(
          bytes,
          pitchRatio: pitchRatio,
        ));
```

Add private cubit fields:

```dart
final Map<String, String> _notePreviewCache = {};
final Map<String, Future<String>> _notePreviewRenderInFlight = {};
final List<String> _notePreviewRoots = [];
final Map<String, int> _notePreviewRoundRobinCursor = {};
var _notePreviewRequest = 0;
```

Add private helpers with these names:

| Helper | Purpose |
|---|---|
| `_resolveKeyboardNotePreviewRegion(int midi)` | Applies candidate filtering, velocity lane default, overlap ranking, and RR group cursor read. Returns a private result object with region and RR cursor key. |
| `_notePreviewEffectiveLow(PolySampleRegion region)` | Same fallback as `effectiveLow`: `rangeLow ?? switchPoint ?? rootMidi ?? 0`, clamped `0..127`. |
| `_notePreviewEffectiveHigh(PolySampleRegion region, List<PolySampleRegion> regions)` | Same fallback as `effectiveHigh` for same velocity lane. |
| `_isLocalMountedWavPreviewPath(String path)` | Returns true only for `.wav` paths that are not direct hardware source paths. |
| `_renderedKeyboardNotePreviewPath(PolySampleRegion region, int midi)` | Builds stat-based cache key, single-flights render through `_notePreviewRenderer`, writes temp WAV, returns temp path. |
| `_cleanupNotePreviewRoots()` | Best-effort recursive deletion, clears cache/in-flight/root lists. |

The private result class name is `_KeyboardNotePreviewMatch` with fields:

```dart
const _KeyboardNotePreviewMatch({
  required this.region,
  required this.roundRobinCursorKey,
});

final PolySampleRegion region;
final String roundRobinCursorKey;
```

### `PolyKeyMap`

Extend constructor and widget fields:

```dart
final ValueChanged<int>? onPreviewNote;
```

Pointer behavior:

| Area | Behavior |
|---|---|
| Region zone (`layout.zoneRect`) | Existing `_regionAtPosition` selection behavior remains unchanged. |
| Keyboard strip (`layout.keyboardTop..keyboardBottom`) | Compute MIDI from x coordinate and call `onPreviewNote?.call(midi)`. Do not call `onSelect`. |
| Outside both areas | No callback. |

Add helper:

```dart
int? _midiAtKeyboardPosition(
  Offset position,
  Size size,
  int minMidi,
  int maxMidi,
)
```

Semantics behavior:

| Element | Rule |
|---|---|
| Container label | Remains `Keyboard map with <N> mapped samples`. |
| Container hint | Add `Tap sample ranges to select. Tap piano keys to preview notes.` |
| Piano key targets | For every visible MIDI note from `minMidi` through `maxMidi`, add a `Positioned.fromRect` semantic button over that key in the keyboard strip. |
| Piano key label | `Preview <NOTE>`, using `PolyMultisampleParser.midiToNoteName(midi)`. |
| Piano key action | Calls `onPreviewNote?.call(midi)`. |
| No callback | Do not add piano key semantic targets when `onPreviewNote == null`. |

### `PolySamplesEditorView`

Wire both desktop and narrow `PolyKeyMap` instances:

```dart
onPreviewNote: cubit.playKeyboardNotePreview,
```

No new toolbar buttons, chips, snackbars, or success effects are added.

## Acceptance criteria

1. `WavAudioRenderer.renderPitchedPreview` renders valid 16-bit WAV bytes for pitch ratios `2.0`, `0.5`, and invalid ratio fallback `1.0`.
2. `PolyAudioPreviewService.restartPreview` restarts playback for the same visible path and never toggles off.
3. Tapping `Preview C4` or the painted C4 piano key calls `PolyMultisampleBuilderCubit.playKeyboardNotePreview(60)` through the editor view.
4. The cubit selects the matched region, writes a temp WAV, and uses `restartPreview` with source path as display path.
5. Same-range RR regions rotate on subsequent successful taps.
6. Overlapping ranges, velocity defaults, non-WAV mappings, hardware paths, stale async completions, and temp cleanup behave exactly as stated above.
7. Existing normal sample preview and auto-preview tests keep passing.
8. Verification command passes:

```bash
flutter analyze && flutter test
```
