import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:nt_helper/cubit/disting_cubit.dart';
import 'package:nt_helper/models/algorithm_connection.dart';

/// Service for discovering connections between algorithm slots based on
/// shared bus assignments.
///
/// This service analyzes algorithm slots to identify when one algorithm's
/// output parameter is configured to use the same bus number as another
/// algorithm's input parameter, creating algorithm-to-algorithm connections.
///
/// The service implements caching to avoid expensive recalculation when
/// slot data hasn't changed, and ensures deterministic ordering of results
/// for consistent UI updates.
class AlgorithmConnectionService {
  static const int _maxBusNumber = 28;
  static const int _minBusNumber = 1;

  // Simple caching based on slots data hash
  String? _lastSlotsHash;
  List<AlgorithmConnection>? _cachedConnections;

  /// Discovers all algorithm-to-algorithm connections from the given slots.
  ///
  /// Analyzes each slot's parameters to find output parameters that share
  /// bus numbers with input parameters from other slots, creating connections
  /// that represent signal flow between algorithms.
  ///
  /// Returns a deterministically sorted list of [AlgorithmConnection] objects.
  /// Results are cached based on the slots data hash to improve performance.
  List<AlgorithmConnection> discoverAlgorithmConnections(List<Slot> slots) {
    // Generate hash of slots data for caching
    final slotsHash = _generateSlotsHash(slots);

    // Return cached result if slots haven't changed
    if (_lastSlotsHash == slotsHash && _cachedConnections != null) {
      return _cachedConnections!;
    }


    try {
      // Discover all connections
      final connections = _performConnectionDiscovery(slots);

      // Cache results
      _lastSlotsHash = slotsHash;
      _cachedConnections = connections;

      return connections;
    } catch (e) {
      return [];
    }
  }

  /// Clears the internal cache, forcing rediscovery on next call.
  void clearCache() {
    _lastSlotsHash = null;
    _cachedConnections = null;
  }

  /// Performs the actual connection discovery logic.
  List<AlgorithmConnection> _performConnectionDiscovery(List<Slot> slots) {
    final connections = <AlgorithmConnection>[];

    // Build bus assignment maps for each slot
    final List<_SlotBusInfo> slotBusInfos = [];
    for (int i = 0; i < slots.length; i++) {
      final slot = slots[i];
      slotBusInfos.add(_extractBusInfo(slot, i));
    }

    // Find algorithm-to-algorithm connections by matching bus assignments
    for (
      int sourceIndex = 0;
      sourceIndex < slotBusInfos.length;
      sourceIndex++
    ) {
      final sourceBusInfo = slotBusInfos[sourceIndex];

      for (
        int targetIndex = 0;
        targetIndex < slotBusInfos.length;
        targetIndex++
      ) {
        if (sourceIndex == targetIndex) continue; // Skip self-connections

        final targetBusInfo = slotBusInfos[targetIndex];

        // Check for shared buses between source outputs and target inputs
        final sharedConnections = _findSharedBusConnections(
          sourceBusInfo,
          targetBusInfo,
          sourceIndex,
          targetIndex,
        );

        connections.addAll(sharedConnections);
      }
    }

    // Find algorithm-to-physical-output connections
    for (
      int sourceIndex = 0;
      sourceIndex < slotBusInfos.length;
      sourceIndex++
    ) {
      final sourceBusInfo = slotBusInfos[sourceIndex];

      // Create connections from algorithm outputs to physical outputs
      for (final outputEntry in sourceBusInfo.outputBuses.entries) {
        final outputParamName = outputEntry.key;
        final busNumber = outputEntry.value;

        // Create connection from algorithm output to physical output
        // Use special target algorithm index -3 to indicate physical output
        final connection = AlgorithmConnection.withGeneratedId(
          sourceAlgorithmIndex: sourceIndex,
          sourcePortId: outputParamName,
          targetAlgorithmIndex: -3, // Special index for physical outputs
          targetPortId: 'physical_output_$busNumber',
          busNumber: busNumber,
          connectionType: _inferConnectionTypeFromParamName(outputParamName),
        );

        connections.add(connection);
      }
    }

    // Validate and sort connections deterministically
    final validConnections = connections
        .where((connection) => _isValidConnection(connection))
        .toList();

    return _sortConnectionsDeterministically(validConnections);
  }

  /// Extracts bus assignment information from a slot.
  _SlotBusInfo _extractBusInfo(Slot slot, int algorithmIndex) {
    final valueByParam = <int, int>{
      for (final v in slot.values) v.parameterNumber: v.value,
    };

    final inputBuses = <String, int>{};
    final outputBuses = <String, int>{};

    // Extract bus assignments from common parameter patterns
    for (final param in slot.parameters) {
      final paramName = param.name.toLowerCase();
      final busValue =
          valueByParam[param.parameterNumber] ?? param.defaultValue;

      // Skip "None" bus assignments (typically 0)
      if (busValue < _minBusNumber || busValue > _maxBusNumber) continue;

      if (_isOutputParameter(paramName)) {
        outputBuses[param.name] = busValue;
      } else if (_isInputParameter(paramName)) {
        inputBuses[param.name] = busValue;
      }
    }

    return _SlotBusInfo(
      algorithmIndex: algorithmIndex,
      algorithmName: slot.algorithm.name,
      inputBuses: inputBuses,
      outputBuses: outputBuses,
    );
  }

  /// Determines if a parameter name indicates an output parameter.
  bool _isOutputParameter(String paramName) {
    final lower = paramName.toLowerCase();
    return lower.contains('output') && !lower.contains('input');
  }

  /// Determines if a parameter name indicates an input parameter.
  bool _isInputParameter(String paramName) {
    final lower = paramName.toLowerCase();
    return lower.contains('input') && !lower.contains('output');
  }

  /// Finds connections between source outputs and target inputs that share bus numbers.
  List<AlgorithmConnection> _findSharedBusConnections(
    _SlotBusInfo sourceBusInfo,
    _SlotBusInfo targetBusInfo,
    int sourceIndex,
    int targetIndex,
  ) {
    final connections = <AlgorithmConnection>[];

    for (final sourceOutput in sourceBusInfo.outputBuses.entries) {
      final sourceBus = sourceOutput.value;

      for (final targetInput in targetBusInfo.inputBuses.entries) {
        final targetBus = targetInput.value;

        // Create connection if buses match
        if (sourceBus == targetBus) {
          final connectionType = _inferConnectionType(
            sourceOutput.key,
            targetInput.key,
          );

          final connection = AlgorithmConnection.withGeneratedId(
            sourceAlgorithmIndex: sourceIndex,
            sourcePortId: sourceOutput.key,
            targetAlgorithmIndex: targetIndex,
            targetPortId: targetInput.key,
            busNumber: sourceBus,
            connectionType: connectionType,
          );

          connections.add(connection);
        }
      }
    }

    return connections;
  }

  /// Infers connection type from a single parameter name (for algorithm-to-physical connections)
  AlgorithmConnectionType _inferConnectionTypeFromParamName(String paramName) {
    final lower = paramName.toLowerCase();

    // Check for CV connections
    if (lower.contains('cv')) {
      return AlgorithmConnectionType.controlVoltage;
    }

    // Check for gate/trigger connections
    if (lower.contains('gate') || lower.contains('trigger')) {
      return AlgorithmConnectionType.gateTrigger;
    }

    // Check for clock connections
    if (lower.contains('clock')) {
      return AlgorithmConnectionType.clockTiming;
    }

    // Default to audio signal for output parameters
    return AlgorithmConnectionType.audioSignal;
  }

  /// Infers the connection type based on parameter names.
  AlgorithmConnectionType _inferConnectionType(
    String sourceParam,
    String targetParam,
  ) {
    final sourceLower = sourceParam.toLowerCase();
    final targetLower = targetParam.toLowerCase();

    // Check for CV connections
    if (sourceLower.contains('cv') || targetLower.contains('cv')) {
      return AlgorithmConnectionType.controlVoltage;
    }

    // Check for gate/trigger connections
    if (sourceLower.contains('gate') ||
        sourceLower.contains('trigger') ||
        targetLower.contains('gate') ||
        targetLower.contains('trigger')) {
      return AlgorithmConnectionType.gateTrigger;
    }

    // Check for clock connections
    if (sourceLower.contains('clock') || targetLower.contains('clock')) {
      return AlgorithmConnectionType.clockTiming;
    }

    // Check for audio connections
    if (sourceLower.contains('audio') ||
        sourceLower.contains('main') ||
        sourceLower.contains('left') ||
        sourceLower.contains('right') ||
        targetLower.contains('audio') ||
        targetLower.contains('wave')) {
      return AlgorithmConnectionType.audioSignal;
    }

    // Default to mixed for unclear cases
    return AlgorithmConnectionType.mixed;
  }

  /// Validates that a connection meets requirements.
  bool _isValidConnection(AlgorithmConnection connection) {
    // Check basic field validity
    if (connection.busNumber < _minBusNumber ||
        connection.busNumber > _maxBusNumber) {
      return false;
    }

    // Validate algorithm indices
    if (connection.sourceAlgorithmIndex < 0 ||
        connection.targetAlgorithmIndex < 0) {
      return false;
    }

    // Run full validation
    final validation = connection.validate();
    return validation.isValid;
  }

  /// Sorts connections deterministically for consistent UI updates.
  List<AlgorithmConnection> _sortConnectionsDeterministically(
    List<AlgorithmConnection> connections,
  ) {
    connections.sort((a, b) {
      // Sort by source algorithm index first
      int result = a.sourceAlgorithmIndex.compareTo(b.sourceAlgorithmIndex);
      if (result != 0) return result;

      // Then by target algorithm index
      result = a.targetAlgorithmIndex.compareTo(b.targetAlgorithmIndex);
      if (result != 0) return result;

      // Then by bus number
      result = a.busNumber.compareTo(b.busNumber);
      if (result != 0) return result;

      // Finally by connection ID for complete determinism
      return a.id.compareTo(b.id);
    });

    return connections;
  }

  /// Generates a hash of the slots data for caching purposes.
  String _generateSlotsHash(List<Slot> slots) {
    final buffer = StringBuffer();

    for (final slot in slots) {
      buffer.write('${slot.algorithm.algorithmIndex}:${slot.algorithm.name}|');

      // Hash parameter values that might affect bus assignments
      for (final value in slot.values) {
        buffer.write('${value.parameterNumber}=${value.value},');
      }

      buffer.write(';;');
    }

    final bytes = utf8.encode(buffer.toString());
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}

/// Internal class to hold bus assignment information for a slot.
class _SlotBusInfo {
  final int algorithmIndex;
  final String algorithmName;
  final Map<String, int> inputBuses;
  final Map<String, int> outputBuses;

  const _SlotBusInfo({
    required this.algorithmIndex,
    required this.algorithmName,
    required this.inputBuses,
    required this.outputBuses,
  });

  @override
  String toString() {
    return '_SlotBusInfo(index: $algorithmIndex, name: $algorithmName, '
        'inputs: $inputBuses, outputs: $outputBuses)';
  }
}
