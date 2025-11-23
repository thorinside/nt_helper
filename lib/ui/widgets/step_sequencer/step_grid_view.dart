import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nt_helper/cubit/disting_cubit.dart';
import 'package:nt_helper/services/step_sequencer_params.dart';
import 'package:nt_helper/ui/widgets/step_sequencer/step_column_widget.dart';
import 'package:nt_helper/ui/widgets/step_sequencer/step_edit_modal.dart';

/// Grid view displaying all 16 steps of the step sequencer
///
/// Responsive layout:
/// - Desktop (> 768px): GridView showing all 16 steps
/// - Mobile (≤ 768px): Horizontal scrolling ListView
class StepGridView extends StatelessWidget {
  final Slot slot;
  final int slotIndex;

  const StepGridView({
    super.key,
    required this.slot,
    required this.slotIndex,
  });

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

        return prev.slots[slotIndex].values != curr.slots[slotIndex].values;
      },
      builder: (context, state) {
        if (state is! DistingStateSynchronized) {
          return const Center(child: CircularProgressIndicator());
        }

        final currentSlot = state.slots[slotIndex];
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
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
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
    );
  }

  /// Build full grid for desktop
  Widget _buildFullGrid(
    BuildContext context,
    Slot slot,
    StepSequencerParams params,
  ) {
    return GridView.count(
      crossAxisCount: params.numSteps,
      childAspectRatio: 0.3,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      children: List.generate(
        params.numSteps,
        (index) => RepaintBoundary(
          child: _buildStepColumn(context, slot, params, index),
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
      onTap: () => _showStepEditModal(context, slot, params, stepIndex),
    );
  }

  /// Show step edit modal (dialog on desktop, bottom sheet on mobile)
  void _showStepEditModal(
    BuildContext context,
    Slot slot,
    StepSequencerParams params,
    int stepIndex,
  ) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width <= 768;

    if (isMobile) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (context) => SizedBox(
          height: MediaQuery.of(context).size.height * 0.8,
          child: StepEditModal(
            slotIndex: slotIndex,
            stepIndex: stepIndex,
            params: params,
            slot: slot,
          ),
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (context) => StepEditModal(
          slotIndex: slotIndex,
          stepIndex: stepIndex,
          params: params,
          slot: slot,
        ),
      );
    }
  }
}
