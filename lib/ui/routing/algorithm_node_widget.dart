import 'package:flutter/material.dart';
import 'package:nt_helper/models/algorithm_port.dart';
import 'package:nt_helper/models/node_position.dart';
import 'package:nt_helper/ui/widgets/port_widget.dart';
import 'package:nt_helper/domain/disting_nt_sysex.dart';
import 'package:nt_helper/models/packed_mapping_data.dart';

typedef PositionChangedCallback = void Function(NodePosition position);
typedef PortConnectionCallback = void Function(String portId, PortType type);
typedef PortPanCallback = void Function(String portId, PortType type, DragStartDetails details);
typedef PortPanUpdateCallback = void Function(String portId, PortType type, DragUpdateDetails details);
typedef PortPanEndCallback = void Function(String portId, PortType type, DragEndDetails details);

class AlgorithmNodeWidget extends StatefulWidget {
  // Layout constants
  static const double headerVerticalPadding = 6.0;
  static const double headerButtonHeight = 24.0;
  static const double headerHeight = headerVerticalPadding * 2 + headerButtonHeight;
  static const double horizontalPadding = 8.0;
  static const double portsVerticalPadding = 4.0;
  static const double portWidgetSize = 24.0;
  static const double portVerticalMargin = 4.0;
  static const double portRowPadding = 1.0;
  static const double portRowHeight = portWidgetSize + (portVerticalMargin * 2) + (portRowPadding * 2);
  
  final NodePosition nodePosition;
  final String algorithmName;
  final List<AlgorithmPort> inputPorts;
  final List<AlgorithmPort> outputPorts;
  final bool isSelected;
  final Set<String> connectedPorts;
  final bool canMoveUp;
  final bool canMoveDown;
  final List<dynamic> mappings; // List of Mapping objects
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;
  final VoidCallback? onDelete;
  final PositionChangedCallback? onPositionChanged;
  final PortConnectionCallback? onPortConnectionStart;
  final PortConnectionCallback? onPortConnectionEnd;
  final PortPanCallback? onPortPanStart;
  final PortPanUpdateCallback? onPortPanUpdate;
  final PortPanEndCallback? onPortPanEnd;

  const AlgorithmNodeWidget({
    super.key,
    required this.nodePosition,
    required this.algorithmName,
    required this.inputPorts,
    required this.outputPorts,
    this.isSelected = false,
    this.connectedPorts = const {},
    this.canMoveUp = true,
    this.canMoveDown = true,
    this.mappings = const [],
    this.onMoveUp,
    this.onMoveDown,
    this.onDelete,
    this.onPositionChanged,
    this.onPortConnectionStart,
    this.onPortConnectionEnd,
    this.onPortPanStart,
    this.onPortPanUpdate,
    this.onPortPanEnd,
  });

  @override
  State<AlgorithmNodeWidget> createState() => _AlgorithmNodeWidgetState();
}

class _AlgorithmNodeWidgetState extends State<AlgorithmNodeWidget> {
  bool _isDragging = false;
  bool _shouldHandlePan = true;
  Offset? _dragStartGlobalPosition;
  NodePosition? _dragStartNodePosition;

  void _onPanStart(DragStartDetails details) {
    final dx = details.localPosition.dx;
    final dy = details.localPosition.dy;

    // Exclude header arrow buttons (allow clicks/drags on them without moving node)
    // Header is at the top with height = headerHeight. Two buttons on right.
    const headerHeight = AlgorithmNodeWidget.headerHeight;
    const headerButtonWidth = AlgorithmNodeWidget.headerButtonHeight; // Square buttons
    const horizontalPadding = AlgorithmNodeWidget.horizontalPadding;

    // If we're within header area, only block pan when starting on the buttons area
    if (dy <= headerHeight) {
      final rightButtonsStartX = widget.nodePosition.width - horizontalPadding - (2 * headerButtonWidth);
      final rightEdgeX = widget.nodePosition.width;
      final onHeaderButtons = dx >= rightButtonsStartX && dx <= rightEdgeX;
      _shouldHandlePan = !onHeaderButtons;
    } else {
      // In ports/body area, block pan only when starting directly over port widgets
      // Ports are 24x24 circles flush to left/right with small padding.
      const portSize = AlgorithmNodeWidget.portWidgetSize;
      const portHitSlop = 6.0; // a little extra to match visual
      const leftPortCenterX = horizontalPadding + (portSize / 2);
      final rightPortCenterX = widget.nodePosition.width - horizontalPadding - (portSize / 2);

      final onLeftPortColumn = (dx - leftPortCenterX).abs() <= (portSize / 2 + portHitSlop);
      final onRightPortColumn = (dx - rightPortCenterX).abs() <= (portSize / 2 + portHitSlop);
      _shouldHandlePan = !(onLeftPortColumn || onRightPortColumn);
    }

    if (_shouldHandlePan) {
      setState(() {
        _isDragging = true;
        _dragStartGlobalPosition = details.globalPosition;
        _dragStartNodePosition = widget.nodePosition;
      });
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!_shouldHandlePan || _dragStartGlobalPosition == null || _dragStartNodePosition == null) return;
    
    // Calculate new position based on global coordinates for accurate tracking
    final globalDelta = details.globalPosition - _dragStartGlobalPosition!;
    final newPosition = _dragStartNodePosition!.copyWith(
      x: _dragStartNodePosition!.x + globalDelta.dx,
      y: _dragStartNodePosition!.y + globalDelta.dy,
    );
    widget.onPositionChanged?.call(newPosition);
  }

  void _onPanEnd(DragEndDetails details) {
    _shouldHandlePan = true; // Reset for next gesture
    setState(() {
      _isDragging = false;
      _dragStartGlobalPosition = null;
      _dragStartNodePosition = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: widget.nodePosition.x,
      top: widget.nodePosition.y,
      child: GestureDetector(
        onPanStart: _onPanStart,
        onPanUpdate: _onPanUpdate,
        onPanEnd: _onPanEnd,
        child: Container(
          width: widget.nodePosition.width,
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
                color: Colors.black.withValues(alpha: _isDragging ? 0.3 : 0.2),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: AlgorithmNodeWidget.horizontalPadding,
                    vertical: AlgorithmNodeWidget.headerVerticalPadding,
                  ),
                  decoration: BoxDecoration(
                    color: widget.isSelected
                        ? Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.1)
                        : Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(8),
                    ),
                  ),
                  child: Row(
                    children: [
                      // Mapping indicator icon
                      if (_hasMappedParameters())
                        Padding(
                          padding: const EdgeInsets.only(right: 4.0),
                          child: Icon(
                            Icons.map_sharp,
                            size: 12,
                            color: Colors.green,
                          ),
                        ),
                      Expanded(
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
                      // Move up button
                      SizedBox(
                        width: AlgorithmNodeWidget.headerButtonHeight,
                        height: AlgorithmNodeWidget.headerButtonHeight,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          iconSize: 16,
                          icon: Icon(
                            Icons.arrow_upward,
                            color: widget.canMoveUp
                                ? Theme.of(context).colorScheme.onSurface
                                : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                          ),
                          onPressed: widget.canMoveUp ? widget.onMoveUp : null,
                          tooltip: 'Move algorithm up',
                        ),
                      ),
                      // Move down button
                      SizedBox(
                        width: AlgorithmNodeWidget.headerButtonHeight,
                        height: AlgorithmNodeWidget.headerButtonHeight,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          iconSize: 16,
                          icon: Icon(
                            Icons.arrow_downward,
                            color: widget.canMoveDown
                                ? Theme.of(context).colorScheme.onSurface
                                : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                          ),
                          onPressed: widget.canMoveDown ? widget.onMoveDown : null,
                          tooltip: 'Move algorithm down',
                        ),
                      ),
                      // Overflow menu
                      if (widget.onDelete != null)
                        SizedBox(
                          width: AlgorithmNodeWidget.headerButtonHeight,
                          height: AlgorithmNodeWidget.headerButtonHeight,
                          child: PopupMenuButton<String>(
                            padding: EdgeInsets.zero,
                            iconSize: 16,
                            icon: Icon(
                              Icons.more_vert,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                            tooltip: 'Algorithm options',
                            onSelected: (value) {
                              if (value == 'delete') {
                                widget.onDelete?.call();
                              } else if (value.startsWith('mapping_')) {
                                // Handle mapping selection - extract parameter number
                                final parameterNumber = int.tryParse(value.replaceFirst('mapping_', ''));
                                if (parameterNumber != null) {
                                  _showMappingEditor(context, parameterNumber);
                                }
                              }
                            },
                            itemBuilder: (context) {
                              final items = <PopupMenuEntry<String>>[];
                              
                              // Add mappings submenu if there are mapped parameters
                              if (_hasMappedParameters()) {
                                items.add(
                                  PopupMenuItem(
                                    enabled: false, // This acts as a submenu header
                                    child: Row(
                                      children: [
                                        Icon(Icons.map_sharp, size: 18),
                                        SizedBox(width: 8),
                                        Text('Mappings', style: TextStyle(fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                                );
                                
                                // Add individual mapped parameters
                                for (final mapping in _getMappedParameters()) {
                                  final icon = _getMappingIcon(mapping.packedMappingData);
                                  items.add(
                                    PopupMenuItem(
                                      value: 'mapping_${mapping.parameterNumber}',
                                      child: Row(
                                        children: [
                                          SizedBox(width: 8), // Indent for submenu item
                                          Icon(icon, size: 16),
                                          SizedBox(width: 8),
                                          Text('Parameter ${mapping.parameterNumber}'),
                                        ],
                                      ),
                                    ),
                                  );
                                }
                                
                                // Add divider before delete option
                                items.add(const PopupMenuDivider());
                              }
                              
                              // Add delete option
                              items.add(
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(Icons.delete_forever_rounded, size: 18),
                                      SizedBox(width: 8),
                                      Text('Delete Algorithm'),
                                    ],
                                  ),
                                ),
                              );
                              
                              return items;
                            },
                          ),
                        ),
                    ],
                  ),
                ),

                // Ports area
                Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AlgorithmNodeWidget.horizontalPadding,
                      vertical: AlgorithmNodeWidget.portsVerticalPadding,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Input ports
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: widget.inputPorts
                                .map(
                                  (port) => _buildPortRow(port, PortType.input),
                                )
                                .toList(),
                          ),
                        ),

                        // Spacer
                        const SizedBox(width: 8),

                        // Output ports
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: widget.outputPorts
                                .map(
                                  (port) =>
                                      _buildPortRow(port, PortType.output),
                                )
                                .toList(),
                          ),
                        ),
                      ],
                    ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Check if this algorithm has any mapped parameters
  bool _hasMappedParameters() {
    for (final mapping in widget.mappings) {
      if (mapping is Mapping && mapping.packedMappingData.isMapped()) {
        return true;
      }
    }
    return false;
  }

  /// Get mapped parameters for display in submenu
  List<Mapping> _getMappedParameters() {
    return widget.mappings
        .whereType<Mapping>()
        .where((mapping) => mapping.packedMappingData.isMapped())
        .toList();
  }

  /// Get mapping icon based on mapping types
  IconData _getMappingIcon(PackedMappingData data) {
    if (data.cvInput > 0 || data.source > 0) {
      return Icons.settings_input_antenna; // CV icon
    } else if (data.isMidiEnabled) {
      return Icons.piano; // MIDI icon  
    } else if (data.isI2cEnabled) {
      return Icons.router; // I2C icon
    }
    return Icons.map_sharp; // Fallback
  }

  /// Show the mapping editor for a specific parameter
  void _showMappingEditor(BuildContext context, int parameterNumber) {
    // Find the mapping for this parameter
    final mapping = widget.mappings
        .whereType<Mapping>()
        .firstWhere(
          (m) => m.parameterNumber == parameterNumber,
          orElse: () => Mapping.filler(),
        );
    
    // Here we would typically show the PackedMappingDataEditor bottom sheet
    // For now, show a simple dialog indicating the feature is connected
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Mapping'),
        content: Text('Mapping editor for algorithm ${widget.nodePosition.algorithmIndex + 1}, parameter $parameterNumber would open here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildPortRow(AlgorithmPort port, PortType type) {
    final isConnected = widget.connectedPorts.contains(port.id ?? port.name);
    final portId = port.id ?? port.name;

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
                  onConnectionStart: null,
                  onConnectionEnd: () =>
                      widget.onPortConnectionEnd?.call(portId, type),
                  onPanStart: (details) =>
                      widget.onPortPanStart?.call(portId, type, details),
                  onPanUpdate: (details) =>
                      widget.onPortPanUpdate?.call(portId, type, details),
                  onPanEnd: (details) =>
                      widget.onPortPanEnd?.call(portId, type, details),
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
                  onConnectionStart: null,
                  onConnectionEnd: () =>
                      widget.onPortConnectionEnd?.call(portId, type),
                  onPanStart: (details) =>
                      widget.onPortPanStart?.call(portId, type, details),
                  onPanUpdate: (details) =>
                      widget.onPortPanUpdate?.call(portId, type, details),
                  onPanEnd: (details) =>
                      widget.onPortPanEnd?.call(portId, type, details),
                ),
              ],
      ),
    );
  }
}
