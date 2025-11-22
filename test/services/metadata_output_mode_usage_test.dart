import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/db/database.dart';
import 'package:drift/native.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MetadataDao - Output Mode Usage Persistence', () {
    late AppDatabase database;

    setUp(() async {
      database = AppDatabase.forTesting(NativeDatabase.memory());
    });

    tearDown(() async {
      await database.close();
    });

    test('should insert and retrieve output mode usage entries', () async {
      // Arrange - create test entries
      const algorithmGuid = 'test-algo-guid';
      const paramNumber1 = 5;
      const paramNumber2 = 7;
      final affectedOutputs1 = [10, 11, 12];
      final affectedOutputs2 = [15, 16];

      final entries = [
        ParameterOutputModeUsageEntry(
          algorithmGuid: algorithmGuid,
          parameterNumber: paramNumber1,
          affectedOutputNumbers: affectedOutputs1,
        ),
        ParameterOutputModeUsageEntry(
          algorithmGuid: algorithmGuid,
          parameterNumber: paramNumber2,
          affectedOutputNumbers: affectedOutputs2,
        ),
      ];

      // Act - insert entries
      await database.metadataDao.upsertOutputModeUsage(entries);

      // Assert - verify entries were persisted
      final retrievedEntries = await database.metadataDao.getAllOutputModeUsage();
      expect(retrievedEntries, isNotEmpty);
      expect(retrievedEntries.length, equals(2));

      final entry1 = retrievedEntries.firstWhere((e) => e.parameterNumber == paramNumber1);
      expect(entry1.algorithmGuid, equals(algorithmGuid));
      expect(entry1.affectedOutputNumbers, equals(affectedOutputs1));

      final entry2 = retrievedEntries.firstWhere((e) => e.parameterNumber == paramNumber2);
      expect(entry2.algorithmGuid, equals(algorithmGuid));
      expect(entry2.affectedOutputNumbers, equals(affectedOutputs2));
    });

    test('should support upsert behavior (insert or replace)', () async {
      // Arrange
      const algorithmGuid = 'test-upsert-algo';
      const paramNumber = 3;
      final originalAffected = [20, 21];
      final updatedAffected = [22, 23, 24];

      final entry = ParameterOutputModeUsageEntry(
        algorithmGuid: algorithmGuid,
        parameterNumber: paramNumber,
        affectedOutputNumbers: originalAffected,
      );

      // Act - insert original
      await database.metadataDao.upsertOutputModeUsage([entry]);

      // Verify original
      var retrieved = await database.metadataDao.getAllOutputModeUsage();
      expect(retrieved.length, equals(1));
      expect(retrieved.first.affectedOutputNumbers, equals(originalAffected));

      // Update with new affected outputs
      final updatedEntry = ParameterOutputModeUsageEntry(
        algorithmGuid: algorithmGuid,
        parameterNumber: paramNumber,
        affectedOutputNumbers: updatedAffected,
      );
      await database.metadataDao.upsertOutputModeUsage([updatedEntry]);

      // Assert - verify replacement
      retrieved = await database.metadataDao.getAllOutputModeUsage();
      expect(retrieved.length, equals(1), reason: 'Should have replaced, not added');
      expect(retrieved.first.affectedOutputNumbers, equals(updatedAffected));
    });

    test('should handle empty affected output lists', () async {
      // Arrange
      const algorithmGuid = 'test-empty-algo';
      const paramNumber = 10;

      final entry = ParameterOutputModeUsageEntry(
        algorithmGuid: algorithmGuid,
        parameterNumber: paramNumber,
        affectedOutputNumbers: [], // Empty list
      );

      // Act - insert with empty affected outputs
      await database.metadataDao.upsertOutputModeUsage([entry]);

      // Assert - entry should be stored even with empty list
      final retrieved = await database.metadataDao.getAllOutputModeUsage();
      final foundEntry = retrieved.firstWhere(
        (e) => e.algorithmGuid == algorithmGuid,
        orElse: () => throw AssertionError('Entry not found'),
      );
      expect(foundEntry.affectedOutputNumbers, isEmpty);
    });

    test('should query entries by algorithm guid', () async {
      // Arrange - insert entries for multiple algorithms
      final entries = [
        ParameterOutputModeUsageEntry(
          algorithmGuid: 'algo-1',
          parameterNumber: 1,
          affectedOutputNumbers: [10],
        ),
        ParameterOutputModeUsageEntry(
          algorithmGuid: 'algo-1',
          parameterNumber: 2,
          affectedOutputNumbers: [20],
        ),
        ParameterOutputModeUsageEntry(
          algorithmGuid: 'algo-2',
          parameterNumber: 3,
          affectedOutputNumbers: [30],
        ),
      ];

      // Act - insert all
      await database.metadataDao.upsertOutputModeUsage(entries);

      // Assert - query all and filter
      final allEntries = await database.metadataDao.getAllOutputModeUsage();
      expect(allEntries.length, equals(3));

      final algo1Entries = allEntries.where((e) => e.algorithmGuid == 'algo-1').toList();
      expect(algo1Entries.length, equals(2));

      final algo2Entries = allEntries.where((e) => e.algorithmGuid == 'algo-2').toList();
      expect(algo2Entries.length, equals(1));
    });

    test('should handle batch insert with multiple entries', () async {
      // Arrange
      final batchEntries = List.generate(
        5,
        (index) => ParameterOutputModeUsageEntry(
          algorithmGuid: 'batch-algo',
          parameterNumber: index,
          affectedOutputNumbers: [index * 10, index * 10 + 1],
        ),
      );

      // Act - batch insert
      await database.metadataDao.upsertOutputModeUsage(batchEntries);

      // Assert
      final retrieved = await database.metadataDao.getAllOutputModeUsage();
      final batchEntriesRetrieved = retrieved.where((e) => e.algorithmGuid == 'batch-algo').toList();
      expect(batchEntriesRetrieved.length, equals(5));

      // Verify each entry
      for (int i = 0; i < 5; i++) {
        final entry = batchEntriesRetrieved.firstWhere((e) => e.parameterNumber == i);
        expect(entry.affectedOutputNumbers, equals([i * 10, i * 10 + 1]));
      }
    });
  });
}
