# Epic 3: Drag-and-Drop Preset Package Installation

**Author:** Neal
**Date:** 2025-10-28
**Status:** Draft
**Epic ID:** 3

---

## Overview

This epic restores the drag-and-drop preset package installation feature that was lost during the UI consolidation in commit b589e37. The original implementation (commit 1183117) allowed users to drag .zip preset packages or .json preset files directly onto the Load Preset dialog on desktop platforms (Windows, macOS, Linux). The feature included sophisticated package analysis, manifest validation, file conflict detection, and a resolution UI that enabled users to selectively install files with proper conflict handling.

When the Load Preset dialog was refactored and the Browse Presets dialog became the primary interface, this drag-and-drop capability was not migrated to the new dialog, leaving users without the convenient desktop installation workflow.

**Value Proposition:**

Desktop users need an efficient workflow for installing preset packages from the community. Drag-and-drop installation eliminates the need for manual file extraction and copying, provides visual feedback on package contents, detects conflicts with existing SD card files, and gives users control over which files to install. This is particularly valuable for managing large preset libraries and avoiding accidental overwrites of custom presets.

---

## Objectives and Scope

**In Scope:**
- Add drag-and-drop zone to Browse Presets dialog for .zip packages and .json presets
- Integrate existing `PresetPackageAnalyzer` service to parse dropped packages
- Integrate existing `FileConflictDetector` service to identify SD card conflicts
- Integrate existing `PackageInstallDialog` widget for conflict resolution UI
- Support desktop platforms only (Windows, macOS, Linux) using `desktop_drop` package
- Provide visual feedback during drag-over state
- Show error dialogs for invalid packages or analysis failures
- Maintain compatibility with existing package format (manifest.json in root)

**Out of Scope:**
- Mobile platform support (no native drag-and-drop on iOS/Android)
- Drag-and-drop for algorithm (.so/.dll) files (different installation path)
- Package creation or export features (already exist separately)
- Network-based package downloads or package repository browsing
- Migration of old Load Preset dialog code (use Browse Presets as new home)

---

## System Architecture Alignment

This epic leverages existing infrastructure that was preserved during the UI refactoring:

**Existing Services (No Changes Required):**
- `lib/services/preset_package_analyzer.dart` - Analyzes .zip packages, extracts manifest.json, validates structure
- `lib/services/file_conflict_detector.dart` - Compares package files against SD card directory listings
- `lib/services/package_creator.dart` - Not used for installation, but part of package ecosystem

**Existing Models (No Changes Required):**
- `lib/models/package_analysis.dart` - Contains package metadata, file list, conflict status
- `lib/models/package_file.dart` - Represents individual files in package with conflict flags
- `lib/models/package_config.dart` - Configuration data (not directly used in drag-drop flow)

**Existing UI Components (No Changes Required):**
- `lib/ui/widgets/package_install_dialog.dart` - Full-featured conflict resolution UI with per-file actions
- `lib/ui/widgets/preset_package_dialog.dart` - Simpler package info display (alternative UI)

**Component to Modify:**
- `lib/ui/widgets/preset_browser_dialog.dart` - Add `DropTarget` wrapper and drop handling logic

**Dependencies:**
- `desktop_drop: ^0.4.4` (already in pubspec.yaml)
- `cross_file: ^0.3.3+5` (already in pubspec.yaml, provides XFile abstraction)
- `archive: ^3.4.9` (already in pubspec.yaml, used by PresetPackageAnalyzer)

**Architectural Patterns:**
- Drag-and-drop wraps the existing dialog content with `DropTarget` widget
- Drop handler converts XFile → Uint8List → PresetPackageAnalyzer
- FileConflictDetector queries DistingCubit for current SD card file listings
- PackageInstallDialog coordinates installation using DistingCubit's writeSdCardFile method
- All installation operations go through DistingCubit to maintain state consistency

---

## Technical Background

### Existing Drag-and-Drop Implementations

The codebase has THREE existing drag-and-drop implementations that establish the pattern to follow:

1. **`lib/ui/widgets/load_preset_dialog.dart`** (Original implementation from commit 1183117)
   - Still exists with full drag-and-drop functionality for preset packages
   - No longer used (replaced by PresetBrowserDialog)
   - Contains all the handler code we need to migrate

2. **`lib/ui/gallery_screen.dart`** (Plugin installation)
   - Active drag-and-drop for installing plugin .so/.dll files
   - Shows the established pattern for wrapping entire screens

3. **`lib/ui/widgets/file_parameter_editor.dart`** (Lua script development)
   - Active drag-and-drop for uploading Lua scripts
   - Shows pattern for wrapping individual widgets

The established pattern wraps the entire dialog/screen with platform-conditional DropTarget:

```dart
// Build the main content first
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

This pattern:
- Builds content first as a regular widget
- Conditionally wraps with DropTarget only on desktop platforms
- Uses Stack to overlay visual feedback during drag operations
- Uses separate handler methods for each drag event

### File Handling Flow

1. **Drop Detection**: `DropTarget.onDragDone` receives `List<XFile>`
2. **File Filtering**: Accept only `.zip` or `.json` extensions
3. **Data Loading**: Convert `XFile` to `Uint8List` via `file.readAsBytes()`
4. **Package Analysis**: Call `PresetPackageAnalyzer.analyzePackage(bytes)`
5. **Conflict Detection**: Call `FileConflictDetector.detectConflicts(analysis, sdCardFiles)`
6. **UI Presentation**: Show `PackageInstallDialog` with analyzed package
7. **Installation**: Dialog uses `DistingCubit.writeSdCardFile()` for each selected file
8. **Progress Tracking**: Dialog shows per-file progress and error handling

### SD Card File Access

The conflict detection requires current SD card file listings from the hardware:

```dart
final state = distingCubit.state;
if (state is DistingStateSynchronized && !state.offline) {
  final sdCardFiles = await distingCubit.fetchSdCardDirectoryListing('/');
  // sdCardFiles contains all files on SD card for conflict checking
}
```

---

## Story Breakdown

### Story E3.1: Integrate DropTarget into Browse Presets Dialog

As a desktop user of the Browse Presets dialog,
I want to drag a preset package .zip file onto the dialog window,
So that I can see visual feedback indicating the drop zone is active.

**Acceptance Criteria:**
1. `preset_browser_dialog.dart` imports `desktop_drop` package at top (no conditional import needed)
2. State variable `_isDragOver` tracks drag-enter/drag-exit events
3. State variable `_isInstallingPackage` tracks installation in progress
4. Build method creates `content` variable with existing AlertDialog
5. After building content, wrap with platform check following established pattern:
   ```dart
   if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.windows ||
       defaultTargetPlatform == TargetPlatform.macOS ||
       defaultTargetPlatform == TargetPlatform.linux))
   ```
6. Return `DropTarget` wrapping `Stack([content, if (_isDragOver) _buildDragOverlay()])`
7. Implement `_handleDragEntered` to set `_isDragOver = true`
8. Implement `_handleDragExited` to set `_isDragOver = false`
9. Stub out `_handleDragDone` (no functionality yet)
10. Implement `_buildDragOverlay()` showing semi-transparent blue overlay with drop icon
11. `flutter analyze` passes with zero warnings

**Prerequisites:** None

**Technical Notes:**
- Follow exact pattern from `gallery_screen.dart` and `load_preset_dialog.dart`
- Use `defaultTargetPlatform` from `package:flutter/foundation.dart`
- The imports are not conditional - only the DropTarget wrapping is conditional
- Visual feedback should match existing overlays in gallery_screen.dart

---

### Story E3.2: Handle Dropped Files and Analyze Packages

As a desktop user dropping a preset package onto the Browse Presets dialog,
I want the application to analyze the package contents and validate the manifest,
So that I can see what files will be installed and detect any errors early.

**Acceptance Criteria:**
1. Implement `_handleDragDone(DropDoneDetails details)` handler
2. Extract `List<XFile>` from `details.files`
3. Handler filters files to accept only `.zip` and `.json` extensions
4. Handler shows error dialog if no valid files found or multiple files dropped
5. For valid .zip file, handler converts XFile to `Uint8List` via `readAsBytes()`
6. Handler calls `PresetPackageAnalyzer.analyzePackage(bytes)` and awaits result
7. If analysis fails, show error dialog with exception message
8. If analysis succeeds, store `PackageAnalysis` result and `Uint8List` in state variables
9. Set `_isInstallingPackage = true` during analysis, show overlay via `_buildInstallOverlay()`
10. `flutter analyze` passes with zero warnings

**Prerequisites:** Story E3.1

**Technical Notes:**
- Reference `load_preset_dialog.dart` `_handleDragDone` method for implementation pattern
- Use try/catch around analysis to handle corrupt zips gracefully
- `PresetPackageAnalyzer` already validates manifest.json structure
- For .json files, scope is out - only handle .zip packages for this epic
- Store both `PackageAnalysis` and raw `Uint8List` - needed for Story E3.5 installation

---

### Story E3.3: Detect File Conflicts with SD Card

As a user installing a preset package,
I want the application to check if package files already exist on the SD card,
So that I can avoid accidentally overwriting my custom presets.

**Acceptance Criteria:**
1. After successful package analysis, handler calls `distingCubit.fetchSdCardDirectoryListing('/')`
2. Handler passes directory listing to `FileConflictDetector.detectConflicts(analysis, sdCardFiles)`
3. `FileConflictDetector` updates each `PackageFile.hasConflict` flag based on path matching
4. Updated `PackageAnalysis` with conflict flags stored in state
5. If SD card fetch fails (offline mode, firmware version too old), proceed with no conflicts detected
6. Error dialog shown if SD card communication fails unexpectedly
7. `flutter analyze` passes with zero warnings

**Prerequisites:** Story E3.2

**Technical Notes:**
- Reference `load_preset_dialog.dart` `_handleDragDone` for conflict detection integration
- `FileConflictDetector` compares `PackageFile.targetPath` against SD card file paths
- Conflict detection is case-sensitive (SD card filesystem is case-sensitive)
- Offline mode should gracefully skip conflict detection (user warned in install dialog)
- Firmware versions before 1.10 lack SD card listing support
- Access DistingCubit via `widget.distingCubit` passed to PresetBrowserDialog constructor

---

### Story E3.4: Display Package Install Dialog with Conflict Resolution

As a user reviewing a dropped preset package,
I want to see the package contents, file conflicts, and choose which files to install,
So that I have full control over the installation process.

**Acceptance Criteria:**
1. After conflict detection completes, handler shows `PackageInstallDialog` as modal
2. Dialog receives: `PackageAnalysis`, original package `Uint8List`, `DistingCubit` reference
3. Dialog displays package metadata: name, author, version, file count, conflict count
4. Dialog shows scrollable file list with conflict indicators (red text for conflicts)
5. Dialog provides bulk actions: "Overwrite All Conflicts", "Skip All Conflicts", "Install All"
6. Dialog provides per-file actions: Install, Skip, Overwrite (for conflicted files)
7. Install button enabled only when at least one file marked for installation
8. Cancel button dismisses dialog without installing
9. Dialog remains open until user clicks Install or Cancel
10. `flutter analyze` passes with zero warnings

**Prerequisites:** Story E3.3

**Technical Notes:**
- Reference `load_preset_dialog.dart` `_handleDragDone` for how to show PackageInstallDialog
- `PackageInstallDialog` already exists with full implementation in `lib/ui/widgets/package_install_dialog.dart`
- Use `showDialog(context: context, builder: ...)` to display as modal
- Pass `onInstall` callback to close dialog and refresh Browse Presets listing via PresetBrowserCubit
- Pass `onCancel` callback to close dialog without action
- Dialog manages its own action state (which files to install/skip)

---

### Story E3.5: Execute Package Installation with Progress Tracking

As a user clicking "Install" in the package install dialog,
I want to see progress as each file is written to the SD card,
So that I know the installation is working and can identify any failures.

**Acceptance Criteria:**
1. Install button triggers file-by-file installation loop
2. For each file marked for installation, dialog calls `distingCubit.writeSdCardFile(targetPath, bytes)`
3. Progress indicator shows: current file name, completed count, total count
4. Linear progress bar updates as files complete
5. If any file write fails, error is logged but installation continues
6. Error summary displayed at end if any files failed (file names listed)
7. Success message shown if all files installed successfully
8. Install button disabled during installation (prevent double-clicks)
9. Cancel button disabled during installation
10. Dialog auto-closes on success or remains open on errors (user must acknowledge)
11. Browse Presets listing refreshes after successful installation
12. `flutter analyze` passes with zero warnings

**Prerequisites:** Story E3.4

**Technical Notes:**
- `PackageInstallDialog` already implements entire installation loop with error handling
- Story E3.4 already passed the `Uint8List packageData` to PackageInstallDialog
- PackageInstallDialog uses `archive` package to extract file bytes from .zip
- PackageInstallDialog calls `distingCubit.writeSdCardFile()` for each file
- This story is verification/testing only - no new code needed beyond Story E3.4
- Test with the sample package at `docs/7s and 11s_package.zip` (added in commit b589e37)

---

### Story E3.6: Verify Cross-Platform Compatibility

As a developer maintaining cross-platform compatibility,
I want drag-and-drop to compile on all platforms but only activate on desktop,
So that mobile builds don't break.

**Acceptance Criteria:**
1. Platform check using `!kIsWeb && (defaultTargetPlatform == ...)` is in place from Story E3.1
2. On mobile/web platforms, dialog renders without `DropTarget` (no drag-drop capability)
3. On desktop platforms, dialog renders with full drag-drop support
4. No runtime errors on any platform when opening Browse Presets dialog
5. `flutter analyze` passes with zero warnings
6. Build succeeds for: `flutter build apk`, `flutter build macos`
7. Manual testing confirms drag-and-drop works on macOS

**Prerequisites:** Story E3.5

**Technical Notes:**
- No conditional imports needed - `desktop_drop` package works on all platforms
- Platform check wraps the DropTarget widget, not the imports
- This follows established pattern from `gallery_screen.dart` and `file_parameter_editor.dart`
- On non-desktop platforms, the code simply returns `content` without DropTarget wrapper

---

### Story E3.7: Remove Obsolete LoadPresetDialog

As a developer maintaining code quality,
I want to remove the obsolete LoadPresetDialog widget and enum,
So that we don't maintain duplicate, unused code.

**Acceptance Criteria:**
1. Move `PresetAction` enum from `load_preset_dialog.dart` to its own file `lib/models/preset_action.dart`
2. Update import in `preset_browser_dialog.dart` to reference new location
3. Delete `lib/ui/widgets/load_preset_dialog.dart` entirely
4. Search codebase for any remaining references to `LoadPresetDialog` widget
5. Remove any unused imports or references found
6. `flutter analyze` passes with zero warnings
7. All tests pass
8. Build succeeds for desktop and mobile platforms

**Prerequisites:** Story E3.6

**Technical Notes:**
- `PresetAction` enum is still used by `PresetBrowserDialog` for load/append/export actions
- Ensure no other files reference `LoadPresetDialog` widget before deletion
- Use grep to verify: `grep -r "LoadPresetDialog" lib/ test/`
- This completes the migration from old Load Preset dialog to Browse Presets dialog

---

## Story Guidelines Reference

**Story Format:**

```
**Story [EPIC.N]: [Story Title]**

As a [user type],
I want [goal/desire],
So that [benefit/value].

**Acceptance Criteria:**
1. [Specific testable criterion]
2. [Another specific criterion]
3. [etc.]

**Prerequisites:** [Dependencies on previous stories, if any]
```

**Story Requirements:**

- **Vertical slices** - Complete, testable functionality delivery
- **Sequential ordering** - Logical progression within epic
- **No forward dependencies** - Only depend on previous work
- **AI-agent sized** - Completable in 2-4 hour focused session
- **Value-focused** - Integrate technical enablers into value-delivering stories

---

## Testing Strategy

**Unit Tests:**
- Test package analysis with valid and invalid .zip files
- Test conflict detection with various SD card file scenarios
- Test file filtering logic (accept .zip/.json, reject others)

**Widget Tests:**
- Test drag-over visual feedback appears and disappears correctly
- Test error dialogs shown for invalid packages
- Test PackageInstallDialog integration with mock DistingCubit

**Integration Tests:**
- Test full drop-to-install flow with mock hardware responses
- Test offline mode gracefully skips conflict detection
- Test multi-file package installation with progress tracking

**Manual Testing:**
- Test on all desktop platforms: Windows, macOS, Linux
- Test with real preset packages from community
- Test with corrupted .zip files
- Test with packages containing conflicting files
- Test with very large packages (50+ files)
- Test canceling during installation

---

## Risk Assessment

**Technical Risks:**
- **Platform fragmentation**: Conditional imports must work correctly on all platforms
  - *Mitigation*: Test builds on all platforms, use established stub file pattern
- **Desktop_drop package compatibility**: Package may have breaking changes in future versions
  - *Mitigation*: Pin to tested version in pubspec.yaml, monitor package updates
- **SD card read failures**: Conflict detection depends on hardware communication
  - *Mitigation*: Gracefully degrade to no-conflict mode in offline/error cases

**UX Risks:**
- **Hidden feature**: Users may not discover drag-and-drop capability
  - *Mitigation*: Add tooltip or hint text "Drag preset packages here to install"
- **Overwrite anxiety**: Users may fear losing custom presets
  - *Mitigation*: Clear conflict indicators and per-file control in install dialog

**Performance Risks:**
- **Large package analysis**: Big .zip files may cause UI freezes
  - *Mitigation*: Show loading indicator, consider isolate for analysis if needed
- **Slow SD card writes**: Installation may take minutes for large packages
  - *Mitigation*: Clear progress feedback, allow background operation

---

## Dependencies and Integration Points

**External Dependencies:**
- `desktop_drop: ^0.4.4` - Provides DropTarget widget and XFile handling
- `cross_file: ^0.3.3+5` - Cross-platform file abstraction
- `archive: ^3.4.9` - Zip file extraction and parsing

**Internal Service Dependencies:**
- `DistingCubit` - State management, SD card operations
  - Methods: `fetchSdCardDirectoryListing()`, `writeSdCardFile()`
- `PresetPackageAnalyzer` - Package analysis and validation
- `FileConflictDetector` - Conflict detection and resolution logic

**UI Component Dependencies:**
- `PackageInstallDialog` - Full-featured conflict resolution UI
- `PresetBrowserDialog` - Host dialog for drag-and-drop feature

---

## Implementation Notes

### Reference Implementation

**IMPORTANT:** The old `LoadPresetDialog` (lib/ui/widgets/load_preset_dialog.dart) contains the complete, working implementation of this feature. When implementing each story:

1. Reference the corresponding methods in `LoadPresetDialog._handleDragDone` (lines ~370-450)
2. Copy and adapt the handler code to work with PresetBrowserDialog's structure
3. The logic for package analysis, conflict detection, and dialog display is all there

Key methods to reference:
- `_handleDragEntered` / `_handleDragExited` - Simple state setters
- `_handleDragDone` - Complete drop handling with analysis and conflict detection
- `_buildDragOverlay` - Visual feedback during drag-over

The migration is primarily about moving this working code from LoadPresetDialog to PresetBrowserDialog, not reimplementing from scratch.

### Package Format Expectations

Preset packages follow this structure:
```
package.zip
├── manifest.json          # Required: Package metadata
└── root/                  # Required: Files to install
    ├── presets/
    │   └── my_preset.json
    └── samples/
        └── sample.wav
```

The `manifest.json` contains:
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

All files under `root/` are installed to SD card root, preserving directory structure.

### Error Handling Patterns

- **Invalid package**: Show error dialog with specific reason (missing manifest, corrupt zip)
- **Network errors**: Gracefully skip conflict detection, warn in install dialog
- **Write failures**: Continue installation, collect errors, show summary at end
- **User cancellation**: Clean up partial state, no files written to SD card

### Future Enhancement Opportunities

- Drag-and-drop for algorithm (.so/.dll) files to plugin manager
- Multiple package installation (drop 5 packages at once, queue them)
- Package preview before analyzing (show package name from manifest without full analysis)
- Installation history log (track what was installed when)
- Undo last installation (remove recently installed package files)

---

**For implementation:** Use the `create-story` workflow to generate individual story implementation plans from this epic breakdown.
