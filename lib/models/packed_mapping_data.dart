import 'dart:typed_data';

import 'package:nt_helper/domain/disting_nt_sysex.dart';

class PackedMappingData {
  // Version
  final int version;

  // CV Mapping
  final int cvInput; // Input source for CV
  final bool isUnipolar; // Unipolar or bipolar mapping
  final bool isGate; // Gate mapping enabled
  final int volts; // Voltage scale
  final int delta; // CV delta (sensitivity)

  // MIDI Mapping
  final int midiChannel; // MIDI channel
  final int midiCC; // MIDI control change number
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

  // Constructor
  PackedMappingData({
    required this.cvInput,
    required this.isUnipolar,
    required this.isGate,
    required this.volts,
    required this.delta,
    required this.midiChannel,
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
    required this.version,
  });

  factory PackedMappingData.filler() {
    return PackedMappingData(
        cvInput: -1,
        isUnipolar: false,
        isGate: false,
        volts: -1,
        delta: -1,
        midiChannel: -1,
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
        version: -1);
  }

  // Decode from packed Uint8List with bounds checking
  factory PackedMappingData.fromBytes(int version, Uint8List data) {
    if (version < 1 || version > 3) {
      print(
          "Warning: Unknown PackedMappingData version $version. Returning filler.");
      return PackedMappingData.filler();
    }

    int offset = 0;
    final dataLength = data.length;

    // Helper function for safe decoding
    int safeDecode16(int currentOffset) {
      if (currentOffset + 2 >= dataLength) {
        print(
            "Warning: PackedMappingData truncated during decode16 at offset $currentOffset (length $dataLength). Returning 0.");
        return 0; // Or throw, or return a specific error indicator?
      }
      return DistingNT.decode16(data, currentOffset);
    }

    // Helper function for safe byte read
    int safeReadByte(int currentOffset) {
      if (currentOffset >= dataLength) {
        print(
            "Warning: PackedMappingData truncated during byte read at offset $currentOffset (length $dataLength). Returning 0.");
        return 0;
      }
      return data[currentOffset];
    }

    // --- Decode CV Mapping (6 bytes) ---
    if (offset + 5 >= dataLength) {
      // Need 6 bytes total (offset 0 to 5)
      print(
          "Warning: PackedMappingData truncated before CV delta (offset $offset, length $dataLength). Returning filler.");
      return PackedMappingData.filler();
    }
    final cvInput = safeReadByte(offset++);
    final cvFlags = safeReadByte(offset++);
    final isUnipolar = (cvFlags & 1) != 0;
    final isGate = (cvFlags & 2) != 0;
    final volts = safeReadByte(offset++);
    final delta = safeDecode16(offset);
    offset += 3;

    // --- Decode MIDI Mapping (8 or 9 bytes) ---
    int midiSectionMinLength = offset + 7; // Base size (v1)
    if (version >= 2) midiSectionMinLength++; // Add 1 for flags2
    if (midiSectionMinLength >= dataLength) {
      // Need at least 8 (v1) or 9 (v2/3) bytes total (offset up to 7 or 8 + 6 for decode16 calls)
      print(
          "Warning: PackedMappingData truncated before MIDI max (offset $offset, length $dataLength). Returning filler.");
      return PackedMappingData.filler();
    }
    var midiCC = safeReadByte(offset++);
    final midiFlags = safeReadByte(offset++);
    final midiFlags2 = version >= 2 ? safeReadByte(offset++) : 0;
    if (midiFlags & 4 != 0) {
      midiCC = 128;
    }
    final midiChannel = (midiFlags >> 3) & 0xF;
    final isMidiEnabled = (midiFlags & 1) != 0;
    final isMidiSymmetric = (midiFlags & 2) != 0;
    final isMidiRelative = (midiFlags2 & 1) != 0;
    final midiMin = safeDecode16(offset);
    offset += 3;
    final midiMax = safeDecode16(offset);
    offset += 3;

    // --- Decode I2C Mapping (8 or 9 bytes) ---
    int i2cSectionMinLength = offset + 7; // Base size (v1/v2)
    if (version >= 3) i2cSectionMinLength++; // Add 1 for extra I2C CC byte
    if (i2cSectionMinLength >= dataLength) {
      // Need offset up to 7 or 8 + 6 for decode16 calls
      print(
          "Warning: PackedMappingData truncated before I2C max (offset $offset, length $dataLength). Returning filler.");
      return PackedMappingData.filler();
    }
    var i2cCC = safeReadByte(offset++);
    if (version >= 3) {
      // Check if we have the extra byte before reading it
      if (offset >= dataLength) {
        print(
            "Warning: PackedMappingData (v3) truncated before extra I2C CC byte (offset $offset, length $dataLength). Returning filler.");
        return PackedMappingData.filler();
      }
      i2cCC = i2cCC | (safeReadByte(offset++) & 1) << 7;
    }
    final i2cFlags = safeReadByte(offset++);
    final isI2cEnabled = (i2cFlags & 1) != 0;
    final isI2cSymmetric = (i2cFlags & 2) != 0;
    final i2cMin = safeDecode16(offset);
    offset += 3;
    final i2cMax = safeDecode16(
        offset); // This is the problematic call if dataLength is 23 for v2
    // No need to increment offset after the last read
    // offset += 3;

    // Final check (optional): Ensure offset matches expected length based on version
    int expectedLength = (version == 1)
        ? 22
        : (version == 2)
            ? 23
            : 24;
    if (offset != expectedLength) {
      print(
          "Warning: PackedMappingData final offset ($offset) doesn't match expected length ($expectedLength) for version $version. Data might be corrupt.");
      // Decide whether to return filler or the potentially partially decoded data
      // return PackedMappingData.filler();
    }

    return PackedMappingData(
      cvInput: cvInput,
      isUnipolar: isUnipolar,
      isGate: isGate,
      volts: volts,
      delta: delta,
      midiChannel: midiChannel,
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
      version: version,
    );
  }

  Uint8List encodeCVPackedData() {
    // Compute the flags
    int flags = (isUnipolar ? 1 : 0) | (isGate ? 2 : 0);

    // Build the packed payload (starting after the version byte)
    final payload = [
      cvInput & 0x7F, // CV input number
      flags & 0x7F, // Flags for unipolar/gate settings
      volts & 0x7F, // Voltage setting (0-127)
      ...DistingNT.encode16(delta), // Encode 'delta' as 7-bit chunks
    ];

    return Uint8List.fromList(payload);
  }

  Uint8List encodeMidiPackedData() {
    var adjustedCC = midiCC;
    var min = midiMin;
    var max = midiMax;

    // Compute the flags
    int flags = (isMidiEnabled ? 1 : 0) |
        (isMidiSymmetric ? 2 : 0) |
        ((midiChannel & 0xF) << 3);

    int flags2 = (isMidiRelative ? 1 : 0);

    // Adjust the CC number and flags if necessary
    if (adjustedCC == 128) {
      adjustedCC = 0;
      flags |= (1 << 2);
    }

    // Build the packed payload (starting after the version byte)
    final payload = [
      adjustedCC & 0x7F, // MIDI CC number
      flags & 0x7F, // Flags
      if (version >= 2) flags2 & 0x7F,
      ...DistingNT.encode16(min), // Encode 'min' as 7-bit chunks
      ...DistingNT.encode16(max), // Encode 'max' as 7-bit chunks
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
      ...DistingNT.encode16(min), // Encode 'min' as 7-bit chunks
      ...DistingNT.encode16(max), // Encode 'max' as 7-bit chunks
    ];

    return Uint8List.fromList(payload);
  }

  // Convert back to Uint8List (excluding the version byte itself)
  Uint8List toBytes() {
    final bytes = <int>[];

    // Encode CV Mapping (6 bytes)
    bytes.add(cvInput & 0x7F);
    bytes.add(((isUnipolar ? 1 : 0) | (isGate ? 2 : 0)) & 0x7F);
    bytes.add(volts & 0x7F);
    bytes.addAll(DistingNT.encode16(delta));

    // Encode MIDI Mapping (8 or 9 bytes)
    int midiFlags = (isMidiEnabled ? 1 : 0) |
        (isMidiSymmetric ? 2 : 0) |
        ((midiChannel & 0xF) << 3);
    int midiFlags2 = (isMidiRelative ? 1 : 0);
    int adjustedMidiCC = midiCC;
    if (adjustedMidiCC == 128) {
      adjustedMidiCC = 0;
      midiFlags |= (1 << 2); // Use bit 2 of flags like in fromBytes
    }
    bytes.add(adjustedMidiCC & 0x7F);
    bytes.add(midiFlags & 0x7F);
    if (version >= 2) {
      bytes.add(midiFlags2 & 0x7F);
    }
    bytes.addAll(DistingNT.encode16(midiMin));
    bytes.addAll(DistingNT.encode16(midiMax));

    // Encode I2C Mapping (8 or 9 bytes)
    int i2cFlags = (isI2cEnabled ? 1 : 0) | (isI2cSymmetric ? 2 : 0);
    // Correctly encode i2cCC based on version
    bytes.add(i2cCC & 0x7F); // Lower 7 bits
    if (version >= 3) {
      // Add the high bit as the next byte for v3+
      bytes.add((i2cCC >> 7) & 0x01);
    }
    bytes.add(i2cFlags & 0x7F);
    bytes.addAll(DistingNT.encode16(i2cMin));
    bytes.addAll(DistingNT.encode16(i2cMax));

    // Verify length (optional but good practice)
    int expectedLength = (version == 1)
        ? 22
        : (version == 2)
            ? 23
            : 24;
    if (bytes.length != expectedLength) {
      print(
          "FATAL: PackedMappingData.toBytes() produced incorrect length (${bytes.length}) for version $version. Expected $expectedLength.");
      // Handle error - maybe return fixed-size filler bytes?
    }

    return Uint8List.fromList(bytes);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! PackedMappingData) return false;

    return other.cvInput == cvInput &&
        other.isUnipolar == isUnipolar &&
        other.isGate == isGate &&
        other.volts == volts &&
        other.delta == delta &&
        other.midiChannel == midiChannel &&
        other.midiCC == midiCC &&
        other.isMidiEnabled == isMidiEnabled &&
        other.isMidiSymmetric == isMidiSymmetric &&
        other.midiMin == midiMin &&
        other.midiMax == midiMax &&
        other.i2cCC == i2cCC &&
        other.isI2cEnabled == isI2cEnabled &&
        other.isI2cSymmetric == isI2cSymmetric &&
        other.i2cMin == i2cMin &&
        other.i2cMax == i2cMax;
  }

  @override
  int get hashCode {
    return Object.hash(
      cvInput,
      isUnipolar,
      isGate,
      volts,
      delta,
      midiChannel,
      midiCC,
      isMidiEnabled,
      isMidiSymmetric,
      midiMin,
      midiMax,
      i2cCC,
      isI2cEnabled,
      isI2cSymmetric,
      i2cMin,
      i2cMax,
    );
  }

  bool isMapped() {
    return (cvInput != 0) || isMidiEnabled || isI2cEnabled;
  }
}
