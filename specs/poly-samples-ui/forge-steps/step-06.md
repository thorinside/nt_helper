## STEP 6 of 14 — PolyKeyMap widget

Spec section: "Step 6 — PolyKeyMap".

Files: NEW `lib/ui/poly_multisample/widgets/poly_key_map.dart`,
NEW `test/poly_multisample/widgets/poly_key_map_test.dart`.

1. Build the widget per the spec. The painter/layout/hit-test code is COPIED
   from `_SimpleKeyboardPainter`, `_KeyboardLayout`, and
   `_regionAtKeyboardPosition` in
   `lib/ui/poly_multisample/poly_multisample_builder_screen.dart` (renamed
   per the spec; rewired to `poly_region_math.dart`). Do not edit the old
   file.
2. Tests (pump inside `MaterialApp(home: Scaffold(body: SizedBox(width: 800,
   height: 200, child: PolyKeyMap(height: 200, ...))))` — pass `height: 200`
   explicitly so the tap math below is exact):
   - `testWidgets('exposes a keyboard map semantics label', ...)` — two
     mapped regions → `find.bySemanticsLabel('Keyboard map with 2 mapped
     samples')` (use `tester.ensureSemantics()`).
   - `testWidgets('tap on a mapped zone selects the region', ...)` — one
     region rooted at C3 spanning the full range (rangeLow 0, rangeHigh
     127). Compute the tap point from the layout constants rather than the
     widget center: with the copied `_PolyKeyMapLayout(size, const [1])`
     the zone strip runs from `zoneTop` (24) to `zoneBottom`
     (`height - 42 - 8`), so tap at
     `tester.getTopLeft(find.byType(PolyKeyMap)) + Offset(width / 2,
     (24 + (height - 50)) / 2)` where width/height are the SizedBox
     dimensions from the pump (800×200). Assert the `onSelect` callback
     received that region.
   - `testWidgets('renders without mapped regions', ...)` — empty list, no
     exceptions, one `CustomPaint` under `find.byType(PolyKeyMap)`.

Verify; test file:
`flutter test test/poly_multisample/widgets/poly_key_map_test.dart`.

Commit message: `feat(poly): add PolyKeyMap keyboard map widget`

---

