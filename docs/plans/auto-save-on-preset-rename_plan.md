# Plan: Auto-save preset on rename

## Goal

When the user renames the current preset to a non-empty value, the preset is saved to the device immediately — the user no longer has to invoke the manual "Save Preset" action separately. Renames to empty/whitespace-only strings are already rejected by existing validation and must NOT trigger a save.

## Current behavior (verified)

### Rename flow

| Step | Location |
|---|---|
| User taps "Preset:" label | `lib/ui/synchronized_screen.dart:2123` (`InkWell.onTap`) |
| Rename dialog opens | `lib/ui/widgets/rename_preset_dialog.dart:38-55` (TextField + OK/Cancel buttons; submit on Enter or OK) |
| Dialog returns trimmed name (or `null` on cancel) | `rename_preset_dialog.dart:33-36` |
| UI guards empty / unchanged | `synchronized_screen.dart:2133-2137` (`newName != null && newName.isNotEmpty && newName != widget.presetName`) |
| Cubit facade | `lib/cubit/disting_cubit.dart:422-424` (`renamePreset()` → `renamePresetImpl()`) |
| Cubit impl | `lib/cubit/disting_cubit_preset_ops.dart:32-77` (optimistic UI emit, async `requestSetPresetName`, deferred verification read-back) |

`renamePresetImpl()` already trims and re-checks emptiness: line 35-36 short-circuits when `trimmed.isEmpty || trimmed == currentState.presetName`.

### Manual save flow (the path we must reuse)

The manual save calls `IDistingMidiManager.requestSavePreset()` directly — there is no cubit-level wrapper today. Three call sites:

- `synchronized_screen.dart:503` — keyboard shortcut handler.
- `synchronized_screen.dart:1828` — "save first, then new preset" branch.
- `synchronized_screen.dart:1851` — "Save Preset" popup menu item.

Plus one external call site:

- `lib/services/disting_controller_impl.dart:329` — `DistingController.savePreset()` (used by MCP).

All four invoke `manager.requestSavePreset()` (with no option arg) on the active manager. Implementations:

- `lib/domain/disting_midi_manager.dart:664` — sends SysEx `SavePresetMessage` with option=2 to the live device.
- `lib/domain/offline_disting_midi_manager.dart:528` — persists to the local Drift database via `presetsDao.saveFullPreset()`.
- `lib/domain/mock_disting_midi_manager.dart:1069` — no-op (demo mode).

The interface declares `Future<void> requestSavePreset({int option})` (`lib/domain/i_disting_midi_manager.dart:77`). The mock signature uses `int? option`, but every caller invokes it with no argument, so default-arg behaviour is what matters and it is consistent (option=2 on hardware, ignored offline/mock).

The device handles SysEx commands sequentially (comment at `synchronized_screen.dart:1829-1831`), so chaining `requestSetPresetName` and `requestSavePreset` is already safe — that is precisely how the existing "save before new preset" branch works.

## Design

### Trigger point

Inside `renamePresetImpl()` in `lib/cubit/disting_cubit_preset_ops.dart`, **after** the existing empty-name guard and **after** the optimistic UI emit + the `requestSetPresetName` background send. Calling save from inside the cubit (rather than the UI) means *all* rename entry points get auto-save:

- The rename dialog (`synchronized_screen.dart:2136`).
- The MCP `setPresetName` controller (`disting_controller_impl.dart:96`, which calls `cubit.renamePreset()`).

Both should auto-save — that matches the spirit of the feature ("renaming a preset persists it").

### Empty-name guard

The existing line 35-36 already short-circuits empty/whitespace-only renames AND no-op renames (where the trimmed name equals the current preset name). Auto-save must run only on the path past that guard, so it inherits the same protection for free. No new validation needed.

### Reuse the manual-save path

The rename impl has access to `disting` (line 42, the active manager). Calling `disting.requestSavePreset()` from there hits the same interface method as every other save call site — no parallel save logic, no new cubit method. This satisfies the "same code path" acceptance criterion.

### Sequencing

`disting.requestSetPresetName(trimmed)` is fired without `await` today (line 43 — the future is chained with `.catchError`). Auto-save must follow the rename SysEx, not race it. Two viable ordering strategies:

1. **Await the rename, then save.** Change `disting.requestSetPresetName(trimmed).catchError(...)` to `await` it, save on success, skip save on failure. Most correct, but converts the rename from fire-and-forget to await — slight behavior change for callers that don't await `renamePreset()` (the UI doesn't, MCP does via `Future.value()`).
2. **Fire-and-forget save after rename, relying on the device's sequential command processing.** Simply call `disting.requestSavePreset()` immediately after the `requestSetPresetName(...)` line. Matches what `synchronized_screen.dart:1828` already does for the "save first, then new preset" branch.

**Choice: strategy 1 (await rename, then save).** Rationale: the offline manager's `requestSetPresetName` writes to the database synchronously (via `await`); strategy 2 would still work there, but strategy 1 also lets us skip the save when the rename failed — which matches the existing verification-fallback that re-reads the device truth. Skipping the save on failure avoids persisting a stale UI name. The catch handler stays in place to schedule the verification read-back.

### Last-write-wins on rapid renames

Multiple rename calls in quick succession: each `renamePresetImpl` call emits its own optimistic UI update and fires its own `requestSetPresetName` + `requestSavePreset`. The device processes SysEx sequentially, so the last name wins on the device side. The verification operation is already cancelled-and-replaced on each call (`_renamePresetVerificationOperation?.cancel()` at lines 45 and 61), which keeps the last verification authoritative. No new debounce is needed — the existing semantics (last write wins) carry through to the auto-save.

### What does NOT change

- `renamePreset()` facade signature (still `void renamePreset(String newName)`).
- The rename dialog UI.
- The manual save call sites (keyboard shortcut, menu, "save first new", MCP `savePreset()`).
- The `requestSavePreset` interface and all implementations.

## Files to modify

| File | Change |
|---|---|
| `lib/cubit/disting_cubit_preset_ops.dart` | After awaiting `requestSetPresetName(trimmed)` succeeds, call `disting.requestSavePreset()`. On error, fall through to existing verification path and do NOT save. |
| `test/cubit/disting_cubit_preset_rename_test.dart` (NEW) | New test file. Cases: (a) renaming to non-empty value calls `requestSetPresetName` then `requestSavePreset` exactly once, (b) renaming to whitespace-only does NOT call either, (c) renaming to the same name does NOT save, (d) two rapid renames result in two saves with the latest name being the final SysEx call. |

No UI file changes. No interface changes. No new cubit method.

## Acceptance criteria — how each is met

| Criterion | How |
|---|---|
| Rename to non-empty persists immediately | `disting.requestSavePreset()` runs after `requestSetPresetName` succeeds, inside `renamePresetImpl`. |
| Rename to empty/whitespace does NOT save | Existing `trimmed.isEmpty` guard at `disting_cubit_preset_ops.dart:36` short-circuits before any SysEx is sent — auto-save is below the guard. |
| Manual save still works | No change to any of the four manual-save call sites. |
| Same code path as manual save | Auto-save calls `disting.requestSavePreset()` — the exact method every manual save call site uses. |
| Rapid renames → latest wins | Existing rename impl already emits last-write-wins semantics; auto-save follows the same ordering on the device. |
| `flutter analyze` clean | No new warnings introduced. |
| Tests pass | New test file added; existing tests untouched. |
| New test covers the change | New `disting_cubit_preset_rename_test.dart` covers the four cases above. |

## Gaps integrated

### G1 — Behavior change for MCP `setPresetName` callers

`lib/services/disting_controller_impl.dart:96` (`DistingController.setPresetName`) routes to `cubit.renamePreset()`. After this change, the MCP tool `disting_tools.dart:setPresetName` (line 955) will auto-save as a side effect. Two MCP tools chain `setPresetName` with subsequent work that ends in an explicit `savePreset()`:

- `buildPresetFromJson` (line 1935) — sets name first, then loads slots; later returns without an explicit save.
- `editPreset` (line 4221) — applies diff then sets name in step 6, then explicitly saves at line 2823.

**Resolution:** This is acceptable, not a bug. The device handles SysEx commands sequentially, so an extra save SysEx during a complex MCP flow is idempotent and harmless. `editPreset`'s explicit `savePreset()` at line 2823 still runs and remains the authoritative save. `buildPresetFromJson` previously did not save at all (relied on user to save manually); auto-save now persists the name change earlier, but the slot operations that follow still require a final save (out of scope for this feature). No MCP test changes needed — existing tests mock `DistingController`, not the cubit, so they are unaffected.

### G2 — Failure of `requestSetPresetName` must skip the save

The plan's strategy 1 (await rename, save on success) is correct, but the implementation must be precise:

- Wrap `await disting.requestSetPresetName(trimmed)` in a try/catch.
- On success: call `disting.requestSavePreset()` (do not await — keep cubit responsive).
- On error: schedule the existing 250ms verification read-back (preserve the current `.catchError` behavior). Do NOT call save.
- The unconditional 500ms verification read at lines 61-75 is preserved as-is — it remains useful regardless of save success/failure.

### G3 — No cubit BuildContext for semantics announcement (accept)

The keyboard-shortcut manual save (`synchronized_screen.dart:503`) emits `SemanticsService.sendAnnouncement('Preset saved')` after `requestSavePreset()`. The popup-menu manual save and the MCP save path do **not**. Auto-save runs inside the cubit which has no `BuildContext`, so it cannot emit a semantics announcement.

**Resolution:** Accept the gap. The screen reader already hears the rename event (the preset name in the UI updates optimistically). Adding a save announcement would require a UI-layer listener and is out of scope. The keyboard-shortcut announcement is preserved as-is.

### G4 — Test cases expanded

The original test list is upgraded to:

1. **Rename to non-empty name** calls `requestSetPresetName(trimmed)` and `requestSavePreset()` exactly once each, **in that order** (verified via Mocktail `verifyInOrder`).
2. **Rename to empty string** does NOT call either method.
3. **Rename to whitespace-only** ('   ', '\t\n') does NOT call either method (Dart `String.trim()` strips all Unicode whitespace).
4. **Rename to the same name** as the current preset does NOT call either method.
5. **Rename when state is not `DistingStateSynchronized`** does NOT call either method.
6. **`requestSetPresetName` throws** → `requestSavePreset` is NOT called (regression guard for G2).
7. **Two rapid renames** result in `requestSetPresetName` then `requestSavePreset` being called twice in total, with the SECOND name being the last `requestSetPresetName` argument (last-write-wins).

### G5 — Offline mode behaviour

The offline manager's `requestSavePreset` writes to the local Drift database (`lib/domain/offline_disting_midi_manager.dart:528`). When `_loadedPresetId == null`, it creates a new preset entry (id=-1 path). This is a pre-existing behavior of the manual-save call, NOT introduced by this feature — and the existing rename guard (`if (currentState is DistingStateSynchronized)`) already requires a synchronized state, which means a preset is loaded. No additional guard required. Tests use `MockDistingMidiManager` and verify the call, not the offline-specific branch behavior.

### G6 — `requestSavePreset` is not awaited

To keep the cubit responsive (no UI freeze waiting for save round-trip), the auto-save call is **fire-and-forget** with a `.catchError` to swallow errors. The rename await is kept for sequencing (so we know the rename succeeded before asking for a save). This mirrors the existing manual-save call sites which also do not await.
