import 'dart:async';
import 'dart:typed_data';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/domain/ntx_8cv/ntx_8cv_sysex.dart';

import '../../fixtures/ntx_8cv_sysex_fixtures.dart';

void main() {
  const codec = Ntx8cvSysExCodec();

  group('NTX-8CV documented packet fixtures', () {
    test(
      'encodes device information, setting read/write, and reboot frames',
      () {
        expect(
          codec.requestDeviceInformation(deviceId: 0),
          orderedEquals(Ntx8cvSysExFixtures.deviceInformationRequest),
        );
        expect(
          codec.readSetting(deviceId: 0, settingId: 0x00),
          orderedEquals(Ntx8cvSysExFixtures.readChannelGroupSetting),
        );
        expect(
          codec.writeSetting(deviceId: 0, settingId: 0x00, value: 7),
          orderedEquals(Ntx8cvSysExFixtures.writeChannelGroupSetting),
        );
        expect(
          codec.readSetting(deviceId: 0, settingId: 0x01),
          orderedEquals(Ntx8cvSysExFixtures.readEs5EnabledSetting),
        );
        expect(
          codec.writeSetting(deviceId: 0, settingId: 0x01, value: 1),
          orderedEquals(Ntx8cvSysExFixtures.writeEs5EnabledSetting),
        );
        expect(
          codec.readSetting(deviceId: 0, settingId: 0x04),
          orderedEquals(Ntx8cvSysExFixtures.readAudioChannel1EnabledSetting),
        );
        expect(
          codec.writeSetting(deviceId: 0, settingId: 0x04, value: 0),
          orderedEquals(Ntx8cvSysExFixtures.writeAudioChannel1DisabledSetting),
        );
        expect(
          codec.readSetting(deviceId: 0, settingId: 0x1B),
          orderedEquals(Ntx8cvSysExFixtures.readModeSetting),
        );
        expect(
          codec.writeSetting(deviceId: 0, settingId: 0x1B, value: 2),
          orderedEquals(Ntx8cvSysExFixtures.writeModeSetting),
        );
        expect(
          codec.reboot(deviceId: 0),
          orderedEquals(Ntx8cvSysExFixtures.reboot),
        );
      },
    );

    test('decodes a complete device-information response', () {
      final decoded = codec.decode(
        Ntx8cvSysExFixtures.deviceInformationResponse,
      );

      expect(decoded, isA<Ntx8cvDeviceInformation>());
      final information = decoded! as Ntx8cvDeviceInformation;
      expect(information.deviceId, 0);
      expect(information.firmwareText, 'fixture-firmware');
      expect(information.serialText, 'fixture-serial');
      expect(information.textFields, ['fixture-firmware', 'fixture-serial']);
    });

    test(
      'decodes complete Channel Group, ES-5, audio-channel, and mode setting responses',
      () {
        final channelGroup = codec.decode(
          Ntx8cvSysExFixtures.channelGroupResponse,
        );
        final es5 = codec.decode(Ntx8cvSysExFixtures.es5EnabledResponse);
        final audioChannel = codec.decode(
          Ntx8cvSysExFixtures.audioChannel1EnabledResponse,
        );
        final mode = codec.decode(Ntx8cvSysExFixtures.modeSettingResponse);

        expect(channelGroup, isA<Ntx8cvSettingValue>());
        final channelGroupSetting = channelGroup! as Ntx8cvSettingValue;
        expect(channelGroupSetting.deviceId, 0);
        expect(channelGroupSetting.settingId, 0x00);
        expect(channelGroupSetting.value, 7);

        expect(es5, isA<Ntx8cvSettingValue>());
        final es5Setting = es5! as Ntx8cvSettingValue;
        expect(es5Setting.deviceId, 0);
        expect(es5Setting.settingId, 0x01);
        expect(es5Setting.value, 1);

        expect(audioChannel, isA<Ntx8cvSettingValue>());
        final audioChannelSetting = audioChannel! as Ntx8cvSettingValue;
        expect(audioChannelSetting.deviceId, 0);
        expect(audioChannelSetting.settingId, 0x04);
        expect(audioChannelSetting.value, 1);

        expect(mode, isA<Ntx8cvSettingValue>());
        final modeSetting = mode! as Ntx8cvSettingValue;
        expect(modeSetting.deviceId, 0);
        expect(modeSetting.settingId, 0x1B);
        expect(modeSetting.value, 2);
      },
    );

    test('rejects malformed, wrong-product, and incomplete responses', () {
      expect(codec.decode(Ntx8cvSysExFixtures.malformedWrongProduct), isNull);
      expect(
        codec.decode(Ntx8cvSysExFixtures.malformedSettingResponse),
        isNull,
      );
      expect(
        codec.decode(Ntx8cvSysExFixtures.malformedInformationResponse),
        isNull,
      );
      expect(
        codec.decode(
          Uint8List.fromList([
            0xF0,
            0x00,
            0x21,
            0x27,
            0x6A,
            0x00,
            0x31,
            0x1B,
            0x02,
            0x01,
            0xF7,
          ]),
        ),
        isNull,
      );
    });

    test('rejects values outside the MIDI 7-bit range when encoding', () {
      expect(
        () => codec.readSetting(deviceId: 128, settingId: 0x1B),
        throwsArgumentError,
      );
      expect(
        () => codec.writeSetting(deviceId: 0, settingId: -1, value: 2),
        throwsArgumentError,
      );
      expect(
        () => codec.writeSetting(deviceId: 0, settingId: 0x1B, value: 128),
        throwsArgumentError,
      );
    });
  });

  group('NTX-8CV session', () {
    late _FakeNtx8cvMidiTransport transport;
    late Ntx8cvSession session;

    setUp(() {
      transport = _FakeNtx8cvMidiTransport();
      session = Ntx8cvSession(
        transport: transport,
        deviceId: 0,
        timeout: const Duration(seconds: 1),
      );
    });

    tearDown(() async {
      await session.close();
      await transport.close();
    });

    test('matches device information only from the selected NTX-8CV', () async {
      final response = session.requestDeviceInformation();

      expect(
        transport.sent.single,
        orderedEquals(Ntx8cvSysExFixtures.deviceInformationRequest),
      );

      transport.receive(
        Uint8List.fromList([
          0xF0,
          0x00,
          0x21,
          0x27,
          0x6A,
          0x01,
          0x32,
          0x00,
          0x00,
          0xF7,
        ]),
      );
      await Future<void>.delayed(Duration.zero);
      expect(transport.sent, hasLength(1));

      transport.receive(Ntx8cvSysExFixtures.deviceInformationResponse);
      expect((await response).serialText, 'fixture-serial');
    });

    test(
      'writes then requires matching setting readback for confirmation',
      () async {
        final confirmation = session.writeAndConfirmSetting(
          settingId: 0x1B,
          value: 2,
        );

        expect(
          transport.sent.single,
          orderedEquals(Ntx8cvSysExFixtures.writeModeSetting),
        );
        await _flushMicrotasks();
        expect(
          transport.sent[1],
          orderedEquals(Ntx8cvSysExFixtures.readModeSetting),
        );

        transport.receive(Ntx8cvSysExFixtures.modeSettingResponse);
        expect((await confirmation).value, 2);
      },
    );

    test(
      'rejects a setting confirmation when readback does not match',
      () async {
        final confirmation = session.writeAndConfirmSetting(
          settingId: 0x1B,
          value: 2,
        );
        await _flushMicrotasks();

        transport.receive(
          Uint8List.fromList([
            0xF0,
            0x00,
            0x21,
            0x27,
            0x6A,
            0x00,
            0x31,
            0x1B,
            0x01,
            0xF7,
          ]),
        );

        await expectLater(confirmation, throwsA(isA<StateError>()));
      },
    );

    test('reports a malformed response from the selected device', () async {
      final confirmation = session.writeAndConfirmSetting(
        settingId: 0x1B,
        value: 2,
      );
      await _flushMicrotasks();

      transport.receive(Ntx8cvSysExFixtures.malformedSettingResponse);

      await expectLater(
        confirmation,
        throwsA(isA<Ntx8cvMalformedResponseException>()),
      );
    });

    test('reports a configurable timeout when a response is absent', () {
      fakeAsync((async) {
        Object? failure;
        final timeoutSession = Ntx8cvSession(
          transport: transport,
          deviceId: 0,
          timeout: const Duration(milliseconds: 25),
        );

        () async {
          try {
            await timeoutSession.readSetting(settingId: 0x1B);
          } catch (error) {
            failure = error;
          }
        }();

        async.flushMicrotasks();
        async.elapse(const Duration(milliseconds: 25));
        async.flushMicrotasks();

        expect(failure, isA<Ntx8cvTimeoutException>());
        final timeout = failure! as Ntx8cvTimeoutException;
        expect(timeout.operation, 'read setting 0x1B');
        expect(timeout.timeout, const Duration(milliseconds: 25));
        timeoutSession.close();
      });
    });
  });
}

Future<void> _flushMicrotasks() async {
  await Future<void>.value();
  await Future<void>.value();
}

class _FakeNtx8cvMidiTransport implements Ntx8cvMidiTransport {
  final StreamController<Uint8List> _received =
      StreamController<Uint8List>.broadcast(sync: true);
  final List<Uint8List> sent = [];

  @override
  Stream<Uint8List> get receivedPackets => _received.stream;

  @override
  Future<void> send(Uint8List packet) async {
    sent.add(packet);
  }

  void receive(Uint8List packet) => _received.add(packet);

  Future<void> close() => _received.close();
}
