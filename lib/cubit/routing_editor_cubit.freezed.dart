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

 String get sourcePortId; String get targetPortId;
/// Create a copy of Connection
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ConnectionCopyWith<Connection> get copyWith => _$ConnectionCopyWithImpl<Connection>(this as Connection, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'Connection'))
    ..add(DiagnosticsProperty('sourcePortId', sourcePortId))..add(DiagnosticsProperty('targetPortId', targetPortId));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Connection&&(identical(other.sourcePortId, sourcePortId) || other.sourcePortId == sourcePortId)&&(identical(other.targetPortId, targetPortId) || other.targetPortId == targetPortId));
}


@override
int get hashCode => Object.hash(runtimeType,sourcePortId,targetPortId);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'Connection(sourcePortId: $sourcePortId, targetPortId: $targetPortId)';
}


}

/// @nodoc
abstract mixin class $ConnectionCopyWith<$Res>  {
  factory $ConnectionCopyWith(Connection value, $Res Function(Connection) _then) = _$ConnectionCopyWithImpl;
@useResult
$Res call({
 String sourcePortId, String targetPortId
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
@pragma('vm:prefer-inline') @override $Res call({Object? sourcePortId = null,Object? targetPortId = null,}) {
  return _then(_self.copyWith(
sourcePortId: null == sourcePortId ? _self.sourcePortId : sourcePortId // ignore: cast_nullable_to_non_nullable
as String,targetPortId: null == targetPortId ? _self.targetPortId : targetPortId // ignore: cast_nullable_to_non_nullable
as String,
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String sourcePortId,  String targetPortId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Connection() when $default != null:
return $default(_that.sourcePortId,_that.targetPortId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String sourcePortId,  String targetPortId)  $default,) {final _that = this;
switch (_that) {
case _Connection():
return $default(_that.sourcePortId,_that.targetPortId);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String sourcePortId,  String targetPortId)?  $default,) {final _that = this;
switch (_that) {
case _Connection() when $default != null:
return $default(_that.sourcePortId,_that.targetPortId);case _:
  return null;

}
}

}

/// @nodoc


class _Connection with DiagnosticableTreeMixin implements Connection {
  const _Connection({required this.sourcePortId, required this.targetPortId});
  

@override final  String sourcePortId;
@override final  String targetPortId;

/// Create a copy of Connection
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ConnectionCopyWith<_Connection> get copyWith => __$ConnectionCopyWithImpl<_Connection>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'Connection'))
    ..add(DiagnosticsProperty('sourcePortId', sourcePortId))..add(DiagnosticsProperty('targetPortId', targetPortId));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Connection&&(identical(other.sourcePortId, sourcePortId) || other.sourcePortId == sourcePortId)&&(identical(other.targetPortId, targetPortId) || other.targetPortId == targetPortId));
}


@override
int get hashCode => Object.hash(runtimeType,sourcePortId,targetPortId);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'Connection(sourcePortId: $sourcePortId, targetPortId: $targetPortId)';
}


}

/// @nodoc
abstract mixin class _$ConnectionCopyWith<$Res> implements $ConnectionCopyWith<$Res> {
  factory _$ConnectionCopyWith(_Connection value, $Res Function(_Connection) _then) = __$ConnectionCopyWithImpl;
@override @useResult
$Res call({
 String sourcePortId, String targetPortId
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
@override @pragma('vm:prefer-inline') $Res call({Object? sourcePortId = null,Object? targetPortId = null,}) {
  return _then(_Connection(
sourcePortId: null == sourcePortId ? _self.sourcePortId : sourcePortId // ignore: cast_nullable_to_non_nullable
as String,targetPortId: null == targetPortId ? _self.targetPortId : targetPortId // ignore: cast_nullable_to_non_nullable
as String,
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( RoutingEditorStateInitial value)?  initial,TResult Function( RoutingEditorStateDisconnected value)?  disconnected,TResult Function( RoutingEditorStateConnecting value)?  connecting,TResult Function( RoutingEditorStateRefreshing value)?  refreshing,TResult Function( RoutingEditorStateLoaded value)?  loaded,TResult Function( RoutingEditorStateError value)?  error,required TResult orElse(),}){
final _that = this;
switch (_that) {
case RoutingEditorStateInitial() when initial != null:
return initial(_that);case RoutingEditorStateDisconnected() when disconnected != null:
return disconnected(_that);case RoutingEditorStateConnecting() when connecting != null:
return connecting(_that);case RoutingEditorStateRefreshing() when refreshing != null:
return refreshing(_that);case RoutingEditorStateLoaded() when loaded != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( RoutingEditorStateInitial value)  initial,required TResult Function( RoutingEditorStateDisconnected value)  disconnected,required TResult Function( RoutingEditorStateConnecting value)  connecting,required TResult Function( RoutingEditorStateRefreshing value)  refreshing,required TResult Function( RoutingEditorStateLoaded value)  loaded,required TResult Function( RoutingEditorStateError value)  error,}){
final _that = this;
switch (_that) {
case RoutingEditorStateInitial():
return initial(_that);case RoutingEditorStateDisconnected():
return disconnected(_that);case RoutingEditorStateConnecting():
return connecting(_that);case RoutingEditorStateRefreshing():
return refreshing(_that);case RoutingEditorStateLoaded():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( RoutingEditorStateInitial value)?  initial,TResult? Function( RoutingEditorStateDisconnected value)?  disconnected,TResult? Function( RoutingEditorStateConnecting value)?  connecting,TResult? Function( RoutingEditorStateRefreshing value)?  refreshing,TResult? Function( RoutingEditorStateLoaded value)?  loaded,TResult? Function( RoutingEditorStateError value)?  error,}){
final _that = this;
switch (_that) {
case RoutingEditorStateInitial() when initial != null:
return initial(_that);case RoutingEditorStateDisconnected() when disconnected != null:
return disconnected(_that);case RoutingEditorStateConnecting() when connecting != null:
return connecting(_that);case RoutingEditorStateRefreshing() when refreshing != null:
return refreshing(_that);case RoutingEditorStateLoaded() when loaded != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function()?  disconnected,TResult Function()?  connecting,TResult Function()?  refreshing,TResult Function( List<Port> physicalInputs,  List<Port> physicalOutputs,  List<RoutingAlgorithm> algorithms,  List<Connection> connections)?  loaded,TResult Function( String message)?  error,required TResult orElse(),}) {final _that = this;
switch (_that) {
case RoutingEditorStateInitial() when initial != null:
return initial();case RoutingEditorStateDisconnected() when disconnected != null:
return disconnected();case RoutingEditorStateConnecting() when connecting != null:
return connecting();case RoutingEditorStateRefreshing() when refreshing != null:
return refreshing();case RoutingEditorStateLoaded() when loaded != null:
return loaded(_that.physicalInputs,_that.physicalOutputs,_that.algorithms,_that.connections);case RoutingEditorStateError() when error != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function()  disconnected,required TResult Function()  connecting,required TResult Function()  refreshing,required TResult Function( List<Port> physicalInputs,  List<Port> physicalOutputs,  List<RoutingAlgorithm> algorithms,  List<Connection> connections)  loaded,required TResult Function( String message)  error,}) {final _that = this;
switch (_that) {
case RoutingEditorStateInitial():
return initial();case RoutingEditorStateDisconnected():
return disconnected();case RoutingEditorStateConnecting():
return connecting();case RoutingEditorStateRefreshing():
return refreshing();case RoutingEditorStateLoaded():
return loaded(_that.physicalInputs,_that.physicalOutputs,_that.algorithms,_that.connections);case RoutingEditorStateError():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function()?  disconnected,TResult? Function()?  connecting,TResult? Function()?  refreshing,TResult? Function( List<Port> physicalInputs,  List<Port> physicalOutputs,  List<RoutingAlgorithm> algorithms,  List<Connection> connections)?  loaded,TResult? Function( String message)?  error,}) {final _that = this;
switch (_that) {
case RoutingEditorStateInitial() when initial != null:
return initial();case RoutingEditorStateDisconnected() when disconnected != null:
return disconnected();case RoutingEditorStateConnecting() when connecting != null:
return connecting();case RoutingEditorStateRefreshing() when refreshing != null:
return refreshing();case RoutingEditorStateLoaded() when loaded != null:
return loaded(_that.physicalInputs,_that.physicalOutputs,_that.algorithms,_that.connections);case RoutingEditorStateError() when error != null:
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


class RoutingEditorStateLoaded with DiagnosticableTreeMixin implements RoutingEditorState {
  const RoutingEditorStateLoaded({required final  List<Port> physicalInputs, required final  List<Port> physicalOutputs, required final  List<RoutingAlgorithm> algorithms, required final  List<Connection> connections}): _physicalInputs = physicalInputs,_physicalOutputs = physicalOutputs,_algorithms = algorithms,_connections = connections;
  

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


/// Create a copy of RoutingEditorState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RoutingEditorStateLoadedCopyWith<RoutingEditorStateLoaded> get copyWith => _$RoutingEditorStateLoadedCopyWithImpl<RoutingEditorStateLoaded>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'RoutingEditorState.loaded'))
    ..add(DiagnosticsProperty('physicalInputs', physicalInputs))..add(DiagnosticsProperty('physicalOutputs', physicalOutputs))..add(DiagnosticsProperty('algorithms', algorithms))..add(DiagnosticsProperty('connections', connections));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RoutingEditorStateLoaded&&const DeepCollectionEquality().equals(other._physicalInputs, _physicalInputs)&&const DeepCollectionEquality().equals(other._physicalOutputs, _physicalOutputs)&&const DeepCollectionEquality().equals(other._algorithms, _algorithms)&&const DeepCollectionEquality().equals(other._connections, _connections));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_physicalInputs),const DeepCollectionEquality().hash(_physicalOutputs),const DeepCollectionEquality().hash(_algorithms),const DeepCollectionEquality().hash(_connections));

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'RoutingEditorState.loaded(physicalInputs: $physicalInputs, physicalOutputs: $physicalOutputs, algorithms: $algorithms, connections: $connections)';
}


}

/// @nodoc
abstract mixin class $RoutingEditorStateLoadedCopyWith<$Res> implements $RoutingEditorStateCopyWith<$Res> {
  factory $RoutingEditorStateLoadedCopyWith(RoutingEditorStateLoaded value, $Res Function(RoutingEditorStateLoaded) _then) = _$RoutingEditorStateLoadedCopyWithImpl;
@useResult
$Res call({
 List<Port> physicalInputs, List<Port> physicalOutputs, List<RoutingAlgorithm> algorithms, List<Connection> connections
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
@pragma('vm:prefer-inline') $Res call({Object? physicalInputs = null,Object? physicalOutputs = null,Object? algorithms = null,Object? connections = null,}) {
  return _then(RoutingEditorStateLoaded(
physicalInputs: null == physicalInputs ? _self._physicalInputs : physicalInputs // ignore: cast_nullable_to_non_nullable
as List<Port>,physicalOutputs: null == physicalOutputs ? _self._physicalOutputs : physicalOutputs // ignore: cast_nullable_to_non_nullable
as List<Port>,algorithms: null == algorithms ? _self._algorithms : algorithms // ignore: cast_nullable_to_non_nullable
as List<RoutingAlgorithm>,connections: null == connections ? _self._connections : connections // ignore: cast_nullable_to_non_nullable
as List<Connection>,
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
