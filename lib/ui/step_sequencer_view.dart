import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nt_helper/cubit/disting_cubit.dart';
import 'package:nt_helper/models/firmware_version.dart';
import 'package:nt_helper/services/scale_quantizer.dart';
import 'package:nt_helper/services/step_sequencer_params.dart';
import 'package:nt_helper/ui/widgets/step_sequencer/quantize_controls.dart';
import 'package:nt_helper/ui/widgets/step_sequencer/sequence_selector.dart';
import 'package:nt_helper/ui/widgets/step_sequencer/step_grid_view.dart';

/// Custom widget view for Step Sequencer algorithm (GUID: 'spsq')
///
/// Displays a visual grid interface with 16 step columns showing pitch and velocity.
/// Includes scale quantization controls for musical pitch mapping.
class StepSequencerView extends StatefulWidget {
  final Slot slot;
  final FirmwareVersion firmwareVersion;
  final int slotIndex;

  const StepSequencerView({
    super.key,
    required this.slot,
    required this.firmwareVersion,
    required this.slotIndex,
  });

  @override
  State<StepSequencerView> createState() => _StepSequencerViewState();
}

class _StepSequencerViewState extends State<StepSequencerView> {
  // Local state for quantization settings (UI-only, not persisted)
  bool _snapEnabled = false;
  String _selectedScale = 'Major';
  int _rootNote = 0; // C

  // Local state for sequence selection (UI-only, not persisted)
  int _currentSequence = 0; // 0-31 (hardware value)
  bool _isLoadingSequence = false;

  @override
  void initState() {
    super.initState();
    _initializeCurrentSequence();
  }

  /// Initialize current sequence from slot parameter value
  void _initializeCurrentSequence() {
    final params = StepSequencerParams.fromSlot(widget.slot);
    final sequenceParamNum = params.currentSequence;

    if (sequenceParamNum != null &&
        sequenceParamNum < widget.slot.values.length) {
      final sequenceValue = widget.slot.values[sequenceParamNum].value;
      if (sequenceValue >= 0 && sequenceValue < 32) {
        setState(() {
          _currentSequence = sequenceValue;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    try {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Text(
              'Step Sequencer',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            // Sequence selector
            SequenceSelector(
              currentSequence: _currentSequence,
              isLoading: _isLoadingSequence,
              onSequenceChanged: _handleSequenceChange,
            ),
            const SizedBox(height: 16),

            // Quantize controls
            QuantizeControls(
              snapEnabled: _snapEnabled,
              selectedScale: _selectedScale,
              rootNote: _rootNote,
              onToggleSnap: _toggleSnapToScale,
              onScaleChanged: _setScale,
              onRootNoteChanged: _setRootNote,
              onQuantizeAll: _quantizeAllSteps,
            ),
            const SizedBox(height: 16),

            // Step grid (expanded to fill available space)
            Expanded(
              child: StepGridView(
                slot: widget.slot,
                slotIndex: widget.slotIndex,
                snapEnabled: _snapEnabled,
                selectedScale: _selectedScale,
                rootNote: _rootNote,
              ),
            ),
          ],
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

  void _toggleSnapToScale() {
    setState(() {
      _snapEnabled = !_snapEnabled;
    });
  }

  void _setScale(String scale) {
    setState(() {
      _selectedScale = scale;
    });
  }

  void _setRootNote(int root) {
    setState(() {
      _rootNote = root;
    });
  }

  /// Handle sequence selection change
  ///
  /// Updates hardware parameter and triggers slot data refresh to load new sequence
  Future<void> _handleSequenceChange(int newSequence) async {
    if (_isLoadingSequence) return; // Prevent concurrent operations

    setState(() {
      _isLoadingSequence = true;
    });

    try {
      final params = StepSequencerParams.fromSlot(widget.slot);
      final sequenceParamNum = params.currentSequence;

      if (sequenceParamNum == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Current Sequence parameter not found'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Update hardware parameter (0-31 value)
      final cubit = context.read<DistingCubit>();
      await cubit.updateParameterValue(
        algorithmIndex: widget.slotIndex,
        parameterNumber: sequenceParamNum,
        value: newSequence,
        userIsChangingTheValue: true,
      );

      // Wait for hardware to process the change
      await Future.delayed(const Duration(milliseconds: 100));

      // Update local state
      setState(() {
        _currentSequence = newSequence;
      });

      // Note: Slot data will auto-refresh via cubit state updates
      // No need to manually trigger refresh here
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to switch sequence: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingSequence = false;
        });
      }
    }
  }

  Future<void> _quantizeAllSteps() async {
    // Show confirmation dialog
    final confirmed = await QuantizeControls.showQuantizeAllDialog(context);
    if (!confirmed || !mounted) return;

    try {
      final params = StepSequencerParams.fromSlot(widget.slot);

      // Show progress indicator
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Quantize all 16 steps
      final cubit = context.read<DistingCubit>();
      for (int step = 1; step <= 16; step++) {
        final pitchParamNum = params.getPitch(step);
        if (pitchParamNum != null) {
          // Get current pitch value
          final currentPitch =
              widget.slot.values.isNotEmpty &&
                      pitchParamNum < widget.slot.values.length
                  ? widget.slot.values[pitchParamNum].value
                  : 60; // Default to middle C if not available

          // Quantize to scale
          final quantized = ScaleQuantizer.quantize(
            currentPitch,
            _selectedScale,
            _rootNote,
          );

          // Update parameter (with debouncing built into cubit)
          cubit.updateParameterValue(
            algorithmIndex: widget.slotIndex,
            parameterNumber: pitchParamNum,
            value: quantized,
            userIsChangingTheValue: true,
          );

          // Small delay to avoid overwhelming MIDI scheduler
          await Future.delayed(const Duration(milliseconds: 10));
        }
      }

      // Close progress dialog
      if (mounted) {
        Navigator.of(context).pop();

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All steps quantized to scale'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      // Close progress dialog if open
      if (mounted) {
        Navigator.of(context).pop();

        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error quantizing steps: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
