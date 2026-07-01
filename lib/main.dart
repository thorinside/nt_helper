import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nt_helper/core/routing/routing_service_locator.dart';
import 'package:nt_helper/db/database.dart';
import 'package:nt_helper/disting_app.dart';
import 'package:nt_helper/services/algorithm_metadata_service.dart';
import 'package:nt_helper/services/database_integrity_service.dart';
import 'package:nt_helper/services/mcp_server_service.dart';
import 'package:nt_helper/services/node_positions_persistence_service.dart';
import 'package:nt_helper/services/settings_service.dart' show SettingsService;
import 'package:nt_helper/services/startup_log_service.dart';
import 'package:nt_helper/services/video_popup_window_service.dart';
import 'package:nt_helper/services/zoom_hotkey_service.dart';
import 'package:nt_helper/ui/video_popup_app.dart';
import 'package:nt_helper/util/in_app_logger.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';

// Define the static MethodChannel
const MethodChannel _windowEventsChannel = MethodChannel(
  'com.nt_helper.app/window_events',
);

const MethodChannel _zoomHotkeysChannel = MethodChannel(
  'com.nt_helper.app/zoom_hotkeys',
);

/// Manages window bounds persistence - saves on every move/resize
class _WindowBoundsManager with WindowListener {
  static const _keyX = 'window_x';
  static const _keyY = 'window_y';
  static const _keyWidth = 'window_width';
  static const _keyHeight = 'window_height';

  SharedPreferences? _prefs;

  Future<void> init(SharedPreferences prefs) async {
    _prefs = prefs;
    windowManager.addListener(this);
  }

  /// Load saved bounds, returns null if none saved
  static Future<Rect?> loadBounds(SharedPreferences prefs) async {
    final x = prefs.getDouble(_keyX);
    final y = prefs.getDouble(_keyY);
    final width = prefs.getDouble(_keyWidth);
    final height = prefs.getDouble(_keyHeight);

    if (x != null && y != null && width != null && height != null) {
      if (width > 0 && height > 0) {
        return Rect.fromLTWH(x, y, width, height);
      }
    }
    return null;
  }

  Future<void> _saveBounds() async {
    if (_prefs == null) return;
    final bounds = await windowManager.getBounds();
    await Future.wait([
      _prefs!.setDouble(_keyX, bounds.left),
      _prefs!.setDouble(_keyY, bounds.top),
      _prefs!.setDouble(_keyWidth, bounds.width),
      _prefs!.setDouble(_keyHeight, bounds.height),
    ]);
  }

  @override
  void onWindowMoved() => _saveBounds();

  @override
  void onWindowResized() => _saveBounds();
}

final _windowBoundsManager = _WindowBoundsManager();

bool _hasRunAppSuccessfully = false;

void main(List<String> args) {
  StartupLogService.initialize();
  StartupLogService.log('main() entered');

  runZonedGuarded(
    () async {
      await _bootstrapApp(args);
    },
    (error, stackTrace) {
      final isStartupError = !_hasRunAppSuccessfully;
      StartupLogService.logError(
        isStartupError
            ? 'UNCAUGHT startup zone error'
            : 'UNCAUGHT app zone error after startup',
        error,
        stackTrace,
      );
      if (isStartupError) {
        _showStartupFailure(error, stackTrace);
      }
    },
  );
}

Future<void> _bootstrapApp(List<String> _) async {
  _installGlobalErrorHandlers();

  StartupLogService.traceSync(
    'WidgetsFlutterBinding.ensureInitialized',
    WidgetsFlutterBinding.ensureInitialized,
  );

  if (_isDesktop) {
    try {
      final windowController = await StartupLogService.traceAsync(
        'WindowController.fromCurrentEngine',
        WindowController.fromCurrentEngine,
      );
      if (VideoPopupWindowService.isVideoPopupArguments(
        windowController.arguments,
      )) {
        await _bootstrapVideoPopupWindow();
        return;
      }
    } catch (error, stackTrace) {
      StartupLogService.logError(
        'Unable to inspect multi-window arguments; continuing main startup',
        error,
        stackTrace,
      );
    }
  }

  // Initialize window_manager on desktop platforms
  Rect? savedBounds;
  if (_isDesktop) {
    await StartupLogService.traceAsync(
      'windowManager.ensureInitialized',
      windowManager.ensureInitialized,
    );

    // Load saved window position/size
    final prefs = await StartupLogService.traceAsync(
      'SharedPreferences.getInstance',
      SharedPreferences.getInstance,
    );
    savedBounds = await StartupLogService.traceAsync(
      'WindowBoundsManager.loadBounds',
      () => _WindowBoundsManager.loadBounds(prefs),
    );
    StartupLogService.log('Saved window bounds: ${savedBounds ?? 'none'}');

    // Initialize bounds manager to save on move/resize
    await StartupLogService.traceAsync(
      'WindowBoundsManager.init',
      () => _windowBoundsManager.init(prefs),
    );

    final initialSize = savedBounds?.size ?? const Size(720, 1080);
    StartupLogService.log('Initial window size: $initialSize');

    // Configure window options but DON'T show yet - wait for first frame
    WindowOptions windowOptions = WindowOptions(
      size: initialSize,
      minimumSize: const Size(640, 720),
      center: savedBounds == null,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.normal,
    );

    // Set up the window but don't show yet
    // We'll set bounds and show after first frame renders to avoid white flash
    await StartupLogService.traceAsync(
      'windowManager.waitUntilReadyToShow',
      () => windowManager.waitUntilReadyToShow(windowOptions, () async {
        // Set position immediately in this callback (before show)
        if (savedBounds != null) {
          StartupLogService.log('Applying saved window bounds: $savedBounds');
          await windowManager.setBounds(savedBounds);
        }
      }),
    );
  }

  // Check database integrity before opening
  final integrityResult = await StartupLogService.traceAsync(
    'DatabaseIntegrityService.checkIntegrity',
    DatabaseIntegrityService.checkIntegrity,
  );
  StartupLogService.log(
    'Database integrity: fileExists=${integrityResult.fileExists}, '
    'isCorrupt=${integrityResult.isCorrupt}, error=${integrityResult.error}',
  );
  if (integrityResult.isCorrupt) {
    await StartupLogService.traceAsync(
      'DatabaseIntegrityService.deleteDatabase',
      DatabaseIntegrityService.deleteDatabase,
    );
  }

  final database = StartupLogService.traceSync(
    'AppDatabase()',
    AppDatabase.new,
  );
  await StartupLogService.traceAsync(
    'SettingsService.init',
    SettingsService().init,
  );
  await StartupLogService.traceAsync(
    'NodePositionsPersistenceService.init',
    NodePositionsPersistenceService().init,
  );
  await StartupLogService.traceAsync(
    'AlgorithmMetadataService.initialize',
    () => AlgorithmMetadataService().initialize(database),
  );

  // Initialize routing dependencies
  await StartupLogService.traceAsync(
    'RoutingServiceLocator.setup',
    RoutingServiceLocator.setup,
  );

  StartupLogService.log('Calling runApp');
  runApp(
    MultiProvider(
      providers: [
        RepositoryProvider<AppDatabase>(create: (context) => database),
        ChangeNotifierProvider(create: (_) => InAppLogger()),
      ],
      child: DistingApp(),
    ),
  );
  _hasRunAppSuccessfully = true;
  StartupLogService.log('runApp returned');

  // Show window after first frame renders to avoid white flash
  if (_isDesktop) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      StartupLogService.log('First frame rendered; showing desktop window');
      unawaited(_showDesktopWindow('normal startup'));
    });
  }

  // Set up the method call handler for _windowEventsChannel
  _windowEventsChannel.setMethodCallHandler((call) async {
    if (call.method == 'windowWillClose') {
      StartupLogService.log('windowWillClose received');
      // Bounds are already saved by _WindowBoundsManager on move/resize
      if (_isDesktop) {
        try {
          await McpServerService.instance.stop();
        } catch (error, stackTrace) {
          StartupLogService.logError(
            'McpServerService.stop failed during shutdown',
            error,
            stackTrace,
          );
        }
      }

      try {
        await database.close();
      } catch (error, stackTrace) {
        StartupLogService.logError(
          'Database close failed during shutdown',
          error,
          stackTrace,
        );
      }

      try {
        await RoutingServiceLocator.reset();
      } catch (error, stackTrace) {
        StartupLogService.logError(
          'RoutingServiceLocator.reset failed during shutdown',
          error,
          stackTrace,
        );
      }

      StartupLogService.log('windowWillClose completed');
      return true; // Signal Swift to proceed with close
    }
    return null;
  });
  StartupLogService.log('Window events MethodChannel handler installed');

  _zoomHotkeysChannel.setMethodCallHandler((call) async {
    switch (call.method) {
      case 'zoomIn':
        ZoomHotkeyService.instance.dispatch(ZoomHotkeyAction.zoomIn);
        break;
      case 'zoomOut':
        ZoomHotkeyService.instance.dispatch(ZoomHotkeyAction.zoomOut);
        break;
      case 'resetZoom':
        ZoomHotkeyService.instance.dispatch(ZoomHotkeyAction.resetZoom);
        break;
    }
    return null;
  });
  StartupLogService.log('Zoom hotkeys MethodChannel handler installed');
  StartupLogService.log('Startup bootstrap completed');
}

Future<void> _bootstrapVideoPopupWindow() async {
  await StartupLogService.traceAsync(
    'windowManager.ensureInitialized',
    windowManager.ensureInitialized,
  );
  await StartupLogService.traceAsync(
    'SettingsService.init',
    SettingsService().init,
  );
  runApp(const VideoPopupApp());
  _hasRunAppSuccessfully = true;
  WidgetsBinding.instance.addPostFrameCallback((_) {
    unawaited(
      StartupLogService.traceAsync(
        'configureVideoPopupWindow',
        configureVideoPopupWindow,
      ),
    );
  });
}

bool get _isDesktop =>
    Platform.isLinux || Platform.isMacOS || Platform.isWindows;

void _installGlobalErrorHandlers() {
  final previousFlutterErrorHandler = FlutterError.onError;
  FlutterError.onError = (details) {
    StartupLogService.logError(
      'Flutter framework error',
      details.exception,
      details.stack ?? StackTrace.current,
    );
    (previousFlutterErrorHandler ?? FlutterError.presentError).call(details);
  };

  final previousPlatformErrorHandler = PlatformDispatcher.instance.onError;
  PlatformDispatcher.instance.onError = (error, stackTrace) {
    StartupLogService.logError(
      'PlatformDispatcher uncaught error',
      error,
      stackTrace,
    );
    return previousPlatformErrorHandler?.call(error, stackTrace) ?? false;
  };

  StartupLogService.log('Global error handlers installed');
}

Future<void> _showDesktopWindow(String reason) async {
  try {
    await windowManager.ensureInitialized();
    await windowManager.show();
    await windowManager.focus();
    StartupLogService.log('Desktop window shown for $reason');
  } catch (error, stackTrace) {
    StartupLogService.logError(
      'Unable to show desktop window for $reason',
      error,
      stackTrace,
    );
  }
}

void _showStartupFailure(Object error, StackTrace stackTrace) {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    runApp(_StartupFailureApp(error: error, stackTrace: stackTrace));
    if (_isDesktop) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(_showDesktopWindow('startup failure'));
      });
    }
  } catch (secondaryError, secondaryStackTrace) {
    StartupLogService.logError(
      'Unable to display startup failure screen',
      secondaryError,
      secondaryStackTrace,
    );
  }
}

class _StartupFailureApp extends StatelessWidget {
  const _StartupFailureApp({required this.error, required this.stackTrace});

  final Object error;
  final StackTrace stackTrace;

  @override
  Widget build(BuildContext context) {
    final logPath = StartupLogService.logPath ?? 'unknown';

    return MaterialApp(
      home: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ListView(
              children: [
                Semantics(
                  header: true,
                  child: const Text(
                    'nt_helper failed to start',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Please send the startup log file and the error below to the nt_helper developer.',
                ),
                const SizedBox(height: 12),
                SelectableText('Startup log: $logPath'),
                const SizedBox(height: 24),
                SelectableText('Error: $error'),
                const SizedBox(height: 16),
                SelectableText('Stack trace:\n$stackTrace'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
