# Firmware Flow Diagram CustomPainter Has No Semantic Description

**Severity: Medium**

**Status: Addressed (2026-02-06)** — in commit 664e27b

## Files Affected

- `lib/ui/firmware/firmware_flow_diagram.dart` (entire file, especially lines 38-69 build, 72-318 painter)

## Description

The `FirmwareFlowDiagram` widget displays an animated diagram showing firmware update progress: `Computer -> Connection Line -> Disting NT`. It is rendered entirely via `CustomPainter` (`_FlowDiagramPainter`) which draws:

- A computer icon (monitor + stand)
- A connection line (solid or dashed depending on stage)
- A Disting NT module icon (Eurorack module shape)
- Animated status indicators (flow dots, pulsing dot, checkmark, error X)

The widget correctly respects `MediaQuery.disableAnimations` (line 40-53), which is good. However, it has **no `Semantics` wrapper** at all. The visual diagram communicating firmware update progress is invisible to screen readers.

## Impact on Blind Users

During a firmware update (a critical and potentially anxiety-inducing operation), a blind user cannot see:
- The connection status between computer and module
- Whether data is actively transferring
- Whether an error occurred in the transfer
- Whether the update completed successfully

The firmware progress is likely communicated through other UI elements (progress bars, text), so this may be partially mitigated. However, the visual diagram provides unique at-a-glance status that should be available to all users.

## Recommended Fix

### 1. Add semantic description matching visual state

```dart
@override
Widget build(BuildContext context) {
  final stageDescription = _getStageDescription();

  return Semantics(
    label: 'Firmware update diagram: $stageDescription',
    liveRegion: true,  // Announce changes automatically
    child: // existing CustomPaint or AnimatedBuilder
  );
}

String _getStageDescription() {
  if (widget.progress.isError) {
    return 'Error during firmware update';
  }

  switch (widget.progress.stage) {
    case FlashStage.sdpConnect:
      return 'Connecting to Disting NT';
    case FlashStage.blCheck:
      return 'Checking bootloader';
    case FlashStage.sdpUpload:
      return 'Uploading firmware to device';
    case FlashStage.write:
      return 'Writing firmware to flash memory';
    case FlashStage.configure:
      return 'Configuring device';
    case FlashStage.reset:
      return 'Resetting device';
    case FlashStage.complete:
      return 'Firmware update complete';
  }
}
```

### 2. Use liveRegion for automatic announcements

The `liveRegion: true` property will cause VoiceOver/TalkBack to automatically announce when the label changes, keeping the user informed of progress transitions.

### 3. Implement SemanticsBuilderCallback

```dart
@override
SemanticsBuilderCallback get semanticsBuilder {
  return (Size size) {
    return [
      CustomPainterSemantics(
        rect: Offset.zero & size,
        properties: SemanticsProperties(
          label: _getStageDescription(),
          textDirection: TextDirection.ltr,
        ),
      ),
    ];
  };
}
```
