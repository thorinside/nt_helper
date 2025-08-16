import Cocoa
import FlutterMacOS
import AVFoundation

public class UsbVideoCapturePlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
    private var eventSink: FlutterEventSink?
    private var captureSession: AVCaptureSession?
    private var videoOutput: AVCaptureVideoDataOutput?
    private let sessionQueue = DispatchQueue(label: "com.example.nt_helper.videoCaptureQueue")
    private let ciContext = CIContext(options: [.workingColorSpace: NSNull()])
    private let processingQueue = DispatchQueue(label: "com.example.nt_helper.frameProcessingQueue", qos: .userInitiated)
    
    private static let DISTING_VENDOR_ID = 0x16C0  // Expert Sleepers vendor ID
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "com.example.nt_helper/usb_video", binaryMessenger: registrar.messenger)
        let eventChannel = FlutterEventChannel(name: "com.example.nt_helper/usb_video_stream", binaryMessenger: registrar.messenger)
        
        let instance = UsbVideoCapturePlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
        eventChannel.setStreamHandler(instance)
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
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

extension UsbVideoCapturePlugin: AVCaptureVideoDataOutputSampleBufferDelegate {
    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // Convert sample buffer to PNG quickly and efficiently
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { 
            return 
        }
        
        autoreleasepool {
            let ciImage = CIImage(cvPixelBuffer: imageBuffer)
            
            if let cgImage = ciContext.createCGImage(ciImage, from: ciImage.extent) {
                let bitmapRep = NSBitmapImageRep(cgImage: cgImage)
                bitmapRep.size = NSSize(width: CGFloat(cgImage.width), height: CGFloat(cgImage.height))
                
                if let pngData = bitmapRep.representation(using: .png, properties: [
                    .compressionFactor: 0.0
                ]) {
                    // Send directly to Flutter (no main queue dispatch)
                    self.eventSink?(FlutterStandardTypedData(bytes: pngData))
                }
            }
        }
    }
}