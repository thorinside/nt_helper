# Step Sequencer Parameter Mode Not Announced on Change

**Severity: High**

**Status: Addressed (2026-02-06)** — in commit 664e27b

## Files Affected
- `lib/ui/widgets/step_sequencer/step_column_widget.dart` (line 36: `activeParameter`)
- `lib/ui/widgets/step_sequencer/step_grid_view.dart` (line 23: `activeParameter`)

## Description

The step sequencer has a global "active parameter" mode that determines what the visual bars represent (pitch, velocity, mod, division, pattern, ties, mute, skip, reset, repeat). This mode is passed down from the parent view and changes the meaning of every step column's visual bar.

When the mode changes:
- All 16 step columns change their color and value display
- The meaning of tap/drag interactions changes entirely
- The value format changes (e.g., MIDI notes vs percentages vs voltage)

However, there is no accessibility announcement when the mode changes. A screen reader user adjusting parameters has no way to know which parameter type they're editing unless they navigate to each step and read its value.

## Impact on Blind Users

- Mode change is silent - the user has no idea what parameter they're now editing
- All step values change simultaneously but no announcement is made
- Color changes (teal for pitch, green for velocity, etc.) are meaningless to screen reader users
- The mode selector UI (not in these files - in the parent view) may or may not be accessible, but even if it is, the grid itself doesn't confirm the change

## Recommended Fix

When the active parameter changes, announce it:

```dart
@override
void didUpdateWidget(StepGridView oldWidget) {
  super.didUpdateWidget(oldWidget);
  if (oldWidget.activeParameter != widget.activeParameter) {
    SemanticsService.announce(
      'Now editing ${widget.activeParameter.name} for all steps',
      TextDirection.ltr,
    );
  }
}
```

Each step column should include the parameter type in its semantic label:

```dart
Semantics(
  label: 'Step ${widget.stepIndex + 1}, '
         '${widget.activeParameter.name}: '
         '${_formatStepValue(_getCurrentParameterValue())}',
  ...
)
```
