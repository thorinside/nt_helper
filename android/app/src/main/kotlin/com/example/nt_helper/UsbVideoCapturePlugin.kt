package com.example.nt_helper

import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.SurfaceTexture
import android.hardware.usb.UsbConstants
import android.hardware.usb.UsbDevice
import android.hardware.usb.UsbManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.view.Surface
import android.view.TextureView
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.view.TextureRegistry
import java.io.ByteArrayOutputStream
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.util.concurrent.Executors
import com.serenegiant.usb.IFrameCallback
import android.graphics.YuvImage
import android.graphics.ImageFormat
import android.graphics.Rect
import android.graphics.BitmapFactory

class UsbVideoCapturePlugin : FlutterPlugin, MethodCallHandler, EventChannel.StreamHandler {
    private lateinit var channel: MethodChannel
    private lateinit var eventChannel: EventChannel
    private lateinit var debugEventChannel: EventChannel
    private lateinit var context: Context
    private lateinit var flutterPluginBinding: FlutterPlugin.FlutterPluginBinding
    private var eventSink: EventChannel.EventSink? = null
    var debugEventSink: EventChannel.EventSink? = null
    // Use high-priority thread for video capture callbacks to prevent frame drops
    private val executor = Executors.newSingleThreadExecutor { r ->
        Thread(r, "VideoCapture").apply {
            priority = Thread.MAX_PRIORITY
        }
    }

    private var isStreamingActive = false
    private var frameCount = 0
    private var frameCallback: VideoFrameCallback? = null
    private var currentCameraId: Int? = null

    // For texture-based frame extraction
    private var textureRegistry: TextureRegistry? = null
    private var surfaceTextureEntry: TextureRegistry.SurfaceTextureEntry? = null
    private var cameraSurface: Surface? = null
    private val mainHandler = Handler(Looper.getMainLooper())

    companion object {
        private const val DISTING_VENDOR_ID = 0x16C0  // Expert Sleepers vendor ID
        private const val ACTION_USB_PERMISSION = "com.example.nt_helper.USB_PERMISSION"
        private const val VIDEO_WIDTH = 256
        private const val VIDEO_HEIGHT = 64
        private const val TARGET_FPS = 15
        private const val FRAME_INTERVAL_MS = 1000L / TARGET_FPS  // ~67ms
    }

    // Frame callback that receives frames from UVCCamera
    private class VideoFrameCallback(
        private val plugin: UsbVideoCapturePlugin,
        private val width: Int,
        private val height: Int
    ) : IFrameCallback {
        private var frameCount = 0
        private var lastFrameTime = System.currentTimeMillis()

        override fun onFrame(frame: ByteBuffer) {
            // Throttle to target FPS
            val currentTime = System.currentTimeMillis()
            val elapsed = currentTime - lastFrameTime

            if (elapsed < FRAME_INTERVAL_MS) {
                return  // Skip frame
            }

            lastFrameTime = currentTime
            frameCount++

            try {
                // Convert NV21 → Bitmap → BMP
                val bitmap = nv21ToBitmap(frame, width, height)
                val bmpData = plugin.encodeBMP(bitmap)
                bitmap.recycle()

                if (frameCount % TARGET_FPS == 0) {
                    plugin.debugLog("Real camera frame #$frameCount (${bmpData.size} bytes)")
                }

                // Send on main thread
                plugin.mainHandler.post {
                    plugin.eventSink?.success(bmpData)
                }
            } catch (e: Exception) {
                android.util.Log.e("VideoCapture", "Frame error: ${e.message}", e)
            }
        }

        private fun nv21ToBitmap(nv21: ByteBuffer, width: Int, height: Int): Bitmap {
            val yuvImage = YuvImage(
                nv21.array(),
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
    }

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        this.flutterPluginBinding = flutterPluginBinding
        context = flutterPluginBinding.applicationContext
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "com.example.nt_helper/usb_video")
        channel.setMethodCallHandler(this)

        eventChannel = EventChannel(flutterPluginBinding.binaryMessenger, "com.example.nt_helper/usb_video_stream")
        eventChannel.setStreamHandler(this)

        debugEventChannel = EventChannel(flutterPluginBinding.binaryMessenger, "com.example.nt_helper/usb_video_debug")
        debugEventChannel.setStreamHandler(UsbVideoDebugHandler(this))
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "listUsbCameras" -> {
                val usbManager = context.getSystemService(Context.USB_SERVICE) as UsbManager
                val devices = usbManager.deviceList.values
                    .filter { device ->
                        // Check if device is a video class device or Disting NT
                        device.deviceClass == UsbConstants.USB_CLASS_VIDEO ||
                        device.vendorId == DISTING_VENDOR_ID
                    }
                    .map { device ->
                        mapOf(
                            "deviceId" to device.deviceName,
                            "productName" to (device.productName ?: "Unknown Device"),
                            "vendorId" to device.vendorId,
                            "productId" to device.productId,
                            "isDistingNT" to (device.vendorId == DISTING_VENDOR_ID)
                        )
                    }
                result.success(devices)
            }
            
            "requestUsbPermission" -> {
                val deviceId = call.argument<String>("deviceId")
                if (deviceId == null) {
                    result.error("INVALID_ARGUMENT", "deviceId is required", null)
                    return
                }
                
                val usbManager = context.getSystemService(Context.USB_SERVICE) as UsbManager
                val device = usbManager.deviceList[deviceId]
                
                if (device == null) {
                    result.error("DEVICE_NOT_FOUND", "USB device not found", null)
                    return
                }
                
                if (usbManager.hasPermission(device)) {
                    result.success(true)
                } else {
                    val permissionIntent = PendingIntent.getBroadcast(
                        context,
                        0,
                        Intent(ACTION_USB_PERMISSION),
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                            PendingIntent.FLAG_MUTABLE
                        } else {
                            0
                        }
                    )
                    usbManager.requestPermission(device, permissionIntent)
                    result.success(false)  // Permission requested but not yet granted
                }
            }
            
            "startVideoStream" -> {
                val deviceId = call.argument<String>("deviceId")
                val cameraId = call.argument<Int>("cameraId")

                if (deviceId == null) {
                    result.error("INVALID_ARGUMENT", "deviceId is required", null)
                    return
                }

                if (cameraId != null) {
                    try {
                        startRealCameraFrameCapture(cameraId)
                        result.success(true)
                    } catch (e: Exception) {
                        debugLog("Failed to start real camera: ${e.message}")
                        // Fallback to test frames
                        startVideoStream()
                        result.success(true)
                    }
                } else {
                    // Test mode
                    startVideoStream()
                    result.success(true)
                }
            }

            "stopVideoStream" -> {
                if (currentCameraId != null) {
                    stopRealCameraFrameCapture()
                } else {
                    stopVideoStream()
                }
                result.success(null)
            }
            
            "isSupported" -> {
                // Android supports USB video with proper libraries
                result.success(true)
            }
            
            else -> {
                result.notImplemented()
            }
        }
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }

    private fun startVideoStream() {
        if (isStreamingActive) {
            return
        }

        isStreamingActive = true
        frameCount = 0
        executor.execute {
            try {
                // Generate frames at target FPS
                // In production with real UVCCamera integration, this would consume actual camera frames
                var lastFrameTime = System.currentTimeMillis()

                while (isStreamingActive) {
                    val currentTime = System.currentTimeMillis()
                    val elapsedTime = currentTime - lastFrameTime

                    if (elapsedTime >= FRAME_INTERVAL_MS) {
                        // Generate test frame pattern (Disting NT display size: 256x64)
                        val testBitmap = generateTestFrame()
                        val bmpData = encodeBMP(testBitmap)
                        testBitmap.recycle()

                        frameCount++
                        if (frameCount % TARGET_FPS == 0) {
                            android.util.Log.d("VideoCapture", "Streamed frame #$frameCount (${bmpData.size} bytes)")
                        }

                        // EventChannel calls must be made on the main UI thread
                        mainHandler.post {
                            eventSink?.success(bmpData)
                        }

                        lastFrameTime = currentTime
                    } else {
                        // Sleep for a short time to avoid busy waiting
                        Thread.sleep(1)
                    }
                }
            } catch (e: Exception) {
                android.util.Log.e("VideoCapture", "Error in video stream: ${e.message}", e)
                // Error calls also need to be on main thread
                mainHandler.post {
                    eventSink?.error("STREAM_ERROR", e.message, null)
                }
            }
        }
    }

    private fun stopVideoStream() {
        isStreamingActive = false
    }

    private fun generateTestFrame(): Bitmap {
        // NOTE: This is a placeholder implementation that generates test frames.
        // In production, this should extract real frames from the UVCCamera instance.
        // The UVCCamera package renders to a texture, so frame extraction requires:
        // 1. Creating a Surface/TextureView to receive camera frames
        // 2. Reading pixels from the rendered texture
        // 3. Converting to Bitmap for BMP encoding
        //
        // TODO: Implement real frame extraction from UVCCamera
        // Possible approaches:
        // - Use PixelCopy API (Android 24+) to read from Surface
        // - Create a GLSurfaceView and use glReadPixels
        // - Access the underlying libuvc frames via JNI

        // Create a test pattern bitmap (256x64 for Disting NT)
        val bitmap = Bitmap.createBitmap(VIDEO_WIDTH, VIDEO_HEIGHT, Bitmap.Config.RGB_565)
        val canvas = Canvas(bitmap)

        // Fill with animated pattern to show frames are updating
        val timeValue = (System.currentTimeMillis() / 10) % 256
        val backgroundColor = Color.rgb(timeValue.toInt(), timeValue.toInt() / 2, 0)
        canvas.drawColor(backgroundColor)

        // Draw test pattern with "NO CAMERA" text to indicate test mode
        val paint = android.graphics.Paint().apply {
            color = Color.WHITE
            strokeWidth = 1f
            textSize = 12f
            textAlign = android.graphics.Paint.Align.CENTER
        }

        // Draw grid lines
        for (i in 0 until VIDEO_HEIGHT step 4) {
            canvas.drawLine(0f, i.toFloat(), VIDEO_WIDTH.toFloat(), i.toFloat(), paint)
        }

        // Draw "TEST MODE" text
        canvas.drawText("TEST MODE - NO CAMERA", VIDEO_WIDTH / 2f, VIDEO_HEIGHT / 2f, paint)

        return bitmap
    }

    private fun encodeBMP(bitmap: Bitmap): ByteArray {
        // Extract RGB data from bitmap
        val width = bitmap.width
        val height = bitmap.height
        val pixels = IntArray(width * height)
        bitmap.getPixels(pixels, 0, width, 0, 0, width, height)

        // BMP format specifications
        val bytesPerPixel = 3  // RGB24
        val rowPadding = (4 - ((width * bytesPerPixel) % 4)) % 4
        val paddedBytesPerRow = width * bytesPerPixel + rowPadding
        val dataSize = paddedBytesPerRow * height
        val fileSize = 54 + dataSize  // 54 byte header + pixel data

        val bmpData = ByteArray(fileSize)
        val buffer = ByteBuffer.wrap(bmpData).order(ByteOrder.LITTLE_ENDIAN)

        // BMP File Header (14 bytes)
        bmpData[0] = 0x42  // 'B'
        bmpData[1] = 0x4D  // 'M'
        buffer.putInt(2, fileSize)  // File size
        buffer.putInt(6, 0)  // Reserved
        buffer.putInt(10, 54)  // Offset to pixel data

        // DIB Header (40 bytes)
        buffer.putInt(14, 40)  // Header size
        buffer.putInt(18, width)
        buffer.putInt(22, -height)  // Negative = top-down
        buffer.putShort(26, 1)  // Planes
        buffer.putShort(28, 24)  // Bits per pixel
        // Compression and other fields remain 0

        // Write pixel data (BGR format with row padding)
        var bmpIndex = 54
        for (y in 0 until height) {
            for (x in 0 until width) {
                val pixelIndex = y * width + x
                val pixel = pixels[pixelIndex]

                // Extract RGB and convert to BGR for BMP
                val r = (pixel shr 16) and 0xFF
                val g = (pixel shr 8) and 0xFF
                val b = pixel and 0xFF

                bmpData[bmpIndex] = b.toByte()
                bmpData[bmpIndex + 1] = g.toByte()
                bmpData[bmpIndex + 2] = r.toByte()
                bmpIndex += 3
            }

            // Add row padding
            for (i in 0 until rowPadding) {
                bmpData[bmpIndex] = 0
                bmpIndex++
            }
        }

        return bmpData
    }

    // Debug logging method
    fun debugLog(message: String) {
        val timestamp = java.text.SimpleDateFormat("HH:mm:ss", java.util.Locale.US).format(java.util.Date())
        val logMessage = "[$timestamp] [NATIVE] $message"
        mainHandler.post {
            debugEventSink?.success(logMessage)
        }
    }

    private fun startRealCameraFrameCapture(cameraId: Int) {
        if (isStreamingActive) {
            return
        }

        debugLog("Starting real camera frame capture for cameraId: $cameraId")

        try {
            // Call uvccamera's new startFrameStreaming API via method channel
            val uvccameraChannel = MethodChannel(
                flutterPluginBinding.binaryMessenger,
                "uvccamera"
            )

            // Create callback
            frameCallback = VideoFrameCallback(this, VIDEO_WIDTH, VIDEO_HEIGHT)
            currentCameraId = cameraId

            // Register with uvccamera
            uvccameraChannel.invokeMethod("startFrameStreaming", mapOf(
                "cameraId" to cameraId,
                "pixelFormat" to 5  // NV21
            ))

            isStreamingActive = true
            debugLog("Real camera streaming started successfully")

        } catch (e: Exception) {
            debugLog("ERROR starting real camera: ${e.message}")
            throw e
        }
    }

    private fun stopRealCameraFrameCapture() {
        val cameraId = currentCameraId ?: return

        try {
            val uvccameraChannel = MethodChannel(
                flutterPluginBinding.binaryMessenger,
                "uvccamera"
            )

            uvccameraChannel.invokeMethod("stopFrameStreaming", mapOf(
                "cameraId" to cameraId
            ))

            frameCallback = null
            currentCameraId = null
            isStreamingActive = false
            debugLog("Real camera streaming stopped")

        } catch (e: Exception) {
            debugLog("ERROR stopping real camera: ${e.message}")
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
        debugEventChannel.setMethodCallHandler(null)
        executor.shutdown()
    }
}

// Debug Stream Handler
class UsbVideoDebugHandler(private val plugin: UsbVideoCapturePlugin) : EventChannel.StreamHandler {
    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        plugin.debugEventSink = events
        plugin.debugLog("USB Video Debug channel connected")
    }

    override fun onCancel(arguments: Any?) {
        plugin.debugEventSink = null
    }
}