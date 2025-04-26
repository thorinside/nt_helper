part of 'midi_listener_cubit.dart';

enum MidiEventType { cc, noteOn, noteOff }

@freezed
class MidiListenerState with _$MidiListenerState {
  /// The initial state: no devices discovered, not connected.
  const factory MidiListenerState.initial() = _Initial;

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
  }) = _Data;
}
