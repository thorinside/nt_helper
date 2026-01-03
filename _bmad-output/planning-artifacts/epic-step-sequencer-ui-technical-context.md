# Technical Context: Step Sequencer UI Epic

**Epic:** Visual Step Sequencer UI Widget
**Created:** 2025-11-23
**Architect:** Winston
**Status:** Ready for Implementation

---

## Executive Summary

This epic introduces a visual grid interface for the Step Sequencer algorithm (GUID: `spsq`), replacing the default parameter list with an intuitive 16-step grid. The implementation leverages the existing **AlgorithmViewRegistry pattern** (see `NotesAlgorithmView`) and integrates seamlessly with the mature nt_helper architecture.

**Key Insight:** This is a **UI enhancement** requiring zero changes to MIDI layer, state management core, or SysEx commands. All infrastructure exists—we're building a specialized visualization layer.

---

## Architecture Alignment

### Existing Patterns Being Reused

#### 1. Widget Replacement Pattern (AlgorithmViewRegistry)

**Reference Implementation:** `lib/ui/notes_algorithm_view.dart`

**How It Works:**
```dart
// lib/ui/algorithm_registry.dart
static Widget? findViewFor(String algorithmGuid, ...) {
  switch (algorithmGuid) {
    case 'notes': // Existing pattern
      return NotesAlgorithmView(slot: slot, firmwareVersion: firmwareVersion);

    case 'spsq':  // NEW: Step Sequencer
      return StepSequencerView(slot: slot, firmwareVersion: firmwareVersion);

    default:
      return null; // Falls back to parameter list
  }
}
```

**Integration Point:** `lib/ui/synchronized_screen.dart` already calls `AlgorithmViewRegistry.findViewFor()` when rendering slot details. No changes required there.

#### 2. State Management (DistingCubit)

**Source of Truth:** `lib/cubit/disting_cubit.dart` (lines 1-1000+)

**What We Get:**
- `Slot` objects with algorithm, parameters, values, routing info
- `updateParameterValue(slotIndex, paramNumber, value)` method for MIDI writes
- Offline mode support with dirty parameter tracking
- Real-time parameter value streams

**What We Use:**
```dart
// In StepSequencerView
BlocBuilder<DistingCubit, DistingState>(
  buildWhen: (prev, curr) {
    // Only rebuild when this slot's parameters change
    return curr.maybeWhen(
      synchronized: (_, slots, __, ___, ____, _____) {
        final prevSlots = prev.maybeWhen(
          synchronized: (_, s, __, ___, ____, _____) => s,
          orElse: () => null,
        );
        return prevSlots?[slotIndex].parameterValues !=
               slots[slotIndex].parameterValues;
      },
      orElse: () => false,
    );
  },
  builder: (context, state) {
    return state.maybeWhen(
      synchronized: (disting, slots, _, __, ___, ____) {
        final slot = slots[slotIndex];
        return _buildStepGrid(slot);
      },
      orElse: () => CircularProgressIndicator(),
    );
  },
)
```

**Parameter Updates:**
```dart
// Updating a step's pitch value
context.read<DistingCubit>().updateParameterValue(
  slotIndex,
  parameterNumber, // e.g., "Pitch 1" parameter
  newValue,        // 0-127 MIDI note
);
```

**No New Cubit Required:** DistingCubit already handles all state management. We only need UI-local state for things like "which step is selected for editing."

#### 3. MIDI Write Infrastructure (IDistingMidiManager)

**Interface:** `lib/domain/i_disting_midi_manager.dart`
**Implementation:** `lib/domain/disting_midi_manager.dart` (Live mode)

**What We Get:**
- `setParameterValue(slot, paramNumber, value)` - SysEx 0x44
- Automatic queueing via `DistingMessageScheduler`
- Retry logic and timeout handling
- Works in all three modes (Live, Mock, Offline)

**What We Don't Need:**
- No new SysEx commands required
- No changes to MIDI layer
- No new request/response implementations

#### 4. Offline Mode Support

**Implementation:** `lib/domain/offline_disting_midi_manager.dart`

**How It Works:**
- Parameter changes update local state immediately
- Dirty parameters tracked in `dirtyParameters` map
- On reconnect, user prompted to sync changes
- Bulk sync via `DistingCubit.syncDirtyParameters()`

**What We Get for Free:**
- UI works identically offline vs. online
- Visual editing persists across disconnect/reconnect
- No special handling needed in our widget

---

## Technical Decisions

### 1. No Separate Cubit for Step Sequencer State

**Decision:** Use local StatefulWidget state for transient UI concerns (e.g., selected step for editing, quantize settings).

**Rationale:**
- DistingCubit already manages all parameter values
- Quantize/scale settings are UI-only (not persisted to hardware)
- Simpler architecture, follows NotesAlgorithmView pattern
- Avoids bloating DistingCubit with algorithm-specific logic

**Local State Examples:**
```dart
class _StepSequencerViewState extends State<StepSequencerView> {
  int? _selectedStep; // Which step is being edited
  bool _snapToScale = false;
  String _selectedScale = 'Major';
  int _rootNote = 0; // C

  // ... widget builds using both DistingCubit (parameters) and local state (UI)
}
```

### 2. Parameter Value Debouncing

**Decision:** Implement 50ms debounce using `Timer` in the widget, not in DistingCubit.

**Rationale:**
- DistingCubit is algorithm-agnostic
- Other algorithms may want different debounce strategies
- Keeps debounce logic localized to this UI

**Implementation:**
```dart
class ParameterWriteDebouncer {
  final Map<String, Timer> _timers = {};

  void schedule(String key, VoidCallback callback, Duration delay) {
    _timers[key]?.cancel();
    _timers[key] = Timer(delay, () {
      callback();
      _timers.remove(key);
    });
  }

  void dispose() {
    for (final timer in _timers.values) {
      timer.cancel();
    }
    _timers.clear();
  }
}
```

**Usage:**
```dart
// In _StepSequencerViewState
final _debouncer = ParameterWriteDebouncer();

void _updateStepPitch(int step, int midiNote) {
  setState(() {
    // Update local preview immediately
    _previewValues[step] = midiNote;
  });

  _debouncer.schedule('pitch_$step', () {
    context.read<DistingCubit>().updateParameterValue(
      widget.slotIndex,
      _getPitchParameterNumber(step),
      midiNote,
    );
  }, Duration(milliseconds: 50));
}

@override
void dispose() {
  _debouncer.dispose();
  super.dispose();
}
```

### 3. CustomPaint for Step Bars

**Decision:** Use `CustomPainter` for pitch bar visualization, not stacked Containers.

**Rationale:**
- Performance: 16 columns × 60fps = need efficient rendering
- Gradient fills require `CustomPaint` anyway
- Enables future enhancements (waveform preview, animations)

**Reference:** Flutter performance best practices recommend CustomPaint for data visualization.

### 4. Responsive Breakpoints

**Decision:** Mobile ≤ 768px, Tablet 769-1024px, Desktop > 1024px

**Rationale:**
- Aligns with existing app responsive patterns
- 768px is standard mobile/tablet breakpoint
- Matches mockup viewport simulator design

**Detection:**
```dart
final width = MediaQuery.of(context).size.width;
final isMobile = width <= 768;
final isTablet = width > 768 && width <= 1024;
final isDesktop = width > 1024;
```

### 5. Scale Quantization (UI-Only)

**Decision:** Quantization happens in UI layer, not persisted to hardware.

**Rationale:**
- Hardware stores raw MIDI note values
- Quantization is a composition aid, not a parameter
- User can disable/change scale without affecting stored sequence
- Aligns with DAW workflow (MIDI notes are raw, quantize is non-destructive)

**Implementation:**
```dart
class ScaleQuantizer {
  static const Map<String, List<int>> scales = {
    'Chromatic': [0,1,2,3,4,5,6,7,8,9,10,11],
    'Major': [0,2,4,5,7,9,11],
    'Minor': [0,2,3,5,7,8,10],
    'Dorian': [0,2,3,5,7,9,10],
    'Phrygian': [0,1,3,5,7,8,10],
    'Lydian': [0,2,4,6,7,9,11],
    'Mixolydian': [0,2,4,5,7,9,10],
    'Aeolian': [0,2,3,5,7,8,10],
    'Locrian': [0,1,3,5,6,8,10],
    'Pentatonic Major': [0,2,4,7,9],
    'Pentatonic Minor': [0,3,5,7,10],
  };

  static int quantize(int midiNote, String scale, int root) {
    final noteClass = midiNote % 12;
    final octave = midiNote ~/ 12;
    final scaleIntervals = scales[scale] ?? scales['Chromatic']!;

    // Transpose scale to root
    final transposedScale = scaleIntervals.map((i) => (i + root) % 12).toList();

    // Find nearest scale degree
    int nearest = transposedScale.first;
    int minDistance = ((noteClass - nearest).abs());

    for (final degree in transposedScale) {
      final distance = ((noteClass - degree).abs());
      if (distance < minDistance) {
        minDistance = distance;
        nearest = degree;
      }
    }

    return (octave * 12) + nearest;
  }
}
```

---

## Integration Points

### 1. AlgorithmViewRegistry Registration

**File:** `lib/ui/algorithm_registry.dart`
**Location:** Line ~8
**Change:** Add `case 'spsq':` returning `StepSequencerView`

**Risk:** Low. Pattern is well-established (NotesAlgorithmView precedent).

### 2. DistingCubit Parameter Updates

**File:** `lib/cubit/disting_cubit.dart`
**Method:** `updateParameterValue(int slotIndex, int paramNumber, dynamic value)`
**Usage:** Called on every debounced parameter change

**Risk:** None. Method already handles high-frequency updates (used by parameter sliders).

### 3. Slot Data Access

**File:** `lib/cubit/disting_state.dart`
**Structure:** `Slot` class with `parameters`, `parameterValues`, `algorithm`

**What We Read:**
```dart
final slot = slots[slotIndex];
final algorithm = slot.algorithm; // Check if GUID is 'spsq'
final parameters = slot.parameters; // Get parameter definitions
final values = slot.parameterValues; // Get current MIDI values
```

**Risk:** None. Read-only access to existing state.

### 4. Theme Integration

**File:** `lib/disting_app.dart`
**Theme Colors:** Already defines `primaryColor`, but we add teal variants

**Addition to app theme:**
```dart
// In ThemeData
extensions: [
  StepSequencerTheme(
    primaryTeal: Color(0xFF14b8a6),
    darkTeal: Color(0xFF0f766e),
    darkerTeal: Color(0xFF115e59),
    brightTeal: Color(0xFF5eead4),
  ),
],
```

**Risk:** Low. Theme extensions are additive.

---

## File Structure

### New Files (9 total)

```
lib/
├── ui/
│   ├── step_sequencer_view.dart              # Main widget (Story 1)
│   └── widgets/
│       └── step_sequencer/
│           ├── step_grid_view.dart           # Grid container (Story 2)
│           ├── step_column_widget.dart       # Individual step (Story 2)
│           ├── pitch_bar_painter.dart        # CustomPaint (Story 2)
│           ├── step_edit_modal.dart          # Edit dialog (Story 3)
│           ├── quantize_controls.dart        # Scale controls (Story 4)
│           ├── sequence_selector.dart        # Sequence dropdown (Story 5)
│           └── playback_controls.dart        # Playback settings (Story 6)
│
├── services/
│   ├── step_sequencer_params.dart            # Parameter discovery (Story 1)
│   └── scale_quantizer.dart                  # Quantization logic (Story 4)
│
└── util/
    └── parameter_write_debouncer.dart        # Debounce utility (Story 7)
```

### Modified Files (1 total)

```
lib/
└── ui/
    └── algorithm_registry.dart               # Add 'spsq' case (Story 1)
```

---

## Parameter Mapping Strategy

### Step Sequencer Parameters (from research)

The Step Sequencer has 50+ parameters organized as:
- **Per-Step Parameters (16 steps):** Pitch, Velocity, Mod, Division, Pattern, Ties, Probability
- **Global Parameters:** Direction, Start Step, End Step, Gate Length, Trigger Length, Glide Time, Current Sequence

### Mapping Approach

**Story 1:** Discover parameter structure from algorithm metadata and parameter names:

```dart
class StepSequencerParams {
  final int numSteps;
  final Map<String, int> _paramIndices = {};

  StepSequencerParams.fromSlot(Slot slot)
    : numSteps = _discoverNumSteps(slot) {
    _buildParameterMap(slot.parameters);
  }

  static int _discoverNumSteps(Slot slot) {
    // Step Sequencer algorithm metadata should specify number of steps
    // Fallback: discover from parameter names (highest step number found)
    final stepPattern = RegExp(r'^(\d+)\.');  // Matches "1. Pitch", "2. Pitch", etc.
    int maxStep = 0;

    for (final param in slot.parameters) {
      final match = stepPattern.firstMatch(param.name);
      if (match != null) {
        final step = int.parse(match.group(1)!);
        if (step > maxStep) maxStep = step;
      }
    }
    return maxStep > 0 ? maxStep : 16; // Default to 16 if not discovered
  }

  void _buildParameterMap(List<ParameterInfo> parameters) {
    for (int i = 0; i < parameters.length; i++) {
      final param = parameters[i];
      _paramIndices[param.name] = i;
    }
  }

  int? getStepParam(int step, String paramType) {
    // Hardware format discovered in implementation:
    // "N:Param" (e.g., "1:Pitch", "2:Velocity")
    final paramName = '$step:$paramType';

    if (_paramIndices.containsKey(paramName)) {
      return _paramIndices[paramName];
    }

    // If no match, log warning and return null
    debugPrint('[StepSequencerParams] WARNING: Parameter not found - $paramName');
    return null;
  }

  // Convenience helpers with null safety
  int? getPitch(int step) => getStepParam(step, 'Pitch');
  int? getVelocity(int step) => getStepParam(step, 'Velocity');
  int? getMod(int step) => getStepParam(step, 'Mod');
  int? getDivision(int step) => getStepParam(step, 'Division');
  int? getPattern(int step) => getStepParam(step, 'Pattern');
  int? getTies(int step) => getStepParam(step, 'Ties');

  // Note: Per-step probability parameters are not exposed by the current
  // firmware. Probability-style controls in the UI (Mute/Skip/Reset/Repeat)
  // are planned in a later story and are not discovered here yet.

  // Global parameters (discover by exact name match)
  int? get direction => _paramIndices['Direction'];
  int? get startStep => _paramIndices['Start'];
  int? get endStep => _paramIndices['End'];
  int? get gateLength => _paramIndices['Gate length'];
  int? get triggerLength => _paramIndices['Trigger length'];
  int? get glideTime => _paramIndices['Glide'];
  int? get currentSequence => _paramIndices['Sequence'];
}
```

**Usage:**
```dart
// Initialize from slot
final params = StepSequencerParams.fromSlot(slot);

// Update step 5's pitch (1-indexed from user perspective)
final paramNum = params.getPitch(5);
if (paramNum != null) {
  cubit.updateParameterValue(slotIndex, paramNum, newValue);
} else {
  // Parameter not found - show error to user, disable control
  showSnackBar('Step parameter not available');
}

// Update global parameter
final directionParam = params.direction;
if (directionParam != null) {
  cubit.updateParameterValue(slotIndex, directionParam, newValue);
}
```

**Advantages:**
- ✅ Discovers parameter structure from actual slot data (no hardcoded assumptions)
- ✅ Handles multiple naming patterns (flexible to firmware changes)
- ✅ Discovers number of steps from metadata or parameter names
- ✅ Clear error handling when parameters not found
- ✅ Null-safe with explicit checks
- ✅ Maintainable - pattern list easy to extend if new naming discovered

**Story 1 Task:** During widget registration, instantiate `StepSequencerParams` and verify:
1. Number of steps discovered correctly (expected: 16)
2. All expected parameters found (Pitch, Velocity, Mod, Division, Pattern, Ties, Probability per step)
3. Global parameters found (Direction, Start/End Step, Gate/Trigger/Glide)
4. Log warnings for any missing parameters

---

## Performance Considerations

### Target: 60fps (16.67ms frame budget)

#### Optimizations

1. **const Constructors:** Use wherever possible
   ```dart
   const StepNumber(stepIndex: 1); // Good
   StepNumber(stepIndex: 1);       // Rebuilds unnecessarily
   ```

2. **BlocBuilder Precision:**
   ```dart
   // Only rebuild when THIS slot's parameter values change
   buildWhen: (prev, curr) =>
     prev.slots[slotIndex].parameterValues != curr.slots[slotIndex].parameterValues
   ```

3. **ListView.builder for Horizontal Scroll:**
   ```dart
   // Lazy loading on mobile
   ListView.builder(
     scrollDirection: Axis.horizontal,
     itemCount: 16,
     itemBuilder: (context, index) => StepColumnWidget(index),
   );
   ```

4. **RepaintBoundary for Step Columns:**
   ```dart
   RepaintBoundary(
     child: StepColumnWidget(stepIndex: i),
   );
   ```

5. **shouldRepaint Optimization:**
   ```dart
   class PitchBarPainter extends CustomPainter {
     final int pitchValue;

     @override
     bool shouldRepaint(PitchBarPainter oldDelegate) {
       return pitchValue != oldDelegate.pitchValue;
     }
   }
   ```

#### Performance Risks

**Risk 1:** 16 CustomPaint widgets repainting on every frame
- **Mitigation:** RepaintBoundary + shouldRepaint optimization
- **Fallback:** Use simpler gradient containers if CustomPaint too slow

**Risk 2:** Debouncer creating excessive Timers
- **Mitigation:** Single debouncer instance, cancel old timers
- **Monitoring:** Add debug counters in development builds

---

## Testing Strategy

### Unit Tests (Stories 4, 7)

```dart
// test/services/scale_quantizer_test.dart
test('quantizes to nearest scale degree', () {
  final quantized = ScaleQuantizer.quantize(61, 'Major', 0); // C# → C or D
  expect(quantized, isIn([60, 62])); // C or D
});

// test/util/parameter_write_debouncer_test.dart
test('debounces rapid calls', () async {
  final debouncer = ParameterWriteDebouncer();
  int callCount = 0;

  for (int i = 0; i < 10; i++) {
    debouncer.schedule('test', () => callCount++, Duration(milliseconds: 50));
    await Future.delayed(Duration(milliseconds: 10));
  }

  await Future.delayed(Duration(milliseconds: 100));
  expect(callCount, equals(1)); // Only last call executed
});
```

### Widget Tests (Stories 2, 3)

```dart
// test/ui/widgets/step_sequencer/step_column_widget_test.dart
testWidgets('displays pitch value correctly', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: StepColumnWidget(
        stepIndex: 0,
        pitchValue: 64, // E4
        velocityValue: 100,
        isActive: true,
      ),
    ),
  );

  expect(find.text('1'), findsOneWidget); // Step number
  // Verify pitch bar renders
  expect(find.byType(CustomPaint), findsOneWidget);
});
```

### Integration Tests (Story 1, 8)

```dart
// test/integration/step_sequencer_integration_test.dart
testWidgets('full editing workflow', (tester) async {
  // 1. Load app with step sequencer algorithm in slot 0
  final cubit = DistingCubit(mockDatabase);
  await cubit.loadMockPresetWithStepSequencer();

  // 2. Navigate to step sequencer view
  await tester.pumpWidget(
    BlocProvider.value(
      value: cubit,
      child: MaterialApp(home: StepSequencerView(slotIndex: 0)),
    ),
  );
  await tester.pumpAndSettle();

  // 3. Tap step 1
  await tester.tap(find.byKey(Key('step_0')));
  await tester.pumpAndSettle();

  // 4. Edit pitch in modal
  final slider = find.byKey(Key('pitch_slider'));
  expect(slider, findsOneWidget);

  // 5. Verify parameter update called
  verify(() => mockCubit.updateParameterValue(0, any, any)).called(1);
});
```

### Manual Testing Checklist

- [ ] Desktop layout (all 16 steps visible)
- [ ] Tablet layout (horizontal scroll if needed)
- [ ] Mobile layout (header stacking, horizontal step scroll)
- [ ] Dark mode theme support
- [ ] Offline mode (edits persist, sync on reconnect)
- [ ] Live hardware sync (50ms debounce observable)
- [ ] Scale quantization accuracy (all 11 scales)
- [ ] Step edit modal (all parameters accessible)
- [ ] Sequence switching (1-32 sequences)
- [ ] Playback controls (direction, start/end, gate, glide)

---

## Risk Assessment

### Low Risk ✅

1. **Widget Registration:** Established pattern (NotesAlgorithmView)
2. **State Management:** No new Cubit, using DistingCubit
3. **MIDI Layer:** No changes required
4. **Offline Mode:** Existing infrastructure handles it
5. **Theme Integration:** Additive change only

### Medium Risk ⚠️

1. **Parameter Discovery Verification:** Assumes parameter naming follows discoverable patterns
   - **Mitigation:** Support multiple naming patterns ("1. Pitch", "Step 1 Pitch", "1_Pitch")
   - **Mitigation:** Discover number of steps from metadata or parameter names
   - **Mitigation:** Log warnings for missing parameters, graceful degradation
   - **Validation:** Story 1 AC includes parameter discovery verification
2. **Performance (16 CustomPaint widgets):** May need optimization
   - **Mitigation:** RepaintBoundary, shouldRepaint checks
   - **Fallback:** Simpler container-based bars
3. **Mobile Layout Complexity:** Header stacking, horizontal scroll
   - **Mitigation:** Extensive responsive testing
   - **Mockup validation:** Already designed and reviewed

### High Risk ❌

None identified. This is a UI-only enhancement leveraging mature, tested infrastructure.

---

## Dependencies and Blockers

### External Dependencies
- **None.** All required functionality exists in current codebase.

### Internal Dependencies
- ✅ AlgorithmViewRegistry pattern (exists)
- ✅ DistingCubit state management (exists)
- ✅ IDistingMidiManager interface (exists)
- ✅ Offline mode infrastructure (exists)
- ✅ Parameter update debouncing (NEW, implemented in Story 7)

### Blockers
- **None.** All stories can proceed immediately after Story 1 (registry).

---

## Implementation Sequence Rationale

### Phase 1: Foundation (Story 1)
- **Story 1:** Widget registration (15 min)
- **Why First:** Unblocks all other stories. Developers can see empty widget immediately.

### Phase 2: Core Visualization (Stories 2-3)
- **Story 2:** Step grid component (2-3 days)
- **Story 3:** Step editing modal (1-2 days)
- **Why Second:** Delivers core value (visual editing). Users can edit sequences.
- **Deliverable:** Functional step sequencer, no advanced features yet.

### Phase 3: Playback & Workflow (Stories 6, 5)
- **Story 6:** Playback controls (1 day)
- **Story 5:** Sequence selector (4 hours)
- **Why Third:** Completes workflow (direction, length, multi-sequence).
- **Deliverable:** Full sequence composition capability.

### Phase 4: Musicality & Polish (Stories 4, 7, 8)
- **Story 4:** Scale quantization (6 hours)
- **Story 7:** Auto-sync debouncing (4 hours)
- **Story 8:** Offline mode (2 hours)
- **Why Last:** Polish and optimization. App already functional without these.
- **Deliverable:** Production-ready, optimized, musical editing experience.

**Total:** ~8-10 weeks (conservative estimate)

---

## Success Criteria

### Technical Metrics
- ✅ `flutter analyze` passes with zero warnings
- ✅ All tests pass (unit, widget, integration)
- ✅ 60fps maintained during editing (profiled on real devices)
- ✅ Parameter write latency < 60ms (50ms debounce + 10ms MIDI)
- ✅ Works identically in Live, Mock, and Offline modes

### User Experience Metrics
- ✅ Time to create 16-step sequence: < 2 minutes
- ✅ Mobile layout usable (header clear, steps scrollable)
- ✅ Dark mode fully supported
- ✅ Sequence changes visible within 100ms (local state update)
- ✅ Hardware sync visible within 100ms of debounce completion

### Code Quality Metrics
- ✅ No new Cubits (reuses DistingCubit)
- ✅ No SysEx layer changes
- ✅ Follows existing architecture patterns
- ✅ Widget tree depth < 10 levels (performance)
- ✅ All new code documented with inline comments

---

## Future Enhancements (Out of Scope)

These are explicitly **not** part of this epic but documented for future reference:

1. **Step Sequencer Head Integration** (separate epic)
   - Real-time playback position indicator
   - Requires new SysEx command for "current step" query

2. **Visual Waveform Preview**
   - Show waveform of pitch curve
   - Requires FFT processing or similar

3. **Sequence Library/Templates**
   - Preset sequences (bass lines, arpeggios, etc.)
   - Requires database schema extension

4. **Advanced Gesture Controls**
   - Swipe to draw pitch curves
   - Multi-touch editing
   - Requires gesture detector implementation

5. **Pattern Randomization**
   - Euclidean rhythm generation
   - Markov chain-based melody generation

---

## Appendix A: Algorithm GUID Reference

**Step Sequencer GUID:** `spsq`

**Registry Check:**
```dart
if (algorithmGuid == 'spsq') {
  return StepSequencerView(slot: slot, firmwareVersion: firmwareVersion);
}
```

**Firmware Version Requirements:** None. Step Sequencer exists in all firmware versions >= 1.0.0.

---

## Appendix B: Parameter Name Reference

Based on research document analysis:

### Per-Step Parameters (1-16)
- `Pitch 1` through `Pitch 16` (MIDI note, 0-127)
- `Velocity 1` through `Velocity 16` (0-127)
- `Mod 1` through `Mod 16` (modulation amount)
- `Division 1` through `Division 16` (note division)
- `Pattern 1` through `Pattern 16` (pattern selection)
- `Ties 1` through `Ties 16` (tie to next step)
- `Probability 1` through `Probability 16` (probability of trigger)

### Global Parameters
- `Direction` (Forward, Reverse, Pendulum, Random, etc.)
- `Start Step` (1-16)
- `End Step` (1-16)
- `Gate Length` (1-99%)
- `Trigger Length` (1-100ms)
- `Glide Time` (0-1000ms)
- `Current Sequence` (1-32)

---

## Appendix C: Mockup Reference

**Location:** `docs/step-sequencer-ui-mockups.html`

**Key Design Elements:**
- Teal color scheme (#14b8a6 primary)
- 16-column grid with 8px gap
- Pitch bars: dark gradient background, bright teal fill
- Mobile: horizontal scroll, stacked header
- Desktop: all steps visible, horizontal header
- Dark mode support

**Viewport Simulator:** Use to verify responsive breakpoints during development.

---

## Document Revision History

| Date | Version | Changes | Author |
|------|---------|---------|--------|
| 2025-11-23 | 1.0 | Initial technical context | Winston (Architect) |

---

**End of Technical Context Document**
