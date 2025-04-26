// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'midi_listener_cubit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$MidiListenerState {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function(
            List<MidiDevice> devices,
            MidiDevice? selectedDevice,
            bool isConnected,
            MidiEventType? lastDetectedType,
            int? lastDetectedChannel,
            int? lastDetectedCc,
            int? lastDetectedNote,
            DateTime? lastDetectedTime)
        data,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function(
            List<MidiDevice> devices,
            MidiDevice? selectedDevice,
            bool isConnected,
            MidiEventType? lastDetectedType,
            int? lastDetectedChannel,
            int? lastDetectedCc,
            int? lastDetectedNote,
            DateTime? lastDetectedTime)?
        data,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function(
            List<MidiDevice> devices,
            MidiDevice? selectedDevice,
            bool isConnected,
            MidiEventType? lastDetectedType,
            int? lastDetectedChannel,
            int? lastDetectedCc,
            int? lastDetectedNote,
            DateTime? lastDetectedTime)?
        data,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Initial value) initial,
    required TResult Function(_Data value) data,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Initial value)? initial,
    TResult? Function(_Data value)? data,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Initial value)? initial,
    TResult Function(_Data value)? data,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MidiListenerStateCopyWith<$Res> {
  factory $MidiListenerStateCopyWith(
          MidiListenerState value, $Res Function(MidiListenerState) then) =
      _$MidiListenerStateCopyWithImpl<$Res, MidiListenerState>;
}

/// @nodoc
class _$MidiListenerStateCopyWithImpl<$Res, $Val extends MidiListenerState>
    implements $MidiListenerStateCopyWith<$Res> {
  _$MidiListenerStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MidiListenerState
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc
abstract class _$$InitialImplCopyWith<$Res> {
  factory _$$InitialImplCopyWith(
          _$InitialImpl value, $Res Function(_$InitialImpl) then) =
      __$$InitialImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$InitialImplCopyWithImpl<$Res>
    extends _$MidiListenerStateCopyWithImpl<$Res, _$InitialImpl>
    implements _$$InitialImplCopyWith<$Res> {
  __$$InitialImplCopyWithImpl(
      _$InitialImpl _value, $Res Function(_$InitialImpl) _then)
      : super(_value, _then);

  /// Create a copy of MidiListenerState
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$InitialImpl implements _Initial {
  const _$InitialImpl();

  @override
  String toString() {
    return 'MidiListenerState.initial()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$InitialImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function(
            List<MidiDevice> devices,
            MidiDevice? selectedDevice,
            bool isConnected,
            MidiEventType? lastDetectedType,
            int? lastDetectedChannel,
            int? lastDetectedCc,
            int? lastDetectedNote,
            DateTime? lastDetectedTime)
        data,
  }) {
    return initial();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function(
            List<MidiDevice> devices,
            MidiDevice? selectedDevice,
            bool isConnected,
            MidiEventType? lastDetectedType,
            int? lastDetectedChannel,
            int? lastDetectedCc,
            int? lastDetectedNote,
            DateTime? lastDetectedTime)?
        data,
  }) {
    return initial?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function(
            List<MidiDevice> devices,
            MidiDevice? selectedDevice,
            bool isConnected,
            MidiEventType? lastDetectedType,
            int? lastDetectedChannel,
            int? lastDetectedCc,
            int? lastDetectedNote,
            DateTime? lastDetectedTime)?
        data,
    required TResult orElse(),
  }) {
    if (initial != null) {
      return initial();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Initial value) initial,
    required TResult Function(_Data value) data,
  }) {
    return initial(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Initial value)? initial,
    TResult? Function(_Data value)? data,
  }) {
    return initial?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Initial value)? initial,
    TResult Function(_Data value)? data,
    required TResult orElse(),
  }) {
    if (initial != null) {
      return initial(this);
    }
    return orElse();
  }
}

abstract class _Initial implements MidiListenerState {
  const factory _Initial() = _$InitialImpl;
}

/// @nodoc
abstract class _$$DataImplCopyWith<$Res> {
  factory _$$DataImplCopyWith(
          _$DataImpl value, $Res Function(_$DataImpl) then) =
      __$$DataImplCopyWithImpl<$Res>;
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
class __$$DataImplCopyWithImpl<$Res>
    extends _$MidiListenerStateCopyWithImpl<$Res, _$DataImpl>
    implements _$$DataImplCopyWith<$Res> {
  __$$DataImplCopyWithImpl(_$DataImpl _value, $Res Function(_$DataImpl) _then)
      : super(_value, _then);

  /// Create a copy of MidiListenerState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
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
    return _then(_$DataImpl(
      devices: null == devices
          ? _value._devices
          : devices // ignore: cast_nullable_to_non_nullable
              as List<MidiDevice>,
      selectedDevice: freezed == selectedDevice
          ? _value.selectedDevice
          : selectedDevice // ignore: cast_nullable_to_non_nullable
              as MidiDevice?,
      isConnected: null == isConnected
          ? _value.isConnected
          : isConnected // ignore: cast_nullable_to_non_nullable
              as bool,
      lastDetectedType: freezed == lastDetectedType
          ? _value.lastDetectedType
          : lastDetectedType // ignore: cast_nullable_to_non_nullable
              as MidiEventType?,
      lastDetectedChannel: freezed == lastDetectedChannel
          ? _value.lastDetectedChannel
          : lastDetectedChannel // ignore: cast_nullable_to_non_nullable
              as int?,
      lastDetectedCc: freezed == lastDetectedCc
          ? _value.lastDetectedCc
          : lastDetectedCc // ignore: cast_nullable_to_non_nullable
              as int?,
      lastDetectedNote: freezed == lastDetectedNote
          ? _value.lastDetectedNote
          : lastDetectedNote // ignore: cast_nullable_to_non_nullable
              as int?,
      lastDetectedTime: freezed == lastDetectedTime
          ? _value.lastDetectedTime
          : lastDetectedTime // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc

class _$DataImpl implements _Data {
  const _$DataImpl(
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
  @override
  @JsonKey()
  List<MidiDevice> get devices {
    if (_devices is EqualUnmodifiableListView) return _devices;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_devices);
  }

  @override
  final MidiDevice? selectedDevice;
  @override
  @JsonKey()
  final bool isConnected;
  @override
  final MidiEventType? lastDetectedType;
  @override
  final int? lastDetectedChannel;
  @override
  final int? lastDetectedCc;
  @override
  final int? lastDetectedNote;
  @override
  final DateTime? lastDetectedTime;

  @override
  String toString() {
    return 'MidiListenerState.data(devices: $devices, selectedDevice: $selectedDevice, isConnected: $isConnected, lastDetectedType: $lastDetectedType, lastDetectedChannel: $lastDetectedChannel, lastDetectedCc: $lastDetectedCc, lastDetectedNote: $lastDetectedNote, lastDetectedTime: $lastDetectedTime)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DataImpl &&
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

  /// Create a copy of MidiListenerState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DataImplCopyWith<_$DataImpl> get copyWith =>
      __$$DataImplCopyWithImpl<_$DataImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function(
            List<MidiDevice> devices,
            MidiDevice? selectedDevice,
            bool isConnected,
            MidiEventType? lastDetectedType,
            int? lastDetectedChannel,
            int? lastDetectedCc,
            int? lastDetectedNote,
            DateTime? lastDetectedTime)
        data,
  }) {
    return data(
        devices,
        selectedDevice,
        isConnected,
        lastDetectedType,
        lastDetectedChannel,
        lastDetectedCc,
        lastDetectedNote,
        lastDetectedTime);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function(
            List<MidiDevice> devices,
            MidiDevice? selectedDevice,
            bool isConnected,
            MidiEventType? lastDetectedType,
            int? lastDetectedChannel,
            int? lastDetectedCc,
            int? lastDetectedNote,
            DateTime? lastDetectedTime)?
        data,
  }) {
    return data?.call(
        devices,
        selectedDevice,
        isConnected,
        lastDetectedType,
        lastDetectedChannel,
        lastDetectedCc,
        lastDetectedNote,
        lastDetectedTime);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function(
            List<MidiDevice> devices,
            MidiDevice? selectedDevice,
            bool isConnected,
            MidiEventType? lastDetectedType,
            int? lastDetectedChannel,
            int? lastDetectedCc,
            int? lastDetectedNote,
            DateTime? lastDetectedTime)?
        data,
    required TResult orElse(),
  }) {
    if (data != null) {
      return data(
          devices,
          selectedDevice,
          isConnected,
          lastDetectedType,
          lastDetectedChannel,
          lastDetectedCc,
          lastDetectedNote,
          lastDetectedTime);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Initial value) initial,
    required TResult Function(_Data value) data,
  }) {
    return data(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Initial value)? initial,
    TResult? Function(_Data value)? data,
  }) {
    return data?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Initial value)? initial,
    TResult Function(_Data value)? data,
    required TResult orElse(),
  }) {
    if (data != null) {
      return data(this);
    }
    return orElse();
  }
}

abstract class _Data implements MidiListenerState {
  const factory _Data(
      {final List<MidiDevice> devices,
      final MidiDevice? selectedDevice,
      final bool isConnected,
      final MidiEventType? lastDetectedType,
      final int? lastDetectedChannel,
      final int? lastDetectedCc,
      final int? lastDetectedNote,
      final DateTime? lastDetectedTime}) = _$DataImpl;

  List<MidiDevice> get devices;
  MidiDevice? get selectedDevice;
  bool get isConnected;
  MidiEventType? get lastDetectedType;
  int? get lastDetectedChannel;
  int? get lastDetectedCc;
  int? get lastDetectedNote;
  DateTime? get lastDetectedTime;

  /// Create a copy of MidiListenerState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DataImplCopyWith<_$DataImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
