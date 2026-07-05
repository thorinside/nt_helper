## STEP 11 of 14 — Decent Sampler import dialog

Spec section: "Step 11 — Decent dialog".

Files: NEW `lib/ui/poly_multisample/dialogs/poly_decent_import_dialog.dart`,
NEW `test/poly_multisample/dialogs/poly_decent_import_dialog_test.dart`.

1. Build per the spec. The dialog reads everything from
   `PolyDecentImportCubit`; the optional `previewCubit` drives row preview
   buttons only.
2. Tests: drive the cubit directly — provide the dialog's content widget
   (`_PolyDecentImportDialog` is private; instead pump
   `showPolyDecentImportDialog` with a fake import service injected...).
   Since `showPolyDecentImportDialog` constructs its own cubit, add an
   optional param `@visibleForTesting PolyDecentImportCubit? cubit` to the
   function; when non-null use `BlocProvider.value(value: cubit)` and skip
   `analyzeSource`. Tests then use a test cubit subclass with a public
   `setTestState` (same pattern as earlier steps) seeded with a
   `DecentSamplerImportAnalysis` fixture (2 presets, 2 groups, 2 tags —
   construct inline with minimal string fields).
   - `testWidgets('shows analysis summary and handling modes', ...)` —
     expect the structure summary text and all seven handling labels.
   - `testWidgets('selectedTags mode reveals per-tag range steppers', ...)`
     — set handling `selectedTags` and one tag selected; expect that tag's
     Low/Root/High steppers (`find.byTooltip('Increase Low')` at least one).
   - `testWidgets('import disabled while warnings present', ...)` — state
     with a warning; the `'Import'` `FilledButton`'s `onPressed` is null.

Verify; test file:
`flutter test test/poly_multisample/dialogs/poly_decent_import_dialog_test.dart`.

Commit message: `feat(poly): add Decent Sampler import dialog`

---

