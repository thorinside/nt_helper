import 'package:flutter/material.dart';
import 'package:nt_helper/core/routing/models/port.dart';
import 'package:nt_helper/ui/widgets/routing/jack_connection_widget.dart';
import 'package:nt_helper/ui/widgets/routing/physical_port_generator.dart';

/// Base widget for displaying physical I/O nodes in the routing canvas.
/// 
/// This widget provides the common structure and styling for both
/// physical input and output nodes, displaying a vertical list of
/// jack connections with appropriate spacing and visual design.
class PhysicalIONodeWidget extends StatelessWidget {
  /// The list of ports to display in this node.
  final List<Port> ports;
  
  /// The title to display in the header.
  final String title;
  
  /// The icon to display in the header.
  final IconData icon;
  
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
  
  /// Whether to use vertical layout (default true).
  final bool isVerticalLayout;
  
  /// The width of the node container.
  final double nodeWidth;
  
  /// The spacing between jack centers.
  final double jackSpacing;
  
  /// Whether to show port labels.
  final bool showLabels;
  
  /// The alignment of labels relative to jacks.
  final LabelAlignment labelAlignment;
  
  const PhysicalIONodeWidget({
    super.key,
    required this.ports,
    required this.title,
    required this.icon,
    this.onPortTapped,
    this.onDragStart,
    this.onDragUpdate,
    this.onDragEnd,
    this.position = Offset.zero,
    this.isVerticalLayout = true,
    this.nodeWidth = 160.0,
    this.jackSpacing = 35.0,
    this.showLabels = true,
    this.labelAlignment = LabelAlignment.right,
  });
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return RepaintBoundary(
      child: SizedBox(
        width: nodeWidth,
        child: Container(
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainer.withValues(alpha: 0.8),
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.3),
              width: 1.0,
            ),
            borderRadius: BorderRadius.circular(8.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 4.0,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IntrinsicHeight(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(context),
                const SizedBox(height: 8.0),
                _buildPortList(context),
                const SizedBox(height: 8.0),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  /// Builds the header section with title and icon.
  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(8.0),
          topRight: Radius.circular(8.0),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16.0,
            color: colorScheme.primary,
          ),
          const SizedBox(width: 8.0),
          Expanded(
            child: Text(
              title,
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
  
  /// Builds the list of port widgets.
  Widget _buildPortList(BuildContext context) {
    if (isVerticalLayout) {
      return SizedBox(
        width: nodeWidth,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: ports.map((port) => _buildPortRow(context, port)).toList(),
        ),
      );
    } else {
      return SizedBox(
        height: 50, // Fixed height for horizontal layout
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: ports.map((port) => _buildPortColumn(context, port)).toList(),
          ),
        ),
      );
    }
  }
  
  /// Builds a single port row (for vertical layout).
  Widget _buildPortRow(BuildContext context, Port port) {
    final isInput = labelAlignment == LabelAlignment.right;
    
    return SizedBox(
      width: nodeWidth,
      height: jackSpacing,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: 
              isInput ? MainAxisAlignment.start : MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (!isInput && showLabels) ...[
              Flexible(child: _buildLabel(context, port)),
              const SizedBox(width: 8.0),
            ],
            _buildJack(context, port),
            if (isInput && showLabels) ...[
              const SizedBox(width: 8.0),
              Flexible(child: _buildLabel(context, port)),
            ],
          ],
        ),
      ),
    );
  }
  
  /// Builds a single port column (for horizontal layout).
  Widget _buildPortColumn(BuildContext context, Port port) {
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: 8.0,
        horizontal: (jackSpacing - 24.0) / 2,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildJack(context, port),
          if (showLabels) ...[
            const SizedBox(height: 4.0),
            _buildLabel(context, port),
          ],
        ],
      ),
    );
  }
  
  /// Builds the jack widget for a port.
  Widget _buildJack(BuildContext context, Port port) {
    return Container(
      width: 120, // Increased width for better text readability
      height: 32, // Increased height for better visual appearance
      alignment: Alignment.center,
      child: GestureDetector(
        key: ValueKey(port.id),
        onTap: () => onPortTapped?.call(port),
        onPanStart: (_) => onDragStart?.call(port),
        onPanUpdate: (details) => onDragUpdate?.call(port, details.globalPosition),
        onPanEnd: (details) => onDragEnd?.call(port, details.velocity.pixelsPerSecond.distance > 0 
            ? details.velocity.pixelsPerSecond 
            : Offset.zero),
        child: JackConnectionWidget(
          port: port,
          isSelected: false, // TODO: Track selection state
          customWidth: 120, // Match the container width
          // Disable haptic/visual overlay for all physical ports (inputs and outputs)
          enableHapticFeedback: !PhysicalPortGenerator.isPhysicalPort(port),
          onTap: () => onPortTapped?.call(port),
        ),
      ),
    );
  }
  
  /// Builds the label for a port.
  Widget _buildLabel(BuildContext context, Port port) {
    final theme = Theme.of(context);
    final label = PhysicalPortGenerator.getPhysicalPortLabel(port);
    
    return Text(
      label,
      style: theme.textTheme.labelSmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
      overflow: TextOverflow.ellipsis,
    );
  }
  
  /// Calculates the optimal spacing based on screen size.
  static double getOptimalSpacing(Size screenSize) {
    // Base spacing: 35px (optimal for touch)
    const double baseSpacing = 35.0;
    
    // Adjust for screen height
    if (screenSize.height < 600) {
      return baseSpacing * 0.8; // 28px for smaller screens
    } else if (screenSize.height > 1000) {
      return baseSpacing * 1.2; // 42px for larger screens
    }
    
    return baseSpacing;
  }
}

/// Enum for label alignment relative to jacks.
enum LabelAlignment {
  left,
  right,
  top,
  bottom,
}
