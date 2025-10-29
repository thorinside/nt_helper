# nt_helper - Epic Breakdown

**Author:** Neal
**Date:** 2025-10-27
**Project Level:** 2
**Target Scale:** TBD

---

## Overview

This document provides the detailed epic breakdown for nt_helper, expanding on the high-level epic list in the [PRD](./PRD.md).

Each epic includes:

- Expanded goal and value proposition
- Complete story breakdown with user stories
- Acceptance criteria for each story
- Story sequencing and dependencies

**Epic Sequencing Principles:**

- Epic 1 establishes foundational infrastructure and initial functionality
- Subsequent epics build progressively, each delivering significant end-to-end value
- Stories within epics are vertically sliced and sequentially ordered
- No forward dependencies - each story builds only on previous work

---

## Epic 2: 14-bit MIDI CC Support

**Expanded Goal:**

Extend the MIDI mapping system to support 14-bit MIDI CC messages, providing higher-resolution parameter control. This matches the functionality added to the Expert Sleepers reference implementation, where users can designate MIDI mappings as "14 bit CC - low" or "14 bit CC - high" pairs instead of standard 7-bit CC messages.

**Value Proposition:**

14-bit MIDI CC uses two CC numbers (a primary MSB controller and a secondary LSB controller offset by 32) to achieve 16,384 discrete values instead of 128, eliminating zipper noise and enabling smooth, precise parameter sweeps for critical synthesis parameters like pitch, filter cutoff, and oscillator tuning.

**Story Breakdown:**

**Story E2.1: Extend MidiMappingType enum and data model**

As a developer maintaining the mapping data model,
I want the `MidiMappingType` enum to include `cc14BitLow` and `cc14BitHigh` values,
So that packed mapping data can represent both 7-bit and 14-bit MIDI CC mappings.

**Acceptance Criteria:**
1. `MidiMappingType` enum adds two new values: `cc14BitLow` (value=3), `cc14BitHigh` (value=4)
2. `PackedMappingData.fromBytes()` decodes `midiFlags2` using bit-shift (`flags2 >> 2`) instead of conditional logic
3. `PackedMappingData.encodeMIDIPackedData()` encodes type as `(type << 2)` in `midiFlags2`
4. Existing tests pass and new tests verify 14-bit type encoding/decoding
5. `flutter analyze` passes with zero warnings

**Prerequisites:** None

**Story E2.2: Update mapping editor UI for 14-bit CC selection**

As a user configuring MIDI mappings in the parameter property editor,
I want to select "14 bit CC - low" or "14 bit CC - high" from the MIDI Type dropdown,
So that I can create high-resolution MIDI mappings for precise parameter control.

**Acceptance Criteria:**
1. `packed_mapping_data_editor.dart` dropdown includes two new entries: "14 bit CC - low" and "14 bit CC - high"
2. Dropdown displays all five MIDI types: CC, Note - Momentary, Note - Toggle, 14 bit CC - low, 14 bit CC - high
3. Selecting 14-bit types correctly updates `_data.midiMappingType`
4. "MIDI Relative" switch is disabled for 14-bit CC types (same as note types)
5. UI changes are visually consistent with existing design
6. `flutter analyze` passes with zero warnings

**Prerequisites:** Story E2.1

**Story E2.3: SysEx compatibility and hardware sync**

As a user saving presets with 14-bit MIDI mappings,
I want nt_helper to correctly encode and decode 14-bit CC types when communicating with Disting NT hardware,
So that my 14-bit mappings persist correctly and sync with the reference preset editor.

**Acceptance Criteria:**
1. `set_midi_mapping.dart` correctly encodes 14-bit types in SysEx messages
2. `mapping_response.dart` correctly decodes 14-bit types from hardware responses
3. Round-trip test: Create 14-bit mapping → save to hardware → read back → verify type preserved
4. Presets created in reference HTML editor load correctly with 14-bit mappings intact
5. Presets created in nt_helper load correctly in reference HTML editor with 14-bit mappings intact
6. `flutter analyze` passes with zero warnings

**Prerequisites:** Stories E2.1 and E2.2

---

## Epic 3: Drag-and-Drop Preset Package Installation

**Expanded Goal:**

Restore the drag-and-drop preset package installation feature to the Browse Presets dialog, enabling desktop users to install .zip preset packages and .json preset files by simply dragging them onto the dialog window. This feature was originally implemented in the Load Preset dialog (commit 1183117) but was lost during UI consolidation (commit b589e37).

**Value Proposition:**

Desktop users need an efficient workflow for installing community preset packages. Manual extraction and file copying is error-prone and time-consuming. Drag-and-drop installation provides immediate visual feedback, automatic manifest validation, intelligent conflict detection against existing SD card files, and granular control over which files to install or skip. This is essential for managing large preset libraries and protecting custom presets from accidental overwrites.

**Story Breakdown:**

**Story E3.1: Integrate DropTarget into Browse Presets Dialog**

As a desktop user of the Browse Presets dialog,
I want to drag a preset package .zip file onto the dialog window,
So that I can see visual feedback indicating the drop zone is active.

**Acceptance Criteria:**
1. `preset_browser_dialog.dart` wraps main content area with `DropTarget` widget
2. `DropTarget` imports from `desktop_drop` package (conditional import for desktop-only)
3. State variable `_isDragOver` tracks drag-enter/drag-exit events
4. When `_isDragOver` is true, content area shows blue border (2px, rounded corners)
5. Border disappears when drag exits or drop completes
6. No functionality executed on drop yet (just visual feedback)
7. `flutter analyze` passes with zero warnings

**Prerequisites:** None

**Story E3.2: Handle Dropped Files and Analyze Packages**

As a desktop user dropping a preset package onto the Browse Presets dialog,
I want the application to analyze the package contents and validate the manifest,
So that I can see what files will be installed and detect any errors early.

**Acceptance Criteria:**
1. `onDragDone` handler extracts `List<XFile>` from drop details
2. Handler filters files to accept only `.zip` and `.json` extensions
3. Handler shows error dialog if no valid files found or multiple files dropped
4. For valid .zip file, handler converts XFile to `Uint8List` via `readAsBytes()`
5. Handler calls `PresetPackageAnalyzer.analyzePackage(bytes)` and awaits result
6. If analysis fails, show error dialog with exception message
7. If analysis succeeds, store `PackageAnalysis` result in state variable
8. Loading indicator displayed during analysis (prevents UI interaction)
9. `flutter analyze` passes with zero warnings

**Prerequisites:** Story E3.1

**Story E3.3: Detect File Conflicts with SD Card**

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

**Story E3.4: Display Package Install Dialog with Conflict Resolution**

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

**Story E3.5: Execute Package Installation with Progress Tracking**

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

**Story E3.6: Verify Cross-Platform Compatibility**

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

**Story E3.7: Remove Obsolete LoadPresetDialog**

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

**For implementation:** Use the `create-story` workflow to generate individual story implementation plans from this epic breakdown.
