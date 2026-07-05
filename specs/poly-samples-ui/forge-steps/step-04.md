## STEP 4 of 14 — extract public region math (poly_region_math.dart)

Spec section: "Step 4 — poly_region_math.dart".

Files: NEW `lib/ui/poly_multisample/poly_region_math.dart`,
NEW `test/poly_multisample/poly_region_math_test.dart`.

1. Copy the five private helpers from the BOTTOM of
   `lib/ui/poly_multisample/poly_multisample_builder_screen.dart`
   (`_selectedRegionFor`, `_effectiveLow`, `_effectiveHigh`, `_midiExtents`,
   `_velocityLanes`) into the new file with the public names from the spec's
   table. Bodies verbatim except renaming internal cross-calls to the public
   names. Do NOT edit the old screen file.
2. Test file: group `'poly region math'` with:
   - `test('effectiveLow falls back through switchPoint and root', ...)` —
     three regions covering `rangeLow` set, only `switchPoint` set, only
     `rootMidi` set; assert each.
   - `test('effectiveHigh uses next lane low minus one', ...)` — two mapped
     regions same velocity lane, lows 48 and 60, no explicit highs; assert
     `effectiveHigh(first, regions) == 59` and second == 127.
   - `test('midiExtents returns null for unmapped regions', ...)`.
   - `test('velocityLanes returns descending distinct lanes', ...)` —
     regions with layers 1,2,2,null (null counts as 1); expect `[2, 1]`.
   - `test('selectedRegionFor prefers focusedPath', ...)` — build a
     `PolyMultisampleBuilderState` with two edited regions, `focusedPath`
     on the second; assert it wins; with no focus and a selectedPaths entry,
     that wins; with neither, the first region.

Verify; test file:
`flutter test test/poly_multisample/poly_region_math_test.dart`.

Symbol count: the new file declares exactly 5 public functions.

Commit message: `refactor(poly): extract shared region math helpers`

---

