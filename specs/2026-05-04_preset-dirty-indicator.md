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
- No restructuring of the existing rename autosave path. The autosave
  is best-effort and the dirty flag will simply remain set during the
  rename-and-autosave window and clear on the next save / refresh /
  load (see "Edge cases").

## Affected files

### State

- `lib/cubit/disting_state.dart` — add `isDirty` field to
  `DistingStateSynchronized`.

### Cubit / delegates

- `lib/cubit/disting_cubit.dart` — add facade `savePreset()` method.
- `lib/cubit/disting_cubit_preset_ops.dart` — `renamePresetImpl`
  optimistic emit (line 39) sets `isDirty: true`.
- `lib/cubit/disting_cubit_state_refresh_delegate.dart` — explicitly
  emit `isDirty: false` after a refresh from device (line 34).
- `lib/cubit/disting_cubit_parameter_value_delegate.dart` — set on
  parameter writes (lines 59, 107).
- `lib/cubit/disting_cubit_parameter_string_delegate.dart` — set on
  string parameter writes (lines 43, 93, 131).
- `lib/cubit/disting_cubit_algorithm_ops.dart` — set on add / remove /
  move-up / move-down optimistic emits (lines 110, 126, 223, 319, 437).
  Verification emits (lines 172, 185, 370, 483) preserve current
  `isDirty` (don't reset it).
- `lib/cubit/disting_cubit_slot_ops.dart` — set on slot custom-name
  changes (lines 33, 69).
- `lib/cubit/disting_cubit_slot_state_delegate.dart` — set on
  slot-state mutations (lines 71, 128, 170, 196, 227, 248).
- `lib/cubit/disting_cubit_mapping_delegate.dart` — set on CV / MIDI /
  i2c / performance mapping changes (lines 84, 135, 175).
- `lib/cubit/disting_cubit_perf_page_delegate.dart` — set on perf page
  item edits (lines 34, 62). Perf page item edits *are* preset
  mutations; they persist in the preset bytes alongside slot data.
- `lib/cubit/disting_cubit_slot_maintenance_delegate.dart` — set on
  slot repair (lines 98, 135).
- `lib/cubit/disting_cubit_offline_demo_delegate.dart` — fresh
  construction; `@Default(false) isDirty` applies, no change needed.
- `lib/cubit/disting_cubit_connection_delegate.dart` — initial sync
  construction; `@Default(false) isDirty` applies, no change needed.

### UI

- `lib/disting_app.dart` — pass `state.isDirty` to `SynchronizedScreen`
  (construction site at line 432).
- `lib/ui/synchronized_screen.dart` — accept `isDirty` constructor
  argument; render asterisk in `_buildPresetInfoEditor` and in the
  semantic label; switch the three direct
  `requireDisting().requestSavePreset()` call sites (lines 503, 1828,
  1851) to a new `cubit.savePreset()` facade so the flag clears on
  save.

### Services

- `lib/services/disting_controller_impl.dart` — route the MCP-driven
  `savePreset` (line 329) through the cubit's `savePreset()` facade so
  external saves also clear the flag.

### Tests

- `test/cubit/preset_dirty_indicator_test.dart` — new file. See *Test
  plan* below.
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
freshly-synchronized state is clean, which matches the data flow: every
path that creates a `DistingStateSynchronized` either reads from device
(clean) or constructs from a freshly-loaded preset (clean).

### Mutation rule (cubit-side)

**Every site that emits state reflecting a *user-initiated* change to
`slots`, `presetName`, in-slot mapping data, or perf page items sets
`isDirty: true`.**

The codebase has two emission patterns: most delegates call
`_emitState(...)` (the wrapper at `disting_cubit.dart:305`); a few
files (notably `disting_cubit_algorithm_ops.dart`) call `emit(...)`
directly. The wrapper is a thin pass-through; both patterns behave
identically with respect to `copyWith(isDirty: true)`.

Concretely, the following call sites add `isDirty: true` to their
`copyWith(...)` argument lists (line numbers from current `main`):

| File | Line | Operation |
|------|------|-----------|
| `disting_cubit_parameter_value_delegate.dart` | 59, 107 | parameter write (real-time + release) |
| `disting_cubit_parameter_string_delegate.dart` | 43, 93, 131 | string parameter write |
| `disting_cubit_algorithm_ops.dart` | 110, 126, 223, 319, 437 | add / remove / move algorithms — optimistic emits |
| `disting_cubit_slot_ops.dart` | 33, 69 | slot custom name |
| `disting_cubit_slot_state_delegate.dart` | 71, 128, 170, 196, 227, 248 | slot state updates |
| `disting_cubit_slot_maintenance_delegate.dart` | 98, 135 | slot repair |
| `disting_cubit_mapping_delegate.dart` | 84, 135, 175 | CV / MIDI / i2c / performance mapping |
| `disting_cubit_perf_page_delegate.dart` | 34, 62 | perf page item edits |
| `disting_cubit_preset_ops.dart` | 39 | preset rename optimistic emit |

The following call sites are **not user mutations** and must **not**
set `isDirty: true`. They preserve the current `isDirty` value
(omit the field from `copyWith` so it stays unchanged) — they reflect
device truth or non-preset state:

| File | Line | Why |
|------|------|-----|
| `disting_cubit_parameter_refresh_delegate.dart` | 66, 115, 247, 317 | live polling — device truth, not user changes |
| `disting_cubit_cc_notification_delegate.dart` | 216 | CC value reflection from device |
| `disting_cubit_state_refresh_delegate.dart` | 16, 47 | loading/error paths (the success path explicitly clears — see below) |
| `disting_cubit_hardware_commands_delegate.dart` | 20 | screenshot only |
| `disting_cubit_monitoring_delegate.dart` | 74, 90 | video/CPU stream state |
| `disting_cubit_algorithm_library_delegate.dart` | all | algorithm library cache, not preset content |
| `disting_cubit_connection_delegate.dart` | all | connection lifecycle (initial sync uses default `false`) |
| `disting_cubit_plugin_delegate.dart` | 663 | algorithm library, not preset content |
| `disting_cubit_algorithm_ops.dart` | 172, 185, 370, 483 | post-add/move *verification* refreshes — preserve isDirty (the optimistic emit already set it; these refreshes only correct slot details) |

Routing changes flow through the existing `RoutingEditorCubit`, which
calls back into `DistingCubit` via parameter writes — so they're
covered by the parameter-write path automatically.

### Clear rule

`isDirty` is set back to `false` at exactly the points where the
in-memory preset is fully resynchronised with a known clean baseline:

1. **Save completes** — `cubit.savePreset()` emits `isDirty: false`
   on success (see "Save flow" below).
2. **State refresh from device** —
   `_StateRefreshDelegate.refreshStateFromManager` line 34 explicitly
   sets `isDirty: false`. Refreshing pulls fresh slots and preset
   name from the device, so the in-memory copy *is* the device copy.
   We set this **explicitly** rather than relying on Freezed's
   default, because the existing emit chains a `copyWith` from the
   prior (possibly dirty) state.
3. **New preset** — `newPresetImpl` calls `requestNewPreset()` then
   `_refreshStateFromManager()`, which resets via #2.
4. **Load preset (online)** — `loadPresetImpl` calls
   `requestLoadPreset()` then `_refreshStateFromManager()`, which
   resets via #2.
5. **Load preset (offline)** — `_OfflineDemoDelegate.loadPresetOffline`
   constructs a fresh `DistingStateSynchronized`; default
   `isDirty: false` applies.
6. **Demo / offline init** — same as #5.

The rename verification path (`disting_cubit_preset_ops.dart` lines
56, 74) corrects the preset name to device truth if the rename failed.
These corrections **preserve the existing `isDirty` value** — they're
neither a fresh mutation by the user nor a full refresh.

### Save flow

The current save path bypasses the cubit: three sites in
`synchronized_screen.dart` (lines 503, 1828, 1851) call
`cubit.requireDisting().requestSavePreset()` directly. Add a facade:

```dart
// disting_cubit.dart
Future<void> savePreset() async {
  final s = state;
  if (s is! DistingStateSynchronized) return;
  try {
    await s.disting.requestSavePreset();
    final cur = state;
    if (cur is DistingStateSynchronized) {
      _emitState(cur.copyWith(isDirty: false));
    }
  } catch (_) {
    // Leave isDirty as-is; a failed save did not actually persist.
    rethrow;
  }
}
```

Re-reading `state` after the `await` is deliberate: a parameter write
or refresh may have landed during the save. We always re-check the
current state class before emitting.

Update the three call sites in `synchronized_screen.dart` to use
`cubit.savePreset()`. The "Save First & New" path (line 1828) becomes:

```dart
try {
  await cubit.savePreset();
  cubit.newPreset();
} catch (e) {
  // existing error UI
}
```

so `newPreset()` only runs on a successful save.

The auto-save inside `renamePresetImpl` (line 45) — `disting.requestSavePreset().catchError((_) {})`
— is **out of scope for this change**. It's a fire-and-forget best-effort
operation; the dirty flag will simply remain set until the next save /
refresh / load. (The user-visible behaviour: rename a preset and the
asterisk will appear briefly until the next refresh or save.) This is
acceptable and avoids touching the rename verification machinery in
this PR.

### MCP / external save paths

`DistingControllerImpl.savePreset`
(`lib/services/disting_controller_impl.dart` line 329) currently calls
`_getManager().requestSavePreset()` directly, bypassing the cubit. To
keep the dirty flag in sync for MCP-driven saves, route through the
cubit:

```dart
await _distingCubit.savePreset();
```

If the controller cannot reach a cubit instance in some test paths,
fall back to the existing direct-manager call — the contract is "if a
cubit is reachable, clear the flag through it."

The `metadata_sync_cubit.dart` line 329 save is a different flow that
already orchestrates `_refreshStateFromManager()` itself, which clears
the flag via the refresh rule. No change needed.

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
icon, no colour change. Spoken accessibility uses the phrase "unsaved
changes" rather than reading "asterisk" aloud. (Convention: VS Code,
Vim, Sublime, Xcode all use a trailing asterisk or modified-dot for
unsaved documents.)

## Edge cases

- **Rename to the same name**: `renamePresetImpl` early-returns
  (line 36) before emitting, so `isDirty` is unchanged. Correct.
- **Parameter slider scrubbing back to original value**: marks dirty.
  Acceptable per non-goals.
- **Failed save**: the `await disting.requestSavePreset()` may throw or
  silently fail; the cubit's `try/rethrow` keeps `isDirty: true` so
  the user retains the indicator. Acceptable; matches user mental
  model ("the save didn't work, my changes are still unsaved").
- **Save succeeds but device disconnects mid-save** (state machine
  transitions out of `DistingStateSynchronized` between the await and
  the emit): the post-save emit is skipped because the state class
  no longer matches. On reconnect, the sync flow builds a fresh
  `DistingStateSynchronized` (default `isDirty: false`). This is
  correct — the device persisted, and the new state reflects device
  truth.
- **User mutation lands during a save**: the `await` in `savePreset`
  yields the event loop. If the user moves a slider during the save,
  the slider write emits `isDirty: true` first, then `savePreset`
  re-reads `state` and emits `isDirty: false`. The newer mutation is
  silently re-marked clean. **This is a known small race window**
  measured in tens of milliseconds (one MIDI request/response). It is
  not worth a counter or sequence number for this feature; the next
  user mutation will mark it dirty again.
- **User mutation lands during a refresh**: same race shape — refresh
  emits `isDirty: false`, the mutation lands and emits `true`. Order
  on the event queue determines outcome. Acceptable; matches the
  existing optimistic-emit-then-verify pattern used throughout the
  cubit.
- **Live parameter polling** (`_parameter_refresh_delegate`) updates
  `slots` from device truth. These must **not** flip `isDirty: true`
  even though they emit slot changes. The mutation table above
  explicitly excludes them; they preserve current `isDirty`.
- **CC notification reflections** (`_cc_notification_delegate`) likewise
  reflect device-side changes; excluded.
- **Algorithm-op verification refreshes** (`_algorithm_ops` lines 172,
  185, 370, 483) re-emit slot details a beat after the optimistic
  emit. The optimistic emit already set dirty; verification preserves
  it (omit `isDirty` from `copyWith`).
- **Plugin install** doesn't directly mutate preset content. If
  installing a plugin causes a `_refreshStateFromManager()` to fire,
  the refresh path correctly clears the flag — same code path as a
  manual refresh. Consistent.
- **Lua reload** (`disting_cubit_lua_reload_delegate.dart`) restores
  parameter values on the device by replaying parameter writes. Each
  parameter write goes through the standard parameter-write path,
  which marks dirty. This matches user mental model: a Lua reload
  that re-applies values *is* a mutation from the device's
  saved-preset perspective until the next explicit save.
- **Checkpoint restore** likewise replays parameter writes; marks
  dirty. Correct.
- **Offline mode**: parameter writes still queue to the
  `OfflineDistingMidiManager`, which persists to local storage on
  `requestSavePreset()`. The dirty flag behaves identically.
- **Demo mode**: `requestSavePreset()` is a no-op on the mock manager.
  The flag still flips to true on mutation and clears on the no-op
  save. Harmless.
- **Connection loss mid-edit**: state transitions back to
  `DistingStateConnected` or `DistingStateInitial`, neither of which
  has `isDirty`. Reconnecting goes through the sync flow which builds
  a fresh `DistingStateSynchronized` (clean). Any unsaved edits are
  lost — that's existing behaviour, unchanged.
- **Build-runner**: the freezed change requires regenerating
  `disting_state.freezed.dart`. Run
  `dart run build_runner build --delete-conflicting-outputs` per
  CLAUDE.md.

## Test plan

New file `test/cubit/preset_dirty_indicator_test.dart`:

1. Fresh sync state has `isDirty == false`.
2. After `updateParameterValue(...)`, state is dirty.
3. After `onAddAlgorithm(...)`, state is dirty.
4. After `onRemoveAlgorithm(...)`, state is dirty.
5. After `moveAlgorithmUp/Down(...)`, state is dirty.
6. After `renamePreset(...)` to a new name, optimistic state is dirty.
7. After `saveMapping(...)`, state is dirty.
8. After `setPerfPageItem(...)`, state is dirty.
9. After a parameter-refresh emit (simulated via the live polling
   delegate), state preserves dirty (still true if it was true; still
   false if it was false).
10. `savePreset()` clears the flag on success.
11. `savePreset()` leaves the flag set on failure (manager throws).
12. `savePreset()` does not crash if state is not synchronized (early
    return).
13. `loadPreset(...)` clears the flag (via refresh path).
14. `newPreset()` clears the flag (via refresh path).
15. `refresh()` clears the flag.
16. Algorithm-op verification refresh preserves prior dirty state.

Widget test in `test/ui/synchronized_screen_dirty_indicator_test.dart`:

1. With `isDirty: false`, header text is `Preset: <name>`.
2. With `isDirty: true`, header text is `Preset: <name> *`.
3. Semantic label includes "unsaved changes" when dirty; does not
   include it when clean.

Manual smoke (cannot run from CI):

- Connect to hardware (or use demo mode).
- Move a parameter slider; observe asterisk appears.
- Hit Save Preset; observe asterisk clears.
- Add an algorithm; observe asterisk appears, persists across
  verification refresh.
- Load a different preset; observe asterisk clears.
- Trigger a refresh; observe asterisk clears.

## Rollout

Single PR. No feature flag — the indicator is purely additive UI and
the new cubit field is free for any code path that ignores it. Run
`dart run build_runner build --delete-conflicting-outputs` first
because the freezed state class changes. Then `flutter analyze` (must
pass with zero warnings) and `flutter test` before opening the PR.
