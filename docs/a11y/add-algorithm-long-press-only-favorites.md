# Add Algorithm Screen: Favorites Toggle Only Via Long Press

**Severity:** Critical

**Status: Addressed (2026-02-06)** — customSemanticsActions for Add/Remove from favorites in all 3 view modes (chip, list, column)

**Files affected:**
- `lib/ui/add_algorithm_screen.dart` (lines 1032-1079, chip grid view)
- `lib/ui/add_algorithm_screen.dart` (lines 1108-1110, list view `onLongPress`)
- `lib/ui/add_algorithm_screen.dart` (lines 1264-1265, column view `onLongPress`)

## Description

In all three view modes (chip grid, list, column), the only way to toggle an algorithm as a favorite is via `onLongPress`. This gesture is:

1. Not discoverable by screen reader users (no hint about it)
2. Difficult to perform with VoiceOver/TalkBack (requires a specific gesture that conflicts with screen reader navigation)
3. Not exposed via `Semantics.customSemanticsActions`

The favorite star icons (lines 1046-1054, 1146-1151, 1282-1283) are purely decorative with no semantic labels explaining what they represent.

## Impact on blind users

Blind users cannot:
- Mark algorithms as favorites
- Remove algorithms from favorites
- Understand what the star icon means when they encounter it

The "Show Favorites Only" toggle button (lines 574-590) works via a standard `onPressed`, but if blind users can never set favorites, this filter is useless to them.

## Recommended fix

1. Add `Semantics.customSemanticsActions` to each algorithm item:

```dart
Semantics(
  label: '${algo.name}${isFavorite ? ", favorite" : ""}${isCommunityPlugin ? ", community plugin" : ""}',
  hint: isSelected ? 'Selected' : 'Double-tap to select',
  customSemanticsActions: {
    CustomSemanticsAction(
      label: isFavorite ? 'Remove from favorites' : 'Add to favorites',
    ): () => _toggleFavorite(algo.guid),
  },
  child: ...
)
```

2. Add semantic labels to the favorite star icons:

```dart
Semantics(
  label: 'Favorite',
  excludeSemantics: true, // or child-only
  child: Icon(Icons.star, ...),
)
```

3. Consider adding a visible favorite toggle button in the selection area (bottom section) when an algorithm is selected, as a non-gesture alternative.
