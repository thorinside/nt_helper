# Metadata Sync Page Complex State Transitions Not Accessible

**Severity: High**

**Status: Addressed (2026-02-06)** — in commit 664e27b

## Files Affected

- `lib/ui/metadata_sync/metadata_sync_page.dart` (lines 280-401, 414-567, 570-620)

## Description

The `MetadataSyncPage` renders different body content based on `MetadataSyncState`, transitioning between loading, error, checkpoint, syncing, viewing data, and success states. These transitions have several accessibility issues:

### 1. State Transitions Not Announced

The page body rebuilds via `BlocBuilder` when state changes (line 282), but state transitions are not announced to screen readers:
- Moving from "Idle" to "SyncingMetadata" (loading spinner appears)
- Moving from syncing to success or error
- Moving from any state to "ViewingLocalData"

### 2. Checkpoint Dialog Not Announced (lines 570-620)

The `_buildCheckpointDialog` creates a card asking "Resume Metadata Sync?" with "Start Fresh" and "Resume" buttons. When this appears, screen readers are not told that a decision is needed. This is a `Card` widget, not an `AlertDialog`, so it lacks dialog semantics entirely.

### 3. Progress Indicator Missing Live Region (lines 414-567)

The progress indicator card shows:
- A `LinearProgressIndicator` with value
- Main message text ("Syncing metadata from device...")
- Algorithm counter ("Algorithm 45 of 100")
- Sub-message text with a secondary progress bar
- Cancel button

The algorithm counter and sub-message update frequently during sync but are not in a `Semantics(liveRegion: true)` region. Users have no way to know progress is happening.

### 4. Error States Not Announced (lines 296-338)

When an error occurs, the page shows an error icon, error message, and retry button. Screen readers are not notified of the error — users must explore the screen to discover it.

### 5. Tab Bar State Not Synced (lines 701-767)

The `DefaultTabController` with three tabs (Saved Presets, Templates, Synced Algorithms) uses a `Badge` widget on the Templates tab showing the template count. The badge is not accessible — screen readers may not announce the count.

## Impact on Blind Users

- Users cannot tell when a sync operation starts, progresses, or finishes
- The checkpoint recovery dialog may go unnoticed
- Errors are not announced
- Tab badge counts are visual-only

## Recommended Fix

1. Announce state transitions:

```dart
BlocListener<MetadataSyncCubit, MetadataSyncState>(
  listener: (context, state) {
    if (state is SyncingMetadata) {
      SemanticsService.announce(
        'Syncing metadata from device',
        TextDirection.ltr,
      );
    } else if (state is MetadataSyncSuccess) {
      SemanticsService.announce(
        'Metadata sync completed successfully',
        TextDirection.ltr,
      );
    } else if (state is Failure) {
      SemanticsService.announce(
        'Error: ${state.error}',
        TextDirection.ltr,
      );
    }
  },
  child: /* existing BlocBuilder */,
)
```

2. Wrap progress counter in live region:

```dart
Semantics(
  liveRegion: true,
  child: Text(
    "Algorithm $algorithmsProcessed of $totalAlgorithms",
  ),
)
```

3. Make checkpoint dialog an actual dialog or add dialog semantics:

```dart
Semantics(
  label: 'Resume sync dialog',
  explicitChildNodes: true,
  child: _buildCheckpointDialog(context, metaState),
)
```
