## STEP 1 of 14 — extend PolyWaveformDraft with fade curve/strength

Spec section: "Step 1 — PolyWaveformDraft new fields".

Files: `lib/poly_multisample/poly_multisample_models.dart`,
`lib/ui/poly_multisample/poly_multisample_builder_cubit.dart`,
`test/poly_multisample/poly_multisample_builder_cubit_test.dart`.

1. Add the four fields + defaults to `PolyWaveformDraft` and the twelve-field
   `copyWith` with the five clear-flags, exactly as the spec's table states.
   Add `import 'wav_metadata.dart';` to the models file.
2. In `PolyMultisampleBuilderCubit.saveDestructiveWav`, pass the four new
   draft fields into `WavRenderOptions` as the spec shows.
3. Append one test to the existing `group` in the cubit test file:
   `test('saveDestructiveWav forwards fade curve and strength', ...)` —
   construct a `PolyWaveformDraft(fadeInCurve: WavFadeCurve.sCurve,
   fadeOutCurve: WavFadeCurve.equalPower, fadeInStrength: 0.8,
   fadeOutStrength: 0.2)` and assert `copyWith()` preserves all four, and
   `copyWith(clearNormalize: true)` nulls `normalizePeakDb` while keeping
   the fades. (A pure model test — no file IO.)

Verify per conventions; test file:
`flutter test test/poly_multisample/poly_multisample_builder_cubit_test.dart`.

Leftover check: `rg -n "fadeInCurve" lib/poly_multisample/poly_multisample_models.dart lib/ui/poly_multisample/poly_multisample_builder_cubit.dart`
must show hits in BOTH files.

Commit message: `feat(poly): add fade curve and strength to PolyWaveformDraft`

---

