# Android Camera Integration Notes

## Current State (as of Epic 2 completion)

The Android UVC video integration is **partially complete**. The infrastructure is fully implemented and working with test frames, but real camera frame extraction is not yet implemented.

### What's Working

1. **Device Detection** ✅
   - UVCCamera devices are detected properly
   - Disting NT identified by vendor ID (0x16C0)
   - USB permissions handled correctly

2. **Camera Controller** ✅
   - UvcCameraController initializes successfully
   - Device events (attach/detach) handled
   - Proper resource cleanup on errors

3. **Frame Streaming Pipeline** ✅
   - EventChannel communication established
   - BMP encoding implemented in native Kotlin
   - Frames delivered to VideoFrameCubit
   - Test frames display properly at 15fps

4. **Lifecycle Management** ✅
   - App pause/resume handled
   - USB reconnection detection
   - Error recovery with retry logic

### What's Not Working

**Real Camera Frames** ❌
- Currently shows "TEST MODE - NO CAMERA" animated pattern
- UvcCameraController is initialized but frames are not extracted from it
- The texture-based rendering from UVCCamera is not being captured

## The Problem

The UVCCamera package uses texture-based rendering (GPU) but our EventChannel needs raw bytes (CPU). The camera renders to a TextureView/Surface, but we need to extract pixel data from that texture.

## Potential Solutions

### Option 1: PixelCopy API (Recommended for Android 24+)
```kotlin
// In UsbVideoCapturePlugin.kt
private fun extractFrameFromSurface(surface: Surface): Bitmap? {
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
        val bitmap = Bitmap.createBitmap(VIDEO_WIDTH, VIDEO_HEIGHT, Bitmap.Config.ARGB_8888)
        val copyResult = CountDownLatch(1)
        var success = false

        PixelCopy.request(
            surface as SurfaceView,
            bitmap,
            { result ->
                success = (result == PixelCopy.SUCCESS)
                copyResult.countDown()
            },
            Handler(Looper.getMainLooper())
        )

        copyResult.await(100, TimeUnit.MILLISECONDS)
        return if (success) bitmap else null
    }
    return null
}
```

### Option 2: Create a TextureView and Read Pixels
```kotlin
// Create a TextureView to receive camera frames
private val textureView = TextureView(context)

// Set up surface texture listener
textureView.surfaceTextureListener = object : TextureView.SurfaceTextureListener {
    override fun onSurfaceTextureAvailable(surface: SurfaceTexture, width: Int, height: Int) {
        // Connect UVCCamera to this surface
        // uvcCamera.setPreviewDisplay(Surface(surface))
    }

    override fun onSurfaceTextureUpdated(surface: SurfaceTexture) {
        // Extract frame here
        val bitmap = textureView.getBitmap() // This gets the current frame
        sendFrameThroughEventChannel(bitmap)
    }
}
```

### Option 3: OpenGL Rendering Pipeline
- Create a GLSurfaceView
- Render UVCCamera output to OpenGL texture
- Use glReadPixels to extract frame data
- More complex but most flexible

### Option 4: Native JNI Integration
- Access the underlying libuvc C++ layer directly
- Get raw frame callbacks before GPU rendering
- Most performant but requires JNI code

## Implementation Steps

To complete the real camera integration:

1. **Choose extraction method** based on Android version support requirements
2. **Modify UsbVideoCapturePlugin.kt** to:
   - Store reference to UvcCameraController from Dart side
   - Create Surface/TextureView for camera output
   - Connect camera to the surface
   - Extract frames from the surface
   - Replace `generateTestFrame()` with real frame extraction

3. **Update AndroidUsbVideoChannel.dart** to:
   - Pass camera controller reference to native side if needed
   - Coordinate texture ID between Dart and native layers

4. **Test with physical device** and Disting NT hardware

## Why This Wasn't Completed

The Epic 2 stories focused on establishing the complete infrastructure for video streaming. Story 2.3 explicitly documented that real camera integration would use test frames initially, with real camera frame extraction identified as technical debt for future implementation.

This approach allowed:
- Validation of the entire pipeline (EventChannel, BMP encoding, frame delivery)
- Testing without requiring physical hardware
- Clear separation of infrastructure from camera-specific implementation

## Testing the Current Implementation

Even with test frames, you can verify:
- Frame delivery at 15fps
- BMP format correctness
- Memory stability (no leaks)
- Lifecycle handling
- Error recovery

The test frames show an animated pattern that changes color over time, proving that frames are being generated and delivered continuously.

## Next Steps

1. Research which UVCCamera APIs are available in the Flutter package
2. Implement one of the extraction methods above
3. Test with physical Android device + Disting NT
4. Optimize performance if needed