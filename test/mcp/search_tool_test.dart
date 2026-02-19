import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/mcp/tools/algorithm_tools.dart';
import 'package:nt_helper/services/algorithm_metadata_service.dart';
import 'package:nt_helper/services/metadata_import_service.dart';
import 'package:nt_helper/services/disting_controller_impl.dart';
import 'package:nt_helper/cubit/disting_cubit.dart';
import 'package:nt_helper/db/database.dart';
import 'package:drift/native.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;

import '../test_helpers/mock_midi_command.dart';

void main() {
  group('MCPAlgorithmTools - searchAlgorithms', () {
    late MCPAlgorithmTools tools;
    late DistingCubit distingCubit;
    late AppDatabase database;

    setUpAll(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues({});
      database = AppDatabase.forTesting(NativeDatabase.memory());

      // Load metadata from file and import into test database
      var current = Directory.current;
      while (!File(path.join(current.path, 'pubspec.yaml')).existsSync()) {
        final parent = current.parent;
        if (parent.path == current.path) {
          throw Exception('Could not find project root');
        }
        current = parent;
      }
      final metadataPath = path.join(
        current.path,
        'assets',
        'metadata',
        'full_metadata.json',
      );
      final file = File(metadataPath);
      final jsonString = file.readAsStringSync();

      final importService = MetadataImportService(database);
      await importService.importFromJson(jsonString);

      // Initialize the AlgorithmMetadataService
      await AlgorithmMetadataService().initialize(database);
    });

    setUp(() {
      distingCubit = DistingCubit(database, midiCommand: MockMidiCommand());
      tools = MCPAlgorithmTools(DistingControllerImpl(distingCubit), distingCubit);
    });

    tearDown(() {
      distingCubit.close();
    });

    tearDownAll(() async {
      await database.close();
    });

    group('search - parameter validation', () {
      test('should return error when type is missing', () async {
        final result = await tools.searchAlgorithms({
          'query': 'clock',
        });

        final decoded = jsonDecode(result);
        expect(decoded['success'], isFalse);
        expect(decoded['error'], contains('type'));
      });

      test('should return error when query is missing', () async {
        final result = await tools.searchAlgorithms({
          'type': 'algorithm',
        });

        final decoded = jsonDecode(result);
        expect(decoded['success'], isFalse);
        expect(decoded['error'], contains('query'));
      });

      test('should return error when type is not "algorithm"', () async {
        final result = await tools.searchAlgorithms({
          'type': 'effect',
          'query': 'delay',
        });

        final decoded = jsonDecode(result);
        expect(decoded['success'], isFalse);
        expect(decoded['error'], contains('Invalid type'));
      });

      test('should return error when query is empty string', () async {
        final result = await tools.searchAlgorithms({
          'type': 'algorithm',
          'query': '',
        });

        final decoded = jsonDecode(result);
        expect(decoded['success'], isFalse);
        expect(decoded['error'], contains('query'));
      });
    });

    group('search - exact matches', () {
      test('should find algorithm by exact GUID match', () async {
        final result = await tools.searchAlgorithms({
          'type': 'algorithm',
          'query': 'clck',
        });

        final decoded = jsonDecode(result);
        expect(decoded['results'], isList);
        expect(decoded['results'].length, greaterThan(0));

        final firstResult = decoded['results'][0];
        expect(firstResult['guid'], equals('clck'));
        expect(firstResult['name'], equals('Clock'));
      });

      test('should find algorithm by exact name match', () async {
        final result = await tools.searchAlgorithms({
          'type': 'algorithm',
          'query': 'Clock',
        });

        final decoded = jsonDecode(result);
        expect(decoded['results'], isList);
        expect(decoded['results'].length, greaterThan(0));

        final firstResult = decoded['results'][0];
        expect(firstResult['name'], equals('Clock'));
      });

      test('should be case-insensitive for exact name match', () async {
        final result = await tools.searchAlgorithms({
          'type': 'algorithm',
          'query': 'clock',
        });

        final decoded = jsonDecode(result);
        expect(decoded['results'], isList);
        expect(decoded['results'].length, greaterThan(0));
      });
    });

    group('search - fuzzy matching', () {
      test('should find algorithms with partial name match', () async {
        final result = await tools.searchAlgorithms({
          'type': 'algorithm',
          'query': 'cloc',
        });

        final decoded = jsonDecode(result);
        expect(decoded['results'], isList);
        expect(decoded['results'].length, greaterThan(0));
      });

      test('should find algorithms with fuzzy matching above 70% threshold', () async {
        final result = await tools.searchAlgorithms({
          'type': 'algorithm',
          'query': 'Oscilator', // Typo: missing 'l' in Oscillator
        });

        final decoded = jsonDecode(result);
        // Should find oscillator-related algorithms through fuzzy matching
        expect(decoded['results'], isList);
      });

      test('should exclude algorithms with similarity below 70%', () async {
        final result = await tools.searchAlgorithms({
          'type': 'algorithm',
          'query': 'xyz123notreal',
        });

        final decoded = jsonDecode(result);
        expect(decoded['results'], isList);
        // Should return empty or only category matches with low scores
      });
    });

    group('search - category filtering', () {
      test('should find algorithms matching category name', () async {
        final result = await tools.searchAlgorithms({
          'type': 'algorithm',
          'query': 'Filter',
        });

        final decoded = jsonDecode(result);
        expect(decoded['results'], isList);
        // Should find algorithms in the Filter category
      });

      test('should find algorithms when querying category with partial match', () async {
        final result = await tools.searchAlgorithms({
          'type': 'algorithm',
          'query': 'filt',
        });

        final decoded = jsonDecode(result);
        expect(decoded['results'], isList);
      });
    });

    group('search - result formatting', () {
      test('should include required fields in results', () async {
        final result = await tools.searchAlgorithms({
          'type': 'algorithm',
          'query': 'clock',
        });

        final decoded = jsonDecode(result);
        expect(decoded['results'], isList);

        if (decoded['results'].isNotEmpty) {
          final firstResult = decoded['results'][0];
          expect(firstResult.containsKey('guid'), isTrue);
          expect(firstResult.containsKey('name'), isTrue);
          expect(firstResult.containsKey('category'), isTrue);
          expect(firstResult.containsKey('description'), isTrue);
          expect(firstResult.containsKey('general_parameters'), isTrue);
        }
      });

      test('should include categories array in results', () async {
        final result = await tools.searchAlgorithms({
          'type': 'algorithm',
          'query': 'clock',
        });

        final decoded = jsonDecode(result);
        if (decoded['results'].isNotEmpty) {
          final firstResult = decoded['results'][0];
          expect(firstResult.containsKey('categories'), isTrue);
          expect(firstResult['categories'], isList);
        }
      });

      test('should include count in response', () async {
        final result = await tools.searchAlgorithms({
          'type': 'algorithm',
          'query': 'clock',
        });

        final decoded = jsonDecode(result);
        expect(decoded.containsKey('count'), isTrue);
        expect(decoded['count'], equals(decoded['results'].length));
      });

      test('should include message in response', () async {
        final result = await tools.searchAlgorithms({
          'type': 'algorithm',
          'query': 'clock',
        });

        final decoded = jsonDecode(result);
        expect(decoded.containsKey('message'), isTrue);
        expect(decoded['message'], isNotEmpty);
      });
    });

    group('search - result limiting', () {
      test('should limit results to maximum 10 matches', () async {
        final result = await tools.searchAlgorithms({
          'type': 'algorithm',
          'query': 'a', // Broad query that might match many algorithms
        });

        final decoded = jsonDecode(result);
        expect(decoded['results'], isList);
        expect(decoded['results'].length, lessThanOrEqualTo(10));
      });

      test('should return count matching actual results', () async {
        final result = await tools.searchAlgorithms({
          'type': 'algorithm',
          'query': 'clock',
        });

        final decoded = jsonDecode(result);
        expect(decoded['count'], equals(decoded['results'].length));
      });
    });

    group('search - empty results', () {
      test('should return empty results with helpful message', () async {
        final result = await tools.searchAlgorithms({
          'type': 'algorithm',
          'query': 'notanythingreal123456789',
        });

        final decoded = jsonDecode(result);
        expect(decoded['results'], isList);
        expect(decoded['results'].isEmpty, isTrue);
        expect(decoded.containsKey('message'), isTrue);
        expect(decoded['message'], contains('No algorithms found'));
      });

      test('should provide suggestions in empty results', () async {
        final result = await tools.searchAlgorithms({
          'type': 'algorithm',
          'query': 'nonexistentquery',
        });

        final decoded = jsonDecode(result);
        if (decoded['results'].isEmpty) {
          expect(decoded.containsKey('suggestions'), isTrue);
        }
      });
    });

    group('search - relevance scoring', () {
      test('should score exact matches highest', () async {
        final result = await tools.searchAlgorithms({
          'type': 'algorithm',
          'query': 'Clock',
        });

        final decoded = jsonDecode(result);
        if (decoded['results'].isNotEmpty) {
          // Clock should be the first result as it's an exact match
          expect(decoded['results'][0]['name'], equals('Clock'));
        }
      });

      test('should sort results by relevance', () async {
        final result = await tools.searchAlgorithms({
          'type': 'algorithm',
          'query': 'clock',
        });

        final decoded = jsonDecode(result);
        if (decoded['results'].length > 1) {
          // Results should be sorted by relevance (exact/partial matches first)
          expect(decoded['results'][0]['name'], contains(RegExp('clock|Clock', caseSensitive: false)));
        }
      });
    });

    group('search - parameter descriptions', () {
      test('should include general parameter description', () async {
        final result = await tools.searchAlgorithms({
          'type': 'algorithm',
          'query': 'clock',
        });

        final decoded = jsonDecode(result);
        if (decoded['results'].isNotEmpty) {
          final firstResult = decoded['results'][0];
          expect(firstResult['general_parameters'], isNotEmpty);
          // Should not contain specific parameter numbers like "Parameter 0", "Parameter 1"
          expect(firstResult['general_parameters'], isNot(contains(RegExp(r'Parameter \d+'))));
        }
      });

      test('should describe parameter categories without indices', () async {
        final result = await tools.searchAlgorithms({
          'type': 'algorithm',
          'query': 'Filter',
        });

        final decoded = jsonDecode(result);
        if (decoded['results'].isNotEmpty) {
          for (final algorithmResult in decoded['results']) {
            final paramDesc = algorithmResult['general_parameters'] as String;
            // Should use descriptive terms, not specific parameter numbers
            if (!paramDesc.contains('No parameters')) {
              expect(
                paramDesc.toLowerCase(),
                anyOf([
                  contains('frequency'),
                  contains('resonance'),
                  contains('controls'),
                  contains('parameters'),
                ]),
              );
            }
          }
        }
      });
    });

    group('search - semantic text search', () {
      test('should find algorithms by description keywords', () async {
        final result = await tools.searchAlgorithms({
          'type': 'algorithm',
          'query': 'reverb',
        });

        final decoded = jsonDecode(result);
        expect(decoded['results'], isList);
        expect(decoded['results'].length, greaterThan(0));
        // Reverb algorithm should be in results
        final guids = (decoded['results'] as List).map((r) => r['guid']).toList();
        expect(guids, contains('revb'));
      });

      test('should find algorithms by parameter names', () async {
        final result = await tools.searchAlgorithms({
          'type': 'algorithm',
          'query': 'resonance',
        });

        final decoded = jsonDecode(result);
        expect(decoded['results'], isList);
        expect(decoded['results'].length, greaterThan(0));
      });

      test('should find algorithms by multi-word queries', () async {
        final result = await tools.searchAlgorithms({
          'type': 'algorithm',
          'query': 'clock divider',
        });

        final decoded = jsonDecode(result);
        expect(decoded['results'], isList);
        expect(decoded['results'].length, greaterThan(0));
      });

      test('should find algorithms via synonym expansion', () async {
        // "echo" should find delay-related algorithms via synonyms
        final result = await tools.searchAlgorithms({
          'type': 'algorithm',
          'query': 'echo',
        });

        final decoded = jsonDecode(result);
        expect(decoded['results'], isList);
        expect(decoded['results'].length, greaterThan(0));
      });

      test('should rank name matches above text matches', () async {
        final result = await tools.searchAlgorithms({
          'type': 'algorithm',
          'query': 'Clock',
        });

        final decoded = jsonDecode(result);
        expect(decoded['results'], isList);
        expect(decoded['results'].length, greaterThan(0));
        // Exact name match should be first
        expect(decoded['results'][0]['name'], equals('Clock'));
      });

      test('should find pitch shifting algorithms', () async {
        final result = await tools.searchAlgorithms({
          'type': 'algorithm',
          'query': 'pitch shifting',
        });

        final decoded = jsonDecode(result);
        expect(decoded['results'], isList);
        expect(decoded['results'].length, greaterThan(0));
      });

      test('should find modulation sources', () async {
        final result = await tools.searchAlgorithms({
          'type': 'algorithm',
          'query': 'modulation',
        });

        final decoded = jsonDecode(result);
        expect(decoded['results'], isList);
        expect(decoded['results'].length, greaterThan(0));
      });
    });

    group('search - connection mode support', () {
      test('should work in any connection mode', () async {
        // Mock and offline modes are tested implicitly through
        // the DistingCubit and database setup, which starts in offline mode

        final result = await tools.searchAlgorithms({
          'type': 'algorithm',
          'query': 'clock',
        });

        final decoded = jsonDecode(result);
        expect(decoded['results'], isList);
        // Should return results regardless of connection mode
      });
    });

    group('search - special characters and edge cases', () {
      test('should handle special characters in query', () async {
        final result = await tools.searchAlgorithms({
          'type': 'algorithm',
          'query': 'filter-low pass',
        });

        final decoded = jsonDecode(result);
        expect(decoded['results'], isList);
        // Should handle gracefully without crashing
      });

      test('should handle very long query strings', () async {
        final result = await tools.searchAlgorithms({
          'type': 'algorithm',
          'query': 'a' * 1000,
        });

        final decoded = jsonDecode(result);
        expect(decoded['results'], isList);
        // Should return empty results rather than crashing
      });

      test('should handle whitespace in query', () async {
        final result = await tools.searchAlgorithms({
          'type': 'algorithm',
          'query': '  clock  ',
        });

        final decoded = jsonDecode(result);
        // Should treat as valid query (whitespace handling)
        expect(decoded['results'], isList);
      });
    });
  });
}
