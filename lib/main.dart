import 'package:flutter/material.dart';
import 'package:nt_helper/disting_app.dart';
import 'package:nt_helper/services/settings_service.dart' show SettingsService;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SettingsService().init();
  runApp(DistingApp());
}
