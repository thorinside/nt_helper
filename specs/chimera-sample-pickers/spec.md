# Chimera sample picker hand-off spec

Baseline refs:

- `nt_helper`: `8cd000d9af410a852f2c0428e9a344a0ac0eb07d`
- `thorinside/disting-chimera`: `50ff295051aa07afb0323fbf3633a7f36d7113f0`
- `expertsleepersltd/distingNT_API`: `cd12d876dbe060859828053efab1cbc98c9df251`

Hardening policy: realistic-only

Program-level verification:

```bash
cd /Users/nealsanche/nosuch/nt_helper
flutter analyze
flutter test
```

## Outcome

Add native `nt_helper` folder and audio-file pickers for Chimera's three folder
parameters and seven sample parameters without changing Chimera's C++ metadata.

Chimera already follows the official Disting NT sample-player parameter contract:

| Parameter kind | Disting NT unit | Current Chimera use |
|---|---|---|
| Folder | `kNT_unitHasStrings` | `Lion folder`, `Goat folder`, `Beef folder` |
| Sample/file | `kNT_unitConfirm` | `Lion sample`, `Goat sample`, `Kick sample`, `Snare sample`, `Perc sample`, `Hat sample`, `Crash sample` |

The current official
`expertsleepersltd/distingNT_API/examples/samplePlayer.cpp` uses the same
`kNT_unitHasStrings`/`kNT_unitConfirm` pair. Do not change those units in the
plugin.

The app-side defect has three parts:

1. `ParameterEditorRegistry` only recognizes unqualified generic names
   `Folder`/`Sample`, so all Chimera names fall through to the numeric editor.
2. `FileParameterEditor` decides whether a file depends on a folder by looking
   for case-sensitive `Sample` or `File` substrings. Chimera uses lowercase
   `sample`.
3. The five Beef sample parameters share `Beef folder` and reserve value `0`
   for `None`; real files use values `1..N`. The existing sentinel support is
   hard-coded to Poly Multisample's `Multisample` label.

## Inventory

Inventory was generated from the `nt_helper` repo root with:

```bash
python3 /Users/nealsanche/.agents/skills/decision-free-specs/languages/dart/inventory.py \
  lib/ui/parameter_editor_registry.dart \
  lib/ui/widgets/file_parameter_editor.dart \
  test/ui/parameter_editor_registry_test.dart \
  test/ui/widgets/file_parameter_editor_poly_multisample_test.dart \
  > /tmp/chimera_nt_helper_inventory.md
```

Hand check completed for both production files. The inventory declarations
match the source:

- `lib/ui/parameter_editor_registry.dart`: `FileSelectionMode`,
  `ParameterUnitScheme`, `ParameterUnits`, `ParameterEditorRule`,
  `ParameterEditorRegistry`.
- `lib/ui/widgets/file_parameter_editor.dart`: `FileParameterEditor`,
  `_DevelopmentState`, `_FileParameterEditorState`, `_FileSelectionDialog`,
  `_FileSelectionDialogState`.

Relevant inventory:

| File | Size | Relevant surface | Importers |
|---|---:|---|---|
| `lib/ui/parameter_editor_registry.dart` | 506 lines | `ParameterEditorRule`, `_fileUnits`, `_folderUnits`, `_rules`, `findEditorFor` | Cubit diagnostics and parameter UI widgets/tests |
| `lib/ui/widgets/file_parameter_editor.dart` | 1540 lines | sentinel mapping, folder association, directory loading, selection dialog | registry and focused widget tests |
| `test/ui/parameter_editor_registry_test.dart` | 508 lines | registry rule tests and slot factory | none |
| `test/ui/widgets/file_parameter_editor_poly_multisample_test.dart` | 304 lines | existing zero-value sentinel and recursive folder regressions | none |
| `test/ui/widgets/file_parameter_editor_chimera_test.dart` | new | focused Chimera folder/file/value regressions | none |

No symbol moves are required. No compatibility re-export is required.

## Architecture

Keep `ParameterEditorRegistry` as the declarative source of file-picker
semantics. Extend `ParameterEditorRule` with:

```dart
final String? correspondingFolderParameterName;
final String? zeroValueSentinelLabel;
```

`correspondingFolderParameterName` is an exact parameter name in the same
`Slot`. It makes folder dependency explicit and removes any need for
Chimera-specific branching in `FileParameterEditor`.

`zeroValueSentinelLabel` means:

- parameter value `0` is not a file;
- the picker inserts one synthetic first entry with this exact label;
- the first real file maps to parameter value `1`;
- negative values display the sentinel defensively;
- `null` preserves normal `min`-relative, zero-based mapping.

Replace the existing `hasMultisampleSampleSentinel` boolean with
`zeroValueSentinelLabel`. Existing Poly Multisample rules use
`zeroValueSentinelLabel: 'Multisample'`; Chimera's Beef rule uses
`zeroValueSentinelLabel: 'None'`.

### Target file tree

| Path | Action |
|---|---|
| `lib/ui/parameter_editor_registry.dart` | Generalize sentinel metadata, add folder association metadata, add GUID-scoped Chimera rules |
| `lib/ui/widgets/file_parameter_editor.dart` | Consume the generic metadata for sentinel mapping and folder-dependent loading |
| `test/ui/parameter_editor_registry_test.dart` | Update sentinel assertions and add Chimera rule regressions |
| `test/ui/widgets/file_parameter_editor_poly_multisample_test.dart` | Do not edit; use as the existing Poly Multisample regression gate |
| `test/ui/widgets/file_parameter_editor_chimera_test.dart` | Add focused recursive folder, per-loop folder association, and Beef sentinel regressions |

### Symbol map

| Symbol | Location after implementation | Exported | Required change |
|---|---|---:|---|
| `ParameterEditorRule` | `lib/ui/parameter_editor_registry.dart` | yes | Replace `hasMultisampleSampleSentinel`; add `correspondingFolderParameterName` and `zeroValueSentinelLabel` |
| `ParameterEditorRegistry._rules` | same | no | Add four Chimera rules and migrate two Poly Multisample rules |
| `_FileParameterEditorState._findCorrespondingFolderParameter` | `lib/ui/widgets/file_parameter_editor.dart` | no | Resolve the rule's exact folder name before legacy trigger/fallback inference |
| `_FileParameterEditorState.didUpdateWidget` | same | no | Use the metadata-driven folder-dependency predicate |
| `_FileParameterEditorState._loadDirectoryContents` | same | no | Use the metadata-driven folder-dependency predicate |
| `_FileParameterEditorState._getDisplayValueForCurrentValue` | same | no | Render the configured zero-value label |
| `_FileParameterEditorState._entryIndexForParameterValue` | same | no | Preserve `0` as sentinel and `1..N` as files when configured |
| `_FileParameterEditorState._parameterValueForEntryIndex` | same | no | Inverse of the entry-index mapping |
| `_FileParameterEditorState._zeroValueSentinelEntry` | same | no | Renamed/generalized from `_multisampleSentinelEntry` |
| `_FileSelectionDialogState._selectedIndex` | same | no | Use `zeroValueSentinelLabel != null` |

## Decisions

| Decision | Rationale |
|---|---|
| Fix `nt_helper`, not Chimera C++ | Chimera matches the current official NT sample-player unit contract |
| Scope rules to GUID `Chim` | Avoid misclassifying unrelated parameters such as `Sample rate` |
| Keep units unchanged | Folder remains unit 16/`HasStrings`; files remain unit 17/`Confirm` on modern firmware |
| Use `_folderUnits` for Chimera folders and `_fileUnits` for Chimera samples | Preserve the registry's legacy/modern compatibility model while accepting the official confirm unit |
| Use `ntSampleFolderEnumeration: true` | Chimera values are indices used with `NT_getSampleFolderInfo`, so nested `/samples` ordering must match the NT |
| Store exact corresponding folder names in rules | Lion, Goat, and shared Beef associations are known metadata and must not be guessed by UI code |
| Generalize the existing sentinel instead of adding a Beef special case | Poly Multisample and Beef share the same index-shift behavior with different labels |
| Preserve existing numeric fallback association | Existing sample-player and MIDI-player behavior remains compatible |
| No strategy registry or new service | There is one file-picker behavior with declarative rule variance, not multiple behavioral strategies |
| No source-file extraction | The change is small and remains within the existing registry/editor module boundaries |

## Chimera rule contract

Insert the Chimera rules after the Poly Multisample rules and before the Sample
Player rules so the app checks the most specific GUID-scoped rules before
generic file rules.

All rules use:

```dart
algorithmGuid: 'Chim',
baseDirectory: '/samples',
ntSampleFolderEnumeration: true,
```

Add exactly these rules:

| Match | Units | Mode | Folder association | Sentinel | Description |
|---|---|---|---|---|---|
| `r'^(Lion\|Goat\|Beef) folder$'` | `_folderUnits` | `folderOnly` | none | none | `Chimera sample folder selection` |
| `r'^Lion sample$'` | `_fileUnits` | `fileOnly` | `Lion folder` | none | `Chimera Lion sample selection` |
| `r'^Goat sample$'` | `_fileUnits` | `fileOnly` | `Goat folder` | none | `Chimera Goat sample selection` |
| `r'^(Kick\|Snare\|Perc\|Hat\|Crash) sample$'` | `_fileUnits` | `fileOnly` | `Beef folder` | `None` | `Chimera Beef sample selection` |

The table escapes `|` for Markdown only. The Dart raw regex strings must use
unescaped alternation:

```dart
r'^(Lion|Goat|Beef) folder$'
r'^(Kick|Snare|Perc|Hat|Crash) sample$'
```

Every `fileOnly` rule has:

```dart
allowedExtensions: ['.wav', '.aif', '.aiff'],
```

## `ParameterEditorRule` contract

After STEP 2 the relevant constructor shape is:

```dart
const ParameterEditorRule({
  this.algorithmGuid,
  this.parameterNamePattern,
  this.units,
  this.baseDirectory,
  required this.mode,
  this.excludeDirs = const [],
  this.allowedExtensions,
  required this.description,
  this.recursive = false,
  this.defaultFolder,
  this.ntSampleFolderEnumeration = false,
  this.correspondingFolderParameterName,
  this.zeroValueSentinelLabel,
});
```

Do not retain `hasMultisampleSampleSentinel`.

## File editor behavior contract

Add these getters to `_FileParameterEditorState`:

```dart
String? get _zeroValueSentinelLabel =>
    widget.rule.zeroValueSentinelLabel;

bool get _hasZeroValueSentinel => _zeroValueSentinelLabel != null;

bool get _loadsFromSelectedFolder =>
    widget.rule.mode == FileSelectionMode.fileOnly &&
    (widget.rule.correspondingFolderParameterName != null ||
        widget.parameterInfo.name.contains('Sample') ||
        widget.parameterInfo.name.contains('File'));
```

Use `_loadsFromSelectedFolder` in both places that currently repeat the
case-sensitive `Sample`/`File` condition:

- `didUpdateWidget`, before `_checkForFolderChanges`;
- `_loadDirectoryContents`, before `_getSelectedFolderPath`.

Update `_findCorrespondingFolderParameter` in this exact order:

1. Read `widget.rule.correspondingFolderParameterName`.
2. When non-null, use `indexWhere` to find an exact `ParameterInfo.name`
   match in `widget.slot.parameters`.
3. Return the explicit index when found.
4. If no explicit match exists, continue through the existing numbered
   `N:Folder` inference.
5. If that fails, retain the existing first-parameter-containing-`Folder`
   fallback.

Do not throw when a rule names a missing folder parameter. The existing fallback
and `/samples` base-directory behavior remain the recovery path.

### Sentinel behavior

Replace every `_hasMultisampleSampleSentinel` reference with
`_hasZeroValueSentinel`.

Rename `_multisampleSentinelEntry` to `_zeroValueSentinelEntry` and use:

```dart
DirectoryEntry _zeroValueSentinelEntry() {
  return DirectoryEntry(
    name: _zeroValueSentinelLabel!,
    attributes: 0,
    date: 0,
    time: 0,
    size: 0,
  );
}
```

The following behavior must remain internally consistent:

| Operation | No sentinel | Configured sentinel |
|---|---|---|
| Display value `<= 0` | existing min-relative display | exact configured label |
| Insert synthetic entry | no | index `0` |
| Parameter value to entry index | `value - min` | `value <= 0 ? 0 : value` |
| Entry index to parameter value | `index + min` | `index <= 0 ? 0 : index` |
| Previous button enabled | existing `value > min` | `value > 0` |
| Increment from `0` | existing `+1` | `1` |
| Decrement from `1` | existing `-1` | `0` |
| Dialog selected index | existing `value - min` | `value <= 0 ? 0 : value` |

Poly Multisample continues to display `Multisample` at value `0`; Beef displays
`None` at value `0`.

## Test fixture contract

Create `test/ui/widgets/file_parameter_editor_chimera_test.dart` using
`mocktail` and the same `DistingCubit`/`IDistingMidiManager` mocking pattern as
`file_parameter_editor_poly_multisample_test.dart`.

The fake `/samples` tree is:

```text
/samples
├── Breaks
│   ├── Goat
│   │   ├── goat-a.wav
│   │   └── goat-b.wav
│   └── Lion
│       ├── lion-a.wav
│       └── lion-b.wav
└── Drums
    └── Beef
        ├── kick-a.wav
        └── kick-b.wav
```

Return directory entries with attribute `0x10` and filenames with attribute
`0x20`. Sorting plus NT recursive enumeration produces:

| Folder value | Folder |
|---:|---|
| 0 | `Breaks` |
| 1 | `Breaks/Goat` |
| 2 | `Breaks/Lion` |
| 3 | `Drums` |
| 4 | `Drums/Beef` |

The focused Chimera `Slot` contains these parameters and aligned values:

| Number | Name | Unit | Min | Max | Value |
|---:|---|---:|---:|---:|---:|
| 0 | `Lion folder` | `modernHasStrings` | 0 | 100 | 2 |
| 1 | `Lion sample` | `modernConfirm` | 0 | 1 | 0 |
| 2 | `Goat folder` | `modernHasStrings` | 0 | 100 | 1 |
| 3 | `Goat sample` | `modernConfirm` | 0 | 1 | 0 |
| 4 | `Beef folder` | `modernHasStrings` | 0 | 100 | 4 |
| 5 | `Kick sample` | `modernConfirm` | 0 | 2 | 0 |

Use algorithm GUID `Chim` and name `Chimera`. Create aligned lists for enums,
mappings, and value strings with matching parameter numbers; do not use the
`filler()` factories because those carry parameter number `-1`.

Add exactly these widget tests:

1. `Chimera folder picker uses recursive NT sample folder values`
   - Pump parameter `0`.
   - Assert `Breaks/Lion` is displayed.
   - Open `Browse`, select `Drums/Beef`, and assert the single written value is
     `4`.
2. `Chimera Goat sample loads its corresponding folder and writes zero-based file values`
   - Pump parameter `3`.
   - Assert `goat-a` is displayed and `lion-a` is absent.
   - Open `Browse`, select `goat-b`, and assert the single written value is `1`.
3. `Chimera Beef sample maps None to zero and the first file to one`
   - Pump parameter `5`.
   - Assert `None` is displayed and `kick-a` is absent before browsing.
   - Open `Browse`, assert `kick-a` and `kick-b` are available.
   - Select `kick-a` and assert the single written value is `1`.

In `test/ui/parameter_editor_registry_test.dart`, add exactly these tests:

1. `Chimera folder parameters use recursive NT sample enumeration`
2. `Chimera loop sample parameters use confirm units and their own folders`
3. `Chimera Beef samples share Beef folder and use a None sentinel`
4. `qualified sample names remain scoped to Chimera`

The first three tests assert `FileParameterEditor`, rule mode, base directory,
recursive NT enumeration, folder association, and sentinel label. The fourth
uses GUID `test`, name `Lion sample`, unit `modernConfirm`, and expects no
special editor.

## Acceptance criteria

- The fork exists at `thorinside/disting-chimera`; no plugin source change is
  required for this fix.
- `Lion folder`, `Goat folder`, and `Beef folder` render folder pickers backed by
  NT-recursive `/samples` ordering.
- `Lion sample` reads files from `Lion folder` and uses zero-based file indices.
- `Goat sample` reads files from `Goat folder` and uses zero-based file indices.
- All five Beef role samples read files from the shared `Beef folder`.
- Beef value `0` displays and selects `None`; first/second real files map to
  values `1`/`2`.
- Poly Multisample value `0` still displays and selects `Multisample`.
- Unrelated qualified parameters do not acquire a file picker.
- `flutter analyze` and the full `flutter test` suite pass.

## Explicit non-goals

- Do not edit `disting-chimera/chimera.cpp`.
- Do not change `ParameterUnits` numeric constants or firmware-version
  detection.
- Do not broaden the generic `Folder`/`Sample` regexes.
- Do not alter SD-card directory APIs, SysEx packet formats, upload behavior,
  plugin loading, parameter refresh, or value-string fetching.
- Do not add a Chimera controller/editor screen.
- Do not change parameter ordering, values, presets, serialization, or the
  plugin GUID.
- Do not add debug logging or success snackbars.
- Do not bump or release `nt_helper` as part of this two-step implementation
  plan.
