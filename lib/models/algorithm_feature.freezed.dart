// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'algorithm_feature.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AlgorithmFeature {
  String get guid;
  String get name;
  String? get description;
  List<AlgorithmParameter> get parameters;

  /// Create a copy of AlgorithmFeature
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $AlgorithmFeatureCopyWith<AlgorithmFeature> get copyWith =>
      _$AlgorithmFeatureCopyWithImpl<AlgorithmFeature>(
          this as AlgorithmFeature, _$identity);

  /// Serializes this AlgorithmFeature to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is AlgorithmFeature &&
            (identical(other.guid, guid) || other.guid == guid) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.description, description) ||
                other.description == description) &&
            const DeepCollectionEquality()
                .equals(other.parameters, parameters));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, guid, name, description,
      const DeepCollectionEquality().hash(parameters));

  @override
  String toString() {
    return 'AlgorithmFeature(guid: $guid, name: $name, description: $description, parameters: $parameters)';
  }
}

/// @nodoc
abstract mixin class $AlgorithmFeatureCopyWith<$Res> {
  factory $AlgorithmFeatureCopyWith(
          AlgorithmFeature value, $Res Function(AlgorithmFeature) _then) =
      _$AlgorithmFeatureCopyWithImpl;
  @useResult
  $Res call(
      {String guid,
      String name,
      String? description,
      List<AlgorithmParameter> parameters});
}

/// @nodoc
class _$AlgorithmFeatureCopyWithImpl<$Res>
    implements $AlgorithmFeatureCopyWith<$Res> {
  _$AlgorithmFeatureCopyWithImpl(this._self, this._then);

  final AlgorithmFeature _self;
  final $Res Function(AlgorithmFeature) _then;

  /// Create a copy of AlgorithmFeature
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? guid = null,
    Object? name = null,
    Object? description = freezed,
    Object? parameters = null,
  }) {
    return _then(_self.copyWith(
      guid: null == guid
          ? _self.guid
          : guid // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _self.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      description: freezed == description
          ? _self.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      parameters: null == parameters
          ? _self.parameters
          : parameters // ignore: cast_nullable_to_non_nullable
              as List<AlgorithmParameter>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _AlgorithmFeature implements AlgorithmFeature {
  const _AlgorithmFeature(
      {required this.guid,
      required this.name,
      this.description,
      final List<AlgorithmParameter> parameters = const []})
      : _parameters = parameters;
  factory _AlgorithmFeature.fromJson(Map<String, dynamic> json) =>
      _$AlgorithmFeatureFromJson(json);

  @override
  final String guid;
  @override
  final String name;
  @override
  final String? description;
  final List<AlgorithmParameter> _parameters;
  @override
  @JsonKey()
  List<AlgorithmParameter> get parameters {
    if (_parameters is EqualUnmodifiableListView) return _parameters;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_parameters);
  }

  /// Create a copy of AlgorithmFeature
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$AlgorithmFeatureCopyWith<_AlgorithmFeature> get copyWith =>
      __$AlgorithmFeatureCopyWithImpl<_AlgorithmFeature>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$AlgorithmFeatureToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _AlgorithmFeature &&
            (identical(other.guid, guid) || other.guid == guid) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.description, description) ||
                other.description == description) &&
            const DeepCollectionEquality()
                .equals(other._parameters, _parameters));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, guid, name, description,
      const DeepCollectionEquality().hash(_parameters));

  @override
  String toString() {
    return 'AlgorithmFeature(guid: $guid, name: $name, description: $description, parameters: $parameters)';
  }
}

/// @nodoc
abstract mixin class _$AlgorithmFeatureCopyWith<$Res>
    implements $AlgorithmFeatureCopyWith<$Res> {
  factory _$AlgorithmFeatureCopyWith(
          _AlgorithmFeature value, $Res Function(_AlgorithmFeature) _then) =
      __$AlgorithmFeatureCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String guid,
      String name,
      String? description,
      List<AlgorithmParameter> parameters});
}

/// @nodoc
class __$AlgorithmFeatureCopyWithImpl<$Res>
    implements _$AlgorithmFeatureCopyWith<$Res> {
  __$AlgorithmFeatureCopyWithImpl(this._self, this._then);

  final _AlgorithmFeature _self;
  final $Res Function(_AlgorithmFeature) _then;

  /// Create a copy of AlgorithmFeature
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? guid = null,
    Object? name = null,
    Object? description = freezed,
    Object? parameters = null,
  }) {
    return _then(_AlgorithmFeature(
      guid: null == guid
          ? _self.guid
          : guid // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _self.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      description: freezed == description
          ? _self.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      parameters: null == parameters
          ? _self._parameters
          : parameters // ignore: cast_nullable_to_non_nullable
              as List<AlgorithmParameter>,
    ));
  }
}

// dart format on
