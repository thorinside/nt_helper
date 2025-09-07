import 'package:flutter/material.dart';
import 'package:nt_helper/core/routing/models/port.dart';
import 'package:nt_helper/ui/widgets/routing/port_widget.dart';

/// A movable widget for displaying physical I/O nodes with draggable functionality.
///
/// This widget provides a movable version of physical I/O nodes using the shared
/// PortWidget for consistent visualization across the routing system.
class MovablePhysicalIONode extends StatefulWidget {
  /// The list of ports to display in this node.
  final List<Port> ports;

  /// The title to display in the header.
  final String title;

  /// The icon to display in the header.
  final IconData icon;

  /// The initial position of this node in the canvas.
  final Offset position;

  /// Whether this is a physical input node (affects label positioning).
  /// Physical inputs act as outputs to algorithms (left labels).
  /// Physical outputs act as inputs from algorithms (right labels).
  final bool isInput;

  /// Callback when the node position changes.
  final Function(Offset)? onPositionChanged;

  /// Callback when a port is tapped.
  final Function(Port)? onPortTapped;

  /// Callback when drag starts from a port.
  final Function(Port)? onPortDragStart;

  /// Callback when drag updates with new position.
  final Function(Port, Offset)? onPortDragUpdate;

  /// Callback when drag ends at a position.
  final Function(Port, Offset)? onPortDragEnd;

  /// Callback to report each port's global center for connection anchoring.
  final void Function(Port port, Offset globalCenter)? onPortPositionResolved;

  /// Callback when node drag starts.
  final VoidCallback? onNodeDragStart;

  /// Callback when node drag ends.
  final VoidCallback? onNodeDragEnd;

  /// Set of connected port IDs
  final Set<String>? connectedPorts;

  /// Callback for routing actions from ports
  final void Function(String portId, String action)? onRoutingAction;

  /// ID of the port that should be highlighted (during drag operations)
  final String? highlightedPortId;

  const MovablePhysicalIONode({
    super.key,
    required this.ports,
    required this.title,
    required this.icon,
    required this.position,
    required this.isInput,
    this.onPositionChanged,
    this.onPortTapped,
    this.onPortDragStart,
    this.onPortDragUpdate,
    this.onPortDragEnd,
    this.onPortPositionResolved,
    this.onNodeDragStart,
    this.onNodeDragEnd,
    this.connectedPorts,
    this.onRoutingAction,
    this.highlightedPortId,
  });

  @override
  State<MovablePhysicalIONode> createState() => _MovablePhysicalIONodeState();
}

class _MovablePhysicalIONodeState extends State<MovablePhysicalIONode> {
  bool _isDragging = false;
  Offset _dragStartGlobal = Offset.zero;
  Offset _initialPosition = Offset.zero;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onPanStart: _handleDragStart,
      onPanUpdate: _handleDragUpdate,
      onPanEnd: _handleDragEnd,
      child: AnimatedContainer(
        duration: _isDragging
            ? Duration.zero
            : const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainer.withValues(alpha: 0.95),
          border: Border.all(
            color: colorScheme.outline.withValues(alpha: 0.4),
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(12.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: _isDragging ? 0.3 : 0.1),
              blurRadius: _isDragging ? 8 : 4,
              offset: Offset(0, _isDragging ? 4 : 2),
            ),
          ],
        ),
        child: IntrinsicHeight(
          child: SizedBox(
            width: 180.0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(colorScheme, theme),
                const SizedBox(height: 8.0),
                _buildPortList(),
                const SizedBox(height: 8.0),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the header section with title and icon.
  Widget _buildHeader(ColorScheme colorScheme, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12.0),
          topRight: Radius.circular(12.0),
        ),
      ),
      child: Row(
        children: [
          Icon(widget.icon, size: 16.0, color: colorScheme.primary),
          const SizedBox(width: 8.0),
          Expanded(
            child: Text(
              widget.title,
              style: theme.textTheme.labelMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the list of port widgets using the shared PortWidget.
  Widget _buildPortList() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: widget.ports.map((port) => _buildPortRow(port)).toList(),
      ),
    );
  }

  /// Builds a single port row using PortWidget.
  Widget _buildPortRow(Port port) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: PortWidget(
        label: port.name,
        // Physical inputs act as outputs to algorithms (they send signals TO algorithms)
        // Physical outputs act as inputs from algorithms (they receive signals FROM algorithms)
        isInput: !widget.isInput,
        portId: port.id,
        port: port,
        labelPosition: widget.isInput
            ? PortLabelPosition.left
            : PortLabelPosition.right,
        style: PortStyle.jack,
        isConnected:
            port.isConnected ||
            (widget.connectedPorts?.contains(port.id) ??
                false), // Check both port's connection status and connectedPorts
        isHighlighted: port.id == widget.highlightedPortId,
        onPortPositionResolved: widget.onPortPositionResolved != null
            ? (portId, globalCenter, isInput) {
                widget.onPortPositionResolved!(port, globalCenter);
              }
            : null,
        onTap: () => widget.onPortTapped?.call(port),
        onRoutingAction: widget.onRoutingAction,
        onDragStart: () => widget.onPortDragStart?.call(port),
        onDragUpdate: (position) =>
            widget.onPortDragUpdate?.call(port, position),
        onDragEnd: (position) => widget.onPortDragEnd?.call(port, position),
      ),
    );
  }

  void _handleDragStart(DragStartDetails details) {
    setState(() {
      _isDragging = true;
      _dragStartGlobal = details.globalPosition;
      _initialPosition = widget.position;
    });

    widget.onNodeDragStart?.call();
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    if (!_isDragging) return;

    final dragDelta = details.globalPosition - _dragStartGlobal;
    final newPosition = _initialPosition + dragDelta;

    // Snap to grid
    const double gridSize = 25.0;
    final snappedPosition = Offset(
      (newPosition.dx / gridSize).round() * gridSize,
      (newPosition.dy / gridSize).round() * gridSize,
    );

    // Constrain to canvas bounds
    const double canvasSize = 5000.0;
    final constrainedPosition = Offset(
      snappedPosition.dx.clamp(0.0, canvasSize - 200),
      snappedPosition.dy.clamp(0.0, canvasSize - 300),
    );

    widget.onPositionChanged?.call(constrainedPosition);
  }

  void _handleDragEnd(DragEndDetails details) {
    setState(() {
      _isDragging = false;
    });

    widget.onNodeDragEnd?.call();
  }
}
