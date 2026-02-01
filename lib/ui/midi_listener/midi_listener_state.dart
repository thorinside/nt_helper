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
