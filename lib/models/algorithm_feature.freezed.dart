// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'algorithm_feature.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

AlgorithmFeature _$AlgorithmFeatureFromJson(Map<String, dynamic> json) {
  return _AlgorithmFeature.fromJson(json);
}

/// @nodoc
mixin _$AlgorithmFeature {
  String get guid => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  List<AlgorithmParameter> get parameters => throw _privateConstructorUsedError;

  /// Serializes this AlgorithmFeature to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of AlgorithmFeature
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AlgorithmFeatureCopyWith<AlgorithmFeature> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AlgorithmFeatureCopyWith<$Res> {
  factory $AlgorithmFeatureCopyWith(
          AlgorithmFeature value, $Res Function(AlgorithmFeature) then) =
      _$AlgorithmFeatureCopyWithImpl<$Res, AlgorithmFeature>;
  @useResult
  $Res call(
      {String guid,
      String name,
      String? description,
      List<AlgorithmParameter> parameters});
}

/// @nodoc
class _$AlgorithmFeatureCopyWithImpl<$Res, $Val extends AlgorithmFeature>
    implements $AlgorithmFeatureCopyWith<$Res> {
  _$AlgorithmFeatureCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

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
    return _then(_value.copyWith(
      guid: null == guid
          ? _value.guid
          : guid // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      parameters: null == parameters
          ? _value.parameters
          : parameters // ignore: cast_nullable_to_non_nullable
              as List<AlgorithmParameter>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$AlgorithmFeatureImplCopyWith<$Res>
    implements $AlgorithmFeatureCopyWith<$Res> {
  factory _$$AlgorithmFeatureImplCopyWith(_$AlgorithmFeatureImpl value,
          $Res Function(_$AlgorithmFeatureImpl) then) =
      __$$AlgorithmFeatureImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String guid,
      String name,
      String? description,
      List<AlgorithmParameter> parameters});
}

/// @nodoc
class __$$AlgorithmFeatureImplCopyWithImpl<$Res>
    extends _$AlgorithmFeatureCopyWithImpl<$Res, _$AlgorithmFeatureImpl>
    implements _$$AlgorithmFeatureImplCopyWith<$Res> {
  __$$AlgorithmFeatureImplCopyWithImpl(_$AlgorithmFeatureImpl _value,
      $Res Function(_$AlgorithmFeatureImpl) _then)
      : super(_value, _then);

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
    return _then(_$AlgorithmFeatureImpl(
      guid: null == guid
          ? _value.guid
          : guid // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      parameters: null == parameters
          ? _value._parameters
          : parameters // ignore: cast_nullable_to_non_nullable
              as List<AlgorithmParameter>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$AlgorithmFeatureImpl implements _AlgorithmFeature {
  const _$AlgorithmFeatureImpl(
      {required this.guid,
      required this.name,
      this.description,
      final List<AlgorithmParameter> parameters = const []})
      : _parameters = parameters;

  factory _$AlgorithmFeatureImpl.fromJson(Map<String, dynamic> json) =>
      _$$AlgorithmFeatureImplFromJson(json);

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

  @override
  String toString() {
    return 'AlgorithmFeature(guid: $guid, name: $name, description: $description, parameters: $parameters)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AlgorithmFeatureImpl &&
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

  /// Create a copy of AlgorithmFeature
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AlgorithmFeatureImplCopyWith<_$AlgorithmFeatureImpl> get copyWith =>
      __$$AlgorithmFeatureImplCopyWithImpl<_$AlgorithmFeatureImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AlgorithmFeatureImplToJson(
      this,
    );
  }
}

abstract class _AlgorithmFeature implements AlgorithmFeature {
  const factory _AlgorithmFeature(
      {required final String guid,
      required final String name,
      final String? description,
      final List<AlgorithmParameter> parameters}) = _$AlgorithmFeatureImpl;

  factory _AlgorithmFeature.fromJson(Map<String, dynamic> json) =
      _$AlgorithmFeatureImpl.fromJson;

  @override
  String get guid;
  @override
  String get name;
  @override
  String? get description;
  @override
  List<AlgorithmParameter> get parameters;

  /// Create a copy of AlgorithmFeature
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AlgorithmFeatureImplCopyWith<_$AlgorithmFeatureImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
