# BPM Editor Increment/Decrement Buttons Lack Context

**Severity: Medium**

**Status: Addressed (2026-02-06)** — in commit 664e27b

## Files Affected
- `lib/ui/bpm_editor_widget.dart` (lines 250-326)

## Description

The BPM editor uses two `IconButton` widgets for increment/decrement:
- Decrement: `Icons.remove_circle_outline` (line 259)
- Increment: `Icons.add_circle_outline` (line 319)

These buttons have no explicit semantic labels. The screen reader will announce them as their icon descriptions ("remove circle outline", "add circle outline"), which provides some context but is not ideal.

More critically:
- The long-press acceleration behavior (lines 254-257, 314-317) is wrapped in `GestureDetector` around the `IconButton`, which may conflict with VoiceOver's gesture handling
- The `TextField` for direct BPM entry (line 270) lacks a semantic label - it shows a number but doesn't indicate what it is
- The "BPM" label is a separate `Positioned` widget (line 299-309) that is only shown on widescreen and is not semantically associated with the text field

## Impact on Blind Users

- Buttons are usable but lack clear purpose ("remove circle outline" vs "Decrease BPM")
- Long-press acceleration is unusable via VoiceOver/TalkBack
- The text field is editable but doesn't announce that it's a BPM value
- On mobile, "BPM" label is hidden, so there's no context at all

## Recommended Fix

```dart
Semantics(
  label: 'Decrease BPM',
  button: true,
  child: IconButton(
    icon: const Icon(Icons.remove_circle_outline),
    onPressed: () => _handleIconButtonTap(false),
  ),
)

// TextField
TextField(
  controller: _textController,
  decoration: InputDecoration(
    labelText: 'BPM', // Always show label, not just on widescreen
    ...
  ),
)

Semantics(
  label: 'Increase BPM',
  button: true,
  child: IconButton(
    icon: const Icon(Icons.add_circle_outline),
    onPressed: () => _handleIconButtonTap(true),
  ),
)
```
