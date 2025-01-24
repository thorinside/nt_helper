part of 'disting_cubit.dart';

@freezed
class Slot with _$Slot {
  const factory Slot({
    required Algorithm algorithm,
    required RoutingInfo routing,
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
    Uint8List? screenshot,
  }) = DistingStateInitial;

  const factory DistingState.selectDevice({
    required List<MidiDevice> inputDevices,
    required List<MidiDevice> outputDevices,
    Uint8List? screenshot,
  }) = DistingStateSelectDevice;

  const factory DistingState.connected({
    required DistingMidiManager disting,
    Uint8List? screenshot,
  }) = DistingStateConnected;

  const factory DistingState.synchronized({
    required DistingMidiManager disting,
    required String distingVersion,
    required String presetName,
    required List<AlgorithmInfo> algorithms,
    required List<Slot> slots,
    required List<String> unitStrings,
    Uint8List? screenshot,
  }) = DistingStateSynchronized;
}
