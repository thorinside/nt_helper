# Firmware Update Flow: Missing Live Regions and Progress Announcements

**Severity:** High

**Status: Addressed (2026-02-06)** — in commit 664e27b

**Files affected:**
- `lib/ui/firmware/firmware_update_screen.dart` (lines 434-463, download progress)
- `lib/ui/firmware/firmware_update_screen.dart` (lines 577-626, flashing progress)
- `lib/ui/firmware/firmware_update_screen.dart` (lines 680-718, success state)

## Description

The firmware update screen progresses through multiple states (initial, downloading, waiting for bootloader, flashing, success, error) without any screen reader announcements:

1. **Download progress**: Shows `LinearProgressIndicator` and percentage text but no live region. Blind users won't know download is progressing.
2. **Flashing progress**: Stage transitions ("Connecting to bootloader...", "Writing firmware...") are critical safety information but have no announcements.
3. **Success state**: No announcement when update completes.
4. **Bootloader instructions**: Step cards use visual numbering but reading order may not be clear.
5. **Disabled back button during flashing**: Constraint is not announced.

## Impact on blind users

Firmware updating is a high-stakes operation. A blind user won't know current progress, stage, or when it's safe to interact with the device again.

## Recommended fix

1. Add `SemanticsService.announce()` at each state transition in the BlocConsumer listener.
2. Add `Semantics(liveRegion: true)` to progress indicators.
3. Add `Semantics(header: true)` to bootloader instruction step titles.
