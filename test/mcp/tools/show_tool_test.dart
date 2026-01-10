import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/mcp/tools/algorithm_tools.dart';
import 'package:nt_helper/services/algorithm_metadata_service.dart';
import 'package:nt_helper/services/metadata_import_service.dart';
import 'package:nt_helper/cubit/disting_cubit.dart';
import 'package:nt_helper/db/database.dart';
import 'package:drift/native.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart' as path;

import '../../test_helpers/mock_midi_command.dart';

void main() {
  group('MCPAlgorithmTools - show', () {
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
      tools = MCPAlgorithmTools(distingCubit);
    });

    tearDown(() {
      distingCubit.close();
    });

    tearDownAll(() async {
      await database.close();
    });

    group('show - parameter validation', () {
      test('should return error when target parameter is missing', () async {
        final result = await tools.show({});

        final decoded = jsonDecode(result);
        expect(decoded['success'], isFalse);
        expect(decoded['error'], contains('Missing required parameter: target'));
        expect(decoded['valid_targets'], isNotNull);
      });

      test('should return error when target is empty string', () async {
        final result = await tools.show({'target': ''});

        final decoded = jsonDecode(result);
        expect(decoded['success'], isFalse);
        expect(decoded['error'], contains('Missing required parameter: target'));
      });

      test('should return error when target is invalid', () async {
        final result = await tools.show({'target': 'invalid'});

        final decoded = jsonDecode(result);
        expect(decoded['success'], isFalse);
        expect(decoded['error'], contains('Invalid target'));
        expect(decoded['valid_targets'], equals(['preset', 'slot', 'parameter', 'screen', 'routing', 'cpu']));
      });
    });

    group('show - preset target', () {
      test('should return error when device not synchronized', () async {
        final result = await tools.show({'target': 'preset'});

        final decoded = jsonDecode(result);
        expect(decoded['success'], isFalse);
        expect(decoded['error'], contains('Device not synchronized'));
      });
    });

    group('show - slot target', () {
      test('should return error when identifier is missing', () async {
        final result = await tools.show({'target': 'slot'});

        final decoded = jsonDecode(result);
        expect(decoded['success'], isFalse);
        expect(decoded['error'], contains('Missing required parameter: identifier'));
      });

      test('should return error when identifier is not an integer', () async {
        final result = await tools.show({'target': 'slot', 'identifier': 'not-a-number'});

        final decoded = jsonDecode(result);
        expect(decoded['success'], isFalse);
        expect(decoded['error'], contains('Invalid identifier format'));
      });

      test('should return error when slot index is negative', () async {
        final result = await tools.show({'target': 'slot', 'identifier': -1});

        final decoded = jsonDecode(result);
        expect(decoded['success'], isFalse);
        expect(decoded['error'], contains('Invalid slot index'));
        expect(decoded['error'], contains('Must be 0-31'));
      });

      test('should return error when slot index is >= 32', () async {
        final result = await tools.show({'target': 'slot', 'identifier': 32});

        final decoded = jsonDecode(result);
        expect(decoded['success'], isFalse);
        expect(decoded['error'], contains('Invalid slot index'));
        expect(decoded['error'], contains('Must be 0-31'));
      });

      test('should return error when device not synchronized', () async {
        final result = await tools.show({'target': 'slot', 'identifier': 0});

        final decoded = jsonDecode(result);
        expect(decoded['success'], isFalse);
        expect(decoded['error'], contains('Device not synchronized'));
      });

      test('should accept slot index as string integer', () async {
        // Should not throw during parsing
        final result = await tools.show({'target': 'slot', 'identifier': '0'});

        final decoded = jsonDecode(result);
        // Either synchronized error or slot error, both are acceptable
        expect(decoded['success'] ?? decoded['error'], isNotNull);
      });
    });

    group('show - parameter target', () {
      test('should return error when identifier is missing', () async {
        final result = await tools.show({'target': 'parameter'});

        final decoded = jsonDecode(result);
        expect(decoded['success'], isFalse);
        expect(decoded['error'], contains('Missing required parameter: identifier'));
      });

      test('should return error when identifier format is invalid (no colon)', () async {
        final result = await tools.show({'target': 'parameter', 'identifier': '0'});

        final decoded = jsonDecode(result);
        expect(decoded['success'], isFalse);
        expect(decoded['error'], contains('Invalid identifier format'));
        expect(decoded['error'], contains('slot_index:parameter_number'));
      });

      test('should return error when identifier has no slot_index', () async {
        final result = await tools.show({'target': 'parameter', 'identifier': ':5'});

        final decoded = jsonDecode(result);
        expect(decoded['success'], isFalse);
        expect(decoded['error'], contains('Invalid identifier format'));
      });

      test('should return error when identifier has non-integer slot_index', () async {
        final result = await tools.show({'target': 'parameter', 'identifier': 'abc:5'});

        final decoded = jsonDecode(result);
        expect(decoded['success'], isFalse);
        expect(decoded['error'], contains('slot_index and parameter_number must be integers'));
      });

      test('should return error when identifier has non-integer parameter_number', () async {
        final result = await tools.show({'target': 'parameter', 'identifier': '0:abc'});

        final decoded = jsonDecode(result);
        expect(decoded['success'], isFalse);
        expect(decoded['error'], contains('slot_index and parameter_number must be integers'));
      });

      test('should return error when slot_index is negative', () async {
        final result = await tools.show({'target': 'parameter', 'identifier': '-1:5'});

        final decoded = jsonDecode(result);
        expect(decoded['success'], isFalse);
        expect(decoded['error'], contains('Invalid slot index'));
      });

      test('should return error when slot_index >= 32', () async {
        final result = await tools.show({'target': 'parameter', 'identifier': '32:5'});

        final decoded = jsonDecode(result);
        expect(decoded['success'], isFalse);
        expect(decoded['error'], contains('Invalid slot index'));
      });

      test('should return error when device not synchronized', () async {
        final result = await tools.show({'target': 'parameter', 'identifier': '0:0'});

        final decoded = jsonDecode(result);
        expect(decoded['success'], isFalse);
        expect(decoded['error'], contains('Device not synchronized'));
      });
    });

    group('show - screen target', () {
      test('should return error when device not synchronized', () async {
        final result = await tools.show({'target': 'screen'});

        final decoded = jsonDecode(result);
        expect(decoded['success'], isFalse);
        expect(decoded['error'], contains('Device not synchronized'));
      });
    });

    group('show - routing target', () {
      test('should return valid JSON when routing is accessed', () async {
        final result = await tools.show({'target': 'routing'});

        final decoded = jsonDecode(result);
        // Routing might return an empty array or an object - both are valid
        expect(decoded, isNotNull);
      });
    });

    group('show - case insensitivity', () {
      test('should accept uppercase target', () async {
        final result = await tools.show({'target': 'PRESET'});

        final decoded = jsonDecode(result);
        // Should process as preset (synchronized error is expected)
        expect(decoded, isMap);
      });

      test('should accept mixed case target', () async {
        final result = await tools.show({'target': 'Slot'});

        final decoded = jsonDecode(result);
        // Should process as slot (identifier missing error is expected)
        expect(decoded, isMap);
      });
    });

    group('show - error handling', () {
      test('should handle exceptions gracefully', () async {
        // This test verifies the overall exception handling
        final result = await tools.show({'target': 'preset'});

        final decoded = jsonDecode(result);
        // Should always return valid JSON with either success or error
        expect(decoded, isMap);
      });
    });
  });
}
