import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nt_helper/cubit/disting_cubit.dart';
import 'package:nt_helper/domain/i_disting_midi_manager.dart';
import 'package:nt_helper/domain/disting_nt_sysex.dart';
import 'package:nt_helper/db/database.dart';
import 'package:nt_helper/db/daos/metadata_dao.dart';
import 'package:nt_helper/models/firmware_version.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../test_helpers/mock_midi_command.dart';

class MockAppDatabase extends Mock implements AppDatabase {}

class MockMetadataDao extends Mock implements MetadataDao {}

class MockDistingMidiManager extends Mock implements IDistingMidiManager {}

void main() {
  late DistingCubit cubit;
  late MockAppDatabase mockDatabase;
  late MockMetadataDao mockMetadataDao;
  late MockDistingMidiManager mockDisting;
  late MockMidiCommand mockMidiCommand;

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    registerFallbackValue(DistingState.initial());
  });

  setUp(() {
    mockDatabase = MockAppDatabase();
    mockMetadataDao = MockMetadataDao();
    mockDisting = MockDistingMidiManager();
    mockMidiCommand = MockMidiCommand();

    when(() => mockDatabase.metadataDao).thenReturn(mockMetadataDao);
    when(
      () => mockMetadataDao.hasCachedAlgorithms(),
    ).thenAnswer((_) async => false);

    cubit = DistingCubit(mockDatabase, midiCommand: mockMidiCommand);
  });

  tearDown(() async {
    await cubit.close();
  });

  DistingStateSynchronized _makeSyncState({
    required List<Slot> slots,
    String presetName = 'Test Preset',
  }) {
    return DistingStateSynchronized(
      disting: mockDisting,
      distingVersion: '1.10.0',
      firmwareVersion: FirmwareVersion('1.14.0'),
      presetName: presetName,
      algorithms: const [],
      slots: slots,
      unitStrings: const [],
      offline: false,
    );
  }

  Slot _makeSlot({
    required int index,
    required String guid,
    required Map<int, int> values,
  }) {
    return Slot(
      algorithm: Algorithm(
        algorithmIndex: index,
        guid: guid,
        name: 'Algo $guid',
        specifications: const [],
      ),
      routing: RoutingInfo.filler(),
      pages: ParameterPages(algorithmIndex: index, pages: const []),
      parameters: values.entries
          .map(
            (e) => ParameterInfo(
              algorithmIndex: index,
              parameterNumber: e.key,
              min: 0,
              max: 100,
              defaultValue: 0,
              unit: 0,
              name: 'Param ${e.key}',
              powerOfTen: 0,
              ioFlags: 0,
            ),
          )
          .toList(),
      values: values.entries
          .map(
            (e) => ParameterValue(
              algorithmIndex: index,
              parameterNumber: e.key,
              value: e.value,
              isDisabled: false,
            ),
          )
          .toList(),
      enums: const [],
      mappings: const [],
      valueStrings: const [],
    );
  }

  group('Checkpoint', () {
    test('createCheckpoint returns null when not synchronized', () {
      expect(cubit.createCheckpoint(), isNull);
      expect(cubit.checkpoints, isEmpty);
    });

    test('createCheckpoint captures current state', () {
      final state = _makeSyncState(
        slots: [
          _makeSlot(index: 0, guid: 'abcd', values: {0: 50, 1: 75}),
          _makeSlot(index: 1, guid: 'efgh', values: {0: 10}),
        ],
      );
      cubit.emit(state);

      final checkpoint = cubit.createCheckpoint(label: 'Before change');

      expect(checkpoint, isNotNull);
      expect(checkpoint!.label, 'Before change');
      expect(checkpoint.presetName, 'Test Preset');
      expect(checkpoint.slotCount, 2);
      expect(cubit.checkpoints, hasLength(1));
    });

    test('restoreCheckpoint writes back differing values', () async {
      // Set up initial state and create checkpoint
      final initialState = _makeSyncState(
        slots: [
          _makeSlot(index: 0, guid: 'abcd', values: {0: 50, 1: 75}),
        ],
      );
      cubit.emit(initialState);
      final checkpoint = cubit.createCheckpoint();

      // Simulate state change (parameter 0 changed from 50 to 99)
      final changedState = _makeSyncState(
        slots: [
          _makeSlot(index: 0, guid: 'abcd', values: {0: 99, 1: 75}),
        ],
      );
      cubit.emit(changedState);

      // Restore should write back only the changed parameter
      final result = await cubit.restoreCheckpoint(checkpoint!);

      // Should have restored 1 parameter (param 0: 99 → 50)
      expect(result, 1);
    });

    test('restoreCheckpoint returns 0 when nothing changed', () async {
      final state = _makeSyncState(
        slots: [
          _makeSlot(index: 0, guid: 'abcd', values: {0: 50}),
        ],
      );
      cubit.emit(state);
      final checkpoint = cubit.createCheckpoint();

      // State hasn't changed
      final result = await cubit.restoreCheckpoint(checkpoint!);
      expect(result, 0);
    });

    test('restoreCheckpoint fails when algorithm lineup changed', () async {
      final state = _makeSyncState(
        slots: [
          _makeSlot(index: 0, guid: 'abcd', values: {0: 50}),
        ],
      );
      cubit.emit(state);
      final checkpoint = cubit.createCheckpoint();

      // Change algorithm lineup
      final newState = _makeSyncState(
        slots: [
          _makeSlot(index: 0, guid: 'xxxx', values: {0: 50}),
        ],
      );
      cubit.emit(newState);

      final result = await cubit.restoreCheckpoint(checkpoint!);
      expect(result, -1);
    });

    test('restoreCheckpoint fails when slot count changed', () async {
      final state = _makeSyncState(
        slots: [
          _makeSlot(index: 0, guid: 'abcd', values: {0: 50}),
        ],
      );
      cubit.emit(state);
      final checkpoint = cubit.createCheckpoint();

      // Add a slot
      final newState = _makeSyncState(
        slots: [
          _makeSlot(index: 0, guid: 'abcd', values: {0: 50}),
          _makeSlot(index: 1, guid: 'efgh', values: {0: 10}),
        ],
      );
      cubit.emit(newState);

      final result = await cubit.restoreCheckpoint(checkpoint!);
      expect(result, -1);
    });

    test('evicts oldest checkpoint when over limit', () {
      final state = _makeSyncState(
        slots: [_makeSlot(index: 0, guid: 'abcd', values: {0: 50})],
      );
      cubit.emit(state);

      // Create 11 checkpoints (limit is 10)
      for (int i = 0; i < 11; i++) {
        cubit.createCheckpoint(label: 'Checkpoint $i');
      }

      expect(cubit.checkpoints, hasLength(10));
      // Oldest (Checkpoint 0) should have been evicted
      expect(cubit.checkpoints.first.label, 'Checkpoint 1');
      expect(cubit.checkpoints.last.label, 'Checkpoint 10');
    });

    test('clearCheckpoints removes all', () {
      final state = _makeSyncState(
        slots: [_makeSlot(index: 0, guid: 'abcd', values: {0: 50})],
      );
      cubit.emit(state);

      cubit.createCheckpoint();
      cubit.createCheckpoint();
      expect(cubit.checkpoints, hasLength(2));

      cubit.clearCheckpoints();
      expect(cubit.checkpoints, isEmpty);
    });

    test('removeCheckpoint removes specific checkpoint', () {
      final state = _makeSyncState(
        slots: [_makeSlot(index: 0, guid: 'abcd', values: {0: 50})],
      );
      cubit.emit(state);

      final cp1 = cubit.createCheckpoint(label: 'first');
      cubit.createCheckpoint(label: 'second');
      expect(cubit.checkpoints, hasLength(2));

      cubit.removeCheckpoint(cp1!);
      expect(cubit.checkpoints, hasLength(1));
      expect(cubit.checkpoints.first.label, 'second');
    });
  });
}
