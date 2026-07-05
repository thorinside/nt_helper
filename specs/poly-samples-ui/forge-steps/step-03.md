## STEP 3 of 14 — adoptStagedImport / addStagedRegions on the builder cubit

Spec section: "Step 3 — staged-import adoption".

Files: `lib/ui/poly_multisample/poly_multisample_builder_cubit.dart`,
`test/poly_multisample/poly_multisample_builder_cubit_test.dart`.

1. Implement both methods exactly per the spec; refactor `_stageImport`'s
   success path to call `adoptStagedImport`.
2. Tests (append; build `PolyStagedImport` values inline with fake regions —
   `PolySampleRegion(path: ..., fileName: ..., displayName: ...)`):
   - `test('adoptStagedImport sets an import draft instrument', ...)` —
     staged with 2 regions and one warning; assert `sourceMode ==
     PolySampleSourceMode.importDraft`, `editedRegions.length == 2`,
     `warnings` contains the warning, `currentInstrument!.name == staged.name`.
   - `test('addStagedRegions merges without duplicating paths', ...)` —
     first `adoptStagedImport` with regions A,B; then `addStagedRegions`
     with regions B,C; assert `editedRegions` paths == {A,B,C} and length 3.
   - `test('addStagedRegions is a no-op without an instrument', ...)` —
     fresh cubit, call it, assert state unchanged
     (`currentInstrument == null`, `editedRegions` empty).

Verify; test file:
`flutter test test/poly_multisample/poly_multisample_builder_cubit_test.dart`.

Commit message: `feat(poly): adopt and merge staged imports in builder cubit`

---

