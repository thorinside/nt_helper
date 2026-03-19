import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/utils/app_directory.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory tempRoot;

  setUp(() {
    resetAppDirectoryForTest();
    tempRoot = Directory.systemTemp.createTempSync('app_directory_test_');
  });

  tearDown(() {
    resetAppDirectoryForTest();
    if (tempRoot.existsSync()) {
      tempRoot.deleteSync(recursive: true);
    }
  });

  group('getAppDirectory', () {
    test('creates nt_helper subdirectory', () async {
      final result = await getAppDirectory(
        docsProvider: () async => tempRoot,
      );

      expect(result.existsSync(), isTrue);
      expect(p.basename(result.path), 'nt_helper');
    });

    test('creates .migrated marker file after first run', () async {
      final result = await getAppDirectory(
        docsProvider: () async => tempRoot,
      );

      final marker = File(p.join(result.path, '.migrated'));
      expect(marker.existsSync(), isTrue);
    });

    test('returns same directory on subsequent calls', () async {
      final first = await getAppDirectory(
        docsProvider: () async => tempRoot,
      );
      final second = await getAppDirectory(
        docsProvider: () async => tempRoot,
      );

      expect(first.path, second.path);
    });

    test('concurrent calls return the same directory', () async {
      final futures = List.generate(
        5,
        (_) => getAppDirectory(docsProvider: () async => tempRoot),
      );

      final results = await Future.wait(futures);
      for (final dir in results) {
        expect(dir.path, results.first.path);
      }
    });
  });

  group('migration', () {
    test('copies sqlite and gallery_cache from old location', () async {
      File(p.join(tempRoot.path, 'nt_helper_db.sqlite'))
          .writeAsStringSync('db-content');
      File(p.join(tempRoot.path, 'gallery_cache.json'))
          .writeAsStringSync('cache-content');

      final result = await getAppDirectory(
        docsProvider: () async => tempRoot,
      );

      expect(
        File(p.join(result.path, 'nt_helper_db.sqlite')).readAsStringSync(),
        'db-content',
      );
      expect(
        File(p.join(result.path, 'gallery_cache.json')).readAsStringSync(),
        'cache-content',
      );
    });

    test('does not copy WAL or SHM files', () async {
      File(p.join(tempRoot.path, 'nt_helper_db.sqlite'))
          .writeAsStringSync('db');
      File(p.join(tempRoot.path, 'nt_helper_db.sqlite-wal'))
          .writeAsStringSync('wal');
      File(p.join(tempRoot.path, 'nt_helper_db.sqlite-shm'))
          .writeAsStringSync('shm');

      final result = await getAppDirectory(
        docsProvider: () async => tempRoot,
      );

      expect(
        File(p.join(result.path, 'nt_helper_db.sqlite-wal')).existsSync(),
        isFalse,
      );
      expect(
        File(p.join(result.path, 'nt_helper_db.sqlite-shm')).existsSync(),
        isFalse,
      );
    });

    test('deletes old files after successful migration', () async {
      File(p.join(tempRoot.path, 'nt_helper_db.sqlite'))
          .writeAsStringSync('db');
      File(p.join(tempRoot.path, 'gallery_cache.json'))
          .writeAsStringSync('cache');

      await getAppDirectory(docsProvider: () async => tempRoot);

      expect(
        File(p.join(tempRoot.path, 'nt_helper_db.sqlite')).existsSync(),
        isFalse,
      );
      expect(
        File(p.join(tempRoot.path, 'gallery_cache.json')).existsSync(),
        isFalse,
      );
    });

    test('cleans up old WAL and SHM files', () async {
      File(p.join(tempRoot.path, 'nt_helper_db.sqlite'))
          .writeAsStringSync('db');
      File(p.join(tempRoot.path, 'nt_helper_db.sqlite-wal'))
          .writeAsStringSync('wal');
      File(p.join(tempRoot.path, 'nt_helper_db.sqlite-shm'))
          .writeAsStringSync('shm');

      await getAppDirectory(docsProvider: () async => tempRoot);

      expect(
        File(p.join(tempRoot.path, 'nt_helper_db.sqlite-wal')).existsSync(),
        isFalse,
      );
      expect(
        File(p.join(tempRoot.path, 'nt_helper_db.sqlite-shm')).existsSync(),
        isFalse,
      );
    });

    test('skips migration when .migrated marker exists', () async {
      final appDir = Directory(p.join(tempRoot.path, 'nt_helper'));
      appDir.createSync();
      File(p.join(appDir.path, '.migrated')).createSync();

      // Place a file in the old location that would be migrated
      File(p.join(tempRoot.path, 'nt_helper_db.sqlite'))
          .writeAsStringSync('should-not-be-copied');

      final result = await getAppDirectory(
        docsProvider: () async => tempRoot,
      );

      // File should NOT have been copied since marker exists
      expect(
        File(p.join(result.path, 'nt_helper_db.sqlite')).existsSync(),
        isFalse,
      );
    });

    test('runs migration when directory exists but marker is missing', () async {
      final appDir = Directory(p.join(tempRoot.path, 'nt_helper'));
      appDir.createSync();

      // No .migrated marker, so migration should run
      File(p.join(tempRoot.path, 'nt_helper_db.sqlite'))
          .writeAsStringSync('should-be-copied');

      final result = await getAppDirectory(
        docsProvider: () async => tempRoot,
      );

      expect(
        File(p.join(result.path, 'nt_helper_db.sqlite')).readAsStringSync(),
        'should-be-copied',
      );
    });
  });
}
