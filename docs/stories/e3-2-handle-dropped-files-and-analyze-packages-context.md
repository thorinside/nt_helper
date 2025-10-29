# Story E3.2: Handle Dropped Files and Analyze Packages - Context Document

**Epic:** 3 - Drag-and-Drop Preset Package Installation
**Story ID:** e3-2-handle-dropped-files-and-analyze-packages
**Generated:** 2025-10-28
**Status:** Ready for Implementation

---

## Purpose

This document provides detailed implementation context for Story E3.2, including complete reference implementations, API documentation, data models, error scenarios, and testing guidance.

---

## Table of Contents

1. [Reference Implementation](#reference-implementation)
2. [PresetPackageAnalyzer API](#presetpackageanalyzer-api)
3. [PackageAnalysis Model](#packageanalysis-model)
4. [PackageFile Model](#packagefile-model)
5. [Error Scenarios](#error-scenarios)
6. [Debug Logging Patterns](#debug-logging-patterns)
7. [Testing Scenarios](#testing-scenarios)

---

## Reference Implementation

### Complete _handleDragDone Implementation

**Source:** `/Users/nealsanche/nosuch/nt_helper/lib/ui/widgets/load_preset_dialog.dart` (lines 535-576)

This is the exact implementation pattern to follow for PresetBrowserDialog:

```dart
void _handleDragDone(DropDoneDetails details) {
  setState(() {
    _isDragOver = false;
  });

  // Filter for supported files (zip packages or json presets)
  final supportedFiles = details.files.where((file) {
    final lowerPath = file.path.toLowerCase();
    return lowerPath.endsWith('.zip') || lowerPath.endsWith('.json');
  }).toList();

  if (supportedFiles.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Please drop a preset package (.zip) or preset file (.json)',
        ),
        backgroundColor: Colors.orange,
      ),
    );
    return;
  }

  if (supportedFiles.length > 1) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Please drop only one file at a time'),
        backgroundColor: Colors.orange,
      ),
    );
    return;
  }

  final file = supportedFiles.first;
  if (file.path.toLowerCase().endsWith('.zip')) {
    // Process as package
    _processPackageFile(file);
  } else if (file.path.toLowerCase().endsWith('.json')) {
    // Process as single preset
    _processPresetFile(file);
  }
}
```

### Package Processing Implementation

**Source:** `/Users/nealsanche/nosuch/nt_helper/lib/ui/widgets/load_preset_dialog.dart` (lines 578-654)

**Scope Note:** For E3.2, we only implement package analysis. File conflict detection (E3.3) and the PackageInstallDialog (E3.4) come later. This story ends after storing the analysis results.

```dart
Future<void> _processPackageFile(XFile file) async {
  setState(() {
    _isInstallingPackage = true;
  });

  try {
    debugPrint('[PresetBrowserDialog] Analyzing package: ${file.path}');

    // Read file data
    final fileBytes = await file.readAsBytes();
    debugPrint('[PresetBrowserDialog] Package size: ${fileBytes.length} bytes');

    // Validate and analyze the package
    final isValid = await PresetPackageAnalyzer.isValidPackage(fileBytes);
    if (!isValid) {
      setState(() {
        _isInstallingPackage = false;
      });
      _showValidationErrorDialog(
        'Invalid Package Format',
        'The dropped file is not a valid preset package. Please ensure it contains a manifest.json file and a root/ directory with the preset files.',
      );
      return;
    }

    // Analyze the package
    final analysis = await PresetPackageAnalyzer.analyzePackage(fileBytes);
    if (!analysis.isValid) {
      setState(() {
        _isInstallingPackage = false;
      });
      _showValidationErrorDialog(
        'Package Analysis Failed',
        analysis.errorMessage ?? 'Unable to analyze the package contents.',
      );
      return;
    }

    debugPrint('[PresetBrowserDialog] Package analyzed: ${analysis.packageName}');
    debugPrint('[PresetBrowserDialog] Files in package: ${analysis.files.length}');

    // Store analysis results and package data
    setState(() {
      _currentAnalysis = analysis;
      _currentPackageData = fileBytes;
    });

    debugPrint('[PresetBrowserDialog] Package analysis complete, ready for conflict detection');

    // Story E3.3 will continue with conflict detection here

  } catch (e, stackTrace) {
    debugPrint('[PresetBrowserDialog] Error processing package: $e');
    debugPrintStack(stackTrace: stackTrace);

    setState(() {
      _isInstallingPackage = false;
    });

    _showValidationErrorDialog(
      'Package Processing Error',
      'An unexpected error occurred while processing the package:\n\n$e',
    );
  } finally {
    if (mounted) {
      setState(() {
        _isInstallingPackage = false;
      });
    }
  }
}
```

### Error Dialog Helper

**Source:** `/Users/nealsanche/nosuch/nt_helper/lib/ui/widgets/load_preset_dialog.dart` (lines 753-775)

```dart
void _showValidationErrorDialog(String title, String message) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Row(
        children: [
          Icon(Icons.error, color: Theme.of(context).colorScheme.error),
          const SizedBox(width: 8),
          Expanded(child: Text(title)),
        ],
      ),
      content: SingleChildScrollView(
        child: Text(message, style: Theme.of(context).textTheme.bodyMedium),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}
```

### Required State Variables

Add to `_PresetBrowserDialogState`:

```dart
class _PresetBrowserDialogState extends State<PresetBrowserDialog> {
  bool _isDragOver = false;
  bool _isInstallingPackage = false;

  // Add these for E3.2:
  PackageAnalysis? _currentAnalysis;
  Uint8List? _currentPackageData;

  // ... existing state variables
}
```

### Required Imports

Add to the top of `preset_browser_dialog.dart`:

```dart
import 'dart:typed_data';
import 'package:cross_file/cross_file.dart';
import 'package:nt_helper/services/preset_package_analyzer.dart';
import 'package:nt_helper/models/package_analysis.dart';
```

---

## PresetPackageAnalyzer API

**Source:** `/Users/nealsanche/nosuch/nt_helper/lib/services/preset_package_analyzer.dart`

### analyzePackage()

**Signature:**
```dart
static Future<PackageAnalysis> analyzePackage(Uint8List zipBytes) async
```

**Purpose:** Analyzes a zip file and extracts package metadata and file listing.

**Process:**
1. Decodes the zip archive using `ZipDecoder().decodeBytes()`
2. Finds and parses `manifest.json` (required)
3. Extracts package metadata from `manifest['preset']`:
   - `filename` → packageName
   - `name` → presetName
   - `author` → author
   - `version` → version
4. Scans `root/` directory for files to install
5. Creates `PackageFile` objects for each file
6. Returns `PackageAnalysis` with `isValid: true` on success

**Error Handling:**
- Missing manifest.json → throws Exception
- Invalid JSON → throws Exception (caught)
- Corrupt zip → throws Exception (caught)
- All exceptions caught and returned as `PackageAnalysis.invalid()`

**Returns:**
- Success: `PackageAnalysis` with `isValid: true`
- Failure: `PackageAnalysis.invalid(errorMessage: '...')`

**Debug Output:**
```
[PackageAnalyzer] Starting package analysis...
[PackageAnalyzer] Decoded archive with N files
[PackageAnalyzer] Found and parsed manifest
[PackageAnalyzer] Found N files in root/ directory
[PackageAnalyzer] Created N package file entries
```

**Example Usage:**
```dart
final analysis = await PresetPackageAnalyzer.analyzePackage(fileBytes);
if (!analysis.isValid) {
  // Show error: analysis.errorMessage
  return;
}
// Continue with analysis.packageName, analysis.files, etc.
```

---

### isValidPackage()

**Signature:**
```dart
static Future<bool> isValidPackage(Uint8List zipBytes) async
```

**Purpose:** Quick validation check before full analysis.

**Checks:**
- Can decode as zip archive
- Contains `manifest.json` file
- Contains at least one file in `root/` directory

**Returns:**
- `true` if structure is valid
- `false` if validation fails or exception occurs

**Example Usage:**
```dart
final isValid = await PresetPackageAnalyzer.isValidPackage(fileBytes);
if (!isValid) {
  _showError('Invalid package structure');
  return;
}
```

---

### extractFile()

**Signature:**
```dart
static Future<Uint8List?> extractFile(Uint8List zipBytes, String filePath) async
```

**Purpose:** Extract specific file content from the package.

**Parameters:**
- `zipBytes`: Package zip file bytes
- `filePath`: Path within zip (e.g., "root/presets/my_preset.json")

**Returns:**
- `Uint8List` of file content on success
- `null` if file not found or error occurs

**Note:** Not used in E3.2, but available for future stories.

---

### Utility Methods

**getFilesForDirectory():**
```dart
static List<PackageFile> getFilesForDirectory(
  PackageAnalysis analysis,
  String directory,
)
```
Returns all files that target a specific directory (e.g., "presets", "samples").

**getDirectorySummary():**
```dart
static Map<String, int> getDirectorySummary(PackageAnalysis analysis)
```
Returns a map of directory names to file counts (e.g., `{"presets": 3, "samples": 5}`).

---

## PackageAnalysis Model

**Source:** `/Users/nealsanche/nosuch/nt_helper/lib/models/package_analysis.dart`

### Fields

```dart
class PackageAnalysis {
  final String packageName;       // From manifest preset.filename
  final String presetName;        // From manifest preset.name
  final String author;            // From manifest preset.author
  final String version;           // From manifest preset.version
  final List<PackageFile> files;  // Files in root/ directory
  final Map<String, dynamic> manifest;  // Full manifest JSON
  final bool isValid;             // Analysis success flag
  final String? errorMessage;     // Error details if invalid
}
```

### Constructors

**Normal Constructor:**
```dart
const PackageAnalysis({
  required this.packageName,
  required this.presetName,
  required this.author,
  required this.version,
  required this.files,
  required this.manifest,
  required this.isValid,
  this.errorMessage,
});
```

**Invalid Constructor:**
```dart
const PackageAnalysis.invalid({required this.errorMessage})
```
Creates an invalid analysis with all fields set to empty/false.

### Computed Properties

```dart
int get totalFiles => files.length;
int get conflictCount => files.where((f) => f.hasConflict).length;
int get installCount => files.where((f) => f.shouldInstall).length;
int get skipCount => files.where((f) => f.shouldSkip).length;
bool get hasConflicts => conflictCount > 0;
bool get canInstall => isValid && files.isNotEmpty;
Map<String, List<PackageFile>> get filesByDirectory { ... }
```

**Note for E3.2:**
- `hasConflict` will always be false (conflict detection is Story E3.3)
- `shouldInstall` and `shouldSkip` are not set yet (Story E3.4)
- Use `totalFiles` and `isValid` to verify analysis worked

### Methods

**copyWith():**
```dart
PackageAnalysis copyWith({List<PackageFile>? files})
```
Creates a copy with updated files list. Used by FileConflictDetector (E3.3).

---

## PackageFile Model

**Source:** `/Users/nealsanche/nosuch/nt_helper/lib/models/package_file.dart` (not shown but referenced)

### Fields

```dart
class PackageFile {
  final String relativePath;  // Path within zip (e.g., "root/presets/my_preset.json")
  final String targetPath;    // Install path on SD card (e.g., "presets/my_preset.json")
  final int size;             // File size in bytes
  final bool hasConflict;     // Set by FileConflictDetector (E3.3)

  // Action flags (set by PackageInstallDialog in E3.4):
  bool shouldInstall;
  bool shouldSkip;
}
```

### Constructor

```dart
PackageFile({
  required this.relativePath,
  required this.targetPath,
  required this.size,
  required this.hasConflict,
  this.shouldInstall = true,   // Default: install
  this.shouldSkip = false,     // Default: don't skip
});
```

---

## Error Scenarios

### 1. Invalid File Type

**Trigger:** User drops a file that is not `.zip` or `.json`

**Detection:** File extension check in `_handleDragDone()`

**Response:**
```dart
ScaffoldMessenger.of(context).showSnackBar(
  const SnackBar(
    content: Text(
      'Please drop a preset package (.zip) or preset file (.json)',
    ),
    backgroundColor: Colors.orange,
  ),
);
```

**User Action:** Drop a valid file type

---

### 2. Multiple Files Dropped

**Trigger:** User drops 2+ files at once

**Detection:** `supportedFiles.length > 1` check

**Response:**
```dart
ScaffoldMessenger.of(context).showSnackBar(
  const SnackBar(
    content: Text('Please drop only one file at a time'),
    backgroundColor: Colors.orange,
  ),
);
```

**User Action:** Drop files one at a time

---

### 3. Invalid Package Structure

**Trigger:** Zip file missing `manifest.json` or `root/` directory

**Detection:** `PresetPackageAnalyzer.isValidPackage()` returns false

**Response:**
```dart
_showValidationErrorDialog(
  'Invalid Package Format',
  'The dropped file is not a valid preset package. Please ensure it contains a manifest.json file and a root/ directory with the preset files.',
);
```

**User Action:** Use a properly structured package

**Expected Package Structure:**
```
package.zip
├── manifest.json
└── root/
    ├── presets/...
    └── samples/...
```

---

### 4. Corrupt or Invalid Manifest

**Trigger:** `manifest.json` exists but is not valid JSON

**Detection:** JSON parsing exception in `analyzePackage()`

**Response:**
```dart
_showValidationErrorDialog(
  'Package Analysis Failed',
  analysis.errorMessage ?? 'Unable to analyze the package contents.',
);
```

**Example Error Message:** "Failed to analyze package: FormatException: Unexpected character..."

**User Action:** Fix manifest JSON or use different package

---

### 5. Corrupt Zip File

**Trigger:** File has `.zip` extension but is not a valid zip archive

**Detection:** `ZipDecoder().decodeBytes()` throws exception

**Response:**
```dart
_showValidationErrorDialog(
  'Package Processing Error',
  'An unexpected error occurred while processing the package:\n\n$e',
);
```

**Example Error Message:** "ArchiveException: Invalid or unsupported archive format"

**User Action:** Use a valid zip file

---

### 6. Empty Package

**Trigger:** Package has valid structure but no files in `root/`

**Detection:** `analysis.files.isEmpty` after parsing

**Behavior:** Analysis succeeds with `isValid: true` but `totalFiles: 0`

**Note:** This is technically valid but unusual. PackageInstallDialog (E3.4) will handle this case.

---

### 7. Large Files / Memory Issues

**Trigger:** Very large package causes memory issues

**Detection:** Exception during `readAsBytes()` or zip decoding

**Response:** Standard error dialog with exception message

**Mitigation:**
- Show progress indicator during analysis (`_isInstallingPackage = true`)
- Graceful error handling with stack traces logged

---

## Debug Logging Patterns

### Required Debug Statements

Follow this exact pattern for Story E3.2:

```dart
// On drop start
debugPrint('[PresetBrowserDialog] Analyzing package: ${file.path}');

// After reading file
debugPrint('[PresetBrowserDialog] Package size: ${fileBytes.length} bytes');

// After successful analysis
debugPrint('[PresetBrowserDialog] Package analyzed: ${analysis.packageName}');
debugPrint('[PresetBrowserDialog] Files in package: ${analysis.files.length}');

// Ready for next story
debugPrint('[PresetBrowserDialog] Package analysis complete, ready for conflict detection');

// On error
debugPrint('[PresetBrowserDialog] Error processing package: $e');
debugPrintStack(stackTrace: stackTrace);
```

### Analyzer Service Logs

You will also see these from `PresetPackageAnalyzer`:

```
[PackageAnalyzer] Starting package analysis...
[PackageAnalyzer] Decoded archive with 8 files
[PackageAnalyzer] Found and parsed manifest
[PackageAnalyzer] Found 5 files in root/ directory
[PackageAnalyzer] Created 5 package file entries
```

### Log Prefix Convention

- `[PresetBrowserDialog]` - UI component logs
- `[PackageAnalyzer]` - Service logs
- `[FileConflictDetector]` - Conflict detection logs (E3.3)

---

## Testing Scenarios

### Scenario 1: Valid Package - Happy Path

**Test File:** `/Users/nealsanche/nosuch/nt_helper/docs/7s and 11s_package.zip`

**Steps:**
1. Open Browse Presets dialog
2. Drag and drop `7s and 11s_package.zip` onto dialog
3. Observe progress indicator appears briefly
4. Verify no errors displayed

**Expected Console Output:**
```
[PresetBrowserDialog] Analyzing package: /path/to/7s and 11s_package.zip
[PresetBrowserDialog] Package size: XXXXX bytes
[PackageAnalyzer] Starting package analysis...
[PackageAnalyzer] Decoded archive with 8 files
[PackageAnalyzer] Found and parsed manifest
[PackageAnalyzer] Found 5 files in root/ directory
[PackageAnalyzer] Created 5 package file entries
[PresetBrowserDialog] Package analyzed: 7s_and_11s
[PresetBrowserDialog] Files in package: 5
[PresetBrowserDialog] Package analysis complete, ready for conflict detection
```

**Expected State After:**
- `_currentAnalysis` is not null
- `_currentAnalysis.isValid` is true
- `_currentAnalysis.packageName` is "7s_and_11s"
- `_currentAnalysis.files.length` is 5
- `_currentPackageData` contains the zip bytes
- `_isInstallingPackage` is false
- No dialog shown (waiting for E3.3)

**Success Criteria:**
- No errors or exceptions
- Progress indicator appears and disappears
- State variables populated correctly

---

### Scenario 2: Invalid File Type

**Steps:**
1. Create a text file: `test.txt`
2. Drag and drop onto dialog

**Expected Behavior:**
- Orange snackbar appears with message: "Please drop a preset package (.zip) or preset file (.json)"
- No progress indicator
- No state changes

**Console Output:** None (early return before processing)

---

### Scenario 3: Multiple Files

**Steps:**
1. Select 2 .zip files
2. Drag and drop both onto dialog

**Expected Behavior:**
- Orange snackbar appears with message: "Please drop only one file at a time"
- No progress indicator
- No state changes

**Console Output:** None (early return before processing)

---

### Scenario 4: Invalid Package Structure

**Steps:**
1. Create a .zip file without `manifest.json`:
   ```
   invalid_package.zip
   └── some_file.json
   ```
2. Drag and drop onto dialog

**Expected Behavior:**
- Progress indicator appears briefly
- Error dialog appears:
  - Title: "Invalid Package Format" (with error icon)
  - Message: "The dropped file is not a valid preset package..."
- State variables not updated

**Console Output:**
```
[PresetBrowserDialog] Analyzing package: /path/to/invalid_package.zip
[PresetBrowserDialog] Package size: XXXX bytes
[PackageAnalyzer] Package validation failed: Exception: manifest.json not found in package
```

---

### Scenario 5: Corrupt Manifest JSON

**Steps:**
1. Create a .zip package with invalid JSON in manifest.json:
   ```
   corrupt_manifest.zip
   ├── manifest.json (contains: { invalid json )
   └── root/
       └── presets/test.json
   ```
2. Drag and drop onto dialog

**Expected Behavior:**
- Progress indicator appears briefly
- Error dialog appears:
  - Title: "Package Analysis Failed" (with error icon)
  - Message: "Unable to analyze the package contents" or specific JSON error
- State variables not updated

**Console Output:**
```
[PresetBrowserDialog] Analyzing package: /path/to/corrupt_manifest.zip
[PresetBrowserDialog] Package size: XXXX bytes
[PackageAnalyzer] Starting package analysis...
[PackageAnalyzer] Decoded archive with 2 files
[PackageAnalyzer] Error analyzing package: FormatException: Unexpected character (at character 1)
[PackageAnalyzer] <stack trace>
```

---

### Scenario 6: Corrupt Zip File

**Steps:**
1. Create a text file and rename to `.zip`:
   ```bash
   echo "not a zip file" > fake_package.zip
   ```
2. Drag and drop onto dialog

**Expected Behavior:**
- Progress indicator appears briefly
- Error dialog appears:
  - Title: "Package Processing Error" (with error icon)
  - Message: "An unexpected error occurred while processing the package:\n\n<exception details>"
- State variables not updated

**Console Output:**
```
[PresetBrowserDialog] Analyzing package: /path/to/fake_package.zip
[PresetBrowserDialog] Package size: 16 bytes
[PackageAnalyzer] Package validation failed: ArchiveException: Invalid or unsupported archive format
[PresetBrowserDialog] Error processing package: ArchiveException: Invalid or unsupported archive format
[PresetBrowserDialog] <stack trace>
```

---

### Scenario 7: Empty Package (Edge Case)

**Steps:**
1. Create a valid package with no files in `root/`:
   ```
   empty_package.zip
   ├── manifest.json (valid)
   └── root/ (empty directory)
   ```
2. Drag and drop onto dialog

**Expected Behavior:**
- Progress indicator appears briefly
- Analysis succeeds (no error dialog)
- State variables updated with empty files list

**Console Output:**
```
[PresetBrowserDialog] Analyzing package: /path/to/empty_package.zip
[PresetBrowserDialog] Package size: XXX bytes
[PackageAnalyzer] Starting package analysis...
[PackageAnalyzer] Decoded archive with 1 files
[PackageAnalyzer] Found and parsed manifest
[PackageAnalyzer] Found 0 files in root/ directory
[PackageAnalyzer] Created 0 package file entries
[PresetBrowserDialog] Package analyzed: <package name>
[PresetBrowserDialog] Files in package: 0
[PresetBrowserDialog] Package analysis complete, ready for conflict detection
```

**Note:** PackageInstallDialog (E3.4) will handle this edge case.

---

### Scenario 8: Very Large Package (Performance Test)

**Steps:**
1. Create a package with many files or large files (e.g., 50+ MB)
2. Drag and drop onto dialog

**Expected Behavior:**
- Progress indicator appears and remains visible during analysis
- Analysis may take several seconds
- No timeout or crash
- Eventually succeeds or fails gracefully

**Performance Notes:**
- `readAsBytes()` is async and non-blocking
- `ZipDecoder().decodeBytes()` runs synchronously but should complete
- Monitor for memory issues on low-end devices

---

## Verification Checklist

After implementing E3.2, verify:

- [ ] All test scenarios pass as described
- [ ] Console output matches expected patterns
- [ ] No `flutter analyze` warnings
- [ ] Progress indicator appears/disappears correctly
- [ ] Error dialogs are user-friendly and actionable
- [ ] State variables populated on success
- [ ] State variables NOT populated on failure
- [ ] No crashes or unhandled exceptions
- [ ] Memory cleaned up properly (no leaks)
- [ ] Works on macOS, Linux, and Windows (if available)

---

## Next Story Integration Points

### Story E3.3 Will Add:

Conflict detection after successful analysis:

```dart
// After this line:
debugPrint('[PresetBrowserDialog] Package analysis complete, ready for conflict detection');

// E3.3 will add:
final conflictDetector = FileConflictDetector(widget.distingCubit);
final analysisWithConflicts = await conflictDetector.detectConflicts(analysis);

setState(() {
  _currentAnalysis = analysisWithConflicts;
});
```

### Story E3.4 Will Add:

Show PackageInstallDialog after conflict detection:

```dart
// After conflict detection completes:
if (!mounted) return;

await showDialog(
  context: context,
  builder: (context) => PackageInstallDialog(
    analysis: _currentAnalysis!,
    packageData: _currentPackageData!,
    distingCubit: widget.distingCubit,
    onInstall: () { ... },
    onCancel: () { ... },
  ),
);
```

---

## Related Files

**Target File:**
- `/Users/nealsanche/nosuch/nt_helper/lib/ui/widgets/preset_browser_dialog.dart`

**Reference Files:**
- `/Users/nealsanche/nosuch/nt_helper/lib/ui/widgets/load_preset_dialog.dart`
- `/Users/nealsanche/nosuch/nt_helper/lib/services/preset_package_analyzer.dart`
- `/Users/nealsanche/nosuch/nt_helper/lib/models/package_analysis.dart`
- `/Users/nealsanche/nosuch/nt_helper/lib/models/package_file.dart`

**Test Resource:**
- `/Users/nealsanche/nosuch/nt_helper/docs/7s and 11s_package.zip`

**Documentation:**
- `/Users/nealsanche/nosuch/nt_helper/docs/stories/e3-2-handle-dropped-files-and-analyze-packages.md` (Story)
- `/Users/nealsanche/nosuch/nt_helper/docs/epic-3-context.md` (Epic Context)
- `/Users/nealsanche/nosuch/nt_helper/docs/epic-3-drag-drop-preset-packages.md` (Epic Spec)

---

## Summary

This story implements the core drop handling and package analysis logic. The implementation:

1. Accepts dropped files and filters for `.zip` packages
2. Validates single file drops only
3. Reads file bytes asynchronously
4. Validates package structure
5. Analyzes package metadata and file list
6. Stores results in state for next story
7. Shows user-friendly errors for all failure cases
8. Provides debug logging for troubleshooting

The implementation is a direct migration from LoadPresetDialog's proven pattern, with Story E3.2 stopping after analysis. Stories E3.3 and E3.4 will add conflict detection and installation UI.

---

**End of Context Document**
