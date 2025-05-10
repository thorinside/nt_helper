// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'algorithm_specification.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

AlgorithmSpecification _$AlgorithmSpecificationFromJson(
    Map<String, dynamic> json) {
  return _AlgorithmSpecification.fromJson(json);
}

/// @nodoc
mixin _$AlgorithmSpecification {
  String get name => throw _privateConstructorUsedError;
  String? get unit =>
      throw _privateConstructorUsedError; // Using dynamic for value fields as structure varies (min/max/default or just value)
  dynamic get value => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  dynamic get min => throw _privateConstructorUsedError; // For older format
  dynamic get max => throw _privateConstructorUsedError;

  /// Serializes this AlgorithmSpecification to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of AlgorithmSpecification
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AlgorithmSpecificationCopyWith<AlgorithmSpecification> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AlgorithmSpecificationCopyWith<$Res> {
  factory $AlgorithmSpecificationCopyWith(AlgorithmSpecification value,
          $Res Function(AlgorithmSpecification) then) =
      _$AlgorithmSpecificationCopyWithImpl<$Res, AlgorithmSpecification>;
  @useResult
  $Res call(
      {String name,
      String? unit,
      dynamic value,
      String? description,
      dynamic min,
      dynamic max});
}

/// @nodoc
class _$AlgorithmSpecificationCopyWithImpl<$Res,
        $Val extends AlgorithmSpecification>
    implements $AlgorithmSpecificationCopyWith<$Res> {
  _$AlgorithmSpecificationCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AlgorithmSpecification
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? unit = freezed,
    Object? value = freezed,
    Object? description = freezed,
    Object? min = freezed,
    Object? max = freezed,
  }) {
    return _then(_value.copyWith(
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      unit: freezed == unit
          ? _value.unit
          : unit // ignore: cast_nullable_to_non_nullable
              as String?,
      value: freezed == value
          ? _value.value
          : value // ignore: cast_nullable_to_non_nullable
              as dynamic,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      min: freezed == min
          ? _value.min
          : min // ignore: cast_nullable_to_non_nullable
              as dynamic,
      max: freezed == max
          ? _value.max
          : max // ignore: cast_nullable_to_non_nullable
              as dynamic,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$AlgorithmSpecificationImplCopyWith<$Res>
    implements $AlgorithmSpecificationCopyWith<$Res> {
  factory _$$AlgorithmSpecificationImplCopyWith(
          _$AlgorithmSpecificationImpl value,
          $Res Function(_$AlgorithmSpecificationImpl) then) =
      __$$AlgorithmSpecificationImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String name,
      String? unit,
      dynamic value,
      String? description,
      dynamic min,
      dynamic max});
}

/// @nodoc
class __$$AlgorithmSpecificationImplCopyWithImpl<$Res>
    extends _$AlgorithmSpecificationCopyWithImpl<$Res,
        _$AlgorithmSpecificationImpl>
    implements _$$AlgorithmSpecificationImplCopyWith<$Res> {
  __$$AlgorithmSpecificationImplCopyWithImpl(
      _$AlgorithmSpecificationImpl _value,
      $Res Function(_$AlgorithmSpecificationImpl) _then)
      : super(_value, _then);

  /// Create a copy of AlgorithmSpecification
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? unit = freezed,
    Object? value = freezed,
    Object? description = freezed,
    Object? min = freezed,
    Object? max = freezed,
  }) {
    return _then(_$AlgorithmSpecificationImpl(
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      unit: freezed == unit
          ? _value.unit
          : unit // ignore: cast_nullable_to_non_nullable
              as String?,
      value: freezed == value
          ? _value.value
          : value // ignore: cast_nullable_to_non_nullable
              as dynamic,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      min: freezed == min
          ? _value.min
          : min // ignore: cast_nullable_to_non_nullable
              as dynamic,
      max: freezed == max
          ? _value.max
          : max // ignore: cast_nullable_to_non_nullable
              as dynamic,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$AlgorithmSpecificationImpl implements _AlgorithmSpecification {
  const _$AlgorithmSpecificationImpl(
      {required this.name,
      this.unit,
      this.value,
      this.description,
      this.min,
      this.max});

  factory _$AlgorithmSpecificationImpl.fromJson(Map<String, dynamic> json) =>
      _$$AlgorithmSpecificationImplFromJson(json);

  @override
  final String name;
  @override
  final String? unit;
// Using dynamic for value fields as structure varies (min/max/default or just value)
  @override
  final dynamic value;
  @override
  final String? description;
  @override
  final dynamic min;
// For older format
  @override
  final dynamic max;

  @override
  String toString() {
    return 'AlgorithmSpecification(name: $name, unit: $unit, value: $value, description: $description, min: $min, max: $max)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AlgorithmSpecificationImpl &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.unit, unit) || other.unit == unit) &&
            const DeepCollectionEquality().equals(other.value, value) &&
            (identical(other.description, description) ||
                other.description == description) &&
            const DeepCollectionEquality().equals(other.min, min) &&
            const DeepCollectionEquality().equals(other.max, max));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      name,
      unit,
      const DeepCollectionEquality().hash(value),
      description,
      const DeepCollectionEquality().hash(min),
      const DeepCollectionEquality().hash(max));

  /// Create a copy of AlgorithmSpecification
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AlgorithmSpecificationImplCopyWith<_$AlgorithmSpecificationImpl>
      get copyWith => __$$AlgorithmSpecificationImplCopyWithImpl<
          _$AlgorithmSpecificationImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AlgorithmSpecificationImplToJson(
      this,
    );
  }
}

abstract class _AlgorithmSpecification implements AlgorithmSpecification {
  const factory _AlgorithmSpecification(
      {required final String name,
      final String? unit,
      final dynamic value,
      final String? description,
      final dynamic min,
      final dynamic max}) = _$AlgorithmSpecificationImpl;

  factory _AlgorithmSpecification.fromJson(Map<String, dynamic> json) =
      _$AlgorithmSpecificationImpl.fromJson;

  @override
  String get name;
  @override
  String?
      get unit; // Using dynamic for value fields as structure varies (min/max/default or just value)
  @override
  dynamic get value;
  @override
  String? get description;
  @override
  dynamic get min; // For older format
  @override
  dynamic get max;

  /// Create a copy of AlgorithmSpecification
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AlgorithmSpecificationImplCopyWith<_$AlgorithmSpecificationImpl>
      get copyWith => throw _privateConstructorUsedError;
}
