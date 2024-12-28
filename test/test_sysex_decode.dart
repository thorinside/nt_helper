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
        ...DistingNT.encode16(45000),
      ]);

      var allParameterValues = DistingNT.decodeAllParameterValues(message);

      expect(allParameterValues.algorithmIndex, equals(1));
      expect(allParameterValues.values.length, equals(5));
      expect(allParameterValues.values, equals([1, 2, 3, 4, 45000]));
    });

    test("can decode a single parameter value", () {
      // 45H – Parameter value
      // F0 00 21 27 6D <SysEx ID> 45 <algorithm index> <16 bit parameter number> <16 bit value> F7
      // Contains the value of the given parameter in the indexed algorithm.
      final message = Uint8List.fromList([
        2,
        ...DistingNT.encode16(88),
        ...DistingNT.encode16(65534),
      ]);

      var parameterValue = DistingNT.decodeParameterValue(message);

      expect(parameterValue.algorithmIndex, equals(2));
      expect(parameterValue.parameterNumber, equals(88));
      expect(parameterValue.value, equals(65534));
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

    test("can decode mapping data for a parameter", () {
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
        midiCC: 64,
        isMidiEnabled: true,
        isMidiSymmetric: false,
        midiMin: 0,
        midiMax: 127,
        i2cCC: 10,
        isI2cEnabled: true,
        isI2cSymmetric: true,
        i2cMin: 2,
        i2cMax: 16384,
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
      expect(mapping.version, equals(1));
      expect(mapping.packedMappingData, equals(data));
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
      // Sent in response to ‘60H – Request number of algorithms’, as above.
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
