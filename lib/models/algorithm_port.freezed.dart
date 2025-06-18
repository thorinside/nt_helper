// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'algorithm_port.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AlgorithmPort {
  String? get id;
  String get name;
  String? get description;
  @JsonKey(name: 'busIdRef')
  String? get busIdRef;
  @JsonKey(name: 'channelCountRef')
  String? get channelCountRef;
  @JsonKey(name: 'isPerChannel')
  bool? get isPerChannel;

  /// Create a copy of AlgorithmPort
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $AlgorithmPortCopyWith<AlgorithmPort> get copyWith =>
      _$AlgorithmPortCopyWithImpl<AlgorithmPort>(
          this as AlgorithmPort, _$identity);

  /// Serializes this AlgorithmPort to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is AlgorithmPort &&
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

  @override
  String toString() {
    return 'AlgorithmPort(id: $id, name: $name, description: $description, busIdRef: $busIdRef, channelCountRef: $channelCountRef, isPerChannel: $isPerChannel)';
  }
}

/// @nodoc
abstract mixin class $AlgorithmPortCopyWith<$Res> {
  factory $AlgorithmPortCopyWith(
          AlgorithmPort value, $Res Function(AlgorithmPort) _then) =
      _$AlgorithmPortCopyWithImpl;
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
class _$AlgorithmPortCopyWithImpl<$Res>
    implements $AlgorithmPortCopyWith<$Res> {
  _$AlgorithmPortCopyWithImpl(this._self, this._then);

  final AlgorithmPort _self;
  final $Res Function(AlgorithmPort) _then;

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
    return _then(_self.copyWith(
      id: freezed == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String?,
      name: null == name
          ? _self.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      description: freezed == description
          ? _self.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      busIdRef: freezed == busIdRef
          ? _self.busIdRef
          : busIdRef // ignore: cast_nullable_to_non_nullable
              as String?,
      channelCountRef: freezed == channelCountRef
          ? _self.channelCountRef
          : channelCountRef // ignore: cast_nullable_to_non_nullable
              as String?,
      isPerChannel: freezed == isPerChannel
          ? _self.isPerChannel
          : isPerChannel // ignore: cast_nullable_to_non_nullable
              as bool?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _AlgorithmPort implements AlgorithmPort {
  const _AlgorithmPort(
      {this.id,
      required this.name,
      this.description,
      @JsonKey(name: 'busIdRef') this.busIdRef,
      @JsonKey(name: 'channelCountRef') this.channelCountRef,
      @JsonKey(name: 'isPerChannel') this.isPerChannel});
  factory _AlgorithmPort.fromJson(Map<String, dynamic> json) =>
      _$AlgorithmPortFromJson(json);

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

  /// Create a copy of AlgorithmPort
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$AlgorithmPortCopyWith<_AlgorithmPort> get copyWith =>
      __$AlgorithmPortCopyWithImpl<_AlgorithmPort>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$AlgorithmPortToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _AlgorithmPort &&
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

  @override
  String toString() {
    return 'AlgorithmPort(id: $id, name: $name, description: $description, busIdRef: $busIdRef, channelCountRef: $channelCountRef, isPerChannel: $isPerChannel)';
  }
}

/// @nodoc
abstract mixin class _$AlgorithmPortCopyWith<$Res>
    implements $AlgorithmPortCopyWith<$Res> {
  factory _$AlgorithmPortCopyWith(
          _AlgorithmPort value, $Res Function(_AlgorithmPort) _then) =
      __$AlgorithmPortCopyWithImpl;
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
class __$AlgorithmPortCopyWithImpl<$Res>
    implements _$AlgorithmPortCopyWith<$Res> {
  __$AlgorithmPortCopyWithImpl(this._self, this._then);

  final _AlgorithmPort _self;
  final $Res Function(_AlgorithmPort) _then;

  /// Create a copy of AlgorithmPort
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = freezed,
    Object? name = null,
    Object? description = freezed,
    Object? busIdRef = freezed,
    Object? channelCountRef = freezed,
    Object? isPerChannel = freezed,
  }) {
    return _then(_AlgorithmPort(
      id: freezed == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String?,
      name: null == name
          ? _self.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      description: freezed == description
          ? _self.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      busIdRef: freezed == busIdRef
          ? _self.busIdRef
          : busIdRef // ignore: cast_nullable_to_non_nullable
              as String?,
      channelCountRef: freezed == channelCountRef
          ? _self.channelCountRef
          : channelCountRef // ignore: cast_nullable_to_non_nullable
              as String?,
      isPerChannel: freezed == isPerChannel
          ? _self.isPerChannel
          : isPerChannel // ignore: cast_nullable_to_non_nullable
              as bool?,
    ));
  }
}

// dart format on
