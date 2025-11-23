import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nt_helper/cubit/disting_cubit.dart';
import 'package:nt_helper/models/firmware_version.dart';
import 'package:nt_helper/services/scale_quantizer.dart';
import 'package:nt_helper/services/step_sequencer_params.dart';
import 'package:nt_helper/ui/widgets/step_sequencer/playback_controls.dart';
import 'package:nt_helper/ui/widgets/step_sequencer/quantize_controls.dart';
import 'package:nt_helper/ui/widgets/step_sequencer/sequence_selector.dart';
import 'package:nt_helper/ui/widgets/step_sequencer/step_grid_view.dart';
import 'package:nt_helper/ui/widgets/step_sequencer/sync_status_indicator.dart';
import 'package:nt_helper/util/parameter_write_debouncer.dart';

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

  // Sync status tracking
  final _debouncer = ParameterWriteDebouncer();
  SyncStatus _syncStatus = SyncStatus.synced;
  String? _lastError;

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
  void dispose() {
    _debouncer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    try {
      return BlocBuilder<DistingCubit, DistingState>(
        builder: (context, state) {
          // Determine if we're offline
          final isOffline = state.maybeWhen(
            connected: (disting, inputDevice, outputDevice, offline, loading) => offline,
            synchronized: (
              disting,
              distingVersion,
              firmwareVersion,
              presetName,
              algorithms,
              slots,
              unitStrings,
              inputDevice,
              outputDevice,
              loading,
              offline,
              screenshot,
              demo,
              videoStream,
            ) => offline,
            orElse: () => false,
          );

          // Update sync status based on offline state
          final effectiveSyncStatus = isOffline ? SyncStatus.offline : _syncStatus;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Offline banner (if offline)
                if (isOffline) _buildOfflineBanner(context),
                if (isOffline) const SizedBox(height: 16),

                // Header with sync status
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Step Sequencer',
                        style: Theme.of(context).textTheme.headlineSmall,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SyncStatusIndicator(
                      status: effectiveSyncStatus,
                      errorMessage: _lastError,
                      onRetry: _retryFailedWrites,
                    ),
                  ],
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

                // Step grid and playback controls (expanded to fill available space)
                Expanded(
                  child: Column(
                    children: [
                      // Step grid (80% of expanded space)
                      Expanded(
                        flex: 80,
                        child: StepGridView(
                          slot: widget.slot,
                          slotIndex: widget.slotIndex,
                          snapEnabled: _snapEnabled,
                          selectedScale: _selectedScale,
                          rootNote: _rootNote,
                        ),
                      ),

                      // Playback controls (15% of expanded space)
                      Expanded(
                        flex: 15,
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final width = MediaQuery.of(context).size.width;
                            final isMobile = width <= 768;
                            final params = StepSequencerParams.fromSlot(widget.slot);

                            return PlaybackControls(
                              slotIndex: widget.slotIndex,
                              params: params,
                              slot: widget.slot,
                              compact: isMobile,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
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
      _syncStatus = SyncStatus.syncing;
    });

    try {
      final params = StepSequencerParams.fromSlot(widget.slot);
      final sequenceParamNum = params.currentSequence;

      if (sequenceParamNum == null) {
        if (mounted) {
          setState(() {
            _syncStatus = SyncStatus.error;
            _lastError = 'Current Sequence parameter not found';
          });
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
      if (mounted) {
        setState(() {
          _currentSequence = newSequence;
          _syncStatus = SyncStatus.synced;
          _lastError = null;
        });
      }

      // Note: Slot data will auto-refresh via cubit state updates
      // No need to manually trigger refresh here
    } catch (e) {
      if (mounted) {
        setState(() {
          _syncStatus = SyncStatus.error;
          _lastError = 'Failed to switch sequence: $e';
        });
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

    setState(() {
      _syncStatus = SyncStatus.syncing;
    });

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

        setState(() {
          _syncStatus = SyncStatus.synced;
          _lastError = null;
        });

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

        setState(() {
          _syncStatus = SyncStatus.error;
          _lastError = 'Error quantizing steps: $e';
        });

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

  void _retryFailedWrites() {
    setState(() {
      _syncStatus = SyncStatus.synced;
      _lastError = null;
    });
  }

  /// Build offline banner widget
  Widget _buildOfflineBanner(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? Colors.orange.shade900.withValues(alpha: 0.3)
            : Colors.orange.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? Colors.orange.shade700 : Colors.orange.shade300,
          width: 1,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(
            Icons.cloud_off,
            color: isDark ? Colors.orange.shade400 : Colors.orange.shade900,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Offline - editing locally',
              style: TextStyle(
                color: isDark ? Colors.orange.shade400 : Colors.orange.shade900,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
