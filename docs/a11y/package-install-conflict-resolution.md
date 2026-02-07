# Package Install Dialog Conflict Resolution Accessibility

**Severity: Medium**

**Status: Addressed (2026-02-06)** — in commit 664e27b

## Files Affected

- `lib/ui/widgets/package_install_dialog.dart` (lines 177-322)

## Description

The `PackageInstallDialog` handles file conflict resolution when installing preset packages. It has several accessibility issues specific to the conflict resolution workflow:

### 1. ActionChip Bulk Actions (lines 177-209)

The bulk action chips ("Install All", "Skip Conflicts", "Skip All") use `ActionChip` with `avatar` icons. While `ActionChip` has reasonable default accessibility, the icons in `avatar` position may create redundant announcements.

### 2. File Status Color-Only Communication (lines 244-322)

Each file item shows a `CircleAvatar` with a colored background and icon indicating status:
- Green + check = will install (no conflict)
- Primary color + download = conflict, will install
- Error color + skip = conflict, will skip
- Disabled color + remove = won't install

The `_getFileStatusColor()` and `_getFileStatusIcon()` methods return visual-only indicators. Screen readers would need to understand the combination of color + icon to determine the file's status.

### 3. Install/Skip Toggle Buttons (lines 278-316)

For files with conflicts, two `ElevatedButton.icon` widgets are shown side-by-side ("Install" and "Skip"). The currently selected action is indicated by background color changes (primary vs surface, error vs surface). Screen readers cannot determine which button is "active" — both appear as regular buttons.

### 4. Strikethrough Text (lines 258-259)

Skipped files have their filename displayed with `TextDecoration.lineThrough`. This visual decoration is not communicated to screen readers.

### 5. ExpansionTile File Groups (lines 220-243)

Files are grouped by directory using `ExpansionTile`. The expansion tile title contains a folder icon, directory name, and a `Chip` with file count. The `Chip` may add clutter to screen reader output.

## Impact on Blind Users

- File install status is communicated only through color and icon
- Users cannot tell which resolution (Install/Skip) is currently selected for a conflict
- Strikethrough visual indicator for skipped files is invisible to screen readers
- Understanding the overall conflict situation requires visual scanning

## Recommended Fix

1. Add semantic labels to file status indicators:

```dart
Semantics(
  label: _getFileStatusDescription(file),
  child: CircleAvatar(
    radius: 12,
    backgroundColor: _getFileStatusColor(file),
    child: Icon(_getFileStatusIcon(file), size: 16, color: Colors.white),
  ),
)

String _getFileStatusDescription(PackageFile file) {
  if (file.hasConflict) {
    return file.shouldInstall
        ? 'Conflict: will overwrite'
        : 'Conflict: will skip';
  }
  return file.shouldInstall ? 'Will install' : 'Will skip';
}
```

2. Use `ToggleButtons` or add selected semantics to Install/Skip buttons:

```dart
Semantics(
  selected: willInstall,
  label: 'Install this file',
  child: ElevatedButton.icon(/* ... */),
)
```

3. Add text description for skipped files:

```dart
if (!willInstall)
  Text(
    'Skipped',
    style: TextStyle(color: Theme.of(context).disabledColor, fontSize: 11),
  ),
```
