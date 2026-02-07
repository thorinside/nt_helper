# Sync Status Indicator Relies on Color Only

**Severity: High**

**Status: Addressed (2026-02-06)** — in commit 664e27b

## Files Affected
- `lib/ui/widgets/step_sequencer/sync_status_indicator.dart` (lines 46-82)

## Description

The `SyncStatusIndicator` shows a colored dot to indicate sync state:
- Green = Synced
- Orange = Editing / Offline
- Blue = Syncing
- Red = Error

On mobile (width <= 768px), only the colored dot is shown (lines 60-69) - no text label. On desktop, a text label accompanies the dot.

The entire indicator has no `Semantics` wrapper. The colored `Container` (line 52-58) is a plain decorated box with no semantic meaning.

## Impact on Blind Users

- On mobile: sync status is completely invisible to screen readers (just a colored dot with no semantics)
- On desktop: the text label is readable but not identified as a status indicator
- The retry button (line 71-79) has a tooltip which helps, but the error state itself is not announced
- Color-only communication fails for color-blind users as well

## Recommended Fix

```dart
Semantics(
  label: 'Sync status: ${_getStatusText(status)}'
      '${status == SyncStatus.error && errorMessage != null ? ". Error: $errorMessage" : ""}',
  liveRegion: true, // Announce changes automatically
  child: Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      // ... existing dot and text ...
    ],
  ),
)
```
