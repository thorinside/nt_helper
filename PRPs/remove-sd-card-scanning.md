name: "Remove Obsolete SD Card Scanning Feature"
description: |
  Refactor the NT Helper application to remove the obsolete SD card preset scanning functionality
  that has been replaced by SysEx directory listing in firmware 1.10+. This includes removing
  the UI, services, database tables, and refactoring the Load Preset functionality.

---

## Goal

**Feature Goal**: Remove all obsolete SD card preset scanning code and database tables, simplifying the codebase by eliminating functionality that has been replaced by firmware 1.10+ SysEx directory listing

**Deliverable**: Refactored codebase with SD card scanning removed, Load Preset functionality updated to use only live SysEx directory listing, and cleaned up database schema

**Success Definition**: All SD card scanning UI, services, DAOs, and database tables removed; Load Preset works without indexed preset data; zero flutter analyze errors; application builds and runs on all platforms

## Why

- Removes ~2000+ lines of obsolete code that duplicates firmware 1.10+ functionality
- Eliminates database storage overhead for indexed preset files
- Simplifies maintenance by removing complex platform-specific file access code
- Reduces confusion by having single source of truth for preset listings
- Improves performance by removing unnecessary database operations and UI components

## What

Remove the entire SD card scanning infrastructure while maintaining preset loading capabilities through the newer SysEx directory listing approach.

### Success Criteria

- [ ] "Scan SD Card Presets" menu item removed from Offline Data page
- [ ] All SD card scanning services and BLoCs removed
- [ ] Database tables `SdCards` and `IndexedPresetFiles` removed via migration
- [ ] Load Preset dialog refactored to not use indexed preset data
- [ ] Application works on all platforms without SD card scanning
- [ ] `flutter analyze` shows zero errors/warnings
- [ ] All existing tests pass (no SD card scanning tests exist to remove)

## All Needed Context

### Context Completeness Check

_This PRP contains all file paths, dependencies, and refactoring requirements needed to completely remove the SD card scanning feature without breaking existing functionality._

### Documentation & References

```yaml
# MUST READ - Include these in your context window
- file: CLAUDE.md
  why: Core codebase concepts and architecture patterns
  critical: Zero tolerance for flutter analyze errors, debugPrint() usage

- file: lib/ui/metadata_sync/metadata_sync_page.dart
  lines: 184-209
  why: Contains the "Scan SD Card Presets" button that needs removal
  action: Remove IconButton with sd_storage_outlined icon

- file: lib/ui/widgets/load_preset_dialog.dart
  why: Main dialog that depends on indexed preset data
  pattern: Currently uses IndexedPresetFilesDao for autocomplete
  action: Refactor to use only live SysEx directory listing

- file: lib/cubit/disting_cubit.dart
  why: Contains fetchSdCardPresets() method for live scanning
  pattern: This is the NEW approach to keep, remove indexed data usage

- file: lib/db/database.dart
  lines: 84-96
  why: Shows migration that added SD card tables in version 3
  action: Add new migration to drop these tables
```

### Files to be Removed Completely

```yaml
UI Layer:
  - lib/ui/sd_card_scanner/sd_card_scanner_page.dart
  - lib/ui/sd_card_scanner/sd_card_scanner_state.dart
  - lib/ui/sd_card_scanner/bloc/sd_card_scanner_bloc.dart
  - lib/ui/sd_card_scanner/bloc/sd_card_scanner_event.dart
  - lib/ui/sd_card_scanner/widgets/sd_card_selection_card.dart
  - lib/ui/sd_card_scanner/widgets/scanning_progress_card.dart

Service Layer:
  - lib/services/sd_card_indexing_service.dart

Database Layer:
  - lib/db/daos/sd_cards_dao.dart
  - lib/db/daos/indexed_preset_files_dao.dart

Utility Layer:
  - lib/util/preset_parser_utils.dart (if only used by SD scanning)
  - lib/util/file_system_utils.dart (if only used by SD scanning)
```

### Code to be Modified

```yaml
lib/ui/metadata_sync/metadata_sync_page.dart:
  - Remove lines 184-209 (Scan SD Card button)
  - Remove import for sd_card_scanner_page.dart

lib/disting_app.dart:
  - Remove line 17 (sdCardScannerRoute constant)
  - Remove line 107 (route mapping for SD card scanner)
  - Remove import for SdCardScannerPage

lib/db/tables.dart:
  - Remove lines 234-240 (SdCards table definition)
  - Remove lines 242-257 (IndexedPresetFiles table definition)

lib/db/database.dart:
  - Add migration version 4 to drop SD card tables
  - Update schemaVersion to 4
  - Remove imports for sd_cards_dao and indexed_preset_files_dao

lib/ui/widgets/load_preset_dialog.dart:
  - Remove SD card dropdown widget
  - Remove IndexedPresetFilesDao usage
  - Refactor _fetchSuggestions to use only live scanning
  - Remove _selectedSdCard state variable
  - Simplify _handlePresetSelection logic

lib/services/package_creator.dart:
  - Check if it depends on SD card indexing
  - Refactor to use live directory listing if needed

lib/models/sd_card_file_system.dart:
  - Keep this file (used by new SysEx directory listing)
```

### Known Gotchas & Dependencies

```dart
// CRITICAL: The new SysEx directory listing (firmware 1.10+) is the replacement
// CRITICAL: DirectoryEntry and DirectoryListing models are KEPT (used by new system)
// CRITICAL: Must handle firmware < 1.10 gracefully (no preset browsing)
// CRITICAL: LoadPresetDialog autocomplete needs alternative data source
// CRITICAL: Database migration must be backward compatible
// CRITICAL: Some imports may need cleanup after file deletion
```

## Implementation Blueprint

### Implementation Tasks (ordered by dependencies)

```yaml
Task 1: CREATE Database Migration
  - MODIFY: lib/db/database.dart
  - ADD: Migration to version 4 that drops SdCards and IndexedPresetFiles tables
  - IMPLEMENT: Conditional drop if tables exist (for safety)
  - UPDATE: schemaVersion from 3 to 4
  - PATTERN: Follow existing migration patterns in the file

Task 2: REMOVE Database Layer
  - DELETE: lib/db/daos/sd_cards_dao.dart
  - DELETE: lib/db/daos/indexed_preset_files_dao.dart
  - MODIFY: lib/db/tables.dart - remove table definitions
  - CLEANUP: Remove all imports for these DAOs throughout codebase

Task 3: REMOVE Service Layer
  - DELETE: lib/services/sd_card_indexing_service.dart
  - CHECK: lib/services/package_creator.dart for SD card dependencies
  - VERIFY: No other services import sd_card_indexing_service

Task 4: REMOVE UI Components
  - DELETE: Entire lib/ui/sd_card_scanner/ directory
  - MODIFY: lib/ui/metadata_sync/metadata_sync_page.dart
    - Remove lines 184-209 (SD card scan button)
    - Remove import for sd_card_scanner
  - MODIFY: lib/disting_app.dart
    - Remove sdCardScannerRoute constant and mapping
    - Remove SdCardScannerPage import

Task 5: REFACTOR Load Preset Dialog
  - MODIFY: lib/ui/widgets/load_preset_dialog.dart
  - REMOVE: SD card dropdown widget and related state
  - REMOVE: All IndexedPresetFilesDao usage
  - REFACTOR: _fetchSuggestions method to use only:
    - History from SharedPreferences
    - Live SysEx directory listing via DistingCubit.fetchSdCardPresets()
  - SIMPLIFY: _handlePresetSelection to not resolve indexed paths
  - ADD: Firmware version check with user message if < 1.10

Task 6: CLEANUP Utilities
  - CHECK: lib/util/preset_parser_utils.dart usage
    - DELETE if only used by SD scanning
    - KEEP if used elsewhere
  - CHECK: lib/util/file_system_utils.dart usage
    - DELETE if only used by SD scanning
    - KEEP if used elsewhere
  - VERIFY: lib/models/sd_card_file_system.dart is KEPT (used by SysEx)

Task 7: VERIFY and Fix Imports
  - RUN: flutter analyze to find broken imports
  - FIX: Remove all imports for deleted files
  - VERIFY: No dangling references to removed code
  - CHECK: No unused imports remain
```

### Database Migration Pattern

```dart
// In lib/db/database.dart, add to onUpgrade:

if (from <= 3) {
  try {
    debugPrint("Migrating to version 4: Removing obsolete SD card tables...");
    
    // Drop tables if they exist (safe for fresh installs)
    await m.database.customStatement('DROP TABLE IF EXISTS indexed_preset_files');
    await m.database.customStatement('DROP TABLE IF EXISTS sd_cards');
    
    debugPrint("Migration successful: Removed obsolete SD card scanning tables.");
  } catch (e) {
    debugPrint("Migration error removing SD card tables: $e");
    // Non-critical error - tables might not exist in some installations
  }
}
```

### Load Preset Dialog Refactoring Pattern

```dart
// Simplified _fetchSuggestions without indexed data:
Future<List<String>> _fetchSuggestions(String query) async {
  final suggestions = <String>[];
  
  // Add history items
  final history = _presetHistory.where((h) => 
    h.toLowerCase().contains(query.toLowerCase())).toList();
  suggestions.addAll(history);
  
  // Add live SD card presets if firmware supports it
  final firmwareVersion = context.read<DistingCubit>().state.firmwareVersion;
  if (firmwareVersion != null && firmwareVersion.hasSdCardSupport) {
    try {
      final livePresets = await context.read<DistingCubit>().fetchSdCardPresets();
      final filtered = livePresets.where((p) =>
        p.toLowerCase().contains(query.toLowerCase())).toList();
      suggestions.addAll(filtered);
    } catch (e) {
      debugPrint('Could not fetch live presets: $e');
    }
  }
  
  return suggestions.take(20).toList();
}
```

## Validation Loop

### Level 1: Syntax & Style

```bash
# After each file modification/deletion
flutter analyze
# Must show ZERO errors/warnings before proceeding

# Format remaining code
dart format lib/ --fix
```

### Level 2: Build Verification

```bash
# Verify database generation after table removal
flutter pub run build_runner build --delete-conflicting-outputs

# Run existing tests (no SD card tests to remove)
flutter test

# Verify the app builds
flutter build macos   # or your platform
```

### Level 3: Functional Testing

```bash
# Test Load Preset functionality
# 1. Launch app
# 2. Connect to Disting NT (firmware 1.10+)
# 3. Open Load Preset dialog
# 4. Verify presets load from device via SysEx
# 5. Verify autocomplete works with live data

# Test database migration
# 1. Install previous version with SD card data
# 2. Run new version
# 3. Verify migration completes without errors
# 4. Check database: sqlite3 ~/.nt_helper/nt_helper.db ".tables"
#    Should NOT show sd_cards or indexed_preset_files tables

# Test Offline Data page
# 1. Navigate to Offline Data
# 2. Verify "Scan SD Card" button is gone
# 3. Verify other functionality still works
```

### Level 4: Cross-Platform Validation

```bash
# Build and test on each platform
flutter build windows
flutter build linux
flutter build ios
flutter build android

# Verify Load Preset works on each platform
# without SD card scanning functionality
```

## Final Validation Checklist

### Code Removal Validation

- [ ] All SD card scanner UI files deleted
- [ ] All SD card service files deleted
- [ ] All SD card DAO files deleted
- [ ] SD card route removed from navigation
- [ ] SD card button removed from Offline Data page
- [ ] Database tables dropped via migration

### Refactoring Validation

- [ ] Load Preset dialog works without indexed data
- [ ] Autocomplete uses live SysEx directory listing
- [ ] No references to deleted files remain
- [ ] `flutter analyze` shows zero errors
- [ ] Application builds on all platforms

### Functional Validation

- [ ] Load Preset works with firmware 1.10+ devices
- [ ] Graceful handling for firmware < 1.10
- [ ] Database migration completes successfully
- [ ] No UI references to SD card scanning remain
- [ ] All other features continue to work

### Performance Validation

- [ ] Reduced database size (no indexed presets)
- [ ] Faster app startup (less initialization)
- [ ] Simplified codebase (~2000 lines removed)
- [ ] No memory leaks from removed components

---

## Anti-Patterns to Avoid

- ❌ Don't leave commented-out code from removed features
- ❌ Don't forget to remove imports for deleted files
- ❌ Don't skip the database migration
- ❌ Don't break Load Preset for firmware < 1.10
- ❌ Don't leave UI elements that reference removed functionality
- ❌ Don't forget to run flutter analyze after changes
- ❌ Don't leave unused utility functions