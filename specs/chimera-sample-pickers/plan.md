# Chimera sample picker implementation plan

Total steps: 2

Each step is independently committable. Execute exactly one numbered step per
fresh-context session. Read `specs/conventions.md` and
`specs/chimera-sample-pickers/spec.md` completely before editing.

Program-level verification after STEP 2:

```bash
cd /Users/nealsanche/nosuch/nt_helper
flutter analyze
flutter test
```

## STEP 1 of 2 — Generalize zero-value sample sentinel metadata

### Files to edit

- `lib/ui/parameter_editor_registry.dart`
- `lib/ui/widgets/file_parameter_editor.dart`
- `test/ui/parameter_editor_registry_test.dart`

### Required implementation

1. In `ParameterEditorRule`, remove:

   ```dart
   final bool hasMultisampleSampleSentinel;
   ```

2. Add this field in the same position:

   ```dart
   /// Optional label for a value-0 sentinel before real file entries.
   final String? zeroValueSentinelLabel;
   ```

3. In the constructor, remove
   `this.hasMultisampleSampleSentinel = false` and add
   `this.zeroValueSentinelLabel`.
4. In both `pymu` and `pyms` `Sample` rules, replace:

   ```dart
   hasMultisampleSampleSentinel: true,
   ```

   with:

   ```dart
   zeroValueSentinelLabel: 'Multisample',
   ```

5. In `_FileParameterEditorState`, replace the
   `_hasMultisampleSampleSentinel` getter with:

   ```dart
   String? get _zeroValueSentinelLabel =>
       widget.rule.zeroValueSentinelLabel;

   bool get _hasZeroValueSentinel => _zeroValueSentinelLabel != null;
   ```

6. Replace every remaining `_hasMultisampleSampleSentinel` reference with
   `_hasZeroValueSentinel`.
7. In `_getDisplayValueForCurrentValue`, return
   `_zeroValueSentinelLabel` instead of the literal `Multisample` when the
   sentinel is active and the current value is `<= 0`.
8. Rename `_multisampleSentinelEntry` to `_zeroValueSentinelEntry` and replace
   the literal entry name with `_zeroValueSentinelLabel!`.
9. Update the call that inserts the synthetic entry to call
   `_zeroValueSentinelEntry`.
10. In `_FileSelectionDialogState._selectedIndex`, replace the
    `hasMultisampleSampleSentinel` condition with
    `widget.rule.zeroValueSentinelLabel != null`.
11. Do not alter directory ordering, filename filtering, current-value
    clamping, editor layout, semantics, or dialog behavior.

### Required tests

In `test/ui/parameter_editor_registry_test.dart`:

1. In `pymu Folder and Sample use Poly Multisample rules`, replace the boolean
   assertion with:

   ```dart
   expect(
     fileEditor.rule.zeroValueSentinelLabel,
     parameterName == 'Sample' ? 'Multisample' : isNull,
   );
   ```

2. Make the same replacement in
   `pyms Folder and Sample use Poly Multisample legacy rules`.
3. In `generic Folder and Sample rules remain non-recursive`, replace the
   boolean false assertion with:

   ```dart
   expect(fileEditor.rule.zeroValueSentinelLabel, isNull);
   ```

Keep every existing test name and all other assertions unchanged.

Do not change the behavior or test names in
`file_parameter_editor_poly_multisample_test.dart`; formatting-only changes are
not allowed. Its existing tests are the regression gate for `Multisample`,
negative sample values, and first-file value `1`.

### Leftover checks

Run:

```bash
rg -n "hasMultisampleSampleSentinel|_hasMultisampleSampleSentinel|_multisampleSentinelEntry" \
  lib/ui/parameter_editor_registry.dart \
  lib/ui/widgets/file_parameter_editor.dart \
  test/ui/parameter_editor_registry_test.dart \
  test/ui/widgets/file_parameter_editor_poly_multisample_test.dart || true
rg -n "zeroValueSentinelLabel" \
  lib/ui/parameter_editor_registry.dart \
  lib/ui/widgets/file_parameter_editor.dart \
  test/ui/parameter_editor_registry_test.dart
rg -n "_zeroValueSentinelEntry" lib/ui/widgets/file_parameter_editor.dart
```

Expected:

- The first command prints zero lines.
- `zeroValueSentinelLabel` appears in the rule field, constructor, both Poly
  Multisample rules, file editor, dialog, and registry tests.
- `_zeroValueSentinelEntry` appears once as a declaration and once as a call.

### Verification commands

```bash
cd /Users/nealsanche/nosuch/nt_helper
dart format \
  lib/ui/parameter_editor_registry.dart \
  lib/ui/widgets/file_parameter_editor.dart \
  test/ui/parameter_editor_registry_test.dart
flutter analyze
flutter test \
  test/ui/parameter_editor_registry_test.dart \
  test/ui/widgets/file_parameter_editor_poly_multisample_test.dart
git add \
  lib/ui/parameter_editor_registry.dart \
  lib/ui/widgets/file_parameter_editor.dart \
  test/ui/parameter_editor_registry_test.dart
git status --short
git commit -m "refactor(files): generalize zero-value sample sentinels"
```

Only the three files named above may appear in `git status --short` before the
commit.

### Commit message

`refactor(files): generalize zero-value sample sentinels`

## STEP 2 of 2 — Register Chimera folder and sample pickers

### Prerequisites

- STEP 1 committed with message
  `refactor(files): generalize zero-value sample sentinels`.

### Files to edit

- `lib/ui/parameter_editor_registry.dart`
- `lib/ui/widgets/file_parameter_editor.dart`
- `test/ui/parameter_editor_registry_test.dart`
- Create `test/ui/widgets/file_parameter_editor_chimera_test.dart`

### Required implementation

1. In `ParameterEditorRule`, add:

   ```dart
   /// Exact folder parameter name used by this file parameter, when known.
   final String? correspondingFolderParameterName;
   ```

2. Add `this.correspondingFolderParameterName` to its constructor immediately
   before `this.zeroValueSentinelLabel`.
3. Insert the four Chimera rules from the spec after the `pyms` Sample rule and
   before the Sample Player rules. Copy every field, regex, description, unit
   list, folder association, sentinel, allowed extension, base directory, and
   `ntSampleFolderEnumeration` value exactly from the spec.
4. In `_FileParameterEditorState`, add:

   ```dart
   bool get _loadsFromSelectedFolder =>
       widget.rule.mode == FileSelectionMode.fileOnly &&
       (widget.rule.correspondingFolderParameterName != null ||
           widget.parameterInfo.name.contains('Sample') ||
           widget.parameterInfo.name.contains('File'));
   ```

5. In `didUpdateWidget`, replace the repeated `fileOnly` plus
   `Sample`/`File` condition with `if (_loadsFromSelectedFolder)`.
6. In `_loadDirectoryContents`, make the same replacement before calling
   `_getSelectedFolderPath`.
7. At the start of `_findCorrespondingFolderParameter`, after reading
   `currentParamName`, add:

   ```dart
   final explicitFolderName =
       widget.rule.correspondingFolderParameterName;
   if (explicitFolderName != null) {
     final explicitFolderIndex = widget.slot.parameters.indexWhere(
       (parameter) => parameter.name == explicitFolderName,
     );
     if (explicitFolderIndex != -1) {
       return explicitFolderIndex;
     }
   }
   ```

8. Leave the existing numbered-trigger lookup and generic fallback unchanged
   after the explicit lookup.
9. Do not add a check for GUID `Chim` to `FileParameterEditor`; all
   plugin-specific behavior belongs in registry metadata.
10. Do not alter `ParameterUnits`, generic folder/sample rules, directory
    sorting, SysEx calls, Cubit methods, or the C++ plugin.

### Required registry tests

Add a `group('ParameterEditorRegistry - Chimera', () { ... })` immediately
before the existing tuning-file group in
`test/ui/parameter_editor_registry_test.dart`.

Add the four tests named in the spec. Use the existing `createTestSlot` and
`findEditor` helpers.

For the folder test, iterate over `Lion folder`, `Goat folder`, and
`Beef folder` with unit `ParameterUnits.modernHasStrings`. Assert:

- editor is `FileParameterEditor`;
- mode is `folderOnly`;
- base directory is `/samples`;
- `ntSampleFolderEnumeration` is true;
- `correspondingFolderParameterName` is null;
- `zeroValueSentinelLabel` is null.

For the loop-sample test, use this map:

```dart
const expectedFolders = {
  'Lion sample': 'Lion folder',
  'Goat sample': 'Goat folder',
};
```

For each entry use unit `ParameterUnits.modernConfirm` and assert:

- editor is `FileParameterEditor`;
- mode is `fileOnly`;
- base directory is `/samples`;
- allowed extensions equal `['.wav', '.aif', '.aiff']`;
- `ntSampleFolderEnumeration` is true;
- `correspondingFolderParameterName` equals the map value;
- `zeroValueSentinelLabel` is null.

For the Beef test, iterate over `Kick sample`, `Snare sample`, `Perc sample`,
`Hat sample`, and `Crash sample`, using unit
`ParameterUnits.modernConfirm`. Assert the same file rule properties, plus:

- `correspondingFolderParameterName == 'Beef folder'`;
- `zeroValueSentinelLabel == 'None'`.

For the scoping test, create GUID `test`, parameter name `Lion sample`, unit
`ParameterUnits.modernConfirm`, and assert `findEditor(slot)` is null.

### Required widget tests

Create `test/ui/widgets/file_parameter_editor_chimera_test.dart` exactly from
the fixture and three-test contract in the spec.

Use these imports:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nt_helper/cubit/disting_cubit.dart';
import 'package:nt_helper/domain/disting_nt_sysex.dart';
import 'package:nt_helper/domain/i_disting_midi_manager.dart';
import 'package:nt_helper/models/firmware_version.dart';
import 'package:nt_helper/models/packed_mapping_data.dart';
import 'package:nt_helper/models/sd_card_file_system.dart';
import 'package:nt_helper/ui/parameter_editor_registry.dart';
import 'package:nt_helper/ui/widgets/file_parameter_editor.dart';
```

Mirror the existing Poly Multisample test helpers:

- `_MockDistingCubit`
- `_MockDistingMidiManager`
- `_dir`
- `_file`
- `_stubChimeraSampleTree`
- `_pumpEditor`
- `_chimeraSlot`

In `setUpAll`, call:

```dart
TestWidgetsFlutterBinding.ensureInitialized();
ParameterEditorRegistry.setFirmwareVersion(FirmwareVersion('1.17.0'));
```

In `setUp`, stub:

```dart
when(() => cubit.state).thenReturn(DistingStateInitial());
when(() => cubit.stream).thenAnswer((_) => const Stream.empty());
when(() => cubit.disting()).thenReturn(manager);
```

`_pumpEditor` must call `ParameterEditorRegistry.findEditorFor`, assert the
result is a `FileParameterEditor`, pump it under
`BlocProvider<DistingCubit>.value`, and call `pumpAndSettle`.

`_chimeraSlot` must use the exact six-parameter table from the spec and accept
optional named overrides:

```dart
int lionFolderValue = 2,
int lionSampleValue = 0,
int goatFolderValue = 1,
int goatSampleValue = 0,
int beefFolderValue = 4,
int kickSampleValue = 0,
```

Build the slot's `parameters` list in the exact table order from the spec. Then
use this exact aligned-data shape, with `parameterValues` populated from the six
named overrides in the same order:

```dart
final parameterValues = [
  lionFolderValue,
  lionSampleValue,
  goatFolderValue,
  goatSampleValue,
  beefFolderValue,
  kickSampleValue,
];

values: List.generate(
  parameterValues.length,
  (index) => ParameterValue(
    algorithmIndex: 0,
    parameterNumber: index,
    value: parameterValues[index],
  ),
),
enums: List.generate(
  parameterValues.length,
  (index) => ParameterEnumStrings(
    algorithmIndex: 0,
    parameterNumber: index,
    values: const [],
  ),
),
mappings: List.generate(
  parameterValues.length,
  (index) => Mapping(
    algorithmIndex: 0,
    parameterNumber: index,
    packedMappingData: PackedMappingData.filler(),
  ),
),
valueStrings: List.generate(
  parameterValues.length,
  (index) => ParameterValueString(
    algorithmIndex: 0,
    parameterNumber: index,
    value: '',
  ),
),
```

Do not use `ParameterValue.filler`, `ParameterEnumStrings.filler`,
`Mapping.filler`, or `ParameterValueString.filler`; their `-1` indices do not
represent an aligned slot.

Implement the three widget tests with the exact names and assertions from the
spec. Use `find.text('Browse')`, then `tester.tap` and `pumpAndSettle` to open
the selection dialog and choose entries. The app strips audio extensions for
display, so assert `goat-a`, `goat-b`, `lion-a`, `kick-a`, and `kick-b`, not the
`.wav` forms.

### Leftover checks

Run:

```bash
rg -n "algorithmGuid: 'Chim'" lib/ui/parameter_editor_registry.dart
rg -n "correspondingFolderParameterName" \
  lib/ui/parameter_editor_registry.dart \
  lib/ui/widgets/file_parameter_editor.dart \
  test/ui/parameter_editor_registry_test.dart
rg -n "_loadsFromSelectedFolder" lib/ui/widgets/file_parameter_editor.dart
rg -n "contains\\('Sample'\\)|contains\\('File'\\)" \
  lib/ui/widgets/file_parameter_editor.dart
rg -n "Chimera .*sample|Chimera folder picker" \
  test/ui/parameter_editor_registry_test.dart \
  test/ui/widgets/file_parameter_editor_chimera_test.dart
```

Expected:

- `algorithmGuid: 'Chim'` appears four times.
- `correspondingFolderParameterName` appears in the rule model, three file
  rules, file editor, and tests.
- `_loadsFromSelectedFolder` appears once as a declaration and twice as a use.
- `contains('Sample')` and `contains('File')` appear only inside
  `_loadsFromSelectedFolder`.
- All seven required Chimera test names are present.

### Verification commands

```bash
cd /Users/nealsanche/nosuch/nt_helper
dart format \
  lib/ui/parameter_editor_registry.dart \
  lib/ui/widgets/file_parameter_editor.dart \
  test/ui/parameter_editor_registry_test.dart \
  test/ui/widgets/file_parameter_editor_chimera_test.dart
flutter analyze
flutter test \
  test/ui/parameter_editor_registry_test.dart \
  test/ui/widgets/file_parameter_editor_poly_multisample_test.dart \
  test/ui/widgets/file_parameter_editor_chimera_test.dart
git add \
  lib/ui/parameter_editor_registry.dart \
  lib/ui/widgets/file_parameter_editor.dart \
  test/ui/parameter_editor_registry_test.dart \
  test/ui/widgets/file_parameter_editor_chimera_test.dart
git status --short
git commit -m "fix(files): add Chimera sample pickers"
```

Only the four files named above may appear in `git status --short` before the
commit.

### Commit message

`fix(files): add Chimera sample pickers`
