import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/db/database.dart';

void main() {
  group('ioFlags Database Migration Tests', () {
    late AppDatabase database;

    setUp(() {
      // Create in-memory database for testing
      database = AppDatabase.forTesting(NativeDatabase.memory());
    });

    tearDown(() async {
      await database.close();
    });

    test('Migration adds ioFlags column to parameters table', () async {
      // Test that schema version 10 includes ioFlags column
      expect(database.schemaVersion, 10);

      // Insert a test algorithm
      await database.into(database.algorithms).insert(
            AlgorithmsCompanion(
              guid: const Value('test'),
              name: const Value('Test Algorithm'),
              numSpecifications: const Value(0),
            ),
          );

      // Insert a parameter with ioFlags
      await database.into(database.parameters).insert(
            ParametersCompanion(
              algorithmGuid: const Value('test'),
              parameterNumber: const Value(0),
              name: const Value('Test Parameter'),
              minValue: const Value(0),
              maxValue: const Value(100),
              defaultValue: const Value(50),
              unitId: const Value(null),
              powerOfTen: const Value(0),
              rawUnitIndex: const Value(null),
              ioFlags: const Value(5), // Test with flags value
            ),
          );

      // Query the parameter back
      final param = await (database.select(database.parameters)
            ..where((p) => p.algorithmGuid.equals('test')))
          .getSingle();

      // Verify ioFlags was stored correctly
      expect(param.ioFlags, 5);
    });

    test('Parameters with null ioFlags are stored correctly', () async {
      // Insert a test algorithm
      await database.into(database.algorithms).insert(
            AlgorithmsCompanion(
              guid: const Value('test'),
              name: const Value('Test Algorithm'),
              numSpecifications: const Value(0),
            ),
          );

      // Insert a parameter with null ioFlags
      await database.into(database.parameters).insert(
            ParametersCompanion(
              algorithmGuid: const Value('test'),
              parameterNumber: const Value(0),
              name: const Value('Test Parameter'),
              minValue: const Value(0),
              maxValue: const Value(100),
              defaultValue: const Value(50),
              unitId: const Value(null),
              powerOfTen: const Value(0),
              rawUnitIndex: const Value(null),
              ioFlags: const Value(null), // Explicit null
            ),
          );

      // Query the parameter back
      final param = await (database.select(database.parameters)
            ..where((p) => p.algorithmGuid.equals('test')))
          .getSingle();

      // Verify ioFlags is null
      expect(param.ioFlags, null);
    });

    test('Parameters with ioFlags = 0 are distinct from null', () async {
      // Insert a test algorithm
      await database.into(database.algorithms).insert(
            AlgorithmsCompanion(
              guid: const Value('test'),
              name: const Value('Test Algorithm'),
              numSpecifications: const Value(0),
            ),
          );

      // Insert parameter with ioFlags = 0
      await database.into(database.parameters).insert(
            ParametersCompanion(
              algorithmGuid: const Value('test'),
              parameterNumber: const Value(0),
              name: const Value('Test Parameter'),
              minValue: const Value(0),
              maxValue: const Value(100),
              defaultValue: const Value(50),
              unitId: const Value(null),
              powerOfTen: const Value(0),
              rawUnitIndex: const Value(null),
              ioFlags: const Value(0), // Explicit zero
            ),
          );

      // Query the parameter back
      final param = await (database.select(database.parameters)
            ..where((p) => p.algorithmGuid.equals('test')))
          .getSingle();

      // Verify ioFlags is 0, not null
      expect(param.ioFlags, 0);
      expect(param.ioFlags != null, true);
    });

    test('ioFlags supports all valid flag values (0-15)', () async {
      // Insert a test algorithm
      await database.into(database.algorithms).insert(
            AlgorithmsCompanion(
              guid: const Value('test'),
              name: const Value('Test Algorithm'),
              numSpecifications: const Value(0),
            ),
          );

      // Test all valid flag values
      for (int flagValue = 0; flagValue <= 15; flagValue++) {
        await database.into(database.parameters).insert(
              ParametersCompanion(
                algorithmGuid: const Value('test'),
                parameterNumber: Value(flagValue),
                name: Value('Parameter $flagValue'),
                minValue: const Value(0),
                maxValue: const Value(100),
                defaultValue: const Value(50),
                unitId: const Value(null),
                powerOfTen: const Value(0),
                rawUnitIndex: const Value(null),
                ioFlags: Value(flagValue),
              ),
            );
      }

      // Query all parameters back
      final params = await (database.select(database.parameters)
            ..where((p) => p.algorithmGuid.equals('test'))
            ..orderBy([(p) => OrderingTerm.asc(p.parameterNumber)]))
          .get();

      // Verify all flag values
      expect(params.length, 16);
      for (int i = 0; i < 16; i++) {
        expect(params[i].ioFlags, i);
      }
    });
  });
}
