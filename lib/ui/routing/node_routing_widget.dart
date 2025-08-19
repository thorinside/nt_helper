import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nt_helper/cubit/node_routing_cubit.dart';
import 'package:nt_helper/cubit/node_routing_state.dart';
import 'package:nt_helper/ui/routing/routing_canvas.dart';

class NodeRoutingWidget extends StatelessWidget {

  const NodeRoutingWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NodeRoutingCubit, NodeRoutingState>(
      builder: (context, state) {
        return switch (state) {
          NodeRoutingStateInitial() => _buildInitializing(context),
          NodeRoutingStateLoading() => _buildLoading(),
          NodeRoutingStateLoaded() => _buildLoaded(context, state),
          NodeRoutingStateError() => _buildError(context, state),
        };
      },
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

  Widget _buildLoaded(BuildContext context, NodeRoutingStateLoaded state) {
    // Show error snackbar if there's an error message
    if (state.errorMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(state.errorMessage!),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      });
    }

    return RoutingCanvas(
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
