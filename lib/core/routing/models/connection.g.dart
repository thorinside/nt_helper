// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'connection.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Connection _$ConnectionFromJson(Map<String, dynamic> json) => _Connection(
  id: json['id'] as String,
  sourcePortId: json['sourcePortId'] as String,
  destinationPortId: json['destinationPortId'] as String,
  connectionType: $enumDecode(_$ConnectionTypeEnumMap, json['connectionType']),
  status:
      $enumDecodeNullable(_$ConnectionStatusEnumMap, json['status']) ??
      ConnectionStatus.active,
  isPartial: json['isPartial'] as bool? ?? false,
  busNumber: (json['busNumber'] as num?)?.toInt(),
  busId: json['busId'] as String?,
  busLabel: json['busLabel'] as String?,
  algorithmId: json['algorithmId'] as String?,
  algorithmIndex: (json['algorithmIndex'] as num?)?.toInt(),
  parameterNumber: (json['parameterNumber'] as num?)?.toInt(),
  parameterName: json['parameterName'] as String?,
  portName: json['portName'] as String?,
  signalType: $enumDecodeNullable(_$SignalTypeEnumMap, json['signalType']),
  isOutput: json['isOutput'] as bool? ?? false,
  isBackwardEdge: json['isBackwardEdge'] as bool? ?? false,
  outputMode: $enumDecodeNullable(_$OutputModeEnumMap, json['outputMode']),
  name: json['name'] as String?,
  description: json['description'] as String?,
  gain: (json['gain'] as num?)?.toDouble() ?? 1.0,
  isMuted: json['isMuted'] as bool? ?? false,
  isGhostConnection: json['isGhostConnection'] as bool? ?? false,
  isInverted: json['isInverted'] as bool? ?? false,
  delayMs: (json['delayMs'] as num?)?.toDouble() ?? 0.0,
  createdAt: json['createdAt'] == null
      ? null
      : DateTime.parse(json['createdAt'] as String),
  modifiedAt: json['modifiedAt'] == null
      ? null
      : DateTime.parse(json['modifiedAt'] as String),
);

Map<String, dynamic> _$ConnectionToJson(_Connection instance) =>
    <String, dynamic>{
      'id': instance.id,
      'sourcePortId': instance.sourcePortId,
      'destinationPortId': instance.destinationPortId,
      'connectionType': _$ConnectionTypeEnumMap[instance.connectionType]!,
      'status': _$ConnectionStatusEnumMap[instance.status]!,
      'isPartial': instance.isPartial,
      'busNumber': instance.busNumber,
      'busId': instance.busId,
      'busLabel': instance.busLabel,
      'algorithmId': instance.algorithmId,
      'algorithmIndex': instance.algorithmIndex,
      'parameterNumber': instance.parameterNumber,
      'parameterName': instance.parameterName,
      'portName': instance.portName,
      'signalType': _$SignalTypeEnumMap[instance.signalType],
      'isOutput': instance.isOutput,
      'isBackwardEdge': instance.isBackwardEdge,
      'outputMode': _$OutputModeEnumMap[instance.outputMode],
      'name': instance.name,
      'description': instance.description,
      'gain': instance.gain,
      'isMuted': instance.isMuted,
      'isGhostConnection': instance.isGhostConnection,
      'isInverted': instance.isInverted,
      'delayMs': instance.delayMs,
      'createdAt': instance.createdAt?.toIso8601String(),
      'modifiedAt': instance.modifiedAt?.toIso8601String(),
    };

const _$ConnectionTypeEnumMap = {
  ConnectionType.hardwareInput: 'hardwareInput',
  ConnectionType.hardwareOutput: 'hardwareOutput',
  ConnectionType.algorithmToAlgorithm: 'algorithmToAlgorithm',
  ConnectionType.partialOutputToBus: 'partialOutputToBus',
  ConnectionType.partialBusToInput: 'partialBusToInput',
};

const _$ConnectionStatusEnumMap = {
  ConnectionStatus.active: 'active',
  ConnectionStatus.disabled: 'disabled',
  ConnectionStatus.error: 'error',
  ConnectionStatus.connecting: 'connecting',
};

const _$SignalTypeEnumMap = {
  SignalType.audio: 'audio',
  SignalType.cv: 'cv',
  SignalType.gate: 'gate',
  SignalType.trigger: 'trigger',
  SignalType.unknown: 'unknown',
};

const _$OutputModeEnumMap = {
  OutputMode.add: 'add',
  OutputMode.replace: 'replace',
};
