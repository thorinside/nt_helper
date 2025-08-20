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

class PortExtractionService {
  final AlgorithmMetadataService _metadataService;

  PortExtractionService(this._metadataService);

  /// Extract ports from live slot data (preferred method)
  AlgorithmPortInfo extractPortsFromSlot(Slot slot) {
    final inputPorts = <AlgorithmPort>[];
    final outputPorts = <AlgorithmPort>[];
    final busAssignments = <String, int>{};

    debugPrint('[PortExtractionService] Extracting ports from live slot data for ${slot.algorithm.name}');

    // Look through all parameters to find bus-type parameters
    for (final paramInfo in slot.parameters) {
      final paramValue = slot.values.firstWhere(
        (v) => v.parameterNumber == paramInfo.parameterNumber,
        orElse: () => ParameterValue.filler(),
      );

      if (_isBusParameter(paramInfo, paramValue)) {
        final portId = paramInfo.parameterNumber.toString();
        final port = AlgorithmPort(
          id: portId,
          name: paramInfo.name,
          description: null,
          busIdRef: paramInfo.name,
        );

        final isInput = _isInputParameterFromSlot(paramInfo, slot.algorithm.guid);
        final isOutput = _isOutputParameterFromSlot(paramInfo, slot.algorithm.guid);
        
        debugPrint('🔍 [PortExtractionService] Parameter "${paramInfo.name}" defaultValue=${paramInfo.defaultValue} -> isInput=$isInput, isOutput=$isOutput');
        
        if (isInput) {
          inputPorts.add(port);
          debugPrint('✅ [PortExtractionService] Added INPUT port: ${paramInfo.name}');
        } else if (isOutput) {
          outputPorts.add(port);
          debugPrint('✅ [PortExtractionService] Added OUTPUT port: ${paramInfo.name}');
        }

        if (paramValue.value > 0) {
          busAssignments[portId] = paramValue.value;
        }
      }
    }

    // Fallback to static metadata if no live parameters found
    if (inputPorts.isEmpty && outputPorts.isEmpty) {
      debugPrint('[PortExtractionService] No bus parameters found in live data, falling back to static metadata');
      return extractPorts(slot.algorithm.guid);
    }

    debugPrint('[PortExtractionService] Found ${inputPorts.length} inputs, ${outputPorts.length} outputs from live data');

    return AlgorithmPortInfo(
      inputPorts: inputPorts,
      outputPorts: outputPorts,
      portBusAssignments: busAssignments,
    );
  }

  AlgorithmPortInfo extractPorts(String algorithmGuid) {
    final metadata = _metadataService.getAlgorithmByGuid(algorithmGuid);
    if (metadata == null) {
      debugPrint('[PortExtractionService] No metadata found for GUID: "$algorithmGuid"');
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
    // Primary check: proper bus parameter has min 0 or 1 and max 28
    if ((paramInfo.min == 0 || paramInfo.min == 1) && paramInfo.max == 28) {
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
      
      // Must have reasonable bus range (0-28)
      if (paramInfo.max >= 28 && paramInfo.min <= 28) {
        return true;
      }
    }
    
    return false;
  }

  bool _isInputParameterFromSlot(ParameterInfo paramInfo, [String? algorithmGuid]) {
    // 1) Check if this is a bus parameter (min 0 or 1, max 28)
    if (!((paramInfo.min == 0 || paramInfo.min == 1) && paramInfo.max == 28)) {
      return false;
    }
    
    // 2) Check parameter name for semantic hints
    final nameLower = paramInfo.name.toLowerCase();
    if (nameLower.contains('input')) {
      return true;
    }
    if (nameLower.contains('output')) {
      return false; // It's an output, not input
    }
    
    // 3) Fall back to defaultValue ranges
    if (paramInfo.defaultValue >= 1 && paramInfo.defaultValue <= 12) {
      return true; // Input buses
    }
    if (paramInfo.defaultValue >= 21 && paramInfo.defaultValue <= 28) {
      return true; // Aux buses (also inputs)
    }
    
    return false;
  }

  bool _isOutputParameterFromSlot(ParameterInfo paramInfo, [String? algorithmGuid]) {
    // 1) Check if this is a bus parameter (min 0 or 1, max 28)
    if (!((paramInfo.min == 0 || paramInfo.min == 1) && paramInfo.max == 28)) {
      return false;
    }
    
    // 2) Check parameter name for semantic hints
    final nameLower = paramInfo.name.toLowerCase();
    if (nameLower.contains('output')) {
      return true;
    }
    if (nameLower.contains('input')) {
      return false; // It's an input, not output
    }
    
    // 3) Fall back to defaultValue ranges
    if (paramInfo.defaultValue >= 13 && paramInfo.defaultValue <= 20) {
      return true; // Output buses
    }
    
    return false;
  }

}
