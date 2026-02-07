# Randomize Settings Dialog Accessibility Issues

**Severity: Medium**

## Files Affected

- `lib/ui/widgets/step_sequencer/randomize_settings_dialog.dart` (lines 1-428)

## Description

The `RandomizeSettingsDialog` presents 17+ parameters for configuring step sequencer randomization. Several accessibility issues:

### 1. DropdownButton Missing Labels (lines 193-220, 223-251)

The `_buildRandomiseWhatDropdown` and `_buildNoteDistributionDropdown` methods use `DropdownButton` widgets inside `ListTile.subtitle`. The `ListTile.title` provides a visual label ("Randomise what", "Note distribution") but the `DropdownButton` itself has no `hint` or semantic label connecting it to its title.

### 2. Close Button Inconsistency (lines 99-101)

On mobile, the dialog shows `Dialog.fullscreen` with an `AppBar` close button (`Icons.close`). On desktop, it shows a plain `Dialog` with no close button — users must click outside or press Escape. Desktop screen reader users may not know how to dismiss this dialog.

### 3. Section Headers Not Semantic (lines 163-174)

Section headers ("Trigger", "What to Randomize", "Note Distribution", etc.) are styled `Text` widgets. They are not `Semantics(header: true)` which would let screen readers announce them as headers and support header-level navigation.

### 4. SwitchListTile is Good (line 183-190)

The trigger parameter correctly uses `SwitchListTile` with title and subtitle. This is the correct pattern and is well-supported by screen readers.

### 5. Slider Labels Visual-Only (lines 339-373)

The `_buildSliderParameter` method shows the current value text below the slider. While the `Slider.label` is set, this label is typically shown as a tooltip on drag, not announced by screen readers. The `semanticFormatterCallback` is missing.

### 6. Probability Percentage Conversion (lines 376-410)

Probability sliders convert firmware values (0-127) to percentages (0-100%) for display. The `Slider.label` shows "$percentage%" but `semanticFormatterCallback` is not set, so screen readers may announce the raw double value instead.

## Impact on Blind Users

- Dropdown menus may not be clearly labeled
- Desktop users have no obvious dismiss mechanism
- Section headers can't be navigated by heading level
- Slider values are not clearly announced in user-friendly format

## Recommended Fix

1. Mark section headers as semantic headers:

```dart
Widget _buildSectionHeader(String title) {
  return Semantics(
    header: true,
    child: Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title, style: /* ... */),
    ),
  );
}
```

2. Add `semanticFormatterCallback` to sliders:

```dart
Slider(
  value: percentage.toDouble(),
  semanticFormatterCallback: (value) => '${value.round()}%',
  // ...
)
```

3. Add close button for desktop mode:

```dart
Dialog(
  child: ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
    child: Scaffold(
      appBar: AppBar(
        title: const Text('Randomize Settings'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: 'Close',
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      // ...
    ),
  ),
)
```
