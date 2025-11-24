import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nt_helper/cubit/disting_cubit.dart';
import 'package:nt_helper/services/scale_quantizer.dart';
import 'package:nt_helper/services/step_sequencer_params.dart';
import 'package:nt_helper/ui/widgets/step_sequencer/step_column_widget.dart';
import 'package:nt_helper/util/parameter_write_debouncer.dart';

/// Grid view displaying all 16 steps of the step sequencer
///
/// Responsive layout:
/// - Desktop (> 768px): GridView showing all 16 steps
/// - Mobile (≤ 768px): Horizontal scrolling ListView
///
/// Supports drag-to-paint: drag across steps to paint values based on Y position
class StepGridView extends StatefulWidget {
  final Slot slot;
  final int slotIndex;
  final bool snapEnabled;
  final String selectedScale;
  final int rootNote;
  final StepParameter activeParameter; // Global parameter mode

  const StepGridView({
    super.key,
    required this.slot,
    required this.slotIndex,
    required this.snapEnabled,
    required this.selectedScale,
    required this.rootNote,
    required this.activeParameter,
  });

  @override
  State<StepGridView> createState() => _StepGridViewState();
}

class _StepGridViewState extends State<StepGridView> {
  bool _isDragging = false;
  int? _lastPaintedStep;
  final _debouncer = ParameterWriteDebouncer();
  final _rowKey = GlobalKey(); // Key to get Row's position

  @override
  void dispose() {
    _debouncer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width <= 768;

    // Use BlocBuilder to rebuild when parameter values change
    return BlocBuilder<DistingCubit, DistingState>(
      buildWhen: (prev, curr) {
        // Only rebuild when this slot's parameter values change
        if (curr is! DistingStateSynchronized) return false;
        if (prev is! DistingStateSynchronized) return true;

        return prev.slots[widget.slotIndex].values != curr.slots[widget.slotIndex].values;
      },
      builder: (context, state) {
        if (state is! DistingStateSynchronized) {
          return const Center(child: CircularProgressIndicator());
        }

        final currentSlot = state.slots[widget.slotIndex];
        final params = StepSequencerParams.fromSlot(currentSlot);

        return isMobile
            ? _buildHorizontalScrollGrid(context, currentSlot, params)
            : _buildFullGrid(context, currentSlot, params);
      },
    );
  }

  /// Build horizontal scrolling grid for mobile
  Widget _buildHorizontalScrollGrid(
    BuildContext context,
    Slot slot,
    StepSequencerParams params,
  ) {
    return GestureDetector(
      onPanStart: (details) => _handleDragStart(details.globalPosition, slot, params),
      onPanUpdate: (details) => _handleDragUpdate(details.globalPosition, slot, params),
      onPanEnd: (details) => _handleDragEnd(),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          key: _rowKey,
          children: List.generate(
            params.numSteps,
            (index) => SizedBox(
              width: 60,
              child: RepaintBoundary(
                child: _buildStepColumn(context, slot, params, index),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Build full grid for desktop
  Widget _buildFullGrid(
    BuildContext context,
    Slot slot,
    StepSequencerParams params,
  ) {
    return GestureDetector(
      onPanStart: (details) => _handleDragStart(details.globalPosition, slot, params),
      onPanUpdate: (details) => _handleDragUpdate(details.globalPosition, slot, params),
      onPanEnd: (details) => _handleDragEnd(),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          key: _rowKey,
          children: List.generate(
            params.numSteps,
            (index) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: SizedBox(
                width: 60,
                child: RepaintBoundary(
                  child: _buildStepColumn(context, slot, params, index),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Build individual step column widget
  Widget _buildStepColumn(
    BuildContext context,
    Slot slot,
    StepSequencerParams params,
    int stepIndex,
  ) {
    // Get parameter indices for this step (1-indexed)
    final pitchParamIndex = params.getPitch(stepIndex + 1);
    final velocityParamIndex = params.getVelocity(stepIndex + 1);

    // Get current values (default to 0 if parameter not found)
    final pitchValue = pitchParamIndex != null && pitchParamIndex < slot.values.length
        ? slot.values[pitchParamIndex].value
        : 0;

    final velocityValue = velocityParamIndex != null &&
            velocityParamIndex < slot.values.length
        ? slot.values[velocityParamIndex].value
        : 0;

    return StepColumnWidget(
      stepIndex: stepIndex,
      pitchValue: pitchValue,
      velocityValue: velocityValue,
      isActive: false, // TODO: Will be implemented in future story
      slotIndex: widget.slotIndex,
      slot: slot,
      snapEnabled: widget.snapEnabled,
      selectedScale: widget.selectedScale,
      rootNote: widget.rootNote,
      activeParameter: widget.activeParameter, // Pass global parameter mode
    );
  }

  /// Handle drag start - begin painting values
  void _handleDragStart(Offset globalPosition, Slot slot, StepSequencerParams params) {
    setState(() {
      _isDragging = true;
      _lastPaintedStep = null;
    });
    _paintValueAtPosition(globalPosition, slot, params);
  }

  /// Handle drag update - continue painting as drag moves
  void _handleDragUpdate(Offset globalPosition, Slot slot, StepSequencerParams params) {
    if (_isDragging) {
      _paintValueAtPosition(globalPosition, slot, params);
    }
  }

  /// Handle drag end - stop painting
  void _handleDragEnd() {
    setState(() {
      _isDragging = false;
      _lastPaintedStep = null;
    });
  }

  /// Paint value at the given position
  void _paintValueAtPosition(Offset globalPosition, Slot slot, StepSequencerParams params) {
    // Skip bit pattern modes (Pattern, Ties) - they need special editor
    if (widget.activeParameter == StepParameter.pattern ||
        widget.activeParameter == StepParameter.ties) {
      return;
    }

    // Convert global position to local position relative to the Row
    final RenderBox? rowBox = _rowKey.currentContext?.findRenderObject() as RenderBox?;
    if (rowBox == null) {
      return; // Row not yet rendered
    }

    final localPosition = rowBox.globalToLocal(globalPosition);

    // Calculate which step column is under the cursor
    final stepIndex = _calculateStepIndex(localPosition.dx, params.numSteps);
    if (stepIndex == null || stepIndex == _lastPaintedStep) {
      return; // Outside grid or same step as last update
    }

    _lastPaintedStep = stepIndex;

    // Calculate value from Y position
    final value = _calculateValueFromY(localPosition.dy, slot, params);
    if (value == null) {
      return;
    }

    // Update the parameter
    _updateStepParameter(stepIndex, value, params);
  }

  /// Calculate which step column is under the cursor based on X position
  int? _calculateStepIndex(double x, int numSteps) {
    // Each step is 60px wide + 8px padding (4px on each side) for desktop
    // Mobile has no padding, just 60px
    final width = MediaQuery.of(context).size.width;
    final isMobile = width <= 768;

    final stepWidth = isMobile ? 60.0 : 68.0; // 60px + 8px padding
    final stepIndex = (x / stepWidth).floor();

    if (stepIndex < 0 || stepIndex >= numSteps) {
      return null; // Outside grid
    }

    return stepIndex;
  }

  /// Calculate parameter value from Y position within step column
  int? _calculateValueFromY(double y, Slot slot, StepSequencerParams params) {
    // Get parameter info for range
    final paramIndex = _getParameterIndexForStep(0, params); // Use step 0 as reference
    if (paramIndex == null || paramIndex >= slot.parameters.length) {
      return null;
    }

    final paramInfo = slot.parameters[paramIndex];
    final min = paramInfo.min;
    final max = paramInfo.max;

    // Step column structure from StepColumnWidget:
    // - Step number (Text): ~14px
    // - SizedBox(height: 4)
    // - Expanded (bar area)
    // - SizedBox(height: 4)
    // - ConstrainedBox(minHeight: 22, maxHeight: 22) - value text

    const stepNumberHeight = 14.0; // Text fontSize: 12, plus some padding
    const topSpacing = 4.0;
    const bottomSpacing = 4.0;
    const valueTextHeight = 22.0;

    const headerHeight = stepNumberHeight + topSpacing; // ~18px
    const footerHeight = bottomSpacing + valueTextHeight; // ~26px

    // The step column container has padding: 8px all around from Container
    const containerPadding = 8.0;

    // Adjust Y for container padding
    final yInContainer = y - containerPadding;

    // Calculate position relative to the bar area
    final barTop = headerHeight;
    final relativeY = yInContainer - barTop;

    // Bar height estimate (from 400px grid height - 44px padding - 44px header/footer)
    final barHeight = 400.0 - (containerPadding * 2) - headerHeight - footerHeight;

    if (relativeY < 0 || relativeY > barHeight) {
      // Outside bar area - clamp to nearest edge
      final clampedY = relativeY.clamp(0.0, barHeight);
      final normalized = 1.0 - (clampedY / barHeight);
      int value = (min + (normalized * (max - min))).round().clamp(min, max);

      // Apply quantization for pitch if enabled
      if (widget.activeParameter == StepParameter.pitch && widget.snapEnabled) {
        value = ScaleQuantizer.quantize(value, widget.selectedScale, widget.rootNote);
      }
      return value;
    }

    // Calculate normalized position (inverted: top = 1.0, bottom = 0.0)
    final normalized = 1.0 - (relativeY / barHeight).clamp(0.0, 1.0);

    // Map to parameter range
    int value = (min + (normalized * (max - min))).round().clamp(min, max);

    // Apply quantization for pitch if enabled
    if (widget.activeParameter == StepParameter.pitch && widget.snapEnabled) {
      value = ScaleQuantizer.quantize(
        value,
        widget.selectedScale,
        widget.rootNote,
      );
    }

    return value;
  }

  /// Get parameter index for a step based on active parameter mode
  int? _getParameterIndexForStep(int stepIndex, StepSequencerParams params) {
    final step1Based = stepIndex + 1; // Convert to 1-indexed for params

    switch (widget.activeParameter) {
      case StepParameter.pitch:
        return params.getPitch(step1Based);
      case StepParameter.velocity:
        return params.getVelocity(step1Based);
      case StepParameter.mod:
        return params.getMod(step1Based);
      case StepParameter.division:
        return params.getDivision(step1Based);
      case StepParameter.mute:
        return params.getMute(step1Based);
      case StepParameter.skip:
        return params.getSkip(step1Based);
      case StepParameter.reset:
        return params.getReset(step1Based);
      case StepParameter.repeat:
        return params.getRepeat(step1Based);
      default:
        return null;
    }
  }

  /// Update step parameter value with debouncing
  void _updateStepParameter(int stepIndex, int value, StepSequencerParams params) {
    final paramIndex = _getParameterIndexForStep(stepIndex, params);
    if (paramIndex == null) {
      return;
    }

    // Debounce parameter writes to prevent flooding hardware
    _debouncer.schedule('step_$stepIndex', () {
      if (mounted) {
        context.read<DistingCubit>().updateParameterValue(
          algorithmIndex: widget.slotIndex,
          parameterNumber: paramIndex,
          value: value,
          userIsChangingTheValue: true,
        );
      }
    }, const Duration(milliseconds: 50));
  }
}
