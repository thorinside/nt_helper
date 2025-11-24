# Story 10.17: Use Firmware Enum Strings for Dropdowns

Status: done
Completed: 2025-11-23

## Story

As a **Step Sequencer user**,
I want **dropdown lists to display firmware-provided enum strings**,
So that **parameter options match exactly what the hardware uses, stay synchronized across firmware versions, and display correctly localized text if available**.

## Acceptance Criteria

### AC1: Enum String Discovery

Parameter info from firmware includes enum strings for discrete parameters:
- **Direction parameter**: Enum strings like "Forward", "Reverse", "Pendulum", "Random", "Brownian", "1-Shot"
- **Permutation parameter**: Enum strings like "None", "Variation 1", "Variation 2", "Variation 3"
- **Sequence parameter**: Enum strings like "1", "2", "3", ... "32" (or possibly named sequences)
- **Gate Type parameter**: Enum strings like "Gate", "Trigger"
- **Randomise What parameter**: Enum strings like "Nothing", "Pitches", "Rhythm", "Both"
- **Note Distribution parameter**: Enum strings like "Uniform", "Normal"

**Firmware Data Source:**
- Enum strings come from parameter info metadata (same as standard parameter editor)
- Available in `ParameterInfo.enumStrings` or similar field
- Strings provided by firmware, not hardcoded in app

### AC2: Replace Hardcoded Direction Dropdown

Current Direction dropdown uses hardcoded strings:
```dart
// CURRENT (hardcoded):
DropdownButtonFormField(
  items: [
    DropdownMenuItem(value: 0, child: Text('Forward')),
    DropdownMenuItem(value: 1, child: Text('Reverse')),
    // ... etc (hardcoded)
  ],
)
```

**Replace with firmware-driven approach:**
```dart
// NEW (firmware-driven):
DropdownButtonFormField(
  items: _buildEnumDropdownItems(params.direction!),
)

List<DropdownMenuItem<int>> _buildEnumDropdownItems(int paramNumber) {
  final paramInfo = slot.parameters[paramNumber];
  final enumStrings = paramInfo.enumStrings; // From firmware

  return List.generate(
    enumStrings.length,
    (index) => DropdownMenuItem(
      value: index,
      child: Text(enumStrings[index]),
    ),
  );
}
```

### AC3: Replace Hardcoded Permutation Dropdown

Current Permutation dropdown uses hardcoded strings ("None", "Variation 1", "Variation 2", "Variation 3").

**Replace with firmware enum strings:**
- Read enum strings from Permutation parameter info
- Build dropdown items dynamically
- Handle firmware variations (some versions may have different labels)

### AC4: Replace Hardcoded Sequence Selector

Current Sequence selector uses hardcoded 1-32 numbers.

**Replace with firmware enum strings (if available):**
- Check if Sequence parameter has enum strings
- If yes: Use firmware strings (may include sequence names)
- If no: Fall back to numeric labels "1", "2", "3", ... "32"

### AC5: Replace Hardcoded Gate Type Toggle

Current Gate Type toggle uses hardcoded strings ("Gate", "Trigger").

**Replace with firmware enum strings:**
- Read enum strings from Gate Type parameter info
- Build toggle segments dynamically
- Typically 2 strings, but handle variable count if firmware changes

### AC6: Replace Hardcoded Randomize Settings Dropdowns

Randomize settings dialog uses hardcoded strings for:
- **Randomise What**: "Nothing", "Pitches", "Rhythm", "Both"
- **Note Distribution**: "Uniform", "Normal"

**Replace with firmware enum strings:**
- Read from parameter info for each parameter
- Build dropdowns dynamically
- Handle missing enum strings gracefully (fall back to numeric values)

### AC7: Enum String Fallback Handling

Handle cases where firmware doesn't provide enum strings:
- **No enum strings available**: Fall back to numeric labels ("0", "1", "2", ...)
- **Fewer enum strings than values**: Use numeric labels for missing values
- **Empty enum string**: Use numeric label for that index

**Fallback Logic:**
```dart
String getEnumStringOrFallback(ParameterInfo param, int value) {
  if (param.enumStrings.isEmpty) {
    return value.toString(); // Fallback to number
  }

  if (value >= 0 && value < param.enumStrings.length) {
    final enumString = param.enumStrings[value];
    return enumString.isNotEmpty ? enumString : value.toString();
  }

  return value.toString(); // Out of range fallback
}
```

### AC8: Dynamic Dropdown Item Count

Dropdowns adapt to firmware-provided enum count:
- **Direction**: May have 6-10 options depending on firmware version
- **Permutation**: Currently 4 options, but may change
- **Sequence**: 32 options (or more in future firmware)
- Dropdown item count = enum strings length (or parameter max value + 1)

**No hardcoded counts:**
- Don't assume Direction has exactly 6 options
- Don't assume Permutation has exactly 4 options
- Read actual count from firmware metadata

### AC9: Consistency with Standard Parameter Editor

Step Sequencer dropdowns use same enum string logic as standard parameter editor:
- Reuse existing enum string extraction code (if available)
- Consistent behavior: if parameter editor shows "Brownian", Step Sequencer shows "Brownian"
- Leverage existing `ParameterInfo` infrastructure
- No duplicate enum string handling code

### AC10: Firmware Version Compatibility

Enum-driven dropdowns work across firmware versions:
- **Old firmware**: May have fewer Direction options (e.g., no "Brownian")
- **New firmware**: May add new Direction options
- **Future firmware**: May rename or add options
- App adapts automatically without code changes

## Tasks / Subtasks

- [ ] **Task 1: Investigate Existing Enum String Infrastructure** (AC: #9)
  - [ ] Check if `ParameterInfo` class includes enum strings field
  - [ ] Find how standard parameter editor uses enum strings (if at all)
  - [ ] Locate any existing helper methods for building enum dropdowns
  - [ ] Document current parameter info structure (fields available)
  - [ ] If enum strings not available, investigate SysEx request for parameter metadata

- [ ] **Task 2: Add Enum String Helper Method** (AC: #7)
  - [ ] Create `_getEnumStringOrFallback(ParameterInfo param, int value)` helper
  - [ ] Handle missing enum strings (return numeric string)
  - [ ] Handle out-of-range values (return numeric string)
  - [ ] Handle empty enum strings (return numeric string)
  - [ ] Add unit tests for all fallback cases

- [ ] **Task 3: Create Dynamic Dropdown Builder** (AC: #2, #8)
  - [ ] Create `_buildEnumDropdownItems(int paramNumber)` method:
    - [ ] Read parameter info from slot
    - [ ] Extract enum strings
    - [ ] Generate DropdownMenuItem list dynamically
    - [ ] Use enum string or fallback for each item
  - [ ] Handle variable item counts (don't hardcode length)
  - [ ] Test with parameters that have different enum string counts

- [ ] **Task 4: Replace Direction Dropdown with Enum-Driven Version** (AC: #2)
  - [ ] Modify `_buildDirectionDropdown()` in `playback_controls.dart`
  - [ ] Remove hardcoded Direction strings ("Forward", "Reverse", etc.)
  - [ ] Use `_buildEnumDropdownItems(params.direction!)`
  - [ ] Verify dropdown shows correct firmware strings
  - [ ] Test with different firmware versions (if available)
  - [ ] Verify current selection still works correctly

- [ ] **Task 5: Replace Permutation Dropdown with Enum-Driven Version** (AC: #3)
  - [ ] Modify `_buildPermutationDropdown()` in `playback_controls.dart`
  - [ ] Remove hardcoded Permutation strings ("None", "Variation 1", etc.)
  - [ ] Use `_buildEnumDropdownItems(params.permutation!)`
  - [ ] Verify dropdown shows correct firmware strings
  - [ ] Test permutation selection and parameter updates

- [ ] **Task 6: Replace Sequence Selector with Enum-Driven Version** (AC: #4)
  - [ ] Modify sequence selector in `sequencer_header.dart` (or wherever it lives)
  - [ ] Check if Sequence parameter has enum strings
  - [ ] If yes: Use firmware strings
  - [ ] If no: Fall back to numeric labels "1", "2", ..., "32"
  - [ ] Test sequence selection and parameter updates

- [ ] **Task 7: Replace Gate Type Toggle with Enum-Driven Version** (AC: #5)
  - [ ] Modify `_buildGateTypeToggle()` in `playback_controls.dart`
  - [ ] Remove hardcoded Gate Type strings ("Gate", "Trigger")
  - [ ] Read enum strings from Gate Type parameter info
  - [ ] Build SegmentedButton segments dynamically
  - [ ] Handle variable segment counts (if firmware changes)
  - [ ] Test gate type toggle and parameter updates

- [ ] **Task 8: Replace Randomize Settings Dropdowns** (AC: #6)
  - [ ] Modify `randomize_settings_dialog.dart` (when implemented in Story 10.15)
  - [ ] Replace "Randomise What" hardcoded strings with enum strings
  - [ ] Replace "Note Distribution" hardcoded strings with enum strings
  - [ ] Use dynamic dropdown builder for both
  - [ ] Test dropdown item counts match firmware metadata

- [ ] **Task 9: Add Tests for Enum String Handling**
  - [ ] Unit tests for `_getEnumStringOrFallback()`:
    - [ ] Test with valid enum strings
    - [ ] Test with missing enum strings (empty array)
    - [ ] Test with out-of-range value
    - [ ] Test with empty string in array
  - [ ] Unit tests for `_buildEnumDropdownItems()`:
    - [ ] Test with parameter containing enum strings
    - [ ] Test with parameter missing enum strings
    - [ ] Test with variable enum string counts (3, 4, 6, 10 items)
  - [ ] Widget tests for dropdowns:
    - [ ] Test Direction dropdown renders firmware strings
    - [ ] Test Permutation dropdown renders firmware strings
    - [ ] Test dropdown item counts match firmware metadata
    - [ ] Test fallback to numeric labels when enum strings missing

- [ ] **Task 10: Handle Firmware Variations** (AC: #10)
  - [ ] Test with different firmware versions (if available):
    - [ ] Old firmware with fewer Direction options
    - [ ] Current firmware with standard options
    - [ ] Mock future firmware with additional options
  - [ ] Verify dropdowns adapt automatically
  - [ ] Verify no crashes when enum string count changes
  - [ ] Document any firmware version differences discovered

- [ ] **Task 11: Code Quality Validation**
  - [ ] Run `flutter analyze` - must pass with zero warnings
  - [ ] Run all tests: `flutter test` - all tests must pass
  - [ ] Manual testing:
    - [ ] Open playback controls, verify Direction dropdown shows firmware strings
    - [ ] Open playback controls, verify Permutation dropdown shows firmware strings
    - [ ] Open sequence selector, verify sequence options correct
    - [ ] Toggle Gate Type, verify strings match firmware
    - [ ] Compare with standard parameter editor (should match)
  - [ ] Verify no regressions in dropdown behavior

## Dev Notes

### Learnings from Previous Stories

**From Story e10-13 (Permutation and Gate Type Controls):**
- Permutation dropdown currently uses hardcoded strings: "None", "Variation 1", "Variation 2", "Variation 3"
- Gate Type toggle currently uses hardcoded strings: "Gate", "Trigger"
- These should be replaced with firmware enum strings

**From Story e10-6 (Playback Controls):**
- Direction dropdown currently uses hardcoded strings
- Standard parameter editor may already use enum strings (investigate)

### Parameter Info Structure

Based on existing codebase (`lib/domain/disting_nt_sysex.dart`):
```dart
class ParameterInfo {
  final int slotIndex;
  final int parameterNumber;
  final String name;
  final int value;
  final bool disabled;
  final int minValue;
  final int maxValue;
  final String unit;
  // QUESTION: Does ParameterInfo include enumStrings field?
  // If not, where do enum strings come from?
  final List<String>? enumStrings; // May need to add this
}
```

**Investigation needed:**
- Check if `ParameterInfo` already includes enum strings
- If not, investigate how standard parameter editor builds enum dropdowns
- May need to add enum string support to SysEx parameter info request

### Enum String Sources

**Possible sources of enum strings:**
1. **ParameterInfo SysEx response** - Firmware includes enum strings in parameter metadata
2. **Algorithm metadata** - Offline metadata includes enum strings
3. **Hardcoded in standard parameter editor** - App currently hardcodes them (anti-pattern)

**Preferred approach:** Firmware-provided enum strings (source #1)

### Dynamic Dropdown Builder Pattern

**Reusable helper for building enum dropdowns:**
```dart
class EnumDropdownBuilder {
  static List<DropdownMenuItem<int>> buildItems({
    required ParameterInfo paramInfo,
  }) {
    final enumStrings = paramInfo.enumStrings ?? [];

    if (enumStrings.isEmpty) {
      // Fallback to numeric labels
      return List.generate(
        paramInfo.maxValue - paramInfo.minValue + 1,
        (index) => DropdownMenuItem(
          value: paramInfo.minValue + index,
          child: Text('${paramInfo.minValue + index}'),
        ),
      );
    }

    // Use firmware enum strings
    return List.generate(
      enumStrings.length,
      (index) => DropdownMenuItem(
        value: paramInfo.minValue + index,
        child: Text(enumStrings[index].isNotEmpty
          ? enumStrings[index]
          : '${paramInfo.minValue + index}'),
      ),
    );
  }

  static String getEnumString(ParameterInfo paramInfo, int value) {
    final enumStrings = paramInfo.enumStrings ?? [];
    final index = value - paramInfo.minValue;

    if (index >= 0 && index < enumStrings.length) {
      return enumStrings[index].isNotEmpty
        ? enumStrings[index]
        : value.toString();
    }

    return value.toString(); // Fallback
  }
}
```

### Example: Direction Dropdown Before/After

**BEFORE (hardcoded):**
```dart
DropdownButtonFormField<int>(
  value: currentDirection,
  items: const [
    DropdownMenuItem(value: 0, child: Text('Forward')),
    DropdownMenuItem(value: 1, child: Text('Reverse')),
    DropdownMenuItem(value: 2, child: Text('Pendulum')),
    DropdownMenuItem(value: 3, child: Text('Random')),
    DropdownMenuItem(value: 4, child: Text('Brownian')),
    DropdownMenuItem(value: 5, child: Text('1-Shot')),
  ],
  onChanged: (value) {
    _updateParameter(params.direction!, value!);
  },
)
```

**AFTER (firmware-driven):**
```dart
DropdownButtonFormField<int>(
  value: currentDirection,
  items: _buildEnumDropdownItems(params.direction!),
  onChanged: (value) {
    _updateParameter(params.direction!, value!);
  },
)

// Helper method
List<DropdownMenuItem<int>> _buildEnumDropdownItems(int paramNumber) {
  final paramInfo = slot.parameters[paramNumber];
  return EnumDropdownBuilder.buildItems(paramInfo: paramInfo);
}
```

### Benefits of Firmware-Driven Approach

**Advantages:**
1. **Firmware version compatibility** - New firmware versions can add options without app update
2. **Localization** - Firmware may provide localized strings in future
3. **Consistency** - Step Sequencer matches standard parameter editor exactly
4. **Maintainability** - No hardcoded strings to update when firmware changes
5. **Accuracy** - Always shows exact strings firmware uses (no typos or mismatches)

**Example scenario:**
- Firmware 1.11 adds new Direction option "Euclidean"
- Old app (hardcoded): Dropdown shows "0", "1", "2", "3", "4", "5", "6" (breaks)
- New app (enum-driven): Dropdown shows "Forward", "Reverse", "Pendulum", "Random", "Brownian", "1-Shot", "Euclidean" (works automatically)

### Fallback Strategy

**When enum strings unavailable:**
- Option 1: Show numeric labels ("0", "1", "2", ...)
- Option 2: Show "Option 0", "Option 1", "Option 2", ...
- Option 3: Hide dropdown, show slider instead

**Recommended: Option 1** (numeric labels)
- Simplest fallback
- User can still select values (just not human-readable)
- Degraded UX but functional

### Testing with Mock Firmware

**Create mock parameters with different enum string scenarios:**
```dart
// Mock 1: Standard Direction with 6 options
final mockDirection = ParameterInfo(
  parameterNumber: 10,
  name: 'Direction',
  value: 0,
  minValue: 0,
  maxValue: 5,
  enumStrings: ['Forward', 'Reverse', 'Pendulum', 'Random', 'Brownian', '1-Shot'],
);

// Mock 2: Future Direction with 7 options (added Euclidean)
final mockDirectionFuture = ParameterInfo(
  parameterNumber: 10,
  name: 'Direction',
  value: 0,
  minValue: 0,
  maxValue: 6,
  enumStrings: ['Forward', 'Reverse', 'Pendulum', 'Random', 'Brownian', '1-Shot', 'Euclidean'],
);

// Mock 3: Missing enum strings (fallback test)
final mockDirectionNoEnums = ParameterInfo(
  parameterNumber: 10,
  name: 'Direction',
  value: 0,
  minValue: 0,
  maxValue: 5,
  enumStrings: null, // or []
);
```

### Integration with Standard Parameter Editor

**Investigation tasks:**
1. Check how standard parameter editor (non-Step-Sequencer) renders enum parameters
2. If it uses enum strings, reuse that code
3. If it hardcodes strings, refactor both to use firmware enum strings
4. Ensure consistency: both UIs show same strings for same parameter

**Potential code locations:**
- `lib/ui/widgets/parameter_editor.dart` (or similar)
- `lib/ui/widgets/parameter_list.dart`
- May already have enum dropdown logic to reuse

### Performance Considerations

**Enum string access:**
- Enum strings loaded once per parameter (cached in ParameterInfo)
- No runtime overhead (just array access)
- Dropdown items built once per mode change (not every frame)

**No performance impact expected** - enum strings are lightweight metadata

### References

- Epic: [docs/epics/epic-10.md](../epics/epic-10.md) (Story 17)
- Architecture: [docs/architecture.md](../architecture.md) (Parameter Info structure)
- Previous Story: [docs/stories/e10-16-add-division-subdivision-display.md](e10-16-add-division-subdivision-display.md)
- Related Story: [docs/stories/e10-13-add-permutation-and-gate-type-controls.md](e10-13-add-permutation-and-gate-type-controls.md)
- Parameter Info: `lib/domain/disting_nt_sysex.dart` (ParameterInfo class)

---

## Dev Agent Record

### Context Reference

<!-- Path to story context XML will be added here by context workflow -->

### Agent Model Used

<!-- Will be filled during implementation -->

### Debug Log References

### Completion Notes List

### File List

## Change Log

<!-- Implementation changes will be logged here -->
