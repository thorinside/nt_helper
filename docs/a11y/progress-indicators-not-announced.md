# Progress Indicators and Loading States Not Announced

**Severity: High**

**Status: Addressed (2026-02-06)** — CircularProgressIndicator wrapped in Semantics with contextual labels in preset_package_dialog.dart

## Files Affected

- `lib/ui/widgets/template_preview_dialog.dart` (lines 185-209)
- `lib/ui/widgets/preset_package_dialog.dart` (lines 157-166)
- `lib/ui/widgets/package_install_dialog.dart` (lines 99-112)
- `lib/ui/metadata_sync/metadata_sync_page.dart` (lines 414-567)
- `lib/ui/widgets/preset_browser_dialog.dart` (lines 112-115, 164-174, 532-538)
- `lib/ui/widgets/algorithm_export_dialog.dart` (lines 132-138, 297-304)

## Description

Many widgets display `CircularProgressIndicator` or `LinearProgressIndicator` during operations, but these loading states are not communicated to screen readers:

1. **CircularProgressIndicator without label**: All instances are bare `CircularProgressIndicator()` without a `Semantics` wrapper. Flutter's default semantics for this is "busy" but without context of what is loading.

2. **LinearProgressIndicator progress not announced**: The package install dialog (line 103) and metadata sync page (line 472) show `LinearProgressIndicator` with dynamic progress values, but changes in progress are not announced.

3. **State transitions are silent**: When dialogs transition from content to loading to success/error (e.g., `TemplatePreviewDialog._buildLoadingDialog()`), the screen reader is not notified of the state change.

4. **Install overlay blocks interaction silently**: `PresetBrowserDialog._buildInstallOverlay()` (line 532-538) places a semi-transparent overlay with a spinner. Screen reader users would not know interaction is blocked.

5. **Progress text not live-region**: Status text like "Installing: filename (3/10)" updates frequently but is not in a `Semantics(liveRegion: true)` region.

## Impact on Blind Users

- Users don't know when an operation has started
- Users can't track progress of long operations (metadata sync can take minutes)
- Users don't know when an operation completes or fails
- Blocked UI during installation is not communicated

## Recommended Fix

1. Add `Semantics(label: 'Loading')` to progress indicators:

```dart
Semantics(
  label: 'Loading, please wait',
  child: const CircularProgressIndicator(),
)
```

2. Use `SemanticsService.announce()` for state transitions:

```dart
// When entering loading state:
SemanticsService.announce(
  'Installing package, please wait',
  TextDirection.ltr,
);

// When progress updates (throttled):
SemanticsService.announce(
  'Installing file 3 of 10',
  TextDirection.ltr,
);
```

3. Wrap progress text in live regions:

```dart
Semantics(
  liveRegion: true,
  child: Text(
    'Installing: $_currentFile ($_completedFiles/$_totalFiles)',
    style: const TextStyle(fontSize: 12),
  ),
)
```
