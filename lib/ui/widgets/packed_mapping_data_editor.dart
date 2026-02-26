import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nt_helper/core/routing/bus_spec.dart';
import 'package:nt_helper/cubit/disting_cubit.dart';
import 'package:nt_helper/models/packed_mapping_data.dart';
import 'package:nt_helper/ui/midi_listener/midi_detector_widget.dart';
import 'package:nt_helper/ui/midi_listener/midi_listener_cubit.dart';

class PackedMappingDataEditor extends StatefulWidget {
  final PackedMappingData initialData;
  final Future<void> Function(PackedMappingData) onSave;
  final List<Slot> slots;
  final int algorithmIndex;
  final int parameterNumber;
  final int parameterMin;
  final int parameterMax;
  final int powerOfTen;
  final String? unitString;

  const PackedMappingDataEditor({
    super.key,
    required this.initialData,
    required this.onSave,
    required this.slots,
    required this.algorithmIndex,
    required this.parameterNumber,
    required this.parameterMin,
    required this.parameterMax,
    required this.powerOfTen,
    this.unitString,
  });

  @override
  PackedMappingDataEditorState createState() => PackedMappingDataEditorState();
}

class PackedMappingDataEditorState extends State<PackedMappingDataEditor>
    with SingleTickerProviderStateMixin {
  static int? _lastTabIndex;

  late TabController _tabController;

  // We'll keep a local copy of the data that we can edit
  late PackedMappingData _data;

  // CV range state (replaces volts/delta text controllers)
  late int _cvRangeMin;
  late int _cvRangeMax;

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

  // Parameter value preview during range slider drag
  DateTime? _lastPreviewSent;
  static const _previewThrottleDuration = Duration(milliseconds: 100);

  @override
  void initState() {
    super.initState();

    _data = widget.initialData;

    // Auto-default MIDI min/max to the full parameter range for new mappings
    final bool isNewMidiMapping =
        (_data.midiMin == 0 && _data.midiMax == 0 && !_data.isMidiEnabled) ||
        (_data.midiMin == -1 && _data.midiMax == -1);
    if (isNewMidiMapping && widget.parameterMin < widget.parameterMax) {
      _data = _data.copyWith(
        midiMin: widget.parameterMin,
        midiMax: widget.parameterMax,
      );
    }

    // Auto-default I2C min/max to the full parameter range for new mappings
    final bool isNewI2cMapping =
        (_data.i2cMin == 0 && _data.i2cMax == 0 && !_data.isI2cEnabled) ||
        (_data.i2cMin == -1 && _data.i2cMax == -1);
    if (isNewI2cMapping && widget.parameterMin < widget.parameterMax) {
      _data = _data.copyWith(
        i2cMin: widget.parameterMin,
        i2cMax: widget.parameterMax,
      );
    }

    // Auto-default CV range for new mappings
    final bool isNewCvMapping = (_data.volts == -1) ||
        (_data.volts == 0 && _data.delta == 0);
    if (isNewCvMapping && widget.parameterMin < widget.parameterMax) {
      _cvRangeMin = widget.parameterMin;
      _cvRangeMax = widget.parameterMax;
      final depth = widget.parameterMax - widget.parameterMin;
      _data = _data.copyWith(volts: 5, delta: depth);
    } else {
      // Derive range from existing volts/delta
      final depth = _data.isUnipolar
          ? _data.delta
          : _data.delta * 2;
      _cvRangeMin = widget.parameterMin;
      _cvRangeMax = (widget.parameterMin + depth)
          .clamp(widget.parameterMin, widget.parameterMax);
    }

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
      // No mapping configured — use last selected tab if available
      initialIndex = _lastTabIndex ?? 0;
    }

    // Create the TabController with initialIndex set to the matching page.
    _tabController = TabController(
      length: 4,
      vsync: this,
      initialIndex: initialIndex,
    );
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _lastTabIndex = _tabController.index;
      }
    });

    // Initialize controllers with the existing data
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
    _midiCcController.dispose();
    _midiMinController.dispose();
    _midiMaxController.dispose();
    _i2cCcController.dispose();
    _i2cMinController.dispose();
    _i2cMaxController.dispose();

    super.dispose();
  }

  void _previewParameterValue(int value) {
    final now = DateTime.now();
    if (_lastPreviewSent == null ||
        now.difference(_lastPreviewSent!) > _previewThrottleDuration) {
      _lastPreviewSent = now;
      context.read<DistingCubit>().updateParameterValue(
            algorithmIndex: widget.algorithmIndex,
            parameterNumber: widget.parameterNumber,
            value: value,
            userIsChangingTheValue: true,
          );
    }
  }

  void _restoreParameterValue() {
    final state = context.read<DistingCubit>().state;
    if (state is DistingStateSynchronized) {
      final currentValue = state
          .slots[widget.algorithmIndex].values[widget.parameterNumber].value;
      context.read<DistingCubit>().updateParameterValue(
            algorithmIndex: widget.algorithmIndex,
            parameterNumber: widget.parameterNumber,
            value: currentValue,
            userIsChangingTheValue: false,
          );
    }
  }

  void _triggerOptimisticSave({bool force = false}) {
    setState(() {
      _isDirty = true;
      _isSaving = force;
    });
    _debounceTimer?.cancel();
    if (force) {
      _attemptSave();
    } else {
      _debounceTimer = Timer(_debounceDuration, () {
        setState(() {
          _isSaving = true;
        });
        _attemptSave();
      });
    }
  }

  // Synchronous save for disposal - no setState calls
  void _performSaveSync() {
    // Update data from controllers without calling setState
    final midiCC = int.tryParse(_midiCcController.text) ?? _data.midiCC;
    final midiMin = int.tryParse(_midiMinController.text) ?? _data.midiMin;
    final midiMax = int.tryParse(_midiMaxController.text) ?? _data.midiMax;
    final i2cCC = int.tryParse(_i2cCcController.text) ?? _data.i2cCC;
    final i2cMin = int.tryParse(_i2cMinController.text) ?? _data.i2cMin;
    final i2cMax = int.tryParse(_i2cMaxController.text) ?? _data.i2cMax;

    _data = _data.copyWith(
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
        SemanticsService.sendAnnouncement(
          View.of(context), 'Changes saved', TextDirection.ltr,
        );
      }
    } catch (e) {
      if (attempt < _maxRetries) {
        final delay = Duration(milliseconds: 100 * (1 << attempt));
        await Future.delayed(delay);
        await _attemptSave(attempt: attempt + 1);
      } else {
        if (mounted) {
          setState(() {
            _isSaving = false;
          });
          SemanticsService.sendAnnouncement(
            View.of(context), 'Failed to save changes', TextDirection.ltr,
          );
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
                  left: 16,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: Semantics(
                      liveRegion: true,
                      label: _isSaving ? 'Saving changes' : 'Unsaved changes',
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
    final state = context.read<DistingCubit>().state;
    final hasExtendedAuxBuses = state is DistingStateSynchronized
        ? state.firmwareVersion.hasExtendedAuxBuses
        : false;
    final auxMax = BusSpec.auxMaxForFirmware(hasExtendedAuxBuses: hasExtendedAuxBuses);

    // Safely clamp the current CV input to valid range for display
    final cvInputValue = (_data.cvInput >= 0 && _data.cvInput <= auxMax)
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
                dropdownMenuEntries: List.generate(auxMax + 1, (index) {
                  if (index == 0) {
                    return const DropdownMenuEntry<int>(
                      value: 0,
                      label: 'None',
                    );
                  } else if (index <= BusSpec.inputMax) {
                    return DropdownMenuEntry<int>(
                      value: index,
                      label: 'Input $index',
                    );
                  } else if (index <= BusSpec.outputMax) {
                    return DropdownMenuEntry<int>(
                      value: index,
                      label: 'Output ${index - BusSpec.inputMax}',
                    );
                  } else {
                    return DropdownMenuEntry<int>(
                      value: index,
                      label: 'Aux ${index - BusSpec.outputMax}',
                    );
                  }
                }),
              ),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              title: const Text('Unipolar'),
              value: _data.isUnipolar,
              dense: true,
              contentPadding: EdgeInsets.zero,
              onChanged: (val) {
                setState(() {
                  _data = _data.copyWith(isUnipolar: val);
                  final depth = val ? _data.delta : _data.delta * 2;
                  _cvRangeMin = widget.parameterMin;
                  _cvRangeMax = (widget.parameterMin + depth)
                      .clamp(widget.parameterMin, widget.parameterMax);
                });
                _triggerOptimisticSave();
              },
            ),
            SwitchListTile(
              title: const Text('Gate'),
              value: _data.isGate,
              dense: true,
              contentPadding: EdgeInsets.zero,
              onChanged: (val) {
                setState(() {
                  _data = _data.copyWith(isGate: val);
                });
                _triggerOptimisticSave();
              },
            ),
            Row(
              children: [
                const Text('CV Voltage'),
                Expanded(
                  child: Slider(
                    value: _data.volts.clamp(1, 10).toDouble(),
                    min: 1,
                    max: 10,
                    divisions: 9,
                    label: '${_data.volts.clamp(1, 10)}V',
                    onChanged: (val) {
                      setState(() {
                        _data = _data.copyWith(volts: val.round());
                      });
                      _triggerOptimisticSave();
                    },
                  ),
                ),
                Text('${_data.volts.clamp(1, 10)}V'),
              ],
            ),
            _buildRangeSlider(
              minValue: _cvRangeMin,
              maxValue: _cvRangeMax,
              onChanged: (rawMin, rawMax) {
                final previousMin = _cvRangeMin;
                setState(() {
                  _cvRangeMin = rawMin;
                  _cvRangeMax = rawMax;
                  final depth = rawMax - rawMin;
                  final delta = _data.isUnipolar ? depth : depth ~/ 2;
                  _data = _data.copyWith(delta: delta);
                });
                _triggerOptimisticSave();
                final previewValue =
                    (rawMin != previousMin) ? rawMin : rawMax;
                _previewParameterValue(previewValue);
              },
              onChangeEnd: (_, _) {
                _restoreParameterValue();
              },
            ),
          ],
        ),
      ),
    );
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
            onChanged: _triggerOptimisticSave,
          ),
          SwitchListTile(
            title: const Text('MIDI Enabled'),
            value: _data.isMidiEnabled,
            dense: true,
            contentPadding: EdgeInsets.zero,
            onChanged: (val) {
              setState(() {
                _data = _data.copyWith(isMidiEnabled: val);
              });
              _triggerOptimisticSave();
            },
          ),
          SwitchListTile(
            title: const Text('MIDI Symmetric'),
            value: _data.isMidiSymmetric,
            dense: true,
            contentPadding: EdgeInsets.zero,
            onChanged: (val) {
              setState(() {
                _data = _data.copyWith(isMidiSymmetric: val);
              });
              _triggerOptimisticSave();
            },
          ),
          SwitchListTile(
            title: const Text('MIDI Relative'),
            value: _data.isMidiRelative,
            dense: true,
            contentPadding: EdgeInsets.zero,
            onChanged: _data.midiMappingType == MidiMappingType.cc
                ? (val) {
                    setState(() {
                      _data = _data.copyWith(isMidiRelative: val);
                    });
                    _triggerOptimisticSave();
                  }
                : null,
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
          _buildRangeSlider(
            minValue: _data.midiMin,
            maxValue: _data.midiMax,
            onChanged: (rawMin, rawMax) {
              final previousMin = _data.midiMin;
              setState(() {
                _data = _data.copyWith(midiMin: rawMin, midiMax: rawMax);
                _midiMinController.text = rawMin.toString();
                _midiMaxController.text = rawMax.toString();
              });
              _triggerOptimisticSave();
              // Preview whichever thumb moved
              final previewValue =
                  (rawMin != previousMin) ? rawMin : rawMax;
              _previewParameterValue(previewValue);
            },
            onChangeEnd: (_, _) {
              _restoreParameterValue();
            },
          ),
          // Add the MIDI Detector
          MidiDetectorWidget(
            onMidiEventFound:
                ({
                  required MidiEventType type,
                  required channel,
                  required number,
                }) {
                  // Determine the mapping type from the detected event type
                  MidiMappingType detectedMappingType = MidiMappingType.cc;
                  if (type == MidiEventType.noteOn ||
                      type == MidiEventType.noteOff) {
                    if (_data.midiMappingType !=
                            MidiMappingType.noteMomentary &&
                        _data.midiMappingType != MidiMappingType.noteToggle) {
                      detectedMappingType = MidiMappingType.noteMomentary;
                    } else {
                      detectedMappingType = _data.midiMappingType;
                    }
                  } else if (type == MidiEventType.cc14BitLowFirst) {
                    detectedMappingType = MidiMappingType.cc14BitLow;
                  } else if (type == MidiEventType.cc14BitHighFirst) {
                    detectedMappingType = MidiMappingType.cc14BitHigh;
                  }

                  // Skip save if nothing actually changed
                  if (_data.midiMappingType == detectedMappingType &&
                      _data.midiCC == number &&
                      _data.midiChannel == channel &&
                      _data.isMidiEnabled) {
                    return;
                  }

                  setState(() {
                    _data = _data.copyWith(
                      midiMappingType: detectedMappingType,
                      midiCC: number,
                      midiChannel: channel,
                      isMidiEnabled: true,
                    );
                  });
                  _midiCcController.text = number.toString();
                  _triggerOptimisticSave(force: true);
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
    });
    if (_midiCcController.text != _data.midiCC.toString()) {
      _midiCcController.text = _data.midiCC.toString();
    }
  }

  void _updateMidiMinFromController() {
    final parsed = int.tryParse(_midiMinController.text) ?? _data.midiMin;
    final clamped = parsed.clamp(-32768, 32767);
    setState(() {
      _data = _data.copyWith(midiMin: clamped);
    });
    if (_midiMinController.text != _data.midiMin.toString()) {
      _midiMinController.text = _data.midiMin.toString();
    }
  }

  void _updateMidiMaxFromController() {
    final parsed = int.tryParse(_midiMaxController.text) ?? _data.midiMax;
    final clamped = parsed.clamp(-32768, 32767);
    setState(() {
      _data = _data.copyWith(midiMax: clamped);
    });
    if (_midiMaxController.text != _data.midiMax.toString()) {
      _midiMaxController.text = _data.midiMax.toString();
    }
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
            onChanged: _triggerOptimisticSave,
          ),
          SwitchListTile(
            title: const Text('I2C Enabled'),
            value: _data.isI2cEnabled,
            dense: true,
            contentPadding: EdgeInsets.zero,
            onChanged: (val) {
              setState(() {
                _data = _data.copyWith(isI2cEnabled: val);
              });
              _triggerOptimisticSave();
            },
          ),
          SwitchListTile(
            title: const Text('I2C Symmetric'),
            value: _data.isI2cSymmetric,
            dense: true,
            contentPadding: EdgeInsets.zero,
            onChanged: (val) {
              setState(() {
                _data = _data.copyWith(isI2cSymmetric: val);
              });
              _triggerOptimisticSave();
            },
          ),
          _buildRangeSlider(
            minValue: _data.i2cMin,
            maxValue: _data.i2cMax,
            onChanged: (rawMin, rawMax) {
              final previousMin = _data.i2cMin;
              setState(() {
                _data = _data.copyWith(i2cMin: rawMin, i2cMax: rawMax);
                _i2cMinController.text = rawMin.toString();
                _i2cMaxController.text = rawMax.toString();
              });
              _triggerOptimisticSave();
              // Preview whichever thumb moved
              final previewValue =
                  (rawMin != previousMin) ? rawMin : rawMax;
              _previewParameterValue(previewValue);
            },
            onChangeEnd: (_, _) {
              _restoreParameterValue();
            },
          ),
        ],
      ),
    );
  }

  void _updateI2cCcFromController() {
    final parsed = int.tryParse(_i2cCcController.text) ?? _data.i2cCC;
    setState(() {
      _data = _data.copyWith(i2cCC: parsed);
    });
    if (_i2cCcController.text != _data.i2cCC.toString()) {
      _i2cCcController.text = _data.i2cCC.toString();
    }
  }

  void _updateI2cMinFromController() {
    final parsed = int.tryParse(_i2cMinController.text) ?? _data.i2cMin;
    setState(() {
      _data = _data.copyWith(i2cMin: parsed);
    });
    if (_i2cMinController.text != _data.i2cMin.toString()) {
      _i2cMinController.text = _data.i2cMin.toString();
    }
  }

  void _updateI2cMaxFromController() {
    final parsed = int.tryParse(_i2cMaxController.text) ?? _data.i2cMax;
    setState(() {
      _data = _data.copyWith(i2cMax: parsed);
    });
    if (_i2cMaxController.text != _data.i2cMax.toString()) {
      _i2cMaxController.text = _data.i2cMax.toString();
    }
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
  /// Range Slider
  /// ---------------------
  String _formatDisplayValue(double displayValue) {
    final decimalPlaces = widget.powerOfTen.abs();
    final formatted = displayValue.toStringAsFixed(decimalPlaces);
    final unit = widget.unitString?.trim();
    if (unit != null && unit.isNotEmpty) {
      return '$formatted $unit';
    }
    return formatted;
  }

  Widget _buildRangeSlider({
    required int minValue,
    required int maxValue,
    required void Function(int rawMin, int rawMax) onChanged,
    void Function(int rawMin, int rawMax)? onChangeEnd,
  }) {
    final scale = pow(10, widget.powerOfTen).toDouble();
    var sliderMin = widget.parameterMin;
    var sliderMax = widget.parameterMax;
    if (sliderMin > sliderMax) {
      final tmp = sliderMin;
      sliderMin = sliderMax;
      sliderMax = tmp;
    }

    if (sliderMin == sliderMax) {
      // Only one possible value — show a label instead of a slider
      final displayValue = sliderMin * scale;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Text(
          'Range: ${_formatDisplayValue(displayValue)}',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }

    final displayMin = sliderMin * scale;
    final displayMax = sliderMax * scale;

    // Clamp current values to slider range
    final clampedMin = minValue.clamp(sliderMin, sliderMax);
    final clampedMax = maxValue.clamp(sliderMin, sliderMax);
    final displayStart = clampedMin * scale;
    final displayEnd = clampedMax * scale;

    final divisions = sliderMax - sliderMin;

    return Column(
      children: [
        RangeSlider(
          values: RangeValues(displayStart, displayEnd),
          min: displayMin,
          max: displayMax,
          divisions: divisions,
          labels: RangeLabels(
            _formatDisplayValue(displayStart),
            _formatDisplayValue(displayEnd),
          ),
          semanticFormatterCallback: (value) => _formatDisplayValue(value),
          onChanged: (RangeValues values) {
            final rawMin = (values.start / scale).round();
            final rawMax = (values.end / scale).round();
            onChanged(rawMin, rawMax);
          },
          onChangeEnd: onChangeEnd != null
              ? (RangeValues values) {
                  final rawMin = (values.start / scale).round();
                  final rawMax = (values.end / scale).round();
                  onChangeEnd(rawMin, rawMax);
                }
              : null,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Min: ${_formatDisplayValue(displayStart)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Text(
                'Max: ${_formatDisplayValue(displayEnd)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
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
