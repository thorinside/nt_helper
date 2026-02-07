# Tab Bar Algorithm Names: Gesture-Only Actions Inaccessible

**Severity:** Critical

**Files affected:**
- `lib/ui/synchronized_screen.dart` (lines 1466-1535, `_buildTabBar`)

## Description

Each algorithm tab in the tab bar is wrapped in a `GestureDetector` with:
- `onDoubleTap`: Focuses the algorithm UI on the hardware display
- `onLongPress`: Opens a rename dialog for the algorithm slot

These gesture-based actions have **no screen reader alternative**. VoiceOver/TalkBack users cannot perform double-tap or long-press custom actions on these tabs because:

1. There are no `Semantics` custom actions registered
2. There is no alternative menu or button for these operations
3. The `MouseRegion` wrapping is purely visual (hover-based contextual help) and has no semantic meaning

Additionally, the `Tab` widget inside the `GestureDetector` does not include any semantic hint about the available interactions.

## Impact on blind users

Blind users can switch between algorithm tabs (standard Tab behavior) but cannot:
- Focus an algorithm on the hardware display (double-tap action)
- Rename an algorithm slot (long-press action)

These are important workflow actions with no accessible alternative path.

## Recommended fix

Add `Semantics` with custom actions to each tab:

```dart
Semantics(
  label: 'Algorithm: $displayName',
  hint: 'Double-tap to select. Use actions menu for more options.',
  customSemanticsActions: {
    CustomSemanticsAction(label: 'Focus algorithm on hardware'): () {
      cubit.disting()?.let((manager) {
        manager.requestSetFocus(index, 0);
        manager.requestSetDisplayMode(DisplayMode.algorithmUI);
      });
    },
    CustomSemanticsAction(label: 'Rename algorithm'): () async {
      final newName = await showDialog<String>(...);
      ...
    },
  },
  child: GestureDetector(
    onDoubleTap: () { ... },
    onLongPress: () { ... },
    child: Tab(text: displayName),
  ),
)
```
