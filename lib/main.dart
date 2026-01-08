import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nt_helper/core/routing/routing_service_locator.dart';
import 'package:nt_helper/db/database.dart';
import 'package:nt_helper/disting_app.dart';
import 'package:nt_helper/services/algorithm_metadata_service.dart';
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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize window_manager on desktop platforms
  if (Platform.isLinux || Platform.isMacOS || Platform.isWindows) {
    await windowManager.ensureInitialized();

    // Load saved window position/size
    final prefs = await SharedPreferences.getInstance();
    double? x = prefs.getDouble('window_x');
    double? y = prefs.getDouble('window_y');
    double? width = prefs.getDouble('window_width');
    double? height = prefs.getDouble('window_height');

    bool hasSavedBounds =
        x != null && y != null && width != null && height != null;

    Size initialSize;
    Offset? initialPosition;

    if (hasSavedBounds && width > 0 && height > 0) {
      initialSize = Size(width, height);
      initialPosition = Offset(x, y);
    } else {
      initialSize = const Size(720, 1080);
      initialPosition = null; // Will center
    }

    // Configure window options but DON'T show yet - wait for first frame
    WindowOptions windowOptions = WindowOptions(
      size: initialSize,
      minimumSize: const Size(640, 720),
      center: initialPosition == null,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.normal,
    );

    // Just set up the window options, don't show
    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      if (initialPosition != null) {
        await windowManager.setPosition(initialPosition);
      }
      // Don't show here - we'll show after first frame renders
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
      bool prefsSavedSuccessfully = false;
      try {
        final prefs = await SharedPreferences.getInstance();
        final bounds = await windowManager.getBounds();

        final List<Future<bool>> saveFutures = [
          prefs.setDouble('window_x', bounds.left),
          prefs.setDouble('window_y', bounds.top),
          prefs.setDouble('window_width', bounds.width),
          prefs.setDouble('window_height', bounds.height),
        ];

        final List<bool> results = await Future.wait(saveFutures);
        prefsSavedSuccessfully = results.every((result) => result);
      } catch (e) {
        prefsSavedSuccessfully = false;
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

      return prefsSavedSuccessfully;
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
