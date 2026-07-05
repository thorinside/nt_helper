## STEP 13 of 14 — PolySamplesScreen

Spec section: "Step 13 — PolySamplesScreen".

Files: NEW `lib/ui/poly_multisample/poly_samples_screen.dart`,
NEW `test/poly_multisample/poly_samples_screen_test.dart`.

1. Build the screen per the spec (BlocConsumer with the verbatim
   listener copy, PopScope dirty guard, body dispatch, flow helpers).
2. Tests. Mock `DistingCubit` with mocktail
   (`class MockDistingCubit extends Mock implements DistingCubit {}`) and
   stub `disting()` to return null. Provide the builder cubit via
   `BlocProvider.value` around `PolySamplesView` (same injection style as
   the current screen test). Port these four tests from
   `test/poly_multisample/poly_multisample_builder_screen_test.dart`,
   adapted to the new widget names (read that file first; keep the assertion
   logic identical unless a label changed in the spec):
   - the stale-announcement test (`'does not re-announce stale success when
     clearing an error'`) — verbatim port, pumping `PolySamplesView`.
   - the hardware-empty-state test — same expectation
     (`'No sample folders found on /samples.'`).
   - a landing test replacing the old `'shows source states...'` test:
     expect AppBar title `'Samples'` and the three landing cards.
   - a keyboard-editor test replacing the old back-button test: seed the
     Piano state from the old test; expect
     `find.bySemanticsLabel('Keyboard map with 1 mapped samples')` and
     `find.text('Root: C3')`; tap tooltip `'Back to sample sources'`;
     expect the landing header and `state.currentInstrument == null`.
   Plus one new test:
   - `testWidgets('pop is guarded while dirty', ...)` — push the view onto a
     navigator, seed a dirty state (baseline ≠ edited), trigger a system
     back (`(tester.state(find.byType(Navigator)) as NavigatorState)
     .maybePop()`), pump, expect `find.text('Discard changes?')`; tap
     `'Cancel'`; the view is still present.

Verify; test file:
`flutter test test/poly_multisample/poly_samples_screen_test.dart`.

Commit message: `feat(poly): add standalone PolySamplesScreen`

---

