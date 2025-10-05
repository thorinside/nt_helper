import 'package:flutter/services.dart';

class UsbVideoDebugChannel {
  static const _eventChannel = EventChannel(
    'com.example.nt_helper/usb_video_debug',
  );

  Stream<String>? _debugStream;

  Stream<String> get debugStream {
    _debugStream ??= _eventChannel.receiveBroadcastStream().cast<String>();
    return _debugStream!;
  }

  void dispose() {
    _debugStream = null;
  }
}
