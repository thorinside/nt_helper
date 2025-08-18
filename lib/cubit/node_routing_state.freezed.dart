// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'node_routing_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$NodeRoutingState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NodeRoutingState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'NodeRoutingState()';
}


}

/// @nodoc
class $NodeRoutingStateCopyWith<$Res>  {
$NodeRoutingStateCopyWith(NodeRoutingState _, $Res Function(NodeRoutingState) __);
}


/// Adds pattern-matching-related methods to [NodeRoutingState].
extension NodeRoutingStatePatterns on NodeRoutingState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( NodeRoutingStateInitial value)?  initial,TResult Function( NodeRoutingStateLoading value)?  loading,TResult Function( NodeRoutingStateLoaded value)?  loaded,TResult Function( NodeRoutingStateError value)?  error,required TResult orElse(),}){
final _that = this;
switch (_that) {
case NodeRoutingStateInitial() when initial != null:
return initial(_that);case NodeRoutingStateLoading() when loading != null:
return loading(_that);case NodeRoutingStateLoaded() when loaded != null:
return loaded(_that);case NodeRoutingStateError() when error != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( NodeRoutingStateInitial value)  initial,required TResult Function( NodeRoutingStateLoading value)  loading,required TResult Function( NodeRoutingStateLoaded value)  loaded,required TResult Function( NodeRoutingStateError value)  error,}){
final _that = this;
switch (_that) {
case NodeRoutingStateInitial():
return initial(_that);case NodeRoutingStateLoading():
return loading(_that);case NodeRoutingStateLoaded():
return loaded(_that);case NodeRoutingStateError():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( NodeRoutingStateInitial value)?  initial,TResult? Function( NodeRoutingStateLoading value)?  loading,TResult? Function( NodeRoutingStateLoaded value)?  loaded,TResult? Function( NodeRoutingStateError value)?  error,}){
final _that = this;
switch (_that) {
case NodeRoutingStateInitial() when initial != null:
return initial(_that);case NodeRoutingStateLoading() when loading != null:
return loading(_that);case NodeRoutingStateLoaded() when loaded != null:
return loaded(_that);case NodeRoutingStateError() when error != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function()?  loading,TResult Function( Map<int, NodePosition> nodePositions,  List<Connection> connections,  Map<int, PortLayout> portLayouts,  Set<String> connectedPorts,  Map<int, String> algorithmNames,  Map<String, Offset> portPositions,  bool hasUserRepositioned,  ConnectionPreview? connectionPreview,  String? hoveredConnectionId,  String? hoveredLabelId,  Set<int>? selectedNodes,  Map<String, bool>? portHoverStates,  String? errorMessage,  Set<String> pendingConnections,  Set<String> failedConnections,  Map<String, DateTime> operationTimestamps, @Deprecated('Use portLayouts instead')  Map<int, List<AlgorithmPort>>? algorithmPorts)?  loaded,TResult Function( String message)?  error,required TResult orElse(),}) {final _that = this;
switch (_that) {
case NodeRoutingStateInitial() when initial != null:
return initial();case NodeRoutingStateLoading() when loading != null:
return loading();case NodeRoutingStateLoaded() when loaded != null:
return loaded(_that.nodePositions,_that.connections,_that.portLayouts,_that.connectedPorts,_that.algorithmNames,_that.portPositions,_that.hasUserRepositioned,_that.connectionPreview,_that.hoveredConnectionId,_that.hoveredLabelId,_that.selectedNodes,_that.portHoverStates,_that.errorMessage,_that.pendingConnections,_that.failedConnections,_that.operationTimestamps,_that.algorithmPorts);case NodeRoutingStateError() when error != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function()  loading,required TResult Function( Map<int, NodePosition> nodePositions,  List<Connection> connections,  Map<int, PortLayout> portLayouts,  Set<String> connectedPorts,  Map<int, String> algorithmNames,  Map<String, Offset> portPositions,  bool hasUserRepositioned,  ConnectionPreview? connectionPreview,  String? hoveredConnectionId,  String? hoveredLabelId,  Set<int>? selectedNodes,  Map<String, bool>? portHoverStates,  String? errorMessage,  Set<String> pendingConnections,  Set<String> failedConnections,  Map<String, DateTime> operationTimestamps, @Deprecated('Use portLayouts instead')  Map<int, List<AlgorithmPort>>? algorithmPorts)  loaded,required TResult Function( String message)  error,}) {final _that = this;
switch (_that) {
case NodeRoutingStateInitial():
return initial();case NodeRoutingStateLoading():
return loading();case NodeRoutingStateLoaded():
return loaded(_that.nodePositions,_that.connections,_that.portLayouts,_that.connectedPorts,_that.algorithmNames,_that.portPositions,_that.hasUserRepositioned,_that.connectionPreview,_that.hoveredConnectionId,_that.hoveredLabelId,_that.selectedNodes,_that.portHoverStates,_that.errorMessage,_that.pendingConnections,_that.failedConnections,_that.operationTimestamps,_that.algorithmPorts);case NodeRoutingStateError():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function()?  loading,TResult? Function( Map<int, NodePosition> nodePositions,  List<Connection> connections,  Map<int, PortLayout> portLayouts,  Set<String> connectedPorts,  Map<int, String> algorithmNames,  Map<String, Offset> portPositions,  bool hasUserRepositioned,  ConnectionPreview? connectionPreview,  String? hoveredConnectionId,  String? hoveredLabelId,  Set<int>? selectedNodes,  Map<String, bool>? portHoverStates,  String? errorMessage,  Set<String> pendingConnections,  Set<String> failedConnections,  Map<String, DateTime> operationTimestamps, @Deprecated('Use portLayouts instead')  Map<int, List<AlgorithmPort>>? algorithmPorts)?  loaded,TResult? Function( String message)?  error,}) {final _that = this;
switch (_that) {
case NodeRoutingStateInitial() when initial != null:
return initial();case NodeRoutingStateLoading() when loading != null:
return loading();case NodeRoutingStateLoaded() when loaded != null:
return loaded(_that.nodePositions,_that.connections,_that.portLayouts,_that.connectedPorts,_that.algorithmNames,_that.portPositions,_that.hasUserRepositioned,_that.connectionPreview,_that.hoveredConnectionId,_that.hoveredLabelId,_that.selectedNodes,_that.portHoverStates,_that.errorMessage,_that.pendingConnections,_that.failedConnections,_that.operationTimestamps,_that.algorithmPorts);case NodeRoutingStateError() when error != null:
return error(_that.message);case _:
  return null;

}
}

}

/// @nodoc


class NodeRoutingStateInitial implements NodeRoutingState {
  const NodeRoutingStateInitial();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NodeRoutingStateInitial);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'NodeRoutingState.initial()';
}


}




/// @nodoc


class NodeRoutingStateLoading implements NodeRoutingState {
  const NodeRoutingStateLoading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NodeRoutingStateLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'NodeRoutingState.loading()';
}


}




/// @nodoc


class NodeRoutingStateLoaded implements NodeRoutingState {
  const NodeRoutingStateLoaded({required final  Map<int, NodePosition> nodePositions, required final  List<Connection> connections, required final  Map<int, PortLayout> portLayouts, required final  Set<String> connectedPorts, required final  Map<int, String> algorithmNames, required final  Map<String, Offset> portPositions, this.hasUserRepositioned = false, this.connectionPreview, this.hoveredConnectionId, this.hoveredLabelId, final  Set<int>? selectedNodes, final  Map<String, bool>? portHoverStates, this.errorMessage, final  Set<String> pendingConnections = const {}, final  Set<String> failedConnections = const {}, final  Map<String, DateTime> operationTimestamps = const {}, @Deprecated('Use portLayouts instead') final  Map<int, List<AlgorithmPort>>? algorithmPorts}): _nodePositions = nodePositions,_connections = connections,_portLayouts = portLayouts,_connectedPorts = connectedPorts,_algorithmNames = algorithmNames,_portPositions = portPositions,_selectedNodes = selectedNodes,_portHoverStates = portHoverStates,_pendingConnections = pendingConnections,_failedConnections = failedConnections,_operationTimestamps = operationTimestamps,_algorithmPorts = algorithmPorts;
  

 final  Map<int, NodePosition> _nodePositions;
 Map<int, NodePosition> get nodePositions {
  if (_nodePositions is EqualUnmodifiableMapView) return _nodePositions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_nodePositions);
}

 final  List<Connection> _connections;
 List<Connection> get connections {
  if (_connections is EqualUnmodifiableListView) return _connections;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_connections);
}

 final  Map<int, PortLayout> _portLayouts;
 Map<int, PortLayout> get portLayouts {
  if (_portLayouts is EqualUnmodifiableMapView) return _portLayouts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_portLayouts);
}

 final  Set<String> _connectedPorts;
 Set<String> get connectedPorts {
  if (_connectedPorts is EqualUnmodifiableSetView) return _connectedPorts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_connectedPorts);
}

 final  Map<int, String> _algorithmNames;
 Map<int, String> get algorithmNames {
  if (_algorithmNames is EqualUnmodifiableMapView) return _algorithmNames;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_algorithmNames);
}

 final  Map<String, Offset> _portPositions;
 Map<String, Offset> get portPositions {
  if (_portPositions is EqualUnmodifiableMapView) return _portPositions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_portPositions);
}

// algorithmIndex_portId -> Offset
@JsonKey() final  bool hasUserRepositioned;
 final  ConnectionPreview? connectionPreview;
 final  String? hoveredConnectionId;
 final  String? hoveredLabelId;
// Currently hovered label ID for mode toggle
 final  Set<int>? _selectedNodes;
// Currently hovered label ID for mode toggle
 Set<int>? get selectedNodes {
  final value = _selectedNodes;
  if (value == null) return null;
  if (_selectedNodes is EqualUnmodifiableSetView) return _selectedNodes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(value);
}

 final  Map<String, bool>? _portHoverStates;
 Map<String, bool>? get portHoverStates {
  final value = _portHoverStates;
  if (value == null) return null;
  if (_portHoverStates is EqualUnmodifiableMapView) return _portHoverStates;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

// portId -> isHovered
 final  String? errorMessage;
 final  Set<String> _pendingConnections;
@JsonKey() Set<String> get pendingConnections {
  if (_pendingConnections is EqualUnmodifiableSetView) return _pendingConnections;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_pendingConnections);
}

// Connection IDs being created
 final  Set<String> _failedConnections;
// Connection IDs being created
@JsonKey() Set<String> get failedConnections {
  if (_failedConnections is EqualUnmodifiableSetView) return _failedConnections;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_failedConnections);
}

// Connection IDs that failed
 final  Map<String, DateTime> _operationTimestamps;
// Connection IDs that failed
@JsonKey() Map<String, DateTime> get operationTimestamps {
  if (_operationTimestamps is EqualUnmodifiableMapView) return _operationTimestamps;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_operationTimestamps);
}

// For timeout tracking
 final  Map<int, List<AlgorithmPort>>? _algorithmPorts;
// For timeout tracking
@Deprecated('Use portLayouts instead') Map<int, List<AlgorithmPort>>? get algorithmPorts {
  final value = _algorithmPorts;
  if (value == null) return null;
  if (_algorithmPorts is EqualUnmodifiableMapView) return _algorithmPorts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}


/// Create a copy of NodeRoutingState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NodeRoutingStateLoadedCopyWith<NodeRoutingStateLoaded> get copyWith => _$NodeRoutingStateLoadedCopyWithImpl<NodeRoutingStateLoaded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NodeRoutingStateLoaded&&const DeepCollectionEquality().equals(other._nodePositions, _nodePositions)&&const DeepCollectionEquality().equals(other._connections, _connections)&&const DeepCollectionEquality().equals(other._portLayouts, _portLayouts)&&const DeepCollectionEquality().equals(other._connectedPorts, _connectedPorts)&&const DeepCollectionEquality().equals(other._algorithmNames, _algorithmNames)&&const DeepCollectionEquality().equals(other._portPositions, _portPositions)&&(identical(other.hasUserRepositioned, hasUserRepositioned) || other.hasUserRepositioned == hasUserRepositioned)&&(identical(other.connectionPreview, connectionPreview) || other.connectionPreview == connectionPreview)&&(identical(other.hoveredConnectionId, hoveredConnectionId) || other.hoveredConnectionId == hoveredConnectionId)&&(identical(other.hoveredLabelId, hoveredLabelId) || other.hoveredLabelId == hoveredLabelId)&&const DeepCollectionEquality().equals(other._selectedNodes, _selectedNodes)&&const DeepCollectionEquality().equals(other._portHoverStates, _portHoverStates)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage)&&const DeepCollectionEquality().equals(other._pendingConnections, _pendingConnections)&&const DeepCollectionEquality().equals(other._failedConnections, _failedConnections)&&const DeepCollectionEquality().equals(other._operationTimestamps, _operationTimestamps)&&const DeepCollectionEquality().equals(other._algorithmPorts, _algorithmPorts));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_nodePositions),const DeepCollectionEquality().hash(_connections),const DeepCollectionEquality().hash(_portLayouts),const DeepCollectionEquality().hash(_connectedPorts),const DeepCollectionEquality().hash(_algorithmNames),const DeepCollectionEquality().hash(_portPositions),hasUserRepositioned,connectionPreview,hoveredConnectionId,hoveredLabelId,const DeepCollectionEquality().hash(_selectedNodes),const DeepCollectionEquality().hash(_portHoverStates),errorMessage,const DeepCollectionEquality().hash(_pendingConnections),const DeepCollectionEquality().hash(_failedConnections),const DeepCollectionEquality().hash(_operationTimestamps),const DeepCollectionEquality().hash(_algorithmPorts));

@override
String toString() {
  return 'NodeRoutingState.loaded(nodePositions: $nodePositions, connections: $connections, portLayouts: $portLayouts, connectedPorts: $connectedPorts, algorithmNames: $algorithmNames, portPositions: $portPositions, hasUserRepositioned: $hasUserRepositioned, connectionPreview: $connectionPreview, hoveredConnectionId: $hoveredConnectionId, hoveredLabelId: $hoveredLabelId, selectedNodes: $selectedNodes, portHoverStates: $portHoverStates, errorMessage: $errorMessage, pendingConnections: $pendingConnections, failedConnections: $failedConnections, operationTimestamps: $operationTimestamps, algorithmPorts: $algorithmPorts)';
}


}

/// @nodoc
abstract mixin class $NodeRoutingStateLoadedCopyWith<$Res> implements $NodeRoutingStateCopyWith<$Res> {
  factory $NodeRoutingStateLoadedCopyWith(NodeRoutingStateLoaded value, $Res Function(NodeRoutingStateLoaded) _then) = _$NodeRoutingStateLoadedCopyWithImpl;
@useResult
$Res call({
 Map<int, NodePosition> nodePositions, List<Connection> connections, Map<int, PortLayout> portLayouts, Set<String> connectedPorts, Map<int, String> algorithmNames, Map<String, Offset> portPositions, bool hasUserRepositioned, ConnectionPreview? connectionPreview, String? hoveredConnectionId, String? hoveredLabelId, Set<int>? selectedNodes, Map<String, bool>? portHoverStates, String? errorMessage, Set<String> pendingConnections, Set<String> failedConnections, Map<String, DateTime> operationTimestamps,@Deprecated('Use portLayouts instead') Map<int, List<AlgorithmPort>>? algorithmPorts
});




}
/// @nodoc
class _$NodeRoutingStateLoadedCopyWithImpl<$Res>
    implements $NodeRoutingStateLoadedCopyWith<$Res> {
  _$NodeRoutingStateLoadedCopyWithImpl(this._self, this._then);

  final NodeRoutingStateLoaded _self;
  final $Res Function(NodeRoutingStateLoaded) _then;

/// Create a copy of NodeRoutingState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? nodePositions = null,Object? connections = null,Object? portLayouts = null,Object? connectedPorts = null,Object? algorithmNames = null,Object? portPositions = null,Object? hasUserRepositioned = null,Object? connectionPreview = freezed,Object? hoveredConnectionId = freezed,Object? hoveredLabelId = freezed,Object? selectedNodes = freezed,Object? portHoverStates = freezed,Object? errorMessage = freezed,Object? pendingConnections = null,Object? failedConnections = null,Object? operationTimestamps = null,Object? algorithmPorts = freezed,}) {
  return _then(NodeRoutingStateLoaded(
nodePositions: null == nodePositions ? _self._nodePositions : nodePositions // ignore: cast_nullable_to_non_nullable
as Map<int, NodePosition>,connections: null == connections ? _self._connections : connections // ignore: cast_nullable_to_non_nullable
as List<Connection>,portLayouts: null == portLayouts ? _self._portLayouts : portLayouts // ignore: cast_nullable_to_non_nullable
as Map<int, PortLayout>,connectedPorts: null == connectedPorts ? _self._connectedPorts : connectedPorts // ignore: cast_nullable_to_non_nullable
as Set<String>,algorithmNames: null == algorithmNames ? _self._algorithmNames : algorithmNames // ignore: cast_nullable_to_non_nullable
as Map<int, String>,portPositions: null == portPositions ? _self._portPositions : portPositions // ignore: cast_nullable_to_non_nullable
as Map<String, Offset>,hasUserRepositioned: null == hasUserRepositioned ? _self.hasUserRepositioned : hasUserRepositioned // ignore: cast_nullable_to_non_nullable
as bool,connectionPreview: freezed == connectionPreview ? _self.connectionPreview : connectionPreview // ignore: cast_nullable_to_non_nullable
as ConnectionPreview?,hoveredConnectionId: freezed == hoveredConnectionId ? _self.hoveredConnectionId : hoveredConnectionId // ignore: cast_nullable_to_non_nullable
as String?,hoveredLabelId: freezed == hoveredLabelId ? _self.hoveredLabelId : hoveredLabelId // ignore: cast_nullable_to_non_nullable
as String?,selectedNodes: freezed == selectedNodes ? _self._selectedNodes : selectedNodes // ignore: cast_nullable_to_non_nullable
as Set<int>?,portHoverStates: freezed == portHoverStates ? _self._portHoverStates : portHoverStates // ignore: cast_nullable_to_non_nullable
as Map<String, bool>?,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,pendingConnections: null == pendingConnections ? _self._pendingConnections : pendingConnections // ignore: cast_nullable_to_non_nullable
as Set<String>,failedConnections: null == failedConnections ? _self._failedConnections : failedConnections // ignore: cast_nullable_to_non_nullable
as Set<String>,operationTimestamps: null == operationTimestamps ? _self._operationTimestamps : operationTimestamps // ignore: cast_nullable_to_non_nullable
as Map<String, DateTime>,algorithmPorts: freezed == algorithmPorts ? _self._algorithmPorts : algorithmPorts // ignore: cast_nullable_to_non_nullable
as Map<int, List<AlgorithmPort>>?,
  ));
}


}

/// @nodoc


class NodeRoutingStateError implements NodeRoutingState {
  const NodeRoutingStateError({required this.message});
  

 final  String message;

/// Create a copy of NodeRoutingState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NodeRoutingStateErrorCopyWith<NodeRoutingStateError> get copyWith => _$NodeRoutingStateErrorCopyWithImpl<NodeRoutingStateError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NodeRoutingStateError&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'NodeRoutingState.error(message: $message)';
}


}

/// @nodoc
abstract mixin class $NodeRoutingStateErrorCopyWith<$Res> implements $NodeRoutingStateCopyWith<$Res> {
  factory $NodeRoutingStateErrorCopyWith(NodeRoutingStateError value, $Res Function(NodeRoutingStateError) _then) = _$NodeRoutingStateErrorCopyWithImpl;
@useResult
$Res call({
 String message
});




}
/// @nodoc
class _$NodeRoutingStateErrorCopyWithImpl<$Res>
    implements $NodeRoutingStateErrorCopyWith<$Res> {
  _$NodeRoutingStateErrorCopyWithImpl(this._self, this._then);

  final NodeRoutingStateError _self;
  final $Res Function(NodeRoutingStateError) _then;

/// Create a copy of NodeRoutingState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(NodeRoutingStateError(
message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
