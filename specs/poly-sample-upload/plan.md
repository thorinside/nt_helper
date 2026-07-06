# Plan: poly-sample-upload

This plan has **4 steps**. Execute exactly one step per fresh-context session, in order. `specs/poly-sample-upload/spec.md` is the authoritative design; `specs/conventions.md` gives repo-wide rules. Each step below names the exact files it may edit, exact tests, exact verification commands, and exact commit message.

Prerequisites: none outside this repo. Do not edit `lib/cubit/*`; this feature stays in the poly multisample cubit/service/UI files named below.

Program-level final verification after STEP 4: `flutter analyze && flutter test`.

Expected completion commits, one per step in order:

1. `feat(poly): remember mounted sample upload destination`
2. `feat(poly): add sample upload transport service`
3. `feat(poly): add upload actions to sample builder cubit`
4. `feat(poly): add sample folder upload toolbar action`

---

## STEP 1 of 4 — add mounted upload destination preference and state field

Spec sections: `Decision inventory`, `PolyMultisampleBuilderState additions`.

Files:

- `lib/poly_multisample/poly_sample_preferences_service.dart`
- `lib/ui/poly_multisample/poly_multisample_builder_cubit.dart`
- `test/poly_multisample/poly_sample_preferences_service_test.dart`
- `test/poly_multisample/poly_multisample_builder_cubit_test.dart`

Mechanical edits:

1. In `PolySamplePreferencesService`, add key `poly_multisample.lastMountedUploadFolder`, getter `String? get lastMountedUploadFolder`, and method `Future<void> setLastMountedUploadFolder(String path)`.
2. In `PolyMultisampleBuilderState`, add nullable field `lastMountedUploadFolder` with default null, constructor parameter, final field, and `copyWith` parameter. Preserve all existing field order and place this field after `lastWavExportFolder`.
3. In `PolyMultisampleBuilderCubit._loadPreferences`, include `prefs.lastMountedUploadFolder` in the all-null early-return condition and in the emitted `copyWith`.
4. Do not add upload methods in this step.
5. Extend `test/poly_multisample/poly_sample_preferences_service_test.dart` with `test('stores last mounted upload folder', ...)`: seed `SharedPreferences.setMockInitialValues({})`, create service, call `await service.setLastMountedUploadFolder('/Volumes/NT/samples/Piano')`, expect getter equals that string.
6. Extend `test/poly_multisample/poly_multisample_builder_cubit_test.dart` next to the existing `test('loads remembered folders into state on construction', ...)` with `test('loads remembered mounted upload folder into state on construction', ...)`: seed `{'poly_multisample.lastMountedUploadFolder': '/Volumes/NT/samples/Piano'}`, create `PolySamplePreferencesService`, construct `PolyMultisampleBuilderCubit(preferencesService: service)`, `await Future<void>.delayed(Duration.zero)`, expect `state.lastMountedUploadFolder` equals the seeded path, then close cubit.

Verification commands:

```bash
cd /Users/nealsanche/nosuch/nt_helper
dart format lib/poly_multisample/poly_sample_preferences_service.dart lib/ui/poly_multisample/poly_multisample_builder_cubit.dart test/poly_multisample/poly_sample_preferences_service_test.dart test/poly_multisample/poly_multisample_builder_cubit_test.dart
flutter analyze
flutter test test/poly_multisample/poly_sample_preferences_service_test.dart test/poly_multisample/poly_multisample_builder_cubit_test.dart
git add -A && git status --short
```

Leftover checks:

```bash
rg -n "lastMountedUploadFolder|setLastMountedUploadFolder|poly_multisample.lastMountedUploadFolder" lib/poly_multisample/poly_sample_preferences_service.dart lib/ui/poly_multisample/poly_multisample_builder_cubit.dart test/poly_multisample
```

The grep must show hits in both named lib files and both named test files.

Commit message: `feat(poly): remember mounted sample upload destination`

---

## STEP 2 of 4 — add PolySampleUploadService with mounted upload and optional SysEx verification

Spec sections: `PolySampleUploadService`, `Hardening matrix`.

Files:

- NEW `lib/poly_multisample/poly_sample_upload_service.dart`
- NEW `test/poly_multisample/poly_sample_upload_service_test.dart`

Mechanical edits:

1. Create `lib/poly_multisample/poly_sample_upload_service.dart` with the exact public symbols and method signatures from the spec: `PolySampleUploadProgress`, `PolySampleUploadException`, `PolySampleUploadFile`, `PolySampleUploadResult`, and `PolySampleUploadService`.
2. Import exactly: `dart:io`, `dart:typed_data`, `package:path/path.dart` as `p`, `package:nt_helper/domain/i_disting_midi_manager.dart`, `package:nt_helper/models/sd_card_file_system.dart`, `package:nt_helper/poly_multisample/poly_multisample_models.dart`, and `package:nt_helper/poly_multisample/poly_sample_apply_service.dart`.
3. Implement the private field `final PolySampleApplyService _applyService;` and constructor initializer from the spec.
4. Implement `buildUploadFiles` using `_applyService.buildTargetFileName` and duplicate-target detection from the spec.
5. Implement `uploadMountedSd` with temp-copy replacement, same-source skip, parent directory creation, host path context, and temp cleanup on failure.
6. Implement `uploadSysEx` with POSIX path context, parent directory creation, 512-byte chunked upload, byte-count/ETA progress text, optional post-upload directory-listing verification of planned target names/sizes, and failed verification counts instead of aborting the folder upload. Do not implement chunked SysEx download; the canonical NT SD-card download operation is whole-file only.
7. Private helper names in this file: `_ensureHardwareParent`, `_requireSuccess`, `_uniqueTempPath`; use the exact `_requireSuccess` signature from the spec.
8. Create `test/poly_multisample/poly_sample_upload_service_test.dart` with `MockDistingMidiManager extends Mock implements IDistingMidiManager`. Register `Uint8List(0)` fallback in `setUpAll`.
9. Add these tests exactly:
   - `test('buildUploadFiles rejects duplicate target names', ...)`: two regions that both target `Piano_C3.wav`; expect `PolySampleUploadException` and message contains `Multiple samples target Piano_C3.wav`.
   - `test('uploadMountedSd copies renamed files and preserves unrelated files', ...)`: create a temp source folder with `Piano_C3.wav`, destination folder with existing `Piano_C3.wav` containing different bytes and `unrelated.txt`; upload one region rooted C3; expect target bytes equal source and unrelated file still exists.
   - `test('uploadMountedSd skips same source and target path without deleting', ...)`: source path is already the computed target in destination; upload; expect file bytes unchanged.
   - `test('uploadSysEx creates parents and uploads chunk without verification by default', ...)`: nested hardware folder `/multisamples/Piano/Nested`, mock mkdir success, upload chunk success; verify `requestDirectoryCreate('/multisamples/Piano')`, `requestDirectoryCreate('/multisamples/Piano/Nested')`, one chunk upload, no chunk download, and result `correctedFiles == 0`.
   - `test('uploadSysEx writes semantic filenames into multisamples folder', ...)`: two edited regions with changed root, switch point, velocity, and round robin upload to `/multisamples/Piano/<semantic filename>.wav`; expect target paths contain the generated root/SW/V/RR tags used by the NT PolyMultisample player.
   - `test('uploadSysEx verifies uploaded files by listing names and sizes', ...)`: with `verifyAfterUpload: true`, directory listing contains the planned filename and byte size; expect `failedVerificationFiles == 0`, `correctedFiles == 0`, and no chunk downloads.
   - `test('uploadSysEx reports listing verification failures', ...)`: directory listing has a missing or size-mismatched planned file; expect `failedVerificationFiles == 1`.
   - `test('uploadSysEx uploads remaining files before verification failures', ...)`: two files upload first, then one listing verification failure is reported; expect `filesUploaded == 2`.
   - `test('uploadSysEx failed chunk upload surfaces PolySampleUploadException', ...)`: a later chunk returns `SdCardStatus(success: false, message: 'nope')`; expect message contains `Hardware upload chunk at 512 for /multisamples/Piano/Piano_C3.wav failed: nope`.

Verification commands:

```bash
cd /Users/nealsanche/nosuch/nt_helper
dart format lib/poly_multisample/poly_sample_upload_service.dart test/poly_multisample/poly_sample_upload_service_test.dart
flutter analyze
flutter test test/poly_multisample/poly_sample_upload_service_test.dart
git add -A && git status --short
```

Leftover checks:

```bash
python3 /Users/nealsanche/nosuch/nt_helper/.pi/skills/decision-free-specs/languages/dart/inventory.py lib/poly_multisample/poly_sample_upload_service.dart > /tmp/poly_sample_upload_service_inventory.md
rg -n "PolySampleUploadProgress|PolySampleUploadException|PolySampleUploadFile|PolySampleUploadResult|PolySampleUploadService" /tmp/poly_sample_upload_service_inventory.md
```

The inventory must list exactly 5 exported top-level declarations for the new service file.

Commit message: `feat(poly): add sample upload transport service`

---

## STEP 3 of 4 — wire upload service into PolyMultisampleBuilderCubit

Spec sections: `PolyMultisampleBuilderCubit additions`, `Hardening matrix`.

Files:

- `lib/ui/poly_multisample/poly_multisample_builder_cubit.dart`
- `test/poly_multisample/poly_multisample_builder_cubit_test.dart`

Mechanical edits:

1. Import `package:nt_helper/poly_multisample/poly_sample_upload_service.dart` in the cubit file.
2. Add `uploading` after `saving` in `PolyMultisampleActiveOperation`.
3. Add optional constructor parameter `PolySampleUploadService? uploadService`, field `final PolySampleUploadService _uploadService;`, and initializer `_uploadService = uploadService ?? const PolySampleUploadService()`.
4. Implement `uploadViaMountedSd` and `uploadViaSysEx` exactly as the spec states, including guard order, active operation/progress emits, preference persistence for mounted uploads, SysEx target `/multisamples/<sanitized current instrument name>`, effect strings, and failure emit.
5. Add private helper `_safeHardwareFolderName` near `_fingerprintRegions` at the bottom of the cubit file.
6. In the test file, import `package:nt_helper/poly_multisample/poly_sample_upload_service.dart` and add a fake upload service class near other fake service classes:

```dart
class _FakeUploadService extends PolySampleUploadService {
  _FakeUploadService({this.result, this.error, this.completer});
  final PolySampleUploadResult? result;
  final Object? error;
  final Completer<void>? completer;
  String? mountedDestination;
  String? hardwareFolder;
  int mountedCalls = 0;
  int sysexCalls = 0;

  @override
  Future<PolySampleUploadResult> uploadMountedSd({
    required List<PolySampleRegion> regions,
    required String destinationFolder,
    PolySampleUploadProgress? onProgress,
  }) async { ... }

  @override
  Future<PolySampleUploadResult> uploadSysEx({
    required IDistingMidiManager manager,
    required List<PolySampleRegion> regions,
    required String hardwareFolder,
    bool verifyAfterUpload = false,
    PolySampleUploadProgress? onProgress,
  }) async { ... }
}
```

The fake methods increment call counts, store destination/folder, call `onProgress?.call('Uploading fake sample...')`, await `completer?.future`, throw `error` when non-null, and return `result ?? const PolySampleUploadResult(filesUploaded: 1, bytesUploaded: 3, correctedFiles: 0)`.

7. Extend `_ExposedPolyMultisampleBuilderCubit` so its constructor accepts `super.uploadService` in addition to the existing `super.applyService`, `super.wavService`, and `super.previewService` parameters.
8. Add these cubit tests exactly:
   - `test('uploadViaMountedSd persists destination and emits success effect', ...)`: seed a local/importDraft state with one edited region using `_ExposedPolyMultisampleBuilderCubit.setTestState`; call upload; expect fake destination, `lastMountedUploadFolder`, `activeOperation.none`, and effect `Uploaded sample folder to /Volumes/NT/samples/Piano.`.
   - `test('uploadViaSysEx targets sanitized instrument folder', ...)`: instrument name `Piano/Bad:*Name`; call upload with `_MockDistingMidiManager`; expect fake `hardwareFolder == '/multisamples/Piano_Bad__Name'` and effect `Uploaded sample folder to /multisamples/Piano_Bad__Name.`.
   - `test('uploadViaSysEx reports corrected file count in effect', ...)`: fake result `correctedFiles: 2`; expect effect `Uploaded sample folder to /multisamples/Piano and corrected 2 files.`.
   - `test('uploadViaSysEx reports verification failures as an error', ...)`: fake result `failedVerificationFiles: 1`; call with `verifyAfterUpload: true`; expect fake flag true, error text, and no success effect.
   - `test('upload guards hardware source mode', ...)`: state sourceMode hardware; call mounted upload; expect fake `mountedCalls == 0` and error `Open or import a local sample folder before uploading.`.
   - `test('upload guards pending waveform edits', ...)`: state with `wavEditDrafts` non-empty; call SysEx upload; expect fake `sysexCalls == 0` and error `Save or discard waveform edits before uploading this sample set.`.
   - `test('upload surfaces transport errors', ...)`: fake throws `PolySampleUploadException('boom')`; call mounted upload; expect `activeOperation.none` and error `boom`.
   - `test('stale upload success is ignored after returning to sources', ...)`: fake uses a completer; start `uploadViaMountedSd`, wait one microtask, call `returnToSources`, complete fake, await upload future; expect `currentInstrument == null` and effect is null.

Verification commands:

```bash
cd /Users/nealsanche/nosuch/nt_helper
dart format lib/ui/poly_multisample/poly_multisample_builder_cubit.dart test/poly_multisample/poly_multisample_builder_cubit_test.dart
flutter analyze
flutter test test/poly_multisample/poly_multisample_builder_cubit_test.dart
git add -A && git status --short
```

Leftover checks:

```bash
rg -n "uploadViaMountedSd|uploadViaSysEx|PolyMultisampleActiveOperation.uploading|_safeHardwareFolderName" lib/ui/poly_multisample/poly_multisample_builder_cubit.dart test/poly_multisample/poly_multisample_builder_cubit_test.dart
```

The grep must show hits in both the cubit file and cubit test file.

Commit message: `feat(poly): add upload actions to sample builder cubit`

---

## STEP 4 of 4 — add upload dialog and top toolbar action

Spec sections: `Upload path dialog`, `Editor toolbar integration`, `PolySamplesView._upload`.

Files:

- NEW `lib/ui/poly_multisample/dialogs/poly_sample_upload_dialog.dart`
- NEW `test/poly_multisample/dialogs/poly_sample_upload_dialog_test.dart`
- `lib/ui/poly_multisample/poly_samples_editor_view.dart`
- `lib/ui/poly_multisample/poly_samples_screen.dart`
- `test/poly_multisample/poly_samples_editor_view_test.dart`
- `test/poly_multisample/poly_samples_screen_test.dart`

Mechanical edits:

1. Create the dialog file exactly as specified, including exported enum `PolySampleUploadPath` and exported function `showPolySampleUploadPathDialog`.
2. Add `onUpload` required constructor parameter and field to `PolySamplesEditorView` and `_Toolbar`.
3. Add the `Upload` `FilledButton.tonalIcon` directly before the existing Save As/Apply button. Use the exact `canUpload` and `uploading` expressions from the spec.
4. Add the uploading live-region status line below the toolbar wrap.
5. In `poly_samples_screen.dart`, import `dialogs/poly_sample_upload_dialog.dart`.
6. Add private method `_upload(BuildContext context)` exactly as the spec states.
7. Wire `onUpload: () => _upload(context)` in the `PolySamplesEditorView` construction.
8. Update every `PolySamplesEditorView` construction in tests to pass `onUpload`.
9. Dialog tests in `test/poly_multisample/dialogs/poly_sample_upload_dialog_test.dart`:
   - `testWidgets('returns sysex path when SysEx tile is tapped', ...)`: open dialog with `sysexAvailable: true`, tap `SysEx to NT hardware`, expect result path `PolySampleUploadPath.sysex` and `verifyAfterUpload == false`.
   - `testWidgets('returns sysex choice with verification enabled', ...)`: open dialog with `sysexAvailable: true`, tap `Verify after upload`, tap `SysEx to NT hardware`, expect result path `PolySampleUploadPath.sysex` and `verifyAfterUpload == true`.
   - `testWidgets('returns mounted path when mounted tile is tapped', ...)`: tap `Mounted SD-card folder`, expect result path `PolySampleUploadPath.mountedSd`.
   - `testWidgets('disables SysEx tile without a manager', ...)`: open with `sysexAvailable: false`, expect disabled subtitle `Connect to Disting NT to use SysEx upload.`, tap `SysEx to NT hardware`, pump, expect dialog still present.
10. Editor-view test additions in `test/poly_multisample/poly_samples_editor_view_test.dart`:
    - `testWidgets('toolbar Upload button invokes callback for local sample sets', ...)`: pump local state, tap `find.text('Upload')`, expect callback count 1.
    - `testWidgets('toolbar Upload button is disabled for hardware sample sets', ...)`: pump state with `sourceMode: PolySampleSourceMode.hardware`, read `FilledButton` whose child contains text `Upload`, expect `onPressed == null`.
    - `testWidgets('toolbar shows upload progress as a live status', ...)`: pump state with `activeOperation: PolyMultisampleActiveOperation.uploading` and `progressText: 'Uploading fake sample...'`, expect that text and a `CircularProgressIndicator`.
11. Samples-screen test addition in `test/poly_multisample/poly_samples_screen_test.dart`:
    - `testWidgets('upload button opens path dialog with SysEx disabled when disconnected', ...)`: pump `PolySamplesView` with a local instrument state and mock `disting()` returning null; tap `Upload`; expect dialog title `Upload sample folder`, mounted tile text, and disabled SysEx subtitle.

Verification commands:

```bash
cd /Users/nealsanche/nosuch/nt_helper
dart format lib/ui/poly_multisample test/poly_multisample
flutter analyze
flutter test test/poly_multisample/dialogs/poly_sample_upload_dialog_test.dart test/poly_multisample/poly_samples_editor_view_test.dart test/poly_multisample/poly_samples_screen_test.dart
flutter test test/poly_multisample
git add -A && git status --short
```

Leftover checks:

```bash
rg -n "Upload sample folder|Mounted SD-card folder|SysEx to NT hardware|onUpload|showPolySampleUploadPathDialog" lib/ui/poly_multisample test/poly_multisample
```

The grep must show hits in the new dialog, editor view, samples screen, and all three named test areas.

Commit message: `feat(poly): add sample folder upload toolbar action`
