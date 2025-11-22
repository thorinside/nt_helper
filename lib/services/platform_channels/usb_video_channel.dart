import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:nt_helper/domain/video/usb_device_info.dart';
import 'package:nt_helper/services/debug_service.dart';
import 'package:nt_helper/services/platform_channels/android_usb_video_channel.dart';

class UsbVideoChannel {
  static const _channel = MethodChannel('com.example.nt_helper/usb_video');
  static const _eventChannel = EventChannel(
    'com.example.nt_helper/usb_video_stream',
  );

  Stream<dynamic>? _videoStream;
  StreamSubscription<dynamic>? _keepAliveSubscription; // Keep stream alive
  String? _currentDeviceId; // Track current device to prevent duplicate starts
  final DebugService _debugService = DebugService();

  // Android-specific implementation using uvccamera
  AndroidUsbVideoChannel? _androidChannel;

  void _debugLog(String message) {
    _debugService.addLocalMessage('[UsbVideoChannel] $message');
  }

  bool get _useAndroidImplementation => !kIsWeb && Platform.isAndroid;

  void _ensureAndroidChannel() {
    if (_useAndroidImplementation && _androidChannel == null) {
      _debugLog('Creating AndroidUsbVideoChannel');
      _androidChannel = AndroidUsbVideoChannel();
    }
  }

  Future<List<UsbDeviceInfo>> listUsbCameras() async {
    // Use Android-specific implementation if on Android
    if (_useAndroidImplementation) {
      _ensureAndroidChannel();
      return _androidChannel!.listUsbCameras();
    }

    // Original implementation for iOS and other platforms
    try {
      _debugLog('Calling listUsbCameras...');
      final List<dynamic> devices = await _channel.invokeMethod(
        'listUsbCameras',
      );
      _debugLog('Received ${devices.length} devices from platform');
      return devices.map((d) => UsbDeviceInfo.fromMap(d)).toList();
    } on PlatformException catch (e) {
      _debugLog('Failed to list USB cameras: ${e.message}');
      return [];
    }
  }

  Future<bool> requestUsbPermission(String deviceId) async {
    // Use Android-specific implementation if on Android
    if (_useAndroidImplementation) {
      _ensureAndroidChannel();
      return _androidChannel!.requestUsbPermission(deviceId);
    }

    // Original implementation for iOS and other platforms
    try {
      final bool granted = await _channel.invokeMethod('requestUsbPermission', {
        'deviceId': deviceId,
      });
      return granted;
    } on PlatformException catch (e) {
      _debugLog('Failed to request USB permission: ${e.message}');
      return false;
    }
  }

  Stream<dynamic> startVideoStream(String deviceId) {
    _debugLog('Starting video stream for device: $deviceId');

    // Use Android-specific implementation if on Android
    if (_useAndroidImplementation) {
      _ensureAndroidChannel();
      return _androidChannel!.startVideoStream(deviceId);
    }

    // Original implementation for iOS and other platforms

    // If already streaming from this device, return existing stream
    if (_videoStream != null && _currentDeviceId == deviceId) {
      _debugLog('Already streaming from device $deviceId, returning existing stream');
      return _videoStream!;
    }

    // Stop any existing stream first (only if it's a different device)
    if (_videoStream != null && _currentDeviceId != deviceId) {
      _debugLog('Stopping existing video stream for different device');
      stopVideoStream();
    }

    // Track the current device
    _currentDeviceId = deviceId;

    // Create a fresh event channel stream for receiving frames
    _debugLog('Creating new event channel stream');
    _videoStream = _eventChannel.receiveBroadcastStream({'deviceId': deviceId});

    // Convert to broadcast stream and add error handling
    _videoStream = _videoStream!
        .asBroadcastStream()
        .handleError((error) {
          _debugLog('Stream error: $error');
          _debugLog('Stream error type: ${error.runtimeType}');
        })
        .map((data) {
          _debugLog(
            'Received data: ${data.runtimeType}, size: ${data is List ? data.length : 'unknown'}',
          );
          return data;
        });

    // Create a keep-alive subscription to prevent EventChannel from cancelling
    _debugLog('Creating keep-alive subscription to prevent stream cancellation');
    _keepAliveSubscription = _videoStream!.listen(
      (_) {}, // Do nothing with the data
      onError: (error) => _debugLog('Keep-alive subscription error: $error'),
      cancelOnError: false,
    );

    // Then call the method channel to start the capture (after event channel is ready)
    _channel
        .invokeMethod('startVideoStream', {'deviceId': deviceId})
        .then((result) {
          _debugLog('startVideoStream result: $result');
        })
        .catchError((error) {
          _debugLog('startVideoStream error: $error');
        });

    return _videoStream!;
  }

  Future<void> stopVideoStream() async {
    // Use Android-specific implementation if on Android
    if (_useAndroidImplementation) {
      _androidChannel?.stopVideoStream();
      return;
    }

    // Original implementation for iOS and other platforms
    try {
      // Cancel keep-alive subscription first
      await _keepAliveSubscription?.cancel();
      _keepAliveSubscription = null;

      await _channel.invokeMethod('stopVideoStream');
      _videoStream = null;
      _currentDeviceId = null; // Clear device tracking
    } on PlatformException catch (e) {
      _debugLog('Failed to stop video stream: ${e.message}');
    }
  }

  Future<bool> isSupported() async {
    // Use Android-specific implementation if on Android
    if (_useAndroidImplementation) {
      _ensureAndroidChannel();
      return _androidChannel!.isSupported();
    }

    // Original implementation for iOS and other platforms
    try {
      final bool supported = await _channel.invokeMethod('isSupported');
      return supported;
    } on PlatformException catch (e) {
      _debugLog('Failed to check video support: ${e.message}');
      return false;
    }
  }

  /// Called when app enters background
  Future<void> pauseStreaming() async {
    _debugLog('Pausing video streaming');
    if (_useAndroidImplementation) {
      await _androidChannel?.pauseStreaming();
    }
  }

  /// Called when app returns to foreground
  Future<void> resumeStreaming() async {
    _debugLog('Resuming video streaming');
    if (_useAndroidImplementation) {
      await _androidChannel?.resumeStreaming();
    }
  }

  Future<void> dispose() async {
    _debugLog('Disposing UsbVideoChannel');
    await _keepAliveSubscription?.cancel();
    _keepAliveSubscription = null;
    await _androidChannel?.dispose();
    _androidChannel = null;
    await stopVideoStream();
  }

}
