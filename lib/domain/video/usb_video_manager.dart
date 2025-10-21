import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:collection/collection.dart';
import 'package:nt_helper/domain/video/usb_device_info.dart';
import 'package:nt_helper/domain/video/video_stream_state.dart';
import 'package:nt_helper/services/platform_channels/usb_video_channel.dart';
import 'package:nt_helper/services/debug_service.dart';
import 'package:uvccamera/uvccamera.dart';

class UsbVideoManager {
  final UsbVideoChannel _channel;
  final DebugService _debugService = DebugService();

  UsbVideoManager({UsbVideoChannel? channel})
    : _channel = channel ?? UsbVideoChannel();
  StreamController<VideoStreamState>? _stateController;
  Timer? _recoveryTimer;
  String? _lastConnectedDeviceId;

  Stream<VideoStreamState> get stateStream =>
      _stateController?.stream ?? const Stream.empty();

  VideoStreamState _currentState = const VideoStreamState.disconnected();
  VideoStreamState get currentState => _currentState;

  static const int distintgVendorId = 0x16C0; // Expert Sleepers vendor ID
  static const Duration _recoveryCheckInterval = Duration(seconds: 5);

  void _debugLog(String message) {
    _debugService.addLocalMessage('[UsbVideoManager] $message');
  }

  Future<void> initialize() async {
    _stateController = StreamController<VideoStreamState>.broadcast();
    _updateState(const VideoStreamState.disconnected());
  }

  Future<bool> isSupported() async {
    try {
      final supported = await _channel.isSupported();
      _debugLog('isSupported() returned: $supported');
      return supported;
    } catch (e) {
      _debugLog('ERROR checking video support: $e');
      return false;
    }
  }

  Future<List<UsbDeviceInfo>> listUsbCameras() async {
    try {
      debugPrint('[USB_VIDEO] Calling listUsbCameras()...');
      final devices = await _channel.listUsbCameras();
      debugPrint('[USB_VIDEO] Found ${devices.length} devices');
      for (var device in devices) {
        debugPrint(
          '[USB_VIDEO]   - ${device.productName} (ID: ${device.deviceId})',
        );
      }
      return devices;
    } catch (e) {
      debugPrint('[USB_VIDEO] ERROR listing USB cameras: $e');
      return [];
    }
  }

  Future<UsbDeviceInfo?> findDistingNT() async {
    final devices = await listUsbCameras();
    try {
      return devices.firstWhere((device) => device.isDistingNT);
    } catch (e) {
      // No Disting NT found
      return null;
    }
  }

  Future<void> connectToDevice(String deviceId) async {
    try {
      _debugLog('Connecting to device: $deviceId');
      _updateState(const VideoStreamState.connecting());

      // Request permission if needed (Android)
      final hasPermission = await _channel.requestUsbPermission(deviceId);
      _debugLog('USB permission: $hasPermission');
      if (!hasPermission) {
        _updateState(const VideoStreamState.error('USB permission denied'));
        _startRecoveryTimer();
        return;
      }

      // Start video stream
      _debugLog('Starting video stream...');
      final videoStream = _channel.startVideoStream(deviceId);

      // Add debug monitoring to the stream
      final monitoredStream = videoStream.map((data) {
        _debugLog(
          'Received frame data: ${data?.runtimeType} ${data is Uint8List ? data.length : 'unknown'} bytes',
        );
        return data;
      });

      // Wait a moment to ensure the platform channel is fully set up
      await Future.delayed(const Duration(milliseconds: 100));

      // Store the device ID for recovery attempts
      _lastConnectedDeviceId = deviceId;

      // Stop any recovery timer since we're now connected
      _stopRecoveryTimer();

      // Set to streaming state with monitored stream
      _updateState(
        VideoStreamState.streaming(
          videoStream: monitoredStream,
          width: 256, // Disting NT display width
          height: 64, // Disting NT display height
          fps: 15.0, // Target FPS
        ),
      );

      debugPrint(
        '[UsbVideoManager] Video stream state updated to streaming - VideoFrameCubit will handle frame consumption',
      );
    } catch (e) {
      debugPrint('[UsbVideoManager] Connection failed: $e');
      _updateState(
        VideoStreamState.error('Device disconnected or unavailable'),
      );
      _startRecoveryTimer();
    }
  }

  /// Get the raw video stream for direct consumption by VideoFrameCubit
  Stream<dynamic>? getRawVideoStream() {
    return _currentState.maybeWhen(
      streaming: (stream, width, height, fps) => stream,
      orElse: () => null,
    );
  }

  /// Get the Android UvcCameraController for direct widget access
  /// Returns null on non-Android platforms
  UvcCameraController? getAndroidCameraController() {
    return _channel.getAndroidCameraController();
  }

  Future<void> disconnect() async {
    try {
      await _channel.stopVideoStream();
      _stopRecoveryTimer();
      _updateState(const VideoStreamState.disconnected());
    } catch (e) {
      debugPrint('Error disconnecting video: $e');
    }
  }

  Future<void> autoConnect() async {
    debugPrint('[USB_VIDEO] === AUTOCONNECT START ===');

    // First check if video is supported on this platform
    final supported = await isSupported();
    if (!supported) {
      debugPrint('[USB_VIDEO] Platform does not support USB video');
      _updateState(
        const VideoStreamState.error(
          'USB video not supported on this platform',
        ),
      );
      return;
    }

    final distingNT = await findDistingNT();
    if (distingNT != null) {
      debugPrint('[USB_VIDEO] Found Disting NT: ${distingNT.deviceId}');
      await connectToDevice(distingNT.deviceId);
    } else {
      // Try to find any USB camera as fallback
      final devices = await listUsbCameras();
      debugPrint('[USB_VIDEO] Total devices found: ${devices.length}');

      if (devices.isNotEmpty) {
        debugPrint(
          '[USB_VIDEO] Connecting to first device: ${devices.first.deviceId}',
        );
        await connectToDevice(devices.first.deviceId);
      } else {
        debugPrint('[USB_VIDEO] No devices found - setting error state');
        _updateState(
          const VideoStreamState.error('No USB video devices found'),
        );
      }
    }
    debugPrint('[USB_VIDEO] === AUTOCONNECT END ===');
  }

  void _updateState(VideoStreamState newState) {
    _currentState = newState;
    _stateController?.add(newState);
  }

  void _startRecoveryTimer() {
    _stopRecoveryTimer(); // Cancel any existing timer
    debugPrint(
      '[UsbVideoManager] Starting recovery timer - checking every ${_recoveryCheckInterval.inSeconds} seconds',
    );

    _recoveryTimer = Timer.periodic(_recoveryCheckInterval, (timer) async {
      // Only attempt recovery if we're in error state
      if (!_currentState.maybeWhen(error: (_) => true, orElse: () => false)) {
        _stopRecoveryTimer();
        return;
      }

      debugPrint('[UsbVideoManager] Attempting automatic recovery...');

      // Try to reconnect to the last known device first
      if (_lastConnectedDeviceId != null) {
        final devices = await listUsbCameras();
        final targetDevice = devices
            .where((d) => d.deviceId == _lastConnectedDeviceId)
            .firstOrNull;

        if (targetDevice != null) {
          debugPrint(
            '[UsbVideoManager] Last connected device found, attempting reconnection',
          );
          await connectToDevice(_lastConnectedDeviceId!);
          return;
        }
      }

      // Fallback: try to find any Disting NT or USB camera
      await autoConnect();
    });
  }

  void _stopRecoveryTimer() {
    _recoveryTimer?.cancel();
    _recoveryTimer = null;
  }

  /// Called when app enters background (lifecycle pause)
  Future<void> pauseForLifecycle() async {
    _debugLog('Pausing for app lifecycle event');
    await _channel.pauseStreaming();
  }

  /// Called when app returns to foreground (lifecycle resume)
  Future<void> resumeForLifecycle() async {
    _debugLog('Resuming from app lifecycle event');
    await _channel.resumeStreaming();
  }

  Future<void> dispose() async {
    _stopRecoveryTimer();
    _stateController?.close();
    await _channel.stopVideoStream();
    await _channel.dispose();
  }
}
