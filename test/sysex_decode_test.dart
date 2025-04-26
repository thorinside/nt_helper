import 'dart:typed_data';

import 'package:nt_helper/domain/ascii.dart';
import 'package:nt_helper/domain/disting_nt_sysex.dart';
import 'package:nt_helper/models/packed_mapping_data.dart';
import 'package:test/test.dart';

void main() {
  group("Disting NT Sysex Tests", () {
    test("can decode message", () {
      final message = Uint8List.fromList([
        ...encodeNullTerminatedAscii("Filter Cutoff"),
      ]);
      expect(DistingNT.decodeMessage(message), equals("Filter Cutoff"));
    });

    test("can decode parameter info", () {
      final message = Uint8List.fromList([
        1,
        ...DistingNT.encode16(1),
        ...DistingNT.encode16(0),
        ...DistingNT.encode16(127),
        ...DistingNT.encode16(64),
        0x01, // Unit
        ...encodeNullTerminatedAscii("Filter Cutoff"),
      ]);

      var parameterInfo = DistingNT.decodeParameterInfo(message);

      expect(parameterInfo.algorithmIndex, equals(1));
      expect(parameterInfo.min, equals(0));
      expect(parameterInfo.max, equals(127));
      expect(parameterInfo.defaultValue, equals(64));
      expect(parameterInfo.unit, equals(1));
      expect(parameterInfo.name, equals("Filter Cutoff"));
    });

    test("can decode all parameter values", () {
      final message = Uint8List.fromList([
        1,
        ...DistingNT.encode16(1),
        ...DistingNT.encode16(2),
        ...DistingNT.encode16(3),
        ...DistingNT.encode16(4),
        ...DistingNT.encode16(32763),
      ]);

      var allParameterValues = DistingNT.decodeAllParameterValues(message);

      expect(allParameterValues.algorithmIndex, equals(1));
      expect(allParameterValues.values.length, equals(5));
      expect(allParameterValues.values.map((e) => e.value),
          equals([1, 2, 3, 4, 32763]));
    });

    test("can decode a single parameter value", () {
      // 45H – Parameter value
      // F0 00 21 27 6D <SysEx ID> 45 <algorithm index> <16 bit parameter number> <16 bit value> F7
      // Contains the value of the given parameter in the indexed algorithm.
      final message = Uint8List.fromList([
        2,
        ...DistingNT.encode16(88),
        ...DistingNT.encode16(-2),
      ]);

      var parameterValue = DistingNT.decodeParameterValue(message);

      expect(parameterValue.algorithmIndex, equals(2));
      expect(parameterValue.parameterNumber, equals(88));
      expect(parameterValue.value, equals(-2));
    });

    test("can decode unit strings", () {
      // 48H – Unit strings
      // F0 00 21 27 6D <SysEx ID> 48 <number of strings> [<ASCII string>] F7
      // Contains an array of string descriptions of the possible parameter units (Hz, ms etc.).

      final message = Uint8List.fromList([
        2,
        ...encodeNullTerminatedAscii("First String"),
        ...encodeNullTerminatedAscii("Second String"),
      ]);

      var strings = DistingNT.decodeStrings(message);

      expect(strings[0], equals("First String"));
      expect(strings[1], equals("Second String"));
    });

    test("can decode enum strings", () {
      // 49H – Enum strings
      // F0 00 21 27 6D <SysEx ID> 49 <algorithm index> <16 bit parameter number> <number of strings>
      // [<ASCII string>] F7

      int numStrings = 255;
      final message = Uint8List.fromList([
        5,
        ...DistingNT.encode16(99),
        numStrings,
        for (int i = 0; i < numStrings; i++)
          ...encodeNullTerminatedAscii("String $i"),
      ]);

      var enumStrings = DistingNT.decodeEnumStrings(message);

      expect(enumStrings.algorithmIndex, equals(5));
      expect(enumStrings.parameterNumber, equals(99));
      expect(enumStrings.values.length, equals(numStrings));
      for (int i = 0; i < numStrings; i++) {
        expect(enumStrings.values[i], equals("String $i"));
      }
    });

    test("can decode V1 mapping data for a parameter", () {
      // 4BH – Mapping
      // F0 00 21 27 6D <SysEx ID> 4B <algorithm index> <16 bit parameter number> <version number>
      // <mapping data> F7

      PackedMappingData data = PackedMappingData(
        cvInput: 1,
        isUnipolar: true,
        isGate: false,
        volts: 5,
        delta: 100,
        midiChannel: 2,
        midiMappingType: MidiMappingType.cc,
        midiCC: 64,
        isMidiEnabled: true,
        isMidiSymmetric: false,
        isMidiRelative: false,
        midiMin: 0,
        midiMax: 127,
        i2cCC: 10,
        isI2cEnabled: true,
        isI2cSymmetric: true,
        i2cMin: 2,
        i2cMax: 16384,
        version: 1,
        source: 0,
      );

      final message = Uint8List.fromList([
        5,
        ...DistingNT.encode16(99),
        1,
        ...data.toBytes(),
      ]);

      var mapping = DistingNT.decodeMapping(message);

      expect(mapping.algorithmIndex, equals(5));
      expect(mapping.parameterNumber, equals(99));
      expect(mapping.packedMappingData.version, equals(1));
      expect(mapping.packedMappingData, equals(data));
    });

    test("can decode V2 mapping data for a parameter", () {
      // 4BH – Mapping
      // F0 00 21 27 6D <SysEx ID> 4B <algorithm index> <16 bit parameter number> <version number>
      // <mapping data> F7

      PackedMappingData data = PackedMappingData(
        cvInput: 1,
        isUnipolar: true,
        isGate: false,
        volts: 5,
        delta: 100,
        midiChannel: 2,
        midiMappingType: MidiMappingType.cc,
        midiCC: 64,
        isMidiEnabled: true,
        isMidiSymmetric: false,
        isMidiRelative: true,
        midiMin: 0,
        midiMax: 127,
        i2cCC: 10,
        isI2cEnabled: true,
        isI2cSymmetric: true,
        i2cMin: 2,
        i2cMax: 16384,
        version: 2,
        source: 0,
      );

      final message = Uint8List.fromList([
        5,
        ...DistingNT.encode16(99),
        2,
        ...data.toBytes(),
      ]);

      var mapping = DistingNT.decodeMapping(message);

      expect(mapping.algorithmIndex, equals(5));
      expect(mapping.parameterNumber, equals(99));
      expect(mapping.packedMappingData.version, equals(2));
      expect(mapping.packedMappingData, equals(data));
      expect(mapping.packedMappingData.isMidiRelative, equals(true));
    });

    test("can decode V2 mapping data for Note parameters", () {
      // Momentary Note Mapping
      PackedMappingData momentaryData = PackedMappingData(
        cvInput: 0,
        isUnipolar: false,
        isGate: false,
        volts: 0,
        delta: 0,
        midiChannel: 1,
        midiMappingType: MidiMappingType.noteMomentary,
        midiCC: 60, // Note C4
        isMidiEnabled: true,
        isMidiSymmetric: false,
        isMidiRelative: false, // Usually false for notes
        midiMin: 0, // Typically 0 for note off
        midiMax: 127, // Typically 127 for note on
        i2cCC: 0,
        isI2cEnabled: false,
        isI2cSymmetric: false,
        i2cMin: 0,
        i2cMax: 0,
        version: 2,
        source: 0,
      );

      final momentaryMessage = Uint8List.fromList([
        10, // Algorithm index
        ...DistingNT.encode16(5), // Parameter number
        2, // Version
        ...momentaryData.toBytes(),
      ]);

      var momentaryMapping = DistingNT.decodeMapping(momentaryMessage);
      expect(momentaryMapping.algorithmIndex, equals(10));
      expect(momentaryMapping.parameterNumber, equals(5));
      expect(momentaryMapping.packedMappingData.version, equals(2));
      expect(momentaryMapping.packedMappingData.midiMappingType,
          equals(MidiMappingType.noteMomentary));
      expect(momentaryMapping.packedMappingData, equals(momentaryData));

      // Toggle Note Mapping
      PackedMappingData toggleData = PackedMappingData(
        cvInput: 0,
        isUnipolar: false,
        isGate: false,
        volts: 0,
        delta: 0,
        midiChannel: 1,
        midiMappingType: MidiMappingType.noteToggle,
        midiCC: 61, // Note C#4
        isMidiEnabled: true,
        isMidiSymmetric: false,
        isMidiRelative: false,
        midiMin: 0,
        midiMax: 127,
        i2cCC: 0,
        isI2cEnabled: false,
        isI2cSymmetric: false,
        i2cMin: 0,
        i2cMax: 0,
        version: 2,
        source: 0,
      );

      final toggleMessage = Uint8List.fromList([
        11, // Algorithm index
        ...DistingNT.encode16(6), // Parameter number
        2, // Version
        ...toggleData.toBytes(),
      ]);

      var toggleMapping = DistingNT.decodeMapping(toggleMessage);
      expect(toggleMapping.algorithmIndex, equals(11));
      expect(toggleMapping.parameterNumber, equals(6));
      expect(toggleMapping.packedMappingData.version, equals(2));
      expect(toggleMapping.packedMappingData.midiMappingType,
          equals(MidiMappingType.noteToggle));
      expect(toggleMapping.packedMappingData, equals(toggleData));
    });

    test("Can decode parameter value string", () {
      // 50H – Parameter value string
      // F0 00 21 27 6D <SysEx ID> 50 <algorithm index> <16 bit parameter number> <ASCII string> F7

      final message = Uint8List.fromList([
        5,
        ...DistingNT.encode16(99),
        ...encodeNullTerminatedAscii("1000"),
      ]);

      var value = DistingNT.decodeParameterValueString(message);

      expect(value.algorithmIndex, equals(5));
      expect(value.parameterNumber, equals(99));
      expect(value.value, equals("1000"));
    });

    test("Can decode number of algorithms", () {
      // 60H – Number of algorithms
      // F0 00 21 27 6D <SysEx ID> 60 <count> F7
      // Sent in response to '60H – Request number of algorithms', as above.
      final message = Uint8List.fromList([
        ...DistingNT.encode16(55),
      ]);

      var value = DistingNT.decodeNumberOfAlgorithms(message);

      expect(value, equals(55));
    });

    test("Can decode routing information", () {
      // 61H – Routing information
      // F0 00 21 27 6D <SysEx ID> 61 <algorithm index> <routing data> F7

      final message = Uint8List.fromList([
        42,
        ...DistingNT.encode32(16385),
        ...DistingNT.encode32(65535),
        ...DistingNT.encode32(128000),
        ...DistingNT.encode32(512000),
        ...DistingNT.encode32(7000000),
        ...DistingNT.encode32(0),
      ]);

      var value = DistingNT.decodeRoutingInformation(message);

      expect(value.algorithmIndex, equals(42));
      expect(value.routingInfo[0], equals(16385));
      expect(value.routingInfo[5], equals(0));
    });
  });
}
