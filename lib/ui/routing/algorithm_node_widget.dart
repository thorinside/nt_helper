import 'package:flutter/material.dart';
import 'package:nt_helper/models/algorithm_port.dart';
import 'package:nt_helper/models/node_position.dart';
import 'package:nt_helper/ui/widgets/port_widget.dart';

typedef PositionChangedCallback = void Function(NodePosition position);
typedef PortConnectionCallback = void Function(String portId, PortType type);
typedef PortPanCallback = void Function(String portId, PortType type, DragStartDetails details);
typedef PortPanUpdateCallback = void Function(String portId, PortType type, DragUpdateDetails details);
typedef PortPanEndCallback = void Function(String portId, PortType type, DragEndDetails details);

class AlgorithmNodeWidget extends StatefulWidget {
  // Layout constants
  static const double headerVerticalPadding = 6.0;
  static const double headerButtonHeight = 24.0;
  static const double headerHeight = headerVerticalPadding * 2 + headerButtonHeight;
  static const double horizontalPadding = 8.0;
  static const double portsVerticalPadding = 4.0;
  static const double portWidgetSize = 16.0;
  static const double portVerticalMargin = 2.0;
  static const double portRowPadding = 1.0;
  static const double portRowHeight = portWidgetSize + (portVerticalMargin * 2) + (portRowPadding * 2);
  
  final NodePosition nodePosition;
  final String algorithmName;
  final List<AlgorithmPort> inputPorts;
  final List<AlgorithmPort> outputPorts;
  final bool isSelected;
  final Set<String> connectedPorts;
  final bool canMoveUp;
  final bool canMoveDown;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;
  final PositionChangedCallback? onPositionChanged;
  final PortConnectionCallback? onPortConnectionStart;
  final PortConnectionCallback? onPortConnectionEnd;
  final PortPanCallback? onPortPanStart;
  final PortPanUpdateCallback? onPortPanUpdate;
  final PortPanEndCallback? onPortPanEnd;

  const AlgorithmNodeWidget({
    super.key,
    required this.nodePosition,
    required this.algorithmName,
    required this.inputPorts,
    required this.outputPorts,
    this.isSelected = false,
    this.connectedPorts = const {},
    this.canMoveUp = true,
    this.canMoveDown = true,
    this.onMoveUp,
    this.onMoveDown,
    this.onPositionChanged,
    this.onPortConnectionStart,
    this.onPortConnectionEnd,
    this.onPortPanStart,
    this.onPortPanUpdate,
    this.onPortPanEnd,
  });

  @override
  State<AlgorithmNodeWidget> createState() => _AlgorithmNodeWidgetState();
}

class _AlgorithmNodeWidgetState extends State<AlgorithmNodeWidget> {
  bool _isDragging = false;
  bool _shouldHandlePan = true;

  void _onPanStart(DragStartDetails details) {
    // Don't handle pan if it starts on a port area
    // Ports are 16x16 with some margin, check if we're in the port columns
    const portColumnWidth = 40.0; // Approximate width of port column
    
    if (details.localPosition.dx < portColumnWidth || 
        details.localPosition.dx > widget.nodePosition.width - portColumnWidth) {
      _shouldHandlePan = false;
      return;
    }
    
    _shouldHandlePan = true;
    setState(() {
      _isDragging = true;
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!_shouldHandlePan) return;
    
    // Calculate new position and immediately delegate to cubit
    final newPosition = widget.nodePosition.copyWith(
      x: widget.nodePosition.x + details.delta.dx,
      y: widget.nodePosition.y + details.delta.dy,
    );
    widget.onPositionChanged?.call(newPosition);
  }

  void _onPanEnd(DragEndDetails details) {
    _shouldHandlePan = true; // Reset for next gesture
    setState(() {
      _isDragging = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: widget.nodePosition.x,
      top: widget.nodePosition.y,
      child: GestureDetector(
        onPanStart: _onPanStart,
        onPanUpdate: _onPanUpdate,
        onPanEnd: _onPanEnd,
        child: Container(
          width: widget.nodePosition.width,
          height: widget.nodePosition.height,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border.all(
              color: widget.isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.outline,
              width: widget.isSelected ? 2.0 : 1.0,
            ),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: _isDragging ? 0.3 : 0.2),
                blurRadius: _isDragging ? 12 : 8,
                offset: Offset(0, _isDragging ? 6 : 4),
              ),
            ],
          ),
          child: Opacity(
            opacity: _isDragging ? 0.8 : 1.0,
            child: Column(
              children: [
                // Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AlgorithmNodeWidget.horizontalPadding,
                    vertical: AlgorithmNodeWidget.headerVerticalPadding,
                  ),
                  decoration: BoxDecoration(
                    color: widget.isSelected
                        ? Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.1)
                        : Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(8),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${widget.nodePosition.algorithmIndex + 1}. ${widget.algorithmName}',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Move up button
                      SizedBox(
                        width: AlgorithmNodeWidget.headerButtonHeight,
                        height: AlgorithmNodeWidget.headerButtonHeight,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          iconSize: 16,
                          icon: Icon(
                            Icons.arrow_upward,
                            color: widget.canMoveUp
                                ? Theme.of(context).colorScheme.onSurface
                                : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                          ),
                          onPressed: widget.canMoveUp ? widget.onMoveUp : null,
                          tooltip: 'Move algorithm up',
                        ),
                      ),
                      // Move down button
                      SizedBox(
                        width: AlgorithmNodeWidget.headerButtonHeight,
                        height: AlgorithmNodeWidget.headerButtonHeight,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          iconSize: 16,
                          icon: Icon(
                            Icons.arrow_downward,
                            color: widget.canMoveDown
                                ? Theme.of(context).colorScheme.onSurface
                                : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                          ),
                          onPressed: widget.canMoveDown ? widget.onMoveDown : null,
                          tooltip: 'Move algorithm down',
                        ),
                      ),
                    ],
                  ),
                ),

                // Ports area
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AlgorithmNodeWidget.horizontalPadding,
                      vertical: AlgorithmNodeWidget.portsVerticalPadding,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Input ports
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: widget.inputPorts
                                .map(
                                  (port) => _buildPortRow(port, PortType.input),
                                )
                                .toList(),
                          ),
                        ),

                        // Spacer
                        const SizedBox(width: 8),

                        // Output ports
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: widget.outputPorts
                                .map(
                                  (port) =>
                                      _buildPortRow(port, PortType.output),
                                )
                                .toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPortRow(AlgorithmPort port, PortType type) {
    final isConnected = widget.connectedPorts.contains(port.id ?? port.name);
    final portId = port.id ?? port.name;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: type == PortType.input
            ? [
                PortWidget(
                  port: port,
                  type: type,
                  isConnected: isConnected,
                  onConnectionStart: () =>
                      widget.onPortConnectionStart?.call(portId, type),
                  onConnectionEnd: () =>
                      widget.onPortConnectionEnd?.call(portId, type),
                  onPanStart: (details) =>
                      widget.onPortPanStart?.call(portId, type, details),
                  onPanUpdate: (details) =>
                      widget.onPortPanUpdate?.call(portId, type, details),
                  onPanEnd: (details) =>
                      widget.onPortPanEnd?.call(portId, type, details),
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    port.name,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 10,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ]
            : [
                Flexible(
                  child: Text(
                    port.name,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 10,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                  ),
                ),
                const SizedBox(width: 4),
                PortWidget(
                  port: port,
                  type: type,
                  isConnected: isConnected,
                  onConnectionStart: () =>
                      widget.onPortConnectionStart?.call(portId, type),
                  onConnectionEnd: () =>
                      widget.onPortConnectionEnd?.call(portId, type),
                  onPanStart: (details) =>
                      widget.onPortPanStart?.call(portId, type, details),
                  onPanUpdate: (details) =>
                      widget.onPortPanUpdate?.call(portId, type, details),
                  onPanEnd: (details) =>
                      widget.onPortPanEnd?.call(portId, type, details),
                ),
              ],
      ),
    );
  }
}
