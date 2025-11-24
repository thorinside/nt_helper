import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nt_helper/cubit/disting_cubit.dart';
import 'package:nt_helper/models/firmware_version.dart';
import 'package:nt_helper/services/scale_quantizer.dart';
import 'package:nt_helper/services/step_sequencer_params.dart';
import 'package:nt_helper/ui/widgets/step_sequencer/parameter_pages_view.dart';
import 'package:nt_helper/ui/widgets/step_sequencer/playback_controls.dart';
import 'package:nt_helper/ui/widgets/step_sequencer/quantize_controls.dart';
import 'package:nt_helper/ui/widgets/step_sequencer/randomize_settings_dialog.dart';
import 'package:nt_helper/ui/widgets/step_sequencer/sequence_selector.dart';
import 'package:nt_helper/ui/widgets/step_sequencer/step_column_widget.dart';
import 'package:nt_helper/ui/widgets/step_sequencer/step_grid_view.dart';
import 'package:nt_helper/ui/widgets/step_sequencer/sync_status_indicator.dart';
import 'package:nt_helper/util/parameter_write_debouncer.dart';

/// Custom widget view for Step Sequencer algorithm (GUID: 'spsq')
///
/// Displays a visual grid interface with 16 step columns with global parameter mode selector.
/// Users can edit all 16 steps for a single parameter at once (like a DAW automation lane).
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
  // Global parameter mode state (affects all 16 steps)
  late StepParameter _activeParameter = StepParameter.pitch;

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

                // Compact header row: Title, Sync Status, Overflow Menu
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Step Sequencer',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SyncStatusIndicator(
                          status: effectiveSyncStatus,
                          errorMessage: _lastError,
                          onRetry: _retryFailedWrites,
                        ),
                        const SizedBox(width: 8),
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert),
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'randomize',
                              child: ListTile(
                                leading: Icon(Icons.shuffle),
                                title: Text('Randomize'),
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'settings',
                              child: ListTile(
                                leading: Icon(Icons.settings),
                                title: Text('Randomize Settings...'),
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'parameter_pages',
                              child: ListTile(
                                leading: Icon(Icons.view_list),
                                title: Text('Parameter Pages...'),
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ],
                          onSelected: (value) {
                            if (value == 'randomize') {
                              _triggerRandomize();
                            } else if (value == 'settings') {
                              _showRandomizeSettingsDialog();
                            } else if (value == 'parameter_pages') {
                              _showParameterPages();
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Global parameter mode selector (no "Edit:" label)
                _buildGlobalParameterModeSelector(),
                const SizedBox(height: 12),

                // Compact control row: Sequence + Quantize controls
                Row(
                  children: [
                    // Sequence selector (compact)
                    SizedBox(
                      width: 150,
                      child: _buildSequenceSelector(widget.slot),
                    ),
                    const SizedBox(width: 16),
                    // Quantize controls (inline)
                    Expanded(
                      child: QuantizeControls(
                        snapEnabled: _snapEnabled,
                        selectedScale: _selectedScale,
                        rootNote: _rootNote,
                        onToggleSnap: _toggleSnapToScale,
                        onScaleChanged: _setScale,
                        onRootNoteChanged: _setRootNote,
                        onQuantizeAll: _quantizeAllSteps,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Step grid (fills most of the space)
                Expanded(
                  child: StepGridView(
                    slot: widget.slot,
                    slotIndex: widget.slotIndex,
                    snapEnabled: _snapEnabled,
                    selectedScale: _selectedScale,
                    rootNote: _rootNote,
                    activeParameter: _activeParameter,
                  ),
                ),
                const SizedBox(height: 12),

                // Playback controls (fixed height)
                SizedBox(
                  height: 180,
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

  /// Triggers randomization by setting Randomise parameter to 1, waiting 100ms, then resetting to 0
  Future<void> _triggerRandomize() async {
    final params = StepSequencerParams.fromSlot(widget.slot);
    final randomiseParam = params.randomise;

    if (randomiseParam == null) {
      // Randomise parameter not found - show error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Randomize parameter not found'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    final cubit = context.read<DistingCubit>();

    try {
      // Set trigger to 1
      await cubit.updateParameterValue(
        algorithmIndex: widget.slotIndex,
        parameterNumber: randomiseParam,
        value: 1,
        userIsChangingTheValue: true,
      );

      // Wait 100ms (allow hardware to process)
      await Future.delayed(const Duration(milliseconds: 100));

      // Reset trigger to 0
      await cubit.updateParameterValue(
        algorithmIndex: widget.slotIndex,
        parameterNumber: randomiseParam,
        value: 0,
        userIsChangingTheValue: true,
      );

      // Show feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Randomizing sequence...'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error triggering randomize: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  /// Shows the randomize settings dialog
  void _showRandomizeSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => RandomizeSettingsDialog(
        slot: widget.slot,
        slotIndex: widget.slotIndex,
      ),
    );
  }

  /// Shows the Parameter Pages view
  ///
  /// Opens a dialog (desktop) or full-screen view (mobile) displaying
  /// parameters not covered by the custom Step Sequencer UI.
  void _showParameterPages() {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 600;

    if (isMobile) {
      // Mobile: Full-screen navigation
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ParameterPagesView(
            slot: widget.slot,
            slotIndex: widget.slotIndex,
          ),
        ),
      );
    } else {
      // Desktop: Dialog
      showDialog(
        context: context,
        builder: (context) => ParameterPagesView(
          slot: widget.slot,
          slotIndex: widget.slotIndex,
        ),
      );
    }
  }

  /// Build global parameter mode selector
  /// Shows 10 ChoiceChip buttons for switching between parameter modes
  /// Builds sequence selector with firmware-provided enum strings
  Widget _buildSequenceSelector(Slot slot) {
    final params = StepSequencerParams.fromSlot(slot);
    final sequenceParam = params.currentSequence;

    // Get enum strings from firmware (if available)
    List<String>? enumStrings;
    if (sequenceParam != null && sequenceParam < slot.enums.length) {
      final enumData = slot.enums[sequenceParam];
      if (enumData.values.isNotEmpty) {
        enumStrings = enumData.values;
      }
    }

    return SequenceSelector(
      currentSequence: _currentSequence,
      isLoading: _isLoadingSequence,
      onSequenceChanged: _handleSequenceChange,
      enumStrings: enumStrings,
    );
  }

  Widget _buildGlobalParameterModeSelector() {
    const modeDefinitions = [
      (StepParameter.pitch, 'Pitch', Color(0xFF14b8a6)),
      (StepParameter.velocity, 'Velocity', Color(0xFF10b981)),
      (StepParameter.mod, 'Mod', Color(0xFF8b5cf6)),
      (StepParameter.division, 'Division', Color(0xFFf97316)),
      (StepParameter.pattern, 'Pattern', Color(0xFF3b82f6)),
      (StepParameter.ties, 'Ties', Color(0xFFeab308)),
      (StepParameter.mute, 'Mute', Color(0xFFef4444)),
      (StepParameter.skip, 'Skip', Color(0xFFec4899)),
      (StepParameter.reset, 'Reset', Color(0xFFf59e0b)),
      (StepParameter.repeat, 'Repeat', Color(0xFF06b6d4)),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final (mode, label, color) in modeDefinitions)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: _buildModeButton(mode, label, color),
            ),
        ],
      ),
    );
  }

  /// Build individual mode button
  Widget _buildModeButton(
    StepParameter mode,
    String label,
    Color color,
  ) {
    final isActive = _activeParameter == mode;

    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isActive,
      selectedColor: color.withValues(alpha: 0.3),
      backgroundColor: Colors.transparent,
      side: BorderSide(
        color: color,
        width: isActive ? 2 : 1,
      ),
      onSelected: (_) {
        setState(() {
          _activeParameter = mode;
        });
      },
    );
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
