# Story E3.7 Context: Remove Obsolete LoadPresetDialog

**Epic:** 3 - Drag-and-Drop Preset Package Installation
**Story ID:** e3-7-remove-obsolete-loadpresetdialog
**Generated:** 2025-10-28

---

## Overview

This story completes Epic 3 by removing the obsolete `LoadPresetDialog` widget. The drag-and-drop functionality has been successfully migrated to `PresetBrowserDialog`, making the old implementation redundant. The `PresetAction` enum must be preserved by extracting it to its own file.

---

## Current State Analysis

### LoadPresetDialog Location
**File:** `/Users/nealsanche/nosuch/nt_helper/lib/ui/widgets/load_preset_dialog.dart`

### What LoadPresetDialog Contains

1. **PresetAction Enum** (MUST BE PRESERVED)
   ```dart
   enum PresetAction { load, append, export }
   ```
   - Used by `PresetBrowserDialog` for action handling
   - Must be extracted before deletion

2. **LoadPresetDialog Widget** (OBSOLETE)
   - Original drag-drop implementation
   - Replaced by `PresetBrowserDialog` with Stories E3.1-E3.6
   - No longer referenced in active code

### Current Import in PresetBrowserDialog

**File:** `/Users/nealsanche/nosuch/nt_helper/lib/ui/widgets/preset_browser_dialog.dart`

```dart
import 'package:nt_helper/ui/widgets/load_preset_dialog.dart';
```

This import is only needed for the `PresetAction` enum.

---

## Implementation Steps

### Step 1: Extract PresetAction Enum

**Create:** `/Users/nealsanche/nosuch/nt_helper/lib/models/preset_action.dart`

```dart
/// Actions that can be performed on presets
enum PresetAction {
  /// Load preset, replacing current preset
  load,

  /// Append preset to current preset
  append,

  /// Export preset to file
  export,
}
```

**Why in `lib/models/`:**
- Enums represent data models
- Consistent with other model files in the project
- Clear separation of concerns
- Easy to import from anywhere

### Step 2: Update PresetBrowserDialog Import

**File:** `/Users/nealsanche/nosuch/nt_helper/lib/ui/widgets/preset_browser_dialog.dart`

**Replace:**
```dart
import 'package:nt_helper/ui/widgets/load_preset_dialog.dart';
```

**With:**
```dart
import 'package:nt_helper/models/preset_action.dart';
```

### Step 3: Search for Other References

**Command:**
```bash
cd /Users/nealsanche/nosuch/nt_helper
grep -r "LoadPresetDialog" lib/ test/
grep -r "load_preset_dialog" lib/ test/
```

**Expected Results:**
- Import statements in files that use `PresetAction`
- No direct usage of `LoadPresetDialog` widget

**Action:**
- Update all imports to use `package:nt_helper/models/preset_action.dart`
- Verify no code instantiates `LoadPresetDialog`

### Step 4: Verify No Widget Usage

**Command:**
```bash
cd /Users/nealsanche/nosuch/nt_helper
grep -r "LoadPresetDialog(" lib/
```

**Expected Result:** No matches (no instantiation of the widget)

If matches are found, they must be migrated to use `PresetBrowserDialog` instead.

### Step 5: Delete LoadPresetDialog

**Command:**
```bash
rm /Users/nealsanche/nosuch/nt_helper/lib/ui/widgets/load_preset_dialog.dart
```

### Step 6: Run Quality Checks

**Commands:**
```bash
cd /Users/nealsanche/nosuch/nt_helper

# Must pass with zero warnings
flutter analyze

# Run all tests
flutter test

# Verify builds succeed
flutter build macos
flutter build apk
```

All must succeed.

---

## Files to Modify

### New File: lib/models/preset_action.dart

```dart
/// Actions that can be performed on presets
enum PresetAction {
  /// Load preset, replacing current preset
  load,

  /// Append preset to current preset
  append,

  /// Export preset to file
  export,
}
```

### Modified File: lib/ui/widgets/preset_browser_dialog.dart

**Before:**
```dart
import 'package:nt_helper/ui/widgets/load_preset_dialog.dart';
```

**After:**
```dart
import 'package:nt_helper/models/preset_action.dart';
```

### Other Files (Search and Update)

Any file importing `load_preset_dialog.dart` for `PresetAction` must be updated:

```bash
# Find all files importing load_preset_dialog
grep -r "import.*load_preset_dialog" lib/
```

Update each to import from `models/preset_action.dart` instead.

---

## Verification Checklist

### Code Quality
- [ ] `flutter analyze` passes with zero warnings
- [ ] All tests pass
- [ ] No unused imports remain
- [ ] No references to `LoadPresetDialog` widget

### PresetAction Enum
- [ ] `lib/models/preset_action.dart` created
- [ ] Enum contains all three values: `load`, `append`, `export`
- [ ] Documentation comments added
- [ ] File follows project code style

### Import Updates
- [ ] `preset_browser_dialog.dart` imports updated
- [ ] All other files importing `load_preset_dialog.dart` updated
- [ ] No broken imports remain

### File Deletion
- [ ] `load_preset_dialog.dart` deleted
- [ ] File not in working directory
- [ ] File not in git staging area (committed deletion)

### Build Verification
- [ ] Desktop build succeeds (macOS)
- [ ] Mobile build succeeds (Android)
- [ ] No build warnings or errors

### Functional Verification
- [ ] Browse Presets dialog still works
- [ ] Drag-drop still works (desktop)
- [ ] Preset actions (load, append, export) still work
- [ ] No runtime errors

---

## Testing Plan

### 1. Before Deletion (Baseline)

```bash
# Verify current state works
flutter run -d macos
```

**Manual Test:**
- Open Browse Presets dialog
- Test drag-drop functionality
- Test preset load action
- Test preset export action
- Everything should work

### 2. After Enum Extraction

```bash
# After creating lib/models/preset_action.dart
flutter analyze
flutter test
```

**Manual Test:**
- Repeat functional tests
- Everything should still work

### 3. After Import Updates

```bash
# After updating all imports
flutter analyze
flutter test
```

**Manual Test:**
- Repeat functional tests
- Everything should still work

### 4. After Deletion

```bash
# After deleting load_preset_dialog.dart
flutter analyze
flutter test
flutter build macos
flutter build apk
```

**Manual Test:**
- Full regression test
- Browse Presets dialog works
- Drag-drop works (desktop)
- All preset actions work
- No errors in console

---

## Potential Issues and Solutions

### Issue 1: Other Files Import LoadPresetDialog

**Symptom:** Build fails with import errors after deletion

**Diagnosis:**
```bash
grep -r "import.*load_preset_dialog" lib/
```

**Solution:** Update all imports to use `models/preset_action.dart`

### Issue 2: LoadPresetDialog Widget Still Referenced

**Symptom:** Build fails with undefined class errors

**Diagnosis:**
```bash
grep -r "LoadPresetDialog(" lib/
```

**Solution:** Migrate those usages to `PresetBrowserDialog` before deletion

### Issue 3: Tests Reference LoadPresetDialog

**Symptom:** Tests fail after deletion

**Diagnosis:**
```bash
grep -r "LoadPresetDialog" test/
```

**Solution:** Update tests to import `preset_action.dart` or use `PresetBrowserDialog`

### Issue 4: Git Conflicts

**Symptom:** Merge conflicts when deleting file

**Solution:**
```bash
git rm lib/ui/widgets/load_preset_dialog.dart
git commit -m "Remove obsolete LoadPresetDialog"
```

---

## Regression Testing

After completing all steps, perform full regression testing:

### Desktop (macOS)
- [ ] App launches
- [ ] Browse Presets dialog opens
- [ ] Drag-drop works
- [ ] Package installation works
- [ ] Preset load action works
- [ ] Preset export action works

### Mobile (Android)
- [ ] App launches
- [ ] Browse Presets dialog opens
- [ ] Preset browsing works
- [ ] No drag-drop UI (expected)
- [ ] Preset actions work

### Code Quality
- [ ] `flutter analyze` passes
- [ ] `flutter test` passes
- [ ] No console warnings
- [ ] No deprecation warnings

---

## Git Workflow

### Commit Strategy

**Option A: Single Commit**
```bash
# Create enum file
# Update imports
# Delete old file
git add lib/models/preset_action.dart
git add lib/ui/widgets/preset_browser_dialog.dart
# Add other modified files
git rm lib/ui/widgets/load_preset_dialog.dart
git commit -m "Epic 3: Remove obsolete LoadPresetDialog, extract PresetAction enum

- Create lib/models/preset_action.dart with PresetAction enum
- Update imports in preset_browser_dialog.dart
- Remove obsolete load_preset_dialog.dart
- Epic 3 migration complete"
```

**Option B: Multiple Commits (Safer)**
```bash
# Commit 1: Extract enum
git add lib/models/preset_action.dart
git commit -m "Extract PresetAction enum to models directory"

# Commit 2: Update imports
git add lib/ui/widgets/preset_browser_dialog.dart
# Add other modified files
git commit -m "Update imports to use new PresetAction location"

# Commit 3: Delete old file
git rm lib/ui/widgets/load_preset_dialog.dart
git commit -m "Remove obsolete LoadPresetDialog widget"
```

---

## Definition of Done

- [ ] PresetAction enum extracted to `lib/models/preset_action.dart`
- [ ] All imports updated to reference new location
- [ ] No references to `LoadPresetDialog` widget remain
- [ ] `load_preset_dialog.dart` file deleted
- [ ] `flutter analyze` passes with zero warnings
- [ ] All tests pass
- [ ] Desktop build succeeds
- [ ] Mobile build succeeds
- [ ] Manual smoke test passes
- [ ] Epic 3 migration fully complete

---

## Success Criteria

### Code Cleanliness
- ✅ Obsolete code removed
- ✅ No unused imports
- ✅ Clear separation of concerns
- ✅ Consistent project structure

### Functionality Preserved
- ✅ All features still work
- ✅ No regressions introduced
- ✅ Preset actions still available
- ✅ Drag-drop functionality intact

### Quality Standards
- ✅ Zero `flutter analyze` warnings
- ✅ All tests passing
- ✅ Builds succeed on all platforms
- ✅ Code follows project conventions

---

## Post-Completion Verification

### Final Checks

```bash
# Verify file structure
ls lib/models/preset_action.dart
ls lib/ui/widgets/load_preset_dialog.dart  # Should not exist

# Verify no references remain
grep -r "LoadPresetDialog" lib/ test/

# Verify builds
flutter build macos --release
flutter build apk --release

# Verify code quality
flutter analyze
flutter test
```

### Manual Verification

1. Launch app on macOS
2. Open Browse Presets dialog
3. Test drag-drop installation
4. Verify all preset actions work
5. No console errors

---

## Related Changes

### Updated in Epic 3

- **E3.1**: Added drag-drop to PresetBrowserDialog
- **E3.2**: Added package analysis handling
- **E3.3**: Added conflict detection
- **E3.4**: Integrated PackageInstallDialog
- **E3.5**: Verified installation flow
- **E3.6**: Verified cross-platform compatibility
- **E3.7 (this story)**: Remove obsolete LoadPresetDialog

---

## Future Considerations

### Potential Enhancements (Outside Epic 3 Scope)

1. **Enhanced PresetAction Enum**
   - Could add more actions in the future
   - Consider adding metadata to enum values

2. **Action Handlers**
   - Could create action handler classes
   - Separate action logic from UI

3. **Testing**
   - Unit tests for PresetAction enum
   - Integration tests for preset actions

---

## References

- **Story File:** `/Users/nealsanche/nosuch/nt_helper/docs/stories/e3-7-remove-obsolete-loadpresetdialog.md`
- **Epic Context:** `/Users/nealsanche/nosuch/nt_helper/docs/epic-3-context.md`
- **File to Delete:** `/Users/nealsanche/nosuch/nt_helper/lib/ui/widgets/load_preset_dialog.dart`
- **File to Create:** `/Users/nealsanche/nosuch/nt_helper/lib/models/preset_action.dart`
- **PresetBrowserDialog:** `/Users/nealsanche/nosuch/nt_helper/lib/ui/widgets/preset_browser_dialog.dart`
- **Previous Story:** E3.6 - Verify Cross-Platform Compatibility
- **Epic:** Epic 3 - Drag-and-Drop Preset Package Installation
