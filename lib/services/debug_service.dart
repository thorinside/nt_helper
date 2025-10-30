import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:nt_helper/services/platform_channels/usb_video_debug_channel.dart';

class DebugService {
  static final DebugService _instance = DebugService._internal();
  factory DebugService() => _instance;
  DebugService._internal();

  final UsbVideoDebugChannel _debugChannel = UsbVideoDebugChannel();
  final StreamController<String> _debugController =
      StreamController.broadcast();
  final List<String> _debugMessages = [];
  StreamSubscription<String>? _debugSubscription;

  bool get isDebugMode => kDebugMode;

  Stream<String> get debugStream => _debugController.stream;
  List<String> get debugMessages => List.unmodifiable(_debugMessages);

  void initialize() {
    if (isDebugMode) {
      _debugSubscription = _debugChannel.debugStream.listen((message) {
        _addDebugMessage(message);
      });
    }
  }

  void _addDebugMessage(String message) {
    _debugMessages.add(message);

    // Keep only the last 100 messages to prevent memory issues
    if (_debugMessages.length > 100) {
      _debugMessages.removeAt(0);
    }

    _debugController.add(message);

    // Also print to console in debug mode
    if (kDebugMode) {
    }
  }

  void addLocalMessage(String message) {
    if (isDebugMode) {
      final timestamp = DateTime.now().toString().substring(11, 19);
      _addDebugMessage('[$timestamp] [LOCAL] $message');
    }
  }

  void clearMessages() {
    _debugMessages.clear();
  }

  void dispose() {
    _debugSubscription?.cancel();
    _debugController.close();
    _debugChannel.dispose();
  }
}
