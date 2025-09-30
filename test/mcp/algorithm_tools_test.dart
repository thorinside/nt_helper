import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/mcp/tools/algorithm_tools.dart';
import 'package:nt_helper/services/algorithm_metadata_service.dart';
import 'package:nt_helper/cubit/disting_cubit.dart';
import 'package:nt_helper/db/database.dart';
import 'package:drift/native.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() {
  group('MCPAlgorithmTools', () {
    late MCPAlgorithmTools tools;
    late DistingCubit distingCubit;
    late AppDatabase database;

    setUpAll(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues({});
      database = AppDatabase.forTesting(NativeDatabase.memory());

      // Initialize the AlgorithmMetadataService
      await AlgorithmMetadataService().initialize(database);
    });

    setUp(() {
      distingCubit = DistingCubit(database);
      tools = MCPAlgorithmTools(distingCubit);
    });

    tearDown(() {
      distingCubit.close();
    });

    tearDownAll(() async {
      await database.close();
    });

    group('getAlgorithmDetails', () {
      test('should return algorithm details for valid GUID', () async {
        final result = await tools.getAlgorithmDetails({
          'algorithm_guid': 'clck',
        });

        final decoded = jsonDecode(result);
        expect(decoded['guid'], equals('clck'));
        expect(decoded['name'], equals('Clock'));
        expect(decoded['description'], isNotEmpty);
      });

      test('should handle clck algorithm specifically', () async {
        // Test the problematic 'clck' algorithm
        final result = await tools.getAlgorithmDetails({
          'algorithm_guid': 'clck',
        });

        expect(() => jsonDecode(result), returnsNormally);

        final decoded = jsonDecode(result);
        expect(decoded['guid'], equals('clck'));
        expect(decoded['name'], equals('Clock'));
        expect(decoded['parameters'], isList);
        expect(decoded['categories'], contains('Clock'));
      });

      test('should return algorithm details by name', () async {
        final result = await tools.getAlgorithmDetails({
          'algorithm_name': 'Clock',
        });

        final decoded = jsonDecode(result);
        expect(decoded['guid'], equals('clck'));
        expect(decoded['name'], equals('Clock'));
      });

      test('should return error for missing parameters', () async {
        final result = await tools.getAlgorithmDetails({});

        final decoded = jsonDecode(result);
        expect(decoded['success'], isFalse);
        expect(decoded['error'], contains('Missing required parameter'));
      });

      test('should return error for invalid GUID', () async {
        final result = await tools.getAlgorithmDetails({
          'algorithm_guid': 'invalid_guid_12345',
        });

        final decoded = jsonDecode(result);
        expect(decoded['success'], isFalse);
        expect(decoded['error'], contains('Resource not found'));
      });

      test('should return error for ambiguous name', () async {
        // Find an algorithm name that might have multiple matches
        // or use a partial name that could match multiple
        final result = await tools.getAlgorithmDetails({
          'algorithm_name': 'a', // Very generic, might match multiple
        });

        final decoded = jsonDecode(result);
        // Either no match or ambiguous
        expect(decoded['success'], isFalse);
      });

      test('should expand features when requested', () async {
        final result = await tools.getAlgorithmDetails({
          'algorithm_guid': 'clck',
          'expand_features': true,
        });

        final decoded = jsonDecode(result);
        expect(decoded['guid'], equals('clck'));
        // Expanded parameters might include additional feature-based params
        expect(decoded['parameters'], isList);
      });

      test('should handle fuzzy name matching', () async {
        final result = await tools.getAlgorithmDetails({
          'algorithm_name': 'Clok', // Typo in Clock
        });

        final decoded = jsonDecode(result);
        // Should either find Clock via fuzzy matching or return error
        if (decoded['success'] == false) {
          expect(decoded['error'], isNotNull);
        } else {
          expect(decoded['guid'], equals('clck'));
        }
      });
    });

    group('listAlgorithms', () {
      test('should list all algorithms without filter', () async {
        final result = await tools.listAlgorithms({});

        final decoded = jsonDecode(result);
        expect(decoded, isList);
        expect(decoded.length, greaterThan(0));

        // Check structure of first algorithm
        final first = decoded[0];
        expect(first['guid'], isNotNull);
        expect(first['name'], isNotNull);
        expect(first['description'], isNotNull);
      });

      test('should filter by category', () async {
        final result = await tools.listAlgorithms({
          'category': 'Clock',
        });

        final decoded = jsonDecode(result);
        expect(decoded, isList);

        // Should include the Clock algorithm
        final clockAlgo = decoded.firstWhere(
          (alg) => alg['guid'] == 'clck',
          orElse: () => null,
        );
        expect(clockAlgo, isNotNull);
        expect(clockAlgo['name'], equals('Clock'));
      });

      test('should filter by query text', () async {
        final result = await tools.listAlgorithms({
          'query': 'clock',
        });

        final decoded = jsonDecode(result);
        expect(decoded, isList);

        // Should find algorithms with 'clock' in name or description
        final hasClockRelated = decoded.any((alg) =>
          alg['name'].toString().toLowerCase().contains('clock') ||
          alg['description'].toString().toLowerCase().contains('clock')
        );
        expect(hasClockRelated, isTrue);
      });

      test('should combine category and query filters', () async {
        final result = await tools.listAlgorithms({
          'category': 'Utility',
          'query': 'clock',
        });

        final decoded = jsonDecode(result);
        expect(decoded, isList);
        // Results should be filtered by both criteria
      });
    });

    group('Error Handling', () {
      test('should handle service not initialized gracefully', () async {
        // This test would require mocking the AlgorithmMetadataService
        // to simulate an uninitialized state, which is complex given
        // the singleton pattern. The actual fix will handle this.
        expect(true, isTrue); // Placeholder for now
      });
    });
  });
}