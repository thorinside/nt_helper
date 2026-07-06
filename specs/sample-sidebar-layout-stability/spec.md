# Sample sidebar layout stability

Baseline ref: `HEAD` (`c8e4f648` at spec authoring time)  
Target language: Dart / Flutter  
Hardening policy: realistic-only  
Program folder: `specs/sample-sidebar-layout-stability`

## Request

Rework the poly multisample sample editor side panel so changing values never changes the geometry of an existing side-panel row. Repeated clicks on steppers and jog controls must keep numeric text, controls, row positions, and hit targets stable.

## Inventory method

The inventory was generated before reading implementation blocks:

```bash
python3 /Users/nealsanche/nosuch/nt_helper/.pi/skills/decision-free-specs/languages/dart/inventory.py \
  lib/ui/poly_multisample/widgets/poly_sample_inspector.dart \
  lib/ui/poly_multisample/widgets/poly_waveform_editor.dart \
  lib/ui/poly_multisample/poly_samples_editor_view.dart \
  lib/ui/poly_multisample/widgets/poly_sample_list.dart \
  test/poly_multisample/widgets/poly_sample_inspector_test.dart \
  test/poly_multisample/widgets/poly_waveform_editor_test.dart \
  test/poly_multisample/poly_samples_editor_view_test.dart \
  > /tmp/sample_sidebar_inventory.md
```

One real file was hand-checked against the inventory: `lib/ui/poly_multisample/widgets/poly_sample_inspector.dart`. The inventory declarations match the file's top-level declarations and private widget order.

## Source inventory

| File | Current size | Relevant declarations | Imported by |
|---|---:|---|---|
| `lib/ui/poly_multisample/widgets/poly_sample_inspector.dart` | 794 lines | `PolySampleInspector`, `_HeaderRow`, `_PreviewControls`, `_MappingSection`, `_WaveformSection`, `_FadeRow`, `_StepRow`, `_FrameNudgeRow`, `_curveLabel`, `_isLocalPath`, `_revealFolder` | `lib/ui/poly_multisample/poly_samples_editor_view.dart`, `test/poly_multisample/poly_samples_editor_view_test.dart`, `test/poly_multisample/widgets/poly_sample_inspector_test.dart` |
| `lib/ui/poly_multisample/widgets/poly_waveform_editor.dart` | 546 lines | `PolyWaveformEditorMode`, `PolyWaveformEditor`, `_PolyWaveformEditorState`, waveform intents, `_PolyWaveformPainter` | `lib/ui/poly_multisample/widgets/poly_sample_inspector.dart`, waveform tests |
| `lib/ui/poly_multisample/poly_samples_editor_view.dart` | 316 lines | `PolySamplesEditorView`, `_Toolbar`, `_EditorBody`, `_WarningPanel` | `lib/ui/poly_multisample/poly_samples_screen.dart`, editor tests |
| `lib/ui/poly_multisample/widgets/poly_sample_list.dart` | 142 lines | `PolySampleList`, `_PolySampleListState` | editor view and sample list tests |
| `test/poly_multisample/widgets/poly_sample_inspector_test.dart` | 443 lines | `main`, `_pumpInspector`, `_selectedState`, `_duplicateNameState`, `_overview`, test cubit/fake preview adapter | no importers |
| `test/poly_multisample/poly_samples_editor_view_test.dart` | 234 lines | editor integration tests and helpers | no importers |

`PolyWaveformEditor` and `PolySampleList` are not modified by this program. They are inventoried because they are adjacent to the side panel and prove the change stays inside the inspector/layout surface.

## Architecture

Pattern: model/helper extraction plus focused widget rewrites.

Create one reusable helper file for stable side-panel layout constants and value/button presentation:

```text
lib/ui/poly_multisample/widgets/poly_sample_sidebar_layout.dart
```

This file is not a public package API. It is imported only by `poly_sample_inspector.dart` and by tests that need constants for geometry assertions.

### New helper symbols

| Symbol | Kind | Destination | Exported | Purpose |
|---|---|---|---|---|
| `PolySampleSidebarLayout` | class with static constants | `lib/ui/poly_multisample/widgets/poly_sample_sidebar_layout.dart` | yes | Own every hard-coded side-panel width used by row rewrites. |
| `PolySampleSidebarValueText` | stateless widget | same file | yes | Render changing values in fixed-width boxes with tabular figures and full semantics. |
| `PolySampleSidebarIconButton` | stateless widget | same file | yes | Render every jog/stepper button in a fixed square hit target with stable tooltip semantics. |
| `PolySampleSidebarSliderValue` | stateless widget | same file | yes | Render slider trailing values in fixed-width boxes with tabular figures and full semantics. |

No compatibility re-export is needed because the helper file is new and has no existing importers.

### Exact constants

`PolySampleSidebarLayout` must contain these exact constants:

| Constant | Value | Use |
|---|---:|---|
| `panelWidth` | `320.0` | Desktop inspector width in `_EditorBody`. |
| `outerPadding` | `12.0` | `PolySampleInspector` scroll padding. |
| `contentWidth` | `296.0` | `panelWidth - outerPadding * 2`; documentation/test reference only. |
| `rowHeight` | `40.0` | Mapping, frame, gain, peak, fade control rows. |
| `iconButtonExtent` | `40.0` | Every side-panel step/jog button width and height. |
| `mappingLabelWidth` | `92.0` | Mapping row label column. |
| `mappingValueWidth` | `64.0` | Mapping row value column. |
| `frameLabelWidth` | `72.0` | Loop and trim frame row label column. |
| `frameValueWidth` | `64.0` | Loop and trim frame value column. |
| `sliderLabelWidth` | `92.0` | Preview, gain, peak, fade length, fade strength labels. |
| `dbValueWidth` | `64.0` | dB value columns. |
| `msValueWidth` | `64.0` | millisecond value columns. |
| `unitValueWidth` | `56.0` | unitless strength value column. |
| `fadeCurveDropdownWidth` | `140.0` | Fade curve dropdown width. |
| `rowGap` | `4.0` | Gap between stable value columns and controls. |

### Helper API

`PolySampleSidebarValueText` constructor:

```dart
const PolySampleSidebarValueText({
  super.key,
  required this.value,
  required this.width,
  this.semanticLabel,
  this.textAlign = TextAlign.right,
  this.alignment = Alignment.centerRight,
});

final String value;
final double width;
final String? semanticLabel;
final TextAlign textAlign;
final AlignmentGeometry alignment;
```

Build rules:

1. Wrap the visible text in `SizedBox(width: width)`.
2. Align the text using `alignment`.
3. Use `maxLines: 1` and `overflow: TextOverflow.fade`.
4. Apply `FontFeature.tabularFigures()` to the effective text style.
5. Wrap with `Semantics(label: semanticLabel, value: value)` when `semanticLabel` is non-null.
6. Preserve visual text semantics when `semanticLabel` is null.

`PolySampleSidebarSliderValue` constructor:

```dart
const PolySampleSidebarSliderValue({
  super.key,
  required this.value,
  required this.width,
  required this.semanticLabel,
});

final String value;
final double width;
final String semanticLabel;
```

Build rule: delegate to `PolySampleSidebarValueText` with the same `value`, `width`, and `semanticLabel`.

`PolySampleSidebarIconButton` constructor:

```dart
const PolySampleSidebarIconButton({
  super.key,
  required this.tooltip,
  required this.onPressed,
  required this.icon,
});

final String tooltip;
final VoidCallback? onPressed;
final IconData icon;
```

Build rules:

1. Return `SizedBox.square(dimension: PolySampleSidebarLayout.iconButtonExtent)`.
2. Put an `IconButton` inside the square.
3. Set `tooltip` to the provided tooltip.
4. Set `constraints` to a tight 40 by 40 box.
5. Set `padding` to `EdgeInsets.zero`.
6. Set `visualDensity` to `VisualDensity.compact`.
7. Set the icon to `Icon(icon, size: 18)`.
8. Do not wrap the button in `GestureDetector` or any widget that removes normal `IconButton` focus and keyboard behavior.

### Stable row rules

All side-panel rows in `poly_sample_inspector.dart` follow these rules after implementation:

1. Existing row widgets keep stable top-left coordinates when their own value text changes and no rows are inserted or removed.
2. Existing interactive controls keep stable rectangles when their row value text changes.
3. Changing a value never changes a row's `SizedBox(height: PolySampleSidebarLayout.rowHeight)` height.
4. Numeric or note text is never concatenated into the label text for rows with controls. The label and value are separate fixed-width children.
5. Changing a value never changes any `ValueKey` assigned to the row, value text, slider, dropdown, or control.
6. All numeric value text uses tabular figures.
7. Semantics expose the full untruncated label and value even when visual text fades or clips.

### Row inventory and exact treatment

| Current row | Current instability | Required treatment | Required keys |
|---|---|---|---|
| `_MappingSection` `Root` | `Text('Root: $value')` width moves minus/plus buttons when `C3` becomes `C#3` | Use fixed `mappingLabelWidth`, fixed `mappingValueWidth`, spacer, two `PolySampleSidebarIconButton`s | row `poly-sidebar-mapping-root-row`; value `poly-sidebar-mapping-root-value`; buttons `poly-sidebar-mapping-root-decrease`, `poly-sidebar-mapping-root-increase` |
| `_MappingSection` `Low` | Same as root | Same as root | row/value/buttons with suffix `low` |
| `_MappingSection` `High` | Same as root | Same as root | row/value/buttons with suffix `high` |
| `_MappingSection` `Velocity` | Digit count change moves controls, for example `9` to `10` | Same as root | row/value/buttons with suffix `velocity` |
| `_MappingSection` `Round robin` | Digit count change moves controls | Same as root | row/value/buttons with suffix `round-robin` |
| `_FrameNudgeRow` `Loop start` | Expanded `Text('$label: $value')` changes residual width before four buttons | Use fixed `frameLabelWidth`, fixed `frameValueWidth`, spacer, four fixed buttons | row `poly-sidebar-frame-loop-start-row`; value `poly-sidebar-frame-loop-start-value`; buttons suffixes `minus100`, `minus1`, `plus1`, `plus100` |
| `_FrameNudgeRow` `Loop end` | Same as loop start | Same as loop start | row/value/buttons with `loop-end` |
| `_FrameNudgeRow` `Trim start` | Same as loop start | Same as loop start | row/value/buttons with `trim-start` |
| `_FrameNudgeRow` `Trim end` | Same as loop start | Same as loop start | row/value/buttons with `trim-end` |
| `_PreviewControls` preview gain | Trailing dB text can change slider width | Use row height 40, icon fixed 40, slider expanded, trailing fixed `dbValueWidth` | value `poly-sidebar-preview-gain-value`; slider keeps no new required key |
| `_WaveformSection` destructive gain | Trailing dB text has fixed width today but not shared constants or tabular figures | Use `sliderLabelWidth`, fixed `dbValueWidth`, stable value helper; keep existing slider key | value `poly-sidebar-wav-gain-value`; existing slider `poly-wav-gain-slider` |
| `_WaveformSection` normalize peak | Slider lacks trailing fixed value; enabling and value changes have no stable value presentation | Add trailing `dbValueWidth` peak value column and stable semantics | value `poly-sidebar-normalize-peak-value`; slider key `poly-sidebar-normalize-peak-slider` |
| `_FadeRow` length | Slider overlay changes are stable, but no fixed visible value exists | Render a fixed-height label/slider/value row with `msValueWidth` | row `poly-sidebar-fade-in-length-row` / `poly-sidebar-fade-out-length-row`; value suffix `length-value` |
| `_FadeRow` curve | Dropdown label width can change and move adjacent strength slider in the `Wrap` | Replace `Wrap` with separate fixed rows; dropdown wrapped in fixed `fadeCurveDropdownWidth` | dropdown keys `poly-sidebar-fade-in-curve-dropdown`, `poly-sidebar-fade-out-curve-dropdown` |
| `_FadeRow` strength | Strength value text can change in slider overlay; row shares unstable `Wrap` with curve row | Render a fixed-height label/slider/value row with `unitValueWidth` | row/value keys `poly-sidebar-fade-in-strength-row`, `poly-sidebar-fade-in-strength-value`, and fade-out equivalents |
| `SwitchListTile` `Auto-preview`, `Loop enabled`, `Normalize` | Switch geometry does not depend on numeric text | No layout rewrite beyond adjacent stable rows | no new keys required |
| `_HeaderRow` previous/next/preview/reveal controls | Icon buttons already have stable boxes; labels are not numeric row values | No change | no new keys required |
| Save loop / Save as / Overwrite buttons | Enablement does not change label width | No change | no new keys required |

Loop-enabled insertion and waveform-loading insertion are intentionally outside the row-stability guarantee because they add or remove rows. Numeric edits inside already-visible loop, trim, fade, gain, and mapping rows are in scope.

### Exact rewritten widget behavior

`_EditorBody` in `poly_samples_editor_view.dart` must replace `SizedBox(width: 320, child: inspector)` with `SizedBox(width: PolySampleSidebarLayout.panelWidth, child: inspector)` and import the helper file.

`PolySampleInspector` scroll padding must use `EdgeInsets.all(PolySampleSidebarLayout.outerPadding)`.

`_StepRow` remains private in `poly_sample_inspector.dart` and gains a required `rowKeySuffix` string parameter. It builds:

```text
SizedBox(height: rowHeight)
  Semantics(container: true, label: label, value: value)
    Row
      SizedBox(width: mappingLabelWidth, child: Text(label, overflow ellipsis))
      PolySampleSidebarValueText(width: mappingValueWidth, value: value, semanticLabel: '$label value')
      SizedBox(width: rowGap)
      Spacer()
      PolySampleSidebarIconButton(decrease)
      PolySampleSidebarIconButton(increase)
```

`_FrameNudgeRow` remains private and gains a required `rowKeySuffix` string parameter. It builds:

```text
SizedBox(height: rowHeight)
  Semantics(container: true, label: label, value: '$value frames')
    Row
      SizedBox(width: frameLabelWidth, child: Text(label, overflow ellipsis))
      PolySampleSidebarValueText(width: frameValueWidth, value: '$value', semanticLabel: '$label frame value')
      SizedBox(width: rowGap)
      Spacer()
      fixed buttons for -100, -1, +1, +100 in that order
```

Button tooltips stay byte-for-byte equal to current tooltip strings for frame rows. Mapping button tooltips stay byte-for-byte equal to current tooltip strings.

`_FadeRow` remains private. It must not use `Wrap`. It renders, in order:

1. `Text(label)`.
2. Length row: `SizedBox(height: rowHeight)` with slider label column, expanded slider, fixed ms value.
3. Curve row: `SizedBox(height: rowHeight)` with label column text `'$label curve:'`, fixed dropdown width, no strength slider in this row.
4. Strength row: `SizedBox(height: rowHeight)` with label column text `'$label strength'`, expanded slider, fixed unit value.

The fade length slider semantics keep label `'$label length'` and value `'${ms.round()} ms'`. The fade strength slider semantics keep label `'$label strength'` and value `strength.toStringAsFixed(2)`.

### Accessibility requirements

1. Existing section headers remain wrapped with `Semantics(header: true)`.
2. Every fixed value helper exposes the full value to semantics.
3. Mapping rows expose `Semantics(label: label, value: value, container: true)`.
4. Frame rows expose `Semantics(label: label, value: '$value frames', container: true)`.
5. Sliders keep their existing `semanticFormatterCallback` behavior.
6. Tooltip strings for existing buttons remain unchanged so screen reader action labels and tests stay compatible.
7. Visual overflow is handled with fade/ellipsis while semantics retain the complete string.

### Keyboard and focus requirements

1. All stepper and nudge controls remain `IconButton`s.
2. Button order in the widget tree remains the visual order.
3. Stable `ValueKey`s are assigned to every changed button so focusable elements keep identity across rebuilds.
4. Pressing Space or Enter on a focused stepper/nudge button triggers the same callback as a pointer click through normal `IconButton` behavior.
5. A value-changing rebuild must keep the focused button's rectangle unchanged.
6. No `FocusTraversalGroup` is added in this program.

## Decision inventory

| Decision | Rationale | Files affected | Status |
|---|---|---|---|
| Create `poly_sample_sidebar_layout.dart` rather than keeping constants private | Multiple private rows need the same fixed widths and tests need the constants without reaching into a private library | new helper file, inspector, editor view, tests | required |
| Keep `_StepRow`, `_FrameNudgeRow`, and `_FadeRow` private in `poly_sample_inspector.dart` | They are inspector-specific compositions and no other file imports them | inspector only | required |
| Use fixed widths and tabular figures rather than measuring text | Fixed widths make layout deterministic and testable across representative values | helper file and inspector | required |
| Use `panelWidth = 320.0` | This preserves current desktop side-panel width while making the number named and reusable | editor view and helper | required |
| Use 40 by 40 side-panel icon buttons | This matches compact side-panel controls while making hit targets stable | helper file and inspector | required |
| Replace fade `Wrap` with fixed rows | The wrap lets dropdown text width move adjacent controls | inspector and tests | required |
| Add a trailing fixed normalize-peak value | Peak is a numeric sidebar row and needs the same stable presentation as gain | inspector and tests | required |
| Preserve existing tooltips | Existing widget tests and screen-reader labels depend on these strings | inspector and tests | required |
| Do not modify `PolyWaveformEditor` | The unstable rows are in the inspector, not the canvas editor | none | out-of-scope |
| Do not modify `PolySampleList` row steppers | The request targets the sample editor side panel; list rows are outside this side panel | none | out-of-scope |
| Do not reserve space for hidden loop rows when loop is disabled | Enabling loop intentionally reveals additional controls; this is row insertion, not numeric row-width instability | none | out-of-scope |
| Do not add success snackbars | Project rule says avoid success snackbars and no success path is needed | none | out-of-scope |

## Hardening matrix

| Risk | Plausible path | Chosen handling | Tests required |
|---|---|---|---|
| Mapping value text changes width and moves plus/minus under the mouse | User repeatedly clicks Root, Velocity, or Round robin and values cross `C3` to `C#3` or `9` to `10` | Separate fixed label/value columns and fixed button squares | Inspector widget test comparing button and row rectangles before and after representative taps |
| Loop/trim frame values cross digit boundaries and move four jog buttons | User clicks `+1`, `+100`, `-1`, or `-100` while editing loop or trim points | Fixed frame label/value columns plus fixed button squares | Inspector widget test comparing loop and trim button rectangles before and after frame value changes |
| Gain or normalize peak dB text changes width while dragging a slider | User drags gain or peak slider across `9.9 dB` to `10.0 dB` or `-0.3 dB` to `-10.0 dB` | Fixed trailing dB value columns with tabular figures | Inspector widget test comparing slider rectangles before and after cubit state changes |
| Fade curve label changes width and moves strength controls | User changes fade curve from `Linear` to `Equal power` | Fixed-width dropdown row separated from the strength row | Inspector widget test comparing strength slider/value rectangles before and after changing curve |
| Keyboard focus loses identity after value-changing rebuild | Keyboard or assistive-tech user activates a focused stepper repeatedly | Stable `ValueKey`s and unchanged `IconButton` widgets | Inspector widget test activates a focused velocity increment button with Enter and asserts focus and rect stability |
| Screen reader hears clipped numeric text | User uses VoiceOver/TalkBack on a row whose visual value fades due to fixed width | Fixed value helpers provide full `Semantics` label/value | Semantics expectations for mapping value, frame value, gain, peak, fade length, and fade strength |
| Waveform loading inserts the whole waveform section | User selects a local WAV without an overview loaded | Existing async waveform loading behavior inserts content after data arrives | Out of scope for this request; no row exists before loading |
| Loop enabled toggle inserts or removes loop rows | User toggles `Loop enabled` | Existing behavior reveals or hides loop controls | Out of scope for numeric row stability; no test required |
| Hardware or MIDI latency reorders side-panel rows | App receives slow hardware responses | Side-panel row layout is local Flutter state and no MIDI path reorders these rows | No plausible path for this layout bug; no hardening required |
| File-system failures during Save as or Overwrite move rows | User saves edited WAV and the file operation fails | Save failure behavior is unrelated to row numeric width | No plausible path for this layout bug; no hardening required |

## Acceptance criteria

1. `flutter analyze` reports no issues.
2. `flutter test test/poly_multisample/widgets/poly_sample_inspector_test.dart test/poly_multisample/poly_samples_editor_view_test.dart` passes.
3. Program-level verification `flutter analyze && flutter test` passes.
4. Repeated pointer clicks on mapping steppers leave the clicked button rectangle unchanged.
5. Repeated pointer clicks on loop and trim jog controls leave all four jog button rectangles unchanged.
6. Gain, normalize peak, fade length, fade curve, and fade strength value changes leave slider/control rectangles unchanged.
7. Semantics expose full values for fixed-width visual value text.
8. Keyboard activation of a focused stepper updates the value without moving the focused button.
