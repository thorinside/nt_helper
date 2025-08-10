// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'algorithm_specification.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AlgorithmSpecification _$AlgorithmSpecificationFromJson(
  Map<String, dynamic> json,
) => _AlgorithmSpecification(
  name: json['name'] as String,
  unit: json['unit'] as String?,
  value: json['value'],
  description: json['description'] as String?,
  min: json['min'],
  max: json['max'],
);

Map<String, dynamic> _$AlgorithmSpecificationToJson(
  _AlgorithmSpecification instance,
) => <String, dynamic>{
  'name': instance.name,
  'unit': instance.unit,
  'value': instance.value,
  'description': instance.description,
  'min': instance.min,
  'max': instance.max,
};
