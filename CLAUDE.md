# nt_helper - Disting NT MIDI Helper

Cross-platform Flutter application for managing Disting NT Eurorack module presets and algorithms.

> **Note:** This file contains high-level project information. Detailed documentation has been organized into the [CLAUDE/](./CLAUDE/) directory for better maintainability. See [CLAUDE/index.md](./CLAUDE/index.md) for the complete table of contents.

## Core Concepts

**Purpose:** MIDI SysEx communication with Disting NT hardware for preset management, algorithm loading, and parameter control.

**Platforms:** Linux, macOS, iOS, Android, Windows with desktop drag-drop and backup features.

**Operation Modes:** Demo (no hardware), Offline (cached data), Connected (live MIDI).

## Architecture Patterns

**State Management:** Cubit pattern for application state.

**MIDI Layer:** Interface-based design with multiple implementations (mock, offline, live).

**Database:** Drift ORM for local data persistence.

**MCP Integration:** Model Context Protocol server for external tool access.

## Routing System

The routing editor uses an object-oriented framework for data-driven routing visualization:

### Architecture
- **Source of Truth**: `DistingCubit` exposes synchronized `Slot`s (algorithm + parameters + values)
- **OO Framework**: `lib/core/routing/` contains all routing logic
  - `AlgorithmRouting.fromSlot()` factory creates routing instances from live Slot data
  - Specialized implementations: `PolyAlgorithmRouting`, `MultiChannelAlgorithmRouting`, `Es5DirectOutputAlgorithmRouting`, etc.
  - `ConnectionDiscoveryService` discovers connections via bus assignments (1-12 inputs, 13-20 outputs)
- **State Management**: `RoutingEditorCubit` orchestrates the framework, stores computed state
- **Visualization**: `RoutingEditorWidget` purely displays pre-computed data

### ES-5 Direct Output Support (Epic 4 - Completed 2025-10-28)
Five algorithms support ES-5 direct output routing, where outputs can route directly to ES-5 expander hardware:
- **Clock** (clck) - Single-channel clock generator
- **Euclidean** (eucp) - Multi-channel Euclidean rhythm generator
- **Clock Multiplier** (clkm) - Single-channel clock multiplier
- **Clock Divider** (clkd) - Multi-channel clock divider
- **Poly CV** (pycv) - Polyphonic MIDI/CV converter (gates only)

**Base Class**: `lib/core/routing/es5_direct_output_algorithm_routing.dart` handles dual-mode output logic (ES-5 vs. normal buses) based on "ES-5 Expander" parameter value.

### Key Principles
- All routing logic lives in the OO framework (`lib/core/routing/`)
- Connections are discovered automatically via shared bus assignments
- Port model uses typesafe direct properties (no generic metadata maps)
- The visualization layer contains no business logic
- ES-5 algorithms use dual-mode output: direct to ES-5 when configured, or normal bus routing

### Important Files
- `lib/core/routing/algorithm_routing.dart` – Base class and factory
- `lib/core/routing/es5_direct_output_algorithm_routing.dart` – ES-5 base class
- `lib/core/routing/connection_discovery_service.dart` – Connection discovery
- `lib/cubit/routing_editor_cubit.dart` – State orchestration
- `lib/ui/widgets/routing/routing_editor_widget.dart` – Visualization only

## Development Standards

**Code Quality:** Zero tolerance for `flutter analyze` errors.

**Debugging:** Always use `debugPrint()`, never `print()`.

**Testing:** Run tests before commits. Check for existing test patterns.

## Quick Reference

### Key Services
- State: `lib/cubit/disting_cubit.dart`
- MIDI: `lib/domain/i_disting_midi_manager.dart`
- Database: `lib/db/database.dart`
- MCP Server: `lib/services/mcp_server_service.dart`
- Metadata: `lib/services/algorithm_metadata_service.dart`

### Main UI
- Main Screen: `lib/ui/synchronized_screen.dart`
- Routing Editor: `lib/ui/widgets/routing/routing_editor_widget.dart`
- Gallery: `lib/ui/gallery_screen.dart`
- Plugin Manager: `lib/ui/plugin_manager_screen.dart`

### Commands
- `flutter analyze` – Must pass with zero warnings
- `flutter test` – Run all tests
- `flutter run -d macos --print-dtd` – Run with DevTools for MCP connection

### MCP Dart Connection
To connect MCP Dart tooling:
1. Run `flutter run -d macos --print-dtd`
2. Note the DTD URL from output
3. Use URL after "The Flutter DevTools debugger and profiler on macOS is available at:"
4. Connect MCP tool using the DTD URL

### Release Process
- **Quick Release**: `./version && git push && git push --tags` 
- **Patch Release**: `./version patch && git push && git push --tags`
- **Major Release**: `./version major && git push && git push --tags`
- **📝 Automatic Changelogs**: GitHub Actions now generates beautiful, categorized release notes from commits and PRs
- **Manual Generation**: Use `./scripts/generate-release-notes.sh [tag]` for testing
- **Full Documentation**: See [RELEASE_PROCESS.md](./RELEASE_PROCESS.md) for complete details

---

## Additional Documentation

For detailed information about BMAD-METHOD agents, tasks, and workflows, see:

- **[Full Documentation Index](./CLAUDE/index.md)** - Complete table of contents
- **[BMAD Agents](./CLAUDE/agents.md)** - All available agent definitions
- **[Tasks](./CLAUDE/tasks.md)** - Task documentation and usage
- **[How To Use With Codex](./CLAUDE/how-to-use-with-codex.md)** - Codex integration guide

The CLAUDE/ directory contains all detailed BMAD-METHOD documentation in an organized, maintainable structure.
