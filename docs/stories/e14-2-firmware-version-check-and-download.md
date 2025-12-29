# Story E14.2: Firmware Version Check and Download

Status: done

## Story

As a user checking for firmware updates,
I want to see if a new firmware version is available and download it with one tap,
so that I can prepare for an update without leaving the app.

## Acceptance Criteria

### Version Discovery
1. Display current device firmware version (from `state.firmwareVersion`)
2. Background check for updates on successful connection (non-blocking)
3. Parse Expert Sleepers firmware page HTML:
   - Extract version numbers from download link filenames (`distingNT-vX.Y.Z.zip`)
   - Extract release dates from adjacent date text
   - Extract changelog entries from `<li>` items under version headings
   - Extract download URLs from `<a>` tags with `.zip` extension
4. Show update indicator (arrow up icon) next to firmware version in bottom app bar when update available
5. Tapping firmware indicator opens FirmwareUpdateScreen (→ UI implemented in E14.3, placeholder snackbar for now)
6. Display release notes (scrollable, newest first) (→ UI implemented in E14.3, data model ready)
7. Show current version vs latest available at top (→ UI implemented in E14.3)

### Package Download
8. "Update to vX.Y.Z" button downloads firmware .zip to temp directory
9. Show simple progress bar during download
10. Verify ZIP is valid: attempt to list archive entries, throw `FirmwareDownloadException` if corrupted
11. After successful download, navigate to bootloader instructions (handled by E14.3)
12. Delete package after successful flash OR if user cancels
13. No multi-version caching - download fresh each time
14. `flutter analyze` passes with zero warnings

## Tasks

- [x] Task 1: Create data model
  - [x] Create `lib/models/firmware_release.dart` with version, releaseDate, changelog, downloadUrl
  - [x] Note: Named `FirmwareRelease` to avoid collision with existing `FirmwareVersion` class
  - [x] Add freezed annotations

- [x] Task 2: Create FirmwareVersionService
  - [x] Create `lib/services/firmware_version_service.dart`
  - [x] Implement `Future<List<FirmwareRelease>> fetchAvailableVersions()`
  - [x] Parse HTML using `html` package to extract version blocks
  - [x] Extract download URLs using CSS selectors for `.zip` links
  - [x] Cache results for session
  - [x] Implement `FirmwareRelease? getLatestVersion(List<FirmwareRelease> versions)`
  - [x] Implement `bool isUpdateAvailable(String currentVersion, List<FirmwareRelease> available)`

- [x] Task 3: Add update check to DistingCubit
  - [x] Add `availableFirmwareUpdate` field to DistingState (nullable FirmwareRelease)
  - [x] Check for updates after successful connection (non-blocking)

- [x] Task 4: Update bottom app bar UI
  - [x] Add update indicator when `state.availableFirmwareUpdate != null`
  - [x] Make firmware version row tappable (placeholder snackbar until E14.3 screen exists)
  - [x] Only show update indicator on desktop platforms

- [x] Task 5: Implement firmware download
  - [x] Add `Future<String> downloadFirmware(FirmwareRelease version)` to FirmwareVersionService
  - [x] Download to temp directory
  - [x] Return path to downloaded .zip file
  - [x] Implement download progress callback (`onProgress`) for UI
  - [x] Verify ZIP is valid: list archive entries, require `.uf2` file
  - [x] Implement `deleteFirmwarePackage(String path)` cleanup

- [x] Task 6: Unit tests
  - [x] Test version parsing from sample HTML
  - [x] Test `isUpdateAvailable` with various scenarios
  - [x] Mock HTTP for download tests

## Dev Notes

### Expert Sleepers Page
URL: `https://expert-sleepers.co.uk/distingNTfirmwareupdates.html`

Parse using `html` package:
- Version numbers: Extract from download link filenames (`distingNT-vX.Y.Z.zip`)
- Download URLs: Extract href from `<a>` tags with `.zip` extension

### Files Modified
- `lib/cubit/disting_state.dart` - add `availableFirmwareUpdate` field
- `lib/cubit/disting_cubit.dart` - add `checkForFirmwareUpdate()` method and `FirmwareVersionService` instance
- `lib/cubit/disting_cubit_connection_delegate.dart` - call `checkForFirmwareUpdate()` after sync (desktop only)
- `lib/ui/synchronized_screen.dart` - add update indicator to bottom bar
- `pubspec.yaml` - add `html` and `archive` dependencies

### Files Created
- `lib/models/firmware_release.dart` (+ `.freezed.dart`, `.g.dart`)
- `lib/services/firmware_version_service.dart`
- `test/services/firmware_version_service_test.dart`

### References
- [Source: docs/epics/epic-14-firmware-update.md#Story E14.2]
- [Pattern: lib/services/plugin_update_checker.dart]
- [External: https://expert-sleepers.co.uk/distingNTfirmwareupdates.html]
