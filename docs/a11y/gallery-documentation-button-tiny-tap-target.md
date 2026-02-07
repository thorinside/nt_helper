# Gallery Screen: Documentation Button Too Small for Accessibility

**Severity:** Medium

**Files affected:**
- `lib/ui/gallery_screen.dart` (lines 1162-1182, list tile documentation button)
- `lib/ui/gallery_screen.dart` (lines 1448-1471, card view documentation button)

## Description

The "View Documentation" button in both list and card views is a 24x24 `SizedBox` containing a `Material` > `InkWell` > `Tooltip` > `Icon(size: 16)`. This tap target is 24x24px, well below the WCAG/Material accessibility minimum of 48x48px. The `InkWell` has no `Semantics` annotation.

## Impact on blind users

Touch exploration may miss this tiny target. Users with motor impairments (common alongside visual impairments) will struggle to activate it.

## Recommended fix

Replace with `IconButton` which automatically provides 48x48 minimum touch target and proper semantics:
```dart
IconButton(
  icon: Icon(Icons.description_outlined, size: 20),
  tooltip: 'View Documentation',
  onPressed: () => _showReadmeDialog(parentContext, plugin),
)
```
