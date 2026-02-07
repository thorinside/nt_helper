# Debug Panel and Log Display Accessibility Issues

**Severity: Low**

## Files Affected

- `lib/ui/widgets/debug_panel.dart` (lines 1-145)
- `lib/ui/common/log_display_page.dart` (lines 1-67)

## Description

While these are debug/developer tools, they do have accessibility issues worth noting since they appear in the shipping app:

### Debug Panel

1. **Stream-driven updates not announced**: The debug panel auto-scrolls when new messages arrive (lines 23-32) but new messages are not announced to screen readers.

2. **Bug report icon in header not labeled**: The `Icon(Icons.bug_report, size: 16)` at line 58 has no label.

3. **Copy confirmation**: The "Debug log copied to clipboard" snackbar (line 71-75) is a good accessibility practice.

### Log Display Page

4. **Reverse list order may confuse screen readers**: The ListView uses `reverse: true` (line 53) to show newest entries first. This reverses the swipe direction for VoiceOver, which can be disorienting.

5. **SelectableText for log entries**: Using `SelectableText` (line 59) is good for clipboard access but may create focus traps where VoiceOver gets stuck on individual log entries.

6. **Play/pause state not announced on toggle**: When toggling recording on/off, the icon changes but there's no `SemanticsService.announce()` to confirm the state change. The tooltip updates correctly.

## Impact on Blind Users

- Minor: These are developer tools not typically used by end users
- Reverse list ordering can confuse screen reader navigation
- Log entries may create unnecessary focus stops

## Recommended Fix

1. Hide decorative icons:

```dart
ExcludeSemantics(
  child: Icon(Icons.bug_report, size: 16),
),
```

2. Announce recording state changes:

```dart
onPressed: () {
  if (logger.isRecording) {
    logger.stopRecording();
    SemanticsService.announce('Logging paused', TextDirection.ltr);
  } else {
    logger.startRecording();
    SemanticsService.announce('Logging resumed', TextDirection.ltr);
  }
},
```
