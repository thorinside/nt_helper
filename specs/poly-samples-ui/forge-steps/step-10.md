## STEP 10 of 14 — loose WAV import dialog

Spec section: "Step 10 — loose WAV dialog".

Files: NEW `lib/ui/poly_multisample/dialogs/poly_loose_wav_import_dialog.dart`,
NEW `test/poly_multisample/dialogs/poly_loose_wav_import_dialog_test.dart`.

1. Build per the spec.
2. Tests (open via a test button that calls
   `showPolyLooseWavImportDialog`; paths need not exist on disk for
   selection/mapping tests):
   - `testWidgets('lists files and mapping modes', ...)` — two paths;
     expect both basenames, all five mode labels, `'All'`, `'None'`.
   - `testWidgets('start note row appears for chromatic mode', ...)` —
     select `'Spread chromatically from start note'`; expect
     `find.textContaining('Start note: C4')` (default startMidi 60 → `'C4'`
     per `PolyMultisampleParser.midiToNoteName(60)`).
   - `testWidgets('cancel returns null', ...)` — tap `'Cancel'`, assert the
     awaited result is null.

Verify; test file:
`flutter test test/poly_multisample/dialogs/poly_loose_wav_import_dialog_test.dart`.

Commit message: `feat(poly): add loose WAV import dialog`

---

