# Plugin Selection Dialog Checkbox List Accessibility

**Severity: Medium**

**Status: Addressed (2026-02-06)** — in commit 664e27b

## Files Affected

- `lib/ui/widgets/plugin_selection_dialog.dart` (lines 143-220)

## Description

The `PluginSelectionDialog` displays a list of plugins with `CheckboxListTile` widgets for multi-selection. While `CheckboxListTile` is generally well-supported by screen readers, there are several issues:

1. **Selection count not live**: The "X of Y selected" text (line 147-150) updates when checkboxes are toggled, but it is not a live region. Screen readers won't announce the updated count.

2. **Select All/Deselect All button state**: The button text changes between "Select All" and "Deselect All" (line 153) but the state change is visual-only.

3. **Search field missing accessible hint**: The search TextField (line 133-139) has `hintText: 'Search plugins...'` but no `semanticsLabel` to provide additional context.

4. **Plugin subtitle information**: Each plugin item has a subtitle with file type icon, file type text, file size, and optional description. The file type icon (line 176) is not labeled, so screen readers will announce "Image" before the file type text.

5. **Disabled Install button text**: When no plugins are selected, the install button text changes to "Select at least one plugin" and is disabled. This text change is a good accessibility practice, but the disabled state may not be clearly announced.

## Impact on Blind Users

- Users cannot hear the running total of selected plugins as they check/uncheck items
- Decorative file type icons add noise to screen reader output
- The search field works but could be more descriptive

## Recommended Fix

1. Wrap selection count in a live region:

```dart
Semantics(
  liveRegion: true,
  child: Text(
    '$selectedCount of ${plugins.length} selected',
    style: Theme.of(dlgContext).textTheme.bodySmall,
  ),
),
```

2. Hide decorative icons:

```dart
ExcludeSemantics(
  child: Icon(_getFileTypeIcon(plugin.fileType), size: 16),
),
```

3. Add `semanticsLabel` to search field:

```dart
TextField(
  controller: searchController,
  decoration: const InputDecoration(
    hintText: 'Search plugins...',
    prefixIcon: ExcludeSemantics(child: Icon(Icons.search)),
    border: OutlineInputBorder(),
  ),
),
```
