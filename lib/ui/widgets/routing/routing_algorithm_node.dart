import 'package:flutter/material.dart';
import 'package:nt_helper/core/routing/models/algorithm_routing_metadata.dart';
import 'package:nt_helper/core/routing/models/port.dart';
import 'package:nt_helper/core/routing/routing_factory.dart';
import 'package:nt_helper/core/routing/algorithm_routing.dart';
import 'package:nt_helper/ui/widgets/routing/algorithm_node.dart';

/// A widget that combines AlgorithmNode with dynamic port generation via RoutingFactory.
/// 
/// This widget creates an AlgorithmRouting instance using the RoutingFactory based on
/// the provided AlgorithmRoutingMetathen uses the generated ports to display
/// the algorithm node with correct input/output ports for the routing type.
/// 
/// This demonstrates the polymorphic behavior where the same widget can display
/// different port layouts for PolyAlgorithmRouting vs MultiChannelAlgorithmRouting.
class RoutingAlgorithmNode extends StatefulWidget {
  /// The metadata for this algorithm
  final AlgorithmRoutingMetadata metadata;
  
  /// The routing factory to use for creating routing instances
  final RoutingFactory routingFactory;
  
  /// Whether this node is currently selected
  final bool isSelected;
  
  /// Called when a port is tapped (for connection creation)
  final Function(Port port)? onPortTapped;
  
  /// Called when the node itself is tapped
  final VoidCallback? onNodeTapped;
  
  /// The position of this node on the canvas
  final Offset position;

  const RoutingAlgorithmNode({
    super.key,
    required this.metadata,
    required this.routingFactory,
    required this.position,
    this.isSelected = false,
    this.onPortTapped,
    this.onNodeTapped,
  });

  /// Creates a positioned version of this node for use in a Stack/Canvas
  Widget positioned() {
    return Positioned(
      left: position.dx,
      top: position.dy,
      child: this,
    );
  }

  @override
  State<RoutingAlgorithmNode> createState() => _RoutingAlgorithmNodeState();
}

class _RoutingAlgorithmNodeState extends State<RoutingAlgorithmNode> {
  AlgorithmRouting? _algorithmRouting;
  List<Port> _inputPorts = [];
  List<Port> _outputPorts = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _createRoutingInstance();
  }

  @override
  void didUpdateWidget(RoutingAlgorithmNode oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Recreate routing instance if metadata changed
    if (oldWidget.metadata != widget.metadata) {
      _createRoutingInstance();
    }
  }

  /// Creates the appropriate routing instance and generates ports
  void _createRoutingInstance() {
    try {
      _errorMessage = null;
      
      // Create routing instance using the factory
      _algorithmRouting = widget.routingFactory.createValidatedRouting(widget.metadata);
      
      // Generate ports from the routing instance
      _inputPorts = _algorithmRouting!.inputPorts;
      _outputPorts = _algorithmRouting!.outputPorts;
      
      debugPrint(
        'RoutingAlgorithmNode: Created ${widget.metadata.routingType} routing '
        'with ${_inputPorts.length} inputs and ${_outputPorts.length} outputs'
      );
      
    } catch (e) {
      _errorMessage = e.toString();
      _inputPorts = [];
      _outputPorts = [];
      
      debugPrint('RoutingAlgorithmNode: Error creating routing instance: $e');
    }
    
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _algorithmRouting?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Show error state if routing creation failed
    if (_errorMessage != null) {
      return _buildErrorNode(context);
    }

    // Build normal algorithm node with generated ports
    return AlgorithmNode(
      metadata: widget.metadata,
      inputPorts: _inputPorts,
      outputPorts: _outputPorts,
      position: widget.position,
      isSelected: widget.isSelected,
      onPortTapped: widget.onPortTapped,
      onNodeTapped: widget.onNodeTapped,
    );
  }

  /// Builds an error node when routing creation fails
  Widget _buildErrorNode(BuildContext context) {
    return GestureDetector(
      onTap: widget.onNodeTapped,
      child: Container(
        constraints: const BoxConstraints(
          minWidth: 160,
          minHeight: 100,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.errorContainer,
          border: Border.all(
            color: Theme.of(context).colorScheme.error,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.error,
                    color: Theme.of(context).colorScheme.error,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      widget.metadata.algorithmName ?? 'Unknown Algorithm',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Routing Error',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 4),
                Text(
                  _errorMessage!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onErrorContainer,
                    fontSize: 10,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Gets the current algorithm routing instance (for external access)
  AlgorithmRouting? get algorithmRouting => _algorithmRouting;

  /// Gets the current input ports
  List<Port> get inputPorts => _inputPorts;

  /// Gets the current output ports
  List<Port> get outputPorts => _outputPorts;
}