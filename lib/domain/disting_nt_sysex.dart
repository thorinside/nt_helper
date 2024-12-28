import 'dart:math';
import 'dart:typed_data';

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

/// Enum of all known 'Sent SysEx messages' (requests)
enum DistingNTRequestMessageType {
  // Sent messages (going TO the disting)
  takeScreenshot(0x01),
  setRealTimeClock(0x04),
  wake(0x07),
  sclFile(0x11),
  kbmFile(0x12),
  requestVersionString(0x22),
  requestNumAlgorithms(0x30),
  requestAlgorithmInfo(0x31),
  addAlgorithm(0x32),
  removeAlgorithm(0x33),
  loadPreset(0x34),
  newPreset(0x35),
  savePreset(0x36),
  moveAlgorithm(0x37),
  requestAlgorithmGuid(0x40),
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
  respAlgorithmGuid(0x40),
  respPresetName(0x41),
  respNumParameters(0x42),
  respParameterInfo(0x43),
  respAllParameterValues(0x44),
  respParameterValue(0x45),
  respUnitStrings(0x48),
  respEnumStrings(0x49),
  respMapping(0x4B),
  respParameterValueString(0x50),
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

class AlgorithmGuid implements HasAlgorithmIndex {
  @override
  final int algorithmIndex;
  final String guid;

  AlgorithmGuid({required this.algorithmIndex, required this.guid});

  @override
  String toString() {
    return "AlgorithmGuid: index=$algorithmIndex guid=$guid";
  }
}

class Specification {
  final int min;
  final int max;
  final int defaultValue;
  final int type;

  Specification(
      {required this.min,
      required this.max,
      required this.defaultValue,
      required this.type});

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

  ParameterInfo(
      {required this.algorithmIndex,
      required this.parameterNumber,
      required this.min,
      required this.max,
      required this.defaultValue,
      required this.unit,
      required this.name});

  /// Factory constructor for default `filler` instance
  factory ParameterInfo.filler() {
    return ParameterInfo(
      algorithmIndex: -1,
      parameterNumber: -1,
      min: 0,
      max: 0,
      defaultValue: 0,
      unit: 0,
      name: 'Filler',
    );
  }

  @override
  String toString() {
    return "ParameterInfo: min=$min, max=$max, defaultValue=$defaultValue, unit=$unit, name=$name";
  }
}

class AllParameterValues implements HasAlgorithmIndex {
  @override
  final int algorithmIndex;
  final List<int> values;

  AllParameterValues({required this.algorithmIndex, required this.values});
}

class ParameterValue implements HasAlgorithmIndex, HasParameterNumber {
  @override
  final int algorithmIndex;
  @override
  final int parameterNumber;
  final int value;

  ParameterValue(
      {required this.algorithmIndex,
      required this.parameterNumber,
      required this.value});

  /// Factory constructor for default `filler` instance
  factory ParameterValue.filler() {
    return ParameterValue(
      algorithmIndex: -1,
      parameterNumber: -1,
      value: 0,
    );
  }
}

class ParameterValueString implements HasAlgorithmIndex, HasParameterNumber {
  @override
  final int algorithmIndex;
  @override
  final int parameterNumber;
  final String value;

  ParameterValueString(
      {required this.algorithmIndex,
      required this.parameterNumber,
      required this.value});

  factory ParameterValueString.filler() {
    return ParameterValueString(
        algorithmIndex: -1, parameterNumber: -1, value: "filler");
  }
}

class Mapping implements HasAlgorithmIndex, HasParameterNumber {
  @override
  final int algorithmIndex;
  @override
  final int parameterNumber;
  final PackedMappingData packedMappingData;
  final int version;

  Mapping(
      {required this.algorithmIndex,
      required this.parameterNumber,
      required this.packedMappingData,
      required this.version});

  factory Mapping.filler() {
    return Mapping(
        algorithmIndex: -1,
        parameterNumber: -1,
        packedMappingData: PackedMappingData.filler(),
        version: -1);
  }
}

class ParameterEnumStrings implements HasAlgorithmIndex, HasParameterNumber {
  @override
  final int algorithmIndex;
  @override
  final int parameterNumber;
  final List<String> values;

  ParameterEnumStrings(
      {required this.algorithmIndex,
      required this.parameterNumber,
      required this.values});

  factory ParameterEnumStrings.filler() {
    return ParameterEnumStrings(
        algorithmIndex: -1, parameterNumber: -1, values: List.empty());
  }
}

class AlgorithmInfo implements HasAlgorithmIndex {
  @override
  final int algorithmIndex;
  final String guid;
  final int numSpecifications;
  final List<Specification> specifications;
  final String name;
  final String specificationName;

  AlgorithmInfo(
      {required this.algorithmIndex,
      required this.guid,
      required this.numSpecifications,
      required this.specifications,
      required this.name,
      required this.specificationName});

  factory AlgorithmInfo.filler() {
    return AlgorithmInfo(
      algorithmIndex: -1,
      guid: "",
      numSpecifications: 0,
      specifications: List.empty(),
      name: "name",
      specificationName: "specificationName",
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
      kSysExStart,
      ...kExpertSleepersManufacturerId, // 00 21 27
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

  /// A small utility to pack a 16-bit integer into 3 bytes of 7-bit data,
  /// as described in the doc:
  ///
  ///  <most significant 2 bits> <middle 7 bits> <least significant 7 bits>
  static List<int> encode16(int value) {
    // Ensure 16-bit range
    final int v = value & 0xFFFF;
    final int ms2 = (v >> 14) & 0x03; // top 2 bits
    final int mid7 = (v >> 7) & 0x7F; // next 7 bits
    final int ls7 = v & 0x7F; // final 7 bits
    return [ms2, mid7, ls7];
  }

  /// The reverse: parse 3 bytes of 7-bit data into a 16-bit integer.
  static int decode16(List<int> bytes, int offset) {
    final int ms2 = bytes[offset + 0] & 0x03;
    final int mid7 = bytes[offset + 1] & 0x7F;
    final int ls7 = bytes[offset + 2] & 0x7F;
    return (ms2 << 14) | (mid7 << 7) | ls7;
  }

  /// Similar approach for 32-bit if needed (e.g. set real-time clock).
  /// The doc says "32 bit number" but doesn't explicitly define
  /// 7-bit splitting. The existing tools do typically use 7-bit expansions.
  /// Here is a hypothetical approach:
  static List<int> encode32(int value) {
    // We'll do it as 5 bytes:
    //
    //  <most significant 4 bits> <middle 7 bits> <middle 7 bits> <middle 7 bits> <least significant 7 bits>
    final v = value & 0xFFFFFFFF;
    final int ms4 = (v >> 28) & 0x0F; // top 4 bits
    final int next7_1 = (v >> 21) & 0x7F;
    final int next7_2 = (v >> 14) & 0x7F;
    final int next7_3 = (v >> 7) & 0x7F;
    final int ls7 = v & 0x7F;
    return [ms4, next7_1, next7_2, next7_3, ls7];
  }

  static int decode32(List<int> bytes, int offset) {
    final ms4 = bytes[offset + 0] & 0x0F;
    final n7_1 = bytes[offset + 1] & 0x7F;
    final n7_2 = bytes[offset + 2] & 0x7F;
    final n7_3 = bytes[offset + 3] & 0x7F;
    final ls7 = bytes[offset + 4] & 0x7F;
    return (ms4 << 28) | (n7_1 << 21) | (n7_2 << 14) | (n7_3 << 7) | ls7;
  }

  /// Build a 'Take screenshot' SysEx message.
  ///
  /// F0 00 21 27 6D <SysEx ID> 01 F7
  static Uint8List encodeTakeScreenshot(int distingSysExId) {
    final bytes = <int>[
      ..._buildHeader(distingSysExId),
      DistingNTRequestMessageType.takeScreenshot.value,
      ..._buildFooter(),
    ];
    return Uint8List.fromList(bytes);
  }

  /// Build a 'Wake' SysEx message.
  ///
  /// F0 00 21 27 6D <SysEx ID> 07 F7
  static Uint8List buildWake(int distingSysExId) {
    final bytes = <int>[
      ..._buildHeader(distingSysExId),
      DistingNTRequestMessageType.wake.value,
      ..._buildFooter(),
    ];
    return Uint8List.fromList(bytes);
  }

  /// Build a 'Set real-time clock' SysEx message.
  ///
  /// F0 00 21 27 6D <SysEx ID> 04 <time MSB> <time> <time> <time> <time LSB> F7
  ///
  /// The time is a 32-bit integer (seconds since epoch).
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
  ///
  /// F0 00 21 27 6D <SysEx ID> 22 F7
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
      DistingNTRequestMessageType.requestAlgorithmGuid.value,
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

  static AlgorithmInfo decodeAlgorithmInfo(Uint8List data) {
    var algorithmIndex = decode16(data, 0);
    var guid = String.fromCharCodes(data.sublist(3, 7));
    var numSpecifications = data[3 + 4].toInt();
    List<Specification> specifications =
        List.generate(numSpecifications, (index) {
      int offset = 3 + 4 + 1;
      int specOffset = index * 10 + offset;

      int min = decode16(data, specOffset);
      int max = decode16(data, specOffset + 3);
      int defaultValue = decode16(data, specOffset + 3 + 3);
      int type = data[specOffset + 3 + 3 + 3];

      return Specification(
          min: min, max: max, defaultValue: defaultValue, type: type);
    });
    var str =
        decodeNullTerminatedAscii(data, 3 + 4 + 1 + numSpecifications * 10);
    var str2 = decodeNullTerminatedAscii(data, str.nextOffset);

    return AlgorithmInfo(
      algorithmIndex: algorithmIndex,
      guid: guid,
      numSpecifications: numSpecifications,
      specifications: specifications,
      name: str.value,
      specificationName: str2.value,
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
      data,
      deviceId: device.id, // Specify the target device ID
      timestamp: null, // Timestamp if needed, or leave as null
    );
  }

  static AlgorithmGuid decodeGuid(Uint8List guidData) {
    return AlgorithmGuid(
        algorithmIndex: guidData[0].toInt(),
        guid: String.fromCharCodes(guidData.sublist(1, guidData.length)));
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
      print('Error generating bitmap: $e');
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
    );
  }

  static AllParameterValues decodeAllParameterValues(Uint8List message) {
    return AllParameterValues(
      algorithmIndex: decode8(message.sublist(0, 1)),
      values: [
        for (int offset = 1; offset < message.length; offset += 3)
          decode16(message, offset)
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
      packedMappingData:
          PackedMappingData.fromBytes(message.sublist(5, message.length)),
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

  static AlgorithmGuid decodeAlgorithmGuid(Uint8List payload) {
    return decodeGuid(payload);
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
        'type: $messageType, payloadLen: ${payload.length})';
  }
}
