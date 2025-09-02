// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'routing_state.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_RoutingState _$RoutingStateFromJson(Map<String, dynamic> json) =>
    _RoutingState(
      status:
          $enumDecodeNullable(_$RoutingSystemStatusEnumMap, json['status']) ??
          RoutingSystemStatus.uninitialized,
      inputPorts:
          (json['inputPorts'] as List<dynamic>?)
              ?.map((e) => Port.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      outputPorts:
          (json['outputPorts'] as List<dynamic>?)
              ?.map((e) => Port.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      connections:
          (json['connections'] as List<dynamic>?)
              ?.map((e) => Connection.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      errorMessage: json['errorMessage'] as String?,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      lastUpdated: json['lastUpdated'] == null
          ? null
          : DateTime.parse(json['lastUpdated'] as String),
      isReadOnly: json['isReadOnly'] as bool? ?? false,
      configuration: json['configuration'] as Map<String, dynamic>?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$RoutingStateToJson(_RoutingState instance) =>
    <String, dynamic>{
      'status': _$RoutingSystemStatusEnumMap[instance.status]!,
      'inputPorts': instance.inputPorts,
      'outputPorts': instance.outputPorts,
      'connections': instance.connections,
      'errorMessage': instance.errorMessage,
      'createdAt': instance.createdAt?.toIso8601String(),
      'lastUpdated': instance.lastUpdated?.toIso8601String(),
      'isReadOnly': instance.isReadOnly,
      'configuration': instance.configuration,
      'metadata': instance.metadata,
    };

const _$RoutingSystemStatusEnumMap = {
  RoutingSystemStatus.uninitialized: 'uninitialized',
  RoutingSystemStatus.initializing: 'initializing',
  RoutingSystemStatus.ready: 'ready',
  RoutingSystemStatus.updating: 'updating',
  RoutingSystemStatus.error: 'error',
  RoutingSystemStatus.disposing: 'disposing',
};
