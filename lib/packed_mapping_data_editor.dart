import 'package:flutter/material.dart';
import 'package:nt_helper/models/packed_mapping_data.dart';
import 'package:nt_helper/ui/midi_listener/midi_detector_widget.dart';

class PackedMappingDataEditor extends StatefulWidget {
  final PackedMappingData initialData;
  final ValueChanged<PackedMappingData> onSave;

  const PackedMappingDataEditor({
    super.key,
    required this.initialData,
    required this.onSave,
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
    } else {
      // No CV, MIDI, or I2C in use, default to CV tab
      initialIndex = 0;
    }

    // Create the TabController with initialIndex set to the matching page.
    _tabController = TabController(
      length: 3,
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

  void _onSavePressed() {
    // Final clamp/parse before saving
    _updateVoltsFromController();
    _updateDeltaFromController();
    _updateMidiCcFromController();
    _updateMidiMinFromController();
    _updateMidiMaxFromController();
    _updateI2cCcFromController();
    _updateI2cMinFromController();
    _updateI2cMaxFromController();

    widget.onSave(_data);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 450, // keep the bottom sheet from being too tall
      child: Column(
        children: [
          TabBar(
            controller: _tabController,
            labelColor: Theme.of(context).colorScheme.onSurface,
            unselectedLabelColor:
                Theme.of(context).colorScheme.onSurface.withAlpha(64),
            tabs: const [
              Tab(text: 'CV'),
              Tab(text: 'MIDI'),
              Tab(text: 'I2C'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildCvEditor(),
                _buildMidiEditor(),
                _buildI2cEditor(),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: _onSavePressed,
              child: const Text('Save'),
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
    final cvInputValue =
        (_data.cvInput >= 0 && _data.cvInput <= 29) ? _data.cvInput : 0;

    // Safely clamp the source value for the dropdown
    final sourceValue =
        (_data.source >= 0 && _data.source <= 33) ? _data.source : 0;

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
                    return DropdownMenuEntry<int>(
                      value: index,
                      label: 'Slot $slotNumber',
                    );
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
                  },
                ),
              ],
            ),
            _buildNumericField(
              label: 'Volts',
              controller: _voltsController,
              onSubmit: _updateVoltsFromController,
            ),
            _buildNumericField(
              label: 'Delta',
              controller: _deltaController,
              onSubmit: _updateDeltaFromController,
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
          _buildNumericField(
            label: 'MIDI CC (0–128)',
            controller: _midiCcController,
            onSubmit: _updateMidiCcFromController,
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
                },
              ),
            ],
          ),
          Row(
            children: [
              const Text('MIDI Relative'),
              Switch(
                value: _data.isMidiRelative,
                onChanged: (val) {
                  setState(() {
                    _data = _data.copyWith(isMidiRelative: val);
                  });
                },
              ),
            ],
          ),
          _buildNumericField(
            label: 'MIDI Min',
            controller: _midiMinController,
            onSubmit: _updateMidiMinFromController,
          ),
          _buildNumericField(
            label: 'MIDI Max',
            controller: _midiMaxController,
            onSubmit: _updateMidiMaxFromController,
          ),
          // Add the MIDI Detector
          MidiDetectorWidget(
            onCcFound: ({cc, channel}) {
              // When we've detected 10 consecutive hits of the same CC,
              // automatically fill in the CC number, and midi channel in your form data
              // and assume we want to enable the midi mapping.
              setState(() {
                _data = _data.copyWith(
                    midiCC: cc, midiChannel: channel, isMidiEnabled: true);
              });
              // Also update the text field / controller if necessary
              _midiCcController.text = cc.toString();
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
                },
              ),
            ],
          ),
          _buildNumericField(
            label: 'I2C Min',
            controller: _i2cMinController,
            onSubmit: _updateI2cMinFromController,
          ),
          _buildNumericField(
            label: 'I2C Max',
            controller: _i2cMaxController,
            onSubmit: _updateI2cMaxFromController,
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
  /// Helpers
  /// ---------------------
  /// Builds a labeled numeric TextField that calls [onSubmit]
  /// when the user presses the "done" button on the keyboard
  Widget _buildNumericField({
    required String label,
    required TextEditingController controller,
    required VoidCallback onSubmit,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: TextField(
        keyboardType: TextInputType.number,
        textInputAction: TextInputAction.done,
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        onSubmitted: (_) => onSubmit(),
      ),
    );
  }
}

/// CopyWith extension
extension on PackedMappingData {
  PackedMappingData copyWith({
    int? source,
    int? cvInput,
    bool? isUnipolar,
    bool? isGate,
    int? volts,
    int? delta,
    int? midiChannel,
    int? midiCC,
    bool? isMidiEnabled,
    bool? isMidiSymmetric,
    bool? isMidiRelative,
    int? midiMin,
    int? midiMax,
    int? i2cCC,
    bool? isI2cEnabled,
    bool? isI2cSymmetric,
    int? i2cMin,
    int? i2cMax,
    int? version,
  }) {
    return PackedMappingData(
      source: source ?? this.source,
      cvInput: cvInput ?? this.cvInput,
      isUnipolar: isUnipolar ?? this.isUnipolar,
      isGate: isGate ?? this.isGate,
      volts: volts ?? this.volts,
      delta: delta ?? this.delta,
      midiChannel: midiChannel ?? this.midiChannel,
      midiCC: midiCC ?? this.midiCC,
      isMidiEnabled: isMidiEnabled ?? this.isMidiEnabled,
      isMidiSymmetric: isMidiSymmetric ?? this.isMidiSymmetric,
      isMidiRelative: isMidiRelative ?? this.isMidiRelative,
      midiMin: midiMin ?? this.midiMin,
      midiMax: midiMax ?? this.midiMax,
      i2cCC: i2cCC ?? this.i2cCC,
      isI2cEnabled: isI2cEnabled ?? this.isI2cEnabled,
      isI2cSymmetric: isI2cSymmetric ?? this.isI2cSymmetric,
      i2cMin: i2cMin ?? this.i2cMin,
      i2cMax: i2cMax ?? this.i2cMax,
      version: version ?? this.version,
    );
  }
}
