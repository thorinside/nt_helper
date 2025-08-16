// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'node_position.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_NodePosition _$NodePositionFromJson(Map<String, dynamic> json) =>
    _NodePosition(
      algorithmIndex: (json['algorithmIndex'] as num).toInt(),
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      width: (json['width'] as num?)?.toDouble() ?? 200.0,
      height: (json['height'] as num?)?.toDouble() ?? 100.0,
    );

Map<String, dynamic> _$NodePositionToJson(_NodePosition instance) =>
    <String, dynamic>{
      'algorithmIndex': instance.algorithmIndex,
      'x': instance.x,
      'y': instance.y,
      'width': instance.width,
      'height': instance.height,
    };
