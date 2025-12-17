# nt_helper - Disting NT MIDI Helper

Flutter app for Disting NT Eurorack module: preset management, algorithm loading, parameter control via MIDI SysEx.

**Platforms:** Linux, macOS, iOS, Android, Windows
**Modes:** Demo (no hardware), Offline (cached), Connected (live MIDI)

## Architecture

- **State:** Cubit pattern with delegate decomposition (`lib/cubit/disting_cubit.dart`)
- **MIDI:** Interface-based with mock/offline/live implementations (`lib/domain/i_disting_midi_manager.dart`)
- **Database:** Drift ORM (`lib/db/database.dart`)
- **MCP:** Model Context Protocol server (`lib/services/mcp_server_service.dart`)

### DistingCubit Delegates

The main cubit is decomposed into delegates and mixins for maintainability.

**Rule of thumb**: keep `lib/cubit/disting_cubit.dart` as an orchestration/facade layer. Add new non-trivial behavior in a delegate or an existing ops mixin.

| File | Type | Purpose |
|------|------|---------|
| `*_connection_delegate.dart` | Delegate | MIDI device connection |
| `*_parameter_fetch_delegate.dart` | Delegate | Parameter loading with retry |
| `*_parameter_refresh_delegate.dart` | Delegate | Live parameter polling |
| `*_parameter_value_delegate.dart` | Delegate | Parameter value writes + verification |
| `*_parameter_string_delegate.dart` | Delegate | Parameter value-string reads/writes |
| `*_mapping_delegate.dart` | Delegate | CV/MIDI/i2c/performance mappings |
| `*_slot_state_delegate.dart` | Delegate | Slot state updates + routing refresh |
| `*_slot_maintenance_delegate.dart` | Delegate | Slot repair/refresh/reset helpers |
| `*_state_refresh_delegate.dart` | Delegate | Refresh state from MIDI manager |
| `*_state_helpers_delegate.dart` | Delegate | Routing + offline metadata helpers |
| `*_algorithm_library_delegate.dart` | Delegate | Algorithm library refresh/rescan |
| `*_plugin_delegate.dart` | Delegate | Plugin installation |
| `*_sd_card_delegate.dart` | Delegate | SD card preset listing/scanning |
| `*_lua_reload_delegate.dart` | Delegate | Lua reload with state preservation |
| `*_offline_demo_delegate.dart` | Delegate | Demo/offline mode |
| `*_hardware_commands_delegate.dart` | Delegate | Screenshot/display/reboot/remount |
| `*_monitoring_delegate.dart` | Delegate | CPU monitoring + USB video |
| `*_refresh_delegate.dart` | Delegate | Refresh/cancelSync orchestration |
| `*_algorithm_ops.dart` | Mixin | Algorithm operations |
| `*_preset_ops.dart` | Mixin | Preset operations |
| `*_slot_ops.dart` | Mixin | Slot operations |

All use `part of 'disting_cubit.dart'` for private access. See `docs/architecture/coding-standards.md` for pattern details and guardrails.

## Routing System

OO framework in `lib/core/routing/` for data-driven routing visualization.

- `AlgorithmRouting.fromSlot()` creates routing from live Slot data
- `ConnectionDiscoveryService` discovers connections via bus assignments (1-12 inputs, 13-20 outputs)
- `RoutingEditorCubit` orchestrates state; `RoutingEditorWidget` displays only
- ES-5 algorithms (clck, eucp, clkm, clkd, pycv) support direct output routing via `Es5DirectOutputAlgorithmRouting`

## Key Files

| Area | Path |
|------|------|
| State | `lib/cubit/disting_cubit.dart` (+ delegates/mixins) |
| Routing | `lib/core/routing/algorithm_routing.dart` |
| Main UI | `lib/ui/synchronized_screen.dart` |
| Routing UI | `lib/ui/widgets/routing/routing_editor_widget.dart` |
| Metadata | `lib/services/algorithm_metadata_service.dart` |

## Commands

```
flutter analyze          # Must pass with zero warnings
flutter test             # Run before commits
flutter run -d macos --print-dtd   # Run with DTD URL for MCP connection
```

## Release

```
./version && git push && git push --tags           # Quick
./version patch && git push && git push --tags     # Patch
./version major && git push && git push --tags     # Major
```

See [RELEASE_PROCESS.md](./RELEASE_PROCESS.md) for details.

## MCP Docs

- [MCP API Guide](./docs/mcp-api-guide.md) — 4-tool API (search, new, edit, show)
- [MCP Mapping Guide](./docs/mcp-mapping-guide.md) — CV, MIDI, i2c mappings

## Rules

- Zero tolerance for `flutter analyze` errors
- Never add debug logging unless explicitly asked
- Do not restart the app if already running — disrupts MCP/debugger connections
