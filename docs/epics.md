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

## Epic 5: Preset Template System

**Expanded Goal:**

Enable users to create and manage reusable preset templates in the local database, with the ability to inject template algorithms into the current preset for faster workflow setup and consistency. Templates are tagged offline presets that can be appended to the current hardware preset, adding their algorithms sequentially to the end.

**Value Proposition:**

Users often start new projects with similar algorithm configurations (e.g., "Polyphonic Setup", "Modular Processing Chain", "Performance Rig"). Instead of manually recreating the same setup each time, they can save proven configurations as templates and quickly inject them into new presets. This saves time, ensures consistency, and enables users to build personal libraries of reusable building blocks.

**Story Breakdown:**

**Story E5.1: Extend database schema for template flag**

As a developer maintaining the preset data model,
I want the presets table to include an `isTemplate` boolean column,
So that offline presets can be flagged as templates and queried separately.

**Acceptance Criteria:**
1. Add `isTemplate` boolean column to `presets` table in database schema (default: false)
2. Generate Drift migration to add column to existing databases
3. Update `PresetsDao` to expose `isTemplate` in queries
4. `saveFullPreset()` method accepts optional `isTemplate` parameter
5. Database migration runs successfully on app upgrade
6. `flutter analyze` passes with zero warnings
7. All tests pass

**Prerequisites:** None

**Story E5.2: Add UI to tag/untag presets as templates**

As a user managing my saved presets in the Offline Data screen,
I want to mark/unmark presets as templates using a checkbox or toggle,
So that I can designate which presets are reusable templates vs regular saved presets.

**Acceptance Criteria:**
1. Preset list items in `metadata_sync_page.dart` show template indicator (star icon or badge) when `preset.isTemplate` is true
2. Long-press or context menu on preset shows "Mark as Template" / "Unmark as Template" option
3. Toggling template status updates database via `PresetsDao`
4. UI updates immediately after toggling (optimistic update or refresh)
5. Template state persists across app restarts
6. User confirmation dialog shown before unmarking template (optional based on UX preference)
7. `flutter analyze` passes with zero warnings

**Prerequisites:** Story E5.1

**Story E5.3: Filter presets to show templates only**

As a user browsing templates for injection,
I want to see a filtered view showing only templates (not all saved presets),
So that I can quickly find and select the template I want to inject.

**Acceptance Criteria:**
1. Add "Templates" tab or filter toggle to Offline Data screen preset tab
2. Templates view shows only presets where `isTemplate` is true
3. Templates are sorted alphabetically by name
4. Empty state message shown when no templates exist: "No templates found. Mark saved presets as templates to see them here."
5. Template count badge or indicator shows number of available templates
6. Switching between "All Presets" and "Templates" view is instant (no loading delay)
7. `flutter analyze` passes with zero warnings

**Prerequisites:** Story E5.2

**Story E5.4: Implement template injection logic (append-only)**

As a developer implementing template injection,
I want to create a service method that appends template algorithms to the current hardware preset,
So that the UI can trigger template injection with a single method call.

**Acceptance Criteria:**
1. Create `injectTemplateToDevice(FullPresetDetails template, IDistingMidiManager manager)` method in `MetadataSyncCubit` or new service
2. Method does NOT call `requestNewPreset()` (preserves current preset)
3. Method calls `requestAddAlgorithm()` for each template slot, adding them sequentially to the end
4. Method sets parameter values and mappings for each injected slot (reuse logic from `loadPresetToDevice`)
5. Method does NOT call `requestSavePreset()` (lets user save manually)
6. Method validates that current preset + template slots ≤ 32 slots before starting injection
7. If slot limit exceeded, method throws exception with clear error message
8. Method emits loading/success/failure states to UI
9. Unit tests verify slot limit validation and algorithm addition sequence
10. `flutter analyze` passes with zero warnings

**Prerequisites:** Story E5.3

**Story E5.5: Build template preview dialog**

As a user about to inject a template,
I want to see a preview showing what algorithms will be added and where they'll go,
So that I can confirm the injection before modifying my current preset.

**Acceptance Criteria:**
1. Preview dialog shows current preset summary: "Current: 5 algorithms (slots 1-5)"
2. Preview shows template algorithms that will be added: List of algorithm names from template
3. Preview shows result: "After injection: 8 algorithms (current 1-5 + template algorithms in slots 6-8)"
4. Dialog shows warning if injection would exceed 32 slots (and disables Inject button)
5. Dialog has "Cancel" and "Inject Template" buttons
6. "Inject Template" button triggers `injectTemplateToDevice()` method
7. Dialog shows loading spinner during injection
8. Dialog auto-closes on successful injection
9. Error message displayed in dialog if injection fails (stays open for user to read)
10. `flutter analyze` passes with zero warnings

**Prerequisites:** Story E5.4

**Story E5.6: Add "Inject Template" action to templates view**

As a user browsing templates in online mode,
I want an "Inject" button next to each template,
So that I can quickly inject a template into my current hardware preset.

**Acceptance Criteria:**
1. When in online mode (connected to hardware), template list items show "Inject" icon button (e.g., `Icons.add_circle_outline`)
2. Clicking "Inject" button opens template preview dialog (Story E5.5)
3. "Inject" button is disabled when in offline mode (show tooltip: "Connect to device to inject templates")
4. "Inject" button is disabled during sync operations (same logic as existing Load/Delete buttons)
5. Successfully injected template shows success snackbar: "Template '[name]' injected (X algorithms added)"
6. Template injection updates routing editor and parameter views automatically (via existing `_refreshStateFromManager()`)
7. `flutter analyze` passes with zero warnings

**Prerequisites:** Story E5.5

**Story E5.7: Handle edge cases and error scenarios**

As a user working with templates,
I want clear error messages and graceful handling when things go wrong,
So that I understand what happened and can take corrective action.

**Acceptance Criteria:**
1. Error shown if current preset + template > 32 slots: "Cannot inject: Would exceed 32 slot limit (current: X, template: Y)"
2. Error shown if hardware connection lost during injection: "Connection lost during injection. Preset may be partially modified."
3. Error shown if template metadata incomplete: "Template missing algorithm metadata. Sync algorithms first."
4. Warning shown if template is empty (0 slots): "Cannot inject empty template"
5. Confirmation dialog shown if injecting large template (> 10 algorithms): "This will add X algorithms. Continue?"
6. Injection can be cancelled during progress (via cancel button in preview dialog)
7. Partial injection failure handled gracefully: rollback not possible (NT doesn't support it), but user sees clear error showing which algorithm failed
8. All error messages include actionable guidance (not just "Error occurred")
9. `flutter analyze` passes with zero warnings
10. All tests pass

**Prerequisites:** Story E5.6

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
