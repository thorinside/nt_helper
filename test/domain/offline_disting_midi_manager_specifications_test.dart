import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/db/database.dart';
import 'package:nt_helper/db/daos/presets_dao.dart';
import 'package:nt_helper/domain/disting_nt_sysex.dart';
import 'package:nt_helper/domain/offline_disting_midi_manager.dart';

void main() {
  group('OfflineDistingMidiManager specification values', () {
    late AppDatabase database;
    late OfflineDistingMidiManager manager;

    setUp(() async {
      database = AppDatabase.forTesting(NativeDatabase.memory());
      manager = OfflineDistingMidiManager(database);

      for (final (guid, name) in const [
        ('algo-a', 'Algorithm A'),
        ('algo-b', 'Algorithm B'),
        ('algo-c', 'Algorithm C'),
      ]) {
        await database
            .into(database.algorithms)
            .insert(
              AlgorithmsCompanion(
                guid: Value(guid),
                name: Value(name),
                numSpecifications: const Value(1),
              ),
            );
      }
    });

    tearDown(() async {
      await database.close();
    });

    test('loads and returns defensive copies of saved values', () async {
      final sourceValues = <int>[4];
      await manager.initializeFromDb(
        _presetDetails([_slot(0, 'algo-a', 'Algorithm A', sourceValues)]),
      );

      sourceValues[0] = 1;
      final firstRead = await manager.requestAlgorithmGuid(0);
      expect(firstRead?.specifications, [4]);

      firstRead!.specifications[0] = 2;
      expect((await manager.requestAlgorithmGuid(0))?.specifications, [4]);
    });

    test(
      'preserves exact added values through current details and save',
      () async {
        await manager.initializeFromDb(null);
        await manager.requestSetPresetName('Four Channel Quantizer');
        final selectedValues = <int>[4];

        await manager.requestAddAlgorithm(
          _algorithmInfo('algo-a', 'Algorithm A'),
          selectedValues,
        );
        selectedValues[0] = 1;

        expect((await manager.requestAlgorithmGuid(0))?.specifications, [4]);
        expect(
          (await manager.requestCurrentPresetDetails())
              ?.slots
              .single
              .specificationValues,
          [4],
        );

        await manager.requestSavePreset();
        final savedPreset = await database.presetsDao.getPresetByName(
          'Four Channel Quantizer',
        );
        final savedDetails = await database.presetsDao.getFullPresetDetails(
          savedPreset!.id,
        );
        expect(savedDetails!.slots.single.specificationValues, [4]);
      },
    );

    test('keeps values aligned through moves and removal', () async {
      await manager.initializeFromDb(
        _presetDetails([
          _slot(0, 'algo-a', 'Algorithm A', [1]),
          _slot(1, 'algo-b', 'Algorithm B', [2]),
          _slot(2, 'algo-c', 'Algorithm C', [3]),
        ]),
      );

      await manager.requestMoveAlgorithmDown(0);
      expect(await _slotIdentities(manager), [
        {
          'guid': 'algo-b',
          'specifications': [2],
        },
        {
          'guid': 'algo-a',
          'specifications': [1],
        },
        {
          'guid': 'algo-c',
          'specifications': [3],
        },
      ]);

      await manager.requestMoveAlgorithmUp(2);
      expect(await _slotIdentities(manager), [
        {
          'guid': 'algo-b',
          'specifications': [2],
        },
        {
          'guid': 'algo-c',
          'specifications': [3],
        },
        {
          'guid': 'algo-a',
          'specifications': [1],
        },
      ]);

      await manager.requestRemoveAlgorithm(1);
      expect(await _slotIdentities(manager), [
        {
          'guid': 'algo-b',
          'specifications': [2],
        },
        {
          'guid': 'algo-a',
          'specifications': [1],
        },
      ]);
    });

    test('new preset clears all saved specification values', () async {
      await manager.initializeFromDb(
        _presetDetails([
          _slot(0, 'algo-a', 'Algorithm A', [4]),
        ]),
      );

      await manager.requestNewPreset();

      expect(await manager.requestAlgorithmGuid(0), isNull);
      expect((await manager.requestCurrentPresetDetails())?.slots, isEmpty);
    });
  });
}

AlgorithmInfo _algorithmInfo(String guid, String name) => AlgorithmInfo(
  algorithmIndex: 0,
  name: name,
  guid: guid,
  specifications: [
    Specification(name: 'Channels', min: 1, max: 8, defaultValue: 1, type: 0),
  ],
);

FullPresetDetails _presetDetails(List<FullPresetSlot> slots) =>
    FullPresetDetails(
      preset: PresetEntry(
        id: -1,
        name: 'Test Preset',
        lastModified: DateTime(2026),
        isTemplate: false,
      ),
      slots: slots,
    );

FullPresetSlot _slot(
  int index,
  String guid,
  String name,
  List<int> specificationValues,
) => FullPresetSlot(
  slot: PresetSlotEntry(
    id: index + 1,
    presetId: -1,
    slotIndex: index,
    algorithmGuid: guid,
    customName: null,
  ),
  algorithm: AlgorithmEntry(
    guid: guid,
    name: name,
    numSpecifications: 1,
    pluginFilePath: null,
  ),
  specificationValues: specificationValues,
  parameterValues: const {},
  parameterStringValues: const {},
  mappings: const {},
);

Future<List<Map<String, Object>>> _slotIdentities(
  OfflineDistingMidiManager manager,
) async {
  final result = <Map<String, Object>>[];
  for (var index = 0; ; index++) {
    final algorithm = await manager.requestAlgorithmGuid(index);
    if (algorithm == null) break;
    result.add({
      'guid': algorithm.guid,
      'specifications': algorithm.specifications,
    });
  }
  return result;
}
