// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'algorithm_metadata.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AlgorithmMetadata _$AlgorithmMetadataFromJson(
  Map<String, dynamic> json,
) => _AlgorithmMetadata(
  guid: json['guid'] as String,
  name: json['name'] as String,
  categories: (json['categories'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  description: json['description'] as String,
  shortDescription: json['short_description'] as String?,
  guiDescription: json['gui_description'] as String?,
  useCases:
      (json['use_cases'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  specifications:
      (json['specifications'] as List<dynamic>?)
          ?.map(
            (e) => AlgorithmSpecification.fromJson(e as Map<String, dynamic>),
          )
          .toList() ??
      const [],
  parameters: json['parameters'] == null
      ? const []
      : _parametersFromJson(json['parameters'] as List?),
  features:
      (json['features'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  inputPorts: json['input_ports'] == null
      ? const []
      : _portsFromJson(json['input_ports'] as List),
  outputPorts: json['output_ports'] == null
      ? const []
      : _portsFromJson(json['output_ports'] as List),
);

Map<String, dynamic> _$AlgorithmMetadataToJson(_AlgorithmMetadata instance) =>
    <String, dynamic>{
      'guid': instance.guid,
      'name': instance.name,
      'categories': instance.categories,
      'description': instance.description,
      'short_description': instance.shortDescription,
      'gui_description': instance.guiDescription,
      'use_cases': instance.useCases,
      'specifications': instance.specifications,
      'parameters': instance.parameters,
      'features': instance.features,
      'input_ports': instance.inputPorts,
      'output_ports': instance.outputPorts,
    };
