import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/db/database.dart';
import 'package:nt_helper/db/daos/presets_dao.dart';
import 'package:nt_helper/models/packed_mapping_data.dart';

void main() {
  late AppDatabase database;

  setUp(() {
    // Create an in-memory database for testing
    database = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  group('PresetsDao - perfPageIndex persistence', () {
    test('saves and loads mapping with perfPageIndex > 0', () async {
      // 1. Create test algorithm
      await database.metadataDao.upsertAlgorithms([
        AlgorithmEntry(
          guid: 'TEST',
          name: 'Test Algorithm',
          numSpecifications: 0,
          pluginFilePath: null,
        ),
      ]);

      // 2. Create a mapping with perfPageIndex = 5
      final testMapping = PackedMappingData(
        source: 1,
        cvInput: 2,
        isUnipolar: false,
        isGate: false,
        volts: 5,
        delta: 100,
        midiChannel: 1,
        midiMappingType: MidiMappingType.cc,
        midiCC: 64,
        isMidiEnabled: true,
        isMidiSymmetric: false,
        isMidiRelative: false,
        midiMin: 0,
        midiMax: 127,
        i2cCC: 32,
        isI2cEnabled: false,
        isI2cSymmetric: false,
        i2cMin: 0,
        i2cMax: 16383,
        perfPageIndex: 5, // Test non-zero performance page
        version: 5,
      );

      // 3. Create a preset with a slot containing the mapping
      final presetDetails = FullPresetDetails(
        preset: PresetEntry(
          id: -1, // -1 indicates new preset for auto-increment
          name: 'Test Preset',
          lastModified: DateTime.now(),
        ),
        slots: [
          FullPresetSlot(
            slot: PresetSlotEntry(
              id: -1,
              presetId: -1,
              slotIndex: 0,
              algorithmGuid: 'TEST',
              customName: null,
            ),
            algorithm: AlgorithmEntry(
              guid: 'TEST',
              name: 'Test Algorithm',
              numSpecifications: 0,
              pluginFilePath: null,
            ),
            parameterValues: {},
            parameterStringValues: {},
            mappings: {
              10: testMapping, // Parameter 10 has the mapping
            },
          ),
        ],
      );

      // 4. Save the preset
      final presetId = await database.presetsDao.saveFullPreset(presetDetails);

      // 5. Load the preset back
      final loadedPreset = await database.presetsDao.getFullPresetDetails(presetId);

      // 6. Verify perfPageIndex was persisted correctly
      expect(loadedPreset, isNotNull);
      expect(loadedPreset!.slots.length, equals(1));

      final loadedMapping = loadedPreset.slots[0].mappings[10];
      expect(loadedMapping, isNotNull);
      expect(loadedMapping!.perfPageIndex, equals(5),
        reason: 'perfPageIndex should be persisted to database');
    });

    test('saves mapping with perfPageIndex = 0 (not assigned)', () async {
      // 1. Create test algorithm
      await database.metadataDao.upsertAlgorithms([
        AlgorithmEntry(
          guid: 'TST2',
          name: 'Test Algorithm 2',
          numSpecifications: 0,
          pluginFilePath: null,
        ),
      ]);

      // 2. Create a mapping with perfPageIndex = 0 (not assigned)
      final testMapping = PackedMappingData(
        source: 1,
        cvInput: 2,
        isUnipolar: false,
        isGate: false,
        volts: 5,
        delta: 100,
        midiChannel: 1,
        midiMappingType: MidiMappingType.cc,
        midiCC: 64,
        isMidiEnabled: true,
        isMidiSymmetric: false,
        isMidiRelative: false,
        midiMin: 0,
        midiMax: 127,
        i2cCC: 32,
        isI2cEnabled: false,
        isI2cSymmetric: false,
        i2cMin: 0,
        i2cMax: 16383,
        perfPageIndex: 0, // Not assigned
        version: 5,
      );

      // 3. Create and save preset
      final presetDetails = FullPresetDetails(
        preset: PresetEntry(
          id: -1,
          name: 'Test Preset 2',
          lastModified: DateTime.now(),
        ),
        slots: [
          FullPresetSlot(
            slot: PresetSlotEntry(
              id: -1,
              presetId: -1,
              slotIndex: 0,
              algorithmGuid: 'TST2',
              customName: null,
            ),
            algorithm: AlgorithmEntry(
              guid: 'TST2',
              name: 'Test Algorithm 2',
              numSpecifications: 0,
              pluginFilePath: null,
            ),
            parameterValues: {},
            parameterStringValues: {},
            mappings: {5: testMapping},
          ),
        ],
      );

      final presetId = await database.presetsDao.saveFullPreset(presetDetails);

      // 4. Load and verify
      final loadedPreset = await database.presetsDao.getFullPresetDetails(presetId);
      final loadedMapping = loadedPreset!.slots[0].mappings[5];

      expect(loadedMapping!.perfPageIndex, equals(0),
        reason: 'perfPageIndex = 0 should be persisted correctly');
    });
  });
}
