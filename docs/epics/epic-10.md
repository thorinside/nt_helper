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

### Story 9: Implement Bit Pattern Editor for Ties
**As a** user
**I want** to edit step Ties parameters using a bit pattern visualization
**So that** I can control substep note ties with an intuitive interface

**AC:**
- AC9.1: Global mode selector includes "Ties" button
- AC9.2: When Ties mode active, step bars show 8-segment bit pattern (not vertical bars)
- AC9.3: Each segment represents one substep tie state (bits 0-7, LSB to MSB)
- AC9.4: Tapping step bar segment toggles that bit directly (0→1 or 1→0)
- AC9.5: Bit toggling updates Ties parameter value (0-255) via debounced write
- AC9.6: Visual feedback: filled segments (orange) for tied substeps, empty (gray) for separate
- AC9.7: Works with existing debounce system (50ms)
- AC9.8: Offline mode support via dirty parameter tracking

**Files:**
- Modify: `lib/ui/widgets/step_sequencer/step_column_widget.dart`
- Modify: `lib/ui/widgets/step_sequencer/pitch_bar_painter.dart`

---

### Story 10: Implement Bit Pattern Editor for Pattern
**As a** user
**I want** to edit Pattern parameters using the same bit pattern editor as Ties
**So that** I can control which substeps play when Division > 0 using visual interface

**AC:**
- AC10.1: When Pattern mode active, step bars show 8-segment bit pattern (same as Ties)
- AC10.2: Each segment represents one substep on/off state (bits 0-7, LSB to MSB)
- AC10.3: Tapping step bar segment toggles that bit directly (0→1 or 1→0)
- AC10.4: Bit toggling updates Pattern parameter value (0-255) via debounced write
- AC10.5: Visual feedback: filled segments (blue) for playing substeps, empty (gray) for muted
- AC10.6: Pattern parameter follows same interaction as Ties (direct tap, debounced write)
- AC10.7: When Division = 0, Pattern parameter has no effect (all substeps irrelevant)
- AC10.8: Works with existing debounce system (50ms)

**Files:**
- Modify: `lib/ui/widgets/step_sequencer/step_column_widget.dart` (add Pattern mode handling)
- Modify: `lib/ui/widgets/step_sequencer/pitch_bar_painter.dart` (add blue bit pattern rendering)

---

### Story 11: Audit and Validate Parameter UI Controls
**As a** user
**I want** all parameter controls to function correctly and display appropriate UI
**So that** I can reliably edit all step parameters with correct interaction methods

**AC:**
- AC11.1: All 10 parameter types per step are discoverable and editable
- AC11.2: Each parameter uses appropriate interaction (continuous drag, discrete selection, bit pattern)
- AC11.3: Value ranges match firmware specifications
- AC11.4: Parameter discovery works across firmware versions 1.10+
- AC11.5: Missing or incorrectly named parameters are gracefully handled
- AC11.6: Division parameter uses discrete 0-14 selection (not continuous)
- AC11.7: All parameter modes render correct visualization
- AC11.8: All parameter edits trigger debounced writes correctly

**Files:**
- Audit: All step sequencer widget files
- Test: Validate parameter discovery and rendering

---

### Story 12: Add Per-Step Probability Parameters
**As a** user
**I want** to edit per-step probability parameters (Mute, Skip, Reset, Repeat)
**So that** I can create generative sequences with probabilistic variation

**AC:**
- AC12.1: `StepSequencerParams` discovers all four probability parameters per step (Mute, Skip, Reset, Repeat)
- AC12.2: Global mode selector includes four new buttons: Mute (red), Skip (pink), Reset (amber), Repeat (cyan)
- AC12.3: When in probability mode, step bars show vertical percentage bars (0-100%)
- AC12.4: Color coding matches mode button (red for Mute, pink for Skip, amber for Reset, cyan for Repeat)
- AC12.5: Dragging step bar updates probability value via debounced write
- AC12.6: Percentage label shows current value (e.g., "75%")
- AC12.7: Values scale correctly: 0-127 firmware → 0-100% UI
- AC12.8: Works with existing debounce and offline mode infrastructure

**Files:**
- Modify: `lib/services/step_sequencer_params.dart` (add getMute, getSkip, getReset, getRepeat)
- Modify: `lib/ui/widgets/step_sequencer/step_grid.dart` (add probability mode buttons)
- Modify: `lib/ui/widgets/step_sequencer/pitch_bar_painter.dart` (add probability rendering)

---

### Story 13: Add Permutation and Gate Type Controls
**As a** user
**I want** to control sequence permutation and gate type via global playback controls
**So that** I can create evolving patterns with different playback variations and gate behavior

**AC:**
- AC13.1: `StepSequencerParams` discovers permutation (0-3) and gateType (0-1) parameters
- AC13.2: Playback controls section includes permutation dropdown and gate type toggle
- AC13.3: Permutation dropdown shows: None (0), Variation 1 (1), Variation 2 (2), Variation 3 (3)
- AC13.4: Gate Type toggle shows: Gate (0) - sustained notes, Trigger (1) - short pulses
- AC13.5: Both controls positioned logically with existing playback controls
- AC13.6: Selection updates hardware parameter via debounced write (50ms)
- AC13.7: Controls integrate seamlessly with existing layout (desktop horizontal, mobile wrapping)
- AC13.8: Offline mode support via existing dirty parameter tracking

**Files:**
- Modify: `lib/services/step_sequencer_params.dart` (add permutation, gateType getters)
- Modify: `lib/ui/widgets/step_sequencer/playback_controls.dart` (add dropdown and toggle)

---

### Story 14: Gate Type Parameter Dependency Handling
**As a** user
**I want** parameter availability to update automatically when Gate Type changes
**So that** I only see relevant parameters (Gate Length vs Trigger Length) based on the current gate type

**AC:**
- AC14.1: When Gate Type parameter changes, refresh all parameter states to detect disabled/enabled changes
- AC14.2: Before displaying Gate Length parameter, fetch latest parameter values from hardware/state
- AC14.3: Gate Length parameter shows disabled state (grayed out) when Gate Type = Trigger (value: 1)
- AC14.4: Trigger Length parameter shows disabled state (grayed out) when Gate Type = Gate (value: 0)
- AC14.5: Parameter refresh triggered automatically when Gate Type is modified
- AC14.6: Disabled parameters remain visible but non-interactive (tooltip explains why disabled)
- AC14.7: Parameter dependency logic works identically in Connected, Offline, and Demo modes
- AC14.8: No performance degradation (parameter refresh < 10ms)

**Implementation Notes:**
- Gate Type parameter (0=Gate, 1=Trigger) controls which length parameter is active
- When Gate Type = 0 (Gate): Gate Length enabled, Trigger Length disabled
- When Gate Type = 1 (Trigger): Trigger Length enabled, Gate Length disabled
- Must refresh parameter disabled state when:
  1. Gate Type parameter is modified by user
  2. Before rendering Gate Length or Trigger Length controls
  3. After slot/preset change
- Use existing parameter disabled flag from hardware state
- Leverage `StepSequencerParams` parameter discovery for type detection

**Files:**
- Modify: `lib/ui/widgets/step_sequencer/playback_controls.dart` (add refresh logic)
- Modify: `lib/services/step_sequencer_params.dart` (detect Gate Type changes)
- Test: `test/ui/widgets/step_sequencer/playback_controls_test.dart` (dependency behavior)

---

### Story 15: Add Randomize Menu and Settings
**As a** user
**I want** to randomize sequence parameters via a menu action and configure randomization settings
**So that** I can quickly generate new musical ideas with controlled randomization

**AC:**
- AC15.1: Step Sequencer header includes three-dot overflow menu (top-right corner)
- AC15.2: Menu contains two items: "Randomize" and "Randomize Settings..."
- AC15.3: "Randomize" triggers randomization by setting Randomise parameter to 1 for 100ms, then back to 0
- AC15.4: "Randomize Settings..." opens dialog showing all 17 randomize parameters
- AC15.5: Settings dialog uses scrollable area with existing parameter editor widgets
- AC15.6: All parameter editors wire to `cubit.updateParameterValue()` (reuse existing infrastructure)
- AC15.7: Dialog responsive: full-screen on mobile, centered (600px max) on desktop
- AC15.8: `StepSequencerParams` discovers all randomize parameters (randomise, randomiseWhat, noteDistribution, min/max/mean note, probabilities, etc.)
- AC15.9: Works in Connected, Offline, and Demo modes (leverage existing infrastructure)
- AC15.10: Optional user feedback: SnackBar "Randomizing sequence..." after trigger

**Implementation Notes:**
- Randomise parameter (0-1) is a boolean trigger that initiates randomization
- Setting from 0→1 triggers hardware randomization, parameter auto-resets to 0
- Wait 100ms between setting 1 and resetting to 0 (allow hardware to process)
- Settings dialog displays 17 parameters: trigger, distribution type, pitch ranges, rhythm ranges, probabilities (0-100% UI, maps to 0-127 firmware)
- Reuse existing parameter slider/dropdown widgets (no custom editors needed)
- All parameter updates use existing debouncing and offline tracking

**Files:**
- Modify: `lib/services/step_sequencer_params.dart` (add 17 randomize parameter getters)
- Modify: `lib/ui/widgets/step_sequencer/step_sequencer_view.dart` (add overflow menu to header)
- Create: `lib/ui/widgets/step_sequencer/randomize_settings_dialog.dart` (settings dialog)
- Test: `test/ui/widgets/step_sequencer/randomize_settings_dialog_test.dart`

---

### Story 16: Add Division Subdivision Display
**As a** user
**I want** to see the number of subdivisions and their type (Ratchets/Repeats) below the Division parameter
**So that** I can quickly understand how many substeps are active and whether the step will ratchet or repeat

**AC:**
- AC16.1: Calculate subdivision count: `subdivisions = |Division - 7| + 1`
- AC16.2: Display subdivision label below Division value in step columns
- AC16.3: Label shows "X Ratchets" when Division < 7 (e.g., Division=6 → "2 Ratchets")
- AC16.4: Label shows "X Repeats" when Division > 7 (e.g., Division=9 → "3 Repeats")
- AC16.5: Label shows "1" or hidden when Division = 7 (no subdivision)
- AC16.6: Label visible only when Division mode active (hidden in other modes)
- AC16.7: Label updates immediately when Division value changes
- AC16.8: Subdivision count indicates number of active bits in Pattern/Ties (1-8)
- AC16.9: Label is read-only (purely informational, no tap handling)
- AC16.10: Responsive layout: label fits within step column width on mobile and desktop

**Implementation Notes:**
- Division = 7 is the default (zero divisions, one note per step)
- Division < 7 (0-6) creates ratchets (fast subdivided notes)
- Division > 7 (8-14) creates repeats (multiple sustained notes)
- Subdivision count correlates directly with Pattern/Ties bit count:
  - 1 subdivision → 1 bit active (bit 0)
  - 8 subdivisions → 8 bits active (bits 0-7)
- Label styling: smaller font (10-12px), secondary text color, opacity 0.7
- Label positioned below division value with 4-8px spacing

**Files:**
- Modify: `lib/ui/widgets/step_sequencer/step_column_widget.dart` (add subdivision label)
- Test: Widget tests for label rendering and calculation logic

---

### Story 17: Use Firmware Enum Strings for Dropdowns
**As a** user
**I want** dropdown lists to display firmware-provided enum strings
**So that** parameter options match exactly what the hardware uses and stay synchronized across firmware versions

**AC:**
- AC17.1: Replace hardcoded Direction dropdown strings with firmware enum strings
- AC17.2: Replace hardcoded Permutation dropdown strings with firmware enum strings
- AC17.3: Replace hardcoded Sequence selector with firmware enum strings (if available)
- AC17.4: Replace hardcoded Gate Type toggle strings with firmware enum strings
- AC17.5: Replace hardcoded Randomize Settings dropdowns with firmware enum strings
- AC17.6: Create dynamic dropdown builder that reads enum strings from ParameterInfo
- AC17.7: Implement fallback to numeric labels when enum strings unavailable
- AC17.8: Dropdown item counts adapt to firmware metadata (no hardcoded counts)
- AC17.9: Consistent with standard parameter editor (reuse enum string logic if available)
- AC17.10: Works across firmware versions (adapts automatically to new/changed options)

**Implementation Notes:**
- Enum strings come from ParameterInfo.enumStrings field (firmware metadata)
- Same infrastructure as standard parameter editor uses for enum parameters
- Benefits: firmware version compatibility, localization support, consistency, maintainability
- Fallback strategy: show numeric labels ("0", "1", "2") when enum strings unavailable
- Example: Direction dropdown may have 6-10 options depending on firmware version

**Files:**
- Modify: `lib/ui/widgets/step_sequencer/playback_controls.dart` (Direction, Permutation, Gate Type)
- Modify: `lib/ui/widgets/step_sequencer/sequencer_header.dart` (Sequence selector)
- Modify: `lib/ui/widgets/step_sequencer/randomize_settings_dialog.dart` (Randomize dropdowns)
- Create: `lib/util/enum_dropdown_builder.dart` (reusable helper) (optional)
- Test: Unit tests for enum string handling and fallbacks

---

### Story 18: Add Parameter Pages View
**As a** user
**I want** to access parameter pages for MIDI, routing, and other parameters not shown in the custom UI
**So that** I can configure all Step Sequencer parameters without falling back to the generic parameter list

**AC:**
- AC18.1: Identify parameters not covered by custom Step Sequencer UI (MIDI, routing, modulation, other globals)
- AC18.2: Group uncovered parameters into logical pages (MIDI, Routing, Modulation, Global)
- AC18.3: Add "Parameter Pages..." option to overflow menu
- AC18.4: Parameter pages view shows page tabs and scrollable parameter lists
- AC18.5: Reuse existing parameter editor widgets (sliders, dropdowns, switches)
- AC18.6: MIDI page displays MIDI parameters (channel, velocity curve, note mode, etc.)
- AC18.7: Routing page displays bus assignments and mix levels
- AC18.8: Responsive layout: full-screen on mobile, large modal on desktop
- AC18.9: All parameter updates use `cubit.updateParameterValue()` (same infrastructure as custom UI)
- AC18.10: Hide empty pages (don't show tabs for pages with zero parameters)

**Implementation Notes:**
- Parameter grouping uses heuristics: name patterns, parameter number ranges
- Reuse parameter editor infrastructure from standard parameter list
- Alternative approach: Allow access to ALL pages (not just uncovered) - defer to future story
- Pages adapt to available parameters (firmware-driven, no hardcoded assumptions)
- Same offline tracking and debouncing as custom Step Sequencer UI

**Files:**
- Create: `lib/ui/widgets/step_sequencer/parameter_pages_view.dart` (main view)
- Modify: `lib/ui/widgets/step_sequencer/step_sequencer_view.dart` (add overflow menu item)
- Create: `lib/util/parameter_page_assigner.dart` (parameter grouping logic) (optional)
- Test: Widget tests for pages view and parameter discovery

---

## Implementation Order

**Completed Stories (in order):**
1. **Story 1** - Widget registration ✅
2. **Story 2** - Step grid component ✅
3. **Story 3** - Step editing modal ✅
4. **Story 4** - Scale quantization ✅
5. **Story 5** - Sequence selector ✅
6. **Story 6** - Playback controls ✅
7. **Story 7** - Auto-sync debouncing ✅
8. **Story 8** - Offline mode ✅
9. **Story 9** - Bit pattern editor for Ties ✅
10. **Story 10** - Bit pattern editor for Pattern ✅
11. **Story 11** - Audit and validate parameter controls ✅
12. **Story 12** - Per-step probability parameters ✅
13. **Story 13** - Permutation and gate type controls ✅

**Drafted (Ready for Dev):**
14. **Story 14** - Gate type parameter dependency handling 📝
15. **Story 15** - Randomize menu and settings 📝
16. **Story 16** - Division subdivision display 📝
17. **Story 17** - Use firmware enum strings for dropdowns 📝
18. **Story 18** - Add parameter pages view 📝

**Epic Status:** 13 of 18 stories complete (72%)

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
