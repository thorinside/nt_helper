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

## Epic 4: MCP Library Replacement & Simplified Preset Creation API

**Expanded Goal:**

Replace the current MCP implementation with the official `dart_mcp` library from the Dart/Flutter team and redesign the MCP tool interface around four intuitive operations: search, new, edit, and show. The new design uses familiar CRUD-style verbs, supports multiple granularity levels (preset/slot/parameter), includes full mapping support (CV/MIDI/i2c/performance pages), and provides intelligent backend diffing to hide NT hardware complexities from LLM clients.

**Value Proposition:**

The current MCP tool set fragments operations across 20+ specialized functions, forcing LLMs to navigate complex tool selection and remember intricate workflows. Four core tools (search/new/edit/show) with flexible granularity reduce cognitive load, enable smaller models to succeed, and map to familiar patterns that LLMs already understand from CLI/database contexts. Backend diffing means LLMs declare desired state rather than orchestrating low-level operations. Full mapping support enables LLMs to configure CV/MIDI/i2c control and performance pages without understanding NT's packed binary format.

**Story Breakdown:**

**Story E4.1: Replace MCP server foundation with dart_mcp library**

As a developer maintaining MCP integration,
I want to migrate from the current MCP library to the official `dart_mcp` package with HTTP streaming transport,
So that MCP clients can connect via standard HTTP on port 3000 without stdio configuration friction.

**Acceptance Criteria:**
1. Add `dart_mcp` dependency to `pubspec.yaml` (verify latest stable version from pub.dev)
2. Remove current MCP library dependency from `pubspec.yaml`
3. Study example servers in `https://github.com/dart-lang/ai/tree/main/pkgs/dart_mcp/example` to understand proper setup patterns
4. Update `mcp_server_service.dart` to initialize HTTP server on port 3000 with `/mcp` endpoint using `dart_mcp` streamable HTTP transport
5. Configure server to use `dart_mcp`'s built-in streamable HTTP transport (following dart_mcp example patterns)
6. Server accepts HTTP POST requests to `/mcp` endpoint with MCP protocol messages
7. Backend connection handling (cubit access, MIDI manager access) remains functional
8. Server logs startup message with connection URL: "MCP server running at http://localhost:3000/mcp"
9. Verify server responds to MCP handshake via HTTP client (curl or Postman test)
10. Remove all old MCP library imports from codebase
11. `flutter analyze` passes with zero warnings
12. All tests pass

**Prerequisites:** None

---

**Story E4.2: Implement search tool for algorithm discovery**

As an LLM client exploring available algorithms,
I want a search tool that finds algorithms by name/category with fuzzy matching and returns documentation,
So that I can discover appropriate algorithms without knowing exact names or GUIDs.

**Acceptance Criteria:**
1. Create `search` tool accepting: `type` ("algorithm" required), `query` (string, required)
2. When `type: "algorithm"`, search by fuzzy name matching (≥70% similarity) or exact GUID
3. Search also filters by category if query matches category name
4. Return array of matching algorithms with: `guid`, `name`, `category`, `description`
5. Include general parameter description in results (NOT specific parameter numbers - those depend on specifications)
6. Parameter descriptions explain what kinds of parameters the algorithm has (e.g., "frequency controls", "envelope settings") without mapping to specific indices
7. Results sorted by relevance score (exact match > high similarity > category match)
8. Limit results to top 10 matches to avoid overwhelming output
9. Return empty array with helpful message if no matches found
10. Tool works in all connection modes (demo, offline, connected)
11. JSON schema documents the tool with clear examples
12. `flutter analyze` passes with zero warnings
13. All tests pass

**Prerequisites:** Story E4.1

---

**Story E4.3: Implement new tool for preset initialization**

As an LLM client starting preset creation,
I want a tool that creates a new blank preset or preset with initial algorithms,
So that I have a clean starting point for building my configuration.

**Acceptance Criteria:**
1. Create `new` tool accepting: `name` (string, required), `algorithms` (array, optional)
2. When `algorithms` not provided, create blank preset with specified name
3. When `algorithms` provided, accept array of: `{ "guid": "...", "name": "...", "specifications": [...] }`
4. Support algorithm identification by GUID or name (fuzzy matching ≥70%)
5. `specifications` array provides values for algorithm creation (required for some algorithms, optional for others)
6. Tool validates algorithm existence before creation
7. Tool validates specification values against algorithm requirements
8. Tool clears current preset on device (unsaved changes lost - warn in description)
9. Tool adds algorithms sequentially to slots 0, 1, 2, etc.
10. New algorithms have default parameter values and all mappings disabled (CV/MIDI/i2c enabled=false, performance_page=0)
11. Return created preset state with all slots, default parameter values, and disabled mappings
12. Tool fails with clear error if in offline/demo mode
13. JSON schema includes examples: blank preset, preset with 1 algorithm, preset with 3 algorithms
14. `flutter analyze` passes with zero warnings
15. All tests pass

**Prerequisites:** Story E4.2

---

**Story E4.4: Implement edit tool with preset-level granularity**

As an LLM client modifying a preset,
I want to send a complete desired preset state and have the backend calculate minimal changes,
So that I don't need to understand NT hardware slot reordering and algorithm movement.

**Acceptance Criteria:**
1. Create `edit` tool accepting: `target` ("preset"), `data` (object with preset JSON)
2. Preset JSON format: `{ "name": "...", "slots": [ { "algorithm": {...}, "parameters": [...] } ] }`
3. Parameter structure: `{ "parameter_number": N, "value": V, "mapping": {...} }` where mapping is optional
4. Mapping structure (all fields optional): `{ "cv": {...}, "midi": {...}, "i2c": {...}, "performance_page": N }`
5. Use snake_case for all JSON field names: `cv_input`, `midi_channel`, `is_midi_enabled`, etc.
6. When mapping omitted entirely from parameter JSON, existing mapping is preserved unchanged
7. When creating new parameters (new algorithm), all mapping types default to disabled (cv/midi/i2c enabled=false, performance_page=0)
8. When mapping included, only specified mapping types are updated, others preserved
9. Backend diff engine compares desired state vs current device state (reads from SynchronizedState)
10. Diff engine determines: algorithms to add, algorithms to remove, algorithms to move, parameters to change, mappings to update
11. Diff validates all changes before applying (fail fast on first validation error)
12. Mapping validation: MIDI channel 0-15, MIDI CC 0-128 (128=aftertouch), CV input 0-12, i2c CC 0-255, performance_page 0-15, etc.
13. If validation succeeds, apply changes and auto-save preset
14. Return updated preset state after successful application
15. Return detailed error message if validation or application fails (no partial changes)
16. Tool works only in connected mode (clear error if offline/demo)
17. JSON schema documents complete preset structure with mapping examples
18. Unit tests verify diff logic: add algorithm, remove algorithm, reorder algorithms, change parameters, update mappings, combined changes
19. `flutter analyze` passes with zero warnings
20. All tests pass

**Prerequisites:** Story E4.3

---

**Story E4.5: Implement edit tool with slot-level granularity**

As an LLM client modifying a single slot,
I want to send desired slot state without affecting other slots,
So that I can make targeted changes efficiently.

**Acceptance Criteria:**
1. Extend `edit` tool to accept: `target` ("slot"), `slot_index` (int, required), `data` (object with slot JSON)
2. Slot JSON format: `{ "algorithm": { "guid": "...", "specifications": [...] }, "name": "...", "parameters": [...] }`
3. Parameter structure: `{ "parameter_number": N, "value": V, "mapping": {...} }` where mapping is optional
4. Mapping fields (all optional): `cv`, `midi`, `i2c`, `performance_page` using snake_case naming
5. When mapping omitted, existing mapping is preserved
6. When mapping included, only specified types are updated (partial updates supported)
7. Backend compares desired slot vs current slot at specified index (reads from SynchronizedState)
8. If algorithm changes: backend handles parameter/mapping reset automatically (tools just render SynchronizedState)
9. If algorithm stays same: update only changed parameters and mappings
10. If slot name provided: update custom slot name
11. Validate slot_index in range 0-31
12. Validate algorithm exists and specifications are valid
13. Validate parameter values against algorithm constraints
14. Validate mapping fields: MIDI channel 0-15, CC 0-128, type enum valid, CV input 0-12, i2c CC 0-255, performance_page 0-15
15. Apply changes and auto-save preset
16. Return updated slot state after successful application
17. Return error if validation fails (no partial changes)
18. JSON schema includes mapping examples: MIDI CC, CV input, i2c, performance page, combined mappings
19. `flutter analyze` passes with zero warnings
20. All tests pass

**Prerequisites:** Story E4.4

---

**Story E4.6: Implement edit tool with parameter-level granularity**

As an LLM client adjusting specific parameters,
I want to set parameter values and mappings by name or number without sending full preset/slot data,
So that I can make quick parameter tweaks efficiently.

**Acceptance Criteria:**
1. Extend `edit` tool to accept: `target` ("parameter"), `slot_index` (int, required), `parameter` (string or int, required), `value` (number, optional), `mapping` (object, optional)
2. Support parameter identification by: `parameter_name` (string) OR `parameter_number` (int, 0-based)
3. When using `parameter_name`, search slot parameters for matching name (exact match required)
4. When `value` provided: validate and update parameter value
5. When `mapping` provided: validate and update parameter mapping
6. When both `value` and `mapping` omitted: return error "Must provide value or mapping"
7. Mapping object structure (all fields optional, snake_case): `cv`, `midi`, `i2c`, `performance_page`
8. Partial mapping updates supported - only specified mapping types are updated, others preserved. Example: `{ "midi": {...} }` updates only MIDI, preserves CV/i2c/performance_page
9. Empty mapping object `{}` is valid and preserves all existing mappings
10. Validate slot_index in range 0-31
11. Validate parameter exists in slot
12. Validate value within parameter min/max range (if provided)
13. Validate mapping fields strictly: MIDI channel 0-15, MIDI CC 0-128, MIDI type enum values, CV input 0-12, CV source (algorithm output index), i2c CC 0-255, performance_page 0-15
14. Apply changes and auto-save preset
15. Return updated parameter state: `{ "slot_index": N, "parameter_number": N, "parameter_name": "...", "value": N, "mapping": {...} }`
16. Disabled mappings omitted from return value (only enabled mappings included)
17. Return error if parameter not found, value out of range, or mapping validation fails
18. JSON schema includes complete mapping field documentation with valid ranges and examples
19. `flutter analyze` passes with zero warnings
20. All tests pass

**Prerequisites:** Story E4.5

---

**Story E4.7: Implement show tool for state inspection**

As an LLM client inspecting current state,
I want a flexible show tool that displays preset, slot, parameter, screen, or routing information with mappings included,
So that I can understand the current configuration before making changes.

**Acceptance Criteria:**
1. Create `show` tool accepting: `target` ("preset"|"slot"|"parameter"|"screen"|"routing", required), `identifier` (string or int, optional)
2. When `target: "preset"`, return complete preset with all slots, parameters, and mappings (rendered from SynchronizedState)
3. Parameter structure includes: `parameter_number`, `parameter_name`, `value`, `min`, `max`, `unit`, `mapping` (optional - only if enabled)
4. Mapping structure uses snake_case: `cv_input`, `midi_channel`, `is_midi_enabled`, etc.
5. Disabled mappings omitted from output (only include mapping object if at least one type is enabled)
6. CV mapping included if: `cv_input > 0` OR `source > 0`
7. CV mapping fields: `source`, `cv_input`, `is_unipolar`, `is_gate`, `volts`, `delta`
8. MIDI mapping included if: `is_midi_enabled == true`
9. MIDI mapping fields: `is_midi_enabled`, `midi_channel`, `midi_type` ("cc"|"note_momentary"|"note_toggle"|"cc_14bit_low"|"cc_14bit_high"), `midi_cc`, `is_midi_symmetric`, `is_midi_relative`, `midi_min`, `midi_max`
10. i2c mapping included if: `is_i2c_enabled == true`
11. i2c mapping fields: `is_i2c_enabled`, `i2c_cc`, `is_i2c_symmetric`, `i2c_min`, `i2c_max`
12. Performance page included if: `performance_page > 0` (value 1-15)
13. When `target: "slot"`, require `identifier` (int slot_index), return single slot with all parameters and enabled mappings
14. When `target: "parameter"`, require `identifier` (format: "slot_index:parameter_number"), return single parameter with mapping (if enabled)
15. When `target: "screen"`, return current device screen as base64 JPEG image (reuse existing screenshot logic)
16. When `target: "routing"`, return routing state in same format as current `get_routing` tool
17. Routing returns physical names (Input N, Output N, Aux N, None) not internal bus numbers
18. Routing works in both online and offline modes (uses routing editor state)
19. Validate identifier format and ranges for each target type
20. Return clear error if identifier missing when required or invalid
21. JSON schema documents all target types with complete mapping field descriptions and examples
22. `flutter analyze` passes with zero warnings
23. All tests pass

**Prerequisites:** Story E4.6

---

**Story E4.8: Create comprehensive JSON schema documentation with mapping examples**

As an LLM client learning the API,
I want detailed JSON schema documentation with mapping field descriptions and examples,
So that I understand how to work with CV/MIDI/i2c mappings and performance pages.

**Acceptance Criteria:**
1. JSON schema for all tools includes complete mapping structure documentation using snake_case
2. Mapping field descriptions explain purpose and valid ranges for each field
3. CV mapping documentation explains: `source` (algorithm output for observing other algorithm outputs - advanced usage), `cv_input` (physical CV input 0-12), `is_unipolar` (unipolar vs bipolar), `is_gate` (gate mode), `volts` (voltage scaling), `delta` (sensitivity)
4. MIDI mapping documentation explains: `midi_type` values (cc, note_momentary, note_toggle, cc_14bit_low, cc_14bit_high), `midi_channel` (0-15), `midi_cc` (0-128, 128=aftertouch), `is_midi_symmetric`, `is_midi_relative`, `midi_min`/`midi_max` (scaling range)
5. i2c mapping documentation explains: `i2c_cc` (0-255), `is_i2c_symmetric`, `i2c_min`/`i2c_max` (scaling range)
6. Performance page documentation explains: pages 1-15 for parameter grouping/organization, 0 = not assigned
7. Schema examples include: preset with MIDI mappings, slot with CV mappings, parameter with i2c mapping, parameter with performance page assignment
8. Schema examples show partial mapping updates (e.g., update only MIDI, preserve CV/i2c)
9. Schema examples show common patterns: map filter cutoff to MIDI CC, map envelope to CV input, assign multiple params to performance page, observe algorithm output as CV source
10. Helper documentation created: `docs/mcp-mapping-guide.md` explaining mapping concepts and use cases
11. Mapping guide includes troubleshooting: common validation errors, mapping conflicts, performance page best practices
12. Mapping guide explains that disabled mappings are omitted from `show` output but preserved when editing
13. Update main `CLAUDE.md` with link to mapping guide
14. `flutter analyze` passes with zero warnings

**Prerequisites:** Story E4.7

---

**Story E4.9: Remove old MCP tools and consolidate documentation**

As a developer maintaining clean codebase,
I want to remove all old MCP tool implementations and update documentation,
So that we have a single source of truth for the new 4-tool API.

**Acceptance Criteria:**
1. Remove all old tool registrations from `mcp_server_service.dart` (keep only: search, new, edit, show)
2. Remove old tool implementation files if no longer needed
3. Keep backend services that are reused by new tools (diffing logic, validation, SynchronizedState rendering, etc.)
4. Update or remove hardcoded documentation resources to reflect new tool set
5. Create new `docs/mcp-api-guide.md` documenting the 4-tool API with mapping support
6. Include workflow examples: "Creating a simple preset", "Modifying existing preset with mappings", "Exploring algorithms", "Setting up MIDI control", "Organizing with performance pages"
7. Include JSON schema reference for each tool with complete mapping field documentation
8. Include troubleshooting section for common errors (including mapping validation errors)
9. Add section on granularity: when to use preset vs slot vs parameter edits
10. Add section on mapping strategies: when to use CV vs MIDI vs i2c, performance page organization, using CV source for modulation
11. Update main `CLAUDE.md` with link to new MCP API guide
12. `flutter analyze` passes with zero warnings
13. All tests pass

**Prerequisites:** Story E4.8

---

**Story E4.10: Test with smaller LLM and iterate on usability**

As a developer validating the "foolproof" goal,
I want to test the 4-tool API with mappings using a smaller LLM and measure success rate,
So that I can identify and fix remaining usability issues.

**Acceptance Criteria:**
1. Set up test environment with smaller LLM (GPT-OSS-20B or similar) connected to nt_helper MCP server
2. Conduct 12 test scenarios covering: search algorithms, create simple preset, create complex preset, modify preset, add MIDI mappings, add CV mappings, set performance pages, inspect state with mappings, handle errors
3. Measure success rate: % of scenarios where LLM successfully completes task without human intervention
4. Document failure modes: tool selection errors, schema misunderstandings, validation errors, mapping field confusion, snake_case issues
5. Identify top 3 usability issues from testing
6. Iterate on tool descriptions, JSON schemas, mapping documentation, or error messages to address issues
7. Re-test after improvements and document success rate change
8. Target: >80% success rate on simple operations, >60% on complex operations, >50% on mapping operations
9. Document findings and recommendations in `docs/mcp-api-guide.md`
10. Special focus on mapping usability: Are field names clear? Are validation errors helpful? Are examples sufficient? Is snake_case better than camelCase for LLMs?
11. `flutter analyze` passes with zero warnings

**Prerequisites:** Story E4.9

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

## Epic 7: Sysex Updates

**Expanded Goal:**

Implement new features based on SysEx protocol enhancements and hardware firmware updates. This epic focuses on extracting and utilizing additional data fields from SysEx responses that provide richer state information about parameter behavior, routing configurations, and hardware capabilities.

**Value Proposition:**

As the Disting NT firmware evolves and exposes more detailed state information via SysEx messages, nt_helper needs to extract and present this data to users. The parameter disabled flag (bits 16-20 in 0x44/0x45 responses) is the first example: it tells users which parameters are currently active vs inactive based on their configuration, preventing confusion about why parameter changes have no effect. Future SysEx updates will enable additional features like dynamic routing visualization, output state detection, and configuration-aware UX improvements.

**Story Breakdown:**

**Story E7.1: Implement Parameter Disabled/Grayed-Out State in UI**

As a user editing parameters in online mode,
I want to see which parameters are disabled (grayed out) based on my current configuration,
So that I can focus on relevant parameters and understand why certain controls have no effect.

**Acceptance Criteria:**

1. **Data Model:** Add `isDisabled` boolean field to `ParameterValue` class with default value `false` for backward compatibility
2. **Data Model:** Update `ParameterValue` equality, hashCode, and toString methods to include `isDisabled` field
3. **SysEx Parsing:** Extract disabled flag from 0x44 (All Parameter Values) response using formula: `flag = (byte0 >> 2) & 0x1F; isDisabled = (flag == 1)`
4. **SysEx Parsing:** Extract disabled flag from 0x45 (Single Parameter Value) response using same formula
5. **SysEx Parsing:** Add private `_extractDisabledFlag(int byte0)` helper method to both response parsers
6. **Offline Mode:** MockDistingMIDIManager and OfflineDistingMIDIManager always return `isDisabled = false` (flag only available from live hardware)
7. **State Management:** DistingCubit propagates `isDisabled` state through Slot model to UI
8. **State Management:** Parameter updates trigger UI rebuild when disabled state changes
9. **UI Visual Feedback:** Parameter editor widgets display disabled parameters with 0.5 opacity (50% transparency)
10. **UI Visual Feedback:** Parameter list/grid views show disabled parameters with grayed-out text and reduced opacity
11. **UI Behavior:** Disabled parameters are read-only (cannot be edited) with clear visual indication
12. **UI Behavior:** Tooltip or help text explains why parameter is disabled when user hovers/taps
13. **MCP Integration:** `get_parameter_value` response includes `is_disabled` boolean field in JSON
14. **MCP Integration:** `get_multiple_parameters` includes `is_disabled` for each parameter
15. **MCP Integration:** Parameter search results include `is_disabled` field
16. **Testing:** Unit tests verify flag extraction for various byte0 values (0x00→false, 0x04→true, 0x08→false)
17. **Testing:** Unit tests verify ParameterValue equality with different disabled states
18. **Testing:** Integration test verifies Clock algorithm with Internal source shows Clock input parameter as disabled
19. **Testing:** Integration test verifies changing Source from Internal to External updates disabled state
20. **Testing:** Widget tests verify disabled parameters show reduced opacity and cannot be edited
21. **Testing:** Offline mode test verifies all parameters appear enabled (isDisabled=false)
22. **Documentation:** Update parameter flag analysis report (docs/parameter-flag-analysis-report.md) with implementation status
23. **Documentation:** Add inline code comments explaining flag extraction bit manipulation
24. **Code Quality:** `flutter analyze` passes with zero warnings
25. **Code Quality:** All existing tests pass with no regressions

**Prerequisites:** None

**Technical Notes:**
- Files to modify: `lib/domain/disting_nt_sysex.dart`, `lib/domain/sysex/responses/all_parameter_values_response.dart`, `lib/domain/sysex/responses/parameter_value_response.dart`, `lib/domain/mock_disting_midi_manager.dart`, `lib/domain/offline_disting_midi_manager.dart`, `lib/cubit/disting_cubit.dart`, `lib/models/slot.dart`, `lib/ui/widgets/parameter_editor_widget.dart`, `lib/ui/widgets/parameter_list_widget.dart`, `lib/mcp/tools/disting_tools.dart`
- Reference documents: `docs/parameter-flag-findings.md`, `docs/parameter-flag-analysis-report.md`
- Test files: Create `test/integration/parameter_disabled_state_test.dart`, update existing response parser tests

**Story E7.2: Auto-refresh parameter state after edits and remove disabled parameter tooltip**

As a user editing algorithm parameters,
I want the parameter disabled states to automatically update when I change a parameter that affects other parameters,
So that I can immediately see which parameters become available or unavailable without manually refreshing.

**Acceptance Criteria:**
1. **Auto-refresh Logic:** When user finishes editing a parameter value (on value commit, not during drag), schedule a single `requestAllParameterValues` message
2. **Debouncing:** Use debounce/throttle mechanism to ensure only one refresh request is queued at a time (prevent request flooding)
3. **Debounce Timing:** Wait 300ms after last parameter edit before sending refresh request (allows batch edits without multiple refreshes)
4. **State Management:** DistingCubit or parameter editor manages debounced refresh timer
5. **Cancel Pending:** If new parameter edit occurs before timer expires, cancel pending refresh and restart timer
6. **UI Feedback:** No loading spinner needed (refresh is fast and non-blocking)
7. **Remove Tooltip:** Remove tooltip/help text that explains why parameter is disabled
8. **Visual Clarity:** Grayed-out appearance (0.5 opacity) and read-only state are sufficient visual feedback
9. **UI Polish:** Ensure disabled parameters remain clearly distinguishable without tooltip clutter
10. **Testing:** Integration test verifies changing Clock algorithm Source parameter triggers auto-refresh
11. **Testing:** Integration test verifies Clock Input parameter disabled state updates automatically after Source change
12. **Testing:** Unit test verifies debounce logic prevents request flooding when editing multiple parameters rapidly
13. **Testing:** Widget test verifies tooltip is removed from disabled parameters
14. **Code Quality:** `flutter analyze` passes with zero warnings
15. **Code Quality:** All existing tests pass with no regressions

**Prerequisites:** Story E7.1

**Technical Notes:**
- Files to modify: `lib/cubit/disting_cubit.dart` or `lib/ui/widgets/parameter_editor_widget.dart` (add debounced refresh logic), `lib/ui/widgets/parameter_editor_widget.dart` or equivalent (remove tooltip)
- Debounce implementation: Use `Timer` with cancel/restart pattern or rxdart `debounceTime` operator
- Reference: Story E7.1 implementation for disabled state handling
- Test files: Update `test/integration/parameter_disabled_state_test.dart`, add debounce unit tests

---

## Epic 8: Android Video Implementation

**Expanded Goal:**

Enable real camera video streaming on Android by completing the uvccamera fork's EventChannel implementation and integrating it with nt_helper's existing unified video architecture.

**Value Proposition:**

Android is the only platform where video doesn't work. iOS and macOS use a unified BMP → EventChannel → VideoFrameCubit architecture that works perfectly. Completing Android support achieves feature parity across all platforms, allowing Android users to view the Disting NT's 256x64 display in the floating video overlay.

**Story Breakdown:**

**Story E8.1: Complete uvccamera fork EventChannel implementation**

As a developer maintaining the uvccamera fork,
I want to add EventChannel and MethodChannel handlers for continuous frame streaming,
So that nt_helper can subscribe to frame data following the fork's established EventChannel patterns.

**Acceptance Criteria:**
1. Create `UvcCameraFrameEventStreamHandler.java` following existing handler patterns
2. Add `frameEventChannel` to `UvcCameraPlugin.java` with "uvccamera/frames" channel name
3. Pass `frameEventStreamHandler` to `UvcCameraPlatform` constructor
4. Update `UvcCameraPlatform.startFrameStreaming()` to create IFrameCallback calling `frameEventStreamHandler.sendFrame()`
5. Add "startFrameStreaming" and "stopFrameStreaming" cases to `UvcCameraNativeMethodCallHandler`
6. Method handlers extract `cameraId` and `pixelFormat`, validate arguments, call platform methods
7. EventStreamHandler dispatches frames to main thread before calling `eventSink.success()`
8. Proper error handling with try/catch and `result.error()` calls
9. Fork builds successfully
10. Pattern matches existing EventChannel implementations (error, status, button, device handlers)

**Prerequisites:** None (fork foundation already exists)

**Story E8.2: Integrate fork frame streaming with nt_helper and test on Android device**

As a user running nt_helper on Android,
I want video to display in the floating overlay just like iOS/macOS,
So that I have feature parity across all platforms.

**Acceptance Criteria:**
1. Update pubspec.yaml to point to latest fork commit with EventChannel implementation
2. Remove `VideoFrameCallback` class from `UsbVideoCapturePlugin.kt` (no longer needed)
3. Update `startRealCameraFrameCapture` to call fork's startFrameStreaming via MethodChannel
4. Subscribe to "uvccamera/frames" EventChannel in native plugin
5. Convert NV21 frames to Bitmap using `YuvImage` helper
6. Encode Bitmap to BMP using existing `encodeBMP()` method
7. Forward BMP data via nt_helper's EventChannel to Dart layer
8. `flutter analyze` passes with zero warnings
9. Build APK succeeds: `flutter build apk`
10. Deploy to Android device, connect Disting NT via USB OTG
11. Video displays correctly in floating overlay
12. Frame rate stable at 10-15 FPS
13. No memory leaks (verified via Android Studio profiler)
14. Camera reconnection works after disconnect/reconnect
15. App backgrounding/foregrounding handled gracefully
16. Video quality matches iOS/macOS

**Prerequisites:** Story E8.1

**Technical Notes:**
- Fork location: `https://github.com/thorinside/UVCCamera` branch `feature/frame-streaming-api`
- Files to modify (fork): `UvcCameraFrameEventStreamHandler.java` (NEW), `UvcCameraPlugin.java`, `UvcCameraPlatform.java`, `UvcCameraNativeMethodCallHandler.java`
- Files to modify (nt_helper): `pubspec.yaml`, `android/app/src/main/kotlin/com/example/nt_helper/UsbVideoCapturePlugin.kt`
- Reference documents: `docs/epic-8-android-video-implementation-context.md`, `docs/uvccamera-fork-frame-streaming-story.md`
- Testing: Requires Android device with USB OTG support and Disting NT hardware

---

**For implementation:** Use the `create-story` workflow to generate individual story implementation plans from this epic breakdown.
