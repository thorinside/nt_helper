# Quick Reference

## Key Services
- State: `lib/cubit/disting_cubit.dart`
- MIDI: `lib/domain/i_disting_midi_manager.dart`
- Database: `lib/db/database.dart`
- MCP Server: `lib/services/mcp_server_service.dart`
- Metadata: `lib/services/algorithm_metadata_service.dart`

## Main UI
- Main Screen: `lib/ui/synchronized_screen.dart`
- Routing Editor: `lib/ui/widgets/routing/routing_editor_widget.dart`
- Gallery: `lib/ui/gallery_screen.dart`
- Plugin Manager: `lib/ui/plugin_manager_screen.dart`

## Commands
- `flutter analyze` – Must pass with zero warnings
- `flutter test` – Run all tests
- `flutter run -d macos --print-dtd` – Run with DevTools for MCP connection

## MCP Dart Connection
To connect MCP Dart tooling:
1. Run `flutter run -d macos --print-dtd`
2. Note the DTD URL from output
3. Use URL after "The Flutter DevTools debugger and profiler on macOS is available at:"
4. Connect MCP tool using the DTD URL

<!-- BEGIN: BMAD-AGENTS -->