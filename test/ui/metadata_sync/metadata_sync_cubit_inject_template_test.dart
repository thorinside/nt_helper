import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nt_helper/db/daos/metadata_dao.dart';
import 'package:nt_helper/db/daos/presets_dao.dart';
import 'package:nt_helper/db/database.dart';
import 'package:nt_helper/domain/disting_nt_sysex.dart';
import 'package:nt_helper/domain/i_disting_midi_manager.dart';
import 'package:nt_helper/models/packed_mapping_data.dart';
import 'package:nt_helper/ui/metadata_sync/metadata_sync_cubit.dart';

class MockDistingMidiManager extends Mock implements IDistingMidiManager {}

class MockAppDatabase extends Mock implements AppDatabase {}

class MockMetadataDao extends Mock implements MetadataDao {}

class MockPresetsDao extends Mock implements PresetsDao {}

class FakeAlgorithmInfo extends Fake implements AlgorithmInfo {}

class FakePackedMappingData extends Fake implements PackedMappingData {}

void main() {
  late MetadataSyncCubit cubit;
  late MockDistingMidiManager mockMidiManager;
  late MockAppDatabase mockDatabase;
  late MockMetadataDao mockMetadataDao;
  late MockPresetsDao mockPresetsDao;

  setUpAll(() {
    registerFallbackValue(FakeAlgorithmInfo());
    registerFallbackValue(FakePackedMappingData());
  });

  setUp(() {
    mockMidiManager = MockDistingMidiManager();
    mockDatabase = MockAppDatabase();
    mockMetadataDao = MockMetadataDao();
    mockPresetsDao = MockPresetsDao();

    when(() => mockDatabase.metadataDao).thenReturn(mockMetadataDao);
    when(() => mockDatabase.presetsDao).thenReturn(mockPresetsDao);

    cubit = MetadataSyncCubit(mockDatabase);
  });

  tearDown(() {
    cubit.close();
  });

  group('MetadataSyncCubit - injectTemplateToDevice', () {
    test('initial state is idle', () {
      expect(cubit.state, const MetadataSyncState.idle());
    });

    blocTest<MetadataSyncCubit, MetadataSyncState>(
      'throws exception when slot limit would be exceeded (39 + 2 > 40)',
      build: () {
        when(
          () => mockMidiManager.requestNumAlgorithmsInPreset(),
        ).thenAnswer((_) async => 39);
        when(() => mockMetadataDao.getFullAlgorithmDetails(any())).thenAnswer(
          (_) async => FullAlgorithmDetails(
            algorithm: AlgorithmEntry(
              guid: 'test-guid',
              name: 'Test Algorithm',
              numSpecifications: 1,
            ),
            specifications: [],
            parameters: [],
            parameterPages: [],
            enums: {},
          ),
        );

        return cubit;
      },
      act: (cubit) async {
        final template = FullPresetDetails(
          preset: PresetEntry(
            id: 1,
            name: 'Test Template',
            lastModified: DateTime.now(),
            isTemplate: true,
          ),
          slots: [
            FullPresetSlot(
              slot: PresetSlotEntry(
                id: 1,
                presetId: 1,
                slotIndex: 0,
                algorithmGuid: 'test-guid-1',
              ),
              algorithm: AlgorithmEntry(
                guid: 'test-guid-1',
                name: 'Test Algorithm 1',
                numSpecifications: 1,
              ),
              parameterValues: {},
              parameterStringValues: {},
              mappings: {},
            ),
            FullPresetSlot(
              slot: PresetSlotEntry(
                id: 2,
                presetId: 1,
                slotIndex: 1,
                algorithmGuid: 'test-guid-2',
              ),
              algorithm: AlgorithmEntry(
                guid: 'test-guid-2',
                name: 'Test Algorithm 2',
                numSpecifications: 1,
              ),
              parameterValues: {},
              parameterStringValues: {},
              mappings: {},
            ),
          ],
        );

        await cubit.injectTemplateToDevice(template, mockMidiManager);
      },
      expect: () => [
        const MetadataSyncState.injectingTemplate(applied: 0, total: 2),
        isA<PresetLoadFailure>().having(
          (state) => state.error,
          'error message',
          contains('Would exceed 40 slot limit'),
        ),
      ],
    );

    blocTest<MetadataSyncCubit, MetadataSyncState>(
      'does not call requestNewPreset during injection',
      build: () {
        when(
          () => mockMidiManager.requestNumAlgorithmsInPreset(),
        ).thenAnswer((_) async => 5);
        when(
          () => mockMidiManager.requestAddAlgorithm(any(), any()),
        ).thenAnswer((_) async => {});
        when(
          () => mockMidiManager.setParameterValue(any(), any(), any()),
        ).thenAnswer((_) async => {});
        when(
          () => mockMidiManager.requestSetMapping(any(), any(), any()),
        ).thenAnswer((_) async => {});
        when(
          () => mockMidiManager.requestSendSlotName(any(), any()),
        ).thenAnswer((_) async => {});
        when(() => mockMetadataDao.getFullAlgorithmDetails(any())).thenAnswer(
          (_) async => FullAlgorithmDetails(
            algorithm: AlgorithmEntry(
              guid: 'test-guid',
              name: 'Test Algorithm',
              numSpecifications: 1,
            ),
            specifications: [
              SpecificationEntry(
                algorithmGuid: 'test-guid',
                specIndex: 0,
                name: 'param1',
                minValue: 0,
                maxValue: 100,
                defaultValue: 50,
                type: 0,
              ),
            ],
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
        ).thenAnswer((_) async => {});
        when(() => mockPresetsDao.getAllPresets()).thenAnswer((_) async => []);

        return cubit;
      },
      act: (cubit) async {
        final template = FullPresetDetails(
          preset: PresetEntry(
            id: 1,
            name: 'Test Template',
            lastModified: DateTime.now(),
            isTemplate: true,
          ),
          slots: [
            FullPresetSlot(
              slot: PresetSlotEntry(
                id: 1,
                presetId: 1,
                slotIndex: 0,
                algorithmGuid: 'test-guid',
              ),
              algorithm: AlgorithmEntry(
                guid: 'test-guid',
                name: 'Test Algorithm',
                numSpecifications: 1,
              ),
              parameterValues: {},
              parameterStringValues: {},
              mappings: {},
            ),
          ],
        );

        await cubit.injectTemplateToDevice(template, mockMidiManager);
      },
      verify: (_) {
        verifyNever(() => mockMidiManager.requestNewPreset());
      },
    );

    blocTest<MetadataSyncCubit, MetadataSyncState>(
      'does not call requestSavePreset during injection',
      build: () {
        when(
          () => mockMidiManager.requestNumAlgorithmsInPreset(),
        ).thenAnswer((_) async => 5);
        when(
          () => mockMidiManager.requestAddAlgorithm(any(), any()),
        ).thenAnswer((_) async => {});
        when(
          () => mockMidiManager.setParameterValue(any(), any(), any()),
        ).thenAnswer((_) async => {});
        when(
          () => mockMidiManager.requestSetMapping(any(), any(), any()),
        ).thenAnswer((_) async => {});
        when(
          () => mockMidiManager.requestSendSlotName(any(), any()),
        ).thenAnswer((_) async => {});
        when(() => mockMetadataDao.getFullAlgorithmDetails(any())).thenAnswer(
          (_) async => FullAlgorithmDetails(
            algorithm: AlgorithmEntry(
              guid: 'test-guid',
              name: 'Test Algorithm',
              numSpecifications: 1,
            ),
            specifications: [
              SpecificationEntry(
                algorithmGuid: 'test-guid',
                specIndex: 0,
                name: 'param1',
                minValue: 0,
                maxValue: 100,
                defaultValue: 50,
                type: 0,
              ),
            ],
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
        ).thenAnswer((_) async => {});
        when(() => mockPresetsDao.getAllPresets()).thenAnswer((_) async => []);

        return cubit;
      },
      act: (cubit) async {
        final template = FullPresetDetails(
          preset: PresetEntry(
            id: 1,
            name: 'Test Template',
            lastModified: DateTime.now(),
            isTemplate: true,
          ),
          slots: [
            FullPresetSlot(
              slot: PresetSlotEntry(
                id: 1,
                presetId: 1,
                slotIndex: 0,
                algorithmGuid: 'test-guid',
              ),
              algorithm: AlgorithmEntry(
                guid: 'test-guid',
                name: 'Test Algorithm',
                numSpecifications: 1,
              ),
              parameterValues: {},
              parameterStringValues: {},
              mappings: {},
            ),
          ],
        );

        await cubit.injectTemplateToDevice(template, mockMidiManager);
      },
      verify: (_) {
        verifyNever(() => mockMidiManager.requestSavePreset());
      },
    );

    blocTest<MetadataSyncCubit, MetadataSyncState>(
      'calls requestAddAlgorithm for each template slot',
      build: () {
        when(
          () => mockMidiManager.requestNumAlgorithmsInPreset(),
        ).thenAnswer((_) async => 5);
        when(
          () => mockMidiManager.requestAddAlgorithm(any(), any()),
        ).thenAnswer((_) async => {});
        when(
          () => mockMidiManager.setParameterValue(any(), any(), any()),
        ).thenAnswer((_) async => {});
        when(
          () => mockMidiManager.requestSetMapping(any(), any(), any()),
        ).thenAnswer((_) async => {});
        when(
          () => mockMidiManager.requestSendSlotName(any(), any()),
        ).thenAnswer((_) async => {});
        when(() => mockMetadataDao.getFullAlgorithmDetails(any())).thenAnswer(
          (_) async => FullAlgorithmDetails(
            algorithm: AlgorithmEntry(
              guid: 'test-guid',
              name: 'Test Algorithm',
              numSpecifications: 1,
            ),
            specifications: [
              SpecificationEntry(
                algorithmGuid: 'test-guid',
                specIndex: 0,
                name: 'param1',
                minValue: 0,
                maxValue: 100,
                defaultValue: 50,
                type: 0,
              ),
            ],
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
        ).thenAnswer((_) async => {});
        when(() => mockPresetsDao.getAllPresets()).thenAnswer((_) async => []);

        return cubit;
      },
      act: (cubit) async {
        final template = FullPresetDetails(
          preset: PresetEntry(
            id: 1,
            name: 'Test Template',
            lastModified: DateTime.now(),
            isTemplate: true,
          ),
          slots: [
            FullPresetSlot(
              slot: PresetSlotEntry(
                id: 1,
                presetId: 1,
                slotIndex: 0,
                algorithmGuid: 'test-guid-1',
              ),
              algorithm: AlgorithmEntry(
                guid: 'test-guid-1',
                name: 'Algorithm 1',
                numSpecifications: 1,
              ),
              parameterValues: {},
              parameterStringValues: {},
              mappings: {},
            ),
            FullPresetSlot(
              slot: PresetSlotEntry(
                id: 2,
                presetId: 1,
                slotIndex: 1,
                algorithmGuid: 'test-guid-2',
              ),
              algorithm: AlgorithmEntry(
                guid: 'test-guid-2',
                name: 'Algorithm 2',
                numSpecifications: 1,
              ),
              parameterValues: {},
              parameterStringValues: {},
              mappings: {},
            ),
          ],
        );

        await cubit.injectTemplateToDevice(template, mockMidiManager);
      },
      verify: (_) {
        verify(
          () => mockMidiManager.requestAddAlgorithm(any(), any()),
        ).called(2);
      },
    );

    test('applies the template slot specification values', () async {
      when(
        () => mockMidiManager.requestNumAlgorithmsInPreset(),
      ).thenAnswer((_) async => 0);
      when(
        () => mockMidiManager.requestAddAlgorithm(any(), any()),
      ).thenAnswer((_) async {});
      when(
        () => mockMidiManager.requestSendSlotName(any(), any()),
      ).thenAnswer((_) async {});
      when(() => mockMetadataDao.getFullAlgorithmDetails('quan')).thenAnswer(
        (_) async => FullAlgorithmDetails(
          algorithm: AlgorithmEntry(
            guid: 'quan',
            name: 'Quantizer',
            numSpecifications: 1,
          ),
          specifications: [
            SpecificationEntry(
              algorithmGuid: 'quan',
              specIndex: 0,
              name: 'Channels',
              minValue: 1,
              maxValue: 12,
              defaultValue: 1,
              type: 0,
            ),
          ],
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
      ).thenAnswer((_) async => {});
      when(() => mockPresetsDao.getAllPresets()).thenAnswer((_) async => []);
      final template = FullPresetDetails(
        preset: PresetEntry(
          id: 1,
          name: 'Four Channel Quantizer',
          lastModified: DateTime.now(),
          isTemplate: true,
        ),
        slots: [
          FullPresetSlot(
            slot: PresetSlotEntry(
              id: 1,
              presetId: 1,
              slotIndex: 0,
              algorithmGuid: 'quan',
            ),
            algorithm: AlgorithmEntry(
              guid: 'quan',
              name: 'Quantizer',
              numSpecifications: 1,
            ),
            specificationValues: const [4],
            parameterValues: const {},
            parameterStringValues: const {},
            mappings: const {},
          ),
        ],
      );

      await cubit.injectTemplateToDevice(template, mockMidiManager);

      verify(
        () => mockMidiManager.requestAddAlgorithm(any(), const [4]),
      ).called(1);
    });

    test('rejects invalid specification values before adding a slot', () async {
      when(() => mockMetadataDao.getFullAlgorithmDetails('quan')).thenAnswer(
        (_) async => FullAlgorithmDetails(
          algorithm: AlgorithmEntry(
            guid: 'quan',
            name: 'Quantizer',
            numSpecifications: 1,
          ),
          specifications: [
            SpecificationEntry(
              algorithmGuid: 'quan',
              specIndex: 0,
              name: 'Channels',
              minValue: 1,
              maxValue: 12,
              defaultValue: 1,
              type: 0,
            ),
          ],
          parameters: [],
          parameterPages: [],
          enums: {},
        ),
      );

      final template = FullPresetDetails(
        preset: PresetEntry(
          id: 1,
          name: 'Invalid Quantizer',
          lastModified: DateTime.now(),
          isTemplate: true,
        ),
        slots: [
          FullPresetSlot(
            slot: PresetSlotEntry(
              id: 1,
              presetId: 1,
              slotIndex: 0,
              algorithmGuid: 'quan',
            ),
            algorithm: AlgorithmEntry(
              guid: 'quan',
              name: 'Quantizer',
              numSpecifications: 1,
            ),
            specificationValues: const [13],
            parameterValues: const {},
            parameterStringValues: const {},
            mappings: const {},
          ),
        ],
      );

      await cubit.injectTemplateToDevice(template, mockMidiManager);

      verifyNever(() => mockMidiManager.requestAddAlgorithm(any(), any()));
      expect(cubit.state, isA<PresetLoadFailure>());
    });

    blocTest<MetadataSyncCubit, MetadataSyncState>(
      'sets parameter values with correct slot offset (current slot count + template slot index)',
      build: () {
        when(
          () => mockMidiManager.requestNumAlgorithmsInPreset(),
        ).thenAnswer((_) async => 10);
        when(
          () => mockMidiManager.requestAddAlgorithm(any(), any()),
        ).thenAnswer((_) async => {});
        when(
          () => mockMidiManager.setParameterValue(any(), any(), any()),
        ).thenAnswer((_) async => {});
        when(
          () => mockMidiManager.requestSetMapping(any(), any(), any()),
        ).thenAnswer((_) async => {});
        when(
          () => mockMidiManager.requestSendSlotName(any(), any()),
        ).thenAnswer((_) async => {});
        when(() => mockMetadataDao.getFullAlgorithmDetails(any())).thenAnswer(
          (_) async => FullAlgorithmDetails(
            algorithm: AlgorithmEntry(
              guid: 'test-guid',
              name: 'Test Algorithm',
              numSpecifications: 1,
            ),
            specifications: [
              SpecificationEntry(
                algorithmGuid: 'test-guid',
                specIndex: 0,
                name: 'param1',
                minValue: 0,
                maxValue: 100,
                defaultValue: 50,
                type: 0,
              ),
            ],
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
        ).thenAnswer((_) async => {});
        when(() => mockPresetsDao.getAllPresets()).thenAnswer((_) async => []);

        return cubit;
      },
      act: (cubit) async {
        final template = FullPresetDetails(
          preset: PresetEntry(
            id: 1,
            name: 'Test Template',
            lastModified: DateTime.now(),
            isTemplate: true,
          ),
          slots: [
            FullPresetSlot(
              slot: PresetSlotEntry(
                id: 1,
                presetId: 1,
                slotIndex: 0,
                algorithmGuid: 'test-guid',
              ),
              algorithm: AlgorithmEntry(
                guid: 'test-guid',
                name: 'Test Algorithm',
                numSpecifications: 1,
              ),
              parameterValues: {0: 75, 1: 50},
              parameterStringValues: {},
              mappings: {},
            ),
          ],
        );

        await cubit.injectTemplateToDevice(template, mockMidiManager);
      },
      verify: (_) {
        // Should set parameters at slot index 10 (current 10 + template slot 0)
        verify(() => mockMidiManager.setParameterValue(10, 0, 75)).called(1);
        verify(() => mockMidiManager.setParameterValue(10, 1, 50)).called(1);
      },
    );

    blocTest<MetadataSyncCubit, MetadataSyncState>(
      'throws exception when template is empty',
      build: () => cubit,
      act: (cubit) async {
        final emptyTemplate = FullPresetDetails(
          preset: PresetEntry(
            id: 1,
            name: 'Empty Template',
            lastModified: DateTime.now(),
            isTemplate: true,
          ),
          slots: [], // Empty slots
        );

        await cubit.injectTemplateToDevice(emptyTemplate, mockMidiManager);
      },
      expect: () => [
        const MetadataSyncState.injectingTemplate(applied: 0, total: 0),
        isA<PresetLoadFailure>().having(
          (state) => state.error,
          'error message',
          contains('Cannot inject empty template'),
        ),
      ],
    );

    blocTest<MetadataSyncCubit, MetadataSyncState>(
      'throws exception when template algorithm metadata is missing',
      build: () {
        when(
          () => mockMidiManager.requestNumAlgorithmsInPreset(),
        ).thenAnswer((_) async => 5);
        when(
          () => mockMetadataDao.getFullAlgorithmDetails(any()),
        ).thenAnswer((_) async => null); // Simulate missing metadata

        return cubit;
      },
      act: (cubit) async {
        final template = FullPresetDetails(
          preset: PresetEntry(
            id: 1,
            name: 'Test Template',
            lastModified: DateTime.now(),
            isTemplate: true,
          ),
          slots: [
            FullPresetSlot(
              slot: PresetSlotEntry(
                id: 1,
                presetId: 1,
                slotIndex: 0,
                algorithmGuid: 'missing-guid',
              ),
              algorithm: AlgorithmEntry(
                guid: 'missing-guid',
                name: 'Missing Algorithm',
                numSpecifications: 1,
              ),
              parameterValues: {},
              parameterStringValues: {},
              mappings: {},
            ),
          ],
        );

        await cubit.injectTemplateToDevice(template, mockMidiManager);
      },
      expect: () => [
        const MetadataSyncState.injectingTemplate(applied: 0, total: 1),
        isA<PresetLoadFailure>().having(
          (state) => state.error,
          'error message',
          contains('Template missing algorithm metadata'),
        ),
      ],
    );
  });
}
