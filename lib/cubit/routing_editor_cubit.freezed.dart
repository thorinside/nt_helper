// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'routing_editor_cubit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Port implements DiagnosticableTreeMixin {

 String get id;// Unique identifier
 String get name;// Display name
 PortType get type; PortDirection get direction;
/// Create a copy of Port
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PortCopyWith<Port> get copyWith => _$PortCopyWithImpl<Port>(this as Port, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'Port'))
    ..add(DiagnosticsProperty('id', id))..add(DiagnosticsProperty('name', name))..add(DiagnosticsProperty('type', type))..add(DiagnosticsProperty('direction', direction));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Port&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.type, type) || other.type == type)&&(identical(other.direction, direction) || other.direction == direction));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,type,direction);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'Port(id: $id, name: $name, type: $type, direction: $direction)';
}


}

/// @nodoc
abstract mixin class $PortCopyWith<$Res>  {
  factory $PortCopyWith(Port value, $Res Function(Port) _then) = _$PortCopyWithImpl;
@useResult
$Res call({
 String id, String name, PortType type, PortDirection direction
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
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? type = null,Object? direction = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as PortType,direction: null == direction ? _self.direction : direction // ignore: cast_nullable_to_non_nullable
as PortDirection,
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  PortType type,  PortDirection direction)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Port() when $default != null:
return $default(_that.id,_that.name,_that.type,_that.direction);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  PortType type,  PortDirection direction)  $default,) {final _that = this;
switch (_that) {
case _Port():
return $default(_that.id,_that.name,_that.type,_that.direction);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  PortType type,  PortDirection direction)?  $default,) {final _that = this;
switch (_that) {
case _Port() when $default != null:
return $default(_that.id,_that.name,_that.type,_that.direction);case _:
  return null;

}
}

}

/// @nodoc


class _Port with DiagnosticableTreeMixin implements Port {
  const _Port({required this.id, required this.name, required this.type, required this.direction});
  

@override final  String id;
// Unique identifier
@override final  String name;
// Display name
@override final  PortType type;
@override final  PortDirection direction;

/// Create a copy of Port
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PortCopyWith<_Port> get copyWith => __$PortCopyWithImpl<_Port>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'Port'))
    ..add(DiagnosticsProperty('id', id))..add(DiagnosticsProperty('name', name))..add(DiagnosticsProperty('type', type))..add(DiagnosticsProperty('direction', direction));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Port&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.type, type) || other.type == type)&&(identical(other.direction, direction) || other.direction == direction));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,type,direction);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'Port(id: $id, name: $name, type: $type, direction: $direction)';
}


}

/// @nodoc
abstract mixin class _$PortCopyWith<$Res> implements $PortCopyWith<$Res> {
  factory _$PortCopyWith(_Port value, $Res Function(_Port) _then) = __$PortCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, PortType type, PortDirection direction
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
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? type = null,Object? direction = null,}) {
  return _then(_Port(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as PortType,direction: null == direction ? _self.direction : direction // ignore: cast_nullable_to_non_nullable
as PortDirection,
  ));
}


}

/// @nodoc
mixin _$Connection implements DiagnosticableTreeMixin {

 String get id; String get sourcePortId; String get targetPortId; String? get busId; OutputMode get outputMode; double get gain; bool get isMuted; bool get isGhostConnection; DateTime? get createdAt; DateTime? get modifiedAt;
/// Create a copy of Connection
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ConnectionCopyWith<Connection> get copyWith => _$ConnectionCopyWithImpl<Connection>(this as Connection, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'Connection'))
    ..add(DiagnosticsProperty('id', id))..add(DiagnosticsProperty('sourcePortId', sourcePortId))..add(DiagnosticsProperty('targetPortId', targetPortId))..add(DiagnosticsProperty('busId', busId))..add(DiagnosticsProperty('outputMode', outputMode))..add(DiagnosticsProperty('gain', gain))..add(DiagnosticsProperty('isMuted', isMuted))..add(DiagnosticsProperty('isGhostConnection', isGhostConnection))..add(DiagnosticsProperty('createdAt', createdAt))..add(DiagnosticsProperty('modifiedAt', modifiedAt));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Connection&&(identical(other.id, id) || other.id == id)&&(identical(other.sourcePortId, sourcePortId) || other.sourcePortId == sourcePortId)&&(identical(other.targetPortId, targetPortId) || other.targetPortId == targetPortId)&&(identical(other.busId, busId) || other.busId == busId)&&(identical(other.outputMode, outputMode) || other.outputMode == outputMode)&&(identical(other.gain, gain) || other.gain == gain)&&(identical(other.isMuted, isMuted) || other.isMuted == isMuted)&&(identical(other.isGhostConnection, isGhostConnection) || other.isGhostConnection == isGhostConnection)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.modifiedAt, modifiedAt) || other.modifiedAt == modifiedAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,sourcePortId,targetPortId,busId,outputMode,gain,isMuted,isGhostConnection,createdAt,modifiedAt);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'Connection(id: $id, sourcePortId: $sourcePortId, targetPortId: $targetPortId, busId: $busId, outputMode: $outputMode, gain: $gain, isMuted: $isMuted, isGhostConnection: $isGhostConnection, createdAt: $createdAt, modifiedAt: $modifiedAt)';
}


}

/// @nodoc
abstract mixin class $ConnectionCopyWith<$Res>  {
  factory $ConnectionCopyWith(Connection value, $Res Function(Connection) _then) = _$ConnectionCopyWithImpl;
@useResult
$Res call({
 String id, String sourcePortId, String targetPortId, String? busId, OutputMode outputMode, double gain, bool isMuted, bool isGhostConnection, DateTime? createdAt, DateTime? modifiedAt
});




}
/// @nodoc
class _$ConnectionCopyWithImpl<$Res>
    implements $ConnectionCopyWith<$Res> {
  _$ConnectionCopyWithImpl(this._self, this._then);

  final Connection _self;
  final $Res Function(Connection) _then;

/// Create a copy of Connection
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? sourcePortId = null,Object? targetPortId = null,Object? busId = freezed,Object? outputMode = null,Object? gain = null,Object? isMuted = null,Object? isGhostConnection = null,Object? createdAt = freezed,Object? modifiedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,sourcePortId: null == sourcePortId ? _self.sourcePortId : sourcePortId // ignore: cast_nullable_to_non_nullable
as String,targetPortId: null == targetPortId ? _self.targetPortId : targetPortId // ignore: cast_nullable_to_non_nullable
as String,busId: freezed == busId ? _self.busId : busId // ignore: cast_nullable_to_non_nullable
as String?,outputMode: null == outputMode ? _self.outputMode : outputMode // ignore: cast_nullable_to_non_nullable
as OutputMode,gain: null == gain ? _self.gain : gain // ignore: cast_nullable_to_non_nullable
as double,isMuted: null == isMuted ? _self.isMuted : isMuted // ignore: cast_nullable_to_non_nullable
as bool,isGhostConnection: null == isGhostConnection ? _self.isGhostConnection : isGhostConnection // ignore: cast_nullable_to_non_nullable
as bool,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,modifiedAt: freezed == modifiedAt ? _self.modifiedAt : modifiedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [Connection].
extension ConnectionPatterns on Connection {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Connection value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Connection() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Connection value)  $default,){
final _that = this;
switch (_that) {
case _Connection():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Connection value)?  $default,){
final _that = this;
switch (_that) {
case _Connection() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String sourcePortId,  String targetPortId,  String? busId,  OutputMode outputMode,  double gain,  bool isMuted,  bool isGhostConnection,  DateTime? createdAt,  DateTime? modifiedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Connection() when $default != null:
return $default(_that.id,_that.sourcePortId,_that.targetPortId,_that.busId,_that.outputMode,_that.gain,_that.isMuted,_that.isGhostConnection,_that.createdAt,_that.modifiedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String sourcePortId,  String targetPortId,  String? busId,  OutputMode outputMode,  double gain,  bool isMuted,  bool isGhostConnection,  DateTime? createdAt,  DateTime? modifiedAt)  $default,) {final _that = this;
switch (_that) {
case _Connection():
return $default(_that.id,_that.sourcePortId,_that.targetPortId,_that.busId,_that.outputMode,_that.gain,_that.isMuted,_that.isGhostConnection,_that.createdAt,_that.modifiedAt);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String sourcePortId,  String targetPortId,  String? busId,  OutputMode outputMode,  double gain,  bool isMuted,  bool isGhostConnection,  DateTime? createdAt,  DateTime? modifiedAt)?  $default,) {final _that = this;
switch (_that) {
case _Connection() when $default != null:
return $default(_that.id,_that.sourcePortId,_that.targetPortId,_that.busId,_that.outputMode,_that.gain,_that.isMuted,_that.isGhostConnection,_that.createdAt,_that.modifiedAt);case _:
  return null;

}
}

}

/// @nodoc


class _Connection with DiagnosticableTreeMixin implements Connection {
  const _Connection({required this.id, required this.sourcePortId, required this.targetPortId, this.busId, this.outputMode = OutputMode.replace, this.gain = 1.0, this.isMuted = false, this.isGhostConnection = false, this.createdAt, this.modifiedAt});
  

@override final  String id;
@override final  String sourcePortId;
@override final  String targetPortId;
@override final  String? busId;
@override@JsonKey() final  OutputMode outputMode;
@override@JsonKey() final  double gain;
@override@JsonKey() final  bool isMuted;
@override@JsonKey() final  bool isGhostConnection;
@override final  DateTime? createdAt;
@override final  DateTime? modifiedAt;

/// Create a copy of Connection
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ConnectionCopyWith<_Connection> get copyWith => __$ConnectionCopyWithImpl<_Connection>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'Connection'))
    ..add(DiagnosticsProperty('id', id))..add(DiagnosticsProperty('sourcePortId', sourcePortId))..add(DiagnosticsProperty('targetPortId', targetPortId))..add(DiagnosticsProperty('busId', busId))..add(DiagnosticsProperty('outputMode', outputMode))..add(DiagnosticsProperty('gain', gain))..add(DiagnosticsProperty('isMuted', isMuted))..add(DiagnosticsProperty('isGhostConnection', isGhostConnection))..add(DiagnosticsProperty('createdAt', createdAt))..add(DiagnosticsProperty('modifiedAt', modifiedAt));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Connection&&(identical(other.id, id) || other.id == id)&&(identical(other.sourcePortId, sourcePortId) || other.sourcePortId == sourcePortId)&&(identical(other.targetPortId, targetPortId) || other.targetPortId == targetPortId)&&(identical(other.busId, busId) || other.busId == busId)&&(identical(other.outputMode, outputMode) || other.outputMode == outputMode)&&(identical(other.gain, gain) || other.gain == gain)&&(identical(other.isMuted, isMuted) || other.isMuted == isMuted)&&(identical(other.isGhostConnection, isGhostConnection) || other.isGhostConnection == isGhostConnection)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.modifiedAt, modifiedAt) || other.modifiedAt == modifiedAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,sourcePortId,targetPortId,busId,outputMode,gain,isMuted,isGhostConnection,createdAt,modifiedAt);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'Connection(id: $id, sourcePortId: $sourcePortId, targetPortId: $targetPortId, busId: $busId, outputMode: $outputMode, gain: $gain, isMuted: $isMuted, isGhostConnection: $isGhostConnection, createdAt: $createdAt, modifiedAt: $modifiedAt)';
}


}

/// @nodoc
abstract mixin class _$ConnectionCopyWith<$Res> implements $ConnectionCopyWith<$Res> {
  factory _$ConnectionCopyWith(_Connection value, $Res Function(_Connection) _then) = __$ConnectionCopyWithImpl;
@override @useResult
$Res call({
 String id, String sourcePortId, String targetPortId, String? busId, OutputMode outputMode, double gain, bool isMuted, bool isGhostConnection, DateTime? createdAt, DateTime? modifiedAt
});




}
/// @nodoc
class __$ConnectionCopyWithImpl<$Res>
    implements _$ConnectionCopyWith<$Res> {
  __$ConnectionCopyWithImpl(this._self, this._then);

  final _Connection _self;
  final $Res Function(_Connection) _then;

/// Create a copy of Connection
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? sourcePortId = null,Object? targetPortId = null,Object? busId = freezed,Object? outputMode = null,Object? gain = null,Object? isMuted = null,Object? isGhostConnection = null,Object? createdAt = freezed,Object? modifiedAt = freezed,}) {
  return _then(_Connection(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,sourcePortId: null == sourcePortId ? _self.sourcePortId : sourcePortId // ignore: cast_nullable_to_non_nullable
as String,targetPortId: null == targetPortId ? _self.targetPortId : targetPortId // ignore: cast_nullable_to_non_nullable
as String,busId: freezed == busId ? _self.busId : busId // ignore: cast_nullable_to_non_nullable
as String?,outputMode: null == outputMode ? _self.outputMode : outputMode // ignore: cast_nullable_to_non_nullable
as OutputMode,gain: null == gain ? _self.gain : gain // ignore: cast_nullable_to_non_nullable
as double,isMuted: null == isMuted ? _self.isMuted : isMuted // ignore: cast_nullable_to_non_nullable
as bool,isGhostConnection: null == isGhostConnection ? _self.isGhostConnection : isGhostConnection // ignore: cast_nullable_to_non_nullable
as bool,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,modifiedAt: freezed == modifiedAt ? _self.modifiedAt : modifiedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

/// @nodoc
mixin _$RoutingBus implements DiagnosticableTreeMixin {

 String get id; String get name; BusStatus get status; List<String> get connectionIds; OutputMode get defaultOutputMode; double get masterGain; DateTime? get createdAt; DateTime? get modifiedAt;
/// Create a copy of RoutingBus
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RoutingBusCopyWith<RoutingBus> get copyWith => _$RoutingBusCopyWithImpl<RoutingBus>(this as RoutingBus, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'RoutingBus'))
    ..add(DiagnosticsProperty('id', id))..add(DiagnosticsProperty('name', name))..add(DiagnosticsProperty('status', status))..add(DiagnosticsProperty('connectionIds', connectionIds))..add(DiagnosticsProperty('defaultOutputMode', defaultOutputMode))..add(DiagnosticsProperty('masterGain', masterGain))..add(DiagnosticsProperty('createdAt', createdAt))..add(DiagnosticsProperty('modifiedAt', modifiedAt));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RoutingBus&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other.connectionIds, connectionIds)&&(identical(other.defaultOutputMode, defaultOutputMode) || other.defaultOutputMode == defaultOutputMode)&&(identical(other.masterGain, masterGain) || other.masterGain == masterGain)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.modifiedAt, modifiedAt) || other.modifiedAt == modifiedAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,status,const DeepCollectionEquality().hash(connectionIds),defaultOutputMode,masterGain,createdAt,modifiedAt);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'RoutingBus(id: $id, name: $name, status: $status, connectionIds: $connectionIds, defaultOutputMode: $defaultOutputMode, masterGain: $masterGain, createdAt: $createdAt, modifiedAt: $modifiedAt)';
}


}

/// @nodoc
abstract mixin class $RoutingBusCopyWith<$Res>  {
  factory $RoutingBusCopyWith(RoutingBus value, $Res Function(RoutingBus) _then) = _$RoutingBusCopyWithImpl;
@useResult
$Res call({
 String id, String name, BusStatus status, List<String> connectionIds, OutputMode defaultOutputMode, double masterGain, DateTime? createdAt, DateTime? modifiedAt
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
as OutputMode,masterGain: null == masterGain ? _self.masterGain : masterGain // ignore: cast_nullable_to_non_nullable
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  BusStatus status,  List<String> connectionIds,  OutputMode defaultOutputMode,  double masterGain,  DateTime? createdAt,  DateTime? modifiedAt)?  $default,{required TResult orElse(),}) {final _that = this;
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  BusStatus status,  List<String> connectionIds,  OutputMode defaultOutputMode,  double masterGain,  DateTime? createdAt,  DateTime? modifiedAt)  $default,) {final _that = this;
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  BusStatus status,  List<String> connectionIds,  OutputMode defaultOutputMode,  double masterGain,  DateTime? createdAt,  DateTime? modifiedAt)?  $default,) {final _that = this;
switch (_that) {
case _RoutingBus() when $default != null:
return $default(_that.id,_that.name,_that.status,_that.connectionIds,_that.defaultOutputMode,_that.masterGain,_that.createdAt,_that.modifiedAt);case _:
  return null;

}
}

}

/// @nodoc


class _RoutingBus with DiagnosticableTreeMixin implements RoutingBus {
  const _RoutingBus({required this.id, required this.name, required this.status, final  List<String> connectionIds = const [], this.defaultOutputMode = OutputMode.replace, this.masterGain = 1.0, this.createdAt, this.modifiedAt}): _connectionIds = connectionIds;
  

@override final  String id;
@override final  String name;
@override final  BusStatus status;
 final  List<String> _connectionIds;
@override@JsonKey() List<String> get connectionIds {
  if (_connectionIds is EqualUnmodifiableListView) return _connectionIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_connectionIds);
}

@override@JsonKey() final  OutputMode defaultOutputMode;
@override@JsonKey() final  double masterGain;
@override final  DateTime? createdAt;
@override final  DateTime? modifiedAt;

/// Create a copy of RoutingBus
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RoutingBusCopyWith<_RoutingBus> get copyWith => __$RoutingBusCopyWithImpl<_RoutingBus>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'RoutingBus'))
    ..add(DiagnosticsProperty('id', id))..add(DiagnosticsProperty('name', name))..add(DiagnosticsProperty('status', status))..add(DiagnosticsProperty('connectionIds', connectionIds))..add(DiagnosticsProperty('defaultOutputMode', defaultOutputMode))..add(DiagnosticsProperty('masterGain', masterGain))..add(DiagnosticsProperty('createdAt', createdAt))..add(DiagnosticsProperty('modifiedAt', modifiedAt));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RoutingBus&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other._connectionIds, _connectionIds)&&(identical(other.defaultOutputMode, defaultOutputMode) || other.defaultOutputMode == defaultOutputMode)&&(identical(other.masterGain, masterGain) || other.masterGain == masterGain)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.modifiedAt, modifiedAt) || other.modifiedAt == modifiedAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,status,const DeepCollectionEquality().hash(_connectionIds),defaultOutputMode,masterGain,createdAt,modifiedAt);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'RoutingBus(id: $id, name: $name, status: $status, connectionIds: $connectionIds, defaultOutputMode: $defaultOutputMode, masterGain: $masterGain, createdAt: $createdAt, modifiedAt: $modifiedAt)';
}


}

/// @nodoc
abstract mixin class _$RoutingBusCopyWith<$Res> implements $RoutingBusCopyWith<$Res> {
  factory _$RoutingBusCopyWith(_RoutingBus value, $Res Function(_RoutingBus) _then) = __$RoutingBusCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, BusStatus status, List<String> connectionIds, OutputMode defaultOutputMode, double masterGain, DateTime? createdAt, DateTime? modifiedAt
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
as OutputMode,masterGain: null == masterGain ? _self.masterGain : masterGain // ignore: cast_nullable_to_non_nullable
as double,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,modifiedAt: freezed == modifiedAt ? _self.modifiedAt : modifiedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

/// @nodoc
mixin _$RoutingAlgorithm implements DiagnosticableTreeMixin {

 int get index; Algorithm get algorithm; List<Port> get inputPorts; List<Port> get outputPorts;
/// Create a copy of RoutingAlgorithm
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RoutingAlgorithmCopyWith<RoutingAlgorithm> get copyWith => _$RoutingAlgorithmCopyWithImpl<RoutingAlgorithm>(this as RoutingAlgorithm, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'RoutingAlgorithm'))
    ..add(DiagnosticsProperty('index', index))..add(DiagnosticsProperty('algorithm', algorithm))..add(DiagnosticsProperty('inputPorts', inputPorts))..add(DiagnosticsProperty('outputPorts', outputPorts));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RoutingAlgorithm&&(identical(other.index, index) || other.index == index)&&(identical(other.algorithm, algorithm) || other.algorithm == algorithm)&&const DeepCollectionEquality().equals(other.inputPorts, inputPorts)&&const DeepCollectionEquality().equals(other.outputPorts, outputPorts));
}


@override
int get hashCode => Object.hash(runtimeType,index,algorithm,const DeepCollectionEquality().hash(inputPorts),const DeepCollectionEquality().hash(outputPorts));

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'RoutingAlgorithm(index: $index, algorithm: $algorithm, inputPorts: $inputPorts, outputPorts: $outputPorts)';
}


}

/// @nodoc
abstract mixin class $RoutingAlgorithmCopyWith<$Res>  {
  factory $RoutingAlgorithmCopyWith(RoutingAlgorithm value, $Res Function(RoutingAlgorithm) _then) = _$RoutingAlgorithmCopyWithImpl;
@useResult
$Res call({
 int index, Algorithm algorithm, List<Port> inputPorts, List<Port> outputPorts
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
@pragma('vm:prefer-inline') @override $Res call({Object? index = null,Object? algorithm = null,Object? inputPorts = null,Object? outputPorts = null,}) {
  return _then(_self.copyWith(
index: null == index ? _self.index : index // ignore: cast_nullable_to_non_nullable
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int index,  Algorithm algorithm,  List<Port> inputPorts,  List<Port> outputPorts)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RoutingAlgorithm() when $default != null:
return $default(_that.index,_that.algorithm,_that.inputPorts,_that.outputPorts);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int index,  Algorithm algorithm,  List<Port> inputPorts,  List<Port> outputPorts)  $default,) {final _that = this;
switch (_that) {
case _RoutingAlgorithm():
return $default(_that.index,_that.algorithm,_that.inputPorts,_that.outputPorts);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int index,  Algorithm algorithm,  List<Port> inputPorts,  List<Port> outputPorts)?  $default,) {final _that = this;
switch (_that) {
case _RoutingAlgorithm() when $default != null:
return $default(_that.index,_that.algorithm,_that.inputPorts,_that.outputPorts);case _:
  return null;

}
}

}

/// @nodoc


class _RoutingAlgorithm with DiagnosticableTreeMixin implements RoutingAlgorithm {
  const _RoutingAlgorithm({required this.index, required this.algorithm, required final  List<Port> inputPorts, required final  List<Port> outputPorts}): _inputPorts = inputPorts,_outputPorts = outputPorts;
  

@override final  int index;
@override final  Algorithm algorithm;
 final  List<Port> _inputPorts;
@override List<Port> get inputPorts {
  if (_inputPorts is EqualUnmodifiableListView) return _inputPorts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_inputPorts);
}

 final  List<Port> _outputPorts;
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
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'RoutingAlgorithm'))
    ..add(DiagnosticsProperty('index', index))..add(DiagnosticsProperty('algorithm', algorithm))..add(DiagnosticsProperty('inputPorts', inputPorts))..add(DiagnosticsProperty('outputPorts', outputPorts));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RoutingAlgorithm&&(identical(other.index, index) || other.index == index)&&(identical(other.algorithm, algorithm) || other.algorithm == algorithm)&&const DeepCollectionEquality().equals(other._inputPorts, _inputPorts)&&const DeepCollectionEquality().equals(other._outputPorts, _outputPorts));
}


@override
int get hashCode => Object.hash(runtimeType,index,algorithm,const DeepCollectionEquality().hash(_inputPorts),const DeepCollectionEquality().hash(_outputPorts));

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'RoutingAlgorithm(index: $index, algorithm: $algorithm, inputPorts: $inputPorts, outputPorts: $outputPorts)';
}


}

/// @nodoc
abstract mixin class _$RoutingAlgorithmCopyWith<$Res> implements $RoutingAlgorithmCopyWith<$Res> {
  factory _$RoutingAlgorithmCopyWith(_RoutingAlgorithm value, $Res Function(_RoutingAlgorithm) _then) = __$RoutingAlgorithmCopyWithImpl;
@override @useResult
$Res call({
 int index, Algorithm algorithm, List<Port> inputPorts, List<Port> outputPorts
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
@override @pragma('vm:prefer-inline') $Res call({Object? index = null,Object? algorithm = null,Object? inputPorts = null,Object? outputPorts = null,}) {
  return _then(_RoutingAlgorithm(
index: null == index ? _self.index : index // ignore: cast_nullable_to_non_nullable
as int,algorithm: null == algorithm ? _self.algorithm : algorithm // ignore: cast_nullable_to_non_nullable
as Algorithm,inputPorts: null == inputPorts ? _self._inputPorts : inputPorts // ignore: cast_nullable_to_non_nullable
as List<Port>,outputPorts: null == outputPorts ? _self._outputPorts : outputPorts // ignore: cast_nullable_to_non_nullable
as List<Port>,
  ));
}


}

/// @nodoc
mixin _$RoutingEditorState implements DiagnosticableTreeMixin {




@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'RoutingEditorState'))
    ;
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RoutingEditorState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function()?  disconnected,TResult Function()?  connecting,TResult Function()?  refreshing,TResult Function()?  persisting,TResult Function()?  syncing,TResult Function( List<Port> physicalInputs,  List<Port> physicalOutputs,  List<RoutingAlgorithm> algorithms,  List<Connection> connections,  List<PhysicalConnection> physicalConnections,  List<RoutingBus> buses,  Map<String, OutputMode> portOutputModes,  bool isHardwareSynced,  bool isPersistenceEnabled,  DateTime? lastSyncTime,  DateTime? lastPersistTime,  String? lastError)?  loaded,TResult Function( String message)?  error,required TResult orElse(),}) {final _that = this;
switch (_that) {
case RoutingEditorStateInitial() when initial != null:
return initial();case RoutingEditorStateDisconnected() when disconnected != null:
return disconnected();case RoutingEditorStateConnecting() when connecting != null:
return connecting();case RoutingEditorStateRefreshing() when refreshing != null:
return refreshing();case RoutingEditorStatePersisting() when persisting != null:
return persisting();case RoutingEditorStateSyncing() when syncing != null:
return syncing();case RoutingEditorStateLoaded() when loaded != null:
return loaded(_that.physicalInputs,_that.physicalOutputs,_that.algorithms,_that.connections,_that.physicalConnections,_that.buses,_that.portOutputModes,_that.isHardwareSynced,_that.isPersistenceEnabled,_that.lastSyncTime,_that.lastPersistTime,_that.lastError);case RoutingEditorStateError() when error != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function()  disconnected,required TResult Function()  connecting,required TResult Function()  refreshing,required TResult Function()  persisting,required TResult Function()  syncing,required TResult Function( List<Port> physicalInputs,  List<Port> physicalOutputs,  List<RoutingAlgorithm> algorithms,  List<Connection> connections,  List<PhysicalConnection> physicalConnections,  List<RoutingBus> buses,  Map<String, OutputMode> portOutputModes,  bool isHardwareSynced,  bool isPersistenceEnabled,  DateTime? lastSyncTime,  DateTime? lastPersistTime,  String? lastError)  loaded,required TResult Function( String message)  error,}) {final _that = this;
switch (_that) {
case RoutingEditorStateInitial():
return initial();case RoutingEditorStateDisconnected():
return disconnected();case RoutingEditorStateConnecting():
return connecting();case RoutingEditorStateRefreshing():
return refreshing();case RoutingEditorStatePersisting():
return persisting();case RoutingEditorStateSyncing():
return syncing();case RoutingEditorStateLoaded():
return loaded(_that.physicalInputs,_that.physicalOutputs,_that.algorithms,_that.connections,_that.physicalConnections,_that.buses,_that.portOutputModes,_that.isHardwareSynced,_that.isPersistenceEnabled,_that.lastSyncTime,_that.lastPersistTime,_that.lastError);case RoutingEditorStateError():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function()?  disconnected,TResult? Function()?  connecting,TResult? Function()?  refreshing,TResult? Function()?  persisting,TResult? Function()?  syncing,TResult? Function( List<Port> physicalInputs,  List<Port> physicalOutputs,  List<RoutingAlgorithm> algorithms,  List<Connection> connections,  List<PhysicalConnection> physicalConnections,  List<RoutingBus> buses,  Map<String, OutputMode> portOutputModes,  bool isHardwareSynced,  bool isPersistenceEnabled,  DateTime? lastSyncTime,  DateTime? lastPersistTime,  String? lastError)?  loaded,TResult? Function( String message)?  error,}) {final _that = this;
switch (_that) {
case RoutingEditorStateInitial() when initial != null:
return initial();case RoutingEditorStateDisconnected() when disconnected != null:
return disconnected();case RoutingEditorStateConnecting() when connecting != null:
return connecting();case RoutingEditorStateRefreshing() when refreshing != null:
return refreshing();case RoutingEditorStatePersisting() when persisting != null:
return persisting();case RoutingEditorStateSyncing() when syncing != null:
return syncing();case RoutingEditorStateLoaded() when loaded != null:
return loaded(_that.physicalInputs,_that.physicalOutputs,_that.algorithms,_that.connections,_that.physicalConnections,_that.buses,_that.portOutputModes,_that.isHardwareSynced,_that.isPersistenceEnabled,_that.lastSyncTime,_that.lastPersistTime,_that.lastError);case RoutingEditorStateError() when error != null:
return error(_that.message);case _:
  return null;

}
}

}

/// @nodoc


class RoutingEditorStateInitial with DiagnosticableTreeMixin implements RoutingEditorState {
  const RoutingEditorStateInitial();
  





@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'RoutingEditorState.initial'))
    ;
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RoutingEditorStateInitial);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'RoutingEditorState.initial()';
}


}




/// @nodoc


class RoutingEditorStateDisconnected with DiagnosticableTreeMixin implements RoutingEditorState {
  const RoutingEditorStateDisconnected();
  





@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'RoutingEditorState.disconnected'))
    ;
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RoutingEditorStateDisconnected);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'RoutingEditorState.disconnected()';
}


}




/// @nodoc


class RoutingEditorStateConnecting with DiagnosticableTreeMixin implements RoutingEditorState {
  const RoutingEditorStateConnecting();
  





@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'RoutingEditorState.connecting'))
    ;
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RoutingEditorStateConnecting);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'RoutingEditorState.connecting()';
}


}




/// @nodoc


class RoutingEditorStateRefreshing with DiagnosticableTreeMixin implements RoutingEditorState {
  const RoutingEditorStateRefreshing();
  





@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'RoutingEditorState.refreshing'))
    ;
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RoutingEditorStateRefreshing);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'RoutingEditorState.refreshing()';
}


}




/// @nodoc


class RoutingEditorStatePersisting with DiagnosticableTreeMixin implements RoutingEditorState {
  const RoutingEditorStatePersisting();
  





@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'RoutingEditorState.persisting'))
    ;
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RoutingEditorStatePersisting);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'RoutingEditorState.persisting()';
}


}




/// @nodoc


class RoutingEditorStateSyncing with DiagnosticableTreeMixin implements RoutingEditorState {
  const RoutingEditorStateSyncing();
  





@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'RoutingEditorState.syncing'))
    ;
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RoutingEditorStateSyncing);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'RoutingEditorState.syncing()';
}


}




/// @nodoc


class RoutingEditorStateLoaded with DiagnosticableTreeMixin implements RoutingEditorState {
  const RoutingEditorStateLoaded({required final  List<Port> physicalInputs, required final  List<Port> physicalOutputs, required final  List<RoutingAlgorithm> algorithms, required final  List<Connection> connections, final  List<PhysicalConnection> physicalConnections = const [], final  List<RoutingBus> buses = const [], final  Map<String, OutputMode> portOutputModes = const {}, this.isHardwareSynced = false, this.isPersistenceEnabled = false, this.lastSyncTime, this.lastPersistTime, this.lastError}): _physicalInputs = physicalInputs,_physicalOutputs = physicalOutputs,_algorithms = algorithms,_connections = connections,_physicalConnections = physicalConnections,_buses = buses,_portOutputModes = portOutputModes;
  

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
 final  List<PhysicalConnection> _physicalConnections;
// All routing connections
@JsonKey() List<PhysicalConnection> get physicalConnections {
  if (_physicalConnections is EqualUnmodifiableListView) return _physicalConnections;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_physicalConnections);
}

// Discovered physical connections
 final  List<RoutingBus> _buses;
// Discovered physical connections
@JsonKey() List<RoutingBus> get buses {
  if (_buses is EqualUnmodifiableListView) return _buses;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_buses);
}

// Available routing buses
 final  Map<String, OutputMode> _portOutputModes;
// Available routing buses
@JsonKey() Map<String, OutputMode> get portOutputModes {
  if (_portOutputModes is EqualUnmodifiableMapView) return _portOutputModes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_portOutputModes);
}

// Output modes per port
@JsonKey() final  bool isHardwareSynced;
// Hardware sync status
@JsonKey() final  bool isPersistenceEnabled;
// State persistence status
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
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'RoutingEditorState.loaded'))
    ..add(DiagnosticsProperty('physicalInputs', physicalInputs))..add(DiagnosticsProperty('physicalOutputs', physicalOutputs))..add(DiagnosticsProperty('algorithms', algorithms))..add(DiagnosticsProperty('connections', connections))..add(DiagnosticsProperty('physicalConnections', physicalConnections))..add(DiagnosticsProperty('buses', buses))..add(DiagnosticsProperty('portOutputModes', portOutputModes))..add(DiagnosticsProperty('isHardwareSynced', isHardwareSynced))..add(DiagnosticsProperty('isPersistenceEnabled', isPersistenceEnabled))..add(DiagnosticsProperty('lastSyncTime', lastSyncTime))..add(DiagnosticsProperty('lastPersistTime', lastPersistTime))..add(DiagnosticsProperty('lastError', lastError));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RoutingEditorStateLoaded&&const DeepCollectionEquality().equals(other._physicalInputs, _physicalInputs)&&const DeepCollectionEquality().equals(other._physicalOutputs, _physicalOutputs)&&const DeepCollectionEquality().equals(other._algorithms, _algorithms)&&const DeepCollectionEquality().equals(other._connections, _connections)&&const DeepCollectionEquality().equals(other._physicalConnections, _physicalConnections)&&const DeepCollectionEquality().equals(other._buses, _buses)&&const DeepCollectionEquality().equals(other._portOutputModes, _portOutputModes)&&(identical(other.isHardwareSynced, isHardwareSynced) || other.isHardwareSynced == isHardwareSynced)&&(identical(other.isPersistenceEnabled, isPersistenceEnabled) || other.isPersistenceEnabled == isPersistenceEnabled)&&(identical(other.lastSyncTime, lastSyncTime) || other.lastSyncTime == lastSyncTime)&&(identical(other.lastPersistTime, lastPersistTime) || other.lastPersistTime == lastPersistTime)&&(identical(other.lastError, lastError) || other.lastError == lastError));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_physicalInputs),const DeepCollectionEquality().hash(_physicalOutputs),const DeepCollectionEquality().hash(_algorithms),const DeepCollectionEquality().hash(_connections),const DeepCollectionEquality().hash(_physicalConnections),const DeepCollectionEquality().hash(_buses),const DeepCollectionEquality().hash(_portOutputModes),isHardwareSynced,isPersistenceEnabled,lastSyncTime,lastPersistTime,lastError);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'RoutingEditorState.loaded(physicalInputs: $physicalInputs, physicalOutputs: $physicalOutputs, algorithms: $algorithms, connections: $connections, physicalConnections: $physicalConnections, buses: $buses, portOutputModes: $portOutputModes, isHardwareSynced: $isHardwareSynced, isPersistenceEnabled: $isPersistenceEnabled, lastSyncTime: $lastSyncTime, lastPersistTime: $lastPersistTime, lastError: $lastError)';
}


}

/// @nodoc
abstract mixin class $RoutingEditorStateLoadedCopyWith<$Res> implements $RoutingEditorStateCopyWith<$Res> {
  factory $RoutingEditorStateLoadedCopyWith(RoutingEditorStateLoaded value, $Res Function(RoutingEditorStateLoaded) _then) = _$RoutingEditorStateLoadedCopyWithImpl;
@useResult
$Res call({
 List<Port> physicalInputs, List<Port> physicalOutputs, List<RoutingAlgorithm> algorithms, List<Connection> connections, List<PhysicalConnection> physicalConnections, List<RoutingBus> buses, Map<String, OutputMode> portOutputModes, bool isHardwareSynced, bool isPersistenceEnabled, DateTime? lastSyncTime, DateTime? lastPersistTime, String? lastError
});




}
/// @nodoc
class _$RoutingEditorStateLoadedCopyWithImpl<$Res>
    implements $RoutingEditorStateLoadedCopyWith<$Res> {
  _$RoutingEditorStateLoadedCopyWithImpl(this._self, this._then);

  final RoutingEditorStateLoaded _self;
  final $Res Function(RoutingEditorStateLoaded) _then;

/// Create a copy of RoutingEditorState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? physicalInputs = null,Object? physicalOutputs = null,Object? algorithms = null,Object? connections = null,Object? physicalConnections = null,Object? buses = null,Object? portOutputModes = null,Object? isHardwareSynced = null,Object? isPersistenceEnabled = null,Object? lastSyncTime = freezed,Object? lastPersistTime = freezed,Object? lastError = freezed,}) {
  return _then(RoutingEditorStateLoaded(
physicalInputs: null == physicalInputs ? _self._physicalInputs : physicalInputs // ignore: cast_nullable_to_non_nullable
as List<Port>,physicalOutputs: null == physicalOutputs ? _self._physicalOutputs : physicalOutputs // ignore: cast_nullable_to_non_nullable
as List<Port>,algorithms: null == algorithms ? _self._algorithms : algorithms // ignore: cast_nullable_to_non_nullable
as List<RoutingAlgorithm>,connections: null == connections ? _self._connections : connections // ignore: cast_nullable_to_non_nullable
as List<Connection>,physicalConnections: null == physicalConnections ? _self._physicalConnections : physicalConnections // ignore: cast_nullable_to_non_nullable
as List<PhysicalConnection>,buses: null == buses ? _self._buses : buses // ignore: cast_nullable_to_non_nullable
as List<RoutingBus>,portOutputModes: null == portOutputModes ? _self._portOutputModes : portOutputModes // ignore: cast_nullable_to_non_nullable
as Map<String, OutputMode>,isHardwareSynced: null == isHardwareSynced ? _self.isHardwareSynced : isHardwareSynced // ignore: cast_nullable_to_non_nullable
as bool,isPersistenceEnabled: null == isPersistenceEnabled ? _self.isPersistenceEnabled : isPersistenceEnabled // ignore: cast_nullable_to_non_nullable
as bool,lastSyncTime: freezed == lastSyncTime ? _self.lastSyncTime : lastSyncTime // ignore: cast_nullable_to_non_nullable
as DateTime?,lastPersistTime: freezed == lastPersistTime ? _self.lastPersistTime : lastPersistTime // ignore: cast_nullable_to_non_nullable
as DateTime?,lastError: freezed == lastError ? _self.lastError : lastError // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc


class RoutingEditorStateError with DiagnosticableTreeMixin implements RoutingEditorState {
  const RoutingEditorStateError(this.message);
  

 final  String message;

/// Create a copy of RoutingEditorState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RoutingEditorStateErrorCopyWith<RoutingEditorStateError> get copyWith => _$RoutingEditorStateErrorCopyWithImpl<RoutingEditorStateError>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'RoutingEditorState.error'))
    ..add(DiagnosticsProperty('message', message));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RoutingEditorStateError&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
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
