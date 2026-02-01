# Feature Research: 14-bit MIDI CC Auto-Detection

**Domain:** MIDI mapping auto-detection for Eurorack module control
**Researched:** 2026-01-31
**Confidence:** MEDIUM

## Feature Landscape

### Table Stakes (Users Expect These)

Features users assume exist. Missing these = product feels incomplete.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| CC pair detection (0-31 + 32-63) | MIDI spec standard - CC 0-31 (MSB) pairs with CC 32-63 (LSB) | LOW | Already have 7-bit detection infrastructure, just need pairing logic |
| 10-hit threshold for CC pairs | Consistency with existing 7-bit CC detection | LOW | Reuse existing threshold mechanism from MidiListenerCubit.kThreshold |
| Detection status messages | Users need feedback during detection ("Detected CC 1/33 14-bit pair on channel 1") | LOW | Extend existing status message system in MidiDetectorWidget |
| Channel-aware detection | Multiple controllers may send same CC on different channels | LOW | Already handled in existing detection logic |
| Auto-population of mapping fields | Once detected, populate midiCC and midiMappingType in mapping editor | MEDIUM | Integration with existing PackedMappingData and mapping editor |

### Differentiators (Competitive Advantage)

Features that set the product apart. Not required, but valuable.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Byte order auto-detection | Automatically determine if controller sends MSB-first or LSB-first | HIGH | Yamaha sends reverse order vs. others. Requires value analysis heuristics to determine coherent byte order |
| Visual 14-bit value preview | Show real-time 14-bit value (0-16383) during detection | MEDIUM | Helps users verify controller is working correctly before mapping |
| Partial pair warning | Alert if only MSB or LSB detected without partner | MEDIUM | Common issue: some controllers don't send both bytes. Helps diagnose problems |
| CC number recommendation | Suggest which CC number to use based on detection frequency | LOW | If both MSB and LSB detected, recommend the base CC (0-31) |
| Detection confidence indicator | Show confidence level based on value coherence analysis | HIGH | For byte order detection - "HIGH confidence LSB-first based on value distribution" |

### Anti-Features (Commonly Requested, Often Problematic)

Features that seem good but create problems.

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|-----------------|-------------|
| Auto-timeout for pair waiting | "Detect faster by timing out after 50ms if no LSB arrives" | Most controllers send pairs within 1-2ms, but some may be slower. Timeout creates false negatives and user confusion | Wait for 10 hits of coherent pair pattern instead of timeout |
| Automatic mapping type selection | "Just pick cc14BitLow or cc14BitHigh automatically" | Disting NT's byte order preference depends on hardware/firmware expectations, not just controller behavior | Detect byte order, then let user choose or provide smart recommendation with explanation |
| Detection of non-standard pairs | "Support CC pairs that aren't 0-31/32-63" | MIDI spec is explicit. Non-standard pairs are not 14-bit CCs, just independent 7-bit CCs that happen to arrive together | Only detect standard pairs per MIDI spec |
| Reset threshold on any CC change | "If user moves different control, reset counter" | Would prevent detection if user accidentally nudges another control. Too sensitive | Only reset when same CC pair signature repeats (existing behavior) |

## Feature Dependencies

```
[CC Pair Detection]
    └──requires──> [Existing 7-bit CC detection infrastructure]
                       └──requires──> [MIDI event parsing in MidiListenerCubit]

[Byte Order Detection] ──enhances──> [CC Pair Detection]
    └──requires──> [Value analysis heuristics]

[Auto-populate mapping] ──requires──> [CC Pair Detection]
    └──requires──> [Integration with PackedMappingData]

[Visual 14-bit preview] ──enhances──> [CC Pair Detection]
    └──requires──> [Real-time value combining (MSB << 7 | LSB)]

[Partial pair warning] ──requires──> [CC Pair Detection]
    └──conflicts──> [Immediate detection] (must wait to determine if pair completes)
```

### Dependency Notes

- **CC Pair Detection requires existing infrastructure:** The current detection mechanism in `MidiListenerCubit` handles 7-bit CCs with 10-hit threshold. We extend this to track CC pairs (X and X+32) arriving together.
- **Byte Order Detection enhances CC Pair Detection:** Once a pair is detected, analyze the combined values to determine if MSB-first or LSB-first produces coherent results (e.g., smooth value changes vs. erratic jumps).
- **Auto-populate mapping requires integration:** After detection, must map to `MidiMappingType.cc14BitLow` or `cc14BitHigh` and set the base CC number in `PackedMappingData`.
- **Partial pair warning conflicts with immediate detection:** For Note On/Off, detection is immediate (no threshold). For 14-bit CC pairs, must wait for threshold AND verify both MSB/LSB appear in pattern.

## MVP Definition

### Launch With (v1)

Minimum viable product - what's needed to validate the concept.

- [x] CC pair detection (0-31 + 32-63) - Essential for 14-bit support
- [x] 10-hit threshold for pairs - Consistency with existing UX
- [x] Detection status messages - User feedback during detection
- [x] Auto-populate midiCC and suggest midiMappingType - Complete the detection workflow
- [x] Basic byte order detection - Distinguish MSB-first vs LSB-first

### Add After Validation (v1.x)

Features to add once core is working.

- [ ] Visual 14-bit value preview - Add when users request better feedback during detection
- [ ] Detection confidence indicator - Add if byte order detection has ambiguous cases
- [ ] Partial pair warning - Add if users report confusion when only MSB or LSB is sent

### Future Consideration (v2+)

Features to defer until product-market fit is established.

- [ ] CC number recommendation based on frequency - Nice to have, not essential
- [ ] Support for NRPN detection - Different spec, different milestone
- [ ] Multi-channel pair detection visualization - Only needed if users have complex setups

## Feature Prioritization Matrix

| Feature | User Value | Implementation Cost | Priority |
|---------|------------|---------------------|----------|
| CC pair detection (0-31 + 32-63) | HIGH | LOW | P1 |
| 10-hit threshold for pairs | HIGH | LOW | P1 |
| Detection status messages | HIGH | LOW | P1 |
| Auto-populate mapping fields | HIGH | MEDIUM | P1 |
| Byte order auto-detection | MEDIUM | HIGH | P1 |
| Visual 14-bit value preview | MEDIUM | MEDIUM | P2 |
| Partial pair warning | LOW | MEDIUM | P2 |
| CC number recommendation | LOW | LOW | P3 |
| Detection confidence indicator | LOW | HIGH | P3 |

**Priority key:**
- P1: Must have for launch (14-bit detection doesn't work without these)
- P2: Should have, add when possible (improves UX but not blocking)
- P3: Nice to have, future consideration (polish features)

## Implementation Analysis

### Existing Infrastructure (Leverage)

The app already has:

1. **MidiListenerCubit with 10-hit threshold** - Lines 14, 169-172 in `midi_listener_cubit.dart`
   - Tracks consecutive identical events via `_lastEventSignature` and `_consecutiveCount`
   - CC requires 10 hits, Notes are immediate

2. **MidiMappingType enum with 14-bit support** - Lines 5-14 in `packed_mapping_data.dart`
   - `cc14BitLow(3)` and `cc14BitHigh(4)` already defined
   - Encoding/decoding already handles these types in SysEx

3. **MidiDetectorWidget with status messages** - Lines 273-282 in `midi_detector_widget.dart`
   - Shows detection results with fade timer (3 seconds)
   - Already displays CC number and channel

4. **onMidiEventFound callback** - Lines 13-18, 190-194 in `midi_detector_widget.dart`
   - Fires when detection threshold met
   - Returns `{type, channel, number}`

### New Infrastructure Needed

1. **14-bit pair tracking in MidiListenerCubit:**
   - Map to track recent CC activity per channel: `Map<int, Map<int, DateTime>> _recentCCs`
   - When CC X arrives, check if CC X+32 (or X-32) appeared recently
   - Track both MSB and LSB values to compute full 14-bit value
   - Apply 10-hit threshold to the PAIR signature, not individual CCs

2. **Byte order determination logic:**
   - Track sequence: does MSB or LSB typically arrive first?
   - Analyze value coherence: compute 14-bit value both ways (MSB-first vs LSB-first)
   - Choose interpretation with smallest deltas between consecutive values
   - Confidence: HIGH if one interpretation clearly smoother, MEDIUM if ambiguous

3. **Extended MidiEventType enum:**
   - Add `MidiEventType.cc14Bit` to distinguish from regular CC
   - Or extend callback to include `{type, channel, number, is14Bit, byteOrder}`

4. **Extended onMidiEventFound callback:**
   - Current: `{type, channel, number}`
   - Proposed: `{type, channel, number, is14Bit: bool, byteOrder: 'msbFirst'|'lsbFirst'}`

### Edge Cases to Handle

1. **Controller sends only MSB (common for coarse adjustments):**
   - Don't detect as 14-bit pair
   - Fall back to 7-bit CC detection after threshold

2. **Controller sends MSB and LSB non-consecutively:**
   - Use time window (e.g., 100ms) to associate MSB with LSB
   - If LSB arrives >100ms after MSB, treat as independent CCs

3. **User moves multiple 14-bit controls during detection:**
   - Reset counter if different CC pair detected
   - Similar to existing behavior for 7-bit CCs

4. **Yamaha controllers (reverse byte order):**
   - Byte order detection must handle both directions
   - Some Yamaha devices send LSB before MSB (opposite of standard)

5. **Controller sends partial resolution (e.g., only 255 steps in LSB):**
   - Hardware like Novation Bass Station 2 sends LSB in steps of 64
   - Still valid 14-bit CC, just not using full resolution
   - Detection should succeed, but value preview may show step pattern

## MIDI Protocol Context

### 14-bit CC Specification

From MIDI 1.0 spec and community research:

- **Pairing:** CC 0-31 (MSB) pairs with CC 32-63 (LSB)
  - Example: CC 1 (MSB) + CC 33 (LSB) = 14-bit Modulation Wheel
  - Example: CC 7 (MSB) + CC 39 (LSB) = 14-bit Channel Volume

- **Value calculation:** `full_value = (MSB << 7) | LSB`
  - Range: 0 to 16,383 (2^14 - 1)
  - MSB contributes bits 7-13, LSB contributes bits 0-6

- **Message order (standard):** MSB first, then LSB
  - Most controllers send MSB, then LSB within 1-2ms
  - Spec allows LSB-only for fine adjustments (MSB implied unchanged)
  - Spec allows MSB-only for coarse adjustments (LSB implied zero)

- **Yamaha exception:** Some Yamaha devices send LSB then MSB
  - This is non-standard but documented behavior
  - Requires byte order detection to handle gracefully

### Compatibility Design

MIDI 14-bit CCs are designed for backward/forward compatibility:

- **7-bit device receiving 14-bit:** Ignores LSB, uses MSB only
- **14-bit device receiving 7-bit:** Treats missing LSB as zero
- **7-bit controller sending to 14-bit receiver:** LSB assumed zero, still works

This means:
- Detection must distinguish "deliberate 14-bit pair" from "MSB-only usage"
- Threshold helps: if both MSB and LSB consistently appear together, it's 14-bit
- If only MSB appears, it's 7-bit CC (existing behavior)

## Competitor Feature Analysis

| Feature | DAW MIDI Learn (Ableton, Logic) | ReaLearn Plugin | Our Approach |
|---------|----------------------------------|-----------------|--------------|
| 14-bit detection | Manual: user must specify "14-bit mode" before learning | Automatic: detects pairs and offers 14-bit option | Automatic: detect pairs with 10-hit threshold, same as 7-bit |
| Byte order handling | Not addressed (assumes standard MSB-first) | Not addressed | Auto-detect via value coherence analysis |
| Partial pair handling | Ignored (LSB-only messages treated as independent CC) | Ignored | Warn user if only MSB or LSB detected after threshold |
| Status feedback | "Learning... CC 1 received" | "Detected CC 1 (MSB) + CC 33 (LSB)" | "Detected CC 1/33 14-bit pair (MSB-first) on channel 1" |

**Our differentiation:**
1. No mode switching - seamless detection of 7-bit vs 14-bit
2. Byte order detection for Yamaha compatibility
3. Partial pair warnings to help diagnose controller issues

## Sources

### MIDI Protocol and Specification

- [MIDI Specification: Controller Numbers](http://midi.teragonaudio.com/tech/midispec/ctllist.htm) - Authoritative MIDI CC list
- [MIDI CC Lists and Explanations - Control Change](https://nickfever.com/music/midi-cc-list/) - CC 0-31 MSB, 32-63 LSB pairing
- [MIDI MSB/LSB Explained | redconfetti](https://redconfetti.com/music-production/2024/03/18/midi-msb-lsb-explained.html) - Byte order and value calculation
- [What is MSB and LSB? - Morningstar](https://www.morningstar.io/post/2016/12/25/midi-msb-and-lsb) - MSB/LSB fundamentals

### Implementation Patterns

- [Receiving 14-bit MIDI CC messages | PURE DATA forum](https://forum.pdpatchrepo.info/topic/14431/receiving-14-bit-midi-cc-messages) - Buddy logic for pairing, LSB + (MSB * 128) calculation
- [14-bit MIDI CC weirdness (Yamaha reverse order) - Ableton Forum](https://forum.ableton.com/viewtopic.php?t=59762) - Yamaha LSB-first behavior
- [14 bit midi in 1.0 - VCV Rack Community](https://community.vcvrack.com/t/14-bit-midi-in-1-0/1779?page=3) - Detection challenges and buddy logic
- [how can I receive 14 bit resolution CC messages in Max 7? - MaxMSP Forum](https://cycling74.com/forums/how-can-i-receive-14-bit-resolution-cc-messages-in-max-7) - xctlin object approach

### DAW and Plugin Behavior

- [ReaLearn](https://www.helgoboss.org/projects/realearn) - 14-bit CC and (N)RPN source support
- [Using MIDI Learn in UAD Plug-Ins](https://help.uaudio.com/hc/en-us/articles/38338846512276-Using-MIDI-Learn-in-UAD-Plug-Ins) - Single CC to single control mapping
- [Q: 14-bit MIDI CC messages and plug-ins? - KVR Audio](https://www.kvraudio.com/forum/viewtopic.php?t=534618) - Plugin support limitations

### Hardware Controller Behavior

- [14 bit midi controllers - CWITEC Forum - KVR Audio](https://www.kvraudio.com/forum/viewtopic.php?t=623877) - Faderfox UC4/EC4 14-bit mode, Novation/Moog reduced resolution
- [14bit MIDI controllers with REAL high res encoders - MOD WIGGLER](https://modwiggler.com/forum/viewtopic.php?t=210642) - Physical encoder limitations (12 steps/rotation)
- [14 bit midi controllers - Gearspace](https://gearspace.com/board/music-computers/633603-14-bit-midi-controllers.html) - Hardware implementation challenges
- [14-Bit MIDI input - BeepStreet forums](https://forum.beepstreet.com/discussion/2217/14-bit-midi-input) - MSB/LSB transmission patterns

### Edge Cases and Pitfalls

- [Mod Wheel LSB vs. MSB? | VI-CONTROL](https://vi-control.net/community/threads/mod-wheel-lsb-vs-msb.102731/) - Byte order confusion
- [Sending 14-bit USB-MIDI as MSB/LSB. Filter repeats? - Arduino Forum](https://forum.arduino.cc/t/sending-14-bit-usb-midi-as-msb-lsb-filter-repeats/466789) - Message ordering and timing
- [[Solved] Can't get 14-bit MIDI CC's to work - Cockos Forums](https://forum.cockos.com/showthread.php?t=230413) - Common setup issues

**Research confidence levels:**
- **HIGH:** MIDI spec pairing (CC 0-31 + 32-63), value calculation formula, standard message order
- **MEDIUM:** Byte order detection heuristics, timing windows for pair association, hardware resolution variations
- **LOW:** Yamaha-specific behavior (mentioned in forums but not officially documented), exact prevalence of non-standard implementations

---
*Feature research for: 14-bit MIDI CC Auto-Detection*
*Researched: 2026-01-31*
