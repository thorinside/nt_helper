import 'dart:io';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Added for MethodChannel
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

// Define the static MethodChannel
const MethodChannel _windowEventsChannel = MethodChannel(
  'com.nt_helper.app/window_events',
);

const MethodChannel _zoomHotkeysChannel = MethodChannel(
  'com.nt_helper.app/zoom_hotkeys',
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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

  // Set up the method call handler for _windowEventsChannel
  _windowEventsChannel.setMethodCallHandler((call) async {
    if (call.method == 'windowWillClose') {
      // Window position is saved natively in WM_CLOSE handler
      // Clean up database and routing before closing
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

      return true;
    }
    return null; // For unhandled methods
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

  // Initialize bitsdojo_window on desktop platforms
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    doWhenWindowReady(() {
      final win = appWindow;
      // Window position/size is handled natively on Windows
      // Just set minimum size and show the window
      win.minSize = const Size(800, 600);
      win.show();
    });
  }
}
