// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'connection.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Connection _$ConnectionFromJson(Map<String, dynamic> json) => _Connection(
  id: json['id'] as String,
  sourcePortId: json['sourcePortId'] as String,
  destinationPortId: json['destinationPortId'] as String,
  status:
      $enumDecodeNullable(_$ConnectionStatusEnumMap, json['status']) ??
      ConnectionStatus.active,
  name: json['name'] as String?,
  description: json['description'] as String?,
  gain: (json['gain'] as num?)?.toDouble() ?? 1.0,
  isMuted: json['isMuted'] as bool? ?? false,
  isInverted: json['isInverted'] as bool? ?? false,
  delayMs: (json['delayMs'] as num?)?.toDouble() ?? 0.0,
  properties: json['properties'] as Map<String, dynamic>?,
  createdAt: json['createdAt'] == null
      ? null
      : DateTime.parse(json['createdAt'] as String),
  modifiedAt: json['modifiedAt'] == null
      ? null
      : DateTime.parse(json['modifiedAt'] as String),
);

Map<String, dynamic> _$ConnectionToJson(_Connection instance) =>
    <String, dynamic>{
      'id': instance.id,
      'sourcePortId': instance.sourcePortId,
      'destinationPortId': instance.destinationPortId,
      'status': _$ConnectionStatusEnumMap[instance.status]!,
      'name': instance.name,
      'description': instance.description,
      'gain': instance.gain,
      'isMuted': instance.isMuted,
      'isInverted': instance.isInverted,
      'delayMs': instance.delayMs,
      'properties': instance.properties,
      'createdAt': instance.createdAt?.toIso8601String(),
      'modifiedAt': instance.modifiedAt?.toIso8601String(),
    };

const _$ConnectionStatusEnumMap = {
  ConnectionStatus.active: 'active',
  ConnectionStatus.disabled: 'disabled',
  ConnectionStatus.error: 'error',
  ConnectionStatus.connecting: 'connecting',
};
