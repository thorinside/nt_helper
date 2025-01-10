import 'dart:typed_data';

import 'package:nt_helper/domain/disting_nt_sysex.dart';

class PackedMappingData {
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
    required this.midiMin,
    required this.midiMax,
    required this.i2cCC,
    required this.isI2cEnabled,
    required this.isI2cSymmetric,
    required this.i2cMin,
    required this.i2cMax,
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
        midiMin: -1,
        midiMax: -1,
        i2cCC: -1,
        isI2cEnabled: false,
        isI2cSymmetric: false,
        i2cMin: -1,
        i2cMax: -1);
  }

  // Decode from packed Uint8List
  factory PackedMappingData.fromBytes(Uint8List data) {
    int offset = 0;

    // Decode CV Mapping
    final cvInput = data[offset++];
    final cvFlags = data[offset++];
    final isUnipolar = (cvFlags & 1) != 0;
    final isGate = (cvFlags & 2) != 0;
    final volts = data[offset++];
    final delta = DistingNT.decode16(data, offset);
    offset += 3;

    // Decode MIDI Mapping
    var midiCC = data[offset++];
    final midiFlags = data[offset++];
    final midiChannel = (midiFlags >> 3) & 0xF;
    final isMidiEnabled = (midiFlags & 1) != 0;
    final isMidiSymmetric = (midiFlags & 2) != 0;
    final midiMin = DistingNT.decode16(data, offset);
    offset += 3;
    final midiMax = DistingNT.decode16(data, offset);
    offset += 3;

    // Decode I2C Mapping
    final i2cCC = data[offset++];
    final i2cFlags = data[offset++];
    final isI2cEnabled = (i2cFlags & 1) != 0;
    final isI2cSymmetric = (i2cFlags & 2) != 0;
    final i2cMin = DistingNT.decode16(data, offset);
    offset += 3;
    final i2cMax = DistingNT.decode16(data, offset);
    offset += 3;

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
      midiMin: midiMin,
      midiMax: midiMax,
      i2cCC: i2cCC,
      isI2cEnabled: isI2cEnabled,
      isI2cSymmetric: isI2cSymmetric,
      i2cMin: i2cMin,
      i2cMax: i2cMax,
    );
  }

  Uint8List encodeCVPackedData() {
    final bytes = <int>[];

    // Encode CV Mapping
    bytes.add(cvInput);
    bytes.add((isUnipolar ? 1 : 0) | (isGate ? 2 : 0));
    bytes.add(volts);
    bytes.addAll(DistingNT.encode16(delta));

    return Uint8List.fromList(bytes);
  }

  Uint8List encodeMidiPackedData() {
    final bytes = <int>[];

    // Encode MIDI Mapping
    bytes.add(midiCC);
    bytes.add((isMidiEnabled ? 1 : 0) |
    (isMidiSymmetric ? 2 : 0) |
    ((midiChannel & 0xF) << 3));
    bytes.addAll(DistingNT.encode16(midiMin));
    bytes.addAll(DistingNT.encode16(midiMax));

    return Uint8List.fromList(bytes);

  }

  Uint8List encodeI2CPackedData() {
    final bytes = <int>[];

    // Encode I2C Mapping
    bytes.add(i2cCC);
    bytes.add((isI2cEnabled ? 1 : 0) | (isI2cSymmetric ? 2 : 0));
    bytes.addAll(DistingNT.encode16(i2cMin));
    bytes.addAll(DistingNT.encode16(i2cMax));

    return Uint8List.fromList(bytes);

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
