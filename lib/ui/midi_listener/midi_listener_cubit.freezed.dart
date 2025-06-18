// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'midi_listener_cubit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$MidiListenerState {
  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is MidiListenerState);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'MidiListenerState()';
  }
}

/// @nodoc
class $MidiListenerStateCopyWith<$Res> {
  $MidiListenerStateCopyWith(
      MidiListenerState _, $Res Function(MidiListenerState) __);
}

/// @nodoc

class Initial implements MidiListenerState {
  const Initial();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is Initial);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'MidiListenerState.initial()';
  }
}

/// @nodoc

class Data implements MidiListenerState {
  const Data(
      {final List<MidiDevice> devices = const [],
      this.selectedDevice,
      this.isConnected = false,
      this.lastDetectedType,
      this.lastDetectedChannel,
      this.lastDetectedCc,
      this.lastDetectedNote,
      this.lastDetectedTime})
      : _devices = devices;

  final List<MidiDevice> _devices;
  @JsonKey()
  List<MidiDevice> get devices {
    if (_devices is EqualUnmodifiableListView) return _devices;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_devices);
  }

  final MidiDevice? selectedDevice;
  @JsonKey()
  final bool isConnected;
  final MidiEventType? lastDetectedType;
  final int? lastDetectedChannel;
  final int? lastDetectedCc;
  final int? lastDetectedNote;
  final DateTime? lastDetectedTime;

  /// Create a copy of MidiListenerState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $DataCopyWith<Data> get copyWith =>
      _$DataCopyWithImpl<Data>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is Data &&
            const DeepCollectionEquality().equals(other._devices, _devices) &&
            (identical(other.selectedDevice, selectedDevice) ||
                other.selectedDevice == selectedDevice) &&
            (identical(other.isConnected, isConnected) ||
                other.isConnected == isConnected) &&
            (identical(other.lastDetectedType, lastDetectedType) ||
                other.lastDetectedType == lastDetectedType) &&
            (identical(other.lastDetectedChannel, lastDetectedChannel) ||
                other.lastDetectedChannel == lastDetectedChannel) &&
            (identical(other.lastDetectedCc, lastDetectedCc) ||
                other.lastDetectedCc == lastDetectedCc) &&
            (identical(other.lastDetectedNote, lastDetectedNote) ||
                other.lastDetectedNote == lastDetectedNote) &&
            (identical(other.lastDetectedTime, lastDetectedTime) ||
                other.lastDetectedTime == lastDetectedTime));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(_devices),
      selectedDevice,
      isConnected,
      lastDetectedType,
      lastDetectedChannel,
      lastDetectedCc,
      lastDetectedNote,
      lastDetectedTime);

  @override
  String toString() {
    return 'MidiListenerState.data(devices: $devices, selectedDevice: $selectedDevice, isConnected: $isConnected, lastDetectedType: $lastDetectedType, lastDetectedChannel: $lastDetectedChannel, lastDetectedCc: $lastDetectedCc, lastDetectedNote: $lastDetectedNote, lastDetectedTime: $lastDetectedTime)';
  }
}

/// @nodoc
abstract mixin class $DataCopyWith<$Res>
    implements $MidiListenerStateCopyWith<$Res> {
  factory $DataCopyWith(Data value, $Res Function(Data) _then) =
      _$DataCopyWithImpl;
  @useResult
  $Res call(
      {List<MidiDevice> devices,
      MidiDevice? selectedDevice,
      bool isConnected,
      MidiEventType? lastDetectedType,
      int? lastDetectedChannel,
      int? lastDetectedCc,
      int? lastDetectedNote,
      DateTime? lastDetectedTime});
}

/// @nodoc
class _$DataCopyWithImpl<$Res> implements $DataCopyWith<$Res> {
  _$DataCopyWithImpl(this._self, this._then);

  final Data _self;
  final $Res Function(Data) _then;

  /// Create a copy of MidiListenerState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? devices = null,
    Object? selectedDevice = freezed,
    Object? isConnected = null,
    Object? lastDetectedType = freezed,
    Object? lastDetectedChannel = freezed,
    Object? lastDetectedCc = freezed,
    Object? lastDetectedNote = freezed,
    Object? lastDetectedTime = freezed,
  }) {
    return _then(Data(
      devices: null == devices
          ? _self._devices
          : devices // ignore: cast_nullable_to_non_nullable
              as List<MidiDevice>,
      selectedDevice: freezed == selectedDevice
          ? _self.selectedDevice
          : selectedDevice // ignore: cast_nullable_to_non_nullable
              as MidiDevice?,
      isConnected: null == isConnected
          ? _self.isConnected
          : isConnected // ignore: cast_nullable_to_non_nullable
              as bool,
      lastDetectedType: freezed == lastDetectedType
          ? _self.lastDetectedType
          : lastDetectedType // ignore: cast_nullable_to_non_nullable
              as MidiEventType?,
      lastDetectedChannel: freezed == lastDetectedChannel
          ? _self.lastDetectedChannel
          : lastDetectedChannel // ignore: cast_nullable_to_non_nullable
              as int?,
      lastDetectedCc: freezed == lastDetectedCc
          ? _self.lastDetectedCc
          : lastDetectedCc // ignore: cast_nullable_to_non_nullable
              as int?,
      lastDetectedNote: freezed == lastDetectedNote
          ? _self.lastDetectedNote
          : lastDetectedNote // ignore: cast_nullable_to_non_nullable
              as int?,
      lastDetectedTime: freezed == lastDetectedTime
          ? _self.lastDetectedTime
          : lastDetectedTime // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

// dart format on
