# Overflow Menu Items: Icons Create Duplicate Screen Reader Content

**Severity:** Medium

**Files affected:**
- `lib/ui/synchronized_screen.dart` (lines 1036-1404, `_buildOverflowMenu`)

## Description

The `PopupMenuButton` overflow menu contains items structured as `Row` widgets with `Text` and `Icon`:

```dart
child: const Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [Text('Wake Display'), Icon(Icons.alarm_on_rounded)],
),
```

Each `Icon` will be read by the screen reader as a separate element, creating duplicate announcements like "Wake Display, alarm on".

## Impact on blind users

Screen reader users will hear each menu item twice - once as the text label and once as the icon's implicit semantic label. This is noisy and confusing.

## Recommended fix

Wrap each trailing icon in `ExcludeSemantics`:
```dart
children: [
  Text('Wake Display'),
  ExcludeSemantics(child: Icon(Icons.alarm_on_rounded)),
],
```
