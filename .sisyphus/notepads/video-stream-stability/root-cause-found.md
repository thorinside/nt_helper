# Root Cause Found - UI Rendering Issue

## The Bug

**Location**: `lib/ui/widgets/floating_video_overlay.dart` lines 179-218

**Problem**: Race condition between frame arrival and UI update.

### The Flow
1. Frame arrives → VideoFrameCubit emits state with `frameData`
2. BlocBuilder rebuilds with new state
3. Line 184: `onFrameUpdate(frameData)` is called
4. Line 189: Check `if (displayFrame != null)`
5. **BUG**: On first frame, `displayFrame` is still `null`!
6. Falls through to lines 208-217: Shows "Waiting for video frames..."

### Why displayFrame is Null
The `onFrameUpdate` callback (lines 138-148) uses `addPostFrameCallback`:
```dart
onFrameUpdate: (frameData) {
  _lastFrame = frameData;
  if (_displayFrame == null || frameData != _displayFrame) {
    _displayFrame = frameData;
    // Schedule update for next frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  }
},
```

The `setState` happens AFTER the current build, so:
- Build 1: frameData arrives, displayFrame=null, shows "Waiting..."
- PostFrameCallback: Sets displayFrame, calls setState
- Build 2: Should show video

But if frames keep arriving rapidly, the callback might not execute before the next frame, keeping displayFrame null.

### The Fix
Change line 189 to check `frameData` instead of `displayFrame`:
```dart
if (frameData != null && frameData.isNotEmpty) {
  return GestureDetector(
    onLongPress: onCopyToClipboard,
    child: SizedBox.expand(
      child: RepaintBoundary(
        child: Image.memory(
          frameData,  // Use frameData directly, not displayFrame
          ...
        ),
      ),
    ),
  );
}
```

This way, the frame displays immediately when it arrives, without waiting for the callback.
