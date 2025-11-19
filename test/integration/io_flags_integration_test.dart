import 'dart:convert';
import 'dart:io';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/db/database.dart';
import 'package:nt_helper/db/daos/presets_dao.dart';
import 'package:nt_helper/services/metadata_import_service.dart';
import 'package:nt_helper/services/algorithm_json_exporter.dart';
import 'package:nt_helper/domain/offline_disting_midi_manager.dart';

void main() {
  group('ioFlags Integration Tests', () {
    test('Full workflow: v1 JSON import (missing ioFlags) → null in DB', () async {
      // Create a v1 JSON file (without ioFlags field)
      final v1Json = json.encode({
        'exportType': 'full_metadata',
        'exportVersion': 1,
        'tables': {
          'algorithms': [
            {
              'guid': 'test',
              'name': 'Test Algorithm',
              'numSpecifications': 0,
              'pluginFilePath': null,
            }
          ],
          'parameters': [
            {
              'algorithmGuid': 'test',
              'parameterNumber': 0,
              'name': 'Old Format Parameter',
              'minValue': 0,
              'maxValue': 100,
              'defaultValue': 50,
              'unitId': null,
              'powerOfTen': 0,
              'rawUnitIndex': null,
              // No ioFlags field - typical v1 format
            }
          ],
        },
      });

      // Import into fresh database
      final database = AppDatabase.forTesting(NativeDatabase.memory());
      final importService = MetadataImportService(database);

      final success = await importService.importFromJson(v1Json);
      expect(success, isTrue);

      // Verify ioFlags is null in database
      final param = await (database.select(database.parameters)
            ..where((p) => p.algorithmGuid.equals('test')))
          .getSingle();

      expect(param.ioFlags, isNull);

      await database.close();
    });

    test('Full workflow: v2 JSON import with ioFlags → preserved in DB', () async {
      // Create a v2 JSON file (with ioFlags field)
      final v2Json = json.encode({
        'exportType': 'full_metadata',
        'exportVersion': 2,
        'tables': {
          'algorithms': [
            {
              'guid': 'test',
              'name': 'Test Algorithm',
              'numSpecifications': 0,
              'pluginFilePath': null,
            }
          ],
          'parameters': [
            {
              'algorithmGuid': 'test',
              'parameterNumber': 0,
              'name': 'New Format Parameter',
              'minValue': 0,
              'maxValue': 100,
              'defaultValue': 50,
              'unitId': null,
              'powerOfTen': 0,
              'rawUnitIndex': null,
              'ioFlags': 9, // v2 format with ioFlags
            }
          ],
        },
      });

      // Import into fresh database
      final database = AppDatabase.forTesting(NativeDatabase.memory());
      final importService = MetadataImportService(database);

      final success = await importService.importFromJson(v2Json);
      expect(success, isTrue);

      // Verify ioFlags is preserved
      final param = await (database.select(database.parameters)
            ..where((p) => p.algorithmGuid.equals('test')))
          .getSingle();

      expect(param.ioFlags, 9);

      await database.close();
    });

    test('Full workflow: Export→Import round-trip preserves all ioFlags values', () async{
      // Create source database with test data
      final sourceDb = AppDatabase.forTesting(NativeDatabase.memory());

      // Insert test algorithm
      await sourceDb.into(sourceDb.algorithms).insert(
            AlgorithmsCompanion(
              guid: const Value('test'),
              name: const Value('Test Algorithm'),
              numSpecifications: const Value(0),
            ),
          );

      // Insert parameters with various ioFlags values
      final testValues = {
        0: null, // No flags, no data
        1: 0, // Explicit zero (all flags off)
        2: 5, // Some flags set
        3: 15, // All flags set
      };

      for (final entry in testValues.entries) {
        await sourceDb.into(sourceDb.parameters).insert(
              ParametersCompanion(
                algorithmGuid: const Value('test'),
                parameterNumber: Value(entry.key),
                name: Value('Param ${entry.key}'),
                minValue: const Value(0),
                maxValue: const Value(100),
                defaultValue: const Value(50),
                unitId: const Value(null),
                powerOfTen: const Value(0),
                rawUnitIndex: const Value(null),
                ioFlags: Value(entry.value),
              ),
            );
      }

      // Export to JSON file
      final exporter = AlgorithmJsonExporter(sourceDb);
      final tempDir = Directory.systemTemp.createTempSync('io_flags_integration_test');
      final exportPath = '${tempDir.path}/export.json';

      await exporter.exportFullMetadata(exportPath);

      // Verify export file exists
      final exportFile = File(exportPath);
      expect(exportFile.existsSync(), isTrue);

      // Read exported JSON
      final exportJsonString = await exportFile.readAsString();
      final exportJson = json.decode(exportJsonString);

      // Verify export structure
      expect(exportJson['exportVersion'], 2);
      expect(exportJson['exportType'], 'full_metadata');

      // Import into fresh database
      final targetDb = AppDatabase.forTesting(NativeDatabase.memory());
      final importService = MetadataImportService(targetDb);

      final success = await importService.importFromJson(exportJsonString);
      expect(success, isTrue);

      // Verify all ioFlags values preserved in target database
      for (final entry in testValues.entries) {
        final param = await (targetDb.select(targetDb.parameters)
              ..where((p) =>
                  p.algorithmGuid.equals('test') &
                  p.parameterNumber.equals(entry.key)))
            .getSingle();

        expect(param.ioFlags, entry.value,
            reason: 'Parameter ${entry.key} ioFlags should be ${entry.value}');
      }

      // Cleanup
      await sourceDb.close();
      await targetDb.close();
      tempDir.deleteSync(recursive: true);
    });

    test('Full workflow: Offline mode reads ioFlags correctly', () async {
      // Create database with test data
      final database = AppDatabase.forTesting(NativeDatabase.memory());

      // Insert test algorithm
      await database.into(database.algorithms).insert(
            AlgorithmsCompanion(
              guid: const Value('test'),
              name: const Value('Test Algorithm'),
              numSpecifications: const Value(0),
            ),
          );

      // Insert parameter with specific ioFlags
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
              rawUnitIndex: const Value(5),
              ioFlags: const Value(11), // Specific flags
            ),
          );

      // Create preset with the algorithm
      final presetId = await database.presetsDao.saveFullPreset(
        FullPresetDetails(
          preset: PresetEntry(
            id: -1,
            name: 'Test Preset',
            lastModified: DateTime.now(),
            isTemplate: false,
          ),
          slots: [
            FullPresetSlot(
              slot: PresetSlotEntry(
                id: -1,
                presetId: -1,
                slotIndex: 0,
                algorithmGuid: 'test',
                customName: null,
              ),
              algorithm: AlgorithmEntry(
                guid: 'test',
                name: 'Test Algorithm',
                numSpecifications: 0,
                pluginFilePath: null,
              ),
              parameterValues: {},
              parameterStringValues: {},
              mappings: {},
            ),
          ],
        ),
      );

      // Load preset in offline mode
      final offlineManager = OfflineDistingMidiManager(database);
      final presetDetails = await database.presetsDao.getFullPresetDetails(presetId);
      await offlineManager.initializeFromDb(presetDetails);

      // Request parameter info through offline manager
      final paramInfo = await offlineManager.requestParameterInfo(0, 0);

      // Verify ioFlags is read correctly
      expect(paramInfo, isNotNull);
      expect(paramInfo!.ioFlags, 11);

      await database.close();
    });

    test('Full workflow: Offline mode null ioFlags fallback to 0', () async {
      // Create database with parameter having null ioFlags
      final database = AppDatabase.forTesting(NativeDatabase.memory());

      await database.into(database.algorithms).insert(
            AlgorithmsCompanion(
              guid: const Value('test'),
              name: const Value('Test Algorithm'),
              numSpecifications: const Value(0),
            ),
          );

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
              rawUnitIndex: const Value(5),
              ioFlags: const Value(null), // Null ioFlags
            ),
          );

      // Create preset
      final presetId = await database.presetsDao.saveFullPreset(
        FullPresetDetails(
          preset: PresetEntry(
            id: -1,
            name: 'Test Preset',
            lastModified: DateTime.now(),
            isTemplate: false,
          ),
          slots: [
            FullPresetSlot(
              slot: PresetSlotEntry(
                id: -1,
                presetId: -1,
                slotIndex: 0,
                algorithmGuid: 'test',
                customName: null,
              ),
              algorithm: AlgorithmEntry(
                guid: 'test',
                name: 'Test Algorithm',
                numSpecifications: 0,
                pluginFilePath: null,
              ),
              parameterValues: {},
              parameterStringValues: {},
              mappings: {},
            ),
          ],
        ),
      );

      // Load in offline mode
      final offlineManager = OfflineDistingMidiManager(database);
      final presetDetails = await database.presetsDao.getFullPresetDetails(presetId);
      await offlineManager.initializeFromDb(presetDetails);

      // Request parameter info
      final paramInfo = await offlineManager.requestParameterInfo(0, 0);

      // Verify null defaults to 0
      expect(paramInfo, isNotNull);
      expect(paramInfo!.ioFlags, 0);

      await database.close();
    });

    test('Full workflow: Complex scenario with multiple algorithms and mixed ioFlags', () async {
      // Create database with multiple algorithms and parameters
      final database = AppDatabase.forTesting(NativeDatabase.memory());

      // Insert multiple algorithms
      await database.into(database.algorithms).insert(
        AlgorithmsCompanion(
          guid: const Value('algo1'),
          name: const Value('Algorithm 1'),
          numSpecifications: const Value(0),
        ),
      );
      await database.into(database.algorithms).insert(
        AlgorithmsCompanion(
          guid: const Value('algo2'),
          name: const Value('Algorithm 2'),
          numSpecifications: const Value(0),
        ),
      );

      // Insert parameters with various ioFlags combinations
      await database.into(database.parameters).insert(
        ParametersCompanion(
          algorithmGuid: const Value('algo1'),
          parameterNumber: const Value(0),
          name: const Value('Algo1 Param0'),
          minValue: const Value(0),
          maxValue: const Value(100),
          defaultValue: const Value(50),
          unitId: const Value(null),
          powerOfTen: const Value(0),
          rawUnitIndex: const Value(null),
          ioFlags: const Value(null), // null
        ),
      );
      await database.into(database.parameters).insert(
        ParametersCompanion(
          algorithmGuid: const Value('algo1'),
          parameterNumber: const Value(1),
          name: const Value('Algo1 Param1'),
          minValue: const Value(0),
          maxValue: const Value(100),
          defaultValue: const Value(50),
          unitId: const Value(null),
          powerOfTen: const Value(0),
          rawUnitIndex: const Value(null),
          ioFlags: const Value(4), // isAudio flag
        ),
      );
      await database.into(database.parameters).insert(
        ParametersCompanion(
          algorithmGuid: const Value('algo2'),
          parameterNumber: const Value(0),
          name: const Value('Algo2 Param0'),
          minValue: const Value(0),
          maxValue: const Value(100),
          defaultValue: const Value(50),
          unitId: const Value(null),
          powerOfTen: const Value(0),
          rawUnitIndex: const Value(null),
          ioFlags: const Value(3), // isInput + isOutput
        ),
      );

      // Export
      final exporter = AlgorithmJsonExporter(database);
      final tempDir = Directory.systemTemp.createTempSync('io_flags_integration_test');
      final exportPath = '${tempDir.path}/complex_export.json';
      await exporter.exportFullMetadata(exportPath);

      // Import into new database
      final targetDb = AppDatabase.forTesting(NativeDatabase.memory());
      final importService = MetadataImportService(targetDb);
      final exportJsonString = await File(exportPath).readAsString();
      await importService.importFromJson(exportJsonString);

      // Verify all parameters preserved correctly
      final algo1Param0 = await (targetDb.select(targetDb.parameters)
            ..where((p) =>
                p.algorithmGuid.equals('algo1') & p.parameterNumber.equals(0)))
          .getSingle();
      expect(algo1Param0.ioFlags, isNull);

      final algo1Param1 = await (targetDb.select(targetDb.parameters)
            ..where((p) =>
                p.algorithmGuid.equals('algo1') & p.parameterNumber.equals(1)))
          .getSingle();
      expect(algo1Param1.ioFlags, 4);

      final algo2Param0 = await (targetDb.select(targetDb.parameters)
            ..where((p) =>
                p.algorithmGuid.equals('algo2') & p.parameterNumber.equals(0)))
          .getSingle();
      expect(algo2Param0.ioFlags, 3);

      // Cleanup
      await database.close();
      await targetDb.close();
      tempDir.deleteSync(recursive: true);
    });
  });
}
