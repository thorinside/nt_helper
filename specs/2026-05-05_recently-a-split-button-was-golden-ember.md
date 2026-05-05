# Replace split-button with two side-by-side buttons in Add Algorithm screen

## Context

A split-button (ElevatedButton + dropdown IconButton) was added in commit `c331d9d` to allow adding multiple algorithms without leaving the Add Algorithm screen. Issues with the current design:
- The dropdown menu looks unpolished.
- The split-button collapses to its intrinsic width because the dropdown breaks the previous full-width button layout.
- The action area looks left-justified instead of stretched across the bottom.

We want two equally-sized buttons side-by-side ("Add Algorithm" + "Add Another"), with the existing AnimatedContainer continuing to slide them away from the FAB when help is available.

## Critical file

- `lib/ui/add_algorithm_screen.dart`

## Current structure (for reference)

- `_buildActionButton(isOffline)` at L1385-1437 returns either a single `ElevatedButton` or a `Row` containing the button + an `IconButton` dropdown.
- The dropdown opens `_showAddMenu()` (L1445-1475) which uses `_splitButtonKey` (L77) and `showMenu()`.
- `_addAndStayOpen()` (L1477-1497) is the action invoked from the menu — it adds the algorithm via the cubit, shows a SnackBar, and clears selection so the user stays on screen and can pick another.
- The action button area is wrapped by an `AnimatedContainer` at L708-717 inside a `CrossAxisAlignment.stretch` `Column`, which animates `right: 72.0` padding when `_isHelpAvailableForSelected` is true (FAB visible).

## Changes

### 1. Rewrite `_buildActionButton(isOffline)` (L1385-1437)

Keep the early-return paths unchanged:
- `_currentAlgoInfo == null` → disabled `ElevatedButton('Select Algorithm')`.
- `_needsLoading(algorithm) && !isOffline` → `ElevatedButton('Load Plugin')`.

Replace the split-button block with:
- A primary `ElevatedButton('Add Algorithm')` — same `onPressed` as the current `addButton` (pops with `{algorithm, specValues}`). Rename label from "Add to Preset" to "Add Algorithm" per user request.
- When `canAdd && _canStayOpen()` is true, return a `Row` with two `Expanded` children separated by an 8-pixel `SizedBox`:
  - `Expanded(child: ElevatedButton(... 'Add Algorithm'))` — pops the route.
  - `Expanded(child: ElevatedButton(... 'Add Another'))` — calls `_addAndStayOpen()`.
- Otherwise (no specs filled, or slot cap reached), return the single `ElevatedButton('Add Algorithm')` (which the surrounding stretch column will full-width).

Both buttons inside the row inherit the standard `ElevatedButton` theme — no styling differentiation needed since they're peer actions.

### 2. Remove dead code

- `_splitButtonKey` field (L77).
- `_showAddMenu()` method (L1445-1475).

`_addAndStayOpen()` stays — it's now invoked directly by the second button's `onPressed`.

### 3. Animation away from the FAB

No change needed. The existing `AnimatedContainer` at L708-717 already animates `right` padding (0 → 72) over 300ms when `_isHelpAvailableForSelected` toggles. The new `Row` of two buttons sits inside that container and inherits the slide-in behavior. The buttons stretch within the available width, so as the right padding grows, they smoothly compress away from where the FAB will land.

## Verification

1. `flutter analyze` — must be clean (zero warnings, per project rules).
2. `flutter test` — existing test suite passes.
3. Manual UI walkthrough on macOS:
   - Open Add Algorithm screen.
   - Before selecting: button reads "Select Algorithm" (disabled).
   - Select an algorithm without help docs: single full-width "Add Algorithm" button (no FAB, no second button if specs require entry).
   - Select an algorithm whose specs are filled and slot cap not reached: two side-by-side equal-width buttons "Add Algorithm" + "Add Another".
   - Select an algorithm with help docs: FAB (`?`) appears bottom-right, the button row smoothly animates its right edge away from the FAB.
   - Tap "Add Another": algorithm is added, SnackBar confirms, selection clears, screen stays open.
   - Tap "Add Algorithm": screen closes and the algorithm is added to the preset.
   - Fill all 32 slots: the "Add Another" button disappears, leaving a single full-width "Add Algorithm" button.
