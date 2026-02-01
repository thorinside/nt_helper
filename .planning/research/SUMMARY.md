# Project Research Summary

**Project:** nt_helper - Milestone v2.10: 14-bit MIDI CC Detection
**Domain:** MIDI auto-detection for Eurorack module control in Flutter
**Researched:** 2026-01-31
**Confidence:** HIGH

## Executive Summary

The 14-bit MIDI CC auto-detection feature is a **pure logic enhancement** requiring zero new dependencies. The existing `MidiListenerCubit` already handles 7-bit CC detection with a 10-hit threshold pattern that extends naturally to track CC pairs (X and X+32). The key technical challenge is distinguishing deliberate 14-bit pairs from independent CC usage, which requires temporal correlation and value analysis to determine byte order (MSB-first vs LSB-first, to handle Yamaha's reverse-order devices).

The recommended approach is to implement parallel detection paths: 7-bit and 14-bit detection run simultaneously, with the first to reach threshold winning. This preserves existing behavior while adding pair-tracking state to the cubit. The architecture is sound—BlocConsumer pattern already exists, callback signature is extensible via new MidiEventType enum variants, and PackedMappingData already supports cc14BitLow/cc14BitHigh types. Implementation is straightforward extension of proven patterns.

The critical risk is **false positive pairing** when two unrelated CCs happen to be 32 apart (e.g., Spitfire using CC32 independently). Mitigation requires temporal correlation (MSB/LSB within 5-50ms), value coherence analysis, and handling edge cases like MSB-only devices (timeout fallback) and reserved CCs (Bank Select). Secondary risks include state machine corruption during 7-bit to 14-bit transitions and callback contract ambiguity when passing 14-bit event data. All risks are addressable through careful threshold semantics, explicit state tracking separation, and comprehensive edge case testing.

## Key Findings

### Recommended Stack

**Zero new dependencies required.** The feature is implemented entirely within existing infrastructure: flutter_midi_command provides raw MIDI bytes via MidiPacket.data, flutter_bloc/Cubit handles state management, and freezed generates immutable state classes. All pairing logic, threshold tracking, and byte order analysis are pure Dart algorithms using built-in Map/Set data structures.

**Core technologies:**
- **flutter_midi_command ^0.5.3**: MIDI packet reception — already provides raw bytes, no upgrade needed
- **flutter_bloc ^9.1.1**: Cubit state management — existing pattern extends cleanly to 14-bit tracking
- **freezed ^3.2.3**: Immutable state generation — add enum variants and state fields, regenerate with build_runner

**Critical infrastructure already in place:**
- MidiListenerCubit with 10-hit threshold pattern (lines 14, 169-172)
- MidiMappingType enum with cc14BitLow/cc14BitHigh variants (already handles SysEx encoding)
- MidiDetectorWidget BlocConsumer bridge with onMidiEventFound callback
- PackedMappingData encoding/decoding for 14-bit types

### Expected Features

**Must have (table stakes):**
- CC pair detection (0-31 + 32-63) — MIDI spec standard, users assume this works
- 10-hit threshold for pairs — consistency with existing 7-bit UX
- Detection status messages — users need feedback ("Detected CC 1/33 14-bit pair on channel 1")
- Channel-aware detection — multiple controllers may use same CC on different channels
- Auto-populate mapping fields — once detected, populate midiCC and midiMappingType in editor

**Should have (competitive advantage):**
- Byte order auto-detection — automatically handle MSB-first (standard) vs LSB-first (Yamaha)
- Visual 14-bit value preview — show real-time 0-16383 value during detection
- Partial pair warning — alert if only MSB or LSB detected without partner

**Defer (v2+):**
- CC number recommendation based on frequency
- NRPN detection (different spec, different milestone)
- Multi-channel pair detection visualization

**Anti-features (commonly requested but problematic):**
- Auto-timeout for pair waiting — creates false negatives, better to wait for 10 coherent pairs
- Automatic mapping type selection — Disting NT byte order preference needs user context
- Detection of non-standard pairs — MIDI spec is explicit, only detect CC 0-31 + 32-63

### Architecture Approach

Extends the existing BlocConsumer architecture with parallel detection paths. The MidiListenerCubit maintains separate state for 7-bit signatures (single CC) and 14-bit signatures (CC pairs). Both detection paths run in parallel; whichever reaches threshold first emits. Byte order is determined via value analysis after threshold is met, comparing coherence of (lowCC<<7|highCC) vs (highCC<<7|lowCC) interpretations across buffered observations.

**Major components:**
1. **MidiListenerCubit** — extended with pair-tracking state (_last14BitSignature, _last14BitValues buffer, _consecutive14BitCount)
2. **MidiEventType enum** — add cc14BitLowFirst/cc14BitHighFirst variants to encode byte order in type
3. **MidiDetectorWidget** — unchanged, new event types flow through existing callback
4. **PackedMappingDataEditor** — map new event types to existing cc14BitLow/cc14BitHigh MidiMappingType

**Key patterns:**
- Threshold applies to **pairs as single events** — 10 consecutive MSB+LSB pairs, not 20 individual bytes
- Value analysis over arrival order — buffering (lowValue, highValue) across 10 hits, choose interpretation with better coherence
- Type-encoded byte order — cc14BitLowFirst means "lower CC is MSB", consumer maps directly to MidiMappingType
- Parallel detection — both 7-bit and 14-bit paths active, first to threshold wins

### Critical Pitfalls

1. **False Positive Pairing** — Real-world devices repurpose CC 32-63 independently (e.g., Spitfire CC32 for articulation switching). Prevent with temporal correlation (MSB/LSB within 5-50ms), value correlation (LSB changes proportionally to MSB), and consistent byte order across observations.

2. **Message Ordering Glitches** — During value transitions, incorrect intermediate values (e.g., incrementing from 255 to 256 triggers 383 if MSB sent first). Prevent with paired event buffering: don't emit until BOTH MSB and LSB arrive. Count MSB+LSB pairs as "one hit," not two separate hits.

3. **MSB-Only or LSB-Only Devices** — Some controllers send only MSB (e.g., Typhon synthesizer CC0-only). Detector gets stuck waiting for pairing that never comes. Prevent with timeout (50-100ms after MSB without LSB, emit as 7-bit). Track consecutive orphaned messages; if >10, conclude device is MSB-only and fall back to 7-bit mode.

4. **State Machine Corruption** — Transition from 7-bit to 14-bit detection corrupts _lastEventSignature, _consecutiveCount gets reused incorrectly, Freezed state holds mismatched types. Prevent with separate state tracking (different counters for 7-bit vs 14-bit), explicit mode enumeration, and state reset on transitions.

5. **Callback Contract Breaking** — Existing consumers expect `number` to be a 7-bit CC number (0-127), but 14-bit detection makes it ambiguous (is it MSB CC, LSB CC, or combined value?). Prevent by extending MidiEventType enum (add cc14Bit variants), documenting semantics (number = lower CC in pair), and testing all call sites.

## Implications for Roadmap

Based on research, suggested phase structure:

### Phase 1: Type System Extension (Non-Breaking)
**Rationale:** Extend type system before adding logic to verify all consumers handle new types gracefully. This is a non-breaking change that validates the callback contract.
**Delivers:** MidiEventType with cc14BitLowFirst/cc14BitHighFirst variants, regenerated Freezed code, updated PackedMappingDataEditor mapping logic
**Addresses:** Callback contract breaking (Pitfall 5), Reserved CC handling (exclude CC0/CC32 Bank Select)
**Avoids:** Breaking existing 7-bit CC and note detection
**Research flag:** Standard pattern, skip research-phase

### Phase 2: Pair Tracking State
**Rationale:** Add private state fields to cubit without changing behavior. Verify state model is sound before implementing detection logic.
**Delivers:** _last14BitSignature, _last14BitValues buffer, _consecutive14BitCount fields
**Addresses:** State machine corruption (Pitfall 6), threshold semantics clarity (Pitfall 7)
**Avoids:** State contamination between 7-bit and 14-bit modes
**Research flag:** Standard pattern, skip research-phase

### Phase 3: Pair Detection Logic
**Rationale:** Implement pair detection and threshold tracking. Define semantics: MSB+LSB pair = one hit, require 10 consecutive pairs.
**Delivers:** Pair signature tracking (channel, lowCC, highCC), temporal correlation (5-50ms window), value buffering for analysis
**Addresses:** False positive pairing (Pitfall 1), threshold semantics (Pitfall 7)
**Uses:** Existing threshold pattern from 7-bit detection
**Research flag:** Standard pattern, skip research-phase

### Phase 4: Byte Order Detection & Buffering
**Rationale:** After threshold met, analyze buffered values to determine byte order. This is the novel algorithmic component.
**Delivers:** Value analysis function (compare coherence of both interpretations), emit correct event type based on byte order
**Addresses:** Message ordering glitches (Pitfall 2), Yamaha LSB-first compatibility
**Uses:** Buffered (lowValue, highValue) pairs from Phase 3
**Research flag:** **May need research-phase** — value analysis heuristics are domain-specific, test with real hardware

### Phase 5: Timeout & Fallback Logic
**Rationale:** Handle edge cases where devices send incomplete pairs. Essential for MSB-only hardware like Typhon.
**Delivers:** Timeout mechanism (50-100ms), orphaned message tracking, fallback to 7-bit mode
**Addresses:** MSB-only/LSB-only devices (Pitfall 3)
**Avoids:** Detector hanging indefinitely when LSB never arrives
**Research flag:** Standard pattern, skip research-phase

### Phase 6: Resolution Verification & Quality Checks
**Rationale:** Detect hardware quantization (e.g., BCF2000 LSB steps of 16). Nice-to-have for UX polish.
**Delivers:** LSB value distribution analysis, effective resolution reporting in UI
**Addresses:** Hardware quantization (Pitfall 5)
**Research flag:** Standard pattern, skip research-phase (deferred to v2+ if time constrained)

### Phase Ordering Rationale

- **Type system first** because it validates the integration boundary without behavioral risk. If consumers can't handle new types, we discover this before writing detection logic.
- **State before logic** to verify state model separation (7-bit vs 14-bit tracking) before implementing complex pairing algorithm. State contamination is easier to fix if detected early.
- **Detection before buffering** because pair detection validates the temporal correlation approach. If pairing logic has false positives, byte order analysis won't fix them.
- **Byte order after detection** because it depends on buffered values from multiple pair observations. Can't analyze byte order until we have consistent pair data.
- **Timeout after core detection** because it's an edge case handler. Core detection should work on happy path (14-bit controller with consistent pairs) before handling MSB-only devices.

**Architectural boundary respected:** All phases modify cubit internals only until Phase 1 extends the public type system. Phases 2-6 are private implementation. No callback signature changes needed—new event types flow through existing (type, channel, number) structure.

### Research Flags

Phases likely needing deeper research during planning:
- **Phase 4 (Byte Order Detection):** Value analysis heuristics need validation with real hardware. Research question: "What statistical measures reliably distinguish MSB-first from LSB-first given 10 (lowValue, highValue) pairs?" Consider `/gsd:research-phase "Byte order detection heuristics for 14-bit MIDI"` with focus on real-world controller behavior and noise floor.

Phases with standard patterns (skip research-phase):
- **Phase 1:** Enum extension and Freezed regeneration—well-documented Flutter pattern
- **Phase 2:** Cubit state extension—existing codebase has 7 delegate examples
- **Phase 3:** Threshold tracking—reuses existing pattern from 7-bit detection
- **Phase 5:** Timeout/fallback—standard timeout pattern, no MIDI-specific research needed
- **Phase 6:** Distribution analysis—statistical analysis, defer if time-constrained

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | **HIGH** | Zero new dependencies, all infrastructure verified in codebase. flutter_midi_command provides raw bytes (verified line 108), Cubit pattern established (7 delegates), Freezed in active use. |
| Features | **MEDIUM** | MIDI spec pairing (CC 0-31 + 32-63) is HIGH confidence from official docs. Byte order detection heuristics are MEDIUM—forums mention value analysis but no canonical algorithm. Hardware quantization patterns are MEDIUM from community reports. |
| Architecture | **HIGH** | Parallel detection approach is sound (proven in existing 7-bit logic). Type-encoded byte order avoids signature changes. Cubit delegate pattern is well-established in codebase (14 delegates already). Integration points verified (PackedMappingDataEditor lines 683-717). |
| Pitfalls | **HIGH** | False positive pairing is well-documented in forums (Spitfire CC32 usage). Message ordering issues documented in Pure Data/VCV Rack implementations. MSB-only devices confirmed in hardware specs (Typhon). Yamaha reverse byte order mentioned in multiple sources. |

**Overall confidence:** **HIGH**

### Gaps to Address

- **Byte order detection algorithm:** Research identified value analysis as the approach, but didn't specify which statistical measure (monotonicity, variance, range analysis) is most reliable. Recommendation: Test with actual Yamaha hardware during Phase 4, or use `/gsd:research-phase` if hardware unavailable. Fallback: assume MSB-first (standard) if analysis is ambiguous, provide manual override.

- **Reserved CC behavior:** CC0/CC32 (Bank Select) and CC120-127 (Channel Mode Messages) should be excluded from auto-detection per research. Not addressed in architecture docs. Recommendation: Add exclusion list in Phase 1 when extending enum.

- **Quantization detection thresholds:** Research mentions BCF2000 LSB steps of 16, Bass Station 2 steps of 64, but doesn't specify at what threshold to warn users (e.g., if only 8 discrete LSB values appear, is it quantized?). Recommendation: Defer to Phase 6 or v2+, use 32-value threshold as heuristic.

- **Timeout value tuning:** Research suggests 5-50ms for temporal correlation, 50-100ms for orphan timeout. Wide ranges indicate uncertainty. Recommendation: Start with 50ms for both, make configurable for testing, tune based on real hardware feedback.

## Sources

### Primary (HIGH confidence)
- **Existing codebase analysis** — `lib/ui/midi_listener/midi_listener_cubit.dart` (threshold pattern lines 14, 169-172), `lib/models/packed_mapping_data.dart` (cc14BitLow/High variants lines 5-14), `lib/ui/widgets/packed_mapping_data_editor.dart` (callback lines 683-717)
- **MIDI 1.0 Specification** — CC 0-31 (MSB) pairs with CC 32-63 (LSB), value calculation `(MSB << 7) | LSB`, official spec from midi.teragonaudio.com
- **Flutter package docs** — flutter_midi_command ^0.5.3 (pub.dev), flutter_bloc ^9.1.1 (pub.dev), freezed ^3.2.3 (pub.dev)

### Secondary (MEDIUM confidence)
- **Implementation patterns** — Pure Data forum (buddy logic for pairing), VCV Rack Community (detection challenges), MaxMSP Forum (xctlin object approach)
- **Hardware behavior** — Modwiggler (BCF2000 quantization, Bass Station 2 LSB steps), VI-CONTROL (VCI-400 9-bit effective resolution), Yamaha forum (LSB-first byte order)
- **DAW/Plugin behavior** — Ableton Forum (Yamaha reverse order), ReaLearn docs (14-bit CC support), UAD Plug-Ins MIDI Learn behavior

### Tertiary (LOW confidence)
- **Byte order detection heuristics** — Mentioned in forums but no canonical algorithm, needs validation with real hardware
- **Timeout values** — 5-50ms range from implementation reports, not from spec
- **Quantization thresholds** — Inferred from hardware specs, not tested across devices

---
*Research completed: 2026-01-31*
*Ready for roadmap: yes*
