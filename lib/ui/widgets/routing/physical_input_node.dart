import 'package:flutter/material.dart';
import 'package:nt_helper/core/routing/models/port.dart';
import 'package:nt_helper/ui/widgets/routing/physical_io_node_widget.dart';
import 'package:nt_helper/ui/widgets/routing/physical_port_generator.dart';

/// Widget representing the physical input node with 12 hardware input jacks.
/// 
/// This node displays the 12 physical inputs of the Disting NT module,
/// positioned on the left side of the routing canvas. These inputs act
/// as sources for connections to algorithm inputs.
class PhysicalInputNode extends StatelessWidget {
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
  
  /// Custom jack spacing (defaults to optimal spacing).
  final double? jackSpacing;
  
  /// Whether to show port labels.
  final bool showLabels;
  
  /// Callback to report each jack's global center for connection anchoring
  final void Function(Port port, Offset globalCenter)? onPortPositionResolved;
  
  const PhysicalInputNode({
    super.key,
    this.onPortTapped,
    this.onDragStart,
    this.onDragUpdate,
    this.onDragEnd,
    this.position = Offset.zero,
    this.jackSpacing,
    this.showLabels = true,
    this.onPortPositionResolved,
  });
  
  @override
  Widget build(BuildContext context) {
    final ports = PhysicalPortGenerator.generatePhysicalInputPorts();
    final screenSize = MediaQuery.of(context).size;
    final spacing = jackSpacing ?? (
      screenSize.height < 600 ? 28.0 : (screenSize.height > 1000 ? 42.0 : 35.0)
    );
    
    return Semantics(
      label: 'Physical Inputs',
      hint: 'Hardware input jacks. Drag from any jack to connect to algorithm inputs.',
      child: PhysicalIONodeWidget(
        ports: ports,
        title: 'Physical Inputs',
        icon: Icons.input_rounded,
        onPortTapped: onPortTapped,
        onDragStart: onDragStart,
        onDragUpdate: onDragUpdate,
        onDragEnd: onDragEnd,
        position: position,
        isVerticalLayout: true,
        nodeWidth: 160.0, // Wider to accommodate larger jacks and labels
        jackSpacing: spacing,
        showLabels: showLabels,
        labelAlignment: LabelAlignment.right, // Labels on right for inputs
        onPortPositionResolved: onPortPositionResolved,
      ),
    );
  }
}
