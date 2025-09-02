import 'package:flutter/material.dart';
import 'package:nt_helper/core/routing/models/port.dart';
import 'package:nt_helper/ui/widgets/routing/physical_io_node_widget.dart';
import 'package:nt_helper/ui/widgets/routing/physical_port_generator.dart';

/// Widget representing the physical output node with 8 hardware output jacks.
/// 
/// This node displays the 8 physical outputs of the Disting NT module,
/// positioned on the right side of the routing canvas. These outputs act
/// as targets for connections from algorithm outputs.
class PhysicalOutputNode extends StatelessWidget {
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
  
  const PhysicalOutputNode({
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
    final ports = PhysicalPortGenerator.generatePhysicalOutputPorts();
    final screenSize = MediaQuery.of(context).size;
    final spacing = jackSpacing ?? (
      screenSize.height < 600 ? 28.0 : (screenSize.height > 1000 ? 42.0 : 35.0)
    );
    
    return Semantics(
      label: 'Physical Outputs',
      hint: 'Hardware output jacks. Drop connections from algorithm outputs here.',
      child: PhysicalIONodeWidget(
        ports: ports,
        title: 'Physical Outputs',
        icon: Icons.output_rounded,
        onPortTapped: onPortTapped,
        onDragStart: onDragStart,
        onDragUpdate: onDragUpdate,
        onDragEnd: onDragEnd,
        position: position,
        isVerticalLayout: true,
        nodeWidth: 160.0, // Wider to accommodate larger jacks and labels
        jackSpacing: spacing,
        showLabels: showLabels,
        labelAlignment: LabelAlignment.left, // Labels on left for outputs
        onPortPositionResolved: onPortPositionResolved,
      ),
    );
  }
}
