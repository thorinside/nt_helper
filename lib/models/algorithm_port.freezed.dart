// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'algorithm_port.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

AlgorithmPort _$AlgorithmPortFromJson(Map<String, dynamic> json) {
  return _AlgorithmPort.fromJson(json);
}

/// @nodoc
mixin _$AlgorithmPort {
  String? get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  @JsonKey(name: 'busIdRef')
  String? get busIdRef => throw _privateConstructorUsedError;
  @JsonKey(name: 'channelCountRef')
  String? get channelCountRef => throw _privateConstructorUsedError;
  @JsonKey(name: 'isPerChannel')
  bool? get isPerChannel => throw _privateConstructorUsedError;

  /// Serializes this AlgorithmPort to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of AlgorithmPort
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AlgorithmPortCopyWith<AlgorithmPort> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AlgorithmPortCopyWith<$Res> {
  factory $AlgorithmPortCopyWith(
          AlgorithmPort value, $Res Function(AlgorithmPort) then) =
      _$AlgorithmPortCopyWithImpl<$Res, AlgorithmPort>;
  @useResult
  $Res call(
      {String? id,
      String name,
      String? description,
      @JsonKey(name: 'busIdRef') String? busIdRef,
      @JsonKey(name: 'channelCountRef') String? channelCountRef,
      @JsonKey(name: 'isPerChannel') bool? isPerChannel});
}

/// @nodoc
class _$AlgorithmPortCopyWithImpl<$Res, $Val extends AlgorithmPort>
    implements $AlgorithmPortCopyWith<$Res> {
  _$AlgorithmPortCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AlgorithmPort
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? name = null,
    Object? description = freezed,
    Object? busIdRef = freezed,
    Object? channelCountRef = freezed,
    Object? isPerChannel = freezed,
  }) {
    return _then(_value.copyWith(
      id: freezed == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String?,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      busIdRef: freezed == busIdRef
          ? _value.busIdRef
          : busIdRef // ignore: cast_nullable_to_non_nullable
              as String?,
      channelCountRef: freezed == channelCountRef
          ? _value.channelCountRef
          : channelCountRef // ignore: cast_nullable_to_non_nullable
              as String?,
      isPerChannel: freezed == isPerChannel
          ? _value.isPerChannel
          : isPerChannel // ignore: cast_nullable_to_non_nullable
              as bool?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$AlgorithmPortImplCopyWith<$Res>
    implements $AlgorithmPortCopyWith<$Res> {
  factory _$$AlgorithmPortImplCopyWith(
          _$AlgorithmPortImpl value, $Res Function(_$AlgorithmPortImpl) then) =
      __$$AlgorithmPortImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String? id,
      String name,
      String? description,
      @JsonKey(name: 'busIdRef') String? busIdRef,
      @JsonKey(name: 'channelCountRef') String? channelCountRef,
      @JsonKey(name: 'isPerChannel') bool? isPerChannel});
}

/// @nodoc
class __$$AlgorithmPortImplCopyWithImpl<$Res>
    extends _$AlgorithmPortCopyWithImpl<$Res, _$AlgorithmPortImpl>
    implements _$$AlgorithmPortImplCopyWith<$Res> {
  __$$AlgorithmPortImplCopyWithImpl(
      _$AlgorithmPortImpl _value, $Res Function(_$AlgorithmPortImpl) _then)
      : super(_value, _then);

  /// Create a copy of AlgorithmPort
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? name = null,
    Object? description = freezed,
    Object? busIdRef = freezed,
    Object? channelCountRef = freezed,
    Object? isPerChannel = freezed,
  }) {
    return _then(_$AlgorithmPortImpl(
      id: freezed == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String?,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      busIdRef: freezed == busIdRef
          ? _value.busIdRef
          : busIdRef // ignore: cast_nullable_to_non_nullable
              as String?,
      channelCountRef: freezed == channelCountRef
          ? _value.channelCountRef
          : channelCountRef // ignore: cast_nullable_to_non_nullable
              as String?,
      isPerChannel: freezed == isPerChannel
          ? _value.isPerChannel
          : isPerChannel // ignore: cast_nullable_to_non_nullable
              as bool?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$AlgorithmPortImpl implements _AlgorithmPort {
  const _$AlgorithmPortImpl(
      {this.id,
      required this.name,
      this.description,
      @JsonKey(name: 'busIdRef') this.busIdRef,
      @JsonKey(name: 'channelCountRef') this.channelCountRef,
      @JsonKey(name: 'isPerChannel') this.isPerChannel});

  factory _$AlgorithmPortImpl.fromJson(Map<String, dynamic> json) =>
      _$$AlgorithmPortImplFromJson(json);

  @override
  final String? id;
  @override
  final String name;
  @override
  final String? description;
  @override
  @JsonKey(name: 'busIdRef')
  final String? busIdRef;
  @override
  @JsonKey(name: 'channelCountRef')
  final String? channelCountRef;
  @override
  @JsonKey(name: 'isPerChannel')
  final bool? isPerChannel;

  @override
  String toString() {
    return 'AlgorithmPort(id: $id, name: $name, description: $description, busIdRef: $busIdRef, channelCountRef: $channelCountRef, isPerChannel: $isPerChannel)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AlgorithmPortImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.busIdRef, busIdRef) ||
                other.busIdRef == busIdRef) &&
            (identical(other.channelCountRef, channelCountRef) ||
                other.channelCountRef == channelCountRef) &&
            (identical(other.isPerChannel, isPerChannel) ||
                other.isPerChannel == isPerChannel));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, name, description, busIdRef,
      channelCountRef, isPerChannel);

  /// Create a copy of AlgorithmPort
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AlgorithmPortImplCopyWith<_$AlgorithmPortImpl> get copyWith =>
      __$$AlgorithmPortImplCopyWithImpl<_$AlgorithmPortImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AlgorithmPortImplToJson(
      this,
    );
  }
}

abstract class _AlgorithmPort implements AlgorithmPort {
  const factory _AlgorithmPort(
          {final String? id,
          required final String name,
          final String? description,
          @JsonKey(name: 'busIdRef') final String? busIdRef,
          @JsonKey(name: 'channelCountRef') final String? channelCountRef,
          @JsonKey(name: 'isPerChannel') final bool? isPerChannel}) =
      _$AlgorithmPortImpl;

  factory _AlgorithmPort.fromJson(Map<String, dynamic> json) =
      _$AlgorithmPortImpl.fromJson;

  @override
  String? get id;
  @override
  String get name;
  @override
  String? get description;
  @override
  @JsonKey(name: 'busIdRef')
  String? get busIdRef;
  @override
  @JsonKey(name: 'channelCountRef')
  String? get channelCountRef;
  @override
  @JsonKey(name: 'isPerChannel')
  bool? get isPerChannel;

  /// Create a copy of AlgorithmPort
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AlgorithmPortImplCopyWith<_$AlgorithmPortImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
