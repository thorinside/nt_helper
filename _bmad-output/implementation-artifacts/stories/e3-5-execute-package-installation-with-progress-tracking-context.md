# Story E3.5 Context: Execute Package Installation with Progress Tracking

**Epic:** 3 - Drag-and-Drop Preset Package Installation
**Story ID:** e3-5-execute-package-installation-with-progress-tracking
**Generated:** 2025-10-28

---

## Overview

This story is **verification-focused** because `PackageInstallDialog` already implements the complete installation loop with progress tracking. The implementation was completed in previous work. This story ensures the installation works correctly end-to-end.

---

## What PackageInstallDialog Already Implements

### File Extraction & Installation Loop

Located in `/Users/nealsanche/nosuch/nt_helper/lib/ui/widgets/package_install_dialog.dart`:

```dart
void _handleInstall() async {
  setState(() {
    _isInstalling = true;
    _totalFiles = _currentAnalysis.installCount;
    _completedFiles = 0;
    _currentFile = '';
    _errors.clear();
  });

  try {
    // Extract file data from package
    final fileData = await _extractFileData();

    // Install files using DistingCubit
    await widget.distingCubit.installPackageFiles(
      _currentAnalysis.files,
      fileData,
      onFileStart: (fileName, completed, total) {
        setState(() {
          _currentFile = fileName;
          _completedFiles = completed - 1; // completed is 1-based
        });
      },
      onFileComplete: (fileName) {
        setState(() {
          _completedFiles++;
        });
      },
      onFileError: (fileName, error) {
        setState(() {
          _errors.add('$fileName: $error');
          _isInstalling = false;
        });
      },
    );

    setState(() {
      _isInstalling = false;
    });

    // Check for errors
    if (_errors.isNotEmpty) {
      _showErrorDialog();
    } else {
      widget.onInstall?.call();
    }
  } catch (e) {
    setState(() {
      _isInstalling = false;
      _errors.add('Installation failed: $e');
    });
    _showErrorDialog();
  }
}
```

### Progress Tracking UI

```dart
if (_isInstalling) ...[
  const SizedBox(height: 16),
  const LinearProgressIndicator(),
  const SizedBox(height: 8),
  Text(
    _currentFile.isNotEmpty
        ? 'Installing: $_currentFile ($_completedFiles/$_totalFiles)'
        : 'Preparing installation...',
    style: const TextStyle(fontSize: 12),
  ),
]
```

### Error Handling

```dart
void _showErrorDialog() {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Row(
        children: [
          Icon(Icons.error, color: Theme.of(context).colorScheme.error),
          const SizedBox(width: 8),
          const Text('Installation Errors'),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('The following errors occurred during installation:'),
            const SizedBox(height: 16),
            // Scrollable error list
            Container(
              constraints: const BoxConstraints(maxHeight: 300),
              child: Scrollbar(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _errors.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.close, size: 16, color: Theme.of(context).colorScheme.error),
                          const SizedBox(width: 8),
                          Expanded(child: Text(_errors[index])),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Successfully installed: $_completedFiles of $_totalFiles files'),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(); // Close error dialog
            Navigator.of(context).pop(); // Close package dialog
            Navigator.of(context).pop(); // Close load preset dialog
          },
          child: const Text('Close'),
        ),
      ],
    ),
  );
}
```

### Button State Management

```dart
actions: [
  TextButton(
    onPressed: _isInstalling ? null : () => widget.onCancel?.call(),
    child: const Text('Cancel'),
  ),
  ElevatedButton(
    onPressed: _isInstalling || _currentAnalysis.installCount == 0
        ? null
        : _handleInstall,
    child: Text('Install ${_currentAnalysis.installCount} Files'),
  ),
]
```

---

## Verification Tasks

### 1. Successful Installation Test

**Objective:** Verify complete installation flow works correctly.

**Steps:**
1. Build and run the application:
   ```bash
   flutter run -d macos
   ```

2. Open Browse Presets dialog

3. Drag and drop sample package:
   - File: `/Users/nealsanche/nosuch/nt_helper/docs/7s and 11s_package.zip`

4. In PackageInstallDialog:
   - Click "Install All" (or leave default selections)
   - Click "Install" button

5. **Verify progress tracking:**
   - [ ] Linear progress bar appears
   - [ ] Current file name displays
   - [ ] Completed count updates (e.g., "1/5", "2/5", etc.)
   - [ ] Total count matches selected files
   - [ ] Progress updates smoothly

6. **Verify completion:**
   - [ ] Dialog auto-closes on success
   - [ ] Browse Presets listing refreshes
   - [ ] Newly installed files appear in listing
   - [ ] No error messages

### 2. Button State Test

**Objective:** Verify buttons disable during installation.

**Steps:**
1. Drop sample package
2. Click "Install" button
3. **During installation:**
   - [ ] Install button is disabled (grayed out)
   - [ ] Cancel button is disabled (grayed out)
   - [ ] Dialog is not dismissible via barrier click
   - [ ] User cannot close dialog prematurely

4. **After installation:**
   - [ ] Dialog closes automatically (on success)
   - [ ] OR buttons re-enable (on error, allowing retry)

### 3. Error Handling Test

**Objective:** Verify error handling displays correctly.

**Testing Scenarios:**

#### Scenario A: Simulated SD Card Failure
If possible, test with hardware disconnected or in offline mode:

1. Ensure device is offline or SD card unavailable
2. Drop package and attempt installation
3. **Verify error handling:**
   - [ ] Progress stops at failed file
   - [ ] Error summary dialog appears
   - [ ] Error messages list all failed files
   - [ ] Success count shows partial installation
   - [ ] User can close error dialog
   - [ ] Main dialog remains open for retry

#### Scenario B: Invalid Package Data
This may require modified test package (optional):

1. Test with corrupted or invalid package file
2. **Verify error handling:**
   - [ ] Error caught during file extraction
   - [ ] Error dialog shows general failure message
   - [ ] User can close and retry

### 4. Large Package Test

**Objective:** Verify progress tracking with many files.

**Steps:**
1. If available, test with package containing 20+ files
2. **Verify progress updates:**
   - [ ] Progress bar increments smoothly
   - [ ] File names update for each file
   - [ ] Count updates correctly (1/23, 2/23, etc.)
   - [ ] No UI freezing or lag
   - [ ] Responsive during entire installation

### 5. Browse Presets Refresh Test

**Objective:** Verify preset listing refreshes after installation.

**Steps:**
1. Note current preset listing state before installation
2. Install package with new presets
3. **Verify refresh:**
   - [ ] `PresetBrowserCubit.loadRootDirectory()` called
   - [ ] Preset listing updates automatically
   - [ ] New files appear in correct directories
   - [ ] User doesn't need to manually refresh

---

## Testing Checklist Summary

### Installation Flow
- [ ] Install button triggers installation loop
- [ ] Files extracted from zip correctly
- [ ] Each file written to SD card via `distingCubit.writeSdCardFile()`
- [ ] Progress indicator shows current file name
- [ ] Progress indicator shows completed count
- [ ] Progress indicator shows total count
- [ ] Linear progress bar updates

### Error Handling
- [ ] Write failures logged but installation continues
- [ ] Error summary displayed at end
- [ ] Failed file names listed
- [ ] Partial success count shown
- [ ] User can acknowledge errors

### Success Path
- [ ] Success message shown (or silent success with auto-close)
- [ ] Dialog auto-closes on complete success
- [ ] Browse Presets listing refreshes
- [ ] No errors or warnings in console

### Button States
- [ ] Install button disabled during installation
- [ ] Cancel button disabled during installation
- [ ] Dialog not dismissible during installation
- [ ] Buttons re-enable on error (for retry)

### Code Quality
- [ ] No `flutter analyze` warnings
- [ ] No console errors during installation
- [ ] Proper use of `debugPrint()` for logging
- [ ] Mounted checks before `setState()`

---

## Key Implementation Details (Reference)

### DistingCubit.installPackageFiles()

The installation logic delegates to `DistingCubit`:

```dart
await widget.distingCubit.installPackageFiles(
  _currentAnalysis.files,  // List<PackageFile>
  fileData,                // Map<String, Uint8List>
  onFileStart: (fileName, completed, total) {
    // Called before writing each file
  },
  onFileComplete: (fileName) {
    // Called after successfully writing each file
  },
  onFileError: (fileName, error) {
    // Called if file write fails
  },
);
```

### File Extraction

```dart
Future<Map<String, Uint8List>> _extractFileData() async {
  final fileData = <String, Uint8List>{};

  try {
    for (final file in _currentAnalysis.files) {
      if (file.shouldInstall) {
        final data = await PresetPackageAnalyzer.extractFile(
          widget.packageData,
          file.relativePath,
        );
        if (data != null) {
          fileData[file.relativePath] = data;
        }
      }
    }
  } catch (e) {
    throw Exception('Failed to extract files from package: $e');
  }

  return fileData;
}
```

### Progress State Variables

```dart
class _PackageInstallDialogState extends State<PackageInstallDialog> {
  bool _isInstalling = false;
  String _currentFile = '';
  int _completedFiles = 0;
  int _totalFiles = 0;
  final List<String> _errors = [];
  // ...
}
```

---

## Acceptance Criteria Verification

| Criteria | How to Verify |
|----------|---------------|
| 1. Install button triggers loop | Click Install, observe progress starts |
| 2. For each file, calls `writeSdCardFile()` | Check debug logs for write operations |
| 3. Progress shows current file name | Observe "_currentFile" updates in UI |
| 4. Progress shows completed/total count | Observe "5/12" style counter updates |
| 5. Linear progress bar updates | Watch progress bar fill during installation |
| 6. Failures logged but continue | Simulate failure, verify others install |
| 7. Error summary if failures | Check error dialog lists failed files |
| 8. Success message if all succeed | Verify dialog closes or shows success |
| 9. Install button disabled | Try clicking during install (should be disabled) |
| 10. Cancel button disabled | Try clicking during install (should be disabled) |
| 11. Dialog auto-closes on success | Verify dialog disappears after completion |
| 12. Browse Presets refreshes | Verify new files appear in listing |
| 13. `flutter analyze` passes | Run `flutter analyze` |

---

## Debug Output to Monitor

During testing, watch for these debug prints:

```
[PresetBrowserDialog] Package installed, refreshing listing
[PackageInstallDialog] Starting installation of X files
[DistingCubit] Writing file: /path/to/file.ext
[DistingCubit] File write complete: /path/to/file.ext
[PresetBrowserCubit] Loading root directory
```

---

## Sample Test Session

### Console Commands

```bash
# Start app with Dart Tooling Daemon for MCP
flutter run -d macos --print-dtd

# In another terminal, watch for errors
flutter analyze

# Run tests if any exist for package installation
flutter test --name package
```

### Expected User Experience

1. **Drag package file** → Visual feedback (blue overlay)
2. **Drop package** → Analysis progress (brief)
3. **View conflicts** → PackageInstallDialog appears
4. **Click Install** → Progress starts immediately
5. **Watch progress** → File names and counts update
6. **Wait for completion** → Dialog closes automatically
7. **Verify files** → Browse Presets shows new files

### Expected Timeline
- Analysis: < 1 second
- Installation: ~0.5 seconds per file (varies by size)
- Refresh: < 1 second

---

## Notes

- **No code changes expected** - This is pure verification
- If bugs are found, they should be fixed in `PackageInstallDialog` directly
- Focus on user experience: smooth progress, clear feedback, graceful errors
- Test with both small packages (few files) and larger packages (20+ files)
- Verify memory usage remains stable during installation
- Check that concurrent operations don't interfere (unlikely but test anyway)

---

## Follow-Up Actions

After verification completes:

1. **Document any bugs found** in the story file
2. **Fix critical bugs immediately** before moving to E3.6
3. **Note performance issues** for future optimization
4. **Update acceptance criteria** if any were incorrect
5. **Capture screenshots** of successful installation for documentation

---

## References

- **Story File:** `/Users/nealsanche/nosuch/nt_helper/docs/stories/e3-5-execute-package-installation-with-progress-tracking.md`
- **Epic Context:** `/Users/nealsanche/nosuch/nt_helper/docs/epic-3-context.md`
- **PackageInstallDialog:** `/Users/nealsanche/nosuch/nt_helper/lib/ui/widgets/package_install_dialog.dart`
- **DistingCubit:** `/Users/nealsanche/nosuch/nt_helper/lib/cubit/disting_cubit.dart`
- **Sample Package:** `/Users/nealsanche/nosuch/nt_helper/docs/7s and 11s_package.zip`
- **Previous Story:** E3.4 - Display Package Install Dialog
- **Next Story:** E3.6 - Verify Cross-Platform Compatibility
