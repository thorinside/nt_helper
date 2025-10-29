# Epic 3: Drag-and-Drop Preset Package Installation - Technical Context

**Generated:** 2025-10-28
**Epic:** 3
**Status:** Ready for Story Development

---

## Epic Overview

**Goal:** Restore drag-and-drop preset package installation feature to the Browse Presets dialog by migrating the working implementation from the obsolete LoadPresetDialog.

**Value:** Desktop users can install community preset packages efficiently with visual feedback, manifest validation, conflict detection, and granular file control.

---

## Technical Context

### Existing Infrastructure (All Components Already Exist)

**Services:**
- `lib/services/preset_package_analyzer.dart` - Analyzes .zip packages, validates manifest.json
- `lib/services/file_conflict_detector.dart` - Compares package files against SD card listings
- `lib/services/package_creator.dart` - Not used for installation, but part of ecosystem

**Models:**
- `lib/models/package_analysis.dart` - Package metadata, file list, conflict status
- `lib/models/package_file.dart` - Individual file in package with conflict flags
- `lib/models/package_config.dart` - Configuration data

**UI Components:**
- `lib/ui/widgets/package_install_dialog.dart` - Full conflict resolution UI (complete implementation)
- `lib/ui/widgets/preset_package_dialog.dart` - Simpler package info display
- `lib/ui/widgets/load_preset_dialog.dart` - **REFERENCE IMPLEMENTATION** with working drag-drop code
- `lib/ui/widgets/preset_browser_dialog.dart` - **TARGET** for migration

**Dependencies (Already in pubspec.yaml):**
- `desktop_drop: ^0.4.4` - DropTarget widget and XFile handling
- `cross_file: ^0.3.3+5` - Cross-platform file abstraction
- `archive: ^3.4.9` - Zip file extraction

---

## Reference Implementations

The codebase has **THREE existing drag-and-drop patterns** to follow:

### 1. LoadPresetDialog (Original - To be migrated)
**File:** `lib/ui/widgets/load_preset_dialog.dart`
- Complete working implementation for preset packages
- Contains all handler methods we need
- Will be deleted after migration (Story E3.7)

**Key Methods to Reference:**
- `_handleDragEntered(details)` - Sets `_isDragOver = true`
- `_handleDragExited(details)` - Sets `_isDragOver = false`
- `_handleDragDone(DropDoneDetails details)` - Complete drop handling (lines ~370-450)
- `_buildDragOverlay()` - Semi-transparent blue overlay with drop icon

### 2. GalleryScreen (Active - Plugin Installation)
**File:** `lib/ui/gallery_screen.dart`
- Shows established pattern for wrapping entire screens
- Uses same platform check and Stack pattern

### 3. FileParameterEditor (Active - Lua Scripts)
**File:** `lib/ui/widgets/file_parameter_editor.dart`
- Shows pattern for wrapping individual widgets
- Conditional DropTarget wrapper

---

## Established Platform Check Pattern

All three implementations use this exact pattern:

```dart
// Build content first
Widget content = AlertDialog(...);

// Only add drag and drop on desktop platforms
if (!kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.linux)) {
  return DropTarget(
    onDragDone: _handleDragDone,
    onDragEntered: _handleDragEntered,
    onDragExited: _handleDragExited,
    child: Stack(
      children: [
        content,
        if (_isDragOver) _buildDragOverlay(),
        if (_isInstalling) _buildInstallOverlay(),
      ],
    ),
  );
}

return content;
```

**Key Points:**
- No conditional imports needed - `desktop_drop` works on all platforms
- Platform check wraps the widget, not the imports
- Use `defaultTargetPlatform` from `package:flutter/foundation.dart`
- Stack overlays for visual feedback

---

## Drop Handling Flow (From LoadPresetDialog)

### Step 1: File Drop
```dart
void _handleDragDone(DropDoneDetails details) async {
  setState(() {
    _isDragOver = false;
    _isInstallingPackage = true;
  });

  try {
    final files = details.files;

    // Filter for .zip files only
    final zipFiles = files.where((f) => f.path.endsWith('.zip')).toList();

    if (zipFiles.isEmpty) {
      _showError('Please drop a .zip preset package file');
      return;
    }

    if (zipFiles.length > 1) {
      _showError('Please drop only one package at a time');
      return;
    }

    final file = zipFiles.first;
    final bytes = await file.readAsBytes();

    // Continue to Step 2...
  } finally {
    if (mounted) {
      setState(() => _isInstallingPackage = false);
    }
  }
}
```

### Step 2: Package Analysis
```dart
// Analyze package
final analysis = await PresetPackageAnalyzer.analyzePackage(bytes);

if (!analysis.isValid) {
  _showError('Invalid package: ${analysis.errorMessage}');
  return;
}
```

### Step 3: Conflict Detection
```dart
// Fetch SD card files for conflict detection
final state = widget.distingCubit.state;
List<DirectoryEntry> sdCardFiles = [];

if (state is DistingStateSynchronized && !state.offline) {
  try {
    sdCardFiles = await widget.distingCubit.fetchSdCardDirectoryListing('/');
  } catch (e) {
    debugPrint('Could not fetch SD card files: $e');
    // Continue without conflict detection
  }
}

// Detect conflicts
final analysisWithConflicts = FileConflictDetector.detectConflicts(
  analysis,
  sdCardFiles,
);
```

### Step 4: Show Install Dialog
```dart
if (!mounted) return;

await showDialog(
  context: context,
  builder: (context) => PackageInstallDialog(
    analysis: analysisWithConflicts,
    packageData: bytes,
    distingCubit: widget.distingCubit,
    onInstall: () {
      Navigator.of(context).pop();
      // Refresh Browse Presets listing
      context.read<PresetBrowserCubit>().loadRootDirectory();
    },
    onCancel: () {
      Navigator.of(context).pop();
    },
  ),
);
```

**PackageInstallDialog handles:**
- Displaying package metadata and file list
- Conflict indicators
- Bulk actions (Install All, Skip All, Overwrite All)
- Per-file actions
- Installation loop with progress tracking
- Error handling

---

## Target Integration Point

**File to Modify:** `lib/ui/widgets/preset_browser_dialog.dart`

**Current Structure:**
```dart
class PresetBrowserDialog extends StatefulWidget {
  final DistingCubit distingCubit;
  // ...
}

class _PresetBrowserDialogState extends State<PresetBrowserDialog> {
  @override
  Widget build(BuildContext context) {
    // ...
    return AlertDialog(
      title: Row(...),
      content: SizedBox(...),
      actions: [...],
    );
  }
}
```

**Required Changes:**
1. Add state variables: `_isDragOver`, `_isInstallingPackage`
2. Add imports for drag-drop components
3. Restructure build() to return content variable first
4. Wrap with platform-conditional DropTarget
5. Add handler methods copied from LoadPresetDialog
6. Add overlay builder methods

**Access to DistingCubit:**
- Already available via `widget.distingCubit` (passed in constructor)

**Access to PresetBrowserCubit:**
- Available via `context.read<PresetBrowserCubit>()` for refreshing after install

---

## State Management Context

**DistingCubit Responsibilities:**
- `fetchSdCardDirectoryListing(path)` - Gets SD card files for conflict detection
- `writeSdCardFile(path, bytes)` - Writes individual files during installation
- State provides firmware version and offline status

**PresetBrowserCubit Responsibilities:**
- `loadRootDirectory()` - Refreshes preset listing after installation
- Manages current directory navigation state

---

## Package Format

```
package.zip
├── manifest.json          # Required: Package metadata
└── root/                  # Required: Files to install
    ├── presets/
    │   └── my_preset.json
    └── samples/
        └── sample.wav
```

**manifest.json Structure:**
```json
{
  "preset": {
    "filename": "my_preset_package",
    "name": "My Preset Collection",
    "author": "Artist Name",
    "version": "1.0"
  }
}
```

**Installation:** All files under `root/` are installed to SD card root, preserving directory structure.

---

## Testing Resources

**Sample Package:** `docs/7s and 11s_package.zip` (added in commit b589e37)

---

## Story Implementation Notes

### E3.1: Visual Feedback
- Copy platform check pattern exactly
- Add state variables and imports
- Implement simple drag enter/exit handlers
- Build drag overlay (semi-transparent blue with icon)

### E3.2: Drop Handling & Analysis
- Copy `_handleDragDone` from LoadPresetDialog
- File filtering (.zip only)
- Convert XFile to Uint8List
- Call PresetPackageAnalyzer
- Store results in state

### E3.3: Conflict Detection
- Check firmware version and offline status
- Fetch SD card files via DistingCubit
- Call FileConflictDetector
- Handle offline gracefully

### E3.4: Install Dialog
- Show PackageInstallDialog (already complete)
- Pass analysis, bytes, DistingCubit
- Wire up onInstall callback to refresh listing
- Wire up onCancel callback

### E3.5: Verification
- PackageInstallDialog handles all installation logic
- Test with sample package
- Verify progress tracking
- Verify error handling

### E3.6: Cross-Platform
- Verify platform check from E3.1 works
- Test builds on desktop and mobile
- Confirm no runtime errors

### E3.7: Cleanup
- Extract PresetAction enum to `lib/models/preset_action.dart`
- Update imports in preset_browser_dialog.dart
- Delete load_preset_dialog.dart
- Verify no remaining references

---

## Risk Mitigation

**Risks:**
- Platform fragmentation → Mitigated: Using established pattern from 2 active implementations
- Desktop_drop compatibility → Mitigated: Package already in use, version pinned
- SD card failures → Mitigated: Graceful degradation in offline mode

**Performance:**
- Large packages → Show loading indicator during analysis
- Slow writes → PackageInstallDialog has progress tracking

---

## Success Criteria

1. ✅ Drag-drop works on desktop (Windows, macOS, Linux)
2. ✅ Visual feedback matches existing patterns
3. ✅ Package analysis validates manifest
4. ✅ Conflict detection works when online
5. ✅ Installation progress tracked per-file
6. ✅ Mobile/web builds succeed without errors
7. ✅ LoadPresetDialog successfully removed
8. ✅ `flutter analyze` passes with zero warnings

---

## References

- Original implementation: commit 1183117
- UI consolidation: commit b589e37
- Full epic spec: `docs/epic-3-drag-drop-preset-packages.md`
- Epic stories: `docs/epics.md` (Epic 3 section)
