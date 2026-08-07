import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nt_helper/core/platform/platform_interaction_service.dart';
import 'package:nt_helper/cubit/disting_cubit.dart';
import 'package:nt_helper/db/daos/metadata_dao.dart';
import 'package:nt_helper/db/daos/presets_dao.dart';
import 'package:nt_helper/db/database.dart';
import 'package:nt_helper/domain/i_disting_midi_manager.dart';
import 'package:nt_helper/models/firmware_version.dart';
import 'package:nt_helper/services/mcp_server_service.dart';
import 'package:nt_helper/ui/ntx_8cv/ntx_8cv_screen.dart';
import 'package:nt_helper/ui/synchronized_screen.dart';

class _MockDistingCubit extends Mock implements DistingCubit {}

class _MockDistingMidiManager extends Mock implements IDistingMidiManager {}

class _MockAppDatabase extends Mock implements AppDatabase {}

class _MockMetadataDao extends Mock implements MetadataDao {}

class _MockPresetsDao extends Mock implements PresetsDao {}

class _MockPlatformInteractionService extends Mock
    implements PlatformInteractionService {}

void main() {
  group('NTX-8CV entry page', () {
    testWidgets('uses a single connection-controls row on wide screens', (
      tester,
    ) async {
      await _setScreenSize(tester, const Size(1280, 900));
      await tester.pumpWidget(const MaterialApp(home: Ntx8cvScreen()));

      expect(
        find.byKey(const Key('ntx8cv-connection-controls-wide')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('ntx8cv-connection-controls-narrow')),
        findsNothing,
      );
      expect(find.widgetWithText(TextFormField, 'MIDI input'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'MIDI output'), findsOneWidget);
      expect(
        find.widgetWithText(TextFormField, 'SysEx device ID'),
        findsOneWidget,
      );
      expect(find.widgetWithText(FilledButton, 'Connect'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('stacks connection controls on narrow screens', (tester) async {
      await _setScreenSize(tester, const Size(500, 900));
      await tester.pumpWidget(const MaterialApp(home: Ntx8cvScreen()));

      expect(
        find.byKey(const Key('ntx8cv-connection-controls-narrow')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('ntx8cv-connection-controls-wide')),
        findsNothing,
      );
      expect(find.text('Disconnected'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('opens from the main overflow menu through Add-ons', (
      tester,
    ) async {
      final cubit = _MockDistingCubit();
      final midiManager = _MockDistingMidiManager();
      final platformService = _MockPlatformInteractionService();
      final database = _MockAppDatabase();
      final metadataDao = _MockMetadataDao();
      final presetsDao = _MockPresetsDao();
      final state = DistingStateSynchronized(
        disting: midiManager,
        distingVersion: '1.10.0',
        firmwareVersion: FirmwareVersion('1.10.0'),
        presetName: 'Test Preset',
        algorithms: const [],
        slots: const [],
        unitStrings: const [],
        offline: false,
      );

      when(() => cubit.checkpoints).thenReturn([]);
      when(() => cubit.cpuUsageStream).thenAnswer((_) => const Stream.empty());
      when(() => cubit.database).thenReturn(database);
      when(() => database.metadataDao).thenReturn(metadataDao);
      when(() => database.presetsDao).thenReturn(presetsDao);
      when(() => presetsDao.getTemplates()).thenAnswer((_) async => []);
      when(() => cubit.state).thenReturn(state);
      when(() => cubit.stream).thenAnswer((_) => Stream.value(state));
      when(() => platformService.isMobilePlatform()).thenReturn(false);
      McpServerService.initialize(distingCubit: cubit);

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<DistingCubit>.value(
            value: cubit,
            child: SynchronizedScreen(
              distingVersion: '1.10.0',
              firmwareVersion: FirmwareVersion('1.10.0'),
              slots: const [],
              algorithms: const [],
              units: const [],
              presetName: 'Test Preset',
              screenshot: Uint8List(0),
              loading: false,
              platformService: platformService,
            ),
          ),
        ),
      );

      await tester.tap(find.bySemanticsLabel('More options'));
      await tester.pumpAndSettle();
      expect(find.text('Add-ons'), findsOneWidget);

      await tester.tap(find.text('Add-ons'));
      await tester.pumpAndSettle();
      expect(find.text('NTX-8CV'), findsOneWidget);

      await tester.tap(find.text('NTX-8CV'));
      await tester.pumpAndSettle();
      expect(find.byType(Ntx8cvScreen), findsOneWidget);
      expect(find.text('Connection'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
    });
  });
}

Future<void> _setScreenSize(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}
