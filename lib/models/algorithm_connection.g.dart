// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'algorithm_connection.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AlgorithmConnection _$AlgorithmConnectionFromJson(Map<String, dynamic> json) =>
    _AlgorithmConnection(
      id: json['id'] as String,
      sourceAlgorithmIndex: (json['sourceAlgorithmIndex'] as num).toInt(),
      sourcePortId: json['sourcePortId'] as String,
      targetAlgorithmIndex: (json['targetAlgorithmIndex'] as num).toInt(),
      targetPortId: json['targetPortId'] as String,
      busNumber: (json['busNumber'] as num).toInt(),
      connectionType: $enumDecode(
        _$AlgorithmConnectionTypeEnumMap,
        json['connectionType'],
      ),
      isValid: json['isValid'] as bool? ?? true,
      validationMessage: json['validationMessage'] as String?,
      edgeLabel: json['edgeLabel'] as String?,
    );

Map<String, dynamic> _$AlgorithmConnectionToJson(
  _AlgorithmConnection instance,
) => <String, dynamic>{
  'id': instance.id,
  'sourceAlgorithmIndex': instance.sourceAlgorithmIndex,
  'sourcePortId': instance.sourcePortId,
  'targetAlgorithmIndex': instance.targetAlgorithmIndex,
  'targetPortId': instance.targetPortId,
  'busNumber': instance.busNumber,
  'connectionType': _$AlgorithmConnectionTypeEnumMap[instance.connectionType]!,
  'isValid': instance.isValid,
  'validationMessage': instance.validationMessage,
  'edgeLabel': instance.edgeLabel,
};

const _$AlgorithmConnectionTypeEnumMap = {
  AlgorithmConnectionType.audioSignal: 'audioSignal',
  AlgorithmConnectionType.controlVoltage: 'controlVoltage',
  AlgorithmConnectionType.gateTrigger: 'gateTrigger',
  AlgorithmConnectionType.clockTiming: 'clockTiming',
  AlgorithmConnectionType.mixed: 'mixed',
};
