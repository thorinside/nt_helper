# Epic 8: Android Video Implementation - Technical Context

**Generated:** 2025-11-15
**Epic:** 8 (Android Video Implementation)
**Status:** In Progress
**Story Count:** 2 stories (E8.1 through E8.2)

---

## Epic Overview

**Goal:** Enable real camera video streaming on Android by completing the uvccamera fork's EventChannel implementation and integrating it with nt_helper's existing video architecture.

**Value:** Android is the only platform that doesn't work for video display. iOS and macOS use a unified BMP → EventChannel → VideoFrameCubit architecture that works perfectly. Android needs the same unified approach to achieve feature parity.

**Key Design Principles:**
1. **Unified Architecture** - Match iOS/macOS pattern: Camera → BMP encoding → EventChannel → VideoFrameCubit
2. **Clean Fork Integration** - Minimal changes following existing uvccamera EventChannel patterns
3. **No Texture Approach** - Remove incomplete texture-based implementation, use proven EventChannel pattern
4. **Maintainable Code** - Follow uvccamera's existing patterns (UvcCameraErrorEventStreamHandler, etc.)

---

## Current State Analysis

### Already Completed Work

**macOS Video Fix** (Committed: 6e84c66)
- Added debug channel matching iOS
- Fixed threading (dispatch to main thread)
- Changed PNG → BMP encoding
- Status: ✅ Working perfectly

**Android Infrastructure** (Committed: dfaec44)
- Added debug channel to `UsbVideoCapturePlugin.kt`
- Implemented `VideoFrameCallback` class with IFrameCallback interface
- Added NV21 to Bitmap conversion helpers
- Updated method handlers to accept cameraId parameter
- Added frame capture methods (startRealCameraFrameCapture, stopRealCameraFrameCapture)
- Integrated with existing BMP encoding
- Status: ✅ Complete, waiting for fork EventChannel

**Dart Integration** (Committed: dfaec44)
- Updated `AndroidUsbVideoChannel` to pass cameraId to native plugin
- Modified `_startFrameCapture` to subscribe to frame EventChannel
- Updated `_stopCurrentStream` to clean up native resources
- Status: ✅ Complete

**UI Simplification** (Committed: dfaec44)
- Removed all Android-specific texture approach from `FloatingVideoOverlay`
- Unified architecture across all platforms using VideoFrameCubit
- Removed unused imports (dart:io, uvccamera)
- Status: ✅ Complete

**Fork Creation** (Committed: feature/frame-streaming-api)
- Forked DigifinityLtd/UVCCamera → thorinside/UVCCamera
- Branch: `feature/frame-streaming-api`
- Added `startFrameStreaming()` and `stopFrameStreaming()` to `UvcCameraPlatform.java`
- Status: ✅ Foundation complete, needs EventChannel implementation

**pubspec.yaml Update** (Committed: dfaec44)
- Points to fork: `https://github.com/thorinside/UVCCamera`
- Ref: `feature/frame-streaming-api`
- Status: ✅ Complete

### Current Blocker

The uvccamera fork has `startFrameStreaming(cameraId, IFrameCallback, pixelFormat)` in `UvcCameraPlatform.java`, but these methods are not exposed via Flutter channels. The fork needs:

1. EventChannel for frame data delivery
2. MethodChannel handlers for startFrameStreaming/stopFrameStreaming
3. EventStreamHandler implementation following existing patterns

### Existing uvccamera Architecture

The fork already has established patterns for EventChannels:

**UvcCameraPlugin.java** - Main plugin class
- Handles Flutter engine attachment/detachment
- Creates channels: `uvccamera/native` (MethodChannel), `uvccamera/device_events` (EventChannel)
- Instantiates `UvcCameraPlatform` and `UvcCameraNativeMethodCallHandler`

**UvcCameraNativeMethodCallHandler.java** - Method routing
- Routes Flutter method calls to `UvcCameraPlatform`
- Existing methods: `isSupported`, `getDevices`, `requestDevicePermission`, `openCamera`, etc.
- Pattern: Switch statement with proper error handling

**Existing EventStreamHandlers:**
- `UvcCameraDeviceEventStreamHandler` - Device attach/detach events
- `UvcCameraErrorEventStreamHandler` - Camera error events
- `UvcCameraStatusEventStreamHandler` - Camera status events
- `UvcCameraButtonEventStreamHandler` - Camera button events

**Pattern to Follow:**
```java
// 1. Create EventStreamHandler implementation
// 2. Add EventChannel in UvcCameraPlugin.onAttachedToEngine
// 3. Pass handler to UvcCameraPlatform constructor
// 4. Set stream handler on EventChannel
// 5. Add MethodChannel cases in UvcCameraNativeMethodCallHandler
```

---

## Android Video Architecture

### Complete Flow

```
UvcCamera Hardware
    ↓
IFrameCallback.onFrame(ByteBuffer) [NV21 format]
    ↓
UvcCameraFrameEventStreamHandler.sendFrame()
    ↓
EventChannel: uvccamera/frames
    ↓
nt_helper UsbVideoCapturePlugin.kt
    ↓
NV21 → Bitmap conversion (YuvImage + JPEG compression)
    ↓
Bitmap → BMP encoding (24-bit RGB, BGR pixel order)
    ↓
EventChannel: com.example.nt_helper/usb_video_stream
    ↓
AndroidUsbVideoChannel._frameSubscription
    ↓
StreamController<Uint8List>
    ↓
VideoFrameCubit (same as iOS/macOS)
    ↓
FloatingVideoOverlay (unified for all platforms)
    ↓
Image.memory(bmpData) display
```

### Key Technical Details

**Frame Format Conversions:**
1. UVCCamera → NV21 (YUV format, native camera output)
2. NV21 → Bitmap (Android's YuvImage.compressToJpeg + BitmapFactory.decodeByteArray)
3. Bitmap → BMP (24-bit RGB with BGR pixel order, row padding, negative height for top-down)

**Threading:**
- IFrameCallback.onFrame() called on camera thread
- EventChannel messages must be sent on main thread
- Handler(Looper.getMainLooper()).post() for thread dispatch

**Frame Rate Control:**
- Target: 15 FPS
- Throttling in VideoFrameCallback via elapsed time check
- FRAME_INTERVAL_MS = 67ms (1000 / 15)

**Memory Management:**
- Bitmap.recycle() after BMP encoding
- ByteBuffer reuse in IFrameCallback
- Stream cleanup on dispose

---

## File Locations

### nt_helper Repository (feature/android-video-implementation branch)

**Modified Files:**
- `android/app/src/main/kotlin/com/example/nt_helper/UsbVideoCapturePlugin.kt`
  - Lines 67-121: VideoFrameCallback class
  - Lines 190-227: Updated method handlers
  - Lines 408-462: Frame capture methods
- `lib/services/platform_channels/android_usb_video_channel.dart`
  - Lines 203-271: Updated _startFrameCapture
  - Lines 408-448: Updated _stopCurrentStream
- `lib/ui/widgets/floating_video_overlay.dart`
  - Removed all Android-specific routing
  - Unified VideoFrameCubit usage

**Documentation:**
- `docs/android-video-implementation-story.md` - Original implementation notes
- `docs/uvccamera-fork-frame-streaming-story.md` - Fork implementation guide
- `docs/android-video-direct-integration-story.md` - Architecture analysis

### uvccamera Fork (/tmp/UVCCamera - feature/frame-streaming-api branch)

**Completed:**
- `flutter/android/src/main/java/org/uvccamera/flutter/UvcCameraPlatform.java`
  - Lines 986-1025: startFrameStreaming() and stopFrameStreaming() methods

**Pending:**
- `flutter/android/src/main/java/org/uvccamera/flutter/UvcCameraFrameEventStreamHandler.java` - NEW FILE
- `flutter/android/src/main/java/org/uvccamera/flutter/UvcCameraPlugin.java` - Add frameEventChannel
- `flutter/android/src/main/java/org/uvccamera/flutter/UvcCameraNativeMethodCallHandler.java` - Add method handlers

---

## Dependencies

**nt_helper pubspec.yaml:**
```yaml
uvccamera:
  git:
    url: https://github.com/thorinside/UVCCamera
    ref: feature/frame-streaming-api
    path: flutter
```

**uvccamera Fork:**
- Base: DigifinityLtd/UVCCamera
- Branch: feature/16kb-page-size-compliance (base branch)
- Our branch: feature/frame-streaming-api (created from base)

---

## Testing Strategy

### Manual Testing Steps

1. **Fork Changes:**
   - Build modified fork
   - Verify EventChannel registration
   - Test method call routing with logs

2. **Integration Testing:**
   - Update nt_helper to latest fork commit
   - Run `flutter pub get`
   - Build for Android
   - Deploy to physical Android device with USB OTG support
   - Connect Disting NT via USB
   - Open floating video overlay
   - Verify frames display correctly

3. **Validation Checklist:**
   - [ ] Frame rate stable at ~15 FPS
   - [ ] No "Invalid BMP header" errors
   - [ ] Memory usage stable (no leaks)
   - [ ] Video quality acceptable
   - [ ] Camera reconnection works
   - [ ] App backgrounding/foregrounding handled
   - [ ] Matches iOS/macOS video quality

### Debug Verification

**Expected Log Flow:**
```
[NATIVE] Starting real camera frame capture for cameraId: 0
[NATIVE] Real camera streaming started successfully
[uvccamera] startFrameStreaming: cameraId=0, pixelFormat=5
[uvccamera] Frame streaming started
[NATIVE] Real camera frame #15 (49224 bytes)
[AndroidUsbVideoChannel] Frame stream data received (49224 bytes)
[VideoFrameCubit] Frame data updated
```

---

## Success Criteria

**Definition of Done:**
- ✅ Fork EventChannel implementation complete and tested
- ✅ MethodChannel handlers added to uvccamera
- ✅ nt_helper integration updated
- ✅ Video displays on Android matching iOS/macOS quality
- ✅ Frame rate acceptable (10-15 FPS sustained)
- ✅ No memory leaks or crashes
- ✅ `flutter analyze` passes
- ✅ Debug logs show proper frame flow

**Deployment:**
- Fork committed and pushed to origin/feature/frame-streaming-api
- nt_helper changes on feature/android-video-implementation branch
- Testing completed on real Android hardware
- Optional: Submit upstream PR to DigifinityLtd/UVCCamera

---

## Risk Mitigation

**Risk: Fork Maintenance Burden**
- Mitigation: Keep changes minimal (~90 lines), follow existing patterns
- Consider: Submit upstream PR to reduce fork maintenance

**Risk: Frame Format Conversion Issues**
- Mitigation: Use Android's YuvImage class (tested and proven)
- Validation: Compare frame checksums with iOS/macOS

**Risk: Performance Problems**
- Mitigation: Frame throttling, memory monitoring, profiling
- Fallback: Reduce target FPS if needed

**Risk: Plugin Communication Complexity**
- Mitigation: Well-defined EventChannel API, error handling
- Testing: Comprehensive integration tests

---

## References

- [Source: docs/android-video-implementation-story.md] - Original implementation notes
- [Source: docs/uvccamera-fork-frame-streaming-story.md] - Detailed implementation guide
- [Source: macos/Runner/UsbVideoCapturePlugin.swift] - Reference BMP encoding
- [Source: android/app/src/main/kotlin/com/example/nt_helper/UsbVideoCapturePlugin.kt] - Current Android implementation
- [GitHub: thorinside/UVCCamera fork](https://github.com/thorinside/UVCCamera)
