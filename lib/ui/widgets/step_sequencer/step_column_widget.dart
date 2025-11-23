import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nt_helper/cubit/disting_cubit.dart';
import 'package:nt_helper/services/scale_quantizer.dart';
import 'package:nt_helper/services/step_sequencer_params.dart';
import 'package:nt_helper/ui/widgets/step_sequencer/bit_pattern_editor_dialog.dart';
import 'package:nt_helper/ui/widgets/step_sequencer/pitch_bar_painter.dart';
import 'package:nt_helper/util/ui_helpers.dart';

/// Step parameter types for editing (GLOBAL mode, not per-step)
enum StepParameter {
  pitch,
  velocity,
  mod,
  division,
  pattern,
  ties,
  mute,
  skip,
  reset,
  repeat,
}

/// Individual step column widget showing parameter bar and step number
/// Uses global parameter mode selector (controlled by parent StepSequencerView)
class StepColumnWidget extends StatefulWidget {
  final int stepIndex; // 0-indexed
  final int pitchValue; // 0-127 MIDI note
  final int velocityValue; // 0-127
  final bool isActive;
  final int slotIndex;
  final Slot slot;
  final bool snapEnabled;
  final String selectedScale;
  final int rootNote;
  final StepParameter activeParameter; // GLOBAL parameter mode from parent
  final ValueChanged<int>? onParameterChanged; // Callback for parameter updates

  const StepColumnWidget({
    super.key,
    required this.stepIndex,
    required this.pitchValue,
    required this.velocityValue,
    required this.isActive,
    required this.slotIndex,
    required this.slot,
    required this.snapEnabled,
    required this.selectedScale,
    required this.rootNote,
    required this.activeParameter,
    this.onParameterChanged,
  });

  @override
  State<StepColumnWidget> createState() => _StepColumnWidgetState();
}

class _StepColumnWidgetState extends State<StepColumnWidget> {
  // OLD: Per-step parameter selection (_activeParam) - REMOVED
  // NEW: Global parameter mode is passed via widget.activeParameter

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Teal color scheme
    const primaryTeal = Color(0xFF14b8a6);
    final borderColor = widget.isActive ? primaryTeal : _getBorderColor(isDark);
    final borderWidth = widget.isActive ? 2.0 : 1.0;

    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: widget.isActive
            ? primaryTeal.withValues(alpha: 0.2)
            : _getBackgroundColor(isDark),
        border: Border.all(
          color: borderColor,
          width: borderWidth,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Step number (1-indexed for display)
          Text(
            '${widget.stepIndex + 1}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: _getTextColor(isDark),
            ),
          ),
          const SizedBox(height: 4),

          // Main parameter bar (tappable and draggable for editing current parameter)
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return GestureDetector(
                  onTapDown: (details) {
                    // For bit pattern modes, show editor dialog; for continuous, handle drag
                    if (_isBitPatternMode()) {
                      _showBitPatternEditor();
                    } else {
                      _handleBarInteraction(
                        details.localPosition.dy,
                        constraints.maxHeight,
                      );
                    }
                  },
                  onVerticalDragUpdate: (details) {
                    // Only continuous parameters support drag
                    if (!_isBitPatternMode()) {
                      _handleBarInteraction(
                        details.localPosition.dy,
                        constraints.maxHeight,
                      );
                    }
                  },
                  child: SizedBox(
                    width: double.infinity,
                    child: CustomPaint(
                      painter: PitchBarPainter(
                        pitchValue: _getCurrentParameterValue(),
                        barColor: _getActiveParameterColor(),
                        displayMode: _getDisplayMode(),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 4),

          // Current parameter value text (formatted based on parameter type)
          Text(
            _formatStepValue(_getCurrentParameterValue()),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: _getActiveParameterColor(),
            ),
          ),
        ],
      ),
    );
  }

  /// Check if current mode is bit pattern (Pattern or Ties)
  bool _isBitPatternMode() {
    return widget.activeParameter == StepParameter.pattern ||
        widget.activeParameter == StepParameter.ties;
  }

  /// Get the appropriate display mode for the painter
  BarDisplayMode _getDisplayMode() {
    if (_isBitPatternMode()) {
      return BarDisplayMode.bitPattern;
    } else if (widget.activeParameter == StepParameter.division) {
      return BarDisplayMode.division;
    } else {
      return BarDisplayMode.continuous;
    }
  }

  /// Show bit pattern editor dialog for Ties/Pattern modes
  void _showBitPatternEditor() {
    final currentValue = _getCurrentParameterValue();
    final paramName =
        widget.activeParameter == StepParameter.ties ? 'Ties' : 'Pattern';
    final color = _getActiveParameterColor();

    showDialog(
      context: context,
      builder: (context) => BitPatternEditorDialog(
        initialValue: currentValue,
        parameterName: paramName,
        color: color,
      ),
    ).then((newValue) {
      if (newValue != null && newValue != currentValue) {
        _updateParameter(newValue);
      }
    });
  }

  /// Update parameter value via cubit
  void _updateParameter(int newValue) {
    final params = StepSequencerParams.fromSlot(widget.slot);
    int? paramIndex = _getParameterIndex(params, widget.activeParameter);

    if (paramIndex != null) {
      context.read<DistingCubit>().updateParameterValue(
            algorithmIndex: widget.slotIndex,
            parameterNumber: paramIndex,
            value: newValue,
            userIsChangingTheValue: true,
          );
    }
  }

  /// Handle tap or drag on pitch bar to edit active parameter
  void _handleBarInteraction(double localY, double barHeight) {
    // Calculate value based on position (inverted - top is high, bottom is low)
    int newValue = ((1.0 - (localY / barHeight)) * 127).round().clamp(0, 127);

    // Apply quantization if needed for pitch parameter
    if (widget.activeParameter == StepParameter.pitch && widget.snapEnabled) {
      newValue = ScaleQuantizer.quantize(
        newValue,
        widget.selectedScale,
        widget.rootNote,
      );
    }

    _updateParameter(newValue);
  }

  /// Get parameter index from parameter type using step sequencer params service
  int? _getParameterIndex(
    StepSequencerParams params,
    StepParameter param,
  ) {
    final step = widget.stepIndex + 1; // Convert 0-indexed to 1-indexed

    switch (param) {
      case StepParameter.pitch:
        return params.getPitch(step);
      case StepParameter.velocity:
        return params.getVelocity(step);
      case StepParameter.mod:
        return params.getMod(step);
      case StepParameter.division:
        return params.getDivision(step);
      case StepParameter.pattern:
        return params.getPattern(step);
      case StepParameter.ties:
        return params.getTies(step);
      case StepParameter.mute:
      case StepParameter.skip:
      case StepParameter.reset:
      case StepParameter.repeat:
        // Probability parameters - TODO: implement in Story 10.12
        return null;
    }
  }

  /// Get the value of the currently selected parameter
  int _getCurrentParameterValue() {
    final params = StepSequencerParams.fromSlot(widget.slot);
    final paramIndex = _getParameterIndex(params, widget.activeParameter);

    if (paramIndex != null && paramIndex < widget.slot.values.length) {
      return widget.slot.values[paramIndex].value;
    }
    return 0; // Default if parameter not found
  }

  /// Format step value based on parameter type
  String _formatStepValue(int value) {
    switch (widget.activeParameter) {
      case StepParameter.pitch:
        return midiNoteToNoteString(value); // e.g., "C4", "E4"

      case StepParameter.velocity:
        return value.toString(); // e.g., "64"

      case StepParameter.mod:
        return formatWithUnit(
          value,
          min: 0,
          max: 255,
          name: 'V',
          unit: 'V',
          powerOfTen: -1,
        ); // e.g., "2.0V"

      case StepParameter.division:
        return (value + 1).toString(); // Show number of notes: 0→"1", 1→"2"

      case StepParameter.pattern:
      case StepParameter.ties:
        return ''; // Empty - bit pattern is visualized in the bar

      case StepParameter.mute:
      case StepParameter.skip:
      case StepParameter.reset:
      case StepParameter.repeat:
        return '$value%'; // e.g., "50%"
    }
  }

  /// Get the color of the currently selected parameter
  Color _getActiveParameterColor() {
    switch (widget.activeParameter) {
      case StepParameter.pitch:
        return const Color(0xFF14b8a6);
      case StepParameter.velocity:
        return const Color(0xFF10b981);
      case StepParameter.mod:
        return const Color(0xFF8b5cf6);
      case StepParameter.division:
        return const Color(0xFFf97316);
      case StepParameter.pattern:
        return const Color(0xFF3b82f6);
      case StepParameter.ties:
        return const Color(0xFFeab308);
      case StepParameter.mute:
        return const Color(0xFFef4444);
      case StepParameter.skip:
        return const Color(0xFFec4899);
      case StepParameter.reset:
        return const Color(0xFFf59e0b);
      case StepParameter.repeat:
        return const Color(0xFF06b6d4);
    }
  }

  Color _getBackgroundColor(bool isDark) {
    return isDark ? Colors.grey.shade900 : Colors.grey.shade50;
  }

  Color _getBorderColor(bool isDark) {
    return isDark ? Colors.grey.shade700 : Colors.grey.shade300;
  }

  Color _getTextColor(bool isDark) {
    return isDark ? Colors.grey.shade400 : Colors.grey.shade700;
  }
}
