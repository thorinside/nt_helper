import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nt_helper/db/database.dart';
import 'package:nt_helper/disting_app.dart';
import 'package:nt_helper/services/algorithm_metadata_service.dart';
import 'package:nt_helper/services/settings_service.dart' show SettingsService;
import 'package:shared_preferences/shared_preferences.dart';

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

  appWindow.onWindowClose = () async {
    final prefs = await SharedPreferences.getInstance();
    try {
      await prefs.setDouble('window_x', appWindow.rect.left);
      await prefs.setDouble('window_y', appWindow.rect.top);
      await prefs.setDouble('window_width', appWindow.rect.width);
      await prefs.setDouble('window_height', appWindow.rect.height);
    } catch (e) {
      // Handle error saving window state
      print('Error saving window state: $e');
    }
    return true; // Allow window to close
  };

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
      print('Error loading window state: $e');
    }

    appWindow.minSize = Size(640, 720);

    if (x != null && y != null && width != null && height != null) {
      appWindow.rect = Rect.fromLTWH(x, y, width, height);
    } else {
      const initialSize = Size(720, 1080);
      appWindow.size = initialSize;
      appWindow.alignment = Alignment.center;
    }
    appWindow.show();
  });
}
