import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:collection/collection.dart';
import 'package:nt_helper/domain/video/usb_device_info.dart';
import 'package:nt_helper/domain/video/video_stream_state.dart';
import 'package:nt_helper/services/platform_channels/usb_video_channel.dart';

class UsbVideoManager {
  final UsbVideoChannel _channel;

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

  Future<void> initialize() async {
    _stateController = StreamController<VideoStreamState>.broadcast();
    _updateState(const VideoStreamState.disconnected());
  }

  Future<bool> isSupported() async {
    try {
      return await _channel.isSupported();
    } catch (e) {
      debugPrint('Error checking video support: $e');
      return false;
    }
  }

  Future<List<UsbDeviceInfo>> listUsbCameras() async {
    try {
      return await _channel.listUsbCameras();
    } catch (e) {
      debugPrint('Error listing USB cameras: $e');
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
      debugPrint('[UsbVideoManager] Connecting to device: $deviceId');
      _updateState(const VideoStreamState.connecting());

      // Request permission if needed (Android)
      final hasPermission = await _channel.requestUsbPermission(deviceId);
      debugPrint('[UsbVideoManager] USB permission: $hasPermission');
      if (!hasPermission) {
        _updateState(const VideoStreamState.error('USB permission denied'));
        _startRecoveryTimer();
        return;
      }

      // Start video stream
      debugPrint('[UsbVideoManager] Starting video stream...');
      final videoStream = _channel.startVideoStream(deviceId);

      // Wait a moment to ensure the platform channel is fully set up
      await Future.delayed(const Duration(milliseconds: 100));

      // Store the device ID for recovery attempts
      _lastConnectedDeviceId = deviceId;

      // Stop any recovery timer since we're now connected
      _stopRecoveryTimer();

      // Set to streaming state with platform stream directly
      _updateState(
        VideoStreamState.streaming(
          videoStream: videoStream,
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
    debugPrint('[UsbVideoManager] Starting autoConnect...');
    final distingNT = await findDistingNT();
    if (distingNT != null) {
      debugPrint('[UsbVideoManager] Found Disting NT: ${distingNT.deviceId}');
      await connectToDevice(distingNT.deviceId);
    } else {
      // Try to find any USB camera as fallback
      final devices = await listUsbCameras();
      debugPrint('[UsbVideoManager] Found ${devices.length} USB cameras');
      for (final device in devices) {
        debugPrint(
          '[UsbVideoManager] Device: ${device.productName} (${device.deviceId})',
        );
      }
      if (devices.isNotEmpty) {
        debugPrint(
          '[UsbVideoManager] Connecting to first device: ${devices.first.deviceId}',
        );
        await connectToDevice(devices.first.deviceId);
      } else {
        _updateState(
          const VideoStreamState.error('No USB video devices found'),
        );
      }
    }
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

  void dispose() {
    _stopRecoveryTimer();
    _stateController?.close();
    _channel.stopVideoStream();
  }
}
