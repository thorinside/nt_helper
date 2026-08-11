import 'package:fake_async/fake_async.dart';
import 'package:flutter_midi_command/flutter_midi_command.dart';
import 'package:flutter_midi_command_platform_interface/midi_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nt_helper/cubit/disting_cubit.dart';
import 'package:nt_helper/db/daos/metadata_dao.dart';
import 'package:nt_helper/db/database.dart';
import 'package:nt_helper/domain/i_disting_midi_manager.dart';
import 'package:nt_helper/models/cpu_usage.dart';
import 'package:nt_helper/models/firmware_version.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../test_helpers/mock_midi_command.dart';

class _MockAppDatabase extends Mock implements AppDatabase {}

class _MockMetadataDao extends Mock implements MetadataDao {}

class _MockDistingMidiManager extends Mock implements IDistingMidiManager {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _MockAppDatabase database;
  late _MockMetadataDao metadataDao;
  late MockMidiCommand midiCommand;
  late DistingCubit cubit;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    database = _MockAppDatabase();
    metadataDao = _MockMetadataDao();
    midiCommand = MockMidiCommand();
    when(() => database.metadataDao).thenReturn(metadataDao);
    when(
      () => metadataDao.hasCachedAlgorithms(),
    ).thenAnswer((_) async => false);
    cubit = DistingCubit(database, midiCommand: midiCommand);
  });

  tearDown(() async {
    await cubit.close();
  });

  MidiDevice device(String id, String name, MidiPortType direction) {
    final device = MidiDevice(id, name, MidiDeviceType.serial, true);
    if (direction == MidiPortType.IN) {
      device.inputPorts.add(MidiPort(0, direction));
    } else {
      device.outputPorts.add(MidiPort(0, direction));
    }
    return device;
  }

  test('releases input and output independently and retains MidiCommand', () {
    final input = device('input', 'Disting NT', MidiPortType.IN);
    final output = device('output', 'Disting NT', MidiPortType.OUT);
    final manager = _MockDistingMidiManager();
    when(
      () => midiCommand.disconnectDevice(input),
    ).thenThrow(StateError('input already gone'));
    when(() => midiCommand.disconnectDevice(output)).thenAnswer((_) {});
    when(() => manager.dispose()).thenAnswer((_) {});

    cubit.disposeFirmwareMidiManager(manager, input, output);

    verify(() => midiCommand.disconnectDevice(input)).called(1);
    verify(() => midiCommand.disconnectDevice(output)).called(1);
    verify(() => manager.dispose()).called(1);
    verifyNever(() => midiCommand.dispose());
  });

  test('firmware handoff stops polling the disposed pre-flash manager', () {
    final input = device('input', 'Disting NT', MidiPortType.IN);
    final output = device('output', 'Disting NT', MidiPortType.OUT);
    final manager = _MockDistingMidiManager();
    when(() => manager.requestWake()).thenAnswer((_) async {});
    when(
      () => manager.requestCpuUsage(),
    ).thenAnswer((_) async => CpuUsage(cpu1: 1, cpu2: 2, slotUsages: const []));
    when(() => manager.dispose()).thenAnswer((_) {});
    when(() => midiCommand.disconnectDevice(input)).thenAnswer((_) {});
    when(() => midiCommand.disconnectDevice(output)).thenAnswer((_) {});
    cubit.emit(
      DistingState.synchronized(
        disting: manager,
        distingVersion: '1.16.0',
        firmwareVersion: FirmwareVersion('1.16.0'),
        presetName: 'Test',
        algorithms: const [],
        slots: const [],
        unitStrings: const [],
        inputDevice: input,
        outputDevice: output,
      ),
    );

    fakeAsync((async) {
      final subscription = cubit.cpuUsageStream.listen((_) {});
      async.flushMicrotasks();
      verify(() => manager.requestCpuUsage()).called(1);
      clearInteractions(manager);

      cubit.disposeFirmwareMidiManager(manager, input, output);
      clearInteractions(manager);
      async.elapse(const Duration(seconds: 10));
      async.flushMicrotasks();

      verifyNever(() => manager.requestWake());
      verifyNever(() => manager.requestCpuUsage());
      subscription.cancel();
    });
  });

  test(
    'uses a fresh snapshot and refreshes device selection on completion',
    () async {
      final input = device('input', 'Disting NT', MidiPortType.IN);
      final output = device('output', 'Disting NT', MidiPortType.OUT);
      var snapshots = 0;
      when(() => midiCommand.devices).thenAnswer((_) async {
        snapshots++;
        return snapshots == 1 ? [] : [input, output];
      });
      when(() => midiCommand.onMidiSetupChanged).thenReturn(null);

      expect(
        await cubit.firmwareMidiDevicesAvailable('Disting NT', 'Disting NT'),
        isFalse,
      );
      expect(
        await cubit.firmwareMidiDevicesAvailable('Disting NT', 'Disting NT'),
        isTrue,
      );

      await cubit.onFirmwareUpdateComplete();

      expect(snapshots, 3);
      final state = cubit.state as DistingStateSelectDevice;
      expect(state.inputDevices, [input]);
      expect(state.outputDevices, [output]);
      verifyNever(() => midiCommand.dispose());
    },
  );
}
