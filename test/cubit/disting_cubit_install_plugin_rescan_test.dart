import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nt_helper/cubit/disting_cubit.dart';
import 'package:nt_helper/domain/i_disting_midi_manager.dart';
import 'package:nt_helper/db/database.dart';
import 'package:nt_helper/db/daos/metadata_dao.dart';
import 'package:nt_helper/models/firmware_version.dart';
import 'package:nt_helper/models/sd_card_file_system.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockAppDatabase extends Mock implements AppDatabase {}

class MockMetadataDao extends Mock implements MetadataDao {}

class MockDistingMidiManager extends Mock implements IDistingMidiManager {}

void main() {
  late DistingCubit cubit;
  late MockAppDatabase mockDatabase;
  late MockMetadataDao mockMetadataDao;
  late MockDistingMidiManager mockDisting;

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    registerFallbackValue(DistingState.initial());
    registerFallbackValue(Uint8List(0));
  });

  setUp(() {
    mockDatabase = MockAppDatabase();
    mockMetadataDao = MockMetadataDao();
    mockDisting = MockDistingMidiManager();

    when(() => mockDatabase.metadataDao).thenReturn(mockMetadataDao);
    when(() => mockMetadataDao.hasCachedAlgorithms()).thenAnswer((_) async => false);

    cubit = DistingCubit(mockDatabase);

    // Setup common mocks for file upload
    when(() => mockDisting.requestWake()).thenAnswer((_) async {});
    when(() => mockDisting.requestDirectoryListing(any()))
        .thenAnswer((_) async => DirectoryListing(entries: []));
    when(() => mockDisting.requestDirectoryCreate(any()))
        .thenAnswer((_) async => SdCardStatus(success: true, message: 'ok'));
    when(() => mockDisting.requestFileUploadChunk(any(), any(), any(), createAlways: any(named: 'createAlways')))
        .thenAnswer((_) async => SdCardStatus(success: true, message: 'ok'));
    when(() => mockDisting.requestRescanPlugins()).thenAnswer((_) async {});
    when(() => mockDisting.requestNumberOfAlgorithms()).thenAnswer((_) async => 0);
  });

  tearDown(() {
    cubit.close();
  });

  DistingStateSynchronized createSynchronizedState() {
    return DistingStateSynchronized(
      disting: mockDisting,
      distingVersion: '1.12.0',
      firmwareVersion: FirmwareVersion('1.12.0'),
      presetName: 'Test',
      algorithms: [],
      slots: [],
      unitStrings: [],
      inputDevice: null,
      outputDevice: null,
      loading: false,
      offline: false,
      screenshot: null,
      demo: false,
      videoStream: null,
    );
  }

  group('DistingCubit installPlugin rescan behavior', () {
    test('triggers requestRescanPlugins after .o file upload', () async {
      // Arrange
      cubit.emit(createSynchronizedState());
      final testData = Uint8List.fromList([0x01, 0x02, 0x03]);

      // Act
      await cubit.installPlugin('test_plugin.o', testData);

      // Assert - rescan should be called for C++ plugins
      verify(() => mockDisting.requestRescanPlugins()).called(1);
    });

    test('does NOT trigger requestRescanPlugins after .lua file upload', () async {
      // Arrange
      cubit.emit(createSynchronizedState());
      final testData = Uint8List.fromList([0x01, 0x02, 0x03]);

      // Act
      await cubit.installPlugin('test_script.lua', testData);

      // Assert - rescan should NOT be called for Lua scripts
      verifyNever(() => mockDisting.requestRescanPlugins());
    });

    test('does NOT trigger requestRescanPlugins after .3pot file upload', () async {
      // Arrange
      cubit.emit(createSynchronizedState());
      final testData = Uint8List.fromList([0x01, 0x02, 0x03]);

      // Act
      await cubit.installPlugin('test_script.3pot', testData);

      // Assert - rescan should NOT be called for Three Pot scripts
      verifyNever(() => mockDisting.requestRescanPlugins());
    });

    test('continues successfully even if rescan fails', () async {
      // Arrange
      cubit.emit(createSynchronizedState());
      final testData = Uint8List.fromList([0x01, 0x02, 0x03]);

      // Make rescan fail
      when(() => mockDisting.requestRescanPlugins())
          .thenThrow(Exception('Rescan failed'));

      // Act - should not throw
      await cubit.installPlugin('test_plugin.o', testData);

      // Assert - installation should complete without throwing
      verify(() => mockDisting.requestRescanPlugins()).called(1);
    });

    test('triggers rescan for .O extension (case insensitive)', () async {
      // Arrange
      cubit.emit(createSynchronizedState());
      final testData = Uint8List.fromList([0x01, 0x02, 0x03]);

      // Act
      await cubit.installPlugin('test_plugin.O', testData);

      // Assert - rescan should be called (extension comparison is case-insensitive)
      verify(() => mockDisting.requestRescanPlugins()).called(1);
    });

    test('triggers rescan for plugins with subdirectories in path', () async {
      // Arrange
      cubit.emit(createSynchronizedState());
      final testData = Uint8List.fromList([0x01, 0x02, 0x03]);

      // Act
      await cubit.installPlugin('subfolder/test_plugin.o', testData);

      // Assert - rescan should be called regardless of path structure
      verify(() => mockDisting.requestRescanPlugins()).called(1);
    });
  });
}
