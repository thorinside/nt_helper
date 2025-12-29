// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'firmware_release.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_FirmwareRelease _$FirmwareReleaseFromJson(Map<String, dynamic> json) =>
    _FirmwareRelease(
      version: json['version'] as String,
      releaseDate: DateTime.parse(json['releaseDate'] as String),
      changelog: (json['changelog'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      downloadUrl: json['downloadUrl'] as String,
    );

Map<String, dynamic> _$FirmwareReleaseToJson(_FirmwareRelease instance) =>
    <String, dynamic>{
      'version': instance.version,
      'releaseDate': instance.releaseDate.toIso8601String(),
      'changelog': instance.changelog,
      'downloadUrl': instance.downloadUrl,
    };
