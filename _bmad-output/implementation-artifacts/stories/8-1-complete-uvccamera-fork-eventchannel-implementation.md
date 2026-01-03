# Story 8.1: Complete uvccamera fork EventChannel implementation

Status: drafted

## Story

As a developer maintaining the uvccamera fork,
I want to add EventChannel and MethodChannel handlers for continuous frame streaming,
So that nt_helper can subscribe to frame data following the fork's established EventChannel patterns.

## Acceptance Criteria

1. Create `UvcCameraFrameEventStreamHandler.java` following the pattern of existing handlers (UvcCameraErrorEventStreamHandler, etc.)
2. EventStreamHandler implements proper onListen/onCancel lifecycle
3. sendFrame() method dispatches frame data to main thread before calling eventSink.success()
4. Add frameEventChannel to `UvcCameraPlugin.java` in onAttachedToEngine()
5. Pass frameEventStreamHandler to UvcCameraPlatform constructor
6. Set frameEventChannel stream handler in onAttachedToEngine()
7. Clean up frameEventChannel in onDetachedFromEngine()
8. Update UvcCameraPlatform constructor to accept frameEventStreamHandler parameter
9. Store frameEventStreamHandler as private field in UvcCameraPlatform
10. Update startFrameStreaming() to create IFrameCallback that calls frameEventStreamHandler.sendFrame()
11. Add "startFrameStreaming" case to UvcCameraNativeMethodCallHandler switch statement
12. Add "stopFrameStreaming" case to UvcCameraNativeMethodCallHandler switch statement
13. Method handlers extract cameraId and pixelFormat from call arguments
14. Method handlers call UvcCameraPlatform.startFrameStreaming(cameraId, pixelFormat)
15. Proper error handling with try/catch and result.error() calls
16. Fork builds successfully with `./gradlew build` (or equivalent)
17. EventChannel registered as "uvccamera/frames"
18. Method handlers follow exact same pattern as existing handlers (openCamera, closeCamera, etc.)

## Tasks / Subtasks

- [ ] Create UvcCameraFrameEventStreamHandler (AC: 1-3)
  - [ ] Create new file: `flutter/android/src/main/java/org/uvccamera/flutter/UvcCameraFrameEventStreamHandler.java`
  - [ ] Implement EventChannel.StreamHandler interface
  - [ ] Add onListen() method storing EventSink
  - [ ] Add onCancel() method clearing EventSink
  - [ ] Add sendFrame(ByteBuffer) method with main thread dispatch
  - [ ] Add proper logging with TAG constant

- [ ] Update UvcCameraPlugin.java (AC: 4-7)
  - [ ] Add frameEventChannel field declaration
  - [ ] Create EventChannel in onAttachedToEngine with "uvccamera/frames" name
  - [ ] Instantiate UvcCameraFrameEventStreamHandler
  - [ ] Pass handler to UvcCameraPlatform constructor
  - [ ] Call setStreamHandler on frameEventChannel
  - [ ] Add cleanup in onDetachedFromEngine

- [ ] Update UvcCameraPlatform.java (AC: 8-10)
  - [ ] Add frameEventStreamHandler parameter to constructor
  - [ ] Store as private final field
  - [ ] Update startFrameStreaming to create IFrameCallback
  - [ ] IFrameCallback.onFrame calls frameEventStreamHandler.sendFrame()
  - [ ] Pass IFrameCallback to camera.setFrameCallback()

- [ ] Update UvcCameraNativeMethodCallHandler.java (AC: 11-15)
  - [ ] Add "startFrameStreaming" case after existing cases
  - [ ] Extract cameraId and pixelFormat from call.argument()
  - [ ] Validate arguments are not null
  - [ ] Call uvcCameraPlatform.startFrameStreaming()
  - [ ] Wrap in try/catch with result.error() on exceptions
  - [ ] Add "stopFrameStreaming" case
  - [ ] Extract cameraId, validate, call stopFrameStreaming()

- [ ] Build and verify (AC: 16-18)
  - [ ] Run build to verify compilation
  - [ ] Check EventChannel name is "uvccamera/frames"
  - [ ] Verify pattern matches existing handlers
  - [ ] Add commit message following fork's convention

## Dev Notes

### Architecture Context

This story completes the uvccamera fork's frame streaming API by adding the EventChannel layer. The fork already has:

- `UvcCameraPlatform.startFrameStreaming(cameraId, IFrameCallback, pixelFormat)` - implemented
- `UvcCameraPlatform.stopFrameStreaming(cameraId)` - implemented
- Existing EventChannel patterns to follow:
  - UvcCameraDeviceEventStreamHandler (device events)
  - UvcCameraErrorEventStreamHandler (camera errors)
  - UvcCameraStatusEventStreamHandler (camera status)
  - UvcCameraButtonEventStreamHandler (button events)

### Code Pattern to Follow

**EventStreamHandler Pattern:**
```java
public class UvcCameraFrameEventStreamHandler implements EventChannel.StreamHandler {
    private EventChannel.EventSink eventSink;
    private final Handler mainHandler = new Handler(Looper.getMainLooper());

    @Override
    public void onListen(Object arguments, EventChannel.EventSink events) {
        this.eventSink = events;
    }

    @Override
    public void onCancel(Object arguments) {
        this.eventSink = null;
    }

    public void sendFrame(@NonNull ByteBuffer frame) {
        // Convert ByteBuffer to byte array
        // Post to main thread
        // Call eventSink.success(frameData)
    }
}
```

**MethodChannel Handler Pattern:**
```java
case "startFrameStreaming" -> {
    final Integer cameraId = call.argument("cameraId");
    final Integer pixelFormat = call.argument("pixelFormat");

    if (cameraId == null) {
        result.error("INVALID_ARGUMENT", "cameraId is required", null);
        return;
    }

    try {
        uvcCameraPlatform.startFrameStreaming(cameraId, pixelFormat);
        result.success(true);
    } catch (final Exception e) {
        result.error(e.getClass().getSimpleName(), e.getMessage(), null);
    }
}
```

### Project Structure Notes

**Fork Location:** `/tmp/UVCCamera` (local clone)
**Branch:** `feature/frame-streaming-api`
**Base Branch:** `feature/16kb-page-size-compliance`

**Files to Modify:**
- `flutter/android/src/main/java/org/uvccamera/flutter/UvcCameraFrameEventStreamHandler.java` (NEW)
- `flutter/android/src/main/java/org/uvccamera/flutter/UvcCameraPlugin.java`
- `flutter/android/src/main/java/org/uvccamera/flutter/UvcCameraPlatform.java`
- `flutter/android/src/main/java/org/uvccamera/flutter/UvcCameraNativeMethodCallHandler.java`

**Alignment with Fork Standards:**
- Follow existing naming conventions
- Match logging patterns (TAG + Log.v for verbose, Log.e for errors)
- Use same error handling patterns
- Follow existing code formatting style

### References

- [Source: docs/epic-8-android-video-implementation-context.md#Existing uvccamera Architecture]
- [Source: docs/uvccamera-fork-frame-streaming-story.md#Implementation Steps]
- [Fork: flutter/android/src/main/java/org/uvccamera/flutter/UvcCameraErrorEventStreamHandler.java] - Reference pattern
- [Fork: flutter/android/src/main/java/org/uvccamera/flutter/UvcCameraPlugin.java] - EventChannel registration
- [Fork: flutter/android/src/main/java/org/uvccamera/flutter/UvcCameraNativeMethodCallHandler.java] - Method handler patterns

## Dev Agent Record

### Context Reference

<!-- Path(s) to story context XML will be added here by context workflow -->

### Agent Model Used

<!-- Model name and version will be filled in during implementation -->

### Debug Log References

<!-- Debug information will be added during implementation -->

### Completion Notes List

<!-- Completion notes will be added when story is done -->

### File List

<!-- Modified files will be listed when story is complete -->
