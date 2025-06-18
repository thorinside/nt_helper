import 'dart:typed_data';

import 'package:flutter/material.dart' show debugPrint;
import 'package:nt_helper/domain/sysex/sysex_utils.dart';

enum MidiMappingType {
  cc, // 0
  noteMomentary, // 1
  noteToggle, // 2
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
        version: -1);
  }

  // Decode from packed Uint8List with bounds checking
  factory PackedMappingData.fromBytes(int version, Uint8List data) {
    if (version < 1 || version > 4) {
      debugPrint(
          "Warning: Unknown PackedMappingData version $version. Returning filler.");
      return PackedMappingData.filler();
    }

    int offset = 0;
    final dataLength = data.length;

    // Helper function for safe decoding
    int safeDecode16(int currentOffset) {
      if (currentOffset + 2 >= dataLength) {
        debugPrint(
            "Warning: PackedMappingData truncated during decode16 at offset $currentOffset (length $dataLength). Returning 0.");
        return 0; // Or throw, or return a specific error indicator?
      }
      return decode16(data, currentOffset);
    }

    // Helper function for safe byte read
    int safeReadByte(int currentOffset) {
      if (currentOffset >= dataLength) {
        debugPrint(
            "Warning: PackedMappingData truncated during byte read at offset $currentOffset (length $dataLength). Returning 0.");
        return 0;
      }
      return data[currentOffset];
    }

    // --- Decode CV Mapping ---
    int cvSectionMinLength = (version >= 4) ? 7 : 6;
    if (offset + cvSectionMinLength - 1 >= dataLength) {
      // Check if enough bytes for the whole section
      debugPrint(
          "Warning: PackedMappingData truncated within CV section (offset $offset, length $dataLength, version $version). Returning filler.");
      return PackedMappingData.filler();
    }
    final source = (version >= 4) ? safeReadByte(offset++) : 0;
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
    // Need enough bytes for midiCC, midiFlags, midiFlags2 (if v >= 2), midiMin (3), midiMax (3)
    int requiredMidiBytes = 1 + 1 + (version >= 2 ? 1 : 0) + 3 + 3;
    if (offset + requiredMidiBytes > dataLength) {
      debugPrint(
          "Warning: PackedMappingData truncated within MIDI section (offset $offset, required $requiredMidiBytes, length $dataLength, version $version). Returning filler.");
      return PackedMappingData.filler();
    }
    var midiCC = safeReadByte(offset++);
    final midiFlags = safeReadByte(offset++);
    final midiFlags2 = version >= 2 ? safeReadByte(offset++) : 0;
    if (midiFlags & 4 != 0) {
      // This flag indicates Aftertouch, not a specific CC adjustment in the JS
      midiCC = 128;
    }
    final midiChannel = (midiFlags >> 3) & 0xF;
    final isMidiEnabled = (midiFlags & 1) != 0;
    final isMidiSymmetric = (midiFlags & 2) != 0;
    // Decode from midiFlags2
    final isMidiRelative = (midiFlags2 & 1) != 0;
    final isNoteMapping = (midiFlags2 & 4) != 0; // Bit 2 indicates Note mapping
    final isToggleNote =
        (midiFlags2 & 2) != 0; // Bit 1 indicates Toggle for Notes
    final MidiMappingType midiMappingType;
    if (isNoteMapping) {
      midiMappingType = isToggleNote
          ? MidiMappingType.noteToggle
          : MidiMappingType.noteMomentary;
    } else {
      midiMappingType = MidiMappingType.cc;
    }
    // ---
    final midiMin = safeDecode16(offset);
    offset += 3;
    final midiMax = safeDecode16(offset);
    offset += 3;

    // --- Decode I2C Mapping (8 or 9 bytes) ---
    int i2cSectionMinLength = offset + 7; // Base size (v1/v2)
    if (version >= 3) i2cSectionMinLength++; // Add 1 for extra I2C CC byte
    // Need enough bytes for i2cCC (1 or 2), i2cFlags (1), i2cMin (3), i2cMax (3)
    int requiredI2cBytes = (version >= 3 ? 2 : 1) + 1 + 3 + 3;
    if (offset + requiredI2cBytes > dataLength) {
      debugPrint(
          "Warning: PackedMappingData truncated within I2C section (offset $offset, required $requiredI2cBytes, length $dataLength, version $version). Returning filler.");
      return PackedMappingData.filler();
    }
    var i2cCC = safeReadByte(offset++);
    if (version >= 3) {
      // Check if we have the extra byte before reading it - already checked above
      i2cCC |= (safeReadByte(offset++) & 1) << 7;
    }
    final i2cFlags = safeReadByte(offset++);
    final isI2cEnabled = (i2cFlags & 1) != 0;
    final isI2cSymmetric = (i2cFlags & 2) != 0;
    final i2cMin = safeDecode16(offset);
    offset += 3;
    final i2cMax = safeDecode16(offset);

    // Final check (optional): Ensure offset matches expected length based on version
    int expectedLength = (version == 1)
        ? 22
        : (version == 2)
            ? 23
            : (version == 3)
                ? 24
                : 25;
    // The final offset should be *equal* to the expected length after reading all bytes
    if (offset != expectedLength) {
      debugPrint(
          "Warning: PackedMappingData final offset ($offset) doesn't match expected length ($expectedLength) for version $version. Data might be corrupt or have extra bytes.");
      // Decide whether to return filler or the potentially partially decoded data
      // Consider returning filler if strict adherence is needed.
      // return PackedMappingData.filler();
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
    int flags = (isMidiEnabled ? 1 : 0) |
        (isMidiSymmetric ? 2 : 0) |
        ((midiChannel & 0xF) << 3);

    // Encode midiFlags2 based on type and relative setting
    bool isNote = midiMappingType != MidiMappingType.cc;
    bool isToggle = midiMappingType == MidiMappingType.noteToggle;
    int midiFlags2 =
        (isMidiRelative ? 1 : 0) | (isToggle ? 2 : 0) | (isNote ? 4 : 0);

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

    final allBytes = [
      ...cvBytes,
      ...midiBytes,
      ...i2cBytes,
    ];

    return Uint8List.fromList(allBytes);
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
        other.i2cMax == i2cMax;
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
      i2cMax,
    );
  }

  bool isMapped() {
    return (cvInput != 0) || isMidiEnabled || isI2cEnabled;
  }
}
