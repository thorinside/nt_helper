import 'package:flutter/material.dart';
import 'package:nt_helper/core/routing/models/port.dart';
import 'package:nt_helper/ui/widgets/routing/movable_physical_io_node.dart';

/// Widget representing the physical input node with 12 hardware input jacks.
///
/// This node displays the 12 physical inputs of the Disting NT module.
/// From the algorithm perspective, these physical inputs act as outputs
/// (they output signals to algorithms), so they use left label positioning.
class PhysicalInputNode extends StatelessWidget {
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

  const PhysicalInputNode({
    super.key,
    required this.ports,
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
    this.connectedPorts,
    this.highlightedPortId,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Inputs',
      hint: 'Hardware input jacks. These act as outputs to algorithms.',
      child: MovablePhysicalIONode(
        ports: ports,
        connectedPorts: connectedPorts,
        title: 'Inputs',
        icon: Icons.input_rounded,
        position: position,
        isInput: true,
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
