# Mapping Editor Dirty State Indicator Not Accessible

**Severity: Medium**

## Files Affected

- `lib/ui/widgets/packed_mapping_data_editor.dart` (lines 303-326)

## Description

The mapping editor uses a small colored dot (10x10 pixels) to indicate unsaved changes (amber) or active saving (blue). This dot is positioned absolutely in the top-left corner of the tab bar area. While it has a `Tooltip`, it has no semantic label:

```dart
Tooltip(
  message: _isSaving ? 'Saving...' : 'Unsaved changes',
  child: Container(
    width: 10,
    height: 10,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: _isSaving ? Colors.blue : Colors.amber,
    ),
  ),
),
```

## Impact on Blind Users

- The save status indicator is invisible to screen readers
- Users cannot tell whether their changes have been saved
- If a save fails silently (after max retries at line 272-278), the user has no way to know
- The color distinction (amber vs blue) is meaningless without a text alternative

## Recommended Fix

Wrap the indicator in a `Semantics` widget with a `liveRegion` to announce changes:

```dart
Semantics(
  liveRegion: true,
  label: _isSaving ? 'Saving changes' : 'Unsaved changes',
  child: Tooltip(
    message: _isSaving ? 'Saving...' : 'Unsaved changes',
    child: Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _isSaving ? Colors.blue : Colors.amber,
      ),
    ),
  ),
)
```

Also consider announcing save success/failure:

```dart
// After successful save:
SemanticsService.announce('Changes saved', TextDirection.ltr);

// After failed save:
SemanticsService.announce('Failed to save changes', TextDirection.ltr);
```
