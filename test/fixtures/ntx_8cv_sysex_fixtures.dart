import 'dart:typed_data';

/// Deterministic NTX-8CV frames derived from the approved protocol contract.
///
/// The device-information text is deliberately opaque fixture data rather than
/// a claimed firmware or serial-number grammar. Both fields are NUL-terminated
/// ASCII as required by the protocol contract.
abstract final class Ntx8cvSysExFixtures {
  static final Uint8List deviceInformationRequest = Uint8List.fromList([
    0xF0,
    0x00,
    0x21,
    0x27,
    0x6A,
    0x00,
    0x22,
    0xF7,
  ]);

  static final Uint8List deviceInformationResponse = Uint8List.fromList([
    0xF0,
    0x00,
    0x21,
    0x27,
    0x6A,
    0x00,
    0x32,
    ...'fixture-firmware'.codeUnits,
    0x00,
    ...'fixture-serial'.codeUnits,
    0x00,
    0xF7,
  ]);

  static final Uint8List readModeSetting = Uint8List.fromList([
    0xF0,
    0x00,
    0x21,
    0x27,
    0x6A,
    0x00,
    0x31,
    0x1B,
    0xF7,
  ]);

  static final Uint8List modeSettingResponse = Uint8List.fromList([
    0xF0,
    0x00,
    0x21,
    0x27,
    0x6A,
    0x00,
    0x31,
    0x1B,
    0x02,
    0xF7,
  ]);

  static final Uint8List writeModeSetting = Uint8List.fromList([
    0xF0,
    0x00,
    0x21,
    0x27,
    0x6A,
    0x00,
    0x32,
    0x1B,
    0x02,
    0xF7,
  ]);

  static final Uint8List reboot = Uint8List.fromList([
    0xF0,
    0x00,
    0x21,
    0x27,
    0x6A,
    0x00,
    0x7F,
    0xF7,
  ]);

  static final Uint8List malformedWrongProduct = Uint8List.fromList([
    0xF0,
    0x00,
    0x21,
    0x27,
    0x6D,
    0x00,
    0x31,
    0x1B,
    0x02,
    0xF7,
  ]);

  static final Uint8List malformedSettingResponse = Uint8List.fromList([
    0xF0,
    0x00,
    0x21,
    0x27,
    0x6A,
    0x00,
    0x31,
    0x1B,
    0xF7,
  ]);

  static final Uint8List malformedInformationResponse = Uint8List.fromList([
    0xF0,
    0x00,
    0x21,
    0x27,
    0x6A,
    0x00,
    0x32,
    ...'unterminated'.codeUnits,
    0xF7,
  ]);
}
