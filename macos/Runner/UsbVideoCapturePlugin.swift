import Cocoa
import FlutterMacOS
import AVFoundation

public class UsbVideoCapturePlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
    private var eventSink: FlutterEventSink?
    var debugEventSink: FlutterEventSink?
    private var captureSession: AVCaptureSession?
    private var videoOutput: AVCaptureVideoDataOutput?
    private let sessionQueue = DispatchQueue(label: "com.example.nt_helper.videoCaptureQueue")
    private let ciContext = CIContext(options: [.workingColorSpace: NSNull()])
    private let processingQueue = DispatchQueue(label: "com.example.nt_helper.frameProcessingQueue", qos: .userInitiated)

    // Frame rate limiting
    private var nextFrameTime: TimeInterval = 0
    private static let TARGET_FPS = 30.0
    private static let FRAME_INTERVAL = 1.0 / TARGET_FPS  // ~0.033 seconds

    private static let DISTING_VENDOR_ID = 0x16C0  // Expert Sleepers vendor ID

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "com.example.nt_helper/usb_video", binaryMessenger: registrar.messenger)
        let eventChannel = FlutterEventChannel(name: "com.example.nt_helper/usb_video_stream", binaryMessenger: registrar.messenger)
        let debugChannel = FlutterEventChannel(name: "com.example.nt_helper/usb_video_debug", binaryMessenger: registrar.messenger)

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
            // macOS handles camera permissions via Info.plist and system prompts
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
            // macOS supports external cameras
            result(true)
            
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    private func listExternalCameras(result: @escaping FlutterResult) {
        // Use discovery session instead of deprecated devices(for:)
        let allDevicesSession = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.externalUnknown, .builtInWideAngleCamera],
            mediaType: .video,
            position: .unspecified
        )
        let allDevices = allDevicesSession.devices
        print("[UsbVideoCapturePlugin] Found \(allDevices.count) total video devices:")
        for device in allDevices {
            print("[UsbVideoCapturePlugin] Device: \(device.localizedName) (ID: \(device.uniqueID), Model: \(device.modelID))")
        }
        
        // Try to find external/USB cameras
        let discoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.externalUnknown, .builtInWideAngleCamera],  // Include more device types
            mediaType: .video,
            position: .unspecified
        )
        
        var devices = discoverySession.devices.map { device in
            // Check if this might be the Disting NT based on name
            let isDistingNT = device.localizedName.lowercased().contains("disting") ||
                             device.localizedName.lowercased().contains("nt") ||
                             device.modelID.lowercased().contains("disting")
            
            print("[UsbVideoCapturePlugin] Adding device: \(device.localizedName), isDistingNT: \(isDistingNT)")
            
            return [
                "deviceId": device.uniqueID,
                "productName": device.localizedName,
                "vendorId": 0,  // macOS doesn't provide vendor ID via AVFoundation
                "productId": 0,  // macOS doesn't provide product ID via AVFoundation
                "isDistingNT": isDistingNT
            ]
        }
        
        // If no devices found with discovery session, try the old method
        if devices.isEmpty {
            print("[UsbVideoCapturePlugin] No devices from discovery session, trying all video devices")
            devices = allDevices.map { device in
                let isDistingNT = device.localizedName.lowercased().contains("disting") ||
                                 device.localizedName.lowercased().contains("nt")
                return [
                    "deviceId": device.uniqueID,
                    "productName": device.localizedName,
                    "vendorId": 0,
                    "productId": 0,
                    "isDistingNT": isDistingNT
                ]
            }
        }
        
        print("[UsbVideoCapturePlugin] Returning \(devices.count) devices")
        result(devices)
    }
    
    private func startVideoStream(deviceId: String, result: @escaping FlutterResult) {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            
            // Stop any existing session
            self.stopVideoStream()
            
            // Create new capture session
            self.captureSession = AVCaptureSession()
            guard let captureSession = self.captureSession else {
                DispatchQueue.main.async {
                    result(FlutterError(code: "SESSION_ERROR", message: "Failed to create capture session", details: nil))
                }
                return
            }
            
            // Find the device
            guard let device = AVCaptureDevice(uniqueID: deviceId) else {
                DispatchQueue.main.async {
                    result(FlutterError(code: "DEVICE_NOT_FOUND", message: "Camera device not found", details: nil))
                }
                return
            }
            
            do {
                print("[UsbVideoCapturePlugin] Creating input for device: \(device.localizedName)")
                print("[UsbVideoCapturePlugin] Device formats available: \(device.formats.count)")
                
                // Log available formats
                for (index, format) in device.formats.enumerated() {
                    let dimensions = CMVideoFormatDescriptionGetDimensions(format.formatDescription)
                    print("[UsbVideoCapturePlugin] Format \(index): \(dimensions.width)x\(dimensions.height)")
                }
                
                // Create input
                let input = try AVCaptureDeviceInput(device: device)
                
                // Create output
                self.videoOutput = AVCaptureVideoDataOutput()
                
                // Use device default format for maximum UVC compatibility
                print("[UsbVideoCapturePlugin] Using device default format for UVC compatibility")
                // Don't set any videoSettings - let device use its natural format
                self.videoOutput?.videoSettings = nil
                
                // Log available video settings
                if let availableFormats = self.videoOutput?.availableVideoPixelFormatTypes {
                    print("[UsbVideoCapturePlugin] Available pixel formats: \(availableFormats)")
                }
                
                // Enable frame dropping to prevent buffer overflow
                self.videoOutput?.alwaysDiscardsLateVideoFrames = true
                
                // Set the delegate on a high-priority queue (not sessionQueue)
                self.videoOutput?.setSampleBufferDelegate(self, queue: DispatchQueue.global(qos: .userInitiated))
                print("[UsbVideoCapturePlugin] Created video output with delegate and settings")
                
                // Configure session for UVC compatibility
                captureSession.beginConfiguration()
                
                // Try no preset first for maximum compatibility
                print("[UsbVideoCapturePlugin] Using no preset for UVC compatibility")
                // Don't set any session preset - let the device negotiate its own format
                
                if captureSession.canAddInput(input) {
                    captureSession.addInput(input)
                    print("[UsbVideoCapturePlugin] Added input to session")
                } else {
                    print("[UsbVideoCapturePlugin] ERROR: Cannot add input to session")
                }
                
                if let output = self.videoOutput, captureSession.canAddOutput(output) {
                    captureSession.addOutput(output)
                    print("[UsbVideoCapturePlugin] Added output to session")
                    
                    // Log the actual connection
                    if let connection = output.connection(with: .video) {
                        print("[UsbVideoCapturePlugin] Video connection established")
                        print("[UsbVideoCapturePlugin] Connection is active: \(connection.isActive)")
                        print("[UsbVideoCapturePlugin] Connection is enabled: \(connection.isEnabled)")
                    } else {
                        print("[UsbVideoCapturePlugin] WARNING: No video connection found")
                    }
                } else {
                    print("[UsbVideoCapturePlugin] ERROR: Cannot add output to session")
                }
                
                captureSession.commitConfiguration()
                print("[UsbVideoCapturePlugin] Session configuration committed")
                
                // Check if event sink is available before starting
                print("[UsbVideoCapturePlugin] Event sink available: \(self.eventSink != nil)")
                
                // Add a small delay before starting - some UVC cameras need this
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    // Start capture
                    captureSession.startRunning()
                    print("[UsbVideoCapturePlugin] Session started running, isRunning: \(captureSession.isRunning)")
                }
                
                // Set up session runtime error handling
                NotificationCenter.default.addObserver(
                    forName: .AVCaptureSessionRuntimeError,
                    object: captureSession,
                    queue: .main
                ) { notification in
                    if let error = notification.userInfo?[AVCaptureSessionErrorKey] as? AVError {
                        print("[UsbVideoCapturePlugin] Runtime error: \(error.localizedDescription)")
                        print("[UsbVideoCapturePlugin] Error code: \(error.code.rawValue)")
                    } else {
                        print("[UsbVideoCapturePlugin] Runtime error without details: \(notification)")
                    }
                }
                
                // Set up session interruption handling
                NotificationCenter.default.addObserver(
                    forName: .AVCaptureSessionWasInterrupted,
                    object: captureSession,
                    queue: .main
                ) { notification in
                    print("[UsbVideoCapturePlugin] Session was interrupted")
                }
                
                NotificationCenter.default.addObserver(
                    forName: .AVCaptureSessionInterruptionEnded,
                    object: captureSession,
                    queue: .main
                ) { notification in
                    print("[UsbVideoCapturePlugin] Session interruption ended")
                }
                
                // Monitor session running state changes
                NotificationCenter.default.addObserver(
                    forName: .AVCaptureSessionDidStartRunning,
                    object: captureSession,
                    queue: .main
                ) { notification in
                    print("[UsbVideoCapturePlugin] Session did start running")
                }
                
                NotificationCenter.default.addObserver(
                    forName: .AVCaptureSessionDidStopRunning,
                    object: captureSession,
                    queue: .main
                ) { notification in
                    print("[UsbVideoCapturePlugin] Session did stop running")
                }
                
                // Double check the session is actually running
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    print("[UsbVideoCapturePlugin] Session still running after 0.5s: \(captureSession.isRunning)")
                    if !captureSession.isRunning {
                        print("[UsbVideoCapturePlugin] Session stopped unexpectedly!")
                    }
                }
                
                // Check for frames after 1 second
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    print("[UsbVideoCapturePlugin] Session running after 1.0s: \(captureSession.isRunning)")
                }
                
                // Add periodic session monitoring
                Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { timer in
                    print("[UsbVideoCapturePlugin] Timer check - Session running: \(captureSession.isRunning)")
                    if !captureSession.isRunning {
                        timer.invalidate()
                    }
                }
                
                DispatchQueue.main.async {
                    result(true)
                }
            } catch {
                DispatchQueue.main.async {
                    result(FlutterError(code: "CAPTURE_ERROR", message: error.localizedDescription, details: nil))
                }
            }
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
        print("[UsbVideoCapturePlugin] Event sink set up, arguments: \(String(describing: arguments))")
        self.eventSink = events
        return nil
    }
    
    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        print("[UsbVideoCapturePlugin] Event sink cancelled")
        self.eventSink = nil
        return nil
    }

    // MARK: - Debug Logging

    func debugLog(_ message: String) {
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        let logMessage = "[\(timestamp)] [NATIVE] \(message)"
        debugEventSink?(logMessage)
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

extension UsbVideoCapturePlugin: AVCaptureVideoDataOutputSampleBufferDelegate {
    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // Throttle frame rate to TARGET_FPS
        let currentTime = CACurrentMediaTime()

        // Check if enough time has passed since we last sent a frame
        guard currentTime >= nextFrameTime else {
            return  // Skip this frame to maintain target FPS
        }

        // Schedule next frame (add interval to maintain consistent rate)
        nextFrameTime = currentTime + UsbVideoCapturePlugin.FRAME_INTERVAL

        // Convert sample buffer to BMP data (matching iOS implementation)
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }

        autoreleasepool {
            let ciImage = CIImage(cvPixelBuffer: imageBuffer)

            if let cgImage = ciContext.createCGImage(ciImage, from: ciImage.extent) {
                // Convert CGImage to RGB data then encode as BMP
                if let bmpData = encodeBMP(from: cgImage) {
                    // Send BMP data to Flutter on the main thread
                    DispatchQueue.main.async {
                        self.eventSink?(FlutterStandardTypedData(bytes: bmpData))
                    }
                }
            }
        }
    }

    // BMP encoding function (matching iOS implementation)
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
}

// MARK: - Debug Stream Handler

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