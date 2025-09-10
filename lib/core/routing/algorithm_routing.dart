import 'package:flutter/foundation.dart';
import 'package:nt_helper/cubit/disting_cubit.dart';
import 'package:nt_helper/domain/disting_nt_sysex.dart';
import 'models/routing_state.dart';
import 'models/port.dart';
import 'models/connection.dart';
import 'port_compatibility_validator.dart';
import 'poly_algorithm_routing.dart';
import 'multi_channel_algorithm_routing.dart';
import 'usb_from_algorithm_routing.dart';

/// Abstract base class for algorithm routing implementations.
///
/// This class defines the core interface that all routing algorithms must implement.
/// It provides a standardized way to generate ports, validate connections, and manage
/// routing state while allowing concrete implementations to define their own logic.
///
/// Example usage:
/// ```dart
/// class MyRoutingAlgorithm extends AlgorithmRouting {
///   @override
///   List<Port> generateInputPorts() {
///     return [Port(id: 'input1', name: 'Audio In', type: PortType.audio)];
///   }
///
///   @override
///   List<Port> generateOutputPorts() {
///     return [Port(id: 'output1', name: 'Audio Out', type: PortType.audio)];
///   }
///
///   @override
///   bool validateConnection(Port source, Port destination) {
///     return source.type == destination.type;
///   }
/// }
/// ```
abstract class AlgorithmRouting {
  /// The port compatibility validator for this algorithm
  late final PortCompatibilityValidator _validator;

  /// Mode parameters with their numbers for output mode switching
  Map<String, ({int parameterNumber, int value})>? _modeParametersWithNumbers;

  /// Stable UUID for this algorithm instance
  String? algorithmUuid;

  /// Creates a new AlgorithmRouting instance
  AlgorithmRouting({PortCompatibilityValidator? validator, this.algorithmUuid}) {
    _validator = validator ?? PortCompatibilityValidator();
  }

  /// The current routing state
  RoutingState get state;

  /// List of input ports available for this routing algorithm
  List<Port> get inputPorts;

  /// List of output ports available for this routing algorithm
  List<Port> get outputPorts;

  /// List of active connections between ports
  List<Connection> get connections;

  /// The port compatibility validator
  PortCompatibilityValidator get validator => _validator;

  /// Sets the mode parameters for this routing algorithm
  @protected
  void setModeParameters(
    Map<String, ({int parameterNumber, int value})> modeParameters,
  ) {
    _modeParametersWithNumbers = modeParameters;
  }

  /// Gets the mode parameter number for the given output parameter name
  /// If the output parameter is named "Blah", looks for "Blah mode"
  @protected
  int? getModeParameterNumber(String outputParameterName) {
    final modeParameterName = '$outputParameterName mode';
    return _modeParametersWithNumbers?[modeParameterName]?.parameterNumber;
  }

  /// Generates the list of input ports for this algorithm.
  ///
  /// This method should be implemented by concrete classes to define
  /// what input ports are available for the routing algorithm.
  ///
  /// Returns a list of [Port] objects representing input ports.
  @protected
  List<Port> generateInputPorts();

  /// Generates the list of output ports for this algorithm.
  ///
  /// This method should be implemented by concrete classes to define
  /// what output ports are available for the routing algorithm.
  ///
  /// Returns a list of [Port] objects representing output ports.
  @protected
  List<Port> generateOutputPorts();

  /// Validates whether a connection between two ports is valid.
  ///
  /// This method checks if a connection can be made between the [source]
  /// port and the [destination] port based on their types, directions,
  /// and any other algorithm-specific constraints.
  ///
  /// The default implementation uses the port compatibility validator,
  /// but concrete classes can override this for custom validation logic.
  ///
  /// Parameters:
  /// - [source]: The port where the connection originates
  /// - [destination]: The port where the connection terminates
  ///
  /// Returns `true` if the connection is valid, `false` otherwise.
  bool validateConnection(Port source, Port destination) {
    final result = _validator.validateConnection(
      source,
      destination,
      existingConnections: connections,
    );
    return result.isValid;
  }

  /// Validates a connection with detailed results.
  ///
  /// This method provides detailed validation results including errors
  /// and warnings, which can be useful for providing user feedback.
  ///
  /// Parameters:
  /// - [source]: The port where the connection originates
  /// - [destination]: The port where the connection terminates
  ///
  /// Returns a [ValidationResult] with detailed validation information.
  ValidationResult validateConnectionDetailed(Port source, Port destination) {
    return _validator.validateConnection(
      source,
      destination,
      existingConnections: connections,
    );
  }

  /// Updates the routing state with a new state.
  ///
  /// This method allows updating the internal routing state and should
  /// trigger any necessary state change notifications.
  ///
  /// Parameters:
  /// - [newState]: The new routing state to apply
  void updateState(RoutingState newState);

  /// Adds a connection between two ports if the connection is valid.
  ///
  /// This method validates the connection using [validateConnection] and
  /// adds it to the list of active connections if valid.
  ///
  /// Parameters:
  /// - [source]: The source port for the connection
  /// - [destination]: The destination port for the connection
  ///
  /// Returns the created [Connection] if successful, null if invalid.
  Connection? addConnection(Port source, Port destination) {
    if (!validateConnection(source, destination)) {
      debugPrint(
        'AlgorithmRouting: Invalid connection attempt from ${source.id} to ${destination.id}',
      );
      return null;
    }

    final connection = Connection(
      id: '${source.id}_${destination.id}',
      sourcePortId: source.id,
      destinationPortId: destination.id,
      connectionType: ConnectionType.algorithmToAlgorithm,
    );

    debugPrint('AlgorithmRouting: Created connection ${connection.id}');

    return connection;
  }

  /// Removes a connection by its ID.
  ///
  /// This method removes an active connection from the routing system.
  ///
  /// Parameters:
  /// - [connectionId]: The ID of the connection to remove
  ///
  /// Returns `true` if the connection was found and removed, `false` otherwise.
  bool removeConnection(String connectionId) {
    final removed = connections.any((conn) => conn.id == connectionId);
    if (removed) {
      debugPrint('AlgorithmRouting: Removed connection $connectionId');
    } else {
      debugPrint('AlgorithmRouting: Connection $connectionId not found');
    }
    return removed;
  }

  /// Finds a port by its ID in both input and output ports.
  ///
  /// This utility method searches through all available ports to find
  /// one with the specified ID.
  ///
  /// Parameters:
  /// - [portId]: The ID of the port to find
  ///
  /// Returns the [Port] if found, null otherwise.
  Port? findPortById(String portId) {
    // Search in input ports
    for (final port in inputPorts) {
      if (port.id == portId) {
        return port;
      }
    }

    // Search in output ports
    for (final port in outputPorts) {
      if (port.id == portId) {
        return port;
      }
    }

    return null;
  }

  /// Validates the entire routing configuration.
  ///
  /// This method performs a comprehensive validation of the current
  /// routing state, checking all connections for validity and consistency.
  ///
  /// Returns `true` if the routing configuration is valid, `false` otherwise.
  bool validateRouting() {
    for (final connection in connections) {
      final source = findPortById(connection.sourcePortId);
      final destination = findPortById(connection.destinationPortId);

      if (source == null || destination == null) {
        debugPrint(
          'AlgorithmRouting: Invalid connection ${connection.id} - missing ports',
        );
        return false;
      }

      if (!validateConnection(source, destination)) {
        debugPrint(
          'AlgorithmRouting: Invalid connection ${connection.id} - validation failed',
        );
        return false;
      }
    }

    return true;
  }

  /// Disposes of any resources used by the routing algorithm.
  ///
  /// Concrete implementations should override this method to clean up
  /// any resources, listeners, or subscriptions they may have created.
  @mustCallSuper
  void dispose() {
    debugPrint('AlgorithmRouting: Disposing routing algorithm');
  }

  /// Factory method to create the appropriate AlgorithmRouting from a Slot.
  ///
  /// This method asks each concrete implementation if it can handle the slot,
  /// then delegates creation to the appropriate subclass.
  ///
  /// Parameters:
  /// - [slot]: The slot containing algorithm and parameter information
  /// - [algorithmUuid]: Optional UUID for the algorithm instance
  ///
  /// Returns an appropriate AlgorithmRouting implementation
  static AlgorithmRouting fromSlot(Slot slot, {String? algorithmUuid}) {
    // Extract mode parameters once (used by all implementations)
    final modeParametersWithNumbers = extractModeParametersWithNumbers(slot);

    // Check for USB Audio (From Host) algorithm first and use its own IO extractor
    if (UsbFromAlgorithmRouting.canHandle(slot)) {
      final usbIoParameters = UsbFromAlgorithmRouting.extractIOParameters(slot);
      return UsbFromAlgorithmRouting.createFromSlot(
        slot,
        ioParameters: usbIoParameters,
        modeParametersWithNumbers: modeParametersWithNumbers,
        algorithmUuid: algorithmUuid,
      );
    }

    // For non-USB algorithms use the generic IO extractor
    final ioParameters = extractIOParameters(slot);

    // For other algorithms, we may need the older modeParameters map
    final modeParameters = extractModeParameters(slot);

    // Ask each implementation if it can handle this slot
    AlgorithmRouting instance;
    if (PolyAlgorithmRouting.canHandle(slot)) {
      instance = PolyAlgorithmRouting.createFromSlot(
        slot,
        ioParameters: ioParameters,
        modeParameters: modeParameters,
        modeParametersWithNumbers: modeParametersWithNumbers,
        algorithmUuid: algorithmUuid,
      );
    } else {
      // MultiChannelAlgorithmRouting is the fallback for everything else
      instance = MultiChannelAlgorithmRouting.createFromSlot(
        slot,
        ioParameters: ioParameters,
        modeParameters: modeParameters,
        modeParametersWithNumbers: modeParametersWithNumbers,
        algorithmUuid: algorithmUuid,
      );
    }

    // Set the mode parameters in the base class
    instance.setModeParameters(modeParametersWithNumbers);

    return instance;
  }

  /// Helper method to extract routing-related parameters from a slot.
  ///
  /// Identifies parameters that represent bus assignments for routing.
  /// These are parameters with:
  /// - unit == 1 (enum type)
  /// - min is 0 or 1
  /// - max is 27 or 28
  ///
  /// Parameters:
  /// - [slot]: The slot to analyze
  ///
  /// Returns a map of parameter names to their bus values
  static Map<String, int> extractIOParameters(Slot slot) {
    // Special case: Notes algorithm (guid: 'note') has no I/O capabilities
    // Even if it has parameters that look like bus parameters,
    // they're not for routing audio/CV signals
    if (slot.algorithm.guid == 'note') {
      debugPrint(
        'Notes algorithm detected (guid: note) - returning empty I/O parameters (no routing capability)',
      );
      return {};
    }

    final ioParameters = <String, int>{};

    final valueByParam = <int, int>{
      for (final v in slot.values) v.parameterNumber: v.value,
    };

    for (final param in slot.parameters) {
      // Bus parameters are identified by:
      // - unit == 1 (enum type)
      // - min is 0 or 1
      // - max is 27 or 28
      final isBusParameter =
          param.unit == 1 &&
          (param.min == 0 || param.min == 1) &&
          (param.max == 27 || param.max == 28 || param.max == 30);

      // CV count parameters are identified by:
      // - name contains "CV count"
      // - unit == 0 (numeric type)
      final isCvCountParameter = 
          param.name.contains('CV count') && param.unit == 0;

      // Boolean parameters for Poly CV outputs:
      // - unit == 2 (boolean type)
      // - name contains "outputs" (e.g., "Gate outputs", "Pitch outputs")
      final isBooleanOutputParameter = 
          param.unit == 2 && param.name.contains('outputs');

      // Include numeric parameters like "Voices" or "First output"
      // - unit == 0 (numeric type)
      // - name is exactly "Voices" or "First output"
      final isPolyCvNumericParameter = 
          param.unit == 0 && 
          (param.name == 'Voices' || param.name == 'First output');

      if (isBusParameter || isCvCountParameter || 
          isBooleanOutputParameter || isPolyCvNumericParameter) {
        final value = valueByParam[param.parameterNumber] ?? param.defaultValue;
        // Include all relevant parameters
        // The subclass will decide how to handle them
        ioParameters[param.name] = value;
      }
    }

    return ioParameters;
  }

  /// Helper method to extract mode-related parameters from a slot.
  ///
  /// Identifies parameters that control output modes (Add/Replace).
  /// Mode parameters are identified by:
  /// - Parameter name ending with 'mode' (case-insensitive)
  /// - unit == 1 (enum type)
  /// - enumValues containing 'Add' and 'Replace'
  ///
  /// This method follows the same pattern as extractIOParameters but
  /// specifically targets mode control parameters for output ports.
  ///
  /// Parameters:
  /// - [slot]: The slot to analyze
  ///
  /// Returns a map of parameter names to their mode values (0=Add, 1=Replace)
  static Map<String, int> extractModeParameters(Slot slot) {
    final modeParameters = <String, int>{};

    final valueByParam = <int, int>{
      for (final v in slot.values) v.parameterNumber: v.value,
    };

    // Build enum lookup map
    final enumsByParam = <int, List<String>>{
      for (final e in slot.enums) e.parameterNumber: e.values,
    };

    for (final param in slot.parameters) {
      // Mode parameters are identified by:
      // - name ending with 'mode' (case-insensitive)
      // - unit == 1 (enum type)
      // - enum values containing 'Add' and 'Replace'
      final enumValues = enumsByParam[param.parameterNumber];
      final isModeParameter =
          param.name.toLowerCase().endsWith('mode') &&
          param.unit == 1 &&
          enumValues != null &&
          enumValues.length >= 2 &&
          enumValues.contains('Add') &&
          enumValues.contains('Replace');

      if (isModeParameter) {
        final value = valueByParam[param.parameterNumber] ?? param.defaultValue;
        modeParameters[param.name] = value;
      }
    }

    return modeParameters;
  }

  /// Extract mode parameters with both their values and parameter numbers.
  ///
  /// Parameters:
  /// - [slot]: The slot to analyze
  ///
  /// Returns a map of parameter names to (parameterNumber, value) records
  static Map<String, ({int parameterNumber, int value})>
  extractModeParametersWithNumbers(Slot slot) {
    final modeParameters = <String, ({int parameterNumber, int value})>{};

    final valueByParam = <int, int>{
      for (final v in slot.values) v.parameterNumber: v.value,
    };

    // Build enum lookup map
    final enumsByParam = <int, List<String>>{
      for (final e in slot.enums) e.parameterNumber: e.values,
    };

    debugPrint(
      'AlgorithmRouting: Scanning ${slot.parameters.length} parameters for mode parameters',
    );

    for (final param in slot.parameters) {
      // Mode parameters are identified by:
      // - name ending with 'mode' (case-insensitive)
      // - unit == 1 (enum type)
      // - enum values containing 'Add' and 'Replace'
      final enumValues = enumsByParam[param.parameterNumber];
      final isModeParameter =
          param.name.toLowerCase().endsWith('mode') &&
          param.unit == 1 &&
          enumValues != null &&
          enumValues.length >= 2 &&
          enumValues.contains('Add') &&
          enumValues.contains('Replace');

      if (param.name.toLowerCase().contains('output')) {
        debugPrint(
          'AlgorithmRouting: Checking output parameter ${param.name}: unit=${param.unit}, enums=$enumValues, isModeParam=$isModeParameter',
        );
      }

      if (isModeParameter) {
        final value = valueByParam[param.parameterNumber] ?? param.defaultValue;
        modeParameters[param.name] = (
          parameterNumber: param.parameterNumber,
          value: value,
        );
        debugPrint(
          'AlgorithmRouting: Found mode parameter: ${param.name} -> paramNum=${param.parameterNumber}, value=$value',
        );
      }
    }

    debugPrint(
      'AlgorithmRouting: Found ${modeParameters.length} mode parameters: ${modeParameters.keys}',
    );
    return modeParameters;
  }

  /// Helper method to get parameter value from a slot.
  ///
  /// Parameters:
  /// - [slot]: The slot to extract value from
  /// - [parameterName]: Name of the parameter to find
  ///
  /// Returns the parameter value or default value if not set
  @protected
  static int getParameterValue(Slot slot, String parameterName) {
    final param = slot.parameters.firstWhere(
      (p) => p.name == parameterName,
      orElse: () => ParameterInfo.filler(),
    );

    if (param.parameterNumber < 0) return 0;

    final valueByParam = <int, int>{
      for (final v in slot.values) v.parameterNumber: v.value,
    };

    return valueByParam[param.parameterNumber] ?? param.defaultValue;
  }

  /// Helper method to check if a parameter exists in a slot.
  ///
  /// Parameters:
  /// - [slot]: The slot to check
  /// - [parameterName]: Name of the parameter to find
  ///
  /// Returns true if the parameter exists
  @protected
  static bool hasParameter(Slot slot, String parameterName) {
    return slot.parameters.any((p) => p.name == parameterName);
  }
}
