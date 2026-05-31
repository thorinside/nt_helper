import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

/// Very early, file-backed startup logging for diagnosing cases where the UI
/// never appears.
///
/// This intentionally avoids plugin APIs so it can be initialized before
/// [WidgetsFlutterBinding.ensureInitialized]. Writes are synchronous so the log
/// survives abrupt failures during startup.
class StartupLogService {
  static const _logFileName = 'nt_helper_startup.log';
  static const _previousLogFileName = 'nt_helper_startup.previous.log';

  static File? _logFile;
  static bool _initialized = false;
  static DebugPrintCallback? _previousDebugPrint;

  static String? get logPath => _logFile?.path;

  static void initialize({Directory? directory}) {
    if (_initialized) return;

    final logDirectory = directory ?? _defaultLogDirectory();
    _logFile = File(p.join(logDirectory.path, _logFileName));

    try {
      logDirectory.createSync(recursive: true);

      // On Windows, the native runner starts the same log before Dart starts.
      // Preserve those earliest entries by appending to the existing file.
      final appendExistingNativeLog =
          Platform.isWindows && _logFile!.existsSync();
      if (!appendExistingNativeLog) {
        _rotatePreviousLog(logDirectory);
      }

      _initialized = true;
      log('============================================================');
      log('nt_helper Dart startup log attached');
      log('Log file: ${_logFile!.path}');
      log(
        'Platform: ${Platform.operatingSystem} ${Platform.operatingSystemVersion}',
      );
      log('Dart runtime: ${Platform.version}');
      log('Executable: ${Platform.resolvedExecutable}');
      log('Script: ${Platform.script}');
      log('Current directory: ${Directory.current.path}');
      log('Arguments: ${Platform.executableArguments.join(' ')}');
      log('Locale: ${Platform.localeName}');
      _captureDebugPrint();
    } catch (_) {
      // Startup logging must never stop the app from launching.
      _initialized = true;
    }
  }

  static void log(String message) {
    final file = _logFile;
    if (file == null) return;

    final timestamp = DateTime.now().toIso8601String();
    _writeLine(file, '[$timestamp] $message');
  }

  static void logError(String message, Object error, StackTrace stackTrace) {
    log('$message: $error');
    log('Stack trace:\n$stackTrace');
  }

  static T traceSync<T>(String label, T Function() action) {
    log('START $label');
    try {
      final result = action();
      log('END $label');
      return result;
    } catch (error, stackTrace) {
      logError('FAILED $label', error, stackTrace);
      rethrow;
    }
  }

  static Future<T> traceAsync<T>(
    String label,
    Future<T> Function() action,
  ) async {
    log('START $label');
    try {
      final result = await action();
      log('END $label');
      return result;
    } catch (error, stackTrace) {
      logError('FAILED $label', error, stackTrace);
      rethrow;
    }
  }

  static Directory _defaultLogDirectory() {
    if (Platform.isWindows) {
      final localAppData = Platform.environment['LOCALAPPDATA'];
      if (localAppData != null && localAppData.isNotEmpty) {
        return Directory(p.join(localAppData, 'nt_helper', 'logs'));
      }

      final appData = Platform.environment['APPDATA'];
      if (appData != null && appData.isNotEmpty) {
        return Directory(p.join(appData, 'nt_helper', 'logs'));
      }
    }

    if (Platform.isMacOS || Platform.isLinux) {
      final home = Platform.environment['HOME'];
      if (home != null && home.isNotEmpty) {
        return Directory(p.join(home, '.nt_helper', 'logs'));
      }
    }

    return Directory(p.join(Directory.systemTemp.path, 'nt_helper', 'logs'));
  }

  static void _rotatePreviousLog(Directory logDirectory) {
    final current = File(p.join(logDirectory.path, _logFileName));
    if (!current.existsSync()) return;

    final previous = File(p.join(logDirectory.path, _previousLogFileName));
    try {
      if (previous.existsSync()) {
        previous.deleteSync();
      }
      current.renameSync(previous.path);
    } catch (_) {
      // If rotation fails, best effort is to overwrite the current log.
      current.writeAsStringSync('', mode: FileMode.write, flush: true);
    }
  }

  static void _writeLine(File file, String line) {
    try {
      file.writeAsStringSync('$line\n', mode: FileMode.append, flush: true);
    } catch (_) {
      // Ignore write failures. This logger is diagnostic-only.
    }
  }

  static void _captureDebugPrint() {
    if (_previousDebugPrint != null) return;

    _previousDebugPrint = debugPrint;
    debugPrint = (String? message, {int? wrapWidth}) {
      if (message != null) {
        log('debugPrint: $message');
      }
      _previousDebugPrint?.call(message, wrapWidth: wrapWidth);
    };
  }
}
