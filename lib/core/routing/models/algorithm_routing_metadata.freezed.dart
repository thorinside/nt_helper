// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'algorithm_routing_metadata.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AlgorithmRoutingMetadata {

/// Unique identifier for the algorithm
 String get algorithmGuid;/// The type of routing this algorithm requires
 RoutingType get routingType;/// Human-readable name for debugging/logging
 String? get algorithmName;// === Polyphonic Algorithm Properties ===
/// Number of polyphonic voices (relevant for polyphonic routing)
/// Default: 1 (monophonic)
 int get voiceCount;/// Whether the algorithm requires gate/trigger inputs for each voice
 bool get requiresGateInputs;/// Whether the algorithm uses virtual CV ports for modulation
 bool get usesVirtualCvPorts;/// Number of virtual CV ports per voice (when usesVirtualCvPorts is true)
 int get virtualCvPortsPerVoice;// === Multi-Channel Algorithm Properties ===
/// Number of channels (relevant for multi-channel routing)
/// For normal algorithms: 1, for width-based algorithms: N
 int get channelCount;/// Whether the algorithm supports stereo channel pairing
 bool get supportsStereo;/// Whether channels can be independently routed
 bool get allowsIndependentChannels;/// Whether to create master mix outputs for multi-channel algorithms
 bool get createMasterMix;// === Common Properties ===
/// Port types that this algorithm supports
 List<String> get supportedPortTypes;/// Base name prefix for generated ports
 String? get portNamePrefix;/// Additional algorithm-specific properties for extensibility
///
/// This map allows for future routing requirements without breaking
/// the existing interface. New routing implementations can check for
/// specific keys in this map to enable additional behavior.
 Map<String, dynamic> get customProperties;/// Routing constraints or special requirements
///
/// Examples:
/// - 'maxConnections': 8
/// - 'requiresClockInput': true
/// - 'bypassable': true
 Map<String, dynamic> get routingConstraints;
/// Create a copy of AlgorithmRoutingMetadata
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AlgorithmRoutingMetadataCopyWith<AlgorithmRoutingMetadata> get copyWith => _$AlgorithmRoutingMetadataCopyWithImpl<AlgorithmRoutingMetadata>(this as AlgorithmRoutingMetadata, _$identity);

  /// Serializes this AlgorithmRoutingMetadata to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AlgorithmRoutingMetadata&&(identical(other.algorithmGuid, algorithmGuid) || other.algorithmGuid == algorithmGuid)&&(identical(other.routingType, routingType) || other.routingType == routingType)&&(identical(other.algorithmName, algorithmName) || other.algorithmName == algorithmName)&&(identical(other.voiceCount, voiceCount) || other.voiceCount == voiceCount)&&(identical(other.requiresGateInputs, requiresGateInputs) || other.requiresGateInputs == requiresGateInputs)&&(identical(other.usesVirtualCvPorts, usesVirtualCvPorts) || other.usesVirtualCvPorts == usesVirtualCvPorts)&&(identical(other.virtualCvPortsPerVoice, virtualCvPortsPerVoice) || other.virtualCvPortsPerVoice == virtualCvPortsPerVoice)&&(identical(other.channelCount, channelCount) || other.channelCount == channelCount)&&(identical(other.supportsStereo, supportsStereo) || other.supportsStereo == supportsStereo)&&(identical(other.allowsIndependentChannels, allowsIndependentChannels) || other.allowsIndependentChannels == allowsIndependentChannels)&&(identical(other.createMasterMix, createMasterMix) || other.createMasterMix == createMasterMix)&&const DeepCollectionEquality().equals(other.supportedPortTypes, supportedPortTypes)&&(identical(other.portNamePrefix, portNamePrefix) || other.portNamePrefix == portNamePrefix)&&const DeepCollectionEquality().equals(other.customProperties, customProperties)&&const DeepCollectionEquality().equals(other.routingConstraints, routingConstraints));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,algorithmGuid,routingType,algorithmName,voiceCount,requiresGateInputs,usesVirtualCvPorts,virtualCvPortsPerVoice,channelCount,supportsStereo,allowsIndependentChannels,createMasterMix,const DeepCollectionEquality().hash(supportedPortTypes),portNamePrefix,const DeepCollectionEquality().hash(customProperties),const DeepCollectionEquality().hash(routingConstraints));

@override
String toString() {
  return 'AlgorithmRoutingMetadata(algorithmGuid: $algorithmGuid, routingType: $routingType, algorithmName: $algorithmName, voiceCount: $voiceCount, requiresGateInputs: $requiresGateInputs, usesVirtualCvPorts: $usesVirtualCvPorts, virtualCvPortsPerVoice: $virtualCvPortsPerVoice, channelCount: $channelCount, supportsStereo: $supportsStereo, allowsIndependentChannels: $allowsIndependentChannels, createMasterMix: $createMasterMix, supportedPortTypes: $supportedPortTypes, portNamePrefix: $portNamePrefix, customProperties: $customProperties, routingConstraints: $routingConstraints)';
}


}

/// @nodoc
abstract mixin class $AlgorithmRoutingMetadataCopyWith<$Res>  {
  factory $AlgorithmRoutingMetadataCopyWith(AlgorithmRoutingMetadata value, $Res Function(AlgorithmRoutingMetadata) _then) = _$AlgorithmRoutingMetadataCopyWithImpl;
@useResult
$Res call({
 String algorithmGuid, RoutingType routingType, String? algorithmName, int voiceCount, bool requiresGateInputs, bool usesVirtualCvPorts, int virtualCvPortsPerVoice, int channelCount, bool supportsStereo, bool allowsIndependentChannels, bool createMasterMix, List<String> supportedPortTypes, String? portNamePrefix, Map<String, dynamic> customProperties, Map<String, dynamic> routingConstraints
});




}
/// @nodoc
class _$AlgorithmRoutingMetadataCopyWithImpl<$Res>
    implements $AlgorithmRoutingMetadataCopyWith<$Res> {
  _$AlgorithmRoutingMetadataCopyWithImpl(this._self, this._then);

  final AlgorithmRoutingMetadata _self;
  final $Res Function(AlgorithmRoutingMetadata) _then;

/// Create a copy of AlgorithmRoutingMetadata
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? algorithmGuid = null,Object? routingType = null,Object? algorithmName = freezed,Object? voiceCount = null,Object? requiresGateInputs = null,Object? usesVirtualCvPorts = null,Object? virtualCvPortsPerVoice = null,Object? channelCount = null,Object? supportsStereo = null,Object? allowsIndependentChannels = null,Object? createMasterMix = null,Object? supportedPortTypes = null,Object? portNamePrefix = freezed,Object? customProperties = null,Object? routingConstraints = null,}) {
  return _then(_self.copyWith(
algorithmGuid: null == algorithmGuid ? _self.algorithmGuid : algorithmGuid // ignore: cast_nullable_to_non_nullable
as String,routingType: null == routingType ? _self.routingType : routingType // ignore: cast_nullable_to_non_nullable
as RoutingType,algorithmName: freezed == algorithmName ? _self.algorithmName : algorithmName // ignore: cast_nullable_to_non_nullable
as String?,voiceCount: null == voiceCount ? _self.voiceCount : voiceCount // ignore: cast_nullable_to_non_nullable
as int,requiresGateInputs: null == requiresGateInputs ? _self.requiresGateInputs : requiresGateInputs // ignore: cast_nullable_to_non_nullable
as bool,usesVirtualCvPorts: null == usesVirtualCvPorts ? _self.usesVirtualCvPorts : usesVirtualCvPorts // ignore: cast_nullable_to_non_nullable
as bool,virtualCvPortsPerVoice: null == virtualCvPortsPerVoice ? _self.virtualCvPortsPerVoice : virtualCvPortsPerVoice // ignore: cast_nullable_to_non_nullable
as int,channelCount: null == channelCount ? _self.channelCount : channelCount // ignore: cast_nullable_to_non_nullable
as int,supportsStereo: null == supportsStereo ? _self.supportsStereo : supportsStereo // ignore: cast_nullable_to_non_nullable
as bool,allowsIndependentChannels: null == allowsIndependentChannels ? _self.allowsIndependentChannels : allowsIndependentChannels // ignore: cast_nullable_to_non_nullable
as bool,createMasterMix: null == createMasterMix ? _self.createMasterMix : createMasterMix // ignore: cast_nullable_to_non_nullable
as bool,supportedPortTypes: null == supportedPortTypes ? _self.supportedPortTypes : supportedPortTypes // ignore: cast_nullable_to_non_nullable
as List<String>,portNamePrefix: freezed == portNamePrefix ? _self.portNamePrefix : portNamePrefix // ignore: cast_nullable_to_non_nullable
as String?,customProperties: null == customProperties ? _self.customProperties : customProperties // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,routingConstraints: null == routingConstraints ? _self.routingConstraints : routingConstraints // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}

}


/// Adds pattern-matching-related methods to [AlgorithmRoutingMetadata].
extension AlgorithmRoutingMetadataPatterns on AlgorithmRoutingMetadata {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AlgorithmRoutingMetadata value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AlgorithmRoutingMetadata() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AlgorithmRoutingMetadata value)  $default,){
final _that = this;
switch (_that) {
case _AlgorithmRoutingMetadata():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AlgorithmRoutingMetadata value)?  $default,){
final _that = this;
switch (_that) {
case _AlgorithmRoutingMetadata() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String algorithmGuid,  RoutingType routingType,  String? algorithmName,  int voiceCount,  bool requiresGateInputs,  bool usesVirtualCvPorts,  int virtualCvPortsPerVoice,  int channelCount,  bool supportsStereo,  bool allowsIndependentChannels,  bool createMasterMix,  List<String> supportedPortTypes,  String? portNamePrefix,  Map<String, dynamic> customProperties,  Map<String, dynamic> routingConstraints)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AlgorithmRoutingMetadata() when $default != null:
return $default(_that.algorithmGuid,_that.routingType,_that.algorithmName,_that.voiceCount,_that.requiresGateInputs,_that.usesVirtualCvPorts,_that.virtualCvPortsPerVoice,_that.channelCount,_that.supportsStereo,_that.allowsIndependentChannels,_that.createMasterMix,_that.supportedPortTypes,_that.portNamePrefix,_that.customProperties,_that.routingConstraints);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String algorithmGuid,  RoutingType routingType,  String? algorithmName,  int voiceCount,  bool requiresGateInputs,  bool usesVirtualCvPorts,  int virtualCvPortsPerVoice,  int channelCount,  bool supportsStereo,  bool allowsIndependentChannels,  bool createMasterMix,  List<String> supportedPortTypes,  String? portNamePrefix,  Map<String, dynamic> customProperties,  Map<String, dynamic> routingConstraints)  $default,) {final _that = this;
switch (_that) {
case _AlgorithmRoutingMetadata():
return $default(_that.algorithmGuid,_that.routingType,_that.algorithmName,_that.voiceCount,_that.requiresGateInputs,_that.usesVirtualCvPorts,_that.virtualCvPortsPerVoice,_that.channelCount,_that.supportsStereo,_that.allowsIndependentChannels,_that.createMasterMix,_that.supportedPortTypes,_that.portNamePrefix,_that.customProperties,_that.routingConstraints);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String algorithmGuid,  RoutingType routingType,  String? algorithmName,  int voiceCount,  bool requiresGateInputs,  bool usesVirtualCvPorts,  int virtualCvPortsPerVoice,  int channelCount,  bool supportsStereo,  bool allowsIndependentChannels,  bool createMasterMix,  List<String> supportedPortTypes,  String? portNamePrefix,  Map<String, dynamic> customProperties,  Map<String, dynamic> routingConstraints)?  $default,) {final _that = this;
switch (_that) {
case _AlgorithmRoutingMetadata() when $default != null:
return $default(_that.algorithmGuid,_that.routingType,_that.algorithmName,_that.voiceCount,_that.requiresGateInputs,_that.usesVirtualCvPorts,_that.virtualCvPortsPerVoice,_that.channelCount,_that.supportsStereo,_that.allowsIndependentChannels,_that.createMasterMix,_that.supportedPortTypes,_that.portNamePrefix,_that.customProperties,_that.routingConstraints);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AlgorithmRoutingMetadata implements AlgorithmRoutingMetadata {
  const _AlgorithmRoutingMetadata({required this.algorithmGuid, required this.routingType, this.algorithmName, this.voiceCount = 1, this.requiresGateInputs = false, this.usesVirtualCvPorts = false, this.virtualCvPortsPerVoice = 2, this.channelCount = 1, this.supportsStereo = false, this.allowsIndependentChannels = true, this.createMasterMix = true, final  List<String> supportedPortTypes = const [], this.portNamePrefix, final  Map<String, dynamic> customProperties = const {}, final  Map<String, dynamic> routingConstraints = const {}}): _supportedPortTypes = supportedPortTypes,_customProperties = customProperties,_routingConstraints = routingConstraints;
  factory _AlgorithmRoutingMetadata.fromJson(Map<String, dynamic> json) => _$AlgorithmRoutingMetadataFromJson(json);

/// Unique identifier for the algorithm
@override final  String algorithmGuid;
/// The type of routing this algorithm requires
@override final  RoutingType routingType;
/// Human-readable name for debugging/logging
@override final  String? algorithmName;
// === Polyphonic Algorithm Properties ===
/// Number of polyphonic voices (relevant for polyphonic routing)
/// Default: 1 (monophonic)
@override@JsonKey() final  int voiceCount;
/// Whether the algorithm requires gate/trigger inputs for each voice
@override@JsonKey() final  bool requiresGateInputs;
/// Whether the algorithm uses virtual CV ports for modulation
@override@JsonKey() final  bool usesVirtualCvPorts;
/// Number of virtual CV ports per voice (when usesVirtualCvPorts is true)
@override@JsonKey() final  int virtualCvPortsPerVoice;
// === Multi-Channel Algorithm Properties ===
/// Number of channels (relevant for multi-channel routing)
/// For normal algorithms: 1, for width-based algorithms: N
@override@JsonKey() final  int channelCount;
/// Whether the algorithm supports stereo channel pairing
@override@JsonKey() final  bool supportsStereo;
/// Whether channels can be independently routed
@override@JsonKey() final  bool allowsIndependentChannels;
/// Whether to create master mix outputs for multi-channel algorithms
@override@JsonKey() final  bool createMasterMix;
// === Common Properties ===
/// Port types that this algorithm supports
 final  List<String> _supportedPortTypes;
// === Common Properties ===
/// Port types that this algorithm supports
@override@JsonKey() List<String> get supportedPortTypes {
  if (_supportedPortTypes is EqualUnmodifiableListView) return _supportedPortTypes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_supportedPortTypes);
}

/// Base name prefix for generated ports
@override final  String? portNamePrefix;
/// Additional algorithm-specific properties for extensibility
///
/// This map allows for future routing requirements without breaking
/// the existing interface. New routing implementations can check for
/// specific keys in this map to enable additional behavior.
 final  Map<String, dynamic> _customProperties;
/// Additional algorithm-specific properties for extensibility
///
/// This map allows for future routing requirements without breaking
/// the existing interface. New routing implementations can check for
/// specific keys in this map to enable additional behavior.
@override@JsonKey() Map<String, dynamic> get customProperties {
  if (_customProperties is EqualUnmodifiableMapView) return _customProperties;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_customProperties);
}

/// Routing constraints or special requirements
///
/// Examples:
/// - 'maxConnections': 8
/// - 'requiresClockInput': true
/// - 'bypassable': true
 final  Map<String, dynamic> _routingConstraints;
/// Routing constraints or special requirements
///
/// Examples:
/// - 'maxConnections': 8
/// - 'requiresClockInput': true
/// - 'bypassable': true
@override@JsonKey() Map<String, dynamic> get routingConstraints {
  if (_routingConstraints is EqualUnmodifiableMapView) return _routingConstraints;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_routingConstraints);
}


/// Create a copy of AlgorithmRoutingMetadata
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AlgorithmRoutingMetadataCopyWith<_AlgorithmRoutingMetadata> get copyWith => __$AlgorithmRoutingMetadataCopyWithImpl<_AlgorithmRoutingMetadata>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AlgorithmRoutingMetadataToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AlgorithmRoutingMetadata&&(identical(other.algorithmGuid, algorithmGuid) || other.algorithmGuid == algorithmGuid)&&(identical(other.routingType, routingType) || other.routingType == routingType)&&(identical(other.algorithmName, algorithmName) || other.algorithmName == algorithmName)&&(identical(other.voiceCount, voiceCount) || other.voiceCount == voiceCount)&&(identical(other.requiresGateInputs, requiresGateInputs) || other.requiresGateInputs == requiresGateInputs)&&(identical(other.usesVirtualCvPorts, usesVirtualCvPorts) || other.usesVirtualCvPorts == usesVirtualCvPorts)&&(identical(other.virtualCvPortsPerVoice, virtualCvPortsPerVoice) || other.virtualCvPortsPerVoice == virtualCvPortsPerVoice)&&(identical(other.channelCount, channelCount) || other.channelCount == channelCount)&&(identical(other.supportsStereo, supportsStereo) || other.supportsStereo == supportsStereo)&&(identical(other.allowsIndependentChannels, allowsIndependentChannels) || other.allowsIndependentChannels == allowsIndependentChannels)&&(identical(other.createMasterMix, createMasterMix) || other.createMasterMix == createMasterMix)&&const DeepCollectionEquality().equals(other._supportedPortTypes, _supportedPortTypes)&&(identical(other.portNamePrefix, portNamePrefix) || other.portNamePrefix == portNamePrefix)&&const DeepCollectionEquality().equals(other._customProperties, _customProperties)&&const DeepCollectionEquality().equals(other._routingConstraints, _routingConstraints));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,algorithmGuid,routingType,algorithmName,voiceCount,requiresGateInputs,usesVirtualCvPorts,virtualCvPortsPerVoice,channelCount,supportsStereo,allowsIndependentChannels,createMasterMix,const DeepCollectionEquality().hash(_supportedPortTypes),portNamePrefix,const DeepCollectionEquality().hash(_customProperties),const DeepCollectionEquality().hash(_routingConstraints));

@override
String toString() {
  return 'AlgorithmRoutingMetadata(algorithmGuid: $algorithmGuid, routingType: $routingType, algorithmName: $algorithmName, voiceCount: $voiceCount, requiresGateInputs: $requiresGateInputs, usesVirtualCvPorts: $usesVirtualCvPorts, virtualCvPortsPerVoice: $virtualCvPortsPerVoice, channelCount: $channelCount, supportsStereo: $supportsStereo, allowsIndependentChannels: $allowsIndependentChannels, createMasterMix: $createMasterMix, supportedPortTypes: $supportedPortTypes, portNamePrefix: $portNamePrefix, customProperties: $customProperties, routingConstraints: $routingConstraints)';
}


}

/// @nodoc
abstract mixin class _$AlgorithmRoutingMetadataCopyWith<$Res> implements $AlgorithmRoutingMetadataCopyWith<$Res> {
  factory _$AlgorithmRoutingMetadataCopyWith(_AlgorithmRoutingMetadata value, $Res Function(_AlgorithmRoutingMetadata) _then) = __$AlgorithmRoutingMetadataCopyWithImpl;
@override @useResult
$Res call({
 String algorithmGuid, RoutingType routingType, String? algorithmName, int voiceCount, bool requiresGateInputs, bool usesVirtualCvPorts, int virtualCvPortsPerVoice, int channelCount, bool supportsStereo, bool allowsIndependentChannels, bool createMasterMix, List<String> supportedPortTypes, String? portNamePrefix, Map<String, dynamic> customProperties, Map<String, dynamic> routingConstraints
});




}
/// @nodoc
class __$AlgorithmRoutingMetadataCopyWithImpl<$Res>
    implements _$AlgorithmRoutingMetadataCopyWith<$Res> {
  __$AlgorithmRoutingMetadataCopyWithImpl(this._self, this._then);

  final _AlgorithmRoutingMetadata _self;
  final $Res Function(_AlgorithmRoutingMetadata) _then;

/// Create a copy of AlgorithmRoutingMetadata
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? algorithmGuid = null,Object? routingType = null,Object? algorithmName = freezed,Object? voiceCount = null,Object? requiresGateInputs = null,Object? usesVirtualCvPorts = null,Object? virtualCvPortsPerVoice = null,Object? channelCount = null,Object? supportsStereo = null,Object? allowsIndependentChannels = null,Object? createMasterMix = null,Object? supportedPortTypes = null,Object? portNamePrefix = freezed,Object? customProperties = null,Object? routingConstraints = null,}) {
  return _then(_AlgorithmRoutingMetadata(
algorithmGuid: null == algorithmGuid ? _self.algorithmGuid : algorithmGuid // ignore: cast_nullable_to_non_nullable
as String,routingType: null == routingType ? _self.routingType : routingType // ignore: cast_nullable_to_non_nullable
as RoutingType,algorithmName: freezed == algorithmName ? _self.algorithmName : algorithmName // ignore: cast_nullable_to_non_nullable
as String?,voiceCount: null == voiceCount ? _self.voiceCount : voiceCount // ignore: cast_nullable_to_non_nullable
as int,requiresGateInputs: null == requiresGateInputs ? _self.requiresGateInputs : requiresGateInputs // ignore: cast_nullable_to_non_nullable
as bool,usesVirtualCvPorts: null == usesVirtualCvPorts ? _self.usesVirtualCvPorts : usesVirtualCvPorts // ignore: cast_nullable_to_non_nullable
as bool,virtualCvPortsPerVoice: null == virtualCvPortsPerVoice ? _self.virtualCvPortsPerVoice : virtualCvPortsPerVoice // ignore: cast_nullable_to_non_nullable
as int,channelCount: null == channelCount ? _self.channelCount : channelCount // ignore: cast_nullable_to_non_nullable
as int,supportsStereo: null == supportsStereo ? _self.supportsStereo : supportsStereo // ignore: cast_nullable_to_non_nullable
as bool,allowsIndependentChannels: null == allowsIndependentChannels ? _self.allowsIndependentChannels : allowsIndependentChannels // ignore: cast_nullable_to_non_nullable
as bool,createMasterMix: null == createMasterMix ? _self.createMasterMix : createMasterMix // ignore: cast_nullable_to_non_nullable
as bool,supportedPortTypes: null == supportedPortTypes ? _self._supportedPortTypes : supportedPortTypes // ignore: cast_nullable_to_non_nullable
as List<String>,portNamePrefix: freezed == portNamePrefix ? _self.portNamePrefix : portNamePrefix // ignore: cast_nullable_to_non_nullable
as String?,customProperties: null == customProperties ? _self._customProperties : customProperties // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,routingConstraints: null == routingConstraints ? _self._routingConstraints : routingConstraints // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}


}

// dart format on
