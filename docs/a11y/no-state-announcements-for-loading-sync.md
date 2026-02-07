# No Screen Reader Announcements for Loading/Sync State Changes

**Severity:** High

**Files affected:**
- `lib/ui/synchronized_screen.dart` (entire file - loading state throughout)
- `lib/ui/performance_screen.dart` (line 322 - CircularProgressIndicator)
- `lib/ui/plugin_manager_screen.dart` (lines 669-679 - loading state)
- `lib/ui/gallery_screen.dart` (lines 425-483 - loading/error states)
- `lib/ui/firmware/firmware_update_screen.dart` (lines 440-463 - download progress)

## Description

Throughout the app, state transitions (loading, syncing, error, success) happen silently from a screen reader perspective. There are no calls to `SemanticsService.announce()` when:

1. The app starts loading/syncing data from the hardware
2. Loading completes or fails
3. A preset is saved, loaded, or created
4. An algorithm is added, moved, or removed
5. Firmware download progress updates
6. Plugin installation progresses or completes

The `CircularProgressIndicator` and `LinearProgressIndicator` widgets have implicit semantics but do not announce themselves when they appear or when progress changes significantly.

## Impact on blind users

Blind users have no feedback about what the app is doing. After tapping a button (e.g., "Refresh", "Save Preset"), they hear nothing and have no way to know if the action succeeded, failed, or is still in progress. This is especially problematic during firmware updates where the user needs to know the current stage.

## Recommended fix

Add `SemanticsService.announce()` calls at key state transitions. Examples:

```dart
// When loading starts
SemanticsService.announce('Loading preset data', TextDirection.ltr);

// When loading completes
SemanticsService.announce('Preset loaded successfully', TextDirection.ltr);

// When an error occurs
SemanticsService.announce('Error: $errorMessage', TextDirection.ltr);

// Firmware download progress (announce at milestones)
if (progress % 25 == 0) {
  SemanticsService.announce(
    'Download ${progress.toInt()}% complete',
    TextDirection.ltr,
  );
}
```

For the firmware update screen, wrap the progress indicator in `Semantics` with a live region:

```dart
Semantics(
  liveRegion: true,
  label: 'Download progress: ${(state.progress * 100).toInt()} percent',
  child: LinearProgressIndicator(value: state.progress),
)
```
