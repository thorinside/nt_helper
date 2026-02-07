# Step Sequencer Grid Completely Inaccessible

**Severity: Critical**

**Status: Addressed (2026-02-06)** — step_column_widget.dart has full Semantics wrapper with label/value/hint/onIncrease/onDecrease

## Files Affected
- `lib/ui/widgets/step_sequencer/step_column_widget.dart` (lines 63-193)
- `lib/ui/widgets/step_sequencer/step_grid_view.dart` (lines 50-154)
- `lib/ui/widgets/step_sequencer/pitch_bar_painter.dart` (entire file)

## Description

The step sequencer grid is the primary interface for editing musical sequences - 16 columns representing steps, each with a visual bar showing the current parameter value (pitch, velocity, modulation, etc.). This is rendered using `CustomPaint` with `PitchBarPainter`, which draws directly to a canvas with zero semantic information.

Interactions are entirely gesture-based:
- **Tap on bar** (step_column_widget.dart line 114): Set value based on Y position
- **Vertical drag** (line 121): Continuously adjust value by dragging
- **Drag-to-paint** across steps (step_grid_view.dart lines 89-97, 126-134): Paint values across multiple steps by dragging horizontally

The `CustomPaint` widget produces no accessibility tree nodes. The step number, parameter value text, and warning indicators are plain `Text` widgets with no semantic grouping or labels.

## Impact on Blind Users

- The entire step sequencer grid is invisible to screen readers
- 16 steps x 10 parameter types = 160 editable values with zero accessibility
- This is a core feature for music creation - blind users cannot use it at all
- Drag-to-paint is fundamentally incompatible with screen reader interaction
- The step number text and value text appear as disconnected, unlabeled fragments
- CustomPaint bars have no semantic alternative whatsoever

## Recommended Fix

This requires a fundamental alternative interaction model for screen reader users:

1. **Wrap each step column in Semantics**:

```dart
Semantics(
  label: 'Step ${widget.stepIndex + 1}',
  value: _formatStepValue(_getCurrentParameterValue()),
  hint: 'Swipe up or down to adjust ${widget.activeParameter.name}',
  increasedValue: _formatStepValue(
    (_getCurrentParameterValue() + 1).clamp(_getParameterMin(), _getParameterMax())
  ),
  decreasedValue: _formatStepValue(
    (_getCurrentParameterValue() - 1).clamp(_getParameterMin(), _getParameterMax())
  ),
  onIncrease: () => _updateParameter(
    (_getCurrentParameterValue() + 1).clamp(_getParameterMin(), _getParameterMax())
  ),
  onDecrease: () => _updateParameter(
    (_getCurrentParameterValue() - 1).clamp(_getParameterMin(), _getParameterMax())
  ),
  child: existingContent,
)
```

2. **Add keyboard navigation**: Arrow keys to move between steps, up/down to adjust values

3. **Consider a list-based alternative view** for screen reader users that presents steps as a numbered list with editable fields rather than a visual grid

4. **For the PitchBarPainter**, since `CustomPaint` cannot provide semantics, the `Semantics` wrapper on the parent is essential - the painter itself needs no change, but it must not be the only way to convey information
