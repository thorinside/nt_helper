import 'package:flutter/material.dart';
import 'package:nt_helper/models/algorithm_port.dart';
import 'package:nt_helper/ui/widgets/port_widget.dart';

typedef PortConnectionCallback = void Function(String portId, PortType type);
typedef PortPanCallback = void Function(String portId, PortType type, DragStartDetails details);
typedef PortPanUpdateCallback = void Function(String portId, PortType type, DragUpdateDetails details);
typedef PortPanEndCallback = void Function(String portId, PortType type, DragEndDetails details);

class PhysicalInputNodeWidget extends StatelessWidget {
  // Layout constants - narrower than algorithm nodes
  static const double nodeWidth = 80.0;
  static const double headerHeight = 28.0;
  static const double portRowHeight = 20.0;
  static const double verticalPadding = 4.0;
  static const double portWidgetSize = 16.0;
  static const int jackCount = 12;
  static const int algorithmIndex = -2; // Special index for physical inputs
  
  // Calculate exact content height with bottom padding
  static const double bottomPadding = 12.0;
  static const double headerPadding = 6.0; // vertical padding inside header
  static const double totalHeight = headerHeight + (headerPadding * 2) + (jackCount * portRowHeight) + (verticalPadding * 2) + bottomPadding;

  final Set<String> connectedPorts;
  final PortConnectionCallback? onPortConnectionStart;
  final PortConnectionCallback? onPortConnectionEnd;
  final PortPanCallback? onPortPanStart;
  final PortPanUpdateCallback? onPortPanUpdate;
  final PortPanEndCallback? onPortPanEnd;

  const PhysicalInputNodeWidget({
    super.key,
    this.connectedPorts = const {},
    this.onPortConnectionStart,
    this.onPortConnectionEnd,
    this.onPortPanStart,
    this.onPortPanUpdate,
    this.onPortPanEnd,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: nodeWidth,
      height: totalHeight,
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
            height: headerHeight,
            padding: const EdgeInsets.symmetric(
              horizontal: 4.0,
              vertical: headerPadding,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(8),
              ),
            ),
            child: Center(
              child: Text(
                'INPUTS',
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
              vertical: verticalPadding,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                jackCount,
                (index) => _buildJackRow(context, index + 1),
              ),
            ),
          ),

          // Bottom padding
          const SizedBox(height: bottomPadding),
        ],
      ),
    );
  }

  Widget _buildJackRow(BuildContext context, int jackNumber) {
    final portId = 'physical_input_$jackNumber';
    final isConnected = connectedPorts.contains('${algorithmIndex}_$portId');
    
    final port = AlgorithmPort(
      id: portId,
      name: 'I$jackNumber',
    );

    return SizedBox(
      height: portRowHeight,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 0),
      child: Row(
        children: [
          // Left label
          Expanded(
            child: Text(
              'I$jackNumber',
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
            onConnectionStart: () => onPortConnectionStart?.call(portId, PortType.output),
            onConnectionEnd: () => onPortConnectionEnd?.call(portId, PortType.input),
            onPanStart: (details) => onPortPanStart?.call(portId, PortType.output, details),
            onPanUpdate: (details) => onPortPanUpdate?.call(portId, PortType.output, details),
            onPanEnd: (details) => onPortPanEnd?.call(portId, PortType.output, details),
          ),
          // Right spacer (same as left for centering)
          const Expanded(child: SizedBox()),
        ],
        ),
      ),
    );
  }
}