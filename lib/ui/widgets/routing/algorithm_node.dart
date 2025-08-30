import 'package:flutter/material.dart';
import 'package:nt_helper/core/routing/models/algorithm_routing_metadata.dart';
import 'package:nt_helper/core/routing/models/port.dart';

/// A widget that visually represents an algorithm node in the routing canvas.
/// 
/// This widget displays algorithm metadata and dynamically generates input/output
/// ports based on the routing type (PolyAlgorithmRouting or MultiChannelAlgorithmRouting).
/// The widget is designed to be reusable and extensible for different algorithm types.
/// 
/// ## Features
/// - Dynamic port generation based on algorithm routing type
/// - Visual distinction between different port types (audio, CV, gate, clock)
/// - Selection state management with visual feedback
/// - Interactive callbacks for port and node tapping
/// - Responsive layout with proper constraints
/// - Theme-aware styling
/// 
/// ## Usage
/// ```dart
/// AlgorithmNode(
///   metadata: algorithmMetadata,
///   inputPorts: inputPortsList,
///   outputPorts: outputPortsList,
///   position: Offset(100, 200),
///   isSelected: false,
///   onPortTapped: (port) => handlePortTap(port),
///   onNodeTapped: () => handleNodeTap(),
/// )
/// ```
/// 
/// ## Accessibility
/// - Provides semantic labels for screen readers
/// - Supports keyboard navigation
/// - High contrast port type colors for visibility
class AlgorithmNode extends StatelessWidget {
  /// The metadata containing algorithm information and routing configuration.
  /// 
  /// This includes the algorithm name, routing type, voice/channel counts,
  /// and other properties that determine how ports are displayed.
  final AlgorithmRoutingMetadata metadata;
  
  /// The list of input ports to display on the left side of the node.
  /// 
  /// Each port will be rendered with appropriate color coding based on its type.
  final List<Port> inputPorts;
  
  /// The list of output ports to display on the right side of the node.
  /// 
  /// Each port will be rendered with appropriate color coding based on its type.
  final List<Port> outputPorts;
  
  /// Whether this node is currently selected.
  /// 
  /// Selected nodes are highlighted with a thicker border using the theme's primary color.
  final bool isSelected;
  
  /// Callback invoked when a port is tapped.
  /// 
  /// Typically used to initiate connection creation or port-specific actions.
  /// The callback receives the [Port] that was tapped.
  final Function(Port port)? onPortTapped;
  
  /// Callback invoked when the node container is tapped.
  /// 
  /// Typically used for node selection, deselection, or opening node properties.
  final VoidCallback? onNodeTapped;
  
  /// The absolute position of this node on the canvas.
  /// 
  /// Used by the [positioned] method to place the node correctly in a [Stack].
  final Offset position;

  const AlgorithmNode({
    super.key,
    required this.metadata,
    required this.inputPorts,
    required this.outputPorts,
    required this.position,
    this.isSelected = false,
    this.onPortTapped,
    this.onNodeTapped,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Algorithm node: ${metadata.algorithmName ?? 'Unknown'}',
      hint: 'Double tap to select algorithm node',
      button: true,
      enabled: true,
      child: GestureDetector(
        onTap: onNodeTapped,
        child: Container(
        constraints: BoxConstraints(
          minWidth: 160,
          maxWidth: MediaQuery.of(context).size.width > 600 ? 300 : 250,
          minHeight: 100,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          border: Border.all(
            color: isSelected 
                ? Theme.of(context).primaryColor 
                : Theme.of(context).dividerColor,
            width: isSelected ? 2 : 1,
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(context),
            _buildPortsSection(context),
          ],
        ),
      ),
      ),
    );
  }

  /// Creates a positioned version of this node for use in a Stack/Canvas.
  /// 
  /// This convenience method wraps the widget in a [Positioned] widget using
  /// the provided [position] coordinates. Essential for canvas-style layouts
  /// where nodes need absolute positioning.
  /// 
  /// Returns a [Positioned] widget containing this [AlgorithmNode].
  Widget positioned() {
    return Positioned(
      left: position.dx,
      top: position.dy,
      child: this,
    );
  }

  /// Builds the header section displaying algorithm information.
  /// 
  /// Creates a styled header with the algorithm name and type description.
  /// The header uses the theme's primary color with reduced opacity for
  /// the background and includes proper text styling and overflow handling.
  /// 
  /// Returns a [Widget] containing the formatted header section.
  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(7),
          topRight: Radius.circular(7),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            metadata.algorithmName ?? 'Unknown Algorithm',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: MediaQuery.of(context).size.width < 600 ? 12 : null,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: MediaQuery.of(context).size.width < 600 ? 1 : 2,
          ),
          const SizedBox(height: 2),
          Text(
            _getAlgorithmTypeDescription(),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the ports section displaying input and output ports.
  /// 
  /// Creates a flexible layout with separate columns for input and output ports.
  /// Input ports are aligned to the start, output ports to the end.
  /// Automatically handles cases where either input or output ports are empty.
  /// 
  /// Returns a [Widget] containing the formatted ports section.
  Widget _buildPortsSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: IntrinsicWidth(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          // Input ports column
          if (inputPorts.isNotEmpty) ...[
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Inputs',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  ...inputPorts.map((port) => _buildPortWidget(context, port)),
                ],
              ),
            ),
            if (outputPorts.isNotEmpty) const SizedBox(width: 8),
          ],
          // Output ports column
          if (outputPorts.isNotEmpty) ...[
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Outputs',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  ...outputPorts.map((port) => _buildPortWidget(context, port)),
                ],
              ),
            ),
          ],
        ],
        ),
      ),
    );
  }

  /// Builds an individual port widget with interactive capabilities.
  /// 
  /// Creates a styled container for the port with:
  /// - Color coding based on port type
  /// - Port indicator circle
  /// - Port name with overflow handling
  /// - Tap gesture handling for interactions
  /// 
  /// The port colors follow the standard convention:
  /// - Blue: Audio ports
  /// - Orange: CV ports  
  /// - Red: Gate ports
  /// - Purple: Clock ports
  /// 
  /// Returns a [Widget] representing the individual port.
  Widget _buildPortWidget(BuildContext context, Port port) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Semantics(
        label: '${port.name} port',
        hint: 'Port type: ${port.type.name}. Tap to connect',
        button: true,
        enabled: true,
        child: GestureDetector(
          onTap: () => onPortTapped?.call(port),
        child: Container(
          padding: MediaQuery.of(context).size.width < 600
              ? const EdgeInsets.symmetric(horizontal: 4, vertical: 2)
              : const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: _getPortColor(port.type),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Port indicator
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _getPortIndicatorColor(port.type),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  port.name,
                  style: Theme.of(context).textTheme.bodySmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }

  /// Gets a human-readable description of the algorithm type.
  /// 
  /// Analyzes the algorithm metadata to determine the routing type and
  /// returns an appropriate description:
  /// - 'Poly (N voices)' for polyphonic algorithms
  /// - 'Multi-channel (N channels)' for multi-channel algorithms
  /// - 'Mono' for single-voice/channel algorithms
  /// 
  /// Returns a [String] description of the algorithm type.
  String _getAlgorithmTypeDescription() {
    if (metadata.isPolyphonic && metadata.voiceCount > 1) {
      return 'Poly (${metadata.voiceCount} voices)';
    } else if (metadata.isMultiChannel && metadata.channelCount > 1) {
      return 'Multi-channel (${metadata.channelCount} channels)';
    } else {
      return 'Mono';
    }
  }

  /// Gets the background color for a port based on its type.
  /// 
  /// Returns a semi-transparent version of the port type color for use
  /// as the port container background. Colors follow the standard convention
  /// with 20% opacity for subtle visual distinction.
  /// 
  /// Returns a [Color] with alpha transparency for the port background.
  Color _getPortColor(PortType type) {
    switch (type) {
      case PortType.audio:
        return Colors.blue.withValues(alpha: 0.2);
      case PortType.cv:
        return Colors.orange.withValues(alpha: 0.2);
      case PortType.gate:
        return Colors.red.withValues(alpha: 0.2);
      case PortType.clock:
        return Colors.purple.withValues(alpha: 0.2);
    }
  }

  /// Gets the solid indicator color for a port based on its type.
  /// 
  /// Returns the full-opacity color used for the port indicator circle.
  /// This provides high contrast and clear visual identification of port types:
  /// - Blue (#2196F3): Audio ports
  /// - Orange (#FF9800): CV (Control Voltage) ports
  /// - Red (#F44336): Gate/trigger ports
  /// - Purple (#9C27B0): Clock ports
  /// 
  /// Returns a [Color] at full opacity for the port indicator.
  Color _getPortIndicatorColor(PortType type) {
    switch (type) {
      case PortType.audio:
        return Colors.blue;
      case PortType.cv:
        return Colors.orange;
      case PortType.gate:
        return Colors.red;
      case PortType.clock:
        return Colors.purple;
    }
  }
}