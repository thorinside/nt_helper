part of 'midi_listener_cubit.dart';

@freezed
class MidiListenerState with _$MidiListenerState {
  /// The initial state: no devices discovered, not connected.
  const factory MidiListenerState.initial() = _Initial;

  /// A data state that has all the info needed for the UI:
  const factory MidiListenerState.data({
    @Default([]) List<MidiDevice> devices,
    MidiDevice? selectedDevice,
    @Default(false) bool isConnected,
    int? lastDetectedCc,
    int? lastDetectedChannel,
    DateTime? lastDetectedTime,
  }) = _Data;
}