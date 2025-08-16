package com.example.nt_helper

import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.hardware.usb.UsbConstants
import android.hardware.usb.UsbDevice
import android.hardware.usb.UsbManager
import android.os.Build
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.util.concurrent.Executors

class UsbVideoCapturePlugin : FlutterPlugin, MethodCallHandler, EventChannel.StreamHandler {
    private lateinit var channel: MethodChannel
    private lateinit var eventChannel: EventChannel
    private lateinit var context: Context
    private var eventSink: EventChannel.EventSink? = null
    // Use high-priority thread for video capture callbacks to prevent frame drops
    private val executor = Executors.newSingleThreadExecutor { r ->
        Thread(r, "VideoCapture").apply {
            priority = Thread.MAX_PRIORITY
        }
    }
    
    companion object {
        private const val DISTING_VENDOR_ID = 0x16C0  // Expert Sleepers vendor ID
        private const val ACTION_USB_PERMISSION = "com.example.nt_helper.USB_PERMISSION"
    }

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        context = flutterPluginBinding.applicationContext
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "com.example.nt_helper/usb_video")
        channel.setMethodCallHandler(this)
        
        eventChannel = EventChannel(flutterPluginBinding.binaryMessenger, "com.example.nt_helper/usb_video_stream")
        eventChannel.setStreamHandler(this)
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
                // Note: Actual video streaming would require UVC camera library integration
                // This is a stub implementation
                val deviceId = call.argument<String>("deviceId")
                if (deviceId == null) {
                    result.error("INVALID_ARGUMENT", "deviceId is required", null)
                    return
                }
                
                // Start mock video stream for demonstration
                startMockVideoStream()
                result.success(true)
            }
            
            "stopVideoStream" -> {
                stopMockVideoStream()
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

    private fun startMockVideoStream() {
        // Mock implementation - would be replaced with actual UVC camera streaming
        executor.execute {
            // PERFORMANCE NOTES for real implementation:
            // 1. Use high-priority background thread (already configured above)
            // 2. Process frames quickly in callback - avoid UI thread dispatch
            // 3. Call eventSink directly from capture thread, not main thread
            // 4. Use proper bitmap recycling to prevent memory leaks
            // 5. Minimize processing in capture callback
            //
            // Example efficient callback pattern:
            // fun onFrameAvailable(bitmap: Bitmap) {
            //     val outputStream = ByteArrayOutputStream()
            //     bitmap.compress(Bitmap.CompressFormat.PNG, 100, outputStream)
            //     val pngData = outputStream.toByteArray()
            //     eventSink?.success(pngData)  // Direct call, no UI thread dispatch
            //     bitmap.recycle()  // Important: recycle bitmap immediately
            // }
        }
    }

    private fun stopMockVideoStream() {
        // Stop the video streaming
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
        executor.shutdown()
    }
}