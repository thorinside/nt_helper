# Poly sample upload — SysEx and mounted SD-card paths

## Request

Add an upload action to the poly multisample/sample-folder editor. The action sends the currently open local/imported sampler folder to the Disting NT by one of two user-selected transports:

1. **SysEx to NT hardware** through the existing MIDI SD-card file APIs.
2. **Mounted SD-card folder** through the local filesystem.

The mounted SD-card path prompts for a destination folder and stores that folder for the next upload. The SysEx path uploads first, then always checks every uploaded hardware filename and byte size through directory listing. Byte-for-byte SysEx verification of WAV files is not supported by the Disting NT protocol because SD-card file download is whole-file only.

Hardening policy: **realistic-only**. Required hardening is limited to plausible user actions, async races, filesystem errors, hardware/API latency, and upload data mismatch.

## Inventory-first evidence

Inventory was produced with:

```bash
python3 /Users/nealsanche/nosuch/nt_helper/.pi/skills/decision-free-specs/languages/dart/inventory.py \
  lib/ui/poly_multisample/poly_samples_screen.dart \
  lib/ui/poly_multisample/poly_samples_editor_view.dart \
  lib/ui/poly_multisample/poly_multisample_builder_cubit.dart \
  lib/poly_multisample/poly_sample_hardware_service.dart \
  lib/poly_multisample/poly_sample_apply_service.dart \
  lib/poly_multisample/poly_sample_folder_service.dart \
  lib/poly_multisample/poly_sample_preferences_service.dart \
  lib/poly_multisample/poly_multisample_models.dart \
  lib/domain/i_disting_midi_manager.dart \
  lib/domain/disting_midi_manager.dart \
  lib/domain/mock_disting_midi_manager.dart \
  lib/domain/offline_disting_midi_manager.dart \
  lib/cubit/disting_cubit.dart \
  lib/cubit/disting_cubit_sd_card_delegate.dart
```

Additional inventory was produced for SysEx request classes and upload-adjacent tests:

```bash
python3 /Users/nealsanche/nosuch/nt_helper/.pi/skills/decision-free-specs/languages/dart/inventory.py \
  lib/domain/sysex/requests/request_file_upload.dart \
  lib/domain/sysex/requests/request_file_upload_chunk.dart \
  lib/domain/sysex/requests/request_file_download.dart \
  lib/domain/sysex/requests/request_directory_listing.dart \
  lib/domain/sysex/requests/request_directory_create.dart \
  lib/domain/sysex/requests/request_file_delete.dart

python3 /Users/nealsanche/nosuch/nt_helper/.pi/skills/decision-free-specs/languages/dart/inventory.py \
  test/poly_multisample/poly_multisample_builder_cubit_test.dart \
  test/poly_multisample/poly_sample_hardware_service_test.dart \
  test/poly_multisample/poly_sample_apply_service_test.dart \
  test/poly_multisample/poly_sample_preferences_service_test.dart \
  test/poly_multisample/poly_samples_editor_view_test.dart \
  test/poly_multisample/poly_samples_screen_test.dart
```

Relevant declarations from inventory:

| File | Current exported declarations | Current imported-by notes |
|---|---|---|
| `lib/ui/poly_multisample/poly_samples_screen.dart` | `PolySamplesScreen`, `PolySamplesView` | imported by synchronized screen and samples tests |
| `lib/ui/poly_multisample/poly_samples_editor_view.dart` | `PolySamplesEditorView` | imported by samples screen and editor-view test |
| `lib/ui/poly_multisample/poly_multisample_builder_cubit.dart` | `PolySampleSourceMode`, `PolyMultisampleLoadStatus`, `PolyMultisampleActiveOperation`, `PolyRegionSelectionMode`, `PolyWaveformMode`, `PolyMultisampleBuilderState`, `PolyMultisampleBuilderCubit` | imported by all poly multisample widgets, dialogs, and tests |
| `lib/poly_multisample/poly_sample_hardware_service.dart` | `PolySampleAdditionBytesReader`, `PolySampleHardwareException`, `PolySampleHardwareService` | imported by builder cubit and hardware-service tests |
| `lib/poly_multisample/poly_sample_apply_service.dart` | `PolySampleApplyException`, `PolySampleApplyService` | imported by hardware service, builder cubit, apply-service tests |
| `lib/poly_multisample/poly_sample_preferences_service.dart` | `PolySamplePreferencesService` | imported by builder cubit and preferences tests |
| `lib/domain/i_disting_midi_manager.dart` | `IDistingMidiManager` | existing SD-card methods include listing, download, upload, mkdir, delete, rename |

Hand spot-check after inventory: `poly_sample_hardware_service.dart` now uses SD-card chunk APIs for sample upload/download paths. `poly_samples_editor_view.dart` contains the top toolbar and already routes toolbar actions upward by constructor callbacks. `poly_samples_screen.dart` owns `FilePicker` calls and has access to `distingCubit.disting()`.

## Architecture decisions

### Decision inventory

| Decision | Rationale | Files affected | Status |
|---|---|---|---|
| Add a dedicated `PolySampleUploadService` instead of extending `PolySampleHardwareService`. | Upload spans both local mounted filesystems and hardware SysEx; a separate service keeps transport orchestration out of the cubit and avoids mixing mounted filesystem behavior into the hardware-only service. | NEW `lib/poly_multisample/poly_sample_upload_service.dart`; NEW `test/poly_multisample/poly_sample_upload_service_test.dart`; `lib/ui/poly_multisample/poly_multisample_builder_cubit.dart` | required |
| Reuse `PolySampleApplyService.buildTargetFileName` for upload target filenames. | Upload target naming must match existing Save As/Apply naming semantics for root note, switch point, velocity, and round-robin metadata. | `lib/poly_multisample/poly_sample_upload_service.dart` | required |
| Add `PolyMultisampleActiveOperation.uploading`. | Existing toolbar disables work during long operations by active operation; upload is a long operation with hardware latency and filesystem latency. | `lib/ui/poly_multisample/poly_multisample_builder_cubit.dart`; tests | required |
| Add `lastMountedUploadFolder` to preferences and builder state. | The request requires remembering the mounted SD-card filesystem destination for later uploads; existing folder memories have different meanings and must not be overloaded. | `lib/poly_multisample/poly_sample_preferences_service.dart`; `lib/ui/poly_multisample/poly_multisample_builder_cubit.dart`; tests | required |
| Add `uploadViaMountedSd(String destinationFolder)` and `uploadViaSysEx(IDistingMidiManager manager)` to `PolyMultisampleBuilderCubit`. | The cubit is the single source of truth for sample editor state, error/effect messages, and operation guards. | `lib/ui/poly_multisample/poly_multisample_builder_cubit.dart`; `test/poly_multisample/poly_multisample_builder_cubit_test.dart` | required |
| Keep the upload action out of `DistingCubit`. | The sample editor already owns poly sample state; `DistingCubit` remains the MIDI manager facade and does not gain poly-sample orchestration. | no `lib/cubit/*` edits | out-of-scope |
| Do not add a strategy registry. | There are exactly two transports with one service entry point each; a registry adds indirection without additional behavioral families. | no registry files | out-of-scope |
| The SysEx hardware destination is fixed to `/multisamples/<sanitized current instrument name>`. | The request requires transport selection, not a second SysEx destination workflow. A deterministic destination makes the feature mechanical and matches NT multisample folder conventions. | `lib/ui/poly_multisample/poly_multisample_builder_cubit.dart`; tests | required |
| The mounted SD-card destination is the exact folder returned by `FilePicker.getDirectoryPath`. | The request requires a destination folder and persistence. The selected folder is the final sampler folder; the app does not append the instrument name. | `lib/ui/poly_multisample/poly_samples_screen.dart`; `lib/poly_multisample/poly_sample_upload_service.dart`; tests | required |
| Mounted upload overwrites only planned target files and leaves unrelated existing files alone. | Removing extra files from a user-selected mounted folder is destructive and was not requested. | `lib/poly_multisample/poly_sample_upload_service.dart`; tests | required |
| SysEx name/size checking always runs after all files have uploaded. | Directory listing checks are cheap and must not abort the folder after the first file and leave later samples missing. | `lib/poly_multisample/poly_sample_upload_service.dart`; dialog; tests | required |
| SysEx verification covers every planned target filename and byte size with directory listing and ignores unrelated existing hardware files. | Whole-file SysEx downloads are not viable for WAV files, and the NT protocol has no chunked download operation. Deleting unrelated hardware files is destructive and not required. | `lib/poly_multisample/poly_sample_upload_service.dart`; `lib/domain/i_disting_midi_manager.dart`; tests | required |
| SysEx verification reports missing or size-mismatched files after all uploads complete. | The canonical protocol supports chunked upload and directory listing, but not byte-range download or byte-level correction verification for large WAV files. | `lib/poly_multisample/poly_sample_upload_service.dart`; tests | required |
| Uploaded SysEx filenames are the NT PolyMultisample mapping contract. | The NT PolyMultisample player derives root note, switch point, velocity layer, and round robin from filenames inside `/multisamples/<instrument>`, not from sidecar metadata. | `lib/poly_multisample/poly_sample_upload_service.dart`; tests | required |
| Upload is disabled for hardware-source instruments. | The requested source is a local sampler folder. Hardware-to-hardware copy has different semantics and no local bytes to verify. | `lib/ui/poly_multisample/poly_samples_editor_view.dart`; `lib/ui/poly_multisample/poly_multisample_builder_cubit.dart`; tests | required |
| Upload is blocked while waveform edit drafts exist. | Existing Save/Apply flows block while destructive WAV edits are pending; upload must not send stale source files. | `lib/ui/poly_multisample/poly_multisample_builder_cubit.dart`; tests | required |
| Upload does not mutate `currentInstrument`, `sourceMode`, `baselineRegions`, `editedRegions`, or dirty state. | Upload is an export/send operation. It must not imply that the local editor state has been applied or saved. | `lib/ui/poly_multisample/poly_multisample_builder_cubit.dart`; tests | required |
| Mounted upload does not perform read-back verification. | The request only mandates verification after SysEx upload. Local filesystem copy APIs surface copy failures through exceptions. | no mounted verification code | out-of-scope |
| SysEx upload uses 512-byte chunks. | SysEx messages have a 1024-byte maximum; SD-card write file (`7A 04`) has offset/count fields and uses 512-byte file data chunks. SD-card download (`7A 02`) returns the entire file and must not be used for WAV verification. | `lib/poly_multisample/poly_sample_upload_service.dart`; `lib/domain/i_disting_midi_manager.dart`; tests | required |

## Target file tree

```text
lib/poly_multisample/
  poly_sample_preferences_service.dart       (extend with lastMountedUploadFolder)
  poly_sample_upload_service.dart            (NEW)

lib/ui/poly_multisample/
  dialogs/poly_sample_upload_dialog.dart     (NEW)
  poly_multisample_builder_cubit.dart        (extend state, operation enum, methods)
  poly_samples_editor_view.dart              (toolbar Upload action)
  poly_samples_screen.dart                   (upload flow orchestration)

test/poly_multisample/
  poly_sample_preferences_service_test.dart  (extend)
  poly_sample_upload_service_test.dart       (NEW)
  poly_multisample_builder_cubit_test.dart   (extend)
  poly_samples_editor_view_test.dart         (extend)
  poly_samples_screen_test.dart              (extend)
  dialogs/poly_sample_upload_dialog_test.dart (NEW)
```

## Symbol map

| Symbol | Kind | Destination | Exported | Notes |
|---|---|---|---|---|
| `PolySamplePreferencesService.lastMountedUploadFolder` | getter | `lib/poly_multisample/poly_sample_preferences_service.dart` | yes | New getter backed by `poly_multisample.lastMountedUploadFolder` |
| `PolySamplePreferencesService.setLastMountedUploadFolder` | method | `lib/poly_multisample/poly_sample_preferences_service.dart` | yes | New persistence method |
| `PolySampleUploadException` | class | NEW `lib/poly_multisample/poly_sample_upload_service.dart` | yes | Exception message displayed by cubit snackbar path |
| `PolySampleUploadFile` | class | NEW `lib/poly_multisample/poly_sample_upload_service.dart` | yes | Immutable source/target mapping used by tests |
| `PolySampleUploadResult` | class | NEW `lib/poly_multisample/poly_sample_upload_service.dart` | yes | Contains `filesUploaded`, `bytesUploaded`, `correctedFiles` |
| `PolySampleUploadProgress` | typedef | NEW `lib/poly_multisample/poly_sample_upload_service.dart` | yes | `void Function(String message)` |
| `PolySampleUploadService` | class | NEW `lib/poly_multisample/poly_sample_upload_service.dart` | yes | Transport service |
| `PolySampleUploadService.buildUploadFiles` | method | NEW service | yes | Public for deterministic tests |
| `PolySampleUploadService.uploadMountedSd` | method | NEW service | yes | Mounted filesystem upload |
| `PolySampleUploadService.uploadSysEx` | method | NEW service | yes | SysEx upload + optional listing verification |
| `_ensureHardwareParent` | function | NEW service | no | Private duplicate of hardware parent creation semantics |
| `_requireSuccess` | function | NEW service | no | Private SD-card status guard |
| `_uniqueTempPath` | function | NEW service | no | Private temp path helper for mounted copy |
| `PolyMultisampleActiveOperation.uploading` | enum value | `lib/ui/poly_multisample/poly_multisample_builder_cubit.dart` | yes | New active operation value |
| `PolyMultisampleBuilderState.lastMountedUploadFolder` | field | builder cubit file | yes | New nullable state field |
| `PolyMultisampleBuilderCubit.uploadViaMountedSd` | method | builder cubit file | yes | New mounted upload action |
| `PolyMultisampleBuilderCubit.uploadViaSysEx` | method | builder cubit file | yes | New SysEx upload action |
| `_safeHardwareFolderName` | function | builder cubit file | no | Sanitizes current instrument name for `/multisamples/<name>` |
| `PolySampleUploadPath` | enum | NEW `lib/ui/poly_multisample/dialogs/poly_sample_upload_dialog.dart` | yes | Values `sysex`, `mountedSd` |
| `showPolySampleUploadPathDialog` | function | NEW dialog file | yes | Returns selected upload path or null |
| `_PolySampleUploadDialog` | widget | NEW dialog file | no | Private dialog body |
| `PolySamplesEditorView.onUpload` | constructor field | `lib/ui/poly_multisample/poly_samples_editor_view.dart` | yes | New required callback |
| `_Toolbar.onUpload` | constructor field | editor view file | no | Private toolbar callback |
| `PolySamplesView._upload` | method | `lib/ui/poly_multisample/poly_samples_screen.dart` | no | Dialog + picker orchestration |

## Interface tables

### `PolySampleUploadService`

```dart
typedef PolySampleUploadProgress = void Function(String message);

class PolySampleUploadException implements Exception {
  const PolySampleUploadException(this.message);
  final String message;
  @override
  String toString() => message;
}

class PolySampleUploadFile {
  const PolySampleUploadFile({
    required this.sourcePath,
    required this.targetPath,
    required this.displayName,
  });
  final String sourcePath;
  final String targetPath;
  final String displayName;
}

class PolySampleUploadResult {
  const PolySampleUploadResult({
    required this.filesUploaded,
    required this.bytesUploaded,
    required this.correctedFiles,
  });
  final int filesUploaded;
  final int bytesUploaded;
  final int correctedFiles;
}

class PolySampleUploadService {
  const PolySampleUploadService({
    PolySampleApplyService applyService = const PolySampleApplyService(),
  }) : _applyService = applyService;

  final PolySampleApplyService _applyService;

  List<PolySampleUploadFile> buildUploadFiles({
    required List<PolySampleRegion> regions,
    required String targetFolder,
    p.Context? pathContext,
  });

  Future<PolySampleUploadResult> uploadMountedSd({
    required List<PolySampleRegion> regions,
    required String destinationFolder,
    PolySampleUploadProgress? onProgress,
  });

  Future<PolySampleUploadResult> uploadSysEx({
    required IDistingMidiManager manager,
    required List<PolySampleRegion> regions,
    required String hardwareFolder,
    PolySampleUploadProgress? onProgress,
  });
}
```

Mechanical service rules:

1. `buildUploadFiles` uses `_applyService.buildTargetFileName` with `includeVelocity` true when any region has `(velocityLayer ?? 1) > 1`, and `includeRoundRobin` true when any region has `(roundRobin ?? 1) > 1`.
2. `buildUploadFiles` throws `PolySampleUploadException('Multiple samples target <basename>.')` when two source regions map to the same normalized target path.
3. `uploadMountedSd` calls `buildUploadFiles` with `targetFolder: destinationFolder` and the default host `package:path` context.
4. `uploadMountedSd` creates parent directories, copies each source file to a unique temp file in the target directory, deletes an existing target file with the same path, then renames the temp file to the target path. A source path equal to its normalized target path is counted as uploaded and skipped without deleting the file.
5. `uploadMountedSd` cleans up its temp file on copy/rename failure.
6. `uploadSysEx` calls `buildUploadFiles` with `targetFolder: hardwareFolder` and `pathContext: p.posix`; hardware target paths must always use `/` separators on every host platform.
7. `uploadSysEx` creates hardware parent directories with `requestDirectoryCreate` and `_requireSuccess`, uploads every source file with `requestFileUploadChunk` in 512-byte file-data chunks, and reports progress with elapsed-rate ETA. After every SysEx upload, it uses `requestDirectoryListing` to confirm every planned target filename and byte size, and reports missing or size-mismatched files through `failedVerificationFiles`; it does not throw and does not prevent other files from uploading.
8. `_requireSuccess` has signature `Future<void> _requireSuccess(Future<SdCardStatus?> future, String operation)` and throws `PolySampleUploadException('Hardware $operation failed: ${status?.message ?? 'no response'}')` when the status is null or unsuccessful.
9. `bytesUploaded` counts source bytes sent by primary uploads only. Verification does not add to `bytesUploaded`.

## Dependency and compatibility notes

- New imports added by this spec must use package-prefixed paths from `specs/conventions.md`; do not add new relative imports.
- `lib/poly_multisample/poly_sample_upload_service.dart` imports:
  - `dart:io`
  - `dart:typed_data`
  - `package:path/path.dart` as `p`
  - `package:nt_helper/domain/i_disting_midi_manager.dart`
  - `package:nt_helper/models/sd_card_file_system.dart`
  - `package:nt_helper/poly_multisample/poly_multisample_models.dart`
  - `package:nt_helper/poly_multisample/poly_sample_apply_service.dart`
- No existing public symbols move to new files, so no compatibility re-export is required.
- Do not edit generated files; this feature adds no generated-code classes.

### `PolyMultisampleBuilderState` additions

| Field | Type | Default | copyWith parameter |
|---|---|---|---|
| `lastMountedUploadFolder` | `String?` | `null` | `String? lastMountedUploadFolder` |

Also add `PolyMultisampleActiveOperation.uploading` after `saving` in the enum.

### `PolyMultisampleBuilderCubit` additions

Constructor:

```dart
PolyMultisampleBuilderCubit({
  PolySampleFolderService? folderService,
  PolySampleHardwareService? hardwareService,
  PolySampleImportService? importService,
  PolySampleApplyService? applyService,
  PolyWavService? wavService,
  PolyAudioPreviewService? previewService,
  PolySamplePreferencesService? preferencesService,
  PolySampleUploadService? uploadService,
})
```

New field:

```dart
final PolySampleUploadService _uploadService;
```

New public methods:

```dart
Future<void> uploadViaMountedSd(String destinationFolder);
Future<void> uploadViaSysEx(IDistingMidiManager manager);
```

Shared cubit upload guards, in order:

1. `state.currentInstrument == null` returns without emitting.
2. `state.sourceMode == PolySampleSourceMode.hardware` emits error `'Open or import a local sample folder before uploading.'` and returns.
3. `state.editedRegions.isEmpty` emits error `'There are no samples to upload.'` and returns.
4. `state.hasWaveformDrafts` emits error `'Save or discard waveform edits before uploading this sample set.'` and returns.

Mounted method success behavior:

1. Emit `activeOperation: uploading`, `progressText: 'Uploading sample folder...'`, `clearError: true`.
2. Call `_uploadService.uploadMountedSd(regions: editedRegions, destinationFolder: destinationFolder, onProgress: ...)`.
3. Persist `setLastMountedUploadFolder(destinationFolder)` with `_prefs()` and emit `lastMountedUploadFolder: destinationFolder`.
4. Emit `activeOperation: none`, clear progress text, and effect `'Uploaded sample folder to $destinationFolder.'`.

SysEx method success behavior:

1. Compute `hardwareFolder = p.posix.join('/multisamples', _safeHardwareFolderName(instrument.name))`.
2. Emit `activeOperation: uploading`, `progressText: 'Uploading sample folder...'`, `clearError: true`.
3. Call `_uploadService.uploadSysEx(regions: editedRegions, manager: manager, hardwareFolder: hardwareFolder, onProgress: ...)`.
4. Emit `activeOperation: none`, clear progress text, and effect `'Uploaded sample folder to $hardwareFolder.'`.

Failure behavior for both methods: catch any error and emit `activeOperation: none`, clear progress text, `error: error.toString()`.

Async race rule: capture `operationRevision = _contentRevision` before upload. Progress and success emits are skipped when `operationRevision != _contentRevision`; the failure emit is still allowed because the user needs the error snackbar for the in-flight upload they started.

Private helper:

```dart
String _safeHardwareFolderName(String name)
```

Rules: replace every `RegExp(r'[\\/:*?"<>|]')` match with `_`, trim whitespace, and return `'Untitled'` when the sanitized string is empty.

### Upload path dialog

File: `lib/ui/poly_multisample/dialogs/poly_sample_upload_dialog.dart`

```dart
enum PolySampleUploadPath { sysex, mountedSd }

Future<PolySampleUploadPath?> showPolySampleUploadPathDialog(
  BuildContext context, {
  required bool sysexAvailable,
})
```

Dialog structure:

- `AlertDialog` title: `'Upload sample folder'` wrapped with `Semantics(header: true, child: ...)`.
- Content width: `420`.
- Content column:
  - `Text('Select how to send this sample folder to the Disting NT.')`
  - `ListTile` for SysEx:
    - leading `Icon(Icons.cable, semanticLabel: 'SysEx upload')`
    - title `'SysEx to NT hardware'`
    - subtitle `'Uses MIDI SysEx and checks uploaded filenames and sizes.'`
    - enabled exactly `sysexAvailable`
    - disabled subtitle replacement when false: `'Connect to Disting NT to use SysEx upload.'`
    - onTap pops `PolySampleUploadPath.sysex`
  - `ListTile` for mounted SD:
    - leading `Icon(Icons.sd_storage, semanticLabel: 'Mounted SD-card upload')`
    - title `'Mounted SD-card folder'`
    - subtitle `'Copies files to a mounted SD-card filesystem folder.'`
    - onTap pops `PolySampleUploadPath.mountedSd`
- Actions: `TextButton('Cancel')` pops null.

### Editor toolbar integration

`PolySamplesEditorView` gains:

```dart
final VoidCallback onUpload;
```

The constructor requires `onUpload`; `_Toolbar` also requires `onUpload`.

Toolbar button placement: directly before the existing draft `Save As…` / non-draft `Apply` primary action.

Button:

```dart
FilledButton.tonalIcon(
  onPressed: canUpload ? onUpload : null,
  icon: uploading
      ? const SizedBox.square(
          dimension: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        )
      : const Icon(Icons.upload_file),
  label: const Text('Upload'),
)
```

`canUpload` is true exactly when:

```dart
state.sourceMode != PolySampleSourceMode.hardware &&
state.editedRegions.isNotEmpty &&
!state.hasWaveformDrafts &&
state.activeOperation != PolyMultisampleActiveOperation.uploading &&
state.activeOperation != PolyMultisampleActiveOperation.applying &&
state.activeOperation != PolyMultisampleActiveOperation.saving
```

`uploading` is `state.activeOperation == PolyMultisampleActiveOperation.uploading`.

Add a live-region status line below the toolbar wrap when uploading:

```dart
Semantics(
  liveRegion: true,
  child: Text(state.progressText ?? 'Uploading sample folder...'),
)
```

### `PolySamplesView._upload`

Add private method to `PolySamplesView`:

```dart
Future<void> _upload(BuildContext context) async
```

Mechanical flow:

1. Read cubit: `final cubit = context.read<PolyMultisampleBuilderCubit>();`.
2. Read manager: `final manager = distingCubit.disting();`.
3. Call `showPolySampleUploadPathDialog(context, sysexAvailable: manager != null)`.
4. Return when the dialog returns null or `!context.mounted`.
5. For `PolySampleUploadPath.sysex`, call `await cubit.uploadViaSysEx(manager!)`.
6. For `PolySampleUploadPath.mountedSd`, call `FilePicker.getDirectoryPath(dialogTitle: 'Upload samples to mounted SD-card folder', initialDirectory: cubit.state.lastMountedUploadFolder ?? cubit.state.lastCustomOutputFolder ?? (cubit.state.lastLocalFolder == null ? null : p.dirname(cubit.state.lastLocalFolder!)))`; return on null or unmounted; call `await cubit.uploadViaMountedSd(path)`.

Wire `PolySamplesEditorView(..., onUpload: () => _upload(context), ...)` in `_body`.

## Hardening matrix

| Risk | Plausible path | Chosen handling | Tests required |
|---|---|---|---|
| SysEx upload reports success but file bytes differ on hardware. | MIDI/SysEx transport corruption, device write glitch, or hardware latency. | SysEx cannot byte-verify large WAV files because NT download is whole-file only. When verification is enabled, confirm target names and byte sizes only; use mounted SD-card access for byte-for-byte checks. | Service test: listing with matching name/size succeeds and performs no download. |
| SysEx upload target is missing after upload. | Hardware write failed even though upload request returned success. | Directory listing verification reports the missing planned target in `failedVerificationFiles`. | Service test: listing missing one uploaded filename reports one failure after all files upload. |
| Hardware parent folder does not exist. | First upload to `/multisamples/<instrument>/<subfolder>` on a fresh card. | Create each parent segment with `requestDirectoryCreate`, skipping `/multisamples`. | Service test verifies mkdir calls before nested upload. |
| Hardware API returns null or failed status for upload/mkdir. | Device disconnected, unsupported firmware, timeout. | Throw `PolySampleUploadException('Hardware <operation> failed: <message or no response>')`; cubit emits snackbar error. | Service test for null upload status; cubit test for error state. |
| User starts upload, then leaves editor or opens another source before upload completes. | Back navigation, return to sources, load another folder. | Cubit captures `_contentRevision`; stale progress/success emits are skipped. Failure still emits error. | Cubit test using delayed upload service and `returnToSources` before completion. |
| Mounted SD-card filesystem disappears during copy. | User ejects card or OS unmounts volume. | Filesystem exception is caught by cubit and shown as error; temp file cleanup is attempted. | Service test with fake temp cleanup is not practical without implementation seams; cubit error test with throwing fake service is required. |
| Destination target already exists on mounted folder. | Re-upload to same mounted folder. | Delete only the planned target file and replace it via temp copy. Unrelated files remain. | Service test: existing target content is replaced and unrelated file remains. |
| Destination is the same as the source folder. | User selects current local sample folder as mounted destination. | Source path equal to normalized target path is skipped without deletion and counted as uploaded. | Service test: same source/target file remains intact. |
| Two edited regions map to the same output filename. | User sets duplicate root/velocity/RR metadata. | `buildUploadFiles` throws `Multiple samples target <basename>.`; cubit emits error. | Service duplicate-target test; cubit error test. |
| Hardware-source instrument upload lacks local bytes. | User opened `/samples` from NT then presses Upload. | Toolbar disables Upload for hardware source and cubit guard emits `'Open or import a local sample folder before uploading.'` when called directly. | Editor-view test for disabled Upload in hardware mode; cubit guard test. |
| Pending waveform edits would upload stale source files. | User trims/fades a sample but has not saved WAV edit. | Toolbar disables Upload and cubit guard emits `'Save or discard waveform edits before uploading this sample set.'`. | Editor-view disabled test; cubit guard test. |
| Large sample transfer exceeds SysEx message limits. | WAV files are too large for whole-file SysEx messages. | Upload uses 512-byte file-data chunks. Verification over SysEx is limited to directory listing name/size checks because download is whole-file only. | Service tests verify ordered upload chunks and listing verification. |
| Extra unrelated files exist in destination folder. | Reusing an existing mounted folder or existing hardware folder. | Extra files are left unchanged. Destructive mirroring is out-of-scope. | Service test asserts unrelated mounted file remains. Hardware extra-file deletion has no test because no deletion is implemented. |

## Acceptance criteria

1. `flutter analyze` reports no issues.
2. `flutter test test/poly_multisample` passes.
3. The Samples editor toolbar displays an `Upload` button for local/import/custom sample sets and disables it for hardware-source sample sets.
4. The upload dialog has exactly two paths: `SysEx to NT hardware` and `Mounted SD-card folder`; SysEx is disabled when no MIDI manager is connected; SysEx upload always checks uploaded filenames and byte sizes after transfer.
5. Mounted SD upload prompts with dialog title `'Upload samples to mounted SD-card folder'`, uploads to the exact folder returned by the picker, and persists that exact folder as `lastMountedUploadFolder`.
6. SysEx upload sends to `/multisamples/<sanitized current instrument name>`, shows byte-count and ETA progress, always checks every planned target filename and byte size after upload, and reports a snackbar error when the check fails.
7. Upload success sends an accessibility announcement through the existing effect listener and does not show a success snackbar.
8. Upload never changes the current editor instrument, source mode, edited regions, baseline regions, selection, or dirty state.
