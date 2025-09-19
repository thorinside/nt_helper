import Flutter
import UIKit
import AVFoundation

public class UsbVideoCapturePlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
    private var eventSink: FlutterEventSink?
    var debugEventSink: FlutterEventSink?
    private var captureSession: AVCaptureSession?
    private var videoOutput: AVCaptureVideoDataOutput?
    private let sessionQueue = DispatchQueue(label: "com.example.nt_helper.videoCaptureQueue")
    private let ciContext = CIContext(options: [.workingColorSpace: NSNull()])
    private var frameCount = 0
    
    private static let DISTING_VENDOR_ID = 0x16C0  // Expert Sleepers vendor ID
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "com.example.nt_helper/usb_video", binaryMessenger: registrar.messenger())
        let eventChannel = FlutterEventChannel(name: "com.example.nt_helper/usb_video_stream", binaryMessenger: registrar.messenger())
        let debugChannel = FlutterEventChannel(name: "com.example.nt_helper/usb_video_debug", binaryMessenger: registrar.messenger())

        let instance = UsbVideoCapturePlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
        eventChannel.setStreamHandler(instance)
        debugChannel.setStreamHandler(UsbVideoDebugHandler(plugin: instance))
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "listUsbCameras":
            listExternalCameras(result: result)
            
        case "requestUsbPermission":
            // iOS doesn't require explicit USB permission for cameras
            // Camera permission is handled via Info.plist
            result(true)
            
        case "startVideoStream":
            guard let args = call.arguments as? [String: Any],
                  let deviceId = args["deviceId"] as? String else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "deviceId is required", details: nil))
                return
            }
            startVideoStream(deviceId: deviceId, result: result)
            
        case "stopVideoStream":
            stopVideoStream()
            result(nil)
            
        case "isSupported":
            // Check if iOS version supports external cameras
            if #available(iOS 17.0, *) {
                result(true)
            } else {
                result(false)
            }
            
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    private func listExternalCameras(result: @escaping FlutterResult) {
        if #available(iOS 17.0, *) {
            debugLog("Starting device discovery on iOS \(UIDevice.current.systemVersion)")

            // First try external cameras
            let externalDiscoverySession = AVCaptureDevice.DiscoverySession(
                deviceTypes: [.external],  // External USB cameras
                mediaType: .video,
                position: .unspecified
            )

            debugLog("External discovery session found \(externalDiscoverySession.devices.count) devices")

            var devices = externalDiscoverySession.devices.map { device in
                debugLog("External device: \(device.localizedName) (ID: \(device.uniqueID))")
                return [
                    "deviceId": device.uniqueID,
                    "productName": device.localizedName + " (external)",
                    "vendorId": 0,  // iOS doesn't provide vendor ID
                    "productId": 0,  // iOS doesn't provide product ID
                    "isDistingNT": device.localizedName.lowercased().contains("disting")
                ]
            }

            // If no external cameras found, try all available cameras as fallback
            if devices.isEmpty {
                debugLog("No external devices found, trying fallback discovery")
                let allDiscoverySession = AVCaptureDevice.DiscoverySession(
                    deviceTypes: [.builtInWideAngleCamera, .builtInTelephotoCamera, .builtInUltraWideCamera, .external],
                    mediaType: .video,
                    position: .unspecified
                )

                debugLog("Fallback discovery session found \(allDiscoverySession.devices.count) devices")

                devices = allDiscoverySession.devices.map { device in
                    debugLog("Fallback device: \(device.localizedName) (ID: \(device.uniqueID))")
                    return [
                        "deviceId": device.uniqueID,
                        "productName": device.localizedName + " (fallback)",
                        "vendorId": 0,
                        "productId": 0,
                        "isDistingNT": device.localizedName.lowercased().contains("disting")
                    ]
                }
            }

            debugLog("Returning \(devices.count) devices to Flutter")
            result(devices)
        } else {
            debugLog("ERROR: External cameras require iOS 17.0+, current: \(UIDevice.current.systemVersion)")
            result([])
        }
    }
    
    private func startVideoStream(deviceId: String, result: @escaping FlutterResult) {
        debugLog("startVideoStream called with deviceId: \(deviceId)")

        if #available(iOS 17.0, *) {
            debugLog("iOS 17.0+ confirmed, proceeding with session setup on MAIN THREAD")
            // CRITICAL: iOS requires camera session setup on the same thread as user interactions (main thread)
            DispatchQueue.main.async { [weak self] in
                guard let self = self else {
                    self?.debugLog("ERROR: self is nil in sessionQueue")
                    return
                }
                
                // Stop any existing session
                self.stopVideoStream()

                // Create new capture session
                self.captureSession = AVCaptureSession()
                guard let captureSession = self.captureSession else {
                    self.debugLog("ERROR: Failed to create AVCaptureSession")
                    result(FlutterError(code: "SESSION_ERROR", message: "Failed to create capture session", details: nil))
                    return
                }

                // Find the device
                guard let device = AVCaptureDevice(uniqueID: deviceId) else {
                    // Get all available devices for debugging
                    let allDevices = AVCaptureDevice.DiscoverySession(
                        deviceTypes: [.builtInWideAngleCamera, .builtInTelephotoCamera, .builtInUltraWideCamera, .external],
                        mediaType: .video,
                        position: .unspecified
                    ).devices

                    self.debugLog("ERROR: Device not found! Available devices: \(allDevices.count)")
                    for device in allDevices {
                        self.debugLog("  - \(device.localizedName) (ID: \(device.uniqueID))")
                    }

                    // Clear the session since device not found
                    self.captureSession = nil
                    DispatchQueue.main.async {
                        result(FlutterError(code: "DEVICE_NOT_FOUND",
                                          message: "Camera device not found",
                                          details: nil))
                    }
                    return
                }

                self.debugLog("Device found: \(device.localizedName)")
                
                do {
                    let input = try AVCaptureDeviceInput(device: device)

                    // Log active format details
                    let activeFormat = device.activeFormat
                    let dimensions = CMVideoFormatDescriptionGetDimensions(activeFormat.formatDescription)
                    let pixelFormat = CMFormatDescriptionGetMediaSubType(activeFormat.formatDescription)
                    self.debugLog("Active format: \(dimensions.width)x\(dimensions.height), pixel format: \(self.pixelFormatString(pixelFormat))")

                    // Create output
                    self.videoOutput = AVCaptureVideoDataOutput()

                    // Configure for UVC compatibility - let device use its natural format
                    self.videoOutput?.videoSettings = nil

                    // Enable frame dropping to prevent buffer overflow
                    self.videoOutput?.alwaysDiscardsLateVideoFrames = true

                    // Set the delegate on a high-priority queue (not sessionQueue)
                    self.videoOutput?.setSampleBufferDelegate(self, queue: DispatchQueue.global(qos: .userInitiated))

                    // Configure session
                    captureSession.beginConfiguration()

                    if captureSession.canAddInput(input) {
                        captureSession.addInput(input)
                    } else {
                        self.debugLog("ERROR: Cannot add input to session")
                        self.captureSession = nil
                        result(FlutterError(code: "INPUT_ERROR", message: "Cannot add camera input to session", details: nil))
                        return
                    }

                    if let output = self.videoOutput, captureSession.canAddOutput(output) {
                        captureSession.addOutput(output)
                    } else {
                        self.debugLog("ERROR: Cannot add output to session")
                        self.captureSession = nil
                        result(FlutterError(code: "OUTPUT_ERROR", message: "Cannot add video output to session", details: nil))
                        return
                    }

                    captureSession.commitConfiguration()

                    // Start the capture session
                    captureSession.startRunning()
                    self.debugLog("Video capture session started for device: \(device.localizedName)")

                    DispatchQueue.main.async {
                        result(true)
                    }
                } catch {
                    self.debugLog("ERROR: Failed to setup capture session: \(error.localizedDescription)")
                    // Clear the session since setup failed
                    self.captureSession = nil
                    DispatchQueue.main.async {
                        result(FlutterError(code: "CAPTURE_ERROR", message: "Failed to setup capture session", details: nil))
                    }
                }
            }
        } else {
            result(FlutterError(code: "UNSUPPORTED", message: "External cameras require iOS 17.0 or later", details: nil))
        }
    }
    
    private func stopVideoStream() {
        sessionQueue.async { [weak self] in
            self?.captureSession?.stopRunning()
            self?.captureSession = nil
            self?.videoOutput = nil
        }
    }
    
    // MARK: - FlutterStreamHandler

    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        debugLog("Flutter event channel onListen called - enabling frame streaming")
        self.eventSink = events
        debugLog("Event sink set successfully - frames will now be sent to Flutter")
        return nil
    }

    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        debugLog("Flutter event channel onCancel called - disabling frame streaming (camera session remains active)")
        self.eventSink = nil
        debugLog("Event sink cleared - frames will no longer be sent to Flutter (camera still running)")
        // NOTE: We do NOT stop the camera session here - only disable frame streaming
        // This allows the session to persist across EventChannel reconnections
        return nil
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

extension UsbVideoCapturePlugin: AVCaptureVideoDataOutputSampleBufferDelegate {
    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        frameCount += 1

        // Check if event sink is available (this is normal when Flutter isn't listening)
        if eventSink == nil {
            return
        }

        // Convert sample buffer to BMP data (like other working platforms)
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            debugLog("ERROR: Failed to get image buffer from sample")
            return
        }

        // Debug the raw image buffer properties (enhanced with human-readable format)
        if frameCount <= 3 {
            let width = CVPixelBufferGetWidth(imageBuffer)
            let height = CVPixelBufferGetHeight(imageBuffer)
            let pixelFormat = CVPixelBufferGetPixelFormatType(imageBuffer)
            debugLog("Raw camera frame #\(frameCount): \(width)x\(height), format: \(pixelFormatString(pixelFormat)) (\(pixelFormat))")
        }

        autoreleasepool {
            let ciImage = CIImage(cvPixelBuffer: imageBuffer)

            if let cgImage = ciContext.createCGImage(ciImage, from: ciImage.extent) {
                // Convert CGImage to RGB data then encode as BMP
                if let bmpData = encodeBMP(from: cgImage) {
                    // Double-check event sink before sending
                    guard let sink = self.eventSink else {
                        return
                    }

                    // Send BMP data directly to Flutter (matching other platforms)
                    sink(FlutterStandardTypedData(bytes: bmpData))
                } else {
                    debugLog("ERROR: Failed to encode camera frame as BMP")
                }
            } else {
                debugLog("ERROR: Failed to create CGImage from CIImage")
            }
        }
    }

    // BMP encoding function (matching other platforms)
    private func encodeBMP(from cgImage: CGImage) -> Data? {
        let width = cgImage.width
        let height = cgImage.height

        // Create RGB data from CGImage
        let bytesPerPixel = 3
        let bytesPerRow = width * bytesPerPixel
        let rowPadding = (4 - (bytesPerRow % 4)) % 4
        let paddedBytesPerRow = bytesPerRow + rowPadding
        let dataSize = paddedBytesPerRow * height
        let fileSize = 54 + dataSize

        // Create BMP header
        var bmpData = Data(count: fileSize)

        bmpData.withUnsafeMutableBytes { bytes in
            let buffer = bytes.bindMemory(to: UInt8.self)

            // BMP File Header
            buffer[0] = 0x42  // 'B'
            buffer[1] = 0x4D  // 'M'

            // File size (little endian)
            buffer[2] = UInt8(fileSize & 0xFF)
            buffer[3] = UInt8((fileSize >> 8) & 0xFF)
            buffer[4] = UInt8((fileSize >> 16) & 0xFF)
            buffer[5] = UInt8((fileSize >> 24) & 0xFF)

            // Reserved fields
            buffer[6] = 0; buffer[7] = 0; buffer[8] = 0; buffer[9] = 0

            // Offset to pixel data
            buffer[10] = 54; buffer[11] = 0; buffer[12] = 0; buffer[13] = 0

            // DIB Header
            buffer[14] = 40; buffer[15] = 0; buffer[16] = 0; buffer[17] = 0  // Header size

            // Width (little endian)
            buffer[18] = UInt8(width & 0xFF)
            buffer[19] = UInt8((width >> 8) & 0xFF)
            buffer[20] = UInt8((width >> 16) & 0xFF)
            buffer[21] = UInt8((width >> 24) & 0xFF)

            // Height (negative for top-down, little endian)
            let negHeight = -height
            buffer[22] = UInt8(negHeight & 0xFF)
            buffer[23] = UInt8((negHeight >> 8) & 0xFF)
            buffer[24] = UInt8((negHeight >> 16) & 0xFF)
            buffer[25] = UInt8((negHeight >> 24) & 0xFF)

            // Planes
            buffer[26] = 1; buffer[27] = 0

            // Bits per pixel
            buffer[28] = 24; buffer[29] = 0

            // Compression and other fields (all zeros)
            for i in 30..<54 {
                buffer[i] = 0
            }
        }

        // Extract RGB data from CGImage
        guard let dataProvider = cgImage.dataProvider,
              let pixelData = dataProvider.data else {
            return nil
        }

        let pixelBytes = CFDataGetBytePtr(pixelData)
        let cgBytesPerPixel = cgImage.bitsPerPixel / 8
        let cgBytesPerRow = cgImage.bytesPerRow

        // Copy pixel data to BMP format (BGR order with padding)
        bmpData.withUnsafeMutableBytes { bytes in
            let buffer = bytes.bindMemory(to: UInt8.self)
            var bmpIndex = 54  // Start after header

            for y in 0..<height {
                for x in 0..<width {
                    let pixelIndex = y * cgBytesPerRow + x * cgBytesPerPixel

                    // Convert from RGB to BGR for BMP format
                    if cgBytesPerPixel >= 3 {
                        buffer[bmpIndex] = pixelBytes![pixelIndex + 2]     // B
                        buffer[bmpIndex + 1] = pixelBytes![pixelIndex + 1] // G
                        buffer[bmpIndex + 2] = pixelBytes![pixelIndex]     // R
                    } else {
                        // Handle grayscale or other formats
                        let gray = pixelBytes![pixelIndex]
                        buffer[bmpIndex] = gray     // B
                        buffer[bmpIndex + 1] = gray // G
                        buffer[bmpIndex + 2] = gray // R
                    }
                    bmpIndex += 3
                }

                // Add row padding
                for _ in 0..<rowPadding {
                    buffer[bmpIndex] = 0
                    bmpIndex += 1
                }
            }
        }

        return bmpData
    }

    // Debug logging method
    func pixelFormatString(_ pixelFormat: OSType) -> String {
        let chars = [
            UInt8((pixelFormat >> 24) & 0xFF),
            UInt8((pixelFormat >> 16) & 0xFF),
            UInt8((pixelFormat >> 8) & 0xFF),
            UInt8(pixelFormat & 0xFF)
        ]
        return String(bytes: chars, encoding: .ascii) ?? "Unknown(\(pixelFormat))"
    }

    func debugLog(_ message: String) {
        #if DEBUG
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        let logMessage = "[\(timestamp)] \(message)"
        debugEventSink?(logMessage)
        #endif
    }
}

// Debug handler for the debug event channel
class UsbVideoDebugHandler: NSObject, FlutterStreamHandler {
    private weak var plugin: UsbVideoCapturePlugin?

    init(plugin: UsbVideoCapturePlugin) {
        self.plugin = plugin
    }

    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        plugin?.debugEventSink = events
        plugin?.debugLog("USB Video Debug channel connected")
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        plugin?.debugEventSink = nil
        return nil
    }
}