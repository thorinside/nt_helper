import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:nt_helper/domain/video/usb_device_info.dart';
import 'package:nt_helper/services/debug_service.dart';
import 'package:uvccamera/uvccamera.dart';

/// Android-specific implementation using uvccamera package
class AndroidUsbVideoChannel {
  final DebugService _debugService = DebugService();

  UvcCameraController? _controller;
  StreamSubscription<UvcCameraDeviceEvent>? _deviceEventSubscription;
  StreamSubscription? _errorEventSubscription;
  StreamSubscription? _statusEventSubscription;
  StreamController<Uint8List>? _frameStreamController;
  StreamSubscription? _frameSubscription;

  // Store current device info
  UvcCameraDevice? _currentDevice;
  bool _isInitialized = false;

  void _debugLog(String message) {
    _debugService.addLocalMessage('[AndroidUsbVideoChannel] $message');
    debugPrint('[AndroidUsbVideoChannel] $message');
  }

  Future<List<UsbDeviceInfo>> listUsbCameras() async {
    try {
      _debugLog('Listing USB cameras using uvccamera...');

      // Check if UVC is supported on this device
      final isSupported = await UvcCamera.isSupported();
      if (!isSupported) {
        _debugLog('UVC camera not supported on this device');
        return [];
      }

      // Get available UVC devices
      final devices = await UvcCamera.getDevices();
      _debugLog('Found ${devices.length} UVC devices');

      // Convert to our UsbDeviceInfo format
      return devices.values.map((device) {
        _debugLog(
          'Device: ${device.name}, VID: ${device.vendorId}, PID: ${device.productId}',
        );
        return UsbDeviceInfo(
          deviceId: device.name, // Use device name as ID
          productName:
              device.name, // UvcCameraDevice doesn't have productName, use name
          vendorId: device.vendorId,
          productId: device.productId,
          isDistingNT: device.vendorId == 0x16C0, // Expert Sleepers vendor ID
        );
      }).toList();
    } catch (e, stack) {
      _debugLog('ERROR listing USB cameras: $e');
      _debugLog('Stack trace: $stack');
      return [];
    }
  }

  Future<bool> requestUsbPermission(String deviceId) async {
    try {
      _debugLog('Requesting USB permission for device: $deviceId');

      // With uvccamera, permissions are handled when connecting to the device
      // We'll return true here and handle actual permission during connection
      final devices = await UvcCamera.getDevices();
      final hasDevice = devices.containsKey(deviceId);

      if (hasDevice) {
        _debugLog('Device found, permission will be requested on connection');
        return true;
      } else {
        _debugLog('Device not found');
        return false;
      }
    } catch (e) {
      _debugLog('ERROR requesting permission: $e');
      return false;
    }
  }

  Stream<Uint8List> startVideoStream(String deviceId) {
    _debugLog('Starting video stream for device: $deviceId');

    // Clean up any existing stream
    _stopCurrentStream();

    // Create a new stream controller
    _frameStreamController = StreamController<Uint8List>.broadcast();

    // Start the connection process
    _connectToDevice(deviceId);

    return _frameStreamController!.stream;
  }

  Future<void> _connectToDevice(String deviceId) async {
    try {
      _debugLog('Connecting to device: $deviceId');

      // Get the device
      final devices = await UvcCamera.getDevices();
      final device = devices[deviceId];

      if (device == null) {
        _debugLog('Device not found: $deviceId');
        _frameStreamController?.addError('Device not found');
        return;
      }

      _currentDevice = device;

      // Listen for device events
      _deviceEventSubscription = UvcCamera.deviceEventStream.listen((event) {
        _handleDeviceEvent(event);
      });

      // Create controller for the device
      _controller = UvcCameraController(
        device: device,
        resolutionPreset: UvcCameraResolutionPreset
            .low, // Start with low res for Disting NT (256x64)
      );

      // Initialize the controller
      _debugLog('Initializing camera controller...');
      await _controller!.initialize();
      _isInitialized = true;
      _debugLog('Controller initialized successfully');

      // Start capturing frames
      await _startFrameCapture();
    } catch (e, stack) {
      _debugLog('ERROR connecting to device: $e');
      _debugLog('Stack trace: $stack');
      _frameStreamController?.addError('Failed to connect: $e');
    }
  }

  Future<void> _startFrameCapture() async {
    if (_controller == null || !_isInitialized) {
      _debugLog('Cannot start frame capture - controller not initialized');
      return;
    }

    try {
      _debugLog('Starting frame capture...');

      // Subscribe to camera error events
      _errorEventSubscription = _controller!.cameraErrorEvents.listen((error) {
        _debugLog('Camera error: ${error.error}');
        // Check for preview interruption error type
        if (error.error.toString().contains('previewInterrupted')) {
          _debugLog('Preview interrupted - attempting recovery');
          // Preview interruption requires disconnection and reconnection
          // This will trigger device events that we handle in _handleDeviceEvent
        }
      });

      // Subscribe to camera status events for state tracking
      _statusEventSubscription = _controller!.cameraStatusEvents.listen((status) {
        _debugLog('Camera status: $status');
      });

      // Start generating frames. This validates the streaming pipeline.
      // In production, actual frame data from the uvccamera package would be consumed here.
      // The uvccamera API provides frame callbacks via the controller's frame stream.
      _generateTestFrames();
    } catch (e) {
      _debugLog('ERROR starting frame capture: $e');
      _frameStreamController?.addError('Failed to start frame capture: $e');
    }
  }

  void _generateTestFrames() {
    // Generate test frames at 15 FPS for testing the pipeline
    // This will be replaced with actual frame data from the camera
    Timer.periodic(const Duration(milliseconds: 67), (timer) {
      if (_frameStreamController == null || _frameStreamController!.isClosed) {
        timer.cancel();
        return;
      }

      // Create a test pattern (256x64 for Disting NT)
      final width = 256;
      final height = 64;
      final frameData = Uint8List(width * height * 3); // RGB format

      // Fill with a simple pattern
      for (int i = 0; i < frameData.length; i += 3) {
        frameData[i] = (DateTime.now().millisecondsSinceEpoch ~/ 10) % 255; // R
        frameData[i + 1] = (i ~/ 3) % 255; // G
        frameData[i + 2] = 128; // B
      }

      _debugLog('Sending test frame (${frameData.length} bytes)');
      _frameStreamController?.add(frameData);
    });
  }

  void _handleDeviceEvent(UvcCameraDeviceEvent event) {
    _debugLog('Device event: ${event.type} for ${event.device.name}');

    if (event.device.name != _currentDevice?.name) {
      return; // Not our device
    }

    switch (event.type) {
      case UvcCameraDeviceEventType.attached:
        _debugLog('Device attached');
        break;
      case UvcCameraDeviceEventType.detached:
        _debugLog('Device detached - stopping stream');
        _stopCurrentStream();
        _frameStreamController?.addError('Device disconnected');
        break;
      case UvcCameraDeviceEventType.connected:
        _debugLog('Device connected successfully');
        break;
      case UvcCameraDeviceEventType.disconnected:
        _debugLog('Device disconnected');
        _stopCurrentStream();
        break;
    }
  }

  void _stopCurrentStream() {
    _debugLog('Stopping current stream...');

    _frameSubscription?.cancel();
    _frameSubscription = null;

    _errorEventSubscription?.cancel();
    _errorEventSubscription = null;

    _statusEventSubscription?.cancel();
    _statusEventSubscription = null;

    if (_controller != null) {
      _controller!.dispose();
      _controller = null;
    }

    _deviceEventSubscription?.cancel();
    _deviceEventSubscription = null;

    _isInitialized = false;
    _currentDevice = null;
  }

  Future<void> stopVideoStream() async {
    _debugLog('Stopping video stream');

    _stopCurrentStream();

    await _frameStreamController?.close();
    _frameStreamController = null;
  }

  Future<bool> isSupported() async {
    try {
      final supported = await UvcCamera.isSupported();
      _debugLog('UVC camera support: $supported');
      return supported;
    } catch (e) {
      _debugLog('ERROR checking support: $e');
      return false;
    }
  }

  void dispose() {
    _debugLog('Disposing AndroidUsbVideoChannel');
    stopVideoStream();
  }
}
