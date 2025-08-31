# Technical Stack

> Last Updated: 2025-08-31
> Version: 1.0.0

## Application Framework

- **Framework:** Flutter
- **Version:** 3.8.1+
- **App Version:** 1.47.2+102
- **Language:** Dart
- **Architecture:** Cubit Model View (CMV)

## Database

- **Primary Database:** SQLite
- **ORM:** Drift ORM for type-safe database operations
- **Usage:** Local data persistence, preset storage, algorithm metadata

## State Management

- **Framework:** flutter_bloc
- **Pattern:** Cubit pattern for predictable state management
- **State Classes:** Freezed for immutable state objects

## MIDI Communication

- **Library:** flutter_midi_command
- **Protocol:** MIDI SysEx for Disting NT communication
- **Implementation:** Interface-based design with multiple implementations (mock, offline, live)

## UI Framework

- **Design System:** Material Design with custom components
- **Routing:** Custom routing visualization with canvas-based rendering
- **Responsive:** Multi-platform responsive design

## Development Tools

- **Code Quality:** Zero tolerance for `flutter analyze` errors
- **Formatting:** dart format for consistent code style
- **Debugging:** debugPrint() standardization
- **State Architecture:** Freezed for state classes, Cubit pattern enforcement

## Platform Support

- **Desktop:** Linux, macOS, Windows
- **Mobile:** iOS, Android  
- **Features:** Platform-specific optimizations, drag-and-drop support on desktop

## Integration & Extensibility

- **MCP Protocol:** Model Context Protocol server for external tool integration via mcp_dart
- **API Design:** Interface-based MIDI layer for future hardware extensions
- **Testing:** Comprehensive testing with mock implementations (mockito, bloc_test)
- **File Management:** Cross-platform file operations (path_provider, file_picker, desktop_drop)
- **Platform Integration:** Desktop window management (bitsdojo_window), platform-specific features

## Code Architecture

- **State Management:** Cubit pattern with flutter_bloc
- **Database Layer:** Drift ORM with SQLite
- **MIDI Layer:** Interface-based design (IMidiService, MockMidiService, LiveMidiService)
- **UI Components:** Material Design with custom routing visualization
- **Data Classes:** Freezed for immutable state management