# Preset Browser Three-Panel Navigation Inaccessible

**Severity: High**

**Status: Addressed (2026-02-06)** — Navigate to root label on home button, chevron icons wrapped in ExcludeSemantics in mobile_drill_down_navigator.dart

## Files Affected

- `lib/ui/widgets/preset_browser_dialog.dart` (lines 542-697)
- `lib/ui/widgets/mobile_drill_down_navigator.dart` (lines 1-209)

## Description

### Desktop Three-Panel Navigator (ThreePanelNavigator)

The desktop preset browser uses a three-panel Finder-style navigation (left/center/right panels). This has several accessibility issues:

1. **No panel labels**: Each `DirectoryPanel` is just a `Container` + `ListView` with no `Semantics` label indicating which panel level the user is in. Screen reader users cannot distinguish "root folders", "subfolders", and "files" panels.

2. **Selected state not communicated**: While `ListTile.selected` is set, the three-panel paradigm requires users to understand they are navigating a hierarchical tree across columns. This spatial layout concept is lost on screen readers.

3. **Empty panel states**: Empty panels show "Empty" text without any context about why they are empty (e.g., "Select a folder to see its contents").

4. **Icons without labels**: Directory/file icons (folder, music_note, insert_drive_file) have no semantic labels. A screen reader might say "Image" or skip them.

### Mobile Drill-Down Navigator (MobileDrillDownNavigator)

5. **Breadcrumb home icon has no label** (line 49-55): The home `InkWell` contains only an `Icons.home` with no `Semantics` label or tooltip. VoiceOver would announce "Image" or skip it.

6. **Breadcrumb chevron icons are noise**: The `Icons.chevron_right` between breadcrumb segments will be announced as "Image" by screen readers, cluttering navigation.

7. **No announcement on directory change**: When navigating into a directory, there is no semantic announcement of the new directory contents.

### Dialog-Level Issues

8. **Sort toggle icon ambiguity** (lines 77-91): The sort toggle button switches between `Icons.date_range` and `Icons.sort_by_alpha`. The tooltip says "Sort by date" when it's currently sorting by date (should say "Switch to alphabetical sort" or similar). The actual sorting mode is communicated only by the icon.

9. **Drag overlay not accessible** (lines 496-529): The drag-and-drop overlay ("Drop preset package here") is a visual-only indicator with no screen reader equivalent.

## Impact on Blind Users

- The three-panel navigation model is completely spatial and has no screen reader equivalent
- Users cannot understand the folder hierarchy they are navigating
- Mobile breadcrumb navigation has unlabeled buttons
- Sort mode is ambiguous
- Drag-and-drop is unusable for screen reader users

## Recommended Fix

For the **three-panel navigator**, add `Semantics` labels to each panel:

```dart
Semantics(
  label: 'Root directories',
  child: DirectoryPanel(
    items: leftPanelItems,
    // ...
  ),
),
```

For **breadcrumbs**, add labels:

```dart
Semantics(
  button: true,
  label: 'Navigate to root',
  child: InkWell(
    onTap: () => onBreadcrumbTap(-1),
    child: Padding(
      padding: const EdgeInsets.all(8.0),
      child: Icon(Icons.home, size: 20),
    ),
  ),
),
```

Hide decorative chevrons from accessibility:

```dart
ExcludeSemantics(
  child: Icon(Icons.chevron_right, size: 16),
),
```

For **directory/file items**, add semantic descriptions:

```dart
Semantics(
  label: item.isDirectory
      ? '$displayName folder'
      : '$displayName, ${_formatFileSize(item.size)}',
  child: ListTile(/* ... */),
)
```
