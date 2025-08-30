import 'package:flutter/material.dart';
import 'package:nt_helper/ui/widgets/routing/routing_canvas.dart';

/// RoutingEditorWidget is the canonical widget for the routing editor UI.
/// It composes the routing canvas and exposes the same API for compatibility.
class RoutingEditorWidget extends StatelessWidget {
  final Object? routingFactory;
  final Size canvasSize;
  final bool showPhysicalPorts;
  final Function(String nodeId)? onNodeSelected;
  final Function(String sourcePortId, String targetPortId)? onConnectionCreated;
  final Function(String connectionId)? onConnectionRemoved;

  const RoutingEditorWidget({
    super.key,
    this.routingFactory,
    this.canvasSize = const Size(1200, 800),
    this.showPhysicalPorts = true,
    this.onNodeSelected,
    this.onConnectionCreated,
    this.onConnectionRemoved,
  });

  @override
  Widget build(BuildContext context) {
    // Delegate to the RoutingCanvas (now pure view) for rendering
    return RoutingCanvas(
      routingFactory: routingFactory,
      canvasSize: canvasSize,
      showPhysicalPorts: showPhysicalPorts,
      onNodeSelected: onNodeSelected,
      onConnectionCreated: onConnectionCreated,
      onConnectionRemoved: onConnectionRemoved,
    );
  }
}

