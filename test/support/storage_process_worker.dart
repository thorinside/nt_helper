// Standalone Flutter-engine worker: no test-runner exception handling/finally
// participates when the parent sends SIGKILL at a persistence checkpoint.
import 'dart:convert';
import 'dart:io';

import 'package:nt_helper/db/database.dart';
import 'package:nt_helper/services/macos_library_storage.dart';
import 'package:nt_helper/utils/app_directory.dart';
import 'package:path/path.dart' as p;

import 'storage_fixture.dart';

Future<void> main() async {
  final root = Platform.environment['NT_STORAGE_ROOT']!;
  final fault = Platform.environment['NT_STORAGE_FAULT'];
  final reached = <String>[];
  try {
    await getAppDirectory(
      isMacOS: true,
      docsProvider: () async {
        if (Platform.environment['NT_STORAGE_NO_DOCUMENTS'] == '1') {
          throw StateError('Documents must not be consulted');
        }
        return Directory(p.join(root, 'Documents'));
      },
      supportProvider: () async => Directory(p.join(root, 'Support')),
      storageCheckpoint: (point) async {
        reached.add(point);
        if (point == fault) {
          final signal = File(p.join(root, 'reached-$pid.tmp'));
          signal.writeAsStringSync(
            jsonEncode({'pid': pid, 'point': point}),
            flush: true,
          );
          signal.renameSync(p.join(root, 'reached'));
          // A timer keeps the standalone engine alive until the parent kills
          // it; an uncompleted Completer alone does not keep a VM event loop.
          await Future<void>.delayed(const Duration(days: 1));
        }
      },
    );
    final database = AppDatabase();
    final data = await contents(database);
    await database.close();
    File(p.join(root, 'result-$pid')).writeAsStringSync(
      jsonEncode({
        'selected': selectedLibrary!.file.path,
        'recovery': selectedLibrary!.recovery?.name,
        'contents': data,
        'reached': reached,
      }),
      flush: true,
    );
    exit(0);
  } catch (error) {
    File(p.join(root, 'result-$pid')).writeAsStringSync(
      jsonEncode({
        'error': error.toString(),
        'kind': error is StorageFailure ? error.kind.name : 'unexpected',
        'reached': reached,
      }),
      flush: true,
    );
    exit(2);
  }
}
