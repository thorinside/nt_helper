import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/services/macos_library_storage.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';

import '../support/storage_fixture.dart';

// Fixed normative matrix, not a dynamically discovered list that silently
// shrinks when a production boundary disappears. Both caught faults and actual
// SIGKILL/relaunch exercise every row for each applicable source/initialization.
const _recordBoundaries = [
  'before:create',
  'after:create',
  'before:write',
  'during:write',
  'after:write',
  'before:sync',
  'after:sync',
  'before:witness-sync',
  'after:witness-sync',
  'before:publish',
  'after:publish',
  'before:directory-sync',
  'after:directory-sync',
];
List<String> _boundaries(bool initialize) => [
  for (final operation in [
    'directory',
    'control',
    'coordination',
    'reservation',
  ])
    for (final when in ['before', 'after']) '$when:$operation',
  for (final boundary in _recordBoundaries) '$boundary:reservation-record',
  'before:work',
  'after:work',
  if (initialize) ...[
    'before:initialize',
    'after:initialize',
  ] else ...[
    for (final operation in [
      'retain-0',
      'exclude-0',
      'retain-locked-0',
      'transfer-0',
    ])
      for (final when in ['before', 'after']) '$when:$operation',
    'during:transfer-0',
  ],
  'before:schema-0',
  'during:schema',
  'before:schema-commit',
  'after:schema-commit',
  'after:schema-0',
  'before:validation',
  'after:validation',
  'before:selection',
  for (final boundary in _recordBoundaries) '$boundary:selection-record',
  'after:selection',
  'before:open',
  'after:open',
];

class _Child {
  _Child(this.process, this.output);
  final Process process;
  final Future<String> output;
}

void main() {
  if (!Platform.isMacOS) {
    test(
      'macOS process-death storage matrix',
      () {},
      skip: 'Darwin storage primitives',
    );
    return;
  }
  final sdk = p.normalize(
    p.join(p.dirname(Platform.resolvedExecutable), '../../../../..'),
  );
  final dill = p.join(
    Directory.current.path,
    'build',
    'storage-worker-$pid.dill',
  );
  final children = <_Child>[];
  late Directory root;
  late Directory docs;
  late Directory support;
  late Directory appDir;
  StorageFixture? source;
  Map<String, List<String>>? expected;

  setUpAll(() async {
    final compiled = await Process.run(
      p.join(sdk, 'bin/cache/dart-sdk/bin/dartaotruntime'),
      [
        p.join(
          sdk,
          'bin/cache/dart-sdk/bin/snapshots/frontend_server_aot.dart.snapshot',
        ),
        '--sdk-root',
        p.join(sdk, 'bin/cache/artifacts/engine/common/flutter_patched_sdk'),
        '--target=flutter',
        '--packages=.dart_tool/package_config.json',
        '--output-dill=$dill',
        'test/support/storage_process_worker.dart',
      ],
    );
    expect(
      compiled.exitCode,
      0,
      reason: '${compiled.stdout}\n${compiled.stderr}',
    );
  });
  tearDownAll(() {
    if (File(dill).existsSync()) File(dill).deleteSync();
  });
  setUp(() {
    root = Directory.systemTemp.createTempSync('nt-storage-crash-');
    docs = Directory(p.join(root.path, 'Documents'))..createSync();
    support = Directory(p.join(root.path, 'Support'))..createSync();
    appDir = Directory(p.join(support.path, 'nt_helper'));
    source = null;
    expected = null;
  });
  tearDown(() async {
    for (final child in children) {
      child.process.kill(ProcessSignal.sigkill);
      await child.process.exitCode;
      await child.output;
    }
    children.clear();
    await source?.close();
    root.deleteSync(recursive: true);
  });

  Future<void> seed(String row) async {
    if (row == 'initialize') return;
    final location = row == 'R'
        ? docs
        : row == 'D'
        ? Directory(p.join(docs.path, 'nt_helper'))
        : appDir;
    source = await StorageFixture.create(location);
    expected = await contents(source!.app);
    // Exercise actual supported schema work, not merely querying an already
    // current schema. WAL-only assertion was made before this supported v13
    // fixture transformation; neither operation checkpoints the WAL.
    source!.raw.execute(
      'DROP TABLE algorithm_repeat_grammars; PRAGMA user_version=13',
    );
    expected!['algorithm_repeat_grammars'] = [];
    source!.assertWalOnly();
  }

  Future<_Child> start({String? fault, bool noDocuments = false}) async {
    final process = await Process.start(
      Platform.resolvedExecutable,
      [
        '--disable-vm-service',
        '--enable-software-rendering',
        '--non-interactive',
        '--packages=${p.join(Directory.current.path, '.dart_tool/package_config.json')}',
        '--flutter-assets-dir=${p.join(Directory.current.path, 'build/unit_test_assets')}',
        dill,
      ],
      environment: {
        'NT_STORAGE_ROOT': root.path,
        'NT_STORAGE_FAULT': ?fault,
        if (noDocuments) 'NT_STORAGE_NO_DOCUMENTS': '1',
      },
    );
    final output = Future.wait([
      process.stdout.transform(utf8.decoder).join(),
      process.stderr.transform(utf8.decoder).join(),
    ]).then((v) => v.join('\n'));
    final child = _Child(process, output);
    children.add(child);
    return child;
  }

  Future<Map<String, dynamic>> finish(_Child child) async {
    final code = await child.process.exitCode.timeout(
      const Duration(seconds: 30),
    );
    final output = await child.output;
    final result = File(p.join(root.path, 'result-${child.process.pid}'));
    expect(result.existsSync(), isTrue, reason: 'child exit=$code: $output');
    final value = jsonDecode(result.readAsStringSync()) as Map<String, dynamic>;
    result.deleteSync();
    return value;
  }

  Future<void> waitReached(_Child child, String point) async {
    final signal = File(p.join(root.path, 'reached'));
    final timer = Stopwatch()..start();
    while (!signal.existsSync() &&
        timer.elapsed < const Duration(seconds: 25)) {
      if (File(p.join(root.path, 'result-${child.process.pid}')).existsSync()) {
        fail('Boundary $point not reached: ${await finish(child)}');
      }
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    expect(signal.existsSync(), isTrue, reason: 'Timed out at $point');
    final value = jsonDecode(signal.readAsStringSync()) as Map;
    expect(value['pid'], child.process.pid);
    expect(value['point'], point);
    signal.deleteSync();
  }

  Future<Map<String, dynamic>> recover({bool noDocuments = false}) async {
    final result = await finish(await start(noDocuments: noDocuments));
    expect(result['error'], isNull, reason: '$result');
    if (expected != null) {
      expect(result['contents'], expected);
    } else {
      expect(
        (result['contents'] as Map).values.every(
          (rows) => (rows as List).isEmpty,
        ),
        isTrue,
      );
    }
    return result;
  }

  for (final row in ['R', 'D', 'A', 'initialize']) {
    for (final point in _boundaries(row == 'initialize')) {
      test('$row SIGKILL/relaunch $point', () async {
        await seed(row);
        final child = await start(fault: point);
        await waitReached(child, point);
        child.process.kill(ProcessSignal.sigkill);
        expect(await child.process.exitCode, isNot(0));
        final retained = appDir.existsSync()
            ? appDir
                  .listSync(recursive: true)
                  .whereType<File>()
                  .map((f) => f.path)
                  .toSet()
            : <String>{};
        final result = await recover();
        expect(retained.every((path) => File(path).existsSync()), isTrue);
        final again = await recover(noDocuments: true);
        expect(again['selected'], result['selected']);
      });

      test('$row caught persistent fault/Retry $point', () async {
        await seed(row);
        var interrupted = false;
        final storage = MacosLibraryStorage(
          directory: appDir,
          documentsProvider: () async => docs,
          checkpoint: (boundary) async {
            if (boundary == point) {
              interrupted = true;
              throw const FileSystemException(
                'simulated ENOSPC',
                '',
                OSError('disk full', 28),
              );
            }
          },
        );
        await expectLater(storage.prepare(), throwsA(isA<StorageFailure>()));
        expect(
          interrupted,
          isTrue,
          reason: 'Mandatory fault boundary disappeared: $point',
        );
        await recover();
      });
    }
  }

  for (final mode in ['WAL', 'DELETE']) {
    test(
      '$mode post-crash commits and held writer are included through cutover; source exclusion really prevents writers',
      () async {
        await seed('R');
        if (mode == 'DELETE') {
          source!.raw.execute(
            'PRAGMA wal_checkpoint(TRUNCATE); PRAGMA journal_mode=DELETE',
          );
        }
        final child = await start(fault: 'before:selection');
        await waitReached(child, 'before:selection');
        expect(
          () => source!.raw.execute('BEGIN IMMEDIATE'),
          throwsA(isA<SqliteException>()),
        );
        child.process.kill(ProcessSignal.sigkill);
        await child.process.exitCode;
        source!.addLateCommit();
        expected!['metadata_cache']!.add(
          jsonEncode({
            'cache_key': 'late',
            'cache_value': 'committed after crash',
          }),
        );
        expected!['metadata_cache']!.sort();
        source!.raw.execute(
          "BEGIN IMMEDIATE; INSERT INTO metadata_cache VALUES ('last-writer', 'committed at release')",
        );
        final busy = await finish(await start());
        expect(busy['kind'], 'busy');
        source!.raw.execute('COMMIT');
        expected!['metadata_cache']!.add(
          jsonEncode({
            'cache_key': 'last-writer',
            'cache_value': 'committed at release',
          }),
        );
        expected!['metadata_cache']!.sort();
        final result = await recover();
        source!.raw.execute('BEGIN IMMEDIATE; ROLLBACK');
        expect(File(result['selected'] as String).existsSync(), isTrue);
      },
    );
  }

  test(
    'multiple process startup/Retry attempts serialize one selection and progress after a killed authority',
    () async {
      await seed('D');
      final first = await start(fault: 'before:selection');
      await waitReached(first, 'before:selection');
      for (var i = 0; i < 3; i++) {
        expect((await finish(await start()))['kind'], 'busy');
      }
      first.process.kill(ProcessSignal.sigkill);
      await first.process.exitCode;
      final selected = await recover();
      for (var i = 0; i < 3; i++) {
        expect(
          (await recover(noDocuments: true))['selected'],
          selected['selected'],
        );
      }
      expect(
        appDir
            .listSync(recursive: true)
            .where((f) => p.basename(f.path) == 'selected.json'),
        hasLength(1),
      );
    },
  );

  test(
    'simultaneous process startups and Retry converge on one authority',
    () async {
      await seed('R');
      final racing = await Future.wait(List.generate(4, (_) => start()));
      final results = await Future.wait(racing.map(finish));
      final successes = results.where((r) => r['error'] == null).toList();
      expect(successes, isNotEmpty);
      for (final result in results) {
        if (result['error'] != null) {
          expect(result['kind'], 'busy');
        } else {
          expect(result['selected'], successes.first['selected']);
          expect(result['contents'], expected);
        }
      }
      expect((await recover())['selected'], successes.first['selected']);
    },
  );

  for (final point in [
    'during:schema',
    'before:schema-commit',
    'after:schema-commit',
  ]) {
    test(
      'selected schema interruption $point reopens the same identity without Documents or source access',
      () async {
        await seed('A');
        final initial = await recover();
        final selected = sqlite3.open(
          initial['selected'] as String,
          mode: OpenMode.readWrite,
        );
        selected.execute(
          "PRAGMA journal_mode=PERSIST; DROP TABLE algorithm_repeat_grammars; PRAGMA user_version=13; INSERT INTO metadata_cache VALUES ('destination-only', 'post-cutover edit')",
        );
        selected.close();
        expected!['metadata_cache']!.add(
          jsonEncode({
            'cache_key': 'destination-only',
            'cache_value': 'post-cutover edit',
          }),
        );
        expected!['metadata_cache']!.sort();
        final child = await start(fault: point, noDocuments: true);
        await waitReached(child, point);
        child.process.kill(ProcessSignal.sigkill);
        await child.process.exitCode;
        source!.raw.execute(
          "INSERT INTO metadata_cache VALUES ('old-release', 'must not reimport')",
        );
        final again = await recover(noDocuments: true);
        expect(again['selected'], initial['selected']);
      },
    );
  }
}
