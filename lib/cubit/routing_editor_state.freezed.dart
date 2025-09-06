// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'routing_editor_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Port {

 String get id;// Unique identifier
 String get name;// Display name
 PortType get type; PortDirection get direction; int? get busNumber;// Bus number this port is connected to (1-28)
 String? get parameterName;
/// Create a copy of Port
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PortCopyWith<Port> get copyWith => _$PortCopyWithImpl<Port>(this as Port, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Port&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.type, type) || other.type == type)&&(identical(other.direction, direction) || other.direction == direction)&&(identical(other.busNumber, busNumber) || other.busNumber == busNumber)&&(identical(other.parameterName, parameterName) || other.parameterName == parameterName));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,type,direction,busNumber,parameterName);

@override
String toString() {
  return 'Port(id: $id, name: $name, type: $type, direction: $direction, busNumber: $busNumber, parameterName: $parameterName)';
}


}

/// @nodoc
abstract mixin class $PortCopyWith<$Res>  {
  factory $PortCopyWith(Port value, $Res Function(Port) _then) = _$PortCopyWithImpl;
@useResult
$Res call({
 String id, String name, PortType type, PortDirection direction, int? busNumber, String? parameterName
});




}
/// @nodoc
class _$PortCopyWithImpl<$Res>
    implements $PortCopyWith<$Res> {
  _$PortCopyWithImpl(this._self, this._then);

  final Port _self;
  final $Res Function(Port) _then;

/// Create a copy of Port
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? type = null,Object? direction = null,Object? busNumber = freezed,Object? parameterName = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as PortType,direction: null == direction ? _self.direction : direction // ignore: cast_nullable_to_non_nullable
as PortDirection,busNumber: freezed == busNumber ? _self.busNumber : busNumber // ignore: cast_nullable_to_non_nullable
as int?,parameterName: freezed == parameterName ? _self.parameterName : parameterName // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [Port].
extension PortPatterns on Port {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Port value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Port() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Port value)  $default,){
final _that = this;
switch (_that) {
case _Port():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Port value)?  $default,){
final _that = this;
switch (_that) {
case _Port() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  PortType type,  PortDirection direction,  int? busNumber,  String? parameterName)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Port() when $default != null:
return $default(_that.id,_that.name,_that.type,_that.direction,_that.busNumber,_that.parameterName);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  PortType type,  PortDirection direction,  int? busNumber,  String? parameterName)  $default,) {final _that = this;
switch (_that) {
case _Port():
return $default(_that.id,_that.name,_that.type,_that.direction,_that.busNumber,_that.parameterName);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  PortType type,  PortDirection direction,  int? busNumber,  String? parameterName)?  $default,) {final _that = this;
switch (_that) {
case _Port() when $default != null:
return $default(_that.id,_that.name,_that.type,_that.direction,_that.busNumber,_that.parameterName);case _:
  return null;

}
}

}

/// @nodoc


class _Port implements Port {
  const _Port({required this.id, required this.name, required this.type, required this.direction, this.busNumber, this.parameterName});
  

@override final  String id;
// Unique identifier
@override final  String name;
// Display name
@override final  PortType type;
@override final  PortDirection direction;
@override final  int? busNumber;
// Bus number this port is connected to (1-28)
@override final  String? parameterName;

/// Create a copy of Port
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PortCopyWith<_Port> get copyWith => __$PortCopyWithImpl<_Port>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Port&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.type, type) || other.type == type)&&(identical(other.direction, direction) || other.direction == direction)&&(identical(other.busNumber, busNumber) || other.busNumber == busNumber)&&(identical(other.parameterName, parameterName) || other.parameterName == parameterName));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,type,direction,busNumber,parameterName);

@override
String toString() {
  return 'Port(id: $id, name: $name, type: $type, direction: $direction, busNumber: $busNumber, parameterName: $parameterName)';
}


}

/// @nodoc
abstract mixin class _$PortCopyWith<$Res> implements $PortCopyWith<$Res> {
  factory _$PortCopyWith(_Port value, $Res Function(_Port) _then) = __$PortCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, PortType type, PortDirection direction, int? busNumber, String? parameterName
});




}
/// @nodoc
class __$PortCopyWithImpl<$Res>
    implements _$PortCopyWith<$Res> {
  __$PortCopyWithImpl(this._self, this._then);

  final _Port _self;
  final $Res Function(_Port) _then;

/// Create a copy of Port
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? type = null,Object? direction = null,Object? busNumber = freezed,Object? parameterName = freezed,}) {
  return _then(_Port(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as PortType,direction: null == direction ? _self.direction : direction // ignore: cast_nullable_to_non_nullable
as PortDirection,busNumber: freezed == busNumber ? _self.busNumber : busNumber // ignore: cast_nullable_to_non_nullable
as int?,parameterName: freezed == parameterName ? _self.parameterName : parameterName // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
mixin _$RoutingBus {

 String get id; String get name; BusStatus get status; List<String> get connectionIds; core_port.OutputMode get defaultOutputMode; double get masterGain; DateTime? get createdAt; DateTime? get modifiedAt;
/// Create a copy of RoutingBus
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RoutingBusCopyWith<RoutingBus> get copyWith => _$RoutingBusCopyWithImpl<RoutingBus>(this as RoutingBus, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RoutingBus&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other.connectionIds, connectionIds)&&(identical(other.defaultOutputMode, defaultOutputMode) || other.defaultOutputMode == defaultOutputMode)&&(identical(other.masterGain, masterGain) || other.masterGain == masterGain)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.modifiedAt, modifiedAt) || other.modifiedAt == modifiedAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,status,const DeepCollectionEquality().hash(connectionIds),defaultOutputMode,masterGain,createdAt,modifiedAt);

@override
String toString() {
  return 'RoutingBus(id: $id, name: $name, status: $status, connectionIds: $connectionIds, defaultOutputMode: $defaultOutputMode, masterGain: $masterGain, createdAt: $createdAt, modifiedAt: $modifiedAt)';
}


}

/// @nodoc
abstract mixin class $RoutingBusCopyWith<$Res>  {
  factory $RoutingBusCopyWith(RoutingBus value, $Res Function(RoutingBus) _then) = _$RoutingBusCopyWithImpl;
@useResult
$Res call({
 String id, String name, BusStatus status, List<String> connectionIds, core_port.OutputMode defaultOutputMode, double masterGain, DateTime? createdAt, DateTime? modifiedAt
});




}
/// @nodoc
class _$RoutingBusCopyWithImpl<$Res>
    implements $RoutingBusCopyWith<$Res> {
  _$RoutingBusCopyWithImpl(this._self, this._then);

  final RoutingBus _self;
  final $Res Function(RoutingBus) _then;

/// Create a copy of RoutingBus
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? status = null,Object? connectionIds = null,Object? defaultOutputMode = null,Object? masterGain = null,Object? createdAt = freezed,Object? modifiedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as BusStatus,connectionIds: null == connectionIds ? _self.connectionIds : connectionIds // ignore: cast_nullable_to_non_nullable
as List<String>,defaultOutputMode: null == defaultOutputMode ? _self.defaultOutputMode : defaultOutputMode // ignore: cast_nullable_to_non_nullable
as core_port.OutputMode,masterGain: null == masterGain ? _self.masterGain : masterGain // ignore: cast_nullable_to_non_nullable
as double,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,modifiedAt: freezed == modifiedAt ? _self.modifiedAt : modifiedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [RoutingBus].
extension RoutingBusPatterns on RoutingBus {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RoutingBus value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RoutingBus() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RoutingBus value)  $default,){
final _that = this;
switch (_that) {
case _RoutingBus():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RoutingBus value)?  $default,){
final _that = this;
switch (_that) {
case _RoutingBus() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  BusStatus status,  List<String> connectionIds,  core_port.OutputMode defaultOutputMode,  double masterGain,  DateTime? createdAt,  DateTime? modifiedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RoutingBus() when $default != null:
return $default(_that.id,_that.name,_that.status,_that.connectionIds,_that.defaultOutputMode,_that.masterGain,_that.createdAt,_that.modifiedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  BusStatus status,  List<String> connectionIds,  core_port.OutputMode defaultOutputMode,  double masterGain,  DateTime? createdAt,  DateTime? modifiedAt)  $default,) {final _that = this;
switch (_that) {
case _RoutingBus():
return $default(_that.id,_that.name,_that.status,_that.connectionIds,_that.defaultOutputMode,_that.masterGain,_that.createdAt,_that.modifiedAt);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  BusStatus status,  List<String> connectionIds,  core_port.OutputMode defaultOutputMode,  double masterGain,  DateTime? createdAt,  DateTime? modifiedAt)?  $default,) {final _that = this;
switch (_that) {
case _RoutingBus() when $default != null:
return $default(_that.id,_that.name,_that.status,_that.connectionIds,_that.defaultOutputMode,_that.masterGain,_that.createdAt,_that.modifiedAt);case _:
  return null;

}
}

}

/// @nodoc


class _RoutingBus implements RoutingBus {
  const _RoutingBus({required this.id, required this.name, required this.status, final  List<String> connectionIds = const [], this.defaultOutputMode = core_port.OutputMode.replace, this.masterGain = 1.0, this.createdAt, this.modifiedAt}): _connectionIds = connectionIds;
  

@override final  String id;
@override final  String name;
@override final  BusStatus status;
 final  List<String> _connectionIds;
@override@JsonKey() List<String> get connectionIds {
  if (_connectionIds is EqualUnmodifiableListView) return _connectionIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_connectionIds);
}

@override@JsonKey() final  core_port.OutputMode defaultOutputMode;
@override@JsonKey() final  double masterGain;
@override final  DateTime? createdAt;
@override final  DateTime? modifiedAt;

/// Create a copy of RoutingBus
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RoutingBusCopyWith<_RoutingBus> get copyWith => __$RoutingBusCopyWithImpl<_RoutingBus>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RoutingBus&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other._connectionIds, _connectionIds)&&(identical(other.defaultOutputMode, defaultOutputMode) || other.defaultOutputMode == defaultOutputMode)&&(identical(other.masterGain, masterGain) || other.masterGain == masterGain)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.modifiedAt, modifiedAt) || other.modifiedAt == modifiedAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,status,const DeepCollectionEquality().hash(_connectionIds),defaultOutputMode,masterGain,createdAt,modifiedAt);

@override
String toString() {
  return 'RoutingBus(id: $id, name: $name, status: $status, connectionIds: $connectionIds, defaultOutputMode: $defaultOutputMode, masterGain: $masterGain, createdAt: $createdAt, modifiedAt: $modifiedAt)';
}


}

/// @nodoc
abstract mixin class _$RoutingBusCopyWith<$Res> implements $RoutingBusCopyWith<$Res> {
  factory _$RoutingBusCopyWith(_RoutingBus value, $Res Function(_RoutingBus) _then) = __$RoutingBusCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, BusStatus status, List<String> connectionIds, core_port.OutputMode defaultOutputMode, double masterGain, DateTime? createdAt, DateTime? modifiedAt
});




}
/// @nodoc
class __$RoutingBusCopyWithImpl<$Res>
    implements _$RoutingBusCopyWith<$Res> {
  __$RoutingBusCopyWithImpl(this._self, this._then);

  final _RoutingBus _self;
  final $Res Function(_RoutingBus) _then;

/// Create a copy of RoutingBus
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? status = null,Object? connectionIds = null,Object? defaultOutputMode = null,Object? masterGain = null,Object? createdAt = freezed,Object? modifiedAt = freezed,}) {
  return _then(_RoutingBus(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as BusStatus,connectionIds: null == connectionIds ? _self._connectionIds : connectionIds // ignore: cast_nullable_to_non_nullable
as List<String>,defaultOutputMode: null == defaultOutputMode ? _self.defaultOutputMode : defaultOutputMode // ignore: cast_nullable_to_non_nullable
as core_port.OutputMode,masterGain: null == masterGain ? _self.masterGain : masterGain // ignore: cast_nullable_to_non_nullable
as double,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,modifiedAt: freezed == modifiedAt ? _self.modifiedAt : modifiedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

/// @nodoc
mixin _$RoutingAlgorithm {

/// Stable unique identifier for this algorithm instance
 String get id;/// Current slot index (0-7), can change when algorithms are reordered
 int get index;/// The algorithm definition
 Algorithm get algorithm;/// Input ports for this algorithm
 List<Port> get inputPorts;/// Output ports for this algorithm
 List<Port> get outputPorts;
/// Create a copy of RoutingAlgorithm
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RoutingAlgorithmCopyWith<RoutingAlgorithm> get copyWith => _$RoutingAlgorithmCopyWithImpl<RoutingAlgorithm>(this as RoutingAlgorithm, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RoutingAlgorithm&&(identical(other.id, id) || other.id == id)&&(identical(other.index, index) || other.index == index)&&(identical(other.algorithm, algorithm) || other.algorithm == algorithm)&&const DeepCollectionEquality().equals(other.inputPorts, inputPorts)&&const DeepCollectionEquality().equals(other.outputPorts, outputPorts));
}


@override
int get hashCode => Object.hash(runtimeType,id,index,algorithm,const DeepCollectionEquality().hash(inputPorts),const DeepCollectionEquality().hash(outputPorts));

@override
String toString() {
  return 'RoutingAlgorithm(id: $id, index: $index, algorithm: $algorithm, inputPorts: $inputPorts, outputPorts: $outputPorts)';
}


}

/// @nodoc
abstract mixin class $RoutingAlgorithmCopyWith<$Res>  {
  factory $RoutingAlgorithmCopyWith(RoutingAlgorithm value, $Res Function(RoutingAlgorithm) _then) = _$RoutingAlgorithmCopyWithImpl;
@useResult
$Res call({
 String id, int index, Algorithm algorithm, List<Port> inputPorts, List<Port> outputPorts
});




}
/// @nodoc
class _$RoutingAlgorithmCopyWithImpl<$Res>
    implements $RoutingAlgorithmCopyWith<$Res> {
  _$RoutingAlgorithmCopyWithImpl(this._self, this._then);

  final RoutingAlgorithm _self;
  final $Res Function(RoutingAlgorithm) _then;

/// Create a copy of RoutingAlgorithm
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? index = null,Object? algorithm = null,Object? inputPorts = null,Object? outputPorts = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,index: null == index ? _self.index : index // ignore: cast_nullable_to_non_nullable
as int,algorithm: null == algorithm ? _self.algorithm : algorithm // ignore: cast_nullable_to_non_nullable
as Algorithm,inputPorts: null == inputPorts ? _self.inputPorts : inputPorts // ignore: cast_nullable_to_non_nullable
as List<Port>,outputPorts: null == outputPorts ? _self.outputPorts : outputPorts // ignore: cast_nullable_to_non_nullable
as List<Port>,
  ));
}

}


/// Adds pattern-matching-related methods to [RoutingAlgorithm].
extension RoutingAlgorithmPatterns on RoutingAlgorithm {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RoutingAlgorithm value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RoutingAlgorithm() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RoutingAlgorithm value)  $default,){
final _that = this;
switch (_that) {
case _RoutingAlgorithm():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RoutingAlgorithm value)?  $default,){
final _that = this;
switch (_that) {
case _RoutingAlgorithm() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  int index,  Algorithm algorithm,  List<Port> inputPorts,  List<Port> outputPorts)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RoutingAlgorithm() when $default != null:
return $default(_that.id,_that.index,_that.algorithm,_that.inputPorts,_that.outputPorts);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  int index,  Algorithm algorithm,  List<Port> inputPorts,  List<Port> outputPorts)  $default,) {final _that = this;
switch (_that) {
case _RoutingAlgorithm():
return $default(_that.id,_that.index,_that.algorithm,_that.inputPorts,_that.outputPorts);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  int index,  Algorithm algorithm,  List<Port> inputPorts,  List<Port> outputPorts)?  $default,) {final _that = this;
switch (_that) {
case _RoutingAlgorithm() when $default != null:
return $default(_that.id,_that.index,_that.algorithm,_that.inputPorts,_that.outputPorts);case _:
  return null;

}
}

}

/// @nodoc


class _RoutingAlgorithm implements RoutingAlgorithm {
  const _RoutingAlgorithm({required this.id, required this.index, required this.algorithm, required final  List<Port> inputPorts, required final  List<Port> outputPorts}): _inputPorts = inputPorts,_outputPorts = outputPorts;
  

/// Stable unique identifier for this algorithm instance
@override final  String id;
/// Current slot index (0-7), can change when algorithms are reordered
@override final  int index;
/// The algorithm definition
@override final  Algorithm algorithm;
/// Input ports for this algorithm
 final  List<Port> _inputPorts;
/// Input ports for this algorithm
@override List<Port> get inputPorts {
  if (_inputPorts is EqualUnmodifiableListView) return _inputPorts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_inputPorts);
}

/// Output ports for this algorithm
 final  List<Port> _outputPorts;
/// Output ports for this algorithm
@override List<Port> get outputPorts {
  if (_outputPorts is EqualUnmodifiableListView) return _outputPorts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_outputPorts);
}


/// Create a copy of RoutingAlgorithm
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RoutingAlgorithmCopyWith<_RoutingAlgorithm> get copyWith => __$RoutingAlgorithmCopyWithImpl<_RoutingAlgorithm>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RoutingAlgorithm&&(identical(other.id, id) || other.id == id)&&(identical(other.index, index) || other.index == index)&&(identical(other.algorithm, algorithm) || other.algorithm == algorithm)&&const DeepCollectionEquality().equals(other._inputPorts, _inputPorts)&&const DeepCollectionEquality().equals(other._outputPorts, _outputPorts));
}


@override
int get hashCode => Object.hash(runtimeType,id,index,algorithm,const DeepCollectionEquality().hash(_inputPorts),const DeepCollectionEquality().hash(_outputPorts));

@override
String toString() {
  return 'RoutingAlgorithm(id: $id, index: $index, algorithm: $algorithm, inputPorts: $inputPorts, outputPorts: $outputPorts)';
}


}

/// @nodoc
abstract mixin class _$RoutingAlgorithmCopyWith<$Res> implements $RoutingAlgorithmCopyWith<$Res> {
  factory _$RoutingAlgorithmCopyWith(_RoutingAlgorithm value, $Res Function(_RoutingAlgorithm) _then) = __$RoutingAlgorithmCopyWithImpl;
@override @useResult
$Res call({
 String id, int index, Algorithm algorithm, List<Port> inputPorts, List<Port> outputPorts
});




}
/// @nodoc
class __$RoutingAlgorithmCopyWithImpl<$Res>
    implements _$RoutingAlgorithmCopyWith<$Res> {
  __$RoutingAlgorithmCopyWithImpl(this._self, this._then);

  final _RoutingAlgorithm _self;
  final $Res Function(_RoutingAlgorithm) _then;

/// Create a copy of RoutingAlgorithm
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? index = null,Object? algorithm = null,Object? inputPorts = null,Object? outputPorts = null,}) {
  return _then(_RoutingAlgorithm(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,index: null == index ? _self.index : index // ignore: cast_nullable_to_non_nullable
as int,algorithm: null == algorithm ? _self.algorithm : algorithm // ignore: cast_nullable_to_non_nullable
as Algorithm,inputPorts: null == inputPorts ? _self._inputPorts : inputPorts // ignore: cast_nullable_to_non_nullable
as List<Port>,outputPorts: null == outputPorts ? _self._outputPorts : outputPorts // ignore: cast_nullable_to_non_nullable
as List<Port>,
  ));
}


}

/// @nodoc
mixin _$RoutingEditorState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RoutingEditorState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'RoutingEditorState()';
}


}

/// @nodoc
class $RoutingEditorStateCopyWith<$Res>  {
$RoutingEditorStateCopyWith(RoutingEditorState _, $Res Function(RoutingEditorState) __);
}


/// Adds pattern-matching-related methods to [RoutingEditorState].
extension RoutingEditorStatePatterns on RoutingEditorState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( RoutingEditorStateInitial value)?  initial,TResult Function( RoutingEditorStateDisconnected value)?  disconnected,TResult Function( RoutingEditorStateConnecting value)?  connecting,TResult Function( RoutingEditorStateRefreshing value)?  refreshing,TResult Function( RoutingEditorStatePersisting value)?  persisting,TResult Function( RoutingEditorStateSyncing value)?  syncing,TResult Function( RoutingEditorStateLoaded value)?  loaded,TResult Function( RoutingEditorStateError value)?  error,required TResult orElse(),}){
final _that = this;
switch (_that) {
case RoutingEditorStateInitial() when initial != null:
return initial(_that);case RoutingEditorStateDisconnected() when disconnected != null:
return disconnected(_that);case RoutingEditorStateConnecting() when connecting != null:
return connecting(_that);case RoutingEditorStateRefreshing() when refreshing != null:
return refreshing(_that);case RoutingEditorStatePersisting() when persisting != null:
return persisting(_that);case RoutingEditorStateSyncing() when syncing != null:
return syncing(_that);case RoutingEditorStateLoaded() when loaded != null:
return loaded(_that);case RoutingEditorStateError() when error != null:
return error(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( RoutingEditorStateInitial value)  initial,required TResult Function( RoutingEditorStateDisconnected value)  disconnected,required TResult Function( RoutingEditorStateConnecting value)  connecting,required TResult Function( RoutingEditorStateRefreshing value)  refreshing,required TResult Function( RoutingEditorStatePersisting value)  persisting,required TResult Function( RoutingEditorStateSyncing value)  syncing,required TResult Function( RoutingEditorStateLoaded value)  loaded,required TResult Function( RoutingEditorStateError value)  error,}){
final _that = this;
switch (_that) {
case RoutingEditorStateInitial():
return initial(_that);case RoutingEditorStateDisconnected():
return disconnected(_that);case RoutingEditorStateConnecting():
return connecting(_that);case RoutingEditorStateRefreshing():
return refreshing(_that);case RoutingEditorStatePersisting():
return persisting(_that);case RoutingEditorStateSyncing():
return syncing(_that);case RoutingEditorStateLoaded():
return loaded(_that);case RoutingEditorStateError():
return error(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( RoutingEditorStateInitial value)?  initial,TResult? Function( RoutingEditorStateDisconnected value)?  disconnected,TResult? Function( RoutingEditorStateConnecting value)?  connecting,TResult? Function( RoutingEditorStateRefreshing value)?  refreshing,TResult? Function( RoutingEditorStatePersisting value)?  persisting,TResult? Function( RoutingEditorStateSyncing value)?  syncing,TResult? Function( RoutingEditorStateLoaded value)?  loaded,TResult? Function( RoutingEditorStateError value)?  error,}){
final _that = this;
switch (_that) {
case RoutingEditorStateInitial() when initial != null:
return initial(_that);case RoutingEditorStateDisconnected() when disconnected != null:
return disconnected(_that);case RoutingEditorStateConnecting() when connecting != null:
return connecting(_that);case RoutingEditorStateRefreshing() when refreshing != null:
return refreshing(_that);case RoutingEditorStatePersisting() when persisting != null:
return persisting(_that);case RoutingEditorStateSyncing() when syncing != null:
return syncing(_that);case RoutingEditorStateLoaded() when loaded != null:
return loaded(_that);case RoutingEditorStateError() when error != null:
return error(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function()?  disconnected,TResult Function()?  connecting,TResult Function()?  refreshing,TResult Function()?  persisting,TResult Function()?  syncing,TResult Function( List<Port> physicalInputs,  List<Port> physicalOutputs,  List<RoutingAlgorithm> algorithms,  List<Connection> connections,  List<RoutingBus> buses,  Map<String, core_port.OutputMode> portOutputModes,  bool isHardwareSynced,  bool isPersistenceEnabled,  ConnectionDeletionState deletionState,  DateTime? lastSyncTime,  DateTime? lastPersistTime,  String? lastError)?  loaded,TResult Function( String message)?  error,required TResult orElse(),}) {final _that = this;
switch (_that) {
case RoutingEditorStateInitial() when initial != null:
return initial();case RoutingEditorStateDisconnected() when disconnected != null:
return disconnected();case RoutingEditorStateConnecting() when connecting != null:
return connecting();case RoutingEditorStateRefreshing() when refreshing != null:
return refreshing();case RoutingEditorStatePersisting() when persisting != null:
return persisting();case RoutingEditorStateSyncing() when syncing != null:
return syncing();case RoutingEditorStateLoaded() when loaded != null:
return loaded(_that.physicalInputs,_that.physicalOutputs,_that.algorithms,_that.connections,_that.buses,_that.portOutputModes,_that.isHardwareSynced,_that.isPersistenceEnabled,_that.deletionState,_that.lastSyncTime,_that.lastPersistTime,_that.lastError);case RoutingEditorStateError() when error != null:
return error(_that.message);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function()  disconnected,required TResult Function()  connecting,required TResult Function()  refreshing,required TResult Function()  persisting,required TResult Function()  syncing,required TResult Function( List<Port> physicalInputs,  List<Port> physicalOutputs,  List<RoutingAlgorithm> algorithms,  List<Connection> connections,  List<RoutingBus> buses,  Map<String, core_port.OutputMode> portOutputModes,  bool isHardwareSynced,  bool isPersistenceEnabled,  ConnectionDeletionState deletionState,  DateTime? lastSyncTime,  DateTime? lastPersistTime,  String? lastError)  loaded,required TResult Function( String message)  error,}) {final _that = this;
switch (_that) {
case RoutingEditorStateInitial():
return initial();case RoutingEditorStateDisconnected():
return disconnected();case RoutingEditorStateConnecting():
return connecting();case RoutingEditorStateRefreshing():
return refreshing();case RoutingEditorStatePersisting():
return persisting();case RoutingEditorStateSyncing():
return syncing();case RoutingEditorStateLoaded():
return loaded(_that.physicalInputs,_that.physicalOutputs,_that.algorithms,_that.connections,_that.buses,_that.portOutputModes,_that.isHardwareSynced,_that.isPersistenceEnabled,_that.deletionState,_that.lastSyncTime,_that.lastPersistTime,_that.lastError);case RoutingEditorStateError():
return error(_that.message);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function()?  disconnected,TResult? Function()?  connecting,TResult? Function()?  refreshing,TResult? Function()?  persisting,TResult? Function()?  syncing,TResult? Function( List<Port> physicalInputs,  List<Port> physicalOutputs,  List<RoutingAlgorithm> algorithms,  List<Connection> connections,  List<RoutingBus> buses,  Map<String, core_port.OutputMode> portOutputModes,  bool isHardwareSynced,  bool isPersistenceEnabled,  ConnectionDeletionState deletionState,  DateTime? lastSyncTime,  DateTime? lastPersistTime,  String? lastError)?  loaded,TResult? Function( String message)?  error,}) {final _that = this;
switch (_that) {
case RoutingEditorStateInitial() when initial != null:
return initial();case RoutingEditorStateDisconnected() when disconnected != null:
return disconnected();case RoutingEditorStateConnecting() when connecting != null:
return connecting();case RoutingEditorStateRefreshing() when refreshing != null:
return refreshing();case RoutingEditorStatePersisting() when persisting != null:
return persisting();case RoutingEditorStateSyncing() when syncing != null:
return syncing();case RoutingEditorStateLoaded() when loaded != null:
return loaded(_that.physicalInputs,_that.physicalOutputs,_that.algorithms,_that.connections,_that.buses,_that.portOutputModes,_that.isHardwareSynced,_that.isPersistenceEnabled,_that.deletionState,_that.lastSyncTime,_that.lastPersistTime,_that.lastError);case RoutingEditorStateError() when error != null:
return error(_that.message);case _:
  return null;

}
}

}

/// @nodoc


class RoutingEditorStateInitial implements RoutingEditorState {
  const RoutingEditorStateInitial();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RoutingEditorStateInitial);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'RoutingEditorState.initial()';
}


}




/// @nodoc


class RoutingEditorStateDisconnected implements RoutingEditorState {
  const RoutingEditorStateDisconnected();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RoutingEditorStateDisconnected);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'RoutingEditorState.disconnected()';
}


}




/// @nodoc


class RoutingEditorStateConnecting implements RoutingEditorState {
  const RoutingEditorStateConnecting();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RoutingEditorStateConnecting);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'RoutingEditorState.connecting()';
}


}




/// @nodoc


class RoutingEditorStateRefreshing implements RoutingEditorState {
  const RoutingEditorStateRefreshing();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RoutingEditorStateRefreshing);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'RoutingEditorState.refreshing()';
}


}




/// @nodoc


class RoutingEditorStatePersisting implements RoutingEditorState {
  const RoutingEditorStatePersisting();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RoutingEditorStatePersisting);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'RoutingEditorState.persisting()';
}


}




/// @nodoc


class RoutingEditorStateSyncing implements RoutingEditorState {
  const RoutingEditorStateSyncing();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RoutingEditorStateSyncing);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'RoutingEditorState.syncing()';
}


}




/// @nodoc


class RoutingEditorStateLoaded implements RoutingEditorState {
  const RoutingEditorStateLoaded({required final  List<Port> physicalInputs, required final  List<Port> physicalOutputs, required final  List<RoutingAlgorithm> algorithms, required final  List<Connection> connections, final  List<RoutingBus> buses = const [], final  Map<String, core_port.OutputMode> portOutputModes = const {}, this.isHardwareSynced = false, this.isPersistenceEnabled = false, this.deletionState = const ConnectionDeletionState.initial(), this.lastSyncTime, this.lastPersistTime, this.lastError}): _physicalInputs = physicalInputs,_physicalOutputs = physicalOutputs,_algorithms = algorithms,_connections = connections,_buses = buses,_portOutputModes = portOutputModes;
  

 final  List<Port> _physicalInputs;
 List<Port> get physicalInputs {
  if (_physicalInputs is EqualUnmodifiableListView) return _physicalInputs;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_physicalInputs);
}

// 12 physical input ports
 final  List<Port> _physicalOutputs;
// 12 physical input ports
 List<Port> get physicalOutputs {
  if (_physicalOutputs is EqualUnmodifiableListView) return _physicalOutputs;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_physicalOutputs);
}

// 8 physical output ports
 final  List<RoutingAlgorithm> _algorithms;
// 8 physical output ports
 List<RoutingAlgorithm> get algorithms {
  if (_algorithms is EqualUnmodifiableListView) return _algorithms;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_algorithms);
}

// Algorithms with their ports
 final  List<Connection> _connections;
// Algorithms with their ports
 List<Connection> get connections {
  if (_connections is EqualUnmodifiableListView) return _connections;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_connections);
}

// All routing connections
 final  List<RoutingBus> _buses;
// All routing connections
@JsonKey() List<RoutingBus> get buses {
  if (_buses is EqualUnmodifiableListView) return _buses;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_buses);
}

// Available routing buses
 final  Map<String, core_port.OutputMode> _portOutputModes;
// Available routing buses
@JsonKey() Map<String, core_port.OutputMode> get portOutputModes {
  if (_portOutputModes is EqualUnmodifiableMapView) return _portOutputModes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_portOutputModes);
}

// Output modes per port
@JsonKey() final  bool isHardwareSynced;
// Hardware sync status
@JsonKey() final  bool isPersistenceEnabled;
// State persistence status
@JsonKey() final  ConnectionDeletionState deletionState;
// Connection deletion interaction state
 final  DateTime? lastSyncTime;
// Last hardware sync timestamp
 final  DateTime? lastPersistTime;
// Last persistence save timestamp
 final  String? lastError;

/// Create a copy of RoutingEditorState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RoutingEditorStateLoadedCopyWith<RoutingEditorStateLoaded> get copyWith => _$RoutingEditorStateLoadedCopyWithImpl<RoutingEditorStateLoaded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RoutingEditorStateLoaded&&const DeepCollectionEquality().equals(other._physicalInputs, _physicalInputs)&&const DeepCollectionEquality().equals(other._physicalOutputs, _physicalOutputs)&&const DeepCollectionEquality().equals(other._algorithms, _algorithms)&&const DeepCollectionEquality().equals(other._connections, _connections)&&const DeepCollectionEquality().equals(other._buses, _buses)&&const DeepCollectionEquality().equals(other._portOutputModes, _portOutputModes)&&(identical(other.isHardwareSynced, isHardwareSynced) || other.isHardwareSynced == isHardwareSynced)&&(identical(other.isPersistenceEnabled, isPersistenceEnabled) || other.isPersistenceEnabled == isPersistenceEnabled)&&(identical(other.deletionState, deletionState) || other.deletionState == deletionState)&&(identical(other.lastSyncTime, lastSyncTime) || other.lastSyncTime == lastSyncTime)&&(identical(other.lastPersistTime, lastPersistTime) || other.lastPersistTime == lastPersistTime)&&(identical(other.lastError, lastError) || other.lastError == lastError));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_physicalInputs),const DeepCollectionEquality().hash(_physicalOutputs),const DeepCollectionEquality().hash(_algorithms),const DeepCollectionEquality().hash(_connections),const DeepCollectionEquality().hash(_buses),const DeepCollectionEquality().hash(_portOutputModes),isHardwareSynced,isPersistenceEnabled,deletionState,lastSyncTime,lastPersistTime,lastError);

@override
String toString() {
  return 'RoutingEditorState.loaded(physicalInputs: $physicalInputs, physicalOutputs: $physicalOutputs, algorithms: $algorithms, connections: $connections, buses: $buses, portOutputModes: $portOutputModes, isHardwareSynced: $isHardwareSynced, isPersistenceEnabled: $isPersistenceEnabled, deletionState: $deletionState, lastSyncTime: $lastSyncTime, lastPersistTime: $lastPersistTime, lastError: $lastError)';
}


}

/// @nodoc
abstract mixin class $RoutingEditorStateLoadedCopyWith<$Res> implements $RoutingEditorStateCopyWith<$Res> {
  factory $RoutingEditorStateLoadedCopyWith(RoutingEditorStateLoaded value, $Res Function(RoutingEditorStateLoaded) _then) = _$RoutingEditorStateLoadedCopyWithImpl;
@useResult
$Res call({
 List<Port> physicalInputs, List<Port> physicalOutputs, List<RoutingAlgorithm> algorithms, List<Connection> connections, List<RoutingBus> buses, Map<String, core_port.OutputMode> portOutputModes, bool isHardwareSynced, bool isPersistenceEnabled, ConnectionDeletionState deletionState, DateTime? lastSyncTime, DateTime? lastPersistTime, String? lastError
});


$ConnectionDeletionStateCopyWith<$Res> get deletionState;

}
/// @nodoc
class _$RoutingEditorStateLoadedCopyWithImpl<$Res>
    implements $RoutingEditorStateLoadedCopyWith<$Res> {
  _$RoutingEditorStateLoadedCopyWithImpl(this._self, this._then);

  final RoutingEditorStateLoaded _self;
  final $Res Function(RoutingEditorStateLoaded) _then;

/// Create a copy of RoutingEditorState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? physicalInputs = null,Object? physicalOutputs = null,Object? algorithms = null,Object? connections = null,Object? buses = null,Object? portOutputModes = null,Object? isHardwareSynced = null,Object? isPersistenceEnabled = null,Object? deletionState = null,Object? lastSyncTime = freezed,Object? lastPersistTime = freezed,Object? lastError = freezed,}) {
  return _then(RoutingEditorStateLoaded(
physicalInputs: null == physicalInputs ? _self._physicalInputs : physicalInputs // ignore: cast_nullable_to_non_nullable
as List<Port>,physicalOutputs: null == physicalOutputs ? _self._physicalOutputs : physicalOutputs // ignore: cast_nullable_to_non_nullable
as List<Port>,algorithms: null == algorithms ? _self._algorithms : algorithms // ignore: cast_nullable_to_non_nullable
as List<RoutingAlgorithm>,connections: null == connections ? _self._connections : connections // ignore: cast_nullable_to_non_nullable
as List<Connection>,buses: null == buses ? _self._buses : buses // ignore: cast_nullable_to_non_nullable
as List<RoutingBus>,portOutputModes: null == portOutputModes ? _self._portOutputModes : portOutputModes // ignore: cast_nullable_to_non_nullable
as Map<String, core_port.OutputMode>,isHardwareSynced: null == isHardwareSynced ? _self.isHardwareSynced : isHardwareSynced // ignore: cast_nullable_to_non_nullable
as bool,isPersistenceEnabled: null == isPersistenceEnabled ? _self.isPersistenceEnabled : isPersistenceEnabled // ignore: cast_nullable_to_non_nullable
as bool,deletionState: null == deletionState ? _self.deletionState : deletionState // ignore: cast_nullable_to_non_nullable
as ConnectionDeletionState,lastSyncTime: freezed == lastSyncTime ? _self.lastSyncTime : lastSyncTime // ignore: cast_nullable_to_non_nullable
as DateTime?,lastPersistTime: freezed == lastPersistTime ? _self.lastPersistTime : lastPersistTime // ignore: cast_nullable_to_non_nullable
as DateTime?,lastError: freezed == lastError ? _self.lastError : lastError // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of RoutingEditorState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ConnectionDeletionStateCopyWith<$Res> get deletionState {
  
  return $ConnectionDeletionStateCopyWith<$Res>(_self.deletionState, (value) {
    return _then(_self.copyWith(deletionState: value));
  });
}
}

/// @nodoc


class RoutingEditorStateError implements RoutingEditorState {
  const RoutingEditorStateError(this.message);
  

 final  String message;

/// Create a copy of RoutingEditorState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RoutingEditorStateErrorCopyWith<RoutingEditorStateError> get copyWith => _$RoutingEditorStateErrorCopyWithImpl<RoutingEditorStateError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RoutingEditorStateError&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'RoutingEditorState.error(message: $message)';
}


}

/// @nodoc
abstract mixin class $RoutingEditorStateErrorCopyWith<$Res> implements $RoutingEditorStateCopyWith<$Res> {
  factory $RoutingEditorStateErrorCopyWith(RoutingEditorStateError value, $Res Function(RoutingEditorStateError) _then) = _$RoutingEditorStateErrorCopyWithImpl;
@useResult
$Res call({
 String message
});




}
/// @nodoc
class _$RoutingEditorStateErrorCopyWithImpl<$Res>
    implements $RoutingEditorStateErrorCopyWith<$Res> {
  _$RoutingEditorStateErrorCopyWithImpl(this._self, this._then);

  final RoutingEditorStateError _self;
  final $Res Function(RoutingEditorStateError) _then;

/// Create a copy of RoutingEditorState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(RoutingEditorStateError(
null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
