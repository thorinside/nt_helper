import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/domain/sysex/responses/parameter_info_response.dart';
import 'package:nt_helper/domain/disting_nt_sysex.dart';
import 'dart:typed_data';

void main() {
  group('ParameterInfoResponse powerOfTen extraction', () {
    test('extracts powerOfTen=0 from last byte 0x00', () {
      // Last byte = 0x00: powerOfTen = 0x00 & 0x3 = 0
      final data = Uint8List.fromList([
        0x01, // algorithmIndex
        0x00, 0x05, // parameterNumber (5)
        0x00, // padding
        0x00, 0x00, // min (0)
        0x00, // padding
        0x00, 0x64, // max (100)
        0x00, // padding
        0x00, 0x32, // defaultValue (50)
        0x00, // padding
        0x00, // unit
        0x54, 0x65, 0x73, 0x74, 0x00, // name: "Test\0"
        0x00, // last byte: powerOfTen=0, ioFlags=0
      ]);
      final response = ParameterInfoResponse(data);
      final result = response.parse();

      expect(result.powerOfTen, 0);
    });

    test('extracts powerOfTen=1 from last byte 0x01', () {
      // Last byte = 0x01: powerOfTen = 0x01 & 0x3 = 1
      final data = Uint8List.fromList([
        0x01, 0x00, 0x05, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x64, 0x00, 0x00, 0x32, 0x00, 0x00,
        0x54, 0x65, 0x73, 0x74, 0x00,
        0x01, // last byte: powerOfTen=1, ioFlags=0
      ]);
      final response = ParameterInfoResponse(data);
      final result = response.parse();

      expect(result.powerOfTen, 1);
    });

    test('extracts powerOfTen=2 from last byte 0x02', () {
      // Last byte = 0x02: powerOfTen = 0x02 & 0x3 = 2
      final data = Uint8List.fromList([
        0x01, 0x00, 0x05, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x64, 0x00, 0x00, 0x32, 0x00, 0x00,
        0x54, 0x65, 0x73, 0x74, 0x00,
        0x02, // last byte: powerOfTen=2, ioFlags=0
      ]);
      final response = ParameterInfoResponse(data);
      final result = response.parse();

      expect(result.powerOfTen, 2);
    });

    test('extracts powerOfTen=3 from last byte 0x03', () {
      // Last byte = 0x03: powerOfTen = 0x03 & 0x3 = 3
      final data = Uint8List.fromList([
        0x01, 0x00, 0x05, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x64, 0x00, 0x00, 0x32, 0x00, 0x00,
        0x54, 0x65, 0x73, 0x74, 0x00,
        0x03, // last byte: powerOfTen=3, ioFlags=0
      ]);
      final response = ParameterInfoResponse(data);
      final result = response.parse();

      expect(result.powerOfTen, 3);
    });
  });

  group('ParameterInfoResponse ioFlags extraction', () {
    test('extracts ioFlags=0 from last byte 0x00', () {
      // Last byte = 0x00: ioFlags = (0x00 >> 2) & 0xF = 0
      final data = Uint8List.fromList([
        0x01, 0x00, 0x05, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x64, 0x00, 0x00, 0x32, 0x00, 0x00,
        0x54, 0x65, 0x73, 0x74, 0x00,
        0x00, // last byte: powerOfTen=0, ioFlags=0
      ]);
      final response = ParameterInfoResponse(data);
      final result = response.parse();

      expect(result.ioFlags, 0);
      expect(result.isInput, false);
      expect(result.isOutput, false);
      expect(result.isAudio, false);
      expect(result.isOutputMode, false);
    });

    test('extracts ioFlags=1 (input) from last byte 0x04', () {
      // Last byte = 0x04: ioFlags = (0x04 >> 2) & 0xF = 1
      final data = Uint8List.fromList([
        0x01, 0x00, 0x05, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x64, 0x00, 0x00, 0x32, 0x00, 0x00,
        0x54, 0x65, 0x73, 0x74, 0x00,
        0x04, // last byte: powerOfTen=0, ioFlags=1 (isInput)
      ]);
      final response = ParameterInfoResponse(data);
      final result = response.parse();

      expect(result.ioFlags, 1);
      expect(result.isInput, true);
      expect(result.isOutput, false);
      expect(result.isAudio, false);
      expect(result.isOutputMode, false);
    });

    test('extracts ioFlags=2 (output) from last byte 0x08', () {
      // Last byte = 0x08: ioFlags = (0x08 >> 2) & 0xF = 2
      final data = Uint8List.fromList([
        0x01, 0x00, 0x05, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x64, 0x00, 0x00, 0x32, 0x00, 0x00,
        0x54, 0x65, 0x73, 0x74, 0x00,
        0x08, // last byte: powerOfTen=0, ioFlags=2 (isOutput)
      ]);
      final response = ParameterInfoResponse(data);
      final result = response.parse();

      expect(result.ioFlags, 2);
      expect(result.isInput, false);
      expect(result.isOutput, true);
      expect(result.isAudio, false);
      expect(result.isOutputMode, false);
    });

    test('extracts ioFlags=4 (audio) from last byte 0x10', () {
      // Last byte = 0x10: ioFlags = (0x10 >> 2) & 0xF = 4
      final data = Uint8List.fromList([
        0x01, 0x00, 0x05, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x64, 0x00, 0x00, 0x32, 0x00, 0x00,
        0x54, 0x65, 0x73, 0x74, 0x00,
        0x10, // last byte: powerOfTen=0, ioFlags=4 (isAudio)
      ]);
      final response = ParameterInfoResponse(data);
      final result = response.parse();

      expect(result.ioFlags, 4);
      expect(result.isInput, false);
      expect(result.isOutput, false);
      expect(result.isAudio, true);
      expect(result.isOutputMode, false);
    });

    test('extracts ioFlags=8 (output mode) from last byte 0x20', () {
      // Last byte = 0x20: ioFlags = (0x20 >> 2) & 0xF = 8
      final data = Uint8List.fromList([
        0x01, 0x00, 0x05, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x64, 0x00, 0x00, 0x32, 0x00, 0x00,
        0x54, 0x65, 0x73, 0x74, 0x00,
        0x20, // last byte: powerOfTen=0, ioFlags=8 (isOutputMode)
      ]);
      final response = ParameterInfoResponse(data);
      final result = response.parse();

      expect(result.ioFlags, 8);
      expect(result.isInput, false);
      expect(result.isOutput, false);
      expect(result.isAudio, false);
      expect(result.isOutputMode, true);
    });

    test('extracts ioFlags=15 (all flags set) from last byte 0x3C', () {
      // Last byte = 0x3C: ioFlags = (0x3C >> 2) & 0xF = 15
      final data = Uint8List.fromList([
        0x01, 0x00, 0x05, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x64, 0x00, 0x00, 0x32, 0x00, 0x00,
        0x54, 0x65, 0x73, 0x74, 0x00,
        0x3C, // last byte: powerOfTen=0, ioFlags=15 (all flags)
      ]);
      final response = ParameterInfoResponse(data);
      final result = response.parse();

      expect(result.ioFlags, 15);
      expect(result.isInput, true);
      expect(result.isOutput, true);
      expect(result.isAudio, true);
      expect(result.isOutputMode, true);
    });
  });

  group('ParameterInfoResponse combined extraction', () {
    test('extracts powerOfTen=1 and ioFlags=5 from last byte 0x15', () {
      // Last byte = 0x15:
      //   powerOfTen = 0x15 & 0x3 = 1
      //   ioFlags = (0x15 >> 2) & 0xF = 5 (input + audio)
      final data = Uint8List.fromList([
        0x01, 0x00, 0x05, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x64, 0x00, 0x00, 0x32, 0x00, 0x00,
        0x54, 0x65, 0x73, 0x74, 0x00,
        0x15, // last byte: powerOfTen=1, ioFlags=5
      ]);
      final response = ParameterInfoResponse(data);
      final result = response.parse();

      expect(result.powerOfTen, 1);
      expect(result.ioFlags, 5);
      expect(result.isInput, true);  // bit 0 set
      expect(result.isOutput, false); // bit 1 not set
      expect(result.isAudio, true);   // bit 2 set
      expect(result.isOutputMode, false); // bit 3 not set
    });

    test('extracts powerOfTen=2 and ioFlags=10 from last byte 0x2A', () {
      // Last byte = 0x2A:
      //   powerOfTen = 0x2A & 0x3 = 2
      //   ioFlags = (0x2A >> 2) & 0xF = 10 (output + output mode)
      final data = Uint8List.fromList([
        0x01, 0x00, 0x05, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x64, 0x00, 0x00, 0x32, 0x00, 0x00,
        0x54, 0x65, 0x73, 0x74, 0x00,
        0x2A, // last byte: powerOfTen=2, ioFlags=10
      ]);
      final response = ParameterInfoResponse(data);
      final result = response.parse();

      expect(result.powerOfTen, 2);
      expect(result.ioFlags, 10);
      expect(result.isInput, false);  // bit 0 not set
      expect(result.isOutput, true);  // bit 1 set
      expect(result.isAudio, false);  // bit 2 not set
      expect(result.isOutputMode, true); // bit 3 set
    });
  });

  group('ParameterInfo equality with ioFlags', () {
    test('two ParameterInfos with same ioFlags are equal', () {
      final info1 = ParameterInfo(
        algorithmIndex: 0,
        parameterNumber: 5,
        min: 0,
        max: 100,
        defaultValue: 50,
        unit: 0,
        name: 'Test',
        powerOfTen: 1,
        ioFlags: 5,
      );
      final info2 = ParameterInfo(
        algorithmIndex: 0,
        parameterNumber: 5,
        min: 0,
        max: 100,
        defaultValue: 50,
        unit: 0,
        name: 'Test',
        powerOfTen: 1,
        ioFlags: 5,
      );

      expect(info1, equals(info2));
      expect(info1.hashCode, equals(info2.hashCode));
    });

    test('two ParameterInfos with different ioFlags are not equal', () {
      final info1 = ParameterInfo(
        algorithmIndex: 0,
        parameterNumber: 5,
        min: 0,
        max: 100,
        defaultValue: 50,
        unit: 0,
        name: 'Test',
        powerOfTen: 1,
        ioFlags: 5,
      );
      final info2 = ParameterInfo(
        algorithmIndex: 0,
        parameterNumber: 5,
        min: 0,
        max: 100,
        defaultValue: 50,
        unit: 0,
        name: 'Test',
        powerOfTen: 1,
        ioFlags: 10,
      );

      expect(info1, isNot(equals(info2)));
      expect(info1.hashCode, isNot(equals(info2.hashCode)));
    });
  });

  group('ParameterInfo helper getters', () {
    test('isInput returns correct boolean for each flag bit', () {
      final flagsInput = ParameterInfo(
        algorithmIndex: 0,
        parameterNumber: 0,
        min: 0,
        max: 100,
        defaultValue: 50,
        unit: 0,
        name: 'Test',
        powerOfTen: 0,
        ioFlags: 1, // bit 0 set
      );
      final flagsNoInput = ParameterInfo(
        algorithmIndex: 0,
        parameterNumber: 0,
        min: 0,
        max: 100,
        defaultValue: 50,
        unit: 0,
        name: 'Test',
        powerOfTen: 0,
        ioFlags: 0, // bit 0 not set
      );

      expect(flagsInput.isInput, true);
      expect(flagsNoInput.isInput, false);
    });

    test('isOutput returns correct boolean for each flag bit', () {
      final flagsOutput = ParameterInfo(
        algorithmIndex: 0,
        parameterNumber: 0,
        min: 0,
        max: 100,
        defaultValue: 50,
        unit: 0,
        name: 'Test',
        powerOfTen: 0,
        ioFlags: 2, // bit 1 set
      );
      final flagsNoOutput = ParameterInfo(
        algorithmIndex: 0,
        parameterNumber: 0,
        min: 0,
        max: 100,
        defaultValue: 50,
        unit: 0,
        name: 'Test',
        powerOfTen: 0,
        ioFlags: 0, // bit 1 not set
      );

      expect(flagsOutput.isOutput, true);
      expect(flagsNoOutput.isOutput, false);
    });

    test('isAudio returns correct boolean for each flag bit', () {
      final flagsAudio = ParameterInfo(
        algorithmIndex: 0,
        parameterNumber: 0,
        min: 0,
        max: 100,
        defaultValue: 50,
        unit: 0,
        name: 'Test',
        powerOfTen: 0,
        ioFlags: 4, // bit 2 set
      );
      final flagsNoAudio = ParameterInfo(
        algorithmIndex: 0,
        parameterNumber: 0,
        min: 0,
        max: 100,
        defaultValue: 50,
        unit: 0,
        name: 'Test',
        powerOfTen: 0,
        ioFlags: 0, // bit 2 not set
      );

      expect(flagsAudio.isAudio, true);
      expect(flagsNoAudio.isAudio, false);
    });

    test('isOutputMode returns correct boolean for each flag bit', () {
      final flagsOutputMode = ParameterInfo(
        algorithmIndex: 0,
        parameterNumber: 0,
        min: 0,
        max: 100,
        defaultValue: 50,
        unit: 0,
        name: 'Test',
        powerOfTen: 0,
        ioFlags: 8, // bit 3 set
      );
      final flagsNoOutputMode = ParameterInfo(
        algorithmIndex: 0,
        parameterNumber: 0,
        min: 0,
        max: 100,
        defaultValue: 50,
        unit: 0,
        name: 'Test',
        powerOfTen: 0,
        ioFlags: 0, // bit 3 not set
      );

      expect(flagsOutputMode.isOutputMode, true);
      expect(flagsNoOutputMode.isOutputMode, false);
    });
  });

  group('ParameterInfo offline/default behavior', () {
    test('ParameterInfo defaults to ioFlags=0 when not specified', () {
      final info = ParameterInfo(
        algorithmIndex: 0,
        parameterNumber: 5,
        min: 0,
        max: 100,
        defaultValue: 50,
        unit: 0,
        name: 'Test',
        powerOfTen: 1,
      );

      expect(info.ioFlags, 0);
      expect(info.isInput, false);
      expect(info.isOutput, false);
      expect(info.isAudio, false);
      expect(info.isOutputMode, false);
    });

    test('ParameterInfo.filler() defaults to ioFlags=0', () {
      final info = ParameterInfo.filler();

      expect(info.ioFlags, 0);
      expect(info.isInput, false);
      expect(info.isOutput, false);
      expect(info.isAudio, false);
      expect(info.isOutputMode, false);
    });
  });

  group('ParameterInfo toString includes ioFlags', () {
    test('toString includes ioFlags value', () {
      final info = ParameterInfo(
        algorithmIndex: 0,
        parameterNumber: 5,
        min: 0,
        max: 100,
        defaultValue: 50,
        unit: 0,
        name: 'Test',
        powerOfTen: 1,
        ioFlags: 5,
      );

      final str = info.toString();
      expect(str, contains('ioFlags=5'));
    });
  });
}
