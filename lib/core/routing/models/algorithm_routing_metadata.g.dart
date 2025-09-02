// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'algorithm_routing_metadata.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AlgorithmRoutingMetadata _$AlgorithmRoutingMetadataFromJson(
  Map<String, dynamic> json,
) => _AlgorithmRoutingMetadata(
  algorithmGuid: json['algorithmGuid'] as String,
  routingType: $enumDecode(_$RoutingTypeEnumMap, json['routingType']),
  algorithmName: json['algorithmName'] as String?,
  voiceCount: (json['voiceCount'] as num?)?.toInt() ?? 1,
  requiresGateInputs: json['requiresGateInputs'] as bool? ?? false,
  usesVirtualCvPorts: json['usesVirtualCvPorts'] as bool? ?? false,
  virtualCvPortsPerVoice:
      (json['virtualCvPortsPerVoice'] as num?)?.toInt() ?? 2,
  channelCount: (json['channelCount'] as num?)?.toInt() ?? 1,
  supportsStereo: json['supportsStereo'] as bool? ?? false,
  allowsIndependentChannels: json['allowsIndependentChannels'] as bool? ?? true,
  createMasterMix: json['createMasterMix'] as bool? ?? true,
  supportedPortTypes:
      (json['supportedPortTypes'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  portNamePrefix: json['portNamePrefix'] as String?,
  customProperties:
      json['customProperties'] as Map<String, dynamic>? ?? const {},
  routingConstraints:
      json['routingConstraints'] as Map<String, dynamic>? ?? const {},
);

Map<String, dynamic> _$AlgorithmRoutingMetadataToJson(
  _AlgorithmRoutingMetadata instance,
) => <String, dynamic>{
  'algorithmGuid': instance.algorithmGuid,
  'routingType': _$RoutingTypeEnumMap[instance.routingType]!,
  'algorithmName': instance.algorithmName,
  'voiceCount': instance.voiceCount,
  'requiresGateInputs': instance.requiresGateInputs,
  'usesVirtualCvPorts': instance.usesVirtualCvPorts,
  'virtualCvPortsPerVoice': instance.virtualCvPortsPerVoice,
  'channelCount': instance.channelCount,
  'supportsStereo': instance.supportsStereo,
  'allowsIndependentChannels': instance.allowsIndependentChannels,
  'createMasterMix': instance.createMasterMix,
  'supportedPortTypes': instance.supportedPortTypes,
  'portNamePrefix': instance.portNamePrefix,
  'customProperties': instance.customProperties,
  'routingConstraints': instance.routingConstraints,
};

const _$RoutingTypeEnumMap = {
  RoutingType.polyphonic: 'polyphonic',
  RoutingType.multiChannel: 'multiChannel',
};
