import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/domain/sysex/requests/set_midi_mapping.dart';
import 'package:nt_helper/domain/sysex/responses/mapping_response.dart';
import 'package:nt_helper/models/packed_mapping_data.dart';

void main() {
  group('14-bit CC SysEx Integration', () {
    test('SetMidiMappingMessage encodes 14-bit CC low type correctly', () {
      final mapping = PackedMappingData(
        source: 1,
        cvInput: 0,
        isUnipolar: true,
        isGate: false,
        volts: 5,
        delta: 100,
        midiChannel: 1,
        midiMappingType: MidiMappingType.cc14BitLow,
        midiCC: 1,
        isMidiEnabled: true,
        isMidiSymmetric: false,
        isMidiRelative: false,
        midiMin: 0,
        midiMax: 16383,
        i2cCC: 0,
        isI2cEnabled: false,
        isI2cSymmetric: false,
        i2cMin: 0,
        i2cMax: 16383,
        perfPageIndex: 0,
        version: 5,
      );

      final message = SetMidiMappingMessage(
        sysExId: 0,
        algorithmIndex: 0,
        parameterNumber: 0,
        data: mapping,
      );

      final encoded = message.encode();

      // SysEx structure:
      // [0xF0] [0x00, 0x21, 0x27] [0x6D] [SysExId] [MessageType] [algorithmIndex] [paramNum 3 bytes] [version] [MIDI payload...] [0xF7]
      // Header: 0xF0, 0x00, 0x21, 0x27, 0x6D (5 bytes)
      // SysExId: 1 byte
      // MessageType: 1 byte
      // AlgorithmIndex: 1 byte
      // ParameterNumber: 3 bytes (encode16)
      // Version: 1 byte
      // MIDI payload starts at byte 12 (only MIDI section, not full PackedMappingData)

      // MIDI section (9 bytes for version >= 2):
      // midiCC: 1 byte (offset 12)
      // midiFlags: 1 byte (offset 13)
      // midiFlags2: 1 byte (offset 14) - contains type
      // midiMin: 3 bytes (offset 15-17)
      // midiMax: 3 bytes (offset 18-20)

      final midiFlags2Offset = 14;
      final midiFlags2 = encoded[midiFlags2Offset];

      // Type 3 (cc14BitLow) should be encoded as (3 << 2) = 0x0C
      expect(midiFlags2 >> 2, equals(3), reason: 'Type value should be 3');
      expect(
        midiFlags2 & 0x01,
        equals(0),
        reason: 'Relative flag should be 0',
      );
      expect(midiFlags2, equals(0x0C), reason: 'Full flags2 byte should be 0x0C');
    });

    test('SetMidiMappingMessage encodes 14-bit CC high type correctly', () {
      final mapping = PackedMappingData(
        source: 1,
        cvInput: 0,
        isUnipolar: true,
        isGate: false,
        volts: 5,
        delta: 100,
        midiChannel: 1,
        midiMappingType: MidiMappingType.cc14BitHigh,
        midiCC: 33,
        isMidiEnabled: true,
        isMidiSymmetric: false,
        isMidiRelative: false,
        midiMin: 0,
        midiMax: 16383,
        i2cCC: 0,
        isI2cEnabled: false,
        isI2cSymmetric: false,
        i2cMin: 0,
        i2cMax: 16383,
        perfPageIndex: 0,
        version: 5,
      );

      final message = SetMidiMappingMessage(
        sysExId: 0,
        algorithmIndex: 0,
        parameterNumber: 0,
        data: mapping,
      );

      final encoded = message.encode();
      final midiFlags2Offset = 14;
      final midiFlags2 = encoded[midiFlags2Offset];

      // Type 4 (cc14BitHigh) should be encoded as (4 << 2) = 0x10
      expect(midiFlags2 >> 2, equals(4), reason: 'Type value should be 4');
      expect(
        midiFlags2 & 0x01,
        equals(0),
        reason: 'Relative flag should be 0',
      );
      expect(
        midiFlags2,
        equals(0x10),
        reason: 'Full flags2 byte should be 0x10',
      );
    });

    test('MappingResponse decodes 14-bit CC low type correctly', () {
      // Simulate a hardware response with 14-bit CC low mapping
      // Response structure: [algorithmIndex] [paramNumber 3 bytes] [version] [payload...]

      // Build the payload manually
      final payload = <int>[
        0, // Algorithm index
        0x00,
        0x00,
        0x00, // Parameter number (encode16 of 0)
        5, // Version
        // CV section (7 bytes)
        1, // source
        0, // cvInput
        1, // flags (unipolar)
        5, // volts
        0x64,
        0x00,
        0x00, // delta (encode16 of 100)
        // MIDI section (9 bytes)
        1, // midiCC
        0x89, // midiFlags: enabled=1, channel=1
        0x0C, // midiFlags2: type=3 (cc14BitLow), relative=0
        0x00,
        0x00,
        0x00, // midiMin (encode16 of 0)
        0x7F,
        0x7F,
        0x00, // midiMax (encode16 of 16383)
        // I2C section (9 bytes)
        0, // i2cCC
        0, // high byte
        0, // flags
        0x00,
        0x00,
        0x00, // i2cMin
        0x7F,
        0x7F,
        0x00, // i2cMax
        // Performance page (1 byte)
        0, // perfPageIndex
      ];

      final response = MappingResponse(Uint8List.fromList(payload));
      final mapping = response.parse();

      expect(
        mapping.packedMappingData.midiMappingType,
        equals(MidiMappingType.cc14BitLow),
      );
      expect(mapping.packedMappingData.midiCC, equals(1));
      expect(mapping.packedMappingData.isMidiRelative, equals(false));
    });

    test('MappingResponse decodes 14-bit CC high type correctly', () {
      final payload = <int>[
        0, // Algorithm index
        0x00,
        0x00,
        0x00, // Parameter number (encode16 of 0)
        5, // Version
        // CV section
        1,
        0,
        1,
        5,
        0x64,
        0x00,
        0x00,
        // MIDI section
        33, // midiCC
        0x89,
        0x10, // midiFlags2: type=4 (cc14BitHigh), relative=0
        0x00,
        0x00,
        0x00,
        0x7F,
        0x7F,
        0x00,
        // I2C section
        0,
        0,
        0,
        0x00,
        0x00,
        0x00,
        0x7F,
        0x7F,
        0x00,
        // Performance page
        0,
      ];

      final response = MappingResponse(Uint8List.fromList(payload));
      final mapping = response.parse();

      expect(
        mapping.packedMappingData.midiMappingType,
        equals(MidiMappingType.cc14BitHigh),
      );
      expect(mapping.packedMappingData.midiCC, equals(33));
      expect(mapping.packedMappingData.isMidiRelative, equals(false));
    });

    test('SetMidiMappingMessage encodes 14-bit CC with relative flag', () {
      final mapping = PackedMappingData(
        source: 1,
        cvInput: 0,
        isUnipolar: true,
        isGate: false,
        volts: 5,
        delta: 100,
        midiChannel: 1,
        midiMappingType: MidiMappingType.cc14BitLow,
        midiCC: 1,
        isMidiEnabled: true,
        isMidiSymmetric: false,
        isMidiRelative: true, // Enable relative
        midiMin: 0,
        midiMax: 16383,
        i2cCC: 0,
        isI2cEnabled: false,
        isI2cSymmetric: false,
        i2cMin: 0,
        i2cMax: 16383,
        perfPageIndex: 0,
        version: 5,
      );

      final message = SetMidiMappingMessage(
        sysExId: 0,
        algorithmIndex: 0,
        parameterNumber: 0,
        data: mapping,
      );

      final encoded = message.encode();
      final midiFlags2Offset = 14;
      final midiFlags2 = encoded[midiFlags2Offset];

      // Should have type=3 and relative=1: (3 << 2) | 1 = 0x0D
      expect(midiFlags2, equals(0x0D), reason: 'Flags2 should be 0x0D');
      expect(midiFlags2 >> 2, equals(3), reason: 'Type should be 3');
      expect(midiFlags2 & 0x01, equals(1), reason: 'Relative flag should be 1');
    });
  });
}
