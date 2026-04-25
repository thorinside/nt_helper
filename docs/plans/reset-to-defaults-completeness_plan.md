# Plan: `SettingsService.resetToDefaults()` completeness

## Problem

`SettingsService.resetToDefaults()` (`lib/services/settings_service.dart:439-460`) only resets a subset of persisted settings. Several keys (chat-related, LLM-related, update-tracking) are never reset. Users invoking "reset to defaults" are left with stale values for these.

Flagged during the audit of PR #120 (auto-center on selection). Pre-existing bug, not a regression.

## Complete persisted-key inventory

Source: `lib/services/settings_service.dart`. Each row corresponds to a `static const String _xxxKey = '...';` constant.

| # | Key constant | Storage key | Type | Default | In `resetToDefaults`? |
|---|---|---|---|---|---|
| 1 | `_requestTimeoutKey` | `request_timeout_ms` | int | `200` (`defaultRequestTimeout`) | yes |
| 2 | `_interMessageDelayKey` | `inter_message_delay_ms` | int | `0` (`defaultInterMessageDelay`) | yes |
| 3 | `_hapticsEnabledKey` | `haptics_enabled` | bool | `true` (`defaultHapticsEnabled`) | yes |
| 4 | `_mcpEnabledKey` | `mcp_enabled` | bool | `false` (`defaultMcpEnabled`) | yes |
| 5 | `_startPagesCollapsedKey` | `start_pages_collapsed` | bool | `false` (`defaultStartPagesCollapsed`) | yes |
| 6 | `_galleryUrlKey` | `gallery_url` | string | `defaultGalleryUrl` | yes |
| 7 | `_graphqlEndpointKey` | `graphql_endpoint` | string | `defaultGraphqlEndpoint` | yes |
| 8 | `_includeCommunityPluginsKey` | `include_community_plugins_in_presets` | bool | `true` | yes |
| 9 | `_overlayPositionXKey` | `overlay_position_x` | double | `-1.0` | yes |
| 10 | `_overlayPositionYKey` | `overlay_position_y` | double | `-1.0` | yes |
| 11 | `_overlaySizeScaleKey` | `overlay_size_scale` | double | `1.0` | yes |
| 12 | `_showDebugPanelKey` | `show_debug_panel` | bool | `true` | yes |
| 13 | `_showContextualHelpKey` | `show_contextual_help` | bool | `true` | yes |
| 14 | `_algorithmCacheDaysKey` | `algorithm_cache_days` | int | `2` | yes |
| 15 | `_cpuMonitorEnabledKey` | `cpu_monitor_enabled` | bool | `true` | yes |
| 16 | `_dismissedUpdateVersionKey` | `dismissed_update_version` | string? | `null` | **no** |
| 17 | `_lastUpdateCheckTimestampKey` | `last_update_check_timestamp` | int? | `null` | **no** |
| 18 | `_splitDividerPositionKey` | `split_divider_position` | double | `0.5` | yes |
| 19 | `_mcpRemoteConnectionsKey` | `mcp_remote_connections` | bool | `false` | yes |
| 20 | `_chatEnabledKey` | `chat_enabled` | bool | `false` | **no** |
| 21 | `_chatPanelWidthKey` | `chat_panel_width` | double | `360` | **no** |
| 22 | `_chatLlmProviderKey` | `chat_llm_provider` | string | `LlmProviderType.anthropic` | **no** |
| 23 | `_anthropicApiKeyKey` | `anthropic_api_key` | string? | `null` | **no** |
| 24 | `_openaiApiKeyKey` | `openai_api_key` | string? | `null` | **no** |
| 25 | `_anthropicModelKey` | `anthropic_model` | string | `'claude-haiku-4-5-20251001'` | **no** |
| 26 | `_openaiModelKey` | `openai_model` | string | `'gpt-5-nano'` | **no** |
| 27 | `_openaiBaseUrlKey` | `openai_base_url` | string? | `null` | **no** |
| 28 | `_uiScaleKey` | `ui_scale` | double | `1.0` | yes |
| 29 | `_autoCenterOnSelectionKey` | `auto_center_on_selection` | bool | `true` | yes |

**Missing from reset:** 10 keys — `dismissedUpdateVersion`, `lastUpdateCheckTimestamp`, `chatEnabled`, `chatPanelWidth`, `chatLlmProvider`, `anthropicApiKey`, `openaiApiKey`, `anthropicModel`, `openaiModel`, `openaiBaseUrl`.

## Chosen pattern

**Hybrid (option c+):** keep individual getter/setter pairs as-is, but introduce a private static `List<String>` registry of every persisted key constant, and rewrite `resetToDefaults()` to remove every registered key (defaults then take effect via the existing getter fallbacks). Add a regression-guard test that scans `settings_service.dart` for all `static const String _xxxKey = '...';` declarations and asserts each one is in the registry.

### Justification

Option (a)/(b) (single registry of `(key, default)` tuples or per-setting `_PrefDef<T>`) require touching every getter/setter and add real complexity for typed access — a much bigger diff for a bug fix. Option (c) (test only) catches *value* regressions but not *missing-key* regressions.

The hybrid keeps the smallest diff (just adds a list and rewrites `resetToDefaults`), but uses `prefs.remove(key)` for each registered key. This is exhaustive by construction because:

1. The list is the single source of truth for "what does this service own?"
2. `remove()` always restores defaults via the getter fallback (`?? default`), so we cannot accidentally pass a wrong default — there is no default duplicated at the reset site.
3. The source-scanning test guarantees that any new `_xxxKey = '...';` constant must appear in the registry, or CI fails. So "add a setting" and "reset a setting" become a single change.

Side benefits:

- For the API-key / nullable settings (`_anthropicApiKeyKey`, `_openaiApiKeyKey`, `_openaiBaseUrlKey`, `_dismissedUpdateVersionKey`, `_lastUpdateCheckTimestampKey`), removing the key correctly restores the `null` default — no special-casing required.
- For settings backed by a `ValueNotifier` (`cpuMonitorEnabled`, `uiScale`), we explicitly resync the notifier value after the bulk-remove since `prefs.remove` does not go through the existing setters.

Note: `prefs.clear()` is **not** acceptable. Other code in the app stores keys in the same `SharedPreferences` (window position in `lib/main.dart`, routing-editor state in `lib/cubit/routing_editor_cubit.dart`, preset browser sort/history in `lib/cubit/preset_browser_cubit.dart`, add-algorithm favorites/view in `lib/ui/add_algorithm_screen.dart`, firmware directory in `lib/ui/firmware/firmware_update_screen.dart`, metadata sync checkpoint, etc.). Reset must scope to keys owned by `SettingsService`.

## Files to modify

| File | Change | Rationale |
|---|---|---|
| `lib/services/settings_service.dart` | Add `_persistedKeys` registry; rewrite `resetToDefaults()` to remove every registered key + resync notifiers; add `@visibleForTesting` accessor for the registry | Core fix |
| `test/services/settings_service_test.dart` (new) | Exhaustive reset test + key-registry source-scan test | Regression guard + acceptance criteria |

No other files need to change. The settings dialog UI (`SettingsDialog` in `settings_service.dart`) does not call `resetToDefaults()` — only the existing UI scale "reset" button calls per-setting setters, which still work. Reset is currently invoked by tests only; behavior of all other code is unchanged.

## Test design

### Test 1 — exhaustive reset (acceptance criteria)

1. Initialize `SharedPreferences` with non-default values for **every** persisted key (mock with `setMockInitialValues` then call `init()`).
2. Verify each getter returns the non-default value (sanity check).
3. Call `resetToDefaults()`.
4. Assert every getter returns the declared default.
5. Assert `_prefs.getKeys()` contains no key from the registry (the underlying storage is clean for these keys).
6. Assert `cpuMonitorEnabledNotifier.value == defaultCpuMonitorEnabled` and `uiScaleNotifier.value == defaultUiScale` (notifier-backed settings resync).

### Test 2 — registry completeness (regression guard)

1. Read `lib/services/settings_service.dart` source as text.
2. Use a regex to extract every `static const String _xxxKey = 'yyy';` declaration's literal value.
3. Assert each extracted key is present in the `_persistedKeys` registry exposed via `@visibleForTesting`.
4. Failure message must explicitly tell the developer: "If you added a new persisted setting, add its key constant to `_persistedKeys` so that `resetToDefaults()` covers it."

This test fails if a developer adds `static const String _newSettingKey = 'new_setting';` without updating the registry — even before they call any new getter/setter on it.

## Acceptance verification

- All existing tests still pass (notably `test/services/settings_service_ui_scale_test.dart`, which already includes a `resetToDefaults` test for `uiScale`).
- New test 1 passes — proves reset is exhaustive.
- New test 2 passes — proves the registry is complete vs. current source.
- `flutter analyze` clean.

## Out of scope

- No change to default values.
- No change to non-reset behavior (getters/setters unchanged).
- No change to UI.
- Settings stored OUTSIDE `SettingsService` (window bounds, routing state, etc.) are intentionally not touched — the bug report scopes to `SettingsService`.

## Gaps integrated

Five Haiku gap-analysis agents reviewed this plan. Material gaps and resolutions:

### G1 — Regex pattern was unspecified (agents 2, 3, 5)

Plan said "use a regex" without committing to one. The `_includeCommunityPluginsKey` declaration wraps across two lines, so naive line-based regexes would miss it. Resolved: the implementation will use this exact pattern, which handles multi-line declarations because `\s*` matches newlines:

```dart
final keyConstantPattern = RegExp(
  r"static\s+const\s+String\s+_\w+Key\s*=\s*'([^']+)'\s*;",
);
```

The single capture group extracts the storage-key literal (e.g. `'request_timeout_ms'`). False-positive risk is negligible: this file has no constants ending in `Key` other than persisted-setting keys.

### G2 — Notifier resync mechanics (agents 1, 2, 3, 4, 5)

Concerns: (a) `prefs.remove()` bypasses setters, so `ValueNotifier`s do not auto-update; (b) `ValueNotifier` only fires when value changes — if a listener was already at the default, no notification is sent (acceptable, since the value is correct). Resolution: after bulk-remove, explicitly assign:

```dart
cpuMonitorEnabledNotifier.value = defaultCpuMonitorEnabled;
uiScaleNotifier.value = defaultUiScale;
```

Confirmed via grep: these are the only two `ValueNotifier`s in `SettingsService`.

### G3 — Registry exposure for the test (agents 3, 4)

Concern: `@visibleForTesting` on a private list still requires an accessor. Resolution: add a `@visibleForTesting` getter `static List<String> get debugPersistedKeys => List.unmodifiable(_persistedKeys);`. Source-scanning test compares the regex-extracted set with this getter's set.

### G4 — Test isolation against singleton state (agent 4)

`SettingsService` is a singleton; tests can leak state. Resolution: each test calls `SharedPreferences.setMockInitialValues({...})` then `await settings.init()` — `init()` re-reads `_prefs`, fully resetting the singleton's view.

### G5 — Mid-reset failure handling (agents 1, 2, 4)

`prefs.remove()` returns a `bool`. Concern: should reset abort, throw, or continue? Resolution: continue (do not abort, do not throw). This matches the existing behavior — the current `resetToDefaults()` ignores setter return values too. Failures of `shared_preferences` writes are extremely rare in practice and there is no useful recovery.

### G6 — Test 1 must set genuinely non-default values (agent 4)

Concern: if the test seeds a value that happens to equal the default, the test passes but doesn't prove anything. Resolution: pick non-default seeds explicitly per type (bool: opposite of default; int: default + 1; double: default + 0.5; string: distinct sentinel). Then the assertion that getters return defaults after reset is meaningful.

### G7 — Stale keys from historical renames (agents 1, 3)

Concern: if a key was ever renamed, the old key value lingers in storage and `resetToDefaults()` won't clean it. Resolution: out of scope. There is no history of renamed keys in this file (verified by `git log -p` on the key constants). The `_persistedKeys` registry is by definition the *current* set of owned keys; old keys are not our concern.

### G8 — `_prefs == null` preservation (agent 5)

Current code returns `false` silently if `init()` was never called. New code (`_prefs?.remove(...) ?? false`) preserves this exactly. No change in contract.

### G9 — Documentation update (agent 5)

Update the doc-comment on `resetToDefaults()` to explain the mechanism (remove keys → getters fall back to defaults). Minor but helpful for future readers.

### Rejected non-issues

- **Plan table label for `_chatLlmProviderKey`** (agent 4 #6): the plan listed the default as `LlmProviderType.anthropic`. That is the *getter* default; the *stored* form is the string `'anthropic'`. The test asserts the getter return value, so the table entry is correct as written.
- **Stronger compile-time guard** (agent 5): a runtime test is sufficient per the acceptance criteria. Codegen / analyzer plugin would be over-engineering.
- **Out-of-`SettingsService` keys reset** (multiple agents): explicitly out of scope per the bug report; the audit confirmed all listed external SharedPreferences usages are unrelated to "user settings."
