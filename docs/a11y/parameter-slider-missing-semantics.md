# Parameter Slider Missing Semantics

**Severity: Critical**

## Files Affected
- `lib/ui/widgets/parameter_view_row.dart` (lines 283-315)

## Description

The main `Slider` widget used for adjusting every algorithm parameter has no `Semantics` wrapper providing a meaningful label. Flutter's built-in `Slider` does expose its value to the accessibility tree, but the screen reader will only announce something like "50%, adjustable" without any context about *which* parameter is being adjusted.

The parameter name (e.g., "Frequency", "Resonance", "Decay") is displayed as a `Text` widget in a sibling `Expanded` column (line 199), but it is not semantically associated with the slider. A VoiceOver/TalkBack user swiping through the interface will hear the name and slider as separate, unrelated elements.

## Impact on Blind Users

- When navigating by swipe, a blind user hears "Frequency" then separately "50%, adjustable" with no connection between them
- With many parameters on screen (10-30+ is common), users cannot tell which slider they are adjusting
- The slider's current value is announced as a raw percentage of the slider range, not the actual parameter value (e.g., "C4" for a note, "120 BPM", "2.5V")
- The alternate +/- editor buttons (lines 254-281) are announced as just "-" and "+" with no parameter context

## Recommended Fix

Wrap each parameter row in a `Semantics` widget that groups the name, slider, and value display together, and provide a meaningful label:

```dart
Semantics(
  label: '${cleanTitle(widget.name)} parameter',
  value: _getAccessibleValueString(), // "C4", "120 BPM", "50%", etc.
  slider: true,
  child: rowContent,
)
```

For the slider itself, use `Slider.adaptive` or wrap with `Semantics`:

```dart
Semantics(
  label: cleanTitle(widget.name),
  value: _getAccessibleValueString(),
  increasedValue: _getAccessibleValueString(currentValue + 1),
  decreasedValue: _getAccessibleValueString(currentValue - 1),
  child: Slider(...)
)
```

For the +/- buttons, add semantic labels:

```dart
Semantics(
  button: true,
  label: 'Decrease ${cleanTitle(widget.name)}',
  child: OutlinedButton(child: const Text("-")),
)
```
