import 'package:nt_helper/cubit/disting_cubit.dart';
import 'package:nt_helper/domain/disting_nt_sysex.dart';
import 'models/port.dart';
import 'multi_channel_algorithm_routing.dart';

/// Routing implementation for the Compressor algorithm.
///
/// The Compressor always works as an insert effect: the output replaces the
/// input signal on the same bus. For each non-sidechain input parameter a
/// virtual output port is created on the same bus with OutputMode.replace.
/// The Reduction output (if present) is handled normally with its mode parameter.
class CompressorAlgorithmRouting extends MultiChannelAlgorithmRouting {
  static bool canHandle(Slot slot) => slot.algorithm.guid == 'comp';

  CompressorAlgorithmRouting({required super.config, super.validator});

  static CompressorAlgorithmRouting createFromSlot(
    Slot slot, {
    required Map<String, int> ioParameters,
    Map<String, int>? modeParameters,
    Map<String, ({int parameterNumber, int value})>? modeParametersWithNumbers,
    String? algorithmUuid,
  }) {
    final config = _buildInsertEffectConfig(
      slot,
      guid: 'comp',
      algorithmUuid: algorithmUuid,
      modeParameters: modeParameters,
      modeParametersWithNumbers: modeParametersWithNumbers,
      includeOutputPorts: true,
    );
    return CompressorAlgorithmRouting(config: config);
  }
}

/// Routing implementation for the Noise Gate algorithm.
///
/// The Noise Gate always works as an insert effect: the output replaces the
/// input signal on the same bus. For each non-sidechain input parameter a
/// virtual output port is created on the same bus with OutputMode.replace.
class NoiseGateAlgorithmRouting extends MultiChannelAlgorithmRouting {
  static bool canHandle(Slot slot) => slot.algorithm.guid == 'nsgt';

  NoiseGateAlgorithmRouting({required super.config, super.validator});

  static NoiseGateAlgorithmRouting createFromSlot(
    Slot slot, {
    required Map<String, int> ioParameters,
    Map<String, int>? modeParameters,
    Map<String, ({int parameterNumber, int value})>? modeParametersWithNumbers,
    String? algorithmUuid,
  }) {
    final config = _buildInsertEffectConfig(
      slot,
      guid: 'nsgt',
      algorithmUuid: algorithmUuid,
      modeParameters: modeParameters,
      modeParametersWithNumbers: modeParametersWithNumbers,
      includeOutputPorts: false,
    );
    return NoiseGateAlgorithmRouting(config: config);
  }
}

/// Shared configuration builder for in-place insert effects.
///
/// For each channel:
/// - Input parameters that are NOT sidechains get an input port + virtual
///   replace output on the same bus (when busValue > 0).
/// - Sidechain inputs get an input port only.
/// - isOutput parameters are included when [includeOutputPorts] is true
///   (Compressor has a Reduction output; Noise Gate does not).
MultiChannelAlgorithmConfig _buildInsertEffectConfig(
  Slot slot, {
  required String guid,
  required String? algorithmUuid,
  required Map<String, int>? modeParameters,
  required Map<String, ({int parameterNumber, int value})>?
  modeParametersWithNumbers,
  required bool includeOutputPorts,
}) {
  // Count channels by finding highest N: prefix in parameter names.
  int channelCount = 0;
  for (final param in slot.parameters) {
    final match = RegExp(r'^(\d+):').firstMatch(param.name);
    if (match != null) {
      final n = int.parse(match.group(1)!);
      if (n > channelCount) channelCount = n;
    }
  }

  final inputPorts = <Map<String, Object?>>[];
  final outputPorts = <Map<String, Object?>>[];

  final valueByParam = <int, int>{
    for (final v in slot.values) v.parameterNumber: v.value,
  };

  for (int channel = 1; channel <= channelCount; channel++) {
    for (final param in slot.parameters) {
      if (!param.isInput) continue;
      final match = RegExp(r'^(\d+):').firstMatch(param.name);
      if (match == null || int.parse(match.group(1)!) != channel) continue;

      final busValue =
          valueByParam[param.parameterNumber] ?? param.defaultValue;
      final isSidechain = param.name.toLowerCase().contains('sidechain');
      final portTypeStr = param.isAudio ? 'audio' : 'cv';

      inputPorts.add({
        'id':
            '${algorithmUuid ?? guid}_ch${channel}_in_${param.parameterNumber}',
        'name': param.name,
        'type': portTypeStr,
        'busParam': param.name,
        'busValue': busValue,
        'parameterNumber': param.parameterNumber,
      });

      // Sidechain is read-only — no virtual replace output.
      if (!isSidechain && busValue > 0) {
        outputPorts.add({
          'id':
              '${algorithmUuid ?? guid}_ch${channel}_vout_${param.parameterNumber}',
          'name': '${param.name} (out)',
          'type': portTypeStr,
          'busParam': null,
          'busValue': busValue,
          'parameterNumber': -param.parameterNumber - 1,
          'outputMode': 'replace',
          'modeParameterNumber': null,
        });
      }
    }
  }

  // Handle isOutput parameters (e.g. Reduction output on Compressor).
  if (includeOutputPorts) {
    for (final param in slot.parameters) {
      if (!param.isOutput) continue;

      final busValue =
          valueByParam[param.parameterNumber] ?? param.defaultValue;
      final portTypeStr = param.isAudio ? 'audio' : 'cv';

      int? modeParameterNumber;
      String? outputMode;

      for (final entry in slot.outputModeMap.entries) {
        if (entry.value.contains(param.parameterNumber)) {
          modeParameterNumber = entry.key;
          final modeValue = slot.values
              .firstWhere(
                (v) => v.parameterNumber == entry.key,
                orElse: () => ParameterValue(
                  algorithmIndex: slot.algorithm.algorithmIndex,
                  parameterNumber: entry.key,
                  value: 0,
                ),
              )
              .value;
          outputMode = modeValue == 1 ? 'replace' : 'add';
          break;
        }
      }

      // Offline fallback when outputModeMap is empty.
      if (slot.outputModeMap.isEmpty && modeParameters != null) {
        final possibleNames = [
          '${param.name} mode',
          '${param.name.split(' ').first} mode',
          'Output mode',
        ];
        for (final name in possibleNames) {
          if (modeParameters.containsKey(name)) {
            outputMode =
                (modeParameters[name] == 1) ? 'replace' : 'add';
            if (modeParametersWithNumbers?.containsKey(name) == true) {
              modeParameterNumber =
                  modeParametersWithNumbers![name]!.parameterNumber;
            }
            break;
          }
        }
      }

      final port = <String, Object?>{
        'id': '${algorithmUuid ?? guid}_ch_out_${param.parameterNumber}',
        'name': param.name,
        'type': portTypeStr,
        'busParam': param.name,
        'busValue': busValue,
        'parameterNumber': param.parameterNumber,
      };
      if (outputMode != null) port['outputMode'] = outputMode;
      if (modeParameterNumber != null) {
        port['modeParameterNumber'] = modeParameterNumber;
      }
      outputPorts.add(port);
    }
  }

  return MultiChannelAlgorithmConfig(
    channelCount: channelCount > 0 ? channelCount : 1,
    supportsStereoChannels: false,
    allowsIndependentChannels: true,
    supportedPortTypes: [PortType.audio],
    portNamePrefix: 'Channel',
    createMasterMix: false,
    algorithmProperties: {
      'algorithmGuid': slot.algorithm.guid,
      'algorithmName': slot.algorithm.name,
      'algorithmUuid': algorithmUuid,
      'channelCount': channelCount,
      'inputs': inputPorts,
      'outputs': outputPorts,
    },
  );
}
