# Story 10.13: Add Permutation and Gate Type Controls

Status: drafted

## Story

As a **Step Sequencer user**,
I want **to control Permutation and Gate Type parameters in the playback controls**,
so that **I can vary sequence playback order and gate behavior**.

## Acceptance Criteria

1. Add Permutation dropdown to playback controls section
2. Permutation options: Straight, Odd/Even, Halves, Inwards (per manual)
3. Add Gate Type toggle/dropdown to playback controls section
4. Gate Type options: "% of clock" (default) or "Trigger"
5. Gate Type toggle affects Gate Length vs. Trigger Length visibility
6. When Gate Type = "% of clock", show Gate Length slider
7. When Gate Type = "Trigger", show Trigger Length slider
8. All controls update hardware via debounced `updateParameterValue()`
9. Responsive layout: controls wrap on mobile, inline on desktop

## Tasks / Subtasks

- [ ] Add Permutation parameter support (AC: #1, #2)
  - [ ] Add Permutation dropdown to PlaybackControls widget (after Direction)
  - [ ] Options: Straight (0), Odd/Even (1), Halves (2), Inwards (3)
  - [ ] Wire to `StepSequencerParams.permutation` getter
  - [ ] Load current value from hardware on mount
  - [ ] Update parameter via `updateParameterValue()` on change

- [ ] Add Gate Type parameter support (AC: #3, #4, #5)
  - [ ] Add Gate Type toggle/segment control to PlaybackControls
  - [ ] Options: "% of clock" (0), "Trigger" (1)
  - [ ] Wire to `StepSequencerParams.gateType` getter
  - [ ] Load current value from hardware on mount
  - [ ] Update parameter via `updateParameterValue()` on change

- [ ] Implement conditional gate slider visibility (AC: #6, #7)
  - [ ] When Gate Type = 0 ("% of clock"): show Gate Length slider (1-99%)
  - [ ] When Gate Type = 1 ("Trigger"): show Trigger Length slider (1-100ms)
  - [ ] Hide the unused slider to reduce visual clutter
  - [ ] Smooth transition when switching gate types

- [ ] Extend parameter discovery (AC: #1, #3)
  - [ ] Add `int? get permutation => _paramIndices['Permutation'];` to StepSequencerParams
  - [ ] Add `int? get gateType => _paramIndices['Gate type'];` to StepSequencerParams
  - [ ] Log warnings if parameters not found (graceful degradation)

- [ ] Update playback controls layout (AC: #9)
  - [ ] Add Permutation dropdown (200px width) after Direction dropdown
  - [ ] Add Gate Type segment control (150px width) before gate sliders
  - [ ] Ensure responsive wrapping on mobile (Wrap widget)
  - [ ] Test layout on desktop (> 768px) and mobile (≤ 768px)

- [ ] Test integration (AC: #8)
  - [ ] Test parameter updates with 50ms debounce
  - [ ] Test offline mode: changes persist, sync on reconnect
  - [ ] Test gate type switching: verify correct slider shown
  - [ ] Test permutation options: verify hardware receives correct values

## Dev Notes

### Architecture Note: Playback Controls vs. Global Mode Selector

**Important Distinction:**
- **Per-step parameters** (Pitch, Velocity, Mod, Division, Pattern, Ties, Mute, Skip, Reset, Repeat) → Edited via **global mode selector** (Story 10.9)
- **True global playback parameters** (Direction, Start, End, Permutation, Gate Type, Gate Length, Trigger Length, Glide) → Edited via **playback controls section** (this story)

Permutation and Gate Type are NOT per-step parameters - they affect the entire sequence playback behavior. Therefore, they belong in the playback controls section alongside Direction, Start, and End.

### Parameter Specifications from Manual (Page 296)

| Parameter | Min | Max | Default | Description |
|-----------|-----|-----|---------|-------------|
| Permutation | 0 | 3 | 0 | Sequencer permutation (see below) |
| Gate type | 0 | 1 | 0 | "% of clock" (0) or "Trigger" (1) |

### Permutation Semantics (Page 300)

From the manual:
> "Note that if the direction is set to one of the random options, the permutation has no effect."

| Value | Name | Behavior |
|-------|------|----------|
| 0 | Straight | Steps play in numerical order: 1, 2, 3, 4, 5, 6, 7, 8... |
| 1 | Odd/Even | Odd steps, then even: 1, 3, 5, 7, 2, 4, 6, 8, 1... |
| 2 | Halves | Second half interleaved with first: 1, 5, 2, 6, 3, 7, 4, 8, 1... |
| 3 | Inwards | First and last, then inward: 1, 8, 2, 7, 3, 6, 4, 5, 1... |

**Key Insight:** Permutation only applies when Direction is NOT random (Random, Random2, Random3).

### Gate Type Semantics (Page 296)

From the manual:
- **Gate type = 0 ("% of clock"):** Gate length is percentage of clock period
  - Uses "Gate length" parameter (1-99%)
  - Example: Gate length = 50% → gate is high for half the clock period

- **Gate type = 1 ("Trigger"):** Gate length is fixed milliseconds
  - Uses "Trigger length" parameter (1-100ms)
  - Example: Trigger length = 10ms → gate is high for 10ms regardless of tempo

**Why This Matters:**
- "% of clock" adapts to tempo changes (musical)
- "Trigger" is fixed duration (good for triggering envelopes)

### UI Implementation

**Permutation Dropdown:**
```dart
DropdownButtonFormField<int>(
  value: permutationValue, // 0-3
  decoration: InputDecoration(
    labelText: 'Permutation',
    border: OutlineInputBorder(),
    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
  ),
  items: [
    DropdownMenuItem(value: 0, child: Text('Straight')),
    DropdownMenuItem(value: 1, child: Text('Odd/Even')),
    DropdownMenuItem(value: 2, child: Text('Halves')),
    DropdownMenuItem(value: 3, child: Text('Inwards')),
  ],
  onChanged: (value) {
    if (value != null) {
      _updateParameter(params.permutation, value);
    }
  },
)
```

**Gate Type Toggle (Segmented Control):**
```dart
SegmentedButton<int>(
  segments: [
    ButtonSegment(
      value: 0,
      label: Text('% of Clock'),
      icon: Icon(Icons.percent, size: 16),
    ),
    ButtonSegment(
      value: 1,
      label: Text('Trigger'),
      icon: Icon(Icons.timer, size: 16),
    ),
  ],
  selected: {gateTypeValue},
  onSelectionChanged: (Set<int> selection) {
    _updateParameter(params.gateType, selection.first);
  },
)
```

**Conditional Gate Slider Display:**
```dart
// In _buildFullLayout or _buildCompactLayout
BlocBuilder<DistingCubit, DistingState>(
  builder: (context, state) {
    if (state is! DistingStateSynchronized) return SizedBox.shrink();

    final slot = state.slots[widget.slotIndex];
    final gateTypeParam = widget.params.gateType;
    final gateTypeValue = gateTypeParam != null && gateTypeParam < slot.values.length
        ? slot.values[gateTypeParam].value
        : 0; // Default to "% of clock"

    return gateTypeValue == 0
        ? _buildGateLengthSlider(slot)   // Show Gate Length (%)
        : _buildTriggerLengthSlider(slot); // Show Trigger Length (ms)
  },
)
```

### Playback Controls Layout Update

**Current Layout (from Story 10.6):**
```
[Direction dropdown] [Start input] [End input] [Gate Length slider] [Trigger Length slider] [Glide Time slider]
```

**New Layout:**
```
[Direction dropdown] [Permutation dropdown] [Gate Type toggle]
[Start input] [End input]
[Gate Length slider OR Trigger Length slider (conditional)] [Glide Time slider]
```

**Responsive Considerations:**
- Desktop: All controls on one or two rows with wrapping
- Mobile: Vertical stack, full-width controls

**Code Structure:**
```dart
Wrap(
  spacing: 16,
  runSpacing: 12,
  children: [
    SizedBox(width: 200, child: _buildDirectionDropdown(slot)),
    SizedBox(width: 200, child: _buildPermutationDropdown(slot)), // NEW
    SizedBox(width: 250, child: _buildGateTypeToggle(slot)),     // NEW
    SizedBox(width: 100, child: _buildStartStepInput(slot)),
    SizedBox(width: 100, child: _buildEndStepInput(slot)),
    SizedBox(
      width: 250,
      child: gateTypeValue == 0
          ? _buildGateLengthSlider(slot)
          : _buildTriggerLengthSlider(slot),
    ),
    SizedBox(width: 250, child: _buildGlideTimeSlider(slot)),
  ],
)
```

### Testing Strategy

**Unit Tests:**
```dart
test('getPermutation returns correct parameter index', () {
  final params = StepSequencerParams.fromSlot(mockSlot);
  expect(params.permutation, isNotNull);
});

test('getGateType returns correct parameter index', () {
  final params = StepSequencerParams.fromSlot(mockSlot);
  expect(params.gateType, isNotNull);
});
```

**Widget Tests:**
```dart
testWidgets('Permutation dropdown shows all options', (tester) async {
  await tester.pumpWidget(createPlaybackControls());

  await tester.tap(find.byKey(Key('permutation_dropdown')));
  await tester.pumpAndSettle();

  expect(find.text('Straight'), findsOneWidget);
  expect(find.text('Odd/Even'), findsOneWidget);
  expect(find.text('Halves'), findsOneWidget);
  expect(find.text('Inwards'), findsOneWidget);
});

testWidgets('Gate Type = 0 shows Gate Length slider', (tester) async {
  await tester.pumpWidget(createPlaybackControls(gateType: 0));
  expect(find.byKey(Key('gate_length_slider')), findsOneWidget);
  expect(find.byKey(Key('trigger_length_slider')), findsNothing);
});

testWidgets('Gate Type = 1 shows Trigger Length slider', (tester) async {
  await tester.pumpWidget(createPlaybackControls(gateType: 1));
  expect(find.byKey(Key('gate_length_slider')), findsNothing);
  expect(find.byKey(Key('trigger_length_slider')), findsOneWidget);
});
```

**Integration Tests:**
```dart
testWidgets('Switching Gate Type toggles slider visibility', (tester) async {
  await tester.pumpWidget(createApp());

  // 1. Verify Gate Length slider visible (default Gate Type = 0)
  expect(find.byKey(Key('gate_length_slider')), findsOneWidget);

  // 2. Switch to Trigger mode
  await tester.tap(find.text('Trigger'));
  await tester.pumpAndSettle();

  // 3. Verify Trigger Length slider now visible
  expect(find.byKey(Key('trigger_length_slider')), findsOneWidget);
  expect(find.byKey(Key('gate_length_slider')), findsNothing);

  // 4. Verify parameter update called
  verify(() => mockCubit.updateParameterValue(any, gateTypeParamIndex, 1)).called(1);
});
```

### Project Structure Notes

**Modified Files:**
- `lib/ui/widgets/step_sequencer/playback_controls.dart` - Add Permutation and Gate Type controls
- `lib/services/step_sequencer_params.dart` - Add permutation and gateType getters

**New Files:**
- None

**Dependencies:**
- Story 10.6 (Playback controls) must be completed first

### References

- [Source: docs/step-sequencer-documentation-pages-294-300.txt#Sequencer-parameters] - Permutation and Gate Type specs
- [Source: docs/step-sequencer-documentation-pages-294-300.txt#Sequencer-permutations] - Permutation behavior
- [Source: lib/ui/widgets/step_sequencer/playback_controls.dart] - Existing playback controls widget
- [Source: lib/services/step_sequencer_params.dart] - Parameter discovery service

## Dev Agent Record

### Context Reference

<!-- Will be added by story-context workflow -->

### Agent Model Used

<!-- Will be filled during implementation -->

### Debug Log References

### Completion Notes List

### File List
