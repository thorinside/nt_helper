# Story E14.4: Error Handling and Platform Setup

Status: Done

## Story

As a user whose firmware update encounters problems,
I want clear explanations of what went wrong and how to fix it,
so that I can successfully complete the update without external support.

## Acceptance Criteria

### Error Display
1. Show the actual ERROR message from nt-flash tool (already user-friendly)
2. Add contextual action button based on failed stage:
   - SDP_CONNECT/BL_CHECK: "Re-enter Bootloader Mode"
   - SDP_UPLOAD/WRITE: "Retry Update"
   - DOWNLOAD/LOAD: "Try Again"
3. "Copy Diagnostics" button: copies platform, OS version, firmware versions, error message, last 20 log lines (from E14.1 log file)
4. No error code numbers shown to user

### Platform Setup
5. On Linux: Before each flash attempt, check if `/etc/udev/rules.d/99-disting-nt.rules` exists. If missing, show inline installation instructions instead of proceeding. (Check is cheap, no caching needed.)
6. Include `99-disting-nt.rules` file in `assets/linux/`

### Recovery
7. "Re-enter Bootloader Mode" → navigates back to bootloader instructions state
8. "Retry Update" → restarts flash from current firmware path (doesn't re-download)
9. "Try Again" → returns to initial state
10. Include "Stuck in bootloader?" help: power cycle instructions
11. Link to Expert Sleepers forum for complex issues
12. `flutter analyze` passes with zero warnings

## Tasks

- [x] Task 1: Create FirmwareErrorWidget
  - [x] Create `lib/ui/firmware/firmware_error_widget.dart`
  - [x] Display error message prominently
  - [x] Contextual action button based on `failedStage` per AC #2
  - [x] "Copy Diagnostics" button
  - [x] Gather diagnostics: platform, OS, versions, error, last 20 lines from flash log
  - [x] Copy to clipboard
  - [x] "Stuck in bootloader?" expandable help section
  - [x] Expert Sleepers forum link

- [x] Task 2: Create udev rules asset
  - [x] Create `assets/linux/99-disting-nt.rules`
  - [x] Register in pubspec.yaml

- [x] Task 3: Implement Linux udev detection
  - [x] In FirmwareUpdateCubit: check if udev rules file exists before flash
  - [x] If missing, show inline instructions:
    ```
    sudo cp [asset path] /etc/udev/rules.d/
    sudo udevadm control --reload-rules
    sudo udevadm trigger
    ```
  - [x] Provide button to copy commands

- [x] Task 4: Integrate error widget into FirmwareUpdateScreen
  - [x] Render FirmwareErrorWidget when state is error
  - [x] Wire action button callbacks to cubit methods:
    - "Re-enter Bootloader Mode" → `cubit.returnToBootloaderInstructions()`
    - "Retry Update" → `cubit.retryFlash()`
    - "Try Again" → `cubit.cleanupAndReset()`

- [x] Task 5: Unit tests
  - [x] Test contextual action button text for each FlashStage
  - [x] Test error types are correctly assigned
  - [x] Test recovery methods (returnToBootloaderInstructions, continueAfterUdevInstall)

## Dev Notes

### udev Rules Content
```
# /etc/udev/rules.d/99-disting-nt.rules
# Allow unprivileged access to Disting NT in SDP (bootloader) mode
SUBSYSTEM=="usb", ATTRS{idVendor}=="1fc9", ATTRS{idProduct}=="0135", MODE="0666"
```

Note: Verify USB vendor/product IDs from nt-flash tool or NXP documentation.

### Diagnostics Format
```
Platform: macOS 14.2 (arm64)
Current Firmware: 1.12.0
Target Firmware: 1.13.0
Error Stage: SDP_CONNECT
Error Message: Device not found in SDP mode

Recent Log:
[2025-12-29 14:32:01] Starting flash tool...
[2025-12-29 14:32:02] STATUS:SDP_CONNECT:0:Connecting...
[2025-12-29 14:32:07] ERROR:Device not found
```

### Files
- `lib/ui/firmware/firmware_error_widget.dart` (NEW)
- `lib/ui/firmware/udev_missing_widget.dart` (NEW)
- `assets/linux/99-disting-nt.rules` (NEW)
- `lib/cubit/firmware_update_cubit.dart` (MODIFY - add udev check, recovery actions)
- `lib/cubit/firmware_update_state.dart` (MODIFY - add FirmwareErrorType, udevMissing state)
- `lib/services/flash_tool_bridge.dart` (MODIFY - add getRecentLogLines)
- `lib/ui/firmware/firmware_update_screen.dart` (MODIFY - integrate new widgets)

### References
- [Source: docs/epics/epic-14-firmware-update.md#Story E14.4]
- [External: https://forum.expert-sleepers.co.uk/]

## Dev Agent Record

### Implementation Plan
- Created FirmwareErrorWidget with contextual action buttons based on error type
- Added FirmwareErrorType enum to categorize errors (bootloaderConnection, flashWrite, download, udevMissing, general)
- Enhanced FirmwareUpdateState.error to include errorType, failedStage, firmwarePath, and targetVersion
- Added new FirmwareUpdateState.udevMissing for Linux udev setup instructions
- Created UdevMissingWidget with copy-to-clipboard for installation commands
- Added recovery methods: returnToBootloaderInstructions(), retryFlash(), continueAfterUdevInstall()
- Added getDiagnostics() method that gathers platform info, versions, and last 20 log lines
- Added getRecentLogLines() to FlashToolBridge for log retrieval

### Completion Notes
- All acceptance criteria satisfied
- All unit tests pass (30 tests)
- flutter analyze passes with zero warnings (only info-level lint hints about underscores in tests)

## File List
- lib/ui/firmware/firmware_error_widget.dart (NEW)
- lib/ui/firmware/udev_missing_widget.dart (NEW)
- assets/linux/99-disting-nt.rules (NEW)
- lib/cubit/firmware_update_cubit.dart (MODIFIED)
- lib/cubit/firmware_update_state.dart (MODIFIED)
- lib/cubit/firmware_update_state.freezed.dart (REGENERATED)
- lib/services/flash_tool_bridge.dart (MODIFIED)
- lib/ui/firmware/firmware_update_screen.dart (MODIFIED)
- pubspec.yaml (MODIFIED - added assets/linux/)
- test/cubit/firmware_update_cubit_test.dart (MODIFIED)

## Senior Developer Review (AI)

**Reviewer:** Code Review Workflow
**Date:** 2025-12-29
**Outcome:** APPROVED with fixes applied

### Review Summary
All 12 acceptance criteria validated as implemented. All tasks verified complete.

### Issues Found & Fixed
1. **[MEDIUM] Log retrieval returned empty for pre-flash errors** - Fixed `getRecentLogLines()` to return informative messages when no log file exists
2. **[MEDIUM] Unused `kUdevInstallCommands` constant and `installCommands` state field** - Removed dead code from cubit and state, regenerated freezed

### Verification
- `flutter analyze`: Zero errors (INFO-level hints only)
- Tests: 30/30 passing

## Change Log
- 2025-12-29: Code review - fixed log retrieval edge case, removed unused installCommands
- 2025-12-29: Implemented error handling with contextual recovery actions and Linux udev detection
