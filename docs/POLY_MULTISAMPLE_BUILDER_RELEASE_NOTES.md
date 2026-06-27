# Poly Multisample Builder Test Release Notes

Date: 2026-06-27
Branch: `nymph-next-fix`
Release tag: `poly-multisample-builder-test-v1`
Windows asset: `nt_helper-windows-poly-multisample-builder-test-v1.zip`

This test build adds an experimental Poly Multisample Builder for Disting NT sample folders.

## Highlights

- Adds a `Samples` workspace mode.
- Opens local/mounted sample folders and direct Disting NT `/samples` folders.
- Parses Disting-style WAV filename tags:
  - root notes;
  - switch/low key points;
  - velocity layers;
  - round robin numbers.
- Shows a read-only keyboard map that reflects the sample list.
- Lets the sample list edit:
  - Root;
  - Low;
  - High;
  - Vel;
  - RR.
- Applies mapping edits by renaming files:
  - local/mounted folders use filesystem rename;
  - direct Disting NT SD folders use the existing SD rename API.
- Adds local/mounted WAV waveform preview.
- Reads and writes local/mounted WAV `smpl` loop metadata.
- Adds local/mounted WAV preview playback and loop audition.
- Adds a first-pass local/mounted WAV editor:
  - Metadata mode for loop-point metadata;
  - Destructive mode for trim, fades, gain, and normalize;
  - Save and Save as actions for destructive audio edits.

## Important Limits

- Direct Disting NT SD waveform preview is disabled for now.
- Direct Disting NT SD audio preview is disabled for now.
- Direct Disting NT SD loop metadata reading/editing is disabled for now.
- Those direct-SD audio features need a better firmware/API path than whole-file WAV download over MIDI/SysEx.

## Validation

- Flutter analyze passed for the touched sample-builder and WAV files.
- Parser tests passed.
- WAV metadata/render tests passed.
- Windows release build completed successfully.

For the detailed technical handoff, see:

```text
docs/POLY_MULTISAMPLE_BUILDER_CHANGELOG_HANDOFF.md
```

For the direct Disting NT SD WAV access question, see:

```text
docs/DISTING_NT_SD_WAV_ACCESS_QUESTION.md
```
