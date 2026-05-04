# Multi-select algorithms in the Add Algorithm screen

## Context

`AddAlgorithmScreen` (`lib/ui/add_algorithm_screen.dart`) is the modal route
through which the user chooses an algorithm to append to the current preset.
Today it is strictly single-select: tracking state in
`String? selectedAlgorithmGuid` (line 71), `_currentAlgoInfo` (line 72), and a
single `List<int>? specValues` (line 73). The "Add to Preset" button pops the
route with a `Map` of one `algorithm` + one `specValues` (lines 1402–1407);
two callers in `synchronized_screen.dart` (lines 680–702 and 905–928) read
that result and call `cubit.onAlgorithmSelected(algo, specValues)` once.

A user building a preset of 5–10 algorithms must therefore reopen the picker,
re-search/scroll/filter, and re-tap "Add" once per algorithm. Each round trip
also triggers an optimistic emit + verification fetch in
`onAlgorithmSelectedImpl` (`lib/cubit/disting_cubit_algorithm_ops.dart:74-201`),
so the user sees a sequence of placeholders settle one at a time even when
the intent was clearly "give me these five."

This spec adds a multi-select mode to the picker so a user can mark several
algorithms in one pass and have them all appended in slot order with one
return to the synchronized screen. The hardware MIDI protocol still adds one
algorithm at a time (`requestAddAlgorithm` in
`lib/domain/i_disting_midi_manager.dart:69-72`); batching is purely a
client-side ergonomics improvement on top of the existing single-add path.

The implementation is constrained by three pre-existing realities:

1. **Specifications are per-algorithm.** Each `AlgorithmInfo` may declare 0..N
   integer specifications (`specifications` field, with min/max/default per
   spec — see `_buildSpecificationInputs`, line 1286). In single-select mode
   the user can edit them before tapping Add. In multi-select mode the user
   has not been shown a spec editor for each algorithm. The spec must define
   how spec values are sourced for batch adds.
2. **Plugins must be loaded before specs are accurate.** Community plugins
   (`_isPlugin`, line 234) start as unloaded with stub specifications, and
   the user can tap "Load Plugin" (line 1392) to fetch real specs over MIDI.
   In single-select today, the action button literally swaps to "Load Plugin"
   when the selected algorithm is unloaded.
3. **Preset slot cap.** A preset can hold at most `MCPConstants.maxSlots = 32`
   algorithms (`lib/mcp/mcp_constants.dart:19`). The picker today does not
   guard this — the device just rejects subsequent adds. With batch we should
   not silently drop selections past the cap.

Goal: from `AddAlgorithmScreen`, a user can switch to a multi-select mode,
tick any number of algorithms, and tap a single "Add N to Preset" button that
returns to the synchronized screen and appends all of them in slot order
using each algorithm's per-spec defaults. Single-select remains the default
mode and behaves exactly as today.

---

## Approach

Five changes plus tests. The first is the only behavioral surface change to
the cubit; the rest is UI plumbing in `add_algorithm_screen.dart` and one
small update to each of the two `Navigator.push` call sites.

### 1. Add a batch entry point to the algorithm-ops mixin

**Files:** `lib/cubit/disting_cubit.dart`, `lib/cubit/disting_cubit_algorithm_ops.dart`

Add `onAlgorithmsSelectedImpl` that takes a list of `(AlgorithmInfo, List<int>)`
pairs and adds them sequentially:

```dart
Future<void> onAlgorithmsSelectedImpl(
  List<({AlgorithmInfo algorithm, List<int> specifications})> entries,
) async {
  for (final entry in entries) {
    final st = state;
    if (st is! DistingStateSynchronized) return; // disconnected / device-select
    if (st.slots.length >= MCPConstants.maxSlots) return; // cap reached
    await onAlgorithmSelectedImpl(entry.algorithm, entry.specifications);
  }
}
```

Sequential, awaiting each call — *not* parallel. Reasons:

- `onAlgorithmSelectedImpl` derives the new slot index from
  `syncstate.slots.length` (line 101) and emits an optimistic placeholder
  before sending MIDI. Two parallel calls would compute the same target
  slot index and emit conflicting optimistic states.
- The verification phase reconciles by fetching only the new slot
  (line 159). Sequencing keeps each verification scoped to one slot.
- Hardware ordering: the user expects the first ticked algorithm to be the
  lower-numbered slot. `requestAddAlgorithm` always appends, so preserving
  call order preserves user-intended order.

**Interruption semantics.** The per-iteration `state is! DistingStateSynchronized`
check is sufficient to abort cleanly on:

- device disconnect (state transitions to `DistingStateConnected` or
  `DistingStateInitial`),
- the user navigating away (state remains `DistingStateSynchronized` but the
  cubit may be torn down — `await` resolves and the next iteration's state
  read is a `DistingStateSynchronized` of a fresh state, which is fine).

Mid-batch hardware errors are already absorbed by `onAlgorithmSelectedImpl`
which rolls back its optimistic placeholder on `requestAddAlgorithm` throw
(line 122) but does *not* rethrow — so the batch loop continues to the next
entry. This is the desired behavior: one bad algorithm should not abort the
remaining adds. Document this explicitly via a comment in the loop body.

The slot-cap re-check inside the loop covers the case where verification of
a previous add ends up not adding a slot (e.g. firmware rejected it), so the
next iteration sees `slots.length` smaller than the loop's caller computed
and proceeds correctly.

Expose via `DistingCubit.onAlgorithmsSelected` in `disting_cubit.dart`
alongside the existing `onAlgorithmSelected` (line 411):

```dart
Future<void> onAlgorithmsSelected(
  List<({AlgorithmInfo algorithm, List<int> specifications})> entries,
) async {
  return onAlgorithmsSelectedImpl(entries);
}
```

Keep `onAlgorithmSelected` exactly as today — no breaking change.

### 2. Add a multi-select mode toggle to `AddAlgorithmScreen`

**File:** `lib/ui/add_algorithm_screen.dart`

Introduce a mode flag and selection set alongside the existing single-select
state. **Both modes coexist** — the existing `selectedAlgorithmGuid` /
`_currentAlgoInfo` / `specValues` remain authoritative for single-select; a
new `Set<String> _selectedGuids` is authoritative for multi-select.

```dart
// new state
bool _multiSelectMode = false;
final Set<String> _selectedGuids = {};
```

Add an `IconButton` to the AppBar `actions` (between the `Refresh` and `Help`
buttons, ~line 478) that toggles `_multiSelectMode`. Icon: `Icons.checklist`
when off, filled accent when on. Tooltip: "Multi-select" / "Exit
multi-select". Toggling **off** clears `_selectedGuids` (no need to re-run
`_filterAlgorithms` — the filter is unaffected by selection state); toggling
**on** clears the single-select state via `_clearSelection()` (line 337).

When the preset is already at cap (`slots.length >= MCPConstants.maxSlots`),
the toggle button is rendered with `onPressed: null` and a tooltip
explaining "Preset full · remove an algorithm to enable multi-select." This
prevents the user from entering multi-select only to be hit with a cap
SnackBar on every tick attempt.

`_multiSelectMode` and `_selectedGuids` are **in-memory only**. The mode
resets to off each time the screen opens. Persisting the toggle and not the
selection would be confusing (user reopens to an empty multi-select view);
persisting the selection would be confusing (selection becomes stale across
preset changes). Picking neither is the simplest correct option.

A `Set<String>` cannot hold duplicates — if a user wants two of the same
algorithm in a preset, they use single-select twice or repeat the multi-add
flow. Document this in the help dialog (step 5).

### 3. Render the picker with multi-select affordances

**File:** `lib/ui/add_algorithm_screen.dart`

#### Chip grid view (`_buildChipGridView`, line 977)

When `_multiSelectMode`:

- Replace `ChoiceChip` with `FilterChip`. `FilterChip.selected` reads
  `_selectedGuids.contains(algo.guid)`. `onSelected` calls
  `_toggleMultiSelect(algo)` (defined below), which gates on cap + plugin
  state and announces the new aggregate count for screen readers.
- Long-press still toggles favorite (`_toggleFavorite`).
- `Semantics` `label`/`hint` adapt: the hint becomes
  `'Double tap to ${isSelected ? 'untick' : 'tick'}'` and the selected count
  is announced via `SemanticsService.sendAnnouncement` from
  `_toggleMultiSelect` ("3 of 32 selected" / "deselected, 2 of 32").

#### List view (`_buildListView`, line 1060)

When `_multiSelectMode`, prepend a leading `Checkbox` (or wrap the row in a
`CheckboxListTile`). Tap on the row toggles the checkbox via
`_toggleMultiSelect(algo)`; long-press still toggles favorite. The
`primaryContainer` background highlight is dropped in multi-select — the
checkbox is the selection signal.

#### Keyboard (`_handleKeyEvent`, line 867)

`_handleKeyEvent` already routes Space/Enter to `_selectAlgorithm` (line
890). In multi-select mode, redirect to `_toggleMultiSelect` for the focused
row. Arrow navigation is unchanged.

#### Filtering interaction (`_filterAlgorithms`, line 244)

When the filter changes such that previously-selected GUIDs are no longer
visible, **do not** clear them — they remain selected and will count toward
the batch. The "Showing N of M algorithms" label (line 645) gains a suffix
when in multi-select: `… · K selected` (where K may exceed the visible
count).

#### `_toggleMultiSelect` — the single source of truth for ticks

```dart
void _toggleMultiSelect(AlgorithmInfo algo) {
  final state = context.read<DistingCubit>().state;
  if (state is! DistingStateSynchronized) return;

  final isSelected = _selectedGuids.contains(algo.guid);

  // Untick is always allowed.
  if (isSelected) {
    setState(() => _selectedGuids.remove(algo.guid));
    _announceCount(removed: algo.name);
    return;
  }

  // Pre-tick guard: cap is "current preset slots + already-selected" — *not*
  // just slots.length — so back-to-back ticks across multiple filter changes
  // can't stack past 32.
  final projected = state.slots.length + _selectedGuids.length + 1;
  if (projected > MCPConstants.maxSlots) {
    final remaining = MCPConstants.maxSlots - state.slots.length - _selectedGuids.length;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Preset full · $remaining slot${remaining == 1 ? '' : 's'} remaining'),
      duration: const Duration(seconds: 2),
    ));
    return;
  }

  setState(() => _selectedGuids.add(algo.guid));
  _announceCount(added: algo.name);
}
```

The cap projection (`slots.length + _selectedGuids.length + 1`) addresses the
cross-filter stacking edge case: if the user filters to "Mixer", ticks two,
then filters to "Reverb" and tries to tick more, the projection accounts for
the Mixer ticks even though they are no longer visible.

Plugin-load state is **not** gated at tick time — see "Unloaded plugins" in
step 5. Ticking an unloaded plugin is allowed; the warning is a separate
banner above the action button.

#### Bottom action area (`_buildActionButton`, line 1381 + spec inputs block, line 692)

When `_multiSelectMode`:

- Hide the `_buildSpecificationInputs` block entirely. Each batch-added
  algorithm uses its `specifications[i].safeDefaultValue` — identical to the
  initial values used by `_selectAlgorithm` (line 316) and to what
  `onAlgorithmSelectedImpl` already substitutes in offline mode (line 93).
- Replace the action button text with `"Add N to Preset"` where N is
  `_selectedGuids.length`. Disable when `N == 0`.
- The unloaded-plugin warning banner (step 5) appears between the action
  button and the spec input area when applicable.
- On press, build the entry list **in `_allAlgorithms` alphabetical order**
  (the canonical sort key — `name.toLowerCase()`, same as line 88) so a
  filtered-out selected GUID still has a deterministic position. Pop with
  the new return-shape map (step 4).

The FAB (`_isHelpAvailableForSelected ? FAB : null`, line 531) hides in
multi-select — it's tied to the single-select `_currentAlgoInfo`. Long-press
on a chip/row in multi-select continues to invoke favorites, not docs;
documentation lookup remains a single-select affordance.

### 4. Update the return shape and the two call sites

**Files:** `lib/ui/add_algorithm_screen.dart`, `lib/ui/synchronized_screen.dart`

In multi-select, replace the existing pop payload (line 1403):

```dart
Navigator.pop(context, {
  'algorithm': _currentAlgoInfo,
  'specValues': specValues,
});
```

with

```dart
Navigator.pop(context, {
  'algorithms': _selectedAlgorithmsInDisplayOrder(),
});
```

where

```dart
List<({AlgorithmInfo algorithm, List<int> specifications})>
    _selectedAlgorithmsInDisplayOrder() {
  // _allAlgorithms is sorted alphabetically by name (initState line 88,
  // refreshed on state change line 423). Filtering uses _filteredAlgorithms;
  // pop order uses _allAlgorithms so filtered-out selected GUIDs still
  // appear in a deterministic alphabetical position.
  return [
    for (final algo in _allAlgorithms)
      if (_selectedGuids.contains(algo.guid))
        (
          algorithm: algo,
          specifications: algo.specifications
              .map((s) => s.safeDefaultValue)
              .toList(),
        ),
  ];
}
```

This iteration approach also gracefully handles the case where a selected
GUID has been removed from `_allAlgorithms` between tick and pop (e.g., a
plugin rescan): the `if` clause silently drops it, no `firstWhere` exception.
After computing the list, also discard any GUIDs that have vanished from
`_selectedGuids` so the in-memory state reflects what was sent.

Single-select pops the existing `{algorithm, specValues}` shape, unchanged.

Update both `Navigator.push` consumers in `lib/ui/synchronized_screen.dart`
(`_handleAddAlgorithmShortcut`, lines 680–702; `_buildFloatingActionButton`,
lines 905–928) to disambiguate by key:

```dart
if (result is Map) {
  if (result['algorithms'] is List) {
    final entries = (result['algorithms'] as List)
        .cast<({AlgorithmInfo algorithm, List<int> specifications})>();
    if (entries.isNotEmpty) {
      await cubit.onAlgorithmsSelected(entries);
      SemanticsService.sendAnnouncement(view,
        '${entries.length} algorithm${entries.length == 1 ? '' : 's'} added',
        TextDirection.ltr);
    }
  } else if (result['algorithm'] != null) {
    await cubit.onAlgorithmSelected(result['algorithm'], result['specValues']);
    SemanticsService.sendAnnouncement(view, 'Algorithm added', TextDirection.ltr);
  }
}
```

Notes on the record-typed payload:

- `Navigator.pop` keeps Dart objects in-memory; there is no
  serialization round-trip. Dart records survive the boundary as ordinary
  objects, just like the existing `_currentAlgoInfo` (an `AlgorithmInfo`
  object) does today.
- The `(result['algorithms'] as List).cast<({...})>()` pattern relies on
  the producer side returning a properly-typed `List<({...})>` (which
  `_selectedAlgorithmsInDisplayOrder` does — the comprehension yields a
  list whose static type is the record-typed list). If the producer ever
  changes to return `List<dynamic>`, the cast becomes a checked view that
  may throw on element access. Keep `_selectedAlgorithmsInDisplayOrder`'s
  return type explicit.
- Implementer convention: if record-cast turns out to be brittle in
  practice (e.g., compiler upgrade changes inference), an equally
  acceptable shape is `List<Map<String, dynamic>>` with `'algorithm'` and
  `'specifications'` keys, unpacked on the receiving side. Prefer records
  unless that brittleness materialises.

### 5. Unloaded-plugin handling, help text

**File:** `lib/ui/add_algorithm_screen.dart`

#### Unloaded plugins

Ticking an unloaded community plugin (`_needsLoading(algo) == true`) is
allowed. Above the action button, render an `MaterialBanner`-style row when
any selected GUID is unloaded **and** the cubit is online:

```
⚠ K plugin(s) need loading. Tap "Add N to Preset" to load them, then add.
```

When the user taps "Add N to Preset" and the list contains unloaded plugins
(determined per-entry at tap time, *not* cached at tick time):

1. Loop the unloaded ones first, calling `cubit.loadPlugin(guid)` sequentially.
   Show a progress SnackBar (`'Loading plugin K of N…'`).
2. After each `loadPlugin` returns, refresh the entry's `algorithm` via
   `_allAlgorithms.firstWhereOrNull` so its `specifications` reflect the
   loaded plugin's real specs (not the stub).
3. If any `loadPlugin` returns `null` (failure) or throws, abort the batch:
   show `SnackBar('Failed to load <plugin>; batch cancelled.')` and do **not**
   call `cubit.onAlgorithmsSelected`. Keep the picker open so the user can
   uncheck or retry.
4. After all plugins load successfully, pop with the (now-up-to-date)
   `algorithms` list.

When **offline** (`distingState.offline == true`), skip the loading loop
entirely and pop immediately. The cubit's offline path
(`disting_cubit_algorithm_ops.dart:88-97`) will substitute stored defaults
per algorithm, which is the same behavior single-select offline already has.

If `cubit.loadPlugin` hangs (no MIDI response), the existing `loadPlugin`
implementation handles its own timeout via the underlying SysEx wrapper; we
do not add a separate timeout here — that is a property of the plugin loader,
not the multi-select flow.

#### Help dialog

The help dialog (`onPressed` of the help `IconButton`, line 497) gains:

```
'• Multi-select mode (top-right) ticks multiple algorithms; default specs are used.'
'• Each algorithm can be ticked once. To add duplicates, repeat the flow.'
'• Unloaded plugins are loaded automatically before the batch is added.'
```

### 6. Tests

**Files:**
- `test/ui/add_algorithm_screen_multi_select_test.dart` (new widget tests)
- `test/cubit/disting_cubit_algorithm_ops_multi_test.dart` (new cubit tests)

Cubit tests (use existing `MockDistingMidiManager` patterns from
`test/cubit/disting_cubit_test.dart`):

- `onAlgorithmsSelected` with N=0 → no-op, no state change, no MIDI calls.
- N=3 → three sequential `requestAddAlgorithm` calls in supplied order;
  final `slots.length` increases by 3; placeholder names follow the
  `Name`, `Name(2)`, `Name(3)` convention from
  `_deriveOptimisticAlgorithmNameForAdd` when the same GUID appears twice
  (only reachable via repeat-flow; document, don't test through public set).
- Cap enforcement: pre-state has 30 slots, user submits 5 → first 2 are
  appended, the 3rd iteration sees `slots.length == 32` and returns.
- Mid-batch hardware error: second `requestAddAlgorithm` throws → first
  add is preserved, second is rolled back (placeholder removed by
  `onAlgorithmSelectedImpl`'s catch block), third proceeds (loop is not
  aborted by a single-add failure).
- Mid-batch device disconnect: cubit transitions to non-synchronized state
  between iterations → loop returns cleanly without further calls.

Widget tests:

- Toggling multi-select mode swaps `ChoiceChip` for `FilterChip` and hides
  the spec input block.
- Ticking three algorithms produces an "Add 3 to Preset" button; tapping
  pops a `Map` whose `algorithms` list has length 3 in alphabetical order.
- Filter that hides a ticked algorithm keeps it ticked (assert
  `_selectedGuids.contains(...)` still true after `_filterAlgorithms()`)
  and the algorithm appears in the popped list at its alphabetical position.
- Cross-filter cap: with 30 slots already in the preset, ticking 2 in one
  filter view then switching filters and trying to tick a 3rd surfaces the
  cap SnackBar (validates the projection accounts for filtered-out
  selections).
- Unloaded plugin path: tick a `_isPlugin && !isLoaded` algorithm online →
  warning banner appears; tapping "Add" calls `cubit.loadPlugin` first; on
  successful load, the popped entry has the post-load specifications.
- Unloaded plugin path: tick a `_isPlugin && !isLoaded` algorithm offline →
  no banner, tap "Add" pops immediately with stub specs (cubit substitutes
  defaults).
- Untoggling multi-select clears `_selectedGuids`.

---

## Critical Files

| File | Change |
|---|---|
| `lib/cubit/disting_cubit_algorithm_ops.dart` | Add `onAlgorithmsSelectedImpl` looping `onAlgorithmSelectedImpl` with cap + state guards |
| `lib/cubit/disting_cubit.dart` | Expose `onAlgorithmsSelected` facade |
| `lib/ui/add_algorithm_screen.dart` | Multi-select mode flag, `Set<String>` selection, `_toggleMultiSelect` with cap projection, FilterChip/Checkbox rendering, batch action button, return-shape branch, plugin pre-load on submit |
| `lib/ui/synchronized_screen.dart` | Two `Navigator.push` call sites branch on `algorithms` vs `algorithm` key in the result map |
| `test/ui/add_algorithm_screen_multi_select_test.dart` (new) | Widget tests for the multi-select mode |
| `test/cubit/disting_cubit_algorithm_ops_multi_test.dart` (new) | Cubit tests for `onAlgorithmsSelected` |

## Reuse / do not duplicate

- `_buildCategoryFilterButton` (line 1210) is the canonical multi-select
  dialog pattern in this screen; mirror its `Set<T>` + `StatefulBuilder`
  approach for any temp-set UI bits.
- `_deriveOptimisticAlgorithmNameForAdd` (line 7 in algorithm_ops) already
  handles repeated-GUID name derivation. Sequencing batch adds through
  `onAlgorithmSelectedImpl` reuses this for free — do not reimplement.
- Plugin loading is already exposed as `cubit.loadPlugin(guid)` (line 871
  of `disting_cubit.dart`). Wrap calls in a sequential loop for the submit-
  time pre-load — do not call `requestLoadPlugin` directly.
- `MCPConstants.maxSlots` (`lib/mcp/mcp_constants.dart:19`) is the source
  of truth for the 32-slot cap. Import and use that constant — do not
  hardcode `32` in either UI or cubit.

## Verification

Manual:

1. `flutter run -d macos --print-dtd`. Connect to a Disting NT (or use
   demo mode).
2. Open Add Algorithm. Toggle multi-select. Tick three factory algorithms
   (e.g., `Mixer Stereo`, `VCA / VCF`, `Reverb`). Tap "Add 3 to Preset".
   Verify all three appear in slot order at the end of the preset with
   default specifications. Verify `flutter analyze` clean.
3. With ~31 algorithms already loaded, attempt to multi-select 3 — verify
   the cap SnackBar fires on the second tick (because `31 + 1 + 1 = 33 > 32`).
4. With ~30 algorithms loaded: filter to "Mixer", tick 1; filter to
   "Reverb", tick 1; filter to "Delay", attempt to tick 2 — second tick
   fires the cap SnackBar (proves cross-filter projection).
5. Tick a community plugin that is *not* loaded (online). Verify the
   warning banner. Tap "Add". Verify a "Loading plugin…" SnackBar appears,
   the plugin loads, then the batch proceeds.
6. Tick the same unloaded plugin while *offline*. Verify no banner; tap
   "Add" pops immediately and the algorithm appears with default specs
   (cubit's offline override path).
7. Filter to a category, tick three, clear filter, tap Add — verify all
   three were added (proves filter-clear does not lose selection).
8. Toggle multi-select off after ticking 3 → selection is cleared,
   single-select state restored, picker behaves as in main.
9. Single-select path (default): pick one algorithm, edit specs, tap Add
   → verify identical behavior to current main.
10. Disconnect the device mid-batch (start a 5-tick add, pull USB after
    slot 2 settles): verify the cubit lands cleanly in
    `DistingStateConnected`/`Initial` and no spurious slot is added.

Automated:

- `flutter analyze` — zero warnings.
- `flutter test test/cubit/disting_cubit_algorithm_ops_multi_test.dart`.
- `flutter test test/ui/add_algorithm_screen_multi_select_test.dart`.
- Existing test suites in `test/cubit/` and `test/ui/` continue to pass
  (no breaking API changes).

## Out of scope

- **Per-algorithm spec editing in batch.** Letting the user open a per-
  algorithm spec sheet for each ticked algorithm before tap-to-add is a
  much heavier UX (modal stack, per-row state, validation). Defaults are
  the documented batch behavior; users who need non-default specs continue
  to use single-select. Tracked as a future "Configure batch specs" flow
  if requested.
- **Reordering selected algorithms before insertion.** Selected algorithms
  insert in alphabetical (display-canonical) order from `_allAlgorithms`.
  Drag-to-reorder would require a new staging surface; users can move slots
  after insertion via the existing `moveAlgorithmUp/Down`.
- **Duplicates of the same algorithm in one batch.** A `Set<String>`
  deliberately precludes ticking the same GUID twice. Repeat the flow if
  needed.
- **Persisting multi-select mode across screen closes.** Mode and selection
  are both in-memory only.
- **Parallel hardware adds.** The MIDI manager is single-request-at-a-time
  in practice; the verification logic in `onAlgorithmSelectedImpl` assumes
  one in-flight add. Sequential-await is the correct model and is not a
  performance bottleneck for the realistic batch size (≤32).
- **MCP tool for batch add.** The MCP API (`docs/mcp-api-guide.md`) has a
  `new` tool that adds one algorithm at a time. A batch MCP tool is a
  separate change with its own validation surface; not in scope here.
- **Online-during-batch transition handling.** If the user goes from
  online to offline mid-batch, the per-iteration state check aborts.
  Rejoining online mid-batch is not a recovery path the spec attempts to
  cover — the user re-runs the picker.
- **Batch favorites.** Multi-tick → "favorite all" is a plausible
  follow-up but not requested. Long-press still operates per-row.
- **Removing the single-select mode.** Single-select remains the default
  and unchanged. Switching the default to multi-select would be a separate
  UX call.

## Acceptance

- An "Add N to Preset" button replaces "Add to Preset" when in multi-select
  mode and exactly N algorithms are ticked (N ≥ 1).
- Tapping it pops the picker and appends N algorithms to the preset in the
  order they appear alphabetically in `_allAlgorithms`, using each
  algorithm's default specifications.
- Slot cap is enforced cumulatively: ticks past `32 - slots.length -
  _selectedGuids.length` are rejected with a SnackBar.
- Unloaded community plugins (online) are loaded before the batch is
  applied; a load failure aborts the batch and surfaces a SnackBar.
- Offline batch adds use the cubit's existing offline default-substitution.
- Single-select mode is byte-for-byte unchanged.
- Mid-batch device disconnect aborts cleanly without phantom slots.
- `flutter analyze` clean; new tests pass; existing suites pass.
