# Story E14.1: Flash Tool Infrastructure

Status: done

## Story

As a developer integrating firmware updates,
I want the app to automatically manage the nt-flash tool and execute it reliably,
so that users never need to manually download or configure external tools.

## Acceptance Criteria

### Tool Management
1. Create `FlashToolManager` service that auto-downloads nt-flash from GitHub releases
2. Fetch latest release via `https://api.github.com/repos/thorinside/nt-flash/releases/latest`
3. Select platform-appropriate binary (darwin-arm64, darwin-x64, win-x64.exe, linux-x64)
4. Download to app data directory, set executable permissions on Unix
5. On macOS: Remove quarantine attribute after download (`xattr -d com.apple.quarantine`). Log but don't fail if xattr fails.
6. Download triggered by first `getToolPath()` call (invoked by FlashToolBridge)
7. No settings UI - tool is always auto-managed
8. Throw `FlashToolDownloadException` on download failure (UI retry handled in E14.4)

### Process Bridge
9. Create `FlashToolBridge` service to spawn nt-flash with `--machine` flag
10. Parse stdout for STATUS/PROGRESS/ERROR messages (format below)
11. Emit `Stream<FlashProgress>` with: stage, percent, message, isError
12. Handle exit codes: 0=success, non-zero=error
13. Support cancellation via process kill
14. Log all stdout/stderr to `{appDataDir}/logs/firmware_YYYYMMDD_HHMMSS.log`
15. `flutter analyze` passes with zero warnings

## Tasks

- [x] Task 1: Create data models
  - [x] Create `lib/models/flash_progress.dart` with stage, percent, message, isError
  - [x] Create `lib/models/flash_stage.dart` enum: SDP_CONNECT, BL_CHECK, SDP_UPLOAD, WRITE, CONFIGURE, RESET, COMPLETE
  - [x] Create `FlashToolDownloadException` class
  - [x] Add freezed annotations

- [x] Task 2: Create FlashToolManager service
  - [x] Create `lib/services/flash_tool_manager.dart`
  - [x] Implement `Future<String> getToolPath()` - returns path, downloads if absent
  - [x] Implement `_downloadTool()` - fetch from GitHub API, detect platform, download
  - [x] Implement `_getPlatformBinaryName()` per platform detection below
  - [x] Set executable permissions on Unix: `Process.run('chmod', ['+x', path])`
  - [x] On macOS: Remove quarantine with `xattr`, log warning on failure (don't fail)
  - [x] Store in `getApplicationSupportDirectory()/nt-flash/`
  - [x] `_isToolPresent()` checks file exists and (on Unix) has executable bit

- [x] Task 3: Create FlashToolBridge service
  - [x] Create `lib/services/flash_tool_bridge.dart`
  - [x] Implement `Stream<FlashProgress> flash(String firmwarePath)`
  - [x] Spawn: `Process.start(toolPath, ['--machine', firmwarePath])`
  - [x] Parse stdout with `_parseMachineOutput()` per format below
  - [x] Create StreamController<FlashProgress> for output
  - [x] Implement `cancel()` - kills process, closes stream
  - [x] Create logs directory if not exists: `{appDataDir}/logs/`
  - [x] Log output to timestamped file

- [x] Task 4: Unit tests
  - [x] Test `_getPlatformBinaryName()` for each platform
  - [x] Test `_parseMachineOutput()` with sample lines
  - [x] Mock Process for FlashToolBridge tests

## Dev Notes

### Platform Detection
```dart
String _getPlatformBinaryName() {
  if (Platform.isMacOS) {
    final result = Process.runSync('uname', ['-m']);
    final arch = result.stdout.toString().trim();
    return arch == 'arm64' ? 'nt-flash-darwin-arm64' : 'nt-flash-darwin-x64';
  } else if (Platform.isWindows) {
    return 'nt-flash-win-x64.exe';
  } else if (Platform.isLinux) {
    return 'nt-flash-linux-x64';
  }
  throw UnsupportedError('Platform not supported');
}
```

### MACHINE.md Output Format
```
STATUS:SDP_CONNECT:0:Connecting to device...
PROGRESS:SDP_UPLOAD:45
STATUS:COMPLETE:100:Firmware update complete!
ERROR:Device not found in SDP mode
```

### Files
- `lib/models/flash_progress.dart` (NEW)
- `lib/models/flash_stage.dart` (NEW)
- `lib/services/flash_tool_manager.dart` (NEW)
- `lib/services/flash_tool_bridge.dart` (NEW)

### References
- [Source: docs/epics/epic-14-firmware-update.md#Story E14.1]
- [External: https://github.com/thorinside/nt-flash/blob/main/MACHINE.md]
- [Pattern: lib/services/plugin_update_checker.dart]

## Dev Agent Record

### Implementation Plan
- Created FlashStage enum with machine-readable values and parsing
- Created FlashProgress freezed model with stage, percent, message, isError
- Created FlashToolDownloadException for download failures
- Implemented FlashToolManager with GitHub API integration and platform detection
- Implemented FlashToolBridge with stream-based progress reporting and logging
- Added static test methods for unit testing private parsing/platform logic

### Completion Notes
All acceptance criteria satisfied:
- FlashToolManager auto-downloads nt-flash from GitHub releases API
- Platform detection handles macOS (arm64/x64), Windows, and Linux
- Downloads to app support directory with executable permissions
- macOS quarantine attribute removal (best-effort, non-blocking)
- FlashToolBridge spawns process with --machine flag
- Parses STATUS/PROGRESS/ERROR messages correctly
- Emits Stream<FlashProgress> with all required fields
- Handles exit codes (0=success, non-zero=error)
- Supports cancellation via process.kill()
- Logs all output to timestamped files in {appDataDir}/logs/
- flutter analyze passes with zero warnings
- 26 unit tests covering platform detection and output parsing

## File List

### New Files
- `lib/models/flash_stage.dart`
- `lib/models/flash_progress.dart`
- `lib/models/flash_progress.freezed.dart` (generated)
- `lib/models/flash_progress.g.dart` (generated)
- `lib/services/flash_tool_manager.dart`
- `lib/services/flash_tool_bridge.dart`
- `test/services/flash_tool_test.dart`

## Change Log

- 2025-12-29: Initial implementation of flash tool infrastructure (E14.1)
- 2025-12-29: Code review fixes:
  - Fixed log filename format to match spec (YYYYMMDD_HHMMSS)
  - Added warning logging for quarantine removal failures (AC5 compliance)
  - Refactored _parseMachineOutput to static method to avoid test helper issues
