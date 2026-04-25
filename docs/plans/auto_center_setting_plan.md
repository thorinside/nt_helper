# Plan: Auto-center on algorithm selection setting

## Goal

Add a user preference "Auto-center on algorithm selection" (default `true`) that gates the existing behavior where the routing canvas auto-scrolls/centers on an algorithm node when that algorithm becomes the sole focused selection.

## Current behavior (verified)

The auto-centering is mediated by `RoutingEditorState.cascadeScrollTarget`. The trigger pipeline is:

1. User selects an algorithm via one of these paths:
   - Plain tap on a node in the routing canvas — `routing_editor_widget.dart:3209` calls `cubit.setFocusedAlgorithm(nodeId)`.
   - Cross-screen sync when the algorithm list changes selection — `synchronized_screen.dart:392` calls `_routingEditorCubit?.setFocusedAlgorithmBySlotIndex(slotIndex)`, which delegates to `setFocusedAlgorithm()`.
2. `setFocusedAlgorithm()` (`routing_editor_cubit.dart:3314-3327`) emits a state with `cascadeScrollTarget` set to the node's centroid.
3. `RoutingEditorWidget.build`'s `BlocConsumer.listener` (`routing_editor_widget.dart:1042-1064`) detects the new `cascadeScrollTarget` and animates the scroll controllers via `_scrollToPosition()`. After the animation it calls `clearCascadeScrollTarget()`.

Two other paths emit a `cascadeScrollTarget` but are NOT selection events and must keep working:

- `_applyCascadeLayout()` (`routing_editor_cubit.dart:3079`) emits a centroid scroll target after running the layout algorithm. The user explicitly invoked layout — that is not an algorithm-selection event, so this scroll must stay unconditional.
- `toggleAlgorithmFocus()` (`routing_editor_cubit.dart:3299`, used for shift-click multi-select) intentionally does NOT set `cascadeScrollTarget` today. No change needed there.

## Setting design

Mirror the existing `cpuMonitorEnabled` boolean setting in `lib/services/settings_service.dart`:

| Aspect | Value |
|---|---|
| Setting key constant | `_autoCenterOnSelectionKey = 'auto_center_on_selection'` |
| Default constant | `defaultAutoCenterOnSelection = true` |
| Public getter | `bool get autoCenterOnSelection` |
| Public setter | `Future<bool> setAutoCenterOnSelection(bool value)` |
| Persistence | `SharedPreferences.setBool` (existing infrastructure, already initialized in `main.dart`) |
| ValueNotifier | Not required — the value is read at the moment a selection happens, not bound reactively, and the UI for toggling rebuilds itself locally inside `_SettingsDialogState`. |

## Gating point

Single point of control: `RoutingEditorCubit.setFocusedAlgorithm()`.

```dart
void setFocusedAlgorithm(String algorithmId) {
  final currentState = state;
  if (currentState is! RoutingEditorStateLoaded) return;

  final shouldAutoCenter = SettingsService().autoCenterOnSelection;
  Offset? scrollTarget;
  if (shouldAutoCenter) {
    final nodePos = currentState.nodePositions[algorithmId];
    scrollTarget = nodePos != null
        ? Offset(nodePos.x + nodePos.width / 2,
                 nodePos.y + nodePos.height / 2)
        : null;
  }

  emit(currentState.copyWith(
    focusedAlgorithmIds: {algorithmId},
    cascadeScrollTarget: scrollTarget,
  ));
}
```

Rationale for gating here, not in the widget listener:
- `setFocusedAlgorithmBySlotIndex()` already delegates to `setFocusedAlgorithm()`, so a single change covers both selection paths.
- `_applyCascadeLayout()` continues to set `cascadeScrollTarget` independently — its scroll is preserved without conditional logic.
- The widget listener stays generic ("if there is a target, scroll to it"), so future producers of `cascadeScrollTarget` aren't accidentally gated.

## Settings UI placement

Add a new `SwitchListTile` in `lib/services/settings_service.dart` `_SettingsDialogState.build()`, immediately after the "Show Contextual Help Hints" tile (around current line 810), before the `SizedBox(height: 24)` that precedes the Gallery URL section. Mirror the haptics/CPU-monitor toggle pattern.

- **Title:** `"Auto-Center on Algorithm Selection"` — chosen as a noun phrase that names the behavior. Neighboring tiles use a mix of imperative ("Enable…", "Show…", "Allow…") and noun-phrase ("Collapse Algorithm Pages by Default") forms; either fits.
- **Subtitle:** `"Automatically scroll the routing canvas to the selected algorithm"` (present-tense action, matches "Provide tactile feedback…", "Show CPU usage…", "Display helpful hints…").

Wire-up checklist (mirrors CPU monitor):
- Add `late bool _autoCenterOnSelection;` to `_SettingsDialogState`.
- Initialize in `_loadSettings()` (`settings.autoCenterOnSelection`).
- Persist in `_saveSettings()` (`await settings.setAutoCenterOnSelection(_autoCenterOnSelection);`).
- Reset in `SettingsService.resetToDefaults()` (`await setAutoCenterOnSelection(defaultAutoCenterOnSelection);`).

## Files changed

| File | Why |
|---|---|
| `lib/services/settings_service.dart` | Add key, default, getter, setter, dialog state field, load/save/reset wiring, toggle UI. |
| `lib/cubit/routing_editor_cubit.dart` | Gate `cascadeScrollTarget` in `setFocusedAlgorithm()` based on `SettingsService().autoCenterOnSelection`. |
| `docs/plans/auto_center_setting_plan.md` | This plan (already created). |
| `test/cubit/routing_editor_cubit_auto_center_test.dart` (new) | Unit test that confirms `setFocusedAlgorithm()` sets `cascadeScrollTarget` when the setting is true and leaves it null when the setting is false. Stubs the singleton via `SharedPreferences.setMockInitialValues`. |

## Tests

A unit test under `test/cubit/` that follows the established pattern (see `test/cubit/routing_editor_cubit_layout_test.dart` for a reference, and `test/services/settings_service_ui_scale_test.dart:12` for the SettingsService init pattern):

1. In `setUp()` for each test, call `SharedPreferences.setMockInitialValues({'auto_center_on_selection': <value>})` BEFORE calling `SettingsService().init()`. The `SettingsService` singleton persists across tests, so each `setUp` must reset the mock to the expected value and re-init so the getter sees the seeded value.
2. Construct a `RoutingEditorCubit` with a minimal `RoutingEditorStateLoaded` (use the `MockDistingCubit` pattern from `routing_editor_cubit_layout_test.dart`) containing a single algorithm with a known `NodePosition`.
3. Call `cubit.setFocusedAlgorithm('algo-id')`.
4. Assert `cascadeScrollTarget` is `null` when setting is `false`, and equals the node centroid when setting is `true`.
5. Assert `focusedAlgorithmIds` contains the id in both cases (focus is independent of scroll).

If hooking the cubit into a fully-loaded state is too heavy, fall back to a focused widget test, or extract the centroid+gating logic behind a small testable method. Prefer the unit test.

### Test isolation note

Because `SettingsService` is a singleton, tests that toggle the setting must be ordered carefully. In each `setUp`, seed `setMockInitialValues` with the desired bool and re-call `init()` — do not rely on cross-test state.

## Edge cases / open questions (for gap analysis)

- Should the setting also gate the cascade-layout scroll? Current plan: NO, because that's a user-initiated layout action, not selection. The setting name says "on algorithm selection".
- Toggling mid-session: setting is read at the next selection event, so changes take effect immediately without a restart.
- First launch: default is `true`, so existing behavior is preserved on upgrade (no migration needed — `getBool` falls back to the default constant).
- Multiple windows / split screen: SharedPreferences is process-wide; both panes see the same setting. No special handling.
- Reset App Data: the new key is a simple bool, will be cleared along with everything else by the existing reset flow.
- Demo / offline mode: setting lives in app preferences, unaffected by mode.
- Accessibility: `accessible_routing_list_view.dart` destructures `cascadeScrollTarget` from the state but does not consume it (no scroll-to-target in list mode). a11y mode is unaffected — confirmed.
- Init-order safety: `SettingsService().init()` is awaited in `lib/main.dart:121` before `runApp`, well before any `RoutingEditorCubit` is constructed by the provider tree. The getter also falls back to the constant default if `_prefs` is null. No race.
- Localization: this codebase has no `.arb`/`l10n` setup. Strings live inline. No translation step required.

## Out of scope (noted but not addressed)

During audit, a pre-existing bug was identified: `SettingsService.resetToDefaults()` (line 428-447) is missing several settings (e.g. `chatEnabled`, `chatPanelWidth`, `dismissedUpdateVersion`, etc.). The new `autoCenterOnSelection` reset call WILL be added per this plan; existing missing resets are out of scope and will not be fixed here.
