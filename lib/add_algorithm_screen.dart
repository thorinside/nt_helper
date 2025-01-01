import 'package:flutter/material.dart';
import 'package:nt_helper/domain/disting_nt_sysex.dart';

class AddAlgorithmScreen extends StatefulWidget {
  final List<AlgorithmInfo> algorithms;

  const AddAlgorithmScreen({super.key, required this.algorithms});

  @override
  State<AddAlgorithmScreen> createState() => _AddAlgorithmScreenState();
}

class _AddAlgorithmScreenState extends State<AddAlgorithmScreen> {
  final _formKey = GlobalKey<FormState>();

  /// The currently selected algorithm from the dropdown.
  AlgorithmInfo? _selectedAlgorithm;

  /// A list of text controllers used for each Specification field.
  final List<TextEditingController> _specControllers = [];

  /// Builds one TextEditingController per Specification in [_selectedAlgorithm].
  void _buildSpecControllers() {
    _specControllers.clear();
    if (_selectedAlgorithm != null &&
        _selectedAlgorithm!.specifications.isNotEmpty) {
      for (var spec in _selectedAlgorithm!.specifications) {
        final controller = TextEditingController(
          text: spec.defaultValue.toString(),
        );
        _specControllers.add(controller);
      }
    }
  }

  /// Validate and pop with the user’s input if all is valid.
  void _onAdd() {
    if (_formKey.currentState?.validate() ?? false) {
      // Build a list of integers for the user-entered specification values
      final enteredValues = <int>[];
      for (var controller in _specControllers) {
        enteredValues.add(int.parse(controller.text));
      }

      // You might need to return something that your caller can use,
      // such as a new AlgorithmInfo or a custom result object.
      // For example, you could build a *copy* of the AlgorithmInfo:
      final resultAlgorithm = AlgorithmInfo(
        algorithmIndex: _selectedAlgorithm!.algorithmIndex,
        guid: _selectedAlgorithm!.guid,
        numSpecifications: _selectedAlgorithm!.numSpecifications,
        specifications: _selectedAlgorithm!.specifications,
        name: _selectedAlgorithm!.name,
      );

      // Pop with two pieces: the chosen AlgorithmInfo and the user’s specs
      Navigator.of(context).pop({
        'algorithm': resultAlgorithm,
        'specValues': enteredValues,
      });
    }
  }

  void _onCancel() {
    Navigator.of(context).pop(null);
  }

  @override
  Widget build(BuildContext context) {
    // Use a Scaffold with Material3, if your overall app theme is not already M3.
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Algorithm'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            children: [
              /// Dropdown to select the algorithm
              DropdownButtonFormField<AlgorithmInfo>(
                decoration: const InputDecoration(
                  labelText: 'Algorithm',
                  border: OutlineInputBorder(),
                ),
                isExpanded: true,
                value: _selectedAlgorithm,
                items: widget.algorithms.map((algo) {
                  return DropdownMenuItem<AlgorithmInfo>(
                    value: algo,
                    child: Text(algo.name),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedAlgorithm = value;
                    _buildSpecControllers();
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Please select an algorithm';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              /// If an algorithm is selected, show its specification fields
              if (_selectedAlgorithm != null &&
                  _selectedAlgorithm!.specifications.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: List.generate(
                      _selectedAlgorithm!.specifications.length, (index) {
                    final spec = _selectedAlgorithm!.specifications[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: TextFormField(
                        controller: _specControllers[index],
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: spec.name,
                          hintText:
                              'Enter a value between ${spec.min} and ${spec.max}',
                          border: const OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Cannot be empty';
                          }
                          final parsed = int.tryParse(value);
                          if (parsed == null) {
                            return 'Must be an integer';
                          }
                          if (parsed < spec.min || parsed > spec.max) {
                            return 'Value must be between ${spec.min} and ${spec.max}';
                          }
                          return null;
                        },
                      ),
                    );
                  }),
                )
              else if (_selectedAlgorithm != null)
                const Text('No specifications for this algorithm.'),

              /// Action buttons: Add / Cancel
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  FilledButton(
                    onPressed: _onCancel,
                    style: FilledButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      backgroundColor: Colors.grey,
                    ),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: _onAdd,
                    child: const Text('Add'),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
