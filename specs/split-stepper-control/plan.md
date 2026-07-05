# Split stepper control implementation plan

Total steps: 3

Each step is independently committable. Execute exactly one numbered step per fresh-context session. Read `specs/conventions.md` and `specs/split-stepper-control/spec.md` before editing.

Program-level verification after STEP 3:

```bash
cd /Users/nealsanche/nosuch/nt_helper
flutter analyze
flutter test test/ui/widgets/split_stepper_control_test.dart test/poly_multisample/widgets/poly_sample_inspector_test.dart
```

## STEP 1 of 3 — Add reusable split stepper widget

### Files to edit

- Create `lib/ui/widgets/split_stepper_control.dart`
- Create `test/ui/widgets/split_stepper_control_test.dart`

### Required implementation

1. Create `lib/ui/widgets/split_stepper_control.dart` with the public API, visual rules, semantics rules, and focus rules from `spec.md`.
2. Use private helper symbols named exactly `_SplitStepperActionSpec` and `_SplitStepperSegment`.
3. The default constructor renders exactly two segments in this order: decrement, increment.
4. The `largeAndSmall` constructor renders exactly four segments in this order: large decrement, small decrement, small increment, large increment.
5. Use exact tooltip strings from `spec.md`.
6. Use exact dimensions from `spec.md`.
7. Create `test/ui/widgets/split_stepper_control_test.dart` with exactly these tests:
   - `compact split stepper renders two semantic buttons and fires callbacks`
   - `large and small split stepper renders four ordered actions`
   - `split stepper supports keyboard focus activation`
8. The keyboard test uses Tab, Enter, Tab, Space in that order.

### Leftover checks

Run:

```bash
grep -n "class SplitStepperControl" lib/ui/widgets/split_stepper_control.dart
grep -n "class _SplitStepperActionSpec" lib/ui/widgets/split_stepper_control.dart
grep -n "class _SplitStepperSegment" lib/ui/widgets/split_stepper_control.dart
```

Expected counts: one line for each command.

### Verification commands

```bash
cd /Users/nealsanche/nosuch/nt_helper
dart format lib/ui/widgets/split_stepper_control.dart test/ui/widgets/split_stepper_control_test.dart
flutter analyze
flutter test test/ui/widgets/split_stepper_control_test.dart
git add lib/ui/widgets/split_stepper_control.dart test/ui/widgets/split_stepper_control_test.dart
git status --short
git commit -m "feat(split-stepper): add reusable compact control"
```

Only these files may appear in `git status --short` before the commit:

- `lib/ui/widgets/split_stepper_control.dart`
- `test/ui/widgets/split_stepper_control_test.dart`

### Commit message

`feat(split-stepper): add reusable compact control`

## STEP 2 of 3 — Use compact split steppers for mapping rows

### Prerequisites

- STEP 1 committed with message `feat(split-stepper): add reusable compact control`.

### Files to edit

- `lib/ui/poly_multisample/widgets/poly_sample_inspector.dart`
- `test/poly_multisample/widgets/poly_sample_inspector_test.dart`

### Required implementation

1. Add this import to `lib/ui/poly_multisample/widgets/poly_sample_inspector.dart`:

   ```dart
   import 'package:nt_helper/ui/widgets/split_stepper_control.dart';
   ```

2. Keep the `_StepRow` constructor and fields unchanged.
3. Replace only the two `IconButton` widgets inside `_StepRow.build` with the exact `SplitStepperControl` row shown in `spec.md`.
4. Do not edit `_FrameNudgeRow` in this step.
5. In `test/poly_multisample/widgets/poly_sample_inspector_test.dart`, update `shows mapping steppers for the selected sample` so it asserts:
   - `find.text('Root: C3')` finds one widget.
   - `find.text('Velocity: 1')` finds one widget.
   - `find.byTooltip('Decrease Root')` finds one widget.
   - `find.byTooltip('Increase Root')` finds one widget.
   - `find.byTooltip('Increase Round robin')` finds one widget.
6. Keep `root stepper updates the cubit` tapping `find.byTooltip('Increase Root')` and expecting root MIDI `49` plus visible text `Root: C#3`.
7. In `labels preview and destructive edit controls for semantics`, add these assertions before the scroll that reveals waveform controls:
   - `find.bySemanticsLabel('Root')` finds one widget.
   - `find.bySemanticsLabel('Decrease Root')` finds one widget.

### Leftover checks

Run:

```bash
grep -n "SplitStepperControl(" lib/ui/poly_multisample/widgets/poly_sample_inspector.dart
grep -n "Increase Round robin" test/poly_multisample/widgets/poly_sample_inspector_test.dart
grep -n "Loop start by 100 frames" test/poly_multisample/widgets/poly_sample_inspector_test.dart || true
```

Expected counts:

- `SplitStepperControl(` appears once.
- `Increase Round robin` appears once.
- `Loop start by 100 frames` appears zero times in this step.

### Verification commands

```bash
cd /Users/nealsanche/nosuch/nt_helper
dart format lib/ui/poly_multisample/widgets/poly_sample_inspector.dart test/poly_multisample/widgets/poly_sample_inspector_test.dart
flutter analyze
flutter test test/poly_multisample/widgets/poly_sample_inspector_test.dart
git add lib/ui/poly_multisample/widgets/poly_sample_inspector.dart test/poly_multisample/widgets/poly_sample_inspector_test.dart
git status --short
git commit -m "feat(poly-samples): use split steppers for mapping fields"
```

Only these files may appear in `git status --short` before the commit:

- `lib/ui/poly_multisample/widgets/poly_sample_inspector.dart`
- `test/poly_multisample/widgets/poly_sample_inspector_test.dart`

### Commit message

`feat(poly-samples): use split steppers for mapping fields`

## STEP 3 of 3 — Use large/small split steppers for frame jog rows

### Prerequisites

- STEP 1 committed with message `feat(split-stepper): add reusable compact control`.
- STEP 2 committed with message `feat(poly-samples): use split steppers for mapping fields`.

### Files to edit

- `lib/ui/poly_multisample/widgets/poly_sample_inspector.dart`
- `test/poly_multisample/widgets/poly_sample_inspector_test.dart`

### Required implementation

1. Keep the `_FrameNudgeRow` constructor and fields unchanged.
2. Replace only the `for (final delta in const [-100, -1, 1, 100]) IconButton(...)` loop inside `_FrameNudgeRow.build` with the exact `SplitStepperControl.largeAndSmall` row shown in `spec.md`.
3. Preserve all existing clamp logic in `_WaveformSection`; only `_FrameNudgeRow.build` changes for frame jog behavior.
4. In `waveform nudge buttons keep endpoints ordered`, replace old frame tooltip strings with exact new strings:
   - `Increase Loop start by 100 frames`
   - `Decrease Loop end by 100 frames`
   - `Increase Trim start by 100 frames`
   - `Decrease Trim end by 100 frames`
5. In `labels preview and destructive edit controls for semantics`, after scrolling far enough for trim rows, add this assertion:
   - `find.bySemanticsLabel('Increase Trim start by 1 frame')` finds one widget.
6. Do not edit `test/poly_multisample/widgets/poly_waveform_editor_test.dart`.

### Leftover checks

Run:

```bash
grep -n "SplitStepperControl.largeAndSmall" lib/ui/poly_multisample/widgets/poly_sample_inspector.dart
grep -n "for (final delta in const \[-100, -1, 1, 100\])" lib/ui/poly_multisample/widgets/poly_sample_inspector.dart || true
grep -n "Increase Loop start by 100 frames" test/poly_multisample/widgets/poly_sample_inspector_test.dart
grep -n "Loop start +100 frames" test/poly_multisample/widgets/poly_sample_inspector_test.dart || true
```

Expected counts:

- `SplitStepperControl.largeAndSmall` appears once.
- The old `for (final delta...)` loop appears zero times.
- `Increase Loop start by 100 frames` appears two times: one `scrollUntilVisible`, one `tap`.
- `Loop start +100 frames` appears zero times.

### Verification commands

```bash
cd /Users/nealsanche/nosuch/nt_helper
dart format lib/ui/poly_multisample/widgets/poly_sample_inspector.dart test/poly_multisample/widgets/poly_sample_inspector_test.dart
flutter analyze
flutter test test/ui/widgets/split_stepper_control_test.dart test/poly_multisample/widgets/poly_sample_inspector_test.dart
git add lib/ui/poly_multisample/widgets/poly_sample_inspector.dart test/poly_multisample/widgets/poly_sample_inspector_test.dart
git status --short
git commit -m "feat(poly-samples): add split frame nudge controls"
```

Only these files may appear in `git status --short` before the commit:

- `lib/ui/poly_multisample/widgets/poly_sample_inspector.dart`
- `test/poly_multisample/widgets/poly_sample_inspector_test.dart`

### Commit message

`feat(poly-samples): add split frame nudge controls`
