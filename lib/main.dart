import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Added for MethodChannel
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nt_helper/db/database.dart';
import 'package:nt_helper/disting_app.dart';
import 'package:nt_helper/services/algorithm_metadata_service.dart';
import 'package:nt_helper/services/settings_service.dart' show SettingsService;
import 'package:shared_preferences/shared_preferences.dart';

// Define the static MethodChannel
const MethodChannel _windowEventsChannel = MethodChannel('com.nt_helper.app/window_events');

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SettingsService().init();
  await AlgorithmMetadataService().initialize();

  final database = AppDatabase();

  runApp(
    RepositoryProvider<AppDatabase>(
      create: (context) => database,
      child: DistingApp(),
      dispose: (db) => db.close(),
    ),
  );

  // Set up the method call handler for _windowEventsChannel
  _windowEventsChannel.setMethodCallHandler((call) async {
    if (call.method == 'windowWillClose') {
      try {
        final prefs = await SharedPreferences.getInstance();
        final windowRect = appWindow.rect;

        // Create a list of futures for all save operations
        final List<Future<bool>> saveFutures = [
          prefs.setDouble('window_x', windowRect.left),
          prefs.setDouble('window_y', windowRect.top),
          prefs.setDouble('window_width', windowRect.width),
          prefs.setDouble('window_height', windowRect.height),
        ];

        // Await all save operations to complete
        final List<bool> results = await Future.wait(saveFutures);

        // Check if all operations were successful (SharedPreferences.setDouble returns true on success)
        if (results.every((result) => result)) {
          return true; // Signal success to native side
        } else {
          return false; // Signal failure
        }
      } catch (e) {
        return false; // Signal failure
      }
    }
    // Handle other method calls if any, or return a default for unhandled methods
    return null;
  });

  // The old appWindow.onWindowClose assignment has been removed.

  doWhenWindowReady(() async {
    // SettingsService().init() is already called above, so SharedPreferences should be initialized.
    final prefs = await SharedPreferences.getInstance();
    double? x, y, width, height;
    try {
      x = prefs.getDouble('window_x');
      y = prefs.getDouble('window_y');
      width = prefs.getDouble('window_width');
      height = prefs.getDouble('window_height');
    } catch (e) {
      // Handle error loading window state
      // Consider logging this to a file or analytics in a real app
    }

    appWindow.minSize = Size(640, 720);

    bool hasSavedPositionAndSize = x != null && y != null && width != null && height != null;

    if (hasSavedPositionAndSize) {
      // Ensure width and height are positive, otherwise bitsdojo might ignore the rect.
      if (width! <= 0 || height! <= 0) {
          const initialSize = Size(720, 1080);
          appWindow.size = initialSize;
          appWindow.alignment = Alignment.center;
      } else {
          // Create Size and Offset objects
          Size savedSize = Size(width, height);
          Offset savedPosition = Offset(x!, y!);
          
          appWindow.size = savedSize;
          appWindow.position = savedPosition;
      }
    } else {
      const initialSize = Size(720, 1080);
      appWindow.size = initialSize;
      appWindow.alignment = Alignment.center;
    }

    appWindow.show();
  });
}
