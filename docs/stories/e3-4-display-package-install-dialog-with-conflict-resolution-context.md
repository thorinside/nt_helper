# Story E3.4 Context: Display Package Install Dialog with Conflict Resolution

**Epic:** 3 - Drag-and-Drop Preset Package Installation
**Story ID:** e3-4-display-package-install-dialog-with-conflict-resolution
**Generated:** 2025-10-28

---

## Overview

This story integrates the existing `PackageInstallDialog` into the `PresetBrowserDialog` drag-drop flow. The dialog is **fully implemented** and handles all conflict resolution UI - this story only needs to **display it** at the right time.

---

## Implementation Details

### Target File

**File:** `/Users/nealsanche/nosuch/nt_helper/lib/ui/widgets/preset_browser_dialog.dart`

### Required Imports

Add these imports to `preset_browser_dialog.dart`:

```dart
import 'package:nt_helper/ui/widgets/package_install_dialog.dart';
import 'package:nt_helper/models/package_analysis.dart';
```

### State Variables

The `_PresetBrowserDialogState` class needs to track the current package being processed:

```dart
class _PresetBrowserDialogState extends State<PresetBrowserDialog> {
  // ... existing state ...

  // Add these for package installation
  PackageAnalysis? _currentAnalysis;
  Uint8List? _currentPackageData;

  // ... rest of existing code ...
}
```

### Integration Point

After conflict detection completes in `_handleDragDone()` (from Story E3.3), add this dialog display logic:

```dart
// Store analysis and package data in state
setState(() {
  _currentAnalysis = analysisWithConflicts;
  _currentPackageData = bytes;
});

if (!mounted) return;

// Show install dialog
await showDialog(
  context: context,
  barrierDismissible: false,
  builder: (context) => PackageInstallDialog(
    analysis: _currentAnalysis!,
    packageData: _currentPackageData!,
    distingCubit: widget.distingCubit,
    onInstall: () {
      Navigator.of(context).pop();
      // Refresh the preset browser listing
      context.read<PresetBrowserCubit>().loadRootDirectory();
      debugPrint('[PresetBrowserDialog] Package installed, refreshing listing');
    },
    onCancel: () {
      Navigator.of(context).pop();
      debugPrint('[PresetBrowserDialog] Package installation canceled');
    },
  ),
);

// Clear state after dialog closes
setState(() {
  _currentAnalysis = null;
  _currentPackageData = null;
});
```

---

## PackageInstallDialog Capabilities (Reference)

The `PackageInstallDialog` already implements:

### Package Metadata Display
- Package name (`analysis.presetName`)
- Author (`analysis.author`)
- Version (`analysis.version`)
- Total file count (`analysis.totalFiles`)
- Conflict count (`analysis.conflictCount`)

### File List
- Scrollable list grouped by directory
- Conflict indicators (red text for files with conflicts)
- File size display
- Target path display

### Bulk Actions
```dart
ActionChip(
  label: const Text('Install All'),
  onPressed: () => _setActionForAllFiles(FileAction.install),
)

ActionChip(
  label: const Text('Skip Conflicts'),
  onPressed: () => _setActionForConflicts(FileAction.skip),
)

ActionChip(
  label: const Text('Skip All'),
  onPressed: () => _setActionForAllFiles(FileAction.skip),
)
```

### Per-File Actions
For each conflicted file:
- **Install** button (green when active)
- **Skip** button (red when active)

### Button States
- **Install** button: Enabled when `analysis.installCount > 0`, disabled during installation
- **Cancel** button: Disabled during installation
- Dialog remains open until user action (not dismissible via barrier)

---

## Testing Checklist

### Visual Verification
- [ ] Dialog displays after conflict detection completes
- [ ] Package metadata shows correctly (name, author, version, file count)
- [ ] File list is scrollable and grouped by directory
- [ ] Conflict indicators appear in red for conflicted files
- [ ] Bulk action buttons are visible and labeled correctly
- [ ] Per-file action buttons appear for conflicted files

### Interaction Verification
- [ ] "Install All" button sets all files to install
- [ ] "Skip Conflicts" button sets only conflicted files to skip
- [ ] "Skip All" button sets all files to skip
- [ ] Per-file "Install" button toggles file to install
- [ ] Per-file "Skip" button toggles file to skip
- [ ] Install button enables/disables based on selection
- [ ] Cancel button closes dialog without installing

### State Management
- [ ] `_currentAnalysis` and `_currentPackageData` stored correctly
- [ ] State cleared after dialog closes
- [ ] No memory leaks or dangling references

### Error Handling
- [ ] Dialog handles mounted check correctly
- [ ] No crashes on rapid user interactions
- [ ] Proper cleanup on error conditions

---

## Integration Points

### DistingCubit Access
The dialog needs `widget.distingCubit` which is already available in `PresetBrowserDialog`:

```dart
class PresetBrowserDialog extends StatefulWidget {
  final DistingCubit distingCubit;
  // ...
}
```

Pass it directly to `PackageInstallDialog` constructor.

### PresetBrowserCubit Access
After successful installation, refresh the listing:

```dart
onInstall: () {
  Navigator.of(context).pop();
  context.read<PresetBrowserCubit>().loadRootDirectory();
  debugPrint('[PresetBrowserDialog] Package installed, refreshing listing');
}
```

This ensures the Browse Presets dialog shows the newly installed files.

---

## Code Examples

### Full _handleDragDone Integration

```dart
void _handleDragDone(DropDoneDetails details) async {
  setState(() {
    _isDragOver = false;
    _isInstallingPackage = true;
  });

  try {
    // Step 1: File validation and reading (from E3.2)
    final files = details.files;
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

    // Step 2: Package analysis (from E3.2)
    final analysis = await PresetPackageAnalyzer.analyzePackage(bytes);

    if (!analysis.isValid) {
      _showError('Invalid package: ${analysis.errorMessage}');
      return;
    }

    // Step 3: Conflict detection (from E3.3)
    final state = widget.distingCubit.state;
    List<DirectoryEntry> sdCardFiles = [];

    if (state is DistingStateSynchronized && !state.offline) {
      try {
        sdCardFiles = await widget.distingCubit.fetchSdCardDirectoryListing('/');
      } catch (e) {
        debugPrint('Could not fetch SD card files: $e');
      }
    }

    final analysisWithConflicts = FileConflictDetector.detectConflicts(
      analysis,
      sdCardFiles,
    );

    // Step 4: Show install dialog (THIS STORY - E3.4)
    setState(() {
      _currentAnalysis = analysisWithConflicts;
      _currentPackageData = bytes;
    });

    if (!mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PackageInstallDialog(
        analysis: _currentAnalysis!,
        packageData: _currentPackageData!,
        distingCubit: widget.distingCubit,
        onInstall: () {
          Navigator.of(context).pop();
          context.read<PresetBrowserCubit>().loadRootDirectory();
          debugPrint('[PresetBrowserDialog] Package installed, refreshing listing');
        },
        onCancel: () {
          Navigator.of(context).pop();
          debugPrint('[PresetBrowserDialog] Package installation canceled');
        },
      ),
    );

    // Clear state after dialog closes
    setState(() {
      _currentAnalysis = null;
      _currentPackageData = null;
    });

  } finally {
    if (mounted) {
      setState(() => _isInstallingPackage = false);
    }
  }
}
```

---

## Acceptance Criteria Mapping

| Criteria | Implementation |
|----------|----------------|
| 1. Show dialog after conflict detection | `showDialog()` called after `FileConflictDetector.detectConflicts()` |
| 2. Dialog receives correct parameters | Pass `analysis`, `packageData`, `distingCubit` |
| 3. Display package metadata | `PackageInstallDialog._buildPackageInfo()` handles this |
| 4. Scrollable file list with conflicts | `PackageInstallDialog._buildFileList()` handles this |
| 5. Bulk actions | `PackageInstallDialog._buildActionButtons()` provides all actions |
| 6. Per-file actions | `PackageInstallDialog._buildFileItem()` provides per-file UI |
| 7. Install button enabled when selection valid | `_currentAnalysis.installCount > 0` check in build |
| 8. Cancel button dismisses dialog | `onCancel` callback calls `Navigator.pop()` |
| 9. Dialog remains open until action | `barrierDismissible: false` |
| 10. `flutter analyze` passes | Run after implementation |

---

## Testing with Sample Package

**Sample Package:** `/Users/nealsanche/nosuch/nt_helper/docs/7s and 11s_package.zip`

### Manual Test Steps

1. **Build and run the app:**
   ```bash
   flutter run -d macos
   ```

2. **Open Browse Presets dialog:**
   - Navigate to main screen
   - Click "Browse Presets" button

3. **Drag and drop sample package:**
   - Drag `7s and 11s_package.zip` onto the dialog
   - Verify drag overlay appears
   - Drop the file

4. **Verify PackageInstallDialog displays:**
   - Package name: "7s and 11s"
   - Author should be shown
   - File count should match package contents
   - File list should be visible and scrollable

5. **Interact with conflict resolution (if any conflicts exist):**
   - Click bulk action buttons
   - Toggle per-file actions
   - Verify Install button enables/disables correctly

6. **Cancel the dialog:**
   - Click Cancel
   - Verify dialog closes
   - Verify preset browser remains open

7. **Repeat and complete installation:**
   - Drag package again
   - Click Install
   - Verify progress tracking (Story E3.5 handles this)

---

## Dependencies

### From Previous Stories
- **E3.1**: Platform-conditional DropTarget wrapper
- **E3.2**: Package analysis with `PresetPackageAnalyzer`
- **E3.3**: Conflict detection with `FileConflictDetector`

### Existing Components
- **PackageInstallDialog**: Fully implemented in `/Users/nealsanche/nosuch/nt_helper/lib/ui/widgets/package_install_dialog.dart`
- **DistingCubit**: Provides SD card access
- **PresetBrowserCubit**: Manages preset listing state

---

## Notes

- **No new UI development needed** - `PackageInstallDialog` is complete
- This story is purely about **integration** and **wiring**
- Story E3.5 will verify the installation functionality works end-to-end
- Keep state management simple: store analysis and package data, clear after dialog closes
- Always check `mounted` before calling `setState()` after async operations

---

## References

- **Story File:** `/Users/nealsanche/nosuch/nt_helper/docs/stories/e3-4-display-package-install-dialog-with-conflict-resolution.md`
- **Epic Context:** `/Users/nealsanche/nosuch/nt_helper/docs/epic-3-context.md`
- **PackageInstallDialog:** `/Users/nealsanche/nosuch/nt_helper/lib/ui/widgets/package_install_dialog.dart`
- **PresetBrowserDialog:** `/Users/nealsanche/nosuch/nt_helper/lib/ui/widgets/preset_browser_dialog.dart`
- **Sample Package:** `/Users/nealsanche/nosuch/nt_helper/docs/7s and 11s_package.zip`
