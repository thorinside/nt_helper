import 'dart:ui';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:nt_helper/core/routing/models/port.dart';

/// Represents a drag operation state for creating connections
enum DragState {
  idle,
  dragStart,
  dragging,
  dragEnd,
}

/// Represents drag direction for connection creation
enum DragDirection {
  outputToInput,
  inputToOutput,
}

/// Data class for drag preview rendering
class DragPreviewData {
  final Offset startPosition;
  final Offset currentPosition;
  final Port sourcePort;
  final bool isValidDrop;

  const DragPreviewData({
    required this.startPosition,
    required this.currentPosition,
    required this.sourcePort,
    this.isValidDrop = false,
  });
}

/// Service for handling drag-and-drop connection creation gestures
class ConnectionDragHandler {
  DragState _currentState = DragState.idle;
  DragDirection? _dragDirection;
  Port? _sourcePort;
  Offset? _startPosition;
  Offset? _currentPosition;
  
  // Callbacks for drag events
  final void Function(Port sourcePort, Offset startPosition)? onDragStart;
  final void Function(Offset currentPosition, bool isValidDrop)? onDragUpdate;
  final void Function(Port sourcePort, Port? targetPort)? onDragEnd;
  final void Function()? onDragCancel;

  ConnectionDragHandler({
    this.onDragStart,
    this.onDragUpdate,
    this.onDragEnd,
    this.onDragCancel,
  });

  /// Current drag state
  DragState get state => _currentState;
  
  /// Current drag direction
  DragDirection? get direction => _dragDirection;
  
  /// Source port being dragged from
  Port? get sourcePort => _sourcePort;
  
  /// Current drag preview data
  DragPreviewData? get previewData {
    if (_sourcePort != null && _startPosition != null && _currentPosition != null) {
      return DragPreviewData(
        startPosition: _startPosition!,
        currentPosition: _currentPosition!,
        sourcePort: _sourcePort!,
        isValidDrop: _isValidDropZone(_currentPosition!),
      );
    }
    return null;
  }

  /// Start drag operation from a port
  void startDrag(Port port, Offset position) {
    if (_currentState != DragState.idle) return;

    _sourcePort = port;
    _startPosition = position;
    _currentPosition = position;
    _currentState = DragState.dragStart;
    
    // Determine drag direction based on port type
    _dragDirection = port.direction == PortDirection.output 
        ? DragDirection.outputToInput 
        : DragDirection.inputToOutput;

    onDragStart?.call(port, position);
    
    // Transition to dragging state
    _currentState = DragState.dragging;
  }

  /// Update drag position
  void updateDrag(Offset position) {
    if (_currentState != DragState.dragging) return;

    _currentPosition = position;
    final isValidDrop = _isValidDropZone(position);
    
    onDragUpdate?.call(position, isValidDrop);
  }

  /// End drag operation, potentially creating a connection
  void endDrag(Port? targetPort) {
    if (_currentState != DragState.dragging) return;

    _currentState = DragState.dragEnd;
    
    if (_sourcePort != null) {
      onDragEnd?.call(_sourcePort!, targetPort);
    }
    
    _resetDragState();
  }

  /// Cancel drag operation
  void cancelDrag() {
    if (_currentState == DragState.idle) return;

    onDragCancel?.call();
    _resetDragState();
  }

  /// Reset drag state to idle
  void _resetDragState() {
    _currentState = DragState.idle;
    _dragDirection = null;
    _sourcePort = null;
    _startPosition = null;
    _currentPosition = null;
  }

  /// Check if current position is over a valid drop zone
  bool _isValidDropZone(Offset position) {
    // TODO: Implement drop zone validation logic
    // This should check if the position is over a compatible port
    return true;
  }

  /// Detect if drag operation should start based on gesture
  bool shouldStartDrag(Offset delta) {
    const double dragThreshold = 8.0;
    return delta.distance > dragThreshold;
  }

  /// Get drag preview line coordinates with proper transforms
  List<Offset> getDragPreviewLine() {
    if (_startPosition == null || _currentPosition == null) {
      return [];
    }
    
    return [_startPosition!, _currentPosition!];
  }

  /// Check port compatibility for connection creation
  bool canConnect(Port sourcePort, Port targetPort) {
    // Output can connect to input
    if (sourcePort.direction == PortDirection.output &&
        targetPort.direction == PortDirection.input) {
      return _arePortTypesCompatible(sourcePort.type, targetPort.type);
    }

    // Input can connect to output (reverse drag)
    if (sourcePort.direction == PortDirection.input &&
        targetPort.direction == PortDirection.output) {
      return _arePortTypesCompatible(targetPort.type, sourcePort.type);
    }

    return false;
  }

  /// Check if two port types are compatible for connection
  bool _arePortTypesCompatible(PortType sourceType, PortType targetType) {
    // Same types are always compatible
    if (sourceType == targetType) return true;

    // Audio and CV are often interchangeable
    if ((sourceType == PortType.audio && targetType == PortType.cv) ||
        (sourceType == PortType.cv && targetType == PortType.audio)) {
      return true;
    }

    // Gate and trigger can be compatible
    // Note: Using 'gate' for both since 'trigger' may not exist in current PortType enum
    if (sourceType == PortType.gate && targetType == PortType.gate) {
      return true;
    }

    return false;
  }

  /// Normalize connection direction for consistent creation
  /// Returns (sourcePort, targetPort) with output always as source
  (Port source, Port target) normalizeConnection(Port portA, Port portB) {
    if (portA.direction == PortDirection.output) {
      return (portA, portB);
    } else {
      return (portB, portA);
    }
  }
}