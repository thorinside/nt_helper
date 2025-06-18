// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'algorithm_parameter.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AlgorithmParameter {
  String get name;
  String?
      get unit; // Using dynamic for min/max/default as they can be int, double, or null
  dynamic get min;
  dynamic get max;
  dynamic get defaultValue;
  String?
      get scope; // e.g., "global", "per-channel", "per-trigger", "operator", "program", "mix", "routing", "vco", "gain", "filter", "animate"
  String? get description;
  @JsonKey(name: 'enumValues')
  List<String>? get values;
  String?
      get type; // e.g., "file", "folder", "toggle", "bus", "scaled", "enum", "trigger", "trigger/gate"
  @JsonKey(name: 'busIdRef')
  String? get busIdRef;
  @JsonKey(name: 'channelCountRef')
  String? get channelCountRef;
  @JsonKey(name: 'isPerChannel')
  bool? get isPerChannel;
  @JsonKey(name: 'isCommon')
  bool? get isCommon;
  int? get parameterNumber;

  /// Create a copy of AlgorithmParameter
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $AlgorithmParameterCopyWith<AlgorithmParameter> get copyWith =>
      _$AlgorithmParameterCopyWithImpl<AlgorithmParameter>(
          this as AlgorithmParameter, _$identity);

  /// Serializes this AlgorithmParameter to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is AlgorithmParameter &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.unit, unit) || other.unit == unit) &&
            const DeepCollectionEquality().equals(other.min, min) &&
            const DeepCollectionEquality().equals(other.max, max) &&
            const DeepCollectionEquality()
                .equals(other.defaultValue, defaultValue) &&
            (identical(other.scope, scope) || other.scope == scope) &&
            (identical(other.description, description) ||
                other.description == description) &&
            const DeepCollectionEquality().equals(other.values, values) &&
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
      const DeepCollectionEquality().hash(values),
      type,
      busIdRef,
      channelCountRef,
      isPerChannel,
      isCommon,
      parameterNumber);

  @override
  String toString() {
    return 'AlgorithmParameter(name: $name, unit: $unit, min: $min, max: $max, defaultValue: $defaultValue, scope: $scope, description: $description, values: $values, type: $type, busIdRef: $busIdRef, channelCountRef: $channelCountRef, isPerChannel: $isPerChannel, isCommon: $isCommon, parameterNumber: $parameterNumber)';
  }
}

/// @nodoc
abstract mixin class $AlgorithmParameterCopyWith<$Res> {
  factory $AlgorithmParameterCopyWith(
          AlgorithmParameter value, $Res Function(AlgorithmParameter) _then) =
      _$AlgorithmParameterCopyWithImpl;
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
class _$AlgorithmParameterCopyWithImpl<$Res>
    implements $AlgorithmParameterCopyWith<$Res> {
  _$AlgorithmParameterCopyWithImpl(this._self, this._then);

  final AlgorithmParameter _self;
  final $Res Function(AlgorithmParameter) _then;

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
    return _then(_self.copyWith(
      name: null == name
          ? _self.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      unit: freezed == unit
          ? _self.unit
          : unit // ignore: cast_nullable_to_non_nullable
              as String?,
      min: freezed == min
          ? _self.min
          : min // ignore: cast_nullable_to_non_nullable
              as dynamic,
      max: freezed == max
          ? _self.max
          : max // ignore: cast_nullable_to_non_nullable
              as dynamic,
      defaultValue: freezed == defaultValue
          ? _self.defaultValue
          : defaultValue // ignore: cast_nullable_to_non_nullable
              as dynamic,
      scope: freezed == scope
          ? _self.scope
          : scope // ignore: cast_nullable_to_non_nullable
              as String?,
      description: freezed == description
          ? _self.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      values: freezed == values
          ? _self.values
          : values // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      type: freezed == type
          ? _self.type
          : type // ignore: cast_nullable_to_non_nullable
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
      isCommon: freezed == isCommon
          ? _self.isCommon
          : isCommon // ignore: cast_nullable_to_non_nullable
              as bool?,
      parameterNumber: freezed == parameterNumber
          ? _self.parameterNumber
          : parameterNumber // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _AlgorithmParameter implements AlgorithmParameter {
  const _AlgorithmParameter(
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
  factory _AlgorithmParameter.fromJson(Map<String, dynamic> json) =>
      _$AlgorithmParameterFromJson(json);

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

  /// Create a copy of AlgorithmParameter
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$AlgorithmParameterCopyWith<_AlgorithmParameter> get copyWith =>
      __$AlgorithmParameterCopyWithImpl<_AlgorithmParameter>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$AlgorithmParameterToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _AlgorithmParameter &&
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

  @override
  String toString() {
    return 'AlgorithmParameter(name: $name, unit: $unit, min: $min, max: $max, defaultValue: $defaultValue, scope: $scope, description: $description, values: $values, type: $type, busIdRef: $busIdRef, channelCountRef: $channelCountRef, isPerChannel: $isPerChannel, isCommon: $isCommon, parameterNumber: $parameterNumber)';
  }
}

/// @nodoc
abstract mixin class _$AlgorithmParameterCopyWith<$Res>
    implements $AlgorithmParameterCopyWith<$Res> {
  factory _$AlgorithmParameterCopyWith(
          _AlgorithmParameter value, $Res Function(_AlgorithmParameter) _then) =
      __$AlgorithmParameterCopyWithImpl;
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
class __$AlgorithmParameterCopyWithImpl<$Res>
    implements _$AlgorithmParameterCopyWith<$Res> {
  __$AlgorithmParameterCopyWithImpl(this._self, this._then);

  final _AlgorithmParameter _self;
  final $Res Function(_AlgorithmParameter) _then;

  /// Create a copy of AlgorithmParameter
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
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
    return _then(_AlgorithmParameter(
      name: null == name
          ? _self.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      unit: freezed == unit
          ? _self.unit
          : unit // ignore: cast_nullable_to_non_nullable
              as String?,
      min: freezed == min
          ? _self.min
          : min // ignore: cast_nullable_to_non_nullable
              as dynamic,
      max: freezed == max
          ? _self.max
          : max // ignore: cast_nullable_to_non_nullable
              as dynamic,
      defaultValue: freezed == defaultValue
          ? _self.defaultValue
          : defaultValue // ignore: cast_nullable_to_non_nullable
              as dynamic,
      scope: freezed == scope
          ? _self.scope
          : scope // ignore: cast_nullable_to_non_nullable
              as String?,
      description: freezed == description
          ? _self.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      values: freezed == values
          ? _self._values
          : values // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      type: freezed == type
          ? _self.type
          : type // ignore: cast_nullable_to_non_nullable
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
      isCommon: freezed == isCommon
          ? _self.isCommon
          : isCommon // ignore: cast_nullable_to_non_nullable
              as bool?,
      parameterNumber: freezed == parameterNumber
          ? _self.parameterNumber
          : parameterNumber // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }
}

// dart format on
