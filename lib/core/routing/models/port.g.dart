// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'port.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Port _$PortFromJson(Map<String, dynamic> json) => _Port(
  id: json['id'] as String,
  name: json['name'] as String,
  type: $enumDecode(_$PortTypeEnumMap, json['type']),
  direction: $enumDecode(_$PortDirectionEnumMap, json['direction']),
  description: json['description'] as String?,
  constraints: json['constraints'] as Map<String, dynamic>?,
  isActive: json['isActive'] as bool? ?? true,
  metadata: json['metadata'] as Map<String, dynamic>?,
);

Map<String, dynamic> _$PortToJson(_Port instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'type': _$PortTypeEnumMap[instance.type]!,
  'direction': _$PortDirectionEnumMap[instance.direction]!,
  'description': instance.description,
  'constraints': instance.constraints,
  'isActive': instance.isActive,
  'metadata': instance.metadata,
};

const _$PortTypeEnumMap = {
  PortType.audio: 'audio',
  PortType.cv: 'cv',
  PortType.gate: 'gate',
  PortType.clock: 'clock',
  PortType.midi: 'midi',
  PortType.data: 'data',
};

const _$PortDirectionEnumMap = {
  PortDirection.input: 'input',
  PortDirection.output: 'output',
  PortDirection.bidirectional: 'bidirectional',
};
