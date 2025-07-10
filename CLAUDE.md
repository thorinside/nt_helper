Flutter app supporting Linux, macOS, iOS, Android, Windows. Desktop versions have backup and drag-drop install features.

**Key Architecture:**
- Main cubit: `lib/cubit/disting_cubit.dart`
- MIDI SysEX: `lib/domain/` with interface `i_disting_midi_manager.dart`
- UI: `lib/ui/synchronized_screen.dart`
- Database: Drift at `lib/db/database.dart` for algorithms and presets
- Three modes: Demo, Offline, Connected (default)

**MCP Service:**
- Implementation: `lib/services/mcp_server_service.dart`
- Controller: `lib/services/disting_controller.dart` (abstracts cubit)
- Tools: `lib/mcp/tools/` (algorithm_tools.dart, disting_tools.dart)

**Preset Export:**
- Dialog: `lib/ui/widgets/preset_package_dialog.dart`
- Services: `lib/services/package_creator.dart`, `preset_analyzer.dart`
- Storage: Drift database with DAOs in `lib/db/daos/`

**Development Best Practices:**
- Always ensure `flutter analyze` has no errors.
- Always start a new feature in a new branch. When development is complete ask if a PR is desired. If the user says yes, make a PR and submit it for review.