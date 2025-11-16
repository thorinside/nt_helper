import 'dart:async';

import 'package:flutter/services.dart';
import 'package:nt_helper/domain/video/usb_device_info.dart';
import 'package:nt_helper/services/debug_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uvccamera/uvccamera.dart';

/// Android-specific implementation using uvccamera package
class AndroidUsbVideoChannel {
  static const methodChannel = MethodChannel('com.example.nt_helper/usb_video');
  static const frameChannel = EventChannel(
    'com.example.nt_helper/usb_video_stream',
  );
  // Lazy-initialize to avoid creating EventChannel on non-Android platforms
  static EventChannel? _uvccameraFrameChannel;
  static EventChannel get uvccameraFrameChannel {
    _uvccameraFrameChannel ??= const EventChannel('uvccamera/frames');
    return _uvccameraFrameChannel!;
  }

  final DebugService _debugService = DebugService();

  int? _cameraId; // Store camera ID from openCamera
  bool _isOpeningCamera = false; // Flag to prevent concurrent opens
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
  Timer? _recoveryTimer;

  // Recovery configuration
  static const int _maxInitializationAttempts = 3;

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
          isDistingNT: device.vendorId == 0x3773, // Expert Sleepers vendor ID (14195 decimal)
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

    // If we already have a camera open for this device, just return the stream
    if (_cameraId != null && _currentDevice?.name == deviceId) {
      _debugLog('Camera already open for device (cameraId: $_cameraId), reusing stream');
      if (_frameStreamController == null || _frameStreamController!.isClosed) {
        _frameStreamController = StreamController<Uint8List>.broadcast();
      }
      return _frameStreamController!.stream;
    }

    // Clean up any existing stream (async, with timeout)
    _stopCurrentStream().timeout(
      const Duration(seconds: 2),
      onTimeout: () {
        _debugLog('Stop stream timed out, proceeding anyway');
      },
    ).then((_) {
      // Start the connection process after cleanup
      _connectToDevice(deviceId);
    }).catchError((error) {
      _debugLog('ERROR during stream cleanup: $error, proceeding anyway');
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

      // Request camera permission (required for USB video class devices on Android)
      _debugLog('Requesting camera permission for USB video access...');
      final cameraPermissionStatus = await Permission.camera.request();
      _debugLog('Camera permission result: $cameraPermissionStatus');

      if (!cameraPermissionStatus.isGranted) {
        _debugLog('Camera permission denied - required for USB video devices');
        _frameStreamController?.addError(
          'Camera permission required for USB video. Please grant permission in settings.',
        );
        return;
      }

      // Request device permission
      _debugLog('Requesting device permission...');
      final hasPermission = await UvcCamera.requestDevicePermission(device);
      _debugLog('Device permission result: $hasPermission');

      if (!hasPermission) {
        _debugLog('Device permission denied');
        _frameStreamController?.addError('Device permission denied');
        return;
      }

      // Permission granted - open camera immediately if not already opening/open
      // On first open: permission dialog triggers connected event, but we open here too (guarded)
      // On subsequent opens: permission already granted, no event fires, so we must open here
      if (_cameraId == null && !_isOpeningCamera) {
        _debugLog('Permission granted - opening camera');
        _isOpeningCamera = true;
        try {
          await _createAndInitializeController(device);
        } finally {
          _isOpeningCamera = false;
        }
      } else if (_isOpeningCamera) {
        _debugLog('Permission granted but camera is already being opened');
      } else {
        _debugLog('Permission granted but camera already open (cameraId: $_cameraId)');
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
    if (_cameraId == null || !_isInitialized) {
      _debugLog('Cannot start frame capture - camera not opened');
      return;
    }

    try {
      _debugLog(
        'Starting frame capture with cameraId: $_cameraId',
      );

      // Call UvcCamera Dart API to start frame streaming
      await UvcCamera.startFrameStreaming(_cameraId!, 5); // 5 = NV21 pixel format

      // Subscribe to uvccamera's NV21 frame stream and convert to BMP
      _frameSubscription = uvccameraFrameChannel.receiveBroadcastStream().listen(
        (data) async {
          if (data is Uint8List) {
            try {
              // Convert NV21 to BMP using native method
              final bmpData = await methodChannel.invokeMethod<Uint8List>(
                'convertNV21ToBMP',
                {
                  'nv21Data': data,
                  'width': 256,
                  'height': 64,
                },
              );

              if (bmpData != null) {
                _frameStreamController?.add(bmpData);
              }
            } catch (e) {
              _debugLog('Frame conversion error: $e');
            }
          }
        },
        onError: (error) {
          _debugLog('Frame stream error: $error');
        },
      );

      _debugLog('Frame capture started successfully');
    } catch (e) {
      _debugLog('ERROR during frame capture setup: $e');
      _frameStreamController?.addError('Failed to start frame capture: $e');
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
        _debugLog('Device connected event received');
        // This event fires on first permission grant (when dialog is shown)
        // We handle opening in _connectToDevice after requestDevicePermission, but this
        // serves as a fallback in case the permission was granted another way
        if (event.device.name == _currentDevice?.name && _cameraId == null && !_isOpeningCamera) {
          _debugLog('Opening camera from connected event (fallback path)');
          _isOpeningCamera = true;
          _createAndInitializeController(event.device).then((_) {
            _isOpeningCamera = false;
          }).catchError((error) {
            _isOpeningCamera = false;
            _debugLog('ERROR in connected event handler: $error');
          });
        } else if (event.device.name == _currentDevice?.name && _isOpeningCamera) {
          _debugLog('Camera is already being opened, ignoring connected event');
        } else if (event.device.name == _currentDevice?.name) {
          _debugLog('Camera already open (cameraId: $_cameraId), ignoring connected event');
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
      _debugLog('Opening camera for device: ${device.name}');

      // Open camera directly via method channel to get cameraId
      const uvccameraChannel = MethodChannel('uvccamera/native');

      try {
        final result = await uvccameraChannel.invokeMethod('openCamera', {
          'deviceName': device.name,
          'resolutionPreset': 'low', // Preset doesn't matter, fork uses first available size
        });

        _cameraId = result as int;
        _isInitialized = true;
        _debugLog('Camera opened successfully with ID: $_cameraId');
      } catch (openError) {
        _debugLog('ERROR opening camera: $openError');
        _debugLog('Device info: ${device.name}, VID: ${device.vendorId}, PID: ${device.productId}');

        throw Exception('Camera open failed: $openError');
      }

      // Start capturing frames
      await _startFrameCapture();
    } catch (e) {
      _debugLog('ERROR opening camera: $e');
      _frameStreamController?.addError('Failed to open camera: $e');
      _cameraId = null;
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

    // Cancel all subscriptions
    _frameSubscription?.cancel();
    _frameSubscription = null;

    _errorEventSubscription?.cancel();
    _errorEventSubscription = null;

    _statusEventSubscription?.cancel();
    _statusEventSubscription = null;

    // Don't cancel device event subscription - we want to keep listening for reconnections
    // _deviceEventSubscription?.cancel();
    // _deviceEventSubscription = null;

    // Stop frame streaming and close camera only if initialized
    if (_isInitialized && _cameraId != null) {
      // Stop frame streaming if active
      try {
        await UvcCamera.stopFrameStreaming(_cameraId!).timeout(
          const Duration(seconds: 1),
          onTimeout: () {
            _debugLog('WARNING: stopFrameStreaming timed out');
          },
        );
        _debugLog('Frame streaming stopped for camera: $_cameraId');
      } catch (e) {
        _debugLog('ERROR stopping frame streaming: $e');
      }

      // Close camera if open
      try {
        const uvccameraChannel = MethodChannel('uvccamera/native');
        await uvccameraChannel.invokeMethod('closeCamera', {
          'cameraId': _cameraId,
        }).timeout(
          const Duration(seconds: 1),
          onTimeout: () {
            _debugLog('WARNING: closeCamera timed out');
            return null;
          },
        );
        _debugLog('Camera closed: $_cameraId');
      } catch (e) {
        _debugLog('ERROR closing camera: $e');
      }
      _cameraId = null;
    } else if (_cameraId != null) {
      _debugLog('Camera not initialized, skipping stop/close (_cameraId: $_cameraId)');
      _cameraId = null;
    } else {
      _debugLog('No camera to stop/close');
    }

    // Reset state but keep device info for reconnection
    _isInitialized = false;
    _isOpeningCamera = false; // Reset opening flag
    // Keep _currentDevice for potential reconnection
    _resetInitializationAttempts();

    _debugLog('Current stream stopped');
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
    _resetInitializationAttempts();

    _debugLog('AndroidUsbVideoChannel disposed completely');
  }
}
