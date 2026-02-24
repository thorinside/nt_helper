import 'dart:typed_data';

import 'package:nt_helper/domain/sysex/sysex_utils.dart';

enum MidiMappingType {
  cc(0),
  noteMomentary(1),
  noteToggle(2),
  cc14BitLow(3),
  cc14BitHigh(4);

  final int value;
  const MidiMappingType(this.value);
}

class PackedMappingData {
  // Version
  final int version;

  // CV Mapping
  final int source; // Source of the CV input
  final int cvInput; // Input source for CV
  final bool isUnipolar; // Unipolar or bipolar mapping
  final bool isGate; // Gate mapping enabled
  final int volts; // Voltage scale
  final int delta; // CV delta (sensitivity)

  // MIDI Mapping
  final int midiChannel; // MIDI channel
  final MidiMappingType midiMappingType; // CC, Note Momentary, or Note Toggle
  final int midiCC; // MIDI control change number (or note number if type != cc)
  final bool isMidiEnabled; // MIDI mapping enabled
  final bool isMidiSymmetric; // MIDI mapping symmetric
  final bool isMidiRelative; // MIDI mapping relative
  final int midiMin; // Minimum MIDI value
  final int midiMax; // Maximum MIDI value

  // I2C Mapping
  final int i2cCC; // I2C control code
  final bool isI2cEnabled; // I2C mapping enabled
  final bool isI2cSymmetric; // I2C mapping symmetric
  final int i2cMin; // Minimum I2C value
  final int i2cMax; // Maximum I2C value

  // Performance Page (used for sort order only, not navigation)
  final int
  perfPageIndex; // Performance page index (0 = not assigned, 1-30 = valid pages)

  // Constructor
  PackedMappingData({
    required this.source,
    required this.cvInput,
    required this.isUnipolar,
    required this.isGate,
    required this.volts,
    required this.delta,
    required this.midiChannel,
    required this.midiMappingType,
    required this.midiCC,
    required this.isMidiEnabled,
    required this.isMidiSymmetric,
    required this.isMidiRelative,
    required this.midiMin,
    required this.midiMax,
    required this.i2cCC,
    required this.isI2cEnabled,
    required this.isI2cSymmetric,
    required this.i2cMin,
    required this.i2cMax,
    required this.perfPageIndex,
    required this.version,
  });

  factory PackedMappingData.filler() {
    return PackedMappingData(
      source: -1,
      cvInput: -1,
      isUnipolar: false,
      isGate: false,
      volts: -1,
      delta: -1,
      midiChannel: -1,
      midiMappingType: MidiMappingType.cc,
      midiCC: -1,
      isMidiEnabled: false,
      isMidiSymmetric: false,
      isMidiRelative: false,
      midiMin: -1,
      midiMax: -1,
      i2cCC: -1,
      isI2cEnabled: false,
      isI2cSymmetric: false,
      i2cMin: -1,
      i2cMax: -1,
      perfPageIndex: 0,
      version: -1,
    );
  }

  // Decode from packed Uint8List with bounds checking
  factory PackedMappingData.fromBytes(int version, Uint8List data) {
    if (version < 1 || version > 5) {
      return PackedMappingData.filler();
    }

    int offset = 0;
    final dataLength = data.length;

    // Helper function for safe decoding (decode16 needs 3 bytes) - using unsigned version to match JavaScript
    int safeDecode16Unsigned(int currentOffset) {
      if (currentOffset + 3 > dataLength) {
        return 0;
      }
      return decode16Unsigned(data, currentOffset);
    }

    // Helper function for safe signed 16-bit decoding
    int safeDecode16Signed(int currentOffset) {
      if (currentOffset + 3 > dataLength) {
        return 0;
      }
      return decode16(data, currentOffset);
    }

    // Helper function for safe byte read
    int safeReadByte(int currentOffset) {
      if (currentOffset >= dataLength) {
        return 0;
      }
      return data[currentOffset];
    }

    // Calculate expected total length based on version
    int expectedLength = (version == 1)
        ? 22 // 6 + 8 + 8 = CV(6) + MIDI(8) + I2C(8)
        : (version == 2)
        ? 23 // 6 + 9 + 8 = CV(6) + MIDI(9) + I2C(8)
        : (version == 3)
        ? 24 // 6 + 9 + 9 = CV(6) + MIDI(9) + I2C(9)
        : (version == 4)
        ? 25 // 7 + 9 + 9 = CV(7) + MIDI(9) + I2C(9)
        : 26; // 7 + 9 + 9 + 1 = CV(7) + MIDI(9) + I2C(9) + Perf(1)

    if (dataLength != expectedLength) {
      return PackedMappingData.filler();
    }

    // --- Decode CV Mapping ---
    final source = (version >= 4) ? safeReadByte(offset++) : 0;
    final cvInput = safeReadByte(offset++);
    final cvFlags = safeReadByte(offset++);
    final isUnipolar = (cvFlags & 1) != 0;
    final isGate = (cvFlags & 2) != 0;
    final volts = safeReadByte(offset++);
    final delta = safeDecode16Unsigned(offset);
    offset += 3;

    // --- Decode MIDI Mapping ---
    var midiCC = safeReadByte(offset++);
    final midiFlags = safeReadByte(offset++);
    final midiFlags2 = version >= 2 ? safeReadByte(offset++) : 0;

    // Handle aftertouch flag
    if (midiFlags & 4 != 0) {
      midiCC = 128;
    }

    final midiChannel = (midiFlags >> 3) & 0xF;
    final isMidiEnabled = (midiFlags & 1) != 0;
    final isMidiSymmetric = (midiFlags & 2) != 0;

    // Extract relative flag (bit 0) and type value (bits 2-6) using bit-shift
    final isMidiRelative = (midiFlags2 & 0x01) != 0;
    final typeValue = midiFlags2 >> 2; // Extract type from bits 2-6

    // Map type value to MidiMappingType enum (supports 0-4)
    final MidiMappingType midiMappingType;
    if (typeValue >= 0 && typeValue < MidiMappingType.values.length) {
      midiMappingType = MidiMappingType.values[typeValue];
    } else {
      midiMappingType = MidiMappingType.cc;
    }

    final midiMin = safeDecode16Signed(offset);
    offset += 3;
    final midiMax = safeDecode16Signed(offset);
    offset += 3;

    // --- Decode I2C Mapping ---
    var i2cCC = safeReadByte(offset++);
    if (version >= 3) {
      i2cCC |= (safeReadByte(offset++) & 1) << 7;
    }
    final i2cFlags = safeReadByte(offset++);
    final isI2cEnabled = (i2cFlags & 1) != 0;
    final isI2cSymmetric = (i2cFlags & 2) != 0;
    final i2cMin = safeDecode16Signed(offset);
    offset += 3;
    final i2cMax = safeDecode16Signed(offset);
    offset += 3;

    // --- Decode Performance Page ---
    final perfPageIndex = (version >= 5) ? safeReadByte(offset++) : 0;

    if (version < 5) {}

    // Final validation: offset should equal expected length
    if (offset != expectedLength) {
      return PackedMappingData.filler();
    }

    return PackedMappingData(
      source: source,
      cvInput: cvInput,
      isUnipolar: isUnipolar,
      isGate: isGate,
      volts: volts,
      delta: delta,
      midiChannel: midiChannel,
      midiMappingType: midiMappingType,
      midiCC: midiCC,
      isMidiEnabled: isMidiEnabled,
      isMidiSymmetric: isMidiSymmetric,
      isMidiRelative: isMidiRelative,
      midiMin: midiMin,
      midiMax: midiMax,
      i2cCC: i2cCC,
      isI2cEnabled: isI2cEnabled,
      isI2cSymmetric: isI2cSymmetric,
      i2cMin: i2cMin,
      i2cMax: i2cMax,
      perfPageIndex: perfPageIndex,
      version: version,
    );
  }

  Uint8List encodeCVPackedData() {
    // Compute the flags
    int flags = (isUnipolar ? 1 : 0) | (isGate ? 2 : 0);

    // Build the packed payload (starting after the version byte)
    final payload = [
      if (version >= 4) source & 0x7F, // Source of the CV input
      cvInput & 0x7F, // CV input number
      flags & 0x7F, // Flags for unipolar/gate settings
      volts & 0x7F, // Voltage setting (0-127)
      ...encode16(delta), // Encode 'delta' as 7-bit chunks
    ];

    return Uint8List.fromList(payload);
  }

  Uint8List encodeMIDIPackedData() {
    var adjustedCC = midiCC;
    var min = midiMin;
    var max = midiMax;

    // Compute the flags
    int flags =
        (isMidiEnabled ? 1 : 0) |
        (isMidiSymmetric ? 2 : 0) |
        ((midiChannel & 0xF) << 3);

    // Encode midiFlags2 using bit-shift: relative flag (bit 0) and type value (bits 2-6)
    int midiFlags2 = (isMidiRelative ? 1 : 0) | (midiMappingType.value << 2);

    // Adjust the CC number and flags if necessary (for Aftertouch)
    if (adjustedCC == 128) {
      adjustedCC = 0;
      flags |= (1 << 2); // Use bit 2 of flags for Aftertouch indication
    }

    // Build the packed payload (starting after the version byte)
    final payload = [
      adjustedCC & 0x7F, // MIDI CC number or Note number
      flags & 0x7F, // Flags
      if (version >= 2) midiFlags2 & 0x7F, // Flags2 (relative, toggle, is_note)
      ...encode16(min), // Encode 'min' as 7-bit chunks
      ...encode16(max), // Encode 'max' as 7-bit chunks
    ];

    return Uint8List.fromList(payload);
  }

  Uint8List encodeI2CPackedData() {
    var adjustedCC = i2cCC;
    var min = i2cMin;
    var max = i2cMax;

    // Compute the flags
    int flags = (isI2cEnabled ? 1 : 0) | (isI2cSymmetric ? 2 : 0);

    // Build the packed payload (starting after the version byte)
    final payload = [
      adjustedCC & 0x7F, // I2C control code
      if (version >= 3) (adjustedCC >> 7) & 0x7F,
      flags & 0x7F, // Flags
      ...encode16(min), // Encode 'min' as 7-bit chunks
      ...encode16(max), // Encode 'max' as 7-bit chunks
    ];

    return Uint8List.fromList(payload);
  }

  // Convert back to Uint8List (excluding the version byte itself)
  Uint8List toBytes() {
    final cvBytes = encodeCVPackedData();
    final midiBytes = encodeMIDIPackedData();
    final i2cBytes = encodeI2CPackedData();

    final allBytes = [...cvBytes, ...midiBytes, ...i2cBytes];

    // Add performance page index for version 5+
    if (version >= 5) {
      // Validate and clamp perfPageIndex to valid range (0-30)
      final clampedIndex = perfPageIndex.clamp(0, 30);
      if (clampedIndex != perfPageIndex) {}
      allBytes.add(clampedIndex & 0x7F);
    }

    final result = Uint8List.fromList(allBytes);

    // Validate the output length matches expected length for this version
    int expectedLength = (version == 1)
        ? 22 // 6 + 8 + 8 = CV(6) + MIDI(8) + I2C(8)
        : (version == 2)
        ? 23 // 6 + 9 + 8 = CV(6) + MIDI(9) + I2C(8)
        : (version == 3)
        ? 24 // 6 + 9 + 9 = CV(6) + MIDI(9) + I2C(9)
        : (version == 4)
        ? 25 // 7 + 9 + 9 = CV(7) + MIDI(9) + I2C(9)
        : 26; // 7 + 9 + 9 + 1 = CV(7) + MIDI(9) + I2C(9) + Perf(1)

    if (result.length != expectedLength) {}

    return result;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! PackedMappingData) return false;

    return other.source == source &&
        other.cvInput == cvInput &&
        other.isUnipolar == isUnipolar &&
        other.isGate == isGate &&
        other.volts == volts &&
        other.delta == delta &&
        other.midiChannel == midiChannel &&
        other.midiMappingType == midiMappingType &&
        other.midiCC == midiCC &&
        other.isMidiEnabled == isMidiEnabled &&
        other.isMidiSymmetric == isMidiSymmetric &&
        other.isMidiRelative == isMidiRelative &&
        other.midiMin == midiMin &&
        other.midiMax == midiMax &&
        other.i2cCC == i2cCC &&
        other.isI2cEnabled == isI2cEnabled &&
        other.isI2cSymmetric == isI2cSymmetric &&
        other.i2cMin == i2cMin &&
        other.i2cMax == i2cMax &&
        other.perfPageIndex == perfPageIndex;
  }

  @override
  int get hashCode {
    return Object.hash(
      source,
      cvInput,
      isUnipolar,
      isGate,
      volts,
      delta,
      midiChannel,
      midiMappingType,
      midiCC,
      isMidiEnabled,
      isMidiSymmetric,
      isMidiRelative,
      midiMin,
      midiMax,
      i2cCC,
      isI2cEnabled,
      isI2cSymmetric,
      i2cMin,
      Object.hash(i2cMax, perfPageIndex),
    );
  }

  bool isMapped() {
    return (cvInput > 0 || source > 0) || isMidiEnabled || isI2cEnabled;
  }

  bool isPerformance() {
    return perfPageIndex > 0;
  }

  PackedMappingData copyWith({
    int? source,
    int? cvInput,
    bool? isUnipolar,
    bool? isGate,
    int? volts,
    int? delta,
    int? midiChannel,
    MidiMappingType? midiMappingType,
    int? midiCC,
    bool? isMidiEnabled,
    bool? isMidiSymmetric,
    bool? isMidiRelative,
    int? midiMin,
    int? midiMax,
    int? i2cCC,
    bool? isI2cEnabled,
    bool? isI2cSymmetric,
    int? i2cMin,
    int? i2cMax,
    int? perfPageIndex,
    int? version,
  }) {
    return PackedMappingData(
      source: source ?? this.source,
      cvInput: cvInput ?? this.cvInput,
      isUnipolar: isUnipolar ?? this.isUnipolar,
      isGate: isGate ?? this.isGate,
      volts: volts ?? this.volts,
      delta: delta ?? this.delta,
      midiChannel: midiChannel ?? this.midiChannel,
      midiMappingType: midiMappingType ?? this.midiMappingType,
      midiCC: midiCC ?? this.midiCC,
      isMidiEnabled: isMidiEnabled ?? this.isMidiEnabled,
      isMidiSymmetric: isMidiSymmetric ?? this.isMidiSymmetric,
      isMidiRelative: isMidiRelative ?? this.isMidiRelative,
      midiMin: midiMin ?? this.midiMin,
      midiMax: midiMax ?? this.midiMax,
      i2cCC: i2cCC ?? this.i2cCC,
      isI2cEnabled: isI2cEnabled ?? this.isI2cEnabled,
      isI2cSymmetric: isI2cSymmetric ?? this.isI2cSymmetric,
      i2cMin: i2cMin ?? this.i2cMin,
      i2cMax: i2cMax ?? this.i2cMax,
      perfPageIndex: perfPageIndex ?? this.perfPageIndex,
      version: version ?? this.version,
    );
  }
}
