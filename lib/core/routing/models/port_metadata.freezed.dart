// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'port_metadata.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
PortMetadata _$PortMetadataFromJson(
  Map<String, dynamic> json
) {
        switch (json['runtimeType']) {
                  case 'hardware':
          return HardwarePortMetadata.fromJson(
            json
          );
                case 'algorithm':
          return AlgorithmPortMetadata.fromJson(
            json
          );
        
          default:
            throw CheckedFromJsonException(
  json,
  'runtimeType',
  'PortMetadata',
  'Invalid union type "${json['runtimeType']}"!'
);
        }
      
}

/// @nodoc
mixin _$PortMetadata {

/// Bus number this port is connected to (1-20)
 int? get busNumber;
/// Create a copy of PortMetadata
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PortMetadataCopyWith<PortMetadata> get copyWith => _$PortMetadataCopyWithImpl<PortMetadata>(this as PortMetadata, _$identity);

  /// Serializes this PortMetadata to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PortMetadata&&(identical(other.busNumber, busNumber) || other.busNumber == busNumber));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,busNumber);

@override
String toString() {
  return 'PortMetadata(busNumber: $busNumber)';
}


}

/// @nodoc
abstract mixin class $PortMetadataCopyWith<$Res>  {
  factory $PortMetadataCopyWith(PortMetadata value, $Res Function(PortMetadata) _then) = _$PortMetadataCopyWithImpl;
@useResult
$Res call({
 int busNumber
});




}
/// @nodoc
class _$PortMetadataCopyWithImpl<$Res>
    implements $PortMetadataCopyWith<$Res> {
  _$PortMetadataCopyWithImpl(this._self, this._then);

  final PortMetadata _self;
  final $Res Function(PortMetadata) _then;

/// Create a copy of PortMetadata
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? busNumber = null,}) {
  return _then(_self.copyWith(
busNumber: null == busNumber ? _self.busNumber! : busNumber // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [PortMetadata].
extension PortMetadataPatterns on PortMetadata {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( HardwarePortMetadata value)?  hardware,TResult Function( AlgorithmPortMetadata value)?  algorithm,required TResult orElse(),}){
final _that = this;
switch (_that) {
case HardwarePortMetadata() when hardware != null:
return hardware(_that);case AlgorithmPortMetadata() when algorithm != null:
return algorithm(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( HardwarePortMetadata value)  hardware,required TResult Function( AlgorithmPortMetadata value)  algorithm,}){
final _that = this;
switch (_that) {
case HardwarePortMetadata():
return hardware(_that);case AlgorithmPortMetadata():
return algorithm(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( HardwarePortMetadata value)?  hardware,TResult? Function( AlgorithmPortMetadata value)?  algorithm,}){
final _that = this;
switch (_that) {
case HardwarePortMetadata() when hardware != null:
return hardware(_that);case AlgorithmPortMetadata() when algorithm != null:
return algorithm(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( int busNumber,  bool isInput,  int jackNumber)?  hardware,TResult Function( String algorithmId,  int parameterNumber,  String parameterName,  int? busNumber,  String? voiceNumber,  String? channel)?  algorithm,required TResult orElse(),}) {final _that = this;
switch (_that) {
case HardwarePortMetadata() when hardware != null:
return hardware(_that.busNumber,_that.isInput,_that.jackNumber);case AlgorithmPortMetadata() when algorithm != null:
return algorithm(_that.algorithmId,_that.parameterNumber,_that.parameterName,_that.busNumber,_that.voiceNumber,_that.channel);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( int busNumber,  bool isInput,  int jackNumber)  hardware,required TResult Function( String algorithmId,  int parameterNumber,  String parameterName,  int? busNumber,  String? voiceNumber,  String? channel)  algorithm,}) {final _that = this;
switch (_that) {
case HardwarePortMetadata():
return hardware(_that.busNumber,_that.isInput,_that.jackNumber);case AlgorithmPortMetadata():
return algorithm(_that.algorithmId,_that.parameterNumber,_that.parameterName,_that.busNumber,_that.voiceNumber,_that.channel);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( int busNumber,  bool isInput,  int jackNumber)?  hardware,TResult? Function( String algorithmId,  int parameterNumber,  String parameterName,  int? busNumber,  String? voiceNumber,  String? channel)?  algorithm,}) {final _that = this;
switch (_that) {
case HardwarePortMetadata() when hardware != null:
return hardware(_that.busNumber,_that.isInput,_that.jackNumber);case AlgorithmPortMetadata() when algorithm != null:
return algorithm(_that.algorithmId,_that.parameterNumber,_that.parameterName,_that.busNumber,_that.voiceNumber,_that.channel);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class HardwarePortMetadata implements PortMetadata {
  const HardwarePortMetadata({required this.busNumber, required this.isInput, required this.jackNumber, final  String? $type}): $type = $type ?? 'hardware';
  factory HardwarePortMetadata.fromJson(Map<String, dynamic> json) => _$HardwarePortMetadataFromJson(json);

/// Bus number this port is connected to (1-20)
@override final  int busNumber;
/// Whether this is an input (true) or output (false) port
 final  bool isInput;
/// Physical jack number (1-12 for inputs, 1-8 for outputs)
 final  int jackNumber;

@JsonKey(name: 'runtimeType')
final String $type;


/// Create a copy of PortMetadata
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HardwarePortMetadataCopyWith<HardwarePortMetadata> get copyWith => _$HardwarePortMetadataCopyWithImpl<HardwarePortMetadata>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$HardwarePortMetadataToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HardwarePortMetadata&&(identical(other.busNumber, busNumber) || other.busNumber == busNumber)&&(identical(other.isInput, isInput) || other.isInput == isInput)&&(identical(other.jackNumber, jackNumber) || other.jackNumber == jackNumber));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,busNumber,isInput,jackNumber);

@override
String toString() {
  return 'PortMetadata.hardware(busNumber: $busNumber, isInput: $isInput, jackNumber: $jackNumber)';
}


}

/// @nodoc
abstract mixin class $HardwarePortMetadataCopyWith<$Res> implements $PortMetadataCopyWith<$Res> {
  factory $HardwarePortMetadataCopyWith(HardwarePortMetadata value, $Res Function(HardwarePortMetadata) _then) = _$HardwarePortMetadataCopyWithImpl;
@override @useResult
$Res call({
 int busNumber, bool isInput, int jackNumber
});




}
/// @nodoc
class _$HardwarePortMetadataCopyWithImpl<$Res>
    implements $HardwarePortMetadataCopyWith<$Res> {
  _$HardwarePortMetadataCopyWithImpl(this._self, this._then);

  final HardwarePortMetadata _self;
  final $Res Function(HardwarePortMetadata) _then;

/// Create a copy of PortMetadata
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? busNumber = null,Object? isInput = null,Object? jackNumber = null,}) {
  return _then(HardwarePortMetadata(
busNumber: null == busNumber ? _self.busNumber : busNumber // ignore: cast_nullable_to_non_nullable
as int,isInput: null == isInput ? _self.isInput : isInput // ignore: cast_nullable_to_non_nullable
as bool,jackNumber: null == jackNumber ? _self.jackNumber : jackNumber // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc
@JsonSerializable()

class AlgorithmPortMetadata implements PortMetadata {
  const AlgorithmPortMetadata({required this.algorithmId, required this.parameterNumber, required this.parameterName, this.busNumber, this.voiceNumber, this.channel, final  String? $type}): $type = $type ?? 'algorithm';
  factory AlgorithmPortMetadata.fromJson(Map<String, dynamic> json) => _$AlgorithmPortMetadataFromJson(json);

/// Stable UUID of the algorithm instance
 final  String algorithmId;
/// Parameter number that controls this port's bus assignment
 final  int parameterNumber;
/// Human-readable name of the parameter
 final  String parameterName;
/// Current bus assignment (null if not connected)
@override final  int? busNumber;
/// Voice number for polyphonic algorithms
 final  String? voiceNumber;
/// Channel designation ('left', 'right', 'mono')
 final  String? channel;

@JsonKey(name: 'runtimeType')
final String $type;


/// Create a copy of PortMetadata
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AlgorithmPortMetadataCopyWith<AlgorithmPortMetadata> get copyWith => _$AlgorithmPortMetadataCopyWithImpl<AlgorithmPortMetadata>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AlgorithmPortMetadataToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AlgorithmPortMetadata&&(identical(other.algorithmId, algorithmId) || other.algorithmId == algorithmId)&&(identical(other.parameterNumber, parameterNumber) || other.parameterNumber == parameterNumber)&&(identical(other.parameterName, parameterName) || other.parameterName == parameterName)&&(identical(other.busNumber, busNumber) || other.busNumber == busNumber)&&(identical(other.voiceNumber, voiceNumber) || other.voiceNumber == voiceNumber)&&(identical(other.channel, channel) || other.channel == channel));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,algorithmId,parameterNumber,parameterName,busNumber,voiceNumber,channel);

@override
String toString() {
  return 'PortMetadata.algorithm(algorithmId: $algorithmId, parameterNumber: $parameterNumber, parameterName: $parameterName, busNumber: $busNumber, voiceNumber: $voiceNumber, channel: $channel)';
}


}

/// @nodoc
abstract mixin class $AlgorithmPortMetadataCopyWith<$Res> implements $PortMetadataCopyWith<$Res> {
  factory $AlgorithmPortMetadataCopyWith(AlgorithmPortMetadata value, $Res Function(AlgorithmPortMetadata) _then) = _$AlgorithmPortMetadataCopyWithImpl;
@override @useResult
$Res call({
 String algorithmId, int parameterNumber, String parameterName, int? busNumber, String? voiceNumber, String? channel
});




}
/// @nodoc
class _$AlgorithmPortMetadataCopyWithImpl<$Res>
    implements $AlgorithmPortMetadataCopyWith<$Res> {
  _$AlgorithmPortMetadataCopyWithImpl(this._self, this._then);

  final AlgorithmPortMetadata _self;
  final $Res Function(AlgorithmPortMetadata) _then;

/// Create a copy of PortMetadata
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? algorithmId = null,Object? parameterNumber = null,Object? parameterName = null,Object? busNumber = freezed,Object? voiceNumber = freezed,Object? channel = freezed,}) {
  return _then(AlgorithmPortMetadata(
algorithmId: null == algorithmId ? _self.algorithmId : algorithmId // ignore: cast_nullable_to_non_nullable
as String,parameterNumber: null == parameterNumber ? _self.parameterNumber : parameterNumber // ignore: cast_nullable_to_non_nullable
as int,parameterName: null == parameterName ? _self.parameterName : parameterName // ignore: cast_nullable_to_non_nullable
as String,busNumber: freezed == busNumber ? _self.busNumber : busNumber // ignore: cast_nullable_to_non_nullable
as int?,voiceNumber: freezed == voiceNumber ? _self.voiceNumber : voiceNumber // ignore: cast_nullable_to_non_nullable
as String?,channel: freezed == channel ? _self.channel : channel // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
