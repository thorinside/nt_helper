import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nt_helper/cubit/node_routing_cubit.dart';
import 'package:nt_helper/cubit/node_routing_state.dart';
import 'package:nt_helper/ui/routing/routing_canvas.dart';

class NodeRoutingWidget extends StatefulWidget {

  const NodeRoutingWidget({
    super.key,
  });

  @override
  State<NodeRoutingWidget> createState() => _NodeRoutingWidgetState();
}

class _NodeRoutingWidgetState extends State<NodeRoutingWidget> {
  final ScrollController _horizontalScrollController = ScrollController();
  final ScrollController _verticalScrollController = ScrollController();

  @override
  void dispose() {
    _horizontalScrollController.dispose();
    _verticalScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<NodeRoutingCubit, NodeRoutingState>(
      listener: (context, state) {
        // Show error snackbar and clear error from state
        if (state is NodeRoutingStateLoaded && state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
          
          // Clear the error message to prevent repeated showing
          context.read<NodeRoutingCubit>().clearError();
        }
      },
      child: BlocBuilder<NodeRoutingCubit, NodeRoutingState>(
        builder: (context, state) {
          return switch (state) {
            NodeRoutingStateInitial() => _buildInitializing(context),
            NodeRoutingStateLoading() => _buildLoading(),
            NodeRoutingStateOptimizing() => _buildOptimizing(),
            NodeRoutingStateLoaded() => _buildLoaded(context, state),
            NodeRoutingStateError() => _buildError(context, state),
          };
        },
      ),
    );
  }

  Widget _buildInitializing(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildLoading() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Initializing node layout...'),
        ],
      ),
    );
  }

  Widget _buildOptimizing() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Optimizing bus routing...'),
        ],
      ),
    );
  }

  Widget _buildLoaded(BuildContext context, NodeRoutingStateLoaded state) {
    // Wrap the canvas to allow it to expand beyond the viewport
    return SingleChildScrollView(
      controller: _horizontalScrollController,
      physics: const NeverScrollableScrollPhysics(), // Disable gesture scrolling
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        controller: _verticalScrollController,
        physics: const NeverScrollableScrollPhysics(), // Disable gesture scrolling
        scrollDirection: Axis.vertical,
        child: RoutingCanvas(
      horizontalScrollController: _horizontalScrollController,
      verticalScrollController: _verticalScrollController,
      nodePositions: state.nodePositions,
      algorithmNames: state.algorithmNames,
      portLayouts: state.portLayouts,
      connections: state.connections,
      connectedPorts: state.connectedPorts,
      portPositions: state.portPositions,
      connectionPreview: state.connectionPreview,
      hoveredConnectionId: state.hoveredConnectionId,
      pendingConnections: state.pendingConnections,
      failedConnections: state.failedConnections,
      onNodePositionChanged: (algorithmIndex, position) {
        context.read<NodeRoutingCubit>().updateNodePosition(
          algorithmIndex,
          position,
        );
      },
      onConnectionCreated: (connection) {
        context.read<NodeRoutingCubit>().createConnection(
          sourceAlgorithmIndex: connection.sourceAlgorithmIndex,
          sourcePortId: connection.sourcePortId,
          targetAlgorithmIndex: connection.targetAlgorithmIndex,
          targetPortId: connection.targetPortId,
        );
      },
      onConnectionRemoved: (connection) {
        context.read<NodeRoutingCubit>().removeConnection(connection);
      },
      onSelectionChanged: () {
        // Handle selection changes if needed
      },
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context, NodeRoutingStateError state) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'Error loading node routing:',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            state.message,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              context.read<NodeRoutingCubit>().initialize();
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
