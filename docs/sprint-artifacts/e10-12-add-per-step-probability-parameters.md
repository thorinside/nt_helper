# Story 10.12: Add Per-Step Probability Parameters to Global Mode Selector

Status: drafted

## Story

As a **Step Sequencer user**,
I want **Mute, Skip, Reset, and Repeat probability parameters in the global mode selector**,
so that **I can edit probabilities across all steps using the same bar interaction as other parameters**.

## Acceptance Criteria

1. Add Mute, Skip, Reset, Repeat modes to global parameter mode selector
2. Each probability mode shows as colored button (consistent with existing modes)
3. When in probability mode, step bars show vertical percentage bars (0-100%)
4. Dragging/tapping bar sets probability value (0% bottom, 100% top)
5. All probability changes update hardware via debounced `updateParameterValue()`
6. Parameter values load correctly from hardware on sequence switch
7. Offline mode: changes persist and sync when reconnected
8. Bar colors distinguish each probability type (red/pink/orange/cyan)

## Tasks / Subtasks

- [ ] Add probability modes to global parameter selector (AC: #1, #2, #8)
  - [ ] Add `StepParameter.mute` to enum (Color: 0xFFef4444 red)
  - [ ] Add `StepParameter.skip` to enum (Color: 0xFFec4899 pink)
  - [ ] Add `StepParameter.reset` to enum (Color: 0xFFf59e0b orange)
  - [ ] Add `StepParameter.repeat` to enum (Color: 0xFF06b6d4 cyan)
  - [ ] Add mode buttons to `_buildGlobalParameterModeSelector()` widget

- [ ] Verify bar visualization for probabilities (AC: #3, #4)
  - [ ] Verify `PitchBarPainter` handles probability modes with vertical bar
  - [ ] Confirm bar scales 0-100 (bottom to top)
  - [ ] Verify `_handleBarInteraction()` maps to 0-100 range

- [ ] Add parameter discovery for probabilities (AC: #5, #6)
  - [ ] Extend `StepSequencerParams` with `getMute(step)` method
  - [ ] Extend with `getSkip(step)`, `getReset(step)`, `getRepeat(step)` methods
  - [ ] Discover parameter names: "N:Mute", "N:Skip", "N:Reset", "N:Repeat"
  - [ ] Log warnings if parameters not found (firmware version may not support)

- [ ] Test integration (AC: #5, #6, #7)
  - [ ] Test debounced parameter writes (50ms delay)
  - [ ] Test offline mode: change probabilities → reconnect → sync
  - [ ] Test sequence switching: verify probabilities load correctly
  - [ ] Test bar interaction: 0% (bottom) to 100% (top) mapping

## Dev Notes

### Global Mode Selector Extension

From Story 10.9, the global mode selector already exists (no "Edit:" label). We're adding 4 new modes:

```dart
// In step_sequencer_view.dart (already implemented in e10-9)
Widget _buildGlobalParameterModeSelector() {
  return SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        // Existing modes from e10-9
        _buildModeButton(StepParameter.pitch, 'Pitch', Color(0xFF14b8a6)),
        _buildModeButton(StepParameter.velocity, 'Velocity', Color(0xFF10b981)),
        _buildModeButton(StepParameter.mod, 'Mod', Color(0xFF8b5cf6)),
        _buildModeButton(StepParameter.division, 'Division', Color(0xFFf97316)),
        _buildModeButton(StepParameter.pattern, 'Pattern', Color(0xFF3b82f6)),
        _buildModeButton(StepParameter.ties, 'Ties', Color(0xFFeab308)),

        // NEW: Probability modes (Story 10.12)
        _buildModeButton(StepParameter.mute, 'Mute', Color(0xFFef4444)),
        _buildModeButton(StepParameter.skip, 'Skip', Color(0xFFec4899)),
        _buildModeButton(StepParameter.reset, 'Reset', Color(0xFFf59e0b)),
        _buildModeButton(StepParameter.repeat, 'Repeat', Color(0xFF06b6d4)),
      ],
    ),
  );
}
```

### Parameter Semantics from Manual (Page 296)

| Parameter | Min | Max | Default | Unit | Description |
|-----------|-----|-----|---------|------|-------------|
| Mute | 0 | 100 | 0 | % | Probability step will be muted (no output) |
| Skip | 0 | 100 | 0 | % | Probability step will be skipped (advance without playing) |
| Reset | 0 | 100 | 0 | % | Probability step causes reset to Start step |
| Repeat | 0 | 100 | 0 | % | Probability step will be repeated (play twice) |

**Behavioral Differences:**
- **Mute**: Step executes but produces no output (gate stays low)
- **Skip**: Step is skipped entirely, sequencer advances to next step
- **Reset**: Step triggers jump back to Start step parameter
- **Repeat**: Step plays again before advancing

### Bar Visualization

Probability parameters use standard vertical bar painting (same as Pitch, Velocity, Mod):

```dart
// In pitch_bar_painter.dart (from e10-9)
@override
void paint(Canvas canvas, Size size) {
  if (displayMode == StepParameter.ties || displayMode == StepParameter.pattern) {
    _paintBitPattern(canvas, size, value, barColor);
  } else if (displayMode == StepParameter.division) {
    _paintDivisionBar(canvas, size, value.clamp(0, 14), barColor);
  } else {
    // Probabilities use this path (0-100 vertical bar)
    _paintVerticalBar(canvas, size, value, barColor);
  }
}
```

**No special visualization needed** - probabilities reuse existing vertical bar painter.

### Parameter Discovery Extension

```dart
// In step_sequencer_params.dart
class StepSequencerParams {
  // ... existing code ...

  // Probability parameter getters (NEW)
  int? getMute(int step) => getStepParam(step, 'Mute');
  int? getSkip(int step) => getStepParam(step, 'Skip');
  int? getReset(int step) => getStepParam(step, 'Reset');
  int? getRepeat(int step) => getStepParam(step, 'Repeat');
}
```

**Parameter naming patterns to try** (in `getStepParam`):
- "N:Mute", "N:Skip", "N:Reset", "N:Repeat" (hardware format from e10-9)
- Falls back to existing pattern matching logic

### Parameter Constraints

From Story 10.11, probability constraints are added to `StepParameterConstraints`:

```dart
StepParameter.mute: ParameterRange(min: 0, max: 100),
StepParameter.skip: ParameterRange(min: 0, max: 100),
StepParameter.reset: ParameterRange(min: 0, max: 100),
StepParameter.repeat: ParameterRange(min: 0, max: 100),
```

Bar interaction automatically maps 0% (bottom) → 0, 100% (top) → 100.

### Testing Strategy

**Unit Tests:**
```dart
test('getMute returns correct parameter index', () {
  final params = StepSequencerParams.fromSlot(mockSlot);
  expect(params.getMute(1), isNotNull);
});
```

**Widget Tests:**
```dart
testWidgets('Mute mode shows vertical bar 0-100%', (tester) async {
  await tester.pumpWidget(createStepColumn(
    activeParameter: StepParameter.mute,
    muteValue: 50, // 50%
  ));

  final painter = tester.widget<CustomPaint>(find.byType(CustomPaint)).painter as PitchBarPainter;
  expect(painter.displayMode, equals(StepParameter.mute));
  expect(painter.value, equals(50));
  expect(painter.barColor, equals(Color(0xFFef4444))); // Red
});
```

**Integration Tests:**
```dart
testWidgets('Switching to Mute mode changes all step bars', (tester) async {
  await tester.pumpWidget(createApp());

  // 1. Initially in Pitch mode
  expect(find.text('Pitch').first, findsOneWidget);

  // 2. Switch to Mute mode
  await tester.tap(find.text('Mute'));
  await tester.pumpAndSettle();

  // 3. Verify all step bars now show Mute values
  // (All bars rebuild with displayMode = StepParameter.mute)
  final painters = tester.widgetList<CustomPaint>(find.byType(CustomPaint));
  for (final paintWidget in painters) {
    final painter = paintWidget.painter as PitchBarPainter;
    expect(painter.displayMode, equals(StepParameter.mute));
  }
});
```

### Project Structure Notes

**New Files:**
- None (reuses global mode selector from e10-9)

**Modified Files:**
- `lib/ui/step_sequencer_view.dart` - Add 4 probability mode buttons (already has selector from e10-9)
- `lib/services/step_sequencer_params.dart` - Add getMute/Skip/Reset/Repeat methods
- `lib/services/step_parameter_constraints.dart` - Add probability ranges (from e10-11)

**Dependencies:**
- Story 10.9 (global mode selector) MUST be completed first
- Story 10.11 (parameter constraints) should be completed first

### References

- [Source: docs/step-sequencer-documentation-pages-294-300.txt#Step-parameters] - Probability parameter specs
- [Source: User feedback] - Global mode selector approach
- [Source: lib/ui/step_sequencer_view.dart] - Global mode selector widget (from e10-9)
- [Source: lib/services/step_sequencer_params.dart] - Parameter discovery service

## Dev Agent Record

### Context Reference

<!-- Will be added by story-context workflow -->

### Agent Model Used

<!-- Will be filled during implementation -->

### Debug Log References

### Completion Notes List

### File List
