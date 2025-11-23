import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nt_helper/cubit/disting_cubit.dart';
import 'package:nt_helper/services/step_sequencer_params.dart';
import 'package:nt_helper/util/parameter_write_debouncer.dart';

/// Playback controls for Step Sequencer algorithm
///
/// Provides controls for global playback parameters:
/// - Direction (Forward, Reverse, Pendulum, Random, etc.)
/// - Start Step (1-16)
/// - End Step (1-16)
/// - Gate Length (1-99%)
/// - Trigger Length (1-100ms)
/// - Glide Time (0-1000ms)
///
/// Supports responsive layouts:
/// - Desktop/Tablet (width > 768px): horizontal wrap layout
/// - Mobile (width ≤ 768px): vertical column layout
class PlaybackControls extends StatefulWidget {
  final int slotIndex;
  final StepSequencerParams params;
  final Slot slot;
  final bool compact;

  const PlaybackControls({
    super.key,
    required this.slotIndex,
    required this.params,
    required this.slot,
    this.compact = false,
  });

  @override
  State<PlaybackControls> createState() => _PlaybackControlsState();
}

class _PlaybackControlsState extends State<PlaybackControls> {
  final _debouncer = ParameterWriteDebouncer();
  final _startStepController = TextEditingController();
  final _endStepController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  @override
  void didUpdateWidget(PlaybackControls oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.slot != widget.slot) {
      _initializeControllers();
    }
  }

  void _initializeControllers() {
    // Initialize start step controller
    final startStepParam = widget.params.startStep;
    if (startStepParam != null && startStepParam < widget.slot.values.length) {
      final startValue = widget.slot.values[startStepParam].value;
      _startStepController.text = startValue.toString();
    }

    // Initialize end step controller
    final endStepParam = widget.params.endStep;
    if (endStepParam != null && endStepParam < widget.slot.values.length) {
      final endValue = widget.slot.values[endStepParam].value;
      _endStepController.text = endValue.toString();
    }
  }

  @override
  void dispose() {
    _debouncer.dispose();
    _startStepController.dispose();
    _endStepController.dispose();
    super.dispose();
  }

  /// Updates a parameter with optional debouncing
  void _updateParameter(int? paramNumber, int value, {bool debounce = false}) {
    if (paramNumber == null) {
      // Parameter not found - this is expected for some firmware versions
      debugPrint('[PlaybackControls] Parameter not available in this firmware version');
      return;
    }

    if (paramNumber >= widget.slot.values.length) {
      debugPrint('[PlaybackControls] Invalid parameter number: $paramNumber');
      return;
    }

    if (debounce) {
      // Debounced update for sliders (continuous values)
      _debouncer.schedule('param_$paramNumber', () {
        context.read<DistingCubit>().updateParameterValue(
              algorithmIndex: widget.slotIndex,
              parameterNumber: paramNumber,
              value: value,
              userIsChangingTheValue: true,
            );
      }, const Duration(milliseconds: 50));
    } else {
      // Immediate update for discrete values (dropdowns, text inputs)
      context.read<DistingCubit>().updateParameterValue(
            algorithmIndex: widget.slotIndex,
            parameterNumber: paramNumber,
            value: value,
            userIsChangingTheValue: true,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DistingCubit, DistingState>(
      buildWhen: (prev, curr) {
        // Only rebuild when playback parameters change
        if (curr is! DistingStateSynchronized) return false;
        if (prev is! DistingStateSynchronized) return true;

        // Check if any playback parameter changed
        final prevSlot = prev.slots[widget.slotIndex];
        final currSlot = curr.slots[widget.slotIndex];

        final playbackParamNumbers = [
          widget.params.direction,
          widget.params.startStep,
          widget.params.endStep,
          widget.params.gateLength,
          widget.params.triggerLength,
          widget.params.glideTime,
        ].whereType<int>(); // Filter out nulls

        for (final paramNum in playbackParamNumbers) {
          if (paramNum < prevSlot.values.length &&
              paramNum < currSlot.values.length) {
            if (prevSlot.values[paramNum].value !=
                currSlot.values[paramNum].value) {
              return true;
            }
          }
        }

        return false;
      },
      builder: (context, state) {
        if (state is! DistingStateSynchronized) {
          return const SizedBox.shrink();
        }

        final slot = state.slots[widget.slotIndex];

        if (widget.compact) {
          return _buildCompactLayout(slot);
        } else {
          return _buildFullLayout(slot);
        }
      },
    );
  }

  Widget _buildFullLayout(Slot slot) {
    // Desktop/tablet: horizontal row layout
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Wrap(
        spacing: 16,
        runSpacing: 12,
        alignment: WrapAlignment.start,
        children: [
          SizedBox(
            width: 200,
            child: _buildDirectionDropdown(slot),
          ),
          SizedBox(
            width: 100,
            child: _buildStartStepInput(slot),
          ),
          SizedBox(
            width: 100,
            child: _buildEndStepInput(slot),
          ),
          SizedBox(
            width: 250,
            child: _buildGateLengthSlider(slot),
          ),
          SizedBox(
            width: 250,
            child: _buildTriggerLengthSlider(slot),
          ),
          SizedBox(
            width: 250,
            child: _buildGlideTimeSlider(slot),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactLayout(Slot slot) {
    // Mobile: vertical column, smaller controls
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: _buildDirectionDropdown(slot)),
              const SizedBox(width: 8),
              SizedBox(width: 80, child: _buildStartStepInput(slot)),
              const SizedBox(width: 8),
              SizedBox(width: 80, child: _buildEndStepInput(slot)),
            ],
          ),
          const SizedBox(height: 12),
          _buildGateLengthSlider(slot),
          const SizedBox(height: 8),
          _buildTriggerLengthSlider(slot),
          const SizedBox(height: 8),
          _buildGlideTimeSlider(slot),
        ],
      ),
    );
  }

  Widget _buildDirectionDropdown(Slot slot) {
    final directionParam = widget.params.direction;
    if (directionParam == null || directionParam >= slot.parameters.length) {
      return const SizedBox.shrink();
    }

    final currentValue = directionParam < slot.values.length
        ? slot.values[directionParam].value
        : 0;

    // Get direction options from enum strings
    final enumStrings = directionParam < slot.enums.length
        ? slot.enums[directionParam]
        : null;
    final options = enumStrings?.values ?? ['Forward', 'Reverse', 'Pendulum', 'Random'];

    return DropdownButtonFormField<int>(
      initialValue: currentValue.clamp(0, options.length - 1),
      decoration: const InputDecoration(
        labelText: 'Direction',
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      items: List.generate(
        options.length,
        (index) => DropdownMenuItem(
          value: index,
          child: Text(options[index]),
        ),
      ),
      onChanged: (value) {
        if (value != null) {
          _updateParameter(directionParam, value);
        }
      },
    );
  }

  Widget _buildStartStepInput(Slot slot) {
    final startStepParam = widget.params.startStep;
    if (startStepParam == null || startStepParam >= slot.parameters.length) {
      return const SizedBox.shrink();
    }

    return TextFormField(
      controller: _startStepController,
      decoration: const InputDecoration(
        labelText: 'Start',
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
      ],
      onChanged: (value) {
        final intValue = int.tryParse(value);
        if (intValue != null && intValue >= 1 && intValue <= 16) {
          _updateParameter(startStepParam, intValue);
        } else if (value.isEmpty) {
          // Allow empty for editing, but don't update
        } else {
          // Invalid value - revert to current
          final current = startStepParam < slot.values.length
              ? slot.values[startStepParam].value
              : 1;
          _startStepController.text = current.toString();
        }
      },
    );
  }

  Widget _buildEndStepInput(Slot slot) {
    final endStepParam = widget.params.endStep;
    if (endStepParam == null || endStepParam >= slot.parameters.length) {
      return const SizedBox.shrink();
    }

    final startStepParam = widget.params.startStep;
    final startValue = startStepParam != null && startStepParam < slot.values.length
        ? slot.values[startStepParam].value
        : 1;

    return TextFormField(
      controller: _endStepController,
      decoration: InputDecoration(
        labelText: 'End',
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        errorText: _getEndStepValidationError(slot),
      ),
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
      ],
      onChanged: (value) {
        final intValue = int.tryParse(value);
        if (intValue != null && intValue >= 1 && intValue <= 16) {
          if (intValue >= startValue) {
            _updateParameter(endStepParam, intValue);
          }
        } else if (value.isEmpty) {
          // Allow empty for editing
        } else {
          // Invalid value - revert to current
          final current = endStepParam < slot.values.length
              ? slot.values[endStepParam].value
              : 16;
          _endStepController.text = current.toString();
        }
      },
    );
  }

  String? _getEndStepValidationError(Slot slot) {
    final endStepParam = widget.params.endStep;
    final startStepParam = widget.params.startStep;

    if (endStepParam == null || startStepParam == null) return null;
    if (endStepParam >= slot.values.length || startStepParam >= slot.values.length) {
      return null;
    }

    final endValue = slot.values[endStepParam].value;
    final startValue = slot.values[startStepParam].value;

    if (endValue < startValue) {
      return 'End must be ≥ Start ($startValue)';
    }

    return null;
  }

  Widget _buildGateLengthSlider(Slot slot) {
    final gateLengthParam = widget.params.gateLength;
    if (gateLengthParam == null || gateLengthParam >= slot.parameters.length) {
      return const SizedBox.shrink();
    }

    final currentValue = gateLengthParam < slot.values.length
        ? slot.values[gateLengthParam].value
        : 50;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Gate Length: $currentValue%',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        Slider(
          value: currentValue.toDouble().clamp(1, 99),
          min: 1,
          max: 99,
          divisions: 98,
          label: '$currentValue%',
          onChanged: (value) {
            _updateParameter(gateLengthParam, value.toInt(), debounce: true);
          },
        ),
      ],
    );
  }

  Widget _buildTriggerLengthSlider(Slot slot) {
    final triggerLengthParam = widget.params.triggerLength;
    if (triggerLengthParam == null || triggerLengthParam >= slot.parameters.length) {
      return const SizedBox.shrink();
    }

    final currentValue = triggerLengthParam < slot.values.length
        ? slot.values[triggerLengthParam].value
        : 10;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Trigger Length: ${currentValue}ms',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        Slider(
          value: currentValue.toDouble().clamp(1, 100),
          min: 1,
          max: 100,
          divisions: 99,
          label: '${currentValue}ms',
          onChanged: (value) {
            _updateParameter(triggerLengthParam, value.toInt(), debounce: true);
          },
        ),
      ],
    );
  }

  Widget _buildGlideTimeSlider(Slot slot) {
    final glideTimeParam = widget.params.glideTime;
    if (glideTimeParam == null || glideTimeParam >= slot.parameters.length) {
      return const SizedBox.shrink();
    }

    final currentValue = glideTimeParam < slot.values.length
        ? slot.values[glideTimeParam].value
        : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Glide Time: ${currentValue}ms',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        Slider(
          value: currentValue.toDouble().clamp(0, 1000),
          min: 0,
          max: 1000,
          divisions: 100,
          label: '${currentValue}ms',
          onChanged: (value) {
            _updateParameter(glideTimeParam, value.toInt(), debounce: true);
          },
        ),
      ],
    );
  }
}
