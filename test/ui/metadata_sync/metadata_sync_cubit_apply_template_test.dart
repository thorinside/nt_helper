import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nt_helper/cubit/disting_cubit.dart';
import 'package:nt_helper/db/daos/metadata_dao.dart';
import 'package:nt_helper/db/daos/presets_dao.dart';
import 'package:nt_helper/db/database.dart';
import 'package:nt_helper/domain/disting_nt_sysex.dart';
import 'package:nt_helper/domain/i_disting_midi_manager.dart';
import 'package:nt_helper/models/firmware_version.dart';
import 'package:nt_helper/models/packed_mapping_data.dart';
import 'package:nt_helper/ui/metadata_sync/metadata_sync_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../test_helpers/mock_midi_command.dart';

class MockDistingMidiManager extends Mock implements IDistingMidiManager {}

class MockAppDatabase extends Mock implements AppDatabase {}

class MockMetadataDao extends Mock implements MetadataDao {}

class MockPresetsDao extends Mock implements PresetsDao {}

class FakeAlgorithmInfo extends Fake implements AlgorithmInfo {}

class FakePackedMappingData extends Fake implements PackedMappingData {}

FullPresetDetails _template({
  int id = 1,
  String name = 'Tmpl',
  List<FullPresetSlot>? slots,
}) => FullPresetDetails(
  preset: PresetEntry(
    id: id,
    name: name,
    lastModified: DateTime.now(),
    isTemplate: true,
  ),
  slots:
      slots ??
      [
        FullPresetSlot(
          slot: PresetSlotEntry(
            id: 1,
            presetId: id,
            slotIndex: 0,
            algorithmGuid: 'guid-1',
          ),
          algorithm: AlgorithmEntry(
            guid: 'guid-1',
            name: 'Alg 1',
            numSpecifications: 0,
          ),
          parameterValues: {},
          parameterStringValues: {},
          mappings: {},
        ),
      ],
);

FullAlgorithmDetails _fullAlgorithmDetails(String guid, String name) {
  return FullAlgorithmDetails(
    algorithm: AlgorithmEntry(guid: guid, name: name, numSpecifications: 0),
    specifications: [],
    parameters: [],
    parameterPages: [],
    enums: {},
  );
}

void _stubRefreshableDevice(
  MockDistingMidiManager manager,
  List<Algorithm> deviceAlgorithms, {
  String presetName = 'Device Preset',
}) {
  when(
    () => manager.requestNumAlgorithmsInPreset(),
  ).thenAnswer((_) async => deviceAlgorithms.length);
  when(() => manager.requestPresetName()).thenAnswer((_) async => presetName);
  when(() => manager.requestParameterPages(any())).thenAnswer((invocation) {
    final index = invocation.positionalArguments[0] as int;
    return Future.value(ParameterPages(algorithmIndex: index, pages: []));
  });
  when(() => manager.requestNumberOfParameters(any())).thenAnswer((invocation) {
    final index = invocation.positionalArguments[0] as int;
    return Future.value(NumParameters(algorithmIndex: index, numParameters: 0));
  });
  when(() => manager.requestAlgorithmGuid(any())).thenAnswer((invocation) {
    final index = invocation.positionalArguments[0] as int;
    return Future.value(deviceAlgorithms[index]);
  });
  when(() => manager.requestAllParameterValues(any())).thenAnswer((invocation) {
    final index = invocation.positionalArguments[0] as int;
    return Future.value(AllParameterValues(algorithmIndex: index, values: []));
  });
}

DistingStateSynchronized _synchronizedState(
  IDistingMidiManager manager, {
  String firmwareVersion = '1.10.0',
}) {
  return DistingStateSynchronized(
    disting: manager,
    distingVersion: firmwareVersion,
    firmwareVersion: FirmwareVersion(firmwareVersion),
    presetName: 'Initial',
    algorithms: const [],
    slots: const [],
    unitStrings: const [],
    offline: true,
  );
}

void main() {
  late MetadataSyncCubit cubit;
  late MockDistingMidiManager mockManager;
  late MockAppDatabase mockDatabase;
  late MockMetadataDao mockMetadataDao;
  late MockPresetsDao mockPresetsDao;

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    registerFallbackValue(FakeAlgorithmInfo());
    registerFallbackValue(FakePackedMappingData());
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    mockManager = MockDistingMidiManager();
    mockDatabase = MockAppDatabase();
    mockMetadataDao = MockMetadataDao();
    mockPresetsDao = MockPresetsDao();
    when(() => mockDatabase.metadataDao).thenReturn(mockMetadataDao);
    when(() => mockDatabase.presetsDao).thenReturn(mockPresetsDao);
    cubit = MetadataSyncCubit(mockDatabase);
  });

  tearDown(() => cubit.close());

  group('applyTemplateToPreset', () {
    blocTest<MetadataSyncCubit, MetadataSyncState>(
      'delegates to DAO with the given args and emits ViewingLocalData on success',
      build: () {
        when(
          () => mockPresetsDao.applyTemplateSlots(
            templateId: any(named: 'templateId'),
            targetPresetId: any(named: 'targetPresetId'),
            templateSlotIndices: any(named: 'templateSlotIndices'),
            insertionOffset: any(named: 'insertionOffset'),
            overwrite: any(named: 'overwrite'),
          ),
        ).thenAnswer(
          (_) async => const ApplyTemplateSlotsResult(
            targetPresetId: 42,
            insertedSlotIndices: [0, 1, 2],
            skippedTemplateSlotIndices: [],
          ),
        );
        when(
          () => mockMetadataDao.getAllAlgorithms(),
        ).thenAnswer((_) async => []);
        when(
          () => mockMetadataDao.getAlgorithmParameterCounts(),
        ).thenAnswer((_) async => <String, int>{});
        when(
          () => mockPresetsDao.getAllPresets(),
        ).thenAnswer((_) async => <PresetEntry>[]);
        return cubit;
      },
      act: (c) async {
        await c.applyTemplateToPreset(
          templateId: 7,
          targetPresetId: 42,
          templateSlotIndices: const [0, 1, 2],
          insertionOffset: 3,
          overwrite: false,
        );
      },
      expect: () => [isA<LoadingPreset>(), isA<ViewingLocalData>()],
      verify: (_) {
        verify(
          () => mockPresetsDao.applyTemplateSlots(
            templateId: 7,
            targetPresetId: 42,
            templateSlotIndices: const [0, 1, 2],
            insertionOffset: 3,
            overwrite: false,
          ),
        ).called(1);
      },
    );

    blocTest<MetadataSyncCubit, MetadataSyncState>(
      'translates TemplateSpaceException to metadataSyncFailure',
      build: () {
        when(
          () => mockPresetsDao.applyTemplateSlots(
            templateId: any(named: 'templateId'),
            targetPresetId: any(named: 'targetPresetId'),
            templateSlotIndices: any(named: 'templateSlotIndices'),
            insertionOffset: any(named: 'insertionOffset'),
            overwrite: any(named: 'overwrite'),
          ),
        ).thenThrow(TemplateSpaceException(current: 30, applied: 4));
        return cubit;
      },
      act: (c) async {
        await expectLater(
          () => c.applyTemplateToPreset(
            templateId: 1,
            targetPresetId: 2,
            templateSlotIndices: const [0, 1, 2, 3],
            insertionOffset: 0,
          ),
          throwsA(isA<TemplateSpaceException>()),
        );
      },
      expect: () => [
        isA<MetadataSyncFailure>().having(
          (s) => s.error,
          'error message',
          allOf(contains('30'), contains('4'), contains('32')),
        ),
      ],
    );

    blocTest<MetadataSyncCubit, MetadataSyncState>(
      'returns DAO result to the caller',
      build: () {
        when(
          () => mockPresetsDao.applyTemplateSlots(
            templateId: any(named: 'templateId'),
            targetPresetId: any(named: 'targetPresetId'),
            templateSlotIndices: any(named: 'templateSlotIndices'),
            insertionOffset: any(named: 'insertionOffset'),
            overwrite: any(named: 'overwrite'),
          ),
        ).thenAnswer(
          (_) async => const ApplyTemplateSlotsResult(
            targetPresetId: 9,
            insertedSlotIndices: [5],
            skippedTemplateSlotIndices: [1],
            warning: 'Skipped 1.',
          ),
        );
        when(
          () => mockMetadataDao.getAllAlgorithms(),
        ).thenAnswer((_) async => []);
        when(
          () => mockMetadataDao.getAlgorithmParameterCounts(),
        ).thenAnswer((_) async => <String, int>{});
        when(
          () => mockPresetsDao.getAllPresets(),
        ).thenAnswer((_) async => <PresetEntry>[]);
        return cubit;
      },
      act: (c) async {
        final result = await c.applyTemplateToPreset(
          templateId: 1,
          targetPresetId: 9,
          templateSlotIndices: const [0, 1],
          insertionOffset: 5,
        );
        expect(result.targetPresetId, 9);
        expect(result.insertedSlotIndices, [5]);
        expect(result.skippedTemplateSlotIndices, [1]);
        expect(result.warning, isNotNull);
      },
    );
  });

  group('loadPresetToDevice', () {
    test(
      'refreshes attached DistingCubit slots after replacing preset',
      () async {
        final deviceAlgorithms = <Algorithm>[
          Algorithm(algorithmIndex: 0, guid: 'old', name: 'Old'),
        ];
        _stubRefreshableDevice(
          mockManager,
          deviceAlgorithms,
          presetName: 'Replacement',
        );
        when(() => mockManager.requestNewPreset()).thenAnswer((_) async {
          deviceAlgorithms.clear();
        });
        when(() => mockManager.requestAddAlgorithm(any(), any())).thenAnswer((
          invocation,
        ) async {
          final info = invocation.positionalArguments[0] as AlgorithmInfo;
          deviceAlgorithms.add(
            Algorithm(
              algorithmIndex: deviceAlgorithms.length,
              guid: info.guid,
              name: info.name,
            ),
          );
        });
        when(
          () => mockManager.requestSendSlotName(any(), any()),
        ).thenAnswer((_) async => {});
        when(
          () => mockManager.setParameterValue(any(), any(), any()),
        ).thenAnswer((_) async => {});
        when(
          () => mockManager.requestSetMapping(any(), any(), any()),
        ).thenAnswer((_) async => {});
        when(
          () => mockManager.requestSetPresetName(any()),
        ).thenAnswer((_) async => {});
        when(() => mockManager.requestSavePreset()).thenAnswer((_) async => {});
        when(
          () => mockMetadataDao.getFullAlgorithmDetails('guid-1'),
        ).thenAnswer((_) async => _fullAlgorithmDetails('guid-1', 'Alg 1'));
        when(
          () => mockMetadataDao.getFullAlgorithmDetails('guid-2'),
        ).thenAnswer((_) async => _fullAlgorithmDetails('guid-2', 'Alg 2'));
        when(
          () => mockMetadataDao.getAllAlgorithms(),
        ).thenAnswer((_) async => []);
        when(
          () => mockMetadataDao.getAlgorithmParameterCounts(),
        ).thenAnswer((_) async => <String, int>{});
        when(
          () => mockPresetsDao.getAllPresets(),
        ).thenAnswer((_) async => <PresetEntry>[]);

        final distingCubit = DistingCubit(
          mockDatabase,
          midiCommand: MockMidiCommand(),
        )..emit(_synchronizedState(mockManager));
        final syncCubit = MetadataSyncCubit(mockDatabase, distingCubit);
        addTearDown(syncCubit.close);
        addTearDown(distingCubit.close);

        await syncCubit.loadPresetToDevice(
          _template(
            name: 'Replacement',
            slots: [
              FullPresetSlot(
                slot: const PresetSlotEntry(
                  id: 1,
                  presetId: 1,
                  slotIndex: 0,
                  algorithmGuid: 'guid-1',
                  customName: 'Custom Alg 1',
                ),
                algorithm: const AlgorithmEntry(
                  guid: 'guid-1',
                  name: 'Alg 1',
                  numSpecifications: 0,
                ),
                parameterValues: {},
                parameterStringValues: {},
                mappings: {},
              ),
              FullPresetSlot(
                slot: const PresetSlotEntry(
                  id: 2,
                  presetId: 1,
                  slotIndex: 1,
                  algorithmGuid: 'guid-2',
                  customName: 'Custom Alg 2',
                ),
                algorithm: const AlgorithmEntry(
                  guid: 'guid-2',
                  name: 'Alg 2',
                  numSpecifications: 0,
                ),
                parameterValues: {},
                parameterStringValues: {},
                mappings: {},
              ),
            ],
          ),
          mockManager,
        );

        final refreshedState = distingCubit.state as DistingStateSynchronized;
        expect(refreshedState.slots.map((slot) => slot.algorithm.guid), [
          'guid-1',
          'guid-2',
        ]);
        verify(
          () => mockManager.requestSendSlotName(0, 'Custom Alg 1'),
        ).called(1);
        verify(
          () => mockManager.requestSendSlotName(1, 'Custom Alg 2'),
        ).called(1);
      },
    );
  });

  group('applyTemplateToDevice', () {
    test(
      'rejects expressive MIDI mappings when attached firmware is before 1.17',
      () async {
        final deviceAlgorithms = <Algorithm>[];
        _stubRefreshableDevice(mockManager, deviceAlgorithms);
        when(() => mockManager.requestAddAlgorithm(any(), any())).thenAnswer((
          invocation,
        ) async {
          final info = invocation.positionalArguments[0] as AlgorithmInfo;
          deviceAlgorithms.add(
            Algorithm(
              algorithmIndex: deviceAlgorithms.length,
              guid: info.guid,
              name: info.name,
            ),
          );
        });
        when(
          () => mockManager.requestSendSlotName(any(), any()),
        ).thenAnswer((_) async => {});
        when(
          () => mockManager.setParameterValue(any(), any(), any()),
        ).thenAnswer((_) async => {});
        when(
          () => mockManager.requestSetMapping(any(), any(), any()),
        ).thenAnswer((_) async => {});
        when(
          () => mockMetadataDao.getFullAlgorithmDetails('guid-1'),
        ).thenAnswer((_) async => _fullAlgorithmDetails('guid-1', 'Alg 1'));
        when(
          () => mockMetadataDao.getAllAlgorithms(),
        ).thenAnswer((_) async => []);
        when(
          () => mockMetadataDao.getAlgorithmParameterCounts(),
        ).thenAnswer((_) async => <String, int>{});
        when(
          () => mockPresetsDao.getAllPresets(),
        ).thenAnswer((_) async => <PresetEntry>[]);

        final distingCubit = DistingCubit(
          mockDatabase,
          midiCommand: MockMidiCommand(),
        )..emit(_synchronizedState(mockManager, firmwareVersion: '1.16.0'));
        final syncCubit = MetadataSyncCubit(mockDatabase, distingCubit);
        addTearDown(syncCubit.close);
        addTearDown(distingCubit.close);

        await syncCubit.applyTemplateToDevice(
          template: _template(
            slots: [
              FullPresetSlot(
                slot: const PresetSlotEntry(
                  id: 1,
                  presetId: 1,
                  slotIndex: 0,
                  algorithmGuid: 'guid-1',
                ),
                algorithm: const AlgorithmEntry(
                  guid: 'guid-1',
                  name: 'Alg 1',
                  numSpecifications: 0,
                ),
                parameterValues: {},
                parameterStringValues: {},
                mappings: {
                  0: PackedMappingData.filler().copyWith(
                    version: 7,
                    midiMappingType: MidiMappingType.pitchBend,
                    midiCC: 0,
                    isMidiEnabled: true,
                  ),
                },
              ),
            ],
          ),
          templateSlotIndices: const [0],
          manager: mockManager,
        );

        expect(
          syncCubit.state,
          isA<PresetLoadFailure>().having(
            (state) => state.error,
            'error',
            contains('firmware 1.17.0 or newer'),
          ),
        );
        verifyNever(() => mockManager.requestSetMapping(any(), any(), any()));
      },
    );

    test(
      'downgrades non-expressive v7 mappings when attached firmware is before 1.17',
      () async {
        final deviceAlgorithms = <Algorithm>[];
        _stubRefreshableDevice(mockManager, deviceAlgorithms);
        when(() => mockManager.requestAddAlgorithm(any(), any())).thenAnswer((
          invocation,
        ) async {
          final info = invocation.positionalArguments[0] as AlgorithmInfo;
          deviceAlgorithms.add(
            Algorithm(
              algorithmIndex: deviceAlgorithms.length,
              guid: info.guid,
              name: info.name,
            ),
          );
        });
        when(
          () => mockManager.requestSendSlotName(any(), any()),
        ).thenAnswer((_) async => {});
        when(
          () => mockManager.setParameterValue(any(), any(), any()),
        ).thenAnswer((_) async => {});
        when(
          () => mockManager.requestSetMapping(any(), any(), any()),
        ).thenAnswer((_) async => {});
        when(
          () => mockMetadataDao.getFullAlgorithmDetails('guid-1'),
        ).thenAnswer((_) async => _fullAlgorithmDetails('guid-1', 'Alg 1'));
        when(
          () => mockMetadataDao.getAllAlgorithms(),
        ).thenAnswer((_) async => []);
        when(
          () => mockMetadataDao.getAlgorithmParameterCounts(),
        ).thenAnswer((_) async => <String, int>{});
        when(
          () => mockPresetsDao.getAllPresets(),
        ).thenAnswer((_) async => <PresetEntry>[]);

        final distingCubit = DistingCubit(
          mockDatabase,
          midiCommand: MockMidiCommand(),
        )..emit(_synchronizedState(mockManager, firmwareVersion: '1.16.0'));
        final syncCubit = MetadataSyncCubit(mockDatabase, distingCubit);
        addTearDown(syncCubit.close);
        addTearDown(distingCubit.close);

        await syncCubit.applyTemplateToDevice(
          template: _template(
            slots: [
              FullPresetSlot(
                slot: const PresetSlotEntry(
                  id: 1,
                  presetId: 1,
                  slotIndex: 0,
                  algorithmGuid: 'guid-1',
                ),
                algorithm: const AlgorithmEntry(
                  guid: 'guid-1',
                  name: 'Alg 1',
                  numSpecifications: 0,
                ),
                parameterValues: {},
                parameterStringValues: {},
                mappings: {
                  0: PackedMappingData.filler().copyWith(
                    version: 7,
                    midiMappingType: MidiMappingType.cc,
                    midiCC: 74,
                    isMidiEnabled: true,
                  ),
                },
              ),
            ],
          ),
          templateSlotIndices: const [0],
          manager: mockManager,
        );

        final captured =
            verify(
                  () => mockManager.requestSetMapping(0, 0, captureAny()),
                ).captured.single
                as PackedMappingData;
        expect(captured.version, equals(6));
        expect(captured.midiMappingType, equals(MidiMappingType.cc));
        expect(captured.midiCC, equals(74));
      },
    );

    test(
      'refreshes attached DistingCubit slots after appending template',
      () async {
        final deviceAlgorithms = <Algorithm>[
          Algorithm(algorithmIndex: 0, guid: 'old', name: 'Old'),
        ];
        _stubRefreshableDevice(mockManager, deviceAlgorithms);
        when(() => mockManager.requestAddAlgorithm(any(), any())).thenAnswer((
          invocation,
        ) async {
          final info = invocation.positionalArguments[0] as AlgorithmInfo;
          deviceAlgorithms.add(
            Algorithm(
              algorithmIndex: deviceAlgorithms.length,
              guid: info.guid,
              name: info.name,
            ),
          );
        });
        when(
          () => mockManager.requestSendSlotName(any(), any()),
        ).thenAnswer((_) async => {});
        when(
          () => mockManager.setParameterValue(any(), any(), any()),
        ).thenAnswer((_) async => {});
        when(
          () => mockManager.requestSetMapping(any(), any(), any()),
        ).thenAnswer((_) async => {});
        when(
          () => mockMetadataDao.getFullAlgorithmDetails('guid-1'),
        ).thenAnswer((_) async => _fullAlgorithmDetails('guid-1', 'Alg 1'));
        when(
          () => mockMetadataDao.getAllAlgorithms(),
        ).thenAnswer((_) async => []);
        when(
          () => mockMetadataDao.getAlgorithmParameterCounts(),
        ).thenAnswer((_) async => <String, int>{});
        when(
          () => mockPresetsDao.getAllPresets(),
        ).thenAnswer((_) async => <PresetEntry>[]);

        final distingCubit = DistingCubit(
          mockDatabase,
          midiCommand: MockMidiCommand(),
        )..emit(_synchronizedState(mockManager));
        final syncCubit = MetadataSyncCubit(mockDatabase, distingCubit);
        addTearDown(syncCubit.close);
        addTearDown(distingCubit.close);

        await syncCubit.applyTemplateToDevice(
          template: _template(
            slots: [
              FullPresetSlot(
                slot: const PresetSlotEntry(
                  id: 1,
                  presetId: 1,
                  slotIndex: 0,
                  algorithmGuid: 'guid-1',
                  customName: 'Custom Alg 1',
                ),
                algorithm: const AlgorithmEntry(
                  guid: 'guid-1',
                  name: 'Alg 1',
                  numSpecifications: 0,
                ),
                parameterValues: {},
                parameterStringValues: {},
                mappings: {},
              ),
            ],
          ),
          templateSlotIndices: const [0],
          manager: mockManager,
        );

        final refreshedState = distingCubit.state as DistingStateSynchronized;
        expect(refreshedState.slots.map((slot) => slot.algorithm.guid), [
          'old',
          'guid-1',
        ]);
        verify(
          () => mockManager.requestSendSlotName(1, 'Custom Alg 1'),
        ).called(1);
      },
    );

    blocTest<MetadataSyncCubit, MetadataSyncState>(
      'emits progress states injectingTemplate(applied, total) during apply',
      build: () {
        when(
          () => mockManager.requestNumAlgorithmsInPreset(),
        ).thenAnswer((_) async => 0);
        when(
          () => mockManager.requestAddAlgorithm(any(), any()),
        ).thenAnswer((_) async => {});
        when(
          () => mockManager.setParameterValue(any(), any(), any()),
        ).thenAnswer((_) async => {});
        when(
          () => mockManager.requestSetMapping(any(), any(), any()),
        ).thenAnswer((_) async => {});
        when(
          () => mockManager.requestSendSlotName(any(), any()),
        ).thenAnswer((_) async => {});
        when(() => mockMetadataDao.getFullAlgorithmDetails(any())).thenAnswer(
          (_) async => FullAlgorithmDetails(
            algorithm: AlgorithmEntry(
              guid: 'guid-1',
              name: 'Alg 1',
              numSpecifications: 0,
            ),
            specifications: [],
            parameters: [],
            parameterPages: [],
            enums: {},
          ),
        );
        when(
          () => mockMetadataDao.getAllAlgorithms(),
        ).thenAnswer((_) async => []);
        when(
          () => mockMetadataDao.getAlgorithmParameterCounts(),
        ).thenAnswer((_) async => <String, int>{});
        when(
          () => mockPresetsDao.getAllPresets(),
        ).thenAnswer((_) async => <PresetEntry>[]);
        return cubit;
      },
      act: (c) async {
        await c.applyTemplateToDevice(
          template: _template(
            slots: [
              for (var i = 0; i < 2; i++)
                FullPresetSlot(
                  slot: PresetSlotEntry(
                    id: i + 1,
                    presetId: 1,
                    slotIndex: i,
                    algorithmGuid: 'guid-1',
                  ),
                  algorithm: AlgorithmEntry(
                    guid: 'guid-1',
                    name: 'Alg 1',
                    numSpecifications: 0,
                  ),
                  parameterValues: {},
                  parameterStringValues: {},
                  mappings: {},
                ),
            ],
          ),
          templateSlotIndices: const [0, 1],
          manager: mockManager,
        );
      },
      expect: () => [
        isA<InjectingTemplate>()
            .having((s) => s.applied, 'applied', 0)
            .having((s) => s.total, 'total', 2),
        isA<InjectingTemplate>()
            .having((s) => s.applied, 'applied', 1)
            .having((s) => s.total, 'total', 2),
        isA<InjectingTemplate>()
            .having((s) => s.applied, 'applied', 2)
            .having((s) => s.total, 'total', 2),
        isA<PresetLoadSuccess>(),
        isA<LoadingPreset>(),
        isA<ViewingLocalData>(),
      ],
    );

    blocTest<MetadataSyncCubit, MetadataSyncState>(
      'only applies the slot indices requested (partial selection)',
      build: () {
        when(
          () => mockManager.requestNumAlgorithmsInPreset(),
        ).thenAnswer((_) async => 0);
        when(
          () => mockManager.requestAddAlgorithm(any(), any()),
        ).thenAnswer((_) async => {});
        when(
          () => mockManager.setParameterValue(any(), any(), any()),
        ).thenAnswer((_) async => {});
        when(
          () => mockManager.requestSetMapping(any(), any(), any()),
        ).thenAnswer((_) async => {});
        when(
          () => mockManager.requestSendSlotName(any(), any()),
        ).thenAnswer((_) async => {});
        when(() => mockMetadataDao.getFullAlgorithmDetails(any())).thenAnswer(
          (_) async => FullAlgorithmDetails(
            algorithm: AlgorithmEntry(
              guid: 'guid-x',
              name: 'Alg x',
              numSpecifications: 0,
            ),
            specifications: [],
            parameters: [],
            parameterPages: [],
            enums: {},
          ),
        );
        when(
          () => mockMetadataDao.getAllAlgorithms(),
        ).thenAnswer((_) async => []);
        when(
          () => mockMetadataDao.getAlgorithmParameterCounts(),
        ).thenAnswer((_) async => <String, int>{});
        when(
          () => mockPresetsDao.getAllPresets(),
        ).thenAnswer((_) async => <PresetEntry>[]);
        return cubit;
      },
      act: (c) async {
        final slots = [
          for (var i = 0; i < 5; i++)
            FullPresetSlot(
              slot: PresetSlotEntry(
                id: i + 1,
                presetId: 1,
                slotIndex: i,
                algorithmGuid: 'guid-$i',
              ),
              algorithm: AlgorithmEntry(
                guid: 'guid-$i',
                name: 'Alg $i',
                numSpecifications: 0,
              ),
              parameterValues: {0: i * 10},
              parameterStringValues: {},
              mappings: {},
            ),
        ];
        await c.applyTemplateToDevice(
          template: _template(slots: slots),
          templateSlotIndices: const [1, 3],
          manager: mockManager,
        );
      },
      verify: (_) {
        verify(() => mockManager.requestAddAlgorithm(any(), any())).called(2);
        verify(() => mockManager.setParameterValue(0, 0, 10)).called(1);
        verify(() => mockManager.setParameterValue(1, 0, 30)).called(1);
        verifyNever(() => mockManager.setParameterValue(any(), 0, 0));
        verifyNever(() => mockManager.setParameterValue(any(), 0, 20));
        verifyNever(() => mockManager.setParameterValue(any(), 0, 40));
      },
    );
  });

  group('injectTemplateToDevice (delegating)', () {
    blocTest<MetadataSyncCubit, MetadataSyncState>(
      'injectTemplateToDevice applies all template slots',
      build: () {
        when(
          () => mockManager.requestNumAlgorithmsInPreset(),
        ).thenAnswer((_) async => 0);
        when(
          () => mockManager.requestAddAlgorithm(any(), any()),
        ).thenAnswer((_) async => {});
        when(
          () => mockManager.setParameterValue(any(), any(), any()),
        ).thenAnswer((_) async => {});
        when(
          () => mockManager.requestSetMapping(any(), any(), any()),
        ).thenAnswer((_) async => {});
        when(
          () => mockManager.requestSendSlotName(any(), any()),
        ).thenAnswer((_) async => {});
        when(() => mockMetadataDao.getFullAlgorithmDetails(any())).thenAnswer(
          (_) async => FullAlgorithmDetails(
            algorithm: AlgorithmEntry(
              guid: 'guid-1',
              name: 'Alg 1',
              numSpecifications: 0,
            ),
            specifications: [],
            parameters: [],
            parameterPages: [],
            enums: {},
          ),
        );
        when(
          () => mockMetadataDao.getAllAlgorithms(),
        ).thenAnswer((_) async => []);
        when(
          () => mockMetadataDao.getAlgorithmParameterCounts(),
        ).thenAnswer((_) async => <String, int>{});
        when(
          () => mockPresetsDao.getAllPresets(),
        ).thenAnswer((_) async => <PresetEntry>[]);
        return cubit;
      },
      act: (c) async {
        await c.injectTemplateToDevice(
          _template(
            slots: [
              for (var i = 0; i < 3; i++)
                FullPresetSlot(
                  slot: PresetSlotEntry(
                    id: i + 1,
                    presetId: 1,
                    slotIndex: i,
                    algorithmGuid: 'guid-1',
                  ),
                  algorithm: AlgorithmEntry(
                    guid: 'guid-1',
                    name: 'Alg 1',
                    numSpecifications: 0,
                  ),
                  parameterValues: {},
                  parameterStringValues: {},
                  mappings: {},
                ),
            ],
          ),
          mockManager,
        );
      },
      verify: (_) {
        verify(() => mockManager.requestAddAlgorithm(any(), any())).called(3);
      },
    );
  });
}
