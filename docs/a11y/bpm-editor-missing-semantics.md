# BPM Editor Widget Missing Semantics and Accessibility

**Severity:** High

**Files affected:**
- `lib/ui/bpm_editor_widget.dart` (entire file, especially lines 250-327)

## Description

The `BpmEditorWidget` is a numeric stepper with minus/plus buttons and a text field. Multiple accessibility issues:

1. **No semantic labels on stepper buttons**: The `IconButton` widgets (lines 258-263, 319-324) use `Icons.remove_circle_outline` and `Icons.add_circle_outline` but have no `tooltip` property. Screen readers will announce generic icon descriptions.

2. **Long press acceleration is inaccessible**: The `GestureDetector` wrapping each `IconButton` (lines 254-263, 314-324) adds `onLongPressStart` for accelerated value changes. This pattern is not accessible via screen readers.

3. **No Semantics wrapper for the overall widget**: The entire BPM editor lacks a `Semantics` widget that would describe it as a "BPM value editor" with current value, min, max.

4. **Text field lacks accessibility label**: The `TextField` (lines 270-296) has no `labelText` or `Semantics` label. Screen readers won't know this is a BPM input.

5. **"BPM" suffix text** (lines 299-309) is positioned absolutely and may not be read by screen readers in the correct order.

## Impact on blind users

Blind users will encounter a confusing collection of unlabeled elements - a minus button (announced as just the icon), an unlabeled text field, and a plus button. They won't know what value they're editing, what the current value means, the valid range, or that long-press accelerates changes.

## Recommended fix

1. Add tooltips to the increment/decrement buttons:
```dart
IconButton(
  icon: const Icon(Icons.remove_circle_outline),
  tooltip: 'Decrease BPM',
  onPressed: () => _handleIconButtonTap(false),
)
```

2. Wrap the entire widget in Semantics with onIncrease/onDecrease callbacks.

3. Add `labelText: 'BPM'` to the TextField's InputDecoration.
