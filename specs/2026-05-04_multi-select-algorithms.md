# Stay-open option in the Add Algorithm screen

## Context

`AddAlgorithmScreen` (`lib/ui/add_algorithm_screen.dart`) is the modal route through which the user chooses an algorithm to append to the current preset. Today it is single-select, single-add: the user picks one algorithm, optionally edits its specifications, taps **Add to Preset**, and the route pops. The caller in `synchronized_screen.dart` receives a `{'algorithm': …, 'specValues': …}` map and invokes `cubit.onAlgorithmSelected` once.

When a user is building a preset of 5–10 algorithms, every add requires reopening the picker, re-applying filters, and finding the next desired algorithm. The goal of this spec is to add a small, unobtrusive affordance that lets the user stay in the picker after adding an algorithm, so they can immediately select and configure the next one.

The single-select flow, specification editing, plugin loading, and slot-cap behavior remain **completely unchanged**. The only delta is a user-toggleable option to keep the screen open after a successful add.

---

## Approach

### 1. Add a `keepOpen` state flag to `AddAlgorithmScreen`

**File:** `lib/ui/add_algorithm_screen.dart`

Introduce one new boolean field:

```dart
bool _keepOpenAfterAdd = false;
```

It is **in-memory only** — resets to `false` each time the screen is pushed. Persisting it would be surprising (e.g. the user accidentally leaves it checked, comes back hours later, and the first add leaves the picker open). Resetting is the safest default.

### 2. Render the keep-open toggle in the bottom action area

**File:** `lib/ui/add_algorithm_screen.dart`

Inside `_buildActionButton` (or in the widget tree just above/beside it), place a `Row` containing the original **Add to Preset** button and a secondary control:

#### Option A — Split-button dropdown (preferred)

Mirror the existing split-button pattern in `_DeviceSelectionView` (`lib/disting_app.dart` lines ~700–780). There, an `ElevatedButton` is paired with an adjacent `IconButton` (keyed via `_splitButtonKey`) that calls `showMenu` to reveal alternate actions.

Apply the same layout in `_buildActionButton`:

- **Primary action:** `Add to Preset` → pops the route, identical to today.
- **Menu item:** `Add and select another` → adds, clears state, stays open.

The menu item is disabled when `_currentAlgoInfo == null || specValues == null` or when `_needsLoading(algorithm) && !isOffline`.

#### Option B — Checkbox beside the button

A `CheckboxListTile` or plain `Row` with a `Checkbox` + `Text('Add another')` positioned above or beside the **Add to Preset** button. When checked, the same primary button changes its behavior from *pop* to *stay open*.

**Decision:** Use whichever is simpler to implement with the existing layout; the split button is slightly clearer because the two outcomes are explicit, whereas a checkbox changes the meaning of the same button.

The toggle control is hidden (or disabled with a tooltip) when the preset is at cap (`slots.length >= MCPConstants.maxSlots`) because there is no room to add another.

### 3. "Stay open" add flow

When the user triggers the "add + keep open" action:

1. **Guard** identical to today — `selectedAlgorithmGuid`, `_currentAlgoInfo`, and `specValues` must all be non-null; the algorithm must be loaded (or offline). If guards fail, button is disabled.
2. **Call `cubit.onAlgorithmSelected(_currentAlgoInfo!, specValues!)`** exactly as today. Await it so the optimistic placeholder + verification cycle starts before we reset the UI.
3. **On success:** call `_clearSelection()` (line 337), which nulls `selectedAlgorithmGuid`, `_currentAlgoInfo`, `specValues`, and `_isHelpAvailableForSelected`.
4. **Show a transient SnackBar** confirming the add (e.g. `'<name> added'`). Keep the `ScaffoldMessenger` logic simple — dismiss any existing SnackBars first so they don't stack.
5. **Do not pop.** The picker remains visible with the same filters, scroll position, and search query.

If the cubit transitions to a non-`DistingStateSynchronized` state during `await` (e.g. device disconnect), `onAlgorithmSelectedImpl` handles its own rollback/placeholder cleanup and returns. The picker stays open but the state transition may already be pushing a new route via the `BlocListener` in `synchronized_screen.dart`; in that case the normal disconnect flow takes precedence.

### 4. Single-tap "Add to Preset" (existing behavior)

Unchanged. The button that pops the route keeps the exact same `Navigator.pop(context, {'algorithm': _currentAlgoInfo, 'specValues': specValues})` payload.

---

## Critical Files

| File | Change |
|---|---|
| `lib/ui/add_algorithm_screen.dart` | Add `_keepOpenAfterAdd` flag; add split-button or checkbox control in bottom action area; add "add and stay open" path that calls `_clearSelection` instead of `Navigator.pop` |

## No changes to

- `lib/cubit/disting_cubit_algorithm_ops.dart`
- `lib/cubit/disting_cubit.dart`
- `lib/ui/synchronized_screen.dart`
- Test files (the existing widget tests for `AddAlgorithmScreen` cover the pop path; no new cubit tests are required because the cubit surface is identical)

## Reuse / do not duplicate

- `_clearSelection` (line 337) already nulls every piece of selection state we need to reset. Call it directly — do not inline.
- `cubit.onAlgorithmSelected` is the only cubit method ever invoked, same as today.
- `MCPConstants.maxSlots` is the source of truth for disabling the toggle when the preset is full.

## Verification

Manual:

1. `flutter run -d macos --print-dtd`. Connect or use demo mode.
2. Open Add Algorithm. Select an algorithm (e.g. `Mixer Stereo`). Do **not** use the keep-open option. Tap **Add to Preset** → screen pops, algorithm appears at end of preset. (Regression check for unchanged path.)
3. Re-open Add Algorithm. Select `VCA / VCF`. Choose **Add and select another** (or check **Add another** then tap **Add**). Verify:
   - A SnackBar appears (`'VCA / VCF added'`).
   - The picker remains open.
   - The previously-selected algorithm is no longer highlighted.
   - Specification inputs disappear (because nothing is selected).
   - Scroll position and active filters are preserved.
4. Without leaving the picker, select `Reverb`. Tap **Add to Preset** (normal pop). Verify the preset now contains the three algorithms in order.
5. With 32 slots already occupied, open the picker. Verify the keep-open toggle/button is disabled or hidden, and the **Add to Preset** button works normally (pops) or is itself disabled if the single add would overflow.
6. Select a community plugin that is *not* loaded. Verify the **Add and select another** action is disabled (just like **Add to Preset** is replaced by **Load Plugin** today).

Automated:

- `flutter analyze` — zero warnings.
- Existing `test/ui/add_algorithm_screen_test.dart` and `test/cubit/disting_cubit_test.dart` suites continue to pass (no breaking API changes).

## Acceptance

- A toggle or menu option labeled "Add and select another" is available when an algorithm is selected and the slot cap has not been reached.
- Triggering it calls `cubit.onAlgorithmSelected` with the current algorithm and spec values, then clears the selection state and leaves the picker open.
- The normal **Add to Preset** path pops the route and behaves identically to the pre-change implementation.
- Specification editing, plugin loading, offline-mode defaults, and slot-cap behavior are unchanged.
- `flutter analyze` clean; existing tests pass.
