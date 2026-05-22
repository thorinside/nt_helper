import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/db/daos/presets_dao.dart';
import 'package:nt_helper/db/database.dart';
import 'package:nt_helper/models/template_metadata.dart';
import 'package:nt_helper/ui/template_manager/template_manager_screen.dart';

FullPresetSlot _slot(int index, String guid, String name) {
  return FullPresetSlot(
    slot: PresetSlotEntry(
      id: -1,
      presetId: -1,
      slotIndex: index,
      algorithmGuid: guid,
    ),
    algorithm: AlgorithmEntry(guid: guid, name: name, numSpecifications: 0),
    parameterValues: {0: 10},
    parameterStringValues: {},
    mappings: {},
  );
}

Future<void> _seedAlgorithm(AppDatabase db, String guid, String name) async {
  await db.metadataDao.upsertAlgorithms([
    AlgorithmEntry(guid: guid, name: name, numSpecifications: 0),
  ]);
}

Future<void> _saveTemplate(
  AppDatabase db,
  String name, {
  String? category,
  required TemplateMetadata metadata,
  required List<FullPresetSlot> slots,
}) async {
  await db.presetsDao.saveFullPreset(
    FullPresetDetails(
      preset: PresetEntry(
        id: -1,
        name: name,
        lastModified: DateTime(2026),
        isTemplate: true,
        category: category,
        templateMetadata: metadata.toJsonString(),
      ),
      slots: slots,
    ),
    isTemplate: true,
  );
}

void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    await _seedAlgorithm(db, 'dely', 'Delay');
    await _seedAlgorithm(db, 'rvb', 'Reverb');
    await _saveTemplate(
      db,
      'Space Kit',
      category: 'Ambience',
      metadata: const TemplateMetadata(tags: ['wide'], author: 'Neal'),
      slots: [_slot(0, 'dely', 'Delay'), _slot(1, 'rvb', 'Reverb')],
    );
    await _saveTemplate(
      db,
      'Utility Kit',
      metadata: const TemplateMetadata(tags: ['utility']),
      slots: [_slot(0, 'dely', 'Delay')],
    );
  });

  tearDown(() async {
    await db.close();
  });

  testWidgets('renders templates grouped by category and filters slots', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: TemplateManagerScreen(database: db)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Ambience'), findsOneWidget);
    expect(find.text('Uncategorized'), findsOneWidget);
    expect(find.text('Space Kit'), findsWidgets);
    expect(find.text('wide'), findsWidgets);

    await tester.tap(find.text('Space Kit').first);
    await tester.pumpAndSettle();
    expect(find.text('Neal'), findsOneWidget);
    expect(find.text('Delay'), findsOneWidget);
    expect(find.text('Reverb'), findsOneWidget);

    await tester.enterText(find.byType(TextField).last, 'verb');
    await tester.pumpAndSettle();
    expect(find.text('Delay'), findsNothing);
    expect(find.text('Reverb'), findsOneWidget);
  });

  testWidgets('opens apply dialog for selected slots', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: TemplateManagerScreen(database: db)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Delay').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Apply selected'));
    await tester.pumpAndSettle();

    expect(find.text('Apply template slots'), findsOneWidget);
    expect(find.textContaining('1 selected from Space Kit'), findsOneWidget);
  });
}
