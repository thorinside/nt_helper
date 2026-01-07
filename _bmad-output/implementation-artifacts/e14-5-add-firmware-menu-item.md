# Story 14.5: Add Firmware to Main Menu

Status: review

## Story

As a desktop user,
I want to access the Firmware Update screen from the main overflow menu,
So that I can easily check for and install firmware updates without searching through the UI.

## Acceptance Criteria

1. A "Firmware" menu item appears in the main overflow menu (⋮) just above the "About" item
2. The menu item shows a `Row` with "Firmware" text and `Icons.system_update` icon (matching existing pattern)
3. Tapping the menu item navigates to `FirmwareUpdateScreen`
4. The menu item is disabled when `widget.loading` is true (same as other menu items)
5. The menu item is only visible on desktop platforms (macOS, Windows, Linux)
6. `flutter analyze` passes with zero warnings

## Tasks / Subtasks

- [x] Task 1: Add Firmware menu item to overflow menu (AC: 1, 2, 3, 4, 5)
  - [x] Add import for `FirmwareUpdateScreen`
  - [x] Add platform check (`Platform.isMacOS || Platform.isWindows || Platform.isLinux`)
  - [x] Create `PopupMenuItem` with value `'firmware'` 
  - [x] Add `Row` with `Text('Firmware')` and `Icon(Icons.system_update)`
  - [x] Implement `onTap` to navigate to `FirmwareUpdateScreen` using `Navigator.push`
  - [x] Pass `distingCubit` to `FirmwareUpdateScreen` constructor
  - [x] Position item immediately before the "About" `PopupMenuItem`
- [x] Task 2: Verify with flutter analyze (AC: 6)

## Dev Notes

### File to Modify

**`lib/ui/synchronized_screen.dart`** — `_buildOverflowMenu` method (around line 1032)

### Existing Pattern (from Offline Data menu item, lines 1303-1323)

```dart
PopupMenuItem(
  value: 'sync_metadata',
  enabled: !widget.loading,
  onTap: widget.loading
      ? null
      : () {
          final distingCubit = popupCtx.read<DistingCubit>();
          Navigator.push(
            popupCtx,
            MaterialPageRoute(
              builder: (_) =>
                  MetadataSyncPage(distingCubit: distingCubit),
            ),
          );
        },
  child: const Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [Text('Offline Data'), Icon(Icons.sync_alt_rounded)],
  ),
),
```

### Implementation Code

Insert this **before** the "About" `PopupMenuItem` (line 1324):

```dart
// Firmware: Desktop only, disabled when loading
if (Platform.isMacOS || Platform.isWindows || Platform.isLinux)
  PopupMenuItem(
    value: 'firmware',
    enabled: !widget.loading,
    onTap: widget.loading
        ? null
        : () {
            final distingCubit = popupCtx.read<DistingCubit>();
            Navigator.push(
              popupCtx,
              MaterialPageRoute(
                builder: (_) =>
                    FirmwareUpdateScreen(distingCubit: distingCubit),
              ),
            );
          },
    child: const Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [Text('Firmware'), Icon(Icons.system_update)],
    ),
  ),
```

### Required Import

Add at top of file (if not already present):

```dart
import 'package:nt_helper/ui/firmware/firmware_update_screen.dart';
```

### Project Structure Notes

- `FirmwareUpdateScreen` already exists at `lib/ui/firmware/firmware_update_screen.dart`
- The screen handles its own platform checks internally (shows message on non-desktop)
- The screen requires `distingCubit` parameter for state access
- Existing firmware feature from Epic 14 is complete and functional

### References

- [Source: lib/ui/synchronized_screen.dart#_buildOverflowMenu] — Overflow menu builder
- [Source: lib/ui/firmware/firmware_update_screen.dart] — Target screen
- [Source: _bmad-output/planning-artifacts/epic-14-firmware-update.md] — Original firmware epic

## Dev Agent Record

### Agent Model Used

Claude Sonnet 4 (claude-sonnet-4-20250514)

### Debug Log References

N/A - No debug logging required for this simple UI addition.

### Completion Notes List

- Import for `FirmwareUpdateScreen` already existed at line 48 (added by Epic 14)
- Added conditional `PopupMenuItem` at lines 1324-1345 in `_buildOverflowMenu` method
- Platform check uses `if (Platform.isMacOS || Platform.isWindows || Platform.isLinux)` for desktop-only visibility
- Menu item positioned immediately before "About" item as specified
- `flutter analyze` passes with zero warnings

### File List

- `lib/ui/synchronized_screen.dart` (modified)
