import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:nt_helper/utils/app_directory.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqlite3/sqlite3.dart';

class DatabaseIntegrityResult {
  final bool isCorrupt;
  final String? error;
  final bool fileExists;

  const DatabaseIntegrityResult({
    required this.isCorrupt,
    this.error,
    required this.fileExists,
  });
}

class DatabaseIntegrityService {
  static const _dbFileName = 'nt_helper_db.sqlite';

  static Future<File> getDatabaseFile() async {
    final dbFolder = await getAppDirectory();
    return File(p.join(dbFolder.path, _dbFileName));
  }

  static Future<DatabaseIntegrityResult> checkIntegrity() async {
    final file = await getDatabaseFile();
    if (!file.existsSync()) {
      return const DatabaseIntegrityResult(isCorrupt: false, fileExists: false);
    }

    try {
      final db = sqlite3.open(file.path, mode: OpenMode.readOnly);
      try {
        final result = db.select('PRAGMA integrity_check');
        final status = result.first.values.first as String;
        if (status == 'ok') {
          return const DatabaseIntegrityResult(
            isCorrupt: false,
            fileExists: true,
          );
        } else {
          return DatabaseIntegrityResult(
            isCorrupt: true,
            error: status,
            fileExists: true,
          );
        }
      } finally {
        db.close();
      }
    } catch (e) {
      return DatabaseIntegrityResult(
        isCorrupt: _isDatabaseCorruptionError(e),
        error: e.toString(),
        fileExists: true,
      );
    }
  }

  @visibleForTesting
  static bool isDatabaseCorruptionError(Object error) {
    return _isDatabaseCorruptionError(error);
  }

  static bool _isDatabaseCorruptionError(Object error) {
    final message = error.toString().toLowerCase();

    // If sqlite3 itself cannot be loaded, the database file has not been
    // inspected. Treating that as corruption would delete healthy user data and
    // still leave startup broken.
    const nativeLibraryLoadMarkers = [
      'couldn\'t resolve native function',
      'failed to load dynamic library',
      'dynamiclibrary.open',
      'sqlite3.dll',
      'winsqlite3.dll',
      'libsqlite3',
    ];
    if (nativeLibraryLoadMarkers.any(message.contains)) {
      return false;
    }

    return true;
  }

  static Future<void> deleteDatabase() async {
    final file = await getDatabaseFile();
    if (file.existsSync()) {
      await file.delete();
    }
    // Also delete WAL and SHM files if they exist
    final walFile = File('${file.path}-wal');
    final shmFile = File('${file.path}-shm');
    if (walFile.existsSync()) await walFile.delete();
    if (shmFile.existsSync()) await shmFile.delete();
  }

  static Future<void> resetAll() async {
    await deleteDatabase();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
