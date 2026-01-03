# Story E14.3: Firmware Update Wizard with Progress Visualization

Status: done

## Story

As a user ready to update firmware,
I want a simple guided flow with clear visual feedback,
so that I can confidently complete the update without confusion.

## Acceptance Criteria

### Single-Screen Progressive Flow
1. Create `FirmwareUpdateScreen` opened from bottom app bar firmware indicator
2. Initial state: Current vs available version, release notes, "Update to vX.Y.Z" button
3. After clicking Update: Call `FirmwareVersionService.downloadFirmware()` (E14.2), then show bootloader instructions
4. Bootloader instructions with steps: (1) Menu > Misc > Enter bootloader mode, (2) Screen shows "BOOT", (3) LEDs flash bootloader pattern, (4) Click "I'm in bootloader mode - Flash Now"
5. "I'm in bootloader mode - Flash Now" button to proceed
6. Progress state: Animated diagram + stage label + progress bar
7. Success state: "Updated to vX.Y.Z!" with Done button
8. Error state: Show error message + contextual action (handled by E14.4)
9. Only available on desktop platforms (macOS, Windows, Linux)
10. Hidden on iOS/Android
11. Disabled in demo and offline modes

### Progress Visualization
12. Animated diagram: Computer → Connection → Disting NT with stage-based line animation (null=dashed pulse, connecting=solid, uploading/writing=flow, complete=checkmark, error=red X). Include stage label and progress bar. Use CustomPainter, respect reduced motion.

### Local File Option
13. Small "Choose file..." text link below main update button
14. File picker filtered to .zip files
15. Validate ZIP can be opened before proceeding
16. Same flow as downloaded package after file selection
17. `flutter analyze` passes with zero warnings

## Tasks

- [x] Task 1: Create FirmwareUpdateCubit
  - [x] Create `lib/cubit/firmware_update_cubit.dart`
  - [x] Create `lib/cubit/firmware_update_state.dart` using freezed with states: initial, downloading, waitingForBootloader, flashing, success, error
  - [x] Inject `FirmwareVersionService`, `FlashToolManager`, `FlashToolBridge`
  - [x] Implement `startUpdate(FirmwareVersion version)` - calls `FirmwareVersionService.downloadFirmware()`, transitions to bootloader wait
  - [x] Implement `startFlashing()` - triggers flash, subscribes to progress stream
  - [x] Implement `useLocalFile(String path)` - validates ZIP, transitions to bootloader wait
  - [x] Implement `cancel()` - kills flash process, cleans up temp files
  - [x] Handle FlashProgress stream → update state
  - [x] Validate mode: reject if demo/offline

- [x] Task 2: Create FirmwareUpdateScreen scaffold
  - [x] Create `lib/ui/firmware/firmware_update_screen.dart`
  - [x] Add route registration (via Navigator.push from bottom bar)
  - [x] BlocProvider for FirmwareUpdateCubit
  - [x] BlocBuilder to render states
  - [x] Platform check: show "Not available on mobile" if on iOS/Android

- [x] Task 3: Implement Initial State UI
  - [x] Display current firmware from `DistingState.firmwareVersion`
  - [x] Display available versions from FirmwareVersionService
  - [x] Show release notes in scrollable container
  - [x] "Update to vX.Y.Z" primary button
  - [x] "Choose file..." text button

- [x] Task 4: Implement Downloading State UI
  - [x] Show download progress indicator (spinner or progress bar)
  - [x] Display "Downloading firmware..." message
  - [x] "Cancel" button

- [x] Task 5: Implement Bootloader Instructions UI
  - [x] Numbered steps widget with the 4 steps per AC #4
  - [x] Simple illustration showing module
  - [x] "I'm in bootloader mode - Flash Now" primary button
  - [x] "Cancel" secondary button

- [x] Task 6: Create FirmwareFlowDiagram widget
  - [x] Create `lib/ui/firmware/firmware_flow_diagram.dart`
  - [x] Draw Computer and Disting NT icons with animated connection line
  - [x] Animate based on FlashStage per AC #12
  - [x] Respect `MediaQuery.disableAnimations`

- [x] Task 7: Implement Flashing State UI
  - [x] Display FirmwareFlowDiagram
  - [x] Stage label text (from FlashProgress.message)
  - [x] LinearProgressIndicator with percent
  - [x] "Cancel" button with confirmation dialog

- [x] Task 8: Implement Success State UI
  - [x] Checkmark icon
  - [x] "Updated to vX.Y.Z!" message
  - [x] "Done" button to close screen

- [x] Task 9: Implement temp file cleanup
  - [x] Clean up on success (after Done clicked)
  - [x] Clean up on cancel (during download or flash)
  - [x] Clean up on error (when user dismisses)

- [x] Task 10: Implement Local File Selection
  - [x] file_picker package already in pubspec.yaml
  - [x] File picker with .zip filter
  - [x] Validate selected file
  - [x] Call `cubit.useLocalFile(path)`

- [x] Task 11: Tests
  - [x] Test FirmwareUpdateCubit state transitions
  - [x] Test cancel during flash
  - [x] Test state equality and when method

## Dev Notes

### FirmwareUpdateState
Use freezed for state unions. Required states: initial, downloading, waitingForBootloader, flashing, success, error.

### References
- [Source: docs/epics/epic-14-firmware-update.md#Story E14.3]

## Dev Agent Record

### File List

**New Files:**
- `lib/cubit/firmware_update_cubit.dart` - Cubit managing firmware update workflow
- `lib/cubit/firmware_update_state.dart` - Freezed state definitions
- `lib/cubit/firmware_update_state.freezed.dart` - Generated freezed code
- `lib/ui/firmware/firmware_update_screen.dart` - Main UI screen with all state views
- `lib/ui/firmware/firmware_flow_diagram.dart` - Animated CustomPainter diagram
- `test/cubit/firmware_update_cubit_test.dart` - Unit tests for cubit

**Modified Files:**
- `lib/ui/synchronized_screen.dart` - Added firmware update indicator button in bottom bar
- `lib/cubit/disting_cubit.dart` - Added `checkForFirmwareUpdate()` method and `firmwareVersionService` getter
- `lib/cubit/disting_state.dart` - Added `availableFirmwareUpdate` field to DistingStateSynchronized
- `lib/cubit/disting_cubit.freezed.dart` - Generated freezed code for new field
- `lib/cubit/disting_cubit_connection_delegate.dart` - Calls firmware version check on connect
- `lib/cubit/routing_editor_cubit.dart` - Pattern updates for new state field

### Change Log

| Date | Change | Author |
|------|--------|--------|
| 2024-12-29 | Initial implementation of FirmwareUpdateCubit, screen, and diagram | Dev Agent |
| 2024-12-29 | Code Review: Fixed `_getCurrentVersionFromState()` bug - stored currentVersion as field to preserve across state changes | Review Agent |
| 2024-12-29 | Code Review: Added missing tests for `useLocalFile()` method (6 test cases) | Review Agent |
| 2024-12-29 | Code Review: Added test verifying currentVersion preserved after cleanupAndReset | Review Agent |
