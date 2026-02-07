# MIDI Detector Status Messages Not Announced to Screen Readers

**Severity: High**

## Files Affected

- `lib/ui/midi_listener/midi_detector_widget.dart` (lines 276-293, 307-317)

## Description

The `MidiDetectorWidget` displays detected MIDI events as transient status messages using an `AnimatedSwitcher` with a fade transition. These messages appear briefly (3 seconds) and then disappear. Examples include:

- "No device connected."
- "Connected to [device name]."
- "Detected CC 74 on channel 1"
- "14-bit CC 32 Ch 1"

The status text is displayed as a plain `Text` widget with no `Semantics(liveRegion: true)` wrapper. The `AnimatedSwitcher` fades the text in/out visually, but this visual change is not communicated to screen readers.

## Impact on Blind Users

- When a MIDI CC/Note is detected, blind users receive no audio/haptic feedback
- The most critical function of this widget (confirming MIDI learn detection) is completely silent for screen reader users
- Connection/disconnection status changes are not announced
- Users cannot verify that their MIDI controller is being detected
- The auto-fading behavior means even if a screen reader could read the text, it may disappear before focus reaches it

## Recommended Fix

1. Wrap the status text in a `Semantics(liveRegion: true)` to auto-announce changes:

```dart
Widget _buildAnimatedStatus(ThemeData theme) {
  return Semantics(
    liveRegion: true,
    child: AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      transitionBuilder: (child, animation) {
        return FadeTransition(opacity: animation, child: child);
      },
      child: SizedBox(
        height: 24,
        child: _statusMessage != null
            ? Text(
                _statusMessage!,
                key: ValueKey(_statusMessage),
                style: theme.textTheme.bodyMedium,
              )
            : const SizedBox.shrink(),
      ),
    ),
  );
}
```

2. Additionally, use `SemanticsService.announce()` for critical detection events:

```dart
void _showStatusMessage(String newMessage) {
  setState(() {
    _statusMessage = newMessage;
  });
  // Announce to screen readers immediately
  SemanticsService.announce(newMessage, TextDirection.ltr);
  _fadeTimer?.cancel();
  _fadeTimer = Timer(const Duration(seconds: 3), () {
    setState(() {
      _statusMessage = null;
    });
  });
}
```
