import 'package:flutter/material.dart';
import 'package:nt_helper/core/routing/models/algorithm_routing_metadata.dart';
import 'package:nt_helper/core/routing/models/port.dart';

/// A widget that visually represents an algorithm node in the routing canvas.
/// 
/// This widget displays algorithm metadata and dynamically generates input/output
/// ports based on the routing type (PolyAlgorithmRouting or MultiChannelAlgorithmRouting).
/// The widget is designed to be reusable and extensible for different algorithm types.
class AlgorithmNode extends StatelessWidget {
  /// The metadata for this algorithm
  final AlgorithmRoutingMetadata metadata;
  
  /// The input ports for this algorithm
  final List<Port> inputPorts;
  
  /// The output ports for this algorithm
  final List<Port> outputPorts;
  
  /// Whether this node is currently selected
  final bool isSelected;
  
  /// Called when a port is tapped (for connection creation)
  final Function(Port port)? onPortTapped;
  
  /// Called when the node itself is tapped
  final VoidCallback? onNodeTapped;
  
  /// The position of this node on the canvas
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
    return GestureDetector(
      onTap: onNodeTapped,
      child: Container(
        constraints: const BoxConstraints(
          minWidth: 160,
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
    );
  }

  /// Creates a positioned version of this node for use in a Stack/Canvas
  Widget positioned() {
    return Positioned(
      left: position.dx,
      top: position.dy,
      child: this,
    );
  }

  /// Builds the header section with algorithm information
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
            ),
            overflow: TextOverflow.ellipsis,
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

  /// Builds the ports section with input and output ports
  Widget _buildPortsSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
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
    );
  }

  /// Builds an individual port widget
  Widget _buildPortWidget(BuildContext context, Port port) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: GestureDetector(
        onTap: () => onPortTapped?.call(port),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
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
    );
  }

  /// Gets a description of the algorithm type based on metadata
  String _getAlgorithmTypeDescription() {
    if (metadata.isPolyphonic && metadata.voiceCount > 1) {
      return 'Poly (${metadata.voiceCount} voices)';
    } else if (metadata.isMultiChannel && metadata.channelCount > 1) {
      return 'Multi-channel (${metadata.channelCount} channels)';
    } else {
      return 'Mono';
    }
  }

  /// Gets the background color for a port based on its type
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

  /// Gets the indicator color for a port based on its type
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