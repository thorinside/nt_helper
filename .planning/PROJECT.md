# nt_helper — Disting NT MIDI Helper

## What This Is

A Flutter app for the Expert Sleepers Disting NT Eurorack module, providing preset management, algorithm loading, and parameter control via MIDI SysEx. Supports Linux, macOS, iOS, Android, and Windows with demo, offline, and connected MIDI modes.

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

### Active

<!-- Current scope. Building toward these. -->

- [ ] Auto-detect 14-bit MIDI CC pairs in the MIDI Detector
- [ ] Determine byte order (low-first vs high-first) via value analysis
- [ ] Emit typed detection events (standard CC, 14-bit CC with byte order, notes)
- [ ] Auto-configure mapping editor from 14-bit detection results
- [ ] Enable 14-bit range slider when 14-bit detection occurs

### Out of Scope

- Overhauling existing 7-bit CC detection — enhance, don't replace
- Custom MIDI message sending/output — detection only
- MIDI clock or transport detection

## Current Milestone: v2.10 14-Bit MIDI Detection

**Goal:** Make the MIDI Detector smart enough to auto-classify incoming MIDI as standard CC, 14-bit CC (with byte order), or notes — and have the mapping editor react accordingly.

**Target features:**
- MIDI Detector auto-detects 14-bit CC pairs (CC X + CC X+32)
- Value analysis determines low-byte-first vs high-byte-first
- Detection events carry full type info (MidiEventType expanded)
- Mapping panel auto-sets MidiMappingType from detection results
- 14-bit range slider enabled automatically on detection

## Context

- Existing `MidiListenerCubit` handles 7-bit CC detection with a 10-hit threshold
- `MidiMappingType` enum already defines `cc14BitLow` and `cc14BitHigh` variants
- 14-bit MIDI standard: CC 0-31 (MSB) paired with CC 32-63 (LSB)
- Detection result feeds into `PackedMappingDataEditor` via `onMidiEventFound` callback
- `MidiEventType` currently has: `cc`, `noteOn`, `noteOff` — needs expansion for 14-bit variants

## Constraints

- **Architecture**: Must follow existing Cubit + delegate pattern
- **Compatibility**: Detection logic in `MidiListenerCubit`, not scattered across UI
- **Testing**: Must maintain zero `flutter analyze` warnings
- **Non-breaking**: Existing 7-bit CC and note detection must continue to work unchanged

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Auto-detect rather than user-selects mode | Smarter detector reduces user friction; detector classifies, panel reacts | — Pending |
| Value analysis for byte order | More reliable than arrival order; standard MIDI has MSB in lower CC but controllers vary | — Pending |
| Same 10-hit threshold for 14-bit | Consistency with existing behavior; 14-bit pairs already strong signal but threshold prevents false positives | — Pending |
| Track CC numbers, no timing window | Simplifies implementation; CC pairs 32 apart are unambiguous regardless of timing | — Pending |

---
*Last updated: 2026-01-31 after milestone v2.10 started*
