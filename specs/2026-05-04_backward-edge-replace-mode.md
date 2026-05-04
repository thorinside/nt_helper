# Detect backward-edge connections with Replace output mode

## Context

PR #126 (commit `9c2583e`) introduced distinct orange-dotted styling for
"backward edges" — algorithm-to-algorithm connections where the writer's
slot index is *higher* than the reader's. The Disting NT processes slots
in increasing order, so when slot 2 writes to a bus that slot 1 reads,
slot 1 sees the value slot 2 wrote on the *previous* audio block (because
internal/aux buses retain their last-written value across blocks). PR #126
flagged these connections with a `kBackwardEdgeColor` (`#FF8800`) dotted
stroke and no endpoint circles, so the user can recognise feedback edges
at a glance.

That painter change works correctly. However, an earlier change to the
discovery service silently breaks the visual contract for one specific
configuration: **backward-edge writers in Replace output mode**.

### Reproduction (from a user screenshot)

- Slot 1: Attenuverter, with `1:Input` reading bus A1 (an aux bus, value 21).
- Slot 2: VCO – Waveshaping, with `Sub output` writing bus A1 in **Replace**
  mode.
- Expected: a single orange dotted line connecting `Sub output` → `1:Input`,
  flagged as a backward edge (writer slot 2 > reader slot 1).
- Actual: no port-to-port line is drawn. Two separate "ghost" bus-label
  chips appear — `A1 R` next to `Sub output`, `A1` next to `1:Input` —
  each connected to its own port by a short dashed grey stub.

If slot 2 writes A1 in **Add** mode instead, the backward edge renders
correctly. The bug is specific to Replace mode.

## Root cause

`lib/core/routing/connection_discovery_service.dart` lines 122–123 (commit
`fcd4d50` — "feat: firmware-aware ES-5 bus routing and extended aux bus
support") added an output-mode guard to the backward-edge branch:

```dart
} else if (!isForward &&
           output.outputMode != OutputMode.replace) {
  // Backward connection: writer is in a higher slot than reader.
  // Skip when the writer uses Replace — the replaced value won't
  // propagate upward, so the backward edge is irrelevant.
```

The original commit that introduced backward-edge discovery (`dd7811d`)
had `else if (!isForward)` with **no** output-mode check. The Replace-mode
skip is therefore a regression introduced incidentally by `fcd4d50`,
not covered by tests on either side of the change.

The comment's reasoning — "the replaced value won't propagate upward" —
is wrong. Disting NT internal/aux bus values *persist across audio
frames*. When slot 2 writes A1 in Replace mode, that value sits on bus
A1 until the next processing frame begins. At the top of the next
frame, slot 1 runs first and reads the value slot 2 left there — i.e.,
the write fed back to the reader, just delayed by one audio block.
That is the definition of a backward / feedback edge. Add and Replace
differ only in how the writer combines with prior bus contents *in the
current frame*; neither mode prevents the bus from retaining its value
for the next frame's reader pass.

The visible failure mode is a knock-on effect: the Replace-mode skip
means the writer's output port and the reader's input port never get
added to `matchedPorts`. They then fall through to
`_createPartialConnections` (line 219), which manufactures two
`bus_${busNumber}_endpoint` "chip" connections with `isPartial: true`.
Because `classifyVisualType` (`connection_painter.dart` lines 124–128)
checks `isPartial` *before* `isInvalidOrder` (≡ `isBackwardEdge`), these
partial connections render as `partial`, not `invalid`. Producing a
non-partial backward-edge `Connection` from the discovery service is the
only path that reaches the orange-dotted style.

## Goal

When the discovery service sees a non-physical, non-self bus assignment
where the writer's slot index is greater than the reader's, it must
produce a single port-to-port `Connection` with `isBackwardEdge: true`
and `isPartial: false`, regardless of `outputMode`. The painter (PR #126)
will then style it as orange dotted.

## Scope

### In scope

- One-line change to `lib/core/routing/connection_discovery_service.dart`
  (drop the Replace-mode clause; rewrite the comment).
- Discovery-side unit tests in
  `test/core/routing/connection_discovery_service_test.dart`.
- Manual verification with the user's repro setup.

### Out of scope

- **Painter changes.** PR #126 already finalised the orange-dotted
  appearance. Do not touch `connection_painter.dart`.
- **Hardware-bus paths.** The bug is confined to the algo→algo branch
  (line 88 guard `!isPhysicalBusWithOutputs`). Physical buses (1–12, 13–20)
  and ES-5 buses route through hardware-node helpers and never enter
  this branch — backward-edge detection is N/A there.
- **Self-writes.** The existing `output.algorithmId == input.algorithmId`
  guard stays.
- **Contribution-aware backward edges.** `BusSessionResolver.contributorsForReader`
  only considers writers with slot < readerSlot, so it never reports a
  backward writer. The forward branch checks `isContributing`; the
  backward branch never has and this fix preserves that. Whether to
  also gate backward edges on a "would actually feed back next frame"
  analysis (e.g., suppress a backward Add when an earlier Replace will
  overwrite the bus before the reader runs next frame) is a separate
  design question — out of scope here, by explicit user direction
  ("matching `dd7811d`'s original behavior").
- **Mode-aware bus-label suffix.** `BusLabelFormatter.formatBusLabelWithMode`
  is not exercised when ports match, so it stays unchanged.
- **Cubit, MIDI, MCP, persistence.** Discovery is a pure function of
  the routing list.

## Files to change

### `lib/core/routing/connection_discovery_service.dart`

In the algo→algo loop, change the `else if` guard from

```dart
} else if (!isForward &&
           output.outputMode != OutputMode.replace) {
```

to

```dart
} else if (!isForward) {
```

and replace the body's comment with one that accurately describes the
trigger condition (writer slot > reader slot, on a non-physical shared
bus, between distinct algorithms — and that the reader sees the writer's
value one audio block later regardless of `OutputMode`). The body of
the branch (the `Connection(...)` constructor call and the two
`matchedPorts.add(...)` lines) is unchanged.

#### Note on null `outputMode`

`OutputMode?` is nullable. The current expression `output.outputMode !=
OutputMode.replace` evaluates to `true` when `outputMode` is `null`, so
null-mode backward writers are *already* detected today. Removing the
clause does not change null-mode behaviour; it only changes behaviour
when `outputMode == OutputMode.replace`.

### `test/core/routing/connection_discovery_service_test.dart`

The existing `_outPort` helper (lines 63–76) does not accept an
`outputMode` parameter. Extend it with an optional named param
`core.OutputMode? mode` and forward it to `core.Port(... outputMode:
mode)`. (`bus_session_discovery_test.dart`'s `_outPort` already follows
this shape — same idea.)

Add a new `group('backward-edge discovery', ...)` block at the end of
the existing `group('ConnectionDiscoveryService', ...)` covering:

1. **Replace + backward** (regression test). Bus 25 (aux, non-physical).
   Routings list `[reader, writer]` so `reader.algorithmIndex == 0` and
   `writer.algorithmIndex == 1`. Writer port has `OutputMode.replace`.
   Assert exactly one `Connection` exists with `connectionType ==
   ConnectionType.algorithmToAlgorithm`, `isBackwardEdge == true`,
   `isPartial == false`, `outputMode == OutputMode.replace`, `sourcePortId
   == writer.portId`, `destinationPortId == reader.portId`. Assert no
   `Connection` exists with `isPartial == true` whose source or
   destination is either of those ports.

2. **Add + backward** (non-regression). Same topology, `OutputMode.add`.
   Same assertions (with `outputMode == OutputMode.add`).

3. **Replace + forward** (non-regression). Routings list `[writer,
   reader]` so `writer.algorithmIndex == 0` and `reader.algorithmIndex
   == 1`. Writer in `OutputMode.replace`. Assert a forward `Connection`
   exists with `isBackwardEdge == false`, `isPartial == false`. Confirms
   the fix didn't accidentally re-classify forward connections.

4. **Self-write**. A single algorithm whose `algorithmUuid` is shared by
   both an output port (bus 25, any mode) and an input port (bus 25).
   Assert no `algorithmToAlgorithm` connection exists between those two
   ports. The existing `output.algorithmId == input.algorithmId` guard
   should still skip the pair.

5. **Multiple backward Replace writers, single reader** (defensive).
   Routings list `[reader, writer1, writer2]` all on bus 25, both
   writers in `OutputMode.replace`. Assert two backward `Connection`s
   are produced — one per (writer, reader) pair — both with
   `isBackwardEdge == true` and `isPartial == false`. Locks in the
   per-pair behaviour matching `dd7811d`, so a future change that adds
   contribution-aware filtering becomes a deliberate, test-visible
   decision rather than a silent regression.

Use bus 25 (Aux 5) consistently to avoid the physical-bus and ES-5
codepaths.

### Manual verification (record before/after in PR description)

Build the user's repro: slot 1 Attenuverter `1:Input` on bus A1, slot 2
VCO `Sub output` on bus A1 in **Replace**. Expected: one orange dotted
line from `Sub output` → `1:Input`; no `A1 R` / `A1` ghost chips.
Then switch slot 2 to **Add** mode and reload — same orange dotted line,
no chips. (The Add case worked before this fix; verifying it didn't
regress.)

## Risk and rollback

The fix re-enables backward-edge `Connection`s for Replace-mode writers.
For any preset that has a higher-slot Replace writer feeding a lower-slot
reader on a non-physical bus, the routing editor will now render a
single orange dotted line where it currently renders two ghost chips.
No MIDI is sent, no parameter is changed; signal flow is unaffected.

Rollback is reverting the one-line change. The new tests will fail on
revert, which is the intended guard.

## PR plan

- Branch: `fix/backward-edge-replace-mode`.
- Title: `fix: detect backward-edge connections with Replace output mode`.
- Body: includes the user's repro, explains bus persistence across
  frames, links the regression to commit `fcd4d50`, references PR #126
  as the painter side this fix completes for the Replace path, and lists
  the new unit tests. Before/after screenshots (Replace and Add) attached.
