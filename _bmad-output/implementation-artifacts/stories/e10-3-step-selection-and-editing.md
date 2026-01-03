# Story: Step Selection and Editing

**Epic:** Epic 10 - Visual Step Sequencer UI Widget
**Story ID:** e10-3-step-selection-and-editing
**Status:** done
**Created:** 2025-11-23
**Completed:** 2025-11-23
**Assigned To:** Dev Agent
**Estimated Effort:** 1-2 days

---

## User Story

**As a** user
**I want** to tap a step to edit its parameters
**So that** I can change pitch, velocity, and other values

---

## Context

This story implements the step editing modal that allows users to modify individual step parameters in the Step Sequencer visual UI. After Story 2 created the visual grid display, this story adds the interactivity to actually edit step values.

**Dependencies:**
- Story 1 (e10-1): Widget registration - DONE
- Story 2 (e10-2): Step grid component - IN REVIEW

**Reference Files:**
- Epic: `docs/epics/epic-step-sequencer-ui.md`
- Technical Context: `docs/epics/epic-step-sequencer-ui-technical-context.md`
- Pattern Reference: `lib/ui/notes_algorithm_view.dart`
- State Management: `lib/cubit/disting_cubit.dart`

---

## Acceptance Criteria

### AC3.1: Tap step → opens modal with all per-step parameters (UPDATED 2025-11-23)
**For continuous/discrete parameters (Pitch, Velocity, Mod, Division):**
- User taps on a step column in the grid
- Modal dialog opens showing all editable parameters for that step
- Modal is properly sized and positioned (centered on desktop, bottom sheet on mobile)
- Step number is displayed in modal header (e.g., "Edit Step 5")

**For bit pattern parameters (Pattern, Ties):**
- User taps directly on value bar segments to toggle individual bits (no modal)
- See story e10.10.1 for direct bit clicking implementation

### AC3.2: Modal shows: Pitch (slider + numeric), Velocity (slider), Mod (slider)
- Pitch parameter: Slider (0-127) with numeric value display and note name (e.g., "C4")
- Velocity parameter: Slider (0-127) with numeric value display
- Mod parameter: Slider with appropriate range based on algorithm spec
- All sliders show current values from slot state
- Sliders are responsive and update smoothly

### AC3.3: Modal shows advanced: Division, Pattern, Ties, Probability sliders
- Advanced parameters section (collapsible or always visible)
- Division: Dropdown or slider based on available values
- Pattern: Dropdown or slider based on available values
- Ties: Toggle or slider (tie to next step)
- Probability: Slider (0-100% or 0-127 based on parameter spec)

### AC3.4: Changes call `cubit.updateParameter(name, value)`
- All parameter changes invoke `context.read<DistingCubit>().updateParameterValue(slotIndex, paramNumber, value)`
- Parameter number correctly resolved using `StepSequencerParams.fromSlot()`
- Changes are debounced (50ms) to prevent excessive MIDI writes during slider drag
- Local state updates immediately for smooth UI feedback

### AC3.5: Modal has Copy/Paste/Clear/Randomize buttons
- **Copy**: Copies all current step parameters to clipboard/memory
- **Paste**: Pastes previously copied parameters to current step
- **Clear**: Resets all step parameters to default values (prompt for confirmation)
- **Randomize**: Generates random musically-appropriate values (within scale if quantize enabled)
- All buttons clearly labeled and styled consistently

### AC3.6: Close modal → changes persist, auto-sync triggers
- Close button (X) or tap outside modal to dismiss
- All parameter changes are already persisted via cubit (no "Save" button needed)
- Auto-sync triggers for any debounced parameter changes
- Modal state is cleaned up properly (no memory leaks)

---

## Technical Implementation Notes

### File Structure
**New File:**
- `lib/ui/widgets/step_sequencer/step_edit_modal.dart` - Main modal implementation

**Modified Files:**
- `lib/ui/widgets/step_sequencer/step_column_widget.dart` - Add tap handler to open modal
- `lib/services/step_sequencer_params.dart` - Already exists from Story 1

### Modal Implementation Pattern

```dart
class StepEditModal extends StatefulWidget {
  final int slotIndex;
  final int stepIndex; // 0-15 (internal), display as 1-16
  final StepSequencerParams params;
  final Slot slot;

  const StepEditModal({
    required this.slotIndex,
    required this.stepIndex,
    required this.params,
    required this.slot,
  });

  @override
  State<StepEditModal> createState() => _StepEditModalState();
}

class _StepEditModalState extends State<StepEditModal> {
  final _debouncer = ParameterWriteDebouncer();
  Map<String, int> _copiedParams = {}; // For copy/paste

  @override
  void dispose() {
    _debouncer.dispose();
    super.dispose();
  }

  void _updateParameter(int paramNumber, int value) {
    _debouncer.schedule('param_$paramNumber', () {
      context.read<DistingCubit>().updateParameterValue(
        widget.slotIndex,
        paramNumber,
        value,
      );
    }, Duration(milliseconds: 50));
  }

  // ... modal UI implementation
}
```

### Responsive Design
- **Desktop/Tablet:** Center modal dialog (max width 600px)
- **Mobile:** Bottom sheet modal that slides up from bottom

### Copy/Paste Implementation
```dart
void _copyStep() {
  final step = widget.stepIndex + 1;
  _copiedParams = {
    'pitch': widget.slot.parameterValues[widget.params.getPitch(step)!] ?? 0,
    'velocity': widget.slot.parameterValues[widget.params.getVelocity(step)!] ?? 0,
    'mod': widget.slot.parameterValues[widget.params.getMod(step)!] ?? 0,
    // ... other parameters
  };
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Step $step copied')),
  );
}

void _pasteStep() {
  if (_copiedParams.isEmpty) return;
  final step = widget.stepIndex + 1;

  // Update all copied parameters
  final pitchParam = widget.params.getPitch(step);
  if (pitchParam != null && _copiedParams.containsKey('pitch')) {
    _updateParameter(pitchParam, _copiedParams['pitch']!);
  }
  // ... other parameters

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Step $step updated')),
  );
}
```

---

## Testing Requirements

### Unit Tests
- Test parameter update debouncing
- Test copy/paste logic
- Test clear functionality
- Test randomize generates valid values

### Widget Tests
- Test modal opens when step tapped
- Test all sliders render correctly
- Test buttons are present and enabled
- Test modal closes correctly

### Integration Tests
- Test full editing workflow (open → edit → close → verify changes persisted)
- Test copy/paste between steps
- Test randomize with quantize enabled/disabled

---

## Out of Scope

- Keyboard shortcuts for copy/paste (future enhancement)
- Multi-step editing (select multiple steps)
- Undo/redo functionality (future enhancement)
- Step parameter presets/templates

---

## Definition of Done

- [ ] AC3.1: Tap handler implemented, modal opens correctly
- [ ] AC3.2: Primary parameters (Pitch, Velocity, Mod) display with sliders
- [ ] AC3.3: Advanced parameters (Division, Pattern, Ties, Probability) display
- [ ] AC3.4: All changes call cubit.updateParameterValue with correct debouncing
- [ ] AC3.5: Copy/Paste/Clear/Randomize buttons implemented and functional
- [ ] AC3.6: Modal closes correctly, changes persist, auto-sync works
- [ ] All tests pass (`flutter test`)
- [ ] `flutter analyze` passes with zero warnings
- [ ] Widget tested on mobile and desktop layouts
- [ ] Dark mode support verified
- [ ] Code reviewed and approved

---

## Notes

- Modal should use theme colors for consistency
- Note name display for pitch: Use MIDI note to name conversion (e.g., 60 = C4)
- Randomize should respect quantize settings if enabled
- Clear should show confirmation dialog to prevent accidental data loss
