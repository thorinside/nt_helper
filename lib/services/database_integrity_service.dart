import 'dart:io';

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
    return selectedLibrary?.file ?? File(p.join(dbFolder.path, _dbFileName));
  }

  static Future<DatabaseIntegrityResult> checkIntegrity() async {
    final file = await getDatabaseFile();
    final selected = selectedLibrary;
    if (selected != null) {
      // macOS selection has already validated the actual AppDatabase. Reopen
      // the bound identity, propagating access/native/missing failures instead
      // of sending them through the historical delete-and-create fallback.
      final database = await selected.open();
      await database.close();
      return const DatabaseIntegrityResult(isCorrupt: false, fileExists: true);
    }
    if (!file.existsSync()) {
      return const DatabaseIntegrityResult(isCorrupt: false, fileExists: false);
    }

    try {
      final db = sqlite3.open(file.path, mode: OpenMode.readOnly);
      try {
        final status = inspect(db);
        if (status == null) {
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

  static bool isDatabaseCorruptionError(Object error) {
    return _isDatabaseCorruptionError(error);
  }

  /// Null means SQLite completed inspection and found no damage. Inspection
  /// failures propagate; neither an error message nor failure to load SQLite
  /// is evidence that the user's library is corrupt.
  static String? inspect(Database database) {
    final failures = database
        .select('PRAGMA integrity_check')
        .map((row) => row.values.first as String)
        .where((status) => status != 'ok')
        .toList();
    return failures.isEmpty ? null : failures.join('\n');
  }

  static bool _isDatabaseCorruptionError(Object error) =>
      error is SqliteException &&
      (error.resultCode == 11 || error.resultCode == 26) &&
      [11, 26].contains(error.extendedResultCode & 0xff);

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
