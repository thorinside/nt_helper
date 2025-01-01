part of 'disting_cubit.dart';

@freezed
class Slot with _$Slot {
  const factory Slot({
    required AlgorithmGuid algorithmGuid,
    required List<ParameterInfo> parameters,
    required List<ParameterValue> values,
    required List<ParameterEnumStrings> enums,
    required List<Mapping> mappings,
    required List<ParameterValueString> valueStrings,
  }) = _Slot;
}

@freezed
class DistingState with _$DistingState {
  const factory DistingState.initial({
    required MidiCommand midiCommand,
  }) = DistingStateInitial;

  const factory DistingState.selectDevice({
    required MidiCommand midiCommand,
    required List<MidiDevice> devices,
  }) = DistingStateSelectDevice;

  const factory DistingState.connected({
    required MidiCommand midiCommand,
    required MidiDevice device,
    required int sysExId,
    required DistingMidiManager disting,
  }) = DistingStateConnected;

  const factory DistingState.synchronized({
    required MidiCommand midiCommand,
    required MidiDevice device,
    required int sysExId,
    required DistingMidiManager disting,
    required String distingVersion,
    required String patchName,
    required List<AlgorithmInfo> algorithms,
    required List<Slot> slots,
    required List<String> unitStrings,
    @Default(false) bool complete,
  }) = DistingStateSynchronized;
}
