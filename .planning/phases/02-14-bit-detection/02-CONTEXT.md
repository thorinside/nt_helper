# Phase 2: 14-Bit Detection - Context

**Gathered:** 2026-01-31
**Status:** Ready for planning

<domain>
## Phase Boundary

Implement 14-bit CC pair detection logic that runs in parallel with existing 7-bit detection. The detector identifies CC pairs (X and X+32), tracks pair hits toward a 10-hit threshold, analyzes values to determine byte order, and emits the correct 14-bit MidiEventType. Reserved CCs (CC0/CC32 Bank Select) are excluded. This phase modifies the detection logic inside the cubit; UI integration is Phase 3.

</domain>

<decisions>
## Implementation Decisions

### Pair tracking mechanics
- Eager pairing: As soon as CC X and CC X+32 are both seen on the same channel, they form a pair immediately
- Single pair lock: Once a pair is formed, other potential pairs are ignored until detection completes or resets
- Lock on first pair seen (no waiting for 2-3 hits before committing)
- Same channel only: CC X and CC X+32 must arrive on the same MIDI channel to form a pair

### Hit counting
- Both seen = 1 hit: A pair hit only increments when both CC X and CC X+32 have been received (in any order)
- A single MSB or LSB alone does not increment the pair hit counter
- 10-hit threshold (same as 7-bit, per requirements)

### Value analysis approach
- Collect value data as pair hits accumulate toward threshold (analyze during, not just at the end)
- By the time 10-hit threshold is reached, 10 MSB+LSB value pairs are available for analysis
- Byte order determination is purely from value analysis — CC numbers are not used as a hint
- "Default to MSB-first" (from requirements) means: when value analysis is ambiguous, assume standard interpretation (lower CC = MSB, higher CC = LSB)

### Detection reset behavior
- Match existing 7-bit detector behavior for reset triggers and post-emit behavior
- When 7-bit wins the race, discard all 14-bit pair tracking state completely
- When 14-bit wins, follow same post-emit pattern as 7-bit

### Claude's Discretion
- Statistical method for byte order determination (variance comparison, range analysis, or other approach)
- Definition of "ambiguous" for byte order analysis (threshold values, criteria)
- Internal data structures for pair tracking state
- How pair hit counting interleaves with 7-bit hit counting in the existing detection loop

</decisions>

<specifics>
## Specific Ideas

- Detection should feel instant to the user — same responsiveness as current 7-bit detection
- The parallel race between 7-bit and 14-bit should be invisible to the user; they just get the right result
- Standard MIDI 14-bit convention: CC 0-31 paired with CC 32-63, where typically lower CC is MSB

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 02-14-bit-detection*
*Context gathered: 2026-01-31*
