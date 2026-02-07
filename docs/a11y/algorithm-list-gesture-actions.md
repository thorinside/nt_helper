# Algorithm List Double-Tap and Long-Press Undiscoverable

**Severity: Medium**

## Files Affected
- `lib/ui/widgets/algorithm_list_view.dart` (lines 39-82)

## Description

Each algorithm in the slot list has three interaction modes:
1. **Tap** (line 66): Select this algorithm slot - works via `ListTile.onTap`
2. **Double-tap** (line 43): Focus the hardware display on this algorithm's UI - uses `GestureDetector.onDoubleTap`
3. **Long-press** (line 67): Rename the algorithm slot - uses `ListTile.onLongPress`

While `ListTile.onTap` and `ListTile.onLongPress` are somewhat accessible (VoiceOver will announce "double-tap to activate" and some screen readers support long-press), the `GestureDetector.onDoubleTap` wrapping the `ListTile` creates a conflict - the outer `GestureDetector` intercepts double-tap before the `ListTile` can handle it, and this action has no semantic equivalent.

The `MouseRegion` help text (line 40: "Double-click: Focus algorithm UI  |  Long-press: Rename algorithm") is hover-only and completely invisible to screen readers.

## Impact on Blind Users

- The "focus hardware display" action is undiscoverable and may conflict with VoiceOver's double-tap activation gesture
- Long-press to rename works with VoiceOver if the user knows to try it, but is not announced
- Contextual help text is mouse-hover only, invisible to assistive technology

## Recommended Fix

Add custom semantic actions to the `ListTile`:

```dart
Semantics(
  customSemanticsActions: {
    CustomSemanticsAction(label: 'Focus hardware display'):
        () => _focusOnHardware(index),
    CustomSemanticsAction(label: 'Rename algorithm'):
        () => _renameSlot(index),
  },
  child: ListTile(
    title: Text(displayName, ...),
    selected: index == selectedIndex,
    onTap: () => onSelectionChanged(index),
    // Keep onLongPress for sighted users but add semantic equivalent
    onLongPress: () => _renameSlot(index),
  ),
)
```
