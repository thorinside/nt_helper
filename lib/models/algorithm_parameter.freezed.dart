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
  List<String>? get enumValues;
  String?
      get type; // e.g., "file", "folder", "toggle", "bus", "scaled", "enum", "trigger", "trigger/gate"
  String? get busIdRef;
  String? get channelCountRef;
  bool? get isPerChannel;
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
            const DeepCollectionEquality()
                .equals(other.enumValues, enumValues) &&
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
      const DeepCollectionEquality().hash(enumValues),
      type,
      busIdRef,
      channelCountRef,
      isPerChannel,
      isCommon,
      parameterNumber);

  @override
  String toString() {
    return 'AlgorithmParameter(name: $name, unit: $unit, min: $min, max: $max, defaultValue: $defaultValue, scope: $scope, description: $description, enumValues: $enumValues, type: $type, busIdRef: $busIdRef, channelCountRef: $channelCountRef, isPerChannel: $isPerChannel, isCommon: $isCommon, parameterNumber: $parameterNumber)';
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
      List<String>? enumValues,
      String? type,
      String? busIdRef,
      String? channelCountRef,
      bool? isPerChannel,
      bool? isCommon,
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
    Object? enumValues = freezed,
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
      enumValues: freezed == enumValues
          ? _self.enumValues
          : enumValues // ignore: cast_nullable_to_non_nullable
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
      final List<String>? enumValues,
      this.type,
      this.busIdRef,
      this.channelCountRef,
      this.isPerChannel,
      this.isCommon,
      this.parameterNumber})
      : _enumValues = enumValues;
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
  final List<String>? _enumValues;
  @override
  List<String>? get enumValues {
    final value = _enumValues;
    if (value == null) return null;
    if (_enumValues is EqualUnmodifiableListView) return _enumValues;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  final String? type;
// e.g., "file", "folder", "toggle", "bus", "scaled", "enum", "trigger", "trigger/gate"
  @override
  final String? busIdRef;
  @override
  final String? channelCountRef;
  @override
  final bool? isPerChannel;
  @override
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
            const DeepCollectionEquality()
                .equals(other._enumValues, _enumValues) &&
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
      const DeepCollectionEquality().hash(_enumValues),
      type,
      busIdRef,
      channelCountRef,
      isPerChannel,
      isCommon,
      parameterNumber);

  @override
  String toString() {
    return 'AlgorithmParameter(name: $name, unit: $unit, min: $min, max: $max, defaultValue: $defaultValue, scope: $scope, description: $description, enumValues: $enumValues, type: $type, busIdRef: $busIdRef, channelCountRef: $channelCountRef, isPerChannel: $isPerChannel, isCommon: $isCommon, parameterNumber: $parameterNumber)';
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
      List<String>? enumValues,
      String? type,
      String? busIdRef,
      String? channelCountRef,
      bool? isPerChannel,
      bool? isCommon,
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
    Object? enumValues = freezed,
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
      enumValues: freezed == enumValues
          ? _self._enumValues
          : enumValues // ignore: cast_nullable_to_non_nullable
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
