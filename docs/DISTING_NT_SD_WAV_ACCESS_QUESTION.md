# Disting NT SD WAV Access Question

Date: 2026-06-27

## Context

I am experimenting with a Poly Multisample Builder inside NT Helper.

For local or mounted SD folders, the builder can:

- parse Disting NT Poly Multisample WAV filename tags;
- show root notes, low/high key ranges, velocity layers, and round robin groups;
- edit filename-derived mapping tags;
- apply those edits by renaming WAV files;
- draw local WAV waveforms;
- read WAV `smpl` loop metadata;
- save edited local/mounted WAV `smpl` loop points;
- audition local WAVs;
- continuously audition the current loop marker draft.

For samples accessed directly from the Disting NT SD card over MIDI/SysEx, NT Helper can list folders and files, but waveform and loop-point editing are currently disabled because the app does not have practical random/ranged WAV access.

## Current Limitation

NT Helper currently appears to have:

- directory listing over SysEx;
- file rename/delete/upload;
- chunked upload;
- whole-file download via the SD file API.

From the app code, file download looks like:

```text
requestFileDownload(path) -> entire file returned in one response
```

The file data is nibble-encoded for MIDI/SysEx transport, so large WAVs become slow and awkward to transfer. This is usable for small preset/script files, but not for responsive waveform display, loop-point inspection, or sample audition.

## Question

Would it be possible to expose a more suitable SD-card file API for WAV inspection/editing from NT Helper?

The most useful options would be:

1. File stat
   - path
   - byte size
   - modified time if available

2. Ranged file read
   - `read_file(path, offset, length)`
   - returns bytes for that range only
   - supports reading RIFF/WAV headers and metadata chunks without downloading the whole WAV

3. WAV metadata read
   - sample rate
   - channel count
   - frame count
   - bit depth/format
   - `smpl` loop start/end points, if present
   - `cue ` / marker info if supported by the firmware

4. WAV metadata write
   - update/add `smpl` loop points without re-uploading the whole WAV
   - ideally safe/atomic, e.g. firmware-side metadata patch or temp-file replace

5. Optional waveform summary
   - firmware returns downsampled min/max peak bins for a WAV
   - avoids transferring the full sample just to draw a waveform

6. Optional chunked full download
   - progress/cancel/resume
   - useful when the user explicitly chooses to copy a WAV locally

## Minimum Useful Feature

The minimum feature that would unlock most of this is probably:

```text
read_file(path, offset, length)
```

With ranged reads, NT Helper could inspect WAV headers and loop metadata directly from the Disting NT SD card.

## Ideal Feature

The ideal feature would be a dedicated WAV summary request:

```text
get_wav_summary(path) -> {
  sampleRate,
  channels,
  bitDepth,
  frameCount,
  loops,
  peakBins
}
```

That would allow direct SD-card waveform display and loop-marker editing without treating MIDI as a bulk WAV transfer pipe.

## Current UX Decision

Until there is a better API, the builder keeps these features local/mounted only:

- waveform preview;
- WAV audition/playback;
- loop-point inspection;
- loop-marker editing and saving.

Direct Disting NT SD access is still useful for browsing and structural filename/tag edits, but not for responsive audio/waveform work.
