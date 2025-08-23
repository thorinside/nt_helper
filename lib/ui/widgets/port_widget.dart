import 'package:flutter/material.dart';
import 'package:nt_helper/models/algorithm_port.dart';

enum PortType { input, output }

typedef PortPanStartCallback = void Function(DragStartDetails details);
typedef PortPanUpdateCallback = void Function(DragUpdateDetails details);
typedef PortPanEndCallback = void Function(DragEndDetails details);

class PortWidget extends StatefulWidget {
  final AlgorithmPort port;
  final PortType type;
  final VoidCallback? onConnectionStart;
  final VoidCallback? onConnectionEnd;
  final PortPanStartCallback? onPanStart;
  final PortPanUpdateCallback? onPanUpdate;
  final PortPanEndCallback? onPanEnd;
  final bool isHovered;
  final bool isConnected;

  const PortWidget({
    super.key,
    required this.port,
    required this.type,
    this.onConnectionStart,
    this.onConnectionEnd,
    this.onPanStart,
    this.onPanUpdate,
    this.onPanEnd,
    this.isHovered = false,
    this.isConnected = false,
  });

  @override
  State<PortWidget> createState() => _PortWidgetState();
}

class _PortWidgetState extends State<PortWidget> {
  bool _isPressed = false;
  bool _isDragging = false;
  Offset? _dragStartPosition;
  
  // Dead zone threshold - minimum distance to drag before starting a connection
  // This prevents accidental connection starts when trying to tap on the port
  static const double _dragThreshold = 10.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (details) {
        setState(() {
          _isPressed = true;
          _dragStartPosition = details.localPosition;
          _isDragging = false;
        });
      },
      onPanUpdate: (details) {
        if (widget.type == PortType.output) {
          // Check if we've moved beyond the threshold
          if (!_isDragging && _dragStartPosition != null) {
            final distance = (details.localPosition - _dragStartPosition!).distance;
            if (distance > _dragThreshold) {
              // Start the connection only after moving beyond threshold
              setState(() {
                _isDragging = true;
              });
              widget.onConnectionStart?.call();
              // Create a synthetic pan start at the original position
              final syntheticStart = DragStartDetails(
                localPosition: _dragStartPosition!,
                globalPosition: details.globalPosition - (details.localPosition - _dragStartPosition!),
              );
              widget.onPanStart?.call(syntheticStart);
            }
          }
          
          // Continue updating if we're dragging
          if (_isDragging) {
            widget.onPanUpdate?.call(details);
          }
        }
      },
      onPanEnd: (details) {
        setState(() {
          _isPressed = false;
        });
        
        if (widget.type == PortType.input) {
          widget.onConnectionEnd?.call();
        }
        
        if (widget.type == PortType.output && _isDragging) {
          // Only trigger pan end if we were actually dragging
          widget.onPanEnd?.call(details);
        }
        
        setState(() {
          _isDragging = false;
          _dragStartPosition = null;
        });
      },
      onTapDown: (_) {
        setState(() {
          _isPressed = true;
        });
      },
      onTap: () {
        // For now, taps on ports don't do anything
        // Connection creation requires dragging beyond the threshold
        // Connection removal is handled through the connection lines themselves
      },
      onTapUp: (_) {
        setState(() {
          _isPressed = false;
        });
      },
      onTapCancel: () {
        setState(() {
          _isPressed = false;
          _isDragging = false;
          _dragStartPosition = null;
        });
      },
      child: Container(
        width: 24,
        height: 24,
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _getPortColor(),
          border: Border.all(
            color: _getBorderColor(),
            width: _getBorderWidth(),
          ),
          boxShadow: widget.isHovered || _isPressed
              ? [
                  BoxShadow(
                    color: _getPortColor().withValues(alpha: 0.5),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: widget.isConnected ? 8 : 6,
            height: widget.isConnected ? 8 : 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.isConnected 
                  ? Colors.white 
                  : Colors.white.withValues(alpha: 0.7),
            ),
          ),
        ),
      ),
    );
  }

  Color _getPortColor() {
    final baseColor = _getPortTypeColor();
    
    if (_isPressed) {
      return baseColor.withValues(alpha: 0.8);
    } else if (widget.isHovered) {
      return baseColor.withValues(alpha: 0.9);
    } else if (widget.isConnected) {
      return baseColor;
    } else {
      return baseColor.withValues(alpha: 0.6);
    }
  }

  Color _getPortTypeColor() {
    // Color code by signal type based on port name
    final portName = widget.port.name.toLowerCase();
    
    if (portName.contains('audio') || portName.contains('signal')) {
      return Colors.blue;
    } else if (portName.contains('cv') || portName.contains('control')) {
      return Colors.orange;
    } else if (portName.contains('gate') || portName.contains('trigger')) {
      return Colors.green;
    } else if (portName.contains('clock') || portName.contains('sync')) {
      return Colors.purple;
    } else {
      return Colors.grey;
    }
  }

  Color _getBorderColor() {
    if (widget.isHovered || _isPressed) {
      return Colors.white;
    } else if (widget.isConnected) {
      return Colors.white.withValues(alpha: 0.8);
    } else {
      return Colors.white.withValues(alpha: 0.5);
    }
  }

  double _getBorderWidth() {
    if (widget.isHovered || _isPressed) {
      return 2.0;
    } else if (widget.isConnected) {
      return 1.5;
    } else {
      return 1.0;
    }
  }
}