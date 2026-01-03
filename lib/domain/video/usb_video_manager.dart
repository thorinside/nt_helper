import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:collection/collection.dart';
import 'package:nt_helper/domain/video/usb_device_info.dart';
import 'package:nt_helper/domain/video/video_stream_state.dart';
import 'package:nt_helper/services/platform_channels/usb_video_channel.dart';
import 'package:nt_helper/services/debug_service.dart';

class UsbVideoManager {
  final UsbVideoChannel _channel;
  final DebugService _debugService = DebugService();

  UsbVideoManager({UsbVideoChannel? channel})
    : _channel = channel ?? UsbVideoChannel();
  StreamController<VideoStreamState>? _stateController;
  Timer? _recoveryTimer;
  Timer? _stallWatchdogTimer;
  String? _lastConnectedDeviceId;
  DateTime? _lastFrameReceivedTime;
  Duration _currentBackoffDuration = _minBackoffDuration;

  Stream<VideoStreamState> get stateStream =>
      _stateController?.stream ?? const Stream.empty();

  VideoStreamState _currentState = const VideoStreamState.disconnected();
  VideoStreamState get currentState => _currentState;

  static const int distintgVendorId = 0x16C0; // Expert Sleepers vendor ID

  // Exponential backoff configuration
  static const Duration _minBackoffDuration = Duration(seconds: 2);
  static const Duration _maxBackoffDuration = Duration(seconds: 60);

  // Stall detection: consider stalled if no frames for this duration
  static const Duration _stallThreshold = Duration(seconds: 3);
  static const Duration _stallCheckInterval = Duration(seconds: 1);

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
      final devices = await _channel.listUsbCameras();
      for (var _ in devices) {}
      return devices;
    } catch (e) {
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

      // Add debug monitoring to the stream and track frame reception
      final monitoredStream = videoStream.map((data) {
        _debugLog(
          'Received frame data: ${data?.runtimeType} ${data is Uint8List ? data.length : 'unknown'} bytes',
        );
        // Track frame reception time for stall detection
        _onFrameReceived();
        return data;
      });

      // Wait a moment to ensure the platform channel is fully set up
      await Future.delayed(const Duration(milliseconds: 100));

      // Store the device ID for recovery attempts
      _lastConnectedDeviceId = deviceId;

      // Stop any recovery timer since we're now connected
      _stopRecoveryTimer();

      // Start stall watchdog to detect if frames stop coming
      _startStallWatchdog();

      // Set to streaming state with monitored stream
      _updateState(
        VideoStreamState.streaming(
          videoStream: monitoredStream,
          width: 256, // Disting NT display width
          height: 64, // Disting NT display height
          fps: 30.0, // Target FPS (matches native throttling)
        ),
      );
    } catch (e) {
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
      _stopStallWatchdog();
      _lastFrameReceivedTime = null;
      _resetBackoff();
      _updateState(const VideoStreamState.disconnected());
    } catch (e) {
      // Intentionally empty
    }
  }

  Future<void> autoConnect() async {
    // First check if video is supported on this platform
    final supported = await isSupported();
    if (!supported) {
      _updateState(
        const VideoStreamState.error(
          'USB video not supported on this platform',
        ),
      );
      return;
    }

    final distingNT = await findDistingNT();
    if (distingNT != null) {
      await connectToDevice(distingNT.deviceId);
    } else {
      // Try to find any USB camera as fallback
      final devices = await listUsbCameras();

      if (devices.isNotEmpty) {
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

    _debugLog(
      'Starting recovery timer with ${_currentBackoffDuration.inSeconds}s backoff',
    );

    _recoveryTimer = Timer(_currentBackoffDuration, () async {
      // Only attempt recovery if we're in error state
      if (!_currentState.maybeWhen(error: (_) => true, orElse: () => false)) {
        _stopRecoveryTimer();
        return;
      }

      // Increase backoff for next attempt (exponential, capped at max)
      _currentBackoffDuration = Duration(
        milliseconds: (_currentBackoffDuration.inMilliseconds * 2).clamp(
          _minBackoffDuration.inMilliseconds,
          _maxBackoffDuration.inMilliseconds,
        ),
      );

      // Try to reconnect to the last known device first
      if (_lastConnectedDeviceId != null) {
        final devices = await listUsbCameras();
        final targetDevice = devices
            .where((d) => d.deviceId == _lastConnectedDeviceId)
            .firstOrNull;

        if (targetDevice != null) {
          await connectToDevice(_lastConnectedDeviceId!);
          return;
        }
      }

      // Fallback: try to find any Disting NT or USB camera
      await autoConnect();

      // If still in error state after autoConnect, schedule another attempt
      if (_currentState.maybeWhen(error: (_) => true, orElse: () => false)) {
        _startRecoveryTimer();
      }
    });
  }

  void _stopRecoveryTimer() {
    _recoveryTimer?.cancel();
    _recoveryTimer = null;
  }

  void _resetBackoff() {
    _currentBackoffDuration = _minBackoffDuration;
    _debugLog('Backoff reset to ${_minBackoffDuration.inSeconds}s');
  }

  /// Called when a frame is received from the video stream
  void _onFrameReceived() {
    final now = DateTime.now();
    final wasStalled =
        _lastFrameReceivedTime != null &&
        now.difference(_lastFrameReceivedTime!) > _stallThreshold;

    _lastFrameReceivedTime = now;

    // If we were stalled and frames resumed, reset backoff
    if (wasStalled) {
      _debugLog('Frames resumed after stall - resetting backoff');
      _resetBackoff();
    }
  }

  void _startStallWatchdog() {
    _stopStallWatchdog();

    _stallWatchdogTimer = Timer.periodic(_stallCheckInterval, (timer) {
      // Only check for stalls during streaming state
      final isStreaming = _currentState.maybeWhen(
        streaming: (stream, width, height, fps) => true,
        orElse: () => false,
      );
      if (!isStreaming) {
        return;
      }

      // Check if frames have stalled
      if (_lastFrameReceivedTime != null) {
        final timeSinceLastFrame = DateTime.now().difference(
          _lastFrameReceivedTime!,
        );
        if (timeSinceLastFrame > _stallThreshold) {
          _debugLog(
            'Frame stall detected: ${timeSinceLastFrame.inSeconds}s since last frame',
          );
          _handleStall();
        }
      }
    });
  }

  void _stopStallWatchdog() {
    _stallWatchdogTimer?.cancel();
    _stallWatchdogTimer = null;
  }

  Future<void> _handleStall() async {
    _stopStallWatchdog();
    _debugLog('Handling stall - disconnecting and attempting recovery');

    // Stop the current stream
    try {
      await _channel.stopVideoStream();
    } catch (e) {
      _debugLog('Error stopping stream during stall recovery: $e');
    }

    // Set error state and start recovery
    _updateState(const VideoStreamState.error('Video stream stalled'));
    _startRecoveryTimer();
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
    _stopStallWatchdog();
    _stateController?.close();
    await _channel.stopVideoStream();
    await _channel.dispose();
  }
}
