# Story 13.2: Install Sample Files to SD Card During Plugin Installation

Status: Ready for Review

## Story

As a user installing a C++ plugin with sample dependencies,
I want sample files to be automatically written to the SD card's `/samples/` directory,
so that my plugin works immediately without manual sample installation.

## Acceptance Criteria

1. `_installFilesViaDisting()` handles sample files separately from plugin files
2. Sample files are uploaded to SD card using the path from the zip (e.g., `samples/drums/kick.wav` -> `/samples/drums/kick.wav`)
3. Before uploading each sample, check if file already exists at target path using existing SD card file listing
4. If sample file already exists, skip upload (do not overwrite)
5. Create parent directories as needed before uploading samples (use existing `_ensureDirectoryExists()`)
6. Sample installation happens after plugin file installation
7. Installation progress includes sample files in progress tracking
8. Sample upload failures are logged but don't fail the entire plugin installation (warn, continue)
9. `QueuedPluginStatus` states work correctly during sample extraction phase
10. Integration test verifies sample files are uploaded to correct paths
11. Integration test verifies existing samples are skipped (not overwritten)
12. `flutter analyze` passes with zero warnings

## Tasks / Subtasks

- [x] Task 1: Add sample installation phase to `_installSinglePluginViaDisting()` (AC: #1, #6)
  - [x] After plugin files are installed, check if `ExtractedArchiveContents.hasSamples`
  - [x] If samples exist, proceed to sample installation phase
  - [x] Update status to new `QueuedPluginStatus.installingSamples` or reuse `installing`

- [x] Task 2: Implement sample file existence check (AC: #3, #4)
  - [x] For each sample file, extract target directory path
  - [x] Call `requestDirectoryListing()` to get existing files in that directory
  - [x] Check if sample filename exists in listing
  - [x] Skip upload if file exists, track as "skipped"

- [x] Task 3: Create directories and upload samples (AC: #2, #5)
  - [x] For each sample to install, extract parent directory path
  - [x] Call `_ensureDirectoryExists()` from `_PluginDelegate` to create directories
  - [x] Use `installFileToPath()` pattern for chunked upload
  - [x] Prepend `/` to sample path (e.g., `samples/x.wav` -> `/samples/x.wav`)

- [x] Task 4: Implement progress tracking for samples (AC: #7)
  - [x] Track total files = plugin files + sample files to install (not skipped)
  - [x] Update progress callbacks to include sample installation progress
  - [x] Consider weighted progress (samples may be larger than plugin files)

- [x] Task 5: Handle sample upload failures gracefully (AC: #8)
  - [x] Wrap individual sample uploads in try/catch
  - [x] Log failures but continue with remaining samples
  - [x] Track failed samples for reporting in Story 13.3

- [x] Task 6: Track installation results for UI (AC: #9)
  - [x] Create `SampleInstallationResult` class to track:
    - `installedSamples`: List of successfully installed sample paths
    - `skippedSamples`: List of samples that already existed
    - `failedSamples`: List of samples that failed with error messages
  - [x] Store result in `QueuedPlugin` or return from install method

- [x] Task 7: Write integration tests (AC: #10, #11)
  - [x] Mock `IDistingMidiManager` to verify upload calls
  - [x] Test sample path transformation (`samples/x.wav` -> `/samples/x.wav`)
  - [x] Test skip behavior when file exists
  - [x] Test directory creation for nested samples

- [x] Task 8: Verify `flutter analyze` passes (AC: #12)

## Dev Notes

### Primary Files to Modify
- `lib/services/gallery_service.dart` - Main installation flow
- `lib/cubit/disting_cubit_plugin_delegate.dart` - Reuse file upload utilities
- `lib/models/gallery_models.dart` - Add sample tracking to `QueuedPlugin`

### Key Existing Methods to Reuse

From `_PluginDelegate` (`lib/cubit/disting_cubit_plugin_delegate.dart`):

```dart
// Create directories recursively
Future<void> _ensureDirectoryExists(String directoryPath, IDistingMidiManager disting)

// Upload file to specific path with chunked upload
Future<void> installFileToPath(String targetPath, Uint8List fileData, {Function(double)? onProgress})

// Check if directory/file exists
final listing = await disting.requestDirectoryListing(path);
```

### Sample Path Transformation

```dart
String _getSampleTargetPath(String zipPath) {
  // zipPath: "samples/drums/kick.wav"
  // returns: "/samples/drums/kick.wav"
  if (zipPath.startsWith('/')) return zipPath;
  return '/$zipPath';
}
```

### Proposed SampleInstallationResult

```dart
class SampleInstallationResult {
  final List<String> installedSamples;
  final List<String> skippedSamples;
  final Map<String, String> failedSamples; // path -> error message

  const SampleInstallationResult({
    this.installedSamples = const [],
    this.skippedSamples = const [],
    this.failedSamples = const {},
  });

  int get totalSamples => installedSamples.length + skippedSamples.length + failedSamples.length;
  bool get hasFailures => failedSamples.isNotEmpty;
}
```

### File Existence Check Strategy

```dart
Future<bool> _sampleFileExists(String samplePath, IDistingMidiManager disting) async {
  final directory = samplePath.substring(0, samplePath.lastIndexOf('/'));
  final filename = samplePath.substring(samplePath.lastIndexOf('/') + 1);

  try {
    final listing = await disting.requestDirectoryListing(directory);
    if (listing == null) return false;
    return listing.entries.any((e) => e.name == filename && !e.isDirectory);
  } catch (e) {
    // If we can't check, assume file doesn't exist and try to upload
    return false;
  }
}
```

### Access to MIDI Manager

The `GalleryService._installFilesViaDisting()` receives `distingInstallPlugin` callback, but for sample installation we need direct access to the MIDI manager. Options:

1. **Pass additional callback** for sample installation
2. **Modify the callback signature** to also handle samples
3. **Add sample-specific callback** parameter to `installQueuedPlugins()`

Recommended: Add `distingSampleInstaller` callback parameter that receives the `DistingCubit` or MIDI manager.

### Project Structure Notes
- Aligns with existing plugin installation patterns
- Reuses established SD card file operation methods
- No new dependencies required

### References
- [Source: lib/services/gallery_service.dart#_installSinglePluginViaDisting]
- [Source: lib/cubit/disting_cubit_plugin_delegate.dart#_ensureDirectoryExists]
- [Source: lib/cubit/disting_cubit_plugin_delegate.dart#installFileToPath]
- [Source: docs/epics.md#Epic 13]

## Dev Agent Record

### Context Reference
Epic 13: Plugin Sample Dependency Installation

### Agent Model Used
Claude Opus 4.5

### Debug Log References
N/A - All tests passed on first run

### Completion Notes List
- Created `SampleInstallationResult` class with installed/skipped/failed tracking
- Created `SampleInstallCallback` typedef for sample installation callback
- Added `distingInstallSample` callback parameter to `installQueuedPlugins()`
- Added `onSampleInstallComplete` callback for UI notification
- Modified `_installSinglePluginViaDisting()` to return `SampleInstallationResult?`
- Added `_installSampleFiles()` method to GalleryService for batch sample installation
- Added `_getSampleTargetPath()` method to transform zip paths to SD card paths
- Added `installSampleFile()` method to `_PluginDelegate` with file existence check
- Added `_sampleFileExists()` helper method using `requestDirectoryListing()`
- Exposed `installSampleFile()` through `DistingCubit`
- Updated `gallery_screen.dart` to pass sample installer callback
- Basic error notification in UI (Story 13.3 will add detailed summary)
- All 31 tests pass (expanded during code review), `flutter analyze` passes with zero warnings
- **Code Review Fixes (2025-12-27):**
  - Added `_installSampleWithRetry()` with exponential backoff for transient failures
  - Added path normalization in `_getSampleTargetPath()` to lowercase `samples/` prefix
  - Added directory conflict detection in `_sampleFileExists()` (throws if directory exists at file path)

### File List
- lib/services/gallery_service.dart (modified)
- lib/cubit/disting_cubit_plugin_delegate.dart (modified)
- lib/cubit/disting_cubit.dart (modified)
- lib/ui/gallery_screen.dart (modified)
- test/services/gallery_service_sample_extraction_test.dart (modified)

## Change Log
- 2025-12-26: Implemented sample file installation to SD card during plugin installation
- 2025-12-27: Code review - added retry logic, path normalization, directory conflict detection
