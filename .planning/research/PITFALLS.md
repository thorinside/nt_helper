# Pitfalls Research: 14-bit MIDI CC Auto-Detection

**Domain:** Adding 14-bit MIDI CC detection to existing 7-bit MIDI helper app
**Researched:** 2026-01-31
**Confidence:** HIGH (based on current codebase analysis + MIDI implementation research)

## Critical Pitfalls

### Pitfall 1: False Positive Pairing (Independent CC Usage)

**What goes wrong:**
The detector incorrectly pairs CC X (0-31) with CC X+32 (32-63) when both are used independently for different purposes. For example, detecting CC1 (Mod Wheel MSB) and CC33 (Mod Wheel LSB) as a 14-bit pair when the controller actually uses CC1 for modulation and CC33 for a completely unrelated function.

**Why it happens:**
Real-world MIDI devices repurpose CC 32-63 for independent functions when 14-bit resolution isn't needed. Spitfire uses CC32 independently to switch articulations. Korg uses CC40+ for synth parameters in Volca keyboards. The detector sees coincidental usage of both ranges and incorrectly assumes they're paired.

**How to avoid:**
1. Require temporal correlation: MSB and LSB must arrive within a tight time window (5-50ms)
2. Require value correlation: Track whether LSB changes proportionally to MSB over multiple events
3. Require consistent byte order: If one pair sends MSB-then-LSB, they should always do this, not randomly alternate
4. Add confidence scoring: Don't immediately lock into 14-bit mode after first pairing; require sustained evidence
5. Allow manual override: User can force 7-bit mode if auto-detection is wrong

**Warning signs:**
- LSB values are always the same (e.g., always 0 or 127) while MSB varies
- Time gap between "paired" messages exceeds 100ms
- LSB changes without corresponding MSB change
- Byte order alternates randomly between MSB-first and LSB-first
- Combined 14-bit values produce erratic jumps that don't match physical controller movement

**Phase to address:**
Phase 2: Pairing Detection Logic

---

### Pitfall 2: Message Ordering Glitches (Intermediate Values)

**What goes wrong:**
During value transitions, incorrect intermediate values are emitted to the callback. When incrementing from MSB=1, LSB=127 (value 255) by 1:
- If MSB sent first then LSB: triggers value 383 before settling to 256
- If LSB sent first then MSB: triggers value 128 before settling to 256

This causes parameter jumps and UI flicker as the mapping system processes invalid intermediate values.

**Why it happens:**
The detector emits a value as soon as either byte arrives, without waiting for the pair. The 10-hit threshold applies to the event signature (type, channel, number), not to complete MSB+LSB pairs. Different manufacturers send in different orders (Yamaha sends reverse order compared to others), and the detector doesn't know which byte is "first" vs. "complete."

**How to avoid:**
1. Implement paired event buffering: Don't call onMidiEventFound until BOTH MSB and LSB arrive
2. Add timeout mechanism: If only one byte arrives within 50ms, treat as unpaired/incomplete
3. Track last-received byte: Store MSB or LSB separately; only emit when you have both
4. Modify threshold logic: Count MSB+LSB pairs as "one hit," not two separate hits
5. Consider suppressing rapid-fire callbacks: If values change faster than 10ms, batch them

**Warning signs:**
- Parameter values jump wildly during smooth knob turns
- UI shows values that exceed the expected range (e.g., 383 when max should be 16383)
- Logs show timestamp gaps between MSB and LSB exceeding 10ms
- onMidiEventFound fires twice per physical movement instead of once

**Phase to address:**
Phase 3: Byte Order Detection & Buffering

---

### Pitfall 3: MSB-Only or LSB-Only Devices (Incomplete Pairs)

**What goes wrong:**
Some controllers send only MSB without LSB (or vice versa), causing the detector to permanently wait for a pairing that never comes. The Typhon synthesizer uses CC0 only (not CC32). Controllers optimized for speed send only MSB. The detector gets stuck in "waiting for pair" state and never fires onMidiEventFound.

**Why it happens:**
Hardware manufacturers optimize for transmission speed or don't need full 14-bit resolution. When a knob movement is too small to change the MSB value, only LSB is sent. Some devices assume "LSB is 0 if not received yet." The detector's pairing logic doesn't have a timeout or fallback for orphaned messages.

**How to avoid:**
1. Implement message timeout: If MSB arrives without LSB within 50-100ms, emit as 7-bit (value = MSB << 7)
2. Track orphaned messages: Count how many times MSB arrives alone; if >10 consecutive, conclude device is MSB-only
3. Adaptive mode switching: If pattern shows consistent MSB-only or LSB-only, fall back to 7-bit mode
4. Don't block 7-bit detection: Even in 14-bit candidate mode, allow 7-bit events to be detected separately
5. Provide debug visibility: Show users when messages are being buffered/orphaned

**Warning signs:**
- onMidiEventFound stops firing entirely after initial 14-bit detection
- UI shows "Waiting for MIDI..." despite active controller input
- Logs show continuous MSB messages without corresponding LSB messages
- Threshold counter keeps incrementing but never triggers callback
- User reports "it worked once, then stopped"

**Phase to address:**
Phase 4: Timeout & Fallback Logic

---

### Pitfall 4: Reserved CC Numbers (Bank Select Special Cases)

**What goes wrong:**
CC0 (Bank Select MSB) and CC32 (Bank Select LSB) are treated as a regular 14-bit pair, but they have special semantics in MIDI. They require a Program Change message afterward to take effect. Detecting them as a generic 14-bit pair and mapping them to Disting NT parameters causes confusion because moving a knob doesn't do what users expect.

In GM2, CC0 has reserved values:
- CC0=121 + CC32=0 = melodic bank 0
- CC0=120 + CC32=0 = drum bank

Users might want to map Bank Select for switching Disting presets, not parameter control.

**Why it happens:**
CC0/CC32 follow the same MSB+32=LSB pattern as other 14-bit pairs, so the detector correctly identifies them structurally but misunderstands their purpose. The detector doesn't distinguish between parameter control CCs and mode/state CCs.

**How to avoid:**
1. Exclude Bank Select from auto-detection: Hardcode CC0/CC32 as non-detectable
2. OR: Detect but flag as "special" type: Add BankSelect variant to MidiEventType
3. Document reserved ranges: CC 120-127 are Channel Mode Messages, not normal CCs
4. Provide user education: Warn when detecting reserved CCs
5. Consider adding Bank Select handling as a separate feature (preset switching)

**Warning signs:**
- Users report "knob doesn't control parameter" when using CC0 or CC32
- Detection fires but downstream mapping has no effect
- Program Change messages appear in MIDI stream alongside CC0/CC32
- Device manual says "use CC0 for bank selection" but detector treats it as parameter

**Phase to address:**
Phase 1: Requirements & Reserved CC List

---

### Pitfall 5: Hardware Quantization (False 14-bit Resolution)

**What goes wrong:**
The detector successfully pairs MSB/LSB and identifies them as 14-bit, but the hardware doesn't actually provide 14-bit resolution. BCF2000's LSB moves in steps of 16 (not 1). Novation Bass Station 2 achieves only 255 steps (LSB steps of 64). VCI-400's LSB takes only 4 values (0x00, 0x20, 0x40, 0x60), making it effectively 9-bit. The detector reports "14-bit detected" but users don't get the expected precision.

**Why it happens:**
Hardware ADC noise floor, potentiometer mechanical limits, and transmission bandwidth optimization mean many devices claim 14-bit but deliver far less. If using a 14-bit ADC to sample a potentiometer, the LSB can be random noise.

**How to avoid:**
1. Detect quantization: Track LSB value distribution over 50+ events; if only a few discrete values appear, it's quantized
2. Report effective resolution: "Detected 14-bit (effective 9-bit)" in UI
3. Warn on noisy LSB: If LSB changes every message despite no MSB change, it's likely noise
4. Allow user to disable LSB: Provide option to ignore LSB if it's just noise
5. Document limitations: Don't promise "full 16383 steps" without verification

**Warning signs:**
- LSB values cluster around a few discrete values (e.g., 0, 32, 64, 96, 127)
- LSB changes randomly while MSB is stable (noise)
- Physical knob has only ~128-256 detents but LSB suggests 16384 steps
- Parameter jitter: value oscillates between N and N+1 when knob is stationary
- Device marketing says "14-bit" but community reports say otherwise

**Phase to address:**
Phase 5: Resolution Verification & Quality Checks

---

### Pitfall 6: State Machine Corruption (7-bit to 14-bit Transition)

**What goes wrong:**
The detector switches from detecting CC X as 7-bit to detecting it as 14-bit (or vice versa), but the transition corrupts internal state:
- `_lastEventSignature` references the wrong event type (7-bit signature vs. 14-bit signature)
- `_consecutiveCount` gets reused across mode changes
- Freezed state holds 7-bit values while detector is in 14-bit mode
- onMidiEventFound callback contract breaks (suddenly receives 14-bit values when expecting 7-bit)

**Why it happens:**
Current code uses a single threshold counter and signature tracker. When adding 14-bit detection, the detector needs separate tracking for 7-bit CC X and 14-bit CC X+X+32 pair. The transition between modes isn't explicitly modeled, leading to state contamination.

**How to avoid:**
1. Separate state tracking: Different counters for 7-bit vs. 14-bit candidates
2. Explicit mode enum: Track current mode (Initial, Detecting7Bit, Detecting14Bit, Confirmed7Bit, Confirmed14Bit)
3. State reset on transition: When switching from 7-bit to 14-bit, reset counters/signatures
4. Immutable transitions: Once a CC is confirmed as 14-bit, don't switch back to 7-bit (or require explicit reset)
5. Callback contract versioning: Add eventBitDepth: 7 | 14 to callback signature
6. Freezed migration: Generate new freezed state with 14-bit fields; test that copyWith preserves integrity

**Warning signs:**
- flutter analyze reports freezed errors after adding 14-bit types
- _consecutiveCount has impossible values (e.g., 150 when threshold is 10)
- onMidiEventFound receives CC number 33 but type is still MidiEventType.cc (not cc14bit)
- UI shows "Detected CC 1" then immediately "Detected CC 1 + CC 33" without user action
- Test failures around state transitions

**Phase to address:**
Phase 1: State Model Design (before implementation)

---

### Pitfall 7: Threshold Semantics (What Counts as "One Hit"?)

**What goes wrong:**
The current implementation counts 10 consecutive identical events before confirming detection. When adding 14-bit pairs, it's unclear what "one event" means:
- Do MSB and LSB each count as 1 hit (20 total for confirmation)?
- Does the MSB+LSB pair count as 1 hit (10 total)?
- What if MSB arrives 10 times without LSB—is that confirmed?

This ambiguity causes either over-sensitive detection (false positives) or under-sensitive detection (never confirms).

**Why it happens:**
The existing threshold logic is simple: track `(type, channel, number)` signature and count repetitions. With 14-bit pairs, the signature concept breaks down because you have TWO numbers. The code doesn't define whether confirmation requires paired events or just independent byte hits.

**How to avoid:**
1. Define threshold semantics upfront: Document what counts as "one hit" for 14-bit
2. Recommended: Count complete pairs as 1 hit (require 10 MSB+LSB pairs within timeout)
3. Alternative: Require 10 consecutive MSBs AND 10 consecutive LSBs (stricter)
4. Edge case handling: If 10 MSBs arrive without LSBs, confirm as MSB-only 7-bit
5. Reset on disorder: If byte order changes mid-detection, reset counter
6. Unit tests: Explicitly test threshold behavior with various interleaving patterns

**Warning signs:**
- Detection confirms after only 5 physical knob turns (each turn sends MSB+LSB, counted as 2)
- Detection never confirms despite 20+ messages (counting pairs as 2, threshold expects 10)
- Different developers interpret "10 hits" differently during code review
- Unit tests pass but integration tests show unexpected confirmation timing
- User feedback: "too sensitive" vs. "never detects" from different hardware

**Phase to address:**
Phase 2: Pairing Detection Logic (define semantics before coding)

---

### Pitfall 8: Callback Contract Breaking (Existing Consumers)

**What goes wrong:**
The existing `onMidiEventFound` callback signature is:
```dart
onMidiEventFound?.call(
  type: lastDetectedType,
  channel: lastDetectedChannel,
  number: eventNumber, // CC or Note number
);
```

When adding 14-bit, consumers receive `number` that is ambiguous:
- Is it the MSB CC number (0-31)?
- Is it the LSB CC number (32-63)?
- Is it the combined 14-bit value (0-16383)?
- Is it a new CC pair identifier?

Existing code in `packed_mapping_data_editor.dart` or other consumers breaks because they expect `number` to be a 7-bit CC number (0-127), not a 14-bit value or pair ID.

**Why it happens:**
The callback was designed for 7-bit events. Adding 14-bit detection without changing the signature causes semantic drift: the same field means different things depending on event type. This is a classic API versioning failure.

**How to avoid:**
1. Extend enum: Add MidiEventType.cc14bit (separate from cc)
2. Expand signature: Add `int? number2` for LSB CC number, or `int? value14bit` for combined value
3. Breaking change: If needed, change signature to include bit depth explicitly
4. Version callback: Provide onMidiEventFound and onMidiEventFoundV2 (deprecated migration)
5. Document semantics: Clearly specify what `number` means for each event type
6. Test all consumers: Grep for onMidiEventFound usage, verify each call site handles new types
7. Freezed regeneration: After modifying MidiEventType, run `dart run build_runner build --delete-conflicting-outputs`

**Warning signs:**
- flutter analyze warnings: "The parameter 'number' is required but was marked as nullable"
- Runtime errors: UI tries to display CC number 16383 (14-bit value) in a 0-127 slider
- Existing mappings break: CC1 mapping stops working after 14-bit detection added
- Type errors in tests: Mockito expectations fail because new enum variants don't match
- Build failures: freezed generation fails with "conflicting output"

**Phase to address:**
Phase 1: API Design (before modifying state or cubit)

---

## Technical Debt Patterns

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|-------------------|----------------|-----------------|
| Treat MSB and LSB as independent 7-bit CCs | Simple: no new logic needed | Can't support true 14-bit; user confusion when CC X and CC X+32 both detected | Never (feature requirement is 14-bit detection) |
| Count MSB and LSB separately toward threshold | Simple counter reuse | False positives: confirms after 5 physical knob turns instead of 10 | Never (violates threshold semantics) |
| Emit intermediate values during MSB/LSB arrival | No buffering logic needed | Parameter jumps, UI flicker, unusable mappings | Never (core UX issue) |
| Skip timeout mechanism for orphaned messages | Simpler state machine | Detector hangs on MSB-only devices; never fires callback | Never (breaks MSB-only hardware) |
| Hardcode MSB-first byte order assumption | Works for most hardware | Fails on Yamaha and other LSB-first devices | Never (known incompatibility) |
| Freeze state after first pairing detected | Faster confirmation | False positives from coincidental CC usage; no recovery if wrong | Only in MVP if timeout/fallback is in Phase 2 |
| Reuse existing `number` field for 14-bit value | No API change needed | Breaks existing consumers; semantic ambiguity | Never (API contract violation) |
| Skip freezed regeneration during prototyping | Faster iteration | IDE errors, type mismatches, broken builds | Only during local experimentation (never commit) |

---

## Integration Gotchas

| Integration | Common Mistake | Correct Approach |
|-------------|----------------|------------------|
| Mapping Editor (onMidiEventFound) | Assume `number` is always a CC 0-127 | Check `type` for cc vs. cc14bit; handle `number` semantics per type |
| Freezed State (MidiListenerState) | Add new fields without regenerating | Run `dart run build_runner build --delete-conflicting-outputs` after any state change |
| Cubit Threshold Logic | Count MSB and LSB separately | Count complete pairs as 1 hit; reset on orphaned messages |
| MIDI Packet Parsing | Assume CC messages are always 3 bytes | Validate `data.length >= 3` before parsing (already done, keep this) |
| Device Discovery | Filter out Disting NT devices | Keep this filter; don't accidentally detect Disting NT's own MIDI feedback |
| Timeout Handling | Use long timeouts (100ms+) to be "safe" | Use 5-50ms; MIDI messages in a pair arrive microseconds apart in practice |

---

## Performance Traps

| Trap | Symptoms | Prevention | When It Breaks |
|------|----------|------------|----------------|
| Unbounded message buffering | Memory grows indefinitely if LSB never arrives | Limit buffer size to 32 messages; expire after 100ms | After 10 minutes of continuous MSB-only input |
| Callback thrashing | onMidiEventFound fires 1000x/sec during fast knob turns | Rate-limit to 60Hz or debounce 16ms | High-resolution encoders with fast sweeps |
| State cloning in every emit | CPU spikes during MIDI floods | Use const constructors; minimize copyWith calls | 10+ MIDI devices with continuous CCs |
| Regex/complex pairing logic | Parsing latency >10ms | Use simple arithmetic (cc2 == cc1 + 32) | Already optimized; N/A for this project |
| Unbounded history tracking | Memory grows to track all detected pairs | Limit to last 10 pairs; use circular buffer | Long-running sessions (hours) with many controllers |

---

## UX Pitfalls

| Pitfall | User Impact | Better Approach |
|---------|-------------|-----------------|
| Silent false positives | User maps CC1, detector pairs with CC33, mapping doesn't work as expected | Show "Detected 14-bit pair CC1+CC33" vs. "Detected CC1 (7-bit)" in UI |
| No recovery from incorrect detection | Detector locks into 14-bit mode; user can't get back to 7-bit | Provide "Reset detection" button; allow manual override to 7-bit/14-bit |
| Mysterious "waiting" state | UI shows "Waiting for MIDI..." after MSB-only messages buffered | Show "Received CC1 MSB, waiting for LSB..." with timeout countdown |
| No feedback on quantization | User expects 16384 steps but gets 256 | Display "Effective resolution: ~256 steps" after analysis |
| Unexpected mode switches | Detector switches from 7-bit to 14-bit mid-session | Require explicit confirmation before switching modes; show warning |
| Threshold progress invisible | User turns knob 5 times, nothing happens (threshold is 10) | Show progress indicator: "5/10 events detected" |

---

## "Looks Done But Isn't" Checklist

- [ ] **14-bit detection implemented:** Does it handle MSB-only devices (timeout/fallback)?
- [ ] **State extended with 14-bit fields:** Did you run freezed code generation after modifying state?
- [ ] **Threshold logic updated:** Is it clear whether pairs count as 1 hit or 2?
- [ ] **Callback signature extended:** Do consumers know whether they received 7-bit or 14-bit?
- [ ] **Byte order detection:** Does it work with both MSB-first and LSB-first devices?
- [ ] **Timeout mechanism:** What happens if LSB never arrives after MSB?
- [ ] **False positive prevention:** Temporal + value correlation checks in place?
- [ ] **Reserved CCs excluded:** CC0/CC32 (Bank Select) and CC120-127 (Channel Mode) handled specially?
- [ ] **Quantization detection:** Can it warn users about fake 14-bit resolution?
- [ ] **Migration path:** Can existing 7-bit mappings coexist with new 14-bit mappings?
- [ ] **flutter analyze clean:** Zero warnings after adding new types/state?
- [ ] **Unit tests for edge cases:** Orphaned MSB, orphaned LSB, byte order flip, quantization, false pairing?

---

## Recovery Strategies

| Pitfall | Recovery Cost | Recovery Steps |
|---------|---------------|----------------|
| False positive pairing | LOW | Add manual override UI; reset detection state; adjust correlation thresholds |
| Callback contract broken | MEDIUM | Version callback API; migrate consumers; add deprecated annotation; test all call sites |
| Freezed generation skipped | LOW | Run `dart run build_runner build --delete-conflicting-outputs`; commit generated files |
| State machine corrupted | HIGH | Redesign state model with explicit modes; write migration path; re-test all transitions |
| Intermediate values emitted | MEDIUM | Add message buffering; implement timeout; adjust threshold to count pairs; batch callbacks |
| MSB-only device hangs | MEDIUM | Add timeout (50-100ms); emit orphaned MSB as 7-bit value; track consecutive orphans |
| Byte order misdetected | LOW | Track both orders; use value analysis to determine correct order; provide manual override |
| Reserved CCs detected | LOW | Add exclusion list; update UI to show special CC types; document limitations |
| Threshold semantics unclear | MEDIUM | Define explicitly in docs; update unit tests; refactor counter logic; add semantic comments |
| Performance degradation | MEDIUM | Add rate limiting (60Hz); bound buffer size (32 msgs); debounce callbacks (16ms) |

---

## Pitfall-to-Phase Mapping

| Pitfall | Prevention Phase | Verification |
|---------|------------------|--------------|
| Callback contract breaking | Phase 1: API Design | Compile all consumers; check onMidiEventFound call sites |
| Reserved CCs detected | Phase 1: Requirements & Reserved CC List | Test with CC0, CC32, CC120-127; verify exclusion |
| State machine corruption | Phase 1: State Model Design | Unit tests for mode transitions; freezed builds without errors |
| Threshold semantics unclear | Phase 2: Pairing Detection Logic | Unit tests with interleaved MSB/LSB; documentation clear |
| False positive pairing | Phase 2: Pairing Detection Logic | Test with Spitfire CC32 (independent); temporal correlation validates |
| Intermediate values emitted | Phase 3: Byte Order Detection & Buffering | Manual test: turn knob, verify no intermediate value in logs |
| MSB-only device hangs | Phase 4: Timeout & Fallback Logic | Test with MSB-only stream; verify callback fires after timeout |
| Byte order misdetected | Phase 3: Byte Order Detection & Buffering | Test with Yamaha device (LSB-first); verify correct value |
| Hardware quantization | Phase 5: Resolution Verification & Quality Checks | Test with BCF2000; detect LSB quantization; warn user |
| Performance degradation | Phase 6: Polish & Optimization | Load test: 10 controllers @ 1000 msg/sec; measure latency |

---

## Sources

**MIDI 14-bit CC Implementation:**
- [Receiving 14-bit MIDI CC messages](https://forum.pdpatchrepo.info/topic/14431/receiving-14-bit-midi-cc-messages) - MSB/LSB pairing, message ordering, buddy logic
- [14-Bit MIDI input discussion](https://forum.beepstreet.com/discussion/2217/14-bit-midi-input) - Byte order issues, Yamaha reverse order
- [14-bit MIDI controllers with REAL high res encoders](https://modwiggler.com/forum/viewtopic.php?t=210642) - Hardware quantization, noise floor, LSB steps
- [MIDI MSB/LSB Explained](https://redconfetti.com/music-production/2024/03/18/midi-msb-lsb-explained.html) - MSB-only transmission, LSB assumed 0

**MIDI CC Reserved Numbers:**
- [StudioCode - MIDI CC numbers](https://studiocode.dev/resources/midi-cc/) - CC0/CC32 Bank Select, CC120-127 reserved
- [Bank Select - InSync | Sweetwater](https://www.sweetwater.com/insync/bank-select/) - GM2 reserved values, CC0=121/120 special cases
- [Is MIDI CC 32 to 63 usable?](https://vi-control.net/community/threads/is-midi-cc-32-to-63-usable.153130/) - Real-world CC32-63 independent usage

**Hardware Resolution Issues:**
- [14bit MIDI controllers with REAL high res encoders](https://modwiggler.com/forum/viewtopic.php?t=210642) - BCF2000 LSB steps of 16, Bass Station 2 LSB steps of 64, Slim Phatty LSB steps of 32
- [Mod Wheel LSB vs. MSB?](https://vi-control.net/community/threads/mod-wheel-lsb-vs-msb.102731/) - VCI-400 effective 9-bit resolution

**Codebase Analysis:**
- Current implementation: `lib/ui/midi_listener/midi_listener_cubit.dart` lines 14-17, 159-172 (threshold logic)
- State model: `lib/ui/midi_listener/midi_listener_state.dart` lines 3-21 (freezed state)
- Callback contract: `lib/ui/midi_listener/midi_detector_widget.dart` lines 13-18, 190-195 (onMidiEventFound)

---

*Pitfalls research for: 14-bit MIDI CC Auto-Detection in nt_helper*
*Researched: 2026-01-31*
