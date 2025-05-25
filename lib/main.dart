import 'dart:isolate';

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
const MethodChannel _windowEventsChannel =
    MethodChannel('com.nt_helper.app/window_events');

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
      debugPrint('Dart: windowWillClose event received');
      try {
        final prefs = await SharedPreferences.getInstance();
        final windowRect = appWindow.rect;
        Isolate.run(() => saveWindowStateToPrefs(prefs, windowRect));
      } catch (e) {
        debugPrint('Dart: Error saving window state: $e');
      }
    }
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
      debugPrint('Loaded from prefs: x=$x, y=$y, width=$width, height=$height');
    } catch (e) {
      // Handle error loading window state
      debugPrint('Error loading window state from SharedPreferences: $e');
    }

    appWindow.minSize = Size(640, 720);

    bool hasSavedPositionAndSize =
        x != null && y != null && width != null && height != null;
    debugPrint(
        'Condition (x != null && y != null && width != null && height != null) is: $hasSavedPositionAndSize');

    if (hasSavedPositionAndSize) {
      // Ensure width and height are positive, otherwise bitsdojo might ignore the rect.
      if (width! <= 0 || height! <= 0) {
        debugPrint(
            'Warning: Loaded width or height is not positive. width=$width, height=$height. Falling back to default size.');
        const initialSize = Size(720, 1080);
        appWindow.size = initialSize;
        debugPrint('Set initialSize to $initialSize');
        appWindow.alignment = Alignment.center;
        debugPrint('Set alignment to center');
      } else {
        Rect savedRect = Rect.fromLTWH(x!, y!, width, height);
        debugPrint('Applying saved rect: $savedRect');
        debugPrint('Before appWindow.rect = savedRect');
        appWindow.rect = savedRect;
        debugPrint(
            'After appWindow.rect = savedRect. Current appWindow.rect is ${appWindow.rect}');
      }
    } else {
      debugPrint('Using default window size and alignment.');
      const initialSize = Size(720, 1080);
      appWindow.size = initialSize;
      debugPrint('Set initialSize to $initialSize');
      appWindow.alignment = Alignment.center;
      debugPrint('Set alignment to center');
    }

    debugPrint(
        'Final check before show: appWindow.rect=${appWindow.rect}, appWindow.size=${appWindow.size}, appWindow.position=${appWindow.position}');
    appWindow.show();
    debugPrint('Called appWindow.show()');
  });
}

Future<void> saveWindowStateToPrefs(
    SharedPreferences prefs, Rect windowRect) async {
  await prefs.setDouble('window_x', windowRect.left);
  await prefs.setDouble('window_y', windowRect.top);
  await prefs.setDouble('window_width', windowRect.width);
  await prefs.setDouble('window_height', windowRect.height);
  debugPrint('Dart: Window state saved successfully.');
}
