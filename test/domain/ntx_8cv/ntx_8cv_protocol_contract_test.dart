import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/cubit/ntx_8cv_settings_cubit.dart';
import 'package:nt_helper/domain/ntx_8cv/ntx_8cv_sysex.dart';

/// Protocol source:
/// `expertsleepersltd/NTX-8CV@6addf424c454aac20b26661d00384e6292401b18`
/// `tools/ntx8cv_config_tool.html`.
void main() {
  const codec = Ntx8cvSysExCodec();

  test('matches every exposed NTX-8CV main-branch setting and value', () {
    const contract = <Ntx8cvSetting, ({int id, List<int> values})>{
      Ntx8cvSetting.channelGroup: (id: 0x00, values: [0, 1, 2, 3, 4, 5, 6, 7]),
      Ntx8cvSetting.es5Enabled: (id: 0x01, values: [0, 1]),
      Ntx8cvSetting.usbAudioChannel1: (id: 0x04, values: [0, 1]),
      Ntx8cvSetting.usbAudioChannel2: (id: 0x05, values: [0, 1]),
      Ntx8cvSetting.usbAudioChannel3: (id: 0x06, values: [0, 1]),
      Ntx8cvSetting.usbAudioChannel4: (id: 0x07, values: [0, 1]),
      Ntx8cvSetting.usbAudioChannel5: (id: 0x08, values: [0, 1]),
      Ntx8cvSetting.usbAudioChannel6: (id: 0x09, values: [0, 1]),
      Ntx8cvSetting.usbAudioChannel7: (id: 0x0A, values: [0, 1]),
      Ntx8cvSetting.usbAudioChannel8: (id: 0x0B, values: [0, 1]),
      Ntx8cvSetting.usbHostEnabled: (id: 0x17, values: [0, 1]),
      Ntx8cvSetting.expansionMode: (id: 0x1B, values: [0, 1, 2]),
      Ntx8cvSetting.expanderAudioChannel1: (id: 0x1C, values: [0, 1]),
      Ntx8cvSetting.expanderAudioChannel2: (id: 0x1D, values: [0, 1]),
      Ntx8cvSetting.expanderAudioChannel3: (id: 0x1E, values: [0, 1]),
      Ntx8cvSetting.expanderAudioChannel4: (id: 0x1F, values: [0, 1]),
      Ntx8cvSetting.expanderAudioChannel5: (id: 0x20, values: [0, 1]),
      Ntx8cvSetting.expanderAudioChannel6: (id: 0x21, values: [0, 1]),
      Ntx8cvSetting.expanderAudioChannel7: (id: 0x22, values: [0, 1]),
      Ntx8cvSetting.expanderAudioChannel8: (id: 0x23, values: [0, 1]),
    };

    expect(contract.keys, orderedEquals(Ntx8cvSetting.values));
    for (final entry in contract.entries) {
      expect(entry.key.id, entry.value.id, reason: entry.key.name);
      expect(
        codec.readSetting(deviceId: 0, settingId: entry.value.id),
        orderedEquals(_frame(0x31, [entry.value.id])),
        reason: 'read ${entry.key.name}',
      );
      for (final value in entry.value.values) {
        expect(
          codec.writeSetting(
            deviceId: 0,
            settingId: entry.value.id,
            value: value,
          ),
          orderedEquals(_frame(0x32, [entry.value.id, value])),
          reason: 'write ${entry.key.name}=$value',
        );
      }
    }

    expect(
      Ntx8cvChannelGroup.values.map((value) => value.value),
      orderedEquals([0, 1, 2, 3, 4, 5, 6, 7]),
    );
    expect(
      Ntx8cvExpansionMode.values.map((value) => value.value),
      orderedEquals([0, 1, 2]),
    );
  });

  test('uses exact product framing at the highest persistent device ID', () {
    expect(
      codec.requestDeviceInformation(deviceId: 126),
      orderedEquals(_frame(0x22, const [], deviceId: 126)),
    );
    expect(
      codec.readSetting(deviceId: 126, settingId: 0x1B),
      orderedEquals(_frame(0x31, const [0x1B], deviceId: 126)),
    );
    expect(
      codec.writeSetting(deviceId: 126, settingId: 0x1B, value: 2),
      orderedEquals(_frame(0x32, const [0x1B, 2], deviceId: 126)),
    );
    expect(
      codec.reboot(deviceId: 126),
      orderedEquals(_frame(0x7F, const [], deviceId: 126)),
    );
  });
}

List<int> _frame(int command, List<int> payload, {int deviceId = 0}) => [
  0xF0,
  0x00,
  0x21,
  0x27,
  0x6A,
  deviceId,
  command,
  ...payload,
  0xF7,
];
