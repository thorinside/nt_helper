// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'connection_metadata.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ConnectionMetadata _$ConnectionMetadataFromJson(Map<String, dynamic> json) =>
    _ConnectionMetadata(
      connectionClass: $enumDecode(
        _$ConnectionClassEnumMap,
        json['connectionClass'],
      ),
      busNumber: (json['busNumber'] as num).toInt(),
      signalType: $enumDecode(_$SignalTypeEnumMap, json['signalType']),
      sourceAlgorithmId: json['sourceAlgorithmId'] as String?,
      targetAlgorithmId: json['targetAlgorithmId'] as String?,
      sourceParameterNumber: (json['sourceParameterNumber'] as num?)?.toInt(),
      targetParameterNumber: (json['targetParameterNumber'] as num?)?.toInt(),
      isBackwardEdge: json['isBackwardEdge'] as bool?,
      isValid: json['isValid'] as bool?,
    );

Map<String, dynamic> _$ConnectionMetadataToJson(_ConnectionMetadata instance) =>
    <String, dynamic>{
      'connectionClass': _$ConnectionClassEnumMap[instance.connectionClass]!,
      'busNumber': instance.busNumber,
      'signalType': _$SignalTypeEnumMap[instance.signalType]!,
      'sourceAlgorithmId': instance.sourceAlgorithmId,
      'targetAlgorithmId': instance.targetAlgorithmId,
      'sourceParameterNumber': instance.sourceParameterNumber,
      'targetParameterNumber': instance.targetParameterNumber,
      'isBackwardEdge': instance.isBackwardEdge,
      'isValid': instance.isValid,
    };

const _$ConnectionClassEnumMap = {
  ConnectionClass.hardware: 'hardware',
  ConnectionClass.algorithm: 'algorithm',
  ConnectionClass.user: 'user',
};

const _$SignalTypeEnumMap = {
  SignalType.audio: 'audio',
  SignalType.cv: 'cv',
  SignalType.gate: 'gate',
  SignalType.clock: 'clock',
  SignalType.mixed: 'mixed',
};
