# Epic 14: Firmware Update Integration

**Created:** 2025-12-29
**Status:** Planned
**Priority:** High
**External Tool:** [thorinside/nt-flash](https://github.com/thorinside/nt-flash)

---

## Vision

One-click firmware updates for musicians. No external tools, no configuration, no decisions.

**User experience:** "Update available" → Click → Follow 4-step bootloader instructions → Done.

## Problem Statement

Updating Disting NT firmware currently requires:
- Downloading MCUXpresso Secure Provisioning Tool (~500MB) OR
- Installing Python 3.10+, SPSDK, and running command-line scripts

Both approaches confuse musicians and generate support burden. nt_helper should handle this invisibly.

## Solution

Use the external `nt-flash` tool with `--machine` mode for structured progress output. The tool handles all USB/protocol complexity. nt_helper just needs to:
1. Download the tool automatically
2. Show current vs latest firmware version
3. Guide user through bootloader entry
4. Display progress and handle errors

---

## Story Breakdown (4 Stories)

### Story E14.1: Flash Tool Infrastructure

As a developer integrating firmware updates,
I want the app to automatically manage the nt-flash tool and execute it reliably,
So that users never need to manually download or configure external tools.

**Acceptance Criteria:**

**Tool Management:**
1. Create `FlashToolManager` service that auto-downloads nt-flash from GitHub releases
2. Fetch latest release via `https://api.github.com/repos/thorinside/nt-flash/releases/latest`
3. Select platform-appropriate binary (darwin-arm64, darwin-x64, win-x64.exe, linux-x64)
4. Download to app data directory, set executable permissions on Unix
5. Download happens automatically when user first attempts update (not on app launch)
6. No settings UI - tool is always auto-managed
7. If download fails, show clear error with retry option

**Process Bridge:**
8. Create `FlashToolBridge` service to spawn nt-flash with `--machine` flag
9. Parse stdout line-by-line for STATUS/PROGRESS/ERROR messages per MACHINE.md spec
10. Emit `Stream<FlashProgress>` with: stage, percent, message, isError
11. Handle exit codes: 0 = success, 1 = error (parse ERROR message for details)
12. Support cancellation via process kill
13. Log all stdout/stderr to timestamped file in app data directory
14. `flutter analyze` passes with zero warnings

**Files:**
- `lib/services/flash_tool_manager.dart`
- `lib/services/flash_tool_bridge.dart`
- `lib/models/flash_progress.dart`
- `lib/models/flash_stage.dart`

**Prerequisites:** None

---

### Story E14.2: Firmware Version Check and Download

As a user checking for updates,
I want to see if a new firmware version is available and download it with one tap,
So that I can prepare for an update without leaving the app.

**Acceptance Criteria:**

**Version Discovery:**
1. Display current device firmware version (already available from SysEx)
2. Background check for updates on app launch (non-blocking)
3. Parse Expert Sleepers firmware page HTML for: version numbers, release dates, changelogs, download URLs
4. Show update indicator icon (⬆️) next to firmware version in bottom app bar when update available
5. Tapping firmware indicator opens Firmware Update screen
6. Display release notes for available versions (scrollable, newest first)
7. Show current version vs latest available prominently at top

**Package Download:**
8. "Update to vX.Y.Z" button downloads firmware .zip to temp directory
9. Show simple progress bar during download (no file size, no MB/s)
10. Verify ZIP can be opened after download
11. Proceed directly to bootloader instructions after successful download
12. Delete package after successful flash OR if user cancels
13. No multi-version caching - download fresh each time
14. `flutter analyze` passes with zero warnings

**Files:**
- `lib/services/firmware_version_service.dart`
- `lib/models/firmware_version.dart`

**Prerequisites:** None (parallel with E14.1)

---

### Story E14.3: Firmware Update Wizard with Progress Visualization

As a user ready to update firmware,
I want a simple guided flow with clear visual feedback,
So that I can confidently complete the update without confusion.

**Acceptance Criteria:**

**Single-Screen Progressive Flow:**
1. Create `FirmwareUpdateScreen` opened from bottom app bar firmware indicator
2. Initial state: Current vs available version, release notes, "Update to vX.Y.Z" button
3. After clicking Update: Download package, then show bootloader instructions with illustration
4. Bootloader instructions: 4 simple steps with visual of module buttons
5. "I'm in bootloader mode - Flash Now" button to proceed
6. Progress state: Animated diagram + stage label + progress bar
7. Success state: "Updated to v1.13.0!" with Done button
8. Error state: Show error message + contextual action (see E14.4)
9. Feature only available on desktop platforms (macOS, Windows, Linux)
10. Hidden on iOS/Android (USB Host limitations prevent flashing)
11. Disabled in demo and offline modes

**Progress Visualization:**
12. Top section: Simple diagram showing Computer → Connection → Disting NT
13. Connection line animates based on stage:
    - Waiting: dashed line pulses
    - Connecting: line solidifies
    - Uploading/Writing: simple flow animation (no particles)
    - Complete: checkmark on NT icon
    - Error: red X on connection
14. Stage label below diagram: "Uploading firmware...", "Configuring...", etc.
15. Linear progress bar with percentage
16. Use standard Flutter widgets + simple CustomPainter (no Rive/Lottie)
17. Respect reduced motion preference (use opacity changes instead)

**Local File Option (for beta testers):**
18. Small "Choose file..." text link below main update button
19. File picker filtered to .zip files
20. Validate ZIP can be opened before proceeding
21. Same flow as downloaded package after file selection
22. `flutter analyze` passes with zero warnings

**Files:**
- `lib/cubit/firmware_update_cubit.dart`
- `lib/ui/firmware/firmware_update_screen.dart`
- `lib/ui/firmware/firmware_flow_diagram.dart`

**Prerequisites:** Stories E14.1, E14.2

---

### Story E14.4: Error Handling and Platform Setup

As a user whose update encounters problems,
I want clear explanations of what went wrong and how to fix it,
So that I can successfully complete the update without external support.

**Acceptance Criteria:**

**Error Display:**
1. Show the actual ERROR message from nt-flash tool (it's already user-friendly)
2. Add contextual action button based on failed stage:
   - SDP_CONNECT/BL_CHECK: "Re-enter Bootloader Mode" button
   - SDP_UPLOAD/WRITE: "Retry Update" button
   - DOWNLOAD/LOAD: "Try Again" button
3. "Copy Diagnostics" button: copies platform, versions, error, log excerpt
4. Full session log available at `{appDataDir}/logs/firmware_YYYYMMDD_HHMMSS.log`
5. No error code numbers shown to user - just clear messages

**Platform Setup (First-Time Only):**
6. On Linux: Detect if udev rules needed, show inline installation instructions
7. Include `99-disting-nt.rules` file in repository under `assets/linux/`
8. On macOS: Handle Gatekeeper quarantine removal automatically if possible
9. Show platform setup only on first update attempt or after error
10. "Don't show again" preference after successful first update

**Recovery:**
11. "Retry" restarts from current step (not from beginning)
12. If device stuck in bootloader: show power cycle instructions
13. Link to Expert Sleepers forum for complex issues
14. `flutter analyze` passes with zero warnings

**Files:**
- `lib/ui/firmware/firmware_error_widget.dart`
- `assets/linux/99-disting-nt.rules`

**Prerequisites:** Story E14.3

---

## What We Cut (and Why)

| Removed | Rationale |
|---------|-----------|
| Settings for tool path | Musicians don't configure tool paths. Auto-manage always. |
| Version history browsing | 95% want latest. Link to ES page for history. |
| Multi-version caching | Firmware updates are rare. Re-download is fine. |
| Separate animation story | Animation is part of progress UI, not separate feature. |
| Particle effects | Overkill. Simple flow animation is sufficient. |
| Demo mode support | Firmware update requires hardware. Just hide the feature. |
| Separate platform docs | Inline troubleshooting is better UX. |
| Complex error code mapping | Tool messages are already good. Trust them. |

---

## Technical Architecture

```
┌─────────────────────────────────────────────┐
│            FirmwareUpdateScreen             │
│  ┌────────────────────────────────────────┐ │
│  │  FirmwareFlowDiagram (progress viz)    │ │
│  │  [Computer] ══════════ [Disting NT]    │ │
│  └────────────────────────────────────────┘ │
│  ┌────────────────────────────────────────┐ │
│  │  Stage: "Uploading firmware..."        │ │
│  │  ████████████████░░░░░░░░  67%         │ │
│  └────────────────────────────────────────┘ │
└─────────────────────────────────────────────┘
                      │
         FirmwareUpdateCubit (state)
                      │
        ┌─────────────┴─────────────┐
        │                           │
FlashToolManager              FlashToolBridge
(download tool)               (execute + parse)
        │                           │
        └─────────────┬─────────────┘
                      │
              nt-flash --machine
                      │
               [USB/Protocol]
                      │
                [Disting NT]
```

### Files to Create

| File | Purpose |
|------|---------|
| `lib/services/flash_tool_manager.dart` | Download and manage nt-flash binary |
| `lib/services/flash_tool_bridge.dart` | Execute tool, parse --machine output |
| `lib/services/firmware_version_service.dart` | Check Expert Sleepers for latest version |
| `lib/cubit/firmware_update_cubit.dart` | State management |
| `lib/ui/firmware/firmware_update_screen.dart` | Main UI |
| `lib/ui/firmware/firmware_flow_diagram.dart` | Simple progress visualization |
| `lib/ui/firmware/firmware_error_widget.dart` | Error display with actions |
| `lib/models/firmware_version.dart` | Version data model |
| `lib/models/flash_progress.dart` | Progress event model |
| `lib/models/flash_stage.dart` | Stage enum |
| `assets/linux/99-disting-nt.rules` | Linux udev rules |

---

## The Simplest Happy Path

```
User opens nt_helper (connected to Disting NT)
  │
  ▼
Bottom app bar shows: "FW: v1.12.0 [⬆️]" (update available)
  │
  ▼
User taps firmware indicator → Opens Firmware Update screen
  │
  ▼
Screen shows:
  ┌────────────────────────────────────────┐
  │  Current: v1.12.0                      │
  │  Available: v1.13.0                    │
  │                                        │
  │  Release Notes:                        │
  │  • Fixed Step Sequencer gate output    │
  │  • Added "Poly Split" algorithm        │
  │  • Improved USB stability              │
  │                                        │
  │  [   Update to v1.13.0   ]             │
  └────────────────────────────────────────┘
  │
  ▼
User taps "Update to v1.13.0"
  │
  ▼
Brief spinner: "Downloading..." (downloads tool + firmware)
  │
  ▼
Instructions: "Put Disting NT in bootloader mode:
               1. Menu > Misc > Enter bootloader mode
               2. Screen shows 'BOOT'"
              [I'm Ready - Flash Now] button
  │
  ▼
Progress: [Computer ══════ Disting NT]
          "Uploading firmware... 67%"
  │
  ▼
Success: "Updated to v1.13.0!"
         [Done]
```

**Total clicks:** 3 (indicator → Update → Flash Now → Done)
**Total decisions:** 1 ("Should I update?" - informed by release notes)

---

## Success Metrics

| Metric | Target |
|--------|--------|
| Time from "Update Now" to complete | < 2 minutes |
| User decisions required | 1 |
| Clicks to complete | 3-4 |
| Support tickets about firmware | Near zero |

---

## Platform Notes

**macOS:** Remove quarantine attribute from downloaded tool automatically.

**Windows:** No special drivers needed (uses HID).

**Linux:** Provide udev rules file with copy-paste instructions.

**iOS/Android:** Feature hidden (USB Host limitations).

---

*Epic simplified: December 29, 2025*
*Reduced from 10 stories to 4 stories (60% reduction)*
*Focus: Foolproof one-click updates for musicians*
