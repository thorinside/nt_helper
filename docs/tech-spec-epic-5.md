# nt_helper - Technical Specification

**Author:** Neal
**Date:** 2025-10-29
**Project Level:** 1
**Project Type:** software
**Development Context:** brownfield

---

## Source Tree Structure

### Modified Files

**Core Widget (Primary Changes)**
- `lib/ui/widgets/packed_mapping_data_editor.dart` - Add debounced optimistic update logic for form fields on the currently selected tab

**Supporting Files (No Changes)**
- `lib/ui/widgets/mapping_editor_bottom_sheet.dart` - No changes required (already passes onSave callback)
- `lib/ui/widgets/mapping_edit_button.dart` - No changes required (already handles saveMapping call)
- `lib/models/packed_mapping_data.dart` - No changes required (copyWith pattern already supports optimistic updates)
- `lib/cubit/disting_cubit.dart` - No changes required (saveMapping method already exists)

### New Files

None required - all changes are contained within the existing `PackedMappingDataEditor` widget.

### Test Files

**Modified**
- `test/ui/widgets/packed_mapping_data_editor_test.dart` - Add tests for debounced optimistic updates

**New**
- None required

---

## Technical Approach

### Overview

Transform the `PackedMappingDataEditor` from a manual-save model to an optimistic update model where changes are automatically persisted ~1 second after the user stops interacting with form fields on the currently selected tab.

### Key Principles

1. **Tab-Scoped Updates**: Only fields on the currently visible tab trigger optimistic updates
2. **Debounced Persistence**: Use a 1-second debounce timer to batch rapid changes
3. **Silent Failure Handling**: Retry failed saves silently, then stop retrying without user notification
4. **No Save Button Removal**: Keep the existing Save button for explicit save operations (allows users to manually trigger save if desired)

### Implementation Strategy

**1. Debounce Mechanism**
- Add a `Timer?` field to track the active debounce timer
- On each form field change, cancel any existing timer and start a new 1-second countdown
- When timer fires, call the `onSave` callback with current data

**2. Change Detection**
- Leverage existing state update mechanisms (`setState` with `_data.copyWith`)
- Hook into dropdown `onSelected` callbacks
- Hook into Switch `onChanged` callbacks
- Hook into TextField value changes (use `onChanged` instead of `onSubmitted`)

**3. Error Handling**
- Implement retry logic with exponential backoff (attempt 2-3 times)
- After retries exhausted, silently abandon the save attempt
- No user-facing error messages or notifications

**4. Tab Awareness**
- Track the currently selected tab via `_tabController.index`
- Only trigger optimistic saves for fields on the active tab
- Tab switching does not trigger saves (only field value changes do)

---

## Implementation Stack

### Language & Framework
- **Dart**: 3.x (as specified in project's pubspec.yaml)
- **Flutter**: 3.x (as specified in project's pubspec.yaml)

### Core Dependencies
- **flutter/material.dart**: UI components (already imported)
- **dart:async**: Timer class for debouncing
- **flutter_bloc**: 8.x (already in use for state management)

### Architecture Patterns
- **Stateful Widget**: `PackedMappingDataEditor` already uses `StatefulWidget`
- **Debounce Pattern**: Timer-based debouncing for optimistic updates
- **Retry Pattern**: Simple retry with exponential backoff for error handling

### State Management
- **Local State**: Widget-level state via `setState` (existing pattern)
- **Global State**: BLoC pattern via `DistingCubit.saveMapping` (existing pattern)

### No New Dependencies Required
All required functionality is available in existing dependencies.

---

## Technical Details

### PackedMappingDataEditor Widget Modifications

#### New Instance Variables
```dart
Timer? _debounceTimer;
int _retryCount = 0;
static const _maxRetries = 3;
static const _debounceDuration = Duration(seconds: 1);
```

#### New Method: Trigger Optimistic Save
```dart
void _triggerOptimisticSave() {
  // Cancel any existing timer
  _debounceTimer?.cancel();

  // Start new debounce timer
  _debounceTimer = Timer(_debounceDuration, () {
    _attemptSave();
  });
}

Future<void> _attemptSave({int attempt = 0}) async {
  try {
    // Update controllers before saving to ensure consistency
    _updateVoltsFromController();
    _updateDeltaFromController();
    _updateMidiCcFromController();
    _updateMidiMinFromController();
    _updateMidiMaxFromController();
    _updateI2cCcFromController();
    _updateI2cMinFromController();
    _updateI2cMaxFromController();

    widget.onSave(_data);
    _retryCount = 0; // Reset retry count on success
  } catch (e) {
    if (attempt < _maxRetries) {
      // Exponential backoff: 100ms, 200ms, 400ms
      final delay = Duration(milliseconds: 100 * (1 << attempt));
      await Future.delayed(delay);
      await _attemptSave(attempt: attempt + 1);
    }
    // Silent failure after max retries
  }
}
```

#### dispose() Method Update
```dart
@override
void dispose() {
  _debounceTimer?.cancel(); // Add this line
  _tabController.dispose();
  // ... existing controller disposal code
  super.dispose();
}
```

#### Field Update Pattern

Each field update callback should call `_triggerOptimisticSave()` after updating state:

**Example: CV Dropdown**
```dart
onSelected: (newValue) {
  if (newValue == null) return;
  setState(() {
    _data = _data.copyWith(cvInput: newValue);
  });
  _triggerOptimisticSave(); // Add this line
}
```

**Example: Switch**
```dart
onChanged: (val) {
  setState(() {
    _data = _data.copyWith(isUnipolar: val);
  });
  _triggerOptimisticSave(); // Add this line
}
```

**Example: TextField**
```dart
// Change TextField onSubmitted to onChanged
TextField(
  // ... existing properties
  onChanged: (_) {
    _updateVoltsFromController();
    _triggerOptimisticSave(); // Add this line
  },
)
```

### Fields Requiring Optimistic Update Hook

#### CV Tab (0)
- Source dropdown
- CV Input dropdown
- Unipolar switch
- Gate switch
- Volts text field
- Delta text field

#### MIDI Tab (1)
- MIDI Channel dropdown
- MIDI Mapping Type dropdown
- MIDI CC text field
- MIDI Enabled switch
- MIDI Symmetric switch
- MIDI Relative switch
- MIDI Min text field
- MIDI Max text field

#### I2C Tab (2)
- I2C CC text field
- I2C Enabled switch
- I2C Symmetric switch
- I2C Min text field
- I2C Max text field

### Important Notes

1. **MIDI Detector Widget**: Does NOT trigger optimistic save (it already updates state, but should remain manual)
2. **Save Button**: Remains functional for explicit saves
3. **Tab Controller**: No listener needed - optimistic saves are triggered by field changes only
4. **Text Field Pattern**: Change from `onSubmitted` to `onChanged` for all numeric fields

---

## Development Setup

### Prerequisites
- Flutter SDK 3.x installed
- Dart SDK 3.x installed
- macOS development environment (as indicated by project structure)
- Disting NT hardware (for end-to-end testing) or mock MIDI setup

### Development Environment
```bash
# Verify Flutter installation
flutter doctor

# Get dependencies (if needed)
flutter pub get

# Run tests
flutter test

# Run app for development
flutter run -d macos --print-dtd
```

### No Additional Setup Required
This feature uses existing dependencies and architecture patterns. No new packages, tools, or configuration changes are needed.

---

## Implementation Guide

### Step 1: Add Required Import
```dart
import 'dart:async'; // Add this import at the top of the file
```

### Step 2: Add Instance Variables
Add these variables to the `PackedMappingDataEditorState` class:

```dart
Timer? _debounceTimer;
int _retryCount = 0;
static const _maxRetries = 3;
static const _debounceDuration = Duration(seconds: 1);
```

### Step 3: Implement Core Methods

Add these two methods to the `PackedMappingDataEditorState` class:

```dart
void _triggerOptimisticSave() {
  _debounceTimer?.cancel();
  _debounceTimer = Timer(_debounceDuration, () {
    _attemptSave();
  });
}

Future<void> _attemptSave({int attempt = 0}) async {
  try {
    _updateVoltsFromController();
    _updateDeltaFromController();
    _updateMidiCcFromController();
    _updateMidiMinFromController();
    _updateMidiMaxFromController();
    _updateI2cCcFromController();
    _updateI2cMinFromController();
    _updateI2cMaxFromController();

    widget.onSave(_data);
    _retryCount = 0;
  } catch (e) {
    if (attempt < _maxRetries) {
      final delay = Duration(milliseconds: 100 * (1 << attempt));
      await Future.delayed(delay);
      await _attemptSave(attempt: attempt + 1);
    }
  }
}
```

### Step 4: Update dispose() Method

Add timer cancellation to the existing `dispose()` method:

```dart
@override
void dispose() {
  _debounceTimer?.cancel(); // ADD THIS LINE FIRST
  _tabController.dispose();
  _voltsController.dispose();
  // ... rest of existing disposal code
  super.dispose();
}
```

### Step 5: Update CV Tab Fields

Add `_triggerOptimisticSave()` to each field's callback in `_buildCvEditor()`:

**Source Dropdown** (line ~180):
```dart
onSelected: (newValue) {
  if (newValue == null) return;
  setState(() {
    _data = _data.copyWith(source: newValue);
  });
  _triggerOptimisticSave(); // ADD THIS LINE
},
```

**CV Input Dropdown** (line ~222):
```dart
onSelected: (newValue) {
  if (newValue == null) return;
  setState(() {
    _data = _data.copyWith(cvInput: newValue);
  });
  _triggerOptimisticSave(); // ADD THIS LINE
},
```

**Unipolar Switch** (line ~259):
```dart
onChanged: (val) {
  setState(() {
    _data = _data.copyWith(isUnipolar: val);
  });
  _triggerOptimisticSave(); // ADD THIS LINE
},
```

**Gate Switch** (line ~272):
```dart
onChanged: (val) {
  setState(() {
    _data = _data.copyWith(isGate: val);
  });
  _triggerOptimisticSave(); // ADD THIS LINE
},
```

**Volts TextField** (line ~280):
Replace the `_buildNumericField` call to add `onChanged`:
```dart
_buildNumericField(
  label: 'Volts',
  controller: _voltsController,
  onSubmit: _updateVoltsFromController,
  onChanged: () {
    _updateVoltsFromController();
    _triggerOptimisticSave();
  },
),
```

**Delta TextField** (line ~285):
```dart
_buildNumericField(
  label: 'Delta',
  controller: _deltaController,
  onSubmit: _updateDeltaFromController,
  onChanged: () {
    _updateDeltaFromController();
    _triggerOptimisticSave();
  },
),
```

### Step 6: Update MIDI Tab Fields

Add `_triggerOptimisticSave()` to each field's callback in `_buildMidiEditor()`:

**MIDI Channel Dropdown** (line ~332):
```dart
onSelected: (newValue) {
  if (newValue == null) return;
  setState(() {
    _data = _data.copyWith(midiChannel: newValue);
  });
  _triggerOptimisticSave(); // ADD THIS LINE
},
```

**MIDI Mapping Type Dropdown** (line ~355):
```dart
onSelected: (newValue) {
  if (newValue == null) return;
  setState(() {
    _data = _data.copyWith(midiMappingType: newValue);
    if (newValue != MidiMappingType.cc) {
      _data = _data.copyWith(isMidiRelative: false);
    }
  });
  _triggerOptimisticSave(); // ADD THIS LINE
},
```

**MIDI Enabled Switch** (line ~400):
```dart
onChanged: (val) {
  setState(() {
    _data = _data.copyWith(isMidiEnabled: val);
  });
  _triggerOptimisticSave(); // ADD THIS LINE
},
```

**MIDI Symmetric Switch** (line ~411):
```dart
onChanged: (val) {
  setState(() {
    _data = _data.copyWith(isMidiSymmetric: val);
  });
  _triggerOptimisticSave(); // ADD THIS LINE
},
```

**MIDI Relative Switch** (line ~426):
```dart
onChanged: _data.midiMappingType == MidiMappingType.cc
    ? (val) {
        setState(() {
          _data = _data.copyWith(isMidiRelative: val);
        });
        _triggerOptimisticSave(); // ADD THIS LINE
      }
    : null,
```

**MIDI CC TextField** (line ~390):
```dart
_buildNumericField(
  label: 'MIDI CC / Note (0–128)',
  controller: _midiCcController,
  onSubmit: _updateMidiCcFromController,
  onChanged: () {
    _updateMidiCcFromController();
    _triggerOptimisticSave();
  },
),
```

**MIDI Min TextField** (line ~447):
```dart
_buildNumericField(
  label: 'MIDI Min',
  controller: _midiMinController,
  onSubmit: _updateMidiMinFromController,
  onChanged: () {
    _updateMidiMinFromController();
    _triggerOptimisticSave();
  },
),
```

**MIDI Max TextField** (line ~452):
```dart
_buildNumericField(
  label: 'MIDI Max',
  controller: _midiMaxController,
  onSubmit: _updateMidiMaxFromController,
  onChanged: () {
    _updateMidiMaxFromController();
    _triggerOptimisticSave();
  },
),
```

### Step 7: Update I2C Tab Fields

Add `_triggerOptimisticSave()` to each field's callback in `_buildI2cEditor()`:

**I2C Enabled Switch** (line ~543):
```dart
onChanged: (val) {
  setState(() {
    _data = _data.copyWith(isI2cEnabled: val);
  });
  _triggerOptimisticSave(); // ADD THIS LINE
},
```

**I2C Symmetric Switch** (line ~554):
```dart
onChanged: (val) {
  setState(() {
    _data = _data.copyWith(isI2cSymmetric: val);
  });
  _triggerOptimisticSave(); // ADD THIS LINE
},
```

**I2C CC TextField** (line ~534):
```dart
_buildNumericField(
  label: 'I2C CC',
  controller: _i2cCcController,
  onSubmit: _updateI2cCcFromController,
  onChanged: () {
    _updateI2cCcFromController();
    _triggerOptimisticSave();
  },
),
```

**I2C Min TextField** (line ~565):
```dart
_buildNumericField(
  label: 'I2C Min',
  controller: _i2cMinController,
  onSubmit: _updateI2cMinFromController,
  onChanged: () {
    _updateI2cMinFromController();
    _triggerOptimisticSave();
  },
),
```

**I2C Max TextField** (line ~570):
```dart
_buildNumericField(
  label: 'I2C Max',
  controller: _i2cMaxController,
  onSubmit: _updateI2cMaxFromController,
  onChanged: () {
    _updateI2cMaxFromController();
    _triggerOptimisticSave();
  },
),
```

### Step 8: Update _buildNumericField Helper

Modify the `_buildNumericField` method to accept an optional `onChanged` callback:

```dart
Widget _buildNumericField({
  required String label,
  required TextEditingController controller,
  required VoidCallback onSubmit,
  VoidCallback? onChanged, // ADD THIS PARAMETER
}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6.0),
    child: TextField(
      keyboardType: TextInputType.number,
      textInputAction: TextInputAction.done,
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      onSubmitted: (_) => onSubmit(),
      onChanged: onChanged != null ? (_) => onChanged() : null, // ADD THIS LINE
    ),
  );
}
```

### Step 9: Verification Checklist

After implementation, verify:
- [ ] Import `dart:async` is added
- [ ] All 4 instance variables are declared
- [ ] Both `_triggerOptimisticSave()` and `_attemptSave()` methods are implemented
- [ ] Timer is cancelled in `dispose()`
- [ ] All 6 CV tab fields trigger optimistic save
- [ ] All 8 MIDI tab fields trigger optimistic save
- [ ] All 5 I2C tab fields trigger optimistic save
- [ ] `_buildNumericField` accepts optional `onChanged` parameter
- [ ] Save button still works for explicit saves

---

## Testing Approach

### Unit Tests

**File**: `test/ui/widgets/packed_mapping_data_editor_test.dart`

#### Test Coverage Areas

1. **Debounce Behavior**
   - Verify that rapid changes trigger only one save after 1 second
   - Verify that timer is cancelled and reset on each change
   - Verify that multiple rapid changes result in final state being saved

2. **Retry Logic**
   - Verify that failed saves retry up to 3 times
   - Verify exponential backoff delays (100ms, 200ms, 400ms)
   - Verify that successful save resets retry count
   - Verify that failures after max retries are silent

3. **Tab-Scoped Updates**
   - Verify that changes on CV tab trigger saves
   - Verify that changes on MIDI tab trigger saves
   - Verify that changes on I2C tab trigger saves
   - Verify that tab switching alone does not trigger saves

4. **Field-Specific Tests**
   - Verify dropdowns trigger optimistic save
   - Verify switches trigger optimistic save
   - Verify text fields trigger optimistic save on value change
   - Verify that all controllers are properly updated before save

5. **Lifecycle Tests**
   - Verify timer is cancelled in dispose()
   - Verify no memory leaks from uncancelled timers

#### Test Implementation Examples

```dart
testWidgets('Debounce: rapid changes trigger single save after 1 second', (tester) async {
  int saveCount = 0;

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: PackedMappingDataEditor(
          initialData: PackedMappingData.filler(),
          slots: [],
          onSave: (_) => saveCount++,
        ),
      ),
    ),
  );

  // Make 5 rapid changes
  for (int i = 0; i < 5; i++) {
    await tester.tap(find.byType(Switch).first);
    await tester.pump(Duration(milliseconds: 100));
  }

  expect(saveCount, 0); // No saves yet

  // Wait for debounce timer
  await tester.pump(Duration(seconds: 1));
  await tester.pump();

  expect(saveCount, 1); // Only one save triggered
});

testWidgets('Timer cancelled on dispose', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: PackedMappingDataEditor(
          initialData: PackedMappingData.filler(),
          slots: [],
          onSave: (_) {},
        ),
      ),
    ),
  );

  // Trigger a change to start timer
  await tester.tap(find.byType(Switch).first);
  await tester.pump();

  // Dispose widget
  await tester.pumpWidget(Container());

  // Wait to ensure no save happens
  await tester.pump(Duration(seconds: 2));

  // No crashes or errors expected
});
```

### Integration Tests

**Objective**: Verify end-to-end optimistic update flow with real BLoC

1. **Full Save Flow**
   - User changes field value
   - Wait 1 second
   - Verify `DistingCubit.saveMapping` is called with correct data
   - Verify hardware state is updated

2. **Multi-Field Changes**
   - User changes multiple fields quickly
   - Verify only final state is persisted
   - Verify all field values are correct after save

3. **Tab Switching During Edit**
   - User edits field on CV tab
   - User switches to MIDI tab before save
   - Verify CV change is still saved after debounce

### Manual Testing Checklist

**Test Environment**: macOS with Disting NT hardware connected

1. **Basic Optimistic Update**
   - [ ] Open mapping editor
   - [ ] Change a dropdown value
   - [ ] Wait 1 second without clicking Save
   - [ ] Close editor
   - [ ] Reopen editor
   - [ ] Verify change was persisted

2. **Rapid Changes**
   - [ ] Change same field multiple times quickly
   - [ ] Wait 1 second
   - [ ] Verify only final value is saved

3. **Multi-Field Changes**
   - [ ] Change 3-4 different fields quickly
   - [ ] Wait 1 second
   - [ ] Verify all changes are saved

4. **Tab Switching**
   - [ ] Edit field on CV tab
   - [ ] Switch to MIDI tab immediately
   - [ ] Wait 1 second
   - [ ] Verify CV change was saved

5. **Text Field Input**
   - [ ] Type numeric value in text field
   - [ ] Do not press Enter/Done
   - [ ] Wait 1 second
   - [ ] Verify value is saved and validated

6. **Save Button Still Works**
   - [ ] Change a field
   - [ ] Click Save button immediately (before 1 second)
   - [ ] Verify change is saved immediately
   - [ ] Verify debounce timer is not triggered

7. **Error Scenario** (requires mock/test environment)
   - [ ] Simulate save failure
   - [ ] Verify retry attempts occur
   - [ ] Verify silent failure after max retries
   - [ ] Verify no error messages shown to user

### Performance Testing

1. **Memory**: Verify no timer leaks over extended use
2. **Responsiveness**: Verify UI remains responsive during debounce period
3. **Battery**: Verify no excessive CPU usage from timer operations

### Regression Testing

After implementation:
- [ ] Run full test suite: `flutter test`
- [ ] Run static analysis: `flutter analyze` (must pass with zero warnings)
- [ ] Verify existing manual save functionality still works
- [ ] Verify MIDI detector widget still works correctly
- [ ] Verify all three tabs function correctly

---

## Deployment Strategy

### Pre-Deployment

1. **Code Review**
   - Review all changes to `packed_mapping_data_editor.dart`
   - Verify all 19 field callbacks include `_triggerOptimisticSave()`
   - Verify timer disposal in `dispose()` method
   - Verify `_buildNumericField` signature update

2. **Static Analysis**
   ```bash
   flutter analyze
   ```
   Must pass with zero warnings (per project requirements)

3. **Unit Tests**
   ```bash
   flutter test test/ui/widgets/packed_mapping_data_editor_test.dart
   ```
   All tests must pass

4. **Full Test Suite**
   ```bash
   flutter test
   ```
   All existing tests must continue to pass (no regressions)

### Deployment Steps

This is a Level 1 feature addition to an existing brownfield project. No special deployment procedures are required beyond standard development workflow.

1. **Local Testing**
   - Test on macOS development machine
   - Verify with real Disting NT hardware if available
   - Complete manual testing checklist

2. **Commit Changes**
   ```bash
   git add lib/ui/widgets/packed_mapping_data_editor.dart
   git add test/ui/widgets/packed_mapping_data_editor_test.dart
   git commit -m "feat: Add optimistic updates to Packed Mapping Parameter editor

   - Add 1-second debounced auto-save on field value changes
   - Apply optimistic updates to all CV, MIDI, and I2C tab fields
   - Implement silent retry logic with exponential backoff
   - Keep Save button for explicit saves
   - Add comprehensive unit tests for debounce and retry behavior

   🤖 Generated with [Claude Code](https://claude.com/claude-code)

   Co-Authored-By: Claude <noreply@anthropic.com>"
   ```

3. **Push to Remote**
   ```bash
   git push
   ```

4. **Version Bump** (if creating release)
   ```bash
   ./version patch && git push && git push --tags
   ```

### Post-Deployment

1. **Monitoring**
   - Monitor for any crash reports related to timer lifecycle
   - Watch for user feedback on auto-save behavior
   - Monitor performance metrics for timer overhead

2. **User Communication** (if needed)
   - Update release notes to mention optimistic update feature
   - Note that Save button is still available for immediate saves
   - Explain 1-second auto-save delay

3. **Rollback Plan**
   If issues arise, the feature can be rolled back by:
   - Removing `_triggerOptimisticSave()` calls from all field callbacks
   - Removing debounce timer and retry logic
   - Reverting to manual Save button only
   - Original functionality is preserved via Save button

### Risk Assessment

**Low Risk** - This is an additive feature that:
- Does not remove existing functionality (Save button remains)
- Uses well-established patterns (debouncing, retry logic)
- Has isolated scope (single widget file)
- Includes timer cleanup in dispose()
- Can be easily rolled back if needed

### Success Metrics

Post-deployment, consider tracking:
- User feedback on auto-save experience
- Reduction in explicit Save button usage
- Any reported issues with data persistence
- Performance impact (memory/CPU usage)
