// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'disting_cubit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$Slot {
  AlgorithmGuid get algorithmGuid => throw _privateConstructorUsedError;
  List<ParameterInfo> get parameters => throw _privateConstructorUsedError;
  List<ParameterValue> get values => throw _privateConstructorUsedError;
  List<ParameterEnumStrings> get enums => throw _privateConstructorUsedError;
  List<Mapping> get mappings => throw _privateConstructorUsedError;
  List<ParameterValueString> get valueStrings =>
      throw _privateConstructorUsedError;

  /// Create a copy of Slot
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SlotCopyWith<Slot> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SlotCopyWith<$Res> {
  factory $SlotCopyWith(Slot value, $Res Function(Slot) then) =
      _$SlotCopyWithImpl<$Res, Slot>;
  @useResult
  $Res call(
      {AlgorithmGuid algorithmGuid,
      List<ParameterInfo> parameters,
      List<ParameterValue> values,
      List<ParameterEnumStrings> enums,
      List<Mapping> mappings,
      List<ParameterValueString> valueStrings});
}

/// @nodoc
class _$SlotCopyWithImpl<$Res, $Val extends Slot>
    implements $SlotCopyWith<$Res> {
  _$SlotCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Slot
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? algorithmGuid = null,
    Object? parameters = null,
    Object? values = null,
    Object? enums = null,
    Object? mappings = null,
    Object? valueStrings = null,
  }) {
    return _then(_value.copyWith(
      algorithmGuid: null == algorithmGuid
          ? _value.algorithmGuid
          : algorithmGuid // ignore: cast_nullable_to_non_nullable
              as AlgorithmGuid,
      parameters: null == parameters
          ? _value.parameters
          : parameters // ignore: cast_nullable_to_non_nullable
              as List<ParameterInfo>,
      values: null == values
          ? _value.values
          : values // ignore: cast_nullable_to_non_nullable
              as List<ParameterValue>,
      enums: null == enums
          ? _value.enums
          : enums // ignore: cast_nullable_to_non_nullable
              as List<ParameterEnumStrings>,
      mappings: null == mappings
          ? _value.mappings
          : mappings // ignore: cast_nullable_to_non_nullable
              as List<Mapping>,
      valueStrings: null == valueStrings
          ? _value.valueStrings
          : valueStrings // ignore: cast_nullable_to_non_nullable
              as List<ParameterValueString>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$SlotImplCopyWith<$Res> implements $SlotCopyWith<$Res> {
  factory _$$SlotImplCopyWith(
          _$SlotImpl value, $Res Function(_$SlotImpl) then) =
      __$$SlotImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {AlgorithmGuid algorithmGuid,
      List<ParameterInfo> parameters,
      List<ParameterValue> values,
      List<ParameterEnumStrings> enums,
      List<Mapping> mappings,
      List<ParameterValueString> valueStrings});
}

/// @nodoc
class __$$SlotImplCopyWithImpl<$Res>
    extends _$SlotCopyWithImpl<$Res, _$SlotImpl>
    implements _$$SlotImplCopyWith<$Res> {
  __$$SlotImplCopyWithImpl(_$SlotImpl _value, $Res Function(_$SlotImpl) _then)
      : super(_value, _then);

  /// Create a copy of Slot
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? algorithmGuid = null,
    Object? parameters = null,
    Object? values = null,
    Object? enums = null,
    Object? mappings = null,
    Object? valueStrings = null,
  }) {
    return _then(_$SlotImpl(
      algorithmGuid: null == algorithmGuid
          ? _value.algorithmGuid
          : algorithmGuid // ignore: cast_nullable_to_non_nullable
              as AlgorithmGuid,
      parameters: null == parameters
          ? _value._parameters
          : parameters // ignore: cast_nullable_to_non_nullable
              as List<ParameterInfo>,
      values: null == values
          ? _value._values
          : values // ignore: cast_nullable_to_non_nullable
              as List<ParameterValue>,
      enums: null == enums
          ? _value._enums
          : enums // ignore: cast_nullable_to_non_nullable
              as List<ParameterEnumStrings>,
      mappings: null == mappings
          ? _value._mappings
          : mappings // ignore: cast_nullable_to_non_nullable
              as List<Mapping>,
      valueStrings: null == valueStrings
          ? _value._valueStrings
          : valueStrings // ignore: cast_nullable_to_non_nullable
              as List<ParameterValueString>,
    ));
  }
}

/// @nodoc

class _$SlotImpl implements _Slot {
  const _$SlotImpl(
      {required this.algorithmGuid,
      required final List<ParameterInfo> parameters,
      required final List<ParameterValue> values,
      required final List<ParameterEnumStrings> enums,
      required final List<Mapping> mappings,
      required final List<ParameterValueString> valueStrings})
      : _parameters = parameters,
        _values = values,
        _enums = enums,
        _mappings = mappings,
        _valueStrings = valueStrings;

  @override
  final AlgorithmGuid algorithmGuid;
  final List<ParameterInfo> _parameters;
  @override
  List<ParameterInfo> get parameters {
    if (_parameters is EqualUnmodifiableListView) return _parameters;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_parameters);
  }

  final List<ParameterValue> _values;
  @override
  List<ParameterValue> get values {
    if (_values is EqualUnmodifiableListView) return _values;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_values);
  }

  final List<ParameterEnumStrings> _enums;
  @override
  List<ParameterEnumStrings> get enums {
    if (_enums is EqualUnmodifiableListView) return _enums;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_enums);
  }

  final List<Mapping> _mappings;
  @override
  List<Mapping> get mappings {
    if (_mappings is EqualUnmodifiableListView) return _mappings;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_mappings);
  }

  final List<ParameterValueString> _valueStrings;
  @override
  List<ParameterValueString> get valueStrings {
    if (_valueStrings is EqualUnmodifiableListView) return _valueStrings;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_valueStrings);
  }

  @override
  String toString() {
    return 'Slot(algorithmGuid: $algorithmGuid, parameters: $parameters, values: $values, enums: $enums, mappings: $mappings, valueStrings: $valueStrings)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SlotImpl &&
            (identical(other.algorithmGuid, algorithmGuid) ||
                other.algorithmGuid == algorithmGuid) &&
            const DeepCollectionEquality()
                .equals(other._parameters, _parameters) &&
            const DeepCollectionEquality().equals(other._values, _values) &&
            const DeepCollectionEquality().equals(other._enums, _enums) &&
            const DeepCollectionEquality().equals(other._mappings, _mappings) &&
            const DeepCollectionEquality()
                .equals(other._valueStrings, _valueStrings));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      algorithmGuid,
      const DeepCollectionEquality().hash(_parameters),
      const DeepCollectionEquality().hash(_values),
      const DeepCollectionEquality().hash(_enums),
      const DeepCollectionEquality().hash(_mappings),
      const DeepCollectionEquality().hash(_valueStrings));

  /// Create a copy of Slot
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SlotImplCopyWith<_$SlotImpl> get copyWith =>
      __$$SlotImplCopyWithImpl<_$SlotImpl>(this, _$identity);
}

abstract class _Slot implements Slot {
  const factory _Slot(
      {required final AlgorithmGuid algorithmGuid,
      required final List<ParameterInfo> parameters,
      required final List<ParameterValue> values,
      required final List<ParameterEnumStrings> enums,
      required final List<Mapping> mappings,
      required final List<ParameterValueString> valueStrings}) = _$SlotImpl;

  @override
  AlgorithmGuid get algorithmGuid;
  @override
  List<ParameterInfo> get parameters;
  @override
  List<ParameterValue> get values;
  @override
  List<ParameterEnumStrings> get enums;
  @override
  List<Mapping> get mappings;
  @override
  List<ParameterValueString> get valueStrings;

  /// Create a copy of Slot
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SlotImplCopyWith<_$SlotImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$DistingState {
  MidiCommand get midiCommand => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(MidiCommand midiCommand) initial,
    required TResult Function(MidiCommand midiCommand, List<MidiDevice> devices)
        selectDevice,
    required TResult Function(MidiCommand midiCommand, MidiDevice device,
            int sysExId, DistingMidiManager disting)
        connected,
    required TResult Function(
            MidiCommand midiCommand,
            MidiDevice device,
            int sysExId,
            DistingMidiManager disting,
            String distingVersion,
            String patchName,
            List<AlgorithmInfo> algorithms,
            List<Slot> slots,
            List<String> unitStrings,
            bool complete,
            bool selectAlgorithm)
        synchronized,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(MidiCommand midiCommand)? initial,
    TResult? Function(MidiCommand midiCommand, List<MidiDevice> devices)?
        selectDevice,
    TResult? Function(MidiCommand midiCommand, MidiDevice device, int sysExId,
            DistingMidiManager disting)?
        connected,
    TResult? Function(
            MidiCommand midiCommand,
            MidiDevice device,
            int sysExId,
            DistingMidiManager disting,
            String distingVersion,
            String patchName,
            List<AlgorithmInfo> algorithms,
            List<Slot> slots,
            List<String> unitStrings,
            bool complete,
            bool selectAlgorithm)?
        synchronized,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(MidiCommand midiCommand)? initial,
    TResult Function(MidiCommand midiCommand, List<MidiDevice> devices)?
        selectDevice,
    TResult Function(MidiCommand midiCommand, MidiDevice device, int sysExId,
            DistingMidiManager disting)?
        connected,
    TResult Function(
            MidiCommand midiCommand,
            MidiDevice device,
            int sysExId,
            DistingMidiManager disting,
            String distingVersion,
            String patchName,
            List<AlgorithmInfo> algorithms,
            List<Slot> slots,
            List<String> unitStrings,
            bool complete,
            bool selectAlgorithm)?
        synchronized,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(DistingStateInitial value) initial,
    required TResult Function(DistingStateSelectDevice value) selectDevice,
    required TResult Function(DistingStateConnected value) connected,
    required TResult Function(DistingStateSynchronized value) synchronized,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(DistingStateInitial value)? initial,
    TResult? Function(DistingStateSelectDevice value)? selectDevice,
    TResult? Function(DistingStateConnected value)? connected,
    TResult? Function(DistingStateSynchronized value)? synchronized,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(DistingStateInitial value)? initial,
    TResult Function(DistingStateSelectDevice value)? selectDevice,
    TResult Function(DistingStateConnected value)? connected,
    TResult Function(DistingStateSynchronized value)? synchronized,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;

  /// Create a copy of DistingState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $DistingStateCopyWith<DistingState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DistingStateCopyWith<$Res> {
  factory $DistingStateCopyWith(
          DistingState value, $Res Function(DistingState) then) =
      _$DistingStateCopyWithImpl<$Res, DistingState>;
  @useResult
  $Res call({MidiCommand midiCommand});
}

/// @nodoc
class _$DistingStateCopyWithImpl<$Res, $Val extends DistingState>
    implements $DistingStateCopyWith<$Res> {
  _$DistingStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of DistingState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? midiCommand = null,
  }) {
    return _then(_value.copyWith(
      midiCommand: null == midiCommand
          ? _value.midiCommand
          : midiCommand // ignore: cast_nullable_to_non_nullable
              as MidiCommand,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$DistingStateInitialImplCopyWith<$Res>
    implements $DistingStateCopyWith<$Res> {
  factory _$$DistingStateInitialImplCopyWith(_$DistingStateInitialImpl value,
          $Res Function(_$DistingStateInitialImpl) then) =
      __$$DistingStateInitialImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({MidiCommand midiCommand});
}

/// @nodoc
class __$$DistingStateInitialImplCopyWithImpl<$Res>
    extends _$DistingStateCopyWithImpl<$Res, _$DistingStateInitialImpl>
    implements _$$DistingStateInitialImplCopyWith<$Res> {
  __$$DistingStateInitialImplCopyWithImpl(_$DistingStateInitialImpl _value,
      $Res Function(_$DistingStateInitialImpl) _then)
      : super(_value, _then);

  /// Create a copy of DistingState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? midiCommand = null,
  }) {
    return _then(_$DistingStateInitialImpl(
      midiCommand: null == midiCommand
          ? _value.midiCommand
          : midiCommand // ignore: cast_nullable_to_non_nullable
              as MidiCommand,
    ));
  }
}

/// @nodoc

class _$DistingStateInitialImpl implements DistingStateInitial {
  const _$DistingStateInitialImpl({required this.midiCommand});

  @override
  final MidiCommand midiCommand;

  @override
  String toString() {
    return 'DistingState.initial(midiCommand: $midiCommand)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DistingStateInitialImpl &&
            (identical(other.midiCommand, midiCommand) ||
                other.midiCommand == midiCommand));
  }

  @override
  int get hashCode => Object.hash(runtimeType, midiCommand);

  /// Create a copy of DistingState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DistingStateInitialImplCopyWith<_$DistingStateInitialImpl> get copyWith =>
      __$$DistingStateInitialImplCopyWithImpl<_$DistingStateInitialImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(MidiCommand midiCommand) initial,
    required TResult Function(MidiCommand midiCommand, List<MidiDevice> devices)
        selectDevice,
    required TResult Function(MidiCommand midiCommand, MidiDevice device,
            int sysExId, DistingMidiManager disting)
        connected,
    required TResult Function(
            MidiCommand midiCommand,
            MidiDevice device,
            int sysExId,
            DistingMidiManager disting,
            String distingVersion,
            String patchName,
            List<AlgorithmInfo> algorithms,
            List<Slot> slots,
            List<String> unitStrings,
            bool complete,
            bool selectAlgorithm)
        synchronized,
  }) {
    return initial(midiCommand);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(MidiCommand midiCommand)? initial,
    TResult? Function(MidiCommand midiCommand, List<MidiDevice> devices)?
        selectDevice,
    TResult? Function(MidiCommand midiCommand, MidiDevice device, int sysExId,
            DistingMidiManager disting)?
        connected,
    TResult? Function(
            MidiCommand midiCommand,
            MidiDevice device,
            int sysExId,
            DistingMidiManager disting,
            String distingVersion,
            String patchName,
            List<AlgorithmInfo> algorithms,
            List<Slot> slots,
            List<String> unitStrings,
            bool complete,
            bool selectAlgorithm)?
        synchronized,
  }) {
    return initial?.call(midiCommand);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(MidiCommand midiCommand)? initial,
    TResult Function(MidiCommand midiCommand, List<MidiDevice> devices)?
        selectDevice,
    TResult Function(MidiCommand midiCommand, MidiDevice device, int sysExId,
            DistingMidiManager disting)?
        connected,
    TResult Function(
            MidiCommand midiCommand,
            MidiDevice device,
            int sysExId,
            DistingMidiManager disting,
            String distingVersion,
            String patchName,
            List<AlgorithmInfo> algorithms,
            List<Slot> slots,
            List<String> unitStrings,
            bool complete,
            bool selectAlgorithm)?
        synchronized,
    required TResult orElse(),
  }) {
    if (initial != null) {
      return initial(midiCommand);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(DistingStateInitial value) initial,
    required TResult Function(DistingStateSelectDevice value) selectDevice,
    required TResult Function(DistingStateConnected value) connected,
    required TResult Function(DistingStateSynchronized value) synchronized,
  }) {
    return initial(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(DistingStateInitial value)? initial,
    TResult? Function(DistingStateSelectDevice value)? selectDevice,
    TResult? Function(DistingStateConnected value)? connected,
    TResult? Function(DistingStateSynchronized value)? synchronized,
  }) {
    return initial?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(DistingStateInitial value)? initial,
    TResult Function(DistingStateSelectDevice value)? selectDevice,
    TResult Function(DistingStateConnected value)? connected,
    TResult Function(DistingStateSynchronized value)? synchronized,
    required TResult orElse(),
  }) {
    if (initial != null) {
      return initial(this);
    }
    return orElse();
  }
}

abstract class DistingStateInitial implements DistingState {
  const factory DistingStateInitial({required final MidiCommand midiCommand}) =
      _$DistingStateInitialImpl;

  @override
  MidiCommand get midiCommand;

  /// Create a copy of DistingState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DistingStateInitialImplCopyWith<_$DistingStateInitialImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$DistingStateSelectDeviceImplCopyWith<$Res>
    implements $DistingStateCopyWith<$Res> {
  factory _$$DistingStateSelectDeviceImplCopyWith(
          _$DistingStateSelectDeviceImpl value,
          $Res Function(_$DistingStateSelectDeviceImpl) then) =
      __$$DistingStateSelectDeviceImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({MidiCommand midiCommand, List<MidiDevice> devices});
}

/// @nodoc
class __$$DistingStateSelectDeviceImplCopyWithImpl<$Res>
    extends _$DistingStateCopyWithImpl<$Res, _$DistingStateSelectDeviceImpl>
    implements _$$DistingStateSelectDeviceImplCopyWith<$Res> {
  __$$DistingStateSelectDeviceImplCopyWithImpl(
      _$DistingStateSelectDeviceImpl _value,
      $Res Function(_$DistingStateSelectDeviceImpl) _then)
      : super(_value, _then);

  /// Create a copy of DistingState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? midiCommand = null,
    Object? devices = null,
  }) {
    return _then(_$DistingStateSelectDeviceImpl(
      midiCommand: null == midiCommand
          ? _value.midiCommand
          : midiCommand // ignore: cast_nullable_to_non_nullable
              as MidiCommand,
      devices: null == devices
          ? _value._devices
          : devices // ignore: cast_nullable_to_non_nullable
              as List<MidiDevice>,
    ));
  }
}

/// @nodoc

class _$DistingStateSelectDeviceImpl implements DistingStateSelectDevice {
  const _$DistingStateSelectDeviceImpl(
      {required this.midiCommand, required final List<MidiDevice> devices})
      : _devices = devices;

  @override
  final MidiCommand midiCommand;
  final List<MidiDevice> _devices;
  @override
  List<MidiDevice> get devices {
    if (_devices is EqualUnmodifiableListView) return _devices;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_devices);
  }

  @override
  String toString() {
    return 'DistingState.selectDevice(midiCommand: $midiCommand, devices: $devices)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DistingStateSelectDeviceImpl &&
            (identical(other.midiCommand, midiCommand) ||
                other.midiCommand == midiCommand) &&
            const DeepCollectionEquality().equals(other._devices, _devices));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType, midiCommand, const DeepCollectionEquality().hash(_devices));

  /// Create a copy of DistingState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DistingStateSelectDeviceImplCopyWith<_$DistingStateSelectDeviceImpl>
      get copyWith => __$$DistingStateSelectDeviceImplCopyWithImpl<
          _$DistingStateSelectDeviceImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(MidiCommand midiCommand) initial,
    required TResult Function(MidiCommand midiCommand, List<MidiDevice> devices)
        selectDevice,
    required TResult Function(MidiCommand midiCommand, MidiDevice device,
            int sysExId, DistingMidiManager disting)
        connected,
    required TResult Function(
            MidiCommand midiCommand,
            MidiDevice device,
            int sysExId,
            DistingMidiManager disting,
            String distingVersion,
            String patchName,
            List<AlgorithmInfo> algorithms,
            List<Slot> slots,
            List<String> unitStrings,
            bool complete,
            bool selectAlgorithm)
        synchronized,
  }) {
    return selectDevice(midiCommand, devices);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(MidiCommand midiCommand)? initial,
    TResult? Function(MidiCommand midiCommand, List<MidiDevice> devices)?
        selectDevice,
    TResult? Function(MidiCommand midiCommand, MidiDevice device, int sysExId,
            DistingMidiManager disting)?
        connected,
    TResult? Function(
            MidiCommand midiCommand,
            MidiDevice device,
            int sysExId,
            DistingMidiManager disting,
            String distingVersion,
            String patchName,
            List<AlgorithmInfo> algorithms,
            List<Slot> slots,
            List<String> unitStrings,
            bool complete,
            bool selectAlgorithm)?
        synchronized,
  }) {
    return selectDevice?.call(midiCommand, devices);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(MidiCommand midiCommand)? initial,
    TResult Function(MidiCommand midiCommand, List<MidiDevice> devices)?
        selectDevice,
    TResult Function(MidiCommand midiCommand, MidiDevice device, int sysExId,
            DistingMidiManager disting)?
        connected,
    TResult Function(
            MidiCommand midiCommand,
            MidiDevice device,
            int sysExId,
            DistingMidiManager disting,
            String distingVersion,
            String patchName,
            List<AlgorithmInfo> algorithms,
            List<Slot> slots,
            List<String> unitStrings,
            bool complete,
            bool selectAlgorithm)?
        synchronized,
    required TResult orElse(),
  }) {
    if (selectDevice != null) {
      return selectDevice(midiCommand, devices);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(DistingStateInitial value) initial,
    required TResult Function(DistingStateSelectDevice value) selectDevice,
    required TResult Function(DistingStateConnected value) connected,
    required TResult Function(DistingStateSynchronized value) synchronized,
  }) {
    return selectDevice(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(DistingStateInitial value)? initial,
    TResult? Function(DistingStateSelectDevice value)? selectDevice,
    TResult? Function(DistingStateConnected value)? connected,
    TResult? Function(DistingStateSynchronized value)? synchronized,
  }) {
    return selectDevice?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(DistingStateInitial value)? initial,
    TResult Function(DistingStateSelectDevice value)? selectDevice,
    TResult Function(DistingStateConnected value)? connected,
    TResult Function(DistingStateSynchronized value)? synchronized,
    required TResult orElse(),
  }) {
    if (selectDevice != null) {
      return selectDevice(this);
    }
    return orElse();
  }
}

abstract class DistingStateSelectDevice implements DistingState {
  const factory DistingStateSelectDevice(
          {required final MidiCommand midiCommand,
          required final List<MidiDevice> devices}) =
      _$DistingStateSelectDeviceImpl;

  @override
  MidiCommand get midiCommand;
  List<MidiDevice> get devices;

  /// Create a copy of DistingState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DistingStateSelectDeviceImplCopyWith<_$DistingStateSelectDeviceImpl>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$DistingStateConnectedImplCopyWith<$Res>
    implements $DistingStateCopyWith<$Res> {
  factory _$$DistingStateConnectedImplCopyWith(
          _$DistingStateConnectedImpl value,
          $Res Function(_$DistingStateConnectedImpl) then) =
      __$$DistingStateConnectedImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {MidiCommand midiCommand,
      MidiDevice device,
      int sysExId,
      DistingMidiManager disting});
}

/// @nodoc
class __$$DistingStateConnectedImplCopyWithImpl<$Res>
    extends _$DistingStateCopyWithImpl<$Res, _$DistingStateConnectedImpl>
    implements _$$DistingStateConnectedImplCopyWith<$Res> {
  __$$DistingStateConnectedImplCopyWithImpl(_$DistingStateConnectedImpl _value,
      $Res Function(_$DistingStateConnectedImpl) _then)
      : super(_value, _then);

  /// Create a copy of DistingState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? midiCommand = null,
    Object? device = null,
    Object? sysExId = null,
    Object? disting = null,
  }) {
    return _then(_$DistingStateConnectedImpl(
      midiCommand: null == midiCommand
          ? _value.midiCommand
          : midiCommand // ignore: cast_nullable_to_non_nullable
              as MidiCommand,
      device: null == device
          ? _value.device
          : device // ignore: cast_nullable_to_non_nullable
              as MidiDevice,
      sysExId: null == sysExId
          ? _value.sysExId
          : sysExId // ignore: cast_nullable_to_non_nullable
              as int,
      disting: null == disting
          ? _value.disting
          : disting // ignore: cast_nullable_to_non_nullable
              as DistingMidiManager,
    ));
  }
}

/// @nodoc

class _$DistingStateConnectedImpl implements DistingStateConnected {
  const _$DistingStateConnectedImpl(
      {required this.midiCommand,
      required this.device,
      required this.sysExId,
      required this.disting});

  @override
  final MidiCommand midiCommand;
  @override
  final MidiDevice device;
  @override
  final int sysExId;
  @override
  final DistingMidiManager disting;

  @override
  String toString() {
    return 'DistingState.connected(midiCommand: $midiCommand, device: $device, sysExId: $sysExId, disting: $disting)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DistingStateConnectedImpl &&
            (identical(other.midiCommand, midiCommand) ||
                other.midiCommand == midiCommand) &&
            (identical(other.device, device) || other.device == device) &&
            (identical(other.sysExId, sysExId) || other.sysExId == sysExId) &&
            (identical(other.disting, disting) || other.disting == disting));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, midiCommand, device, sysExId, disting);

  /// Create a copy of DistingState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DistingStateConnectedImplCopyWith<_$DistingStateConnectedImpl>
      get copyWith => __$$DistingStateConnectedImplCopyWithImpl<
          _$DistingStateConnectedImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(MidiCommand midiCommand) initial,
    required TResult Function(MidiCommand midiCommand, List<MidiDevice> devices)
        selectDevice,
    required TResult Function(MidiCommand midiCommand, MidiDevice device,
            int sysExId, DistingMidiManager disting)
        connected,
    required TResult Function(
            MidiCommand midiCommand,
            MidiDevice device,
            int sysExId,
            DistingMidiManager disting,
            String distingVersion,
            String patchName,
            List<AlgorithmInfo> algorithms,
            List<Slot> slots,
            List<String> unitStrings,
            bool complete,
            bool selectAlgorithm)
        synchronized,
  }) {
    return connected(midiCommand, device, sysExId, disting);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(MidiCommand midiCommand)? initial,
    TResult? Function(MidiCommand midiCommand, List<MidiDevice> devices)?
        selectDevice,
    TResult? Function(MidiCommand midiCommand, MidiDevice device, int sysExId,
            DistingMidiManager disting)?
        connected,
    TResult? Function(
            MidiCommand midiCommand,
            MidiDevice device,
            int sysExId,
            DistingMidiManager disting,
            String distingVersion,
            String patchName,
            List<AlgorithmInfo> algorithms,
            List<Slot> slots,
            List<String> unitStrings,
            bool complete,
            bool selectAlgorithm)?
        synchronized,
  }) {
    return connected?.call(midiCommand, device, sysExId, disting);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(MidiCommand midiCommand)? initial,
    TResult Function(MidiCommand midiCommand, List<MidiDevice> devices)?
        selectDevice,
    TResult Function(MidiCommand midiCommand, MidiDevice device, int sysExId,
            DistingMidiManager disting)?
        connected,
    TResult Function(
            MidiCommand midiCommand,
            MidiDevice device,
            int sysExId,
            DistingMidiManager disting,
            String distingVersion,
            String patchName,
            List<AlgorithmInfo> algorithms,
            List<Slot> slots,
            List<String> unitStrings,
            bool complete,
            bool selectAlgorithm)?
        synchronized,
    required TResult orElse(),
  }) {
    if (connected != null) {
      return connected(midiCommand, device, sysExId, disting);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(DistingStateInitial value) initial,
    required TResult Function(DistingStateSelectDevice value) selectDevice,
    required TResult Function(DistingStateConnected value) connected,
    required TResult Function(DistingStateSynchronized value) synchronized,
  }) {
    return connected(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(DistingStateInitial value)? initial,
    TResult? Function(DistingStateSelectDevice value)? selectDevice,
    TResult? Function(DistingStateConnected value)? connected,
    TResult? Function(DistingStateSynchronized value)? synchronized,
  }) {
    return connected?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(DistingStateInitial value)? initial,
    TResult Function(DistingStateSelectDevice value)? selectDevice,
    TResult Function(DistingStateConnected value)? connected,
    TResult Function(DistingStateSynchronized value)? synchronized,
    required TResult orElse(),
  }) {
    if (connected != null) {
      return connected(this);
    }
    return orElse();
  }
}

abstract class DistingStateConnected implements DistingState {
  const factory DistingStateConnected(
      {required final MidiCommand midiCommand,
      required final MidiDevice device,
      required final int sysExId,
      required final DistingMidiManager disting}) = _$DistingStateConnectedImpl;

  @override
  MidiCommand get midiCommand;
  MidiDevice get device;
  int get sysExId;
  DistingMidiManager get disting;

  /// Create a copy of DistingState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DistingStateConnectedImplCopyWith<_$DistingStateConnectedImpl>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$DistingStateSynchronizedImplCopyWith<$Res>
    implements $DistingStateCopyWith<$Res> {
  factory _$$DistingStateSynchronizedImplCopyWith(
          _$DistingStateSynchronizedImpl value,
          $Res Function(_$DistingStateSynchronizedImpl) then) =
      __$$DistingStateSynchronizedImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {MidiCommand midiCommand,
      MidiDevice device,
      int sysExId,
      DistingMidiManager disting,
      String distingVersion,
      String patchName,
      List<AlgorithmInfo> algorithms,
      List<Slot> slots,
      List<String> unitStrings,
      bool complete,
      bool selectAlgorithm});
}

/// @nodoc
class __$$DistingStateSynchronizedImplCopyWithImpl<$Res>
    extends _$DistingStateCopyWithImpl<$Res, _$DistingStateSynchronizedImpl>
    implements _$$DistingStateSynchronizedImplCopyWith<$Res> {
  __$$DistingStateSynchronizedImplCopyWithImpl(
      _$DistingStateSynchronizedImpl _value,
      $Res Function(_$DistingStateSynchronizedImpl) _then)
      : super(_value, _then);

  /// Create a copy of DistingState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? midiCommand = null,
    Object? device = null,
    Object? sysExId = null,
    Object? disting = null,
    Object? distingVersion = null,
    Object? patchName = null,
    Object? algorithms = null,
    Object? slots = null,
    Object? unitStrings = null,
    Object? complete = null,
    Object? selectAlgorithm = null,
  }) {
    return _then(_$DistingStateSynchronizedImpl(
      midiCommand: null == midiCommand
          ? _value.midiCommand
          : midiCommand // ignore: cast_nullable_to_non_nullable
              as MidiCommand,
      device: null == device
          ? _value.device
          : device // ignore: cast_nullable_to_non_nullable
              as MidiDevice,
      sysExId: null == sysExId
          ? _value.sysExId
          : sysExId // ignore: cast_nullable_to_non_nullable
              as int,
      disting: null == disting
          ? _value.disting
          : disting // ignore: cast_nullable_to_non_nullable
              as DistingMidiManager,
      distingVersion: null == distingVersion
          ? _value.distingVersion
          : distingVersion // ignore: cast_nullable_to_non_nullable
              as String,
      patchName: null == patchName
          ? _value.patchName
          : patchName // ignore: cast_nullable_to_non_nullable
              as String,
      algorithms: null == algorithms
          ? _value._algorithms
          : algorithms // ignore: cast_nullable_to_non_nullable
              as List<AlgorithmInfo>,
      slots: null == slots
          ? _value._slots
          : slots // ignore: cast_nullable_to_non_nullable
              as List<Slot>,
      unitStrings: null == unitStrings
          ? _value._unitStrings
          : unitStrings // ignore: cast_nullable_to_non_nullable
              as List<String>,
      complete: null == complete
          ? _value.complete
          : complete // ignore: cast_nullable_to_non_nullable
              as bool,
      selectAlgorithm: null == selectAlgorithm
          ? _value.selectAlgorithm
          : selectAlgorithm // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc

class _$DistingStateSynchronizedImpl implements DistingStateSynchronized {
  const _$DistingStateSynchronizedImpl(
      {required this.midiCommand,
      required this.device,
      required this.sysExId,
      required this.disting,
      required this.distingVersion,
      required this.patchName,
      required final List<AlgorithmInfo> algorithms,
      required final List<Slot> slots,
      required final List<String> unitStrings,
      this.complete = false,
      this.selectAlgorithm = false})
      : _algorithms = algorithms,
        _slots = slots,
        _unitStrings = unitStrings;

  @override
  final MidiCommand midiCommand;
  @override
  final MidiDevice device;
  @override
  final int sysExId;
  @override
  final DistingMidiManager disting;
  @override
  final String distingVersion;
  @override
  final String patchName;
  final List<AlgorithmInfo> _algorithms;
  @override
  List<AlgorithmInfo> get algorithms {
    if (_algorithms is EqualUnmodifiableListView) return _algorithms;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_algorithms);
  }

  final List<Slot> _slots;
  @override
  List<Slot> get slots {
    if (_slots is EqualUnmodifiableListView) return _slots;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_slots);
  }

  final List<String> _unitStrings;
  @override
  List<String> get unitStrings {
    if (_unitStrings is EqualUnmodifiableListView) return _unitStrings;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_unitStrings);
  }

  @override
  @JsonKey()
  final bool complete;
  @override
  @JsonKey()
  final bool selectAlgorithm;

  @override
  String toString() {
    return 'DistingState.synchronized(midiCommand: $midiCommand, device: $device, sysExId: $sysExId, disting: $disting, distingVersion: $distingVersion, patchName: $patchName, algorithms: $algorithms, slots: $slots, unitStrings: $unitStrings, complete: $complete, selectAlgorithm: $selectAlgorithm)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DistingStateSynchronizedImpl &&
            (identical(other.midiCommand, midiCommand) ||
                other.midiCommand == midiCommand) &&
            (identical(other.device, device) || other.device == device) &&
            (identical(other.sysExId, sysExId) || other.sysExId == sysExId) &&
            (identical(other.disting, disting) || other.disting == disting) &&
            (identical(other.distingVersion, distingVersion) ||
                other.distingVersion == distingVersion) &&
            (identical(other.patchName, patchName) ||
                other.patchName == patchName) &&
            const DeepCollectionEquality()
                .equals(other._algorithms, _algorithms) &&
            const DeepCollectionEquality().equals(other._slots, _slots) &&
            const DeepCollectionEquality()
                .equals(other._unitStrings, _unitStrings) &&
            (identical(other.complete, complete) ||
                other.complete == complete) &&
            (identical(other.selectAlgorithm, selectAlgorithm) ||
                other.selectAlgorithm == selectAlgorithm));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      midiCommand,
      device,
      sysExId,
      disting,
      distingVersion,
      patchName,
      const DeepCollectionEquality().hash(_algorithms),
      const DeepCollectionEquality().hash(_slots),
      const DeepCollectionEquality().hash(_unitStrings),
      complete,
      selectAlgorithm);

  /// Create a copy of DistingState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DistingStateSynchronizedImplCopyWith<_$DistingStateSynchronizedImpl>
      get copyWith => __$$DistingStateSynchronizedImplCopyWithImpl<
          _$DistingStateSynchronizedImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(MidiCommand midiCommand) initial,
    required TResult Function(MidiCommand midiCommand, List<MidiDevice> devices)
        selectDevice,
    required TResult Function(MidiCommand midiCommand, MidiDevice device,
            int sysExId, DistingMidiManager disting)
        connected,
    required TResult Function(
            MidiCommand midiCommand,
            MidiDevice device,
            int sysExId,
            DistingMidiManager disting,
            String distingVersion,
            String patchName,
            List<AlgorithmInfo> algorithms,
            List<Slot> slots,
            List<String> unitStrings,
            bool complete,
            bool selectAlgorithm)
        synchronized,
  }) {
    return synchronized(midiCommand, device, sysExId, disting, distingVersion,
        patchName, algorithms, slots, unitStrings, complete, selectAlgorithm);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(MidiCommand midiCommand)? initial,
    TResult? Function(MidiCommand midiCommand, List<MidiDevice> devices)?
        selectDevice,
    TResult? Function(MidiCommand midiCommand, MidiDevice device, int sysExId,
            DistingMidiManager disting)?
        connected,
    TResult? Function(
            MidiCommand midiCommand,
            MidiDevice device,
            int sysExId,
            DistingMidiManager disting,
            String distingVersion,
            String patchName,
            List<AlgorithmInfo> algorithms,
            List<Slot> slots,
            List<String> unitStrings,
            bool complete,
            bool selectAlgorithm)?
        synchronized,
  }) {
    return synchronized?.call(
        midiCommand,
        device,
        sysExId,
        disting,
        distingVersion,
        patchName,
        algorithms,
        slots,
        unitStrings,
        complete,
        selectAlgorithm);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(MidiCommand midiCommand)? initial,
    TResult Function(MidiCommand midiCommand, List<MidiDevice> devices)?
        selectDevice,
    TResult Function(MidiCommand midiCommand, MidiDevice device, int sysExId,
            DistingMidiManager disting)?
        connected,
    TResult Function(
            MidiCommand midiCommand,
            MidiDevice device,
            int sysExId,
            DistingMidiManager disting,
            String distingVersion,
            String patchName,
            List<AlgorithmInfo> algorithms,
            List<Slot> slots,
            List<String> unitStrings,
            bool complete,
            bool selectAlgorithm)?
        synchronized,
    required TResult orElse(),
  }) {
    if (synchronized != null) {
      return synchronized(midiCommand, device, sysExId, disting, distingVersion,
          patchName, algorithms, slots, unitStrings, complete, selectAlgorithm);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(DistingStateInitial value) initial,
    required TResult Function(DistingStateSelectDevice value) selectDevice,
    required TResult Function(DistingStateConnected value) connected,
    required TResult Function(DistingStateSynchronized value) synchronized,
  }) {
    return synchronized(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(DistingStateInitial value)? initial,
    TResult? Function(DistingStateSelectDevice value)? selectDevice,
    TResult? Function(DistingStateConnected value)? connected,
    TResult? Function(DistingStateSynchronized value)? synchronized,
  }) {
    return synchronized?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(DistingStateInitial value)? initial,
    TResult Function(DistingStateSelectDevice value)? selectDevice,
    TResult Function(DistingStateConnected value)? connected,
    TResult Function(DistingStateSynchronized value)? synchronized,
    required TResult orElse(),
  }) {
    if (synchronized != null) {
      return synchronized(this);
    }
    return orElse();
  }
}

abstract class DistingStateSynchronized implements DistingState {
  const factory DistingStateSynchronized(
      {required final MidiCommand midiCommand,
      required final MidiDevice device,
      required final int sysExId,
      required final DistingMidiManager disting,
      required final String distingVersion,
      required final String patchName,
      required final List<AlgorithmInfo> algorithms,
      required final List<Slot> slots,
      required final List<String> unitStrings,
      final bool complete,
      final bool selectAlgorithm}) = _$DistingStateSynchronizedImpl;

  @override
  MidiCommand get midiCommand;
  MidiDevice get device;
  int get sysExId;
  DistingMidiManager get disting;
  String get distingVersion;
  String get patchName;
  List<AlgorithmInfo> get algorithms;
  List<Slot> get slots;
  List<String> get unitStrings;
  bool get complete;
  bool get selectAlgorithm;

  /// Create a copy of DistingState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DistingStateSynchronizedImplCopyWith<_$DistingStateSynchronizedImpl>
      get copyWith => throw _privateConstructorUsedError;
}
