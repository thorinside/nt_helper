# Range Sliders Missing Semantic Labels

**Severity: Medium**

**Status: Addressed (2026-02-06)** — in commit 664e27b

## Files Affected

- `lib/ui/widgets/packed_mapping_data_editor.dart` (lines 987-1067)
- `lib/ui/widgets/step_sequencer/randomize_settings_dialog.dart` (lines 339-410)

## Description

### Mapping Editor Range Sliders

The `PackedMappingDataEditor._buildRangeSlider()` method creates `RangeSlider` widgets that are used for CV range, MIDI min/max, and I2C min/max. While the `RangeSlider` has `labels` set, it lacks a semantic label describing what the range controls:

```dart
RangeSlider(
  values: RangeValues(displayStart, displayEnd),
  labels: RangeLabels(
    _formatDisplayValue(displayStart),
    _formatDisplayValue(displayEnd),
  ),
  // No semanticFormatterCallback
)
```

The `RangeSlider` is used three times (CV, MIDI, I2C tabs) but there's no way for a screen reader to distinguish between them or know what parameter range is being adjusted.

The Min/Max text labels below the slider (lines 1050-1064) are plain `Text` widgets that provide context but aren't programmatically linked to the slider.

### Step Sequencer Sliders

The `RandomizeSettingsDialog._buildSliderParameter()` and `_buildProbabilitySlider()` methods use `Slider` widgets. These have `label` properties set but no `semanticFormatterCallback`:

```dart
Slider(
  value: value.toDouble(),
  label: showMidiNote ? _midiNoteToString(value) : '$value',
  // No semanticFormatterCallback
)
```

## Impact on Blind Users

- Screen readers will announce slider values numerically without context (e.g., "50 percent" instead of "Note probability: 50 percent")
- Multiple sliders in sequence are indistinguishable
- Range sliders have two thumbs and VoiceOver users may not understand which thumb they are adjusting

## Recommended Fix

Add `semanticFormatterCallback` to sliders:

```dart
RangeSlider(
  values: RangeValues(displayStart, displayEnd),
  semanticFormatterCallback: (value) {
    return _formatDisplayValue(value);
  },
  // ...
)
```

Wrap range sliders in a `Semantics` context:

```dart
Semantics(
  label: 'CV mapping range',
  child: _buildRangeSlider(/* ... */),
)
```

For step sequencer sliders:

```dart
Slider(
  value: value.toDouble(),
  semanticFormatterCallback: (value) {
    return showMidiNote
        ? _midiNoteToString(value.toInt())
        : '${value.toInt()}';
  },
)
```
