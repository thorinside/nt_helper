import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:nt_helper/domain/video/usb_device_info.dart';

class UsbVideoChannel {
  static const _channel = MethodChannel('com.example.nt_helper/usb_video');
  static const _eventChannel = EventChannel(
    'com.example.nt_helper/usb_video_stream',
  );

  Stream<dynamic>? _videoStream;

  Future<List<UsbDeviceInfo>> listUsbCameras() async {
    try {
      debugPrint('[UsbVideoChannel] Calling listUsbCameras...');
      final List<dynamic> devices = await _channel.invokeMethod(
        'listUsbCameras',
      );
      debugPrint(
        '[UsbVideoChannel] Received ${devices.length} devices from platform',
      );
      return devices.map((d) => UsbDeviceInfo.fromMap(d)).toList();
    } on PlatformException catch (e) {
      debugPrint('[UsbVideoChannel] Failed to list USB cameras: ${e.message}');
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
      debugPrint('Failed to request USB permission: ${e.message}');
      return false;
    }
  }

  Stream<dynamic> startVideoStream(String deviceId) {
    debugPrint('[UsbVideoChannel] Starting video stream for device: $deviceId');

    // Stop any existing stream first
    if (_videoStream != null) {
      debugPrint('[UsbVideoChannel] Stopping existing video stream');
      _videoStream = null;
    }

    // Create a fresh event channel stream for receiving frames
    debugPrint('[UsbVideoChannel] Creating new event channel stream');
    _videoStream = _eventChannel.receiveBroadcastStream({'deviceId': deviceId});

    // Then call the method channel to start the capture (after event channel is ready)
    _channel
        .invokeMethod('startVideoStream', {'deviceId': deviceId})
        .then((result) {
          debugPrint('[UsbVideoChannel] startVideoStream result: $result');
        })
        .catchError((error) {
          debugPrint('[UsbVideoChannel] startVideoStream error: $error');
        });

    return _videoStream!;
  }

  Future<void> stopVideoStream() async {
    try {
      await _channel.invokeMethod('stopVideoStream');
      _videoStream = null;
    } on PlatformException catch (e) {
      debugPrint('Failed to stop video stream: ${e.message}');
    }
  }

  Future<bool> isSupported() async {
    try {
      final bool supported = await _channel.invokeMethod('isSupported');
      return supported;
    } on PlatformException catch (e) {
      debugPrint('Failed to check video support: ${e.message}');
      return false;
    }
  }
}
