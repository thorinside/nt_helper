import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/db/database.dart';
import 'package:nt_helper/models/algorithm_repeat_grammar.dart';
import 'package:nt_helper/services/metadata_import_service.dart';
import 'package:nt_helper/services/offline_algorithm_shape_resolver.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase database;
  late Map<String, dynamic> bundle;
  late OfflineAlgorithmShapeResolver resolver;

  setUpAll(() async {
    final source = await File(
      'assets/metadata/full_metadata.json',
    ).readAsString();
    bundle = jsonDecode(source) as Map<String, dynamic>;
    database = AppDatabase.forTesting(NativeDatabase.memory());
    expect(
      await MetadataImportService(database).importFromJson(source),
      isTrue,
    );
    resolver = OfflineAlgorithmShapeResolver(database.metadataDao);
  });

  tearDownAll(() async {
    await database.close();
  });

  test('bundle is version 3 and contains the named repeat grammars', () {
    expect(bundle['exportType'], 'full_metadata');
    expect(bundle['exportVersion'], 3);
    final rows = ((bundle['tables'] as Map)['algorithmRepeatGrammars'] as List)
        .cast<Map<String, dynamic>>();
    expect(
      rows.map((row) => row['algorithmGuid']),
      containsAll(['quan', 'mix1']),
    );
  });

  test('quan expands Channels 1, 4, and 12', () async {
    final one = await resolver.resolve('quan', [1]);
    final four = await resolver.resolve('quan', [4]);
    final twelve = await resolver.resolve('quan', [12]);

    expect(one.usedGrammar, isTrue);
    expect(four.usedGrammar, isTrue);
    expect(twelve.usedGrammar, isTrue);
    expect(one.snapshot.parameters.length, 158);
    expect(four.snapshot.parameters.length, 176);
    expect(twelve.snapshot.parameters.length, 224);
    expect(four.snapshot.parameters.last.name, '4:MIDI channel (out)');
    expect(
      twelve.snapshot.pages.map((page) => page.name),
      contains('Channel 12'),
    );
  });

  test('mix1 expands 4 Channels x 2 Sends with valid relationships', () async {
    final resolved = await resolver.resolve('mix1', [4, 2]);
    final snapshot = resolved.snapshot;

    expect(resolved.usedGrammar, isTrue);
    expect(snapshot.parameters, hasLength(39));
    expect(snapshot.pages.map((page) => page.name), [
      'Common',
      'Send 1',
      'Send 2',
      'Channel 1',
      'Channel 2',
      'Channel 3',
      'Channel 4',
      'Algorithm',
    ]);
    expect(
      snapshot.parameters.map((parameter) => parameter.name),
      contains('4:2:Send gain'),
    );
    expect(
      snapshot.pageMemberships.every(
        (edge) =>
            edge.pageIndex >= 0 &&
            edge.pageIndex < snapshot.pages.length &&
            edge.parameterNumber >= 0 &&
            edge.parameterNumber < snapshot.parameters.length,
      ),
      isTrue,
    );
    expect(
      snapshot.outputUsage.every(
        (edge) =>
            edge.parameterNumber >= 0 &&
            edge.parameterNumber < snapshot.parameters.length &&
            edge.affectedParameterNumber >= 0 &&
            edge.affectedParameterNumber < snapshot.parameters.length,
      ),
      isTrue,
    );
  });

  test(
    'delm has no grammar and allocation values keep flat topology',
    () async {
      final one = await resolver.resolve('delm', [1]);
      final thirty = await resolver.resolve('delm', [30]);

      expect(one.usedGrammar, isFalse);
      expect(thirty.usedGrammar, isFalse);
      expect(one.snapshot.parameters, thirty.snapshot.parameters);
      expect(one.snapshot.pages, thirty.snapshot.pages);
      expect(one.snapshot.pageMemberships, thirty.snapshot.pageMemberships);
    },
  );

  test(
    'every grammar decodes and reconstructs its canonical flat rows',
    () async {
      final rows =
          ((bundle['tables'] as Map)['algorithmRepeatGrammars'] as List)
              .cast<Map<String, dynamic>>();
      for (final row in rows) {
        final grammar = AlgorithmRepeatGrammar.fromCompactJson(row['grammar']);
        final guid = row['algorithmGuid'] as String;
        final fallback = await resolver.resolve(guid, const []);
        expect(fallback.usedGrammar, isFalse, reason: guid);
        expect(
          grammar.expand(fallback.snapshot, grammar.baselineSpecifications),
          fallback.snapshot,
          reason: guid,
        );

        final encoded = jsonEncode(row['grammar']);
        expect(encoded, isNot(contains('snapshot')), reason: guid);
        expect(encoded, isNot(contains('profile')), reason: guid);
        expect(encoded, isNot(contains('proof')), reason: guid);
      }
    },
  );
}
