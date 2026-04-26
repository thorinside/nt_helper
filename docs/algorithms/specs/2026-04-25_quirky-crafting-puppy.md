# Preset Export — Samples & Multisamples Bundling Fix

## Status: Final, scope-confirmed with user

## Context

The "Export Preset Package" feature (zip bundle that travels a preset to
another NT) is meant to be **self-contained**: every algorithm dependency the
preset references on the SD card should ride along inside the zip. The user is
seeing samples missing from exported packages.

After scope review with the user:

- **`samp` Sample Player** plays *specific* sample files. Single-file copy is
  the correct unit when an explicit filename is given. EXCEPT: when the
  trigger's `sample` field is the firmware token `<MULTISAMPLE>`, the firmware
  itself auto-selects from the folder — and **the whole folder must travel**.
- **`pyms` / `pymu` Poly Multisample** algorithms always play files chosen from
  a folder by the firmware. These are folder-level deps (already correct).
- The user wants the export dialog to show an **estimated zip size before
  export** and **per-file progress** while it runs (folder-level multisample
  copies can pull dozens of files over slow SysEx).

The `samples/` directory references for `samp` are mostly working today —
the failure mode that prompted "samples aren't being added" is almost
certainly the `<MULTISAMPLE>` token: the analyzer adds a literal file named
`<MULTISAMPLE>` to `sampleFiles`, the collector tries to read it, finds
nothing, and the manifest reports a missing file the user can never
"fix" by adjusting their SD card.

Manual references:
`/Users/nealsanche/nosuch/nt_docs/output/markdown/full_manual.md`
- Samples in `samples/<folder>/`, lines ~1206–1247
- `<MULTISAMPLE>` token semantics, line ~11079
- Multisample folder structure & naming, lines ~1369–1420

## Diagnosis

| Slot field | Today | Should be | Action |
|---|---|---|---|
| `slot['timbres'][].folder` for `pyms` | folder copy → `multisamples/<f>/` | folder | OK — no change |
| `slot['folder']` for `pymu` | folder copy → `multisamples/<f>/` | folder | OK — no change |
| `slot['timbres'][].folder` for other GUIDs | folder copy → `samples/<f>/` | folder | OK — no change |
| `slot['triggers'][].folder` + `sample = "<MULTISAMPLE>"` | tries to read `samples/<folder>/<MULTISAMPLE>`, fails silently, manifest warns about missing file | folder copy → `samples/<folder>/` | **fix** |
| `slot['triggers'][].folder` + explicit filename | single-file copy `samples/<folder>/<sample>` | single file | OK — no change |
| `slot['sample']` (granulator) | single-file copy under `samples/` | single file | OK — no change |
| `slot['wavetable']` | recursive folder copy via `_collectWavetableFolder` | folder of up to ~100 WAV slices, OR single concatenated `.wav` | OK — no change, but **add regression test** with a 50+ file fixture to lock in folder-level behavior |
| MIDI Player `midp` Folder+File | not analyzed; `dependencies.midiFiles` never populated (file_collector.dart:108–111 has plumbing but it's empty) | single file under `MIDI/<folder>/<file>` | **fix** (in scope) |
| Scala `.scl` files referenced by Quantizer / scale-aware algorithms | not analyzed | single file under `scl/<file>` | **fix** (in scope) |
| KBM `.kbm` files | not analyzed | single file under `kbm/<file>` | **fix** (in scope) |

**Note on JSON shape for MIDI/scl/kbm — verified by inspecting real presets
in `~/Desktop/DISTING NT/presets/`:**

- `Factory/MIDI Song Player.json` shows the `midp` slot stores Folder/File as
  the first two integers in its flat `parameters` array (e.g.
  `"parameters": [0, 1, 1, 1, 0, ...]` = folder index 0, file index 1). No
  resolved name strings.
- `Factory/Aleatoric Piano.json` shows the `quan` (Quantizer) slot keys are
  just `guid`, `specs`, `name`, `parameters` — no named scale string field.
  Scale `.scl` / `.kbm` selection is also parameter-array encoded.

Because index→name resolution would require either querying the live NT for
parameter value-strings (not always feasible — user may export a preset that
isn't currently loaded) or replicating the firmware's directory-sort logic
exactly, **the chosen strategy is to bundle the relevant whole directories**
(`MIDI/`, `scl/`, `kbm/`) when a preset slot uses an algorithm that consumes
them. These trees are small (KB–low MB), and over-inclusion is far better
than silently shipping a preset that loads with the wrong MIDI file or scale
on the destination NT.

## Goal

1. Stop treating `<MULTISAMPLE>` (and other `<…>` tokens) as filenames; route
   those triggers to folder-level copy under `samples/<folder>/` so the
   firmware can resolve them on the destination NT.
2. Bundle MIDI Player files (`MIDI/<folder>/<file>.mid`) and Scala/KBM scale
   files (`scl/<file>.scl`, `kbm/<file>.kbm`) into the package so presets that
   use them are self-contained on the destination NT.
3. Surface a pre-export **estimated zip size** and an **in-flight per-file
   progress** indicator in the export dialog, so users know what they're
   committing to and can see folder-of-multisamples reads making progress
   instead of staring at a spinner.
4. Add regression tests so the `<MULTISAMPLE>`, MIDI, and scale cases can
   never silently regress.

## Implementation plan

### 1. Handle `<MULTISAMPLE>` tokens in `samp` triggers

**File:** `lib/services/preset_analyzer.dart` (replace lines 125–131)

```dart
if (slot['triggers'] != null) {
  for (final trigger in slot['triggers']) {
    final folder = trigger['folder']?.toString().trim();
    final sample = trigger['sample']?.toString().trim();
    if (folder == null || folder.isEmpty) continue;

    if (sample == null || sample.isEmpty || sample.startsWith('<')) {
      // Firmware tokens like `<MULTISAMPLE>`: the algorithm selects from
      // the folder at runtime. Bundle the whole folder so the destination
      // NT can resolve the same way.
      deps.sampleFolders.add(folder);
    } else {
      deps.sampleFiles.add('$folder/$sample');
    }
  }
}
```

Filtering on `sample.startsWith('<')` defends against future firmware tokens
that follow the `<UPPER>` convention.

### 2. De-dup at file-vs-folder boundary

**File:** `lib/services/file_collector.dart`

`PresetDependencies.sampleFolders` is already a `Set<String>` — folder dedup
is automatic. But if a preset has both an explicit-filename trigger and a
`<MULTISAMPLE>` trigger pointing at the same folder, the folder copy will
include the named file *and* `_collectFile` would re-read it. Add a guard.

In `collectDependencies`:

```dart
final List<CollectedFile> files = [];
final Set<String> collectedPaths = {};
final List<String> warnings = [];
```

Pass `collectedPaths` to `_collectFile` and `_collectFolder`. In `_collectFile`
short-circuit on duplicate; in `_collectFolder` skip duplicates inside the
recursion loop.

### 3. Manifest report — only flag missing folders for trigger refs

**File:** `lib/services/preset_analyzer.dart` (`generatePackageReport`,
lines 178–183)

Replace the `sampleFiles`-as-trigger-paths check. After the change,
`sampleFiles` only contains explicit-filename triggers, which is the correct
shape for a path-presence check. But add a sample-folder presence check too:

```dart
for (final folder in dependencies.sampleFolders) {
  final hasAny = collectedFiles.any(
    (f) => f.relativePath.startsWith('samples/$folder/'),
  );
  if (!hasAny) missing.add('samples/$folder/');
}
```

This makes the report message honest when a `<MULTISAMPLE>` trigger's folder
genuinely doesn't exist on the SD card — the user sees
"Missing: samples/MyKit/" instead of "Missing: samples/MyKit/<MULTISAMPLE>".

### 4. Bundle MIDI / scl / kbm trees when consumed

**Files:**
- `lib/models/preset_dependencies.dart` — add three boolean flags:
  `bool bundleMidiTree`, `bool bundleSclTree`, `bool bundleKbmTree`. Default
  false. Keep `Set<String> midiFiles` for forward compatibility but mark it
  as unused for now.
- `lib/services/preset_analyzer.dart` — extend `_analyzeSlot`:

  ```dart
  // GUIDs whose presets reference files via parameter-array indices,
  // requiring whole-directory bundling. The lists below come from
  // scanning every algorithm in `docs/algorithms/*.json` for Folder/File
  // and Microtuning/Scala parameters (see "Algorithm scan" below).
  static const _midiUsingGuids = <String>{'midp'};
  static const _scaleUsingGuids = <String>{
    'quan', // Quantizer
    'trak', // Tracker
    'ssjw', // Seaside Jawari
    'pyfm', // Poly FM
    'tuns', // Tuner (simple)
    'tunf', // Tuner (fancy)
  };

  if (_midiUsingGuids.contains(guid)) deps.bundleMidiTree = true;
  if (_scaleUsingGuids.contains(guid)) {
    deps.bundleSclTree = true;
    deps.bundleKbmTree = true;
  }
  ```

  **Algorithm scan (verified):**
  - **MIDI Player (`midp`)** has `Folder` + `File` parameters loading from
    `MIDI/<folder>/<file>.mid`.
  - **Wavetable consumers** (`vcot`, `wtws`, `vcop`, `pywt`) store their
    wavetable as `slot['wavetable']` (string) — already handled by the
    existing `slot['wavetable']` analyzer path. No new code needed; verified
    against `Just A Phase.json` (vcot) and `Wavetable Voice (CV).json` (vcot)
    in `~/Desktop/DISTING NT/presets/`.
  - **Scala-microtuning consumers** (the six GUIDs above): each has
    `Microtuning` / `Scala .scl` / `Scala .kbm` parameters loading from
    `scl/` and `kbm/`. Only `quan` was confirmed in user presets but the
    parameter shape is identical across all six.

- `lib/services/file_collector.dart` — when the flag is set, recursively
  list and collect every audio/MIDI/text file under `MIDI/`, `scl/`,
  `kbm/`. Reuse `_collectFolder` with a per-tree extension filter:

  ```dart
  if (dependencies.bundleMidiTree) {
    await _collectTree('MIDI', files, warnings,
        extensions: const {'mid', 'midi'});
  }
  if (dependencies.bundleSclTree) {
    await _collectTree('scl', files, warnings,
        extensions: const {'scl'});
  }
  if (dependencies.bundleKbmTree) {
    await _collectTree('kbm', files, warnings,
        extensions: const {'kbm'});
  }
  ```

  `_collectTree` is a small generalization of `_collectFolder` that takes
  the base directory directly and an extension whitelist. Existing
  `_collectFolder` (which is sample-folder oriented and hard-codes audio
  extensions) stays as-is.

- `lib/models/package_config.dart` — add `bool includeMidiTree`,
  `bool includeScales` flags (default true) so the user can opt out of the
  bigger bundle in the dialog. Wire to checkboxes in
  `preset_package_dialog.dart`.

- Manifest report should account for these by listing the directory paths,
  not individual files (avoids 500-line manifest noise for a large MIDI
  library).

**Discovery caveat:** the GUID lists (`_midiUsingGuids`,
`_scaleUsingGuids`) are seeded with `midp` and `quan`. If users hit
presets that reference these file types via other algorithms, the GUID
sets get expanded — same pattern as `_multisampleGuids`.

### 5. Pre-export size estimate

**Files:**
- `lib/services/preset_analyzer.dart` (or a new `lib/services/package_estimator.dart`)
- `lib/ui/widgets/preset_package_dialog.dart`

Add an `estimatePackageSize` method that takes `PresetDependencies` plus the
`PresetFileSystem` and walks each dependency, calling `listFiles` for folders
and reading file metadata where the FS supports it. Sum the byte counts and
return a structured result:

```dart
class PackageSizeEstimate {
  final int totalBytes;
  final int fileCount;
  final List<FolderSize> folders; // (path, fileCount, bytes)
  final List<String> warnings;    // missing folders, oversized files
}
```

`PresetFileSystem` exposes `readFile`/`listFiles` only — there is no
file-size API. Two options:

- **Add `Future<int?> getFileSize(String path)`** to the interface. The live
  implementation calls a SysEx file-info request if the firmware supports it
  (check `disting_nt_sysex.dart` for an existing query); the fake test FS
  returns the byte length of the in-memory map entry.
- **If no SysEx file-info exists**, fall back to `readFile` and discard the
  bytes (slow but correct). This is what the production export flow does
  anyway, so the estimate is the same cost as the export — defeats the point.
  **Recommend adding a real size query.**

Display in the dialog dependencies card:

```
Estimated package size: 28.4 MB (147 files)
  Wavetables (3 folders): 1.2 MB
  Sample folders (4): 22.1 MB
  Multisample folders (1): 4.8 MB
  ...
```

The estimate runs when the dialog opens (after dependency analysis) and is
**advisory only** — actual zip is built fresh on Export click. If the
estimate fails, show "Size unknown" rather than blocking export.

### 6. Per-file progress during export

**Files:**
- `lib/services/file_collector.dart` (already has progress callback)
- `lib/services/package_creator.dart`
- `lib/ui/widgets/preset_package_dialog.dart`

`FileCollector.collectDependencies` already emits log lines but no streaming
progress. Add an optional `void Function(FileProgressUpdate)` callback:

```dart
class FileProgressUpdate {
  final String currentPath;
  final int filesCompleted;
  final int? filesTotal;       // null until estimator runs
  final int bytesCompleted;
  final int? bytesTotal;
}
```

Plumb it through:
- `PackageCreator.createPackage` accepts `onProgress`.
- `FileCollector` calls it after each `_collectFile` success and inside
  `_collectFolder`'s inner loop.
- The dialog binds a `ValueNotifier<FileProgressUpdate?>` to a
  `LinearProgressIndicator` plus a "Reading: samples/Kit/MD16_HH.wav
  (47/147, 12.5/28.4 MB)" label.

If the size estimate from §5 is unavailable, progress shows as "47 files,
12.5 MB" without a percent.

### 7. Tests

**`test/services/preset_analyzer_test.dart`** — required updates:

- New: `samp` slot with a trigger `"sample": "<MULTISAMPLE>"` →
  `sampleFolders` contains the folder, `sampleFiles` does not.
- New: `samp` slot with a trigger `"sample": "kick.wav"` → `sampleFiles`
  contains `<folder>/kick.wav`, `sampleFolders` does not contain the folder.
- New: trigger with no `folder` field → silently skipped (no crash, nothing
  added).
- Verify any existing `samp` assertions still pass (explicit-filename path
  unchanged).

**`test/services/preset_export_integration_test.dart`** — extend the
`SyncLatchDemo` test:

- Add a second fixture (or modify the existing one) where one trigger uses
  `<MULTISAMPLE>` against `samples/MD16_Kit/`, with several sibling files
  (`MD16_BD.wav`, `MD16_SD.wav`, `MD16_HH.wav`).
- Assert all sibling files end up in the zip.
- Assert no warning mentions `<MULTISAMPLE>`.
- Assert duplicate-folder dedup: a folder referenced via both a
  `<MULTISAMPLE>` trigger and an explicit-filename trigger appears once,
  with no duplicate file entries in the zip.

**`test/services/file_collector_test.dart`** — add:
1. If `_collectFolder` and `_collectFile` both target the same path, the
   result list contains it once.
2. Wavetable regression test: fake SD card has `wavetables/MyTable/` with 64
   audio files (`01.wav` through `64.wav`); assert all 64 land in the zip
   under `wavetables/MyTable/`. This locks in the folder-of-WAV-slices
   behavior the firmware uses for wavetables and prevents future
   single-file-only regressions.

**Estimator tests:** new file `test/services/package_estimator_test.dart` (or
inline in analyzer test) — given a fake FS with known byte counts, assert the
estimate sums correctly across folders + files.

**Progress callback test:** in `preset_export_integration_test.dart`, capture
the `onProgress` calls into a list and assert it grows monotonically and ends
with `filesCompleted == filesTotal`.

Add MIDI/scl/kbm fixture: a small preset with one `midp` slot and one `quan`
slot, fake SD card containing `MIDI/Demo/song1.mid`, `MIDI/Demo/song2.mid`,
`scl/12tone.scl`, `kbm/standard.kbm`. Assert all four files appear in the
zip under their canonical paths. Assert that disabling
`PackageConfig.includeMidiTree` excludes the MIDI files.

### 8. Touch list

| File | Change |
|---|---|
| `lib/models/preset_dependencies.dart` | add `bundleMidiTree` / `bundleSclTree` / `bundleKbmTree` flags |
| `lib/models/package_config.dart` | add `includeMidiTree` / `includeScales` flags |
| `lib/services/preset_analyzer.dart` | `<MULTISAMPLE>` trigger handling; midp/quan GUID checks; manifest folder check |
| `lib/services/file_collector.dart` | de-dup guard; `_collectTree` for MIDI/scl/kbm; progress callback |
| `lib/services/package_creator.dart` | thread `onProgress` through |
| `lib/services/package_estimator.dart` (new) | size estimator (covers MIDI/scl/kbm trees too) |
| `lib/interfaces/preset_file_system.dart` | add `getFileSize` |
| `lib/interfaces/impl/preset_file_system_impl.dart` | implement `getFileSize` (SysEx file-info if available) |
| `lib/ui/widgets/preset_package_dialog.dart` | size estimate label, progress UI, MIDI/Scales toggles |
| `lib/domain/disting_nt_sysex.dart` (read-only check) | confirm whether file-info SysEx exists; if not, decide fallback |
| `test/services/preset_analyzer_test.dart` | new cases for `<MULTISAMPLE>`, `midp`, `quan` |
| `test/services/preset_export_integration_test.dart` | sibling-file + dedup + progress + MIDI/scale assertions |
| `test/services/file_collector_test.dart` | de-dup + wavetable-folder test |
| `test/services/package_estimator_test.dart` (new) | size estimate test |

### 9. Verification

1. `flutter run -d macos --print-dtd` (or hot-reload if already running).
2. Open Preset Browser → select a preset using `samp` with at least one
   `<MULTISAMPLE>` trigger, plus a `pyms` slot.
3. Export dialog opens. Confirm: dependency card shows estimated package
   size and per-folder breakdown; toggles for MIDI/Scales appear.
4. Click Export. Confirm: progress bar advances; current-file label updates;
   no UI freeze.
5. Save the zip. Unzip and confirm:
   - Every `.wav`/`.aif` file in each `<MULTISAMPLE>` trigger folder is
     present (not just the trigger-named ones — that's the regression guard).
   - Explicit-filename triggers still produce single-file entries.
   - Each unique folder appears once.
   - `multisamples/<folder>/` still contains its full audio set.
   - Wavetable folders are bundled completely.
6. Repeat with `Factory/MIDI Song Player.json`. Confirm `MIDI/` tree is
   bundled.
7. Repeat with `Factory/Aleatoric Piano.json` (uses `quan`). Confirm
   `scl/` and `kbm/` trees are bundled.
8. `flutter analyze` — must be clean.
9. `flutter test` — existing + new tests must pass.

## Deliberately out of scope — would require firmware-internal work

- **Resolving indexed `midp` Folder/File and Quantizer Scale parameters to
  specific files** (instead of bundling whole `MIDI/`, `scl/`, `kbm/`
  trees). Two approaches were considered and both rejected for this pass:
  1. Query live NT parameter value-strings — only works when the preset
     being exported is the *currently loaded* preset, which it often
     isn't (user typically exports a stored `.json` from the SD card
     without loading it).
  2. Replicate firmware directory-sort + indexing logic in Dart — fragile
     and tied to undocumented firmware behavior.

  Whole-tree bundling is always correct and the trees are small (KB–low
  MB scale). The size savings from index resolution don't justify the
  complexity surface.

- **Streaming compression for very large sample folders.** A perf
  optimization with no current pain point. The 50MB-per-file cap is
  already in place.

- **Granulator `slot['sample']` with folder context.** Per user
  confirmation, granulator plays one specific file — current single-file
  copy is correct.
