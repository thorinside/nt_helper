// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'physical_connection.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PhysicalConnection _$PhysicalConnectionFromJson(Map<String, dynamic> json) =>
    _PhysicalConnection(
      id: json['id'] as String,
      sourcePortId: json['sourcePortId'] as String,
      targetPortId: json['targetPortId'] as String,
      busNumber: (json['busNumber'] as num).toInt(),
      isInputConnection: json['isInputConnection'] as bool,
      algorithmIndex: (json['algorithmIndex'] as num).toInt(),
    );

Map<String, dynamic> _$PhysicalConnectionToJson(_PhysicalConnection instance) =>
    <String, dynamic>{
      'id': instance.id,
      'sourcePortId': instance.sourcePortId,
      'targetPortId': instance.targetPortId,
      'busNumber': instance.busNumber,
      'isInputConnection': instance.isInputConnection,
      'algorithmIndex': instance.algorithmIndex,
    };
