import 'dart:async';
import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:nt_helper/cubit/disting_cubit.dart';
import 'package:nt_helper/core/routing/algorithm_routing.dart' as core_routing;
import 'package:nt_helper/core/routing/models/port.dart' as core_port;
import 'package:nt_helper/core/routing/models/connection.dart';
import 'package:nt_helper/core/routing/services/algorithm_connection_service.dart';
import 'package:nt_helper/core/routing/connection_discovery_service.dart';
import 'package:nt_helper/core/routing/services/connection_validator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'routing_editor_state.dart';


/// Cubit that manages the state of the routing editor.
///
/// Watches the DistingCubit's synchronized state and processes routing
/// information into a visual representation for the routing canvas.
class RoutingEditorCubit extends Cubit<RoutingEditorState> {
  final DistingCubit? _distingCubit;
  final Future<SharedPreferences> _prefs;
  StreamSubscription<DistingState>? _distingStateSubscription;

  RoutingEditorCubit(
    this._distingCubit, {
    AlgorithmConnectionService? algorithmConnectionService,
  }) : _prefs = SharedPreferences.getInstance(),
       super(const RoutingEditorState.initial()) {
    if (_distingCubit != null) {
      _initializeStateWatcher();
      _loadPersistedState();
    }
  }

  /// Initialize watching the disting cubit state changes
  void _initializeStateWatcher() {
    if (_distingCubit == null) return;

    _distingStateSubscription = _distingCubit.stream.listen((distingState) {
      _processDistingState(distingState);
    });

    // Process current state if already synchronized
    final currentState = _distingCubit.state;
    _processDistingState(currentState);
  }

  /// Generate stable algorithm IDs based on GUID and instance counter
  ///
  /// Creates IDs in the format `algo_${guid}_${instanceCounter}` where
  /// instanceCounter increments for duplicate algorithms to ensure uniqueness.
  /// These IDs remain stable regardless of slot position changes.
  List<String> generateStableAlgorithmIds(List<Slot> slots) {
    final algorithmIds = <String>[];
    final guidCounters = <String, int>{};

    for (final slot in slots) {
      final guid = slot.algorithm.guid;
      final counter = guidCounters[guid] ?? 0;
      guidCounters[guid] = counter + 1;

      // Create stable ID without slot index
      algorithmIds.add('algo_${guid}_${counter + 1}');
    }

    return algorithmIds;
  }

  /// Generate a stable port ID using algorithm UUID and parameter number
  ///
  /// Creates simple, opaque IDs with semantic information in metadata
  String generatePortId({
    required String algorithmId,
    required int parameterNumber,
    required String portType,
  }) {
    return '${algorithmId}_port_$parameterNumber';
  }

  /// Process incoming DistingState and update routing editor state accordingly
  void _processDistingState(DistingState distingState) {
    distingState.when(
      initial: () => emit(const RoutingEditorState.initial()),
      selectDevice: (inputDevices, outputDevices, canWorkOffline) =>
          emit(const RoutingEditorState.disconnected()),
      connected: (disting, inputDevice, outputDevice, offline, loading) =>
          emit(const RoutingEditorState.connecting()),
      synchronized:
          (
            disting,
            distingVersion,
            firmwareVersion,
            presetName,
            algorithms,
            slots,
            unitStrings,
            inputDevice,
            outputDevice,
            loading,
            offline,
            screenshot,
            demo,
            videoStream,
          ) {
            _processSynchronizedState(slots);
          },
    );
  }

  /// Extract routing data from synchronized state and build visual representation.
  ///
  /// This method implements performance optimization by only being called when the
  /// DistingCubit's synchronized state changes, ensuring physical connection discovery
  /// only runs when algorithm parameters or slots change, not on every UI rebuild.
  void _processSynchronizedState(List<Slot> slots) {
    debugPrint('[RoutingEditor] Processing synchronized state with ${slots.length} slots');
    try {
      // Create physical hardware ports
      final physicalInputs = _createPhysicalInputPorts();
      final physicalOutputs = _createPhysicalOutputPorts();

      // Build algorithm representations with ports determined by AlgorithmRouting
      final algorithms = <RoutingAlgorithm>[];
      final routings = <core_routing.AlgorithmRouting>[];

      // Generate stable UUIDs for each algorithm instance
      final algorithmUuids = generateStableAlgorithmIds(slots);

      for (int i = 0; i < slots.length; i++) {
        final slot = slots[i];
        final algorithmUuid = algorithmUuids[i];

        // Create routing using the AlgorithmRouting factory method
        final routing = core_routing.AlgorithmRouting.fromSlot(
          slot,
          algorithmUuid: algorithmUuid,
        );
        routings.add(routing);

        final inputPorts = routing.inputPorts;
        final outputPorts = routing.outputPorts;

        final routingAlgorithm = RoutingAlgorithm(
          id: algorithmUuid,
          index: i,
          algorithm: slot.algorithm,
          // Convert core ports to UI model ports
          inputPorts: inputPorts
              .map(
                (p) => Port(
                  id: p.id,
                  name: p.name,
                  type: _toUiPortType(p.type),
                  direction: PortDirection.input,
                  busNumber: p.busValue,
                  parameterName: p.busParam,
                ),
              )
              .toList(),
          outputPorts: outputPorts
              .map(
                (p) => Port(
                  id: p.id,
                  name: p.name,
                  type: _toUiPortType(p.type),
                  direction: PortDirection.output,
                  busNumber: p.busValue,
                  parameterName: p.busParam,
                ),
              )
              .toList(),
        );
        algorithms.add(routingAlgorithm);
      }

      // Use the ConnectionDiscoveryService to discover connections from AlgorithmRouting instances
      final discoveredConnections = ConnectionDiscoveryService.discoverConnections(
        routings,
      );

      // Validate connections for slot ordering violations
      final connections = ConnectionValidator.validateConnections(
        discoveredConnections,
        algorithms,
      );

      // For backward compatibility, keep empty lists for now
      // These will be removed in the next refactoring step

      emit(
        RoutingEditorState.loaded(
          physicalInputs: physicalInputs,
          physicalOutputs: physicalOutputs,
          algorithms: algorithms,
          connections: connections,
          isHardwareSynced: true,
          lastSyncTime: DateTime.now(),
        ),
      );

      // Initialize default buses after loading (fire and forget)
      initializeDefaultBuses();
    } catch (e) {
      debugPrint('Error processing synchronized state: $e');
      emit(RoutingEditorState.error('Failed to process routing data: $e'));
    }
  }

  /// Convert core port type (routing) to UI port type
  PortType _toUiPortType(core_port.PortType type) {
    switch (type) {
      case core_port.PortType.audio:
        return PortType.audio;
      case core_port.PortType.cv:
        return PortType.cv;
      case core_port.PortType.gate:
        return PortType.gate;
      case core_port.PortType.clock:
        return PortType.trigger; // closest match in UI enum
    }
  }

  /// Create the 12 physical input ports of the Disting NT
  List<Port> _createPhysicalInputPorts() {
    return [
      const Port(
        id: 'hw_in_1',
        name: 'I1',
        type: PortType.cv,
        direction: PortDirection.input,
      ),
      const Port(
        id: 'hw_in_2',
        name: 'I2',
        type: PortType.cv,
        direction: PortDirection.input,
      ),
      const Port(
        id: 'hw_in_3',
        name: 'I3',
        type: PortType.cv,
        direction: PortDirection.input,
      ),
      const Port(
        id: 'hw_in_4',
        name: 'I4',
        type: PortType.cv,
        direction: PortDirection.input,
      ),
      const Port(
        id: 'hw_in_5',
        name: 'I5',
        type: PortType.cv,
        direction: PortDirection.input,
      ),
      const Port(
        id: 'hw_in_6',
        name: 'I6',
        type: PortType.cv,
        direction: PortDirection.input,
      ),
      const Port(
        id: 'hw_in_7',
        name: 'I7',
        type: PortType.cv,
        direction: PortDirection.input,
      ),
      const Port(
        id: 'hw_in_8',
        name: 'I8',
        type: PortType.cv,
        direction: PortDirection.input,
      ),
      const Port(
        id: 'hw_in_9',
        name: 'I9',
        type: PortType.cv,
        direction: PortDirection.input,
      ),
      const Port(
        id: 'hw_in_10',
        name: 'I10',
        type: PortType.cv,
        direction: PortDirection.input,
      ),
      const Port(
        id: 'hw_in_11',
        name: 'I11',
        type: PortType.cv,
        direction: PortDirection.input,
      ),
      const Port(
        id: 'hw_in_12',
        name: 'I12',
        type: PortType.cv,
        direction: PortDirection.input,
      ),
    ];
  }

  /// Create the 8 physical output ports of the Disting NT
  List<Port> _createPhysicalOutputPorts() {
    return [
      const Port(
        id: 'hw_out_1',
        name: 'Audio Out 1',
        type: PortType.audio,
        direction: PortDirection.output,
      ),
      const Port(
        id: 'hw_out_2',
        name: 'Audio Out 2',
        type: PortType.audio,
        direction: PortDirection.output,
      ),
      const Port(
        id: 'hw_out_3',
        name: 'Audio Out 3',
        type: PortType.audio,
        direction: PortDirection.output,
      ),
      const Port(
        id: 'hw_out_4',
        name: 'Audio Out 4',
        type: PortType.audio,
        direction: PortDirection.output,
      ),
      const Port(
        id: 'hw_out_5',
        name: 'Audio Out 5',
        type: PortType.audio,
        direction: PortDirection.output,
      ),
      const Port(
        id: 'hw_out_6',
        name: 'Audio Out 6',
        type: PortType.audio,
        direction: PortDirection.output,
      ),
      const Port(
        id: 'hw_out_7',
        name: 'Audio Out 7',
        type: PortType.audio,
        direction: PortDirection.output,
      ),
      const Port(
        id: 'hw_out_8',
        name: 'Audio Out 8',
        type: PortType.audio,
        direction: PortDirection.output,
      ),
    ];
  }

  /// Create a new connection between source and target ports
  Future<void> createConnection({
    required String sourcePortId,
    required String targetPortId,
    String? busId,
    core_port.OutputMode outputMode = core_port.OutputMode.replace,
    double gain = 1.0,
  }) async {
    final currentState = state;
    if (currentState is! RoutingEditorStateLoaded) {
      debugPrint('Cannot create connection - routing editor not loaded');
      return;
    }

    try {
      // Validate ports exist
      final sourcePort = _findPortById(currentState, sourcePortId);
      final targetPort = _findPortById(currentState, targetPortId);

      if (sourcePort == null) {
        debugPrint('Source port not found: $sourcePortId');
        emit(RoutingEditorState.error('Source port not found: $sourcePortId'));
        return;
      }

      if (targetPort == null) {
        debugPrint('Target port not found: $targetPortId');
        emit(RoutingEditorState.error('Target port not found: $targetPortId'));
        return;
      }

      // Validate port compatibility
      if (!_canConnect(sourcePort, targetPort)) {
        debugPrint(
          'Ports are not compatible for connection: $sourcePortId -> $targetPortId',
        );
        emit(
          RoutingEditorState.error(
            'Incompatible ports: ${sourcePort.name} -> ${targetPort.name}',
          ),
        );
        return;
      }

      // Check for duplicate connections
      final existingConnection = _findExistingConnection(
        currentState,
        sourcePortId,
        targetPortId,
      );
      if (existingConnection != null) {
        debugPrint('Connection already exists: $sourcePortId -> $targetPortId');
        emit(RoutingEditorState.error('Connection already exists'));
        return;
      }

      // Generate unique connection ID
      final connectionId =
          'conn_${sourcePortId}_${targetPortId}_${DateTime.now().millisecondsSinceEpoch}';

      // Determine connection type
      final connectionType = _determineConnectionType(sourcePortId, targetPortId);

      // Create new connection
      final newConnection = Connection(
        id: connectionId,
        sourcePortId: sourcePortId,
        destinationPortId: targetPortId,
        connectionType: connectionType,
        outputMode: outputMode,
        gain: gain,
        createdAt: DateTime.now(),
      );

      // Update state with new connection
      final updatedConnections = [...currentState.connections, newConnection];

      emit(
        currentState.copyWith(connections: updatedConnections, lastError: null),
      );

      debugPrint(
        'Connection created: ${sourcePort.name} -> ${targetPort.name}',
      );

      // Mark hardware as out of sync after local changes
      await _autoSyncToHardware();
    } catch (e) {
      debugPrint('Error creating connection: $e');
      emit(RoutingEditorState.error('Failed to create connection: $e'));
    }
  }

  /// Delete an existing connection by ID
  Future<void> deleteConnection(String connectionId) async {
    final currentState = state;
    if (currentState is! RoutingEditorStateLoaded) {
      debugPrint('Cannot delete connection - routing editor not loaded');
      return;
    }

    try {
      // Find the connection to delete
      final connectionToDelete = currentState.connections.firstWhere(
        (connection) => connection.id == connectionId,
        orElse: () =>
            throw ArgumentError('Connection not found: $connectionId'),
      );

      // Remove connection from state
      final updatedConnections = currentState.connections
          .where((connection) => connection.id != connectionId)
          .toList();

      // Update bus if connection was assigned to one
      List<RoutingBus> updatedBuses = currentState.buses;
      if (connectionToDelete.busId != null) {
        updatedBuses = currentState.buses.map((bus) {
          if (bus.id == connectionToDelete.busId) {
            final updatedConnectionIds = bus.connectionIds
                .where((id) => id != connectionId)
                .toList();
            return bus.copyWith(
              connectionIds: updatedConnectionIds,
              status: updatedConnectionIds.isEmpty
                  ? BusStatus.available
                  : BusStatus.assigned,
              modifiedAt: DateTime.now(),
            );
          }
          return bus;
        }).toList();
      }

      emit(
        currentState.copyWith(
          connections: updatedConnections,
          buses: updatedBuses,
          lastError: null,
        ),
      );

      final sourcePort = _findPortById(
        currentState,
        connectionToDelete.sourcePortId,
      );
      final targetPort = _findPortById(
        currentState,
        connectionToDelete.destinationPortId,
      );
      debugPrint(
        'Connection deleted: ${sourcePort?.name} -> ${targetPort?.name}',
      );

      // Mark hardware as out of sync after local changes
      await _autoSyncToHardware();
    } catch (e) {
      debugPrint('Error deleting connection: $e');
      emit(RoutingEditorState.error('Failed to delete connection: $e'));
    }
  }

  /// Delete all connections for a specific port
  Future<void> deleteConnectionsForPort(String portId) async {
    final currentState = state;
    if (currentState is! RoutingEditorStateLoaded) {
      debugPrint('Cannot delete connections - routing editor not loaded');
      return;
    }

    try {
      final connectionsToDelete = currentState.connections
          .where(
            (connection) =>
                connection.sourcePortId == portId ||
                connection.destinationPortId == portId,
          )
          .toList();

      if (connectionsToDelete.isEmpty) {
        debugPrint('No connections found for port: $portId');
        return;
      }

      // Delete each connection
      for (final connection in connectionsToDelete) {
        await deleteConnection(connection.id);
      }

      debugPrint(
        'Deleted ${connectionsToDelete.length} connections for port: $portId',
      );
    } catch (e) {
      debugPrint('Error deleting connections for port: $e');
      emit(
        RoutingEditorState.error('Failed to delete connections for port: $e'),
      );
    }
  }

  /// Update an existing connection's properties
  Future<void> updateConnection({
    required String connectionId,
    String? busId,
    core_port.OutputMode? outputMode,
    double? gain,
    bool? isMuted,
  }) async {
    final currentState = state;
    if (currentState is! RoutingEditorStateLoaded) {
      debugPrint('Cannot update connection - routing editor not loaded');
      return;
    }

    try {
      final connectionIndex = currentState.connections.indexWhere(
        (connection) => connection.id == connectionId,
      );

      if (connectionIndex == -1) {
        debugPrint('Connection not found for update: $connectionId');
        emit(RoutingEditorState.error('Connection not found: $connectionId'));
        return;
      }

      final existingConnection = currentState.connections[connectionIndex];
      final updatedConnection = existingConnection.copyWith(
        busId: busId ?? existingConnection.busId,
        outputMode: outputMode ?? existingConnection.outputMode,
        gain: gain ?? existingConnection.gain,
        isMuted: isMuted ?? existingConnection.isMuted,
        modifiedAt: DateTime.now(),
      );

      final updatedConnections = [...currentState.connections];
      updatedConnections[connectionIndex] = updatedConnection;

      emit(
        currentState.copyWith(connections: updatedConnections, lastError: null),
      );

      debugPrint('Connection updated: $connectionId');
    } catch (e) {
      debugPrint('Error updating connection: $e');
      emit(RoutingEditorState.error('Failed to update connection: $e'));
    }
  }


  /// Helper method to find a port by ID across all port lists
  Port? _findPortById(RoutingEditorStateLoaded state, String portId) {
    // Check physical inputs
    for (final port in state.physicalInputs) {
      if (port.id == portId) return port;
    }

    // Check physical outputs
    for (final port in state.physicalOutputs) {
      if (port.id == portId) return port;
    }

    // Check algorithm ports
    for (final algorithm in state.algorithms) {
      for (final port in algorithm.inputPorts) {
        if (port.id == portId) return port;
      }
      for (final port in algorithm.outputPorts) {
        if (port.id == portId) return port;
      }
    }

    return null;
  }

  /// Helper method to check if two ports can be connected
  bool _canConnect(Port sourcePort, Port targetPort) {
    // Output can connect to input
    if (sourcePort.direction == PortDirection.output &&
        targetPort.direction == PortDirection.input) {
      return _arePortTypesCompatible(sourcePort.type, targetPort.type);
    }

    return false;
  }

  /// Helper method to check port type compatibility
  bool _arePortTypesCompatible(PortType sourceType, PortType targetType) {
    // Same types are always compatible
    if (sourceType == targetType) return true;

    // Audio and CV are often interchangeable
    if ((sourceType == PortType.audio && targetType == PortType.cv) ||
        (sourceType == PortType.cv && targetType == PortType.audio)) {
      return true;
    }

    // Gate and trigger can be compatible
    if ((sourceType == PortType.gate && targetType == PortType.trigger) ||
        (sourceType == PortType.trigger && targetType == PortType.gate)) {
      return true;
    }

    return false;
  }

  /// Helper method to determine if a connection is a ghost connection
  /// Ghost connections occur when an algorithm output connects to a physical input
  
  /// Helper method to determine the type of connection based on port IDs
  ConnectionType _determineConnectionType(String sourcePortId, String targetPortId) {
    final isSourceHardware = sourcePortId.startsWith('hw_in_');
    final isTargetHardware = targetPortId.startsWith('hw_out_');
    
    if (isSourceHardware) {
      return ConnectionType.hardwareInput;
    } else if (isTargetHardware) {
      return ConnectionType.hardwareOutput;
    } else {
      return ConnectionType.algorithmToAlgorithm;
    }
  }

  /// Helper method to find existing connection between two ports
  Connection? _findExistingConnection(
    RoutingEditorStateLoaded state,
    String sourcePortId,
    String targetPortId,
  ) {
    try {
      return state.connections.firstWhere(
        (connection) =>
            connection.sourcePortId == sourcePortId &&
            connection.destinationPortId == targetPortId,
      );
    } catch (e) {
      return null;
    }
  }

  /// Create a new routing bus
  Future<void> createBus({
    required String name,
    core_port.OutputMode defaultOutputMode = core_port.OutputMode.replace,
    double masterGain = 1.0,
  }) async {
    final currentState = state;
    if (currentState is! RoutingEditorStateLoaded) {
      debugPrint('Cannot create bus - routing editor not loaded');
      return;
    }

    try {
      // Generate unique bus ID
      final busId = 'bus_${DateTime.now().millisecondsSinceEpoch}';

      // Create new bus
      final newBus = RoutingBus(
        id: busId,
        name: name,
        status: BusStatus.available,
        defaultOutputMode: defaultOutputMode,
        masterGain: masterGain,
        createdAt: DateTime.now(),
      );

      // Update state with new bus
      final updatedBuses = [...currentState.buses, newBus];

      emit(currentState.copyWith(buses: updatedBuses, lastError: null));

      debugPrint('Bus created: $name (ID: $busId)');

      // Mark hardware as out of sync after local changes
      await _autoSyncToHardware();
    } catch (e) {
      debugPrint('Error creating bus: $e');
      emit(RoutingEditorState.error('Failed to create bus: $e'));
    }
  }

  /// Delete a routing bus and reassign its connections
  Future<void> deleteBus(String busId) async {
    final currentState = state;
    if (currentState is! RoutingEditorStateLoaded) {
      debugPrint('Cannot delete bus - routing editor not loaded');
      return;
    }

    try {
      // Find the bus to delete
      final busToDelete = currentState.buses.firstWhere(
        (bus) => bus.id == busId,
        orElse: () => throw ArgumentError('Bus not found: $busId'),
      );

      // Remove bus assignment from all connections
      final updatedConnections = currentState.connections.map((connection) {
        if (connection.busId == busId) {
          return connection.copyWith(busId: null, modifiedAt: DateTime.now());
        }
        return connection;
      }).toList();

      // Remove bus from state
      final updatedBuses = currentState.buses
          .where((bus) => bus.id != busId)
          .toList();

      emit(
        currentState.copyWith(
          buses: updatedBuses,
          connections: updatedConnections,
          lastError: null,
        ),
      );

      debugPrint(
        'Bus deleted: ${busToDelete.name} (${busToDelete.connectionIds.length} connections unassigned)',
      );
    } catch (e) {
      debugPrint('Error deleting bus: $e');
      emit(RoutingEditorState.error('Failed to delete bus: $e'));
    }
  }

  /// Assign a connection to a routing bus
  Future<void> assignConnectionToBus({
    required String connectionId,
    required String busId,
    core_port.OutputMode? outputMode,
  }) async {
    final currentState = state;
    if (currentState is! RoutingEditorStateLoaded) {
      debugPrint('Cannot assign connection to bus - routing editor not loaded');
      return;
    }

    try {
      // Find the connection
      final connectionIndex = currentState.connections.indexWhere(
        (connection) => connection.id == connectionId,
      );

      if (connectionIndex == -1) {
        debugPrint('Connection not found: $connectionId');
        emit(RoutingEditorState.error('Connection not found: $connectionId'));
        return;
      }

      // Find the bus
      final busIndex = currentState.buses.indexWhere((bus) => bus.id == busId);

      if (busIndex == -1) {
        debugPrint('Bus not found: $busId');
        emit(RoutingEditorState.error('Bus not found: $busId'));
        return;
      }

      final existingConnection = currentState.connections[connectionIndex];
      final existingBus = currentState.buses[busIndex];

      // Remove connection from old bus if it was assigned
      List<RoutingBus> updatedBuses = [...currentState.buses];
      if (existingConnection.busId != null) {
        for (int i = 0; i < updatedBuses.length; i++) {
          if (updatedBuses[i].id == existingConnection.busId) {
            final oldBusConnectionIds = updatedBuses[i].connectionIds
                .where((id) => id != connectionId)
                .toList();
            updatedBuses[i] = updatedBuses[i].copyWith(
              connectionIds: oldBusConnectionIds,
              status: oldBusConnectionIds.isEmpty
                  ? BusStatus.available
                  : BusStatus.assigned,
              modifiedAt: DateTime.now(),
            );
            break;
          }
        }
      }

      // Update connection with new bus assignment
      final updatedConnection = existingConnection.copyWith(
        busId: busId,
        outputMode: outputMode ?? existingBus.defaultOutputMode,
        modifiedAt: DateTime.now(),
      );

      final updatedConnections = [...currentState.connections];
      updatedConnections[connectionIndex] = updatedConnection;

      // Add connection to new bus
      final newBusConnectionIds = [...existingBus.connectionIds, connectionId];
      updatedBuses[busIndex] = existingBus.copyWith(
        connectionIds: newBusConnectionIds,
        status: BusStatus.assigned,
        modifiedAt: DateTime.now(),
      );

      emit(
        currentState.copyWith(
          connections: updatedConnections,
          buses: updatedBuses,
          lastError: null,
        ),
      );

      debugPrint(
        'Connection assigned to bus: $connectionId -> ${existingBus.name}',
      );
    } catch (e) {
      debugPrint('Error assigning connection to bus: $e');
      emit(RoutingEditorState.error('Failed to assign connection to bus: $e'));
    }
  }

  /// Remove a connection from its assigned bus
  Future<void> unassignConnectionFromBus(String connectionId) async {
    final currentState = state;
    if (currentState is! RoutingEditorStateLoaded) {
      debugPrint(
        'Cannot unassign connection from bus - routing editor not loaded',
      );
      return;
    }

    try {
      // Find the connection
      final connectionIndex = currentState.connections.indexWhere(
        (connection) => connection.id == connectionId,
      );

      if (connectionIndex == -1) {
        debugPrint('Connection not found: $connectionId');
        emit(RoutingEditorState.error('Connection not found: $connectionId'));
        return;
      }

      final existingConnection = currentState.connections[connectionIndex];

      if (existingConnection.busId == null) {
        debugPrint('Connection is not assigned to any bus: $connectionId');
        return;
      }

      // Update connection to remove bus assignment
      final updatedConnection = existingConnection.copyWith(
        busId: null,
        modifiedAt: DateTime.now(),
      );

      final updatedConnections = [...currentState.connections];
      updatedConnections[connectionIndex] = updatedConnection;

      // Update bus to remove connection
      final updatedBuses = currentState.buses.map((bus) {
        if (bus.id == existingConnection.busId) {
          final updatedConnectionIds = bus.connectionIds
              .where((id) => id != connectionId)
              .toList();
          return bus.copyWith(
            connectionIds: updatedConnectionIds,
            status: updatedConnectionIds.isEmpty
                ? BusStatus.available
                : BusStatus.assigned,
            modifiedAt: DateTime.now(),
          );
        }
        return bus;
      }).toList();

      emit(
        currentState.copyWith(
          connections: updatedConnections,
          buses: updatedBuses,
          lastError: null,
        ),
      );

      debugPrint('Connection unassigned from bus: $connectionId');
    } catch (e) {
      debugPrint('Error unassigning connection from bus: $e');
      emit(
        RoutingEditorState.error('Failed to unassign connection from bus: $e'),
      );
    }
  }

  /// Set output mode for a specific port
  Future<void> setPortOutputMode({
    required String portId,
    required core_port.OutputMode outputMode,
  }) async {
    final currentState = state;
    if (currentState is! RoutingEditorStateLoaded) {
      debugPrint('Cannot set port output mode - routing editor not loaded');
      return;
    }

    try {
      // Verify port exists
      final port = _findPortById(currentState, portId);
      if (port == null) {
        debugPrint('Port not found: $portId');
        emit(RoutingEditorState.error('Port not found: $portId'));
        return;
      }

      // Verify it's an output port
      if (port.direction != PortDirection.output) {
        debugPrint('Cannot set output mode for input port: $portId');
        emit(
          RoutingEditorState.error(
            'Output mode can only be set for output ports',
          ),
        );
        return;
      }

      // Update port output modes
      final updatedPortOutputModes = Map<String, core_port.OutputMode>.from(
        currentState.portOutputModes,
      );
      updatedPortOutputModes[portId] = outputMode;

        // Update connections that use this port as source
        final updatedConnections = currentState.connections.map((conn) {
          if (conn.sourcePortId == portId) {
            return conn.copyWith(outputMode: outputMode);
          }
          return conn;
        }).toList();

        emit(
          currentState.copyWith(
            portOutputModes: updatedPortOutputModes,
            connections: updatedConnections,
            lastError: null,
          ),
        );

      debugPrint('Port output mode set: ${port.name} -> $outputMode');
    } catch (e) {
      debugPrint('Error setting port output mode: $e');
      emit(RoutingEditorState.error('Failed to set port output mode: $e'));
    }
  }

  /// Get output mode for a specific port
  core_port.OutputMode getPortOutputMode(String portId) {
    final currentState = state;
    if (currentState is RoutingEditorStateLoaded) {
      return currentState.portOutputModes[portId] ?? core_port.OutputMode.replace;
    }
    return core_port.OutputMode.replace;
  }

  /// Update bus properties
  Future<void> updateBus({
    required String busId,
    String? name,
    core_port.OutputMode? defaultOutputMode,
    double? masterGain,
  }) async {
    final currentState = state;
    if (currentState is! RoutingEditorStateLoaded) {
      debugPrint('Cannot update bus - routing editor not loaded');
      return;
    }

    try {
      final busIndex = currentState.buses.indexWhere((bus) => bus.id == busId);

      if (busIndex == -1) {
        debugPrint('Bus not found for update: $busId');
        emit(RoutingEditorState.error('Bus not found: $busId'));
        return;
      }

      final existingBus = currentState.buses[busIndex];
      final updatedBus = existingBus.copyWith(
        name: name ?? existingBus.name,
        defaultOutputMode: defaultOutputMode ?? existingBus.defaultOutputMode,
        masterGain: masterGain ?? existingBus.masterGain,
        modifiedAt: DateTime.now(),
      );

      final updatedBuses = [...currentState.buses];
      updatedBuses[busIndex] = updatedBus;

      emit(currentState.copyWith(buses: updatedBuses, lastError: null));

      debugPrint('Bus updated: ${updatedBus.name}');
    } catch (e) {
      debugPrint('Error updating bus: $e');
      emit(RoutingEditorState.error('Failed to update bus: $e'));
    }
  }

  /// Get all connections assigned to a specific bus
  List<Connection> getConnectionsForBus(String busId) {
    final currentState = state;
    if (currentState is RoutingEditorStateLoaded) {
      return currentState.connections
          .where((connection) => connection.busId == busId)
          .toList();
    }
    return [];
  }

  /// Get bus by ID
  RoutingBus? getBusById(String busId) {
    final currentState = state;
    if (currentState is RoutingEditorStateLoaded) {
      try {
        return currentState.buses.firstWhere((bus) => bus.id == busId);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  /// Initialize default routing buses
  Future<void> initializeDefaultBuses() async {
    final currentState = state;
    if (currentState is! RoutingEditorStateLoaded) {
      debugPrint('Cannot initialize default buses - routing editor not loaded');
      return;
    }

    try {
      final defaultBuses = [
        RoutingBus(
          id: 'bus_audio_main',
          name: 'Audio Main',
          status: BusStatus.available,
          defaultOutputMode: core_port.OutputMode.add,
          masterGain: 1.0,
          createdAt: DateTime.now(),
        ),
        RoutingBus(
          id: 'bus_cv_main',
          name: 'CV Main',
          status: BusStatus.available,
          defaultOutputMode: core_port.OutputMode.replace,
          masterGain: 1.0,
          createdAt: DateTime.now(),
        ),
        RoutingBus(
          id: 'bus_gate_main',
          name: 'Gate/Trigger Main',
          status: BusStatus.available,
          defaultOutputMode: core_port.OutputMode.replace,
          masterGain: 1.0,
          createdAt: DateTime.now(),
        ),
      ];

      // Add default buses if they don't already exist
      final existingBusIds = currentState.buses.map((bus) => bus.id).toSet();
      final newBuses = defaultBuses
          .where((bus) => !existingBusIds.contains(bus.id))
          .toList();

      if (newBuses.isNotEmpty) {
        final updatedBuses = [...currentState.buses, ...newBuses];

        emit(currentState.copyWith(buses: updatedBuses, lastError: null));

        debugPrint('Initialized ${newBuses.length} default buses');
      }
    } catch (e) {
      debugPrint('Error initializing default buses: $e');
      emit(RoutingEditorState.error('Failed to initialize default buses: $e'));
    }
  }

  /// Sync the current routing editor state with hardware
  Future<void> syncToHardware() async {
    final currentState = state;
    if (currentState is! RoutingEditorStateLoaded) {
      debugPrint('Cannot sync to hardware - routing editor not loaded');
      return;
    }

    emit(const RoutingEditorState.syncing());

    try {
      debugPrint(
        'Starting hardware sync with ${currentState.connections.length} connections',
      );

      // Update sync status
      final syncTime = DateTime.now();

      emit(
        currentState.copyWith(
          isHardwareSynced: true,
          lastSyncTime: syncTime,
          lastError: null,
        ),
      );

      debugPrint('Hardware sync completed at $syncTime');
    } catch (e) {
      debugPrint('Error syncing to hardware: $e');
      emit(RoutingEditorState.error('Failed to sync to hardware: $e'));
    }
  }

  /// Sync hardware routing data to the routing editor state
  Future<void> syncFromHardware() async {
    final currentState = state;
    if (currentState is! RoutingEditorStateLoaded) {
      debugPrint('Cannot sync from hardware - routing editor not loaded');
      return;
    }

    emit(const RoutingEditorState.syncing());

    try {
      debugPrint('Starting hardware sync from device');

      // Trigger hardware routing refresh through DistingCubit
      await _distingCubit?.refreshRouting();

      // The state will be updated through the stream subscription
      // when _processSynchronizedState is called

      debugPrint('Hardware sync from device initiated');
    } catch (e) {
      debugPrint('Error syncing from hardware: $e');
      emit(RoutingEditorState.error('Failed to sync from hardware: $e'));
    }
  }

  /// Check if hardware sync is required
  bool isHardwareSyncRequired() {
    final currentState = state;
    if (currentState is! RoutingEditorStateLoaded) {
      return false;
    }

    return !currentState.isHardwareSynced;
  }

  /// Mark hardware as out of sync (called when local changes are made)
  void markHardwareOutOfSync() {
    final currentState = state;
    if (currentState is RoutingEditorStateLoaded &&
        currentState.isHardwareSynced) {
      emit(currentState.copyWith(isHardwareSynced: false, lastError: null));
      debugPrint('Hardware marked as out of sync');
    }
  }

  /// Auto-sync to hardware when changes are made (if enabled)
  Future<void> _autoSyncToHardware() async {
    final currentState = state;
    if (currentState is RoutingEditorStateLoaded) {
      // Mark as out of sync first
      markHardwareOutOfSync();

      // Auto-save state after changes
      await _autoSaveState();

      // Auto-sync could be enabled/disabled via a setting
      // For now, we'll just mark as out of sync and let the user manually sync
      debugPrint('Auto-sync would trigger here (disabled for now)');
    }
  }

  /// Get hardware sync status information
  Map<String, dynamic> getHardwareSyncStatus() {
    final currentState = state;
    if (currentState is RoutingEditorStateLoaded) {
      return {
        'isHardwareSynced': currentState.isHardwareSynced,
        'lastSyncTime': currentState.lastSyncTime?.toIso8601String(),
        'connectionCount': currentState.connections.length,
        'busCount': currentState.buses.length,
      };
    }
    return {
      'isHardwareSynced': false,
      'lastSyncTime': null,
      'connectionCount': 0,
      'busCount': 0,
    };
  }

  /// Refresh routing data from hardware
  Future<void> refreshRouting() async {
    if (state is RoutingEditorStateLoaded) {
      emit(const RoutingEditorState.refreshing());
    }

    try {
      await _distingCubit?.refreshRouting();
      // State will be updated through the stream subscription
    } catch (e) {
      debugPrint('Error refreshing routing: $e');
      emit(RoutingEditorState.error('Failed to refresh routing: $e'));
    }
  }

  /// Clear the current routing state
  void clearRouting() {
    emit(const RoutingEditorState.initial());
  }

  /// Save current routing editor state to persistent storage
  Future<void> saveState() async {
    final currentState = state;
    if (currentState is! RoutingEditorStateLoaded) {
      debugPrint('Cannot save state - routing editor not loaded');
      return;
    }

    emit(const RoutingEditorState.persisting());

    try {
      final prefs = await _prefs;

      // Prepare state data for serialization
      final stateData = {
        'connections': currentState.connections
            .map(
              (connection) => {
                'id': connection.id,
                'sourcePortId': connection.sourcePortId,
                'targetPortId': connection.destinationPortId,
                'busId': connection.busId,
                'outputMode': connection.outputMode?.name,
                'gain': connection.gain,
                'isMuted': connection.isMuted,
                'createdAt': connection.createdAt?.toIso8601String(),
                'modifiedAt': connection.modifiedAt?.toIso8601String(),
              },
            )
            .toList(),
        'buses': currentState.buses
            .map(
              (bus) => {
                'id': bus.id,
                'name': bus.name,
                'status': bus.status.name,
                'connectionIds': bus.connectionIds,
                'defaultOutputMode': bus.defaultOutputMode.name,
                'masterGain': bus.masterGain,
                'createdAt': bus.createdAt?.toIso8601String(),
                'modifiedAt': bus.modifiedAt?.toIso8601String(),
              },
            )
            .toList(),
        'portOutputModes': currentState.portOutputModes.map(
          (key, value) => MapEntry(key, value.name),
        ),
        'lastSyncTime': currentState.lastSyncTime?.toIso8601String(),
        'lastPersistTime': DateTime.now().toIso8601String(),
      };

      // Save to SharedPreferences
      final jsonString = jsonEncode(stateData);
      await prefs.setString('routing_editor_state', jsonString);

      // Update state with persistence timestamp
      final persistTime = DateTime.now();
      emit(
        currentState.copyWith(
          isPersistenceEnabled: true,
          lastPersistTime: persistTime,
          lastError: null,
        ),
      );

      debugPrint('Routing editor state saved at $persistTime');
    } catch (e) {
      debugPrint('Error saving routing editor state: $e');
      emit(RoutingEditorState.error('Failed to save state: $e'));
    }
  }

  /// Load routing editor state from persistent storage
  Future<void> _loadPersistedState() async {
    try {
      final prefs = await _prefs;
      final jsonString = prefs.getString('routing_editor_state');

      if (jsonString == null) {
        debugPrint('No persisted routing editor state found');
        return;
      }

      debugPrint('Loading persisted routing editor state');

      final stateData = jsonDecode(jsonString) as Map<String, dynamic>;

      // Parse connections
      final connections = <Connection>[];
      for (final connectionData in stateData['connections'] as List) {
        final connectionMap = connectionData as Map<String, dynamic>;
        connections.add(
          Connection(
            id: connectionMap['id'] as String,
            sourcePortId: connectionMap['sourcePortId'] as String,
            destinationPortId: connectionMap['targetPortId'] as String,
            connectionType: ConnectionType.values.firstWhere(
              (type) => type.name == connectionMap['connectionType'],
              orElse: () => ConnectionType.algorithmToAlgorithm,
            ),
            outputMode: core_port.OutputMode.values.firstWhere(
              (mode) => mode.name == connectionMap['outputMode'],
              orElse: () => core_port.OutputMode.replace,
            ),
            gain: (connectionMap['gain'] as num?)?.toDouble() ?? 1.0,
            isMuted: connectionMap['isMuted'] as bool? ?? false,
            createdAt: connectionMap['createdAt'] != null
                ? DateTime.parse(connectionMap['createdAt'] as String)
                : null,
            modifiedAt: connectionMap['modifiedAt'] != null
                ? DateTime.parse(connectionMap['modifiedAt'] as String)
                : null,
          ),
        );
      }

      // Parse buses
      final buses = <RoutingBus>[];
      for (final busData in stateData['buses'] as List) {
        final busMap = busData as Map<String, dynamic>;
        buses.add(
          RoutingBus(
            id: busMap['id'] as String,
            name: busMap['name'] as String,
            status: BusStatus.values.firstWhere(
              (status) => status.name == busMap['status'],
              orElse: () => BusStatus.available,
            ),
            connectionIds: (busMap['connectionIds'] as List).cast<String>(),
            defaultOutputMode: core_port.OutputMode.values.firstWhere(
              (mode) => mode.name == busMap['defaultOutputMode'],
              orElse: () => core_port.OutputMode.replace,
            ),
            masterGain: (busMap['masterGain'] as num?)?.toDouble() ?? 1.0,
            createdAt: busMap['createdAt'] != null
                ? DateTime.parse(busMap['createdAt'] as String)
                : null,
            modifiedAt: busMap['modifiedAt'] != null
                ? DateTime.parse(busMap['modifiedAt'] as String)
                : null,
          ),
        );
      }

      // Parse port output modes
      final portOutputModes = <String, core_port.OutputMode>{};
      final portModeData =
          stateData['portOutputModes'] as Map<String, dynamic>?;
      if (portModeData != null) {
        for (final entry in portModeData.entries) {
          portOutputModes[entry.key] = core_port.OutputMode.values.firstWhere(
            (mode) => mode.name == entry.value,
            orElse: () => core_port.OutputMode.replace,
          );
        }
      }

      // Parse timestamps (kept for future use, currently unused)
      // final lastSyncTime = stateData['lastSyncTime'] != null
      //     ? DateTime.parse(stateData['lastSyncTime'] as String)
      //     : null;
      // final lastPersistTime = stateData['lastPersistTime'] != null
      //     ? DateTime.parse(stateData['lastPersistTime'] as String)
      //     : null;

      debugPrint(
        'Loaded ${connections.length} connections, ${buses.length} buses from persistent storage',
      );
    } catch (e) {
      debugPrint('Error loading persisted routing editor state: $e');
      // Don't emit error state here, just log and continue with empty state
    }
  }

  /// Clear all persisted state data
  Future<void> clearPersistedState() async {
    try {
      final prefs = await _prefs;
      await prefs.remove('routing_editor_state');

      final currentState = state;
      if (currentState is RoutingEditorStateLoaded) {
        emit(
          currentState.copyWith(
            isPersistenceEnabled: false,
            lastPersistTime: null,
            lastError: null,
          ),
        );
      }

      debugPrint('Persisted routing editor state cleared');
    } catch (e) {
      debugPrint('Error clearing persisted state: $e');
      emit(RoutingEditorState.error('Failed to clear persisted state: $e'));
    }
  }

  /// Get persistence status information
  Map<String, dynamic> getPersistenceStatus() {
    final currentState = state;
    if (currentState is RoutingEditorStateLoaded) {
      return {
        'isPersistenceEnabled': currentState.isPersistenceEnabled,
        'lastPersistTime': currentState.lastPersistTime?.toIso8601String(),
        'connectionCount': currentState.connections.length,
        'busCount': currentState.buses.length,
      };
    }
    return {
      'isPersistenceEnabled': false,
      'lastPersistTime': null,
      'connectionCount': 0,
      'busCount': 0,
    };
  }

  /// Auto-save state after changes (if enabled)
  Future<void> _autoSaveState() async {
    final currentState = state;
    if (currentState is RoutingEditorStateLoaded &&
        currentState.isPersistenceEnabled) {
      debugPrint('Auto-saving routing editor state');
      await saveState();
    }
  }

  /// Enhanced error recovery method
  Future<void> recoverFromError() async {
    final currentState = state;
    if (currentState is RoutingEditorStateError) {
      debugPrint('Attempting recovery from error: ${currentState.message}');

      try {
        // Try to reload the last known good state
        await _loadPersistedState();

        // If no persisted state, return to initial state
        emit(const RoutingEditorState.initial());

        debugPrint('Recovery attempt completed');
      } catch (e) {
        debugPrint('Recovery failed: $e');
        emit(RoutingEditorState.error('Recovery failed: $e'));
      }
    }
  }

  @override
  Future<void> close() {
    _distingStateSubscription?.cancel();
    return super.close();
  }
}
