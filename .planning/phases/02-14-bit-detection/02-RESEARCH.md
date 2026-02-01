# Phase 2: 14-Bit Detection - Research

**Researched:** 2026-01-31
**Domain:** MIDI 14-bit Control Change detection and byte order analysis
**Confidence:** MEDIUM

## Summary

14-bit MIDI CC detection requires parallel tracking of CC pairs (X and X+32) where 0 ≤ X ≤ 31, accumulating pair hits to a 10-hit threshold while running concurrently with existing 7-bit detection. The standard MIDI specification pairs CC 0-31 (MSB) with CC 32-63 (LSB), but real-world implementations vary in byte order. Statistical analysis of collected value pairs is required to determine whether lower CC numbers represent MSB or LSB.

The primary technical challenge is maintaining two independent detection paths within a single-threaded event handler, where either 7-bit or 14-bit can win the race to threshold. Byte order determination must rely on value analysis rather than arrival order, as manufacturers like Yamaha, Alesis, and Akai transmit bytes in reverse order from the MIDI standard.

**Primary recommendation:** Extend the existing consecutive-hit detection pattern with parallel pair-tracking state. Use variance ratio analysis on collected value samples to determine byte order, defaulting to MSB-first (standard) when variance difference is below a confidence threshold.

## Standard Stack

The established libraries/tools for this domain:

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| flutter_midi_command | (existing) | MIDI message parsing | Already integrated; provides raw MIDI packets |
| Dart core | 3.0+ | State machine, async/await | Native language features for detection logic |
| freezed | (existing) | Immutable state | Already used for MidiListenerState |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| dart:math | stdlib | Statistical calculations | Variance computation for byte order |
| collection | stdlib | List manipulation | Managing hit tracking data |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Variance ratio | Range analysis | Simpler but less robust with partial fader movement |
| Variance ratio | Arrival order timing | Hardware inconsistent; rejected per CONTEXT.md |
| Inline detection | State machine library | Overhead not justified; existing pattern is simple |

**Installation:**
No additional packages required — all tools available in current stack.

## Architecture Patterns

### Recommended State Structure
Extend existing `_handleMidiData` method with parallel tracking:

```dart
// Current 7-bit state
({MidiEventType type, int channel, int number})? _lastEventSignature;
int _consecutiveCount = 0;

// New 14-bit state (parallel)
_PairTracker? _activePair;  // null when no pair locked
Map<int, _CcValue> _channelCcState;  // Track all CCs per channel
```

### Pattern 1: Parallel Race Detection
**What:** Two independent detection paths accumulating hits simultaneously; first to threshold wins and resets both.

**When to use:** Multiple detection strategies compete for the same input stream.

**Example:**
```dart
// Per MIDI packet:
// 1. Update 7-bit tracker (existing)
if (currentEventSignature == _lastEventSignature) {
  _consecutiveCount++;
} else {
  _lastEventSignature = currentEventSignature;
  _consecutiveCount = 1;
}

// 2. Update 14-bit pair tracker (new)
_updatePairTracker(channel, ccNumber, ccValue);

// 3. Check thresholds (both)
final cc7BitReached = _consecutiveCount >= kThreshold;
final cc14BitReached = _activePair?.hitCount >= kThreshold;

// 4. First to win emits and resets both
if (cc14BitReached) {
  _emit14BitDetection();
  _reset7BitState();
  _reset14BitState();
} else if (cc7BitReached) {
  _emit7BitDetection();
  _reset14BitState();
  _reset7BitState();
}
```

### Pattern 2: Eager Pair Lock
**What:** As soon as CC X and CC X+32 both appear on same channel, lock that pair and ignore other potential pairs.

**When to use:** Simplifies state when only one active mapping expected per channel.

**Example:**
```dart
void _updatePairTracker(int channel, int cc, int value) {
  // Store this CC's latest value
  _channelCcState[(channel, cc)] = (value: value, timestamp: now);

  // If no active pair, check for pairable CC
  if (_activePair == null && cc < 32) {
    final partner = cc + 32;
    if (_channelCcState.containsKey((channel, partner))) {
      // Found both halves — lock the pair
      _activePair = _PairTracker(
        channel: channel,
        lowCc: cc,
        highCc: partner,
        hitCount: 0,
        valueSamples: [],
      );
    }
  }

  // If pair active and this CC matches, record pair hit
  if (_activePair != null &&
      _activePair.channel == channel &&
      (cc == _activePair.lowCc || cc == _activePair.highCc)) {

    final low = _channelCcState[(_activePair.channel, _activePair.lowCc)];
    final high = _channelCcState[(_activePair.channel, _activePair.highCc)];

    // Both must be present to count as a hit
    if (low != null && high != null) {
      _activePair.hitCount++;
      _activePair.valueSamples.add((low: low.value, high: high.value));
    }
  }
}
```

### Pattern 3: Variance Ratio Byte Order Analysis
**What:** Compare variance of low vs high CC values to determine which changes more (likely LSB).

**When to use:** After collecting 10 value pairs, need to determine MSB/LSB assignment.

**Example:**
```dart
MidiEventType _determineByteOrder(List<({int low, int high})> samples) {
  // Calculate variance for low CC values
  final lowValues = samples.map((s) => s.low).toList();
  final lowMean = lowValues.reduce((a, b) => a + b) / lowValues.length;
  final lowVariance = lowValues
      .map((v) => pow(v - lowMean, 2))
      .reduce((a, b) => a + b) / lowValues.length;

  // Calculate variance for high CC values
  final highValues = samples.map((s) => s.high).toList();
  final highMean = highValues.reduce((a, b) => a + b) / highValues.length;
  final highVariance = highValues
      .map((v) => highMean - v, 2))
      .reduce((a, b) => a + b) / highValues.length;

  // Compare: higher variance indicates LSB (more frequent changes)
  final varianceRatio = lowVariance / (highVariance + 1.0); // +1 avoids div-by-zero

  // If variance difference is significant, assign based on which varies more
  const ambiguityThreshold = 0.8;  // Within 20% = ambiguous

  if (varianceRatio > 1.0 / ambiguityThreshold) {
    // Low CC varies more → low CC is LSB → high CC is MSB
    return MidiEventType.cc14BitHighFirst;
  } else if (varianceRatio < ambiguityThreshold) {
    // High CC varies more → high CC is LSB → low CC is MSB
    return MidiEventType.cc14BitLowFirst;
  } else {
    // Ambiguous → default to standard (low CC = MSB)
    return MidiEventType.cc14BitLowFirst;
  }
}
```

### Anti-Patterns to Avoid
- **Arrival order timing:** Manufacturers send bytes in inconsistent order; timing is unreliable.
- **Single global threshold:** 7-bit and 14-bit must track independently to race properly.
- **Premature pair commitment:** Wait until both CCs seen before locking pair (eager but not blind).
- **Ignoring Bank Select:** CC0/CC32 must be excluded from 14-bit pairing per MIDI spec.

## Don't Hand-Roll

Problems that look simple but have existing solutions:

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Variance calculation | Custom accumulator | dart:math + inline | Numerical stability; tested formula |
| 14-bit value calc | Manual bit shifting | Standard `(msb << 7) \| lsb` | Universal pattern; well-tested |
| State reset logic | Per-case conditionals | Single reset method | Matches existing 7-bit pattern |

**Key insight:** The detection core should extend the existing pattern, not replace it. Leverage the proven consecutive-hit mechanism and mirror its reset behavior.

## Common Pitfalls

### Pitfall 1: Intermediate Value Glitches
**What goes wrong:** When crossing byte boundaries (e.g., 255→256), receiving MSB before LSB produces intermediate value 383 before settling to 256.

**Why it happens:** Two separate MIDI messages arrive in sequence; naive implementations output both.

**How to avoid:** Only emit 14-bit detection AFTER threshold reached, not on every pair hit. Cubit emits once per detection cycle.

**Warning signs:** Rapid value jumps during smooth fader movement during testing.

### Pitfall 2: Manufacturer Byte Order Variations
**What goes wrong:** Assuming standard MSB-first order fails with Yamaha/Alesis/Akai hardware sending LSB-first.

**Why it happens:** MIDI spec doesn't enforce transmission order, only CC pairing.

**How to avoid:** Use value analysis (variance ratio) instead of arrival order or CC number position.

**Warning signs:** Inverted fader behavior (moving up decreases parameter value).

### Pitfall 3: Bank Select False Positives
**What goes wrong:** CC0/CC32 (Bank Select) detected as 14-bit parameter mapping candidate.

**Why it happens:** They match the pairing rule (0 and 32) but serve a different MIDI function.

**How to avoid:** Explicitly exclude CC0/CC32 from pair tracking at detection entry point.

**Warning signs:** Users unable to set bank select mappings; detection fires on bank changes.

### Pitfall 4: Reset Race Conditions
**What goes wrong:** 7-bit wins race but 14-bit state not cleared; stale pair state affects next detection.

**Why it happens:** Forgetting to reset the non-winning detector's state.

**How to avoid:** Both detectors reset on ANY win (either 7-bit or 14-bit threshold reached).

**Warning signs:** Second detection attempt immediately succeeds with stale data.

### Pitfall 5: Variance Ambiguity on Static Values
**What goes wrong:** User holds fader steady during detection; both CCs show zero variance, byte order determination fails.

**Why it happens:** No value changes = no variance data to analyze.

**How to avoid:** Default to standard MSB-first interpretation when variance ratio near 1.0 (within ambiguity threshold).

**Warning signs:** Detection completes but wrong byte order on devices using non-standard order.

## Code Examples

Verified patterns from analysis:

### 14-bit Value Calculation (Standard)
```dart
// Source: Multiple MIDI forum discussions + official spec
int combine14Bit(int msb, int lsb) {
  return (msb << 7) | lsb;  // Range: 0-16383
}

// Inverse (for debugging/logging)
(int msb, int lsb) split14Bit(int value) {
  return (value >> 7, value & 0x7F);
}
```

### Pair Tracker Data Structure
```dart
// Internal tracking for active 14-bit pair
class _PairTracker {
  final int channel;
  final int lowCc;    // Lower CC number (0-31)
  final int highCc;   // Higher CC number (32-63)
  int hitCount;
  final List<({int low, int high})> valueSamples;

  _PairTracker({
    required this.channel,
    required this.lowCc,
    required this.highCc,
    this.hitCount = 0,
    List<({int low, int high})>? valueSamples,
  }) : valueSamples = valueSamples ?? [];
}

// Per-channel CC state
typedef _CcValue = ({int value, DateTime timestamp});
```

### Reset Pattern (Mirroring 7-bit)
```dart
// Source: Existing midi_listener_cubit.dart pattern
void _reset7BitState() {
  _consecutiveCount = 0;
  _lastEventSignature = null;
}

void _reset14BitState() {
  _activePair = null;
  // Keep _channelCcState for next detection cycle
  // (allows immediate re-detection if user keeps moving fader)
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Timing windows | Value analysis | Per CONTEXT.md decision | Simpler implementation, hardware-agnostic |
| User mode selection | Auto-detection | Per STATE.md decision | Reduced user friction |
| Global detection | Per-channel tracking | MIDI best practice | Supports multi-channel controllers |
| Arrival order | Variance analysis | Research finding | Handles Yamaha/Alesis/Akai correctly |

**Deprecated/outdated:**
- Timing window approach: Rejected per user discussion; CC number tracking sufficient
- User-selected 7-bit vs 14-bit mode: Auto-detection makes this unnecessary

## Open Questions

Things that couldn't be fully resolved:

1. **Variance threshold calibration**
   - What we know: Ratio comparison works in principle; 0.8-1.25 range likely ambiguous
   - What's unclear: Optimal threshold value (needs real-world testing with hardware)
   - Recommendation: Start with 0.8 (20% margin); adjust based on Phase 2 testing

2. **Partial fader movement detection**
   - What we know: User might move fader <10% during detection
   - What's unclear: Will variance be sufficient with small value ranges?
   - Recommendation: Range normalization may help (divide variance by value range); test during implementation

3. **CC state retention across detections**
   - What we know: Clearing all CC state on reset could slow re-detection
   - What's unclear: Memory impact of retaining per-channel CC map indefinitely
   - Recommendation: Keep CC state; it's bounded (128 CCs × 16 channels = 2048 max entries, ~16KB)

4. **Multi-pair scenarios**
   - What we know: Single pair lock simplifies logic
   - What's unclear: Edge case where user has TWO 14-bit pairs on same channel (rare but possible)
   - Recommendation: Current single-pair approach is sufficient; complex multi-pair tracking can be future enhancement if needed

## Sources

### Primary (HIGH confidence)
- MIDI 1.0 specification (14-bit CC pairing: CC 0-31 MSB with CC 32-63 LSB)
- Existing codebase: /Users/nealsanche/nosuch/nt_helper/lib/ui/midi_listener/midi_listener_cubit.dart (7-bit detection pattern established)
- Phase 1 implementation: /Users/nealsanche/nosuch/nt_helper/test/ui/midi_listener/midi_listener_state_test.dart (MidiEventType enum with cc14BitLowFirst/cc14BitHighFirst)

### Secondary (MEDIUM confidence)
- [MIDI Control Change Controllers & 14-Bit Resolution Explained](https://magazine.ediary.site/blog/midi-control-change-controllers-and)
- [Receiving 14-bit MIDI CC messages - Pure Data forum](https://forum.pdpatchrepo.info/topic/14431/receiving-14-bit-midi-cc-messages) — byte order issues, Yamaha reverse order
- [14-Bit MIDI input - BeepStreet forums](https://forum.beepstreet.com/discussion/2217/14-bit-midi-input)
- [MIDI MSB/LSB Explained - redconfetti](https://redconfetti.com/music-production/2024/03/18/midi-msb-lsb-explained.html)
- [MIDI CC Lists - Nick Fever](https://nickfever.com/music/midi-cc-list) — CC0/CC32 Bank Select
- [StudioCode - MIDI CC numbers](https://studiocode.dev/resources/midi-cc/)

### Tertiary (LOW confidence)
- [Bit numbering - Wikipedia](https://en.wikipedia.org/wiki/Bit_numbering) — MSB/LSB concept (general computing, not MIDI-specific)
- [Dart statemachine package](https://pub.dev/packages/statemachine) — not needed per pattern analysis
- [Flutter State Management 2026](https://foresightmobile.com/blog/best-flutter-state-management) — Cubit already in use

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — existing Flutter/Dart tools sufficient; no new dependencies
- Architecture: MEDIUM — patterns derived from existing code + MIDI forums; needs implementation validation
- Pitfalls: MEDIUM — well-documented in MIDI community but variance threshold needs testing

**Research date:** 2026-01-31
**Valid until:** 2026-03-31 (60 days; MIDI spec stable, implementation patterns mature)
