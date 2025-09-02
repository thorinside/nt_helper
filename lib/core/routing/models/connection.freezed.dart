// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'connection.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Connection {

/// Unique identifier for this connection
 String get id;/// ID of the source port
 String get sourcePortId;/// ID of the destination port
 String get destinationPortId;/// Current status of the connection
 ConnectionStatus get status;/// Optional name for the connection
 String? get name;/// Optional description of what this connection does
 String? get description;/// Signal gain/attenuation factor (1.0 = no change)
 double get gain;/// Whether the connection is muted
 bool get isMuted;/// Whether the connection is inverted
 bool get isInverted;/// Optional delay in milliseconds
 double get delayMs;/// Additional connection properties
 Map<String, dynamic>? get properties;/// Timestamp when the connection was created
 DateTime? get createdAt;/// Timestamp when the connection was last modified
 DateTime? get modifiedAt;
/// Create a copy of Connection
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ConnectionCopyWith<Connection> get copyWith => _$ConnectionCopyWithImpl<Connection>(this as Connection, _$identity);

  /// Serializes this Connection to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Connection&&(identical(other.id, id) || other.id == id)&&(identical(other.sourcePortId, sourcePortId) || other.sourcePortId == sourcePortId)&&(identical(other.destinationPortId, destinationPortId) || other.destinationPortId == destinationPortId)&&(identical(other.status, status) || other.status == status)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.gain, gain) || other.gain == gain)&&(identical(other.isMuted, isMuted) || other.isMuted == isMuted)&&(identical(other.isInverted, isInverted) || other.isInverted == isInverted)&&(identical(other.delayMs, delayMs) || other.delayMs == delayMs)&&const DeepCollectionEquality().equals(other.properties, properties)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.modifiedAt, modifiedAt) || other.modifiedAt == modifiedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,sourcePortId,destinationPortId,status,name,description,gain,isMuted,isInverted,delayMs,const DeepCollectionEquality().hash(properties),createdAt,modifiedAt);

@override
String toString() {
  return 'Connection(id: $id, sourcePortId: $sourcePortId, destinationPortId: $destinationPortId, status: $status, name: $name, description: $description, gain: $gain, isMuted: $isMuted, isInverted: $isInverted, delayMs: $delayMs, properties: $properties, createdAt: $createdAt, modifiedAt: $modifiedAt)';
}


}

/// @nodoc
abstract mixin class $ConnectionCopyWith<$Res>  {
  factory $ConnectionCopyWith(Connection value, $Res Function(Connection) _then) = _$ConnectionCopyWithImpl;
@useResult
$Res call({
 String id, String sourcePortId, String destinationPortId, ConnectionStatus status, String? name, String? description, double gain, bool isMuted, bool isInverted, double delayMs, Map<String, dynamic>? properties, DateTime? createdAt, DateTime? modifiedAt
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
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? sourcePortId = null,Object? destinationPortId = null,Object? status = null,Object? name = freezed,Object? description = freezed,Object? gain = null,Object? isMuted = null,Object? isInverted = null,Object? delayMs = null,Object? properties = freezed,Object? createdAt = freezed,Object? modifiedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,sourcePortId: null == sourcePortId ? _self.sourcePortId : sourcePortId // ignore: cast_nullable_to_non_nullable
as String,destinationPortId: null == destinationPortId ? _self.destinationPortId : destinationPortId // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ConnectionStatus,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,gain: null == gain ? _self.gain : gain // ignore: cast_nullable_to_non_nullable
as double,isMuted: null == isMuted ? _self.isMuted : isMuted // ignore: cast_nullable_to_non_nullable
as bool,isInverted: null == isInverted ? _self.isInverted : isInverted // ignore: cast_nullable_to_non_nullable
as bool,delayMs: null == delayMs ? _self.delayMs : delayMs // ignore: cast_nullable_to_non_nullable
as double,properties: freezed == properties ? _self.properties : properties // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String sourcePortId,  String destinationPortId,  ConnectionStatus status,  String? name,  String? description,  double gain,  bool isMuted,  bool isInverted,  double delayMs,  Map<String, dynamic>? properties,  DateTime? createdAt,  DateTime? modifiedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Connection() when $default != null:
return $default(_that.id,_that.sourcePortId,_that.destinationPortId,_that.status,_that.name,_that.description,_that.gain,_that.isMuted,_that.isInverted,_that.delayMs,_that.properties,_that.createdAt,_that.modifiedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String sourcePortId,  String destinationPortId,  ConnectionStatus status,  String? name,  String? description,  double gain,  bool isMuted,  bool isInverted,  double delayMs,  Map<String, dynamic>? properties,  DateTime? createdAt,  DateTime? modifiedAt)  $default,) {final _that = this;
switch (_that) {
case _Connection():
return $default(_that.id,_that.sourcePortId,_that.destinationPortId,_that.status,_that.name,_that.description,_that.gain,_that.isMuted,_that.isInverted,_that.delayMs,_that.properties,_that.createdAt,_that.modifiedAt);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String sourcePortId,  String destinationPortId,  ConnectionStatus status,  String? name,  String? description,  double gain,  bool isMuted,  bool isInverted,  double delayMs,  Map<String, dynamic>? properties,  DateTime? createdAt,  DateTime? modifiedAt)?  $default,) {final _that = this;
switch (_that) {
case _Connection() when $default != null:
return $default(_that.id,_that.sourcePortId,_that.destinationPortId,_that.status,_that.name,_that.description,_that.gain,_that.isMuted,_that.isInverted,_that.delayMs,_that.properties,_that.createdAt,_that.modifiedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Connection extends Connection {
  const _Connection({required this.id, required this.sourcePortId, required this.destinationPortId, this.status = ConnectionStatus.active, this.name, this.description, this.gain = 1.0, this.isMuted = false, this.isInverted = false, this.delayMs = 0.0, final  Map<String, dynamic>? properties, this.createdAt, this.modifiedAt}): _properties = properties,super._();
  factory _Connection.fromJson(Map<String, dynamic> json) => _$ConnectionFromJson(json);

/// Unique identifier for this connection
@override final  String id;
/// ID of the source port
@override final  String sourcePortId;
/// ID of the destination port
@override final  String destinationPortId;
/// Current status of the connection
@override@JsonKey() final  ConnectionStatus status;
/// Optional name for the connection
@override final  String? name;
/// Optional description of what this connection does
@override final  String? description;
/// Signal gain/attenuation factor (1.0 = no change)
@override@JsonKey() final  double gain;
/// Whether the connection is muted
@override@JsonKey() final  bool isMuted;
/// Whether the connection is inverted
@override@JsonKey() final  bool isInverted;
/// Optional delay in milliseconds
@override@JsonKey() final  double delayMs;
/// Additional connection properties
 final  Map<String, dynamic>? _properties;
/// Additional connection properties
@override Map<String, dynamic>? get properties {
  final value = _properties;
  if (value == null) return null;
  if (_properties is EqualUnmodifiableMapView) return _properties;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

/// Timestamp when the connection was created
@override final  DateTime? createdAt;
/// Timestamp when the connection was last modified
@override final  DateTime? modifiedAt;

/// Create a copy of Connection
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ConnectionCopyWith<_Connection> get copyWith => __$ConnectionCopyWithImpl<_Connection>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ConnectionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Connection&&(identical(other.id, id) || other.id == id)&&(identical(other.sourcePortId, sourcePortId) || other.sourcePortId == sourcePortId)&&(identical(other.destinationPortId, destinationPortId) || other.destinationPortId == destinationPortId)&&(identical(other.status, status) || other.status == status)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.gain, gain) || other.gain == gain)&&(identical(other.isMuted, isMuted) || other.isMuted == isMuted)&&(identical(other.isInverted, isInverted) || other.isInverted == isInverted)&&(identical(other.delayMs, delayMs) || other.delayMs == delayMs)&&const DeepCollectionEquality().equals(other._properties, _properties)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.modifiedAt, modifiedAt) || other.modifiedAt == modifiedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,sourcePortId,destinationPortId,status,name,description,gain,isMuted,isInverted,delayMs,const DeepCollectionEquality().hash(_properties),createdAt,modifiedAt);

@override
String toString() {
  return 'Connection(id: $id, sourcePortId: $sourcePortId, destinationPortId: $destinationPortId, status: $status, name: $name, description: $description, gain: $gain, isMuted: $isMuted, isInverted: $isInverted, delayMs: $delayMs, properties: $properties, createdAt: $createdAt, modifiedAt: $modifiedAt)';
}


}

/// @nodoc
abstract mixin class _$ConnectionCopyWith<$Res> implements $ConnectionCopyWith<$Res> {
  factory _$ConnectionCopyWith(_Connection value, $Res Function(_Connection) _then) = __$ConnectionCopyWithImpl;
@override @useResult
$Res call({
 String id, String sourcePortId, String destinationPortId, ConnectionStatus status, String? name, String? description, double gain, bool isMuted, bool isInverted, double delayMs, Map<String, dynamic>? properties, DateTime? createdAt, DateTime? modifiedAt
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
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? sourcePortId = null,Object? destinationPortId = null,Object? status = null,Object? name = freezed,Object? description = freezed,Object? gain = null,Object? isMuted = null,Object? isInverted = null,Object? delayMs = null,Object? properties = freezed,Object? createdAt = freezed,Object? modifiedAt = freezed,}) {
  return _then(_Connection(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,sourcePortId: null == sourcePortId ? _self.sourcePortId : sourcePortId // ignore: cast_nullable_to_non_nullable
as String,destinationPortId: null == destinationPortId ? _self.destinationPortId : destinationPortId // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ConnectionStatus,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,gain: null == gain ? _self.gain : gain // ignore: cast_nullable_to_non_nullable
as double,isMuted: null == isMuted ? _self.isMuted : isMuted // ignore: cast_nullable_to_non_nullable
as bool,isInverted: null == isInverted ? _self.isInverted : isInverted // ignore: cast_nullable_to_non_nullable
as bool,delayMs: null == delayMs ? _self.delayMs : delayMs // ignore: cast_nullable_to_non_nullable
as double,properties: freezed == properties ? _self._properties : properties // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,modifiedAt: freezed == modifiedAt ? _self.modifiedAt : modifiedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
