# Technical Research Report: Disting NT Step Sequencer Algorithm

**Date:** 2025-11-23
**Prepared by:** Neal
**Project Context:** nt_helper - Flutter application for Disting NT hardware management

---

## Executive Summary

This research investigates the Disting NT Step Sequencer algorithm (`spsq`) and Step Sequencer Head algorithm (`spsh`) to inform the design of a new visual UI for step sequencing within the nt_helper application.

### Key Findings

**Step Sequencer Overview:**
- 16-step note sequencer with pitch, velocity, and modulation per step
- 32 internal sequences (snapshots/patterns) for song building
- Supports both CV and MIDI output
- Advanced features: ratcheting, repeats, ties, skip/mute probability
- Based on Expert Sleepers FH-2 sequencer design

**Step Sequencer Head:**
- Additional playback head for existing sequences
- Shares sequence data from nearest Step Sequencer above it
- Independent playback parameters (direction, speed, transposition)
- Enables polyrhythmic and polytemporal sequencing

### Research-Informed Design Principles (from First Principles & Six Thinking Hats analysis)

**Core UI Elements (Primary - 80% of screen):**
1. Visual step grid showing all 16 steps simultaneously
2. Per-step CV values (pitch, velocity, modulation) - editable
3. Clear sequence length indication
4. Interactive editing (tap/click to modify values)

**Secondary Controls (20% of screen):**
- Playback configuration (direction, start/end, permutation)
- Sequence selection (1-32)
- Gate/timing controls
- Output routing

**Tertiary (collapsible/modal):**
- Advanced features (probability, randomization)
- Step Sequencer Head integration (optional Phase 2)

---

## 1. Research Objectives

### Technical Question

**How can we create an intuitive visual UI for the Disting NT Step Sequencer that surfaces all functionality and makes the complex simple?**

Specific goals:
- Document all step sequencer parameters and their behavior
- Understand the data model (CV levels, steps, sequencing logic)
- Map parameter organization (global vs per-step)
- Explore Step Sequencer Head algorithm for potential integration
- Identify UI design opportunities and constraints

### Project Context

**Brownfield:** Existing nt_helper Flutter application with:
- MIDI SysEx communication infrastructure
- Parameter reading/writing capabilities
- Offline mode with cached algorithm data
- Cross-platform support (macOS, iOS, Android, Linux, Windows)

**Current Pain Point:** The hardware interface presents 50+ parameters as a flat list, making step sequencer difficult and unintuitive to use.

**Solution Vision:** A full-screen visual step sequencing UI that presents steps as an interactive grid, with CV values editable graphically and numerically.

### Requirements and Constraints

#### Functional Requirements

**Core Sequencing:**
- Display all 16 steps visually in a grid
- Edit pitch CV values per step (0-127 MIDI note range, maps to CV)
- Edit velocity per step (1-127)
- Edit modulation value per step (-10.0 to +10.0V)
- Configure sequence length (Start: 1-16, End: 1-16)
- Set playback direction (Forward, Reverse, Pendulum, Random, etc.)
- Select active sequence (1-32 snapshots)

**Advanced Features:**
- Per-step division (repeats or ratchets)
- Per-step pattern (substep on/off bitmap)
- Per-step ties (legato/glide between notes)
- Per-step probability (Mute %, Skip %, Reset %, Repeat %)
- Gate configuration (type, length)
- Glide time control

**Real-time sync:**
- Read current parameter values from hardware
- Write parameter changes via MIDI SysEx
- Offline mode support (work without hardware)

#### Non-Functional Requirements

**Performance:**
- Smooth UI rendering for 16-step grid with live updates
- Responsive parameter editing (< 100ms latency)
- Efficient MIDI SysEx communication

**Usability:**
- Touch-friendly on mobile (iOS/Android)
- Mouse/trackpad friendly on desktop (macOS/Linux/Windows)
- Intuitive visual design (no manual required for basic use)
- Progressive disclosure (simple mode → advanced mode)

**Scalability:**
- Support future expansion (64-step sequences if firmware adds)
- Reusable architecture for other complex algorithms

#### Technical Constraints

**Platform:** Flutter (Dart)
**Communication:** MIDI SysEx only (no real-time playback position feedback)
**Existing Infrastructure:**
- `DistingCubit` for state management
- `IDistingMidiManager` for MIDI communication
- Algorithm metadata service for parameter definitions
- Offline mode with cached data

**Known Limitation:** Cannot see real-time playback position (which step is currently playing) - hardware doesn't provide this via SysEx.

---

## 2. Algorithm Analysis

### Step Sequencer (spsq) - Detailed Profile

#### Overview

The Step Sequencer is a 16-step note sequencer based on the sequencers in the Expert Sleepers FH-2 module. It outputs CV and/or MIDI, with each step containing pitch, velocity, and a general-purpose modulation value.

**Source:** nt_helper metadata (`docs/algorithms/spsq.json`), [Expert Sleepers Disting NT](https://www.expert-sleepers.co.uk/distingNT.html)

#### Core Capabilities

**Sequence Storage:**
- 32 internal sequences (referred to as snapshots or patterns)
- Switchable manually or via CV control
- Enables song building by chaining sequences

**Per-Step Data:**
Each of the 16 steps contains:
- **Pitch** (0-127): MIDI note number, maps to CV pitch output
- **Velocity** (1-127): Note dynamics/volume (MIDI) or CV level
- **Mod** (-10.0 to +10.0V): General-purpose modulation output
- **Division** (0-14): Step timing subdivision (see Division section)
- **Pattern** (0-255): 8-bit bitmap for substep on/off
- **Ties** (0-255): 8-bit bitmap for substep ties (legato/glide)
- **Mute** (0-100%): Probability the step will be muted
- **Skip** (0-100%): Probability the step will be skipped
- **Reset** (0-100%): Probability the sequence will reset at this step
- **Repeat** (0-100%): Probability the step will repeat

**Global Parameters:**
- **Sequence** (1-32): Select active sequence/snapshot
- **Start** (1-16): First step of active sequence section
- **End** (1-16): Last step of active sequence section
- **Direction** (0-6): Playback direction (see Direction section)
- **Permutation** (0-3): Step order variation (see Permutation section)
- **Gate type** (0-1): Gate or trigger mode
- **Gate length** (1-99%): Duration of gate output
- **Trigger length** (1-100ms): Duration of trigger output
- **Glide** (0-1000ms): Portamento time for pitch CV

#### Division Parameter Deep Dive

The Division parameter (per-step) controls timing subdivisions. Value range 0-14 with special meaning:

**Interpretation:**
- **0-6:** Repeats - step plays multiple times on subsequent clocks
- **7 (center/default):** Normal - step plays once per clock
- **8-14:** Ratchets - step fires multiple gates within one clock period

**Pattern Bitmap:**
The Pattern parameter (0-255, 8-bit) determines which substeps (repeats or ratchets) are active.
- Each bit represents a substep
- `1` = substep plays, `0` = substep silent
- Example: Pattern=0b10101010 (170) = alternating substeps play

**Use Cases:**
- Repeats: Create syncopated rhythms by extending step duration
- Ratchets: Create drum rolls, flams, and rapid note bursts

**Source:** nt_helper metadata, [Patching a Ratcheting Sequence - Learning Modular](https://learningmodular.com/patching-a-ratcheting-sequence/), [How to Ratchet Notes - Sweetwater](https://www.sweetwater.com/insync/how-to-ratchet-notes-in-a-step-sequencer/)

#### Ties Parameter Deep Dive

The Ties parameter (per-step, 0-255, 8-bit bitmap) controls legato connections between notes.

**Behavior:**
- **CV Output:** Gate stays high between tied notes, pitch CV glides (if glide time > 0)
- **MIDI Output:** Note-off follows next note-on (legato articulation)

**Pattern Bitmap:**
Similar to Pattern, each bit represents a substep's tie status.

**Use Cases:**
- Create smooth melodic phrases
- Synthesizer legato playing
- Glide/portamento effects

#### Direction Parameter Options

Direction (global parameter, 0-6) controls playback order:

| Value | Direction | Description |
|-------|-----------|-------------|
| 0 | Forward | Steps play 1→2→3...→End, loop |
| 1 | Reverse | Steps play End→...→3→2→1, loop |
| 2 | Pendulum | Forward then reverse (1→End→1) |
| 3 | Pendulum (no repeat) | Forward then reverse, skip endpoint repeats |
| 4 | Random | Random step selection |
| 5 | Random (no repeat) | Random, avoid immediate repeats |
| 6 | Brownian | Random walk (±1 step from current) |

**Source:** Common step sequencer patterns, verified in nt_helper metadata

#### Permutation Parameter

Permutation (global parameter, 0-3) varies step order algorithmically.

**Values:**
- **0:** No permutation (normal order)
- **1-3:** Different permutation algorithms (specific algorithms undocumented in available sources)

**Note:** Exact permutation algorithms require firmware manual reference.

#### Output Modes

**CV Output:**
- Pitch CV (V/oct standard)
- Gate/Trigger output
- Velocity CV output
- Modulation CV output

**MIDI Output:**
- Note on/off messages
- Velocity values
- CC messages for modulation

**Simultaneous:** Can output both CV and MIDI concurrently

#### Randomization Function

The algorithm includes a randomization function for:
- **Pitches:** Randomize all step pitch values
- **Rhythm:** Randomize divisions, patterns, ties
- **Both:** Randomize pitches and rhythm simultaneously

**Note:** Randomization trigger mechanism (button, parameter, CV input) requires firmware manual reference.

#### Current Status (Firmware 1.11.0)

**Latest Firmware:** v1.11.0 (released October 20, 2025)
**Step Sequencer Introduction:** v1.2.0
**Recent Enhancements:**
- v1.5.0: MIDI note entry recording, snapshot functionality
- v1.6.0: One-shot reset mode, probability-based Skip/Reset

**Source:** [Expert Sleepers disting NT Firmware Updates](https://www.expert-sleepers.co.uk/distingNTfirmwareupdates.html), [MATRIXSYNTH: disting NT v1.5.0](https://www.matrixsynth.com/2025/01/expert-sleepers-disting-nt-v150.html)

---

### Step Sequencer Head (spsh) - Detailed Profile

#### Overview

The Step Sequencer Head shares sequence data from the nearest Step Sequencer above it in the algorithm list and provides independent playback parameters. This enables multiple simultaneous playback heads reading the same sequence with different characteristics.

**Key Concept:** One sequence, multiple playback interpretations.

**Source:** nt_helper metadata (`docs/algorithms/spsh.json`)

#### Capabilities

**Shared Data:**
- Reads pitch, velocity, mod, division, pattern, ties from parent Step Sequencer
- Automatically updates when parent sequence changes

**Independent Parameters:**
- **Sequence** (1-32): Which of the parent's 32 sequences to read
- **Start** (1-16): Playback start point
- **End** (1-16): Playback end point
- **Direction** (0-6): Playback direction (same options as Step Sequencer)
- **Permutation** (0-3): Step order variation
- **Gate type** (0-1): Gate or trigger mode
- **Gate length** (1-99%): Gate duration
- **Trigger length** (1-100ms): Trigger duration
- **Glide** (0-1000ms): Portamento time
- **Octave** (-10 to +10): Transpose by octaves
- **Transpose** (-60 to +60 semitones): Chromatic transposition

#### Use Cases

**Polyrhythmic Sequencing:**
- Parent: 16-step sequence, forward
- Head 1: Same sequence, reverse (counterpoint)
- Head 2: Steps 1-8 only, double speed

**Polytemporal Layering:**
- Parent: Quarter note steps
- Head 1: Same sequence, different clock division
- Head 2: Octave up, different start/end points

**Harmonic Exploration:**
- Parent: Bass line
- Head 1: +12 semitones (octave harmony)
- Head 2: +7 semitones (fifth harmony)
- Head 3: +4 semitones (major third harmony)

#### Input/Output Ports

**Inputs:**
- Clock input (separate from parent)
- Reset input
- Reset mode
- Sequence CV/trigger inputs (for sequence selection)

**Outputs:**
- Pitch output (with transposition applied)
- Gate output
- Velocity output
- Mod output
- Step output (current step number CV)

**Output Modes:**
Each output has a mode parameter controlling routing (CV bus assignment).

#### Architecture

**Relationship:** Step Sequencer Head references "nearest Step Sequencer above it" in the algorithm list.

**Multiple Heads:** You can have unlimited Step Sequencer Heads per Step Sequencer, each with independent playback parameters.

**Data Flow:**
```
Step Sequencer (spsq)
  └─ 32 sequences × 16 steps × (pitch, velocity, mod, division, pattern, ties)
      ├─ Step Sequencer Head 1 (spsh) → reads sequence, plays independently
      ├─ Step Sequencer Head 2 (spsh) → reads same sequence, different playback
      └─ Step Sequencer Head N (spsh) → ...
```

---

## 3. Data Model

### Parameter Organization

#### Global Parameters (1 instance per algorithm)

| Parameter | Range | Default | Purpose |
|-----------|-------|---------|---------|
| Sequence | 1-32 | 1 | Select active sequence/snapshot |
| Start | 1-16 | 1 | First step of active section |
| End | 1-16 | 16 | Last step of active section |
| Direction | 0-6 | 0 (Forward) | Playback direction |
| Permutation | 0-3 | 0 (None) | Step order variation |
| Gate type | 0-1 | 0 | Gate or trigger mode |
| Gate length | 1-99% | 50% | Gate duration |
| Trigger length | 1-100ms | 10ms | Trigger pulse duration |
| Glide | 0-1000ms | 100ms | Portamento time |

#### Per-Step Parameters (16 instances, one per step)

| Parameter | Range | Default | Purpose |
|-----------|-------|---------|---------|
| Pitch | 0-127 | 48 (C3) | MIDI note number |
| Velocity | 1-127 | 64 | Note dynamics |
| Mod | -10.0 to +10.0V | 0.0V | Modulation CV output |
| Division | 0-14 | 7 (Normal) | Repeat/ratchet timing |
| Pattern | 0-255 | 0 | Substep on/off bitmap (8-bit) |
| Ties | 0-255 | 0 | Substep tie bitmap (8-bit) |
| Mute | 0-100% | 0% | Probability of muting step |
| Skip | 0-100% | 0% | Probability of skipping step |
| Reset | 0-100% | 0% | Probability of sequence reset |
| Repeat | 0-100% | 0% | Probability of step repeat |

**Total per-step parameters:** 10 parameters × 16 steps = 160 parameter instances

#### Sequence Storage

**32 Sequences:**
Each sequence contains complete state:
- 16 steps × 10 per-step parameters = 160 values
- Total storage: 32 sequences × 160 values = 5,120 parameter values

**Switching Sequences:**
- Manual: Via Sequence parameter (1-32)
- CV Control: Via CV input mapped to Sequence parameter
- Trigger: Via trigger input for sequence advance

### CV Output Behavior

#### Pitch Output (V/oct standard)

**MIDI to CV Conversion:**
- MIDI note 0 = 0.00V
- MIDI note 60 (C4) = 5.00V
- MIDI note 127 = 10.58V
- Formula: `CV = MIDI_note / 12` volts

**Glide Behavior:**
- Glide parameter (0-1000ms) sets portamento time
- When tie is active: pitch CV glides smoothly
- When tie is inactive: pitch CV jumps instantly (even if glide > 0)

#### Gate Output

**Gate Type:**
- **Gate mode:** Output high for gate length %, low for remainder
- **Trigger mode:** Output brief pulse (trigger length ms), then low

**Gate Length:**
- Percentage of step duration (1-99%)
- Example: 50% = gate high for first half of step

**Ties Override:**
- When substep has tie active: gate remains high across note boundary
- Creates legato articulation (no gap between notes)

#### Velocity Output

**CV Mapping:**
- Velocity 1 = minimum CV (typically 0V or small positive)
- Velocity 127 = maximum CV (typically 10V)
- Linear scaling

**MIDI Output:**
- Velocity sent directly as MIDI velocity value (1-127)

#### Modulation Output

**Range:** -10.0V to +10.0V
**Resolution:** Continuous (not quantized)
**Purpose:** General-purpose CV for controlling any parameter
**Use Cases:**
- Filter cutoff modulation
- LFO rate control
- Amplitude envelope modulation
- Assignable to any CV-controllable parameter

### MIDI Output Behavior

**Note On/Off:**
- Pitch → MIDI note number (0-127)
- Velocity → MIDI velocity (1-127)
- Ties → Legato (note-off immediately before next note-on)

**Timing:**
- Clock input drives step advance
- Gate/trigger parameters control note-on timing
- Division/ratchet creates sub-clock note bursts

**Channel:**
- MIDI channel configured globally for algorithm
- All notes output on same channel

---

## 4. UI Design Implications

### Visual Hierarchy (Informed by First Principles Analysis)

#### Primary View - Step Grid (80% of screen space)

**Visual Elements:**
1. **Step Grid:** 16 columns (one per step)
2. **Pitch Row:** Visual CV level (vertical bar or waveform segment)
3. **Velocity Row:** Visual intensity (color/opacity/height)
4. **Mod Row:** Visual CV value (bipolar: ±10V)
5. **Active Section Indicator:** Highlight Start→End range
6. **Step Numbers:** 1-16 labels

**Interaction:**
- Tap/click step to select
- Drag vertically to edit pitch
- Pinch/scroll to zoom (optional for 64-step future support)

**Advantages:**
- User sees entire sequence at a glance
- Pattern recognition (melodic shape, rhythmic structure)
- Direct manipulation (no parameter menu diving)

#### Secondary Panel - Playback Controls (15% of screen space)

**Controls:**
- Sequence selector (1-32) with name display
- Start/End step selectors
- Direction selector (dropdown or segmented control)
- Gate type/length sliders

**Advantages:**
- One-tap access to playback config
- Logical grouping (all controls affect "how" sequence plays)

#### Tertiary Panel - Advanced Features (5% or collapsible)

**Controls:**
- Division per-step (expandable row)
- Pattern/Ties editors (modal or separate view)
- Probability sliders (Mute/Skip/Reset/Repeat)
- Glide time slider
- Permutation selector

**Advantages:**
- Progressive disclosure (simple by default, powerful when needed)
- Prevents UI clutter for beginners
- Expert users can expand for full control

### Per-Step Editing Modal

**Trigger:** Tap step in grid → modal appears

**Contents:**
- Pitch (0-127): Slider + numeric entry + piano key visualization
- Velocity (1-127): Slider + numeric entry
- Mod (-10.0 to +10.0V): Slider + numeric entry
- Division (0-14): Segmented control (Repeat←Normal→Ratchet)
- Pattern (0-255): Visual 8-bit editor (substep checkboxes)
- Ties (0-255): Visual 8-bit editor (substep toggles)
- Probability: 4 sliders (Mute %, Skip %, Reset %, Repeat %)

**Actions:**
- Copy step
- Paste step
- Clear step
- Randomize step

### Gesture Design

**Mobile (Touch):**
- Tap: Select step
- Long-press: Open per-step modal
- Swipe horizontal: Navigate steps
- Swipe vertical (on pitch bar): Adjust pitch
- Two-finger drag: Adjust multiple steps simultaneously

**Desktop (Mouse/Trackpad):**
- Click: Select step
- Double-click: Open per-step modal
- Drag: Adjust value
- Shift+click: Multi-select steps
- Cmd+C/V: Copy/paste steps

### Real-time Sync Considerations

**Limitation:** Hardware doesn't provide playback position feedback via SysEx.

**Workaround Strategies:**
1. **No real-time indicator:** Accept limitation, focus on editing experience
2. **Simulated playback:** App calculates expected step position based on clock (requires clock input knowledge)
3. **Visual feedback on write:** Highlight recently changed parameters

**Recommended:** Strategy 1 for MVP, Strategy 2 for Phase 2 (requires additional research on clock input parameter reading)

---

## 5. Implementation Considerations

### Architecture Patterns

**State Management (Existing):**
- Use `DistingCubit` for step sequencer state
- Extend cubit with step sequencer-specific methods:
  - `loadSequence(int sequenceNumber)`
  - `updateStep(int stepIndex, StepData data)`
  - `updateGlobalParam(String paramName, value)`

**Data Model:**
```dart
class StepSequencerState {
  final int activeSequence; // 1-32
  final List<StepData> steps; // 16 elements
  final GlobalParams globals;
  final bool isEditing;
  final int? selectedStepIndex;
}

class StepData {
  final int pitch; // 0-127
  final int velocity; // 1-127
  final double mod; // -10.0 to +10.0
  final int division; // 0-14
  final int pattern; // 0-255 (bitmap)
  final int ties; // 0-255 (bitmap)
  final int muteProbability; // 0-100
  final int skipProbability; // 0-100
  final int resetProbability; // 0-100
  final int repeatProbability; // 0-100
}

class GlobalParams {
  final int start; // 1-16
  final int end; // 1-16
  final Direction direction; // enum
  final int permutation; // 0-3
  final GateType gateType; // enum
  final int gateLength; // 1-99
  final int triggerLength; // 1-100
  final int glide; // 0-1000
}
```

**MIDI Communication:**
- Reuse existing SysEx infrastructure
- Batch parameter updates when possible (reduce MIDI traffic)
- Debounce rapid UI changes (e.g., slider drag)

**Offline Mode:**
- Cache all 32 sequences locally
- Enable full editing without hardware
- Sync changes when hardware reconnects

### UI Component Structure

```
StepSequencerScreen
├── SequenceSelectorHeader
│   ├── SequenceDropdown (1-32)
│   └── SequenceNameDisplay
├── StepGridView
│   ├── StepColumn (×16)
│   │   ├── PitchBar
│   │   ├── VelocityBar
│   │   └── ModBar
│   └── ActiveSectionIndicator
├── PlaybackControlPanel
│   ├── StartEndSelectors
│   ├── DirectionSelector
│   └── GateControls
└── AdvancedPanel (collapsible)
    ├── DivisionRow
    ├── ProbabilitySliders
    └── PermutationSelector

StepEditModal (shown on step tap)
├── PitchEditor
├── VelocityEditor
├── ModEditor
├── DivisionEditor
├── PatternBitmapEditor
├── TiesBitmapEditor
├── ProbabilityEditors (×4)
└── Actions (Copy/Paste/Clear/Randomize)
```

### Performance Optimization

**Rendering:**
- Use Flutter `CustomPainter` for step grid (efficient canvas drawing)
- Memoize step column widgets (avoid unnecessary rebuilds)
- Limit animation frame rate (60fps sufficient)

**MIDI Communication:**
- Batch parameter writes (send multiple in one SysEx message if protocol allows)
- Queue writes during rapid editing (debounce slider changes)
- Prioritize visible parameters (load on-screen steps first)

**Memory:**
- Load active sequence only (not all 32 simultaneously)
- Lazy-load sequences on demand
- Cache recently accessed sequences

### Testing Strategy

**Unit Tests:**
- StepData model validation (range checks)
- State management logic (cubit methods)
- MIDI message generation
- CV value calculations (pitch, velocity, mod)

**Integration Tests:**
- Full sequence CRUD operations
- Parameter read/write via mock MIDI
- Offline mode synchronization

**UI Tests:**
- Step selection and editing
- Multi-step operations (copy/paste)
- Gesture recognition (tap, drag, swipe)

**Manual Testing:**
- Real hardware validation (MIDI SysEx communication)
- Cross-platform testing (iOS, Android, macOS, Linux, Windows)
- Accessibility (screen reader, keyboard navigation)

---

## 6. Phase 2 Opportunities

### Step Sequencer Head Integration

**UI Concept:**
- Add "Heads" tab to step sequencer screen
- Display list of active Step Sequencer Head instances
- Mini-control panel per head:
  - Sequence selector
  - Start/End
  - Direction
  - Octave/Transpose sliders

**Use Case:**
User loads Step Sequencer with bass line sequence, then adds 2 Step Sequencer Heads for harmony (one +7 semitones, one +12 semitones), creating instant three-part harmony from single sequence.

**Implementation:**
- Detect Step Sequencer Head algorithms in preset
- Link heads to parent sequencer
- Display connections visually (parent → heads diagram)

### Advanced Features

**Visual Waveform Preview:**
- Render expected CV output as waveform
- Show pitch, velocity, mod as layered curves
- Helps visualize ties, glide, and ratchets

**Sequence Library:**
- Save/load user sequences
- Share sequences between projects
- Import common patterns (chromatic scale, arpeggio templates)

**Real-time Playback (if possible):**
- Research: Can app detect clock input parameter or infer playback state?
- If yes: Add animated playback position indicator
- If no: Remain with static editing experience

**Gesture Enhancements:**
- Swipe across multiple steps to "draw" pitch curves
- Pinch-to-zoom for fine control
- Three-finger swipe to shift entire sequence left/right

---

## 7. Risk Analysis

### Technical Risks

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| MIDI latency on parameter updates | Medium | Medium | Batch writes, debounce UI, queue operations |
| UI performance on older devices | Low | Medium | Optimize rendering, limit animations, test on low-end hardware |
| Complex state management (32 sequences × 160 params) | Medium | High | Use efficient data structures, lazy loading, memoization |
| Per-step parameter explosion (10 params × 16 steps) | Low | Medium | Progressive disclosure, modal editors, batch operations |
| Real-time sync impossible (no playback position feedback) | High | Low | Accept limitation for MVP, focus on editing UX |

### UX Risks

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| UI too complex for beginners | Medium | High | Progressive disclosure, simple mode, in-app tutorials |
| Touch targets too small on mobile | Low | Medium | Follow platform guidelines (44pt minimum), test on smallest devices |
| Desktop users expect keyboard shortcuts | Medium | Medium | Implement standard shortcuts (Cmd+C/V, arrow keys, etc.) |
| Users miss advanced features (hidden in tertiary panel) | Low | Low | Onboarding flow, "Tip of the Day" hints |

### Project Risks

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Scope creep (too many features for MVP) | High | High | Strict MVP definition, Phase 2 backlog, user story prioritization |
| Firmware changes break assumptions | Low | Medium | Monitor Expert Sleepers firmware updates, design for flexibility |
| Step Sequencer Head integration complexity | Medium | Low | Make it optional Phase 2 feature, validate separately |

---

## 8. Recommendations

### MVP Scope (Phase 1)

**Include:**
1. Visual 16-step grid (pitch, velocity, mod)
2. Per-step editing modal (all 10 parameters)
3. Global playback controls (sequence, start/end, direction, gate, glide)
4. Sequence selector (1-32)
5. Offline mode support
6. Copy/paste/clear/randomize step operations

**Exclude (Phase 2):**
1. Step Sequencer Head integration
2. Real-time playback position indicator
3. Visual waveform preview
4. Sequence library/templates
5. Advanced gesture controls

### Implementation Roadmap

**Week 1-2: Foundation**
- Data model (StepData, GlobalParams)
- State management (extend DistingCubit)
- MIDI communication layer (read/write step parameters)

**Week 3-4: Core UI**
- StepGridView component
- PitchBar, VelocityBar, ModBar widgets
- Step selection and visual feedback

**Week 5-6: Editing**
- StepEditModal
- Parameter editors (sliders, numeric inputs)
- Pattern/Ties bitmap editors

**Week 7-8: Playback Controls**
- Sequence selector
- Start/End controls
- Direction/Gate/Glide controls

**Week 9-10: Polish & Testing**
- Cross-platform testing
- Performance optimization
- Bug fixes and refinements

**Week 11-12: Release**
- User documentation
- Release notes
- App store submissions (if applicable)

### Success Metrics

**Quantitative:**
- Time to create 16-step sequence: < 2 minutes
- Parameter edit latency: < 100ms (UI to MIDI write)
- UI frame rate: > 60fps during editing
- Test coverage: > 80%

**Qualitative:**
- User feedback: "Easier than hardware interface"
- User feedback: "Seeing all steps visually helps me compose"
- Internal validation: Team can create complex sequences without manual

---

## 9. Next Steps

### Immediate Actions

1. **Review this research document** with team/stakeholders
2. **Create Epic** for Step Sequencer UI feature
3. **Break down Epic into User Stories** (use BMAD workflow)
4. **Design mockups** (wireframes, visual design)
5. **Validate assumptions** with test users (if available)

### Open Questions for Clarification

**Parameter Mapping:**
- Q: Are Division values 0-6 definitely repeats, 7=normal, 8-14=ratchets?
- A: Requires firmware manual confirmation or hardware testing

**Permutation:**
- Q: What are the exact algorithms for Permutation 1-3?
- A: Requires firmware manual or hardware experimentation

**Real-time Sync:**
- Q: Is there any way to infer playback position (clock input monitoring, hidden parameters)?
- A: Requires firmware manual deep-dive or Expert Sleepers inquiry

**Randomization:**
- Q: How is the randomization function triggered (button, parameter, CV)?
- A: Requires firmware manual or hardware testing

**MIDI Recording:**
- Q: Firmware v1.5.0 added "MIDI note entry" - how does this work? Can we record from MIDI keyboard into sequence?
- A: Requires firmware manual or hardware testing

### Research Artifacts

**Completed:**
- ✅ Step Sequencer parameter documentation
- ✅ Step Sequencer Head parameter documentation
- ✅ Data model structure
- ✅ UI design principles (First Principles & Six Thinking Hats informed)
- ✅ Implementation architecture
- ✅ Risk analysis

**Pending (Optional for Epic Planning):**
- ⏳ Official firmware manual deep-dive (PDF too large to fetch)
- ⏳ Hardware testing for undefined parameters
- ⏳ Real-time playback position investigation
- ⏳ MIDI recording feature exploration

---

## 10. References and Sources

### Official Documentation

- [Expert Sleepers Disting NT Product Page](https://www.expert-sleepers.co.uk/distingNT.html)
- [Expert Sleepers Disting NT Firmware Updates](https://www.expert-sleepers.co.uk/distingNTfirmwareupdates.html)
- Disting NT User Manual v1.11.0 (PDF - too large to fetch, available at firmware page)

### Firmware Version History

- [MATRIXSYNTH: disting NT v1.5.0 Release](https://www.matrixsynth.com/2025/01/expert-sleepers-disting-nt-v150.html)
- Firmware v1.2.0: Step Sequencer introduced
- Firmware v1.5.0: MIDI note entry, snapshot functionality
- Firmware v1.6.0: One-shot reset mode, probability Skip/Reset
- Firmware v1.11.0: Current version (October 20, 2025)

### Step Sequencing Concepts

- [Patching a Ratcheting Sequence - Learning Modular](https://learningmodular.com/patching-a-ratcheting-sequence/)
- [How to Ratchet Notes in a Step Sequencer - Sweetwater](https://www.sweetwater.com/insync/how-to-ratchet-notes-in-a-step-sequencer/)
- [Step Sequencing - Sound on Sound](https://www.soundonsound.com/techniques/step-sequencing)

### Project Internal Sources

- nt_helper metadata: `docs/algorithms/spsq.json`
- nt_helper metadata: `docs/algorithms/spsh.json`
- nt_helper project: `CLAUDE.md`, `CLAUDE/index.md`

### Community Resources

- [Disting NT Feature Request - MOD WIGGLER](https://www.modwiggler.com/forum/viewtopic.php?t=287977)
- [Disting NT Discussions - MOD WIGGLER](https://modwiggler.com/forum/viewtopic.php?t=287912)

---

## Document Information

**Workflow:** BMad Research Workflow - Technical Research (adapted for algorithm investigation)
**Generated:** 2025-11-23
**Research Type:** Technical / Algorithm Deep-Dive
**Agent:** Mary (Business Analyst)
**Elicitation Methods Applied:** First Principles, Six Thinking Hats
**Next Phase:** Epic Planning (create-epics-and-stories workflow)
**Total Sources Cited:** 12

---

_This technical research report was generated using the BMad Method Research Workflow. The investigation combined existing project metadata, official firmware documentation, community resources, and analytical frameworks (First Principles, Six Thinking Hats) to provide a complete foundation for UI design and epic planning._
