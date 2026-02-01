# nt_helper — Disting NT MIDI Helper

## What This Is

A Flutter app for the Expert Sleepers Disting NT Eurorack module, providing preset management, algorithm loading, and parameter control via MIDI SysEx. Includes intelligent MIDI detection that auto-classifies incoming CC as standard 7-bit, 14-bit (with byte order), or notes. Supports Linux, macOS, iOS, Android, and Windows with demo, offline, and connected MIDI modes.

## Core Value

Reliable, real-time parameter control of the Disting NT via MIDI — the bridge between the user's DAW/controller and the module's deep parameter set.

## Requirements

### Validated

<!-- Shipped and confirmed valuable. -->

- MIDI device connection and SysEx communication
- Preset management (save/load/browse)
- Algorithm loading and library browsing
- Parameter control with live refresh
- CV/MIDI/i2c/performance mapping editor
- 7-bit CC detection via MIDI Detector
- Note detection (momentary and toggle)
- Routing visualization and editing
- SD card preset scanning
- Demo and offline modes
- Lua script reload with state preservation
- Hardware commands (screenshot, reboot, remount)
- CPU monitoring and USB video
- Auto-detect 14-bit MIDI CC pairs in the MIDI Detector — v2.10
- Determine byte order (low-first vs high-first) via value analysis — v2.10
- Emit typed detection events (standard CC, 14-bit CC with byte order, notes) — v2.10
- Auto-configure mapping editor from 14-bit detection results — v2.10
- Enable 14-bit range slider when 14-bit detection occurs — v2.10
- Highlight the active parameter row when the mapping editor bottom sheet is open — v2.11

### Active

<!-- Current scope. Building toward these. -->

(No active requirements — next milestone not yet planned)

### Out of Scope

- Overhauling existing 7-bit CC detection — enhance, don't replace
- Custom MIDI message sending/output — detection only
- MIDI clock or transport detection

## Context

- `MidiListenerCubit` delegates detection to `MidiDetectionEngine` (added v2.10)
- `MidiDetectionEngine` handles parallel 7-bit and 14-bit CC detection with 10-hit threshold
- `MidiEventType` enum has 5 variants: cc, noteOn, noteOff, cc14BitLowFirst, cc14BitHighFirst
- Byte order determined via variance ratio analysis (threshold 0.8, ambiguous defaults to low-first)
- `MidiMappingType` enum defines `cc14BitLow` and `cc14BitHigh` variants
- 14-bit MIDI standard: CC 0-31 (MSB) paired with CC 32-63 (LSB)
- Detection result feeds into `PackedMappingDataEditor` via `onMidiEventFound` callback
- Status messages use concise "14-bit CC X Ch Y" format (5 words)
- 45 MIDI detection tests across 3 test files
- `MappingEditButton` is a StatefulWidget with local `_isEditing` state driving conditional orange border (added v2.11)
- 3 highlight lifecycle widget tests in `mapping_edit_button_highlight_test.dart` (added v2.11)

## Constraints

- **Architecture**: Must follow existing Cubit + delegate pattern
- **Compatibility**: Detection logic delegated to engine, cubit is thin integration layer
- **Testing**: Must maintain zero `flutter analyze` warnings
- **Non-breaking**: Existing 7-bit CC and note detection must continue to work unchanged

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Auto-detect rather than user-selects mode | Smarter detector reduces user friction; detector classifies, panel reacts | Good |
| Value analysis for byte order | More reliable than arrival order; standard MIDI has MSB in lower CC but controllers vary | Good |
| Same 10-hit threshold for 14-bit | Consistency with existing behavior; 14-bit pairs already strong signal but threshold prevents false positives | Good |
| Track CC numbers, no timing window | Simplifies implementation; CC pairs 32 apart are unambiguous regardless of timing | Good |
| Enum variant naming: cc14BitLowFirst/cc14BitHighFirst | Explicit byte order semantics at type level, avoids MSB/LSB ambiguity | Good |
| Variance ratio threshold 0.8 | Clear signal for byte order while handling noisy/stepped controllers | Good |
| Ambiguous variance defaults to cc14BitLowFirst | MIDI spec standard is lower CC = MSB, safer default | Good |
| Cubit delegates to MidiDetectionEngine | Separation of concerns, 56% code reduction, pure testable engine | Good |
| Concise status format "14-bit CC X Ch Y" | Reduces 8 words to 5 for better UI density in status bar | Good |
| Local _isEditing state for highlight | setState before/after await pattern; simpler than cubit/provider for widget-local visual state | Good |
| Renamed 'widget' param to 'parameterViewRow' | Avoids shadowing StatefulWidget's built-in 'widget' property | Good |
| Orange (tertiary) border for editing highlight | Distinct from primaryContainer (mapped state); theme-driven color | Good |

---
*Last updated: 2026-02-01 after v2.11 Mapping Row Highlight milestone*
