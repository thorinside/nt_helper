# Split stepper control spec

Baseline ref: `HEAD` (`b5cca591` at spec authoring time)

Hardening policy: realistic-only

Verification command hint: `flutter analyze && flutter test`

## Inventory summary

Inventory was generated with:

```bash
python3 /Users/nealsanche/nosuch/nt_helper/.pi/skills/decision-free-specs/languages/dart/inventory.py \
  lib/ui/poly_multisample/poly_samples_editor_view.dart \
  lib/ui/poly_multisample/widgets/poly_sample_inspector.dart \
  lib/ui/poly_multisample/widgets/poly_waveform_editor.dart \
  lib/ui/poly_multisample/widgets/poly_sample_list.dart \
  lib/ui/poly_multisample/poly_multisample_builder_cubit.dart \
  lib/ui/poly_multisample/poly_region_math.dart \
  test/poly_multisample/poly_samples_editor_view_test.dart \
  test/poly_multisample/widgets/poly_sample_inspector_test.dart \
  test/poly_multisample/widgets/poly_waveform_editor_test.dart
```

Hand check completed for `lib/ui/poly_multisample/widgets/poly_sample_inspector.dart`: the inventory declaration list matches the file structure around `PolySampleInspector`, `_MappingSection`, `_WaveformSection`, `_StepRow`, and `_FrameNudgeRow`.

Relevant inventory facts:

| File | Size | Relevant declarations | Imported by |
|---|---:|---|---|
| `lib/ui/poly_multisample/poly_samples_editor_view.dart` | 316 lines | `PolySamplesEditorView`, `_EditorBody` | `lib/ui/poly_multisample/poly_samples_screen.dart`, `test/poly_multisample/poly_samples_editor_view_test.dart` |
| `lib/ui/poly_multisample/widgets/poly_sample_inspector.dart` | 794 lines | `PolySampleInspector`, `_MappingSection`, `_WaveformSection`, `_StepRow`, `_FrameNudgeRow` | `lib/ui/poly_multisample/poly_samples_editor_view.dart`, `test/poly_multisample/poly_samples_editor_view_test.dart`, `test/poly_multisample/widgets/poly_sample_inspector_test.dart` |
| `lib/ui/poly_multisample/widgets/poly_waveform_editor.dart` | 546 lines | `PolyWaveformEditor`, keyboard intents and semantics for waveform canvas | `lib/ui/poly_multisample/widgets/poly_sample_inspector.dart`, waveform tests |
| `lib/ui/poly_multisample/poly_multisample_builder_cubit.dart` | 1512 lines | region and waveform draft update methods | many poly multisample UI and test files |
| `test/poly_multisample/widgets/poly_sample_inspector_test.dart` | 443 lines | inspector widget tests | no imports |
| `test/poly_multisample/widgets/poly_waveform_editor_test.dart` | 584 lines | waveform editor tests | no imports |

## Architecture

Add one reusable Flutter widget for segmented stepper controls. Use it inside the poly multisample sample inspector, which is the sidebar at widths `>= 900` because `_EditorBody` renders `SizedBox(width: 320, child: inspector)`.

No cubit, parser, model, waveform painter, file-system, MIDI, hardware, or save-service changes are part of this program.

### Target file tree

| Path | Action |
|---|---|
| `lib/ui/widgets/split_stepper_control.dart` | New reusable widget file |
| `test/ui/widgets/split_stepper_control_test.dart` | New reusable widget tests |
| `lib/ui/poly_multisample/widgets/poly_sample_inspector.dart` | Replace internal jog button visuals with the reusable widget |
| `test/poly_multisample/widgets/poly_sample_inspector_test.dart` | Update and extend inspector tests |
| `specs/README.md` | Program table row already added by this spec authoring commit |

### Symbol map

| Symbol | Current location | Destination after implementation | Exported | Notes |
|---|---|---|---|---|
| `SplitStepperControl` | New symbol | `lib/ui/widgets/split_stepper_control.dart` | yes | Public reusable widget |
| `_SplitStepperActionSpec` | New symbol | `lib/ui/widgets/split_stepper_control.dart` | no | Private immutable action descriptor |
| `_SplitStepperSegment` | New symbol | `lib/ui/widgets/split_stepper_control.dart` | no | Private segment button widget |
| `_StepRow` | `lib/ui/poly_multisample/widgets/poly_sample_inspector.dart` | stays in same file | no | Build method delegates to `SplitStepperControl` |
| `_FrameNudgeRow` | `lib/ui/poly_multisample/widgets/poly_sample_inspector.dart` | stays in same file | no | Build method delegates to `SplitStepperControl.largeAndSmall` |
| `PolySampleInspector` | `lib/ui/poly_multisample/widgets/poly_sample_inspector.dart` | unchanged | yes | Public compatibility unchanged |
| `PolyWaveformEditor` | `lib/ui/poly_multisample/widgets/poly_waveform_editor.dart` | unchanged | yes | No changes |

No compatibility re-export is needed because no existing public symbol moves.

## Reusable widget API

File: `lib/ui/widgets/split_stepper_control.dart`

Imports:

```dart
import 'package:flutter/material.dart';
```

Public API:

```dart
class SplitStepperControl extends StatelessWidget {
  const SplitStepperControl({
    super.key,
    required this.label,
    required this.valueLabel,
    required this.onDecrement,
    required this.onIncrement,
  }) : smallStepLabel = null,
       largeStepLabel = null,
       onSmallDecrement = null,
       onSmallIncrement = null,
       onLargeDecrement = null,
       onLargeIncrement = null;

  const SplitStepperControl.largeAndSmall({
    super.key,
    required this.label,
    required this.valueLabel,
    required this.smallStepLabel,
    required this.largeStepLabel,
    required this.onSmallDecrement,
    required this.onSmallIncrement,
    required this.onLargeDecrement,
    required this.onLargeIncrement,
  }) : onDecrement = null,
       onIncrement = null;

  final String label;
  final String valueLabel;
  final VoidCallback? onDecrement;
  final VoidCallback? onIncrement;
  final String? smallStepLabel;
  final String? largeStepLabel;
  final VoidCallback? onSmallDecrement;
  final VoidCallback? onSmallIncrement;
  final VoidCallback? onLargeDecrement;
  final VoidCallback? onLargeIncrement;
}
```

Constructor behavior:

| Constructor | Rendered segments from left to right | Segment text/icon | Tooltip and semantics label |
|---|---|---|---|
| default | decrement, increment | `Icons.remove`, `Icons.add` | `Decrease <label>`, `Increase <label>` |
| `largeAndSmall` | large decrement, small decrement, small increment, large increment | `−<largeStepLabel>`, `−<smallStepLabel>`, `+<smallStepLabel>`, `+<largeStepLabel>` with the sign prepended by the widget | `Decrease <label> by <largeStepLabel>`, `Decrease <label> by <smallStepLabel>`, `Increase <label> by <smallStepLabel>`, `Increase <label> by <largeStepLabel>` |

For `largeAndSmall`, call sites pass unsigned labels. The frame nudge call site passes `smallStepLabel: '1 frame'` and `largeStepLabel: '100 frames'`.

Private helper contracts:

```dart
class _SplitStepperActionSpec {
  const _SplitStepperActionSpec({
    required this.tooltip,
    required this.child,
    required this.onPressed,
    required this.width,
  });

  final String tooltip;
  final Widget child;
  final VoidCallback? onPressed;
  final double width;
}

class _SplitStepperSegment extends StatelessWidget {
  const _SplitStepperSegment({required this.action});

  final _SplitStepperActionSpec action;
}
```

`_SplitStepperSegment.build` returns the semantics-wrapped `IconButton` for one segment. The `IconButton` uses `constraints: BoxConstraints.tightFor(width: action.width, height: 32)`, `padding: EdgeInsets.zero`, `visualDensity: VisualDensity.compact`, `tooltip: action.tooltip`, `onPressed: action.onPressed`, and `icon: action.child`.

Visual rules:

- The control is a single pill-shaped segmented control.
- Use `DecoratedBox` with `ShapeDecoration` and `StadiumBorder` using `Theme.of(context).colorScheme.outlineVariant` for the border.
- Use `Theme.of(context).colorScheme.surfaceContainerHighest` for the background.
- Each segment is exactly 32 logical pixels high.
- Default constructor segment width is 32 logical pixels.
- `largeAndSmall` segment width is 54 logical pixels.
- Add a vertical divider with width `1`, thickness `1`, and color `outlineVariant` between every pair of adjacent segments.
- Default constructor icons have size `16`.
- `largeAndSmall` segment text uses `Theme.of(context).textTheme.labelSmall`.
- Use Unicode minus `−` (`U+2212`) for visible negative labels in `largeAndSmall`.

Accessibility and focus rules:

- Wrap the whole control in `Semantics(container: true, label: label, value: valueLabel)`.
- Every segment is an `IconButton` with the exact tooltip named above.
- Wrap every `IconButton` in `Semantics(button: true, label: tooltipText, enabled: onPressed != null, excludeSemantics: true)` so the tooltip does not create a duplicate semantics node.
- Do not add custom arrow-key shortcuts. Tab traversal reaches each segment in left-to-right order. Enter and Space activation use Flutter `IconButton` default behavior.
- Do not create live-region announcements. These controls update already-visible draft values synchronously.

## Sidebar integration

File: `lib/ui/poly_multisample/widgets/poly_sample_inspector.dart`

Add import:

```dart
import 'package:nt_helper/ui/widgets/split_stepper_control.dart';
```

### Mapping rows

Keep `_StepRow` and its constructor unchanged. Replace the two standalone `IconButton`s in `_StepRow.build` with the default `SplitStepperControl`.

Required visible layout:

```dart
return Semantics(
  label: '$label $value',
  child: Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text('$label: $value'),
      const SizedBox(width: 8),
      SplitStepperControl(
        label: label,
        valueLabel: value,
        onDecrement: onMinus,
        onIncrement: onPlus,
      ),
    ],
  ),
);
```

Target rows, all in `_MappingSection`:

| Row label | Value source | Decrement callback | Increment callback |
|---|---|---|---|
| `Root` | existing value expression | existing `cubit.updateRoot(region.path, root - 1)` | existing `cubit.updateRoot(region.path, root + 1)` |
| `Low` | existing value expression | existing `cubit.updateRangeLow(region.path, low - 1)` | existing `cubit.updateRangeLow(region.path, low + 1)` |
| `High` | existing value expression | existing `cubit.updateRangeHigh(region.path, high - 1)` | existing `cubit.updateRangeHigh(region.path, high + 1)` |
| `Velocity` | existing value expression | existing clamped callback | existing increment callback |
| `Round robin` | existing value expression | existing clamped callback | existing increment callback |

### Frame nudge rows

Keep `_FrameNudgeRow` and its constructor unchanged. Replace the `for (final delta in const [-100, -1, 1, 100]) IconButton(...)` loop with `SplitStepperControl.largeAndSmall`.

Required visible layout:

```dart
return Row(
  children: [
    Expanded(child: Text('$label: $value')),
    SplitStepperControl.largeAndSmall(
      label: label,
      valueLabel: '$value frames',
      smallStepLabel: '1 frame',
      largeStepLabel: '100 frames',
      onLargeDecrement: () => onNudge(-100),
      onSmallDecrement: () => onNudge(-1),
      onSmallIncrement: () => onNudge(1),
      onLargeIncrement: () => onNudge(100),
    ),
  ],
);
```

Target rows, all in `_WaveformSection`:

| Row label | Visibility | Existing clamp behavior to preserve |
|---|---|---|
| `Loop start` | only while loop enabled | start stays `>= 0` and `< loopEnd` |
| `Loop end` | only while loop enabled | end stays `> loopStart` and `<= maxFrame` |
| `Trim start` | always when waveform overview exists | start stays `>= 0` and `< trimEnd` |
| `Trim end` | always when waveform overview exists | end stays `> trimStart` and `<= maxFrame` |

## Tests

### New file: `test/ui/widgets/split_stepper_control_test.dart`

Imports:

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/ui/widgets/split_stepper_control.dart';
```

Required tests:

| Test name | Assertions |
|---|---|
| `compact split stepper renders two semantic buttons and fires callbacks` | Pump default constructor with `label: 'Root'`, `valueLabel: 'C3'`; find tooltips `Decrease Root` and `Increase Root`; find semantics label `Root`; semantics data value is `C3`; tapping both tooltips increments separate counters once |
| `large and small split stepper renders four ordered actions` | Pump `largeAndSmall` with `label: 'Trim start'`, `valueLabel: '400 frames'`, `smallStepLabel: '1 frame'`, `largeStepLabel: '100 frames'`; find the four exact tooltips from the API table; tap each tooltip left to right; collected deltas equal `[-100, -1, 1, 100]` |
| `split stepper supports keyboard focus activation` | Pump default constructor; send Tab to focus `Decrease Root`; send Enter; send Tab to focus `Increase Root`; send Space; final decrement count is `1` and increment count is `1` |

### Update file: `test/poly_multisample/widgets/poly_sample_inspector_test.dart`

Required updates:

| Test | Required assertions |
|---|---|
| `shows mapping steppers for the selected sample` | Keep existing text expectations; assert tooltips `Decrease Root` and `Increase Root`; assert tooltip `Increase Round robin` |
| `root stepper updates the cubit` | Keep the existing tap on `Increase Root` and result `C#3` |
| `waveform nudge buttons keep endpoints ordered` | Replace old tooltip strings with `Increase Loop start by 100 frames`, `Decrease Loop end by 100 frames`, `Increase Trim start by 100 frames`, `Decrease Trim end by 100 frames`; preserve all final state expectations |
| `labels preview and destructive edit controls for semantics` | Add assertions for semantics labels `Root`, `Decrease Root`, and, after scrolling to the frame rows, `Increase Trim start by 1 frame` |

No changes to `test/poly_multisample/widgets/poly_waveform_editor_test.dart` are required.

## Decision inventory

| Decision | Rationale | Files affected | Status |
|---|---|---|---|
| Add `SplitStepperControl` under `lib/ui/widgets/` rather than under poly multisample | The control is a reusable UI primitive and not domain-specific | `lib/ui/widgets/split_stepper_control.dart`, `test/ui/widgets/split_stepper_control_test.dart` | required |
| Use two constructors on one widget, not separate compact and large widgets | The visual pattern, semantics, and focus behavior are shared | `lib/ui/widgets/split_stepper_control.dart` | required |
| Keep `_StepRow` and `_FrameNudgeRow` as private inspector layout wrappers | The row labels and cubit callbacks remain local to the sidebar | `lib/ui/poly_multisample/widgets/poly_sample_inspector.dart` | required |
| Use the compact two-segment control for `Root`, `Low`, `High`, `Velocity`, and `Round robin` | These are existing numeric jog controls in the mapping sidebar | `lib/ui/poly_multisample/widgets/poly_sample_inspector.dart` | required |
| Use the four-segment large/small control for `Loop start`, `Loop end`, `Trim start`, and `Trim end` | These rows already expose `-100`, `-1`, `+1`, and `+100` frame jogs | `lib/ui/poly_multisample/widgets/poly_sample_inspector.dart` | required |
| Do not change `PolyWaveformEditor` keyboard shortcuts | The waveform canvas already owns direct manipulation and keyboard behavior | none | out-of-scope |
| Do not change cubit clamp logic | Existing callbacks already enforce endpoint order and bounds | none | out-of-scope |
| Do not add success snackbars or live-region announcements | Button actions synchronously update visible draft values | none | out-of-scope |
| Do not add a strategy registry | The variance is visual/action count only, not behavioral request shape variance | none | out-of-scope |
| Disabled-button hardening is not required in this feature path | All current target sidebar callbacks are always non-null when rows render | none | optional |

## Hardening matrix

| Risk | Plausible path | Chosen handling | Tests required |
|---|---|---|---|
| Screen reader users hear unlabeled minus/plus icons | User navigates the sidebar with VoiceOver, TalkBack, or desktop screen reader | Parent semantics exposes field label and value; every segment has exact action label | `split_stepper_control_test.dart` compact semantics test; inspector semantics assertions |
| Keyboard-only users cannot operate the compact control | User tabs through the sidebar and presses Enter or Space | Use `IconButton` segments with default focus and activation | `split_stepper_control_test.dart` keyboard focus activation test |
| Frame endpoints cross during rapid large nudge taps | User repeatedly taps `+100` start or `-100` end near the other endpoint | Preserve existing clamp callbacks in `_WaveformSection` | Existing inspector nudge test with updated tooltips |
| Mapping rows regress by wiring the wrong callback to a segment | User taps Root plus expecting the root note to increase | Keep `_StepRow` callback names and test `Increase Root` changes C3 to C#3 | Existing root stepper test |
| File-system or WAV data corruption during editing | The split stepper only changes in-memory draft values; WAV writes still occur only through existing Save/Overwrite buttons | No new file-system hardening in this program | No new tests |
| MIDI or hardware latency affects jog controls | The target controls update local draft state and do not call hardware APIs | Hardware/API latency is outside this program | No new tests |
| Async race while waveform loads | The controls render only after `overview != null`; loading state shows no jog buttons | Existing loading gate remains unchanged | No new tests |

## Acceptance criteria

- `SplitStepperControl` exists with the exact API above.
- The poly multisample inspector mapping jog rows render compact segmented `− | +` controls.
- Loop and trim frame jog rows render the large/small segmented controls with `100 frames` and `1 frame` actions.
- Existing cubit update behavior and endpoint clamps are preserved.
- Accessibility labels and keyboard activation are covered by tests.
- Verification passes with `flutter analyze` and the named tests in `plan.md`.
