# Preset dirty indicator (unsaved changes)

## Context

The Disting NT app keeps an in-memory copy of the current preset
(`DistingStateSynchronized.presetName` and `DistingStateSynchronized.slots`)
that the user mutates from the UI: parameter sliders, algorithm add/remove,
slot reordering, mapping changes, slot custom names, preset rename, etc.
Those mutations are sent to the device as MIDI SysEx commands and the
in-memory state is updated optimistically — but the device's *persistent*
preset (the one that survives a power cycle or "Load Preset") is only
updated when the user explicitly invokes **Save Preset**.

Today there is **no visual cue** that the in-memory preset has diverged
from the saved one. A user who has been twiddling parameters for an hour
has no way to tell — short of saving — whether the next power cycle will
restore their session or throw it away. The "New Preset" flow already
prompts for a save when slots are non-empty (`synchronized_screen.dart`
line ~1825), which proves the team treats unsaved state as significant,
but the prompt only fires for that one path.

## Goal

Display a **dirty indicator** (an asterisk `*` appended to the preset
name in the app bar header) whenever the in-memory preset has been
mutated since the last save / load / new / refresh from device. The
indicator clears when the user saves the preset, loads a preset, starts
a new preset, or refreshes state from the device.

## Non-goals

- No structural diffing of the preset against the device's saved copy.
  We track *whether mutations occurred*, not *whether they round-trip
  to the same bytes*. A user who nudges a slider to value 42 and back
  to 41 will leave the preset marked dirty until save. This is the
  standard text-editor convention and is acceptable.
- No "discard changes" or "revert" action. (Those would be useful but
  are out of scope; the existing `_CheckpointDelegate` undo system is
  the right place to extend later if we want them.)
- No persistence of the dirty flag across app restarts. The flag lives
  only in `DistingState`. Restarting the app re-fetches state from the
  device, which is by definition clean.
- No cross-platform native window-title decoration (e.g. macOS
  document-modified dot). We only decorate the in-app text label.
- No save-on-quit prompt or unsaved-changes guard on connection loss.
  Those would be welcome follow-ups but are separate features.
- No change to the existing "New Preset" save-prompt dialog logic. We
  could later make it conditional on `isDirty`, but that's a separate
  PR.
- No change to the rename autosave behaviour itself — we only piggyback
  on the existing autosave to clear the flag when it succeeds.

## Naming

Use `isDirty` as the field name. This matches the existing
`DistingStateSynchronized` convention (`loading`, `offline`, `demo`,
no `is*` prefix on most booleans, but `isDirty` is the one widely
recognised text-editor term and reads better than `dirty` alone).
"Dirty" is the standard term in Cocoa, Qt, Flutter and most editor
codebases for "in-memory differs from persisted." `hasUnsavedChanges`
is the user-facing phrase and is what we put in semantic labels, not
the field name.

## Affected files

### State

- `lib/cubit/disting_state.dart` — add field to `DistingStateSynchronized`.

### Cubit / delegates

- `lib/cubit/disting_cubit.dart` — add facade `savePreset()` method.
- `lib/cubit/disting_cubit_preset_ops.dart` — `loadPresetImpl`,
  `newPresetImpl`, `renamePresetImpl`, plus the rename-driven
  autosave clear.
- `lib/cubit/disting_cubit_state_refresh_delegate.dart` — clear the
  flag after a refresh from device.
- `lib/cubit/disting_cubit_connection_delegate.dart` — initial sync
  emit (line 281) constructs a fresh state with default `isDirty: false`;
  no explicit field needed but verify the freezed default fires.
- `lib/cubit/disting_cubit_parameter_value_delegate.dart` — set on
  parameter writes (both real-time and release paths).
- `lib/cubit/disting_cubit_parameter_string_delegate.dart` — set on
  string parameter writes.
- `lib/cubit/disting_cubit_algorithm_ops.dart` — set on add / remove /
  move-up / move-down (both optimistic and verification emits).
- `lib/cubit/disting_cubit_slot_ops.dart` — set on slot custom-name
  changes.
- `lib/cubit/disting_cubit_slot_state_delegate.dart` — set on
  slot-state mutations (parameter pages, etc.).
- `lib/cubit/disting_cubit_mapping_delegate.dart` — set on CV / MIDI /
  i2c mapping changes.
- `lib/cubit/disting_cubit_perf_page_delegate.dart` — set on perf page
  item edits (preserve current `isDirty` on perf page fetch inside
  refresh).
- `lib/cubit/disting_cubit_offline_demo_delegate.dart` — fresh
  constructions get default `isDirty: false`; verify no copy paths
  preserve a stale dirty flag.
- `lib/cubit/disting_cubit_slot_maintenance_delegate.dart` — set on
  slot repair (these mutate slot contents).
- `lib/cubit/disting_cubit_lua_reload_delegate.dart` — Lua reload
  restores parameter values via the same parameter-write path; that
  path will already mark dirty, but verify the success-path emit (if
  any) preserves dirty.

### UI

- `lib/disting_app.dart` — pass `state.isDirty` to `SynchronizedScreen`.
- `lib/ui/synchronized_screen.dart` — accept `isDirty` constructor
  argument; render asterisk in `_buildPresetInfoEditor` and in the
  semantic label; switch the three direct `requireDisting().requestSavePreset()`
  call sites to a new `cubit.savePreset()` facade so the flag clears
  on save.

### Controller / external

- `lib/services/disting_controller_impl.dart` line 327 — change
  `savePreset()` to call `_distingCubit.savePreset()` instead of
  `_getManager().requestSavePreset()`, so MCP-driven saves clear the
  flag.

### Tests

- `test/cubit/preset_dirty_indicator_test.dart` — new file. See
  *Test plan* below.
- `test/ui/synchronized_screen_dirty_indicator_test.dart` — new file.

## Design

### State change

Add one field to `DistingStateSynchronized` in
`lib/cubit/disting_state.dart`:

```dart
const factory DistingState.synchronized({
  // ... existing fields unchanged ...
  @Default(false) bool isDirty,
}) = DistingStateSynchronized;
```

Freezed regenerates `copyWith` automatically. Default `false` means
freshly-synchronized state is clean, which matches the data flow:
every path that constructs a `DistingStateSynchronized` from scratch
(initial sync, offline load, demo init, refresh-from-device) reflects
device truth and is by definition clean.

### Mutation rule

This is the **authoritative rule** the implementer follows:

> An emit of `DistingStateSynchronized` must set `isDirty: true` if and
> only if the emit reflects a **user-initiated change** to preset
> contents — `slots`, `presetName`, or in-slot mappings — that has not
> yet been saved.
>
> Emits that reflect **device truth** (live polling, CC notifications,
> verification reads, full refreshes, screenshots, video, firmware
> update notices) **preserve** the current `isDirty` value via
> `state.isDirty` in the `copyWith` argument list. They do not flip it
> in either direction.
>
> Emits that *replace* state from a fresh device read (full
> `_refreshStateFromManager`, initial sync, preset load) explicitly set
> `isDirty: false`.

Implementation pattern for the "preserve" case:

```dart
_cubit._emitState(
  currentState.copyWith(
    slots: updatedSlots,
    isDirty: currentState.isDirty,  // explicit, even though Dart would default it
  ),
);
```

The explicit `isDirty: currentState.isDirty` is required at every
device-truth emit site. It documents intent and survives future
refactoring (e.g., if someone adds a default constructor that emits
`isDirty: false`). Where a site already passes other unrelated fields
forward, this is a one-line change.

### Mutation site reference (illustrative, not authoritative)

The following table is a **starting point** derived from the codebase
at the spec's commit. The mutation rule above is what the implementer
follows; this table accelerates the first pass but should be
re-validated against `git grep` results during implementation since
line numbers drift.

User-initiated mutation emits — set `isDirty: true`:

| File | Line | Operation |
|------|------|-----------|
| `disting_cubit_parameter_value_delegate.dart` | 59, 107 | parameter write (real-time + release) |
| `disting_cubit_parameter_string_delegate.dart` | 43, 93, 131 | string parameter write |
| `disting_cubit_algorithm_ops.dart` | 110, 126, 223, 319, 437 | add / remove / move algorithms (optimistic emits) |
| `disting_cubit_algorithm_ops.dart` | 172, 185, 370, 483 | add / move verification emits — preserve `isDirty` (the optimistic emit already set it) |
| `disting_cubit_slot_ops.dart` | 33 | slot custom-name optimistic |
| `disting_cubit_slot_ops.dart` | 69 | slot custom-name verification — preserve |
| `disting_cubit_slot_state_delegate.dart` | 71, 128, 170, 196, 227, 248 | slot state updates (parameter pages, output modes) |
| `disting_cubit_slot_maintenance_delegate.dart` | 98, 135 | slot repair |
| `disting_cubit_mapping_delegate.dart` | 84, 135, 175 | CV / MIDI / i2c / performance mapping |
| `disting_cubit_perf_page_delegate.dart` | 34, 62 | perf page item edits |
| `disting_cubit_preset_ops.dart` | 39 | preset rename optimistic emit |

Device-truth emits — preserve current `isDirty`:

| File | Line | Why |
|------|------|-----|
| `disting_cubit_parameter_refresh_delegate.dart` | 66, 115, 247, 317 | live polling reflects device truth |
| `disting_cubit_cc_notification_delegate.dart` | 216 | CC value reflection from device |
| `disting_cubit_hardware_commands_delegate.dart` | 20 | screenshot only |
| `disting_cubit_monitoring_delegate.dart` | 74, 90 | video stream state |
| `disting_cubit_preset_ops.dart` | 56, 74 | rename verification correction (device truth) |
| `disting_cubit.dart` | 893, 999 | firmware-update notice |

Full-refresh emits — explicitly set `isDirty: false`:

| File | Line | Why |
|------|------|-----|
| `disting_cubit_state_refresh_delegate.dart` | 34 | refreshed from device |
| `disting_cubit_connection_delegate.dart` | 281 | initial sync emit (relies on Freezed default) |
| `disting_cubit_offline_demo_delegate.dart` | 30, 72, 107, 193 | fresh state constructions |

Out-of-scope (non-preset state) — pass through:

| File | Line | Why |
|------|------|-----|
| `disting_cubit_state_refresh_delegate.dart` | 16, 47 | loading/error transitions |
| `disting_cubit_algorithm_library_delegate.dart` | all | algorithm library cache, not preset |
| `disting_cubit_connection_delegate.dart` | (other lines) | connection lifecycle |
| `disting_cubit_plugin_delegate.dart` | 663 | algorithm library, not preset |

Routing changes flow through the existing `RoutingEditorCubit`, which
calls back into `DistingCubit` via parameter writes — covered by the
parameter-write path automatically.

### Clear rule

`isDirty` is set back to `false` at exactly the points where the
in-memory preset is fully resynchronised with a known clean baseline:

1. **Save completes** — see "Save flow" below.
2. **State refresh from device** — `_StateRefreshDelegate.refreshStateFromManager`
   line 34: explicitly add `isDirty: false` to the `copyWith`.
3. **New preset** — `newPresetImpl` calls `requestNewPreset()` then
   `_refreshStateFromManager()`, which resets via #2.
4. **Load preset (online)** — `loadPresetImpl` calls
   `requestLoadPreset()` then `_refreshStateFromManager()`, which
   resets via #2.
5. **Load preset (offline)** — `_OfflineDemoDelegate.loadPresetOffline`
   constructs a fresh `DistingStateSynchronized`; default
   `isDirty: false` applies. Verify no `copyWith` paths in this
   delegate inadvertently preserve a stale dirty flag from a prior
   state.
6. **Demo init** — same as #5.
7. **Initial sync** — `performSyncAndEmit` (connection delegate
   line 281) constructs `DistingState.synchronized(...)` without
   passing `isDirty`; the Freezed `@Default(false)` applies. No code
   change needed if Freezed's defaults work as expected. Verify by
   inspecting generated `disting_state.freezed.dart` after build_runner.

### Save flow

The current save path bypasses the cubit: three sites in
`synchronized_screen.dart` (lines 503, 1828, 1851) call
`cubit.requireDisting().requestSavePreset()` directly. Add a facade:

```dart
// disting_cubit.dart
Future<void> savePreset() async {
  final s = state;
  if (s is! DistingStateSynchronized) return;
  final disting = s.disting;
  try {
    await disting.requestSavePreset();
  } catch (_) {
    rethrow;  // Leave isDirty as-is; a failed save did not actually persist.
  }
  // Re-check state after the await: connection could have dropped.
  final after = state;
  if (after is DistingStateSynchronized) {
    _emitState(after.copyWith(isDirty: false));
  }
}
```

The two-step (snapshot before await, re-read after) is intentional:
between the `await` and the emit, state could have transitioned to
`DistingStateConnected` or `DistingStateInitial` (e.g., disconnect).
Re-reading `state` after the await catches that.

Update the three UI call sites to use `cubit.savePreset()`. The
keyboard shortcut path (line 503) and the popup-menu path (line 1851)
both go through cleanly. The "Save First & New" path (line 1828) also
calls `cubit.newPreset()` immediately after; reorder to
`await cubit.savePreset(); cubit.newPreset();` so the save resolves
before the new-preset state machine runs (which would otherwise also
clear the flag via the refresh path, but the explicit ordering avoids
a race).

The auto-save inside `renamePresetImpl` (line 45) — `disting.requestSavePreset().catchError((_) {})`
— must also clear the flag. Replace it with a deferred clear:

```dart
disting.requestSavePreset().then((_) {
  final cur = state;
  if (cur is DistingStateSynchronized) {
    _emitState(cur.copyWith(isDirty: false));
  }
}).catchError((_) {});
```

This is the only change to rename behaviour; otherwise the rename flow
is untouched. Justification: the rename path already triggers a save,
so the flag must clear when that save resolves — otherwise rename
would leave a misleading `*` until the user manually saved again.

The `disting_controller_impl.dart` line 327 `savePreset()` (used by
MCP) currently calls `_getManager().requestSavePreset()` directly.
Change to `await _distingCubit.savePreset();` so MCP-driven saves also
clear the flag. The `_getSynchronizedState()` precondition check
remains; it will throw before `_distingCubit.savePreset()` if state
isn't synchronized.

The `metadata_sync_cubit.dart` line 329 save is part of an internal
sync orchestration that already calls back into `_refreshStateFromManager()`,
which will clear the flag via the refresh rule. No change needed.

### UI change

`SynchronizedScreen` constructor (`lib/ui/synchronized_screen.dart`
lines 77–93) currently takes `presetName` but not `isDirty`. Add:

```dart
final bool isDirty;
const SynchronizedScreen({
  // ...
  required this.presetName,
  required this.isDirty,
  // ...
});
```

Update the construction site in `lib/disting_app.dart` line 432:

```dart
return SynchronizedScreen(
  // ...
  presetName: state.presetName,
  isDirty: state.isDirty,
  // ...
);
```

In `_buildPresetInfoEditor` (line 2113):

```dart
final displayName = widget.presetName.trim();
final dirtyMark = widget.isDirty ? ' *' : '';
// ...
Semantics(
  button: true,
  label: 'Preset: $displayName${widget.isDirty ? ', unsaved changes' : ''}',
  // ...
  TextSpan(text: '$displayName$dirtyMark', ...)
)
```

The asterisk uses the same text style as the preset name — no separate
icon, no colour change. We use an asterisk because it is the universally
recognised "modified document" marker across editors (Vim, VSCode,
Sublime, Xcode, etc.); Material Design has no specific guidance for
in-text "modified" indicators on preset/document headers, so the
text-editor convention applies. Spoken accessibility uses the phrase
"unsaved changes" rather than reading "asterisk" aloud, matching the
existing semantic-label patterns in the screen.

## Edge cases

- **Rename to the same name**: `renamePresetImpl` early-returns
  (line 36) before emitting, so `isDirty` is unchanged. Correct.
- **Rename verification correction**: lines 56 and 74 emit
  `verificationState.copyWith(presetName: actual)` after a rename
  failure or device-truth correction. These must explicitly preserve
  `isDirty` (`isDirty: verificationState.isDirty`) — otherwise the
  freezed `copyWith` keeps the existing value, but adding the
  explicit pass is required by the mutation rule and prevents
  silent regressions.
- **Rename succeeds + autosave fires + user mutates before autosave
  resolves**: window of milliseconds; the autosave clear may
  overwrite a fresh user mutation's `isDirty: true`. Mitigated by the
  fact that the autosave clear re-reads `state` and sets
  `isDirty: false` — but a user write that lands between the autosave
  resolving and the clear emitting would be lost. Acceptable: the
  window is tens of milliseconds and the user's next mutation will
  immediately re-mark dirty.
- **Parameter slider scrubbing back to original value**: marks dirty.
  Acceptable per non-goals.
- **Failed save**: the `await disting.requestSavePreset()` may throw or
  silently fail; the cubit's `try/rethrow` keeps `isDirty: true` so
  the user retains the indicator. UI call sites that previously
  didn't await the save now have a future to consider — the new
  `savePreset()` returns `Future<void>` and may throw. The popup-menu
  and shortcut handlers should ignore failures (existing behaviour);
  the "Save First & New" handler awaits before calling `newPreset()`.
- **Live parameter polling races user mutation**: polling emits
  preserve `isDirty: currentState.isDirty`, so a poll landing right
  after a user mutation keeps the dirty flag set. Without the explicit
  preserve, freezed's `copyWith` would also keep it (since the field
  isn't passed), but the rule requires explicit pass-through.
- **CC notification reflections** likewise reflect device-side changes;
  preserve dirty.
- **External save (auto-save during rename, MCP-driven save, sync
  flow save)**: covered via the rename autosave change, the MCP
  controller change, and the refresh path for sync-driven flows.
- **Lua reload** (`disting_cubit_lua_reload_delegate.dart`): the
  reload flow re-issues parameter writes via the standard parameter
  delegate, which will mark dirty. The reload itself does not emit a
  state directly (it issues SysEx writes that trigger downstream
  refresh paths). No additional code change needed; verify by
  triggering a reload and watching the indicator.
- **Algorithm-add verification** (`algorithm_ops.dart` line 172): the
  verification re-fetches the slot from the device and emits with the
  fresh slot. Optimistic emit at line 110 already set `isDirty: true`;
  the verify emit must `copyWith(slots: ..., isDirty: state.isDirty)`
  to preserve.
- **Initial sync** (`connection_delegate.dart` line 281): builds a
  fresh `DistingState.synchronized(...)`. `isDirty` is omitted, so
  Freezed's `@Default(false)` applies. Verify the generated freezed
  file actually emits the default after `build_runner` runs.
- **Offline mode**: parameter writes still queue to the
  `OfflineDistingMidiManager`, which persists to local storage on
  `requestSavePreset()`. The dirty flag behaves identically.
- **Demo mode**: in demo mode there's no real persistence, but mutations
  still emit slot changes and `requestSavePreset()` is a no-op on the
  mock manager. The flag still flips to true on mutation and clears on
  the no-op save. Harmless.
- **Connection loss mid-edit**: state transitions back to
  `DistingStateConnected` or `DistingStateInitial`, neither of which
  has `isDirty`. Reconnecting goes through the sync flow which builds
  a fresh `DistingStateSynchronized` (clean). Any unsaved edits are
  lost — that's existing behaviour, unchanged.
- **MCP server tool calls** that mutate state (`add_algorithm`,
  `set_parameter_value`, etc.) flow through the same cubit methods, so
  they correctly mark dirty. MCP-driven save is fixed via the
  controller change above.
- **`loadPresetOffline`** (cubit.dart line 300): clears checkpoints and
  delegates to `_offlineDemoDelegate.loadPresetOffline`, which builds
  a fresh `DistingStateSynchronized`. Default `isDirty: false` applies.
- **Plugin install** (`plugin_delegate.dart` line 663): updates the
  algorithm *library*, not preset contents. Out of scope; preserve
  dirty.
- **SD card preset operations**: scanning is read-only; loading goes
  through `loadPresetImpl` which clears via refresh.
- **Build-runner**: the freezed change requires regenerating
  `disting_state.freezed.dart`. Run
  `dart run build_runner build --delete-conflicting-outputs` per
  CLAUDE.md.

## Test plan

New file `test/cubit/preset_dirty_indicator_test.dart`:

1. Fresh synchronized state has `isDirty == false`.
2. After `updateParameterValue(...)`, state is dirty.
3. After `onAddAlgorithm(...)`, state is dirty.
4. After `onRemoveAlgorithm(...)`, state is dirty.
5. After `moveAlgorithmUp/Down(...)`, state is dirty.
6. After `renamePreset(...)` to a new name, state is dirty until the
   autosave resolves, then becomes clean.
7. After `saveMapping(...)`, state is dirty.
8. After a parameter-refresh emit (simulated via the live polling
   delegate), the prior `isDirty` is **preserved** — true stays true,
   false stays false.
9. After a rename verification correction emit, prior `isDirty` is
   preserved.
10. `cubit.savePreset()` clears the flag on success.
11. `cubit.savePreset()` leaves the flag set on failure (manager
    throws).
12. `cubit.savePreset()` is a no-op when state is not
    `DistingStateSynchronized`.
13. `loadPreset(...)` clears the flag (via refresh path).
14. `newPreset()` clears the flag (via refresh path).
15. `refresh()` clears the flag.
16. `disting_controller_impl.savePreset()` (MCP path) clears the flag.

Widget test in `test/ui/synchronized_screen_dirty_indicator_test.dart`:

1. With `isDirty: false`, header text is `Preset: <name>`.
2. With `isDirty: true`, header text is `Preset: <name> *`.
3. Semantic label includes "unsaved changes" when dirty.

Manual smoke (cannot run from CI):

- Connect to hardware (or use demo mode).
- Move a parameter slider; observe asterisk appears.
- Hit Save Preset; observe asterisk clears.
- Rename preset; observe asterisk appears momentarily then clears
  (autosave).
- Load a different preset; observe asterisk clears.
- Trigger MCP save via the controller; observe asterisk clears.

## Rollout

Single PR. No feature flag — the indicator is purely additive UI and
the new cubit field is free for any code path that ignores it. Run
`flutter analyze` (must pass with zero warnings) and `flutter test`
before opening the PR.
