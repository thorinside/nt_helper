# Backwards-connection styling: orange dotted lines

## Context

The Disting NT routing model is strictly forward — a slot can only read from
buses written by lower-indexed slots earlier in the same processing pass.
A connection whose source algorithm sits in a *higher* slot than its
destination is a "backward edge" and only carries signal one block later
(via a routing/aux/feedback bus). These are valid connections that the user
sometimes wants on purpose, but they need to be visually flagged.

Today the routing-diagram renderer paints two visually similar things in
nearly identical styles:

1. **Backward-edge connections** (`Connection.isBackwardEdge == true`,
   exposed in the painter as `ConnectionData.isInvalidOrder`) — rendered
   via `ConnectionVisualType.invalid` with `theme.colorScheme.tertiary`
   color and an 8/4 dashed stroke (see `ConnectionPainter._applyConnectionStyle`
   line ~378 and `_drawConnectionBatch` line ~204), with port-coloured
   endpoint circles (line ~244, ~643).
2. **Partial / disconnected connections** (`Connection.isPartial == true`) —
   rendered via `ConnectionVisualType.partial` with
   `theme.colorScheme.onSurface.withValues(alpha: 0.6)` and the same 8/4
   dashed stroke, but with no endpoint circles.

Both produce dashed muted-grey lines, and users have reported they read
as "the same thing" — namely, *broken*. The intent for backward edges is
the opposite: they are working connections that simply require a feedback
bus, and the visualization should flag them with a distinctive **orange
dotted** style that survives in both light and dark themes.

The bug is not that the painter "short-circuits" past the backward-edge
branch — the `invalid` branch is reached. The bug is that the *style
chosen for that branch* is not visually distinct enough from the `partial`
branch. Fixing the styling in the existing `invalid` branch (and removing
endpoint dots) is enough to satisfy the requirement.

## Files to Change

### `lib/ui/widgets/routing/connection_painter.dart`

#### 1. Add a colour constant (top of file, near imports)

```dart
/// Bright orange used to flag backward-edge ("uphill") connections.
/// Theme-independent so the warning meaning is uniform in light and dark mode.
@visibleForTesting
const Color kBackwardEdgeColor = Color(0xFFFF8800);
```

#### 2. `_applyConnectionStyle()` — invalid branch (~line 378)

Replace:

```dart
if (type == ConnectionVisualType.invalid) {
  paint
    ..strokeWidth = 2.0
    ..color = theme.colorScheme.tertiary;
  return;
}
```

with:

```dart
if (type == ConnectionVisualType.invalid) {
  paint
    ..strokeWidth = 2.0
    ..color = kBackwardEdgeColor;
  return;
}
```

#### 3. New `_drawDottedPath()` method

Add a method that draws a stroked path as a sequence of round dots:

```dart
void _drawDottedPath(Canvas canvas, Path path, Paint paint) {
  final dotPaint = Paint()
    ..style = PaintingStyle.fill
    ..color = paint.color;
  final dotRadius = paint.strokeWidth / 2;
  // Dot centre-to-centre spacing chosen so individual dots remain
  // visually separate (≥2× radius gap) at strokeWidth 2.0 — gives a
  // clear "dotted" reading vs. the 8/4 dash used for ghost/partial.
  const dotSpacing = 6.0;

  for (final metric in path.computeMetrics()) {
    for (double d = 0.0; d <= metric.length; d += dotSpacing) {
      final tangent = metric.getTangentForOffset(d);
      if (tangent != null) {
        canvas.drawCircle(tangent.position, dotRadius, dotPaint);
      }
    }
  }
}
```

Color is read from the mutated `paint` set up by `_applyConnectionStyle()`,
so the dots inherit `kBackwardEdgeColor` automatically. The method handles
multi-contour paths from `_createRoutedPath`'s anti-overlap offsets the
same way `_drawDashedPath` does.

#### 4. `_drawConnectionBatch()` — invalid branch (~line 204)

Replace `_drawDashedPath(canvas, path, paint);` for the invalid type with
`_drawDottedPath(canvas, path, paint);`. The ghost and partial branches
continue to use `_drawDashedPath`.

#### 5. `_drawConnectionBatch()` — endpoint skip (~line 244)

Change:

```dart
if (type != ConnectionVisualType.partial) {
  _drawEndpoints(canvas, conn);
}
```

to:

```dart
if (type != ConnectionVisualType.partial &&
    type != ConnectionVisualType.invalid) {
  _drawEndpoints(canvas, conn);
}
```

The endpoint circles in port-type colors on a backward edge visually
conflict with the warning-orange line and read as a "double-ended broken
connection". Omitting them lets the dotted line itself be the only
endpoint signal.

#### 6. Extract a `@visibleForTesting` classifier

To support the test plan without exposing private state, hoist the
batch-selection logic out of `paint()` (line ~123) into a static method:

```dart
@visibleForTesting
static ConnectionVisualType classifyVisualType(ConnectionData conn) {
  if (conn.isSelected) return ConnectionVisualType.selected;
  if (conn.isPartial) return ConnectionVisualType.partial;
  if (conn.isInvalidOrder) return ConnectionVisualType.invalid;
  if (conn.isGhostConnection) return ConnectionVisualType.ghost;
  return ConnectionVisualType.regular;
}
```

Then use it in the `paint()` batching loop:

```dart
for (final conn in connections) {
  switch (classifyVisualType(conn)) {
    case ConnectionVisualType.selected:  selectedConnections.add(conn); break;
    case ConnectionVisualType.partial:   partialConnections.add(conn);  break;
    case ConnectionVisualType.invalid:   invalidConnections.add(conn);  break;
    case ConnectionVisualType.ghost:     ghostConnections.add(conn);    break;
    case ConnectionVisualType.regular:   regularConnections.add(conn);  break;
  }
}
```

This both deduplicates the precedence rules and makes them testable.

## Behavior Matrix

| Connection state                          | Stroke style    | Color                                      | Endpoints |
|-------------------------------------------|-----------------|--------------------------------------------|-----------|
| Forward (full, neither selected nor dimmed) | Solid          | Port-type (audio blue / CV orange) blended | Drawn     |
| Backward edge (`isBackwardEdge==true`)      | **Dotted (round)** | **`kBackwardEdgeColor` `#FF8800`**     | **None**  |
| Partial / disconnected (`isPartial`)        | Dashed (8/4)    | `onSurface @ 0.6`                          | None      |
| Ghost (`isGhostConnection`)                 | Dashed (8/4)    | `secondaryConnection`                      | Drawn     |
| Selected                                    | Solid           | `selectionIndicator`                       | Drawn     |

### State precedence (intentional, unchanged)

The classification order in `classifyVisualType()` defines what wins when
a connection has multiple flags. Confirmed cases:

- `selected` beats backward → a selected backward edge renders in the
  selection style, not orange dotted. This is the correct UX (selection
  is a transient user-driven highlight).
- `partial` beats backward → a backward edge that *also* has an
  unconnected endpoint renders as the partial dashed style. This is
  acceptable: the connection is genuinely incomplete and the partial
  style is the more important signal.
- `isHighlighted` (hover) and `isDimmed` (focus mode) and the delete
  animation (`deletingPortId` matches a port) are all branches that run
  *after* the type is classified, inside `_applyConnectionStyle()`. They
  intentionally override the orange-dotted styling (`return` early) so
  hover, dimming, and delete animations are uniform across all
  connection types. No change.

The "normal forward connections continue to render as solid green" line
in the bug report describes the *intent* of the existing forward style.
The current implementation already paints forward edges as solid lines in
port-type color (audio blue, CV orange) blended with the theme's
`directConnection.color` (green-ish in the default light theme). No
change to the forward path is in scope.

## Test Plan

Add `test/ui/widgets/routing/backward_connection_style_test.dart`
(or extend `connection_painter_test.dart`) with three tests:

```dart
test('classifies backward edge as invalid', () {
  final conn = _connData(isBackwardEdge: true);
  expect(ConnectionPainter.classifyVisualType(conn),
         ConnectionVisualType.invalid);
});

test('classifies partial connection as partial (not invalid) even if backward', () {
  final conn = _connData(isBackwardEdge: true, isPartial: true);
  expect(ConnectionPainter.classifyVisualType(conn),
         ConnectionVisualType.partial);
});

test('classifies selected backward edge as selected', () {
  final conn = _connData(isBackwardEdge: true, isSelected: true);
  expect(ConnectionPainter.classifyVisualType(conn),
         ConnectionVisualType.selected);
});

testWidgets('backward edge renders dots in kBackwardEdgeColor', (tester) async {
  final painter = ConnectionPainter(
    connections: [_connData(isBackwardEdge: true)],
    theme: ThemeData.light(),
    showLabels: false,
  );
  final recorder = PictureRecorder();
  final canvas = Canvas(recorder);
  painter.paint(canvas, const Size(400, 300));
  // Convert to image and sample a pixel along the bezier path; assert
  // it matches kBackwardEdgeColor (or transparent — between dots).
  // No labelBounds entry should exist for the connection (showLabels:false
  // and invalid type also doesn't draw labels).
  expect(painter.getLabelBounds(), isEmpty);
});
```

The classification tests give certainty about the precedence rules and
verify the bug-fix branch is reached. The widget-test pixel sampling
confirms the orange colour and "no endpoints" expectation. A helper
`_connData({...})` constructs a `Connection` and wraps it in
`ConnectionData` with reasonable defaults.

If pixel sampling is awkward in CI, the spec accepts replacing the last
test with an assertion on `kBackwardEdgeColor` directly (proving the
constant value the code under test will use) plus the classification
assertion (proving the constant *will* be applied for backward edges).

## Out of Scope

- **Slot Y-position locking on drag.** A separate concern about preventing
  the user from dragging an algorithm node above/below a neighbouring
  slot index. Not addressed here.
- **Forward-edge color changes.** The bug report mentions "solid green"
  for forward, but the existing accessible-color theme already governs
  forward color. Not changed.
- **Bus-number label rendering on backward edges.** Today only
  `regularConnections` get the white-rounded-rectangle bus label
  (`_drawConnectionLabel`, called from `paint()` line ~164). Backward
  edges have never shown that label, and that gap is unrelated to the
  styling-confusion bug. If labels are desired on backward edges later,
  it is a separate change.
- **Renaming `ConnectionVisualType.invalid` → `backwardEdge`.** The name
  is a misnomer (a backward edge is *valid*, just deferred), but renaming
  the enum touches every batch site, every theme reference, and the
  `ConnectionVisualTheme.errorConnection` field. Out of scope for this
  fix; tracked as a follow-up.
- **`AccessibilityColors` integration of the orange.** `kBackwardEdgeColor`
  is intentionally theme-independent so the warning meaning is uniform.
  If a future high-contrast mode needs a different orange, gate it on
  `AccessibilityColors.isHighContrast` then — not in this change.
- **Anti-overlap dot density.** A dotted path on a `_createRoutedPath`
  offset bezier may have very slight dot spacing variation at high
  curvature. Acceptable cosmetic trade-off; addressed only if a
  reviewer flags it.
- **`drawEndpointsOnly` mode.** This mode (used in mini-map / endpoint
  overlays) clips a normal path to the source/destination node bounds.
  Backward edges in that mode will draw clipped *dotted* segments, which
  is acceptable. The dotted-path method is invoked via the same
  `_drawConnectionBatch` flow regardless of `drawEndpointsOnly`.

## Acceptance

- A backward-edge connection in the routing diagram is visibly distinct
  from a partial/disconnected connection: round orange dots vs. grey
  dashes.
- Forward, selected, ghost, partial, hover, dimmed, and delete-animation
  styling are unchanged.
- A backward edge that is *also* selected renders selected; that is also
  partial renders partial. Documented and tested.
- Unit test asserts `classifyVisualType` returns `invalid` for a backward
  edge and that `kBackwardEdgeColor == #FF8800`.
- `flutter analyze` passes with zero warnings.
- `flutter test test/ui/widgets/routing/` passes.
