part of 'midi_listener_cubit.dart';

/// MIDI event types detected by the listener.
enum MidiEventType {
  /// Standard 7-bit CC message (one byte of data)
  cc,

  /// Note On message
  noteOn,

  /// Note Off message
  noteOff,

  /// 14-bit CC where lower CC number (0-31) is MSB
  cc14BitLowFirst,

  /// 14-bit CC where higher CC number (32-63) is MSB
  cc14BitHighFirst,

  /// Pitch Bend message
  pitchBend,

  /// Channel Pressure message
  channelPressure,

  /// NRPN parameter selection (firmware 1.18+ supports numbers 0-127).
  ///
  /// The disting NT stores this as an ordinary CC mapping whose CC number is
  /// the NRPN number.
  nrpn,
}

@freezed
sealed class MidiListenerState with _$MidiListenerState {
  /// The initial state: no devices discovered, not connected.
  const factory MidiListenerState.initial() = Initial;

  /// A data state that has all the info needed for the UI:
  const factory MidiListenerState.data({
    @Default([]) List<MidiDevice> devices,
    MidiDevice? selectedDevice,
    @Default(false) bool isConnected,
    MidiEventType? lastDetectedType,
    int? lastDetectedChannel,
    int? lastDetectedCc,
    int? lastDetectedNote,
    DateTime? lastDetectedTime,
  }) = Data;
}
