# Tech Stack

## Technical Summary

**Project Type**: Cross-platform Flutter application
**Primary Purpose**: MIDI SysEx communication with Disting NT hardware for preset management, algorithm loading, and parameter control

**Operation Modes**:
- Demo (Mock) - No hardware required, simulated data
- Offline - Cached algorithm data, no live hardware
- Connected - Live MIDI communication with Disting NT

**Current Version**: 1.55.1+124
**Minimum Dart SDK**: 3.8.1
**Flutter Version**: 3.35.1 (from GitHub Actions)

## Core Dependencies

| Category | Technology | Version | Notes |
|----------|------------|---------|-------|
| Framework | Flutter | 3.35.1 | Cross-platform (Linux, macOS, iOS, Android, Windows) |
| Language | Dart | >=3.8.1 | Null-safe |
| State Management | flutter_bloc | ^9.1.1 | Cubit pattern throughout |
| Database | Drift ORM | ^2.28.1 | SQLite with type-safe queries |
| MIDI | flutter_midi_command | ^0.5.3 | Custom Linux fork via git override |
| MCP Server | mcp_dart | git | Model Context Protocol implementation |
| Code Generation | freezed | ^3.2.0 | Immutable state classes |
| Code Generation | json_serializable | ^6.10.0 | JSON serialization |
| Code Generation | build_runner | ^2.7.1 | Dart code generation |
| Window Management | bitsdojo_window | 0.1.6 | Desktop window control |
| Testing | mocktail | ^1.0.4 | Mocking framework |
| Testing | bloc_test | ^10.0.0 | Bloc testing utilities |

## Supporting Dependencies

- `collection` ^1.19.1 - Collection utilities
- `equatable` ^2.0.7 - Value equality
- `uuid` ^4.5.1 - Unique identifiers
- `crypto` ^3.0.6 - Hashing and secure random
- `file_picker` ^10.3.2 - File selection dialogs
- `desktop_drop` ^0.6.1 - Drag & drop support
- `universal_ble` ^0.9.11 - Bluetooth connectivity
- `uvccamera` ^0.0.13 - USB video device access (for NT display capture)

## Repository Structure

- **Type**: Single repository (monorepo structure)
- **Package Manager**: Standard `flutter pub`
- **Notable**: Dependency override for custom Linux MIDI implementation via git

## Platform Support

- **macOS**: Fully supported, code-signed and notarized
- **iOS**: Fully supported, TestFlight distribution
- **Linux**: Supported, AppImage distribution
- **Android**: Supported, APK/AAB
- **Windows**: Supported, executable
