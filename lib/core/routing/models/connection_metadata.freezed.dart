// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'connection_metadata.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ConnectionMetadata {

/// Classification of this connection
 ConnectionClass get connectionClass;/// Bus number used for this connection (1-28, or 0 for direct)
 int get busNumber;/// Type of signal flowing through this connection
 SignalType get signalType;/// Source algorithm ID (for algorithm connections)
 String? get sourceAlgorithmId;/// Target algorithm ID (for algorithm connections)
 String? get targetAlgorithmId;/// Source parameter number (for algorithm connections)
 int? get sourceParameterNumber;/// Target parameter number (for algorithm connections)
 int? get targetParameterNumber;/// Whether this creates a backward edge in the execution graph
 bool? get isBackwardEdge;/// Whether this connection is valid
 bool? get isValid;
/// Create a copy of ConnectionMetadata
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ConnectionMetadataCopyWith<ConnectionMetadata> get copyWith => _$ConnectionMetadataCopyWithImpl<ConnectionMetadata>(this as ConnectionMetadata, _$identity);

  /// Serializes this ConnectionMetadata to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ConnectionMetadata&&(identical(other.connectionClass, connectionClass) || other.connectionClass == connectionClass)&&(identical(other.busNumber, busNumber) || other.busNumber == busNumber)&&(identical(other.signalType, signalType) || other.signalType == signalType)&&(identical(other.sourceAlgorithmId, sourceAlgorithmId) || other.sourceAlgorithmId == sourceAlgorithmId)&&(identical(other.targetAlgorithmId, targetAlgorithmId) || other.targetAlgorithmId == targetAlgorithmId)&&(identical(other.sourceParameterNumber, sourceParameterNumber) || other.sourceParameterNumber == sourceParameterNumber)&&(identical(other.targetParameterNumber, targetParameterNumber) || other.targetParameterNumber == targetParameterNumber)&&(identical(other.isBackwardEdge, isBackwardEdge) || other.isBackwardEdge == isBackwardEdge)&&(identical(other.isValid, isValid) || other.isValid == isValid));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,connectionClass,busNumber,signalType,sourceAlgorithmId,targetAlgorithmId,sourceParameterNumber,targetParameterNumber,isBackwardEdge,isValid);

@override
String toString() {
  return 'ConnectionMetadata(connectionClass: $connectionClass, busNumber: $busNumber, signalType: $signalType, sourceAlgorithmId: $sourceAlgorithmId, targetAlgorithmId: $targetAlgorithmId, sourceParameterNumber: $sourceParameterNumber, targetParameterNumber: $targetParameterNumber, isBackwardEdge: $isBackwardEdge, isValid: $isValid)';
}


}

/// @nodoc
abstract mixin class $ConnectionMetadataCopyWith<$Res>  {
  factory $ConnectionMetadataCopyWith(ConnectionMetadata value, $Res Function(ConnectionMetadata) _then) = _$ConnectionMetadataCopyWithImpl;
@useResult
$Res call({
 ConnectionClass connectionClass, int busNumber, SignalType signalType, String? sourceAlgorithmId, String? targetAlgorithmId, int? sourceParameterNumber, int? targetParameterNumber, bool? isBackwardEdge, bool? isValid
});




}
/// @nodoc
class _$ConnectionMetadataCopyWithImpl<$Res>
    implements $ConnectionMetadataCopyWith<$Res> {
  _$ConnectionMetadataCopyWithImpl(this._self, this._then);

  final ConnectionMetadata _self;
  final $Res Function(ConnectionMetadata) _then;

/// Create a copy of ConnectionMetadata
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? connectionClass = null,Object? busNumber = null,Object? signalType = null,Object? sourceAlgorithmId = freezed,Object? targetAlgorithmId = freezed,Object? sourceParameterNumber = freezed,Object? targetParameterNumber = freezed,Object? isBackwardEdge = freezed,Object? isValid = freezed,}) {
  return _then(_self.copyWith(
connectionClass: null == connectionClass ? _self.connectionClass : connectionClass // ignore: cast_nullable_to_non_nullable
as ConnectionClass,busNumber: null == busNumber ? _self.busNumber : busNumber // ignore: cast_nullable_to_non_nullable
as int,signalType: null == signalType ? _self.signalType : signalType // ignore: cast_nullable_to_non_nullable
as SignalType,sourceAlgorithmId: freezed == sourceAlgorithmId ? _self.sourceAlgorithmId : sourceAlgorithmId // ignore: cast_nullable_to_non_nullable
as String?,targetAlgorithmId: freezed == targetAlgorithmId ? _self.targetAlgorithmId : targetAlgorithmId // ignore: cast_nullable_to_non_nullable
as String?,sourceParameterNumber: freezed == sourceParameterNumber ? _self.sourceParameterNumber : sourceParameterNumber // ignore: cast_nullable_to_non_nullable
as int?,targetParameterNumber: freezed == targetParameterNumber ? _self.targetParameterNumber : targetParameterNumber // ignore: cast_nullable_to_non_nullable
as int?,isBackwardEdge: freezed == isBackwardEdge ? _self.isBackwardEdge : isBackwardEdge // ignore: cast_nullable_to_non_nullable
as bool?,isValid: freezed == isValid ? _self.isValid : isValid // ignore: cast_nullable_to_non_nullable
as bool?,
  ));
}

}


/// Adds pattern-matching-related methods to [ConnectionMetadata].
extension ConnectionMetadataPatterns on ConnectionMetadata {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ConnectionMetadata value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ConnectionMetadata() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ConnectionMetadata value)  $default,){
final _that = this;
switch (_that) {
case _ConnectionMetadata():
return $default(_that);}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ConnectionMetadata value)?  $default,){
final _that = this;
switch (_that) {
case _ConnectionMetadata() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( ConnectionClass connectionClass,  int busNumber,  SignalType signalType,  String? sourceAlgorithmId,  String? targetAlgorithmId,  int? sourceParameterNumber,  int? targetParameterNumber,  bool? isBackwardEdge,  bool? isValid)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ConnectionMetadata() when $default != null:
return $default(_that.connectionClass,_that.busNumber,_that.signalType,_that.sourceAlgorithmId,_that.targetAlgorithmId,_that.sourceParameterNumber,_that.targetParameterNumber,_that.isBackwardEdge,_that.isValid);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( ConnectionClass connectionClass,  int busNumber,  SignalType signalType,  String? sourceAlgorithmId,  String? targetAlgorithmId,  int? sourceParameterNumber,  int? targetParameterNumber,  bool? isBackwardEdge,  bool? isValid)  $default,) {final _that = this;
switch (_that) {
case _ConnectionMetadata():
return $default(_that.connectionClass,_that.busNumber,_that.signalType,_that.sourceAlgorithmId,_that.targetAlgorithmId,_that.sourceParameterNumber,_that.targetParameterNumber,_that.isBackwardEdge,_that.isValid);}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( ConnectionClass connectionClass,  int busNumber,  SignalType signalType,  String? sourceAlgorithmId,  String? targetAlgorithmId,  int? sourceParameterNumber,  int? targetParameterNumber,  bool? isBackwardEdge,  bool? isValid)?  $default,) {final _that = this;
switch (_that) {
case _ConnectionMetadata() when $default != null:
return $default(_that.connectionClass,_that.busNumber,_that.signalType,_that.sourceAlgorithmId,_that.targetAlgorithmId,_that.sourceParameterNumber,_that.targetParameterNumber,_that.isBackwardEdge,_that.isValid);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ConnectionMetadata extends ConnectionMetadata {
  const _ConnectionMetadata({required this.connectionClass, required this.busNumber, required this.signalType, this.sourceAlgorithmId, this.targetAlgorithmId, this.sourceParameterNumber, this.targetParameterNumber, this.isBackwardEdge, this.isValid}): super._();
  factory _ConnectionMetadata.fromJson(Map<String, dynamic> json) => _$ConnectionMetadataFromJson(json);

/// Classification of this connection
@override final  ConnectionClass connectionClass;
/// Bus number used for this connection (1-28, or 0 for direct)
@override final  int busNumber;
/// Type of signal flowing through this connection
@override final  SignalType signalType;
/// Source algorithm ID (for algorithm connections)
@override final  String? sourceAlgorithmId;
/// Target algorithm ID (for algorithm connections)
@override final  String? targetAlgorithmId;
/// Source parameter number (for algorithm connections)
@override final  int? sourceParameterNumber;
/// Target parameter number (for algorithm connections)
@override final  int? targetParameterNumber;
/// Whether this creates a backward edge in the execution graph
@override final  bool? isBackwardEdge;
/// Whether this connection is valid
@override final  bool? isValid;

/// Create a copy of ConnectionMetadata
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ConnectionMetadataCopyWith<_ConnectionMetadata> get copyWith => __$ConnectionMetadataCopyWithImpl<_ConnectionMetadata>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ConnectionMetadataToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ConnectionMetadata&&(identical(other.connectionClass, connectionClass) || other.connectionClass == connectionClass)&&(identical(other.busNumber, busNumber) || other.busNumber == busNumber)&&(identical(other.signalType, signalType) || other.signalType == signalType)&&(identical(other.sourceAlgorithmId, sourceAlgorithmId) || other.sourceAlgorithmId == sourceAlgorithmId)&&(identical(other.targetAlgorithmId, targetAlgorithmId) || other.targetAlgorithmId == targetAlgorithmId)&&(identical(other.sourceParameterNumber, sourceParameterNumber) || other.sourceParameterNumber == sourceParameterNumber)&&(identical(other.targetParameterNumber, targetParameterNumber) || other.targetParameterNumber == targetParameterNumber)&&(identical(other.isBackwardEdge, isBackwardEdge) || other.isBackwardEdge == isBackwardEdge)&&(identical(other.isValid, isValid) || other.isValid == isValid));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,connectionClass,busNumber,signalType,sourceAlgorithmId,targetAlgorithmId,sourceParameterNumber,targetParameterNumber,isBackwardEdge,isValid);

@override
String toString() {
  return 'ConnectionMetadata(connectionClass: $connectionClass, busNumber: $busNumber, signalType: $signalType, sourceAlgorithmId: $sourceAlgorithmId, targetAlgorithmId: $targetAlgorithmId, sourceParameterNumber: $sourceParameterNumber, targetParameterNumber: $targetParameterNumber, isBackwardEdge: $isBackwardEdge, isValid: $isValid)';
}


}

/// @nodoc
abstract mixin class _$ConnectionMetadataCopyWith<$Res> implements $ConnectionMetadataCopyWith<$Res> {
  factory _$ConnectionMetadataCopyWith(_ConnectionMetadata value, $Res Function(_ConnectionMetadata) _then) = __$ConnectionMetadataCopyWithImpl;
@override @useResult
$Res call({
 ConnectionClass connectionClass, int busNumber, SignalType signalType, String? sourceAlgorithmId, String? targetAlgorithmId, int? sourceParameterNumber, int? targetParameterNumber, bool? isBackwardEdge, bool? isValid
});




}
/// @nodoc
class __$ConnectionMetadataCopyWithImpl<$Res>
    implements _$ConnectionMetadataCopyWith<$Res> {
  __$ConnectionMetadataCopyWithImpl(this._self, this._then);

  final _ConnectionMetadata _self;
  final $Res Function(_ConnectionMetadata) _then;

/// Create a copy of ConnectionMetadata
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? connectionClass = null,Object? busNumber = null,Object? signalType = null,Object? sourceAlgorithmId = freezed,Object? targetAlgorithmId = freezed,Object? sourceParameterNumber = freezed,Object? targetParameterNumber = freezed,Object? isBackwardEdge = freezed,Object? isValid = freezed,}) {
  return _then(_ConnectionMetadata(
connectionClass: null == connectionClass ? _self.connectionClass : connectionClass // ignore: cast_nullable_to_non_nullable
as ConnectionClass,busNumber: null == busNumber ? _self.busNumber : busNumber // ignore: cast_nullable_to_non_nullable
as int,signalType: null == signalType ? _self.signalType : signalType // ignore: cast_nullable_to_non_nullable
as SignalType,sourceAlgorithmId: freezed == sourceAlgorithmId ? _self.sourceAlgorithmId : sourceAlgorithmId // ignore: cast_nullable_to_non_nullable
as String?,targetAlgorithmId: freezed == targetAlgorithmId ? _self.targetAlgorithmId : targetAlgorithmId // ignore: cast_nullable_to_non_nullable
as String?,sourceParameterNumber: freezed == sourceParameterNumber ? _self.sourceParameterNumber : sourceParameterNumber // ignore: cast_nullable_to_non_nullable
as int?,targetParameterNumber: freezed == targetParameterNumber ? _self.targetParameterNumber : targetParameterNumber // ignore: cast_nullable_to_non_nullable
as int?,isBackwardEdge: freezed == isBackwardEdge ? _self.isBackwardEdge : isBackwardEdge // ignore: cast_nullable_to_non_nullable
as bool?,isValid: freezed == isValid ? _self.isValid : isValid // ignore: cast_nullable_to_non_nullable
as bool?,
  ));
}


}

// dart format on
