import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/db/daos/presets_dao.dart';
import 'package:nt_helper/db/database.dart';
import 'package:nt_helper/models/packed_mapping_data.dart';
import 'package:nt_helper/models/template_metadata.dart';
import 'package:nt_helper/services/template_share_service.dart';

FullPresetSlot _slot(int index, String guid, String name) {
  return FullPresetSlot(
    slot: PresetSlotEntry(
      id: index + 1,
      presetId: 1,
      slotIndex: index,
      algorithmGuid: guid,
      customName: 'Slot $index',
    ),
    algorithm: AlgorithmEntry(guid: guid, name: name, numSpecifications: 0),
    parameterValues: {0: index + 10},
    parameterStringValues: {1: 'Value $index'},
    mappings: {2: _mapping()},
    routing: PresetRoutingEntry(
      presetSlotId: index + 1,
      routingInfoJson: [index, index + 1, index + 2],
    ),
  );
}

PackedMappingData _mapping() {
  return PackedMappingData(
    source: 0,
    cvInput: 1,
    isUnipolar: true,
    isGate: false,
    volts: 5,
    delta: 12,
    midiChannel: 1,
    midiMappingType: MidiMappingType.cc,
    midiCC: 74,
    isMidiEnabled: true,
    isMidiSymmetric: false,
    isMidiRelative: false,
    midiMin: 0,
    midiMax: 127,
    i2cCC: 3,
    isI2cEnabled: false,
    isI2cSymmetric: false,
    i2cMin: 0,
    i2cMax: 127,
    perfPageIndex: 0,
    version: 6,
  );
}

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  test('exports and imports a template JSON payload', () async {
    final service = TemplateShareService(db);
    final source = FullPresetDetails(
      preset: PresetEntry(
        id: 1,
        name: 'Shared Template',
        lastModified: DateTime(2026),
        isTemplate: true,
        category: 'Performance',
        templateMetadata: const TemplateMetadata(
          description: 'Shareable patch',
          tags: ['stage', 'poly'],
          author: 'Neal',
        ).toJsonString(),
      ),
      slots: [_slot(0, 'AAAA', 'Alpha'), _slot(1, 'BBBB', 'Beta')],
    );

    final jsonText = service.encodeTemplate(source);
    final decoded = jsonDecode(jsonText) as Map<String, dynamic>;
    expect(decoded['exportType'], TemplateShareService.exportType);
    expect(decoded['exportVersion'], TemplateShareService.exportVersion);

    final importedId = await service.importTemplate(jsonText);
    final imported = (await db.presetsDao.getFullPresetDetails(importedId))!;

    expect(imported.preset.name, 'Shared Template');
    expect(imported.preset.category, 'Performance');
    expect(imported.slots.map((slot) => slot.slot.algorithmGuid), [
      'AAAA',
      'BBBB',
    ]);
    expect(imported.slots.first.parameterValues[0], 10);
    expect(imported.slots.first.parameterStringValues[1], 'Value 0');
    expect(imported.slots.first.mappings[2], _mapping());
    expect(imported.slots.first.routing?.routingInfoJson, [0, 1, 2]);
  });

  test('rejects unrelated JSON payloads', () async {
    await expectLater(
      TemplateShareService(db).importTemplate('{"exportType":"other"}'),
      throwsFormatException,
    );
  });
}
