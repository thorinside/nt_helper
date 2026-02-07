# Bit Pattern Editor Cells Inaccessible

**Severity: Critical**

**Status: Addressed (2026-02-06)** — in commit 664e27b

## Files Affected
- `lib/ui/widgets/step_sequencer/bit_pattern_editor.dart` (lines 20-62)

## Description

The `BitPatternEditor` displays an 8-cell vertical column where each cell represents a bit in a pattern (used for Pattern and Ties parameters in the step sequencer). Each cell is a `GestureDetector` wrapping an empty `Container` with a colored background indicating on/off state.

These cells have:
- No `Semantics` labels
- No indication of which bit position they represent
- No indication of their current state (on/off)
- No indication of whether they are valid/enabled (the `validBitCount` parameter greys out unused bits but doesn't communicate this)
- `GestureDetector` with `onTap` but no semantic role

## Impact on Blind Users

- The entire Pattern and Ties editing interface is invisible to screen readers
- 8 bits x 16 steps = 128 toggleable cells with zero accessibility
- Screen reader cannot convey the on/off state of any bit
- Invalid/disabled bits (greyed out based on division) are indistinguishable from valid ones
- The musical pattern (which substeps are active) cannot be understood or edited

## Recommended Fix

Wrap each bit cell in `Semantics` with appropriate properties:

```dart
Semantics(
  label: 'Substep ${bitIndex + 1}',
  toggled: isSet,
  enabled: isValid,
  onTap: isValid ? () {
    final newValue = value ^ (1 << bitIndex);
    onChanged(newValue);
  } : null,
  child: GestureDetector(
    ...existing code...
  ),
)
```

Consider also providing a summary at the column level:

```dart
Semantics(
  label: 'Pattern for step ${stepIndex + 1}: $validBitCount substeps, '
         '${_countSetBits(value, validBitCount)} active',
  child: Column(children: ...),
)
```
