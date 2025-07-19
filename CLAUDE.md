# nt_helper - Disting NT MIDI Helper

Cross-platform Flutter application for managing Disting NT Eurorack module presets and algorithms.

## Core Concepts

**Purpose:** MIDI SysEx communication with Disting NT hardware for preset management, algorithm loading, and parameter control.

**Platforms:** Linux, macOS, iOS, Android, Windows with desktop drag-drop and backup features.

**Operation Modes:** Demo (no hardware), Offline (cached data), Connected (live MIDI).

## Architecture Patterns

**State Management:** Cubit pattern for application state.

**MIDI Layer:** Interface-based design with multiple implementations (mock, offline, live).

**Database:** Drift ORM for local data persistence.

**MCP Integration:** Model Context Protocol server for external tool access.

## Development Standards

**Code Quality:** Zero tolerance for `flutter analyze` errors.

**Debugging:** Always use `debugPrint()`, never `print()`.

**Workflow:** Feature branches required, PR approval needed.