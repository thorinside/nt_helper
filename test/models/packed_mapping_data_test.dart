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

    test('perfPageIndex supports range 1-15', () {
      for (int i = 1; i <= 15; i++) {
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
}
