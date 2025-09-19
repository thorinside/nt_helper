import 'package:flutter/services.dart';
import 'package:nt_helper/domain/video/usb_device_info.dart';
import 'package:nt_helper/services/debug_service.dart';

class UsbVideoChannel {
  static const _channel = MethodChannel('com.example.nt_helper/usb_video');
  static const _eventChannel = EventChannel(
    'com.example.nt_helper/usb_video_stream',
  );

  Stream<dynamic>? _videoStream;
  final DebugService _debugService = DebugService();

  void _debugLog(String message) {
    _debugService.addLocalMessage('[UsbVideoChannel] $message');
  }

  Future<List<UsbDeviceInfo>> listUsbCameras() async {
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

    // Stop any existing stream first
    if (_videoStream != null) {
      _debugLog('Stopping existing video stream');
      _videoStream = null;
    }

    // Create a fresh event channel stream for receiving frames
    _debugLog('Creating new event channel stream');
    _videoStream = _eventChannel.receiveBroadcastStream({'deviceId': deviceId});

    // Add error handling and debugging to the stream
    _videoStream = _videoStream!.handleError((error) {
      _debugLog('Stream error: $error');
      _debugLog('Stream error type: ${error.runtimeType}');
    }).map((data) {
      _debugLog('Received data: ${data.runtimeType}, size: ${data is List ? data.length : 'unknown'}');
      return data;
    });

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
    try {
      await _channel.invokeMethod('stopVideoStream');
      _videoStream = null;
    } on PlatformException catch (e) {
      _debugLog('Failed to stop video stream: ${e.message}');
    }
  }

  Future<bool> isSupported() async {
    try {
      final bool supported = await _channel.invokeMethod('isSupported');
      return supported;
    } on PlatformException catch (e) {
      _debugLog('Failed to check video support: ${e.message}');
      return false;
    }
  }
}
