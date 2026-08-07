import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_midi_command/flutter_midi_command.dart';
import 'package:flutter_midi_command_platform_interface/midi_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/cubit/ntx_8cv_connection_cubit.dart';
import 'package:nt_helper/cubit/ntx_8cv_settings_cubit.dart';
import 'package:nt_helper/domain/ntx_8cv/ntx_8cv_midi_connection.dart';
import 'package:nt_helper/domain/ntx_8cv/ntx_8cv_sysex.dart';

import '../fixtures/ntx_8cv_sysex_fixtures.dart';

void main() {
  group('Ntx8cvSettingsCubit', () {
    late _FakeNtx8cvMidiConnection midiConnection;
    late Ntx8cvConnectionCubit connectionCubit;
    late Ntx8cvSettingsCubit settingsCubit;

    setUp(() {
      midiConnection = _FakeNtx8cvMidiConnection();
      midiConnection.devices = [
        _midiDevice(id: 'ntx8cv', name: 'NTX-8CV', input: true, output: true),
      ];
      connectionCubit = Ntx8cvConnectionCubit(
        midiConnection: midiConnection,
        store: _MemoryNtx8cvConnectionStore(),
        sessionTimeout: const Duration(milliseconds: 10),
      );
      settingsCubit = Ntx8cvSettingsCubit(connectionCubit: connectionCubit);
    });

    tearDown(() async {
      await settingsCubit.close();
      await connectionCubit.close();
      await midiConnection.dispose();
    });

    test('reads the device-confirmed ES-5 value after connecting', () async {
      midiConnection.transport.onSend = (packet) {
        if (packet[6] == 0x22) {
          midiConnection.transport.receive(
            Ntx8cvSysExFixtures.deviceInformationResponse,
          );
        } else if (packet[6] == 0x31 && packet[7] == 0x01) {
          midiConnection.transport.receive(
            Ntx8cvSysExFixtures.es5DisabledResponse,
          );
        }
      };
      await connectionCubit.initialize();

      await connectionCubit.connect();
      await _flushEvents();

      expect(settingsCubit.state.confirmedEs5Enabled, isFalse);
      expect(settingsCubit.state.hasPendingEs5Change, isFalse);
      expect(midiConnection.transport.sent, hasLength(2));
      expect(
        midiConnection.transport.sent[0],
        orderedEquals(Ntx8cvSysExFixtures.deviceInformationRequest),
      );
      expect(
        midiConnection.transport.sent[1],
        orderedEquals(Ntx8cvSysExFixtures.readEs5EnabledSetting),
      );
    });

    test('changes ES-5 only after a matching same-setting readback', () async {
      midiConnection.transport.onSend = (packet) {
        if (packet[6] == 0x22) {
          midiConnection.transport.receive(
            Ntx8cvSysExFixtures.deviceInformationResponse,
          );
        } else if (packet[6] == 0x31 && packet[7] == 0x01) {
          final hasWrittenEs5 = midiConnection.transport.sent.any(
            (sent) => sent[6] == 0x32 && sent[7] == 0x01,
          );
          midiConnection.transport.receive(
            hasWrittenEs5
                ? Ntx8cvSysExFixtures.es5EnabledResponse
                : Ntx8cvSysExFixtures.es5DisabledResponse,
          );
        }
      };
      await connectionCubit.initialize();
      await connectionCubit.connect();
      await _flushEvents();

      await settingsCubit.setEs5Enabled(true);

      expect(settingsCubit.state.confirmedEs5Enabled, isTrue);
      expect(settingsCubit.state.hasPendingEs5Change, isFalse);
      expect(midiConnection.transport.sent, hasLength(4));
      expect(
        midiConnection.transport.sent[0],
        orderedEquals(Ntx8cvSysExFixtures.deviceInformationRequest),
      );
      expect(
        midiConnection.transport.sent[1],
        orderedEquals(Ntx8cvSysExFixtures.readEs5EnabledSetting),
      );
      expect(
        midiConnection.transport.sent[2],
        orderedEquals(Ntx8cvSysExFixtures.writeEs5EnabledSetting),
      );
      expect(
        midiConnection.transport.sent[3],
        orderedEquals(Ntx8cvSysExFixtures.readEs5EnabledSetting),
      );
    });

    test(
      'retains a mismatched ES-5 change across reconnect and retries it only explicitly',
      () async {
        var returnEnabledValue = false;
        midiConnection.transport.onSend = (packet) {
          final deviceId = packet[5];
          if (packet[6] == 0x22) {
            midiConnection.transport.receive(
              _withDeviceId(
                Ntx8cvSysExFixtures.deviceInformationResponse,
                deviceId,
              ),
            );
          } else if (packet[6] == 0x31 && packet[7] == 0x01) {
            midiConnection.transport.receive(
              _withDeviceId(
                returnEnabledValue
                    ? Ntx8cvSysExFixtures.es5EnabledResponse
                    : Ntx8cvSysExFixtures.es5DisabledResponse,
                deviceId,
              ),
            );
          }
        };
        await connectionCubit.initialize();
        await connectionCubit.connect();
        await _flushEvents();

        await settingsCubit.setEs5Enabled(true);

        expect(settingsCubit.state.confirmedEs5Enabled, isFalse);
        expect(settingsCubit.state.attemptedEs5Enabled, isTrue);
        expect(settingsCubit.state.hasPendingEs5Change, isTrue);
        expect(settingsCubit.state.es5Message, contains('not confirmed'));
        expect(settingsCubit.state.es5Message, contains('uncertain'));

        await connectionCubit.disconnect();
        await connectionCubit.setDeviceIdText('2');
        expect(settingsCubit.state.confirmedEs5Enabled, isNull);
        expect(settingsCubit.state.attemptedEs5Enabled, isTrue);
        expect(settingsCubit.state.es5Message, contains('target changed'));

        final sendsBeforeReconnect = midiConnection.transport.sent.length;
        await connectionCubit.connect();
        await _flushEvents();

        expect(settingsCubit.state.hasPendingEs5Change, isTrue);
        expect(
          midiConnection.transport.sent,
          hasLength(sendsBeforeReconnect + 1),
        );
        expect(midiConnection.transport.sent.last[5], 2);
        expect(midiConnection.transport.sent.last[6], 0x22);

        returnEnabledValue = true;
        await settingsCubit.retryEs5Change();

        expect(settingsCubit.state.confirmedEs5Enabled, isTrue);
        expect(settingsCubit.state.hasPendingEs5Change, isFalse);
        expect(
          midiConnection.transport.sent,
          hasLength(sendsBeforeReconnect + 3),
        );
        expect(midiConnection.transport.sent[sendsBeforeReconnect + 1][5], 2);
        expect(
          midiConnection.transport.sent[sendsBeforeReconnect + 1][6],
          0x32,
        );
        expect(midiConnection.transport.sent[sendsBeforeReconnect + 2][5], 2);
        expect(
          midiConnection.transport.sent[sendsBeforeReconnect + 2][6],
          0x31,
        );
      },
    );

    test(
      'keeps a timed-out ES-5 write pending and labels it uncertain',
      () async {
        var hasStartedWrite = false;
        midiConnection.transport.onSend = (packet) {
          if (packet[6] == 0x22) {
            midiConnection.transport.receive(
              Ntx8cvSysExFixtures.deviceInformationResponse,
            );
          } else if (packet[6] == 0x32 && packet[7] == 0x01) {
            hasStartedWrite = true;
          } else if (packet[6] == 0x31 &&
              packet[7] == 0x01 &&
              !hasStartedWrite) {
            midiConnection.transport.receive(
              Ntx8cvSysExFixtures.es5DisabledResponse,
            );
          }
        };
        await connectionCubit.initialize();
        await connectionCubit.connect();
        await _flushEvents();

        await settingsCubit.setEs5Enabled(true);

        expect(settingsCubit.state.confirmedEs5Enabled, isFalse);
        expect(settingsCubit.state.attemptedEs5Enabled, isTrue);
        expect(settingsCubit.state.isWritingEs5, isFalse);
        expect(settingsCubit.state.es5Message, contains('not confirmed'));
        expect(settingsCubit.state.es5Message, contains('uncertain'));
      },
    );

    test(
      'keeps an interrupted ES-5 write pending and labels it uncertain',
      () async {
        var hasStartedWrite = false;
        midiConnection.transport.onSend = (packet) {
          if (packet[6] == 0x22) {
            midiConnection.transport.receive(
              Ntx8cvSysExFixtures.deviceInformationResponse,
            );
          } else if (packet[6] == 0x32 && packet[7] == 0x01) {
            hasStartedWrite = true;
          } else if (packet[6] == 0x31 &&
              packet[7] == 0x01 &&
              !hasStartedWrite) {
            midiConnection.transport.receive(
              Ntx8cvSysExFixtures.es5DisabledResponse,
            );
          }
        };
        await connectionCubit.initialize();
        await connectionCubit.connect();
        await _flushEvents();

        final write = settingsCubit.setEs5Enabled(true);
        await _flushEvents();
        expect(settingsCubit.state.isWritingEs5, isTrue);
        expect(settingsCubit.state.attemptedEs5Enabled, isTrue);

        await connectionCubit.disconnect();
        await write;

        expect(settingsCubit.state.confirmedEs5Enabled, isFalse);
        expect(settingsCubit.state.attemptedEs5Enabled, isTrue);
        expect(settingsCubit.state.isWritingEs5, isFalse);
        expect(settingsCubit.state.es5Message, contains('disconnected'));
        expect(settingsCubit.state.es5Message, contains('uncertain'));
      },
    );
  });
}

Future<void> _flushEvents() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

Uint8List _withDeviceId(Uint8List packet, int deviceId) {
  final copy = Uint8List.fromList(packet);
  copy[5] = deviceId;
  return copy;
}

MidiDevice _midiDevice({
  required String id,
  required String name,
  bool input = false,
  bool output = false,
}) {
  final device = MidiDevice(id, name, MidiDeviceType.serial, false);
  if (input) device.inputPorts = [MidiPort(1, MidiPortType.IN)];
  if (output) device.outputPorts = [MidiPort(2, MidiPortType.OUT)];
  return device;
}

class _MemoryNtx8cvConnectionStore implements Ntx8cvConnectionStore {
  @override
  Future<Ntx8cvSavedConnection> load() async => const Ntx8cvSavedConnection();

  @override
  Future<void> save(Ntx8cvSavedConnection selection) async {}
}

class _FakeNtx8cvMidiConnection implements Ntx8cvMidiConnection {
  List<MidiDevice> devices = [];
  final _FakeNtx8cvMidiTransport transport = _FakeNtx8cvMidiTransport();

  @override
  Stream<MidiSetupChange>? get setupChanges => null;

  @override
  Future<List<MidiDevice>> listDevices() async => List.of(devices);

  @override
  Future<Ntx8cvMidiTransport> open({
    required MidiDevice inputDevice,
    required MidiDevice outputDevice,
  }) async => transport;

  @override
  Future<void> close({
    required Ntx8cvMidiTransport transport,
    required MidiDevice inputDevice,
    required MidiDevice outputDevice,
  }) async {}

  Future<void> dispose() => transport.close();
}

class _FakeNtx8cvMidiTransport implements Ntx8cvMidiTransport {
  final _received = StreamController<Uint8List>.broadcast(sync: true);
  final List<Uint8List> sent = [];
  void Function(Uint8List packet)? onSend;

  @override
  Stream<Uint8List> get receivedPackets => _received.stream;

  @override
  Future<void> send(Uint8List packet) async {
    sent.add(packet);
    onSend?.call(packet);
  }

  void receive(Uint8List packet) => _received.add(packet);

  Future<void> close() => _received.close();
}
