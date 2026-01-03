# Story 10.11: Audit and Validate Parameter UI Controls

Status: drafted

## Story

As a **developer**,
I want **to audit all step parameter UI controls against hardware specifications**,
so that **each parameter type has appropriate visualization and value constraints matching its min/max range**.

## Acceptance Criteria

1. Audit all 10 step parameters (6 main + 4 probabilities)
2. Verify each parameter's bar visualization matches its data type and range
3. Verify bit pattern parameters (Pattern, Ties) use 8-segment visualization
4. Verify continuous parameters use appropriate vertical bar scaling
5. Verify Division parameter correctly handles 0-14 range (not 0-127)
6. Verify Velocity parameter correctly handles 1-127 range (not 0-127)
7. Document any discrepancies found and create follow-up tasks
8. Add parameter value clamping/validation where needed
9. Add unit tests validating parameter value constraints

## Tasks / Subtasks

- [ ] Review hardware specification for all step parameters (AC: #1, #2)
  - [ ] Document Pitch: 0-127 (MIDI note) → vertical bar ✓
  - [ ] Document Velocity: **1-127** (MIDI velocity) → vertical bar ⚠️ (min is 1, not 0)
  - [ ] Document Mod: -10.0 to 10.0 V → vertical bar ✓
  - [ ] Document Division: **0-14** (repeat/ratchet count) → vertical bar or segments ⚠️ (max is 14, not 127)
  - [ ] Document Pattern: 0-255 (8-bit substep pattern) → 8 segments ✓
  - [ ] Document Ties: 0-255 (8-bit substep tie pattern) → 8 segments ✓
  - [ ] Document Mute: 0-100% (probability) → vertical bar ✓
  - [ ] Document Skip: 0-100% (probability) → vertical bar ✓
  - [ ] Document Reset: 0-100% (probability) → vertical bar ✓
  - [ ] Document Repeat: 0-100% (probability) → vertical bar ✓

- [ ] Fix Velocity parameter range (AC: #6)
  - [ ] Update bar visualization to start at 1, not 0
  - [ ] Add validation: clamp values < 1 to 1
  - [ ] Update `_handleBarInteraction()` to map to 1-127 range

- [ ] Fix Division parameter range (AC: #5)
  - [ ] Update bar visualization to max at 14, not 127
  - [ ] Add validation: clamp values > 14 to 14
  - [ ] Consider showing 15 discrete segments (0-14) instead of continuous bar
  - [ ] Update `_handleBarInteraction()` to map to 0-14 range

- [ ] Implement parameter-specific bar painting (AC: #2, #3, #4)
  - [ ] Velocity (1-127): Map bar 0% → 1, bar 100% → 127
  - [ ] Division (0-14): Show 15 discrete segments OR continuous bar scaled to 0-14
  - [ ] Probabilities (0-100): Map bar 0% → 0, bar 100% → 100
  - [ ] Ensure `_getCurrentParameterValue()` returns correct range per parameter

- [ ] Add parameter validation helper (AC: #8)
  - [ ] Create `StepParameterConstraints` class with min/max/clamp per parameter
  - [ ] Apply constraints in `_handleBarInteraction()` before hardware write
  - [ ] Apply constraints when loading values from hardware

- [ ] Add parameter validation tests (AC: #9)
  - [ ] Test Pitch: values outside 0-127 clamped
  - [ ] Test Velocity: values < 1 clamped to 1, values > 127 clamped to 127
  - [ ] Test Mod: values outside -10.0 to +10.0 clamped
  - [ ] Test Division: values > 14 clamped to 14
  - [ ] Test Pattern: values > 255 clamped to 255
  - [ ] Test Ties: values > 255 clamped to 255
  - [ ] Test Probabilities: values > 100 clamped to 100

- [ ] Document findings and recommendations (AC: #7)
  - [ ] Create audit report with findings
  - [ ] List parameter ranges and their UI representations
  - [ ] Recommend UI improvements for clarity

## Dev Notes

### Parameter Specifications from Manual (Page 296)

| Parameter | Min | Max | Default | Unit | UI Representation | Step Value Label Format |
|-----------|-----|-----|---------|------|-------------------|-------------------------|
| Pitch | 0 | 127 | 48 | MIDI note | Vertical bar (0-127) | Note name (e.g., "C4") |
| Velocity | **1** | 127 | 64 | MIDI velocity | Vertical bar (1-127) ⚠️ | Raw value (e.g., "64") |
| Mod | -10.0 | 10.0 | 0.0 | V | Vertical bar (-10 to +10) | Voltage (e.g., "5.0V") |
| Division | 0 | **14** | 7 | - | Vertical bar (0-14) with ticks ⚠️ | Number of notes (e.g., "3") |
| Pattern | 0 | 255 | 0 | - | 8-segment bit pattern ✓ | Empty space |
| Ties | 0 | 255 | 0 | - | 8-segment bit pattern ✓ | Empty space |
| Mute | 0 | 100 | 0 | % | Vertical bar (0-100%) | Percentage (e.g., "50%") |
| Skip | 0 | 100 | 0 | % | Vertical bar (0-100%) | Percentage (e.g., "50%") |
| Reset | 0 | 100 | 0 | % | Vertical bar (0-100%) | Percentage (e.g., "50%") |
| Repeat | 0 | 100 | 0 | % | Vertical bar (0-100%) | Percentage (e.g., "50%") |

**Key Findings:**
1. ⚠️ **Velocity: 1-127 (NOT 0-127)** → Minimum value is 1, not 0
2. ⚠️ **Division: 0-14 (NOT 0-127)** → Maximum value is 14, not 127
3. ✅ All other parameters: ranges are straightforward
4. ✅ **Step value labels**: Use proper units from existing ui_helpers.dart functions (midiNoteToNoteString, formatWithUnit)
5. ✅ **Pattern/Ties labels**: Show empty space (bit pattern is in the bar, numeric value would be redundant)

### Parameter Constraints Implementation

```dart
// In step_column_widget.dart or new constraints.dart
class StepParameterConstraints {
  static const Map<StepParameter, ParameterRange> ranges = {
    StepParameter.pitch: ParameterRange(min: 0, max: 127),
    StepParameter.velocity: ParameterRange(min: 1, max: 127), // ⚠️ min is 1
    StepParameter.mod: ParameterRange(min: -100, max: 100), // Scaled to -10.0 to +10.0V
    StepParameter.division: ParameterRange(min: 0, max: 14), // ⚠️ max is 14
    StepParameter.pattern: ParameterRange(min: 0, max: 255),
    StepParameter.ties: ParameterRange(min: 0, max: 255),
    StepParameter.mute: ParameterRange(min: 0, max: 100),
    StepParameter.skip: ParameterRange(min: 0, max: 100),
    StepParameter.reset: ParameterRange(min: 0, max: 100),
    StepParameter.repeat: ParameterRange(min: 0, max: 100),
  };

  static int clamp(StepParameter param, int value) {
    final range = ranges[param]!;
    return value.clamp(range.min, range.max);
  }

  static int mapBarToValue(StepParameter param, double normalizedPosition) {
    // normalizedPosition: 0.0 (bottom) to 1.0 (top)
    final range = ranges[param]!;
    final rawValue = (normalizedPosition * (range.max - range.min)) + range.min;
    return rawValue.round().clamp(range.min, range.max);
  }

  static double mapValueToBar(StepParameter param, int value) {
    // Returns 0.0 to 1.0 for bar rendering
    final range = ranges[param]!;
    return (value - range.min) / (range.max - range.min);
  }
}

class ParameterRange {
  final int min;
  final int max;
  const ParameterRange({required this.min, required this.max});
}
```

### Updated Bar Interaction Logic

```dart
// In step_column_widget.dart
void _handleBarInteraction(double localY, double barHeight) {
  // Calculate normalized position (0.0 = bottom, 1.0 = top)
  final normalizedPosition = 1.0 - (localY / barHeight);

  // Map to parameter value using constraints
  int newValue = StepParameterConstraints.mapBarToValue(
    widget.activeParameter,
    normalizedPosition,
  );

  // Apply quantization if pitch parameter and snap enabled
  if (widget.activeParameter == StepParameter.pitch && widget.snapEnabled) {
    newValue = ScaleQuantizer.quantize(
      newValue,
      widget.selectedScale,
      widget.rootNote,
    );
  }

  // Update parameter (already constrained)
  _updateParameter(widget.activeParameter, newValue);
}
```

### Division Visualization Options

**Option A: Continuous bar (0-14)**
- Pro: Simple, consistent with other parameters
- Con: Less intuitive that there are only 15 valid values

**Option B: 15 discrete segments**
- Pro: Shows discrete nature of Division (0, 1, 2, ... 14)
- Con: More complex painting logic

**Recommendation:** Start with continuous bar (Option A) for simplicity. Can add discrete segments in future iteration if users request it.

```dart
// Division as continuous bar
void _paintDivisionBar(Canvas canvas, Size size, int value, Color color) {
  // value is 0-14
  final fillHeight = (value / 14.0) * size.height;

  final fillPaint = Paint()..color = color;
  canvas.drawRect(
    Rect.fromLTWH(0, size.height - fillHeight, size.width, fillHeight),
    fillPaint,
  );

  // Optional: Draw tick marks for each division value
  final segmentHeight = size.height / 15;
  for (int i = 0; i <= 14; i++) {
    final y = size.height - (i * segmentHeight);
    final tickPaint = Paint()
      ..color = Colors.grey.shade600
      ..strokeWidth = 0.5;
    canvas.drawLine(Offset(0, y), Offset(size.width, y), tickPaint);
  }
}
```

### Testing Strategy

**Unit Tests:**
```dart
// test/services/step_parameter_constraints_test.dart
group('Parameter Constraints', () {
  test('Velocity clamps to 1-127', () {
    expect(StepParameterConstraints.clamp(StepParameter.velocity, 0), equals(1));
    expect(StepParameterConstraints.clamp(StepParameter.velocity, 1), equals(1));
    expect(StepParameterConstraints.clamp(StepParameter.velocity, 127), equals(127));
    expect(StepParameterConstraints.clamp(StepParameter.velocity, 128), equals(127));
  });

  test('Division clamps to 0-14', () {
    expect(StepParameterConstraints.clamp(StepParameter.division, 0), equals(0));
    expect(StepParameterConstraints.clamp(StepParameter.division, 14), equals(14));
    expect(StepParameterConstraints.clamp(StepParameter.division, 15), equals(14));
    expect(StepParameterConstraints.clamp(StepParameter.division, 127), equals(14));
  });

  test('mapBarToValue maps correctly for Velocity', () {
    // Bottom of bar (0.0) → 1 (min)
    expect(StepParameterConstraints.mapBarToValue(StepParameter.velocity, 0.0), equals(1));
    // Top of bar (1.0) → 127 (max)
    expect(StepParameterConstraints.mapBarToValue(StepParameter.velocity, 1.0), equals(127));
    // Middle of bar (0.5) → 64 (roughly)
    expect(StepParameterConstraints.mapBarToValue(StepParameter.velocity, 0.5), closeTo(64, 2));
  });

  test('mapBarToValue maps correctly for Division', () {
    // Bottom of bar (0.0) → 0
    expect(StepParameterConstraints.mapBarToValue(StepParameter.division, 0.0), equals(0));
    // Top of bar (1.0) → 14
    expect(StepParameterConstraints.mapBarToValue(StepParameter.division, 1.0), equals(14));
    // Middle of bar (0.5) → 7
    expect(StepParameterConstraints.mapBarToValue(StepParameter.division, 0.5), equals(7));
  });
});
```

**Widget Tests:**
```dart
testWidgets('Bar height correctly represents Division value', (tester) async {
  await tester.pumpWidget(createStepColumn(
    activeParameter: StepParameter.division,
    divisionValue: 7, // Middle value (0-14 range)
  ));

  // Verify bar fills ~50% of height
  final painter = tester.widget<CustomPaint>(find.byType(CustomPaint)).painter as PitchBarPainter;
  expect(painter.value, equals(7));
  expect(painter.displayMode, equals(StepParameter.division));
});
```

### Audit Report Template

```markdown
# Step Sequencer Parameter Audit Report
Date: 2025-11-23

## Parameters Audited: 10

### ✅ Correct Implementation (8/10)
1. **Pitch** (0-127): Vertical bar correctly scaled
2. **Mod** (-10.0 to +10.0V): Vertical bar correctly scaled
3. **Pattern** (0-255): 8-segment bit pattern implemented (Story 10.10)
4. **Ties** (0-255): 8-segment bit pattern implemented (Story 10.9)
5. **Mute** (0-100%): Vertical bar correctly scaled
6. **Skip** (0-100%): Vertical bar correctly scaled
7. **Reset** (0-100%): Vertical bar correctly scaled
8. **Repeat** (0-100%): Vertical bar correctly scaled

### ⚠️ Issues Found (2/10)
1. **Velocity** (1-127): Bar currently maps 0-127 instead of 1-127
   - Impact: Users can see/set invalid value 0
   - Fix: Change bar mapping to 1-127, clamp display values

2. **Division** (0-14): Bar currently maps 0-127 instead of 0-14
   - Impact: Users can see/set invalid values 15-127
   - Fix: Change bar mapping to 0-14, clamp display values

## Recommendations
1. Add `StepParameterConstraints` class for all parameter ranges
2. Use constraints in bar interaction and display logic
3. Add unit tests for all parameter ranges
4. Consider discrete segment visualization for Division parameter
```

### Project Structure Notes

**New Files:**
- `lib/services/step_parameter_constraints.dart` - Parameter range constraints (optional, could be in step_column_widget.dart)
- `test/services/step_parameter_constraints_test.dart` - Constraint validation tests

**Modified Files:**
- `lib/ui/widgets/step_sequencer/step_column_widget.dart` - Apply constraints in `_handleBarInteraction()`
- `lib/ui/widgets/step_sequencer/pitch_bar_painter.dart` - Use constraints for bar rendering

### References

- [Source: docs/step-sequencer-documentation-pages-294-300.txt#Step-parameters] - Official parameter specs
- [Source: lib/ui/widgets/step_sequencer/step_column_widget.dart:89-106] - Current bar interaction
- [Source: lib/ui/widgets/step_sequencer/pitch_bar_painter.dart] - Bar painting logic

## Dev Agent Record

### Context Reference

<!-- Will be added by story-context workflow -->

### Agent Model Used

<!-- Will be filled during implementation -->

### Debug Log References

### Completion Notes List

### File List
