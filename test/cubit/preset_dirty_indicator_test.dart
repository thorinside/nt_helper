import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nt_helper/cubit/disting_cubit.dart';
import 'package:nt_helper/db/daos/metadata_dao.dart';
import 'package:nt_helper/db/database.dart';
import 'package:nt_helper/domain/i_disting_midi_manager.dart';
import 'package:nt_helper/models/firmware_version.dart';
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

  DistingStateSynchronized makeSyncState({
    String presetName = 'Test Preset',
    bool isDirty = false,
  }) {
    return DistingStateSynchronized(
      disting: mockDisting,
      distingVersion: '1.10.0',
      firmwareVersion: FirmwareVersion('1.14.0'),
      presetName: presetName,
      algorithms: const [],
      slots: const [],
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
}
