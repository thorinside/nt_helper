// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'algorithm_specification.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AlgorithmSpecificationImpl _$$AlgorithmSpecificationImplFromJson(
        Map<String, dynamic> json) =>
    _$AlgorithmSpecificationImpl(
      name: json['name'] as String,
      unit: json['unit'] as String?,
      value: json['value'],
      description: json['description'] as String?,
      min: json['min'],
      max: json['max'],
    );

Map<String, dynamic> _$$AlgorithmSpecificationImplToJson(
        _$AlgorithmSpecificationImpl instance) =>
    <String, dynamic>{
      'name': instance.name,
      'unit': instance.unit,
      'value': instance.value,
      'description': instance.description,
      'min': instance.min,
      'max': instance.max,
    };
