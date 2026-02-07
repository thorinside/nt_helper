# Parameter Value Display Not Announced on Change

**Severity: Critical**

**Status: Addressed (2026-02-06)** — in commit 664e27b

## Files Affected
- `lib/ui/widgets/parameter_value_display.dart` (lines 51-133)
- `lib/ui/widgets/parameter_view_row.dart` (lines 283-315)

## Description

When a user adjusts a slider, the displayed value changes (e.g., from "C4" to "D4", from "Off" to "On"), but no accessibility announcement is made. The `ParameterValueDisplay` widget renders value text via `Text`, `Checkbox`, or `DropdownMenu`, but none of these are wrapped in a `Semantics` with `liveRegion: true` to trigger screen reader announcements when values change.

Flutter's `Slider` does announce its own value as a percentage, but the actual meaningful display (MIDI note names, formatted units, display strings from hardware) is shown in a separate widget that the screen reader doesn't know to read.

## Impact on Blind Users

- Adjusting a slider gives no audible feedback about the actual parameter value
- Users hear "50%, adjustable" instead of "C4" or "120.0 BPM" or "Reverb Hall"
- The checkbox at line 62 works reasonably well since `Checkbox` has built-in accessibility
- The `DropdownMenu` at line 72 works but lacks a semantic label connecting it to the parameter name
- The display string shown via `GestureDetector > Text` (lines 106-113) has no semantic role at all - it's invisible to screen readers as an interactive element
- MIDI note display (line 93) and MIDI channel display (line 98) are plain `Text` with no semantic label

## Recommended Fix

1. Wrap the value display in a live region so changes are announced:

```dart
Semantics(
  liveRegion: true,
  label: '${widget.name} value',
  child: Text(formattedValue, style: textStyle),
)
```

2. Use `SemanticsService.announce()` when slider values change to provide immediate feedback:

```dart
import 'package:flutter/semantics.dart';

void onSliderChanged(int value) {
  // ... existing throttle logic ...
  SemanticsService.announce(
    '${cleanTitle(widget.name)}: ${_getAccessibleValueString(value)}',
    TextDirection.ltr,
  );
}
```

3. Add semantic label to the GestureDetector display string:

```dart
Semantics(
  label: '${widget.name}: ${displayString}. Long press for alternate editor.',
  child: GestureDetector(
    onLongPress: onLongPress,
    child: Text(displayString!, ...),
  ),
)
```
