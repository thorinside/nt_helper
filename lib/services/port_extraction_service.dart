import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:nt_helper/cubit/disting_cubit.dart';
import 'package:nt_helper/domain/disting_nt_sysex.dart';
import 'package:nt_helper/models/algorithm_metadata.dart';
import 'package:nt_helper/models/algorithm_parameter.dart';
import 'package:nt_helper/models/algorithm_port.dart';
import 'package:nt_helper/services/algorithm_metadata_service.dart';

class AlgorithmPortInfo {
  final List<AlgorithmPort> inputPorts;
  final List<AlgorithmPort> outputPorts;
  final Map<String, int> portBusAssignments;

  const AlgorithmPortInfo({
    required this.inputPorts,
    required this.outputPorts,
    required this.portBusAssignments,
  });
}

class _WidthBasedPortResult {
  final List<AlgorithmPort> ports;
  final Map<String, int> busAssignments;

  const _WidthBasedPortResult({
    required this.ports,
    required this.busAssignments,
  });
}

class PortExtractionService {
  final AlgorithmMetadataService _metadataService;

  PortExtractionService(this._metadataService);

  /// Extract ports from live slot data (preferred method)
  AlgorithmPortInfo extractPortsFromSlot(Slot slot) {
    final inputPorts = <AlgorithmPort>[];
    final outputPorts = <AlgorithmPort>[];
    final busAssignments = <String, int>{};

    debugPrint(
      '[PortExtractionService] Extracting ports from live slot data for ${slot.algorithm.name}',
    );

    // Try to get metadata for better port classification
    final metadata = _metadataService.getAlgorithmByGuid(slot.algorithm.guid);

    // Look through all parameters to find bus-type parameters
    for (final paramInfo in slot.parameters) {
      final paramValue = slot.values.firstWhere(
        (v) => v.parameterNumber == paramInfo.parameterNumber,
        orElse: () => ParameterValue.filler(),
      );

      if (_isBusParameter(paramInfo, paramValue)) {
        // Skip gate input parameters for poly algorithms - they'll be handled specially
        if (_isPolyAlgorithm(slot.algorithm.guid) &&
            _isGateInputParameter(paramInfo)) {
          debugPrint(
            '🔍 [PortExtractionService] Skipping gate input parameter "${paramInfo.name}" for poly algorithm',
          );
          continue;
        }

        // Skip audio input parameters for width-aware algorithms - they'll be handled specially
        if (_isWidthAwareAlgorithm(slot.algorithm.guid) &&
            _isAudioInputParameter(paramInfo)) {
          debugPrint(
            '🔍 [PortExtractionService] Skipping audio input parameter "${paramInfo.name}" for width-aware algorithm',
          );
          continue;
        }

        final portId = paramInfo.parameterNumber.toString();
        final port = AlgorithmPort(
          id: portId,
          name: paramInfo.name,
          description: null,
          busIdRef: paramInfo.name,
        );

        final isInput = _isInputParameterFromSlot(
          paramInfo,
          slot.algorithm.guid,
          metadata,
        );
        final isOutput = _isOutputParameterFromSlot(
          paramInfo,
          slot.algorithm.guid,
          metadata,
        );

        debugPrint(
          '🔍 [PortExtractionService] Parameter "${paramInfo.name}" defaultValue=${paramInfo.defaultValue} -> isInput=$isInput, isOutput=$isOutput',
        );

        if (isInput) {
          inputPorts.add(port);
          debugPrint(
            '✅ [PortExtractionService] Added INPUT port: ${paramInfo.name}',
          );
        } else if (isOutput) {
          outputPorts.add(port);
          debugPrint(
            '✅ [PortExtractionService] Added OUTPUT port: ${paramInfo.name}',
          );
        }

        if (paramValue.value > 0) {
          busAssignments[portId] = paramValue.value;
        }
      }
    }

    // Special handling for poly algorithms with gate+CV patterns
    if (_isPolyAlgorithm(slot.algorithm.guid)) {
      final polyPorts = _extractPolyInputPorts(slot);
      inputPorts.addAll(polyPorts);
      debugPrint(
        '[PortExtractionService] Added ${polyPorts.length} poly input ports',
      );
    }

    // Special handling for width-aware algorithms with mono/stereo/multi-channel patterns
    if (_isWidthAwareAlgorithm(slot.algorithm.guid)) {
      final widthResult = _extractWidthBasedInputPorts(slot);
      inputPorts.addAll(widthResult.ports);
      busAssignments.addAll(widthResult.busAssignments);
      debugPrint(
        '[PortExtractionService] Added ${widthResult.ports.length} width-based input ports',
      );
    }

    // Fallback to static metadata if no live parameters found
    if (inputPorts.isEmpty && outputPorts.isEmpty) {
      debugPrint(
        '[PortExtractionService] No bus parameters found in live falling back to static metadata',
      );
      return extractPorts(slot.algorithm.guid);
    }

    debugPrint(
      '[PortExtractionService] Found ${inputPorts.length} inputs, ${outputPorts.length} outputs from live data',
    );

    return AlgorithmPortInfo(
      inputPorts: inputPorts,
      outputPorts: outputPorts,
      portBusAssignments: busAssignments,
    );
  }

  AlgorithmPortInfo extractPorts(String algorithmGuid) {
    final metadata = _metadataService.getAlgorithmByGuid(algorithmGuid);
    if (metadata == null) {
      debugPrint(
        '[PortExtractionService] No metadata found for GUID: "$algorithmGuid"',
      );
      return const AlgorithmPortInfo(
        inputPorts: [],
        outputPorts: [],
        portBusAssignments: {},
      );
    }

    if (metadata.inputPorts.isNotEmpty || metadata.outputPorts.isNotEmpty) {
      return _extractFromPortArrays(metadata);
    }

    final parameters = _metadataService.getExpandedParameters(algorithmGuid);
    return _extractFromParameters(parameters);
  }

  AlgorithmPortInfo _extractFromPortArrays(AlgorithmMetadata metadata) {
    final inputPorts = <AlgorithmPort>[];
    final outputPorts = <AlgorithmPort>[];
    final busAssignments = <String, int>{};

    for (final port in metadata.inputPorts) {
      final processedPort = _processPort(port, metadata.parameters);
      inputPorts.add(processedPort);

      if (port.busIdRef != null) {
        final busNumber = _getBusNumberFromParameter(
          port.busIdRef!,
          metadata.parameters,
        );
        if (busNumber != null) {
          busAssignments[port.id ?? port.name] = busNumber;
        }
      }
    }

    for (final port in metadata.outputPorts) {
      final processedPort = _processPort(port, metadata.parameters);
      outputPorts.add(processedPort);

      if (port.busIdRef != null) {
        final busNumber = _getBusNumberFromParameter(
          port.busIdRef!,
          metadata.parameters,
        );
        if (busNumber != null) {
          busAssignments[port.id ?? port.name] = busNumber;
        }
      }
    }

    return AlgorithmPortInfo(
      inputPorts: inputPorts,
      outputPorts: outputPorts,
      portBusAssignments: busAssignments,
    );
  }

  AlgorithmPortInfo _extractFromParameters(
    List<AlgorithmParameter> parameters,
  ) {
    final inputPorts = <AlgorithmPort>[];
    final outputPorts = <AlgorithmPort>[];
    final busAssignments = <String, int>{};

    for (final param in parameters) {
      if (param.unit == 'bus' || param.type == 'bus') {
        final portId = param.name.replaceAll(' ', '_').toLowerCase();

        if (_isInputParameter(param)) {
          inputPorts.add(
            AlgorithmPort(
              id: portId,
              name: param.name,
              description: param.description,
              busIdRef: param.name,
              isPerChannel: param.isPerChannel,
            ),
          );
        } else if (_isOutputParameter(param)) {
          outputPorts.add(
            AlgorithmPort(
              id: portId,
              name: param.name,
              description: param.description,
              busIdRef: param.name,
              isPerChannel: param.isPerChannel,
            ),
          );
        }

        if (param.defaultValue is int) {
          busAssignments[portId] = param.defaultValue as int;
        }
      }
    }

    if (inputPorts.isEmpty && outputPorts.isEmpty) {
      return _createDefaultPorts();
    }

    return AlgorithmPortInfo(
      inputPorts: inputPorts,
      outputPorts: outputPorts,
      portBusAssignments: busAssignments,
    );
  }

  AlgorithmPort _processPort(
    AlgorithmPort port,
    List<AlgorithmParameter> parameters,
  ) {
    String portId = port.id ?? port.name.replaceAll(' ', '_').toLowerCase();

    if (port.isPerChannel == true) {
      return port.copyWith(id: portId);
    }

    return port.copyWith(id: portId);
  }

  int? _getBusNumberFromParameter(
    String parameterName,
    List<AlgorithmParameter> parameters,
  ) {
    final param = parameters.firstWhere(
      (p) => p.name == parameterName,
      orElse: () => const AlgorithmParameter(name: ''),
    );

    if (param.name.isNotEmpty && param.defaultValue is int) {
      return param.defaultValue as int;
    }

    return null;
  }

  bool _isInputParameter(AlgorithmParameter param) {
    // 1) Check parameter name for semantic hints
    final nameLower = param.name.toLowerCase();
    if (nameLower.contains('input')) {
      return true;
    }
    if (nameLower.contains('output')) {
      return false; // It's an output, not input
    }

    // 2) Fall back to defaultValue ranges
    if (param.defaultValue != null) {
      final defaultValue = param.defaultValue as num;
      if ((defaultValue >= 1 && defaultValue <= 12) ||
          (defaultValue >= 21 && defaultValue <= 28)) {
        return true;
      }
    }

    return false;
  }

  bool _isOutputParameter(AlgorithmParameter param) {
    // 1) Check parameter name for semantic hints
    final nameLower = param.name.toLowerCase();
    if (nameLower.contains('output')) {
      return true;
    }
    if (nameLower.contains('input')) {
      return false; // It's an input, not output
    }

    // 2) Fall back to defaultValue ranges
    if (param.defaultValue != null) {
      final defaultValue = param.defaultValue as num;
      if (defaultValue >= 13 && defaultValue <= 20) {
        return true;
      }
    }

    return false;
  }

  AlgorithmPortInfo _createDefaultPorts() {
    return const AlgorithmPortInfo(
      inputPorts: [
        AlgorithmPort(id: 'input_1', name: 'Input 1', busIdRef: 'input_bus'),
        AlgorithmPort(id: 'input_2', name: 'Input 2', busIdRef: 'input_bus_2'),
      ],
      outputPorts: [
        AlgorithmPort(id: 'output_1', name: 'Output 1', busIdRef: 'output_bus'),
        AlgorithmPort(
          id: 'output_2',
          name: 'Output 2',
          busIdRef: 'output_bus_2',
        ),
      ],
      portBusAssignments: {
        'input_1': 1,
        'input_2': 2,
        'output_1': 13,
        'output_2': 14,
      },
    );
  }

  /// Check if a parameter represents a bus connection
  bool _isBusParameter(ParameterInfo paramInfo, ParameterValue paramValue) {
    // Primary check: proper bus parameter has min 0 or 1 and max 27-28
    // Some algorithms (like poly) use max 27 to reserve space for CV inputs
    if ((paramInfo.min == 0 || paramInfo.min == 1) &&
        (paramInfo.max >= 27 && paramInfo.max <= 28)) {
      return true;
    }

    // Secondary check: look for bus parameter name patterns with reasonable range
    final name = paramInfo.name.toLowerCase();
    if (name.contains('input') ||
        name.contains('output') ||
        name.contains('bus') ||
        name.endsWith(' in') ||
        name.endsWith(' out') ||
        name.contains('send') ||
        name.contains('receive') ||
        name.contains('clock') ||
        name.contains('gate') ||
        name.contains('reset') ||
        name.contains('pitch') ||
        name.contains('v/oct') ||
        name.contains('formant') ||
        name.contains('wave') ||
        name.contains('velocity')) {
      // Must have reasonable bus range (min 0-1, max 27-28)
      if (paramInfo.max >= 27 && paramInfo.min <= 1) {
        return true;
      }
    }

    // Tertiary check: enum-based detection for parameters with bus enum values
    // This catches parameters like "Strum" that have bus names as enum values
    if (_hasBusEnumValues(paramInfo)) {
      debugPrint(
        '[PortExtractionService] Parameter "${paramInfo.name}" has bus enum values',
      );
      return true;
    }

    return false;
  }

  /// Check if a parameter has enum values that represent buses
  bool _hasBusEnumValues(ParameterInfo paramInfo) {
    // Must have the right range for bus parameters
    if (!((paramInfo.min == 0 || paramInfo.min == 1) &&
        paramInfo.max >= 27 &&
        paramInfo.max <= 28)) {
      return false;
    }

    // Check if it has enum values (unit == 1 typically indicates enum)
    if (paramInfo.unit != 1) {
      return false;
    }

    // For now, we'll accept any parameter with the right range and enum unit
    // In the future, we could check actual enum string values if available
    return true;
  }

  bool _isInputParameterFromSlot(
    ParameterInfo paramInfo, [
    String? algorithmGuid,
    AlgorithmMetadata? metadata,
  ]) {
    // 1) Check if this is a bus parameter (min 0 or 1, max 27-28)
    if (!((paramInfo.min == 0 || paramInfo.min == 1) &&
        (paramInfo.max >= 27 && paramInfo.max <= 28))) {
      return false;
    }

    // 2) If we have metacheck if this parameter matches a documented input port
    if (metadata != null) {
      final paramNameLower = paramInfo.name.toLowerCase();
      for (final port in metadata.inputPorts) {
        if (port.name.toLowerCase() == paramNameLower ||
            port.busIdRef?.toLowerCase() == paramNameLower) {
          debugPrint(
            '[PortExtractionService] Parameter "${paramInfo.name}" matches metadata input port "${port.name}"',
          );
          return true;
        }
      }
      // Also check if it's explicitly NOT an output
      for (final port in metadata.outputPorts) {
        if (port.name.toLowerCase() == paramNameLower ||
            port.busIdRef?.toLowerCase() == paramNameLower) {
          debugPrint(
            '[PortExtractionService] Parameter "${paramInfo.name}" matches metadata output port "${port.name}" - NOT an input',
          );
          return false;
        }
      }
    }

    // 3) Check parameter name for semantic hints
    final nameLower = paramInfo.name.toLowerCase();
    if (nameLower.contains('input')) {
      return true;
    }
    if (nameLower.contains('output')) {
      return false; // It's an output, not input
    }

    // 4) Check if it's an enum-based bus parameter
    if (_hasBusEnumValues(paramInfo)) {
      // For enum parameters without clear naming, assume input if not in output range
      if (paramInfo.defaultValue >= 13 && paramInfo.defaultValue <= 20) {
        return false; // Default is output bus
      }
      debugPrint(
        '[PortExtractionService] Enum-based parameter "${paramInfo.name}" assumed to be input',
      );
      return true; // Assume input for enum-based bus parameters
    }

    // 5) Fall back to defaultValue ranges
    if (paramInfo.defaultValue >= 1 && paramInfo.defaultValue <= 12) {
      return true; // Input buses
    }
    if (paramInfo.defaultValue >= 21 && paramInfo.defaultValue <= 28) {
      return true; // Aux buses (also inputs)
    }

    return false;
  }

  bool _isOutputParameterFromSlot(
    ParameterInfo paramInfo, [
    String? algorithmGuid,
    AlgorithmMetadata? metadata,
  ]) {
    // 1) Check if this is a bus parameter (min 0 or 1, max 27-28)
    if (!((paramInfo.min == 0 || paramInfo.min == 1) &&
        (paramInfo.max >= 27 && paramInfo.max <= 28))) {
      return false;
    }

    // 2) If we have metacheck if this parameter matches a documented output port
    if (metadata != null) {
      final paramNameLower = paramInfo.name.toLowerCase();
      for (final port in metadata.outputPorts) {
        if (port.name.toLowerCase() == paramNameLower ||
            port.busIdRef?.toLowerCase() == paramNameLower) {
          debugPrint(
            '[PortExtractionService] Parameter "${paramInfo.name}" matches metadata output port "${port.name}"',
          );
          return true;
        }
      }
      // Also check if it's explicitly NOT an input
      for (final port in metadata.inputPorts) {
        if (port.name.toLowerCase() == paramNameLower ||
            port.busIdRef?.toLowerCase() == paramNameLower) {
          debugPrint(
            '[PortExtractionService] Parameter "${paramInfo.name}" matches metadata input port "${port.name}" - NOT an output',
          );
          return false;
        }
      }
    }

    // 3) Check parameter name for semantic hints
    final nameLower = paramInfo.name.toLowerCase();
    if (nameLower.contains('output')) {
      return true;
    }
    if (nameLower.contains('input')) {
      return false; // It's an input, not output
    }

    // 4) Check if it's an enum-based bus parameter
    if (_hasBusEnumValues(paramInfo)) {
      // For enum parameters without clear naming, check default value
      if (paramInfo.defaultValue >= 13 && paramInfo.defaultValue <= 20) {
        debugPrint(
          '[PortExtractionService] Enum-based parameter "${paramInfo.name}" assumed to be output (default in output range)',
        );
        return true; // Default is output bus
      }
      return false; // Not an output if default isn't in output range
    }

    // 5) Fall back to defaultValue ranges
    if (paramInfo.defaultValue >= 13 && paramInfo.defaultValue <= 20) {
      return true; // Output buses
    }

    return false;
  }

  /// Check if algorithm uses poly input patterns (gate + CV count)
  bool _isPolyAlgorithm(String algorithmGuid) {
    // All poly algorithms use 'py' prefix (pycv, pyfm, pyms, pymu, pyri, pywt)
    return algorithmGuid.startsWith('py');
  }

  /// Check if algorithm uses width-based input patterns (mono/stereo/multi-channel)
  bool _isWidthAwareAlgorithm(String algorithmGuid) {
    // Check if algorithm has a Width parameter in its metadata
    final parameters = _metadataService.getExpandedParameters(algorithmGuid);
    return parameters.any((param) {
      final nameLower = param.name.toLowerCase();
      return nameLower == 'width' ||
          nameLower == 'channels' ||
          nameLower == 'channel count';
    });
  }

  /// Check if a parameter is a gate input parameter for poly algorithms
  bool _isGateInputParameter(ParameterInfo paramInfo) {
    return paramInfo.name.toLowerCase().contains('gate input');
  }

  /// Check if a parameter is a width parameter for width-aware algorithms
  bool _isWidthParameter(ParameterInfo paramInfo) {
    final nameLower = paramInfo.name.toLowerCase();
    return nameLower == 'width' ||
        nameLower == 'channels' ||
        nameLower == 'channel count';
  }

  /// Check if a parameter is an audio input parameter for width-aware algorithms
  bool _isAudioInputParameter(ParameterInfo paramInfo) {
    final nameLower = paramInfo.name.toLowerCase();
    return nameLower == 'audio input' ||
        nameLower == 'input' ||
        nameLower == 'left input';
  }

  /// Find width parameter for a given slot
  ParameterInfo? _findWidthParameter(Slot slot) {
    return slot.parameters.firstWhereOrNull(
      (param) => _isWidthParameter(param),
    );
  }

  /// Extract poly input ports for algorithms with gate+CV patterns
  List<AlgorithmPort> _extractPolyInputPorts(Slot slot) {
    final polyPorts = <AlgorithmPort>[];

    debugPrint(
      '[PortExtractionService] Extracting poly input ports for ${slot.algorithm.name}',
    );

    // Look for gate input parameters (pattern: "N:Gate input N")
    final gateParams = slot.parameters
        .where(
          (param) =>
              param.name.toLowerCase().contains('gate input') &&
              _isBusParameter(
                param,
                slot.values.firstWhere(
                  (v) => v.parameterNumber == param.parameterNumber,
                  orElse: () => ParameterValue.filler(),
                ),
              ),
        )
        .toList();

    for (final gateParam in gateParams) {
      final gateValue = slot.values.firstWhere(
        (v) => v.parameterNumber == gateParam.parameterNumber,
        orElse: () => ParameterValue.filler(),
      );

      // Only create ports for active gates (not set to "None"/bus 0)
      if (gateValue.value > 0) {
        final gateNumber = _extractGateNumber(gateParam.name);

        // Create the gate input port
        final gatePortId = '${gateParam.parameterNumber}';
        final gatePort = AlgorithmPort(
          id: gatePortId,
          name: 'Gate $gateNumber',
          description: 'Gate input $gateNumber',
          busIdRef: gateParam.name,
        );
        polyPorts.add(gatePort);

        debugPrint(
          '[PortExtractionService] Added gate port: Gate $gateNumber (param ${gateParam.parameterNumber}, bus ${gateValue.value})',
        );

        // Find corresponding CV count parameter
        final cvCountParam = _findCvCountParameter(slot, gateNumber);
        if (cvCountParam != null) {
          final cvCountValue = slot.values.firstWhere(
            (v) => v.parameterNumber == cvCountParam.parameterNumber,
            orElse: () => ParameterValue.filler(),
          );

          // Create CV input ports based on count
          final cvCount = cvCountValue.value;
          for (int i = 1; i <= cvCount; i++) {
            final cvPortId = '${gateParam.parameterNumber}_cv_$i';
            final cvPort = AlgorithmPort(
              id: cvPortId,
              name: 'Gate $gateNumber CV $i',
              description: 'CV input $i for gate $gateNumber',
              busIdRef: '${gateParam.name}_cv_$i',
            );
            polyPorts.add(cvPort);

            debugPrint(
              '[PortExtractionService] Added CV port: Gate $gateNumber CV $i',
            );
          }
        }
      }
    }

    return polyPorts;
  }

  /// Extract gate number from parameter name (e.g., "1:Gate input 3" -> 3)
  int _extractGateNumber(String paramName) {
    final match = RegExp(
      r'gate input (\d+)',
      caseSensitive: false,
    ).firstMatch(paramName);
    if (match != null) {
      return int.tryParse(match.group(1) ?? '1') ?? 1;
    }
    return 1; // Default fallback
  }

  /// Find CV count parameter for a given gate number
  ParameterInfo? _findCvCountParameter(Slot slot, int gateNumber) {
    return slot.parameters.firstWhereOrNull(
      (param) => param.name.toLowerCase().contains('gate $gateNumber cv count'),
    );
  }

  /// Extract width-based input ports for algorithms with mono/stereo/multi-channel support
  _WidthBasedPortResult _extractWidthBasedInputPorts(Slot slot) {
    final widthPorts = <AlgorithmPort>[];
    final busAssignments = <String, int>{};

    debugPrint(
      '[PortExtractionService] Extracting width-based input ports for ${slot.algorithm.name}',
    );

    // Find width parameter
    final widthParam = _findWidthParameter(slot);
    if (widthParam == null) {
      debugPrint('[PortExtractionService] No width parameter found');
      return _WidthBasedPortResult(
        ports: widthPorts,
        busAssignments: busAssignments,
      );
    }

    final widthValue = slot.values.firstWhere(
      (v) => v.parameterNumber == widthParam.parameterNumber,
      orElse: () => ParameterValue.filler(),
    );

    final width = widthValue.value;
    debugPrint(
      '[PortExtractionService] Found width parameter: ${widthParam.name} = $width',
    );

    // Find audio input parameter
    final audioInputParam = slot.parameters.firstWhereOrNull(
      (param) => _isAudioInputParameter(param),
    );
    if (audioInputParam == null) {
      debugPrint('[PortExtractionService] No audio input parameter found');
      return _WidthBasedPortResult(
        ports: widthPorts,
        busAssignments: busAssignments,
      );
    }

    final audioInputValue = slot.values.firstWhere(
      (v) => v.parameterNumber == audioInputParam.parameterNumber,
      orElse: () => ParameterValue.filler(),
    );

    final baseBus = audioInputValue.value;
    debugPrint(
      '[PortExtractionService] Audio input parameter: ${audioInputParam.name} = bus $baseBus',
    );

    // Note: We always generate ports regardless of connection status
    // so they remain available for connection in the UI

    // Generate ports based on width (always generate them for UI visibility)
    for (int i = 0; i < width; i++) {
      String portName;
      String portId;

      if (width == 1) {
        portName = 'Audio Input';
        portId = '${audioInputParam.parameterNumber}';
      } else if (width == 2) {
        portName = i == 0 ? 'Audio Input L' : 'Audio Input R';
        portId = '${audioInputParam.parameterNumber}_${i == 0 ? 'L' : 'R'}';
      } else {
        portName = 'Audio Input ${i + 1}';
        portId = '${audioInputParam.parameterNumber}_${i + 1}';
      }

      final port = AlgorithmPort(
        id: portId,
        name: portName,
        description: 'Audio input channel ${i + 1}',
        busIdRef: audioInputParam.name,
      );

      widthPorts.add(port);

      // Only assign bus numbers if the base input is connected
      if (baseBus > 0) {
        final busNumber =
            baseBus - i; // Use same logic as connection interpretation
        if (busNumber >= 1 && busNumber <= 28) {
          busAssignments[portId] = busNumber;
          debugPrint(
            '[PortExtractionService] Added width-based port: $portName (bus $busNumber)',
          );
        } else {
          debugPrint(
            '[PortExtractionService] Added width-based port: $portName (no valid bus)',
          );
        }
      } else {
        debugPrint(
          '[PortExtractionService] Added width-based port: $portName (disconnected)',
        );
      }
    }

    return _WidthBasedPortResult(
      ports: widthPorts,
      busAssignments: busAssignments,
    );
  }
}
