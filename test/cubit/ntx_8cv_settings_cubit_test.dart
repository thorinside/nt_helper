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
        rebootReconnectDelay: Duration.zero,
      );
      settingsCubit = Ntx8cvSettingsCubit(connectionCubit: connectionCubit);
    });

    tearDown(() async {
      await settingsCubit.close();
      await connectionCubit.close();
      await midiConnection.dispose();
    });

    test(
      'reads Channel Group, ES-5, Mode, and every audio-channel setting after connecting',
      () async {
        midiConnection.transport.onSend = (packet) {
          _respondWithSettings(midiConnection.transport, packet);
        };
        await connectionCubit.initialize();
        await connectionCubit.connect();
        await _flushEvents();

        expect(settingsCubit.state.confirmedEs5Enabled, isFalse);
        expect(
          settingsCubit.state.confirmedMode,
          Ntx8cvExpansionMode.audio2x8_16bit,
        );
        expect(settingsCubit.state.modeCapabilityEvidenced, isTrue);
        expect(midiConnection.transport.sent, hasLength(12));
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
          orderedEquals(Ntx8cvSysExFixtures.readModeSetting),
        );
        expect(
          midiConnection.transport.sent[3],
          orderedEquals(Ntx8cvSysExFixtures.readAudioChannel1EnabledSetting),
        );
        expect(
          midiConnection.transport.sent
              .sublist(3, 11)
              .map((packet) => packet[7]),
          orderedEquals([0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0A, 0x0B]),
        );
        expect(
          midiConnection.transport.sent[11],
          orderedEquals(Ntx8cvSysExFixtures.readChannelGroupSetting),
        );
        expect(
          settingsCubit.state.confirmedChannelGroup,
          Ntx8cvChannelGroup.channels1To8,
        );
      },
    );

    test(
      'reboots only the selected NTX-8CV then revalidates and refreshes settings',
      () async {
        var channelGroupValue = Ntx8cvChannelGroup.channels1To8.value;
        var es5Value = 0;
        var modeValue = Ntx8cvExpansionMode.cv8x8.value;
        midiConnection.transport.onSend = (packet) {
          if (packet[6] == 0x32 && packet[7] == 0x1B) {
            modeValue = packet[8];
          }
          _respondWithSettings(
            midiConnection.transport,
            packet,
            channelGroupValue: channelGroupValue,
            es5Value: es5Value,
            modeValue: modeValue,
          );
        };
        await connectionCubit.initialize();
        await connectionCubit.connect();
        await _flushEvents();

        await settingsCubit.setExpansionMode(
          Ntx8cvExpansionMode.audio1x8_32bit,
        );
        expect(settingsCubit.state.modeRebootRequired, isTrue);

        channelGroupValue = Ntx8cvChannelGroup.channels57To64.value;
        es5Value = 1;
        final sendsBeforeReboot = midiConnection.transport.sent.length;

        await settingsCubit.reboot();

        expect(midiConnection.openCount, 2);
        expect(midiConnection.closeCount, 1);
        expect(
          midiConnection.transport.sent[sendsBeforeReboot],
          orderedEquals(Ntx8cvSysExFixtures.reboot),
        );
        expect(
          midiConnection.transport.sent[sendsBeforeReboot + 1],
          orderedEquals(Ntx8cvSysExFixtures.deviceInformationRequest),
        );
        expect(
          midiConnection.transport.sent[sendsBeforeReboot + 2],
          orderedEquals(Ntx8cvSysExFixtures.readEs5EnabledSetting),
        );
        expect(
          midiConnection.transport.sent[sendsBeforeReboot + 3],
          orderedEquals(Ntx8cvSysExFixtures.readModeSetting),
        );
        expect(
          midiConnection.transport.sent
              .sublist(sendsBeforeReboot + 4, sendsBeforeReboot + 12)
              .map((packet) => packet[7]),
          orderedEquals([0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0A, 0x0B]),
        );
        expect(
          midiConnection.transport.sent[sendsBeforeReboot + 12],
          orderedEquals(Ntx8cvSysExFixtures.readChannelGroupSetting),
        );
        expect(settingsCubit.state.confirmedEs5Enabled, isTrue);
        expect(
          settingsCubit.state.confirmedMode,
          Ntx8cvExpansionMode.audio1x8_32bit,
        );
        expect(
          settingsCubit.state.confirmedChannelGroup,
          Ntx8cvChannelGroup.channels57To64,
        );
        expect(settingsCubit.state.modeCapabilityEvidenced, isTrue);
        expect(settingsCubit.state.modeRebootRequired, isFalse);
        expect(settingsCubit.state.isRebooting, isFalse);
      },
    );

    test(
      'confirms individual audio channels only after same-setting readback',
      () async {
        final audioChannelValues = [1, 0, 1, 0, 1, 0, 1, 0];
        midiConnection.transport.onSend = (packet) {
          if (packet[6] == 0x32 && packet[7] == 0x05) {
            audioChannelValues[1] = packet[8];
          }
          _respondWithSettings(
            midiConnection.transport,
            packet,
            audioChannelValues: audioChannelValues,
          );
        };
        await connectionCubit.initialize();
        await connectionCubit.connect();
        await _flushEvents();

        expect(
          settingsCubit.state.confirmedAudioChannelEnabled(
            Ntx8cvAudioChannel.channel1,
          ),
          isTrue,
        );
        expect(
          settingsCubit.state.confirmedAudioChannelEnabled(
            Ntx8cvAudioChannel.channel2,
          ),
          isFalse,
        );

        await settingsCubit.setAudioChannelEnabled(
          Ntx8cvAudioChannel.channel2,
          true,
        );

        expect(
          settingsCubit.state.confirmedAudioChannelEnabled(
            Ntx8cvAudioChannel.channel2,
          ),
          isTrue,
        );
        expect(
          settingsCubit.state.hasPendingAudioChannelChange(
            Ntx8cvAudioChannel.channel2,
          ),
          isFalse,
        );
        expect(
          midiConnection.transport.sent[midiConnection.transport.sent.length -
              2],
          orderedEquals(_writeSetting(0x05, 1)),
        );
        expect(
          midiConnection.transport.sent.last,
          orderedEquals(_readSetting(0x05)),
        );
      },
    );

    test(
      'keeps a mismatched audio-channel change pending and uncertain',
      () async {
        midiConnection.transport.onSend = (packet) {
          _respondWithSettings(midiConnection.transport, packet);
        };
        await connectionCubit.initialize();
        await connectionCubit.connect();
        await _flushEvents();

        await settingsCubit.setAudioChannelEnabled(
          Ntx8cvAudioChannel.channel1,
          false,
        );

        expect(
          settingsCubit.state.confirmedAudioChannelEnabled(
            Ntx8cvAudioChannel.channel1,
          ),
          isTrue,
        );
        expect(
          settingsCubit.state.attemptedAudioChannelEnabled(
            Ntx8cvAudioChannel.channel1,
          ),
          isFalse,
        );
        expect(
          settingsCubit.state.hasPendingAudioChannelChange(
            Ntx8cvAudioChannel.channel1,
          ),
          isTrue,
        );
        expect(
          settingsCubit.state
              .audioChannelChange(Ntx8cvAudioChannel.channel1)
              .message,
          contains('uncertain'),
        );
      },
    );

    test(
      'refresh and reconnect repopulate audio channels without resending',
      () async {
        var audioChannelValues = [1, 0, 1, 0, 1, 0, 1, 0];
        midiConnection.transport.onSend = (packet) {
          _respondWithSettings(
            midiConnection.transport,
            packet,
            audioChannelValues: audioChannelValues,
          );
        };
        await connectionCubit.initialize();
        await connectionCubit.connect();
        await _flushEvents();

        audioChannelValues = [0, 1, 0, 1, 0, 1, 0, 1];
        final sendsBeforeRefresh = midiConnection.transport.sent.length;
        await settingsCubit.refresh();

        expect(
          settingsCubit.state.confirmedAudioChannelEnabled(
            Ntx8cvAudioChannel.channel1,
          ),
          isFalse,
        );
        expect(
          settingsCubit.state.confirmedAudioChannelEnabled(
            Ntx8cvAudioChannel.channel2,
          ),
          isTrue,
        );
        expect(
          midiConnection.transport.sent
              .skip(sendsBeforeRefresh)
              .every((packet) => packet[6] != 0x32),
          isTrue,
        );

        await connectionCubit.disconnect();
        final sendsBeforeReconnect = midiConnection.transport.sent.length;
        await connectionCubit.connect();
        await _flushEvents();

        expect(
          settingsCubit.state.confirmedAudioChannelEnabled(
            Ntx8cvAudioChannel.channel1,
          ),
          isFalse,
        );
        expect(
          midiConnection.transport.sent
              .skip(sendsBeforeReconnect)
              .where((packet) => packet[6] == 0x32),
          isEmpty,
        );
        expect(
          midiConnection.transport.sent
              .skip(sendsBeforeReconnect)
              .where((packet) => packet[6] == 0x31)
              .map((packet) => packet[7]),
          containsAllInOrder([0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0A, 0x0B]),
        );
      },
    );

    test(
      'keeps a timed-out audio-channel change pending and uncertain',
      () async {
        var writeStarted = false;
        midiConnection.transport.onSend = (packet) {
          if (packet[6] == 0x32 && packet[7] == 0x04) {
            writeStarted = true;
            return;
          }
          if (writeStarted && packet[6] == 0x31 && packet[7] == 0x04) {
            return;
          }
          _respondWithSettings(midiConnection.transport, packet);
        };
        await connectionCubit.initialize();
        await connectionCubit.connect();
        await _flushEvents();

        await settingsCubit.setAudioChannelEnabled(
          Ntx8cvAudioChannel.channel1,
          false,
        );

        final change = settingsCubit.state.audioChannelChange(
          Ntx8cvAudioChannel.channel1,
        );
        expect(change.attemptedValue, 0);
        expect(change.isWriting, isFalse);
        expect(change.message, contains('timed out'));
        expect(change.message, contains('uncertain'));
      },
    );

    test('labels a malformed audio-channel readback as uncertain', () async {
      var writeStarted = false;
      midiConnection.transport.onSend = (packet) {
        if (packet[6] == 0x32 && packet[7] == 0x04) {
          writeStarted = true;
          return;
        }
        if (writeStarted && packet[6] == 0x31 && packet[7] == 0x04) {
          scheduleMicrotask(() {
            midiConnection.transport.receive(
              Uint8List.fromList([
                0xF0,
                0x00,
                0x21,
                0x27,
                0x6A,
                packet[5],
                0x31,
                0x04,
                0xF7,
              ]),
            );
          });
          return;
        }
        _respondWithSettings(midiConnection.transport, packet);
      };
      await connectionCubit.initialize();
      await connectionCubit.connect();
      await _flushEvents();

      await settingsCubit.setAudioChannelEnabled(
        Ntx8cvAudioChannel.channel1,
        false,
      );

      final change = settingsCubit.state.audioChannelChange(
        Ntx8cvAudioChannel.channel1,
      );
      expect(change.attemptedValue, 0);
      expect(change.message, contains('malformed'));
      expect(change.message, contains('uncertain'));
    });

    test(
      'does not offer audio-channel writes until a confirmed audio Mode is rebooted',
      () async {
        var modeValue = Ntx8cvExpansionMode.cv8x8.value;
        midiConnection.transport.onSend = (packet) {
          if (packet[6] == 0x32 && packet[7] == 0x1B) {
            modeValue = packet[8];
          }
          _respondWithSettings(
            midiConnection.transport,
            packet,
            modeValue: modeValue,
          );
        };
        await connectionCubit.initialize();
        await connectionCubit.connect();
        await _flushEvents();

        await settingsCubit.setExpansionMode(
          Ntx8cvExpansionMode.audio1x8_32bit,
        );
        expect(settingsCubit.state.modeRebootRequired, isTrue);

        final sendsBeforeAudioChange = midiConnection.transport.sent.length;
        await settingsCubit.setAudioChannelEnabled(
          Ntx8cvAudioChannel.channel1,
          false,
        );

        expect(
          midiConnection.transport.sent,
          hasLength(sendsBeforeAudioChange),
        );
      },
    );

    test('changes ES-5 only after matching same-setting readback', () async {
      midiConnection.transport.onSend = (packet) {
        final hasWrittenEs5 = midiConnection.transport.sent.any(
          (sent) => sent[6] == 0x32 && sent[7] == 0x01,
        );
        _respondWithSettings(
          midiConnection.transport,
          packet,
          es5Value: hasWrittenEs5 ? 1 : 0,
        );
      };
      await connectionCubit.initialize();
      await connectionCubit.connect();
      await _flushEvents();

      await settingsCubit.setEs5Enabled(true);

      expect(settingsCubit.state.confirmedEs5Enabled, isTrue);
      expect(settingsCubit.state.hasPendingEs5Change, isFalse);
      expect(midiConnection.transport.sent, hasLength(14));
      expect(
        midiConnection.transport.sent[12],
        orderedEquals(Ntx8cvSysExFixtures.writeEs5EnabledSetting),
      );
      expect(
        midiConnection.transport.sent[13],
        orderedEquals(Ntx8cvSysExFixtures.readEs5EnabledSetting),
      );
    });

    test(
      'confirms a Channel Group only after matching readback and manual retry',
      () async {
        var reportedChannelGroup = Ntx8cvChannelGroup.channels1To8.value;
        midiConnection.transport.onSend = (packet) {
          _respondWithSettings(
            midiConnection.transport,
            packet,
            channelGroupValue: reportedChannelGroup,
          );
        };
        await connectionCubit.initialize();
        await connectionCubit.connect();
        await _flushEvents();

        await settingsCubit.setChannelGroup(Ntx8cvChannelGroup.channels57To64);

        expect(
          settingsCubit.state.confirmedChannelGroup,
          Ntx8cvChannelGroup.channels1To8,
        );
        expect(
          settingsCubit.state.attemptedChannelGroup,
          Ntx8cvChannelGroup.channels57To64,
        );
        expect(settingsCubit.state.hasPendingChannelGroupChange, isTrue);
        expect(settingsCubit.state.channelGroupMessage, contains('uncertain'));
        expect(
          midiConnection.transport.sent[12],
          orderedEquals(Ntx8cvSysExFixtures.writeChannelGroupSetting),
        );
        expect(
          midiConnection.transport.sent[13],
          orderedEquals(Ntx8cvSysExFixtures.readChannelGroupSetting),
        );

        reportedChannelGroup = Ntx8cvChannelGroup.channels57To64.value;
        await settingsCubit.retryChannelGroupChange();

        expect(
          settingsCubit.state.confirmedChannelGroup,
          Ntx8cvChannelGroup.channels57To64,
        );
        expect(settingsCubit.state.hasPendingChannelGroupChange, isFalse);
        expect(settingsCubit.state.modeRebootRequired, isFalse);
      },
    );

    test(
      'retains a mismatched ES-5 change across reconnect and retries only explicitly',
      () async {
        var returnEnabledValue = false;
        midiConnection.transport.onSend = (packet) {
          _respondWithSettings(
            midiConnection.transport,
            packet,
            es5Value: returnEnabledValue ? 1 : 0,
          );
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
        // Reconnect validates identity and reads Mode, all audio channels,
        // and Channel Group, but never resends the pending ES-5 change.
        expect(
          midiConnection.transport.sent,
          hasLength(sendsBeforeReconnect + 11),
        );
        expect(midiConnection.transport.sent[sendsBeforeReconnect][5], 2);
        expect(midiConnection.transport.sent[sendsBeforeReconnect][6], 0x22);
        expect(midiConnection.transport.sent[sendsBeforeReconnect + 1][5], 2);
        expect(
          midiConnection.transport.sent[sendsBeforeReconnect + 1][6],
          0x31,
        );
        expect(
          midiConnection.transport.sent[sendsBeforeReconnect + 1][7],
          0x1B,
        );
        expect(midiConnection.transport.sent.last[5], 2);
        expect(midiConnection.transport.sent.last[6], 0x31);
        expect(midiConnection.transport.sent.last[7], 0x00);
        expect(
          midiConnection.transport.sent
              .sublist(sendsBeforeReconnect + 2, sendsBeforeReconnect + 10)
              .map((packet) => packet[7]),
          orderedEquals([0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0A, 0x0B]),
        );

        returnEnabledValue = true;
        await settingsCubit.retryEs5Change();

        expect(settingsCubit.state.confirmedEs5Enabled, isTrue);
        expect(settingsCubit.state.hasPendingEs5Change, isFalse);
        expect(settingsCubit.state.modeRebootRequired, isFalse);
        expect(
          midiConnection.transport.sent,
          hasLength(sendsBeforeReconnect + 13),
        );
        expect(midiConnection.transport.sent[sendsBeforeReconnect + 11][5], 2);
        expect(
          midiConnection.transport.sent[sendsBeforeReconnect + 11][6],
          0x32,
        );
        expect(midiConnection.transport.sent[sendsBeforeReconnect + 12][5], 2);
        expect(
          midiConnection.transport.sent[sendsBeforeReconnect + 12][6],
          0x31,
        );
      },
    );

    test(
      'keeps a timed-out ES-5 write pending and labels it uncertain',
      () async {
        var hasStartedWrite = false;
        midiConnection.transport.onSend = (packet) {
          if (packet[6] == 0x32 && packet[7] == 0x01) {
            hasStartedWrite = true;
            return;
          }
          if (packet[6] == 0x31 && packet[7] == 0x01 && hasStartedWrite) {
            return;
          }
          _respondWithSettings(midiConnection.transport, packet);
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
          if (packet[6] == 0x32 && packet[7] == 0x01) {
            hasStartedWrite = true;
            return;
          }
          if (packet[6] == 0x31 && packet[7] == 0x01 && hasStartedWrite) {
            return;
          }
          _respondWithSettings(midiConnection.transport, packet);
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

    test(
      'keeps Mode disabled when its capability probe is not evidenced',
      () async {
        midiConnection.transport.onSend = (packet) {
          _respondWithSettings(midiConnection.transport, packet, modeValue: 3);
        };
        await connectionCubit.initialize();
        await connectionCubit.connect();
        await _flushEvents();

        expect(settingsCubit.state.modeCapabilityEvidenced, isFalse);
        expect(settingsCubit.state.confirmedMode, isNull);
        expect(settingsCubit.state.modeMessage, contains('not evidenced'));

        final sendsBeforeModeChange = midiConnection.transport.sent.length;
        await settingsCubit.setExpansionMode(Ntx8cvExpansionMode.cv8x8);
        expect(midiConnection.transport.sent, hasLength(sendsBeforeModeChange));
      },
    );

    test(
      'reports a timed-out Mode probe as capability not evidenced',
      () async {
        midiConnection.transport.onSend = (packet) {
          if (packet[6] == 0x22 || (packet[6] == 0x31 && packet[7] == 0x01)) {
            _respondWithSettings(midiConnection.transport, packet);
          }
        };
        await connectionCubit.initialize();
        await connectionCubit.connect();
        await Future<void>.delayed(const Duration(milliseconds: 20));

        expect(settingsCubit.state.modeCapabilityEvidenced, isFalse);
        expect(settingsCubit.state.isLoadingMode, isFalse);
        expect(settingsCubit.state.modeMessage, contains('not evidenced'));
      },
    );

    test('confirms every supported Mode without changing ES-5', () async {
      var deviceMode = Ntx8cvExpansionMode.cv8x8.value;
      midiConnection.transport.onSend = (packet) {
        if (packet[6] == 0x32 && packet[7] == 0x1B) {
          deviceMode = packet[8];
        }
        _respondWithSettings(
          midiConnection.transport,
          packet,
          es5Value: 1,
          modeValue: deviceMode,
        );
      };
      await connectionCubit.initialize();
      await connectionCubit.connect();
      await _flushEvents();

      expect(
        Ntx8cvExpansionMode.values.map((mode) => mode.label),
        orderedEquals(['8x8 CV', '1x8 32bit Audio', '2x8 16bit Audio']),
      );
      expect(
        Ntx8cvExpansionMode.values.map((mode) => mode.value),
        orderedEquals([0, 1, 2]),
      );

      for (final mode in [
        Ntx8cvExpansionMode.audio1x8_32bit,
        Ntx8cvExpansionMode.audio2x8_16bit,
        Ntx8cvExpansionMode.cv8x8,
      ]) {
        await settingsCubit.setExpansionMode(mode);

        expect(settingsCubit.state.confirmedMode, mode);
        expect(settingsCubit.state.hasPendingModeChange, isFalse);
        expect(settingsCubit.state.modeRebootRequired, isTrue);
        expect(settingsCubit.state.confirmedEs5Enabled, isTrue);
        expect(settingsCubit.state.hasPendingEs5Change, isFalse);
      }

      final settingWrites = midiConnection.transport.sent
          .where((packet) => packet[6] == 0x32)
          .toList();
      expect(
        settingWrites.map((packet) => packet[7]),
        orderedEquals([0x1B, 0x1B, 0x1B]),
      );
      expect(
        settingWrites.map((packet) => packet[8]),
        orderedEquals([1, 2, 0]),
      );
    });

    test(
      'confirms a retried Mode change only after matching readback and requires reboot',
      () async {
        var returnedModeValue = 2;
        midiConnection.transport.onSend = (packet) {
          _respondWithSettings(
            midiConnection.transport,
            packet,
            modeValue: returnedModeValue,
          );
        };
        await connectionCubit.initialize();
        await connectionCubit.connect();
        await _flushEvents();

        await settingsCubit.setExpansionMode(Ntx8cvExpansionMode.cv8x8);

        expect(
          settingsCubit.state.confirmedMode,
          Ntx8cvExpansionMode.audio2x8_16bit,
        );
        expect(settingsCubit.state.attemptedMode, Ntx8cvExpansionMode.cv8x8);
        expect(settingsCubit.state.modeRebootRequired, isFalse);
        expect(settingsCubit.state.modeMessage, contains('not confirmed'));
        expect(settingsCubit.state.modeMessage, contains('uncertain'));

        await connectionCubit.disconnect();
        final sendsBeforeReconnect = midiConnection.transport.sent.length;
        await connectionCubit.connect();
        await _flushEvents();

        expect(settingsCubit.state.hasPendingModeChange, isTrue);
        // Reconnect reads ES-5, Mode, all audio channels, and Channel Group
        // but does not write a pending Mode.
        expect(
          midiConnection.transport.sent,
          hasLength(sendsBeforeReconnect + 12),
        );
        expect(
          midiConnection.transport.sent.where((packet) => packet[6] == 0x32),
          hasLength(1),
        );

        returnedModeValue = 0;
        await settingsCubit.retryModeChange();

        expect(settingsCubit.state.confirmedMode, Ntx8cvExpansionMode.cv8x8);
        expect(settingsCubit.state.hasPendingModeChange, isFalse);
        expect(settingsCubit.state.modeRebootRequired, isTrue);
        expect(settingsCubit.state.confirmedEs5Enabled, isFalse);
        expect(
          midiConnection.transport.sent[midiConnection.transport.sent.length -
              2],
          orderedEquals(_writeSetting(0x1B, 0)),
        );
        expect(
          midiConnection.transport.sent.last,
          orderedEquals(Ntx8cvSysExFixtures.readModeSetting),
        );
      },
    );
  });
}

void _respondWithSettings(
  _FakeNtx8cvMidiTransport transport,
  Uint8List packet, {
  int channelGroupValue = 0,
  int es5Value = 0,
  int modeValue = 2,
  List<int> audioChannelValues = const [1, 0, 1, 0, 1, 0, 1, 0],
}) {
  final deviceId = packet[5];
  if (packet[6] == 0x22) {
    transport.receive(
      _withDeviceId(Ntx8cvSysExFixtures.deviceInformationResponse, deviceId),
    );
  } else if (packet[6] == 0x31 && packet[7] == 0x00) {
    transport.receive(_settingResponse(0x00, channelGroupValue, deviceId));
  } else if (packet[6] == 0x31 && packet[7] == 0x01) {
    transport.receive(_settingResponse(0x01, es5Value, deviceId));
  } else if (packet[6] == 0x31 && packet[7] >= 0x04 && packet[7] <= 0x0B) {
    transport.receive(
      _settingResponse(
        packet[7],
        audioChannelValues[packet[7] - 0x04],
        deviceId,
      ),
    );
  } else if (packet[6] == 0x31 && packet[7] == 0x1B) {
    transport.receive(_settingResponse(0x1B, modeValue, deviceId));
  }
}

Future<void> _flushEvents() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

Uint8List _readSetting(int settingId, [int deviceId = 0]) => Uint8List.fromList(
  [0xF0, 0x00, 0x21, 0x27, 0x6A, deviceId, 0x31, settingId, 0xF7],
);

Uint8List _writeSetting(int settingId, int value, [int deviceId = 0]) =>
    Uint8List.fromList([
      0xF0,
      0x00,
      0x21,
      0x27,
      0x6A,
      deviceId,
      0x32,
      settingId,
      value,
      0xF7,
    ]);

Uint8List _settingResponse(int settingId, int value, [int deviceId = 0]) =>
    Uint8List.fromList([
      0xF0,
      0x00,
      0x21,
      0x27,
      0x6A,
      deviceId,
      0x31,
      settingId,
      value,
      0xF7,
    ]);

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
  int openCount = 0;
  int closeCount = 0;

  @override
  Stream<MidiSetupChange>? get setupChanges => null;

  @override
  Future<List<MidiDevice>> listDevices() async => List.of(devices);

  @override
  Future<Ntx8cvMidiTransport> open({
    required MidiDevice inputDevice,
    required MidiDevice outputDevice,
  }) async {
    openCount += 1;
    return transport;
  }

  @override
  Future<void> close({
    required Ntx8cvMidiTransport transport,
    required MidiDevice inputDevice,
    required MidiDevice outputDevice,
  }) async {
    closeCount += 1;
  }

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
