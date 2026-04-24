# Complete Preset Export/Import Round-Trip

## Context

The current preset packaging UI (`Export` button in the file browser → `PresetPackageDialog` → `PackageCreator`) is *intended* to capture every dependency a preset needs — sample folders, samples, wavetables, FM banks, Lua scripts, 3-pot programs, community plugins — so a packaged ZIP can be installed onto a blank SD card and "just work". A repair pass landed in `509595e fix: repair preset export artifact collection` (2026-03-28) that fixed folder listing and config-flag honoring, but several blocking bugs remain that cause the resulting ZIP to be effectively *just the preset JSON* for very common preset types.

Concrete defects found by reading real `.json` presets from `~/github/distingNT/presets`:

1. **Lua Scripter is never collected.** Real GUID for the Lua algorithm is `'lua '` (4 chars, trailing space). `PresetAnalyzer._analyzeSlot` checks `guid == 'lua'` — never matches. The slot field is also `program`, not `script`. (See `SyncLatchDemo.json` — `"guid": "lua "`, `"program": "sync_latch.lua"`.) `lib/services/preset_analyzer.dart:51-53`.
2. **Granulator samples are never collected.** Analyzer populates `dependencies.granulatorSamples` from the `sample` field, but `FileCollector.collectDependencies` never iterates `granulatorSamples`. `lib/services/file_collector.dart:15-173`. (See `Granulated Piano.json` and any preset using `gran`.)
3. **Sample-player trigger samples are never collected.** Analyzer populates `dependencies.sampleFiles` from `triggers[].folder + triggers[].sample`, but `FileCollector` never reads `sampleFiles`. (See `SyncLatchDemo.json` `samp` slot — 8 trigger entries, none would be packaged.)
4. **Hardcoded multisample-vs-sample mapping.** Only `'pyms'` is treated as multisample. Other multisample-using algorithms get classified as samples. Mapping is brittle.
5. **Community plugins default OFF.** `PackageConfig.includeCommunityPlugins = false`. For round-trip restore on a blank SD card, the plugin binaries must be in the package or the preset cannot load.
6. **Warnings are silently dropped.** `file_collector.dart:170` is literally `if (warnings.isNotEmpty) {}` — a missing wavetable, a permission error, an oversized file, all become invisible. The user has no way to know files were skipped.
7. **`totalCount` excludes `sampleFiles`.** Cosmetic — UI's "Dependencies found: N" undercounts. `lib/models/preset_dependencies.dart:19-29`.
8. **3pot GUID may also be space-padded.** Need to verify `'spin'` (4 chars, no padding needed) vs `'3pot'`/etc. against a real preset. Apply same defensive `guid.trim()` treatment.
9. **Algorithm metadata has `type: "file"` / `"folder"` parameter info that is never consulted.** As new algorithms are added, hardcoded slot-field knowledge in `PresetAnalyzer` will keep falling behind.

Goal: a user can click Export on any preset, get a `.zip`, drop it onto a blank SD card via the import dialog, and the preset loads identically — every sample, wavetable, Lua script, 3-pot program, FM bank, and community plugin restored to its canonical SD path.

---

## Approach

Five changes, smallest first. Each is independently verifiable.

### 1. Fix `PresetAnalyzer` GUID + field-name matching
**File:** `lib/services/preset_analyzer.dart`

- Trim GUIDs before comparison: `final guid = (slot['guid'] as String?)?.trim();`
- Lua: match trimmed `'lua'`, look at slot `program` field (NOT `script`). The current `script` branch is dead code — remove it.
- 3pot: match trimmed `'spin'`, keep `program` field.
- Granulator: handle multiple GUIDs that use a top-level `sample` field (currently catches `gran`; verify `gnit`, `clds`, etc. — keep current "any non-empty `sample` field" behavior since it's already permissive).
- Multisample classification: extend beyond just `'pyms'` — accept any algorithm whose metadata declares the relevant parameter as a multisample folder. As a near-term fallback, also recognize known multisample GUIDs (`'pyms'`, `'mult'`, etc.) — see step 3 for the metadata-driven version.

### 2. Fix `FileCollector` to actually read all populated dependency sets
**File:** `lib/services/file_collector.dart`

- Add a `granulatorSamples` collection block analogous to wavetables: `samples/<name>` (or wherever granulator samples live — verify path; the parameter editor's `BaseSampleParameterEditor` baseDirectory is `/samples`).
- Add a `sampleFiles` collection block: each entry is already `<folder>/<file>`, prepend `samples/` to get the full SD-relative path.
- Add a `midiFiles` collection block (`midi/<name>`) — analyzer doesn't populate it today, but the field exists; either populate via `midp` algorithm in step 1 or leave the slot empty until step 3.
- Surface the `warnings` list as a return value alongside `files` so the dialog can show them. Replace `Future<List<CollectedFile>>` return with a small `CollectionResult { files, warnings }` record/class. Remove the dead `if (warnings.isNotEmpty) {}` block.
- Fix the `_collectFolder` size-check bug: it currently *warns* about oversized files but still adds them to `files`. Skip oversized files (continue) rather than including them.

### 3. Algorithm-metadata-driven file-parameter discovery
**Files:** `lib/services/preset_analyzer.dart`, `lib/services/algorithm_metadata_service.dart`, `lib/models/algorithm_parameter.dart`

The Disting NT slot JSON stores file references as named string fields whose names match parameter names declared in the algorithm metadata (`docs/algorithms/*.json`). Each metadata parameter can have `type: "file"` or `type: "folder"` plus a `unit`/`baseDirectory` indicating where on the SD card it lives.

- Add `AlgorithmMetadataService.getFileParametersForGuid(String guid)` that returns the subset of `AlgorithmParameter` whose `type` is `'file'` or `'folder'`, with the SD baseDirectory (`/samples`, `/wavetables`, `/programs/lua`, `/FMSYX`, `/multisamples`, `/programs/three_pot`, `/midi`).
- In `PresetAnalyzer._analyzeSlot`, after the hardcoded branches (which we keep as a safety net for legacy presets), also iterate the algorithm's file parameters and pull any matching string fields out of the slot JSON, classifying them by `baseDirectory` into the right `PresetDependencies` set.
- This means new algorithms with file params will Just Work as long as their metadata has `type: "file"`/`"folder"`.

Keep the hardcoded branches — they cost nothing and serve as a fallback when metadata isn't loaded (e.g., during analysis before sync).

### 4. Surface warnings + flip community-plugin default
**Files:** `lib/models/package_config.dart`, `lib/ui/widgets/preset_package_dialog.dart`, `lib/services/package_creator.dart`

- Default `PackageConfig.includeCommunityPlugins = true` (was `false`). Round-trip restore is the headline use case; opt-out is fine.
- Update `SettingsService.includeCommunityPlugins` default-read to also default to `true` if unset.
- `PackageCreator.createPackage` should return a `PackageResult { zipBytes, warnings }` (small wrapper, or expose warnings via the existing `onProgress` callback). Use the `CollectionResult.warnings` from step 2.
- After successful export, show a SnackBar or in-dialog alert listing skipped/missing files so the user knows the package is incomplete and can investigate. Do not block — incomplete packages still install partially, but the user must be informed.

### 5. Improve the analyzer-dialog preview
**File:** `lib/ui/widgets/preset_package_dialog.dart`

- Show `sampleFiles.length` in the dependency list (currently invisible).
- Show `granulatorSamples.length` (currently invisible).
- After collection completes (during or just before zip write), show the collected file count as the line item, not just the analyzer's symbolic count, so the user can spot a count of zero collected vs N analyzed.

### 6. Tests
**Files:** `test/services/preset_analyzer_test.dart`, `test/services/file_collector_test.dart` (new fixtures), `test/services/preset_export_integration_test.dart` (new)

- Add `analyzeDependencies` tests — currently zero coverage. Use real preset fixtures copied into `test/fixtures/presets/`:
  - `Granulated Piano.json` → expect `pyms` multisample folder + `gran` sample collected.
  - `SyncLatchDemo.json` → expect `lua ` script `sync_latch.lua`, `samp` triggers (8 sample paths), `pyms` multisample folder.
  - `Automatronic.json` → expect `pyfm` FM banks (4 ROM banks), `waos` wavetable `warm-squ`.
  - A community-plugin preset (one with an uppercase GUID) → expect `communityPlugins` populated.
- `FileCollector` tests for `granulatorSamples` and `sampleFiles` paths (use the existing in-memory `PresetFileSystem` fake from `test/services/file_collector_test.dart`).
- Integration test: feed a fixture preset + fake filesystem with all referenced files, run `PackageCreator.createPackage`, unzip the result, assert all expected paths are present in `root/`.

---

## Critical Files

| File | Change |
|---|---|
| `lib/services/preset_analyzer.dart` | Trim GUIDs; fix Lua field name; add metadata-driven discovery |
| `lib/services/file_collector.dart` | Collect `granulatorSamples`, `sampleFiles`, `midiFiles`; surface warnings; fix size-check bug |
| `lib/models/preset_dependencies.dart` | `totalCount` to include `sampleFiles` |
| `lib/models/package_config.dart` | Default `includeCommunityPlugins = true` |
| `lib/ui/widgets/preset_package_dialog.dart` | Show warnings; show new dependency types in preview |
| `lib/services/package_creator.dart` | Plumb warnings through to caller |
| `lib/services/algorithm_metadata_service.dart` | Add `getFileParametersForGuid` |
| `test/services/preset_analyzer_test.dart` | New fixture-based `analyzeDependencies` tests |
| `test/services/file_collector_test.dart` | Cover the new collection paths |
| `test/services/preset_export_integration_test.dart` (new) | End-to-end ZIP shape verification |
| `test/fixtures/presets/*.json` (new) | Copies of `Granulated Piano.json`, `SyncLatchDemo.json`, `Automatronic.json` |

## Reuse / do not duplicate

- `PresetFileSystemImpl.listFiles` (`lib/interfaces/impl/preset_file_system_impl.dart:11`) — recently fixed; trust it for folder enumeration.
- `disting_cubit_plugin_delegate.installFileToPath` (`lib/cubit/disting_cubit_plugin_delegate.dart:483`) — already handles 512-byte chunked upload + parent-dir creation. The import side does not need changes.
- `FirmwareVersion(...).hasSdCardSupport` — gate any SD ops with this; already used at install time.
- The 50 MB-per-file limit (`file_collector.dart:21`) — keep, but make sure oversize files are *skipped* (currently included with a warning that's silently dropped).

## Verification

End-to-end manual test on real hardware:

1. `flutter run -d macos --print-dtd`. Connect to a Disting NT with at least one preset using each: granulator, Lua scripter, sample player triggers, multisample folder, wavetable, community plugin (e.g. one of the `pyms`/`samp`/`gran`/`waos`/`lua `/community combos in `~/github/distingNT/presets`).
2. Export the preset via the file browser → Export → Create Package. Save as `roundtrip.zip`.
3. `unzip -l roundtrip.zip` and inspect: assert `root/presets/<name>.json` plus every referenced sample, wavetable, Lua script, FM bank, multisample folder content, and plugin binary is present under `root/`.
4. Note any warnings displayed in the dialog; cross-check against the unzip listing.
5. Wipe a spare SD card down to an empty `/presets/` directory, mount it on the NT.
6. Use the import flow (drag the ZIP onto the file browser) to install. Watch for `installPackageFiles` errors on the bus.
7. Load the preset from the NT's UI. Verify it sounds/behaves identical to the source.

Automated tests:

- `flutter analyze` — must remain at zero warnings.
- `flutter test test/services/preset_analyzer_test.dart` — new fixture tests.
- `flutter test test/services/file_collector_test.dart` — extended cases.
- `flutter test test/services/preset_export_integration_test.dart` — new end-to-end test.

Out of scope (intentionally):

- New MCP tools for export/import. The user did not request this; can be a follow-up.
- A standalone "JSON-only" export path. The right-click "Download" on a `.json` file in the file browser already provides that and is fine as-is.
- Changes to the install/upload pipeline. It already works.
