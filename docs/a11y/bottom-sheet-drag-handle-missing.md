# Bottom Sheet Missing Drag Handle and Dismiss Semantics

**Severity: High**

**Status: Addressed (2026-02-06)** — showDragHandle: true added, close button + header added to mapping_editor_bottom_sheet.dart

## Files Affected

- `lib/ui/widgets/mapping_edit_button.dart` (lines 73-92)
- `lib/ui/widgets/mapping_editor_bottom_sheet.dart` (lines 35-69)

## Description

The mapping editor is presented as a `showModalBottomSheet` with `isScrollControlled: true`, but:

1. **No drag handle**: The bottom sheet does not set `showDragHandle: true`, so there is no visible or semantic drag handle for VoiceOver/TalkBack users to grab and dismiss the sheet.

2. **No close button**: The `MappingEditorBottomSheet` contains only the `PackedMappingDataEditor` content with no explicit close/done button. Users must swipe down or tap outside the sheet to dismiss it, which is difficult for screen reader users.

3. **No sheet announcement**: When the bottom sheet opens, there is no semantic announcement that a sheet has appeared. Screen reader users may not realize they are in a modal context.

4. **GestureDetector intercepts taps**: Line 36-37 wraps the content in a `GestureDetector` that unfocuses on tap, which may interfere with screen reader navigation.

## Impact on Blind Users

- VoiceOver users may not know a bottom sheet has appeared
- There is no accessible way to dismiss the sheet (no close button, no drag handle with accessibility labels)
- The 4-tab mapping editor (CV, MIDI, I2C, Performance) opens without announcing which parameter is being edited
- Users may become "trapped" in the bottom sheet if they can't find the dismiss gesture

## Recommended Fix

1. Add `showDragHandle: true` to the `showModalBottomSheet` call:

```dart
await showModalBottomSheet(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (context) {
    return MappingEditorBottomSheet(/* ... */);
  },
);
```

2. Add a close/done button at the top of the bottom sheet:

```dart
Widget build(BuildContext context) {
  return Column(
    children: [
      // Header with close button
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Text('Edit Mapping',
                style: Theme.of(context).textTheme.titleMedium),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            tooltip: 'Close mapping editor',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      // Existing content
      Expanded(child: PackedMappingDataEditor(/* ... */)),
    ],
  );
}
```
