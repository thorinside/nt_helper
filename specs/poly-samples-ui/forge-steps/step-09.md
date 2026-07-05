## STEP 9 of 14 — PolyWaveformEditor + 'Edit audio' section

Spec sections: "Step 9 — PolyWaveformEditor" and inspector section 5.

Files: NEW `lib/ui/poly_multisample/widgets/poly_waveform_editor.dart`,
`lib/ui/poly_multisample/widgets/poly_sample_inspector.dart` (add section 5),
NEW `test/poly_multisample/widgets/poly_waveform_editor_test.dart`,
`test/poly_multisample/widgets/poly_sample_inspector_test.dart` (append).

1. Build `PolyWaveformEditor` per the spec, then add the 'Edit audio'
   `ExpansionTile` to the inspector per spec section 5.
2. Waveform editor tests (construct a `WavOverview` directly:
   `sampleRate: 44100, frameCount: 1000, peaks: [40 × WavPeak(min: -0.5,
   max: 0.5)], zeroCrossings: [0, 250, 500, 750, 999]`):
   - `testWidgets('drag near start handle emits snapped frames', ...)` —
     trim mode, start 0, end 999, width 400: drag from x≈0 to x≈100;
     assert `onChanged` was called and the final startFrame is one of the
     zeroCrossings values (snapping) and < endFrame.
   - `testWidgets('has waveform editor semantics', ...)` —
     `find.bySemanticsLabel('Waveform editor')`.
3. Inspector test additions:
   - `testWidgets('edit audio section shows editor and save buttons', ...)`
     — seed `waveformSummaries` with the fake overview for the selected
     path, expand `'Edit audio'`; expect `find.byType(PolyWaveformEditor)`,
     `find.text('Save as…')`, `find.text('Overwrite')`.
   - `testWidgets('gain slider updates the wav edit draft', ...)` — drag the
     Gain slider; assert `state.wavEditDrafts[path]!.gainDb != 0`.

Verify; test files:
`flutter test test/poly_multisample/widgets/poly_waveform_editor_test.dart test/poly_multisample/widgets/poly_sample_inspector_test.dart`.

Commit message: `feat(poly): add waveform editor and destructive edit section`

---

