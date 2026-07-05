## STEP 7 of 14 — PolySampleList widget

Spec section: "Step 7 — PolySampleList".

Files: NEW `lib/ui/poly_multisample/widgets/poly_sample_list.dart`,
NEW `test/poly_multisample/widgets/poly_sample_list_test.dart`.

1. Build per the spec (info-only rows, modifier-key selection modes,
   scroll-to-focus, preview button).
2. Tests:
   - `testWidgets('renders region info and selected semantics', ...)` — two
     regions, one selected; assert subtitle text contains
     `'Root C3'` for the mapped one and `'Root unmapped'` for the other;
     with `tester.ensureSemantics()` assert the selected row's semantics
     label `'<displayName>, root C3'` exists.
   - `testWidgets('plain tap emits replace mode', ...)` — tap a row, assert
     callback got `PolyRegionSelectionMode.replace`.
   - `testWidgets('preview button disabled for non-wav files', ...)` — a
     region with path ending `.aif`; the trailing IconButton's `onPressed`
     is null.

Verify; test file:
`flutter test test/poly_multisample/widgets/poly_sample_list_test.dart`.

Commit message: `feat(poly): add PolySampleList widget`

---

