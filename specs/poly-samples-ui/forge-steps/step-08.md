## STEP 8 of 14 — PolySampleInspector (header, preview, mapping, loop points)

Spec section: "Step 8 — PolySampleInspector" (sections 1–4 only; section 5
is step 9).

Files: NEW `lib/ui/poly_multisample/widgets/poly_sample_inspector.dart`,
NEW `test/poly_multisample/widgets/poly_sample_inspector_test.dart`.

1. Build sections 1–4 per the spec. Where step 9's 'Edit audio' tile would
   go, leave nothing (it is added in step 9 — do not scaffold it).
2. Tests: pump with a real `PolyMultisampleBuilderCubit` provided via
   `BlocProvider.value` — copy the `_TestPolyMultisampleBuilderCubit` +
   `_FakePreviewAdapter` pattern from
   `test/poly_multisample/poly_multisample_builder_screen_test.dart`
   (define local copies in this test file; do not import that test file).
   Seed a state with one local instrument of two regions (roots C3, C4),
   `selectedPaths`/`focusedPath` on the first.
   - `testWidgets('shows mapping steppers for the selected sample', ...)` —
     `find.text('Root: C3')`, `find.text('Velocity: 1')`,
     `find.byTooltip('Increase Root')` each `findsOneWidget`.
   - `testWidgets('root stepper updates the cubit', ...)` — tap
     `'Increase Root'`, assert the cubit's edited region rootMidi is 49
     and `find.text('Root: C#3')` appears after `pump`.
   - `testWidgets('next sample navigates selection', ...)` — tap tooltip
     `'Next sample'`, assert `state.focusedPath` is the second region's path.
   - `testWidgets('shows empty message with no selection', ...)` — state
     with no regions → `find.text('No sample selected')`.
   - `testWidgets('loop editing gated for hardware paths', ...)` — hardware
     sourceMode + path starting `/samples/` → expand the `'Loop points'`
     tile → `find.text('Loop editing needs a local or mounted folder.')`.

Verify; test file:
`flutter test test/poly_multisample/widgets/poly_sample_inspector_test.dart`.

Commit message: `feat(poly): add PolySampleInspector with mapping and loop sections`

---

