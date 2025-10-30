import 'dart:async';

import 'package:flutter/services.dart';
import 'package:nt_helper/domain/video/usb_device_info.dart';
import 'package:nt_helper/services/debug_service.dart';
import 'package:uvccamera/uvccamera.dart';

/// Android-specific implementation using uvccamera package
class AndroidUsbVideoChannel {
  static const methodChannel = MethodChannel('com.example.nt_helper/usb_video');
  static const frameChannel = EventChannel(
    'com.example.nt_helper/usb_video_stream',
  );

  final DebugService _debugService = DebugService();

  UvcCameraController? _controller;

  /// Expose the controller for direct widget access on Android
  UvcCameraController? get cameraController => _controller;
  StreamSubscription<UvcCameraDeviceEvent>? _deviceEventSubscription;
  StreamSubscription? _errorEventSubscription;
  StreamSubscription? _statusEventSubscription;
  StreamController<Uint8List>? _frameStreamController;
  StreamSubscription<dynamic>? _frameSubscription;

  // Store current device info
  UvcCameraDevice? _currentDevice;
  bool _isInitialized = false;

  // Lifecycle and recovery state tracking
  String? _lastConnectedDeviceId;
  bool _isPaused = false;
  int _initializationAttempts = 0;
  bool _isRecovering = false;
  Timer? _recoveryTimer;

  // Recovery configuration
  static const int _maxInitializationAttempts = 3;
  static const Duration _previewInterruptionRecoveryDelay = Duration(
    milliseconds: 500,
  );

  void _debugLog(String message) {
    _debugService.addLocalMessage('[AndroidUsbVideoChannel] $message');
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

    // If we already have a controller for this device, just return the stream
    if (_controller != null && _currentDevice?.name == deviceId) {
      _debugLog('Controller already exists for device, reusing');
      if (_frameStreamController == null || _frameStreamController!.isClosed) {
        _frameStreamController = StreamController<Uint8List>.broadcast();
      }
      return _frameStreamController!.stream;
    }

    // Clean up any existing stream (async, but we don't wait)
    _stopCurrentStream().then((_) {
      // Start the connection process after cleanup
      _connectToDevice(deviceId);
    });

    // Create a new stream controller
    _frameStreamController = StreamController<Uint8List>.broadcast();

    // Return an empty stream - frames will come through the UvcCameraPreview widget
    // The test frames from native plugin are only needed when controller isn't available
    return _frameStreamController!.stream;
  }

  Future<void> _connectToDevice(String deviceId) async {
    try {
      _debugLog(
        'Connecting to device: $deviceId (attempt ${_initializationAttempts + 1}/$_maxInitializationAttempts)',
      );

      // Get the device
      final devices = await UvcCamera.getDevices();
      final device = devices[deviceId];

      if (device == null) {
        _debugLog('Device not found: $deviceId');
        _frameStreamController?.addError('Device not found');

        // Check if we should retry
        if (_initializationAttempts < _maxInitializationAttempts) {
          _initializationAttempts++;
          final backoffMs =
              100 * _initializationAttempts; // 100ms, 200ms, 300ms
          _debugLog('Retrying in ${backoffMs}ms...');
          await Future.delayed(Duration(milliseconds: backoffMs));
          await _connectToDevice(deviceId);
        } else {
          _debugLog('Max initialization attempts reached');
          _frameStreamController?.addError(
            'Device not found after $_maxInitializationAttempts attempts',
          );
          _resetInitializationAttempts();
        }
        return;
      }

      _currentDevice = device;
      _lastConnectedDeviceId = deviceId;

      // Listen for device events
      _deviceEventSubscription = UvcCamera.deviceEventStream.listen((event) {
        _handleDeviceEvent(event);
      });

      // Wait for the device to be connected before creating controller
      // The example shows controller should be created in response to connected event
      _debugLog('Waiting for device connection event...');

      // Store device for later use when connected
      _currentDevice = device;

      // Request device permission to trigger connection (like in the example)
      _debugLog('Requesting device permission to trigger connection...');
      final hasPermission = await UvcCamera.requestDevicePermission(device);
      _debugLog('Device permission result: $hasPermission');

      if (!hasPermission) {
        _debugLog('Device permission denied');
        _frameStreamController?.addError('Device permission denied');
        return;
      }

      // The controller will be created in _handleDeviceEvent when we get the connected event
      // For now, just wait for the connection
    } catch (e, stack) {
      _debugLog('ERROR connecting to device: $e');
      _debugLog('Stack trace: $stack');
      _frameStreamController?.addError('Failed to connect: $e');
    }
  }

  void _resetInitializationAttempts() {
    _initializationAttempts = 0;
  }

  Future<void> _startFrameCapture() async {
    if (_controller == null || !_isInitialized) {
      _debugLog('Cannot start frame capture - controller not initialized');
      return;
    }

    try {
      _debugLog('Frame capture setup for UvcCameraController');

      // Subscribe to camera error and status events (optional - may not be available)
      if (_controller != null) {
        try {
          // Attempt to subscribe to error events
          try {
            _errorEventSubscription = _controller!.cameraErrorEvents.listen((
              error,
            ) {
              _debugLog('Camera error: ${error.error}');
              if (error.error.toString().contains('previewInterrupted')) {
                _debugLog('Preview interrupted - attempting recovery');
                _handlePreviewInterruptionRecovery();
              }
            });
          } catch (e) {
            _debugLog('WARNING: Camera error events not available: $e');
          }

          // Attempt to subscribe to status events
          try {
            _statusEventSubscription = _controller!.cameraStatusEvents.listen((
              status,
            ) {
              _debugLog('Camera status: $status');
            });
          } catch (e) {
            _debugLog('WARNING: Camera status events not available: $e');
          }
        } catch (e) {
          _debugLog('WARNING: Camera event subscription failed: $e');
          // Continue anyway - frame capture doesn't depend on these events
        }
      }

      // When we have a real UvcCameraController, we don't need test frames
      // The UvcCameraPreview widget will handle displaying the camera feed directly
      _debugLog(
        'UvcCameraController ready - frames will be displayed via UvcCameraPreview widget',
      );

      // Don't start native test frame streaming when we have a real controller
      // The frames come directly through the controller's texture
    } catch (e) {
      _debugLog('ERROR during frame capture setup: $e');
      _frameStreamController?.addError('Failed to start frame capture: $e');
    }
  }

  Future<void> _handlePreviewInterruptionRecovery() async {
    if (_isRecovering) {
      _debugLog('Recovery already in progress, skipping duplicate');
      return;
    }

    _isRecovering = true;
    try {
      _debugLog('Starting preview interruption recovery...');

      // Detach controller
      if (_controller != null) {
        try {
          await _controller!.dispose();
        } catch (e) {
          _debugLog('Error disposing controller during recovery: $e');
        }
        _controller = null;
        _isInitialized = false;
      }

      // Wait before reattach
      await Future.delayed(_previewInterruptionRecoveryDelay);

      // Attempt reattach if we still have a device
      if (_lastConnectedDeviceId != null) {
        _debugLog('Attempting to reinitialize after preview interruption');
        await _connectToDevice(_lastConnectedDeviceId!);
      }
    } catch (e) {
      _debugLog('ERROR during preview interruption recovery: $e');
      _frameStreamController?.addError('Preview recovery failed: $e');
    } finally {
      _isRecovering = false;
    }
  }

  void _handleDeviceEvent(UvcCameraDeviceEvent event) {
    _debugLog('Device event: ${event.type} for ${event.device.name}');

    switch (event.type) {
      case UvcCameraDeviceEventType.attached:
        _debugLog('Device attached');
        // Device is physically connected but not yet authorized
        break;

      case UvcCameraDeviceEventType.connected:
        _debugLog('Device connected successfully - creating controller');
        // Device is now authorized and ready - create controller following the example pattern
        if (event.device.name == _currentDevice?.name && _controller == null) {
          _createAndInitializeController(event.device);
        }
        break;

      case UvcCameraDeviceEventType.detached:
        _debugLog('Device detached - stopping stream');
        if (event.device.name == _currentDevice?.name) {
          _stopCurrentStream().then((_) {
            _frameStreamController?.addError('Device disconnected');
          });
        }
        break;

      case UvcCameraDeviceEventType.disconnected:
        _debugLog('Device disconnected');
        if (event.device.name == _currentDevice?.name) {
          _stopCurrentStream().then((_) {
            _frameStreamController?.addError(
              'Device permission or communication lost',
            );
          });
        }
        break;
    }
  }

  Future<void> _createAndInitializeController(UvcCameraDevice device) async {
    try {
      _debugLog('Creating controller for connected device');

      // Create controller for the device
      _controller = UvcCameraController(
        device: device,
        resolutionPreset: UvcCameraResolutionPreset
            .low, // Start with low res for Disting NT (256x64)
      );

      // Initialize the controller (this automatically starts the preview)
      _debugLog('Initializing camera controller...');
      await _controller!.initialize();
      _isInitialized = true;
      _debugLog(
        'Controller initialized successfully - preview should be active',
      );

      // Start capturing frames
      await _startFrameCapture();
    } catch (e) {
      _debugLog('ERROR initializing controller: $e');
      _frameStreamController?.addError('Failed to initialize controller: $e');
      _controller?.dispose();
      _controller = null;
      _isInitialized = false;
    }
  }

  /// Called when app enters background - pause streaming
  Future<void> pauseStreaming() async {
    if (_isPaused) return;
    _isPaused = true;
    _debugLog('App paused - stopping video streaming');
    await _stopCurrentStream();
  }

  /// Called when app returns to foreground - resume streaming
  Future<void> resumeStreaming() async {
    if (!_isPaused) return;
    _isPaused = false;
    _debugLog('App resumed - attempting to restore video streaming');

    // Check if device is still available
    if (_lastConnectedDeviceId != null) {
      try {
        // Create new stream controller
        _frameStreamController = StreamController<Uint8List>.broadcast();
        await _connectToDevice(_lastConnectedDeviceId!);
      } catch (e) {
        _debugLog('ERROR resuming stream: $e');
        _frameStreamController?.addError('Failed to resume video: $e');
      }
    } else {
      _debugLog('No device stored for resume');
    }
  }

  Future<void> _stopCurrentStream() async {
    _debugLog('Stopping current stream...');

    // Cancel all subscriptions first
    _frameSubscription?.cancel();
    _frameSubscription = null;

    _errorEventSubscription?.cancel();
    _errorEventSubscription = null;

    _statusEventSubscription?.cancel();
    _statusEventSubscription = null;

    // Don't cancel device event subscription - we want to keep listening for reconnections
    // _deviceEventSubscription?.cancel();
    // _deviceEventSubscription = null;

    // Dispose controller
    if (_controller != null) {
      try {
        // Disposing controller will stop preview automatically
        _debugLog('Disposing camera controller...');
        _controller!.dispose();
      } catch (e) {
        _debugLog('ERROR disposing controller: $e');
      }
      _controller = null;
    }

    // Reset state but keep device info for reconnection
    _isInitialized = false;
    // Keep _currentDevice for potential reconnection
    _resetInitializationAttempts();
  }

  Future<void> stopVideoStream() async {
    _debugLog('Stopping video stream');

    await _stopCurrentStream();

    // Close frame stream controller
    try {
      await _frameStreamController?.close();
    } catch (e) {
      _debugLog('ERROR closing frame stream controller: $e');
    }
    _frameStreamController = null;

    // Reset the device tracking so it can be reinitialized
    _lastConnectedDeviceId = null;
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

  /// Comprehensive cleanup on disposal
  Future<void> dispose() async {
    _debugLog('Disposing AndroidUsbVideoChannel');

    // Stop recovery timer
    _recoveryTimer?.cancel();
    _recoveryTimer = null;

    // Stop all streaming
    await stopVideoStream();

    // Cancel device event subscription when disposing completely
    _deviceEventSubscription?.cancel();
    _deviceEventSubscription = null;

    // Clear all state
    _currentDevice = null;
    _lastConnectedDeviceId = null;
    _isPaused = false;
    _isRecovering = false;
    _resetInitializationAttempts();

    _debugLog('AndroidUsbVideoChannel disposed completely');
  }
}
