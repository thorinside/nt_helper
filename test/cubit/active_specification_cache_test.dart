import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nt_helper/cubit/disting_cubit.dart';
import 'package:nt_helper/db/daos/metadata_dao.dart';
import 'package:nt_helper/db/database.dart';
import 'package:nt_helper/domain/disting_nt_sysex.dart';
import 'package:nt_helper/domain/i_disting_midi_manager.dart';
import 'package:nt_helper/models/firmware_version.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../test_helpers/grouped_audio_routing_fixture.dart';
import '../test_helpers/mock_midi_command.dart';

class _Database extends Mock implements AppDatabase {}

class _Metadata extends Mock implements MetadataDao {}

class _Manager extends Mock implements IDistingMidiManager {}

class _Cubit extends DistingCubit {
  _Cubit(super.database, this.slot) : super(midiCommand: MockMidiCommand());
  final Slot slot;

  @override
  Future<List<Slot>> fetchSlots(
    int count,
    IDistingMidiManager manager, {
    void Function(int completed, int total)? onSlotProgress,
  }) async => [slot];

  @override
  Future<void> checkForFirmwareUpdate() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => registerFallbackValue(<AlgorithmInfo>[]));
  setUp(() => SharedPreferences.setMockInitialValues({}));

  for (final incomplete in [false, true]) {
    test(
      'full sync ${incomplete ? 'refreshes incomplete' : 'retains complete'} cached specification metadata for an active plugin',
      () async {
        final database = _Database();
        final metadata = _Metadata();
        final manager = _Manager();
        final live = groupedAudioInfo(guid: 'ATay', name: 'TapeDelay');
        List<AlgorithmInfo>? cached = [
          incomplete
              ? groupedAudioInfo(
                  guid: 'ATay',
                  name: 'TapeDelay',
                  definitions: [],
                )
              : live,
        ];
        when(() => database.metadataDao).thenReturn(metadata);
        when(
          () => metadata.hasCachedAlgorithms(),
        ).thenAnswer((_) async => false);
        when(
          () => metadata.getAlgorithmInfoCache(
            any(),
            cacheFreshnessDays: any(named: 'cacheFreshnessDays'),
          ),
        ).thenAnswer((_) async => cached);
        when(() => metadata.invalidateAlgorithmInfoCache()).thenAnswer((
          _,
        ) async {
          cached = null;
        });
        when(
          () => metadata.saveAlgorithmInfoCache(any(), any()),
        ).thenAnswer((_) async {});
        when(
          () => manager.requestNumberOfAlgorithms(),
        ).thenAnswer((_) async => 1);
        when(
          () => manager.requestNumAlgorithmsInPreset(),
        ).thenAnswer((_) async => 1);
        when(
          () => manager.requestVersionString(),
        ).thenAnswer((_) async => '1.14.0');
        when(
          () => manager.requestPresetName(),
        ).thenAnswer((_) async => 'Chain');
        when(() => manager.requestUnitStrings()).thenAnswer((_) async => []);
        when(
          () => manager.requestAlgorithmInfo(0),
        ).thenAnswer((_) async => live);
        final slot = groupedAudioSlot(guid: 'ATay', name: 'TapeDelay');
        final cubit = _Cubit(database, slot);
        cubit.emit(
          DistingState.synchronized(
            disting: manager,
            distingVersion: '1.14.0',
            firmwareVersion: FirmwareVersion('1.14.0'),
            presetName: 'Chain',
            algorithms: cached!,
            slots: [slot],
            unitStrings: const [],
          ),
        );
        addTearDown(cubit.close);
        final refreshed = cubit.stream.firstWhere(
          (state) =>
              state is DistingStateSynchronized &&
              state.algorithms.isNotEmpty &&
              state.algorithms.single.specifications.length == 1,
        );
        await cubit.refresh(fullRefresh: true);
        await refreshed.timeout(const Duration(seconds: 5));
        if (incomplete) {
          verify(() => metadata.invalidateAlgorithmInfoCache()).called(1);
          verify(() => manager.requestAlgorithmInfo(0)).called(1);
        } else {
          verifyNever(() => metadata.invalidateAlgorithmInfoCache());
          verifyNever(() => manager.requestAlgorithmInfo(any()));
        }
      },
    );
  }
}
