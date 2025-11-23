# Epic: Visual Step Sequencer UI Widget

**Created:** 2025-11-23
**Status:** Planned
**Priority:** High
**Research:** [docs/research-step-sequencer-2025-11-23.md](../research-step-sequencer-2025-11-23.md)
**Mockups:** [docs/step-sequencer-ui-mockups.html](../step-sequencer-ui-mockups.html)

## Vision

Transform the Step Sequencer algorithm from a boring parameter list into an intuitive visual grid interface that makes step sequencing effortless and musical.

**Core Experience:** User selects Step Sequencer algorithm → sees beautiful visual step grid → edits sequences visually → changes auto-sync to hardware (50ms).

## User Value

- **Current Pain:** 50+ parameters as flat list = unusable for composition
- **Solution:** Visual grid showing all 16 steps, pitch/velocity bars, scale quantization, immediate sync
- **Outcome:** Users can compose musical sequences quickly, see melodic shapes visually, stay "in flow"

## Technical Approach

**Widget Replacement Pattern:**
- Add `case 'spsq':` to `AlgorithmViewRegistry.findViewFor()`
- Return `StepSequencerView` widget (replaces parameter list in-place)
- Reference: `NotesAlgorithmView` pattern

**Architecture:**
- Reuse existing `DistingCubit` state management
- Per-parameter MIDI writes with 50ms debounce
- Auto-sync when hardware connected
- Offline mode with dirty tracking

## Design Direction

**Compact Grid** (Direction 1 from mockups):
- 80% visual step grid (16 columns)
- 15% playback controls (direction, start/end, gate, glide)
- 5% header (sequence selector, quantize, sync status)

## Flutter Implementation Guide

### Theme Colors (Teal)
```dart
// Primary teal colors
static const primaryTeal = Color(0xFF14b8a6);
static const darkTeal = Color(0xFF0f766e);
static const darkerTeal = Color(0xFF115e59);
static const brightTeal = Color(0xFF5eead4);

// Gradients
static const pitchBarGradient = LinearGradient(
  begin: Alignment.bottomCenter,
  end: Alignment.topCenter,
  colors: [darkTeal, darkerTeal],
);

static const pitchFillColor = brightTeal;
```

### Widget Hierarchy
```dart
StepSequencerView (top level)
├── Column
│   ├── SequencerHeader (5% height)
│   │   ├── SequenceSelector + SyncIndicator (Row 1)
│   │   └── QuantizeControls (Row 2)
│   ├── StepGridView (80% height)
│   │   └── ListView.builder (horizontal scroll on mobile)
│   │       └── StepColumnWidget × 16
│   │           ├── StepNumber
│   │           ├── PitchBarWidget (CustomPaint)
│   │           └── VelocityIndicator
│   └── PlaybackControls (15% height)
│       └── Wrap (auto-wrap on mobile)
```

### Responsive Layout Strategy

**Desktop/Tablet (width > 768px):**
```dart
// Header: horizontal flex layout
Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    SequenceSelector(), // left
    QuantizeControls(), // center
    SyncStatusIndicator(), // right
  ],
)

// Grid: all 16 steps visible
GridView.count(
  crossAxisCount: 16,
  childAspectRatio: 0.3,
  children: stepColumns,
)
```

**Mobile (width ≤ 768px):**
```dart
// Header: vertical stack with spacing
Column(
  crossAxisAlignment: CrossAxisAlignment.stretch,
  children: [
    Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(child: SequenceSelector()),
        SizedBox(width: 8),
        CompactSyncIndicator(), // just green dot, 24×24
      ],
    ),
    SizedBox(height: 16), // 16px gap between rows
    QuantizeControlsRow(), // Snap toggle + Scale dropdown
  ],
)

// Grid: horizontal scroll
SingleChildScrollView(
  scrollDirection: Axis.horizontal,
  child: Row(
    children: List.generate(16, (i) =>
      SizedBox(
        width: 60,
        child: StepColumnWidget(stepIndex: i),
      ),
    ),
  ),
)
```

### Responsive Detection
```dart
class StepSequencerView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width <= 768;
    final isTablet = width > 768 && width <= 1024;

    return Column(
      children: [
        isMobile
          ? _buildMobileHeader()
          : _buildDesktopHeader(),
        Expanded(
          child: isMobile
            ? _buildHorizontalScrollGrid()
            : _buildFullGrid(),
        ),
        _buildPlaybackControls(compact: isMobile),
      ],
    );
  }
}
```

### Key Widget Patterns

**Step Column (Pitch Bar Visualization):**
```dart
class PitchBarWidget extends StatelessWidget {
  final int pitchValue; // 0-127
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 280,
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isActive ? primaryTeal.withOpacity(0.2) : null,
        border: Border.all(
          color: isActive ? primaryTeal : Colors.grey.shade300,
          width: isActive ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: CustomPaint(
        painter: PitchBarPainter(
          pitchValue: pitchValue,
          backgroundColor: pitchBarGradient,
          fillColor: pitchFillColor,
        ),
      ),
    );
  }
}

class PitchBarPainter extends CustomPainter {
  final int pitchValue;
  final Gradient backgroundColor;
  final Color fillColor;

  @override
  void paint(Canvas canvas, Size size) {
    // Draw dark teal background gradient
    final bgPaint = Paint()..shader = backgroundColor.createShader(
      Rect.fromLTWH(0, 0, size.width, size.height),
    );
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Draw bright teal fill (bottom to pitch level)
    final fillHeight = (pitchValue / 127.0) * size.height;
    final fillPaint = Paint()..color = fillColor;
    canvas.drawRect(
      Rect.fromLTWH(0, size.height - fillHeight, size.width, fillHeight),
      fillPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
```

**Compact Sync Indicator (Mobile):**
```dart
class CompactSyncIndicator extends StatelessWidget {
  final SyncStatus status; // synced, editing, syncing, error

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: _getStatusColor(status),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  Color _getStatusColor(SyncStatus status) {
    switch (status) {
      case SyncStatus.synced: return Color(0xFF10b981); // green
      case SyncStatus.editing: return Color(0xFFf59e0b); // orange
      case SyncStatus.syncing: return Color(0xFF3b82f6); // blue
      case SyncStatus.error: return Color(0xFFef4444); // red
    }
  }
}
```

**Scale Quantize Controls:**
```dart
class QuantizeControlsRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StepSequencerCubit, StepSequencerState>(
      builder: (context, state) {
        return Row(
          children: [
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                icon: Icon(Icons.piano),
                label: Text('Snap to Scale: ${state.snapEnabled ? "ON" : "OFF"}'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: state.snapEnabled ? primaryTeal : Colors.grey,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => context.read<StepSequencerCubit>()
                  .toggleSnapToScale(),
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              flex: 1,
              child: DropdownButtonFormField<String>(
                value: state.selectedScale,
                decoration: InputDecoration(
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                items: ScaleQuantizer.scales.keys.map((scale) =>
                  DropdownMenuItem(value: scale, child: Text(scale)),
                ).toList(),
                onChanged: (scale) => context.read<StepSequencerCubit>()
                  .setScale(scale!),
              ),
            ),
          ],
        );
      },
    );
  }
}
```

### Performance Considerations

1. **Use `const` constructors** wherever possible for static widgets
2. **CustomPaint for step bars** - more efficient than stacked containers
3. **ListView.builder** for horizontal scroll (lazy loading on mobile)
4. **BlocBuilder with `buildWhen`** - only rebuild when specific state changes:
   ```dart
   BlocBuilder<DistingCubit, DistingState>(
     buildWhen: (prev, curr) =>
       prev.slots[slotIndex].parameters != curr.slots[slotIndex].parameters,
     builder: (context, state) => StepGridView(...),
   )
   ```
5. **Debounced parameter updates** - prevent excessive MIDI writes during slider drag

### Dark Mode Support
```dart
// Use Theme.of(context) for text colors
Text(
  'Step $stepNumber',
  style: TextStyle(
    color: Theme.of(context).brightness == Brightness.dark
      ? Colors.grey.shade400
      : Colors.grey.shade700,
  ),
)

// Use theme-aware backgrounds
Container(
  color: Theme.of(context).brightness == Brightness.dark
    ? Colors.grey.shade900
    : Colors.grey.shade50,
)
```

## User Stories

### Story 1: Algorithm Widget Registration
**As a** developer
**I want** Step Sequencer algorithm to render custom widget
**So that** users see visual UI instead of parameter list

**AC:**
- AC1.1: Add `case 'spsq':` to `AlgorithmViewRegistry` (lib/ui/algorithm_registry.dart:8)
- AC1.2: Return `StepSequencerView(slot: slot, firmwareVersion: firmwareVersion)`
- AC1.3: Widget renders when user navigates to Step Sequencer algorithm
- AC1.4: Fallback to parameter list if widget fails to load
- AC1.5: `StepSequencerParams.fromSlot()` discovers parameter structure from slot data
- AC1.6: Verify number of steps discovered (log count, expect 16)
- AC1.7: Verify all step parameters found (Pitch, Velocity, Mod, Division, Pattern, Ties, Probability)
- AC1.8: Verify global parameters found (Direction, Start/End Step, Gate/Trigger/Glide)
- AC1.9: Log warnings (not errors) for any missing parameters

**Files:**
- `lib/ui/algorithm_registry.dart` (add case)
- `lib/ui/step_sequencer_view.dart` (new widget)
- `lib/services/step_sequencer_params.dart` (new - parameter discovery)

---

### Story 2: Step Grid Component
**As a** user
**I want** to see all 16 steps as a visual grid
**So that** I can see my sequence at a glance

**AC:**
- AC2.1: Display 16 step columns in horizontal grid
- AC2.2: Each step shows pitch as vertical bar (gradient fill)
- AC2.3: Each step shows velocity as horizontal indicator below pitch
- AC2.4: Step numbers labeled 1-16
- AC2.5: Grid is scrollable if content exceeds screen width (mobile)
- AC2.6: Active step highlighted with border color change

**Design:**
- Use Flutter `CustomPaint` for efficient rendering
- Grid gap: 8px (compact)
- Step column min-height: 280px
- Pitch bar: Gradient #667eea → #764ba2

**Files:**
- `lib/ui/widgets/step_sequencer/step_grid_view.dart` (new)
- `lib/ui/widgets/step_sequencer/step_column_widget.dart` (new)

---

### Story 3: Step Selection and Editing
**As a** user
**I want** to tap a step to edit its parameters
**So that** I can change pitch, velocity, and other values

**AC:**
- AC3.1: Tap step → opens modal with all per-step parameters
- AC3.2: Modal shows: Pitch (slider + numeric), Velocity (slider), Mod (slider)
- AC3.3: Modal shows advanced: Division, Pattern, Ties, Probability sliders
- AC3.4: Changes call `cubit.updateParameter(name, value)`
- AC3.5: Modal has Copy/Paste/Clear/Randomize buttons
- AC3.6: Close modal → changes persist, auto-sync triggers

**Files:**
- `lib/ui/widgets/step_sequencer/step_edit_modal.dart` (new)

---

### Story 4: Scale Quantization
**As a** user
**I want** to snap pitch values to a musical scale
**So that** my sequences are always in-key

**AC:**
- AC4.1: "Snap to Scale" toggle button in header (ON/OFF states)
- AC4.2: Scale selector dropdown (Chromatic, Major, Minor, Dorian, Pentatonic, etc.)
- AC4.3: Root note selector (C, C#, D, ... B)
- AC4.4: When snap enabled: pitch edits quantize to nearest scale degree in real-time
- AC4.5: "Quantize All Steps" button applies current scale to all existing steps (with confirmation)
- AC4.6: Toggle OFF → raw MIDI values (no quantization)

**Implementation:**
```dart
class ScaleQuantizer {
  static const scales = {
    'Major': [0,2,4,5,7,9,11],
    'Minor': [0,2,3,5,7,8,10],
    // ... 10 scales total
  };

  static int quantize(int midiNote, String scale, int root);
}
```

**Files:**
- `lib/services/scale_quantizer.dart` (new)
- `lib/ui/widgets/step_sequencer/quantize_controls.dart` (new)

---

### Story 5: Sequence Selector
**As a** user
**I want** to switch between 32 stored sequences
**So that** I can build songs from multiple patterns

**AC:**
- AC5.1: Dropdown showing "Sequence 1-32" with optional names
- AC5.2: Selecting sequence loads its 16 steps from hardware
- AC5.3: Loading state shown during sequence switch
- AC5.4: Currently active sequence persists in cubit state
- AC5.5: Sequence names editable (if firmware supports)

**Files:**
- `lib/ui/widgets/step_sequencer/sequence_selector.dart` (new)

---

### Story 6: Playback Controls
**As a** user
**I want** to configure how the sequence plays
**So that** I can control direction, length, and gate behavior

**AC:**
- AC6.1: Direction dropdown (Forward, Reverse, Pendulum, Random, etc.)
- AC6.2: Start Step input (1-16)
- AC6.3: End Step input (1-16)
- AC6.4: Gate Length slider (1-99%)
- AC6.5: Trigger Length slider (1-100ms)
- AC6.6: Glide Time slider (0-1000ms)
- AC6.7: All controls auto-sync with 50ms debounce

**Files:**
- `lib/ui/widgets/step_sequencer/playback_controls.dart` (new)

---

### Story 7: Auto-Sync with Debouncing
**As a** user
**I want** my edits to sync automatically to hardware
**So that** I don't have to press a sync button

**AC:**
- AC7.1: Parameter changes trigger MIDI write after 50ms debounce
- AC7.2: Rapid edits (slider drag) → only final value written
- AC7.3: Sync status indicator shows: Synced (green), Editing (orange), Syncing (blue)
- AC7.4: Failed writes → error indicator with retry button
- AC7.5: Debouncer per parameter (multiple params can sync concurrently)

**Implementation:**
```dart
class ParameterWriteDebouncer {
  final Map<String, Timer> _timers = {};
  void schedule(String key, VoidCallback callback, Duration delay);
}

// In cubit:
final _debouncer = ParameterWriteDebouncer();
void updateStepPitch(int step, int value) {
  emit(state.copyWith(...));
  _debouncer.schedule('pitch_$step', () {
    midiManager.setParameterValue('pitch_$step', value);
  }, Duration(milliseconds: 50));
}
```

**Files:**
- `lib/cubit/parameter_write_debouncer.dart` (new)
- `lib/cubit/disting_cubit.dart` (extend with debouncer)

---

### Story 8: Offline Mode Support
**As a** user
**I want** to edit sequences without hardware connected
**So that** I can work anywhere

**AC:**
- AC8.1: When offline: "Offline - editing locally" banner shown
- AC8.2: All editing works normally (no restrictions)
- AC8.3: Changes tracked in dirty params map
- AC8.4: When hardware reconnects → "Sync X changes?" prompt
- AC8.5: User confirms → bulk sync all dirty params
- AC8.6: Progress indicator during bulk sync

**Files:**
- No new files (reuse existing offline infrastructure)

---

## Implementation Order

1. **Story 1** - Widget registration (15 min)
2. **Story 2** - Step grid component (2-3 days)
3. **Story 3** - Step editing modal (1-2 days)
4. **Story 6** - Playback controls (1 day)
5. **Story 4** - Scale quantization (6 hours)
6. **Story 5** - Sequence selector (4 hours)
7. **Story 7** - Auto-sync debouncing (4 hours)
8. **Story 8** - Offline mode (2 hours)

**Total Estimate:** ~8-10 weeks

## Success Metrics

- Time to create 16-step sequence: < 2 minutes
- Parameter edit latency: < 60ms (50ms debounce + 10ms MIDI)
- UI frame rate: > 60fps during editing
- User feedback: "Easier than hardware interface"

## Out of Scope (Phase 2)

- Step Sequencer Head integration (separate epic)
- Real-time playback position indicator (hardware limitation)
- Visual waveform preview
- Sequence library/templates
- Advanced gesture controls (swipe to draw pitch curves)

## Dependencies

- Existing `AlgorithmViewRegistry` pattern
- Existing `DistingCubit` state management
- Existing MIDI write infrastructure (`IDistingMidiManager`)
- Offline mode infrastructure

## References

- Research: `docs/research-step-sequencer-2025-11-23.md`
- Mockups: `docs/step-sequencer-ui-mockups.html`
- Pattern Reference: `lib/ui/notes_algorithm_view.dart`
- Registry: `lib/ui/algorithm_registry.dart`
