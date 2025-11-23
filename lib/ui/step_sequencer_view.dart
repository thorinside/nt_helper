import 'package:flutter/material.dart';
import 'package:nt_helper/cubit/disting_cubit.dart' show Slot;
import 'package:nt_helper/models/firmware_version.dart';
import 'package:nt_helper/services/step_sequencer_params.dart';

/// Custom widget view for Step Sequencer algorithm (GUID: 'spsq')
///
/// This is a placeholder implementation for Story 10.1.
/// Future stories will add the full visual grid interface.
class StepSequencerView extends StatelessWidget {
  final Slot slot;
  final FirmwareVersion firmwareVersion;

  const StepSequencerView({
    super.key,
    required this.slot,
    required this.firmwareVersion,
  });

  void _verifyParameters() {
    // Triggers parameter discovery and logging for acceptance criteria 1.5–1.9
    StepSequencerParams.fromSlot(slot);
  }

  @override
  Widget build(BuildContext context) {
    _verifyParameters();

    try {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.piano,
                size: 64,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(height: 24),
              Text(
                'Step Sequencer Widget',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              Text(
                'Visual grid interface coming soon',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Algorithm: ${slot.algorithm.name}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      // Fallback to error message if widget fails to render
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Failed to load Step Sequencer widget',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Error: $e',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
  }
}
