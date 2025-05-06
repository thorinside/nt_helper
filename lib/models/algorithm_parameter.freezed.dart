// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'algorithm_parameter.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

AlgorithmParameter _$AlgorithmParameterFromJson(Map<String, dynamic> json) {
  return _AlgorithmParameter.fromJson(json);
}

/// @nodoc
mixin _$AlgorithmParameter {
  String get name => throw _privateConstructorUsedError;
  String? get unit =>
      throw _privateConstructorUsedError; // Using dynamic for min/max/default as they can be int, double, or null
  dynamic get min => throw _privateConstructorUsedError;
  dynamic get max => throw _privateConstructorUsedError;
  dynamic get defaultValue => throw _privateConstructorUsedError;
  String? get scope =>
      throw _privateConstructorUsedError; // e.g., "global", "per-channel", "per-trigger", "operator", "program", "mix", "routing", "vco", "gain", "filter", "animate"
  String? get description => throw _privateConstructorUsedError;
  @JsonKey(name: 'enumValues')
  List<String>? get values => throw _privateConstructorUsedError;
  String? get type =>
      throw _privateConstructorUsedError; // e.g., "file", "folder", "toggle", "bus", "scaled", "enum", "trigger", "trigger/gate"
  @JsonKey(name: 'busIdRef')
  String? get busIdRef => throw _privateConstructorUsedError;
  @JsonKey(name: 'channelCountRef')
  String? get channelCountRef => throw _privateConstructorUsedError;
  @JsonKey(name: 'isPerChannel')
  bool? get isPerChannel => throw _privateConstructorUsedError;
  @JsonKey(name: 'isCommon')
  bool? get isCommon => throw _privateConstructorUsedError;
  int? get parameterNumber => throw _privateConstructorUsedError;

  /// Serializes this AlgorithmParameter to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of AlgorithmParameter
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AlgorithmParameterCopyWith<AlgorithmParameter> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AlgorithmParameterCopyWith<$Res> {
  factory $AlgorithmParameterCopyWith(
          AlgorithmParameter value, $Res Function(AlgorithmParameter) then) =
      _$AlgorithmParameterCopyWithImpl<$Res, AlgorithmParameter>;
  @useResult
  $Res call(
      {String name,
      String? unit,
      dynamic min,
      dynamic max,
      dynamic defaultValue,
      String? scope,
      String? description,
      @JsonKey(name: 'enumValues') List<String>? values,
      String? type,
      @JsonKey(name: 'busIdRef') String? busIdRef,
      @JsonKey(name: 'channelCountRef') String? channelCountRef,
      @JsonKey(name: 'isPerChannel') bool? isPerChannel,
      @JsonKey(name: 'isCommon') bool? isCommon,
      int? parameterNumber});
}

/// @nodoc
class _$AlgorithmParameterCopyWithImpl<$Res, $Val extends AlgorithmParameter>
    implements $AlgorithmParameterCopyWith<$Res> {
  _$AlgorithmParameterCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AlgorithmParameter
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? unit = freezed,
    Object? min = freezed,
    Object? max = freezed,
    Object? defaultValue = freezed,
    Object? scope = freezed,
    Object? description = freezed,
    Object? values = freezed,
    Object? type = freezed,
    Object? busIdRef = freezed,
    Object? channelCountRef = freezed,
    Object? isPerChannel = freezed,
    Object? isCommon = freezed,
    Object? parameterNumber = freezed,
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
      min: freezed == min
          ? _value.min
          : min // ignore: cast_nullable_to_non_nullable
              as dynamic,
      max: freezed == max
          ? _value.max
          : max // ignore: cast_nullable_to_non_nullable
              as dynamic,
      defaultValue: freezed == defaultValue
          ? _value.defaultValue
          : defaultValue // ignore: cast_nullable_to_non_nullable
              as dynamic,
      scope: freezed == scope
          ? _value.scope
          : scope // ignore: cast_nullable_to_non_nullable
              as String?,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      values: freezed == values
          ? _value.values
          : values // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      type: freezed == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
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
      isCommon: freezed == isCommon
          ? _value.isCommon
          : isCommon // ignore: cast_nullable_to_non_nullable
              as bool?,
      parameterNumber: freezed == parameterNumber
          ? _value.parameterNumber
          : parameterNumber // ignore: cast_nullable_to_non_nullable
              as int?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$AlgorithmParameterImplCopyWith<$Res>
    implements $AlgorithmParameterCopyWith<$Res> {
  factory _$$AlgorithmParameterImplCopyWith(_$AlgorithmParameterImpl value,
          $Res Function(_$AlgorithmParameterImpl) then) =
      __$$AlgorithmParameterImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String name,
      String? unit,
      dynamic min,
      dynamic max,
      dynamic defaultValue,
      String? scope,
      String? description,
      @JsonKey(name: 'enumValues') List<String>? values,
      String? type,
      @JsonKey(name: 'busIdRef') String? busIdRef,
      @JsonKey(name: 'channelCountRef') String? channelCountRef,
      @JsonKey(name: 'isPerChannel') bool? isPerChannel,
      @JsonKey(name: 'isCommon') bool? isCommon,
      int? parameterNumber});
}

/// @nodoc
class __$$AlgorithmParameterImplCopyWithImpl<$Res>
    extends _$AlgorithmParameterCopyWithImpl<$Res, _$AlgorithmParameterImpl>
    implements _$$AlgorithmParameterImplCopyWith<$Res> {
  __$$AlgorithmParameterImplCopyWithImpl(_$AlgorithmParameterImpl _value,
      $Res Function(_$AlgorithmParameterImpl) _then)
      : super(_value, _then);

  /// Create a copy of AlgorithmParameter
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? unit = freezed,
    Object? min = freezed,
    Object? max = freezed,
    Object? defaultValue = freezed,
    Object? scope = freezed,
    Object? description = freezed,
    Object? values = freezed,
    Object? type = freezed,
    Object? busIdRef = freezed,
    Object? channelCountRef = freezed,
    Object? isPerChannel = freezed,
    Object? isCommon = freezed,
    Object? parameterNumber = freezed,
  }) {
    return _then(_$AlgorithmParameterImpl(
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      unit: freezed == unit
          ? _value.unit
          : unit // ignore: cast_nullable_to_non_nullable
              as String?,
      min: freezed == min
          ? _value.min
          : min // ignore: cast_nullable_to_non_nullable
              as dynamic,
      max: freezed == max
          ? _value.max
          : max // ignore: cast_nullable_to_non_nullable
              as dynamic,
      defaultValue: freezed == defaultValue
          ? _value.defaultValue
          : defaultValue // ignore: cast_nullable_to_non_nullable
              as dynamic,
      scope: freezed == scope
          ? _value.scope
          : scope // ignore: cast_nullable_to_non_nullable
              as String?,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      values: freezed == values
          ? _value._values
          : values // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      type: freezed == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
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
      isCommon: freezed == isCommon
          ? _value.isCommon
          : isCommon // ignore: cast_nullable_to_non_nullable
              as bool?,
      parameterNumber: freezed == parameterNumber
          ? _value.parameterNumber
          : parameterNumber // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$AlgorithmParameterImpl implements _AlgorithmParameter {
  const _$AlgorithmParameterImpl(
      {required this.name,
      this.unit,
      this.min,
      this.max,
      this.defaultValue,
      this.scope,
      this.description,
      @JsonKey(name: 'enumValues') final List<String>? values,
      this.type,
      @JsonKey(name: 'busIdRef') this.busIdRef,
      @JsonKey(name: 'channelCountRef') this.channelCountRef,
      @JsonKey(name: 'isPerChannel') this.isPerChannel,
      @JsonKey(name: 'isCommon') this.isCommon,
      this.parameterNumber})
      : _values = values;

  factory _$AlgorithmParameterImpl.fromJson(Map<String, dynamic> json) =>
      _$$AlgorithmParameterImplFromJson(json);

  @override
  final String name;
  @override
  final String? unit;
// Using dynamic for min/max/default as they can be int, double, or null
  @override
  final dynamic min;
  @override
  final dynamic max;
  @override
  final dynamic defaultValue;
  @override
  final String? scope;
// e.g., "global", "per-channel", "per-trigger", "operator", "program", "mix", "routing", "vco", "gain", "filter", "animate"
  @override
  final String? description;
  final List<String>? _values;
  @override
  @JsonKey(name: 'enumValues')
  List<String>? get values {
    final value = _values;
    if (value == null) return null;
    if (_values is EqualUnmodifiableListView) return _values;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  final String? type;
// e.g., "file", "folder", "toggle", "bus", "scaled", "enum", "trigger", "trigger/gate"
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
  @JsonKey(name: 'isCommon')
  final bool? isCommon;
  @override
  final int? parameterNumber;

  @override
  String toString() {
    return 'AlgorithmParameter(name: $name, unit: $unit, min: $min, max: $max, defaultValue: $defaultValue, scope: $scope, description: $description, values: $values, type: $type, busIdRef: $busIdRef, channelCountRef: $channelCountRef, isPerChannel: $isPerChannel, isCommon: $isCommon, parameterNumber: $parameterNumber)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AlgorithmParameterImpl &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.unit, unit) || other.unit == unit) &&
            const DeepCollectionEquality().equals(other.min, min) &&
            const DeepCollectionEquality().equals(other.max, max) &&
            const DeepCollectionEquality()
                .equals(other.defaultValue, defaultValue) &&
            (identical(other.scope, scope) || other.scope == scope) &&
            (identical(other.description, description) ||
                other.description == description) &&
            const DeepCollectionEquality().equals(other._values, _values) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.busIdRef, busIdRef) ||
                other.busIdRef == busIdRef) &&
            (identical(other.channelCountRef, channelCountRef) ||
                other.channelCountRef == channelCountRef) &&
            (identical(other.isPerChannel, isPerChannel) ||
                other.isPerChannel == isPerChannel) &&
            (identical(other.isCommon, isCommon) ||
                other.isCommon == isCommon) &&
            (identical(other.parameterNumber, parameterNumber) ||
                other.parameterNumber == parameterNumber));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      name,
      unit,
      const DeepCollectionEquality().hash(min),
      const DeepCollectionEquality().hash(max),
      const DeepCollectionEquality().hash(defaultValue),
      scope,
      description,
      const DeepCollectionEquality().hash(_values),
      type,
      busIdRef,
      channelCountRef,
      isPerChannel,
      isCommon,
      parameterNumber);

  /// Create a copy of AlgorithmParameter
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AlgorithmParameterImplCopyWith<_$AlgorithmParameterImpl> get copyWith =>
      __$$AlgorithmParameterImplCopyWithImpl<_$AlgorithmParameterImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AlgorithmParameterImplToJson(
      this,
    );
  }
}

abstract class _AlgorithmParameter implements AlgorithmParameter {
  const factory _AlgorithmParameter(
      {required final String name,
      final String? unit,
      final dynamic min,
      final dynamic max,
      final dynamic defaultValue,
      final String? scope,
      final String? description,
      @JsonKey(name: 'enumValues') final List<String>? values,
      final String? type,
      @JsonKey(name: 'busIdRef') final String? busIdRef,
      @JsonKey(name: 'channelCountRef') final String? channelCountRef,
      @JsonKey(name: 'isPerChannel') final bool? isPerChannel,
      @JsonKey(name: 'isCommon') final bool? isCommon,
      final int? parameterNumber}) = _$AlgorithmParameterImpl;

  factory _AlgorithmParameter.fromJson(Map<String, dynamic> json) =
      _$AlgorithmParameterImpl.fromJson;

  @override
  String get name;
  @override
  String?
      get unit; // Using dynamic for min/max/default as they can be int, double, or null
  @override
  dynamic get min;
  @override
  dynamic get max;
  @override
  dynamic get defaultValue;
  @override
  String?
      get scope; // e.g., "global", "per-channel", "per-trigger", "operator", "program", "mix", "routing", "vco", "gain", "filter", "animate"
  @override
  String? get description;
  @override
  @JsonKey(name: 'enumValues')
  List<String>? get values;
  @override
  String?
      get type; // e.g., "file", "folder", "toggle", "bus", "scaled", "enum", "trigger", "trigger/gate"
  @override
  @JsonKey(name: 'busIdRef')
  String? get busIdRef;
  @override
  @JsonKey(name: 'channelCountRef')
  String? get channelCountRef;
  @override
  @JsonKey(name: 'isPerChannel')
  bool? get isPerChannel;
  @override
  @JsonKey(name: 'isCommon')
  bool? get isCommon;
  @override
  int? get parameterNumber;

  /// Create a copy of AlgorithmParameter
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AlgorithmParameterImplCopyWith<_$AlgorithmParameterImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
