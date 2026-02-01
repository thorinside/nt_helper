# Requirements: nt_helper v2.10 — 14-bit MIDI Detection

**Defined:** 2026-01-31
**Core Value:** Reliable, real-time parameter control of the Disting NT via MIDI

## v1 Requirements

Requirements for milestone v2.10. Each maps to roadmap phases.

### Detection Core

- [ ] **DET-01**: Detector tracks all incoming CC numbers per channel simultaneously
- [ ] **DET-02**: Detector identifies CC pairs where one CC is 32 higher than the other as 14-bit pairs
- [ ] **DET-03**: 14-bit pair detection uses same 10-hit threshold as 7-bit (MSB+LSB pair = 1 hit)
- [ ] **DET-04**: 7-bit and 14-bit detection run in parallel; first to reach threshold emits
- [ ] **DET-05**: Reserved CCs excluded from 14-bit pairing (CC0/CC32 Bank Select)

### Byte Order

- [ ] **BYT-01**: Detector analyzes values to determine byte order (MSB-first vs LSB-first)
- [ ] **BYT-02**: Default to standard MSB-first interpretation when analysis is ambiguous

### Type System

- [ ] **TYP-01**: MidiEventType enum extended with 14-bit variants encoding byte order
- [ ] **TYP-02**: Existing 7-bit CC and note detection unchanged by new type additions
- [ ] **TYP-03**: MidiListenerState supports emitting 14-bit detection results

### UI Integration

- [ ] **UI-01**: Status message shows concise 14-bit result (e.g., "14-bit CC 1 Ch 1")
- [ ] **UI-02**: onMidiEventFound callback carries 14-bit type info to mapping editor
- [ ] **UI-03**: Mapping editor auto-sets MidiMappingType (cc14BitLow/cc14BitHigh) from detection
- [ ] **UI-04**: Mapping editor auto-fills CC number from 14-bit detection base CC

## v2 Requirements

Deferred to future milestone. Tracked but not in current roadmap.

### Enhanced Detection

- **ENH-01**: Visual 14-bit value preview (0-16383) during detection
- **ENH-02**: Partial pair warning when only MSB or LSB detected
- **ENH-03**: Detection confidence indicator for byte order determination
- **ENH-04**: Resolution verification to detect hardware quantization

### Extended Protocol

- **EXT-01**: NRPN detection support

## Out of Scope

| Feature | Reason |
|---------|--------|
| Timing window for pair association | User confirmed: track CC numbers, no timing needed. Threshold handles false positives. |
| Automatic mapping type selection without detection | Detection drives the type; user doesn't pre-select mode |
| Non-standard CC pairs (outside 0-31/32-63) | MIDI spec is explicit; non-standard pairs are independent 7-bit CCs |
| Timeout/fallback for MSB-only devices | If only one CC appears, 7-bit detection wins the race naturally |
| MIDI clock or transport detection | Not related to parameter mapping |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| DET-01 | Phase 2 | Pending |
| DET-02 | Phase 2 | Pending |
| DET-03 | Phase 2 | Pending |
| DET-04 | Phase 2 | Pending |
| DET-05 | Phase 2 | Pending |
| BYT-01 | Phase 2 | Pending |
| BYT-02 | Phase 2 | Pending |
| TYP-01 | Phase 1 | Pending |
| TYP-02 | Phase 1 | Pending |
| TYP-03 | Phase 1 | Pending |
| UI-01 | Phase 3 | Pending |
| UI-02 | Phase 3 | Pending |
| UI-03 | Phase 3 | Pending |
| UI-04 | Phase 3 | Pending |

**Coverage:**
- v1 requirements: 14 total
- Mapped to phases: 14
- Unmapped: 0 (100% coverage)

---
*Requirements defined: 2026-01-31*
*Last updated: 2026-01-31 after roadmap creation*
