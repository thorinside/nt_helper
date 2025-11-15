# Story 8.2: Integrate fork frame streaming with nt_helper and test on Android device

Status: drafted

## Story

As a user running nt_helper on Android,
I want video to display in the floating overlay just like iOS/macOS,
So that I have feature parity across all platforms.

## Acceptance Criteria

1. Update nt_helper's pubspec.yaml to point to latest fork commit with EventChannel implementation
2. Run `flutter pub get` to pull updated fork
3. Update `UsbVideoCapturePlugin.kt` to subscribe to fork's "uvccamera/frames" EventChannel
4. Remove VideoFrameCallback class (no longer needed - handled by fork)
5. Update startRealCameraFrameCapture to call fork's startFrameStreaming via MethodChannel
6. Subscribe to "uvccamera/frames" EventChannel in startRealCameraFrameCapture
7. Convert NV21 frames to Bitmap using YuvImage helper
8. Encode Bitmap to BMP using existing encodeBMP() method
9. Send BMP data via nt_helper's EventChannel to Dart layer
10. Update stopRealCameraFrameCapture to call fork's stopFrameStreaming
11. `flutter analyze` passes with zero warnings
12. Build APK succeeds: `flutter build apk`
13. Deploy to Android device with USB OTG support
14. Connect Disting NT via USB
15. Open floating video overlay
16. Video displays correctly matching iOS/macOS quality
17. Frame rate stable at 10-15 FPS
18. No memory leaks (monitor via Android Studio profiler)
19. Camera reconnection works after disconnect/reconnect
20. App backgrounding/foregrounding handled gracefully

## Tasks / Subtasks

- [ ] Update dependencies (AC: 1-2)
  - [ ] Update pubspec.yaml with latest fork commit hash
  - [ ] Run `flutter pub get`
  - [ ] Verify fork version includes EventChannel implementation

- [ ] Update UsbVideoCapturePlugin.kt (AC: 3-10)
  - [ ] Remove VideoFrameCallback class (lines 67-121)
  - [ ] Add NV21 to Bitmap conversion helper method
  - [ ] Update startRealCameraFrameCapture to call uvccamera/native startFrameStreaming
  - [ ] Subscribe to uvccamera/frames EventChannel
  - [ ] Add frame conversion pipeline: ByteArray → NV21 → Bitmap → BMP
  - [ ] Forward BMP data to nt_helper's EventChannel
  - [ ] Update stopRealCameraFrameCapture to call fork's stopFrameStreaming
  - [ ] Add proper error handling and logging

- [ ] Build and static analysis (AC: 11-12)
  - [ ] Run `flutter analyze` - verify zero warnings
  - [ ] Run `flutter build apk` - verify successful build
  - [ ] Check APK size is reasonable

- [ ] Device testing (AC: 13-20)
  - [ ] Deploy APK to Android device
  - [ ] Connect Disting NT via USB OTG
  - [ ] Grant USB permissions
  - [ ] Open floating video overlay
  - [ ] Verify video displays
  - [ ] Check frame rate with debug logs
  - [ ] Test camera reconnection
  - [ ] Test app lifecycle (background/foreground)
  - [ ] Monitor memory usage
  - [ ] Compare quality with iOS/macOS

## Dev Notes

### Architecture Context

This story integrates the completed fork EventChannel with nt_helper's existing Android video infrastructure. The integration removes the VideoFrameCallback class (which couldn't work across plugin boundaries) and replaces it with proper EventChannel subscription.

**Current Flow (Not Working):**
```
UsbVideoCapturePlugin.kt attempts to:
- Create VideoFrameCallback (IFrameCallback)
- Call uvccamera MethodChannel startFrameStreaming
- Problem: Can't pass IFrameCallback across MethodChannel
```

**New Flow (Working):**
```
Fork (uvccamera):
  IFrameCallback → EventChannel "uvccamera/frames"

nt_helper (UsbVideoCapturePlugin.kt):
  Subscribe to "uvccamera/frames"
  → Convert NV21 to Bitmap
  → Encode Bitmap to BMP
  → Send via nt_helper EventChannel

Dart (AndroidUsbVideoChannel):
  Subscribe to nt_helper EventChannel
  → Forward to StreamController
  → VideoFrameCubit (unified with iOS/macOS)
```

### Code Changes Required

**Remove VideoFrameCallback Class:**
```kotlin
// DELETE lines 67-121 in UsbVideoCapturePlugin.kt
// This class attempted IFrameCallback but can't work across plugins
```

**Add NV21 Conversion Helper:**
```kotlin
private fun nv21ToBitmap(nv21Data: ByteArray, width: Int, height: Int): Bitmap {
    val yuvImage = YuvImage(
        nv21Data,
        ImageFormat.NV21,
        width,
        height,
        null
    )
    val out = ByteArrayOutputStream()
    yuvImage.compressToJpeg(Rect(0, 0, width, height), 100, out)
    val imageBytes = out.toByteArray()
    return BitmapFactory.decodeByteArray(imageBytes, 0, imageBytes.size)
}
```

**Update startRealCameraFrameCapture:**
```kotlin
private fun startRealCameraFrameCapture(cameraId: Int) {
    if (isStreamingActive) return

    debugLog("Starting real camera frame capture for cameraId: $cameraId")

    try {
        // Call fork's startFrameStreaming
        val uvccameraChannel = MethodChannel(
            flutterPluginBinding.binaryMessenger,
            "uvccamera/native"
        )

        uvccameraChannel.invokeMethod("startFrameStreaming", mapOf(
            "cameraId" to cameraId,
            "pixelFormat" to 5  // NV21
        ))

        // Subscribe to fork's frame EventChannel
        val uvccameraFrameChannel = EventChannel(
            flutterPluginBinding.binaryMessenger,
            "uvccamera/frames"
        )

        uvccameraFrameChannel.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                debugLog("Frame EventChannel connected")
            }

            override fun onCancel(arguments: Any?) {
                debugLog("Frame EventChannel cancelled")
            }
        })

        // Process frames from fork
        uvccameraFrameChannel.receiveBroadcastStream().listen { data ->
            if (data is ByteArray) {
                try {
                    // Convert NV21 → Bitmap → BMP
                    val bitmap = nv21ToBitmap(data, VIDEO_WIDTH, VIDEO_HEIGHT)
                    val bmpData = encodeBMP(bitmap)
                    bitmap.recycle()

                    frameCount++
                    if (frameCount % TARGET_FPS == 0) {
                        debugLog("Real camera frame #$frameCount (${bmpData.size} bytes)")
                    }

                    // Send to nt_helper EventChannel
                    mainHandler.post {
                        eventSink?.success(bmpData)
                    }
                } catch (e: Exception) {
                    android.util.Log.e("VideoCapture", "Frame conversion error: ${e.message}", e)
                }
            }
        }

        currentCameraId = cameraId
        isStreamingActive = true
        debugLog("Real camera streaming started successfully")

    } catch (e: Exception) {
        debugLog("ERROR starting real camera: ${e.message}")
        throw e
    }
}
```

### Testing Approach

**Manual Testing Checklist:**
1. Build APK: `flutter build apk`
2. Install: `adb install build/app/outputs/flutter-apk/app-release.apk`
3. Connect Disting NT via USB OTG cable
4. Launch app
5. Grant USB permissions when prompted
6. Navigate to video overlay
7. Verify video displays
8. Check debug logs for frame count
9. Test reconnection by unplugging/replugging
10. Test app lifecycle by switching to home screen and back

**Debug Verification:**
```
Expected log sequence:
[NATIVE] Starting real camera frame capture for cameraId: 0
[NATIVE] Real camera streaming started successfully
[NATIVE] Frame EventChannel connected
[uvccamera] startFrameStreaming: cameraId=0, pixelFormat=5
[NATIVE] Real camera frame #15 (49224 bytes)
[AndroidUsbVideoChannel] Frame stream data received
[VideoFrameCubit] Frame updated
```

**Performance Targets:**
- Frame rate: 10-15 FPS sustained
- Frame size: ~49KB per frame (256x64 BMP)
- Memory: Stable, no growth over time
- CPU: <20% average usage

### Project Structure Notes

**Files Modified:**
- `pubspec.yaml` - Update fork commit reference
- `android/app/src/main/kotlin/com/example/nt_helper/UsbVideoCapturePlugin.kt` - Integration changes

**Files Unchanged:**
- `lib/services/platform_channels/android_usb_video_channel.dart` - Already updated in previous commits
- `lib/ui/widgets/floating_video_overlay.dart` - Already unified in previous commits
- `lib/cubit/video_frame_cubit.dart` - Platform-agnostic, no changes needed

### References

- [Source: docs/epic-8-android-video-implementation-context.md#Android Video Architecture]
- [Source: docs/uvccamera-fork-frame-streaming-story.md#Step 5: Update nt_helper Plugin Integration]
- [Source: android/app/src/main/kotlin/com/example/nt_helper/UsbVideoCapturePlugin.kt] - Current implementation
- [Source: macos/Runner/UsbVideoCapturePlugin.swift:327-455] - Reference BMP encoding
- [Story 8.1] - Prerequisite fork implementation

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
