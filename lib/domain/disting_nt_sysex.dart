import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_midi_command/flutter_midi_command.dart';
import 'package:image/image.dart' as img;
import 'package:nt_helper/domain/ascii.dart';

import '../models/packed_mapping_data.dart';

/// The MIDI SysEx reference for Expert Sleepers.
const List<int> kExpertSleepersManufacturerId = [0x00, 0x21, 0x27];

/// The byte that identifies this is a disting NT message.
const int kDistingNTPrefix = 0x6D;

/// Start and end markers for SysEx messages.
const int kSysExStart = 0xF0;
const int kSysExEnd = 0xF7;

abstract class HasAlgorithmIndex {
  int get algorithmIndex;
}

abstract class HasParameterNumber {
  int get parameterNumber;
}

enum DisplayMode {
  parameters(0),
  algorithmUI(1),
  overview(2),
  overviewVUs(3),
  ;

  final int value;

  const DisplayMode(this.value);
}

/// Enum of all known 'Sent SysEx messages' (requests)
enum DistingNTRequestMessageType {
  // Sent messages (going TO the disting)
  takeScreenshot(0x01),
  setRealTimeClock(0x04),
  wake(0x07),
  sclFile(0x11),
  kbmFile(0x12),
  setDisplayMode(0x20),
  requestVersionString(0x22),
  requestNumAlgorithms(0x30),
  requestAlgorithmInfo(0x31),
  addAlgorithm(0x32),
  removeAlgorithm(0x33),
  loadPreset(0x34),
  newPreset(0x35),
  savePreset(0x36),
  moveAlgorithm(0x37),
  requestAlgorithm(0x40),
  requestPresetName(0x41),
  requestNumParameters(0x42),
  requestParameterInfo(0x43),
  requestAllParameterValues(0x44),
  requestParameterValue(0x45),
  setParameterValue(0x46),
  setPresetName(0x47),
  requestUnitStrings(0x48),
  requestEnumStrings(0x49),
  setFocus(0x4A),
  requestMappings(0x4B),
  setMapping(0x4D),
  setMidiMapping(0x4E),
  setI2CMapping(0x4F),
  requestParameterValueString(0x50),
  setSlotName(0x51),
  requestParameterPages(0x52),
  requestNumAlgorithmsInPreset(0x60),
  requestRouting(0x61),

  // Unknown/unsupported
  unknown(0xFF);

  final int value;

  const DistingNTRequestMessageType(this.value);

  /// Retrieve the enum variant from a raw message byte, if known.
  static DistingNTRequestMessageType fromByte(int b) {
    for (final t in DistingNTRequestMessageType.values) {
      if (t.value == b) return t;
    }
    return DistingNTRequestMessageType.unknown;
  }
}

/// Enum of all known 'Received
/// SysEx messages' (responses)
enum DistingNTRespMessageType {
  // Sent messages (coming FROM the disting)
  // (Some are the same IDs, but used as a response.)
  respNumAlgorithms(0x30),
  respAlgorithmInfo(0x31),
  respMessage(0x32),
  respScreenshot(0x33),
  respAlgorithm(0x40),
  respPresetName(0x41),
  respNumParameters(0x42),
  respParameterInfo(0x43),
  respAllParameterValues(0x44),
  respParameterValue(0x45),
  respUnitStrings(0x48),
  respEnumStrings(0x49),
  respMapping(0x4B),
  respParameterValueString(0x50),
  respParameterPages(0x52),
  respNumAlgorithmsInPreset(0x60),
  respRouting(0x61),

  // Unknown/unsupported
  unknown(0xFF);

  final int value;

  const DistingNTRespMessageType(this.value);

  /// Retrieve the enum variant from a raw message byte, if known.
  static DistingNTRespMessageType fromByte(int b) {
    for (final t in DistingNTRespMessageType.values) {
      if (t.value == b) return t;
    }
    return DistingNTRespMessageType.unknown;
  }
}

class Algorithm implements HasAlgorithmIndex {
  @override
  final int algorithmIndex;
  final String guid;
  final String name;

  Algorithm(
      {required this.algorithmIndex, required this.guid, required this.name});

  @override
  String toString() {
    return "Algorithm: index=$algorithmIndex guid=$guid name=$name";
  }
}

class Specification {
  final String name;
  final int min;
  final int max;
  final int defaultValue;
  final int type;

  Specification({
    required this.name,
    required this.min,
    required this.max,
    required this.defaultValue,
    required this.type,
  });

  @override
  String toString() {
    return "Specification: min=$min, max=$max, defaultValue=$defaultValue, type=$type";
  }
}

class ParameterInfo implements HasAlgorithmIndex, HasParameterNumber {
  @override
  final int algorithmIndex;
  @override
  final int parameterNumber;
  final int min;
  final int max;
  final int defaultValue;
  final int unit;
  final String name;
  final int powerOfTen;

  ParameterInfo({
    required this.algorithmIndex,
    required this.parameterNumber,
    required this.min,
    required this.max,
    required this.defaultValue,
    required this.unit,
    required this.name,
    required this.powerOfTen,
  });

  /// Factory constructor for default `filler` instance
  factory ParameterInfo.filler() {
    return ParameterInfo(
      algorithmIndex: -1,
      parameterNumber: -1,
      min: 0,
      max: 0,
      defaultValue: 0,
      unit: 0,
      name: '',
      powerOfTen: 0,
    );
  }

  @override
  String toString() {
    return "ParameterInfo: min=$min, max=$max, defaultValue=$defaultValue, unit=$unit, name=$name, powerOfTen=$powerOfTen";
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other.runtimeType != runtimeType) return false;

    return other is ParameterInfo &&
        other.algorithmIndex == algorithmIndex &&
        other.parameterNumber == parameterNumber &&
        other.min == min &&
        other.max == max &&
        other.defaultValue == defaultValue &&
        other.unit == unit &&
        other.name == name &&
        other.powerOfTen == powerOfTen;
  }

  @override
  int get hashCode => Object.hash(algorithmIndex, parameterNumber, min, max,
      defaultValue, unit, name, powerOfTen);

  String? getUnitString(List<String> units) {
    return unit > 0 ? units.elementAtOrNull(unit - 1) : null;
  }
}

class AllParameterValues implements HasAlgorithmIndex {
  @override
  final int algorithmIndex;
  final List<ParameterValue> values;

  AllParameterValues({required this.algorithmIndex, required this.values});
}

class ParameterPage {
  final String name;
  final List<int> parameters;

  ParameterPage({required this.name, required this.parameters});
}

class ParameterPages implements HasAlgorithmIndex {
  @override
  final int algorithmIndex;
  final List<ParameterPage> pages;

  ParameterPages({required this.algorithmIndex, required this.pages});

  factory ParameterPages.filler() {
    return ParameterPages(algorithmIndex: -1, pages: []);
  }

  @override
  String toString() {
    return "ParameterPages(algorithmIndex=$algorithmIndex, pages=[$pages])";
  }
}

class ParameterValue implements HasAlgorithmIndex, HasParameterNumber {
  @override
  final int algorithmIndex;
  @override
  final int parameterNumber;
  final int value;

  ParameterValue({
    required this.algorithmIndex,
    required this.parameterNumber,
    required this.value,
  });

  /// Factory constructor for default `filler` instance
  factory ParameterValue.filler() {
    return ParameterValue(
      algorithmIndex: -1,
      parameterNumber: -1,
      value: 0,
    );
  }

  @override
  String toString() {
    return "ParameterValue(algorithmIndex=$algorithmIndex, parameterNumber=$parameterNumber, value=$value)";
  }

  /// Override == operator for equality comparison
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    if (other is! ParameterValue) return false;

    return algorithmIndex == other.algorithmIndex &&
        parameterNumber == other.parameterNumber &&
        value == other.value;
  }

  /// Override hashCode for using instances in hash-based collections
  @override
  int get hashCode => Object.hash(algorithmIndex, parameterNumber, value);
}

class ParameterValueString implements HasAlgorithmIndex, HasParameterNumber {
  @override
  final int algorithmIndex;
  @override
  final int parameterNumber;
  final String value;

  ParameterValueString({
    required this.algorithmIndex,
    required this.parameterNumber,
    required this.value,
  });

  factory ParameterValueString.filler() {
    return ParameterValueString(
        algorithmIndex: -1, parameterNumber: -1, value: '');
  }

  // Write toString
  @override
  String toString() {
    return "ParameterValueString(algorithmIndex: $algorithmIndex, parameterNumber: $parameterNumber, value: '$value')";
  }
}

class Mapping implements HasAlgorithmIndex, HasParameterNumber {
  @override
  final int algorithmIndex;
  @override
  final int parameterNumber;
  final PackedMappingData packedMappingData;
  final int version;

  Mapping({
    required this.algorithmIndex,
    required this.parameterNumber,
    required this.packedMappingData,
    required this.version,
  });

  factory Mapping.filler() {
    return Mapping(
        algorithmIndex: -1,
        parameterNumber: -1,
        packedMappingData: PackedMappingData.filler(),
        version: -1);
  }

  @override
  String toString() {
    return "Mapping(algorithmIndex: $algorithmIndex, parameterNumber: $parameterNumber, packedMappingData: $packedMappingData, version: $version)";
  }
}

class ParameterEnumStrings implements HasAlgorithmIndex, HasParameterNumber {
  @override
  final int algorithmIndex;
  @override
  final int parameterNumber;
  final List<String> values;

  ParameterEnumStrings({
    required this.algorithmIndex,
    required this.parameterNumber,
    required this.values,
  });

  factory ParameterEnumStrings.filler() {
    return ParameterEnumStrings(
        algorithmIndex: -1, parameterNumber: -1, values: List.empty());
  }

  @override
  String toString() {
    return "ParameterEnumStrings(algorithmIndex: $algorithmIndex, parameterNumber: $parameterNumber, values: $values)";
  }
}

class AlgorithmInfo implements HasAlgorithmIndex {
  @override
  final int algorithmIndex;
  final String guid;
  final int numSpecifications;
  final List<Specification> specifications;
  final String name;

  AlgorithmInfo({
    required this.algorithmIndex,
    required this.guid,
    required this.numSpecifications,
    required this.specifications,
    required this.name,
  });

  factory AlgorithmInfo.filler() {
    return AlgorithmInfo(
      algorithmIndex: -1,
      guid: "",
      numSpecifications: 0,
      specifications: List.empty(),
      name: "name",
    );
  }

  @override
  String toString() {
    return "AlgorithmInfo: algorithmIndex=$algorithmIndex guid=$guid name=$name specificationName=$name specifications=$specifications";
  }
}

class RoutingInfo implements HasAlgorithmIndex {
  @override
  final int algorithmIndex;
  final List<int> routingInfo;

  RoutingInfo({required this.algorithmIndex, required this.routingInfo});

  factory RoutingInfo.filler() {
    return RoutingInfo(
      algorithmIndex: -1,
      routingInfo: List.empty(),
    );
  }
}

class NumParameters implements HasAlgorithmIndex {
  @override
  final int algorithmIndex;
  final int numParameters;

  NumParameters({required this.algorithmIndex, required this.numParameters});

  @override
  String toString() {
    return "NumParameters: index=$algorithmIndex numParameters=$numParameters";
  }
}

class DistingNT {
  final MidiCommand midiCommand;
  final MidiDevice device;
  final int sysExId;

  DistingNT({
    required this.midiCommand,
    required this.device,
    required this.sysExId,
  });

  /// Helper to create the standard SysEx header for a disting NT message,
  /// given the 'SysEx ID' (the module’s own ID in its settings).
  static List<int> _buildHeader(int distingSysExId) {
    return [
      kSysExStart, ...kExpertSleepersManufacturerId, // 00 21 27
      kDistingNTPrefix, // 6D
      (distingSysExId & 0x7F), // <SysEx ID> is 7-bit
    ];
  }

  /// Conclude the SysEx message.
  static List<int> _buildFooter() {
    return [kSysExEnd];
  }

  static int decode8(Uint8List payload) {
    return payload[0].toInt();
  }

  static List<int> encode16(int value) {
    // Ensure 16-bit range
    final int v = value & 0xFFFF;
    final int ms2 = (v >> 14) & 0x03; // top 2 bits
    final int mid7 = (v >> 7) & 0x7F; // next 7 bits
    final int ls7 = v & 0x7F; // final 7 bits
    return [ms2, mid7, ls7];
  }

  /// The reverse: parse 3 bytes of 7-bit data into a 16-bit integer.
  static int decode16(List<int> data, int offset) {
    var v =
        (data[offset + 0] << 14) | (data[offset + 1] << 7) | (data[offset + 2]);
    // Ensure the value is treated as a signed 16-bit integer
    if (v & 0x8000 != 0) {
      v -= 0x10000;
    }
    return v;
  }

  /// Similar approach for 32-bit if needed (e.g. set real-time clock).
  /// The doc says "32 bit number" but doesn't explicitly define
  /// 7-bit splitting. The existing tools do typically use 7-bit expansions.
  /// Here is a hypothetical approach:
  static List<int> encode32(int value) {
    // Force into 32-bit range (in Dart, int can be bigger).
    final v = value & 0xFFFFFFFF;

    // The JS shifts by multiples of 7 bits.
    // That implies each of the "middle" bytes is storing 7 bits,
    // and the last byte stores up to 4 bits (to make a total of 32).
    //
    // bit layout: [bits 28..31] [bits 21..27] [bits 14..20] [bits 7..13] [bits 0..6]
    //
    // Starting from the least-significant bits:
    final b0 = v & 0x7F; // bits 0..6
    final b1 = (v >> 7) & 0x7F; // bits 7..13
    final b2 = (v >> 14) & 0x7F; // bits 14..20
    final b3 = (v >> 21) & 0x7F; // bits 21..27
    final b4 = (v >> 28) & 0x0F; // bits 28..31

    return [b0, b1, b2, b3, b4];
  }

  static int decode32(List<int> bytes, int offset) {
    final b0 = bytes[offset + 0];
    final b1 = bytes[offset + 1];
    final b2 = bytes[offset + 2];
    final b3 = bytes[offset + 3];
    final b4 = bytes[offset + 4];

    // The & 0xFF is optional in Dart if you're sure each value is already 0..255,
    // but including it ensures we're only using the lower 8 bits of each byte.
    return (b0 & 0xFF) |
        ((b1 & 0xFF) << 7) |
        ((b2 & 0xFF) << 14) |
        ((b3 & 0xFF) << 21) |
        ((b4 & 0xFF) << 28);
  }

  /// Build a 'Take screenshot' SysEx message.
  static Uint8List encodeTakeScreenshot(int distingSysExId) {
    final bytes = <int>[
      ..._buildHeader(distingSysExId),
      DistingNTRequestMessageType.takeScreenshot.value,
      ..._buildFooter(),
    ];
    return Uint8List.fromList(bytes);
  }

  /// Build a 'Wake' SysEx message.
  static Uint8List encodeWake(int distingSysExId) {
    final bytes = <int>[
      ..._buildHeader(distingSysExId),
      DistingNTRequestMessageType.wake.value,
      ..._buildFooter(),
    ];
    return Uint8List.fromList(bytes);
  }

  /// Build a 'Set real-time clock' SysEx message.
  static Uint8List encodeSetRealTimeClock(
      int distingSysExId, int unixTimeSeconds) {
    final timeBytes = encode32(unixTimeSeconds);
    final bytes = <int>[
      ..._buildHeader(distingSysExId),
      DistingNTRequestMessageType.setRealTimeClock.value,
      ...timeBytes,
      ..._buildFooter(),
    ];
    return Uint8List.fromList(bytes);
  }

  /// Example: Build a 'Request version string' SysEx message.
  static Uint8List encodeRequestVersionString(int distingSysExId) {
    final bytes = <int>[
      ..._buildHeader(distingSysExId),
      DistingNTRequestMessageType.requestVersionString.value,
      ..._buildFooter(),
    ];
    return Uint8List.fromList(bytes);
  }

  static Uint8List encodeNumAlgorithmsInPreset(int distingSysExId) {
    final bytes = <int>[
      ..._buildHeader(distingSysExId),
      DistingNTRequestMessageType.requestNumAlgorithmsInPreset.value,
      ..._buildFooter(),
    ];
    return Uint8List.fromList(bytes);
  }

  static Uint8List encodeRequestPresetName(int distingSysExId) {
    final bytes = <int>[
      ..._buildHeader(distingSysExId),
      DistingNTRequestMessageType.requestPresetName.value,
      ..._buildFooter(),
    ];
    return Uint8List.fromList(bytes);
  }

  static Uint8List encodeRequestAlgorithmGuid(int distingSysExId, int index) {
    final bytes = <int>[
      ..._buildHeader(distingSysExId),
      DistingNTRequestMessageType.requestAlgorithm.value,
      (index & 0x7F),
      ..._buildFooter(),
    ];
    return Uint8List.fromList(bytes);
  }

  static Uint8List encodeRequestRoutingInformation(
      int distingSysExId, int index) {
    final bytes = <int>[
      ..._buildHeader(distingSysExId),
      DistingNTRequestMessageType.requestRouting.value,
      (index & 0x7F),
      ..._buildFooter(),
    ];
    return Uint8List.fromList(bytes);
  }

  static Uint8List encodeRequestAlgorithmInfo(int distingSysExId, int index) {
    final bytes = <int>[
      ..._buildHeader(distingSysExId),
      DistingNTRequestMessageType.requestAlgorithmInfo.value,
      ...encode16(index),
      ..._buildFooter(),
    ];
    return Uint8List.fromList(bytes);
  }

  static Uint8List encodeRequestAllParameterValues(
      int distingSysExId, int index) {
    final bytes = <int>[
      ..._buildHeader(distingSysExId),
      DistingNTRequestMessageType.requestAllParameterValues.value,
      index & 0x7F,
      ..._buildFooter(),
    ];
    return Uint8List.fromList(bytes);
  }

  static Uint8List encodeRequestNumAlgorithms(int distingSysExId) {
    final bytes = <int>[
      ..._buildHeader(distingSysExId),
      DistingNTRequestMessageType.requestNumAlgorithms.value,
      ..._buildFooter(),
    ];
    return Uint8List.fromList(bytes);
  }

  static Uint8List encodeRequestNumParameters(
      int distingSysExId, int algorithmIndex) {
    final bytes = <int>[
      ..._buildHeader(distingSysExId),
      DistingNTRequestMessageType.requestNumParameters.value,
      algorithmIndex & 0x7F,
      ..._buildFooter(),
    ];
    return Uint8List.fromList(bytes);
  }

  static Uint8List encodeRequestParameterPages(
      int distingSysExId, int algorithmIndex) {
    final bytes = <int>[
      ..._buildHeader(distingSysExId),
      DistingNTRequestMessageType.requestParameterPages.value,
      algorithmIndex & 0x7F,
      ..._buildFooter(),
    ];
    return Uint8List.fromList(bytes);
  }

  static Uint8List encodeRequestParameterInfo(
      int distingSysExId, int algorithmIndex, int parameterNumber) {
    final bytes = <int>[
      ..._buildHeader(distingSysExId),
      DistingNTRequestMessageType.requestParameterInfo.value,
      algorithmIndex & 0x7F,
      ...encode16(parameterNumber),
      ..._buildFooter(),
    ];
    return Uint8List.fromList(bytes);
  }

  static Uint8List encodeRequestParameterValue(
      int distingSysExId, int algorithmIndex, int parameterNumber) {
    final bytes = <int>[
      ..._buildHeader(distingSysExId),
      DistingNTRequestMessageType.requestParameterValue.value,
      algorithmIndex & 0x7F,
      ...encode16(parameterNumber),
      ..._buildFooter(),
    ];
    return Uint8List.fromList(bytes);
  }

  static Uint8List encodeRequestUnitStrings(int distingSysExId) {
    final bytes = <int>[
      ..._buildHeader(distingSysExId),
      DistingNTRequestMessageType.requestUnitStrings.value,
      ..._buildFooter(),
    ];
    return Uint8List.fromList(bytes);
  }

  static Uint8List encodeRequestEnumStrings(
      int distingSysExId, int algorithmIndex, int parameterNumber) {
    final bytes = <int>[
      ..._buildHeader(distingSysExId),
      DistingNTRequestMessageType.requestEnumStrings.value,
      algorithmIndex & 0x7F,
      ...encode16(parameterNumber),
      ..._buildFooter(),
    ];
    return Uint8List.fromList(bytes);
  }

  static Uint8List encodeRequestMappings(
      int distingSysExId, int algorithmIndex, int parameterNumber) {
    final bytes = <int>[
      ..._buildHeader(distingSysExId),
      DistingNTRequestMessageType.requestMappings.value,
      algorithmIndex & 0x7F,
      ...encode16(parameterNumber),
      ..._buildFooter(),
    ];
    return Uint8List.fromList(bytes);
  }

  static Uint8List encodeRequestParameterValueString(
      int distingSysExId, int algorithmIndex, int parameterNumber) {
    final bytes = <int>[
      ..._buildHeader(distingSysExId),
      DistingNTRequestMessageType.requestParameterValueString.value,
      algorithmIndex & 0x7F,
      ...encode16(parameterNumber),
      ..._buildFooter(),
    ];
    return Uint8List.fromList(bytes);
  }

  static Uint8List encodeSetParameterValue(
    int distingSysExId,
    int algorithmIndex,
    int parameterNumber,
    int value,
  ) {
    final bytes = <int>[
      ..._buildHeader(distingSysExId),
      DistingNTRequestMessageType.setParameterValue.value,
      algorithmIndex & 0x7F,
      ...encode16(parameterNumber),
      ...encode16(value),
      ..._buildFooter(),
    ];
    return Uint8List.fromList(bytes);
  }

  static Uint8List encodeAddAlgorithm(
      int distingSysExId, String guid, List<int> specifications) {
    final bytes = <int>[
      ..._buildHeader(distingSysExId),
      DistingNTRequestMessageType.addAlgorithm.value,
      ...guid.codeUnits,
      for (int i = 0; i < specifications.length; i++)
        ...encode16(specifications[i]),
      ..._buildFooter(),
    ];
    return Uint8List.fromList(bytes);
  }

  static Uint8List encodeSendSlotName(
      int distingSysExId, int algorithmIndex, String name) {
    final bytes = <int>[
      ..._buildHeader(distingSysExId),
      DistingNTRequestMessageType.setSlotName.value,
      algorithmIndex & 0x7F,
      ...encodeNullTerminatedAscii(name),
      ..._buildFooter(),
    ];
    return Uint8List.fromList(bytes);
  }

  static Uint8List encodeRemoveAlgorithm(
      int distingSysExId, int algorithmIndex) {
    final bytes = <int>[
      ..._buildHeader(distingSysExId),
      DistingNTRequestMessageType.removeAlgorithm.value,
      algorithmIndex & 0x7F,
      ..._buildFooter(),
    ];
    return Uint8List.fromList(bytes);
  }

  static Uint8List encodeSetFocus(
      int distingSysExId, int algorithmIndex, int parameterNumber) {
    final bytes = <int>[
      ..._buildHeader(distingSysExId),
      DistingNTRequestMessageType.setFocus.value,
      algorithmIndex & 0x7F,
      ...encode16(parameterNumber),
      ..._buildFooter(),
    ];
    return Uint8List.fromList(bytes);
  }

  static Uint8List encodeSetPresetName(int sysExId, String newName) {
    final bytes = <int>[
      ..._buildHeader(sysExId),
      DistingNTRequestMessageType.setPresetName.value,
      ...encodeNullTerminatedAscii(newName),
      ..._buildFooter(),
    ];
    return Uint8List.fromList(bytes);
  }

  // The option value can be 0 (prompt for file overwrite), 1 (never overwrite), or 2
  // (always overwrite)
  static Uint8List encodeSavePreset(int sysExId, int option) {
    final bytes = <int>[
      ..._buildHeader(sysExId),
      DistingNTRequestMessageType.savePreset.value,
      option & 0x7F,
      ..._buildFooter(),
    ];
    return Uint8List.fromList(bytes);
  }

  static Uint8List encodeMoveAlgorithm(int sysExId, int algorithmIndex, int i) {
    final bytes = <int>[
      ..._buildHeader(sysExId),
      DistingNTRequestMessageType.moveAlgorithm.value,
      algorithmIndex & 0x7F,
      i & 0x7F,
      ..._buildFooter(),
    ];
    return Uint8List.fromList(bytes);
  }

  static Uint8List encodeNewPreset(int sysExId) {
    final bytes = <int>[
      ..._buildHeader(sysExId),
      DistingNTRequestMessageType.newPreset.value,
      ..._buildFooter(),
    ];
    return Uint8List.fromList(bytes);
  }

  static Uint8List encodeLoadPreset(
      int sysExId, String presetName, bool append) {
    final bytes = <int>[
      ..._buildHeader(sysExId),
      DistingNTRequestMessageType.loadPreset.value,
      append ? 1 : 0,
      ...encodeNullTerminatedAscii(presetName),
      ..._buildFooter(),
    ];
    return Uint8List.fromList(bytes);
  }

  static Uint8List encodeSetCVMapping(int sysExId, int algorithmIndex,
      int parameterNumber, PackedMappingData data) {
    final bytes = <int>[
      ..._buildHeader(sysExId),
      DistingNTRequestMessageType.setMapping.value,
      algorithmIndex & 0x7F,
      ...encode16(parameterNumber),
      1,
      // version
      ...data.encodeCVPackedData(),
      ..._buildFooter(),
    ];
    return Uint8List.fromList(bytes);
  }

  static Uint8List encodeSetMIDIMapping(int sysExId, int algorithmIndex,
      int parameterNumber, PackedMappingData data) {
    final bytes = <int>[
      ..._buildHeader(sysExId),
      DistingNTRequestMessageType.setMidiMapping.value,
      algorithmIndex & 0x7F,
      ...encode16(parameterNumber),
      1,
      // version
      ...data.encodeMidiPackedData(),
      ..._buildFooter(),
    ];
    return Uint8List.fromList(bytes);
  }

  static Uint8List encodeSetI2CMapping(int sysExId, int algorithmIndex,
      int parameterNumber, PackedMappingData data) {
    final bytes = <int>[
      ..._buildHeader(sysExId),
      DistingNTRequestMessageType.setI2CMapping.value,
      algorithmIndex & 0x7F,
      ...encode16(parameterNumber),
      1,
      // version
      ...data.encodeI2CPackedData(),
      ..._buildFooter(),
    ];
    return Uint8List.fromList(bytes);
  }

  static Uint8List encodeSetDisplayMode(int sysExId, DisplayMode displayMode) {
    final bytes = <int>[
      ..._buildHeader(sysExId),
      DistingNTRequestMessageType.setDisplayMode.value,
      displayMode.value & 0x7F,
      ..._buildFooter()
    ];
    return Uint8List.fromList(bytes);
  }

  static AlgorithmInfo decodeAlgorithmInfo(Uint8List data) {
    int offset = 0;

    // 1) Decode the 16-bit algorithm index (2 bytes).
    final algorithmIndex = decode16(data, offset);
    offset += 2;

    // 2) Skip 1 byte at index 2 (if your data format specifies this gap).
    offset += 1;

    // 3) Decode the 4-byte GUID.
    final guid = String.fromCharCodes(data.sublist(offset, offset + 4));
    offset += 4;

    // 4) Decode the number of specifications (1 byte).
    final numSpecifications = data[offset];
    offset += 1;

    // 5) Decode each specification, each occupying 3 + 3 + 3 + 1 = 10 bytes.
    final specs = List.generate(numSpecifications, (_) {
      final min = decode16(data, offset);
      offset += 3;

      final max = decode16(data, offset);
      offset += 3;

      final defaultValue = decode16(data, offset);
      offset += 3;

      final type = data[offset];
      offset += 1;

      return Specification(
        min: min,
        max: max,
        defaultValue: defaultValue,
        type: type,
        name: "", // We'll fill in names next
      );
    });

    // 6) Decode the main algorithm name (null-terminated ASCII).
    final nameStr = decodeNullTerminatedAscii(data, offset);
    offset = nameStr.nextOffset;
    final algorithmName = nameStr.value;

    // 7) Decode each specification’s display name (also null-terminated).
    final specNames = List.generate(numSpecifications, (_) {
      final str = decodeNullTerminatedAscii(data, offset);
      offset = str.nextOffset;
      return str.value;
    });

    // 8) Attach the names to the corresponding Specifications.
    final updatedSpecs = specs.asMap().entries.map((entry) {
      final i = entry.key;
      final spec = entry.value;
      return Specification(
        min: spec.min,
        max: spec.max,
        defaultValue: spec.defaultValue,
        type: spec.type,
        name: specNames[i],
      );
    }).toList();

    // 9) Build and return the final AlgorithmInfo object.
    return AlgorithmInfo(
      algorithmIndex: algorithmIndex,
      guid: guid,
      numSpecifications: numSpecifications,
      specifications: updatedSpecs,
      name: algorithmName,
    );
  }

  static NumParameters decodeNumParameters(Uint8List data) {
    var algorithmIndex = data[0].toInt();
    var numParameters = decode16(data, 1);

    return NumParameters(
      algorithmIndex: algorithmIndex,
      numParameters: numParameters,
    );
  }

  static ParameterPages decodeParameterPages(Uint8List data) {
    var algorithmIndex = data[0].toInt();
    var numPages = data[1].toInt();
    int offset = 2;
    return ParameterPages(
      algorithmIndex: algorithmIndex,
      pages: List.generate(
        numPages,
        (_) {
          final strInfo = decodeNullTerminatedAscii(data, offset);
          offset = strInfo.nextOffset;
          final name = strInfo.value;
          final numParameters = data[offset++];
          final parameterNumbers = List.generate(numParameters, (_) {
            return data[offset++] << 7 | data[offset++];
          });
          return ParameterPage(name: name, parameters: parameterNumbers);
        },
      ),
    );
  }

  /// A generic function to parse an incoming SysEx message from the disting NT.
  /// Returns null if it's not a valid or recognized message.
  /// Otherwise returns a structure describing the message type & payload.
  static DistingNTParsedMessage? decodeDistingNTSysEx(Uint8List data) {
    // 1) Basic sanity check
    if (data.length < 6) return null;
    if (data.first != kSysExStart || data.last != kSysExEnd) return null;

    // 2) Check manufacturer ID
    if (data[1] != kExpertSleepersManufacturerId[0] ||
        data[2] != kExpertSleepersManufacturerId[1] ||
        data[3] != kExpertSleepersManufacturerId[2]) {
      return null;
    }

    // 3) Check 6D prefix
    if (data[4] != kDistingNTPrefix) return null;

    // 4) The next byte is the SysEx ID for the module
    final distingSysExId = data[5] & 0x7F;
    if (data.length < 8) {
      // Must have at least one more byte for the message type
      return null;
    }

    // 5) The next byte after that is the message type
    final messageTypeByte = data[6] & 0x7F;
    final msgType = DistingNTRespMessageType.fromByte(messageTypeByte);

    // 6) The payload is everything between that byte and the final 0xF7,
    // but usually after the messageType we parse based on the command.
    final payload = data.sublist(7, data.length - 1); // slice out the end

    return DistingNTParsedMessage(
      sysExId: distingSysExId,
      messageType: msgType,
      payload: payload,
      rawBytes: data,
    );
  }

  void sendSysExMessage(
      MidiCommand midiCommand, MidiDevice device, Uint8List data) {
    // Send the SysEx message
    midiCommand.sendData(
      data, deviceId: device.id, // Specify the target device ID
      timestamp: null, // Timestamp if needed, or leave as null
    );
  }

  static Algorithm decodeAlgorithm(Uint8List algorithmData) {
    return Algorithm(
      algorithmIndex: algorithmData[0].toInt(),
      guid: String.fromCharCodes(algorithmData.sublist(1, 5)),
      name: String.fromCharCodes(
        algorithmData.sublist(5).takeWhile((value) => value != 0),
      ).trim(),
    );
  }

  // Generates a bitmap from the screenshot response payload
  static Uint8List decodeBitmap(Uint8List screenshotData) {
    try {
      // Define screenshot properties (adjust based on actual format)
      const int width = 256; // Example width
      const int height = 64; // Example height
      const int borderWidth = 5; // Border size in pixels

      const int newWidth = width + 2 * borderWidth;
      const int newHeight = height + 2 * borderWidth;

      // Create a new image with the border dimensions
      final img.Image borderedImage =
          img.Image(width: newWidth, height: newHeight);

      // Fill the entire image with a border color (e.g., black)
      final img.Color borderColor = img.ColorFloat16.rgb(0, 0, 0); // Black
      for (int y = 0; y < newHeight; y++) {
        for (int x = 0; x < newWidth; x++) {
          borderedImage.setPixel(x, y, borderColor);
        }
      }

      // Create an empty image with specified dimensions
      final img.Image image = img.Image(width: width, height: height);

      // Assuming screenshotData is raw RGB data
      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          int pixelIndex = y * width + x;
          if (pixelIndex < screenshotData.length) {
            double v = screenshotData[pixelIndex].toDouble();
            v = pow(v * 0.066666666666667, 0.45)
                .toDouble(); // Apply gamma correction
            v = pow(v, 0.45).toDouble(); // Apply gamma correction again
            v = v * 255; // Scale to 0–255
            int intensity = v.clamp(0, 255).toInt();
            img.Color color = img.ColorFloat16.rgb(0, intensity, intensity);
            image.setPixel(x, y, color);
          }
        }
      }

      // Copy the original image into the center of the bordered image
      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          img.Pixel originalPixel = image.getPixel(x, y);
          borderedImage.setPixel(
              x + borderWidth, y + borderWidth, originalPixel);
        }
      }

      // Encode the image as PNG
      return Uint8List.fromList(img.encodePng(borderedImage));
    } catch (e) {
      return Uint8List(0); // Return empty on error
    }
  }

  static String decodeMessage(Uint8List messagePayload, {int offset = 0}) {
    return decodeNullTerminatedAscii(messagePayload, offset).value;
  }

  //   43H – Parameter info
  //   F0 00 21 27 6D <SysEx ID> 43 <algorithm index> <16 bit parameter number> <16 bit minimum>
  // <16 bit maximum> <16 bit default> <unit> <ASCII string> F7
  // Contains information for the given parameter in the indexed algorithm.
  static ParameterInfo decodeParameterInfo(Uint8List messagePayload) {
    return ParameterInfo(
      algorithmIndex: decode8(messagePayload.sublist(0, 1)),
      parameterNumber: decode16(messagePayload, 1),
      min: decode16(messagePayload, 4),
      max: decode16(messagePayload, 7),
      defaultValue: decode16(messagePayload, 10),
      unit: decode8(messagePayload.sublist(13, 14)),
      name: decodeNullTerminatedAscii(messagePayload, 14).value,
      powerOfTen: messagePayload.last,
    );
  }

  static AllParameterValues decodeAllParameterValues(Uint8List message) {
    var algorithmIndex = decode8(message.sublist(0, 1));
    return AllParameterValues(
      algorithmIndex: algorithmIndex,
      values: [
        for (int offset = 1; offset < message.length; offset += 3)
          ParameterValue(
              algorithmIndex: algorithmIndex,
              parameterNumber: offset ~/ 3,
              value: decode16(message, offset)),
      ],
    );
  }

  static ParameterValue decodeParameterValue(Uint8List message) {
    return ParameterValue(
      algorithmIndex: decode8(message.sublist(0, 1)),
      parameterNumber: decode16(message, 1),
      value: decode16(message, 4),
    );
  }

  static List<String> decodeStrings(Uint8List message) {
    int numStrings = decode8(message);
    int start = 1;
    return List.generate(numStrings, (i) {
      var value = decodeNullTerminatedAscii(message, start);
      start = value.nextOffset;
      return value.value;
    });
  }

  static ParameterEnumStrings decodeEnumStrings(Uint8List message) {
    int start = 5;
    return ParameterEnumStrings(
      algorithmIndex: decode8(message),
      parameterNumber: decode16(message, 1),
      values: List.generate(decode8(message.sublist(4, 5)), (i) {
        ParseResult result = decodeNullTerminatedAscii(message, start);
        start = result.nextOffset;
        return result.value;
      }),
    );
  }

  static Mapping decodeMapping(Uint8List message) {
    return Mapping(
      algorithmIndex: decode8(message),
      parameterNumber: decode16(message, 1),
      version: decode8(message.sublist(4, 5)),
      packedMappingData: PackedMappingData.fromBytes(message.sublist(5)),
    );
  }

  static ParameterValueString decodeParameterValueString(Uint8List message) {
    return ParameterValueString(
      algorithmIndex: decode8(message.sublist(0, 1)),
      parameterNumber: decode16(message, 1),
      value: decodeNullTerminatedAscii(message, 4).value,
    );
  }

  static int decodeNumberOfAlgorithms(Uint8List message) {
    return decode16(message, 0);
  }

  static int decodeNumberOfAlgorithmsInPreset(Uint8List message) {
    return decode8(message);
  }

  static RoutingInfo decodeRoutingInformation(Uint8List message) {
    int offset = 1;
    return RoutingInfo(
      algorithmIndex: decode8(message.sublist(0, 1)),
      routingInfo: List.generate(6, (i) {
        final value = decode32(message, offset);
        offset += 5;
        return value;
      }),
    );
  }
}

/// A simple container for the parsed result.
class DistingNTParsedMessage {
  final int sysExId; // Which module ID
  final DistingNTRespMessageType messageType;
  final Uint8List payload; // The raw data after messageType
  final Uint8List rawBytes; // Full SysEx

  DistingNTParsedMessage({
    required this.sysExId,
    required this.messageType,
    required this.payload,
    required this.rawBytes,
  });

  @override
  String toString() {
    return 'DistingNTParsedMessage(sysExId: $sysExId, '
        'type: $messageType, payloadLen: ${payload.length}, raw: ${rawBytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join(' ')})';
  }
}
