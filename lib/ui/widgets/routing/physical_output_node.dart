import 'package:flutter/material.dart';
import 'package:nt_helper/core/routing/models/port.dart';
import 'package:nt_helper/ui/widgets/routing/movable_physical_io_node.dart';

/// Widget representing the physical output node with 8 hardware output jacks.
///
/// This node displays the 8 physical outputs of the Disting NT module.
/// From the algorithm perspective, these physical outputs act as inputs
/// (they receive signals from algorithms), so they use right label positioning.
class PhysicalOutputNode extends StatelessWidget {
  /// The list of ports from the routing state to display in this node.
  final List<Port> ports;
  /// Callback when a port is tapped.
  final Function(Port)? onPortTapped;

  /// Callback when drag starts from a port.
  final Function(Port)? onDragStart;

  /// Callback when drag updates with new position.
  final Function(Port, Offset)? onDragUpdate;

  /// Callback when drag ends at a position.
  final Function(Port, Offset)? onDragEnd;

  /// The position of this node in the canvas.
  final Offset position;

  /// Callback when the node position changes due to dragging.
  final Function(Offset)? onPositionChanged;

  /// Custom jack spacing (defaults to optimal spacing).
  final double? jackSpacing;

  /// Whether to show port labels.
  final bool showLabels;

  /// Callback to report each jack's global center for connection anchoring
  final void Function(Port port, Offset globalCenter)? onPortPositionResolved;

  /// Callback when node drag starts.
  final VoidCallback? onNodeDragStart;

  /// Callback when node drag ends.
  final VoidCallback? onNodeDragEnd;

  /// Callback for routing actions from ports
  final void Function(String portId, String action)? onRoutingAction;

  /// Set of connected port IDs
  final Set<String>? connectedPorts;

  /// ID of the port that should be highlighted (during drag operations)
  final String? highlightedPortId;

  const PhysicalOutputNode({
    super.key,
    required this.ports,
    this.connectedPorts,
    this.onPortTapped,
    this.onDragStart,
    this.onDragUpdate,
    this.onDragEnd,
    this.position = Offset.zero,
    this.onPositionChanged,
    this.jackSpacing,
    this.showLabels = true,
    this.onPortPositionResolved,
    this.onNodeDragStart,
    this.onNodeDragEnd,
    this.onRoutingAction,
    this.highlightedPortId,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Outputs',
      hint: 'Hardware output jacks. These act as inputs from algorithms.',
      child: MovablePhysicalIONode(
        ports: ports,
        connectedPorts: connectedPorts,
        title: 'Outputs',
        icon: Icons.output_rounded,
        position: position,
        isInput: false,
        onPositionChanged: onPositionChanged,
        onPortTapped: onPortTapped,
        onPortDragStart: onDragStart,
        onPortDragUpdate: onDragUpdate,
        onPortDragEnd: onDragEnd,
        onPortPositionResolved: onPortPositionResolved,
        onNodeDragStart: onNodeDragStart,
        onNodeDragEnd: onNodeDragEnd,
        onRoutingAction: onRoutingAction,
        highlightedPortId: highlightedPortId,
      ),
    );
  }
}
