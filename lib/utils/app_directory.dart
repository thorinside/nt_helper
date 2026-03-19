import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

const _subDir = 'nt_helper';

/// Returns the dedicated nt_helper directory within the application documents
/// directory, creating it if needed. On first run, copies any existing files
/// (database, gallery cache) from the parent documents directory.
Future<Directory> getAppDirectory() async {
  final docsDir = await getApplicationDocumentsDirectory();
  final appDir = Directory(p.join(docsDir.path, _subDir));

  if (!appDir.existsSync()) {
    appDir.createSync(recursive: true);
    _migrateExistingFiles(docsDir, appDir);
  }

  return appDir;
}

void _migrateExistingFiles(Directory oldDir, Directory newDir) {
  const filesToMigrate = [
    'nt_helper_db.sqlite',
    'nt_helper_db.sqlite-wal',
    'nt_helper_db.sqlite-shm',
    'gallery_cache.json',
  ];

  for (final fileName in filesToMigrate) {
    final oldFile = File(p.join(oldDir.path, fileName));
    final newFile = File(p.join(newDir.path, fileName));
    if (oldFile.existsSync() && !newFile.existsSync()) {
      oldFile.copySync(newFile.path);
    }
  }
}
