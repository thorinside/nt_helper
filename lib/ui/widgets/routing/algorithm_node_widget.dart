import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nt_helper/cubit/disting_cubit.dart';
import 'package:nt_helper/domain/disting_nt_sysex.dart';
import 'package:nt_helper/models/packed_mapping_data.dart';
import 'package:nt_helper/ui/midi_listener/midi_listener_cubit.dart';
import 'package:nt_helper/ui/synchronized_screen.dart';
import 'package:nt_helper/ui/widgets/routing/accessibility_colors.dart';
import 'package:nt_helper/ui/widgets/routing/port_widget.dart';
// No direct dependency on RoutingEditorWidget static members

/// A draggable widget representing an algorithm node in the routing editor.
///
/// Features:
/// - Draggable with precise coordinate transforms
/// - Title bar showing algorithm name and slot number
/// - Toolbar with up/down/delete actions
/// - Input and output connection points
/// - Theme-aware styling
class AlgorithmNodeWidget extends StatefulWidget {
  final String algorithmName;
  final int slotNumber;
  // Position is now handled by parent Positioned widget
  final Offset position;
  // Optional leading icon for the top bar
  final Widget? leadingIcon;
  final bool isSelected;
  final Function(Offset)? onPositionChanged;
  final VoidCallback? onDragStart;
  final VoidCallback? onDragEnd;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;
  final List<String> inputLabels;
  final List<String> outputLabels;
  // Port IDs aligned with labels, used for accurate connection anchors
  final List<String>? inputPortIds;
  final List<String>? outputPortIds;
  // Set of port IDs that are currently connected
  final Set<String>? connectedPorts;
  // Set of output port IDs that are shadowed (red dot indicator)
  final Set<String>? shadowedPortIds;
  // Callback to report per-port anchor global position
  final void Function(String portId, Offset globalCenter, bool isInput)?
  onPortPositionResolved;

  // Callback for routing actions from ports
  final void Function(String portId, String action)? onRoutingAction;

  // Callback when a port is tapped (for connection deletion)
  final void Function(String portId)? onPortTapped;

  // Port drag callbacks for connection creation
  final void Function(String portId)? onPortDragStart;
  final void Function(String portId, Offset position)? onPortDragUpdate;
  final void Function(String portId, Offset position)? onPortDragEnd;

  // ID of the port that should be highlighted (during drag operations)
  final String? highlightedPortId;

  const AlgorithmNodeWidget({
    super.key,
    required this.algorithmName,
    required this.slotNumber,
    required this.position,
    this.leadingIcon,
    this.isSelected = false,
    this.onPositionChanged,
    this.onDragStart,
    this.onDragEnd,
    this.onMoveUp,
    this.onMoveDown,
    this.onDelete,
    this.onTap,
    this.inputLabels = const [],
    this.outputLabels = const [],
    this.inputPortIds,
    this.outputPortIds,
    this.connectedPorts,
    this.shadowedPortIds,
    this.onPortPositionResolved,
    this.onRoutingAction,
    this.onPortTapped,
    this.onPortDragStart,
    this.onPortDragUpdate,
    this.onPortDragEnd,
    this.highlightedPortId,
  });

  @override
  State<AlgorithmNodeWidget> createState() => _AlgorithmNodeWidgetState();
}

class _AlgorithmNodeWidgetState extends State<AlgorithmNodeWidget> {
  bool _isDragging = false;
  // Track drag start and initial position for stable deltas
  Offset _dragStartGlobal = Offset.zero;
  Offset _initialPosition = Offset.zero;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () {
        widget.onTap?.call();
      },
      onPanStart: _handleDragStart,
      onPanUpdate: _handleDragUpdate,
      onPanEnd: _handleDragEnd,
      child: AnimatedContainer(
        duration: _isDragging
            ? Duration.zero
            : const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: widget.isSelected
                ? AccessibilityColors.ensureContrast(
                    theme.colorScheme.primary,
                    theme.colorScheme.surface,
                    minRatio: AccessibilityColors.wcagAANormal,
                  )
                : theme.colorScheme.outline.withValues(
                    alpha: 0.7,
                  ), // Higher alpha for better visibility
            width: widget.isSelected ? 3 : 1, // Thicker border when selected
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: _isDragging ? 0.3 : 0.1),
              blurRadius: _isDragging ? 8 : 4,
              offset: Offset(0, _isDragging ? 4 : 2),
            ),
          ],
        ),
        child: IntrinsicWidth(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [_buildTitleBar(theme), _buildPorts(theme)],
          ),
        ),
      ),
    );
  }

  Widget _buildTitleBar(ThemeData theme) {
    // Use app bar theming for better readability and consistency
    final backgroundColor =
        theme.appBarTheme.backgroundColor ??
        theme.colorScheme.surfaceContainerHigh;
    final foregroundColor =
        theme.appBarTheme.foregroundColor ?? theme.colorScheme.onSurface;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(8),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.leadingIcon != null) ...[
            IconTheme(
              data: IconThemeData(color: foregroundColor, size: 18),
              child: widget.leadingIcon!,
            ),
            const SizedBox(width: 8),
          ],
          // Show mapping icon if any parameters are mapped
          if (_hasAnyMappings()) ...[
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Icon(
                Icons.map_sharp,
                size: 16,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 8),
          ],
          // Title with slot number pre-pended
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(
                right: 12.0,
              ), // Add space after title per Material 3 specs
              child: Text(
                '#${widget.slotNumber} ${_truncateWithEllipsis(widget.algorithmName, 25)}',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: foregroundColor,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
                softWrap: false,
              ),
            ),
          ),
          // Up/Down actions always present; disabled when not applicable
          // Material 3 specs: use density for closer action spacing
          IconButton(
            tooltip: 'Move Up',
            icon: const Icon(Icons.arrow_upward, size: 18),
            onPressed: widget.onMoveUp,
            visualDensity: VisualDensity.compact,
          ),
          IconButton(
            tooltip: 'Move Down',
            icon: const Icon(Icons.arrow_downward, size: 18),
            onPressed: widget.onMoveDown,
            visualDensity: VisualDensity.compact,
          ),
          // Overflow menu: mapped parameters and delete
          PopupMenuButton<String>(
            tooltip: 'More',
            icon: Icon(Icons.more_vert, size: 18, color: foregroundColor),
            itemBuilder: (context) {
              List<PopupMenuEntry<String>> items = [];

              // Add mapped parameter items first
              final cubit = context.read<DistingCubit>();
              final state = cubit.state;
              if (state is DistingStateSynchronized) {
                final slotIndex = widget.slotNumber - 1;
                if (slotIndex >= 0 && slotIndex < state.slots.length) {
                  final slot = state.slots[slotIndex];

                  // Find mapped parameters by checking both parameters list and mappings
                  final mappedParams =
                      <({ParameterInfo param, Mapping mapping})>[];
                  for (int i = 0; i < slot.mappings.length; i++) {
                    final mapping = slot.mappings.elementAtOrNull(i);
                    if (mapping != null &&
                        mapping.packedMappingData !=
                            PackedMappingData.filler() &&
                        mapping.packedMappingData.isMapped()) {
                      // Find corresponding parameter info
                      final param = slot.parameters
                          .where(
                            (p) => p.parameterNumber == mapping.parameterNumber,
                          )
                          .firstOrNull;
                      if (param != null) {
                        mappedParams.add((param: param, mapping: mapping));
                      }
                    }
                  }

                  for (final mappedParam in mappedParams) {
                    items.add(
                      PopupMenuItem(
                        value: 'mapping_${mappedParam.param.parameterNumber}',
                        child: Row(
                          children: [
                            const Icon(Icons.map_sharp, size: 18),
                            const SizedBox(width: 8),
                            Text(mappedParam.param.name),
                          ],
                        ),
                      ),
                    );
                  }

                  if (mappedParams.isNotEmpty) {
                    items.add(const PopupMenuDivider());
                  }
                }
              }

              // Add existing delete item
              items.add(
                PopupMenuItem(
                  value: 'delete',
                  enabled: widget.onDelete != null,
                  child: Row(
                    children: [
                      Icon(
                        Icons.delete,
                        size: 18,
                        color: theme.colorScheme.error,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Delete',
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                    ],
                  ),
                ),
              );

              return items;
            },
            onSelected: (value) {
              if (value == 'delete') {
                _handleDelete();
              } else if (value.startsWith('mapping_')) {
                final paramNumber = int.parse(value.substring(8));
                _handleMappingEdit(paramNumber);
              }
            },
          ),
        ],
      ),
    );
  }

  // Removed old overflow-only toolbar; actions are now visible icon buttons with delete in overflow

  Widget _buildPorts(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Inputs (natural width)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: List.generate(
              widget.inputLabels.length,
              (index) => _buildPort(
                theme,
                widget.inputLabels[index],
                true,
                portId:
                    (widget.inputPortIds != null &&
                        index < widget.inputPortIds!.length)
                    ? widget.inputPortIds![index]
                    : null,
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Flexible spacer pushes outputs to the far right edge
          const Expanded(child: SizedBox.shrink()),
          // Outputs (flush right)
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: List.generate(
              widget.outputLabels.length,
              (index) => _buildPort(
                theme,
                widget.outputLabels[index],
                false,
                portId:
                    (widget.outputPortIds != null &&
                        index < widget.outputPortIds!.length)
                    ? widget.outputPortIds![index]
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPort(
    ThemeData theme,
    String label,
    bool isInput, {
    String? portId,
  }) {
    final isConnected =
        portId != null && (widget.connectedPorts?.contains(portId) ?? false);
    final showShadowDot = !isInput &&
        portId != null &&
        (widget.shadowedPortIds?.contains(portId) ?? false);

    return PortWidget(
      label: label,
      isInput: isInput,
      portId: portId,
      labelPosition: isInput ? PortLabelPosition.right : PortLabelPosition.left,
      theme: theme,
      isConnected:
          isConnected, // Keep using the passed connection info for algorithm ports
      isHighlighted: portId != null && portId == widget.highlightedPortId,
      showShadowDot: showShadowDot,
      onPortPositionResolved: widget.onPortPositionResolved,
      onRoutingAction: widget.onRoutingAction,
      onTap: portId != null && isInput
          ? () => widget.onPortTapped?.call(portId)
          : null,
      onDragStart: portId != null && !isInput && widget.onPortDragStart != null
          ? () => widget.onPortDragStart!(portId)
          : null,
      onDragUpdate:
          portId != null && !isInput && widget.onPortDragUpdate != null
          ? (position) => widget.onPortDragUpdate!(portId, position)
          : null,
      onDragEnd: portId != null && !isInput && widget.onPortDragEnd != null
          ? (position) => widget.onPortDragEnd!(portId, position)
          : null,
    );
  }

  String _truncateWithEllipsis(String text, int maxChars) {
    if (text.length <= maxChars) return text;
    return '${text.substring(0, maxChars)}…';
  }

  void _handleDragStart(DragStartDetails details) {
    debugPrint(
      '=== ALGORITHM NODE DRAG START: ${widget.algorithmName} at ${details.globalPosition}',
    );

    setState(() {
      _isDragging = true;
      _dragStartGlobal = details.globalPosition;
      _initialPosition = widget.position;
    });

    // Notify parent that a drag has begun
    widget.onDragStart?.call();
  }

  // Toolbar action handlers removed; actions call callbacks directly

  void _handleDelete() async {
    debugPrint('AlgorithmNodeWidget: Deleting algorithm #${widget.slotNumber}');

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Algorithm'),
        content: Text(
          'Are you sure you want to delete "${widget.algorithmName}" from slot #${widget.slotNumber}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      debugPrint('AlgorithmNodeWidget: Delete cancelled by user');
      return;
    }

    if (!mounted) return;
    final cubit = context.read<DistingCubit>();
    try {
      // Slot numbers are 1-indexed, but the cubit uses 0-indexed
      final algorithmIndex = widget.slotNumber - 1;

      await cubit.onRemoveAlgorithm(algorithmIndex);
      widget.onDelete?.call();
      _showFeedback('Algorithm deleted');
      debugPrint('AlgorithmNodeWidget: Successfully deleted algorithm');
    } catch (e) {
      debugPrint('AlgorithmNodeWidget: Error deleting algorithm: $e');
      _showFeedback('Failed to delete algorithm: $e', isError: true);
    }
  }

  Future<void> _handleMappingEdit(int parameterNumber) async {
    final cubit = context.read<DistingCubit>();
    final state = cubit.state;

    if (state is! DistingStateSynchronized) return;

    final slotIndex = widget.slotNumber - 1;
    if (slotIndex < 0 || slotIndex >= state.slots.length) return;

    final slot = state.slots[slotIndex];
    final mapping = slot.mappings
        .where((m) => m.parameterNumber == parameterNumber)
        .firstOrNull;

    if (mapping == null) return;

    final data = mapping.packedMappingData;
    final myMidiCubit = context.read<MidiListenerCubit>();

    final updatedData = await showModalBottomSheet<PackedMappingData>(
      context: context,
      isScrollControlled: true,
      builder: (context) => MappingEditorBottomSheet(
        myMidiCubit: myMidiCubit,
        data: data,
        slots: state.slots,
      ),
    );

    if (updatedData != null) {
      cubit.saveMapping(slotIndex, parameterNumber, updatedData);
    }
  }

  void _showFeedback(String message, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? Theme.of(context).colorScheme.error
            : Theme.of(context).colorScheme.primary,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    if (!_isDragging) return;
    // Compute new position from drag delta relative to drag start
    final dragDelta = details.globalPosition - _dragStartGlobal;
    final newPosition = _initialPosition + dragDelta;

    // Snap to grid
    const double gridSize = 50.0;
    final snappedPosition = Offset(
      (newPosition.dx / gridSize).round() * gridSize,
      (newPosition.dy / gridSize).round() * gridSize,
    );

    // Constrain to canvas bounds
    const double canvasSize = 5000.0;
    final constrainedPosition = Offset(
      snappedPosition.dx.clamp(0.0, canvasSize - 200),
      snappedPosition.dy.clamp(0.0, canvasSize - 100),
    );

    debugPrint(
      '=== ALGORITHM NODE DRAG UPDATE: ${widget.algorithmName} to $constrainedPosition',
    );
    widget.onPositionChanged?.call(constrainedPosition);
  }

  void _handleDragEnd(DragEndDetails details) {
    setState(() {
      _isDragging = false;
    });

    // Notify parent that drag ended
    widget.onDragEnd?.call();
  }

  /// Check if the slot has any mapped parameters
  bool _hasAnyMappings() {
    // Get slot data from cubit to check for mappings
    final cubit = context.read<DistingCubit>();
    final state = cubit.state;

    if (state is! DistingStateSynchronized) {
      return false;
    }

    // Find the slot by index (slot numbers are 1-indexed, but list is 0-indexed)
    final slotIndex = widget.slotNumber - 1;
    if (slotIndex < 0 || slotIndex >= state.slots.length) {
      return false;
    }

    final slot = state.slots[slotIndex];

    // Check if any parameter has a mapping that's not empty/filler
    for (int i = 0; i < slot.mappings.length; i++) {
      final mapping = slot.mappings.elementAtOrNull(i);
      if (mapping != null &&
          mapping.packedMappingData != PackedMappingData.filler() &&
          mapping.packedMappingData.isMapped()) {
        return true;
      }
    }

    return false;
  }
}

// Removed dependency on RoutingEditorWidget static values
