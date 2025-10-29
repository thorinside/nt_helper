# Story E3.3: Detect File Conflicts with SD Card - Context Document

**Story:** e3-3-detect-file-conflicts-with-sd-card
**Epic:** 3 - Drag-and-Drop Preset Package Installation
**Generated:** 2025-10-28

---

## Story Overview

This story adds conflict detection to the package installation flow by fetching the SD card directory listing and comparing it against package files. The implementation occurs after package analysis is complete but before showing the install dialog.

**Key Requirement:** Conflict detection must gracefully degrade when the device is offline or firmware is too old, proceeding with installation without conflict flags.

---

## Implementation Location

**Target File:** `/Users/nealsanche/nosuch/nt_helper/lib/ui/widgets/preset_browser_dialog.dart`

**Integration Point:** Inside `_handleDragDone` method, immediately after package analysis completes and before showing the install dialog (to be added in E3.4).

---

## Conflict Detection Code

### Code to Add After Package Analysis

```dart
// Fetch SD card files for conflict detection
final state = widget.distingCubit.state;
List<DirectoryEntry> sdCardFiles = [];

if (state is DistingStateSynchronized && !state.offline) {
  try {
    debugPrint('[PresetBrowserDialog] Fetching SD card directory listing...');
    sdCardFiles = await widget.distingCubit.fetchSdCardDirectoryListing('/');
    debugPrint('[PresetBrowserDialog] Found ${sdCardFiles.length} files on SD card');
  } catch (e) {
    debugPrint('[PresetBrowserDialog] Could not fetch SD card files: $e');
    // Continue without conflict detection - user will be warned in install dialog
  }
}

// Detect conflicts
final analysisWithConflicts = FileConflictDetector.detectConflicts(
  _currentAnalysis!,
  sdCardFiles,
);

setState(() {
  _currentAnalysis = analysisWithConflicts;
});

debugPrint('[PresetBrowserDialog] Conflict detection complete: ${analysisWithConflicts.conflictCount} conflicts');

// Story E3.4 will show the install dialog here
```

### Required Imports

```dart
import 'package:nt_helper/services/file_conflict_detector.dart';
import 'package:nt_helper/models/sd_card_file_system.dart';
```

---

## DistingCubit State and API

### State Checking Pattern

**State Type:** `DistingStateSynchronized`
**Offline Check:** `state.offline` (boolean flag)

The state must be checked to determine if SD card operations are available:

```dart
final state = widget.distingCubit.state;
if (state is DistingStateSynchronized && !state.offline) {
  // Can fetch SD card directory listing
}
```

**Offline Mode Behavior:**
- `state.offline == true`: Device disconnected, using cached data
- Cannot perform SD card operations
- Conflict detection should be skipped gracefully
- Installation proceeds with no conflict warnings

### SD Card Directory Listing API

**Note:** The story mentions `fetchSdCardDirectoryListing('/')` but this method does not exist in the current codebase. The actual implementation should use:

```dart
final disting = widget.distingCubit.disting();
if (disting != null) {
  await disting.requestWake();
  final listing = await disting.requestDirectoryListing('/');
  if (listing != null) {
    sdCardFiles = listing.entries;
  }
}
```

However, for this story implementation, follow the pattern shown in the existing `load_preset_dialog.dart` reference code (lines 613-617), which uses `FileConflictDetector` with the `DistingCubit` instance.

---

## FileConflictDetector Service

### API Overview

**Location:** `/Users/nealsanche/nosuch/nt_helper/lib/services/file_conflict_detector.dart`

**Constructor:**
```dart
final conflictDetector = FileConflictDetector(widget.distingCubit);
```

**Primary Method:**
```dart
Future<PackageAnalysis> detectConflicts(PackageAnalysis analysis) async
```

### How It Works

1. **State Validation:** Checks if `DistingCubit` is in `DistingStateSynchronized` state and not offline
2. **Early Return:** If offline or not synchronized, returns original analysis without conflict flags
3. **Directory Grouping:** Groups package files by target directory using `analysis.filesByDirectory`
4. **Per-Directory Scanning:** Fetches SD card files for each directory containing package files
5. **Filename Matching:** Compares package filenames against SD card filenames in each directory
6. **Flag Updates:** Sets `hasConflict: true` on `PackageFile` instances where matches are found
7. **Error Handling:** Catches and logs errors, returns original analysis on failure

### Internal Methods

**`_getExistingFilesInDirectory(String directoryPath)`**
- Calls `disting.requestWake()` to ensure device is ready
- Calls `disting.requestDirectoryListing(directoryPath)`
- Returns `Set<String>` of filenames (not full paths)
- Returns empty set on error (non-blocking)

**Static Helper Methods:**
```dart
// Update single file action
static PackageAnalysis updateFileAction(
  PackageAnalysis analysis,
  String targetPath,
  FileAction action,
)

// Set action for all conflicting files
static PackageAnalysis setActionForConflicts(
  PackageAnalysis analysis,
  FileAction action,
)

// Set action for all files
static PackageAnalysis setActionForAllFiles(
  PackageAnalysis analysis,
  FileAction action,
)
```

### Behavior Notes

- **Non-blocking:** Directory listing failures do not throw exceptions
- **Granular:** Checks only directories that contain package files
- **Efficient:** Groups files by directory to minimize SysEx requests
- **Safe:** Returns original analysis on any error

---

## SD Card File System Models

### DirectoryEntry

**Location:** `/Users/nealsanche/nosuch/nt_helper/lib/models/sd_card_file_system.dart`

```dart
class DirectoryEntry {
  final String name;        // Filename only, not full path
  final int attributes;     // FAT32 file attributes
  final int date;           // FAT32 date format
  final int time;           // FAT32 time format
  final int size;           // File size in bytes

  bool get isDirectory => (attributes & 0x10) != 0;
}
```

**Key Points:**
- `name` field contains filename only (e.g., "preset.json")
- `isDirectory` flag distinguishes files from directories
- Attributes follow FAT32 format (bit 0x10 = directory flag)

### DirectoryListing

```dart
class DirectoryListing {
  final List<DirectoryEntry> entries;
}
```

**Usage in Conflict Detection:**
```dart
final listing = await disting.requestDirectoryListing('/presets');
if (listing != null) {
  for (final entry in listing.entries) {
    if (!entry.isDirectory) {
      filenames.add(entry.name);
    }
  }
}
```

---

## PackageAnalysis Model Updates

### Conflict-Related Properties

**Location:** `/Users/nealsanche/nosuch/nt_helper/lib/models/package_analysis.dart`

```dart
class PackageAnalysis {
  // ... other fields ...

  /// Number of files that have conflicts
  int get conflictCount => files.where((f) => f.hasConflict).length;

  /// Whether there are any conflicts to resolve
  bool get hasConflicts => conflictCount > 0;

  /// Get files grouped by their target directory
  Map<String, List<PackageFile>> get filesByDirectory {
    final Map<String, List<PackageFile>> grouped = {};
    for (final file in files) {
      final dir = file.targetPath.split('/').first;
      grouped.putIfAbsent(dir, () => []).add(file);
    }
    return grouped;
  }

  /// Update file actions
  PackageAnalysis copyWith({List<PackageFile>? files}) { ... }
}
```

### PackageFile Model

**Location:** `/Users/nealsanche/nosuch/nt_helper/lib/models/package_file.dart`

```dart
class PackageFile {
  final String relativePath;  // Path within package (e.g., "root/presets/my_preset.json")
  final String targetPath;    // Path on SD card (e.g., "presets/my_preset.json")
  final int size;
  final bool hasConflict;     // TRUE if file exists on SD card
  final FileAction action;     // install or skip

  String get filename => relativePath.split('/').last;
  bool get shouldInstall => action == FileAction.install;
  bool get shouldSkip => action == FileAction.skip;

  PackageFile copyWith({
    String? relativePath,
    String? targetPath,
    int? size,
    bool? hasConflict,
    FileAction? action,
  }) { ... }
}

enum FileAction {
  install,  // Install the file (overwrite if exists)
  skip,     // Skip installing this file
}
```

**Conflict Detection Updates:**
- `FileConflictDetector` calls `file.copyWith(hasConflict: true)` for each matching filename
- Original analysis has all files with `hasConflict: false` by default
- Updated analysis has conflict flags set based on SD card comparison

---

## Graceful Degradation Scenarios

### Scenario 1: Offline Mode

**Condition:** `state.offline == true`

**Behavior:**
1. SD card fetch is skipped (not attempted)
2. `FileConflictDetector.detectConflicts()` returns original analysis unchanged
3. All `PackageFile.hasConflict` remain `false`
4. Installation proceeds normally
5. User sees no conflict warnings

**Debug Output:**
```
[ConflictDetector] Cannot detect conflicts: Not synchronized or offline
```

### Scenario 2: Firmware Too Old

**Condition:** Firmware version < 1.10 (no SD card support)

**Behavior:**
1. SD card fetch throws exception (SysEx command not supported)
2. Exception is caught in try-catch block
3. `sdCardFiles` remains empty list
4. `FileConflictDetector.detectConflicts()` called with empty list
5. No conflicts detected (cannot match against empty list)
6. Installation proceeds with no conflict warnings

**Debug Output:**
```
[PresetBrowserDialog] Could not fetch SD card files: <error message>
```

### Scenario 3: Directory Listing Failure

**Condition:** Individual directory requests fail during conflict detection

**Behavior:**
1. `_getExistingFilesInDirectory()` catches exception
2. Returns empty `Set<String>` for that directory
3. No conflicts detected for files in that directory
4. Other directories continue to be checked
5. Partial conflict detection completes successfully

**Debug Output:**
```
[ConflictDetector] Error listing directory /presets: <error message>
```

### Scenario 4: Complete Conflict Detection Failure

**Condition:** Unexpected error during conflict detection

**Behavior:**
1. Top-level try-catch in `detectConflicts()` catches exception
2. Error logged with stack trace
3. Original analysis returned unchanged
4. Installation proceeds with no conflict warnings

**Debug Output:**
```
[ConflictDetector] Error during conflict detection: <error>
<stack trace>
```

---

## Reference Implementation

**File:** `/Users/nealsanche/nosuch/nt_helper/lib/ui/widgets/load_preset_dialog.dart`
**Lines:** 613-617

```dart
// Detect file conflicts
final conflictDetector = FileConflictDetector(widget.distingCubit);
final analysisWithConflicts = await conflictDetector.detectConflicts(
  analysis,
);
```

**Key Differences from Story Spec:**

1. **Static vs Instance Method:**
   - Story spec shows: `FileConflictDetector.detectConflicts(analysis, sdCardFiles)` (static)
   - Actual implementation: `conflictDetector.detectConflicts(analysis)` (instance)
   - The instance method fetches directory listings internally

2. **Directory Listing API:**
   - Story spec mentions: `distingCubit.fetchSdCardDirectoryListing('/')`
   - This method does not exist in current codebase
   - `FileConflictDetector` uses `disting.requestDirectoryListing()` internally

3. **Implementation Approach:**
   - Follow the reference implementation pattern (instance method)
   - Do not manually fetch directory listings
   - Let `FileConflictDetector` handle all SD card communication

---

## Testing Strategy

### Test Package

**Location:** `/Users/nealsanche/nosuch/nt_helper/docs/7s and 11s_package.zip`

### Test Scenarios

1. **No Conflicts (Fresh Installation)**
   - Drop package on clean SD card
   - Verify all `hasConflict` flags are `false`
   - Verify `conflictCount == 0`

2. **Full Conflicts (Re-installation)**
   - Install package once
   - Drop same package again
   - Verify all `hasConflict` flags are `true`
   - Verify `conflictCount == totalFiles`

3. **Partial Conflicts**
   - Install package
   - Manually delete some files from SD card
   - Drop package again
   - Verify some `hasConflict` flags are `true`, others `false`

4. **Offline Mode**
   - Go offline (disconnect device)
   - Drop package
   - Verify analysis completes successfully
   - Verify `conflictCount == 0` (no conflicts detected)

5. **Old Firmware**
   - Connect to device with firmware < 1.10
   - Drop package
   - Verify error is caught gracefully
   - Verify installation proceeds

---

## Verification Checklist

- [ ] Required imports added to `preset_browser_dialog.dart`
- [ ] Conflict detection code added after package analysis
- [ ] State check includes `is DistingStateSynchronized` and `!state.offline`
- [ ] SD card fetch wrapped in try-catch
- [ ] `FileConflictDetector` instance created with `widget.distingCubit`
- [ ] Updated analysis stored in `_currentAnalysis` state variable
- [ ] Debug logging includes conflict count
- [ ] Offline mode proceeds without error
- [ ] Old firmware proceeds without error
- [ ] Test with sample package shows correct conflict detection
- [ ] `flutter analyze` passes with zero warnings

---

## Next Story

**E3.4:** Display Package Install Dialog with Conflict Resolution
- Uses `analysisWithConflicts` from this story
- Shows `PackageInstallDialog` with conflict indicators
- Handles user resolution choices (install/skip/overwrite)
