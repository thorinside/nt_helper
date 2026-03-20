import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

const _subDir = 'nt_helper';
const _markerFile = '.migrated';

/// Files to migrate from the old documents directory. Only the main SQLite
/// file is copied — WAL and SHM files are intentionally excluded because
/// copying them independently is non-atomic and can produce a corrupt
/// database. SQLite will create new WAL/SHM files as needed when it opens
/// the copied database.
const filesToMigrate = [
  'nt_helper_db.sqlite',
  'gallery_cache.json',
];

Completer<Directory>? _initCompleter;

/// Returns the dedicated nt_helper directory within the application documents
/// directory, creating it if needed. On first run, copies any existing files
/// (database, gallery cache) from the parent documents directory.
///
/// Uses a [Completer] to ensure the initialization logic runs only once, even
/// if called concurrently.
///
/// [docsProvider] is injectable for testing.
Future<Directory> getAppDirectory({
  Future<Directory> Function()? docsProvider,
}) async {
  if (_initCompleter != null) {
    return _initCompleter!.future;
  }

  _initCompleter = Completer<Directory>();

  try {
    final docsDir =
        docsProvider != null ? await docsProvider() : await getApplicationDocumentsDirectory();
    final appDir = Directory(p.join(docsDir.path, _subDir));

    if (!appDir.existsSync()) {
      appDir.createSync(recursive: true);
    }

    final marker = File(p.join(appDir.path, _markerFile));
    if (!marker.existsSync()) {
      migrateExistingFiles(docsDir, appDir);
      marker.createSync();
    }

    _initCompleter!.complete(appDir);
  } catch (e, st) {
    _initCompleter!.completeError(e, st);
    _initCompleter = null;
    rethrow;
  }

  return _initCompleter!.future;
}

/// Resets the cached directory so [getAppDirectory] will re-initialize.
/// Only intended for use in tests.
void resetAppDirectoryForTest() {
  _initCompleter = null;
}

/// Copies migratable files from [oldDir] to [newDir], then deletes the
/// originals. Deletion failures are silently ignored so they never break
/// the app.
void migrateExistingFiles(Directory oldDir, Directory newDir) {
  for (final fileName in filesToMigrate) {
    final oldFile = File(p.join(oldDir.path, fileName));
    final newFile = File(p.join(newDir.path, fileName));
    if (oldFile.existsSync() && !newFile.existsSync()) {
      oldFile.copySync(newFile.path);
    }
  }

  // Clean up old files after successful migration.
  for (final fileName in filesToMigrate) {
    try {
      final oldFile = File(p.join(oldDir.path, fileName));
      if (oldFile.existsSync()) {
        oldFile.deleteSync();
      }
    } catch (_) {
      // Deletion is best-effort; failures must not break the app.
    }
  }

  // Also clean up leftover WAL/SHM files from the old location.
  for (final suffix in ['-wal', '-shm']) {
    try {
      final oldFile = File(p.join(oldDir.path, 'nt_helper_db.sqlite$suffix'));
      if (oldFile.existsSync()) {
        oldFile.deleteSync();
      }
    } catch (_) {
      // Best-effort cleanup.
    }
  }
}
