# Disabled Parameter State Not Communicated to Screen Readers

**Severity: High**

## Files Affected
- `lib/ui/widgets/parameter_view_row.dart` (lines 159-162)

## Description

When a parameter is disabled (`widget.isDisabled == true`), the row is wrapped in `Opacity(opacity: 0.5)` and `IgnorePointer(ignoring: true)`. While `IgnorePointer` prevents touch interaction, neither `Opacity` nor `IgnorePointer` communicates the disabled state to the accessibility tree.

A screen reader user will still "see" the parameter, its slider, and its value, and will attempt to adjust it - but nothing will happen. There is no indication that the parameter is disabled or why.

## Impact on Blind Users

- Parameters appear interactive but do not respond to screen reader adjustments
- No "dimmed" or "disabled" announcement from VoiceOver/TalkBack
- User may think the app is broken when adjustments don't work
- This pattern appears in every parameter row and the step sequencer playback controls

## Recommended Fix

Wrap the disabled row in a `Semantics` widget or use `ExcludeSemantics` with a replacement label:

```dart
if (widget.isDisabled) {
  return Semantics(
    label: '${cleanTitle(widget.name)}, disabled',
    excludeSemantics: true,
    child: Opacity(opacity: 0.5, child: ...),
  );
}
```

Or use the built-in `enabled` property:

```dart
Semantics(
  enabled: !widget.isDisabled,
  child: rowContent,
)
```
