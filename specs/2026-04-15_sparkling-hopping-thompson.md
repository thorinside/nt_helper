# Plan: Fix Routing Canvas View Reset

## Context

When the user opens the routing canvas view (or after app restart), the scroll position resets to 0,0 (top-left of the 5000×5000 canvas). Nodes appear at defaults even though positions were saved. The user wants to return to exactly where the view was last set (scroll + zoom), falling back to fit-to-view if no saved data exists.

## Root Causes

**Bug 1 — Centering timing:** `_centerCanvas()` is called in `initState()`'s postFrameCallback. But `_viewModeLoaded = false` at that point, so the widget returns a blank `SizedBox`. Scroll controllers have no clients; `_centerCanvas()` silently does nothing. When `_loadViewMode()` completes and `_viewModeLoaded` becomes true, the canvas appears but scroll is stuck at 0,0.

**Bug 2 — Saved node positions ignored:** `loadNodePositions()` in the cubit loads positions from `routing_positions_{presetName}` into `cubit.state.nodePositions`. But `_initializeNodePositions()` and `_pruneAndInitNodePositions()` in the widget always use default positions — they never read `routingState.nodePositions`. Saved positions are never restored to `_nodePositions`.

**Bug 3 — Scroll/zoom not persisted:** `panOffset` and `zoomLevel` are in cubit state but never saved to SharedPreferences. After app restart they're lost.

## Critical Files

| File | Purpose |
|------|---------|
| `lib/ui/widgets/routing/routing_editor_widget.dart` | Widget: centering, `_nodePositions`, scroll listeners |
| `lib/cubit/routing_editor_cubit.dart` | Cubit: `saveNodePositions()`, `loadNodePositions()`, viewport methods |

## Implementation

### Step 1: Fix `_initializeNodePositions()` to use saved positions (widget, line 256)

Replace `=` assignments with saved-first logic:

```dart
void _initializeNodePositions() {
  const double centerX = _canvasWidth / 2;
  const double centerY = _canvasHeight / 2;
  final routingState = context.read<RoutingEditorCubit>().state;
  final saved = routingState is RoutingEditorStateLoaded
      ? routingState.nodePositions
      : const <String, NodePosition>{};

  NodePosition? s;
  s = saved['physical_inputs'];
  _nodePositions['physical_inputs'] = s != null
      ? Offset(s.x, s.y)
      : const Offset(centerX - 800, centerY - 300);
  s = saved['physical_outputs'];
  _nodePositions['physical_outputs'] = s != null
      ? Offset(s.x, s.y)
      : const Offset(centerX + 600, centerY - 300);

  if (routingState is RoutingEditorStateLoaded) {
    const double algorithmStartX = centerX - 250;
    const double algorithmSpacing = 300.0;
    const double algorithmRowSpacing = 200.0;
    for (int i = 0; i < routingState.algorithms.length && i < 8; i++) {
      final algo = routingState.algorithms[i];
      final savedPos = saved[algo.id];
      _nodePositions[algo.id] = savedPos != null
          ? Offset(savedPos.x, savedPos.y)
          : Offset(
              algorithmStartX + (i % 2) * algorithmSpacing,
              centerY - 300 + (i ~/ 2) * algorithmRowSpacing,
            );
    }
  }
}
```

### Step 2: Fix `_pruneAndInitNodePositions()` to use saved positions (widget, line 1214)

Change each `putIfAbsent` default to check `current.nodePositions[id]` first, converting `NodePosition → Offset`.

### Step 3: Add `updateViewport()` to cubit

```dart
/// Update viewport scroll position and persist alongside node positions
Future<void> updateViewport(Offset scrollOffset) async {
  final currentState = state;
  if (currentState is! RoutingEditorStateLoaded) return;
  emit(currentState.copyWith(panOffset: scrollOffset));
  await saveNodePositions();
}
```

Also call `saveNodePositions()` from `setZoomLevel()` (after emit) so zoom is saved too.

### Step 4: Extend `saveNodePositions()` and `loadNodePositions()` (cubit, lines 3086/3116)

In `saveNodePositions()`, add to the JSON:
```dart
'_viewport': {
  'scrollH': currentState.panOffset.dx,
  'scrollV': currentState.panOffset.dy,
  'zoom': currentState.zoomLevel,
}
```

In `loadNodePositions()`, parse `_viewport` and emit with `panOffset` and `zoomLevel` set:
```dart
final viewport = positionsMap['_viewport'] as Map<String, dynamic>?;
final scrollH = (viewport?['scrollH'] as num?)?.toDouble() ?? 0.0;
final scrollV = (viewport?['scrollV'] as num?)?.toDouble() ?? 0.0;
final zoom = (viewport?['zoom'] as num?)?.toDouble() ?? 1.0;

emit(currentState.copyWith(
  nodePositions: nodePositions,
  panOffset: Offset(scrollH, scrollV),
  zoomLevel: zoom,
));
```

Note: `_viewport` key starts with `_` so it won't clash with node IDs. Remove it from the node positions map before processing node entries.

### Step 5: Add debounced scroll listeners in widget `initState()`

```dart
_horizontalScrollController.addListener(_onScrollChanged);
_verticalScrollController.addListener(_onScrollChanged);
```

```dart
Timer? _scrollSaveTimer;

void _onScrollChanged() {
  _scrollSaveTimer?.cancel();
  _scrollSaveTimer = Timer(const Duration(milliseconds: 500), () {
    if (!mounted) return;
    final h = _horizontalScrollController.hasClients
        ? _horizontalScrollController.offset : 0.0;
    final v = _verticalScrollController.hasClients
        ? _verticalScrollController.offset : 0.0;
    context.read<RoutingEditorCubit>().updateViewport(Offset(h, v));
  });
}
```

Cancel `_scrollSaveTimer` in `dispose()`.

### Step 6: Fix centering — replace `_centerCanvas()` in `initState()` with restore logic in `_loadViewMode()`

Remove (lines 229–231):
```dart
WidgetsBinding.instance.addPostFrameCallback((_) {
  _centerCanvas();
});
```

Add at end of `_loadViewMode()` (after `setState`):
```dart
WidgetsBinding.instance.addPostFrameCallback((_) {
  if (!mounted) return;
  final cubitState = context.read<RoutingEditorCubit>().state;
  final pan = cubitState is RoutingEditorStateLoaded
      ? cubitState.panOffset
      : Offset.zero;
  if (pan != Offset.zero) {
    if (_horizontalScrollController.hasClients) {
      _horizontalScrollController.jumpTo(pan.dx);
    }
    if (_verticalScrollController.hasClients) {
      _verticalScrollController.jumpTo(pan.dy);
    }
  } else {
    _fitToView();
  }
});
```

## Verification

1. Run: `flutter run -d macos`
2. Open routing view — nodes appear centered (fit-to-view, first launch)
3. Pan/zoom, then quit and relaunch — view restores to same position/zoom
4. Move a node, quit and relaunch — node is in saved position
5. Switch tabs and back — scroll/zoom preserved (IndexedStack)
6. `flutter analyze` — zero warnings
7. `flutter test` — all tests pass
