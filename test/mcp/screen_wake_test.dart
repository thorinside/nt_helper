import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nt_helper/chat/services/tool_bridge_service.dart';
import 'package:nt_helper/cubit/disting_cubit.dart';
import 'package:nt_helper/db/database.dart';
import 'package:nt_helper/db/daos/metadata_dao.dart';
import 'package:nt_helper/domain/i_disting_midi_manager.dart';
import 'package:nt_helper/domain/disting_nt_sysex.dart' show DisplayMode;
import 'package:nt_helper/mcp/tool_registry.dart';
import 'package:nt_helper/models/firmware_version.dart';
import 'package:nt_helper/services/settings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../test_helpers/remote_wire_harness.dart';

class _Database extends Mock implements AppDatabase {}

class _Metadata extends Mock implements MetadataDao {}

class _Manager extends Mock implements IDistingMidiManager {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() {
    registerFallbackValue(DisplayMode.overview);
    registerFallbackValue(Uint8List(0));
  });
  for (final chat in [false, true]) {
    test(
      '${chat ? 'chat' : 'MCP'} show_screen waits for Wake without changing display mode',
      () async {
        SharedPreferences.setMockInitialValues({});
        await SettingsService().init();
        final database = _Database();
        final metadata = _Metadata();
        when(() => database.metadataDao).thenReturn(metadata);
        when(
          () => metadata.hasCachedAlgorithms(),
        ).thenAnswer((_) async => false);
        final wire = RemoteWireHarness();
        final manager = _Manager();
        final wake = Completer<void>();
        when(() => manager.requestWake()).thenAnswer((_) => wake.future);
        when(
          () => manager.encodeTakeScreenshot(),
        ).thenAnswer((_) async => Uint8List.fromList([1, 2, 3]));
        final cubit = DistingCubit(
          database,
          midiCommand: wire.midi,
          isWindowsOverride: true,
        );
        cubit.emit(
          DistingState.synchronized(
            disting: manager,
            distingVersion: '1.19.0',
            firmwareVersion: FirmwareVersion('1.19.0'),
            presetName: 'Init',
            algorithms: const [],
            slots: const [],
            unitStrings: const [],
          ),
        );
        final registry = ToolRegistry(cubit);
        final bridge = ToolBridgeService(registry);
        Future<String> call(String name, Map<String, dynamic> args) => chat
            ? bridge.executeTool(name, args)
            : registry.executeTool(name, args);
        try {
          final screenSchema = registry.findByName('show_screen')!.inputSchema;
          expect(screenSchema['properties'], isEmpty);
          expect(screenSchema['additionalProperties'], isFalse);
          expect(
            bridge.toolDefinitions
                .singleWhere((t) => t.name == 'show_screen')
                .inputSchema,
            screenSchema,
          );
          final rejected = jsonDecode(
            await call('show_screen', {'display_mode': 'overview'}),
          );
          expect(rejected['success'], isFalse);
          expect(rejected['error'], contains('takes no arguments'));
          verifyNever(() => manager.requestWake());
          verifyNever(() => manager.encodeTakeScreenshot());
          verifyNever(() => manager.requestSetDisplayMode(any()));

          final result = call('show_screen', {});
          await Future<void>.delayed(Duration.zero);
          verify(() => manager.requestWake()).called(1);
          verifyNever(() => manager.encodeTakeScreenshot());
          wake.complete();
          final response = jsonDecode(await result);
          expect(response['type'], 'image/png');
          expect(response['data'], base64Encode([1, 2, 3]));
          verify(() => manager.encodeTakeScreenshot()).called(1);
          verifyNever(() => manager.requestSetDisplayMode(any()));

          // Mode changes are a separate command, and complete only after send.
          final sent = Completer<void>();
          when(
            () => manager.requestSetDisplayMode(DisplayMode.overview),
          ).thenAnswer((_) => sent.future);
          var completed = false;
          final changed = call('set_display_mode', {'mode': 'overview'}).then((
            value,
          ) {
            completed = true;
            return value;
          });
          await Future<void>.delayed(Duration.zero);
          verify(() => manager.requestWake()).called(1);
          verify(
            () => manager.requestSetDisplayMode(DisplayMode.overview),
          ).called(1);
          expect(completed, isFalse);
          sent.complete();
          final change = jsonDecode(await changed);
          expect(change['success'], isTrue);
          expect(change['delivery'], 'transport_send_only');
          expect(change['acknowledged'], isFalse);
          verifyNever(() => manager.encodeTakeScreenshot());
        } finally {
          await registry.dispose();
          await cubit.close();
          await wire.close();
        }
      },
    );
  }
}
