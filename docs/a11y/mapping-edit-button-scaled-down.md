# Mapping Edit Button Has Tiny Tap Target

**Severity: High**

## Files Affected
- `lib/ui/widgets/mapping_edit_button.dart` (lines 39-102)

## Description

The `MappingEditButton` is wrapped in `Transform.scale(scale: 0.6)` (line 39), which reduces the visual and touch target size to 60% of normal. An `IconButton` at default size is already near the minimum recommended tap target (48x48 logical pixels) - scaling to 60% makes it approximately 29x29 pixels, well below the WCAG 2.5.8 minimum of 44x44 CSS pixels (equivalent).

The button also:
- Uses `Icons.map_sharp` which may not have a clear meaning to screen reader users
- Has a tooltip "Edit mapping" which is good, but the scaling makes it hard to target
- The editing state border (line 44-49) is purely visual with no semantic communication

## Impact on Blind Users

- VoiceOver/TalkBack users may struggle to tap the button even after finding it in the accessibility tree
- Switch Access users with motor impairments will find the target extremely difficult
- The "editing" state (highlighted border) is not communicated to screen readers

## Recommended Fix

1. Remove or increase the scale factor, and use `visualDensity: VisualDensity.compact` instead:

```dart
// Remove Transform.scale(scale: 0.6) and use:
IconButton.filledTonal(
  style: (hasMapping ? mappedStyle : defaultStyle).copyWith(
    minimumSize: WidgetStatePropertyAll(Size(44, 44)),
    tapTargetSize: MaterialTapTargetSize.padded,
  ),
  icon: const Icon(Icons.map_sharp, size: 18),
  tooltip: hasMapping ? 'Edit mapping (active)' : 'Add mapping',
  onPressed: ...
)
```

2. Communicate the mapping status and editing state:

```dart
Semantics(
  label: hasMapping ? 'Mapping active' : 'No mapping',
  button: true,
  child: existingButton,
)
```
