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

  // Decode from packed Uint8List
  factory PackedMappingData.fromBytes(int version, Uint8List data) {
    if (version < 1 || version > 3)
      throw Exception("unknown_mapping_data_version");

    int offset = 0;

    // --- Decode CV Mapping ---
    final cvInput = data[offset++];
    final cvFlags = data[offset++];
    final isUnipolar = (cvFlags & 1) != 0;
    final isGate = (cvFlags & 2) != 0;
    final volts = data[offset++];
    final delta = DistingNT.decode16(data, offset);
    offset += 3;

    // --- Decode MIDI Mapping ---
    var midiCC = data[offset++];
    final midiFlags = data[offset++];
    final midiFlags2 = version >= 2 ? data[offset++] : 0;
    if (midiFlags & 4 != 0) {
      midiCC = 128;
    }
    final midiChannel = (midiFlags >> 3) & 0xF;
    final isMidiEnabled = (midiFlags & 1) != 0;
    final isMidiSymmetric = (midiFlags & 2) != 0;
    final isMidiRelative = (midiFlags2 & 1) != 0;
    final midiMin = DistingNT.decode16(data, offset);
    offset += 3;
    final midiMax = DistingNT.decode16(data, offset);
    offset += 3;

    // --- Decode I2C Mapping ---
    var i2cCC = data[offset++];
    if (version >= 3) {
      i2cCC = i2cCC | (data[offset++] & 1) << 7;
    }
    final i2cFlags = data[offset++];
    final isI2cEnabled = (i2cFlags & 1) != 0;
    final isI2cSymmetric = (i2cFlags & 2) != 0;
    final i2cMin = DistingNT.decode16(data, offset);
    offset += 3;
    final i2cMax = DistingNT.decode16(data, offset);
    offset += 3;

    // Return the decoded mapping data
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

  // Convert back to Uint8List
  Uint8List toBytes() {
    final bytes = <int>[];

    // Encode CV Mapping
    bytes.add(cvInput);
    bytes.add((isUnipolar ? 1 : 0) | (isGate ? 2 : 0));
    bytes.add(volts);
    bytes.addAll(DistingNT.encode16(delta));

    // Encode MIDI Mapping
    bytes.add(midiCC);
    bytes.add((isMidiEnabled ? 1 : 0) |
        (isMidiSymmetric ? 2 : 0) |
        ((midiChannel & 0xF) << 3));
    if (version >= 2) {
      bytes.add((isMidiRelative ? 1 : 0));
    }
    bytes.addAll(DistingNT.encode16(midiMin));
    bytes.addAll(DistingNT.encode16(midiMax));

    // Encode I2C Mapping
    bytes.add(i2cCC);
    bytes.add((isI2cEnabled ? 1 : 0) | (isI2cSymmetric ? 2 : 0));
    bytes.addAll(DistingNT.encode16(i2cMin));
    bytes.addAll(DistingNT.encode16(i2cMax));

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
