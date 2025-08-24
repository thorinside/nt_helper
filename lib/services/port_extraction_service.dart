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
        // Skip gate input parameters for poly algorithms - they'll be handled specially
        if (_isPolyAlgorithm(slot.algorithm.guid) && _isGateInputParameter(paramInfo)) {
          debugPrint('🔍 [PortExtractionService] Skipping gate input parameter "${paramInfo.name}" for poly algorithm');
          continue;
        }

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

    // Special handling for poly algorithms with gate+CV patterns
    if (_isPolyAlgorithm(slot.algorithm.guid)) {
      final polyPorts = _extractPolyInputPorts(slot);
      inputPorts.addAll(polyPorts);
      debugPrint('[PortExtractionService] Added ${polyPorts.length} poly input ports');
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
    // Primary check: proper bus parameter has min 0 or 1 and max 27-28
    // Some algorithms (like poly) use max 27 to reserve space for CV inputs
    if ((paramInfo.min == 0 || paramInfo.min == 1) && (paramInfo.max >= 27 && paramInfo.max <= 28)) {
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
      
      // Must have reasonable bus range (0-27 to 0-28)
      if (paramInfo.max >= 27 && paramInfo.min <= 28) {
        return true;
      }
    }
    
    return false;
  }

  bool _isInputParameterFromSlot(ParameterInfo paramInfo, [String? algorithmGuid]) {
    // 1) Check if this is a bus parameter (min 0 or 1, max 27-28)
    if (!((paramInfo.min == 0 || paramInfo.min == 1) && (paramInfo.max >= 27 && paramInfo.max <= 28))) {
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
    // 1) Check if this is a bus parameter (min 0 or 1, max 27-28)
    if (!((paramInfo.min == 0 || paramInfo.min == 1) && (paramInfo.max >= 27 && paramInfo.max <= 28))) {
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

  /// Check if algorithm uses poly input patterns (gate + CV count)
  bool _isPolyAlgorithm(String algorithmGuid) {
    // Known poly algorithms that use gate+CV patterns
    return algorithmGuid == 'pyfm'; // Poly FM
    // TODO: Add other poly algorithms as discovered
  }

  /// Check if a parameter is a gate input parameter for poly algorithms
  bool _isGateInputParameter(ParameterInfo paramInfo) {
    return paramInfo.name.toLowerCase().contains('gate input');
  }

  /// Extract poly input ports for algorithms with gate+CV patterns
  List<AlgorithmPort> _extractPolyInputPorts(Slot slot) {
    final polyPorts = <AlgorithmPort>[];
    
    debugPrint('[PortExtractionService] Extracting poly input ports for ${slot.algorithm.name}');
    
    // Look for gate input parameters (pattern: "N:Gate input N")
    final gateParams = slot.parameters.where((param) => 
      param.name.toLowerCase().contains('gate input') && 
      _isBusParameter(param, slot.values.firstWhere(
        (v) => v.parameterNumber == param.parameterNumber,
        orElse: () => ParameterValue.filler(),
      ))
    ).toList();
    
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
        
        debugPrint('[PortExtractionService] Added gate port: Gate $gateNumber (param ${gateParam.parameterNumber}, bus ${gateValue.value})');
        
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
            
            debugPrint('[PortExtractionService] Added CV port: Gate $gateNumber CV $i');
          }
        }
      }
    }
    
    return polyPorts;
  }

  /// Extract gate number from parameter name (e.g., "1:Gate input 3" -> 3)
  int _extractGateNumber(String paramName) {
    final match = RegExp(r'gate input (\d+)', caseSensitive: false).firstMatch(paramName);
    if (match != null) {
      return int.tryParse(match.group(1) ?? '1') ?? 1;
    }
    return 1; // Default fallback
  }

  /// Find CV count parameter for a given gate number
  ParameterInfo? _findCvCountParameter(Slot slot, int gateNumber) {
    return slot.parameters.firstWhereOrNull((param) =>
      param.name.toLowerCase().contains('gate $gateNumber cv count'));
  }

}
