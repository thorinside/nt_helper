import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nt_helper/cubit/disting_cubit.dart';
import 'package:nt_helper/models/packed_mapping_data.dart';
import 'package:nt_helper/ui/midi_listener/midi_detector_widget.dart';
import 'package:nt_helper/ui/midi_listener/midi_listener_cubit.dart'; // Import for MidiEventType

class PackedMappingDataEditor extends StatefulWidget {
  final PackedMappingData initialData;
  final Future<void> Function(PackedMappingData) onSave;
  final List<Slot> slots;
  final int algorithmIndex;
  final int parameterNumber;

  const PackedMappingDataEditor({
    super.key,
    required this.initialData,
    required this.onSave,
    required this.slots,
    required this.algorithmIndex,
    required this.parameterNumber,
  });

  @override
  PackedMappingDataEditorState createState() => PackedMappingDataEditorState();
}

class PackedMappingDataEditorState extends State<PackedMappingDataEditor>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // We'll keep a local copy of the data that we can edit
  late PackedMappingData _data;

  // Controllers for numeric TextFields:
  late TextEditingController _voltsController;
  late TextEditingController _deltaController;

  // MIDI
  late TextEditingController _midiCcController;
  late TextEditingController _midiMinController;
  late TextEditingController _midiMaxController;

  // I2C
  late TextEditingController _i2cCcController;
  late TextEditingController _i2cMinController;
  late TextEditingController _i2cMaxController;

  // Debounce timer for optimistic saves
  Timer? _debounceTimer;
  static const _maxRetries = 3;
  static const _debounceDuration = Duration(seconds: 1);

  // Dirty state tracking
  bool _isDirty = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    _data = widget.initialData;

    // Decide which tab should be displayed first.
    int initialIndex;
    if (_data.cvInput != 0) {
      // CV is in use
      initialIndex = 0;
    } else if (_data.isMidiEnabled) {
      // MIDI is in use
      initialIndex = 1;
    } else if (_data.isI2cEnabled) {
      // I2C is in use
      initialIndex = 2;
    } else if (_data.perfPageIndex > 0) {
      // Performance page is assigned
      initialIndex = 3;
    } else {
      // No CV, MIDI, I2C, or Performance in use, default to CV tab
      initialIndex = 0;
    }

    // Create the TabController with initialIndex set to the matching page.
    _tabController = TabController(
      length: 4,
      vsync: this,
      initialIndex: initialIndex,
    );

    // Initialize controllers with the existing data
    _voltsController = TextEditingController(text: _data.volts.toString());
    _deltaController = TextEditingController(text: _data.delta.toString());
    _midiCcController = TextEditingController(text: _data.midiCC.toString());
    _midiMinController = TextEditingController(text: _data.midiMin.toString());
    _midiMaxController = TextEditingController(text: _data.midiMax.toString());
    _i2cCcController = TextEditingController(text: _data.i2cCC.toString());
    _i2cMinController = TextEditingController(text: _data.i2cMin.toString());
    _i2cMaxController = TextEditingController(text: _data.i2cMax.toString());
  }

  @override
  void dispose() {
    // Flush pending save synchronously (widget is disposing)
    if (_debounceTimer != null && _debounceTimer!.isActive) {
      _debounceTimer?.cancel();
      _performSaveSync();
    }
    _tabController.dispose();

    // Dispose controllers
    _voltsController.dispose();
    _deltaController.dispose();
    _midiCcController.dispose();
    _midiMinController.dispose();
    _midiMaxController.dispose();
    _i2cCcController.dispose();
    _i2cMinController.dispose();
    _i2cMaxController.dispose();

    super.dispose();
  }

  void _triggerOptimisticSave() {
    setState(() {
      _isDirty = true;
      _isSaving = false;
    });
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDuration, () {
      setState(() {
        _isSaving = true;
      });
      _attemptSave();
    });
  }

  // Synchronous save for disposal - no setState calls
  void _performSaveSync() {
    // Update data from controllers without calling setState
    final volts = int.tryParse(_voltsController.text) ?? _data.volts;
    final delta = int.tryParse(_deltaController.text) ?? _data.delta;
    final midiCC = int.tryParse(_midiCcController.text) ?? _data.midiCC;
    final midiMin = int.tryParse(_midiMinController.text) ?? _data.midiMin;
    final midiMax = int.tryParse(_midiMaxController.text) ?? _data.midiMax;
    final i2cCC = int.tryParse(_i2cCcController.text) ?? _data.i2cCC;
    final i2cMin = int.tryParse(_i2cMinController.text) ?? _data.i2cMin;
    final i2cMax = int.tryParse(_i2cMaxController.text) ?? _data.i2cMax;

    _data = _data.copyWith(
      volts: volts,
      delta: delta,
      midiCC: midiCC,
      midiMin: midiMin,
      midiMax: midiMax,
      i2cCC: i2cCC,
      i2cMin: i2cMin,
      i2cMax: i2cMax,
    );

    widget.onSave(_data);
  }

  Future<void> _attemptSave({int attempt = 0}) async {
    try {
      _updateVoltsFromController();
      _updateDeltaFromController();
      _updateMidiCcFromController();
      _updateMidiMinFromController();
      _updateMidiMaxFromController();
      _updateI2cCcFromController();
      _updateI2cMinFromController();
      _updateI2cMaxFromController();

      await widget.onSave(_data);

      if (mounted) {
        setState(() {
          _isDirty = false;
          _isSaving = false;
        });
      }
    } catch (e) {
      if (attempt < _maxRetries) {
        final delay = Duration(milliseconds: 100 * (1 << attempt));
        await Future.delayed(delay);
        await _attemptSave(attempt: attempt + 1);
      } else {
        // Silent failure after max retries - reset state
        if (mounted) {
          setState(() {
            _isSaving = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 450, // keep the bottom sheet from being too tall
      child: Column(
        children: [
          Stack(
            children: [
              TabBar(
                controller: _tabController,
                labelColor: Theme.of(context).colorScheme.onSurface,
                unselectedLabelColor: Theme.of(
                  context,
                ).colorScheme.onSurface.withAlpha(64),
                tabs: const [
                  Tab(text: 'CV'),
                  Tab(text: 'MIDI'),
                  Tab(text: 'I2C'),
                  Tab(text: 'Performance'),
                ],
              ),
              if (_isDirty || _isSaving)
                Positioned(
                  right: 16,
                  top: 8,
                  child: Tooltip(
                    message: _isSaving
                        ? 'Saving...'
                        : 'Unsaved changes',
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isSaving
                            ? Colors.blue
                            : Colors.amber,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildCvEditor(),
                _buildMidiEditor(),
                _buildI2cEditor(),
                _buildPerformanceEditor(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// ---------------------
  /// CV Editor
  /// ---------------------
  Widget _buildCvEditor() {
    // Safely clamp the current CV input to 0..12 for display
    final cvInputValue = (_data.cvInput >= 0 && _data.cvInput <= 29)
        ? _data.cvInput
        : 0;

    // Safely clamp the source value for the dropdown
    final sourceValue = (_data.source >= 0 && _data.source <= 33)
        ? _data.source
        : 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: SafeArea(
        child: Column(
          children: [
            // Source Dropdown
            SizedBox(
              width: double.infinity,
              child: DropdownMenu<int>(
                initialSelection: sourceValue,
                requestFocusOnTap: false,
                label: const Text('Source'),
                onSelected: (newValue) {
                  if (newValue == null) return;
                  setState(() {
                    _data = _data.copyWith(source: newValue);
                  });
                  _triggerOptimisticSave();
                },
                dropdownMenuEntries: List.generate(34, (index) {
                  if (index == 0) {
                    return const DropdownMenuEntry<int>(
                      value: 0,
                      label: 'Own inputs',
                    );
                  } else if (index == 1) {
                    return const DropdownMenuEntry<int>(
                      value: 1,
                      label: 'Module inputs',
                    );
                  } else {
                    // index 2..33 correspond to slots 1..32
                    final slotNumber = index - 1;
                    String label = 'Slot $slotNumber'; // Default label
                    // Check if a slot exists at this index (0-based)
                    if (slotNumber - 1 >= 0 &&
                        slotNumber - 1 < widget.slots.length) {
                      final slot = widget.slots[slotNumber - 1];
                      // Use algorithm name if available
                      label = 'Slot $slotNumber: ${slot.algorithm.name}';
                    }

                    return DropdownMenuEntry<int>(value: index, label: label);
                  }
                }),
              ),
            ),
            const SizedBox(height: 12),
            // Material 3 DropdownMenu for CV Input, filling width and removing redundant labels
            SizedBox(
              width: double.infinity,
              child: DropdownMenu<int>(
                initialSelection: cvInputValue,
                requestFocusOnTap: false,
                label: Text('CV Input'), // optional text if you want a hint
                onSelected: (newValue) {
                  if (newValue == null) return;
                  setState(() {
                    _data = _data.copyWith(cvInput: newValue);
                  });
                  _triggerOptimisticSave();
                },
                dropdownMenuEntries: List.generate(29, (index) {
                  if (index == 0) {
                    return const DropdownMenuEntry<int>(
                      value: 0,
                      label: 'None',
                    );
                  } else if (index >= 1 && index <= 12) {
                    return DropdownMenuEntry<int>(
                      value: index,
                      label: 'Input $index',
                    );
                  } else if (index >= 13 && index <= 20) {
                    return DropdownMenuEntry<int>(
                      value: index,
                      label: 'Output ${index - 12}',
                    );
                  } else {
                    return DropdownMenuEntry<int>(
                      value: index,
                      label: 'Aux ${index - 20}',
                    );
                  }
                }),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('Unipolar'),
                Switch(
                  value: _data.isUnipolar,
                  onChanged: (val) {
                    setState(() {
                      _data = _data.copyWith(isUnipolar: val);
                    });
                    _triggerOptimisticSave();
                  },
                ),
              ],
            ),
            Row(
              children: [
                const Text('Gate'),
                Switch(
                  value: _data.isGate,
                  onChanged: (val) {
                    setState(() {
                      _data = _data.copyWith(isGate: val);
                    });
                    _triggerOptimisticSave();
                  },
                ),
              ],
            ),
            _buildNumericField(
              label: 'Volts',
              controller: _voltsController,
              onSubmit: _updateVoltsFromController,
              onChanged: () {
                _updateVoltsFromController();
                _triggerOptimisticSave();
              },
            ),
            _buildNumericField(
              label: 'Delta',
              controller: _deltaController,
              onSubmit: _updateDeltaFromController,
              onChanged: () {
                _updateDeltaFromController();
                _triggerOptimisticSave();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _updateVoltsFromController() {
    final parsed = int.tryParse(_voltsController.text) ?? _data.volts;
    setState(() {
      _data = _data.copyWith(volts: parsed);
      _voltsController.text = _data.volts.toString();
    });
  }

  void _updateDeltaFromController() {
    final parsed = int.tryParse(_deltaController.text) ?? _data.delta;
    setState(() {
      _data = _data.copyWith(delta: parsed);
      _deltaController.text = _data.delta.toString();
    });
  }

  /// ---------------------
  /// MIDI Editor
  /// ---------------------
  Widget _buildMidiEditor() {
    // Safely clamp the current MIDI channel to 0..15
    final midiChannelValue = (_data.midiChannel >= 0 && _data.midiChannel <= 15)
        ? _data.midiChannel
        : 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        children: [
          // Material 3 DropdownMenu for MIDI Channel
          SizedBox(
            width: double.infinity,
            child: DropdownMenu<int>(
              initialSelection: midiChannelValue,
              requestFocusOnTap: false,
              label: Text("MIDI Channel"),
              onSelected: (newValue) {
                if (newValue == null) return;
                setState(() {
                  _data = _data.copyWith(midiChannel: newValue);
                });
                _triggerOptimisticSave();
              },
              dropdownMenuEntries: List.generate(16, (index) {
                // 0..15 = Ch 1..16
                return DropdownMenuEntry<int>(
                  value: index,
                  label: 'Ch ${index + 1}',
                );
              }),
            ),
          ),
          const SizedBox(height: 12),
          // MIDI Mapping Type Dropdown
          SizedBox(
            width: double.infinity,
            child: DropdownMenu<MidiMappingType>(
              initialSelection: _data.midiMappingType,
              requestFocusOnTap: false,
              label: const Text("MIDI Type"),
              onSelected: (newValue) {
                if (newValue == null) return;
                setState(() {
                  _data = _data.copyWith(midiMappingType: newValue);
                  // If type is not CC, disable relative
                  if (newValue != MidiMappingType.cc) {
                    _data = _data.copyWith(isMidiRelative: false);
                  }
                });
                _triggerOptimisticSave();
              },
              dropdownMenuEntries: const [
                DropdownMenuEntry<MidiMappingType>(
                  value: MidiMappingType.cc,
                  label: 'CC',
                ),
                DropdownMenuEntry<MidiMappingType>(
                  value: MidiMappingType.noteMomentary,
                  label: 'Note - Momentary',
                ),
                DropdownMenuEntry<MidiMappingType>(
                  value: MidiMappingType.noteToggle,
                  label: 'Note - Toggle',
                ),
                DropdownMenuEntry<MidiMappingType>(
                  value: MidiMappingType.cc14BitLow,
                  label: '14 bit CC - low',
                ),
                DropdownMenuEntry<MidiMappingType>(
                  value: MidiMappingType.cc14BitHigh,
                  label: '14 bit CC - high',
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _buildNumericField(
            label: 'MIDI CC / Note (0–128)',
            controller: _midiCcController,
            onSubmit: _updateMidiCcFromController,
            onChanged: () {
              _updateMidiCcFromController();
              _triggerOptimisticSave();
            },
          ),
          Row(
            children: [
              const Text('MIDI Enabled'),
              Switch(
                value: _data.isMidiEnabled,
                onChanged: (val) {
                  setState(() {
                    _data = _data.copyWith(isMidiEnabled: val);
                  });
                  _triggerOptimisticSave();
                },
              ),
            ],
          ),
          Row(
            children: [
              const Text('MIDI Symmetric'),
              Switch(
                value: _data.isMidiSymmetric,
                onChanged: (val) {
                  setState(() {
                    _data = _data.copyWith(isMidiSymmetric: val);
                  });
                  _triggerOptimisticSave();
                },
              ),
            ],
          ),
          Row(
            children: [
              const Text('MIDI Relative'),
              Switch(
                value: _data.isMidiRelative,
                onChanged: _data.midiMappingType == MidiMappingType.cc
                    ? (val) {
                        setState(() {
                          _data = _data.copyWith(isMidiRelative: val);
                        });
                        _triggerOptimisticSave();
                      }
                    : null,
              ),
            ],
          ),
          if (_data.midiMappingType != MidiMappingType.cc)
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Text(
                '(N/A for Notes and 14-bit CC)',
                style: TextStyle(
                  color: Theme.of(context).disabledColor,
                  fontSize: Theme.of(context).textTheme.bodySmall?.fontSize,
                ),
              ),
            ),
          _buildNumericField(
            label: 'MIDI Min',
            controller: _midiMinController,
            onSubmit: _updateMidiMinFromController,
            onChanged: () {
              _updateMidiMinFromController();
              _triggerOptimisticSave();
            },
            signed: true,
          ),
          _buildNumericField(
            label: 'MIDI Max',
            controller: _midiMaxController,
            onSubmit: _updateMidiMaxFromController,
            onChanged: () {
              _updateMidiMaxFromController();
              _triggerOptimisticSave();
            },
            signed: true,
          ),
          // Add the MIDI Detector
          MidiDetectorWidget(
            onMidiEventFound:
                ({
                  required MidiEventType type,
                  required channel,
                  required number,
                }) {
                  // When we've detected 10 consecutive hits of the same CC,
                  // automatically fill in the CC number, and midi channel in your form data
                  // and assume we want to enable the midi mapping.
                  setState(() {
                    // Default to CC type, adjust if it's a note
                    MidiMappingType detectedMappingType = MidiMappingType.cc;
                    if (type == MidiEventType.noteOn ||
                        type == MidiEventType.noteOff) {
                      if (_data.midiMappingType !=
                              MidiMappingType.noteMomentary &&
                          _data.midiMappingType != MidiMappingType.noteToggle) {
                        detectedMappingType = MidiMappingType.noteMomentary;
                      } else {
                        // Keep the existing note type if it was already set to one
                        detectedMappingType = _data.midiMappingType;
                      }
                    }

                    _data = _data.copyWith(
                      midiMappingType: detectedMappingType,
                      midiCC: number, // Use 'number' which is CC or Note
                      midiChannel: channel,
                      isMidiEnabled: true,
                    );
                  });
                  // Also update the text field / controller if necessary
                  _midiCcController.text = number.toString();
                },
          ),
        ],
      ),
    );
  }

  void _updateMidiCcFromController() {
    final parsed = int.tryParse(_midiCcController.text) ?? _data.midiCC;
    final clamped = parsed.clamp(0, 128);
    setState(() {
      _data = _data.copyWith(midiCC: clamped);
      _midiCcController.text = _data.midiCC.toString();
    });
  }

  void _updateMidiMinFromController() {
    final parsed = int.tryParse(_midiMinController.text) ?? _data.midiMin;
    final clamped = parsed.clamp(-32768, 32767);
    setState(() {
      _data = _data.copyWith(midiMin: clamped);
      _midiMinController.text = _data.midiMin.toString();
    });
  }

  void _updateMidiMaxFromController() {
    final parsed = int.tryParse(_midiMaxController.text) ?? _data.midiMax;
    final clamped = parsed.clamp(-32768, 32767);
    setState(() {
      _data = _data.copyWith(midiMax: clamped);
      _midiMaxController.text = _data.midiMax.toString();
    });
  }

  /// ---------------------
  /// I2C Editor
  /// ---------------------
  Widget _buildI2cEditor() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        children: [
          _buildNumericField(
            label: 'I2C CC',
            controller: _i2cCcController,
            onSubmit: _updateI2cCcFromController,
            onChanged: () {
              _updateI2cCcFromController();
              _triggerOptimisticSave();
            },
          ),
          Row(
            children: [
              const Text('I2C Enabled'),
              Switch(
                value: _data.isI2cEnabled,
                onChanged: (val) {
                  setState(() {
                    _data = _data.copyWith(isI2cEnabled: val);
                  });
                  _triggerOptimisticSave();
                },
              ),
            ],
          ),
          Row(
            children: [
              const Text('I2C Symmetric'),
              Switch(
                value: _data.isI2cSymmetric,
                onChanged: (val) {
                  setState(() {
                    _data = _data.copyWith(isI2cSymmetric: val);
                  });
                  _triggerOptimisticSave();
                },
              ),
            ],
          ),
          _buildNumericField(
            label: 'I2C Min',
            controller: _i2cMinController,
            onSubmit: _updateI2cMinFromController,
            onChanged: () {
              _updateI2cMinFromController();
              _triggerOptimisticSave();
            },
            signed: true,
          ),
          _buildNumericField(
            label: 'I2C Max',
            controller: _i2cMaxController,
            onSubmit: _updateI2cMaxFromController,
            onChanged: () {
              _updateI2cMaxFromController();
              _triggerOptimisticSave();
            },
            signed: true,
          ),
        ],
      ),
    );
  }

  void _updateI2cCcFromController() {
    final parsed = int.tryParse(_i2cCcController.text) ?? _data.i2cCC;
    setState(() {
      _data = _data.copyWith(i2cCC: parsed);
      _i2cCcController.text = _data.i2cCC.toString();
    });
  }

  void _updateI2cMinFromController() {
    final parsed = int.tryParse(_i2cMinController.text) ?? _data.i2cMin;
    setState(() {
      _data = _data.copyWith(i2cMin: parsed);
      _i2cMinController.text = _data.i2cMin.toString();
    });
  }

  void _updateI2cMaxFromController() {
    final parsed = int.tryParse(_i2cMaxController.text) ?? _data.i2cMax;
    setState(() {
      _data = _data.copyWith(i2cMax: parsed);
      _i2cMaxController.text = _data.i2cMax.toString();
    });
  }

  /// ---------------------
  /// Performance Editor
  /// ---------------------
  Widget _buildPerformanceEditor() {
    return BlocBuilder<DistingCubit, DistingState>(
      builder: (context, state) {
        if (state is! DistingStateSynchronized) {
          return const Center(child: Text('Not synchronized'));
        }

        final slot = state.slots[widget.algorithmIndex];
        final currentPerfPageIndex =
            slot.mappings[widget.parameterNumber].packedMappingData.perfPageIndex;

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info text explaining performance pages
              Text(
                'Assign this parameter to a performance page for quick access.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
              const SizedBox(height: 16),

              // Performance page dropdown
              DropdownMenu<int>(
                initialSelection: currentPerfPageIndex,
                label: const Text('Performance Page'),
                expandedInsets: EdgeInsets.zero,
                dropdownMenuEntries: [
                  // "None" option
                  const DropdownMenuEntry<int>(
                    value: 0,
                    label: 'None',
                  ),
                  // P1 through P15
                  for (int i = 1; i <= 15; i++)
                    DropdownMenuEntry<int>(
                      value: i,
                      label: 'P$i',
                      leadingIcon: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getPageColor(i),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'P$i',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
                onSelected: (newValue) {
                  if (newValue == null) return;
                  // Call cubit directly - SAME AS INLINE DROPDOWN
                  context.read<DistingCubit>().setPerformancePageMapping(
                        widget.algorithmIndex,
                        widget.parameterNumber,
                        newValue,
                      );
                },
              ),

              const SizedBox(height: 16),

              // Help text
              Text(
                currentPerfPageIndex == 0
                    ? 'Not assigned to any performance page'
                    : 'Assigned to Performance Page $currentPerfPageIndex',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[700],
                      fontStyle: FontStyle.italic,
                    ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Helper method to get color for page badges (matches section_parameter_list_view.dart and performance_screen.dart)
  Color _getPageColor(int pageIndex) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
    ];
    return colors[(pageIndex - 1) % colors.length];
  }

  /// ---------------------
  /// Helpers
  /// ---------------------
  /// Builds a labeled numeric TextField that calls [onSubmit]
  /// when the user presses the "done" button on the keyboard
  Widget _buildNumericField({
    required String label,
    required TextEditingController controller,
    required VoidCallback onSubmit,
    VoidCallback? onChanged,
    bool signed = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: TextField(
        keyboardType: signed
            ? const TextInputType.numberWithOptions(signed: true)
            : TextInputType.number,
        textInputAction: TextInputAction.done,
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        onSubmitted: (_) => onSubmit(),
        onChanged: onChanged != null ? (_) => onChanged() : null,
      ),
    );
  }
}
