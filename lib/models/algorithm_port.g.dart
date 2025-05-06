// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'algorithm_port.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AlgorithmPortImpl _$$AlgorithmPortImplFromJson(Map<String, dynamic> json) =>
    _$AlgorithmPortImpl(
      id: json['id'] as String?,
      name: json['name'] as String,
      description: json['description'] as String?,
      busIdRef: json['busIdRef'] as String?,
      channelCountRef: json['channelCountRef'] as String?,
      isPerChannel: json['isPerChannel'] as bool?,
    );

Map<String, dynamic> _$$AlgorithmPortImplToJson(_$AlgorithmPortImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'busIdRef': instance.busIdRef,
      'channelCountRef': instance.channelCountRef,
      'isPerChannel': instance.isPerChannel,
    };
