import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/domain/sysex/sysex_utils.dart';
import 'package:nt_helper/models/packed_mapping_data.dart';

void main() {
  group('PackedMappingData Version 5', () {
    test('fromBytes parses version 5 with perfPageIndex correctly', () {
      // Create 26 bytes for version 5
      final data = Uint8List(26);
      int offset = 0;

      // CV Mapping (7 bytes)
      data[offset++] = 1; // source
      data[offset++] = 2; // cvInput
      data[offset++] = 3; // flags (unipolar=1, gate=1)
      data[offset++] = 5; // volts
      // delta (3 bytes encoded)
      final deltaBytes = encode16(100);
      data[offset++] = deltaBytes[0];
      data[offset++] = deltaBytes[1];
      data[offset++] = deltaBytes[2];

      // MIDI Mapping (9 bytes)
      data[offset++] = 64; // midiCC
      data[offset++] = 0x89; // flags: enabled=1, channel=1
      data[offset++] = 0; // midiFlags2
      // midiMin (3 bytes encoded)
      final minBytes = encode16(0);
      data[offset++] = minBytes[0];
      data[offset++] = minBytes[1];
      data[offset++] = minBytes[2];
      // midiMax (3 bytes encoded)
      final maxBytes = encode16(127);
      data[offset++] = maxBytes[0];
      data[offset++] = maxBytes[1];
      data[offset++] = maxBytes[2];

      // I2C Mapping (9 bytes)
      data[offset++] = 32; // i2cCC
      data[offset++] = 0; // high byte
      data[offset++] = 0; // flags
      // i2cMin (3 bytes encoded)
      final i2cMinBytes = encode16(0);
      data[offset++] = i2cMinBytes[0];
      data[offset++] = i2cMinBytes[1];
      data[offset++] = i2cMinBytes[2];
      // i2cMax (3 bytes encoded)
      final i2cMaxBytes = encode16(16383);
      data[offset++] = i2cMaxBytes[0];
      data[offset++] = i2cMaxBytes[1];
      data[offset++] = i2cMaxBytes[2];

      // Performance Page (1 byte)
      data[offset++] = 5; // perfPageIndex

      final mapping = PackedMappingData.fromBytes(5, data);

      expect(mapping.perfPageIndex, equals(5));
      expect(mapping.version, equals(5));
      expect(mapping.source, equals(1));
      expect(mapping.cvInput, equals(2));
    });

    test('toBytes encodes version 5 with perfPageIndex correctly', () {
      final mapping = PackedMappingData(
        source: 1,
        cvInput: 2,
        isUnipolar: true,
        isGate: false,
        volts: 5,
        delta: 100,
        midiChannel: 1,
        midiMappingType: MidiMappingType.cc,
        midiCC: 64,
        isMidiEnabled: true,
        isMidiSymmetric: false,
        isMidiRelative: false,
        midiMin: 0,
        midiMax: 127,
        i2cCC: 32,
        isI2cEnabled: false,
        isI2cSymmetric: false,
        i2cMin: 0,
        i2cMax: 16383,
        perfPageIndex: 7,
        version: 5,
      );

      final bytes = mapping.toBytes();

      expect(bytes.length, equals(26));
      expect(bytes[25], equals(7)); // perfPageIndex at last byte
    });

    test('version 5 round-trip preserves perfPageIndex', () {
      final original = PackedMappingData(
        source: 3,
        cvInput: 4,
        isUnipolar: false,
        isGate: true,
        volts: 10,
        delta: 200,
        midiChannel: 2,
        midiMappingType: MidiMappingType.noteMomentary,
        midiCC: 60,
        isMidiEnabled: true,
        isMidiSymmetric: true,
        isMidiRelative: false,
        midiMin: 10,
        midiMax: 100,
        i2cCC: 50,
        isI2cEnabled: true,
        isI2cSymmetric: false,
        i2cMin: 100,
        i2cMax: 1000,
        perfPageIndex: 12,
        version: 5,
      );

      final bytes = original.toBytes();
      final decoded = PackedMappingData.fromBytes(5, bytes);

      expect(decoded.perfPageIndex, equals(12));
      expect(decoded.source, equals(original.source));
      expect(decoded.cvInput, equals(original.cvInput));
      expect(decoded.isUnipolar, equals(original.isUnipolar));
      expect(decoded.isGate, equals(original.isGate));
      expect(decoded.volts, equals(original.volts));
      expect(decoded.delta, equals(original.delta));
      expect(decoded.midiChannel, equals(original.midiChannel));
      expect(decoded.midiMappingType, equals(original.midiMappingType));
      expect(decoded.midiCC, equals(original.midiCC));
      expect(decoded.isMidiEnabled, equals(original.isMidiEnabled));
      expect(decoded.isMidiSymmetric, equals(original.isMidiSymmetric));
      expect(decoded.i2cCC, equals(original.i2cCC));
      expect(decoded.isI2cEnabled, equals(original.isI2cEnabled));
      expect(decoded.isI2cSymmetric, equals(original.isI2cSymmetric));
    });

    test('perfPageIndex included in equality check', () {
      final mapping1 = PackedMappingData(
        source: 1,
        cvInput: 2,
        isUnipolar: true,
        isGate: false,
        volts: 5,
        delta: 100,
        midiChannel: 1,
        midiMappingType: MidiMappingType.cc,
        midiCC: 64,
        isMidiEnabled: true,
        isMidiSymmetric: false,
        isMidiRelative: false,
        midiMin: 0,
        midiMax: 127,
        i2cCC: 32,
        isI2cEnabled: false,
        isI2cSymmetric: false,
        i2cMin: 0,
        i2cMax: 16383,
        perfPageIndex: 5,
        version: 5,
      );

      final mapping2 = PackedMappingData(
        source: 1,
        cvInput: 2,
        isUnipolar: true,
        isGate: false,
        volts: 5,
        delta: 100,
        midiChannel: 1,
        midiMappingType: MidiMappingType.cc,
        midiCC: 64,
        isMidiEnabled: true,
        isMidiSymmetric: false,
        isMidiRelative: false,
        midiMin: 0,
        midiMax: 127,
        i2cCC: 32,
        isI2cEnabled: false,
        isI2cSymmetric: false,
        i2cMin: 0,
        i2cMax: 16383,
        perfPageIndex: 7, // Different perfPageIndex
        version: 5,
      );

      expect(mapping1 == mapping2, isFalse);
      expect(mapping1.hashCode == mapping2.hashCode, isFalse);
    });

    test('perfPageIndex=0 means not assigned', () {
      final mapping = PackedMappingData(
        source: 1,
        cvInput: 2,
        isUnipolar: true,
        isGate: false,
        volts: 5,
        delta: 100,
        midiChannel: 1,
        midiMappingType: MidiMappingType.cc,
        midiCC: 64,
        isMidiEnabled: true,
        isMidiSymmetric: false,
        isMidiRelative: false,
        midiMin: 0,
        midiMax: 127,
        i2cCC: 32,
        isI2cEnabled: false,
        isI2cSymmetric: false,
        i2cMin: 0,
        i2cMax: 16383,
        perfPageIndex: 0, // Not assigned
        version: 5,
      );

      expect(mapping.perfPageIndex, equals(0));
    });

    test('perfPageIndex supports range 1-30', () {
      for (int i = 1; i <= 30; i++) {
        final mapping = PackedMappingData(
          source: 1,
          cvInput: 2,
          isUnipolar: true,
          isGate: false,
          volts: 5,
          delta: 100,
          midiChannel: 1,
          midiMappingType: MidiMappingType.cc,
          midiCC: 64,
          isMidiEnabled: true,
          isMidiSymmetric: false,
          isMidiRelative: false,
          midiMin: 0,
          midiMax: 127,
          i2cCC: 32,
          isI2cEnabled: false,
          isI2cSymmetric: false,
          i2cMin: 0,
          i2cMax: 16383,
          perfPageIndex: i,
          version: 5,
        );

        final bytes = mapping.toBytes();
        final decoded = PackedMappingData.fromBytes(5, bytes);

        expect(decoded.perfPageIndex, equals(i));
      }
    });
  });

  group('PackedMappingData Backward Compatibility', () {
    test('version 1 still parses correctly', () {
      // Create 22 bytes for version 1
      final data = Uint8List(22);
      int offset = 0;

      // CV Mapping (6 bytes) - no source
      data[offset++] = 2; // cvInput
      data[offset++] = 1; // flags
      data[offset++] = 5; // volts
      final deltaBytes = encode16(100);
      data[offset++] = deltaBytes[0];
      data[offset++] = deltaBytes[1];
      data[offset++] = deltaBytes[2];

      // MIDI Mapping (8 bytes) - no midiFlags2
      data[offset++] = 64; // midiCC
      data[offset++] = 0x89; // flags
      final minBytes = encode16(0);
      data[offset++] = minBytes[0];
      data[offset++] = minBytes[1];
      data[offset++] = minBytes[2];
      final maxBytes = encode16(127);
      data[offset++] = maxBytes[0];
      data[offset++] = maxBytes[1];
      data[offset++] = maxBytes[2];

      // I2C Mapping (8 bytes) - no high byte
      data[offset++] = 32; // i2cCC
      data[offset++] = 0; // flags
      final i2cMinBytes = encode16(0);
      data[offset++] = i2cMinBytes[0];
      data[offset++] = i2cMinBytes[1];
      data[offset++] = i2cMinBytes[2];
      final i2cMaxBytes = encode16(16383);
      data[offset++] = i2cMaxBytes[0];
      data[offset++] = i2cMaxBytes[1];
      data[offset++] = i2cMaxBytes[2];

      final mapping = PackedMappingData.fromBytes(1, data);

      expect(mapping.version, equals(1));
      expect(mapping.perfPageIndex, equals(0)); // Defaults to 0
      expect(mapping.source, equals(0)); // Defaults to 0 for v1
      expect(mapping.cvInput, equals(2));
    });

    test('version 2 still parses correctly', () {
      // Version 2 adds midiFlags2 (23 bytes)
      final data = Uint8List(23);
      int offset = 0;

      // CV Mapping (6 bytes)
      data[offset++] = 2;
      data[offset++] = 1;
      data[offset++] = 5;
      final deltaBytes = encode16(100);
      data[offset++] = deltaBytes[0];
      data[offset++] = deltaBytes[1];
      data[offset++] = deltaBytes[2];

      // MIDI Mapping (9 bytes with midiFlags2)
      data[offset++] = 64;
      data[offset++] = 0x89;
      data[offset++] = 0; // midiFlags2
      final minBytes = encode16(0);
      data[offset++] = minBytes[0];
      data[offset++] = minBytes[1];
      data[offset++] = minBytes[2];
      final maxBytes = encode16(127);
      data[offset++] = maxBytes[0];
      data[offset++] = maxBytes[1];
      data[offset++] = maxBytes[2];

      // I2C Mapping (8 bytes)
      data[offset++] = 32;
      data[offset++] = 0;
      final i2cMinBytes = encode16(0);
      data[offset++] = i2cMinBytes[0];
      data[offset++] = i2cMinBytes[1];
      data[offset++] = i2cMinBytes[2];
      final i2cMaxBytes = encode16(16383);
      data[offset++] = i2cMaxBytes[0];
      data[offset++] = i2cMaxBytes[1];
      data[offset++] = i2cMaxBytes[2];

      final mapping = PackedMappingData.fromBytes(2, data);

      expect(mapping.version, equals(2));
      expect(mapping.perfPageIndex, equals(0)); // Defaults to 0
    });

    test('version 3 still parses correctly', () {
      // Version 3 adds I2C high byte (24 bytes)
      final data = Uint8List(24);
      int offset = 0;

      // CV Mapping (6 bytes)
      data[offset++] = 2;
      data[offset++] = 1;
      data[offset++] = 5;
      final deltaBytes = encode16(100);
      data[offset++] = deltaBytes[0];
      data[offset++] = deltaBytes[1];
      data[offset++] = deltaBytes[2];

      // MIDI Mapping (9 bytes)
      data[offset++] = 64;
      data[offset++] = 0x89;
      data[offset++] = 0;
      final minBytes = encode16(0);
      data[offset++] = minBytes[0];
      data[offset++] = minBytes[1];
      data[offset++] = minBytes[2];
      final maxBytes = encode16(127);
      data[offset++] = maxBytes[0];
      data[offset++] = maxBytes[1];
      data[offset++] = maxBytes[2];

      // I2C Mapping (9 bytes with high byte)
      data[offset++] = 32;
      data[offset++] = 0; // high byte
      data[offset++] = 0;
      final i2cMinBytes = encode16(0);
      data[offset++] = i2cMinBytes[0];
      data[offset++] = i2cMinBytes[1];
      data[offset++] = i2cMinBytes[2];
      final i2cMaxBytes = encode16(16383);
      data[offset++] = i2cMaxBytes[0];
      data[offset++] = i2cMaxBytes[1];
      data[offset++] = i2cMaxBytes[2];

      final mapping = PackedMappingData.fromBytes(3, data);

      expect(mapping.version, equals(3));
      expect(mapping.perfPageIndex, equals(0)); // Defaults to 0
    });

    test('version 4 still parses correctly', () {
      // Version 4 adds source byte (25 bytes)
      final data = Uint8List(25);
      int offset = 0;

      // CV Mapping (7 bytes with source)
      data[offset++] = 1; // source
      data[offset++] = 2;
      data[offset++] = 1;
      data[offset++] = 5;
      final deltaBytes = encode16(100);
      data[offset++] = deltaBytes[0];
      data[offset++] = deltaBytes[1];
      data[offset++] = deltaBytes[2];

      // MIDI Mapping (9 bytes)
      data[offset++] = 64;
      data[offset++] = 0x89;
      data[offset++] = 0;
      final minBytes = encode16(0);
      data[offset++] = minBytes[0];
      data[offset++] = minBytes[1];
      data[offset++] = minBytes[2];
      final maxBytes = encode16(127);
      data[offset++] = maxBytes[0];
      data[offset++] = maxBytes[1];
      data[offset++] = maxBytes[2];

      // I2C Mapping (9 bytes)
      data[offset++] = 32;
      data[offset++] = 0;
      data[offset++] = 0;
      final i2cMinBytes = encode16(0);
      data[offset++] = i2cMinBytes[0];
      data[offset++] = i2cMinBytes[1];
      data[offset++] = i2cMinBytes[2];
      final i2cMaxBytes = encode16(16383);
      data[offset++] = i2cMaxBytes[0];
      data[offset++] = i2cMaxBytes[1];
      data[offset++] = i2cMaxBytes[2];

      final mapping = PackedMappingData.fromBytes(4, data);

      expect(mapping.version, equals(4));
      expect(mapping.perfPageIndex, equals(0)); // Defaults to 0
      expect(mapping.source, equals(1));
    });

    test('filler factory has perfPageIndex=0', () {
      final filler = PackedMappingData.filler();

      expect(filler.perfPageIndex, equals(0));
    });
  });

  group('MidiMappingType 14-bit CC Support', () {
    test('MidiMappingType enum includes 14-bit CC values', () {
      expect(MidiMappingType.cc14BitLow.value, equals(3));
      expect(MidiMappingType.cc14BitHigh.value, equals(4));
    });

    test('encodeMIDIPackedData encodes cc14BitLow type correctly', () {
      final mapping = PackedMappingData(
        source: 1,
        cvInput: 2,
        isUnipolar: true,
        isGate: false,
        volts: 5,
        delta: 100,
        midiChannel: 1,
        midiMappingType: MidiMappingType.cc14BitLow,
        midiCC: 64,
        isMidiEnabled: true,
        isMidiSymmetric: false,
        isMidiRelative: false,
        midiMin: 0,
        midiMax: 127,
        i2cCC: 32,
        isI2cEnabled: false,
        isI2cSymmetric: false,
        i2cMin: 0,
        i2cMax: 16383,
        perfPageIndex: 0,
        version: 5,
      );

      final bytes = mapping.toBytes();
      // MIDI section starts at offset 7 (CV=7 bytes)
      // midiFlags2 is at offset 7+1+1=9
      final midiFlags2 = bytes[9];

      // Type 3 should be encoded as (3 << 2) = 0x0C
      expect(midiFlags2 >> 2, equals(3)); // Extract type value
      expect(midiFlags2 & 0x01, equals(0)); // Relative flag should be 0
    });

    test('encodeMIDIPackedData encodes cc14BitHigh type correctly', () {
      final mapping = PackedMappingData(
        source: 1,
        cvInput: 2,
        isUnipolar: true,
        isGate: false,
        volts: 5,
        delta: 100,
        midiChannel: 1,
        midiMappingType: MidiMappingType.cc14BitHigh,
        midiCC: 65,
        isMidiEnabled: true,
        isMidiSymmetric: false,
        isMidiRelative: false,
        midiMin: 0,
        midiMax: 127,
        i2cCC: 32,
        isI2cEnabled: false,
        isI2cSymmetric: false,
        i2cMin: 0,
        i2cMax: 16383,
        perfPageIndex: 0,
        version: 5,
      );

      final bytes = mapping.toBytes();
      final midiFlags2 = bytes[9];

      // Type 4 should be encoded as (4 << 2) = 0x10
      expect(midiFlags2 >> 2, equals(4)); // Extract type value
      expect(midiFlags2 & 0x01, equals(0)); // Relative flag should be 0
    });

    test('fromBytes decodes cc14BitLow type correctly', () {
      final data = Uint8List(26);
      int offset = 0;

      // CV Mapping (7 bytes)
      data[offset++] = 1; // source
      data[offset++] = 2; // cvInput
      data[offset++] = 1; // flags
      data[offset++] = 5; // volts
      final deltaBytes = encode16(100);
      data[offset++] = deltaBytes[0];
      data[offset++] = deltaBytes[1];
      data[offset++] = deltaBytes[2];

      // MIDI Mapping (9 bytes)
      data[offset++] = 64; // midiCC
      data[offset++] = 0x89; // flags: enabled=1, channel=1
      data[offset++] = 0x0C; // midiFlags2: type=3 (cc14BitLow), relative=0
      final minBytes = encode16(0);
      data[offset++] = minBytes[0];
      data[offset++] = minBytes[1];
      data[offset++] = minBytes[2];
      final maxBytes = encode16(127);
      data[offset++] = maxBytes[0];
      data[offset++] = maxBytes[1];
      data[offset++] = maxBytes[2];

      // I2C Mapping (9 bytes)
      data[offset++] = 32;
      data[offset++] = 0;
      data[offset++] = 0;
      final i2cMinBytes = encode16(0);
      data[offset++] = i2cMinBytes[0];
      data[offset++] = i2cMinBytes[1];
      data[offset++] = i2cMinBytes[2];
      final i2cMaxBytes = encode16(16383);
      data[offset++] = i2cMaxBytes[0];
      data[offset++] = i2cMaxBytes[1];
      data[offset++] = i2cMaxBytes[2];

      // Performance Page (1 byte)
      data[offset++] = 0;

      final mapping = PackedMappingData.fromBytes(5, data);

      expect(mapping.midiMappingType, equals(MidiMappingType.cc14BitLow));
      expect(mapping.isMidiRelative, equals(false));
    });

    test('fromBytes decodes cc14BitHigh type correctly', () {
      final data = Uint8List(26);
      int offset = 0;

      // CV Mapping (7 bytes)
      data[offset++] = 1;
      data[offset++] = 2;
      data[offset++] = 1;
      data[offset++] = 5;
      final deltaBytes = encode16(100);
      data[offset++] = deltaBytes[0];
      data[offset++] = deltaBytes[1];
      data[offset++] = deltaBytes[2];

      // MIDI Mapping (9 bytes)
      data[offset++] = 65; // midiCC
      data[offset++] = 0x89;
      data[offset++] = 0x10; // midiFlags2: type=4 (cc14BitHigh), relative=0
      final minBytes = encode16(0);
      data[offset++] = minBytes[0];
      data[offset++] = minBytes[1];
      data[offset++] = minBytes[2];
      final maxBytes = encode16(127);
      data[offset++] = maxBytes[0];
      data[offset++] = maxBytes[1];
      data[offset++] = maxBytes[2];

      // I2C Mapping (9 bytes)
      data[offset++] = 32;
      data[offset++] = 0;
      data[offset++] = 0;
      final i2cMinBytes = encode16(0);
      data[offset++] = i2cMinBytes[0];
      data[offset++] = i2cMinBytes[1];
      data[offset++] = i2cMinBytes[2];
      final i2cMaxBytes = encode16(16383);
      data[offset++] = i2cMaxBytes[0];
      data[offset++] = i2cMaxBytes[1];
      data[offset++] = i2cMaxBytes[2];

      // Performance Page (1 byte)
      data[offset++] = 0;

      final mapping = PackedMappingData.fromBytes(5, data);

      expect(mapping.midiMappingType, equals(MidiMappingType.cc14BitHigh));
      expect(mapping.isMidiRelative, equals(false));
    });

    test('existing types 0-2 still decode correctly with bit-shift', () {
      // Test CC (type 0)
      final ccData = Uint8List(26);
      int offset = 0;
      ccData[offset++] = 1;
      ccData[offset++] = 2;
      ccData[offset++] = 1;
      ccData[offset++] = 5;
      final deltaBytes = encode16(100);
      ccData[offset++] = deltaBytes[0];
      ccData[offset++] = deltaBytes[1];
      ccData[offset++] = deltaBytes[2];
      ccData[offset++] = 64;
      ccData[offset++] = 0x89;
      ccData[offset++] = 0x00; // type=0 (CC)
      final minBytes = encode16(0);
      ccData[offset++] = minBytes[0];
      ccData[offset++] = minBytes[1];
      ccData[offset++] = minBytes[2];
      final maxBytes = encode16(127);
      ccData[offset++] = maxBytes[0];
      ccData[offset++] = maxBytes[1];
      ccData[offset++] = maxBytes[2];
      ccData[offset++] = 32;
      ccData[offset++] = 0;
      ccData[offset++] = 0;
      final i2cMinBytes = encode16(0);
      ccData[offset++] = i2cMinBytes[0];
      ccData[offset++] = i2cMinBytes[1];
      ccData[offset++] = i2cMinBytes[2];
      final i2cMaxBytes = encode16(16383);
      ccData[offset++] = i2cMaxBytes[0];
      ccData[offset++] = i2cMaxBytes[1];
      ccData[offset++] = i2cMaxBytes[2];
      ccData[offset++] = 0;

      final ccMapping = PackedMappingData.fromBytes(5, ccData);
      expect(ccMapping.midiMappingType, equals(MidiMappingType.cc));

      // Test noteMomentary (type 1)
      final noteData = Uint8List(26);
      offset = 0;
      noteData[offset++] = 1;
      noteData[offset++] = 2;
      noteData[offset++] = 1;
      noteData[offset++] = 5;
      final deltaBytes2 = encode16(100);
      noteData[offset++] = deltaBytes2[0];
      noteData[offset++] = deltaBytes2[1];
      noteData[offset++] = deltaBytes2[2];
      noteData[offset++] = 60;
      noteData[offset++] = 0x89;
      noteData[offset++] = 0x04; // type=1 (noteMomentary)
      final minBytes2 = encode16(0);
      noteData[offset++] = minBytes2[0];
      noteData[offset++] = minBytes2[1];
      noteData[offset++] = minBytes2[2];
      final maxBytes2 = encode16(127);
      noteData[offset++] = maxBytes2[0];
      noteData[offset++] = maxBytes2[1];
      noteData[offset++] = maxBytes2[2];
      noteData[offset++] = 32;
      noteData[offset++] = 0;
      noteData[offset++] = 0;
      final i2cMinBytes2 = encode16(0);
      noteData[offset++] = i2cMinBytes2[0];
      noteData[offset++] = i2cMinBytes2[1];
      noteData[offset++] = i2cMinBytes2[2];
      final i2cMaxBytes2 = encode16(16383);
      noteData[offset++] = i2cMaxBytes2[0];
      noteData[offset++] = i2cMaxBytes2[1];
      noteData[offset++] = i2cMaxBytes2[2];
      noteData[offset++] = 0;

      final noteMapping = PackedMappingData.fromBytes(5, noteData);
      expect(
        noteMapping.midiMappingType,
        equals(MidiMappingType.noteMomentary),
      );

      // Test noteToggle (type 2)
      final toggleData = Uint8List(26);
      offset = 0;
      toggleData[offset++] = 1;
      toggleData[offset++] = 2;
      toggleData[offset++] = 1;
      toggleData[offset++] = 5;
      final deltaBytes3 = encode16(100);
      toggleData[offset++] = deltaBytes3[0];
      toggleData[offset++] = deltaBytes3[1];
      toggleData[offset++] = deltaBytes3[2];
      toggleData[offset++] = 60;
      toggleData[offset++] = 0x89;
      toggleData[offset++] = 0x08; // type=2 (noteToggle)
      final minBytes3 = encode16(0);
      toggleData[offset++] = minBytes3[0];
      toggleData[offset++] = minBytes3[1];
      toggleData[offset++] = minBytes3[2];
      final maxBytes3 = encode16(127);
      toggleData[offset++] = maxBytes3[0];
      toggleData[offset++] = maxBytes3[1];
      toggleData[offset++] = maxBytes3[2];
      toggleData[offset++] = 32;
      toggleData[offset++] = 0;
      toggleData[offset++] = 0;
      final i2cMinBytes3 = encode16(0);
      toggleData[offset++] = i2cMinBytes3[0];
      toggleData[offset++] = i2cMinBytes3[1];
      toggleData[offset++] = i2cMinBytes3[2];
      final i2cMaxBytes3 = encode16(16383);
      toggleData[offset++] = i2cMaxBytes3[0];
      toggleData[offset++] = i2cMaxBytes3[1];
      toggleData[offset++] = i2cMaxBytes3[2];
      toggleData[offset++] = 0;

      final toggleMapping = PackedMappingData.fromBytes(5, toggleData);
      expect(toggleMapping.midiMappingType, equals(MidiMappingType.noteToggle));
    });

    test('14-bit CC types round-trip correctly', () {
      // Test cc14BitLow
      final lowMapping = PackedMappingData(
        source: 1,
        cvInput: 2,
        isUnipolar: true,
        isGate: false,
        volts: 5,
        delta: 100,
        midiChannel: 1,
        midiMappingType: MidiMappingType.cc14BitLow,
        midiCC: 64,
        isMidiEnabled: true,
        isMidiSymmetric: false,
        isMidiRelative: false,
        midiMin: 0,
        midiMax: 16383,
        i2cCC: 32,
        isI2cEnabled: false,
        isI2cSymmetric: false,
        i2cMin: 0,
        i2cMax: 16383,
        perfPageIndex: 0,
        version: 5,
      );

      final lowBytes = lowMapping.toBytes();
      final lowDecoded = PackedMappingData.fromBytes(5, lowBytes);

      expect(lowDecoded.midiMappingType, equals(MidiMappingType.cc14BitLow));
      expect(lowDecoded.midiCC, equals(64));

      // Test cc14BitHigh
      final highMapping = PackedMappingData(
        source: 1,
        cvInput: 2,
        isUnipolar: true,
        isGate: false,
        volts: 5,
        delta: 100,
        midiChannel: 1,
        midiMappingType: MidiMappingType.cc14BitHigh,
        midiCC: 96,
        isMidiEnabled: true,
        isMidiSymmetric: false,
        isMidiRelative: false,
        midiMin: 0,
        midiMax: 16383,
        i2cCC: 32,
        isI2cEnabled: false,
        isI2cSymmetric: false,
        i2cMin: 0,
        i2cMax: 16383,
        perfPageIndex: 0,
        version: 5,
      );

      final highBytes = highMapping.toBytes();
      final highDecoded = PackedMappingData.fromBytes(5, highBytes);

      expect(highDecoded.midiMappingType, equals(MidiMappingType.cc14BitHigh));
      expect(highDecoded.midiCC, equals(96));
    });

    test('relative flag preserved with 14-bit types', () {
      final mapping = PackedMappingData(
        source: 1,
        cvInput: 2,
        isUnipolar: true,
        isGate: false,
        volts: 5,
        delta: 100,
        midiChannel: 1,
        midiMappingType: MidiMappingType.cc14BitLow,
        midiCC: 64,
        isMidiEnabled: true,
        isMidiSymmetric: false,
        isMidiRelative: true, // Set relative flag
        midiMin: 0,
        midiMax: 16383,
        i2cCC: 32,
        isI2cEnabled: false,
        isI2cSymmetric: false,
        i2cMin: 0,
        i2cMax: 16383,
        perfPageIndex: 0,
        version: 5,
      );

      final bytes = mapping.toBytes();
      final midiFlags2 = bytes[9];

      // Should have type=3 and relative=1: (3 << 2) | 1 = 0x0D
      expect(midiFlags2, equals(0x0D));
      expect(midiFlags2 >> 2, equals(3)); // Type
      expect(midiFlags2 & 0x01, equals(1)); // Relative

      // Test round-trip
      final decoded = PackedMappingData.fromBytes(5, bytes);
      expect(decoded.midiMappingType, equals(MidiMappingType.cc14BitLow));
      expect(decoded.isMidiRelative, equals(true));
    });
  });

  group('Forward Compatibility', () {
    test('unknown version > 5 parses as v5', () {
      // Create v5-sized data (26 bytes) + 2 extra bytes for "v6"
      final data = Uint8List(28);
      int offset = 0;

      // CV Mapping (7 bytes)
      data[offset++] = 1; // source
      data[offset++] = 2; // cvInput
      data[offset++] = 1; // flags (unipolar)
      data[offset++] = 5; // volts
      final deltaBytes = encode16(100);
      data[offset++] = deltaBytes[0];
      data[offset++] = deltaBytes[1];
      data[offset++] = deltaBytes[2];

      // MIDI Mapping (9 bytes)
      data[offset++] = 42; // midiCC
      data[offset++] = 0x09; // flags: enabled=1, channel=1
      data[offset++] = 0; // midiFlags2
      final minBytes = encode16(0);
      data[offset++] = minBytes[0];
      data[offset++] = minBytes[1];
      data[offset++] = minBytes[2];
      final maxBytes = encode16(127);
      data[offset++] = maxBytes[0];
      data[offset++] = maxBytes[1];
      data[offset++] = maxBytes[2];

      // I2C Mapping (9 bytes)
      data[offset++] = 32;
      data[offset++] = 0;
      data[offset++] = 0;
      final i2cMinBytes = encode16(0);
      data[offset++] = i2cMinBytes[0];
      data[offset++] = i2cMinBytes[1];
      data[offset++] = i2cMinBytes[2];
      final i2cMaxBytes = encode16(16383);
      data[offset++] = i2cMaxBytes[0];
      data[offset++] = i2cMaxBytes[1];
      data[offset++] = i2cMaxBytes[2];

      // Performance Page (1 byte)
      data[offset++] = 3;

      // Extra trailing bytes from hypothetical v6
      data[offset++] = 0x55;
      data[offset++] = 0x66;

      final mapping = PackedMappingData.fromBytes(6, data);

      // Should parse successfully, not return filler
      expect(mapping.midiCC, equals(42));
      expect(mapping.isMidiEnabled, isTrue);
      expect(mapping.midiChannel, equals(1));
      expect(mapping.perfPageIndex, equals(3));
      expect(mapping.source, equals(1));
      expect(mapping.cvInput, equals(2));
      // Preserves original firmware version
      expect(mapping.version, equals(6));
    });

    test('version 0 returns filler', () {
      final data = Uint8List(26);
      final mapping = PackedMappingData.fromBytes(0, data);
      expect(mapping.midiCC, equals(-1));
    });

    test('negative version returns filler', () {
      final data = Uint8List(26);
      final mapping = PackedMappingData.fromBytes(-1, data);
      expect(mapping.midiCC, equals(-1));
    });

    test('v5 data with extra trailing bytes parses correctly', () {
      // 26 bytes (v5) + 3 extra bytes
      final data = Uint8List(29);
      int offset = 0;

      // CV Mapping (7 bytes)
      data[offset++] = 0; // source
      data[offset++] = 3; // cvInput
      data[offset++] = 0; // flags
      data[offset++] = 5; // volts
      final deltaBytes = encode16(50);
      data[offset++] = deltaBytes[0];
      data[offset++] = deltaBytes[1];
      data[offset++] = deltaBytes[2];

      // MIDI Mapping (9 bytes)
      data[offset++] = 64; // midiCC
      data[offset++] = 0x09; // flags: enabled=1, channel=1
      data[offset++] = 0; // midiFlags2
      final minBytes = encode16(10);
      data[offset++] = minBytes[0];
      data[offset++] = minBytes[1];
      data[offset++] = minBytes[2];
      final maxBytes = encode16(100);
      data[offset++] = maxBytes[0];
      data[offset++] = maxBytes[1];
      data[offset++] = maxBytes[2];

      // I2C Mapping (9 bytes)
      data[offset++] = 0;
      data[offset++] = 0;
      data[offset++] = 0;
      final i2cMinBytes = encode16(0);
      data[offset++] = i2cMinBytes[0];
      data[offset++] = i2cMinBytes[1];
      data[offset++] = i2cMinBytes[2];
      final i2cMaxBytes = encode16(0);
      data[offset++] = i2cMaxBytes[0];
      data[offset++] = i2cMaxBytes[1];
      data[offset++] = i2cMaxBytes[2];

      // Performance Page (1 byte)
      data[offset++] = 0;

      // Extra trailing bytes
      data[offset++] = 0xAA;
      data[offset++] = 0xBB;
      data[offset++] = 0xCC;

      final mapping = PackedMappingData.fromBytes(5, data);

      expect(mapping.midiCC, equals(64));
      expect(mapping.isMidiEnabled, isTrue);
      expect(mapping.cvInput, equals(3));
      expect(mapping.midiMin, equals(10));
      expect(mapping.midiMax, equals(100));
      expect(mapping.version, equals(5));
    });

    test('v6 round-trip preserves original version and data', () {
      // Create v5-sized data (26 bytes) + 2 extra bytes for "v6"
      final v6Data = Uint8List(28);
      int offset = 0;

      // CV Mapping (7 bytes)
      v6Data[offset++] = 1; // source
      v6Data[offset++] = 2; // cvInput
      v6Data[offset++] = 1; // flags (unipolar)
      v6Data[offset++] = 5; // volts
      final deltaBytes = encode16(100);
      v6Data[offset++] = deltaBytes[0];
      v6Data[offset++] = deltaBytes[1];
      v6Data[offset++] = deltaBytes[2];

      // MIDI Mapping (9 bytes)
      v6Data[offset++] = 42; // midiCC
      v6Data[offset++] = 0x09; // flags: enabled=1, channel=1
      v6Data[offset++] = 0x0C; // midiFlags2: type=3 (cc14BitLow)
      final minBytes = encode16(10);
      v6Data[offset++] = minBytes[0];
      v6Data[offset++] = minBytes[1];
      v6Data[offset++] = minBytes[2];
      final maxBytes = encode16(200);
      v6Data[offset++] = maxBytes[0];
      v6Data[offset++] = maxBytes[1];
      v6Data[offset++] = maxBytes[2];

      // I2C Mapping (9 bytes)
      v6Data[offset++] = 32;
      v6Data[offset++] = 0;
      v6Data[offset++] = 3; // enabled + symmetric
      final i2cMinBytes = encode16(50);
      v6Data[offset++] = i2cMinBytes[0];
      v6Data[offset++] = i2cMinBytes[1];
      v6Data[offset++] = i2cMinBytes[2];
      final i2cMaxBytes = encode16(500);
      v6Data[offset++] = i2cMaxBytes[0];
      v6Data[offset++] = i2cMaxBytes[1];
      v6Data[offset++] = i2cMaxBytes[2];

      // Performance Page (1 byte)
      v6Data[offset++] = 7;

      // Extra trailing bytes from hypothetical v6
      v6Data[offset++] = 0x55;
      v6Data[offset++] = 0x66;

      // Parse as v6
      final parsed = PackedMappingData.fromBytes(6, v6Data);

      // Version must be preserved as 6
      expect(parsed.version, equals(6));

      // Round-trip: toBytes encodes using v5 format (highest known)
      final roundTripped = parsed.toBytes();
      expect(roundTripped.length, equals(26)); // v5 encoding length

      // Re-parse the round-tripped bytes as v6 to verify data integrity
      final reparsed = PackedMappingData.fromBytes(6, roundTripped);
      expect(reparsed.version, equals(6));
      expect(reparsed.source, equals(parsed.source));
      expect(reparsed.cvInput, equals(parsed.cvInput));
      expect(reparsed.isUnipolar, equals(parsed.isUnipolar));
      expect(reparsed.volts, equals(parsed.volts));
      expect(reparsed.delta, equals(parsed.delta));
      expect(reparsed.midiCC, equals(parsed.midiCC));
      expect(reparsed.midiChannel, equals(parsed.midiChannel));
      expect(reparsed.isMidiEnabled, equals(parsed.isMidiEnabled));
      expect(reparsed.midiMappingType, equals(parsed.midiMappingType));
      expect(reparsed.midiMin, equals(parsed.midiMin));
      expect(reparsed.midiMax, equals(parsed.midiMax));
      expect(reparsed.i2cCC, equals(parsed.i2cCC));
      expect(reparsed.isI2cEnabled, equals(parsed.isI2cEnabled));
      expect(reparsed.isI2cSymmetric, equals(parsed.isI2cSymmetric));
      expect(reparsed.i2cMin, equals(parsed.i2cMin));
      expect(reparsed.i2cMax, equals(parsed.i2cMax));
      expect(reparsed.perfPageIndex, equals(parsed.perfPageIndex));
    });

    test('data shorter than expected returns filler', () {
      // Only 20 bytes, but v5 expects 26
      final data = Uint8List(20);
      final mapping = PackedMappingData.fromBytes(5, data);
      expect(mapping.midiCC, equals(-1));
      expect(mapping.version, equals(-1));
    });
  });
}
