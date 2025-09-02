// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'port.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Port {

/// Unique identifier for this port
 String get id;/// Human-readable name of the port
 String get name;/// The type of signal this port handles
 PortType get type;/// The direction of signal flow for this port
 PortDirection get direction;/// Optional description of the port's purpose
 String? get description;/// Optional constraints for this port (e.g., voltage range, frequency)
 Map<String, dynamic>? get constraints;/// Whether this port is currently active/enabled
 bool get isActive;/// Optional metadata for the port
 Map<String, dynamic>? get metadata;/// Optional output mode for output ports (add or replace)
 OutputMode? get outputMode;
/// Create a copy of Port
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PortCopyWith<Port> get copyWith => _$PortCopyWithImpl<Port>(this as Port, _$identity);

  /// Serializes this Port to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Port&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.type, type) || other.type == type)&&(identical(other.direction, direction) || other.direction == direction)&&(identical(other.description, description) || other.description == description)&&const DeepCollectionEquality().equals(other.constraints, constraints)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&const DeepCollectionEquality().equals(other.metadata, metadata)&&(identical(other.outputMode, outputMode) || other.outputMode == outputMode));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,type,direction,description,const DeepCollectionEquality().hash(constraints),isActive,const DeepCollectionEquality().hash(metadata),outputMode);

@override
String toString() {
  return 'Port(id: $id, name: $name, type: $type, direction: $direction, description: $description, constraints: $constraints, isActive: $isActive, metadata: $metadata, outputMode: $outputMode)';
}


}

/// @nodoc
abstract mixin class $PortCopyWith<$Res>  {
  factory $PortCopyWith(Port value, $Res Function(Port) _then) = _$PortCopyWithImpl;
@useResult
$Res call({
 String id, String name, PortType type, PortDirection direction, String? description, Map<String, dynamic>? constraints, bool isActive, Map<String, dynamic>? metadata, OutputMode? outputMode
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
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? type = null,Object? direction = null,Object? description = freezed,Object? constraints = freezed,Object? isActive = null,Object? metadata = freezed,Object? outputMode = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as PortType,direction: null == direction ? _self.direction : direction // ignore: cast_nullable_to_non_nullable
as PortDirection,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,constraints: freezed == constraints ? _self.constraints : constraints // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,metadata: freezed == metadata ? _self.metadata : metadata // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,outputMode: freezed == outputMode ? _self.outputMode : outputMode // ignore: cast_nullable_to_non_nullable
as OutputMode?,
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  PortType type,  PortDirection direction,  String? description,  Map<String, dynamic>? constraints,  bool isActive,  Map<String, dynamic>? metadata,  OutputMode? outputMode)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Port() when $default != null:
return $default(_that.id,_that.name,_that.type,_that.direction,_that.description,_that.constraints,_that.isActive,_that.metadata,_that.outputMode);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  PortType type,  PortDirection direction,  String? description,  Map<String, dynamic>? constraints,  bool isActive,  Map<String, dynamic>? metadata,  OutputMode? outputMode)  $default,) {final _that = this;
switch (_that) {
case _Port():
return $default(_that.id,_that.name,_that.type,_that.direction,_that.description,_that.constraints,_that.isActive,_that.metadata,_that.outputMode);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  PortType type,  PortDirection direction,  String? description,  Map<String, dynamic>? constraints,  bool isActive,  Map<String, dynamic>? metadata,  OutputMode? outputMode)?  $default,) {final _that = this;
switch (_that) {
case _Port() when $default != null:
return $default(_that.id,_that.name,_that.type,_that.direction,_that.description,_that.constraints,_that.isActive,_that.metadata,_that.outputMode);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Port extends Port {
  const _Port({required this.id, required this.name, required this.type, required this.direction, this.description, final  Map<String, dynamic>? constraints, this.isActive = true, final  Map<String, dynamic>? metadata, this.outputMode}): _constraints = constraints,_metadata = metadata,super._();
  factory _Port.fromJson(Map<String, dynamic> json) => _$PortFromJson(json);

/// Unique identifier for this port
@override final  String id;
/// Human-readable name of the port
@override final  String name;
/// The type of signal this port handles
@override final  PortType type;
/// The direction of signal flow for this port
@override final  PortDirection direction;
/// Optional description of the port's purpose
@override final  String? description;
/// Optional constraints for this port (e.g., voltage range, frequency)
 final  Map<String, dynamic>? _constraints;
/// Optional constraints for this port (e.g., voltage range, frequency)
@override Map<String, dynamic>? get constraints {
  final value = _constraints;
  if (value == null) return null;
  if (_constraints is EqualUnmodifiableMapView) return _constraints;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

/// Whether this port is currently active/enabled
@override@JsonKey() final  bool isActive;
/// Optional metadata for the port
 final  Map<String, dynamic>? _metadata;
/// Optional metadata for the port
@override Map<String, dynamic>? get metadata {
  final value = _metadata;
  if (value == null) return null;
  if (_metadata is EqualUnmodifiableMapView) return _metadata;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

/// Optional output mode for output ports (add or replace)
@override final  OutputMode? outputMode;

/// Create a copy of Port
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PortCopyWith<_Port> get copyWith => __$PortCopyWithImpl<_Port>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PortToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Port&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.type, type) || other.type == type)&&(identical(other.direction, direction) || other.direction == direction)&&(identical(other.description, description) || other.description == description)&&const DeepCollectionEquality().equals(other._constraints, _constraints)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&const DeepCollectionEquality().equals(other._metadata, _metadata)&&(identical(other.outputMode, outputMode) || other.outputMode == outputMode));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,type,direction,description,const DeepCollectionEquality().hash(_constraints),isActive,const DeepCollectionEquality().hash(_metadata),outputMode);

@override
String toString() {
  return 'Port(id: $id, name: $name, type: $type, direction: $direction, description: $description, constraints: $constraints, isActive: $isActive, metadata: $metadata, outputMode: $outputMode)';
}


}

/// @nodoc
abstract mixin class _$PortCopyWith<$Res> implements $PortCopyWith<$Res> {
  factory _$PortCopyWith(_Port value, $Res Function(_Port) _then) = __$PortCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, PortType type, PortDirection direction, String? description, Map<String, dynamic>? constraints, bool isActive, Map<String, dynamic>? metadata, OutputMode? outputMode
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
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? type = null,Object? direction = null,Object? description = freezed,Object? constraints = freezed,Object? isActive = null,Object? metadata = freezed,Object? outputMode = freezed,}) {
  return _then(_Port(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as PortType,direction: null == direction ? _self.direction : direction // ignore: cast_nullable_to_non_nullable
as PortDirection,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,constraints: freezed == constraints ? _self._constraints : constraints // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,metadata: freezed == metadata ? _self._metadata : metadata // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,outputMode: freezed == outputMode ? _self.outputMode : outputMode // ignore: cast_nullable_to_non_nullable
as OutputMode?,
  ));
}


}

// dart format on
