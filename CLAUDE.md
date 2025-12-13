# nt_helper - Disting NT MIDI Helper

Flutter app for Disting NT Eurorack module: preset management, algorithm loading, parameter control via MIDI SysEx.

**Platforms:** Linux, macOS, iOS, Android, Windows
**Modes:** Demo (no hardware), Offline (cached), Connected (live MIDI)

## Architecture

- **State:** Cubit pattern (`lib/cubit/disting_cubit.dart`)
- **MIDI:** Interface-based with mock/offline/live implementations (`lib/domain/i_disting_midi_manager.dart`)
- **Database:** Drift ORM (`lib/db/database.dart`)
- **MCP:** Model Context Protocol server (`lib/services/mcp_server_service.dart`)

## Routing System

OO framework in `lib/core/routing/` for data-driven routing visualization.

- `AlgorithmRouting.fromSlot()` creates routing from live Slot data
- `ConnectionDiscoveryService` discovers connections via bus assignments (1-12 inputs, 13-20 outputs)
- `RoutingEditorCubit` orchestrates state; `RoutingEditorWidget` displays only
- ES-5 algorithms (clck, eucp, clkm, clkd, pycv) support direct output routing via `Es5DirectOutputAlgorithmRouting`

## Key Files

| Area | Path |
|------|------|
| State | `lib/cubit/disting_cubit.dart` |
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
