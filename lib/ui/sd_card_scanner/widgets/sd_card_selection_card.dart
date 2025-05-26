import 'package:flutter/material.dart';
import 'dart:io'; // Import for Platform
import 'package:nt_helper/util/file_system_utils.dart'; // Import FileSystemUtils
import 'package:docman/docman.dart' as docman; // Ensure docman is imported

class SdCardSelectionCard extends StatefulWidget {
  final Function(String pathOrUri, String cardName)? onScanRequested;

  const SdCardSelectionCard({super.key, this.onScanRequested});

  @override
  State<SdCardSelectionCard> createState() => _SdCardSelectionCardState();
}

class _SdCardSelectionCardState extends State<SdCardSelectionCard> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedPath; // Store the path selected by the user
  final _manualPathController =
      TextEditingController(); // Still used if user wants to type/paste
  final _cardNameController = TextEditingController();
  bool _isPathSelectedByPicker =
      false; // To know if path came from picker or manual input

  @override
  void dispose() {
    _manualPathController.dispose();
    _cardNameController.dispose();
    super.dispose();
  }

  Future<void> _pickDirectory() async {
    final dynamic pickedIdentifier =
        await FileSystemUtils.pickSdCardRootDirectory(); // Changed to dynamic
    if (pickedIdentifier != null) {
      setState(() {
        if (pickedIdentifier is String) {
          _selectedPath = pickedIdentifier;
          _manualPathController.text = pickedIdentifier;
        } else if (pickedIdentifier is docman.DocumentFile) {
          // Use aliased docman
          _selectedPath =
              pickedIdentifier.uri.toString(); // Store the URI string
          _manualPathController.text =
              _selectedPath!; // Update text field with URI string
        }
        _isPathSelectedByPicker = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select SD Card to Scan',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),

              // Directory Picker Button and Display Field
              TextFormField(
                controller:
                    _manualPathController, // Use this to display picked path or allow manual entry
                decoration: InputDecoration(
                  labelText: 'SD Card Path',
                  hintText: _isPathSelectedByPicker
                      ? _selectedPath
                      : 'Enter path or pick directory',
                  border: const OutlineInputBorder(),
                  // Optionally, add a clear button if path is selected by picker
                  suffixIcon: _isPathSelectedByPicker
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            setState(() {
                              _selectedPath = null;
                              _manualPathController.clear();
                              _isPathSelectedByPicker = false;
                            });
                          },
                        )
                      : null,
                ),
                onChanged: (value) {
                  // If user types, it's no longer considered picked by picker
                  setState(() {
                    _selectedPath = value;
                    _isPathSelectedByPicker = false;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please pick or enter an SD card path.';
                  }
                  // TODO: Add more robust path validation (e.g. check if directory exists)
                  return null;
                },
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                icon: const Icon(Icons.folder_open),
                label: const Text('Choose SD Card Directory...'),
                onPressed: _pickDirectory,
                style: ElevatedButton.styleFrom(
                  minimumSize:
                      const Size(double.infinity, 36), // Make button full width
                ),
              ),
              const SizedBox(height: 16),

              // Custom Card Name
              TextFormField(
                controller: _cardNameController,
                decoration: const InputDecoration(
                  labelText: 'Custom Card Name (Optional)',
                  hintText: 'My Sample Library Card',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),

              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.document_scanner_outlined),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    textStyle: Theme.of(context).textTheme.labelLarge,
                  ),
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      final String pathToScan = _manualPathController
                          .text; // Path is now always from this controller
                      final cardName = _cardNameController.text.isNotEmpty
                          ? _cardNameController.text
                          : pathToScan
                              .split(Platform.isWindows ? '\\' : '/')
                              .last; // Default name from path

                      widget.onScanRequested?.call(pathToScan, cardName);
                    } else {
                      debugPrint('Form is invalid');
                    }
                  },
                  label: const Text('Start Scan'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
