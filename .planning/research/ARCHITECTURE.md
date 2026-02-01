# Architecture Research

**Domain:** 14-bit MIDI CC Auto-Detection in Flutter Cubit Architecture
**Researched:** 2026-01-31
**Confidence:** HIGH

## Integration Overview

14-bit MIDI CC auto-detection extends the existing `MidiListenerCubit` to track CC pairs and determine byte order through value analysis. The cubit already has a single-event signature tracking pattern that must evolve to support pair-based tracking.

```
┌─────────────────────────────────────────────────────────────┐
│                   PackedMappingDataEditor                     │
│                    (Consumer / UI Layer)                      │
├─────────────────────────────────────────────────────────────┤
│                          ↑ onMidiEventFound callback          │
│                          │ (type, channel, number)            │
├─────────────────────────┴─────────────────────────────────────┤
│                     MidiDetectorWidget                         │
│                    (BlocConsumer bridge)                       │
├─────────────────────────────────────────────────────────────┤
│                          ↑ MidiListenerState                   │
│                          │ (lastDetectedType, etc.)           │
├─────────────────────────┴─────────────────────────────────────┤
│                     MidiListenerCubit                          │
│              (Detection logic + state management)              │
│  ┌────────────────────────────────────────────────────────┐  │
│  │ _handleMidiData:                                       │  │
│  │  - Parse packet                                        │  │
│  │  - Track signatures (7-bit: single, 14-bit: pair)     │  │
│  │  - Run value analysis for byte order (14-bit only)    │  │
│  │  - Apply 10-hit threshold                             │  │
│  │  - Emit typed detection event                         │  │
│  └────────────────────────────────────────────────────────┘  │
├─────────────────────────────────────────────────────────────┤
│                          ↑ MidiPacket stream                   │
│                          │                                     │
├─────────────────────────┴─────────────────────────────────────┤
│                      MidiCommand (flutter_midi_command)        │
│                        (MIDI hardware layer)                   │
└─────────────────────────────────────────────────────────────┘
```

### Component Responsibilities

| Component | Responsibility | Current State | Changes Needed |
|-----------|----------------|---------------|----------------|
| `MidiListenerCubit` | Detects MIDI events, tracks signatures, emits state | Tracks single-event signature (_lastEventSignature) | Add pair-tracking for 14-bit CCs, value analysis for byte order |
| `MidiListenerState` | Holds last detected event info | Has lastDetectedType, lastDetectedChannel, lastDetectedCc, lastDetectedNote | May need fields for 14-bit info (paired CC number, byte order) |
| `MidiEventType` enum | Identifies event type | Supports cc, noteOn, noteOff | Add cc14BitLowFirst, cc14BitHighFirst (or similar byte-order variants) |
| `MidiDetectorWidget` | Displays status, bridges cubit → callback | Passes (type, channel, number) to callback | No signature change — new types flow through existing callback |
| `PackedMappingDataEditor` | Consumes detection results, configures mapping | Maps MidiEventType.cc → MidiMappingType.cc | Map new 14-bit event types → cc14BitLow/cc14BitHigh with correct byte order |

## Architectural Patterns

### Pattern 1: Single vs. Pair Signature Tracking

**What:** Current code tracks one event signature (type, channel, number) and counts consecutive hits. 14-bit requires tracking two CC numbers as a pair signature (lowCC, highCC, channel) with consecutive hits of the **pair** pattern.

**When to use:** 14-bit detection requires recognizing that two CCs (X and X+32) are arriving in close succession and repeating together.

**Trade-offs:**
- **Pro:** Avoids false positives from unrelated CCs
- **Pro:** Same 10-hit threshold provides consistency
- **Con:** More complex state management (two CC numbers + value history)

**Example:**
```dart
// Current (single event):
({MidiEventType type, int channel, int number})? _lastEventSignature;
int _consecutiveCount = 0;

// Extended for 14-bit (pair signature):
({MidiEventType type, int channel, int number})? _lastEventSignature;  // Keep for 7-bit
({int channel, int lowCC, int highCC})? _last14BitSignature;
List<(int low, int high)> _last14BitValues = [];  // For value analysis
int _consecutiveCount = 0;
int _consecutive14BitCount = 0;
```

### Pattern 2: Value Analysis for Byte Order Detection

**What:** 14-bit MIDI standard specifies CC 0-31 (MSB) + CC 32-63 (LSB), combined as `(MSB << 7) | LSB`. However, some manufacturers (notably Yamaha) send LSB first. Value analysis observes multiple (low, high) value pairs and calculates both permutations to determine which interpretation produces coherent values.

**When to use:** After detecting a CC pair (X, X+32), collect values across multiple observations (e.g., 10 hits) and compare value interpretations.

**Trade-offs:**
- **Pro:** More reliable than arrival-order detection (packets may arrive out of order)
- **Pro:** Handles manufacturer variation (Yamaha vs. standard)
- **Con:** Requires buffering values across observations
- **Con:** Ambiguous if controller stays static (mitigation: require value variation)

**Example:**
```dart
// Collect observations:
_last14BitValues.add((lowValue, highValue));

// After threshold met, analyze:
bool detectByteOrder(List<(int, int)> observations) {
  // Compare (lowCC<<7|highCC) vs (highCC<<7|lowCC) interpretations
  // Look for monotonic trends, value coherence, or other heuristics
  // Return true if lowCC is MSB, false if highCC is MSB
}
```

### Pattern 3: Threshold Detection with Pair Consistency

**What:** The existing 10-hit threshold applies to single events. For 14-bit, apply the same threshold to **pairs** — require 10 consecutive observations of the same (lowCC, highCC) pair on the same channel before emitting detection.

**When to use:** Prevents false positives when two unrelated CCs happen to be 32 apart.

**Trade-offs:**
- **Pro:** Same UX consistency (10 hits = detection)
- **Pro:** Prevents accidental detection from coincidental CC numbers
- **Con:** Requires user to wiggle controller 10 times (already accepted for 7-bit)

## Data Flow

### 7-bit CC Detection Flow (Current)

```
[User wiggles CC X]
    ↓
[MidiPacket: 0xB0 | channel, X, value]
    ↓
_handleMidiData → parse statusByte, extract channel, CC number
    ↓
signature = (type: cc, channel: N, number: X)
    ↓
if signature == _lastEventSignature → _consecutiveCount++
else → reset _lastEventSignature, _consecutiveCount = 1
    ↓
if _consecutiveCount >= 10 → emit MidiListenerState.data(lastDetectedType: cc, lastDetectedCc: X, lastDetectedChannel: N)
    ↓
MidiDetectorWidget (BlocConsumer) → onMidiEventFound(type: cc, channel: N, number: X)
    ↓
PackedMappingDataEditor → set midiMappingType: cc, midiCC: X, midiChannel: N
```

### 14-bit CC Detection Flow (New)

```
[User wiggles 14-bit CC X + X+32]
    ↓
[MidiPacket stream: alternating CC X and CC X+32, same channel]
    ↓
_handleMidiData → parse each packet
    ↓
Detect pair: if CC Y arrives and (Y-32) or (Y+32) was seen recently on same channel
    ↓
Track pair signature: (channel: N, lowCC: min(X, X+32), highCC: max(X, X+32))
    ↓
if pair signature == _last14BitSignature → _consecutive14BitCount++, collect (lowValue, highValue)
else → reset _last14BitSignature, _consecutive14BitCount = 1, clear value buffer
    ↓
if _consecutive14BitCount >= 10 → run value analysis → determine byte order (lowFirst vs highFirst)
    ↓
emit MidiListenerState.data(lastDetectedType: cc14BitLowFirst (or cc14BitHighFirst), lastDetectedCc: lowCC, lastDetectedChannel: N)
    ↓
MidiDetectorWidget → onMidiEventFound(type: cc14BitLowFirst, channel: N, number: lowCC)
    ↓
PackedMappingDataEditor → set midiMappingType: cc14BitLow (or cc14BitHigh based on byte order), midiCC: lowCC (or highCC), midiChannel: N
```

### Parallel Detection (7-bit and 14-bit)

```
_handleMidiData receives CC packet
    ↓
    ├─→ Track as 7-bit signature (type: cc, channel, number) → threshold → emit if 7-bit pattern
    │
    └─→ Check for 14-bit pair (CC X ± 32 seen recently?) → track pair → threshold → analyze → emit if 14-bit pattern
```

**Key insight:** Both detection paths run in parallel. If a controller sends only CC X, 7-bit detection fires. If it sends X + X+32 pairs, 14-bit detection fires. The first to reach threshold wins.

## State Management

### Current MidiListenerState Structure

```dart
@freezed
sealed class MidiListenerState {
  const factory MidiListenerState.initial() = Initial;

  const factory MidiListenerState.data({
    @Default([]) List<MidiDevice> devices,
    MidiDevice? selectedDevice,
    @Default(false) bool isConnected,
    MidiEventType? lastDetectedType,        // cc, noteOn, noteOff
    int? lastDetectedChannel,               // 0-15
    int? lastDetectedCc,                    // 0-127
    int? lastDetectedNote,                  // 0-127
    DateTime? lastDetectedTime,
  }) = Data;
}
```

### Extended for 14-bit (Minimal Change Option)

**Option A: Reuse existing fields**
- `lastDetectedType` expanded to include `cc14BitLowFirst`, `cc14BitHighFirst`
- `lastDetectedCc` stores the lower CC number (e.g., CC 1 for pair 1+33)
- Byte order is encoded in the type variant
- **Pro:** No new fields, backward compatible
- **Con:** Consumers must interpret type to understand byte order

**Option B: Add explicit fields**
```dart
const factory MidiListenerState.data({
  // ... existing fields ...
  int? lastDetectedCcPair,     // Paired CC number (e.g., CC 33 when CC 1 is in lastDetectedCc)
  bool? lastDetectedByteOrderLowFirst,  // true = lowCC is MSB, false = highCC is MSB
}) = Data;
```
- **Pro:** Explicit byte order info
- **Con:** More fields, more state complexity

**Recommendation:** Option A (type-encoded byte order) for simplicity. The consumer (PackedMappingDataEditor) only needs to know which CC to store and which MidiMappingType to set. Byte order is implicit in the type.

### Extended MidiEventType Enum

```dart
enum MidiEventType {
  cc,               // 7-bit CC
  noteOn,
  noteOff,
  cc14BitLowFirst,  // 14-bit CC where lower CC number is MSB (standard)
  cc14BitHighFirst, // 14-bit CC where higher CC number is MSB (Yamaha-style)
}
```

**Alternative naming:**
```dart
enum MidiEventType {
  cc,
  noteOn,
  noteOff,
  cc14BitMsbLow,    // MSB is the lower CC number (standard: CC 1 = MSB, CC 33 = LSB)
  cc14BitMsbHigh,   // MSB is the higher CC number (reversed: CC 33 = MSB, CC 1 = LSB)
}
```

## Integration Points

### Existing Integration: MidiDetectorWidget → PackedMappingDataEditor

**Current callback signature:**
```dart
Function({
  required MidiEventType type,
  required int channel,
  required int number,  // CC or Note number
})? onMidiEventFound;
```

**Behavior with 14-bit types:**
- `type`: `cc14BitLowFirst` or `cc14BitHighFirst`
- `channel`: MIDI channel (0-15)
- `number`: The **lower** CC number in the pair (e.g., CC 1 for pair 1+33)

**Consumer logic in PackedMappingDataEditor (lines 683-717):**
```dart
onMidiEventFound: ({required type, required channel, required number}) {
  // Current logic for 7-bit CC and notes:
  MidiMappingType detectedMappingType = MidiMappingType.cc;
  if (type == MidiEventType.noteOn || type == MidiEventType.noteOff) {
    detectedMappingType = MidiMappingType.noteMomentary;  // or preserve existing note type
  }

  // NEW: Handle 14-bit CC types
  if (type == MidiEventType.cc14BitLowFirst) {
    detectedMappingType = MidiMappingType.cc14BitLow;  // Lower CC is MSB
  } else if (type == MidiEventType.cc14BitHighFirst) {
    detectedMappingType = MidiMappingType.cc14BitHigh;  // Higher CC is MSB
  }

  _data = _data.copyWith(
    midiMappingType: detectedMappingType,
    midiCC: number,  // Store the lower CC number
    midiChannel: channel,
    isMidiEnabled: true,
  );
}
```

**No signature change required** — existing callback parameters suffice. The type carries byte order information.

### Internal Boundary: Cubit Private State

| Component | Access | Communication |
|-----------|--------|---------------|
| `_handleMidiData` (packet parser) → pair detector | Private method | Direct field access to `_last14BitSignature`, `_last14BitValues` |
| Pair detector → value analyzer | Private method | Pass `List<(int, int)>` of observations |
| Value analyzer → state emitter | Private method | Return `MidiEventType` variant (cc14BitLowFirst or cc14BitHighFirst) |

**Design principle:** All detection logic stays private in `MidiListenerCubit`. Widget layer only consumes emitted state.

## Anti-Patterns

### Anti-Pattern 1: Arrival Order Detection

**What people do:** Detect byte order based on which CC message arrives first (assume first = MSB).

**Why it's wrong:**
- MIDI packet buffering may reorder messages
- USB MIDI has timing jitter
- Manufacturer variation (Yamaha sends LSB first, most send MSB first)
- User wiggling controller may produce inconsistent arrival order

**Do this instead:** Use **value analysis** — observe the 14-bit values over multiple observations and determine which interpretation (low-as-MSB vs high-as-MSB) produces coherent results. For example:
- Check if values are monotonic in one interpretation but jumpy in the other
- Require value variation across observations (static controller = ambiguous)
- Compare statistical variance of interpretations

### Anti-Pattern 2: Global Pair Tracking Across Channels

**What people do:** Track CC pairs globally without channel isolation, e.g., "if CC 1 and CC 33 are seen anywhere, assume 14-bit."

**Why it's wrong:**
- Different controllers on different channels may use overlapping CC numbers
- False positives when two 7-bit controllers happen to use CCs 32 apart
- Confuses user when channel A affects detection for channel B

**Do this instead:** Track pair signatures **per channel** — `(channel, lowCC, highCC)` as the signature. Reset if channel changes.

### Anti-Pattern 3: Exposing Byte Order to UI Layer

**What people do:** Add dropdown in UI for "select byte order: MSB-first or LSB-first."

**Why it's wrong:**
- Adds user friction (most users don't know what MSB/LSB means)
- Detection should be automatic — that's the value proposition
- Defeats the purpose of auto-detection

**Do this instead:** Encode byte order in the detected `MidiEventType`. The UI doesn't need to know about byte order — it just maps type → MidiMappingType.

## Build Order (Phased Implementation)

### Phase 1: Extend Type System (Non-Breaking)
1. Add `cc14BitLowFirst`, `cc14BitHighFirst` to `MidiEventType` enum
2. Regenerate Freezed code for `MidiListenerState`
3. Update `PackedMappingDataEditor` to handle new types (map to existing `cc14BitLow`/`cc14BitHigh`)
4. **Verify:** Existing 7-bit CC and note detection still works unchanged

### Phase 2: Add Pair Tracking State
1. Add private fields to `MidiListenerCubit`:
   - `_last14BitSignature`
   - `_last14BitValues` buffer
   - `_consecutive14BitCount`
2. **Verify:** No behavioral change yet (fields unused)

### Phase 3: Implement Pair Detection Logic
1. In `_handleMidiData`, after parsing CC packet:
   - Check if current CC ± 32 matches a recently seen CC on same channel
   - If yes, update `_last14BitSignature` and collect values
   - Increment `_consecutive14BitCount` if signature matches
2. **Verify:** Can detect pairs in logs (don't emit yet)

### Phase 4: Implement Value Analysis
1. Create `_analyzeByteOrder(List<(int, int)> observations) -> bool` method
2. Compare (lowCC<<7|highCC) vs (highCC<<7|lowCC) interpretations
3. Return `true` if lowCC is MSB, `false` if highCC is MSB
4. **Verify:** Correctly identifies byte order in test cases

### Phase 5: Emit 14-bit Detection Events
1. When `_consecutive14BitCount >= 10`:
   - Run value analysis
   - Emit `MidiListenerState.data` with appropriate `cc14Bit*` type
   - Reset counters
2. **Verify:** Full flow works — wiggle 14-bit CC → detector fires → mapping auto-fills

### Phase 6: Handle Edge Cases
1. Reset 14-bit state when device disconnects
2. Handle transition from 7-bit to 14-bit (user switches controllers)
3. Require value variation for byte order analysis (static = fallback to standard)
4. **Verify:** No false positives, graceful fallback

## Key Design Decisions

### Decision 1: Parallel 7-bit and 14-bit Detection

**Rationale:** Don't break existing 7-bit detection. Run both detection paths in `_handleMidiData`. First to reach threshold emits.

**Implementation:** Track both `_lastEventSignature` (7-bit) and `_last14BitSignature` (14-bit pair) simultaneously. Each has its own consecutive count.

### Decision 2: Type-Encoded Byte Order

**Rationale:** Minimize state complexity. Byte order is part of the event type, not a separate field.

**Implementation:** `MidiEventType.cc14BitLowFirst` means "lower CC is MSB", `cc14BitHighFirst` means "higher CC is MSB". Consumer maps directly to `MidiMappingType`.

### Decision 3: Value Analysis Over Arrival Order

**Rationale:** Arrival order is unreliable (manufacturer variation, packet jitter). Value analysis is more robust.

**Implementation:** Buffer 10 (lowValue, highValue) pairs. Compare coherence of `(low<<7|high)` vs `(high<<7|low)`. Choose interpretation with better characteristics (monotonicity, variance, etc.).

### Decision 4: No Signature Change for Callback

**Rationale:** Existing `onMidiEventFound(type, channel, number)` callback already supports arbitrary `MidiEventType` variants. Adding new types doesn't break the interface.

**Implementation:** Pass lower CC number in `number` parameter. Consumer uses `type` to determine which `MidiMappingType` to apply.

## Sources

- [MIDI Control Change Controllers & 14-Bit Resolution Explained](https://magazine.ediary.site/blog/midi-control-change-controllers-and)
- [MIDI MSB/LSB Explained | redconfetti](https://redconfetti.com/music-production/2024/03/18/midi-msb-lsb-explained.html)
- [MIDI Specification: Controller Numbers](http://midi.teragonaudio.com/tech/midispec/ctllist.htm)
- [What is MSB and LSB? - MIDI - User Forum - Morningstar Engineering](https://forum.morningstar.io/t/what-is-msb-and-lsb/106)
- Existing codebase:
  - `/Users/nealsanche/nosuch/nt_helper/lib/ui/midi_listener/midi_listener_cubit.dart`
  - `/Users/nealsanche/nosuch/nt_helper/lib/ui/midi_listener/midi_listener_state.dart`
  - `/Users/nealsanche/nosuch/nt_helper/lib/ui/widgets/packed_mapping_data_editor.dart`
  - `/Users/nealsanche/nosuch/nt_helper/lib/models/packed_mapping_data.dart`

---
*Architecture research for: 14-bit MIDI CC auto-detection integration*
*Researched: 2026-01-31*
