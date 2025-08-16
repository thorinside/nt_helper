import 'package:flutter/material.dart';
import 'package:nt_helper/models/algorithm_port.dart';
import 'package:nt_helper/models/node_position.dart';
import 'package:nt_helper/ui/widgets/port_widget.dart';

typedef PositionChangedCallback = void Function(NodePosition position);
typedef PortConnectionCallback = void Function(String portId, PortType type);

class AlgorithmNodeWidget extends StatefulWidget {
  final NodePosition nodePosition;
  final String algorithmName;
  final List<AlgorithmPort> inputPorts;
  final List<AlgorithmPort> outputPorts;
  final bool isSelected;
  final Set<String> connectedPorts;
  final PositionChangedCallback? onPositionChanged;
  final PortConnectionCallback? onPortConnectionStart;
  final PortConnectionCallback? onPortConnectionEnd;

  const AlgorithmNodeWidget({
    super.key,
    required this.nodePosition,
    required this.algorithmName,
    required this.inputPorts,
    required this.outputPorts,
    this.isSelected = false,
    this.connectedPorts = const {},
    this.onPositionChanged,
    this.onPortConnectionStart,
    this.onPortConnectionEnd,
  });

  @override
  State<AlgorithmNodeWidget> createState() => _AlgorithmNodeWidgetState();
}

class _AlgorithmNodeWidgetState extends State<AlgorithmNodeWidget> {
  bool _isDragging = false;
  late NodePosition _currentPosition;

  @override
  void initState() {
    super.initState();
    _currentPosition = widget.nodePosition;
  }

  @override
  void didUpdateWidget(AlgorithmNodeWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.nodePosition != widget.nodePosition) {
      _currentPosition = widget.nodePosition;
    }
  }

  void _onPanStart(DragStartDetails details) {
    setState(() {
      _isDragging = true;
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _currentPosition = _currentPosition.copyWith(
        x: _currentPosition.x + details.delta.dx,
        y: _currentPosition.y + details.delta.dy,
      );
    });
    widget.onPositionChanged?.call(_currentPosition);
  }

  void _onPanEnd(DragEndDetails details) {
    setState(() {
      _isDragging = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: _currentPosition.x,
      top: _currentPosition.y,
      child: GestureDetector(
        onPanStart: _onPanStart,
        onPanUpdate: _onPanUpdate,
        onPanEnd: _onPanEnd,
        child: Container(
          width: _currentPosition.width,
          height: _currentPosition.height,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border.all(
              color: widget.isSelected 
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.outline,
              width: widget.isSelected ? 2.0 : 1.0,
            ),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: _isDragging ? 0.3 : 0.2
                ),
                blurRadius: _isDragging ? 12 : 8,
                offset: Offset(0, _isDragging ? 6 : 4),
              ),
            ],
          ),
          child: Opacity(
            opacity: _isDragging ? 0.8 : 1.0,
            child: Column(
              children: [
                // Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: widget.isSelected 
                        ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
                        : Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                  ),
                  child: Text(
                    '${widget.nodePosition.algorithmIndex + 1}. ${widget.algorithmName}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                // Ports area
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Input ports
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: widget.inputPorts.map((port) => 
                              _buildPortRow(port, PortType.input)
                            ).toList(),
                          ),
                        ),

                        // Spacer
                        const SizedBox(width: 8),

                        // Output ports  
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: widget.outputPorts.map((port) => 
                              _buildPortRow(port, PortType.output)
                            ).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPortRow(AlgorithmPort port, PortType type) {
    final isConnected = widget.connectedPorts.contains(port.id);
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: type == PortType.input 
            ? [
                PortWidget(
                  port: port,
                  type: type,
                  isConnected: isConnected,
                  onConnectionStart: () => widget.onPortConnectionStart?.call(port.id!, type),
                  onConnectionEnd: () => widget.onPortConnectionEnd?.call(port.id!, type),
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    port.name,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 10,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ]
            : [
                Flexible(
                  child: Text(
                    port.name,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 10,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                  ),
                ),
                const SizedBox(width: 4),
                PortWidget(
                  port: port,
                  type: type,
                  isConnected: isConnected,
                  onConnectionStart: () => widget.onPortConnectionStart?.call(port.id!, type),
                  onConnectionEnd: () => widget.onPortConnectionEnd?.call(port.id!, type),
                ),
              ],
      ),
    );
  }
}