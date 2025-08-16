import Flutter
import UIKit
import AVFoundation

public class UsbVideoCapturePlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
    private var eventSink: FlutterEventSink?
    private var captureSession: AVCaptureSession?
    private var videoOutput: AVCaptureVideoDataOutput?
    private let sessionQueue = DispatchQueue(label: "com.example.nt_helper.videoCaptureQueue")
    private let ciContext = CIContext(options: [.workingColorSpace: NSNull()])
    
    private static let DISTING_VENDOR_ID = 0x16C0  // Expert Sleepers vendor ID
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "com.example.nt_helper/usb_video", binaryMessenger: registrar.messenger())
        let eventChannel = FlutterEventChannel(name: "com.example.nt_helper/usb_video_stream", binaryMessenger: registrar.messenger())
        
        let instance = UsbVideoCapturePlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
        eventChannel.setStreamHandler(instance)
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
            let discoverySession = AVCaptureDevice.DiscoverySession(
                deviceTypes: [.external],  // External USB cameras
                mediaType: .video,
                position: .unspecified
            )
            
            let devices = discoverySession.devices.map { device in
                return [
                    "deviceId": device.uniqueID,
                    "productName": device.localizedName,
                    "vendorId": 0,  // iOS doesn't provide vendor ID
                    "productId": 0,  // iOS doesn't provide product ID
                    "isDistingNT": false  // Cannot determine without vendor ID
                ]
            }
            
            result(devices)
        } else {
            // iOS versions before 17.0 don't support external cameras
            result([])
        }
    }
    
    private func startVideoStream(deviceId: String, result: @escaping FlutterResult) {
        if #available(iOS 17.0, *) {
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
                    // Create input
                    let input = try AVCaptureDeviceInput(device: device)
                    
                    // Create output
                    self.videoOutput = AVCaptureVideoDataOutput()
                    // Set the delegate on a high-priority queue (not sessionQueue)
                    self.videoOutput?.setSampleBufferDelegate(self, queue: DispatchQueue.global(qos: .userInitiated))
                    
                    // Configure session
                    captureSession.beginConfiguration()
                    
                    if captureSession.canAddInput(input) {
                        captureSession.addInput(input)
                    }
                    
                    if let output = self.videoOutput, captureSession.canAddOutput(output) {
                        captureSession.addOutput(output)
                    }
                    
                    captureSession.commitConfiguration()
                    
                    // Start capture
                    captureSession.startRunning()
                    
                    DispatchQueue.main.async {
                        result(true)
                    }
                } catch {
                    DispatchQueue.main.async {
                        result(FlutterError(code: "CAPTURE_ERROR", message: error.localizedDescription, details: nil))
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
        self.eventSink = events
        return nil
    }
    
    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
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
                let uiImage = UIImage(cgImage: cgImage)
                if let pngData = uiImage.pngData() {
                    // Send directly to Flutter (no main queue dispatch)
                    self.eventSink?(FlutterStandardTypedData(bytes: pngData))
                }
            }
        }
    }
}