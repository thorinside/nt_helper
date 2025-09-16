import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/db/database.dart';
import 'package:drift/drift.dart' hide isNotNull;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Parameter Lookup - Backward Compatibility', () {
    late AppDatabase database;

    setUpAll(() async {
      database = AppDatabase();
    });

    tearDownAll(() async {
      await database.close();
    });

    setUp(() async {
      // Clear any existing test data
      // Note: We'll manually insert test data for each test
    });

    test('should find parameters with full names including prefixes', () async {
      // Insert test parameters with channel prefixes
      await database.into(database.parameters).insert(
        ParametersCompanion.insert(
          algorithmGuid: 'test-algo',
          parameterNumber: 0,
          name: '1: Frequency',
          minValue: const Value(0),
          maxValue: const Value(100),
          defaultValue: const Value(50),
        ),
      );

      await database.into(database.parameters).insert(
        ParametersCompanion.insert(
          algorithmGuid: 'test-algo',
          parameterNumber: 1,
          name: '2: Frequency',
          minValue: const Value(0),
          maxValue: const Value(100),
          defaultValue: const Value(50),
        ),
      );

      // Query parameters and verify we can find them by full name
      final query = database.select(database.parameters)
        ..where((p) => p.algorithmGuid.equals('test-algo'));
      final params = await query.get();

      expect(params.length, equals(2));
      expect(params.any((p) => p.name == '1: Frequency'), isTrue);
      expect(params.any((p) => p.name == '2: Frequency'), isTrue);
    });

    test('should distinguish between channels when looking up parameters', () async {
      // Insert test parameters with same base name but different channels
      await database.into(database.parameters).insert(
        ParametersCompanion.insert(
          algorithmGuid: 'multi-channel-algo',
          parameterNumber: 0,
          name: 'A: Level',
          minValue: const Value(0),
          maxValue: const Value(100),
          defaultValue: const Value(75),
        ),
      );

      await database.into(database.parameters).insert(
        ParametersCompanion.insert(
          algorithmGuid: 'multi-channel-algo',
          parameterNumber: 1,
          name: 'B: Level',
          minValue: const Value(0),
          maxValue: const Value(100),
          defaultValue: const Value(75),
        ),
      );

      await database.into(database.parameters).insert(
        ParametersCompanion.insert(
          algorithmGuid: 'multi-channel-algo',
          parameterNumber: 2,
          name: 'C: Level',
          minValue: const Value(0),
          maxValue: const Value(100),
          defaultValue: const Value(75),
        ),
      );

      // Query and verify each parameter is distinct
      final query = database.select(database.parameters)
        ..where((p) => p.algorithmGuid.equals('multi-channel-algo'))
        ..orderBy([(p) => OrderingTerm.asc(p.parameterNumber)]);

      final params = await query.get();

      expect(params.length, equals(3));

      // Each should have unique parameter number
      final paramNumbers = params.map((p) => p.parameterNumber).toSet();
      expect(paramNumbers.length, equals(3));

      // Each should have unique name
      final paramNames = params.map((p) => p.name).toSet();
      expect(paramNames.length, equals(3));

      // Verify specific names exist
      expect(paramNames, containsAll(['A: Level', 'B: Level', 'C: Level']));
    });

    test('should handle parameter queries by parameter number', () async {
      // Insert test parameters
      await database.into(database.parameters).insert(
        ParametersCompanion.insert(
          algorithmGuid: 'test-algo-2',
          parameterNumber: 5,
          name: '1: Input Gain',
          minValue: const Value(-60),
          maxValue: const Value(12),
          defaultValue: const Value(0),
        ),
      );

      // Query by parameter number
      final query = database.select(database.parameters)
        ..where((p) => p.algorithmGuid.equals('test-algo-2'))
        ..where((p) => p.parameterNumber.equals(5));

      final param = await query.getSingleOrNull();

      expect(param, isNotNull);
      expect(param!.name, equals('1: Input Gain'));
      expect(param.parameterNumber, equals(5));
    });

    test('should preserve parameter metadata with prefixed names', () async {
      // Insert parameter with full metadata
      await database.into(database.parameters).insert(
        ParametersCompanion.insert(
          algorithmGuid: 'metadata-test',
          parameterNumber: 10,
          name: '2: Resonance',
          minValue: const Value(0),
          maxValue: const Value(100),
          defaultValue: const Value(25),
          powerOfTen: const Value(2),
          rawUnitIndex: const Value(3),
        ),
      );

      // Query and verify all metadata is preserved
      final query = database.select(database.parameters)
        ..where((p) => p.algorithmGuid.equals('metadata-test'))
        ..where((p) => p.parameterNumber.equals(10));

      final param = await query.getSingleOrNull();

      expect(param, isNotNull);
      expect(param!.name, equals('2: Resonance'));
      expect(param.minValue, equals(0));
      expect(param.maxValue, equals(100));
      expect(param.defaultValue, equals(25));
      expect(param.powerOfTen, equals(2));
      expect(param.rawUnitIndex, equals(3));
    });

    test('should support filtering parameters by name pattern', () async {
      // Insert various parameters
      await database.batch((batch) {
        batch.insertAll(database.parameters, [
          ParametersCompanion.insert(
            algorithmGuid: 'filter-test',
            parameterNumber: 0,
            name: '1: Frequency',
            minValue: const Value(0),
            maxValue: const Value(100),
            defaultValue: const Value(50),
          ),
          ParametersCompanion.insert(
            algorithmGuid: 'filter-test',
            parameterNumber: 1,
            name: '2: Frequency',
            minValue: const Value(0),
            maxValue: const Value(100),
            defaultValue: const Value(50),
          ),
          ParametersCompanion.insert(
            algorithmGuid: 'filter-test',
            parameterNumber: 2,
            name: '1: Resonance',
            minValue: const Value(0),
            maxValue: const Value(100),
            defaultValue: const Value(25),
          ),
          ParametersCompanion.insert(
            algorithmGuid: 'filter-test',
            parameterNumber: 3,
            name: 'Mix',
            minValue: const Value(0),
            maxValue: const Value(100),
            defaultValue: const Value(50),
          ),
        ]);
      });

      // Query for all Frequency parameters
      final freqQuery = database.select(database.parameters)
        ..where((p) => p.algorithmGuid.equals('filter-test'))
        ..where((p) => p.name.like('%Frequency'));

      final freqParams = await freqQuery.get();
      expect(freqParams.length, equals(2));
      expect(freqParams.every((p) => p.name.contains('Frequency')), isTrue);

      // Query for channel 1 parameters
      final ch1Query = database.select(database.parameters)
        ..where((p) => p.algorithmGuid.equals('filter-test'))
        ..where((p) => p.name.like('1:%'));

      final ch1Params = await ch1Query.get();
      expect(ch1Params.length, equals(2));
      expect(ch1Params.every((p) => p.name.startsWith('1:')), isTrue);

      // Query for non-prefixed parameters
      final noPrefixQuery = database.select(database.parameters)
        ..where((p) => p.algorithmGuid.equals('filter-test'))
        ..where((p) => p.name.equals('Mix'));

      final noPrefixParams = await noPrefixQuery.get();
      expect(noPrefixParams.length, equals(1));
      expect(noPrefixParams.first.name, equals('Mix'));
    });
  });
}