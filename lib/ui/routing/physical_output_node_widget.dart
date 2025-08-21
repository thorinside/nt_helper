import 'package:flutter/material.dart';
import 'package:nt_helper/models/algorithm_port.dart';
import 'package:nt_helper/models/node_position.dart';
import 'package:nt_helper/ui/widgets/port_widget.dart';

typedef PortConnectionCallback = void Function(String portId, PortType type);
typedef PortPanCallback = void Function(String portId, PortType type, DragStartDetails details);
typedef PortPanUpdateCallback = void Function(String portId, PortType type, DragUpdateDetails details);
typedef PortPanEndCallback = void Function(String portId, PortType type, DragEndDetails details);
typedef NodePositionCallback = void Function(NodePosition position);

class PhysicalOutputNodeWidget extends StatefulWidget {
  // Layout constants - narrower than algorithm nodes  
  static const double nodeWidth = 80.0;
  static const double headerHeight = 28.0;
  static const double portRowHeight = 20.0;
  static const double verticalPadding = 4.0;
  static const double portWidgetSize = 16.0;
  static const int jackCount = 8;
  static const int algorithmIndex = -3; // Special index for physical outputs
  
  // Calculate exact content height with bottom padding
  static const double bottomPadding = 12.0;
  static const double headerPadding = 6.0; // vertical padding inside header
  static const double totalHeight = headerHeight + (headerPadding * 2) + (jackCount * portRowHeight) + (verticalPadding * 2) + bottomPadding;

  final NodePosition nodePosition;
  final Set<String> connectedPorts;
  final PortConnectionCallback? onPortConnectionStart;
  final PortConnectionCallback? onPortConnectionEnd;
  final PortPanCallback? onPortPanStart;
  final PortPanUpdateCallback? onPortPanUpdate;
  final PortPanEndCallback? onPortPanEnd;
  final NodePositionCallback? onPositionChanged;

  const PhysicalOutputNodeWidget({
    super.key,
    required this.nodePosition,
    this.connectedPorts = const {},
    this.onPortConnectionStart,
    this.onPortConnectionEnd,
    this.onPortPanStart,
    this.onPortPanUpdate,
    this.onPortPanEnd,
    this.onPositionChanged,
  });

  @override
  State<PhysicalOutputNodeWidget> createState() => _PhysicalOutputNodeWidgetState();
}

class _PhysicalOutputNodeWidgetState extends State<PhysicalOutputNodeWidget> {
  Offset? _dragStartGlobalPosition;
  NodePosition? _dragStartNodePosition;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: _handlePanStart,
      onPanUpdate: _handlePanUpdate,
      onPanEnd: _handlePanEnd,
      child: Container(
        width: PhysicalOutputNodeWidget.nodeWidth,
        height: PhysicalOutputNodeWidget.totalHeight,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border.all(
            color: Theme.of(context).colorScheme.outline,
            width: 1.0,
          ),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
      child: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            height: PhysicalOutputNodeWidget.headerHeight,
            padding: const EdgeInsets.symmetric(
              horizontal: 4.0,
              vertical: PhysicalOutputNodeWidget.headerPadding,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(8),
              ),
            ),
            child: Center(
              child: Text(
                'OUTPUTS',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                  fontSize: 9,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),

          // Jacks area - exact sizing to prevent overflow
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 4.0,
              vertical: PhysicalOutputNodeWidget.verticalPadding,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                PhysicalOutputNodeWidget.jackCount,
                (index) => _buildJackRow(context, index + 1),
              ),
            ),
          ),

          // Bottom padding
          const SizedBox(height: PhysicalOutputNodeWidget.bottomPadding),
        ],
      ),
    ),
    );
  }

  void _handlePanStart(DragStartDetails details) {
    // Store initial positions for accurate tracking
    _dragStartGlobalPosition = details.globalPosition;
    _dragStartNodePosition = widget.nodePosition;
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    if (_dragStartGlobalPosition == null || _dragStartNodePosition == null) return;
    
    // Calculate new position based on global coordinates for accurate tracking
    final globalDelta = details.globalPosition - _dragStartGlobalPosition!;
    final newPosition = NodePosition(
      x: _dragStartNodePosition!.x + globalDelta.dx,
      y: _dragStartNodePosition!.y + globalDelta.dy,
      width: widget.nodePosition.width,
      height: widget.nodePosition.height,
      algorithmIndex: widget.nodePosition.algorithmIndex,
    );
    widget.onPositionChanged?.call(newPosition);
  }

  void _handlePanEnd(DragEndDetails details) {
    // Clear stored positions
    _dragStartGlobalPosition = null;
    _dragStartNodePosition = null;
  }

  Widget _buildJackRow(BuildContext context, int jackNumber) {
    final portId = 'physical_output_$jackNumber';
    final isConnected = widget.connectedPorts.contains('${PhysicalOutputNodeWidget.algorithmIndex}_$portId');
    
    final port = AlgorithmPort(
      id: portId,
      name: 'O$jackNumber',
    );

    return SizedBox(
      height: PhysicalOutputNodeWidget.portRowHeight,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 0),
      child: Row(
        children: [
          // Left label
          Expanded(
            child: Text(
              'O$jackNumber',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 9,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
          // Centered port widget (bidirectional - always acts as output for dragging)
          PortWidget(
            port: port,
            type: PortType.output, // Allow dragging FROM this port
            isConnected: isConnected,
            onConnectionStart: () => widget.onPortConnectionStart?.call(portId, PortType.output),
            onConnectionEnd: () => widget.onPortConnectionEnd?.call(portId, PortType.input),
            onPanStart: (details) => widget.onPortPanStart?.call(portId, PortType.output, details),
            onPanUpdate: (details) => widget.onPortPanUpdate?.call(portId, PortType.output, details),
            onPanEnd: (details) => widget.onPortPanEnd?.call(portId, PortType.output, details),
          ),
          // Right spacer (same as left for centering)
          const Expanded(child: SizedBox()),
        ],
        ),
      ),
    );
  }
}