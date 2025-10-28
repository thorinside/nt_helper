# nt_helper - Epic Breakdown

**Author:** Neal
**Date:** 2025-10-27
**Project Level:** 2
**Target Scale:** TBD

---

## Overview

This document provides the detailed epic breakdown for nt_helper, expanding on the high-level epic list in the [PRD](./PRD.md).

Each epic includes:

- Expanded goal and value proposition
- Complete story breakdown with user stories
- Acceptance criteria for each story
- Story sequencing and dependencies

**Epic Sequencing Principles:**

- Epic 1 establishes foundational infrastructure and initial functionality
- Subsequent epics build progressively, each delivering significant end-to-end value
- Stories within epics are vertically sliced and sequentially ordered
- No forward dependencies - each story builds only on previous work

---

## Epic 2: 14-bit MIDI CC Support

**Expanded Goal:**

Extend the MIDI mapping system to support 14-bit MIDI CC messages, providing higher-resolution parameter control. This matches the functionality added to the Expert Sleepers reference implementation, where users can designate MIDI mappings as "14 bit CC - low" or "14 bit CC - high" pairs instead of standard 7-bit CC messages.

**Value Proposition:**

14-bit MIDI CC uses two CC numbers (a primary MSB controller and a secondary LSB controller offset by 32) to achieve 16,384 discrete values instead of 128, eliminating zipper noise and enabling smooth, precise parameter sweeps for critical synthesis parameters like pitch, filter cutoff, and oscillator tuning.

**Story Breakdown:**

**Story E2.1: Extend MidiMappingType enum and data model**

As a developer maintaining the mapping data model,
I want the `MidiMappingType` enum to include `cc14BitLow` and `cc14BitHigh` values,
So that packed mapping data can represent both 7-bit and 14-bit MIDI CC mappings.

**Acceptance Criteria:**
1. `MidiMappingType` enum adds two new values: `cc14BitLow` (value=3), `cc14BitHigh` (value=4)
2. `PackedMappingData.fromBytes()` decodes `midiFlags2` using bit-shift (`flags2 >> 2`) instead of conditional logic
3. `PackedMappingData.encodeMIDIPackedData()` encodes type as `(type << 2)` in `midiFlags2`
4. Existing tests pass and new tests verify 14-bit type encoding/decoding
5. `flutter analyze` passes with zero warnings

**Prerequisites:** None

**Story E2.2: Update mapping editor UI for 14-bit CC selection**

As a user configuring MIDI mappings in the parameter property editor,
I want to select "14 bit CC - low" or "14 bit CC - high" from the MIDI Type dropdown,
So that I can create high-resolution MIDI mappings for precise parameter control.

**Acceptance Criteria:**
1. `packed_mapping_data_editor.dart` dropdown includes two new entries: "14 bit CC - low" and "14 bit CC - high"
2. Dropdown displays all five MIDI types: CC, Note - Momentary, Note - Toggle, 14 bit CC - low, 14 bit CC - high
3. Selecting 14-bit types correctly updates `_data.midiMappingType`
4. "MIDI Relative" switch is disabled for 14-bit CC types (same as note types)
5. UI changes are visually consistent with existing design
6. `flutter analyze` passes with zero warnings

**Prerequisites:** Story E2.1

**Story E2.3: SysEx compatibility and hardware sync**

As a user saving presets with 14-bit MIDI mappings,
I want nt_helper to correctly encode and decode 14-bit CC types when communicating with Disting NT hardware,
So that my 14-bit mappings persist correctly and sync with the reference preset editor.

**Acceptance Criteria:**
1. `set_midi_mapping.dart` correctly encodes 14-bit types in SysEx messages
2. `mapping_response.dart` correctly decodes 14-bit types from hardware responses
3. Round-trip test: Create 14-bit mapping → save to hardware → read back → verify type preserved
4. Presets created in reference HTML editor load correctly with 14-bit mappings intact
5. Presets created in nt_helper load correctly in reference HTML editor with 14-bit mappings intact
6. `flutter analyze` passes with zero warnings

**Prerequisites:** Stories E2.1 and E2.2

---

## Story Guidelines Reference

**Story Format:**

```
**Story [EPIC.N]: [Story Title]**

As a [user type],
I want [goal/desire],
So that [benefit/value].

**Acceptance Criteria:**
1. [Specific testable criterion]
2. [Another specific criterion]
3. [etc.]

**Prerequisites:** [Dependencies on previous stories, if any]
```

**Story Requirements:**

- **Vertical slices** - Complete, testable functionality delivery
- **Sequential ordering** - Logical progression within epic
- **No forward dependencies** - Only depend on previous work
- **AI-agent sized** - Completable in 2-4 hour focused session
- **Value-focused** - Integrate technical enablers into value-delivering stories

---

**For implementation:** Use the `create-story` workflow to generate individual story implementation plans from this epic breakdown.
