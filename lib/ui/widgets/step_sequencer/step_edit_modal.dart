import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nt_helper/cubit/disting_cubit.dart';
import 'package:nt_helper/services/scale_quantizer.dart';
import 'package:nt_helper/services/step_sequencer_params.dart';
import 'package:nt_helper/util/parameter_write_debouncer.dart';

/// Modal dialog for editing individual step parameters in the Step Sequencer
class StepEditModal extends StatefulWidget {
  final int slotIndex;
  final int stepIndex; // 0-indexed internally, display as 1-indexed
  final StepSequencerParams params;
  final Slot slot;
  final bool snapEnabled;
  final String selectedScale;
  final int rootNote;

  const StepEditModal({
    super.key,
    required this.slotIndex,
    required this.stepIndex,
    required this.params,
    required this.slot,
    required this.snapEnabled,
    required this.selectedScale,
    required this.rootNote,
  });

  @override
  State<StepEditModal> createState() => _StepEditModalState();
}

class _StepEditModalState extends State<StepEditModal> {
  final _debouncer = ParameterWriteDebouncer();
  final Map<String, int> _copiedParams = {};

  // Local preview values for immediate UI feedback
  late Map<String, int> _previewValues;

  @override
  void initState() {
    super.initState();
    _loadCurrentValues();
  }

  @override
  void dispose() {
    _debouncer.dispose();
    super.dispose();
  }

  void _loadCurrentValues() {
    final step = widget.stepIndex + 1; // Convert to 1-indexed

    _previewValues = {
      'pitch': _getParamValue(widget.params.getPitch(step)),
      'velocity': _getParamValue(widget.params.getVelocity(step)),
      'mod': _getParamValue(widget.params.getMod(step)),
      'division': _getParamValue(widget.params.getDivision(step)),
      'pattern': _getParamValue(widget.params.getPattern(step)),
      'ties': _getParamValue(widget.params.getTies(step)),
      'probability': _getParamValue(widget.params.getProbability(step)),
    };
  }

  int _getParamValue(int? paramIndex) {
    if (paramIndex == null) return 0;
    if (paramIndex >= widget.slot.values.length) return 0;
    return widget.slot.values[paramIndex].value;
  }

  void _updateParameter(String paramKey, int? paramIndex, int value) {
    if (paramIndex == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Parameter $paramKey not available')),
      );
      return;
    }

    // Apply quantization to pitch values if snap is enabled
    int finalValue = value;
    if (paramKey == 'pitch' && widget.snapEnabled) {
      finalValue = ScaleQuantizer.quantize(
        value,
        widget.selectedScale,
        widget.rootNote,
      );
    }

    // Update preview value immediately for smooth UI
    setState(() {
      _previewValues[paramKey] = finalValue;
    });

    // Debounce the actual MIDI write
    _debouncer.schedule('param_$paramKey', () {
      context.read<DistingCubit>().updateParameterValue(
            algorithmIndex: widget.slotIndex,
            parameterNumber: paramIndex,
            value: finalValue,
            userIsChangingTheValue: true,
          );
    }, const Duration(milliseconds: 50));
  }

  void _copyStep() {
    final step = widget.stepIndex + 1;

    _copiedParams.clear();
    _copiedParams.addAll(_previewValues);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Step $step copied')),
    );
  }

  void _pasteStep() {
    if (_copiedParams.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No copied step data')),
      );
      return;
    }

    final step = widget.stepIndex + 1;

    // Update all copied parameters
    _copiedParams.forEach((key, value) {
      int? paramIndex;
      switch (key) {
        case 'pitch':
          paramIndex = widget.params.getPitch(step);
          break;
        case 'velocity':
          paramIndex = widget.params.getVelocity(step);
          break;
        case 'mod':
          paramIndex = widget.params.getMod(step);
          break;
        case 'division':
          paramIndex = widget.params.getDivision(step);
          break;
        case 'pattern':
          paramIndex = widget.params.getPattern(step);
          break;
        case 'ties':
          paramIndex = widget.params.getTies(step);
          break;
        case 'probability':
          paramIndex = widget.params.getProbability(step);
          break;
      }

      if (paramIndex != null) {
        _updateParameter(key, paramIndex, value);
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Pasted to Step $step')),
    );
  }

  Future<void> _clearStep() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Step'),
        content: const Text('Reset all parameters to default values?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final step = widget.stepIndex + 1;

      // Default values
      final defaults = {
        'pitch': 60, // C4
        'velocity': 100,
        'mod': 0,
        'division': 0,
        'pattern': 0,
        'ties': 0,
        'probability': 127, // 100%
      };

      defaults.forEach((key, value) {
        int? paramIndex;
        switch (key) {
          case 'pitch':
            paramIndex = widget.params.getPitch(step);
            break;
          case 'velocity':
            paramIndex = widget.params.getVelocity(step);
            break;
          case 'mod':
            paramIndex = widget.params.getMod(step);
            break;
          case 'division':
            paramIndex = widget.params.getDivision(step);
            break;
          case 'pattern':
            paramIndex = widget.params.getPattern(step);
            break;
          case 'ties':
            paramIndex = widget.params.getTies(step);
            break;
          case 'probability':
            paramIndex = widget.params.getProbability(step);
            break;
        }

        if (paramIndex != null) {
          _updateParameter(key, paramIndex, value);
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Step $step cleared')),
        );
      }
    }
  }

  void _randomizeStep() {
    final step = widget.stepIndex + 1;

    // Generate musical random values
    final random = {
      'pitch': 36 + (DateTime.now().millisecondsSinceEpoch % 61), // C2-C7
      'velocity': 40 + (DateTime.now().millisecondsSinceEpoch % 88), // 40-127
      'mod': DateTime.now().millisecondsSinceEpoch % 128,
      'division': DateTime.now().millisecondsSinceEpoch % 8,
      'pattern': DateTime.now().millisecondsSinceEpoch % 4,
      'ties': DateTime.now().millisecondsSinceEpoch % 2,
      'probability': 64 + (DateTime.now().millisecondsSinceEpoch % 64), // 64-127 (higher probability)
    };

    random.forEach((key, value) {
      int? paramIndex;
      switch (key) {
        case 'pitch':
          paramIndex = widget.params.getPitch(step);
          break;
        case 'velocity':
          paramIndex = widget.params.getVelocity(step);
          break;
        case 'mod':
          paramIndex = widget.params.getMod(step);
          break;
        case 'division':
          paramIndex = widget.params.getDivision(step);
          break;
        case 'pattern':
          paramIndex = widget.params.getPattern(step);
          break;
        case 'ties':
          paramIndex = widget.params.getTies(step);
          break;
        case 'probability':
          paramIndex = widget.params.getProbability(step);
          break;
      }

      if (paramIndex != null) {
        _updateParameter(key, paramIndex, value);
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Step $step randomized')),
    );
  }

  String _midiNoteToName(int midiNote) {
    const notes = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];
    final octave = (midiNote ~/ 12) - 1;
    final note = notes[midiNote % 12];
    return '$note$octave';
  }

  Widget _buildSlider({
    required String label,
    required int value,
    required int min,
    required int max,
    required Function(int) onChanged,
    String? subtitle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
            if (subtitle != null) Text(subtitle, style: const TextStyle(fontSize: 12)),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: Slider(
                value: value.toDouble(),
                min: min.toDouble(),
                max: max.toDouble(),
                divisions: max - min,
                onChanged: (val) => onChanged(val.toInt()),
              ),
            ),
            SizedBox(
              width: 50,
              child: Text(
                value.toString(),
                textAlign: TextAlign.right,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final step = widget.stepIndex + 1;
    final isMobile = MediaQuery.of(context).size.width <= 768;

    final content = SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Text(
              'Edit Step $step',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Primary Parameters
            Text(
              'Primary Parameters',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),

            _buildSlider(
              label: 'Pitch',
              value: _previewValues['pitch']!,
              min: 0,
              max: 127,
              subtitle: _midiNoteToName(_previewValues['pitch']!),
              onChanged: (val) {
                final step = widget.stepIndex + 1;
                _updateParameter('pitch', widget.params.getPitch(step), val);
              },
            ),

            _buildSlider(
              label: 'Velocity',
              value: _previewValues['velocity']!,
              min: 0,
              max: 127,
              onChanged: (val) {
                final step = widget.stepIndex + 1;
                _updateParameter('velocity', widget.params.getVelocity(step), val);
              },
            ),

            _buildSlider(
              label: 'Mod',
              value: _previewValues['mod']!,
              min: 0,
              max: 127,
              onChanged: (val) {
                final step = widget.stepIndex + 1;
                _updateParameter('mod', widget.params.getMod(step), val);
              },
            ),

            const Divider(height: 32),

            // Advanced Parameters
            Text(
              'Advanced Parameters',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),

            _buildSlider(
              label: 'Division',
              value: _previewValues['division']!,
              min: 0,
              max: 16,
              onChanged: (val) {
                final step = widget.stepIndex + 1;
                _updateParameter('division', widget.params.getDivision(step), val);
              },
            ),

            _buildSlider(
              label: 'Pattern',
              value: _previewValues['pattern']!,
              min: 0,
              max: 15,
              onChanged: (val) {
                final step = widget.stepIndex + 1;
                _updateParameter('pattern', widget.params.getPattern(step), val);
              },
            ),

            _buildSlider(
              label: 'Ties',
              value: _previewValues['ties']!,
              min: 0,
              max: 1,
              onChanged: (val) {
                final step = widget.stepIndex + 1;
                _updateParameter('ties', widget.params.getTies(step), val);
              },
            ),

            _buildSlider(
              label: 'Probability',
              value: _previewValues['probability']!,
              min: 0,
              max: 127,
              onChanged: (val) {
                final step = widget.stepIndex + 1;
                _updateParameter('probability', widget.params.getProbability(step), val);
              },
            ),

            const SizedBox(height: 24),

            // Action Buttons
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _copyStep,
                  icon: const Icon(Icons.copy),
                  label: const Text('Copy'),
                ),
                ElevatedButton.icon(
                  onPressed: _pasteStep,
                  icon: const Icon(Icons.paste),
                  label: const Text('Paste'),
                ),
                ElevatedButton.icon(
                  onPressed: _clearStep,
                  icon: const Icon(Icons.clear),
                  label: const Text('Clear'),
                ),
                ElevatedButton.icon(
                  onPressed: _randomizeStep,
                  icon: const Icon(Icons.shuffle),
                  label: const Text('Randomize'),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Close Button
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );

    // Return different layouts based on platform
    if (isMobile) {
      return content;
    } else {
      return Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600, maxHeight: 800),
          child: content,
        ),
      );
    }
  }
}
