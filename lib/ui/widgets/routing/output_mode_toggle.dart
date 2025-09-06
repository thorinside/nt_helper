import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nt_helper/cubit/routing_editor_cubit.dart';
import 'package:nt_helper/cubit/routing_editor_state.dart';
import 'package:nt_helper/core/routing/models/port.dart' as core_port;

/// Widget that handles output mode toggling for algorithm output ports
class OutputModeToggle extends StatefulWidget {
  final Port port;
  final VoidCallback? onModeChanged;

  const OutputModeToggle({
    super.key,
    required this.port,
    this.onModeChanged,
  });

  @override
  State<OutputModeToggle> createState() => _OutputModeToggleState();
}

class _OutputModeToggleState extends State<OutputModeToggle>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    // Color animation removed - was unused
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Only show toggle for output ports
    if (widget.port.direction != PortDirection.output) {
      return _buildPortLabel();
    }

    return BlocBuilder<RoutingEditorCubit, RoutingEditorState>(
      builder: (context, state) {
        if (state is! RoutingEditorStateLoaded) {
          return _buildPortLabel();
        }

        final currentMode = context
            .read<RoutingEditorCubit>()
            .getPortOutputMode(widget.port.id);

        return GestureDetector(
          onTap: () => _toggleMode(context, currentMode),
          onTapDown: (_) => _animationController.forward(),
          onTapUp: (_) => _animationController.reverse(),
          onTapCancel: () => _animationController.reverse(),
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: _buildPortLabelWithMode(currentMode),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildPortLabel() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Text(
        widget.port.name,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildPortLabelWithMode(core_port.OutputMode currentMode) {
    final isReplaceMode = currentMode == core_port.OutputMode.replace;
    final labelText = isReplaceMode 
        ? '${widget.port.name} (R)'
        : widget.port.name;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isReplaceMode 
            ? Colors.blue[50]
            : Colors.grey[100],
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isReplaceMode 
              ? Colors.blue
              : Colors.grey[300]!,
          width: isReplaceMode ? 2 : 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            labelText,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isReplaceMode 
                  ? Colors.blue[700]
                  : Colors.grey[700],
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            isReplaceMode ? Icons.swap_horiz : Icons.add,
            size: 14,
            color: isReplaceMode 
                ? Colors.blue[700]
                : Colors.grey[600],
          ),
        ],
      ),
    );
  }

  void _toggleMode(BuildContext context, core_port.OutputMode currentMode) {
    final newMode = currentMode == core_port.OutputMode.replace
        ? core_port.OutputMode.add
        : core_port.OutputMode.replace;

    context.read<RoutingEditorCubit>().setPortOutputMode(
      portId: widget.port.id,
      outputMode: newMode,
    );

    // Trigger callback if provided
    widget.onModeChanged?.call();

    // Show brief feedback
    _showModeChangeSnackBar(context, newMode);
  }

  void _showModeChangeSnackBar(
    BuildContext context, 
    core_port.OutputMode newMode,
  ) {
    final modeText = newMode == core_port.OutputMode.replace 
        ? 'Replace' 
        : 'Add';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${widget.port.name} mode: $modeText'),
        duration: const Duration(milliseconds: 1500),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(
          bottom: 80,
          left: 20,
          right: 20,
        ),
      ),
    );
  }
}

/// Widget factory for creating output mode toggle widgets
class OutputModeToggleFactory {
  /// Create an output mode toggle for the given port
  static Widget create({
    required Port port,
    VoidCallback? onModeChanged,
  }) {
    return OutputModeToggle(
      port: port,
      onModeChanged: onModeChanged,
    );
  }

  /// Create a tooltip explanation for output modes
  static Widget createModeTooltip({
    required Widget child,
  }) {
    return Tooltip(
      message: 'Tap to toggle between Add and Replace modes.\n'
               'Replace (R): Overwrite existing signal\n'
               'Add: Mix with existing signal',
      preferBelow: false,
      child: child,
    );
  }
}

/// Extension to provide output mode descriptions
extension OutputModeDescription on core_port.OutputMode {
  String get description {
    switch (this) {
      case core_port.OutputMode.add:
        return 'Add: Mixes signal with existing inputs on the same bus';
      case core_port.OutputMode.replace:
        return 'Replace: Overwrites any existing signal on the bus';
    }
  }

  String get shortName {
    switch (this) {
      case core_port.OutputMode.add:
        return 'Add';
      case core_port.OutputMode.replace:
        return 'Replace';
    }
  }

  IconData get icon {
    switch (this) {
      case core_port.OutputMode.add:
        return Icons.add;
      case core_port.OutputMode.replace:
        return Icons.swap_horiz;
    }
  }
}