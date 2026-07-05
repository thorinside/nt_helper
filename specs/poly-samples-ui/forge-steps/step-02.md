## STEP 2 of 14 — wire PolySamplePreferencesService into the builder cubit

Spec section: "Step 2 — preferences wiring".

Files: `lib/ui/poly_multisample/poly_multisample_builder_cubit.dart`,
`test/poly_multisample/poly_multisample_builder_cubit_test.dart`.

1. Add the optional `preferencesService` constructor param, `_prefs()`
   memoizer, `_loadPreferences()` startup call, the three persistence hooks,
   and the two `remember*` methods — exactly per the spec. Import
   `package:nt_helper/poly_multisample/poly_sample_preferences_service.dart`.
2. Tests (append to the existing group; use
   `SharedPreferences.setMockInitialValues({...})` from
   `package:shared_preferences/shared_preferences.dart` and construct the
   service via `PolySamplePreferencesService.create()`):
   - `test('loads remembered folders into state on construction', ...)` —
     seed `{'poly_multisample.lastLocalFolder': '/tmp/a',
     'poly_multisample.lastWavExportFolder': '/tmp/b'}`, build the cubit
     with the created service, `await Future<void>.delayed(Duration.zero);`,
     assert `state.lastLocalFolder == '/tmp/a'` and
     `state.lastWavExportFolder == '/tmp/b'`.
   - `test('rememberSourceFolder persists and emits', ...)` — empty seed,
     call `await cubit.rememberSourceFolder('/tmp/src')`, assert
     `state.lastSourceFolder == '/tmp/src'` and the service getter returns it.

Verify; test file:
`flutter test test/poly_multisample/poly_multisample_builder_cubit_test.dart`.

Commit message: `feat(poly): remember sample folders via PolySamplePreferencesService`

---

