# Implementation plan: sample sidebar layout stability

Total steps: 2. Execute one step per fresh-context session. Read `specs/conventions.md` and `specs/sample-sidebar-layout-stability/spec.md` before each step.

Program-level verification after STEP 2:

```bash
cd /Users/nealsanche/nosuch/nt_helper
flutter analyze && flutter test
```

Prerequisites: none.

## STEP 1 of 2: stabilize panel width, preview gain, and mapping rows

### Files to edit

- Create `lib/ui/poly_multisample/widgets/poly_sample_sidebar_layout.dart`
- Edit `lib/ui/poly_multisample/widgets/poly_sample_inspector.dart`
- Edit `lib/ui/poly_multisample/poly_samples_editor_view.dart`
- Edit `test/poly_multisample/widgets/poly_sample_inspector_test.dart`
- Edit `test/poly_multisample/poly_samples_editor_view_test.dart`

### Mechanical changes

1. Create `poly_sample_sidebar_layout.dart` with the four public symbols and exact APIs from `spec.md`:
   - `PolySampleSidebarLayout`
   - `PolySampleSidebarValueText`
   - `PolySampleSidebarIconButton`
   - `PolySampleSidebarSliderValue`
2. Put the exact constants from `spec.md` in `PolySampleSidebarLayout`.
3. Import `dart:ui` with `show FontFeature` in the helper file and use `const [FontFeature.tabularFigures()]` in the helper text style. Implement `PolySampleSidebarValueText` so the `semanticLabel != null` branch uses `ExcludeSemantics` exactly as specified in `spec.md`.
4. Import `package:nt_helper/ui/poly_multisample/widgets/poly_sample_sidebar_layout.dart` in `poly_sample_inspector.dart`.
5. Replace `SingleChildScrollView(padding: const EdgeInsets.all(12), ...)` with `EdgeInsets.all(PolySampleSidebarLayout.outerPadding)`.
6. Rewrite `_PreviewControls` gain row only:
   - icon box width is `PolySampleSidebarLayout.iconButtonExtent`
   - slider remains expanded
   - trailing value is `PolySampleSidebarSliderValue` with key `ValueKey('poly-sidebar-preview-gain-value')`, width `dbValueWidth`, semantic label `Preview gain value`, and value `'${state.previewGainDb.round()} dB'`
7. Add a required `rowKeySuffix` parameter to `_StepRow`.
8. Rewrite `_StepRow` using the exact widget tree and stable row rules from `spec.md`.
9. Add these `rowKeySuffix` values at each `_StepRow` call:
   - Root: `root`
   - Low: `low`
   - High: `high`
   - Velocity: `velocity`
   - Round robin: `round-robin`
10. Add the exact row, value, decrease-button, and increase-button keys from the row inventory in `spec.md`.
11. Preserve the exact mapping button tooltip strings:
    - `Decrease Root`, `Increase Root`
    - `Decrease Low`, `Increase Low`
    - `Decrease High`, `Increase High`
    - `Decrease Velocity`, `Increase Velocity`
    - `Decrease Round robin`, `Increase Round robin`
12. Import `package:nt_helper/ui/poly_multisample/widgets/poly_sample_sidebar_layout.dart` in `poly_samples_editor_view.dart`.
13. Replace `SizedBox(width: 320, child: inspector)` with `SizedBox(width: PolySampleSidebarLayout.panelWidth, child: inspector)`.
14. Update existing inspector tests that assert combined mapping text:
    - Replace `find.text('Root: C3')` with a descendant assertion for `find.text('Root')` and `find.text('C3')` inside key `poly-sidebar-mapping-root-row`.
    - Replace `find.text('Velocity: 1')` with a descendant assertion for `find.text('Velocity')` and `find.text('1')` inside key `poly-sidebar-mapping-velocity-row`.
    - Replace `find.text('Root: C#3')` with a descendant assertion for `find.text('C#3')` inside key `poly-sidebar-mapping-root-row`.
15. Add `import 'package:flutter/services.dart';` to `poly_sample_inspector_test.dart`.
16. Add helper functions at the bottom of `poly_sample_inspector_test.dart`:

```dart
Finder _byStableKey(String value) => find.byKey(ValueKey(value));

Rect _stableRect(WidgetTester tester, String value) {
  return tester.getRect(_byStableKey(value));
}

void _expectStableRect(Rect before, Rect after) {
  expect(after.topLeft, before.topLeft);
  expect(after.size, before.size);
}
```

17. Add test `mapping stepper geometry stays fixed across value width changes` to `poly_sample_inspector_test.dart`:
    - Create a cubit.
    - Set state from `_selectedState()` with the first edited region copied to `rootMidi: 48`, `rootName: 'C3'`, `velocityLayer: 9`, and `roundRobin: 9`.
    - Pump the inspector.
    - Capture rectangles for `poly-sidebar-mapping-root-increase`, `poly-sidebar-mapping-velocity-increase`, `poly-sidebar-mapping-round-robin-increase`, `poly-sidebar-mapping-root-row`, `poly-sidebar-mapping-velocity-row`, and `poly-sidebar-mapping-round-robin-row`.
    - Tap root increase once, velocity increase once, and round-robin increase once.
    - Pump after each tap.
    - Assert the first edited region has `rootMidi == 49`, `velocityLayer == 10`, and `roundRobin == 10`.
    - Capture the same rectangles again and call `_expectStableRect` for every pair.
18. Add test `mapping stepper focus and rect stay stable after keyboard activation` to `poly_sample_inspector_test.dart`:
    - Create a cubit and pump `_selectedState()`.
    - Use finder `_byStableKey('poly-sidebar-mapping-velocity-increase')`.
    - Tap the finder and pump.
    - Capture `FocusManager.instance.primaryFocus` and assert it is not null.
    - Capture the button rectangle.
    - Send `LogicalKeyboardKey.enter` with `tester.sendKeyEvent` and pump.
    - Assert the first edited region velocity is `3`.
    - Assert `FocusManager.instance.primaryFocus` is the same object captured before Enter.
    - Assert the button rectangle is unchanged with `_expectStableRect`.
19. Add semantics expectations to the existing inspector semantics test named `labels preview and destructive edit controls for semantics` immediately after the existing `expect(find.bySemanticsLabel('Preview gain'), findsOneWidget);` line:
    - `expect(find.bySemanticsLabel('Preview gain value'), findsOneWidget);`
    - `expect(find.bySemanticsLabel('Root value'), findsOneWidget);`
20. Update `poly_samples_editor_view_test.dart` by adding the helper import `import 'package:nt_helper/ui/poly_multisample/widgets/poly_sample_sidebar_layout.dart';` and adding this assertion to the existing desktop test named `shows toolbar stats, key map, list and inspector` immediately after `expect(find.byType(PolySampleInspector), findsOneWidget);`:
    - `expect(tester.getSize(find.byType(PolySampleInspector)).width, PolySampleSidebarLayout.panelWidth);`

### Leftover checks

Run these commands after edits and before verification:

```bash
cd /Users/nealsanche/nosuch/nt_helper
grep -n "class PolySampleSidebarLayout" lib/ui/poly_multisample/widgets/poly_sample_inspector.dart || true
grep -n "Root: \\$value\|Velocity: \\$value\|Round robin: \\$value" lib/ui/poly_multisample/widgets/poly_sample_inspector.dart || true
```

Expected output: no matching lines from either grep command. Zero symbols are moved in this step.

### Commit message

`fix(poly-samples): stabilize mapping sidebar rows`

### Verification commands

```bash
cd /Users/nealsanche/nosuch/nt_helper
dart format lib/ui/poly_multisample/widgets/poly_sample_sidebar_layout.dart lib/ui/poly_multisample/widgets/poly_sample_inspector.dart lib/ui/poly_multisample/poly_samples_editor_view.dart test/poly_multisample/widgets/poly_sample_inspector_test.dart test/poly_multisample/poly_samples_editor_view_test.dart
flutter analyze
flutter test test/poly_multisample/widgets/poly_sample_inspector_test.dart test/poly_multisample/poly_samples_editor_view_test.dart
git add lib/ui/poly_multisample/widgets/poly_sample_sidebar_layout.dart lib/ui/poly_multisample/widgets/poly_sample_inspector.dart lib/ui/poly_multisample/poly_samples_editor_view.dart test/poly_multisample/widgets/poly_sample_inspector_test.dart test/poly_multisample/poly_samples_editor_view_test.dart && git status --short
git commit -m "fix(poly-samples): stabilize mapping sidebar rows"
```

Only the five named files may appear in `git status --short` before commit.

## STEP 2 of 2: stabilize waveform frame, fade, gain, and peak rows

### Files to edit

- Edit `lib/ui/poly_multisample/widgets/poly_sample_inspector.dart`
- Edit `test/poly_multisample/widgets/poly_sample_inspector_test.dart`

### Mechanical changes

1. Add required `rowKeySuffix` to `_FrameNudgeRow`.
2. Rewrite `_FrameNudgeRow` using the exact widget tree and stable row rules from `spec.md`.
3. Add these `rowKeySuffix` values at each `_FrameNudgeRow` call:
   - Loop start: `loop-start`
   - Loop end: `loop-end`
   - Trim start: `trim-start`
   - Trim end: `trim-end`
4. Add the exact row, value, and four button keys from the row inventory in `spec.md`.
5. Preserve the exact frame button tooltip string format: `'$label ${delta.isNegative ? '' : '+'}$delta frames'`.
6. Rewrite the destructive gain row using:
   - `SizedBox(height: PolySampleSidebarLayout.rowHeight)` around the row
   - fixed label width `sliderLabelWidth`
   - existing slider key `ValueKey('poly-wav-gain-slider')`
   - trailing `PolySampleSidebarSliderValue` key `ValueKey('poly-sidebar-wav-gain-value')`, width `dbValueWidth`, semantic label `Audio gain value`, and value `'${wavDraft.gainDb.toStringAsFixed(1)} dB'`
7. Add key `ValueKey('poly-sidebar-normalize-peak-slider')` to the normalize peak slider.
8. Rewrite the normalize peak row using:
   - `SizedBox(height: PolySampleSidebarLayout.rowHeight)` around the row
   - fixed label width `sliderLabelWidth`
   - expanded slider
   - trailing `PolySampleSidebarSliderValue` key `ValueKey('poly-sidebar-normalize-peak-value')`, width `dbValueWidth`, semantic label `Normalize peak value`, and value `'${(wavDraft.normalizePeakDb ?? -0.3).toStringAsFixed(1)} dB'`
9. Rewrite `_FadeRow` so it uses no `Wrap`.
10. `_FadeRow` renders the exact four-part sequence from `spec.md`: title text, length row, curve row, strength row.
11. `_FadeRow` row/key suffix is derived mechanically from the label:
    - `Fade in` becomes `fade-in`
    - `Fade out` becomes `fade-out`
12. Add exact fade keys:
    - length rows `poly-sidebar-fade-in-length-row`, `poly-sidebar-fade-out-length-row`
    - length values `poly-sidebar-fade-in-length-value`, `poly-sidebar-fade-out-length-value`
    - curve dropdowns `poly-sidebar-fade-in-curve-dropdown`, `poly-sidebar-fade-out-curve-dropdown`
    - strength rows `poly-sidebar-fade-in-strength-row`, `poly-sidebar-fade-out-strength-row`
    - strength values `poly-sidebar-fade-in-strength-value`, `poly-sidebar-fade-out-strength-value`
13. Fade curve dropdowns use `SizedBox(width: PolySampleSidebarLayout.fadeCurveDropdownWidth)` and `DropdownButton<WavFadeCurve>(isExpanded: true, ...)`.
14. Keep existing fade slider semantics labels and formatter behavior.
15. Add test `waveform nudge geometry stays fixed across frame digit changes` to `poly_sample_inspector_test.dart`:
    - Create a cubit.
    - Set `_selectedState()` with waveform summary from `_overview()`, loop draft `loopStart: 99`, `loopEnd: 900`, and wav edit draft `trimStart: 99`, `trimEnd: 900`.
    - Pump inspector and settle.
    - Scroll until `poly-sidebar-frame-loop-start-plus1` is visible.
    - Capture rectangles for `poly-sidebar-frame-loop-start-row`, `poly-sidebar-frame-loop-start-plus1`, `poly-sidebar-frame-loop-end-minus1`.
    - Tap `poly-sidebar-frame-loop-start-plus1` and pump.
    - Capture the same rectangles and assert stability.
    - Scroll until `poly-sidebar-frame-trim-start-plus1` is visible.
    - Capture rectangles for `poly-sidebar-frame-trim-start-row`, `poly-sidebar-frame-trim-start-plus1`, `poly-sidebar-frame-trim-end-minus1`.
    - Tap `poly-sidebar-frame-trim-start-plus1` and pump.
    - Capture the same rectangles and assert stability.
    - Assert loop start and trim start are both `100`.
16. Add test `waveform slider geometry stays fixed across gain and peak value changes`:
    - Create a cubit.
    - Set `_selectedState()` with `_overview()` and wav edit draft `gainDb: 9.9`, `normalizePeakDb: -9.9`.
    - Pump inspector.
    - Scroll until `poly-wav-gain-slider` is visible.
    - Capture rectangles for `poly-wav-gain-slider` and `poly-sidebar-wav-gain-value`.
    - Call `cubit.updateWavEditDraft('/tmp/Piano/Piano_C3.wav', const PolyWaveformDraft(gainDb: 10.0, normalizePeakDb: -10.0));` and pump.
    - Capture and assert the gain rectangles are stable.
    - Scroll until `poly-sidebar-normalize-peak-slider` is visible.
    - Capture rectangles for `poly-sidebar-normalize-peak-slider` and `poly-sidebar-normalize-peak-value`.
    - Call `cubit.updateWavEditDraft('/tmp/Piano/Piano_C3.wav', const PolyWaveformDraft(gainDb: 10.0, normalizePeakDb: -0.3));` and pump.
    - Capture and assert the peak rectangles are stable.
17. Add test `fade geometry stays fixed across curve and strength value changes`:
    - Create a cubit.
    - Set `_selectedState()` with `_overview()` and wav edit draft `fadeInFrames: 441`, `fadeInCurve: WavFadeCurve.linear`, `fadeInStrength: 0.95`.
    - Pump inspector.
    - Scroll until `poly-sidebar-fade-in-curve-dropdown` is visible.
    - Capture rectangles for `poly-sidebar-fade-in-curve-dropdown`, `poly-sidebar-fade-in-strength-row`, and `poly-sidebar-fade-in-strength-value`.
    - Call `cubit.updateWavEditDraft('/tmp/Piano/Piano_C3.wav', const PolyWaveformDraft(fadeInFrames: 882, fadeInCurve: WavFadeCurve.equalPower, fadeInStrength: 1.0));` and pump.
    - Capture and assert every rectangle is stable.
18. Extend the existing semantics test named `labels preview and destructive edit controls for semantics` after the existing waveform-control expectations that follow the `await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -420));` block:
    - `expect(find.bySemanticsLabel('Audio gain value'), findsOneWidget);`
    - `expect(find.bySemanticsLabel('Normalize peak value'), findsOneWidget);`
    - `expect(find.bySemanticsLabel('Fade in length'), findsOneWidget);`
    - `expect(find.bySemanticsLabel('Fade in strength'), findsOneWidget);`
    - `expect(find.bySemanticsLabel('Fade in length value'), findsOneWidget);`
    - `expect(find.bySemanticsLabel('Fade in strength value'), findsOneWidget);`
19. Keep all existing inspector tests green by replacing any removed combined frame text finder with the matching row/value key from `spec.md`; do not change expected cubit state values.

### Leftover checks

Run these commands after edits and before verification:

```bash
cd /Users/nealsanche/nosuch/nt_helper
grep -n "Wrap(" lib/ui/poly_multisample/widgets/poly_sample_inspector.dart || true
grep -n "\\$label: \\$value" lib/ui/poly_multisample/widgets/poly_sample_inspector.dart || true
```

Expected output: no matching lines from either grep command. Zero symbols are moved in this step.

### Commit message

`fix(poly-samples): stabilize waveform sidebar rows`

### Verification commands

```bash
cd /Users/nealsanche/nosuch/nt_helper
dart format lib/ui/poly_multisample/widgets/poly_sample_inspector.dart test/poly_multisample/widgets/poly_sample_inspector_test.dart
flutter analyze
flutter test test/poly_multisample/widgets/poly_sample_inspector_test.dart
flutter analyze && flutter test
git add lib/ui/poly_multisample/widgets/poly_sample_inspector.dart test/poly_multisample/widgets/poly_sample_inspector_test.dart && git status --short
git commit -m "fix(poly-samples): stabilize waveform sidebar rows"
```

Only the two named files may appear in `git status --short` before commit.
