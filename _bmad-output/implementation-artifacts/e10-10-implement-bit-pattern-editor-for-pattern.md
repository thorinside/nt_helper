# Story 10.10: Implement Bit Pattern Visualization for Pattern Parameter

Status: drafted

## Story

As a **Step Sequencer user**,
I want **to see and edit Pattern as a visual bit pattern within the step bar when in Pattern mode**,
so that **I can control which substeps are active/muted using the same bar interaction as other parameters**.

## Acceptance Criteria

1. When global parameter mode = "Pattern", step bars show 8-segment bit pattern visualization
2. Each segment represents one bit (substeps 0-7, LSB to MSB)
3. Tapping a step bar in Pattern mode opens bit pattern editor overlay
4. Reuse `BitPatternEditorDialog` widget from Story 10.9 (DRY principle)
5. Bit pattern editor shows 8 toggle buttons with labels
6. Toggling a bit updates the parameter value (0-255) via `updateParameterValue()`
7. Visual indication uses blue color (Color(0xFF3b82f6)) for set bits
8. Pattern editor works with existing debounce system (50ms)
9. Offline mode: changes persist and sync when hardware reconnects

## Tasks / Subtasks

- [ ] Verify global parameter mode system from Story 10.9 (AC: #1)
  - [ ] Ensure `StepParameter.pattern` enum value exists
  - [ ] Verify `_activeParameter` state management in StepSequencerView
  - [ ] Verify Pattern mode button in global mode selector

- [ ] Extend bit pattern visualization for Pattern mode (AC: #1, #2, #7)
  - [ ] Verify `PitchBarPainter` handles `StepParameter.pattern` mode
  - [ ] Use blue color (Color(0xFF3b82f6)) for set bits in Pattern mode
  - [ ] Show bit pattern as 8 stacked horizontal segments (bit 0 at bottom)

- [ ] Integrate bit pattern editor for Pattern (AC: #3, #4, #5, #6)
  - [ ] Reuse `BitPatternEditorDialog` from Story 10.9
  - [ ] When user taps step bar in Pattern mode: show dialog
  - [ ] Pass parameterName = "Pattern" to dialog
  - [ ] Pass blue color to dialog
  - [ ] Wire to `StepSequencerParams.getPattern(step)` parameter

- [ ] Test integration (AC: #6, #8, #9)
  - [ ] Test bit pattern writes correct 0-255 value to hardware
  - [ ] Test hardware value correctly displays as bit pattern
  - [ ] Test with Division > 0 to verify substep muting behavior
  - [ ] Test debouncing (rapid bit toggles → single write after 50ms)
  - [ ] Test offline mode: edits persist, sync on reconnect

## Dev Notes

### Pattern Parameter Semantics

From the manual (Page 297):
> "The pattern setting determines which of the repeats actually output a note. For example, with a division setting of 3, there will be 4 notes per step. A pattern setting of 10 (binary 1010) will output notes on the 2nd and 4th of these."

**Bit Pattern Interpretation:**
- Bit 0 (LSB): Substep 0 active (plays)
- Bit 1: Substep 1 active
- ...
- Bit 7 (MSB): Substep 7 active

**Examples:**
- Pattern = 0b00001010 (10 decimal) → substeps 1 and 3 active, others muted
- Pattern = 0b11111111 (255 decimal) → all substeps active (no muting)
- Pattern = 0b10101010 (170 decimal) → alternating substeps

**Visual Representation in Bar:**
When in Pattern mode, the step bar shows 8 segments. Filled segments = substep plays, empty = substep muted.

**Step Value Label:**
Pattern and Ties modes show empty space below the bar (no numeric value). The bit pattern visualization in the bar is sufficient - showing decimal (e.g., "170") or binary would be redundant and clutters the UI.

### Code Reuse from Story 10.9

The `BitPatternEditorDialog` widget is designed to be reusable. We simply pass different `parameterName` and `color` values:

```dart
// In step_column_widget.dart
void _showBitPatternEditorDialog() {
  final currentValue = _getCurrentParameterValue();
  final isPattern = widget.activeParameter == StepParameter.pattern;

  showDialog(
    context: context,
    builder: (context) => BitPatternEditorDialog(
      initialValue: currentValue,
      parameterName: isPattern ? 'Pattern' : 'Ties',
      color: isPattern ? Color(0xFF3b82f6) : Color(0xFFeab308), // Blue vs Yellow
      onChanged: (newValue) {
        _updateParameter(widget.activeParameter, newValue);
      },
    ),
  );
}
```

### Bit Pattern Painter Update

The `PitchBarPainter` from Story 10.9 already handles bit pattern painting. Pattern mode uses the same visualization as Ties mode, just with a different color:

```dart
// In pitch_bar_painter.dart
@override
void paint(Canvas canvas, Size size) {
  if (displayMode == StepParameter.ties || displayMode == StepParameter.pattern) {
    _paintBitPattern(canvas, size, value, barColor); // barColor passed from parent
  } else if (displayMode == StepParameter.division) {
    _paintDivisionBar(canvas, size, value.clamp(0, 14), barColor);
  } else {
    _paintVerticalBar(canvas, size, value, barColor); // Continuous parameters
  }
}
```

### Division and Pattern Interaction

The Pattern parameter only has an effect when Division > 0 (which creates substeps):

| Division | Substeps Created | Active Bits Used |
|----------|------------------|------------------|
| 0 | 1 note | None (pattern ignored) |
| 1 | 2 notes | Bits 0-1 |
| 2 | 3 notes | Bits 0-2 |
| 3 | 4 notes | Bits 0-3 |
| ... | ... | ... |
| 7+ | 8+ notes | All 8 bits |

**UI Note:** All 8 bits are always editable. This allows users to set patterns that apply when Division is increased later.

### Testing Strategy

**Unit Tests:**
```dart
test('getPattern returns correct parameter index', () {
  final params = StepSequencerParams.fromSlot(mockSlot);
  expect(params.getPattern(1), isNotNull);
  expect(params.getPattern(1), equals(expectedPatternParamIndex));
});
```

**Widget Tests:**
```dart
testWidgets('Step bar shows bit pattern in Pattern mode with blue color', (tester) async {
  await tester.pumpWidget(createStepColumn(
    activeParameter: StepParameter.pattern,
    patternValue: 0b10101010, // 170
  ));

  final painter = tester.widget<CustomPaint>(find.byType(CustomPaint)).painter as PitchBarPainter;
  expect(painter.displayMode, equals(StepParameter.pattern));
  expect(painter.value, equals(170));
  expect(painter.barColor, equals(Color(0xFF3b82f6))); // Blue
});

testWidgets('Tapping step bar in Pattern mode shows bit pattern dialog', (tester) async {
  await tester.pumpWidget(createApp());

  // Set active parameter to Pattern
  await tester.tap(find.text('Pattern'));
  await tester.pumpAndSettle();

  // Tap step bar
  await tester.tap(find.byKey(Key('step_0_bar')));
  await tester.pumpAndSettle();

  // Verify dialog shown with Pattern title
  expect(find.byType(BitPatternEditorDialog), findsOneWidget);
  expect(find.text('Edit Pattern Bit Pattern'), findsOneWidget);
});
```

**Integration Tests:**
```dart
testWidgets('Pattern bit pattern writes to hardware correctly', (tester) async {
  await tester.pumpWidget(createApp());

  // 1. Switch to Pattern mode
  await tester.tap(find.text('Pattern'));
  await tester.pumpAndSettle();

  // 2. Tap step 0 bar
  await tester.tap(find.byKey(Key('step_0_bar')));
  await tester.pumpAndSettle();

  // 3. Toggle bit 1 in dialog
  await tester.tap(find.text('1').last); // Bit 1 toggle
  await tester.pumpAndSettle();

  // 4. Apply changes
  await tester.tap(find.text('Apply'));
  await tester.pumpAndSettle();

  // 5. Verify parameter update called with bit 1 set (value = 2)
  verify(() => mockCubit.updateParameterValue(
    any,
    patternParamIndex,
    2, // 0b00000010
  )).called(1);
});
```

### Project Structure Notes

**New Files:**
- None (reuses `BitPatternEditorDialog` from Story 10.9)

**Modified Files:**
- None (all Pattern support added in Story 10.9 via shared bit pattern painting)

**Dependencies:**
- **Story 10.9 MUST be completed first** - creates `BitPatternEditorDialog` and bit pattern painting logic

### References

- [Source: docs/step-sequencer-documentation-pages-294-300.txt#Pattern] - Pattern parameter specification
- [Source: User feedback] - Global mode selector approach
- [Source: lib/ui/widgets/step_sequencer/bit_pattern_editor_dialog.dart] - Widget from Story 10.9
- [Source: lib/services/step_sequencer_params.dart:125] - getPattern(step) method

## Dev Agent Record

### Context Reference

<!-- Will be added by story-context workflow -->

### Agent Model Used

<!-- Will be filled during implementation -->

### Debug Log References

### Completion Notes List

### File List
