# Gallery Screen: Filter Chips Use onDeleted Hack for Dropdown Arrow

**Severity:** Medium

**Status: Addressed (2026-02-06)** — in commit 664e27b

**Files affected:**
- `lib/ui/gallery_screen.dart` (lines 626-669, `_buildCategoryFilter`)
- `lib/ui/gallery_screen.dart` (lines 672-708, `_buildTypeFilter`)

## Description

Category and type filter chips abuse the `deleteIcon` property to show a dropdown arrow:

```dart
Chip(
  deleteIcon: Icon(Icons.arrow_drop_down),
  onDeleted: () {},  // No-op
)
```

This causes screen readers to announce a "delete" action that does nothing when activated.

## Impact on blind users

Blind users will be confused by a non-functional "delete" action. The dropdown behavior is not clearly communicated.

## Recommended fix

Replace with `ActionChip` or add `Semantics` to override the misleading delete action with correct button semantics:
```dart
Semantics(
  label: 'Category filter: ${state.selectedCategory ?? "All"}',
  hint: 'Double-tap to change category',
  button: true,
  child: Chip(...),
)
```
