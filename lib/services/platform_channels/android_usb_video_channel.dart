import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:nt_helper/domain/video/usb_device_info.dart';
import 'package:nt_helper/services/debug_service.dart';
import 'package:uvccamera/uvccamera.dart';

/// Android-specific implementation using uvccamera package
class AndroidUsbVideoChannel {
  static const methodChannel = MethodChannel('com.example.nt_helper/usb_video');
  static const frameChannel = EventChannel('com.example.nt_helper/usb_video_stream');

  final DebugService _debugService = DebugService();

  UvcCameraController? _controller;
  StreamSubscription<UvcCameraDeviceEvent>? _deviceEventSubscription;
  StreamSubscription? _errorEventSubscription;
  StreamSubscription? _statusEventSubscription;
  StreamController<Uint8List>? _frameStreamController;
  StreamSubscription<dynamic>? _frameSubscription;

  // Store current device info
  UvcCameraDevice? _currentDevice;
  bool _isInitialized = false;
  int _frameCount = 0;

  // Lifecycle and recovery state tracking
  String? _lastConnectedDeviceId;
  bool _isPaused = false;
  int _initializationAttempts = 0;
  bool _isRecovering = false;
  Timer? _recoveryTimer;

  // Recovery configuration
  static const int _maxInitializationAttempts = 3;
  static const Duration _previewInterruptionRecoveryDelay = Duration(milliseconds: 500);

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
      _debugLog('Connecting to device: $deviceId (attempt ${_initializationAttempts + 1}/$_maxInitializationAttempts)');

      // Get the device
      final devices = await UvcCamera.getDevices();
      final device = devices[deviceId];

      if (device == null) {
        _debugLog('Device not found: $deviceId');
        _frameStreamController?.addError('Device not found');

        // Check if we should retry
        if (_initializationAttempts < _maxInitializationAttempts) {
          _initializationAttempts++;
          final backoffMs = 100 * _initializationAttempts; // 100ms, 200ms, 300ms
          _debugLog('Retrying in ${backoffMs}ms...');
          await Future.delayed(Duration(milliseconds: backoffMs));
          await _connectToDevice(deviceId);
        } else {
          _debugLog('Max initialization attempts reached');
          _frameStreamController?.addError('Device not found after $_maxInitializationAttempts attempts');
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

      // Create controller for the device
      _controller = UvcCameraController(
        device: device,
        resolutionPreset: UvcCameraResolutionPreset
            .low, // Start with low res for Disting NT (256x64)
      );

      // Initialize the controller with retry on failure
      _debugLog('Initializing camera controller...');
      try {
        await _controller!.initialize();
        _isInitialized = true;
        _debugLog('Controller initialized successfully');
        _resetInitializationAttempts(); // Clear retry counter on success

        // Start capturing frames
        await _startFrameCapture();
      } catch (initError) {
        _debugLog('Controller initialization failed: $initError');

        // Check if we should retry
        if (_initializationAttempts < _maxInitializationAttempts) {
          _initializationAttempts++;
          final backoffMs = 100 * _initializationAttempts;
          _debugLog('Retrying initialization in ${backoffMs}ms...');
          _controller?.dispose();
          _controller = null;
          _isInitialized = false;

          await Future.delayed(Duration(milliseconds: backoffMs));
          await _connectToDevice(deviceId);
        } else {
          _debugLog('Max initialization attempts reached');
          _frameStreamController?.addError('Failed to initialize controller after $_maxInitializationAttempts attempts: $initError');
          _resetInitializationAttempts();
        }
      }
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
      _debugLog('Starting frame capture...');

      // Subscribe to camera error events
      if (_controller != null) {
        _errorEventSubscription = _controller!.cameraErrorEvents.listen((error) {
          _debugLog('Camera error: ${error.error}');
          // Check for preview interruption error type
          if (error.error.toString().contains('previewInterrupted')) {
            _debugLog('Preview interrupted - attempting recovery');
            _handlePreviewInterruptionRecovery();
          }
        });

        // Subscribe to camera status events for state tracking
        _statusEventSubscription = _controller!.cameraStatusEvents.listen((status) {
          _debugLog('Camera status: $status');
        });
      } else {
        _debugLog('WARNING: Controller became null during frame capture setup');
        return;
      }

      // Subscribe to EventChannel for actual frame data from native side
      // The native platform channel intercepts frames from UVCCamera
      _frameSubscription = frameChannel.receiveBroadcastStream().listen(
            (dynamic frameData) {
              if (_frameStreamController == null || _frameStreamController!.isClosed) {
                return;
              }

              if (frameData is Uint8List) {
                _frameCount++;
                if (_frameCount % 15 == 0) {
                  _debugLog('Streaming frame #$_frameCount (${frameData.length} bytes)');
                }
                _frameStreamController?.add(frameData);
              } else {
                _debugLog('WARNING: Received non-Uint8List frame data');
              }
            },
            onError: (error) {
              _debugLog('ERROR in frame stream: $error');
              _frameStreamController?.addError('Frame streaming error: $error');
            },
          );

      _debugLog('Frame capture started successfully');
    } catch (e) {
      _debugLog('ERROR starting frame capture: $e');
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
        // Check if this is our previously connected device
        if (_lastConnectedDeviceId == event.device.name && !_isInitialized) {
          _debugLog('Previously connected device reattached, attempting auto-reconnect');
          _handleDeviceReconnect(event.device.name);
        }
        break;

      case UvcCameraDeviceEventType.detached:
        _debugLog('Device detached - stopping stream');
        if (event.device.name == _currentDevice?.name) {
          _stopCurrentStream();
          _frameStreamController?.addError('Device disconnected');
        }
        break;

      case UvcCameraDeviceEventType.connected:
        _debugLog('Device connected successfully');
        break;

      case UvcCameraDeviceEventType.disconnected:
        _debugLog('Device disconnected');
        if (event.device.name == _currentDevice?.name) {
          _stopCurrentStream();
          _frameStreamController?.addError('Device permission or communication lost');
        }
        break;
    }
  }

  Future<void> _handleDeviceReconnect(String deviceId) async {
    if (_isRecovering) {
      _debugLog('Recovery already in progress, skipping reconnect');
      return;
    }

    _isRecovering = true;
    try {
      _debugLog('Handling device reconnection for $deviceId');
      _stopCurrentStream();

      // Attempt to reconnect
      await Future.delayed(const Duration(milliseconds: 100)); // Let USB enumerate
      await _connectToDevice(deviceId);
    } catch (e) {
      _debugLog('ERROR during device reconnection: $e');
      _frameStreamController?.addError('Reconnection failed: $e');
    } finally {
      _isRecovering = false;
    }
  }

  /// Called when app enters background - pause streaming
  Future<void> pauseStreaming() async {
    if (_isPaused) return;
    _isPaused = true;
    _debugLog('App paused - stopping video streaming');
    _stopCurrentStream();
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

  void _stopCurrentStream() {
    _debugLog('Stopping current stream...');

    // Cancel all subscriptions
    _frameSubscription?.cancel();
    _frameSubscription = null;

    _errorEventSubscription?.cancel();
    _errorEventSubscription = null;

    _statusEventSubscription?.cancel();
    _statusEventSubscription = null;

    _deviceEventSubscription?.cancel();
    _deviceEventSubscription = null;

    // Dispose controller
    if (_controller != null) {
      try {
        _controller!.dispose();
      } catch (e) {
        _debugLog('ERROR disposing controller: $e');
      }
      _controller = null;
    }

    // Reset state
    _isInitialized = false;
    _currentDevice = null;
    _resetInitializationAttempts();
  }

  Future<void> stopVideoStream() async {
    _debugLog('Stopping video stream');

    _stopCurrentStream();

    // Close frame stream controller
    try {
      await _frameStreamController?.close();
    } catch (e) {
      _debugLog('ERROR closing frame stream controller: $e');
    }
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

  /// Comprehensive cleanup on disposal
  Future<void> dispose() async {
    _debugLog('Disposing AndroidUsbVideoChannel');

    // Stop recovery timer
    _recoveryTimer?.cancel();
    _recoveryTimer = null;

    // Stop all streaming
    await stopVideoStream();

    // Clear all state
    _lastConnectedDeviceId = null;
    _isPaused = false;
    _isRecovering = false;
    _resetInitializationAttempts();

    _debugLog('AndroidUsbVideoChannel disposed completely');
  }
}
