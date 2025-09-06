import 'package:flutter/material.dart';
import 'package:nt_helper/cubit/routing_editor_state.dart';
import 'package:nt_helper/core/routing/models/port.dart' as core_port;

/// Represents the current state of a drag operation
enum DragState {
  idle,
  dragging,
  validTarget,
  invalidTarget,
}

/// Represents a connection being dragged
class DragConnection {
  final Port sourcePort;
  final Offset startPosition;
  final Offset currentPosition;
  final DragState state;
  final Port? targetPort;

  const DragConnection({
    required this.sourcePort,
    required this.startPosition,
    required this.currentPosition,
    required this.state,
    this.targetPort,
  });

  DragConnection copyWith({
    Port? sourcePort,
    Offset? startPosition,
    Offset? currentPosition,
    DragState? state,
    Port? targetPort,
  }) {
    return DragConnection(
      sourcePort: sourcePort ?? this.sourcePort,
      startPosition: startPosition ?? this.startPosition,
      currentPosition: currentPosition ?? this.currentPosition,
      state: state ?? this.state,
      targetPort: targetPort ?? this.targetPort,
    );
  }
}

/// Service to manage interactive connection creation through drag operations
class InteractiveConnectionManager {
  DragConnection? _currentDrag;
  final Map<String, Rect> _portBounds = {};

  /// Get the current drag connection if any
  DragConnection? get currentDrag => _currentDrag;

  /// Check if a drag operation is currently active
  bool get isDragging => _currentDrag != null;

  /// Start a new drag operation from the specified port
  void startDrag({
    required Port sourcePort,
    required Offset position,
  }) {
    _currentDrag = DragConnection(
      sourcePort: sourcePort,
      startPosition: position,
      currentPosition: position,
      state: DragState.dragging,
    );
  }

  /// Update the current drag position and validate target
  void updateDrag({
    required Offset position,
    required List<Port> availablePorts,
  }) {
    if (_currentDrag == null) return;

    // Find potential target port at current position
    final targetPort = _findPortAtPosition(position, availablePorts);
    
    // Validate connection if target found
    DragState newState = DragState.dragging;
    if (targetPort != null) {
      newState = _validateConnection(_currentDrag!.sourcePort, targetPort)
          ? DragState.validTarget
          : DragState.invalidTarget;
    }

    _currentDrag = _currentDrag!.copyWith(
      currentPosition: position,
      state: newState,
      targetPort: targetPort,
    );
  }

  /// Complete the drag operation and return connection data if valid
  Map<String, dynamic>? completeDrag() {
    if (_currentDrag == null || _currentDrag!.state != DragState.validTarget) {
      _currentDrag = null;
      return null;
    }

    final result = {
      'sourcePortId': _currentDrag!.sourcePort.id,
      'targetPortId': _currentDrag!.targetPort!.id,
      'outputMode': core_port.OutputMode.replace,
      'gain': 1.0,
    };

    _currentDrag = null;
    return result;
  }

  /// Cancel the current drag operation
  void cancelDrag() {
    _currentDrag = null;
  }

  /// Register port bounds for hit testing
  void registerPortBounds(String portId, Rect bounds) {
    _portBounds[portId] = bounds;
  }

  /// Clear all registered port bounds
  void clearPortBounds() {
    _portBounds.clear();
  }

  /// Find port at the given position
  Port? _findPortAtPosition(Offset position, List<Port> availablePorts) {
    for (final port in availablePorts) {
      final bounds = _portBounds[port.id];
      if (bounds != null && bounds.contains(position)) {
        return port;
      }
    }
    return null;
  }

  /// Validate if source and target ports can be connected
  bool _validateConnection(Port sourcePort, Port targetPort) {
    // Cannot connect to self
    if (sourcePort.id == targetPort.id) return false;

    // Must be output to input or input to output
    if (sourcePort.direction == targetPort.direction) return false;

    // Check signal type compatibility
    return _arePortTypesCompatible(sourcePort.type, targetPort.type);
  }

  /// Check if port types are compatible for connection
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

  /// Get all available ports from routing state
  List<Port> getAllPorts(RoutingEditorStateLoaded state) {
    final allPorts = <Port>[];
    
    // Add physical ports
    allPorts.addAll(state.physicalInputs);
    allPorts.addAll(state.physicalOutputs);
    
    // Add algorithm ports
    for (final algorithm in state.algorithms) {
      allPorts.addAll(algorithm.inputPorts);
      allPorts.addAll(algorithm.outputPorts);
    }
    
    return allPorts;
  }
}