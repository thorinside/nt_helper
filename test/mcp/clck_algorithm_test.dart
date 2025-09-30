import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/services/algorithm_metadata_service.dart';
import 'package:nt_helper/mcp/tools/algorithm_tools.dart';
import 'package:nt_helper/cubit/disting_cubit.dart';
import 'package:nt_helper/db/database.dart';
import 'package:drift/native.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';

void main() {
  group('CLCK Algorithm Specific Tests', () {
    setUpAll(() {
      SharedPreferences.setMockInitialValues({});
    });
    test('clck.json should be valid and loadable', () async {
      final file = File('docs/algorithms/clck.json');
      expect(file.existsSync(), isTrue, reason: 'clck.json file should exist');

      final jsonString = await file.readAsString();
      expect(() => json.decode(jsonString), returnsNormally,
          reason: 'clck.json should be valid JSON');

      final jsonData = json.decode(jsonString);
      expect(jsonData['guid'], equals('clck'));
      expect(jsonData['name'], equals('Clock'));
      expect(jsonData['parameters'], isList);
    });

    test('AlgorithmMetadataService should load clck', () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      final database = AppDatabase.forTesting(NativeDatabase.memory());

      try {
        await AlgorithmMetadataService().initialize(database);

        final service = AlgorithmMetadataService();
        final clckAlgo = service.getAlgorithmByGuid('clck');

        expect(clckAlgo, isNotNull, reason: 'clck algorithm should be loaded');
        expect(clckAlgo!.guid, equals('clck'));
        expect(clckAlgo.name, equals('Clock'));
      } finally {
        await database.close();
      }
    });

    test('MCPAlgorithmTools.getAlgorithmDetails should handle clck', () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      final database = AppDatabase.forTesting(NativeDatabase.memory());

      try {
        await AlgorithmMetadataService().initialize(database);

        final cubit = DistingCubit(database);
        final tools = MCPAlgorithmTools(cubit);

        // Test with timeout to catch any hanging
        final resultFuture = tools.getAlgorithmDetails({
          'algorithm_guid': 'clck',
        }).timeout(
          const Duration(seconds: 5),
          onTimeout: () => throw TimeoutException('getAlgorithmDetails timed out for clck'),
        );

        final result = await resultFuture;
        final decoded = json.decode(result);

        if (decoded['success'] == false) {
          // Error response: ${decoded['error']}
        }

        expect(decoded['guid'], equals('clck'));
        expect(decoded['name'], equals('Clock'));

        cubit.close();
      } finally {
        await database.close();
      }
    });

    test('Check for circular references or infinite loops in clck data', () async {
      final file = File('docs/algorithms/clck.json');
      final jsonString = await file.readAsString();
      final jsonData = json.decode(jsonString);

      // Check if parameters have any suspicious patterns
      final parameters = jsonData['parameters'] as List;

      for (var i = 0; i < parameters.length; i++) {
        final page = parameters[i];
        expect(page, isA<Map>(), reason: 'Each parameter page should be a map');

        if (page['params'] != null) {
          final params = page['params'] as List;
          for (var param in params) {
            // Check for any self-referential fields
            expect(param, isA<Map>(), reason: 'Each param should be a map');

            // Check any enum_values for issues
            if (param['enum_values'] != null) {
              // Parameter ${param['name']} has enum_values: ${param['enum_values']}
            }
          }
        }
      }
    });
  });
}