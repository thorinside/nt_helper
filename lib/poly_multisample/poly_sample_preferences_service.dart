import 'package:shared_preferences/shared_preferences.dart';

class PolySamplePreferencesService {
  const PolySamplePreferencesService._(this._prefs);

  static const _lastLocalFolderKey = 'poly_multisample.lastLocalFolder';
  static const _lastSourceFolderKey = 'poly_multisample.lastSourceFolder';
  static const _lastImportOutputFolderKey =
      'poly_multisample.lastImportOutputFolder';
  static const _lastCustomOutputFolderKey =
      'poly_multisample.lastCustomOutputFolder';
  static const _lastWavExportFolderKey = 'poly_multisample.lastWavExportFolder';
  static const _lastMountedUploadFolderKey =
      'poly_multisample.lastMountedUploadFolder';

  final SharedPreferences _prefs;

  static Future<PolySamplePreferencesService> create() async {
    return PolySamplePreferencesService._(
      await SharedPreferences.getInstance(),
    );
  }

  String? get lastLocalFolder => _prefs.getString(_lastLocalFolderKey);

  String? get lastSourceFolder => _prefs.getString(_lastSourceFolderKey);

  String? get lastImportOutputFolder =>
      _prefs.getString(_lastImportOutputFolderKey);

  String? get lastCustomOutputFolder =>
      _prefs.getString(_lastCustomOutputFolderKey);

  String? get lastWavExportFolder => _prefs.getString(_lastWavExportFolderKey);

  String? get lastMountedUploadFolder =>
      _prefs.getString(_lastMountedUploadFolderKey);

  Future<void> setLastLocalFolder(String path) {
    return _prefs.setString(_lastLocalFolderKey, path);
  }

  Future<void> setLastSourceFolder(String path) {
    return _prefs.setString(_lastSourceFolderKey, path);
  }

  Future<void> setLastImportOutputFolder(String path) {
    return _prefs.setString(_lastImportOutputFolderKey, path);
  }

  Future<void> setLastCustomOutputFolder(String path) {
    return _prefs.setString(_lastCustomOutputFolderKey, path);
  }

  Future<void> setLastWavExportFolder(String path) {
    return _prefs.setString(_lastWavExportFolderKey, path);
  }

  Future<void> setLastMountedUploadFolder(String path) {
    return _prefs.setString(_lastMountedUploadFolderKey, path);
  }
}
