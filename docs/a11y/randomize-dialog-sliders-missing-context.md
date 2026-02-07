# Randomize Dialog Sliders Lack Grouped Labels

**Severity: Medium**

## Files Affected
- `lib/ui/widgets/step_sequencer/randomize_settings_dialog.dart` (lines 339-410)

## Description

The Randomize Settings dialog uses `ListTile` with `Slider` children for parameters like Min note, Max note, probabilities, etc. The `ListTile.title` provides the parameter name and the `Slider.label` shows the value during drag.

The `ListTile` approach is reasonable for accessibility since `ListTile` groups its children. However:
- The `Slider.label` only appears during drag interaction (tooltip-style), not persistently
- The value text below each slider (lines 367, 405) helps but is a separate element
- MIDI note sliders show note names (line 361: `_midiNoteToString`) but this string is only in the drag tooltip and value text, not in the slider's semantic value
- Probability sliders show "X%" (line 395) but the slider itself reports its raw 0-100 value

## Impact on Blind Users

- The overall structure is decent - `ListTile` groups label and slider
- Slider values are announced as raw numbers, not as formatted values (e.g., "60" instead of "C4")
- Multiple similar sliders ("Note probability", "Tie probability") are distinguishable by their ListTile title

## Recommended Fix

Add semantic values to sliders:

```dart
Semantics(
  value: showMidiNote ? _midiNoteToString(value) : '$value',
  child: Slider(
    value: value.toDouble(),
    ...
  ),
)
```
