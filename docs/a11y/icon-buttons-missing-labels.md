# Icon-Only Buttons and Icons Missing Accessible Labels

**Severity: High**

**Status: Addressed (2026-02-06)** — in commit 664e27b

## Files Affected

- `lib/ui/widgets/plugin_selection_dialog.dart` (lines 89, 175-176)
- `lib/ui/widgets/template_preview_dialog.dart` (lines 125-129)
- `lib/ui/widgets/package_install_dialog.dart` (lines 251-253)
- `lib/ui/widgets/algorithm_export_dialog.dart` (lines 113-114, 206)
- `lib/ui/widgets/debug_metadata_export_dialog.dart` (lines 125-126, 154, 239, 273)
- `lib/ui/widgets/rtt_stats_dialog.dart` (lines 67-68, 192-228)
- `lib/ui/widgets/debug_panel.dart` (lines 58, 94-98)
- `lib/ui/widgets/mapping_edit_button.dart` (line 53)
- `lib/ui/common/log_display_page.dart` (lines 22-25)

## Description

Multiple locations use icons (both in `Icon` widgets and within `Row` layouts) that convey meaning purely visually without text alternatives:

1. **Decorative icons in dialog titles**: Dialog titles commonly pair an `Icon` with `Text` in a `Row`. The icon is decorative but screen readers will announce it (e.g., "Image, Export Algorithm Details"). Examples:
   - `AlgorithmExportDialog`: `Icon(Icons.download)` in title row (line 113)
   - `PackageInstallDialog`: `Icon(Icons.archive)` in title row (line 77)
   - `DebugMetadataExportDialog`: `Icon(Icons.bug_report)` in title row (line 125)
   - `TemplatePreviewDialog`: `Icon(Icons.error)` in error title (line 231)

2. **Meaningful icons without labels**: Icons in list items that convey file type or status:
   - `PluginSelectionDialog`: `_getFileTypeIcon()` returns icons for file types (line 175) with no label
   - `PackageInstallDialog`: `CircleAvatar` with status icons (line 251-253) conveying install/skip/conflict status purely through icon and color
   - `RttStatsDialog`: `_buildStatItem()` uses colored icons (line 192-228) for Requests/Timeouts/Avg RTT etc., with the meaning embedded only in the adjacent text

3. **Mapping edit button**: The `IconButton.filledTonal` with `Icons.map_sharp` (line 53) has a tooltip "Edit mapping" but the button is scaled to 60% (`Transform.scale(scale: 0.6)`) making the hit target very small.

4. **Log page play/pause icon**: The recording state icon toggles between `Icons.pause_circle_filled` and `Icons.play_circle_filled` (line 22-25). The tooltip is correct but the icon change itself is not announced.

## Impact on Blind Users

- Decorative icons clutter screen reader output with "Image" announcements
- Status-conveying icons (file type, install status) are meaningless to screen readers
- Small touch targets make interaction difficult
- Icon state changes (play/pause) are not announced

## Recommended Fix

1. Hide decorative icons from the accessibility tree:

```dart
ExcludeSemantics(
  child: Icon(Icons.download, size: 24),
),
```

2. Add labels to meaningful icons:

```dart
Semantics(
  label: 'File type: Lua script',
  child: Icon(_getFileTypeIcon(plugin.fileType), size: 16),
)
```

3. For the mapping edit button, ensure minimum touch target:

```dart
// Remove Transform.scale or ensure the outer Container
// meets 48x48 minimum touch target
IconButton(
  constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
  icon: const Icon(Icons.map_sharp),
  tooltip: 'Edit mapping',
  onPressed: () { ... },
)
```
