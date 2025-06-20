// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plugin_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PluginInfo _$PluginInfoFromJson(Map<String, dynamic> json) => _PluginInfo(
      name: json['name'] as String,
      path: json['path'] as String,
      type: $enumDecode(_$PluginTypeEnumMap, json['type']),
      sizeBytes: (json['sizeBytes'] as num).toInt(),
      description: json['description'] as String?,
      lastModified: json['lastModified'] == null
          ? null
          : DateTime.parse(json['lastModified'] as String),
    );

Map<String, dynamic> _$PluginInfoToJson(_PluginInfo instance) =>
    <String, dynamic>{
      'name': instance.name,
      'path': instance.path,
      'type': _$PluginTypeEnumMap[instance.type]!,
      'sizeBytes': instance.sizeBytes,
      'description': instance.description,
      'lastModified': instance.lastModified?.toIso8601String(),
    };

const _$PluginTypeEnumMap = {
  PluginType.lua: 'lua',
  PluginType.threePot: 'threePot',
  PluginType.cpp: 'cpp',
};
