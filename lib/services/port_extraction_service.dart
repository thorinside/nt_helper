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

      // Check if this parameter represents a bus connection
      if (_isBusParameter(paramInfo, paramValue)) {
        final portId = _sanitizePortId(paramInfo.name);
        final port = AlgorithmPort(
          id: portId,
          name: paramInfo.name,
          description: null,
          busIdRef: paramInfo.name,
        );

        if (_isInputParameterFromSlot(paramInfo)) {
          inputPorts.add(port);
          debugPrint('[PortExtractionService] Added input port: ${paramInfo.name}');
        } else if (_isOutputParameterFromSlot(paramInfo)) {
          outputPorts.add(port);
          debugPrint('[PortExtractionService] Added output port: ${paramInfo.name}');
        }

        // Store bus assignment
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
    final nameLower = param.name.toLowerCase();
    
    // Check explicit output indicators first to avoid misclassification
    if (nameLower.contains('output') || 
        nameLower.contains('send') ||
        nameLower.contains('main') && nameLower.contains('out')) {
      return false;
    }
    
    return nameLower.contains('input') ||
        nameLower.contains('in ') ||
        nameLower.contains('receive') ||
        (param.scope?.contains('routing') == true &&
            param.max != null &&
            (param.max as num) <= 12);
  }

  bool _isOutputParameter(AlgorithmParameter param) {
    final nameLower = param.name.toLowerCase();
    return nameLower.contains('output') ||
        nameLower.contains('out ') ||
        nameLower.contains('send') ||
        (nameLower.contains('main') && !nameLower.contains('input')) ||
        (param.scope?.contains('routing') == true &&
            param.min != null &&
            (param.min as num) >= 13);
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

  /// Check if a parameter represents a bus connection by looking at its enum values
  bool _isBusParameter(ParameterInfo paramInfo, ParameterValue paramValue) {
    final name = paramInfo.name.toLowerCase();
    
    // Check for common bus parameter patterns
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
      
      // Additional check: parameter should have reasonable bus range (0-28)
      if (paramInfo.max >= 28 && paramInfo.min <= 28) {
        return true;
      }
    }
    
    return false;
  }

  bool _isInputParameterFromSlot(ParameterInfo paramInfo) {
    // Primary check: Use defaultValue to determine if this is an input bus parameter
    // Input buses: 1-12, Aux buses: 21-28 (can be used as inputs)
    if (paramInfo.defaultValue >= 1 && paramInfo.defaultValue <= 12) {
      return true;
    }
    if (paramInfo.defaultValue >= 21 && paramInfo.defaultValue <= 28) {
      return true;
    }
    
    // Fallback: Check for enum parameters (unit=1) with input names
    if (paramInfo.unit == 1 && paramInfo.max >= 28) {
      final nameLower = paramInfo.name.toLowerCase();
      if (nameLower.contains('input') ||
          nameLower.contains(' in') ||
          nameLower.contains('receive') ||
          (nameLower.contains('clock') && !nameLower.contains('output')) ||
          (nameLower.contains('reset') && !nameLower.contains('output')) ||
          (nameLower.contains('pitch') && !nameLower.contains('output')) ||
          (nameLower.contains('formant') && !nameLower.contains('output')) ||
          (nameLower.contains('wave') && !nameLower.contains('output')) ||
          (nameLower.contains('step') && !nameLower.contains('output'))) {
        return true;
      }
    }
    
    return false;
  }

  bool _isOutputParameterFromSlot(ParameterInfo paramInfo) {
    // Primary check: Use defaultValue to determine if this is an output bus parameter
    // Output buses: 13-20
    if (paramInfo.defaultValue >= 13 && paramInfo.defaultValue <= 20) {
      return true;
    }
    
    // Fallback: Check for enum parameters (unit=1) with output names
    if (paramInfo.unit == 1 && paramInfo.max >= 28) {
      final nameLower = paramInfo.name.toLowerCase();
      if (nameLower.contains('output') ||
          nameLower.contains(' out') ||
          nameLower.contains('send')) {
        return true;
      }
    }
    
    return false;
  }

  String _sanitizePortId(String name) {
    return name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
  }
}
