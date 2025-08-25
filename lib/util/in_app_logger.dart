import 'package:flutter/foundation.dart';

class InAppLogger extends ChangeNotifier {
  static final InAppLogger _instance = InAppLogger._internal();
  factory InAppLogger() => _instance;
  InAppLogger._internal();

  final List<String> _logs = [];
  bool _isRecording = true; // Start recording by default

  List<String> get logs => List.unmodifiable(_logs);
  bool get isRecording => _isRecording;

  void log(String message) {
    if (!_isRecording) return;

    final timestamp = DateTime.now().toIso8601String().substring(
      11,
      23,
    ); // HH:mm:ss.SSS
    _logs.add('[$timestamp] $message');
    if (_logs.length > 500) {
      // Keep a reasonable limit
      _logs.removeAt(0);
    }
    notifyListeners();
  }

  void clearLogs() {
    _logs.clear();
    notifyListeners();
  }

  void startRecording() {
    _isRecording = true;
    log("--- Logging Resumed ---");
    notifyListeners();
  }

  void stopRecording() {
    log("--- Logging Paused ---");
    _isRecording = false;
    notifyListeners();
  }
}
