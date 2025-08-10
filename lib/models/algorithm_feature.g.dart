// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'algorithm_feature.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AlgorithmFeature _$AlgorithmFeatureFromJson(Map<String, dynamic> json) =>
    _AlgorithmFeature(
      guid: json['guid'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      parameters:
          (json['parameters'] as List<dynamic>?)
              ?.map(
                (e) => AlgorithmParameter.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const [],
    );

Map<String, dynamic> _$AlgorithmFeatureToJson(_AlgorithmFeature instance) =>
    <String, dynamic>{
      'guid': instance.guid,
      'name': instance.name,
      'description': instance.description,
      'parameters': instance.parameters,
    };
