# Parameter Row Uses Gesture-Only Interactions

**Severity: High**

## Files Affected
- `lib/ui/widgets/parameter_view_row.dart` (lines 173-209, 216-225)

## Description

The parameter name column uses `GestureDetector` for two interactions:
1. **Double-tap** (line 174): Sets focus on the hardware display to this parameter
2. **Long-press** (line 187): Sets focus on the hardware display

The slider area also uses `GestureDetector` for:
1. **Double-tap** (line 217): Resets parameter to default value

These are `GestureDetector` widgets wrapping `Text` / `Slider`, not `InkWell` or buttons. `GestureDetector` does not participate in the accessibility tree - it has no semantic role, no focusability for keyboard/switch users, and no announcement to screen readers.

Additionally, the "long press on display string to toggle alternate editor" (line 349) is discovered only by accident - there is no indication this action exists.

## Impact on Blind Users

- The "focus on hardware" action is completely undiscoverable and unusable via VoiceOver/TalkBack
- The "reset to default" double-tap on the slider area is undiscoverable
- The "toggle alternate +/- editor" long-press on the value display is undiscoverable
- Switch Access users cannot trigger double-tap or long-press via GestureDetector
- Keyboard users cannot trigger any of these actions

## Recommended Fix

1. Replace `GestureDetector` with semantically meaningful widgets or add `Semantics` with custom actions:

```dart
Semantics(
  label: cleanTitle(widget.name),
  customSemanticsActions: {
    CustomSemanticsAction(label: 'Focus on hardware display'):
        () => _focusOnHardware(),
    CustomSemanticsAction(label: 'Reset to default value'):
        () => _resetToDefault(),
  },
  child: Text(cleanTitle(widget.name), ...),
)
```

2. For the alternate editor toggle, add it as a custom semantic action rather than relying on long-press:

```dart
Semantics(
  customSemanticsActions: {
    CustomSemanticsAction(label: 'Switch to step editor'):
        () => setState(() => _showAlternateEditor = !_showAlternateEditor),
  },
  child: existingValueDisplay,
)
```
