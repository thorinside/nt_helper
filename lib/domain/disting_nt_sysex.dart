import 'package:nt_helper/models/packed_mapping_data.dart';
import 'dart:typed_data';

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
    if (unit <= 0 || unit > units.length) return null;
    return units[unit - 1];
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
      algorithmIndex: -1,
      parameterNumber: -1,
      value: '',
    );
  }

  @override
  String toString() {
    return "ParameterValueString(algorithmIndex: $algorithmIndex, parameterNumber: $parameterNumber, value: $value)";
  }
}

class AllParameterValues implements HasAlgorithmIndex {
  @override
  final int algorithmIndex;
  final List<ParameterValue> values;

  AllParameterValues({required this.algorithmIndex, required this.values});

  @override
  String toString() {
    return "AllParameterValues: index=$algorithmIndex values=$values";
  }
}

class Mapping implements HasAlgorithmIndex, HasParameterNumber {
  @override
  final int algorithmIndex;
  @override
  final int parameterNumber;
  final PackedMappingData packedMappingData;

  const Mapping(
      {required this.algorithmIndex,
      required this.parameterNumber,
      required this.packedMappingData});

  factory Mapping.filler() {
    return Mapping(
        algorithmIndex: -1,
        parameterNumber: -1,
        packedMappingData: PackedMappingData.filler());
  }
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
}

class AlgorithmInfo {
  final int algorithmIndex;
  final String name;
  final String guid;
  final List<Specification> specifications;

  AlgorithmInfo(
      {required this.algorithmIndex,
      required this.name,
      required this.guid,
      required this.specifications});

  int get numSpecifications {
    return specifications.length;
  }

  @override
  String toString() {
    return "AlgorithmInfo: name=$name, guid=$guid, specs=$specifications";
  }
}

class Algorithm {
  final int algorithmIndex;
  final String guid;
  final String name;

  Algorithm({
    required this.algorithmIndex,
    required this.guid,
    required this.name,
  });

  Algorithm copyWith({int? algorithmIndex}) {
    return Algorithm(
        algorithmIndex: algorithmIndex ?? this.algorithmIndex,
        guid: guid,
        name: name);
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
      routingInfo: List.filled(6, 0),
    );
  }
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
  requestCpuUsage(0x62),
  sdCardOperation(0x7A),

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
  respCpuUsage(0x62),

  // SD Card responses (virtual, mapped from 0x7A by the parser)
  respDirectoryListing(0x7B),
  respFileChunk(0x7C),
  respSdStatus(0x7D),

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

class DistingNTSysExMessage {
  final DistingNTRespMessageType messageType;
  final Uint8List payload;

  const DistingNTSysExMessage({
    required this.messageType,
    required this.payload,
  });

  factory DistingNTSysExMessage.fromResponse(
      DistingNTRespMessageType responseMessageType, Uint8List response) {
    final messageType = responseMessageType;
    // In the original, the payload started from index 6 (0x7A).
    // Now, it should start from index 9 (after 0x7A, status, and command).
    // And it should end before the checksum and the F7 byte.
    // The Javascript `data.slice(9, -1)` means it goes from index 9 up to
    // (but not including) the last element. The last element in the raw MIDI message is 0xF7.
    // The element before 0xF7 is the checksum. So, -1 excludes F7, and the checksum is
    // also excluded.
    final payload =
        Uint8List.fromList(response.sublist(9, response.length - 1));

    return DistingNTSysExMessage(
      messageType: messageType,
      payload: payload,
    );
  }
}
