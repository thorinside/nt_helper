import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nt_helper/core/routing/routing_service_locator.dart';
import 'package:nt_helper/db/database.dart';
import 'package:nt_helper/disting_app.dart';
import 'package:nt_helper/services/algorithm_metadata_service.dart';
import 'package:nt_helper/services/mcp_server_service.dart';
import 'package:nt_helper/services/node_positions_persistence_service.dart';
import 'package:nt_helper/services/settings_service.dart' show SettingsService;
import 'package:nt_helper/services/zoom_hotkey_service.dart';
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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize window_manager on desktop platforms
  Rect? savedBounds;
  if (Platform.isLinux || Platform.isMacOS || Platform.isWindows) {
    await windowManager.ensureInitialized();

    // Load saved window position/size
    final prefs = await SharedPreferences.getInstance();
    savedBounds = await _WindowBoundsManager.loadBounds(prefs);

    // Initialize bounds manager to save on move/resize
    await _windowBoundsManager.init(prefs);

    final initialSize = savedBounds?.size ?? const Size(720, 1080);

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
    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      // Set position immediately in this callback (before show)
      if (savedBounds != null) {
        await windowManager.setBounds(savedBounds);
      }
    });
  }

  final database = AppDatabase();
  await SettingsService().init();
  await NodePositionsPersistenceService().init();
  await AlgorithmMetadataService().initialize(database);

  // Initialize routing dependencies
  await RoutingServiceLocator.setup();

  runApp(
    MultiProvider(
      providers: [
        RepositoryProvider<AppDatabase>(create: (context) => database),
        ChangeNotifierProvider(create: (_) => InAppLogger()),
      ],
      child: DistingApp(),
    ),
  );

  // Show window after first frame renders to avoid white flash
  if (Platform.isLinux || Platform.isMacOS || Platform.isWindows) {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  // Set up the method call handler for _windowEventsChannel
  _windowEventsChannel.setMethodCallHandler((call) async {
    if (call.method == 'windowWillClose') {
      // Bounds are already saved by _WindowBoundsManager on move/resize
      if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
        try {
          await McpServerService.instance.stop();
        } catch (e) {
          // Intentionally empty
        }
      }

      try {
        await database.close();
      } catch (e) {
        // Intentionally empty
      }

      try {
        await RoutingServiceLocator.reset();
      } catch (e) {
        // Intentionally empty
      }

      return true; // Signal Swift to proceed with close
    }
    return null;
  });

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
}
