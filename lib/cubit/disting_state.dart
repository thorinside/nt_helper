part of 'disting_cubit.dart';

@freezed
class Slot with _$Slot {
  const factory Slot({
    required Algorithm algorithm,
    required RoutingInfo routing,
    required ParameterPages pages,
    required List<ParameterInfo> parameters,
    required List<ParameterValue> values,
    required List<ParameterEnumStrings> enums,
    required List<Mapping> mappings,
    required List<ParameterValueString> valueStrings,
  }) = _Slot;
}

@freezed
class MappedParameter with _$MappedParameter {
  const factory MappedParameter({
    required final ParameterInfo parameter,
    required final ParameterValue value,
    required final ParameterEnumStrings enums,
    required final ParameterValueString valueString,
    required final Mapping mapping,
    required final Algorithm algorithm,
  }) = _MappedParameter;
}

@freezed
sealed class DistingState with _$DistingState {
  const factory DistingState.initial() = DistingStateInitial;

  const factory DistingState.selectDevice({
    required List<MidiDevice> inputDevices,
    required List<MidiDevice> outputDevices,
    required bool canWorkOffline,
  }) = DistingStateSelectDevice;

  const factory DistingState.connected({
    required IDistingMidiManager disting,
    MidiDevice? inputDevice,
    MidiDevice? outputDevice,
    @Default(false) bool offline,
    @Default(false) bool loading,
  }) = DistingStateConnected;

  const factory DistingState.synchronized({
    required IDistingMidiManager disting,
    required String distingVersion,
    required String presetName,
    required List<AlgorithmInfo> algorithms,
    required List<Slot> slots,
    required List<String> unitStrings,
    MidiDevice? inputDevice,
    MidiDevice? outputDevice,
    Uint8List? screenshot,
    @Default(false) bool loading,
    @Default(false) bool demo,
    @Default(false) bool offline,
  }) = DistingStateSynchronized;
}
