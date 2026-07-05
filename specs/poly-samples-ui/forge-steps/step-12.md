## STEP 12 of 14 — landing and editor views

Spec section: "Step 12 — landing + editor views".

Files: NEW `lib/ui/poly_multisample/poly_samples_landing_view.dart`,
NEW `lib/ui/poly_multisample/poly_samples_editor_view.dart`,
NEW `test/poly_multisample/poly_samples_editor_view_test.dart`.

1. Build `PolySamplesLandingView`, `PolyHardwareFolderList`,
   `PolyLargeFolderView`, and `PolySamplesEditorView` per the spec.
2. Tests (editor view; same test-cubit pattern as step 8; wide surface —
   wrap in `SizedBox(width: 1200, height: 800)`):
   - `testWidgets('shows toolbar stats, key map, list and inspector', ...)`
     — local instrument, 2 regions, one mapped; expect `'2 samples'`,
     `'1 mapped'`, `find.byType(PolyKeyMap)`, `find.byType(PolySampleList)`,
     `find.byType(PolySampleInspector)` each present.
   - `testWidgets('draft mode shows Save As instead of Apply', ...)` —
     `sourceMode: PolySampleSourceMode.importDraft` → `find.text('Save As…')`
     and `find.text('Apply')` findsNothing.
   - `testWidgets('dirty state enables Apply and Discard', ...)` — local
     mode with `baselineRegions` differing from `editedRegions`; both
     buttons enabled (`onPressed != null`); `find.text('Unsaved changes')`.
   - `testWidgets('landing shows three source cards and empty draft', ...)`
     — pump `PolySamplesLandingView` with a default state; expect
     `'NT Hardware'`, `'Local Folder'`, `'Import Files'`,
     `'Start empty draft'`, and the header
     `'Build or edit a Disting NT multisample folder'`.

Verify; test file:
`flutter test test/poly_multisample/poly_samples_editor_view_test.dart`.

Commit message: `feat(poly): add samples landing and editor views`

---

