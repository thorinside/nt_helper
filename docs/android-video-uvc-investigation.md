# Android USB Video Investigation - Disting NT

## Summary

Disting NT does not support standard UVC probe control queries (UVC_GET_CUR/MIN/MAX) and returns LIBUSB_TRANSFER_STALL error when these are attempted. Fixed by detecting device VID:0x3773 and skipping probe queries.

## Device Characteristics (from macOS AVFoundation)

**Vendor/Product:**
- VID: 0x3773 (14195 decimal) - Expert Sleepers
- PID: 0x0001
- Product Name: disting NT

**Video Format:**
- Resolution: 256x64 pixels
- Frame Rate: ~30 FPS
- Pixel Format: UYVY/YUYV422 or NV12 (YUV 4:2:2 uncompressed)
- NOT MJPEG - uses raw uncompressed video

**USB Interfaces:**
- Interface 5: Video Control (Class 14, Subclass 1) - endpoint 133 (interrupt)
- Interface 6: Video Streaming (Class 14, Subclass 2) - endpoint 134 (isochronous, 1024 byte packets)

## Problem Analysis

### Root Cause

libuvc's `_prepare_stream_ctrl()` function queries the device with:
1. `UVC_GET_CUR` - get current stream settings
2. `UVC_GET_MIN` - get minimum values
3. `UVC_GET_MAX` - get maximum values

Disting NT doesn't respond to these queries and returns STALL error:
```
E/libuvc/stream: uvc_query_stream_ctrl:UVC_GET_MIN:err=-9
E/libusb/usbfs: LIBUSB_TRANSFER_STALL
```

This causes the device to disconnect before streaming can begin.

### Why macOS/iOS Works

AVFoundation on macOS/iOS:
- Uses higher-level Apple frameworks that handle UVC differently
- Likely reads format descriptors from Video Control interface without probe queries
- Has device-specific quirks handling for non-standard UVC devices
- Successfully detects and streams 256x64 @ 30fps

### Why Android Fails

Android using libuvc/libusb:
- Works at lower UVC protocol level
- Attempts standard UVC probe negotiation
- No built-in quirks handling for non-standard devices
- STALL error causes device disconnect

## Solution Implemented

### Fork Changes (thorinside/UVCCamera commit ea994fd)

**File:** `lib/src/main/jni/libuvc/include/libuvc/libuvc_internal.h`
- Added `uint8_t is_disting_nt` flag to device handle struct

**File:** `lib/src/main/jni/libuvc/src/device.c`
- Set `is_disting_nt = true` when VID:0x3773 && PID:0x0001 detected

**File:** `lib/src/main/jni/libuvc/src/stream.c`
- Modified `_prepare_stream_ctrl()` to skip UVC probe queries if `is_disting_nt` is set
- Device will use manually configured stream parameters (256x64 YUYV)

### Pattern

This follows the existing workaround pattern for Apple iSight camera (`is_isight` flag).

## Testing

### Tools Used

```bash
# List video devices on macOS
ffmpeg -f avfoundation -list_devices true -i ""

# Query supported formats
ffmpeg -f avfoundation -i "3" -t 0.1 2>&1 | grep fps

# Capture test frame
ffmpeg -f avfoundation -video_size 256x64 -framerate 30 -i "3" -frames:v 1 /tmp/test.bmp
```

### Expected Results

With the fix applied:
1. Device detection succeeds (VID 0x3773 recognized as Disting NT)
2. Camera opens without STALL error
3. Stream control negotiation skipped
4. NV21 frames received from uvccamera EventChannel
5. NV21→BMP conversion in native plugin
6. BMP frames delivered to VideoFrameCubit

## Pixel Format Notes

Disting NT advertises these pixel formats (from AVFoundation):
- uyvy422 (primary)
- yuyv422
- nv12
- 0rgb
- bgr0

uvccamera likely captures as NV21 (similar to NV12), which is then converted to BMP in the native plugin (`UsbVideoCapturePlugin.kt`).

## Related Files

### nt_helper
- `lib/services/platform_channels/android_usb_video_channel.dart:73` - VID check
- `android/app/src/main/kotlin/com/example/nt_helper/UsbVideoCapturePlugin.kt:176` - NV21→BMP conversion
- `pubspec.yaml:93` - uvccamera fork reference

### UVCCamera Fork
- `lib/src/main/jni/libuvc/include/libuvc/libuvc_internal.h:310` - is_disting_nt flag
- `lib/src/main/jni/libuvc/src/device.c:309` - VID/PID detection
- `lib/src/main/jni/libuvc/src/stream.c:386` - probe query skip logic

## Future Considerations

1. **Frame Rate**: Device runs at 30 FPS but we target 15 FPS throttling - may need adjustment
2. **Pixel Format**: Currently using NV21, but YUYV422 might be more efficient
3. **Other Devices**: This pattern could apply to other non-standard UVC devices
4. **Format Descriptors**: May still be readable from Video Control interface without probe queries

## References

- UVC 1.5 Specification: probe/commit control protocol
- libuvc documentation: stream control negotiation
- AVFoundation docs: macOS video capture

---

*Investigation Date: 2025-11-15*
*Device: Google Pixel 10 Pro (wireless ADB 192.168.50.197:35817)*
*Fork Commit: ea994fd69286ab847e47169e8e4a6e970afff39d*
