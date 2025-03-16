import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';
import 'package:nt_helper/disting_app.dart';
import 'package:nt_helper/services/settings_service.dart' show SettingsService;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SettingsService().init();
  runApp(DistingApp());

  doWhenWindowReady(() {
    const initialSize = Size(720, 1080);
    appWindow.minSize = Size(640, 720);
    appWindow.size = initialSize;
    appWindow.alignment = Alignment.center;
    appWindow.show();
  });
}
