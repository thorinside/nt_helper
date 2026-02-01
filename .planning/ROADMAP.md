# Roadmap: nt_helper v2.10 — 14-bit MIDI Detection

## Overview

Add intelligent 14-bit MIDI CC auto-detection to the MIDI Detector. The detector will run parallel 7-bit and 14-bit detection paths, identify CC pairs (X and X+32), analyze values to determine byte order, and emit typed events that drive the mapping editor to auto-configure for 14-bit control. This enhances the existing 7-bit threshold pattern with pair tracking and value analysis, requiring no new dependencies.

## Phases

**Phase Numbering:**
- Integer phases (1, 2, 3): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED)

Decimal phases appear between their surrounding integers in numeric order.

- [ ] **Phase 1: Type System Foundation** - Extend MidiEventType for 14-bit variants
- [ ] **Phase 2: 14-Bit Detection** - Implement pair detection and byte order analysis
- [ ] **Phase 3: UI Integration** - Auto-configure mapping editor from detection results

## Phase Details

### Phase 1: Type System Foundation
**Goal**: Type system supports 14-bit MIDI events without breaking existing detection
**Depends on**: Nothing (first phase)
**Requirements**: TYP-01, TYP-02, TYP-03
**Success Criteria** (what must be TRUE):
  1. MidiEventType enum includes 14-bit variants encoding byte order
  2. Existing 7-bit CC detection continues working unchanged
  3. Existing note detection continues working unchanged
  4. MidiListenerState can emit 14-bit detection results
  5. Freezed code regenerates without errors
**Plans:** 1 plan

Plans:
- [ ] 01-01-PLAN.md — Extend MidiEventType enum, update pattern matching, write tests

### Phase 2: 14-Bit Detection
**Goal**: Detector identifies 14-bit CC pairs, determines byte order, and emits typed events
**Depends on**: Phase 1
**Requirements**: DET-01, DET-02, DET-03, DET-04, DET-05, BYT-01, BYT-02
**Success Criteria** (what must be TRUE):
  1. Detector tracks all incoming CC numbers per channel simultaneously
  2. Detector identifies CC pairs where one CC is 32 higher than the other
  3. 14-bit pair detection uses 10-hit threshold (MSB+LSB pair counts as 1 hit)
  4. 7-bit and 14-bit detection run in parallel, first to threshold wins
  5. Reserved CCs (CC0/CC32 Bank Select) excluded from 14-bit pairing
  6. Byte order determined via value analysis (MSB-first vs LSB-first)
  7. Standard MSB-first interpretation used when analysis is ambiguous
  8. Detector emits correct 14-bit event type with byte order encoded
**Plans**: TBD

Plans:
- [ ] TBD during planning

### Phase 3: UI Integration
**Goal**: Mapping editor auto-configures from 14-bit detection results
**Depends on**: Phase 2
**Requirements**: UI-01, UI-02, UI-03, UI-04
**Success Criteria** (what must be TRUE):
  1. Status message shows concise 14-bit result (4-5 words, e.g., "14-bit CC 1 Ch 1")
  2. onMidiEventFound callback delivers 14-bit type info to mapping editor
  3. Mapping editor auto-selects MidiMappingType (cc14BitLow or cc14BitHigh) based on detected byte order
  4. Mapping editor auto-fills CC number from 14-bit detection base CC
  5. 14-bit range slider enabled automatically when 14-bit detection occurs
**Plans**: TBD

Plans:
- [ ] TBD during planning

## Progress

**Execution Order:**
Phases execute in numeric order: 1 → 2 → 3

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Type System Foundation | 0/1 | Not started | - |
| 2. 14-Bit Detection | 0/TBD | Not started | - |
| 3. UI Integration | 0/TBD | Not started | - |
