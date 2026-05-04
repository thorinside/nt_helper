import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nt_helper/cubit/disting_cubit.dart';
import 'package:nt_helper/db/daos/metadata_dao.dart';
import 'package:nt_helper/db/database.dart';
import 'package:nt_helper/domain/disting_nt_sysex.dart';
import 'package:nt_helper/domain/i_disting_midi_manager.dart';
import 'package:nt_helper/models/firmware_version.dart';
import 'package:nt_helper/models/packed_mapping_data.dart';
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
    registerFallbackValue(
      AlgorithmInfo(
        algorithmIndex: 0,
        name: 'fallback',
        guid: 'fallback',
        specifications: const [],
      ),
    );
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

  Slot makeSlot({int algorithmIndex = 0, int paramCount = 1}) {
    return Slot(
      algorithm: Algorithm(
        algorithmIndex: algorithmIndex,
        guid: 'test',
        name: 'Test',
      ),
      routing: RoutingInfo.filler(),
      pages: ParameterPages(
        algorithmIndex: algorithmIndex,
        pages: const [],
      ),
      parameters: List.generate(
        paramCount,
        (i) => ParameterInfo(
          algorithmIndex: algorithmIndex,
          parameterNumber: i,
          min: 0,
          max: 100,
          defaultValue: 0,
          unit: 0,
          name: 'p$i',
          powerOfTen: 0,
        ),
      ),
      values: List.generate(
        paramCount,
        (i) => ParameterValue(
          algorithmIndex: algorithmIndex,
          parameterNumber: i,
          value: 0,
        ),
      ),
      enums: List.generate(
        paramCount,
        (i) => ParameterEnumStrings(
          algorithmIndex: algorithmIndex,
          parameterNumber: i,
          values: const [],
        ),
      ),
      mappings: List.generate(
        paramCount,
        (i) => Mapping(
          algorithmIndex: algorithmIndex,
          parameterNumber: i,
          packedMappingData: PackedMappingData.filler(),
        ),
      ),
      valueStrings: List.generate(
        paramCount,
        (i) => ParameterValueString(
          algorithmIndex: algorithmIndex,
          parameterNumber: i,
          value: '',
        ),
      ),
    );
  }

  DistingStateSynchronized makeSyncState({
    String presetName = 'Test Preset',
    bool isDirty = false,
    List<Slot>? slots,
  }) {
    return DistingStateSynchronized(
      disting: mockDisting,
      distingVersion: '1.10.0',
      firmwareVersion: FirmwareVersion('1.14.0'),
      presetName: presetName,
      algorithms: const [],
      slots: slots ?? const [],
      unitStrings: const [],
      offline: false,
      isDirty: isDirty,
    );
  }

  group('DistingStateSynchronized.isDirty default', () {
    test('a freshly constructed synchronized state has isDirty == false', () {
      final s = DistingStateSynchronized(
        disting: mockDisting,
        distingVersion: '1.10.0',
        firmwareVersion: FirmwareVersion('1.14.0'),
        presetName: 'New',
        algorithms: const [],
        slots: const [],
        unitStrings: const [],
      );
      expect(s.isDirty, isFalse);
    });

    test('makeSyncState helper still respects explicit isDirty values', () {
      expect(makeSyncState().isDirty, isFalse);
      expect(makeSyncState(isDirty: true).isDirty, isTrue);
    });
  });

  group('cubit.updateParameterValue()', () {
    test('marks state dirty (real-time slider scrub)', () async {
      cubit.emit(makeSyncState(slots: [makeSlot()]));
      expect((cubit.state as DistingStateSynchronized).isDirty, isFalse);

      await cubit.updateParameterValue(
        algorithmIndex: 0,
        parameterNumber: 0,
        value: 42,
        userIsChangingTheValue: true,
      );

      expect((cubit.state as DistingStateSynchronized).isDirty, isTrue);
    });

    test('marks state dirty (slider release)', () async {
      cubit.emit(makeSyncState(slots: [makeSlot()]));
      expect((cubit.state as DistingStateSynchronized).isDirty, isFalse);

      await cubit.updateParameterValue(
        algorithmIndex: 0,
        parameterNumber: 0,
        value: 50,
        userIsChangingTheValue: false,
      );

      expect((cubit.state as DistingStateSynchronized).isDirty, isTrue);
    });
  });

  group('cubit.updateParameterString()', () {
    test('marks state dirty after setting and refreshing string', () async {
      when(
        () => mockDisting.setParameterString(any(), any(), any()),
      ).thenAnswer((_) async {});
      when(
        () => mockDisting.requestParameterValueString(any(), any()),
      ).thenAnswer((_) async => ParameterValueString(
            algorithmIndex: 0,
            parameterNumber: 0,
            value: 'hi',
          ));
      cubit.emit(makeSyncState(slots: [makeSlot()]));
      expect((cubit.state as DistingStateSynchronized).isDirty, isFalse);

      await cubit.updateParameterString(
        algorithmIndex: 0,
        parameterNumber: 0,
        value: 'hi',
      );

      expect((cubit.state as DistingStateSynchronized).isDirty, isTrue);
    });
  });

  group('cubit algorithm ops', () {
    test('onAlgorithmSelected marks state dirty', () async {
      final algorithmInfo = AlgorithmInfo(
        algorithmIndex: 0,
        name: 'Test Algo',
        guid: 'test',
        specifications: const [],
      );
      when(
        () => mockDisting.requestAddAlgorithm(any(), any()),
      ).thenAnswer((_) async {});

      cubit.emit(makeSyncState());
      await cubit.onAlgorithmSelected(algorithmInfo, const []);

      expect((cubit.state as DistingStateSynchronized).isDirty, isTrue);
    });

    test('onRemoveAlgorithm marks state dirty', () async {
      when(
        () => mockDisting.requestRemoveAlgorithm(any()),
      ).thenAnswer((_) async {});

      cubit.emit(makeSyncState(slots: [makeSlot()]));
      await cubit.onRemoveAlgorithm(0);

      expect((cubit.state as DistingStateSynchronized).isDirty, isTrue);
    });

    test('moveAlgorithmUp marks state dirty', () async {
      when(
        () => mockDisting.requestMoveAlgorithmUp(any()),
      ).thenAnswer((_) async {});

      cubit.emit(
        makeSyncState(
          slots: [
            makeSlot(algorithmIndex: 0),
            makeSlot(algorithmIndex: 1),
          ],
        ),
      );
      await cubit.moveAlgorithmUp(1);

      expect((cubit.state as DistingStateSynchronized).isDirty, isTrue);
    });

    test('moveAlgorithmDown marks state dirty', () async {
      when(
        () => mockDisting.requestMoveAlgorithmDown(any()),
      ).thenAnswer((_) async {});

      cubit.emit(
        makeSyncState(
          slots: [
            makeSlot(algorithmIndex: 0),
            makeSlot(algorithmIndex: 1),
          ],
        ),
      );
      await cubit.moveAlgorithmDown(0);

      expect((cubit.state as DistingStateSynchronized).isDirty, isTrue);
    });
  });

  group('cubit slot ops', () {
    test('renameSlot marks state dirty', () async {
      when(
        () => mockDisting.requestSendSlotName(any(), any()),
      ).thenAnswer((_) async {});

      cubit.emit(makeSyncState(slots: [makeSlot()]));
      cubit.renameSlot(0, 'New Name');
      // Allow microtask queue to flush so the optimistic emit lands.
      await Future<void>.delayed(Duration.zero);

      expect((cubit.state as DistingStateSynchronized).isDirty, isTrue);
    });
  });

  group('device-truth refreshes preserve isDirty', () {
    test('refreshRouting (slot state delegate) preserves dirty flag', () async {
      when(
        () => mockDisting.requestRoutingInformation(any()),
      ).thenAnswer((_) async => RoutingInfo.filler());

      cubit.emit(makeSyncState(isDirty: true, slots: [makeSlot()]));
      await cubit.refreshRouting();

      expect((cubit.state as DistingStateSynchronized).isDirty, isTrue);
    });

    test('refreshRouting does not falsely mark dirty when clean', () async {
      when(
        () => mockDisting.requestRoutingInformation(any()),
      ).thenAnswer((_) async => RoutingInfo.filler());

      cubit.emit(makeSyncState(slots: [makeSlot()]));
      await cubit.refreshRouting();

      expect((cubit.state as DistingStateSynchronized).isDirty, isFalse);
    });
  });

  group('cubit.refresh()', () {
    test('clears isDirty when state refresh from device succeeds', () async {
      when(
        () => mockDisting.requestNumAlgorithmsInPreset(),
      ).thenAnswer((_) async => 0);
      when(
        () => mockDisting.requestPresetName(),
      ).thenAnswer((_) async => 'Refreshed');

      // Offline avoids the background algorithm refresh side-effect.
      cubit.emit(
        DistingStateSynchronized(
          disting: mockDisting,
          distingVersion: '1.10.0',
          firmwareVersion: FirmwareVersion('1.14.0'),
          presetName: 'Test Preset',
          algorithms: const [],
          slots: const [],
          unitStrings: const [],
          offline: true,
          isDirty: true,
        ),
      );

      await cubit.refresh();

      expect((cubit.state as DistingStateSynchronized).isDirty, isFalse);
    });
  });

  group('cubit.savePreset()', () {
    test('clears isDirty on success', () async {
      when(() => mockDisting.requestSavePreset()).thenAnswer((_) async {});
      cubit.emit(makeSyncState(isDirty: true));

      await cubit.savePreset();

      verify(() => mockDisting.requestSavePreset()).called(1);
      final s = cubit.state as DistingStateSynchronized;
      expect(s.isDirty, isFalse);
    });

    test('leaves isDirty set when save throws', () async {
      when(
        () => mockDisting.requestSavePreset(),
      ).thenAnswer((_) async => throw Exception('save failed'));
      cubit.emit(makeSyncState(isDirty: true));

      await expectLater(cubit.savePreset(), throwsA(isA<Exception>()));

      final s = cubit.state as DistingStateSynchronized;
      expect(s.isDirty, isTrue);
    });

    test('is a no-op when state is not synchronized', () async {
      // Initial state is DistingStateInitial; no synchronized state present.
      await cubit.savePreset();

      verifyNever(() => mockDisting.requestSavePreset());
      expect(cubit.state, isA<DistingStateInitial>());
    });
  });
}
