// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'algorithm_parameter.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AlgorithmParameter _$AlgorithmParameterFromJson(Map<String, dynamic> json) =>
    _AlgorithmParameter(
      name: json['name'] as String,
      unit: json['unit'] as String?,
      min: json['min'],
      max: json['max'],
      defaultValue: json['defaultValue'],
      scope: json['scope'] as String?,
      description: json['description'] as String?,
      values: (json['enumValues'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      type: json['type'] as String?,
      busIdRef: json['busIdRef'] as String?,
      channelCountRef: json['channelCountRef'] as String?,
      isPerChannel: json['isPerChannel'] as bool?,
      isCommon: json['isCommon'] as bool?,
      parameterNumber: (json['parameterNumber'] as num?)?.toInt(),
    );

Map<String, dynamic> _$AlgorithmParameterToJson(_AlgorithmParameter instance) =>
    <String, dynamic>{
      'name': instance.name,
      'unit': instance.unit,
      'min': instance.min,
      'max': instance.max,
      'defaultValue': instance.defaultValue,
      'scope': instance.scope,
      'description': instance.description,
      'enumValues': instance.values,
      'type': instance.type,
      'busIdRef': instance.busIdRef,
      'channelCountRef': instance.channelCountRef,
      'isPerChannel': instance.isPerChannel,
      'isCommon': instance.isCommon,
      'parameterNumber': instance.parameterNumber,
    };
