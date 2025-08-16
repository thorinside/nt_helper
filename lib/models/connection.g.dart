// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'connection.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Connection _$ConnectionFromJson(Map<String, dynamic> json) => _Connection(
  id: json['id'] as String,
  sourceAlgorithmIndex: (json['sourceAlgorithmIndex'] as num).toInt(),
  sourcePortId: json['sourcePortId'] as String,
  targetAlgorithmIndex: (json['targetAlgorithmIndex'] as num).toInt(),
  targetPortId: json['targetPortId'] as String,
  assignedBus: (json['assignedBus'] as num).toInt(),
  replaceMode: json['replaceMode'] as bool,
  isValid: json['isValid'] as bool? ?? false,
  edgeLabel: json['edgeLabel'] as String?,
);

Map<String, dynamic> _$ConnectionToJson(_Connection instance) =>
    <String, dynamic>{
      'id': instance.id,
      'sourceAlgorithmIndex': instance.sourceAlgorithmIndex,
      'sourcePortId': instance.sourcePortId,
      'targetAlgorithmIndex': instance.targetAlgorithmIndex,
      'targetPortId': instance.targetPortId,
      'assignedBus': instance.assignedBus,
      'replaceMode': instance.replaceMode,
      'isValid': instance.isValid,
      'edgeLabel': instance.edgeLabel,
    };
