import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:nt_helper/models/node_position.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NodePositionsPersistenceService {
  static NodePositionsPersistenceService? _instance;
  SharedPreferences? _prefs;
  Timer? _saveTimer;
  Map<int, NodePosition>? _pendingPositions;
  String? _pendingKey;

  static const String _nodePositionsKeyPrefix = 'node_positions_';

  factory NodePositionsPersistenceService() {
    _instance ??= NodePositionsPersistenceService._internal();
    return _instance!;
  }

  NodePositionsPersistenceService._internal();

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  @visibleForTesting
  void setSharedPreferencesForTesting(SharedPreferences prefs) {
    _prefs = prefs;
  }

  Future<void> savePositions(
    String presetName,
    Map<int, NodePosition> positions,
  ) async {
    _pendingPositions = positions;
    _pendingKey = '$_nodePositionsKeyPrefix$presetName';
    _saveTimer?.cancel();
    _saveTimer = Timer(
      const Duration(milliseconds: 500),
      _flushPendingPositions,
    );
  }

  Future<void> _flushPendingPositions() async {
    if (_pendingPositions == null || _pendingKey == null) return;

    try {
      final Map<String, dynamic> serializable = _pendingPositions!.map(
        (key, value) => MapEntry(key.toString(), value.toJson()),
      );
      await _prefs?.setString(_pendingKey!, jsonEncode(serializable));
    } catch (e) {
      // Intentionally empty
    }
    _pendingPositions = null;
    _pendingKey = null;
  }

  Future<Map<int, NodePosition>> loadPositions(String presetName) async {
    try {
      final key = '$_nodePositionsKeyPrefix$presetName';
      final jsonString = _prefs?.getString(key);
      if (jsonString == null) return {};

      final Map<String, dynamic> decoded = jsonDecode(jsonString);
      return decoded.map(
        (key, value) => MapEntry(int.parse(key), NodePosition.fromJson(value)),
      );
    } catch (e) {
      return {};
    }
  }

  Future<void> clearPositions(String presetName) async {
    try {
      final key = '$_nodePositionsKeyPrefix$presetName';
      await _prefs?.remove(key);
    } catch (e) {
      // Intentionally empty
    }
  }

  void dispose() {
    _saveTimer?.cancel();
  }
}
