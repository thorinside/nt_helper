# Confirmation Dialogs Don't Announce Destructive Nature

**Severity: Medium**

## Files Affected

- `lib/ui/metadata_sync/metadata_sync_page.dart`:
  - `_showSyncConfirmationDialog` (lines 623-654)
  - `_showIncrementalSyncConfirmationDialog` (lines 657-688)
  - `_showLoadConfirmationDialog` in `_PresetListView` (lines 917-1015)
  - `_showDeleteConfirmationDialog` in `_PresetListView` (lines 1018-1049)
  - `_showDeleteConfirmationDialog` in `_TemplateListView` (lines 1271-1301)
  - `_showLoadConfirmationDialog` in `_TemplateListView` (lines 1217-1268)

## Description

The app has many confirmation dialogs for destructive or significant actions (delete preset, sync metadata which clears preset, send preset to device which overwrites state). These dialogs have appropriate warning text, but:

1. **No urgency/alertness communicated**: None of the destructive confirmation dialogs use any special semantics to indicate urgency. The "Delete" and "Sync" buttons are styled with color (red foreground for delete) but this is visual-only.

2. **Delete buttons not semantically marked as destructive**: The delete buttons in confirmation dialogs use `TextButton.styleFrom(foregroundColor: error)` for visual styling, but screen readers don't announce the color. Users must rely on the button text "Delete" alone.

3. **Warning text in sync dialog not emphasized**: The metadata sync dialog warns "This process reads all algorithm data from the device and may require clearing the current preset. Save any work on the device first!" - this critical warning is not semantically distinguished from the rest of the dialog content.

## Impact on Blind Users

- Users may not perceive the urgency of destructive actions
- The visual red color on delete buttons is lost
- Warning text blends in with informational text
- Users might accidentally confirm a destructive action more easily

## Recommended Fix

1. Add semantic hints to destructive buttons:

```dart
Semantics(
  hint: 'Destructive action',
  child: TextButton(
    style: TextButton.styleFrom(
      foregroundColor: Theme.of(context).colorScheme.error,
    ),
    child: const Text('Delete'),
    onPressed: () { ... },
  ),
)
```

2. Mark warning text with appropriate semantics:

```dart
Semantics(
  label: 'Warning: This process may require clearing the current preset. Save any work on the device first.',
  child: Text('This process reads all algorithm data...'),
)
```
