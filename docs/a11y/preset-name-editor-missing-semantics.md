# Preset Name Editor Missing Semantics

**Severity:** Critical

**Files affected:**
- `lib/ui/synchronized_screen.dart` (lines 1407-1463, `_buildPresetInfoEditor`)

## Description

The preset name area uses a plain `InkWell` wrapping a `Row` with a `Text.rich` and an edit icon. There is no `Semantics` widget, no semantic label, and no button role annotation. A screen reader user will hear the raw text content ("Preset: MyPreset") but will not know:

1. That this element is tappable/interactive
2. That tapping it opens a rename dialog
3. The purpose of the small edit icon (16px, purely decorative indicator)

## Impact on blind users

A VoiceOver/TalkBack user navigating the app bar will encounter this text but have no indication it is interactive. They will likely skip it entirely, unable to rename their preset. The edit icon is also too small (16x16) and has no semantic label.

## Recommended fix

Wrap the `InkWell` in a `Semantics` widget with appropriate properties:

```dart
Semantics(
  label: 'Preset name: ${widget.presetName.trim()}',
  hint: 'Double-tap to rename preset',
  button: true,
  child: InkWell(
    onTap: () async { ... },
    child: Row( ... ),
  ),
)
```

Also add `ExcludeSemantics` around the edit icon since its purpose is conveyed by the parent semantic label:

```dart
ExcludeSemantics(
  child: Icon(Icons.edit, size: 16, ...),
)
```
