// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'port_metadata.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

HardwarePortMetadata _$HardwarePortMetadataFromJson(
  Map<String, dynamic> json,
) => HardwarePortMetadata(
  busNumber: (json['busNumber'] as num).toInt(),
  isInput: json['isInput'] as bool,
  jackNumber: (json['jackNumber'] as num).toInt(),
  $type: json['runtimeType'] as String?,
);

Map<String, dynamic> _$HardwarePortMetadataToJson(
  HardwarePortMetadata instance,
) => <String, dynamic>{
  'busNumber': instance.busNumber,
  'isInput': instance.isInput,
  'jackNumber': instance.jackNumber,
  'runtimeType': instance.$type,
};

AlgorithmPortMetadata _$AlgorithmPortMetadataFromJson(
  Map<String, dynamic> json,
) => AlgorithmPortMetadata(
  algorithmId: json['algorithmId'] as String,
  parameterNumber: (json['parameterNumber'] as num).toInt(),
  parameterName: json['parameterName'] as String,
  busNumber: (json['busNumber'] as num?)?.toInt(),
  voiceNumber: json['voiceNumber'] as String?,
  channel: json['channel'] as String?,
  $type: json['runtimeType'] as String?,
);

Map<String, dynamic> _$AlgorithmPortMetadataToJson(
  AlgorithmPortMetadata instance,
) => <String, dynamic>{
  'algorithmId': instance.algorithmId,
  'parameterNumber': instance.parameterNumber,
  'parameterName': instance.parameterName,
  'busNumber': instance.busNumber,
  'voiceNumber': instance.voiceNumber,
  'channel': instance.channel,
  'runtimeType': instance.$type,
};
