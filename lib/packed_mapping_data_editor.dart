import 'package:flutter/material.dart';
import 'package:nt_helper/models/packed_mapping_data.dart';

/// A widget that displays a 3-tab interface for editing:
///  - CV settings
///  - MIDI settings
///  - I2C settings
///
/// This widget is intended to be shown inside a bottom sheet and
/// returns an updated [PackedMappingData] via [onSave] when the user presses "Save".
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

  // We'll keep a local copy of the data that we can edit.
  late PackedMappingData _data;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _data = widget.initialData;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onSavePressed() {
    // Return the updated data to the parent via callback
    widget.onSave(_data);
  }

  @override
  Widget build(BuildContext context) {
    // We use a fixed-height container to keep the bottom sheet from being too tall.
    return SizedBox(
      height: 400,
      child: Column(
        children: [
          // Tab bar
          TabBar(
            controller: _tabController,
            labelColor: Theme.of(context).primaryColor,
            unselectedLabelColor: Colors.black54,
            tabs: const [
              Tab(text: 'CV'),
              Tab(text: 'MIDI'),
              Tab(text: 'I2C'),
            ],
          ),
          // Tab views
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
          // Save button
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

  /// --- CV Editor ---
  Widget _buildCvEditor() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          _labelAndField(
            label: 'CV Input',
            initialValue: _data.cvInput.toString(),
            onChanged: (value) {
              final parsed = int.tryParse(value) ?? _data.cvInput;
              setState(() {
                _data = _data.copyWith(cvInput: parsed);
              });
            },
          ),
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
          _labelAndField(
            label: 'Volts',
            initialValue: _data.volts.toString(),
            onChanged: (value) {
              final parsed = int.tryParse(value) ?? _data.volts;
              setState(() {
                _data = _data.copyWith(volts: parsed);
              });
            },
          ),
          _labelAndField(
            label: 'Delta',
            initialValue: _data.delta.toString(),
            onChanged: (value) {
              final parsed = int.tryParse(value) ?? _data.delta;
              setState(() {
                _data = _data.copyWith(delta: parsed);
              });
            },
          ),
        ],
      ),
    );
  }

  /// --- MIDI Editor ---
  Widget _buildMidiEditor() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          _labelAndField(
            label: 'MIDI Channel (1-16)',
            initialValue: (_data.midiChannel + 1).toString(),
            onChanged: (value) {
              final parsed = int.tryParse(value) ?? _data.midiChannel;
              // clamp to 1..16, if needed
              final clamped = parsed.clamp(1, 16);
              setState(() {
                _data = _data.copyWith(midiChannel: clamped - 1);
              });
            },
          ),
          _labelAndField(
            label: 'MIDI CC (0-127)',
            initialValue: _data.midiCC.toString(),
            onChanged: (value) {
              final parsed = int.tryParse(value) ?? _data.midiCC;
              // clamp to 0..127
              final clamped = parsed.clamp(0, 127);
              setState(() {
                _data = _data.copyWith(midiCC: clamped);
              });
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
          _labelAndField(
            label: 'MIDI Min (0-127)',
            initialValue: _data.midiMin.toString(),
            onChanged: (value) {
              final parsed = int.tryParse(value) ?? _data.midiMin;
              // clamp to 0..127
              final clamped = parsed.clamp(0, 127);
              setState(() {
                _data = _data.copyWith(midiMin: clamped);
              });
            },
          ),
          _labelAndField(
            label: 'MIDI Max (0-127)',
            initialValue: _data.midiMax.toString(),
            onChanged: (value) {
              final parsed = int.tryParse(value) ?? _data.midiMax;
              // clamp to 0..127
              final clamped = parsed.clamp(0, 127);
              setState(() {
                _data = _data.copyWith(midiMax: clamped);
              });
            },
          ),
        ],
      ),
    );
  }

  /// --- I2C Editor ---
  Widget _buildI2cEditor() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          _labelAndField(
            label: 'I2C CC',
            initialValue: _data.i2cCC.toString(),
            onChanged: (value) {
              final parsed = int.tryParse(value) ?? _data.i2cCC;
              setState(() {
                _data = _data.copyWith(i2cCC: parsed);
              });
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
          _labelAndField(
            label: 'I2C Min',
            initialValue: _data.i2cMin.toString(),
            onChanged: (value) {
              final parsed = int.tryParse(value) ?? _data.i2cMin;
              setState(() {
                _data = _data.copyWith(i2cMin: parsed);
              });
            },
          ),
          _labelAndField(
            label: 'I2C Max',
            initialValue: _data.i2cMax.toString(),
            onChanged: (value) {
              final parsed = int.tryParse(value) ?? _data.i2cMax;
              setState(() {
                _data = _data.copyWith(i2cMax: parsed);
              });
            },
          ),
        ],
      ),
    );
  }

  /// Helper widget to build a labeled TextField quickly
  Widget _labelAndField({
    required String label,
    required String initialValue,
    required ValueChanged<String> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: TextField(
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
        ),
        controller: TextEditingController(text: initialValue),
        onChanged: onChanged,
      ),
    );
  }
}

extension on PackedMappingData {
  /// A convenience extension method for copying the data with updated fields.
  PackedMappingData copyWith({
    int? cvInput,
    bool? isUnipolar,
    bool? isGate,
    int? volts,
    int? delta,
    int? midiChannel,
    int? midiCC,
    bool? isMidiEnabled,
    bool? isMidiSymmetric,
    int? midiMin,
    int? midiMax,
    int? i2cCC,
    bool? isI2cEnabled,
    bool? isI2cSymmetric,
    int? i2cMin,
    int? i2cMax,
  }) {
    return PackedMappingData(
      cvInput: cvInput ?? this.cvInput,
      isUnipolar: isUnipolar ?? this.isUnipolar,
      isGate: isGate ?? this.isGate,
      volts: volts ?? this.volts,
      delta: delta ?? this.delta,
      midiChannel: midiChannel ?? this.midiChannel,
      midiCC: midiCC ?? this.midiCC,
      isMidiEnabled: isMidiEnabled ?? this.isMidiEnabled,
      isMidiSymmetric: isMidiSymmetric ?? this.isMidiSymmetric,
      midiMin: midiMin ?? this.midiMin,
      midiMax: midiMax ?? this.midiMax,
      i2cCC: i2cCC ?? this.i2cCC,
      isI2cEnabled: isI2cEnabled ?? this.isI2cEnabled,
      isI2cSymmetric: isI2cSymmetric ?? this.isI2cSymmetric,
      i2cMin: i2cMin ?? this.i2cMin,
      i2cMax: i2cMax ?? this.i2cMax,
    );
  }
}
