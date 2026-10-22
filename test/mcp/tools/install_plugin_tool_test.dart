import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nt_helper/chat/models/allowed_file_root.dart';
import 'package:nt_helper/cubit/disting_cubit.dart';
import 'package:nt_helper/db/daos/metadata_dao.dart';
import 'package:nt_helper/db/daos/plugin_installations_dao.dart';
import 'package:nt_helper/db/database.dart';
import 'package:nt_helper/domain/disting_nt_sysex.dart';
import 'package:nt_helper/domain/i_disting_midi_manager.dart';
import 'package:nt_helper/mcp/tool_registry.dart';
import 'package:nt_helper/mcp/tools/plugin_tools.dart';
import 'package:nt_helper/models/firmware_version.dart';
import 'package:nt_helper/models/sd_card_file_system.dart';
import 'package:nt_helper/services/settings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../test_helpers/mock_midi_command.dart';

class _MockAppDatabase extends Mock implements AppDatabase {}

class _MockMetadataDao extends Mock implements MetadataDao {}

class _MockPluginInstallationsDao extends Mock
    implements PluginInstallationsDao {}

class _MockDistingMidiManager extends Mock implements IDistingMidiManager {}

/// Fixture whose ELF symbols declare the GUIDs `ATds` and `ATdm`.
const _fixture = 'test/fixtures/plugins/directionalSequencer.o';
const _pluginsDir = '/programs/plug-ins';
const _luaDir = '/programs/lua';

/// A stand-in SD card plus algorithm table behind the mocked MIDI manager.
class _FakeDevice {
  /// Uploaded file contents keyed by absolute SD path.
  final files = <String, List<int>>{};

  /// Every chunk size sent, to check the 512-byte SysEx limit.
  final chunkSizes = <int>[];

  /// Algorithms the device reports once [algorithmsVisibleAfterReads]
  /// algorithm-count reads have happened since the rescan.
  List<AlgorithmInfo> algorithms = [];
  int algorithmsVisibleAfterReads = 1;
  int rescans = 0;
  int countReadsSinceRescan = 0;
  final loadedGuids = <String>{};
  bool failUploads = false;

  List<AlgorithmInfo> get visible =>
      rescans > 0 && countReadsSinceRescan >= algorithmsVisibleAfterReads
      ? algorithms
      : const [];

  AlgorithmInfo withLoadState(AlgorithmInfo a) => AlgorithmInfo(
    algorithmIndex: a.algorithmIndex,
    guid: a.guid,
    name: a.name,
    specifications: a.specifications,
    isPlugin: a.isPlugin,
    isLoaded: a.isLoaded || loadedGuids.contains(a.guid),
    filename: a.filename,
  );

  void wire(_MockDistingMidiManager m) {
    when(() => m.requestWake()).thenAnswer((_) async {});
    when(() => m.requestDirectoryListing(any())).thenAnswer((call) async {
      final dir = call.positionalArguments[0] as String;
      return DirectoryListing(
        entries: [
          for (final entry in files.entries)
            if (entry.key.substring(0, entry.key.lastIndexOf('/')) == dir)
              DirectoryEntry(
                name: entry.key.split('/').last,
                attributes: 0x20,
                date: 0,
                time: 0,
                size: entry.value.length,
              ),
        ],
      );
    });
    when(
      () => m.requestDirectoryCreate(any()),
    ).thenAnswer((_) async => SdCardStatus(success: true, message: 'ok'));
    when(
      () => m.requestFileUploadChunk(
        any(),
        any(),
        any(),
        createAlways: any(named: 'createAlways'),
      ),
    ).thenAnswer((call) async {
      if (failUploads) return SdCardStatus(success: false, message: 'full');
      final target = call.positionalArguments[0] as String;
      final chunk = call.positionalArguments[1] as Uint8List;
      final position = call.positionalArguments[2] as int;
      if (call.namedArguments[#createAlways] == true) files[target] = [];
      expect(position, files[target]!.length);
      chunkSizes.add(chunk.length);
      files[target]!.addAll(chunk);
      return SdCardStatus(success: true, message: 'ok');
    });
    when(() => m.requestRescanPlugins()).thenAnswer((_) async {
      rescans++;
      countReadsSinceRescan = 0;
    });
    when(() => m.requestNumberOfAlgorithms()).thenAnswer((_) async {
      if (rescans > 0) countReadsSinceRescan++;
      return visible.length;
    });
    when(() => m.requestAlgorithmInfo(any())).thenAnswer((call) async {
      final index = call.positionalArguments[0] as int;
      final match = visible.where((a) => a.algorithmIndex == index);
      return match.isEmpty ? null : withLoadState(match.first);
    });
    when(() => m.requestLoadPlugin(any())).thenAnswer((call) async {
      loadedGuids.add(call.positionalArguments[0] as String);
    });
    when(() => m.requestNewPreset()).thenAnswer((_) async {});
    when(() => m.requestLoadPreset(any(), any())).thenAnswer((_) async {});
    when(() => m.requestNumAlgorithmsInPreset()).thenAnswer((_) async => 0);
    when(() => m.requestPresetName()).thenAnswer((_) async => 'Test');
  }
}

AlgorithmInfo _plugin(int index, String guid, String file) => AlgorithmInfo(
  algorithmIndex: index,
  guid: guid,
  name: 'Plugin $guid',
  specifications: const [],
  isPlugin: true,
  isLoaded: false,
  filename: file,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory allowed;
  late Directory outside;
  late SettingsService settings;
  late _MockAppDatabase database;
  late _MockMetadataDao metadataDao;
  late _MockDistingMidiManager manager;
  late _FakeDevice device;
  late DistingCubit cubit;
  late PluginTools tools;
  late Uint8List fixtureBytes;

  setUpAll(() {
    registerFallbackValue(Uint8List(0));
    registerFallbackValue(<AlgorithmInfo>[]);
    fixtureBytes = File(_fixture).readAsBytesSync();
  });

  DistingStateSynchronized synchronized({
    bool offline = false,
    bool demo = false,
    String version = '1.12.0',
    List<AlgorithmInfo> algorithms = const [],
    List<Slot> slots = const [],
  }) => DistingStateSynchronized(
    disting: manager,
    distingVersion: version,
    firmwareVersion: FirmwareVersion(version),
    presetName: 'Test',
    algorithms: algorithms,
    slots: slots,
    unitStrings: const [],
    inputDevice: null,
    outputDevice: null,
    loading: false,
    offline: offline,
    screenshot: null,
    demo: demo,
    videoStream: null,
  );

  Future<Map<String, dynamic>> install(Map<String, dynamic> args) async =>
      jsonDecode(await tools.installPlugin(args)) as Map<String, dynamic>;

  String inAllowed(String name, List<int> bytes) {
    final file = File('${allowed.path}/$name')..writeAsBytesSync(bytes);
    return file.path;
  }

  void expectNothingUploaded() {
    verifyNever(
      () => manager.requestFileUploadChunk(
        any(),
        any(),
        any(),
        createAlways: any(named: 'createAlways'),
      ),
    );
    verifyNever(() => manager.requestRescanPlugins());
  }

  setUp(() async {
    allowed = await Directory.systemTemp.createTemp('nt_install_allowed_');
    outside = await Directory.systemTemp.createTemp('nt_install_outside_');
    SharedPreferences.setMockInitialValues({});
    settings = SettingsService();
    await settings.init();
    await settings.setAllowedFileRoots([
      AllowedFileRoot(
        id: 'builds',
        label: 'Builds',
        path: allowed.path,
        acl: const {
          FileRootActor.mcp: {FileRootPermission.read},
        },
      ),
    ]);

    database = _MockAppDatabase();
    metadataDao = _MockMetadataDao();
    final installations = _MockPluginInstallationsDao();
    when(() => database.metadataDao).thenReturn(metadataDao);
    when(() => database.pluginInstallationsDao).thenReturn(installations);
    when(
      () => metadataDao.hasCachedAlgorithms(),
    ).thenAnswer((_) async => false);
    when(
      () => metadataDao.invalidateAlgorithmInfoCache(),
    ).thenAnswer((_) async {});
    when(
      () => metadataDao.getAlgorithmInfoCache(
        any(),
        cacheFreshnessDays: any(named: 'cacheFreshnessDays'),
      ),
    ).thenAnswer((_) async => null);
    when(
      () => metadataDao.saveAlgorithmInfoCache(any(), any()),
    ).thenAnswer((_) async {});
    when(
      () => installations.recordPluginByPath(
        installationPath: any(named: 'installationPath'),
        pluginName: any(named: 'pluginName'),
        pluginType: any(named: 'pluginType'),
        totalBytes: any(named: 'totalBytes'),
        pluginId: any(named: 'pluginId'),
        pluginVersion: any(named: 'pluginVersion'),
      ),
    ).thenAnswer((_) async => 1);

    manager = _MockDistingMidiManager();
    device = _FakeDevice()..wire(manager);
    cubit = DistingCubit(database, midiCommand: MockMidiCommand());
    cubit.emit(synchronized());
    tools = PluginTools(
      cubit,
      actor: FileRootActor.mcp,
      maxRescanAttempts: 3,
      rescanPollInterval: Duration.zero,
    );
  });

  tearDown(() async {
    await cubit.close();
    for (final dir in [allowed, outside]) {
      if (await dir.exists()) await dir.delete(recursive: true);
    }
  });

  group('registration', () {
    test('describes the tool and every parameter', () {
      final entries = <ToolRegistryEntry>[];
      registerPluginTools(entries, cubit, actor: FileRootActor.mcp);

      final entry = entries.single;
      expect(entry.name, 'install_plugin');
      expect(entry.description, contains('/programs/plug-ins/'));
      expect(entry.description, contains('offline and demo mode'));
      expect(entry.description, contains('list_allowed_roots'));
      expect(entry.inputSchema['required'], ['path']);
      final properties = entry.inputSchema['properties'] as Map;
      expect(properties.keys, unorderedEquals(['path', 'load']));
      for (final property in properties.values) {
        expect((property as Map)['description'], isNotEmpty);
      }
      expect(entry.timeout, const Duration(minutes: 10));
    });
  });

  group('.o install', () {
    test('uploads exact bytes, rescans, and finds every GUID', () async {
      final source = inAllowed('seq.o', fixtureBytes);
      device.algorithms = [
        _plugin(0, 'ATds', '$_pluginsDir/seq.o'),
        _plugin(1, 'ATdm', '$_pluginsDir/seq.o'),
        AlgorithmInfo(
          algorithmIndex: 2,
          guid: 'clck',
          name: 'Clock',
          specifications: const [],
        ),
      ];

      final result = await install({'path': source});

      expect(result['success'], isTrue, reason: '$result');
      expect(result['plugin_type'], 'cpp');
      expect(result['destination_path'], '$_pluginsDir/seq.o');
      expect(result['bytes_written'], fixtureBytes.length);
      expect(device.files['$_pluginsDir/seq.o'], fixtureBytes);
      expect(device.chunkSizes.every((size) => size <= 512), isTrue);
      expect(device.rescans, 1);
      expect(result['file_present'], isTrue);
      expect(result['verified'], isTrue);
      expect(result['expected_guids'], unorderedEquals(['ATds', 'ATdm']));
      expect(result['missing_guids'], isEmpty);
      expect(result['rescan_attempts'], 1);
      expect(
        (result['algorithms'] as List).map((a) => a['guid']),
        unorderedEquals(['ATds', 'ATdm']),
      );
      expect(result['preset_reloaded'], isFalse);
      expect(result['root_duplicate'], {'status': 'not_applicable'});
      expect(result.containsKey('load_results'), isFalse);
      verifyNever(() => manager.requestLoadPlugin(any()));
      final state = cubit.state as DistingStateSynchronized;
      expect(state.algorithms.map((a) => a.guid), contains('ATds'));
    });

    test('waits for a slow rescan before reporting', () async {
      final source = inAllowed('tiny.o', [0x7f, 0x45, 0x4c, 0x46, 1, 2]);
      device
        ..algorithms = [_plugin(0, 'Tiny', '$_pluginsDir/tiny.o')]
        ..algorithmsVisibleAfterReads = 2;

      final result = await install({'path': source});

      expect(result['verified'], isTrue, reason: '$result');
      expect(result['rescan_attempts'], 2);
      expect(result['expected_guids'], isEmpty);
      expect((result['algorithms'] as List).single['guid'], 'Tiny');
    });

    test('reports not found when the rescan never shows the plugin', () async {
      final source = inAllowed('tiny.o', [0x7f, 0x45, 0x4c, 0x46, 1, 2]);

      final result = await install({'path': source});

      expect(result['success'], isTrue);
      expect(result['verified'], isFalse);
      expect(result['file_present'], isTrue);
      expect(result['algorithms'], isEmpty);
      expect(result['rescan_attempts'], 3);
      expect(result['message'], contains('No algorithm for this file'));
    });

    test('reports GUIDs missing after the rescan', () async {
      final source = inAllowed('seq.o', fixtureBytes);
      device.algorithms = [_plugin(0, 'ATds', '$_pluginsDir/seq.o')];

      final result = await install({'path': source});

      expect(result['verified'], isFalse);
      expect(result['missing_guids'], ['ATdm']);
      expect(result['rescan_attempts'], 3);
      expect(result['message'], contains('ATdm'));
    });

    test('load loads every algorithm found and reports each', () async {
      final source = inAllowed('tiny.o', [0x7f, 0x45, 0x4c, 0x46, 1, 2]);
      device.algorithms = [_plugin(0, 'Tiny', '$_pluginsDir/tiny.o')];

      final result = await install({'path': source, 'load': true});

      expect(result['verified'], isTrue, reason: '$result');
      expect(result['load_results'], [
        {'guid': 'Tiny', 'loaded': true},
      ]);
      expect(result['message'], contains('Loaded 1 algorithm'));
      verify(() => manager.requestLoadPlugin('Tiny')).called(1);
    });

    test('load reports nothing loaded when nothing was found', () async {
      final source = inAllowed('tiny.o', [0x7f, 0x45, 0x4c, 0x46, 1, 2]);

      final result = await install({'path': source, 'load': true});

      expect(result['load_results'], isEmpty);
      expect(result['message'], contains('Nothing was loaded'));
      verifyNever(() => manager.requestLoadPlugin(any()));
    });

    test('load=false never loads', () async {
      final source = inAllowed('tiny.o', [0x7f, 0x45, 0x4c, 0x46, 1, 2]);
      device.algorithms = [_plugin(0, 'Tiny', '$_pluginsDir/tiny.o')];

      final result = await install({'path': source, 'load': false});

      expect(result['verified'], isTrue);
      expect(result.containsKey('load_results'), isFalse);
      verifyNever(() => manager.requestLoadPlugin(any()));
    });

    test('reports the preset reload when the plugin is in use', () async {
      const target = '$_pluginsDir/tiny.o';
      final inUse = _plugin(0, 'Tiny', target);
      cubit.emit(
        synchronized(
          algorithms: [inUse],
          slots: [
            Slot(
              algorithm: Algorithm(algorithmIndex: 0, guid: 'Tiny', name: 'T'),
              routing: RoutingInfo.filler(),
              pages: ParameterPages(algorithmIndex: 0, pages: []),
              parameters: [],
              values: [],
              enums: [],
              mappings: [],
              valueStrings: [],
            ),
          ],
        ),
      );
      device.algorithms = [inUse];
      final source = inAllowed('tiny.o', [0x7f, 0x45, 0x4c, 0x46, 1, 2]);

      final result = await install({'path': source});

      expect(result['preset_reloaded'], isTrue);
      expect(result['message'], contains('reloaded from its saved copy'));
      verify(() => manager.requestNewPreset()).called(1);
      verify(() => manager.requestLoadPreset('/presets/Test.json', false));
    });

    test('accepts an upper-case extension', () async {
      final source = inAllowed('TINY.O', [0x7f, 0x45, 0x4c, 0x46, 1]);

      final result = await install({'path': source});

      expect(result['success'], isTrue, reason: '$result');
      expect(result['destination_path'], '$_pluginsDir/TINY.O');
      expect(device.rescans, 1);
    });

    test('reports an upload failure', () async {
      device.failUploads = true;
      final source = inAllowed('tiny.o', [0x7f, 0x45, 0x4c, 0x46, 1]);

      final result = await install({'path': source});

      expect(result['success'], isFalse);
      expect(result['error'], 'install_failed');
      expect(result['message'], contains('full'));
      verifyNever(() => manager.requestRescanPlugins());
    });
  });

  group('.lua install', () {
    test('uploads to /programs/lua and verifies by listing only', () async {
      final bytes = utf8.encode('return {name="t"}\n');
      final source = inAllowed('script.lua', bytes);

      final result = await install({'path': source});

      expect(result['success'], isTrue, reason: '$result');
      expect(result['plugin_type'], 'lua');
      expect(result['destination_path'], '$_luaDir/script.lua');
      expect(device.files['$_luaDir/script.lua'], bytes);
      expect(result['file_present'], isTrue);
      expect(result['verified'], isTrue);
      expect(result.containsKey('algorithms'), isFalse);
      verifyNever(() => manager.requestRescanPlugins());
    });

    test('rejects load for Lua before uploading', () async {
      final source = inAllowed('script.lua', utf8.encode('x'));

      final result = await install({'path': source, 'load': true});

      expect(result['error'], 'load_not_supported');
      expectNothingUploaded();
    });
  });

  group('path checks', () {
    test('refuses a file outside every allowed root', () async {
      final file = File('${outside.path}/seq.o')..writeAsBytesSync([1]);

      final result = await install({'path': file.path});

      expect(result['error'], 'path_outside_allowed_root');
      expect(result['message'], contains('list_allowed_roots'));
      expectNothingUploaded();
    });

    test('refuses a root that grants read to chat only', () async {
      await settings.setAllowedFileRoots([
        AllowedFileRoot.chatReadSearch(
          id: 'chat',
          label: 'Chat',
          path: allowed.path,
        ),
      ]);
      final source = inAllowed('tiny.o', [1]);

      final result = await install({'path': source});

      expect(result['error'], 'path_outside_allowed_root');
      expectNothingUploaded();
    });

    test('refuses .. traversal out of the root', () async {
      File('${outside.path}/seq.o').writeAsBytesSync([1]);
      final escape = '${allowed.path}/../${outside.path.split('/').last}/seq.o';

      final result = await install({'path': escape});

      expect(result['error'], 'path_outside_allowed_root');
      expectNothingUploaded();
    });

    test('refuses a symlink inside the root that points outside', () async {
      final target = File('${outside.path}/seq.o')..writeAsBytesSync([1]);
      final link = Link('${allowed.path}/seq.o')..createSync(target.path);

      final result = await install({'path': link.path});

      expect(result['error'], 'path_outside_allowed_root');
      expectNothingUploaded();
    });

    test('refuses a relative path', () async {
      final result = await install({'path': 'build/seq.o'});

      expect(result['error'], 'absolute_path_required');
      expectNothingUploaded();
    });

    test('reports a missing file inside the root', () async {
      final result = await install({'path': '${allowed.path}/absent.o'});

      expect(result['error'], 'file_not_found');
      expect(result['message'], contains('absent.o'));
      expectNothingUploaded();
    });
  });

  group('file checks', () {
    for (final name in ['notes.txt', 'patch.3pot', 'plugin.o.bak', 'noext']) {
      test('rejects $name', () async {
        final source = inAllowed(name, [1]);

        final result = await install({'path': source});

        expect(result['error'], 'unsupported_extension');
        expectNothingUploaded();
      });
    }

    test('rejects a file over the size cap', () async {
      final source = inAllowed(
        'huge.o',
        Uint8List(PluginTools.maxFileBytes + 1),
      );

      final result = await install({'path': source});

      expect(result['error'], 'file_too_large');
      expect(result['size'], PluginTools.maxFileBytes + 1);
      expect(result['max_bytes'], PluginTools.maxFileBytes);
      expectNothingUploaded();
    });

    test('rejects an empty file', () async {
      final source = inAllowed('empty.o', []);

      final result = await install({'path': source});

      expect(result['error'], 'empty_file');
      expectNothingUploaded();
    });
  });

  group('arguments', () {
    test('requires path', () async {
      expect((await install({}))['error'], 'missing_path');
      expect((await install({'path': '  '}))['error'], 'missing_path');
    });

    test('rejects a non-boolean load', () async {
      final source = inAllowed('tiny.o', [1]);
      expect(
        (await install({'path': source, 'load': 'yes'}))['error'],
        'invalid_load',
      );
    });

    test('rejects unknown arguments', () async {
      final result = await install({'path': '/x.o', 'slot_index': 1});
      expect(result['error'], 'unknown_argument');
      expect(result['message'], contains('slot_index'));
    });
  });

  group('connection mode', () {
    Future<void> expectRefused(DistingState state, String code) async {
      cubit.emit(state);
      final source = inAllowed('tiny.o', [0x7f, 0x45, 0x4c, 0x46]);

      final result = await install({'path': source});

      expect(result['success'], isFalse);
      expect(result['error'], code);
      expect(result['message'], isNotEmpty);
      expectNothingUploaded();
      verifyNever(() => manager.requestWake());
    }

    test(
      'refuses offline mode',
      () => expectRefused(synchronized(offline: true), 'offline_mode'),
    );

    test(
      'refuses demo mode',
      () => expectRefused(synchronized(demo: true), 'demo_mode'),
    );

    test(
      'refuses when no device is synchronized',
      () => expectRefused(DistingState.initial(), 'not_connected'),
    );

    test(
      'refuses firmware without SD card support',
      () =>
          expectRefused(synchronized(version: '1.9.0'), 'sd_card_unsupported'),
    );
  });
}
