name: "USB Video Capture Screen Stream for Disting NT"
description: |
  Replace static screenshot functionality with real-time USB video stream capture from Disting NT hardware

---

## Goal

**Feature Goal**: Replace the current static screenshot polling mechanism with real-time USB video stream capture displaying the Disting NT's OLED screen content via USB Video Class (UVC) protocol

**Deliverable**: Cross-platform video streaming widget that displays live USB video feed from Disting NT, replacing the existing FloatingScreenshotOverlay with a FloatingVideoStreamOverlay

**Success Definition**: Users can view a real-time video stream of the Disting NT display in the app across all platforms (iOS, Android, macOS, Windows, Linux) when the device is connected via USB

## User Persona

**Target User**: Musicians and sound designers using Disting NT hardware who need real-time visual feedback

**Use Case**: Monitoring Disting NT's display while adjusting parameters, viewing waveforms, and navigating presets without looking directly at the hardware

**User Journey**: 
1. User connects Disting NT via USB to their device
2. User opens nt_helper app and navigates to main screen
3. User taps screenshot/video button to open floating overlay
4. Live video stream appears showing real-time NT display content
5. User can resize, minimize, or close the video overlay

**Pain Points Addressed**: 
- Current 5-second polling creates laggy, choppy visual feedback
- Static screenshots miss real-time parameter changes and animations
- Users need to physically look at hardware while making adjustments

## Why

- Os has implemented USB video screen capture on the NT hardware side
- Real-time video provides immediate visual feedback for parameter adjustments
- Enhances remote control capabilities of the app
- Aligns with professional music production workflows requiring screen monitoring

## What

Replace the existing screenshot SysEx polling mechanism with USB Video Class (UVC) streaming to display real-time video from Disting NT's OLED display.

### Success Criteria

- [ ] USB video stream displays at minimum 15 FPS
- [ ] Video overlay can be resized, moved, and closed
- [ ] Stream automatically reconnects on USB disconnect/reconnect
- [ ] Works on iOS, Android, macOS, Windows, and Linux platforms
- [ ] Graceful fallback to screenshot mode if video unavailable
- [ ] No degradation of MIDI communication performance

## All Needed Context

### Context Completeness Check

_This PRP contains all necessary implementation details including platform-specific requirements, existing code patterns, and external library documentation._

### Documentation & References

```yaml
# Flutter USB Video Packages
- url: https://pub.dev/packages/flutter_uvc_camera
  why: Primary package for Android USB video capture with UVC support
  critical: Requires Android USB permissions and may need targetSdkVersion 27 for Android 10+

- url: https://pub.dev/packages/flutter_webrtc#platform-specific-setup
  why: Cross-platform video streaming solution with native performance
  critical: Each platform requires specific native setup steps

- url: https://docs.flutter.dev/platform-integration/platform-channels
  why: Platform channel implementation for iOS/desktop USB video
  critical: iOS requires custom implementation as no package supports external cameras

# Existing Codebase Patterns
- file: lib/domain/sysex/responses/screenshot_response.dart
  why: Current screenshot implementation to understand data flow
  pattern: SysexResponse parsing pattern for image data
  gotcha: Uses 256x64 resolution with gamma correction

- file: lib/ui/widgets/floating_screenshot_overlay.dart
  why: Current overlay widget structure to replicate for video
  pattern: Floating overlay with resize/close functionality
  gotcha: Uses Timer for 5-second polling - replace with stream

- file: lib/cubit/disting_cubit.dart
  why: State management integration point
  pattern: updateScreenshot method at line 471
  gotcha: State updates need to handle video stream instead of Uint8List

- file: ios/Runner/IosFileAccessPlugin.swift
  why: Example of iOS platform channel implementation
  pattern: FlutterPlugin with method channel setup
  gotcha: Shows proper Swift/Flutter bridge pattern

# Platform Documentation
- url: https://developer.android.com/guide/topics/connectivity/usb/host
  why: Android USB host mode requirements
  critical: Requires USB_PERMISSION and CAMERA permissions

- url: https://developer.apple.com/documentation/avfoundation/avcapturedevice
  why: iOS external camera access via AVFoundation
  critical: iOS 17+ required for external webcam support

- docfile: PRPs/ai_docs/usb_video_platforms.md
  why: Platform-specific USB video implementation details
  section: Implementation requirements per platform
```

### Current Codebase Tree

```bash
lib/
├── domain/
│   ├── sysex/
│   │   ├── requests/take_screenshot.dart
│   │   └── responses/screenshot_response.dart
│   └── i_disting_midi_manager.dart (encodeTakeScreenshot method)
├── ui/
│   └── widgets/
│       └── floating_screenshot_overlay.dart
├── cubit/
│   └── disting_cubit.dart (updateScreenshot method)
└── services/
    └── disting_controller.dart

ios/
└── Runner/
    └── IosFileAccessPlugin.swift (platform channel example)

android/
└── app/
    └── src/main/
        ├── kotlin/com/example/nt_helper/MainActivity.kt
        └── AndroidManifest.xml
```

### Desired Codebase Tree with Files to be Added

```bash
lib/
├── domain/
│   ├── video/
│   │   ├── usb_video_manager.dart         # Core video stream management
│   │   └── platform_video_handler.dart    # Platform-specific implementations
│   └── i_disting_midi_manager.dart        # Add getVideoStream method
├── ui/
│   └── widgets/
│       ├── floating_video_overlay.dart    # New video overlay widget
│       └── floating_screenshot_overlay.dart # Keep as fallback
├── cubit/
│   └── disting_cubit.dart                 # Add video stream state
└── services/
    ├── video_stream_service.dart          # Video stream service
    └── platform_channels/
        └── usb_video_channel.dart         # Platform channel interface

ios/
└── Runner/
    └── UsbVideoCapturePlugin.swift        # iOS USB video plugin

android/
└── app/
    └── src/main/
        └── kotlin/.../UsbVideoCapturePlugin.kt # Android USB video plugin

macos/
└── Runner/
    └── UsbVideoCapturePlugin.swift        # macOS USB video plugin

windows/
└── runner/
    └── usb_video_capture_plugin.cpp      # Windows USB video plugin

linux/
└── usb_video_capture_plugin.cc           # Linux USB video plugin
```

### Known Gotchas & Library Quirks

```dart
// CRITICAL: flutter_uvc_camera is Android-only
// iOS/Desktop require custom platform channel implementation

// GOTCHA: Android 10+ with targetSdkVersion 28+ blocks UVC devices
// May need to set targetSdkVersion to 27 in android/app/build.gradle

// PATTERN: Platform channels must handle null/error states
// USB devices can disconnect at any time

// CRITICAL: Video streaming requires different state management
// Stream<Uint8List> instead of Future<Uint8List>
```

## Implementation Blueprint

### Data Models and Structure

```dart
// lib/domain/video/video_stream_state.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'video_stream_state.freezed.dart';

@freezed
class VideoStreamState with _$VideoStreamState {
  const factory VideoStreamState.disconnected() = _Disconnected;
  const factory VideoStreamState.connecting() = _Connecting;
  const factory VideoStreamState.streaming({
    required Stream<Uint8List> videoStream,
    required int width,
    required int height,
    required double fps,
  }) = _Streaming;
  const factory VideoStreamState.error(String message) = _Error;
}

// lib/domain/video/usb_device_info.dart
class UsbDeviceInfo {
  final String deviceId;
  final String productName;
  final int vendorId;
  final int productId;
  final bool isDistingNT;
  
  const UsbDeviceInfo({
    required this.deviceId,
    required this.productName,
    required this.vendorId,
    required this.productId,
    required this.isDistingNT,
  });
}
```

### Implementation Tasks (ordered by dependencies)

```yaml
Task 1: CREATE lib/domain/video/video_stream_state.dart
  - IMPLEMENT: Freezed union for video stream states
  - FOLLOW pattern: lib/cubit/disting_state.dart (freezed state pattern)
  - NAMING: VideoStreamState with union cases for all states
  - PLACEMENT: Domain layer for video functionality

Task 2: CREATE lib/services/platform_channels/usb_video_channel.dart
  - IMPLEMENT: Platform channel interface for USB video
  - FOLLOW pattern: ios/Runner/IosFileAccessPlugin.swift (method channel setup)
  - NAMING: UsbVideoChannel class with stream methods
  - CRITICAL: Handle platform differences via conditional imports
  - PLACEMENT: Services layer platform channels

Task 3: CREATE android/app/src/main/kotlin/.../UsbVideoCapturePlugin.kt
  - IMPLEMENT: Android USB video capture using flutter_uvc_camera
  - FOLLOW pattern: MainActivity.kt structure
  - PERMISSIONS: Add USB and CAMERA permissions to manifest
  - CRITICAL: Handle USB device detection and permissions
  - PLACEMENT: Android native plugin implementation

Task 4: CREATE ios/Runner/UsbVideoCapturePlugin.swift
  - IMPLEMENT: iOS external camera capture via AVFoundation
  - FOLLOW pattern: IosFileAccessPlugin.swift structure
  - CRITICAL: Check iOS version >= 17 for external camera support
  - FALLBACK: Return unsupported error for older iOS versions
  - PLACEMENT: iOS native plugin implementation

Task 5: CREATE macos/Runner/UsbVideoCapturePlugin.swift
  - IMPLEMENT: macOS USB camera capture via AVFoundation
  - PATTERN: Similar to iOS but with macOS-specific APIs
  - CRITICAL: Request camera permissions in Info.plist
  - PLACEMENT: macOS native plugin implementation

Task 6: CREATE windows/runner/usb_video_capture_plugin.cpp
  - IMPLEMENT: Windows USB video via Media Foundation API
  - PATTERN: Flutter Windows plugin structure
  - CRITICAL: Handle DirectShow as fallback
  - PLACEMENT: Windows native plugin implementation

Task 7: CREATE linux/usb_video_capture_plugin.cc
  - IMPLEMENT: Linux USB video via V4L2
  - PATTERN: Flutter Linux plugin structure
  - CRITICAL: Check for /dev/video* devices
  - PLACEMENT: Linux native plugin implementation

Task 8: CREATE lib/domain/video/usb_video_manager.dart
  - IMPLEMENT: Cross-platform video manager using conditional imports
  - FOLLOW pattern: lib/domain/i_disting_midi_manager.dart interface
  - DEPENDENCIES: Import platform channel from Task 2
  - CRITICAL: Detect Disting NT device by USB vendor/product ID
  - PLACEMENT: Domain layer video management

Task 9: CREATE lib/ui/widgets/floating_video_overlay.dart
  - IMPLEMENT: Video stream overlay widget
  - FOLLOW pattern: lib/ui/widgets/floating_screenshot_overlay.dart
  - REPLACE: Timer polling with StreamBuilder for video
  - DEPENDENCIES: Import video manager from Task 8
  - PLACEMENT: UI widgets layer

Task 10: MODIFY lib/cubit/disting_cubit.dart
  - ADD: VideoStreamState field to DistingStateSynchronized
  - REPLACE: updateScreenshot with startVideoStream/stopVideoStream
  - PATTERN: Follow existing state management patterns
  - PRESERVE: Fallback to screenshot mode if video unavailable

Task 11: MODIFY lib/ui/synchronized_screen.dart
  - REPLACE: FloatingScreenshotOverlay with FloatingVideoOverlay
  - ADD: Video/screenshot mode toggle
  - PATTERN: Follow existing overlay management
  - PRESERVE: All other functionality

Task 12: MODIFY android/app/src/main/AndroidManifest.xml
  - ADD: <uses-permission android:name="android.permission.CAMERA" />
  - ADD: <uses-feature android:name="android.hardware.usb.host" />
  - ADD: <uses-permission android:name="android.permission.USB_PERMISSION" />
  - PATTERN: Follow existing permission structure

Task 13: MODIFY ios/Runner/Info.plist
  - ADD: NSCameraUsageDescription key with description
  - ADD: UISupportedExternalAccessoryProtocols if needed
  - PATTERN: Follow existing plist structure

Task 14: MODIFY pubspec.yaml
  - ADD: flutter_uvc_camera: ^1.0.0 (Android only)
  - ADD: flutter_webrtc: ^1.0.0 (fallback option)
  - CONDITIONAL: Platform-specific dependencies
  - RUN: flutter pub get after changes

Task 15: CREATE test/services/usb_video_manager_test.dart
  - IMPLEMENT: Unit tests for video manager
  - FOLLOW pattern: test/enum_parameter_test.dart
  - MOCK: Platform channel responses
  - COVERAGE: Connection, streaming, error states
```

### Implementation Patterns & Key Details

```dart
// Platform channel pattern for video streaming
class UsbVideoChannel {
  static const _channel = MethodChannel('com.example.nt_helper/usb_video');
  static const _eventChannel = EventChannel('com.example.nt_helper/usb_video_stream');
  
  Stream<Uint8List>? _videoStream;
  
  Future<List<UsbDeviceInfo>> listUsbCameras() async {
    try {
      final List<dynamic> devices = await _channel.invokeMethod('listUsbCameras');
      return devices.map((d) => UsbDeviceInfo.fromMap(d)).toList();
    } on PlatformException catch (e) {
      debugPrint('Failed to list USB cameras: ${e.message}');
      return [];
    }
  }
  
  Stream<Uint8List> startVideoStream(String deviceId) {
    _videoStream ??= _eventChannel.receiveBroadcastStream(deviceId)
        .map((data) => data as Uint8List);
    return _videoStream!;
  }
}

// Video overlay widget pattern
class FloatingVideoOverlay extends StatefulWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<VideoStreamState>(
      stream: context.read<DistingCubit>().videoStreamState,
      builder: (context, snapshot) {
        return snapshot.data?.maybeWhen(
          streaming: (stream, width, height, fps) => StreamBuilder<Uint8List>(
            stream: stream,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return Image.memory(
                  snapshot.data!,
                  gaplessPlayback: true, // CRITICAL: Prevents flicker
                );
              }
              return CircularProgressIndicator();
            },
          ),
          error: (message) => Text('Video Error: $message'),
          orElse: () => FloatingScreenshotOverlay(), // Fallback
        ) ?? SizedBox.shrink();
      },
    );
  }
}

// Android native implementation pattern
class UsbVideoCapturePlugin : FlutterPlugin, MethodCallHandler {
    private lateinit var uvcCamera: UVCCameraController
    
    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "listUsbCameras" -> {
                val usbManager = context.getSystemService(Context.USB_SERVICE) as UsbManager
                val devices = usbManager.deviceList.values
                    .filter { it.deviceClass == UsbConstants.USB_CLASS_VIDEO }
                    .map { device ->
                        mapOf(
                            "deviceId" to device.deviceName,
                            "productName" to device.productName,
                            "vendorId" to device.vendorId,
                            "productId" to device.productId,
                            "isDistingNT" to (device.vendorId == DISTING_VENDOR_ID)
                        )
                    }
                result.success(devices)
            }
            "startVideoStream" -> {
                val deviceId = call.argument<String>("deviceId")
                uvcCamera.openUVCCamera(deviceId)
                uvcCamera.captureStreamStart { frame ->
                    eventSink?.success(frame)
                }
                result.success(true)
            }
        }
    }
}
```

### Integration Points

```yaml
PERMISSIONS:
  - android: "Add CAMERA and USB permissions to AndroidManifest.xml"
  - ios: "Add NSCameraUsageDescription to Info.plist"
  - macos: "Add NSCameraUsageDescription to Info.plist"

STATE:
  - modify: lib/cubit/disting_state.dart
  - add: "VideoStreamState? videoStream field to DistingStateSynchronized"

CONFIG:
  - add to: lib/services/settings_service.dart
  - pattern: "bool get preferVideoOverScreenshot => _prefs.getBool('prefer_video') ?? true;"

DEPENDENCIES:
  - pubspec.yaml: "Add platform-specific video packages"
  - android/app/build.gradle: "May need targetSdkVersion 27 for Android 10+"
```

## Validation Loop

### Level 1: Syntax & Style

```bash
# Flutter analysis
flutter analyze

# Expected: Zero errors, warnings acceptable for platform-specific code
```

### Level 2: Unit Tests

```bash
# Run new video tests
flutter test test/services/usb_video_manager_test.dart

# Run all tests to ensure no regression
flutter test

# Expected: All tests pass
```

### Level 3: Integration Testing

```bash
# Build and run on each platform
flutter run -d android  # Test on Android device with USB OTG
flutter run -d ios      # Test on iOS device with camera adapter
flutter run -d macos    # Test on macOS
flutter run -d windows  # Test on Windows
flutter run -d linux    # Test on Linux

# Test USB device detection
# 1. Run app without Disting NT connected
# 2. Connect Disting NT via USB
# 3. Verify device appears in camera list
# 4. Start video stream
# 5. Verify live video displays

# Test fallback behavior
# 1. Disable USB video in settings
# 2. Verify screenshot mode activates
# 3. Confirm 5-second polling works

# Expected: Video stream displays on all platforms or graceful fallback
```

### Level 4: Platform-Specific Validation

```bash
# Android: Check USB permissions
adb shell dumpsys package com.example.nt_helper | grep permission

# iOS: Verify camera entitlements  
codesign -d --entitlements - build/ios/iphoneos/Runner.app

# macOS: Check camera permissions
tccutil reset Camera com.example.nt_helper

# Windows: Verify Media Foundation
dxdiag /t dxdiag_output.txt && grep "DirectShow" dxdiag_output.txt

# Linux: Check V4L2 devices
v4l2-ctl --list-devices

# Performance testing
# Monitor FPS and latency across platforms
# Expected: Minimum 15 FPS, < 100ms latency
```

## Final Validation Checklist

### Technical Validation

- [ ] Flutter analyze shows zero errors
- [ ] All unit tests pass
- [ ] Video stream displays on Android
- [ ] Video stream displays on iOS (17+) or shows unsupported message
- [ ] Video stream displays on macOS
- [ ] Video stream displays on Windows
- [ ] Video stream displays on Linux
- [ ] Fallback to screenshot mode works

### Feature Validation

- [ ] USB device detection works on all platforms
- [ ] Video stream maintains minimum 15 FPS
- [ ] Overlay can be resized and closed
- [ ] Stream reconnects after USB disconnect/reconnect
- [ ] MIDI communication continues during video streaming
- [ ] No memory leaks during extended streaming

### Code Quality Validation

- [ ] Follows existing Flutter/Dart patterns
- [ ] Platform channels properly implemented
- [ ] Error handling for all failure modes
- [ ] Proper resource cleanup on dispose
- [ ] Settings integration for video preference

### Documentation & Deployment

- [ ] Platform-specific setup documented
- [ ] USB requirements documented per platform
- [ ] Fallback behavior documented
- [ ] Performance characteristics documented

---

## Anti-Patterns to Avoid

- ❌ Don't poll for video frames - use streaming
- ❌ Don't block MIDI thread with video processing
- ❌ Don't assume USB devices are always available
- ❌ Don't forget to dispose video streams properly
- ❌ Don't ignore platform-specific limitations
- ❌ Don't hardcode video resolution - detect from device
- ❌ Don't process video on UI thread - use isolates if needed

## Confidence Score

**8/10** - Comprehensive research completed with platform-specific implementation details. Minor uncertainty around exact Disting NT USB video protocol specifics, but fallback mechanisms ensure functionality.