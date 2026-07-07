import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nt_helper/cubit/disting_cubit.dart';
import 'package:nt_helper/db/daos/presets_dao.dart';
import 'package:nt_helper/db/database.dart';
import 'package:nt_helper/domain/disting_nt_sysex.dart';
import 'package:nt_helper/domain/i_disting_midi_manager.dart';
import 'package:nt_helper/mcp/tool_registry.dart';
import 'package:nt_helper/mcp/tools/disting_tools.dart';
import 'package:nt_helper/services/disting_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockDistingController extends Mock implements DistingController {}

class MockDistingCubit extends Mock implements DistingCubit {}

class MockDistingMidiManager extends Mock implements IDistingMidiManager {}

class FakeAlgorithmInfo extends Fake implements AlgorithmInfo {}

FullPresetSlot _slot({required int slotIndex, required String guid}) {
  return FullPresetSlot(
    slot: PresetSlotEntry(
      id: -1,
      presetId: -1,
      slotIndex: slotIndex,
      algorithmGuid: guid,
    ),
    algorithm: AlgorithmEntry(
      guid: guid,
      name: 'Alg $guid',
      numSpecifications: 0,
    ),
    parameterValues: {slotIndex: slotIndex * 10},
    parameterStringValues: {},
    mappings: {},
  );
}

Future<void> _seedAlgorithm(AppDatabase db, String guid) async {
  await db.metadataDao.upsertAlgorithms([
    AlgorithmEntry(guid: guid, name: 'Alg $guid', numSpecifications: 0),
  ]);
}

Future<int> _savePreset(
  AppDatabase db,
  String name, {
  required bool isTemplate,
  required List<FullPresetSlot> slots,
}) {
  return db.presetsDao.saveFullPreset(
    FullPresetDetails(
      preset: PresetEntry(
        id: -1,
        name: name,
        lastModified: DateTime.now(),
        isTemplate: isTemplate,
      ),
      slots: slots,
    ),
    isTemplate: isTemplate,
  );
}

void main() {
  late AppDatabase db;
  late MockDistingCubit cubit;
  late DistingTools tools;

  setUpAll(() {
    registerFallbackValue(FakeAlgorithmInfo());
    registerFallbackValue(<int>[]);
  });

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase.forTesting(NativeDatabase.memory());
    cubit = MockDistingCubit();
    when(() => cubit.database).thenReturn(db);
    when(() => cubit.state).thenReturn(const DistingState.initial());
    tools = DistingTools(MockDistingController(), cubit);
  });

  tearDown(() async {
    await db.close();
  });

  group('apply_template_to_preset tool', () {
    test('applies selected template slots to a named target preset', () async {
      await _seedAlgorithm(db, 'AAAA');
      await _seedAlgorithm(db, 'BBBB');
      await _savePreset(
        db,
        'Starter',
        isTemplate: true,
        slots: [
          _slot(slotIndex: 0, guid: 'AAAA'),
          _slot(slotIndex: 1, guid: 'BBBB'),
        ],
      );
      final targetId = await _savePreset(
        db,
        'Target',
        isTemplate: false,
        slots: const [],
      );

      final response = await tools.applyTemplateToPreset({
        'template_name': 'Starter',
        'target': 'preset',
        'target_preset_name': 'Target',
        'slot_indices': [1, 1],
        'insertion_offset': 0,
      });
      final json = jsonDecode(response) as Map<String, dynamic>;

      expect(json['success'], isTrue);
      expect(json['target'], 'preset');
      expect(json['target_preset_id'], targetId);
      expect(json['applied_slot_count'], 2);
      expect(json['inserted_slot_indices'], [0, 1]);
      expect(json['skipped_template_slot_indices'], isEmpty);

      final target = await db.presetsDao.getFullPresetDetails(targetId);
      expect(target!.slots.map((slot) => slot.slot.algorithmGuid), [
        'BBBB',
        'BBBB',
      ]);
    });

    test('returns structured space errors from the DAO', () async {
      await _seedAlgorithm(db, 'AAAA');
      final templateId = await _savePreset(
        db,
        'Too Big',
        isTemplate: true,
        slots: [
          _slot(slotIndex: 0, guid: 'AAAA'),
          _slot(slotIndex: 1, guid: 'AAAA'),
        ],
      );
      final targetId = await _savePreset(
        db,
        'Crowded',
        isTemplate: false,
        slots: [for (var i = 0; i < 39; i++) _slot(slotIndex: i, guid: 'AAAA')],
      );

      final response = await tools.applyTemplateToPreset({
        'template_id': templateId,
        'target': 'preset',
        'target_preset_id': targetId,
      });
      final json = jsonDecode(response) as Map<String, dynamic>;

      expect(json['success'], isFalse);
      expect(json['error'], 'space');
      expect(json['current'], 39);
      expect(json['applied'], 2);
      expect(json['limit'], 40);
    });

    test('registry exposes apply_template_to_preset', () {
      final registry = ToolRegistry(cubit);
      final entry = registry.findByName('apply_template_to_preset');

      expect(entry, isNotNull);
      expect(entry!.inputSchema['properties'], contains('template_name'));
      expect(entry.inputSchema['properties'], contains('slot_indices'));
      expect(entry.timeout, const Duration(seconds: 120));
    });

    test(
      'device target returns failure when device apply emits failure',
      () async {
        final manager = MockDistingMidiManager();
        when(() => cubit.requireDisting()).thenReturn(manager);
        when(
          () => manager.requestNumAlgorithmsInPreset(),
        ).thenAnswer((_) async => 0);
        when(
          () => manager.requestAddAlgorithm(
            any<AlgorithmInfo>(),
            any<List<int>>(),
          ),
        ).thenAnswer((_) async => throw Exception('MIDI send failed'));

        await _seedAlgorithm(db, 'AAAA');
        final templateId = await _savePreset(
          db,
          'Starter',
          isTemplate: true,
          slots: [_slot(slotIndex: 0, guid: 'AAAA')],
        );

        final response = await tools.applyTemplateToPreset({
          'template_id': templateId,
          'target': 'device',
        });
        final json = jsonDecode(response) as Map<String, dynamic>;

        expect(json['success'], isFalse);
        expect(json['error'], 'partial_apply');
        expect(json['applied_slot_count'], 0);
        expect(json['message'], contains('Connection lost during injection'));
      },
    );
  });
}
