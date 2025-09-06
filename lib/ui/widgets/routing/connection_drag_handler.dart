import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nt_helper/cubit/routing_editor_cubit.dart';
import 'package:nt_helper/cubit/routing_editor_state.dart';
import 'package:nt_helper/services/interactive_connection_manager.dart';

/// Widget that handles drag gestures for connection creation
class ConnectionDragHandler extends StatefulWidget {
  final Widget child;
  final InteractiveConnectionManager connectionManager;

  const ConnectionDragHandler({
    super.key,
    required this.child,
    required this.connectionManager,
  });

  @override
  State<ConnectionDragHandler> createState() => _ConnectionDragHandlerState();
}

class _ConnectionDragHandlerState extends State<ConnectionDragHandler> {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RoutingEditorCubit, RoutingEditorState>(
      builder: (context, state) {
        if (state is! RoutingEditorStateLoaded) {
          return widget.child;
        }

        return GestureDetector(
          onPanStart: (details) => _handlePanStart(context, details, state),
          onPanUpdate: (details) => _handlePanUpdate(context, details, state),
          onPanEnd: (details) => _handlePanEnd(context, details, state),
          onPanCancel: () => _handlePanCancel(context, state),
          child: Stack(
            children: [
              widget.child,
              if (widget.connectionManager.isDragging)
                CustomPaint(
                  painter: ConnectionDragPainter(
                    dragConnection: widget.connectionManager.currentDrag!,
                  ),
                  size: Size.infinite,
                ),
            ],
          ),
        );
      },
    );
  }

  void _handlePanStart(
    BuildContext context,
    DragStartDetails details,
    RoutingEditorStateLoaded state,
  ) {
    final position = details.localPosition;
    final port = _findPortAtPosition(position, state);

    if (port != null) {
      widget.connectionManager.startDrag(
        sourcePort: port,
        position: position,
      );
      setState(() {});
    }
  }

  void _handlePanUpdate(
    BuildContext context,
    DragUpdateDetails details,
    RoutingEditorStateLoaded state,
  ) {
    if (!widget.connectionManager.isDragging) return;

    final availablePorts = widget.connectionManager.getAllPorts(state);
    widget.connectionManager.updateDrag(
      position: details.localPosition,
      availablePorts: availablePorts,
    );
    setState(() {});
  }

  void _handlePanEnd(
    BuildContext context,
    DragEndDetails details,
    RoutingEditorStateLoaded state,
  ) {
    if (!widget.connectionManager.isDragging) return;

    final connectionData = widget.connectionManager.completeDrag();
    if (connectionData != null) {
      // Create connection through cubit
      context.read<RoutingEditorCubit>().createConnectionOptimistic(
            sourcePortId: connectionData['sourcePortId'] as String,
            targetPortId: connectionData['targetPortId'] as String,
            outputMode: connectionData['outputMode'],
            gain: connectionData['gain'] as double,
          );
    }
    setState(() {});
  }

  void _handlePanCancel(
    BuildContext context,
    RoutingEditorStateLoaded state,
  ) {
    if (widget.connectionManager.isDragging) {
      widget.connectionManager.cancelDrag();
      setState(() {});
    }
  }

  Port? _findPortAtPosition(Offset position, RoutingEditorStateLoaded state) {
    // This would need to be implemented based on how ports are positioned
    // in the routing canvas. For now, returning null as a placeholder.
    // The actual implementation would need coordinate mapping from the canvas.
    return null;
  }
}

/// Custom painter for rendering drag connection preview
class ConnectionDragPainter extends CustomPainter {
  final DragConnection dragConnection;

  ConnectionDragPainter({required this.dragConnection});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    // Set color based on drag state
    switch (dragConnection.state) {
      case DragState.dragging:
        paint.color = Colors.blue.withValues(alpha: 0.7);
        break;
      case DragState.validTarget:
        paint.color = Colors.green.withValues(alpha: 0.8);
        break;
      case DragState.invalidTarget:
        paint.color = Colors.red.withValues(alpha: 0.8);
        break;
      case DragState.idle:
        return; // Don't draw anything
    }

    // Draw line from start to current position
    canvas.drawLine(
      dragConnection.startPosition,
      dragConnection.currentPosition,
      paint,
    );

    // Draw drag end indicator
    final endIndicator = Paint()
      ..color = paint.color
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      dragConnection.currentPosition,
      4.0,
      endIndicator,
    );
  }

  @override
  bool shouldRepaint(ConnectionDragPainter oldDelegate) {
    return oldDelegate.dragConnection != dragConnection;
  }
}