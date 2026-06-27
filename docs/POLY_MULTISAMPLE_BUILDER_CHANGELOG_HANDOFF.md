# Poly Multisample Builder Changelog and Handoff

Date: 2026-06-27
Branch: `nymph-next-fix`
Status: Experimental fork work, locally tested on Windows, release packaged for fork testing

## Short Summary

This fork adds an experimental Poly Multisample Builder workspace to NT Helper.

The aim is to make Disting NT Poly Multisample sample-folder editing more visual and less error-prone. The current build focuses on reading and editing the WAV folder structure used by the Poly Multisample algorithm: root notes, key ranges, velocity layers, round robin tags, sample lists, local WAV waveform previews, loop metadata, and first-pass destructive WAV edits for local/mounted files.

It intentionally does not try to edit the live Poly Multisample algorithm parameters beyond opening the existing NT Helper parameter panel alongside the sample builder. The sample builder is currently scoped to the `/samples` folder/file naming workflow.

## User-Facing Changes

- Adds a new `Samples` workspace mode beside `Parameters` and `Routing`.
- Adds a `Sample Builder` entry to the main overflow menu.
- Supports opening sample libraries from:
  - a local/mounted folder, e.g. a mounted Disting NT SD card;
  - the Disting NT SD file browser via `/samples`, for listing and structural inspection.
- Shows a key-map view of the sample layout:
  - root notes;
  - low/high key ranges;
  - velocity layers;
  - round robin grouping.
- Shows a sample list with direct per-sample controls:
  - Root;
  - Low;
  - High;
  - Vel;
  - RR.
- Keeps the keyboard map read-only and predictable.
- Keyboard-map selection highlights the corresponding sample/group and scrolls the list to it.
- List edits update the keyboard map.
- Adds an unsaved draft state.
- Adds undo/apply controls for sample filename changes.
- Applies mapping edits by renaming files in place:
  - local/mounted folders use filesystem rename;
  - direct Disting NT SD folders use the existing SD rename API;
  - apply uses a temporary two-phase rename to reduce collision/swap risk.
- Allows the normal NT Helper parameter panel to be toggled on the left side while the sample builder stays open on the right.
- Adds local/mounted WAV waveform preview.
- Reads standard WAV `smpl` loop metadata from local/mounted WAV files.
- Shows loop start/end markers over the local waveform.
- Saves edited local/mounted loop start/end markers back into the WAV `smpl` chunk from the waveform sidebar.
- Adds local/mounted WAV playback.
- Adds continuous loop audition using the current loop marker draft.
- Adds a first-pass local/mounted WAV editor with two clear modes:
  - Metadata mode edits WAV `smpl` loop points only.
  - Destructive mode rewrites audio.
- Destructive mode supports:
  - start/end trim range;
  - fade in/out lengths;
  - independent fade-in and fade-out curves;
  - Linear, Equal Power, Exponential, and S-curve options;
  - gain adjustment in dB;
  - optional peak normalize target.
- Destructive WAV edits can be saved in place with confirmation, or saved as a new WAV via `Save as`.
- Exact destructive trim positions are preserved. Zero-crossing snapping is available via explicit `Zero` controls rather than hidden automatic snapping while dragging or sliding.
- Manually setting a root note now clears stale `No root` warnings immediately.
- For direct Disting NT SD samples, waveform preview is disabled for now. The user is told to mount or copy the SD folder locally to preview WAVs.

## Why Direct Disting SD Waveforms Are Limited

The current Disting NT SD SysEx file API supports whole-file download:

- command `0x7A`;
- operation `0x02`;
- response contains the full file data nibble-encoded as one response.

Uploads are chunked, but downloads are not currently ranged/chunked from the app's point of view.

That means a large WAV file has to be downloaded entirely over MIDI before NT Helper can draw a waveform or read loop metadata. This is too slow and fragile for automatic waveform preview.

Current UX choice:

- Local/mounted files: waveform and loop metadata are automatic.
- Direct Disting NT SD files: waveform preview is disabled; use a local/mounted copy for waveform and loop metadata.

Suggested firmware/API improvement:

- Add a ranged file-read request, e.g. `read_file(path, offset, length)`.
- Or add a dedicated WAV metadata/summary request:
  - read `fmt`;
  - read `smpl` loop points;
  - optionally return waveform peak summaries.

Either would make direct-from-Disting waveform preview practical.

## Implementation Map

New files:

- `lib/poly_multisample/poly_multisample_models.dart`
  - Data models for sample regions and instruments.
- `lib/poly_multisample/poly_multisample_parser.dart`
  - Parses Disting-style sample filenames.
  - Supports root notes, switch tags, velocity layers, round robin tags.
  - Reads local folders and Disting NT `/samples` listings.
- `lib/poly_multisample/wav_metadata.dart`
  - Minimal WAV parser for local waveform preview.
  - Reads RIFF/WAVE, `fmt `, `data`, and first `smpl` loop.
  - Generates downsampled waveform peaks for UI display.
- `lib/ui/poly_multisample/poly_multisample_builder_screen.dart`
  - Main builder UI.
  - Folder/NT SD open actions.
  - Key-map visualization.
  - Sample list editing.
  - Apply/discard draft workflow.
  - Local/mounted file renaming.
  - Direct Disting NT SD file renaming via the existing MIDI API.
  - Local waveform/loop preview.
  - Local audio playback and continuous loop audition.
  - Direct SD waveform disabled message.
- `test/poly_multisample/poly_multisample_parser_test.dart`
  - Parser coverage for Disting note names, roots, switch points, velocity, round robin, flats, and missing root warnings.
- `test/poly_multisample/wav_metadata_test.dart`
  - WAV metadata parser coverage for PCM peaks and `smpl` loop points.

Modified files:

- `lib/ui/synchronized_screen.dart`
  - Adds `EditMode.sampleBuilder`.
  - Adds the `Samples` segmented-control entry.
  - Adds sample-builder workspace switching.
  - Adds optional left-side parameter panel while the sample builder is open.
  - Adds `Sample Builder` to the overflow menu.

## Current Behaviour Details

### Local or Mounted Folder

Recommended path for serious editing.

The builder can:

- recurse a selected folder;
- parse supported audio files;
- build the visual map;
- read WAV bytes directly;
- render waveform peaks;
- read `smpl` loop start/end;
- save edited `smpl` loop start/end;
- preview and continuously audition loop marker drafts;
- destructively render local WAV edits with trim/fades/gain/normalization;
- save destructive WAV edits in place with confirmation;
- save destructive WAV edits as a separate WAV file;
- audition WAV files;
- continuously audition the current loop marker draft;
- apply mapping changes by renaming files back to that folder.

This is the expected workflow for editing an SD card mounted as a normal drive.

### Direct Disting NT SD

Useful for browsing and inspecting structure.

The builder can:

- list `/samples`;
- open a sample folder from the Disting NT SD listing;
- parse filenames into regions;
- display root/range/velocity/round robin layout.
- apply filename-derived mapping changes using SD-card rename operations.

Limitations:

- waveform preview is disabled;
- audio preview is disabled;
- loop metadata is not read;
- loop marker editing is disabled;
- the current API would require full WAV download before either could be read;
- full WAV download may be slow or fail for large samples because the current API returns the entire file as one SysEx response.

## Test Build

Windows release build was produced and copied to:

```text
C:\Users\babyj\nt_helper-build\build\windows\x64\runner\Release\nt_helper.exe
```

Build source was synced from WSL to:

```text
C:\Users\babyj\nt_helper_winbuild
```

## Verification Run

Analyzer:

```text
flutter analyze lib\ui\synchronized_screen.dart lib\ui\poly_multisample lib\poly_multisample test\poly_multisample
```

Result:

```text
No issues found
```

Focused tests:

```text
flutter test test\poly_multisample\poly_multisample_parser_test.dart test\poly_multisample\wav_metadata_test.dart
```

Result:

```text
All tests passed
```

Windows build:

```text
flutter build windows --release
```

Result:

```text
Built build\windows\x64\runner\Release\nt_helper.exe
```

## Tested Manually

- Opened the app on Windows.
- Opened local/mounted sample folders.
- Opened Disting NT `/samples` folders.
- Verified the key map reflects parsed sample roots/ranges/velocity layers.
- Verified list edits update the visual layout.
- Verified local WAV waveform preview.
- Verified local WAV playback and loop audition controls build successfully.
- Verified local WAV `smpl` loop metadata write coverage in tests.
- Verified local WAV render coverage for exact trim start, loop adjustment, fades, gain, and normalize.
- Verified manual root edits clear stale missing-root warnings.
- Verified direct Disting NT SD waveform preview is disabled with a local/mounted-folder message.
- Confirmed direct Disting NT SD full WAV waveform loading should not be exposed as a normal UI path with the current whole-file MIDI download path.

## Known Rough Edges

- The builder is experimental and has had heavy iteration around map/list sync behaviour.
- Complex velocity and round-robin sets need more real-world testing.
- Filename renaming is the current persistence model; this is appropriate for folder-structure editing but not a full algorithm parameter editor.
- Local/mounted loop marker edits can be saved to standard WAV `smpl` metadata from the waveform sidebar.
- Local/mounted destructive WAV editing exists, including trim, fades, gain, normalize, save, and save-as.
- Destructive save is intentionally local/mounted only and requires overwrite confirmation.
- Drag/drop import, drag-to-key assignment, and generated rename workflows are not implemented yet.
- Direct SD waveform and loop metadata are blocked by the whole-file download limitation described above.

## Proposed Next Steps

1. Keep the initial upstream review focused on the local/mounted sample-folder editor.
2. Treat direct Disting NT SD waveform preview as future work unless the firmware/API gains ranged reads or WAV metadata summaries.
3. Add broader parser tests from real factory/sample-library naming patterns.
4. Continue testing the save/apply split:
   - filename/tag edits use the main builder Apply button;
   - loop metadata edits use Save metadata in the waveform sidebar;
   - destructive audio edits use Save or Save as in destructive mode.
5. Add a non-destructive export workflow for imported Decent Sampler libraries.
6. Later, consider drag/drop import and drag-to-key assignment once the manual list/map workflow has had more testing.

## Related Firmware/API Question

See:

```text
docs/DISTING_NT_SD_WAV_ACCESS_QUESTION.md
```

That document summarizes the direct SD WAV access question for Os / Expert Sleepers: ranged reads, WAV metadata summaries, waveform peak summaries, and safe loop metadata writes.

## Suggested Note for Os / Expert Sleepers

The sample builder can inspect `/samples` over the current SD file API, but waveform/loop preview needs either:

- a ranged file-read API such as `read_file(path, offset, length)`, or
- a dedicated WAV metadata/summary API that returns `fmt`, `smpl` loop points, and optional waveform peaks.

The existing `0x7A / 0x02` file download response appears to return the whole file in one response, nibble-encoded. That is acceptable for small files, but it is not practical for automatic sample waveform preview over MIDI.
