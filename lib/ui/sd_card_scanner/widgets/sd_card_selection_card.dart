import 'package:flutter/material.dart';
import 'dart:io'; // Import for Platform
import 'package:nt_helper/util/file_system_utils.dart'; // Import FileSystemUtils
import 'package:docman/docman.dart' as docman; // Ensure docman is imported

class SdCardSelectionCard extends StatefulWidget {
  final Function(dynamic sdCardRootIdentifier, String relativePresetsPath,
      String cardName)? onScanRequested;
  final String? initialSdCardRootPath; // To pre-fill SD card root
  final String? initialCardName; // To pre-fill card name
  final bool isRescan; // To indicate if this is for a rescan

  const SdCardSelectionCard(
      {super.key,
      this.onScanRequested,
      this.initialSdCardRootPath,
      this.initialCardName,
      this.isRescan = false});

  @override
  State<SdCardSelectionCard> createState() => _SdCardSelectionCardState();
}

class _SdCardSelectionCardState extends State<SdCardSelectionCard> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedPath; // Store the path selected by the user
  dynamic
      _selectedIdentifier; // To store the original picked identifier (String or DocumentFile)
  final _manualPathController =
      TextEditingController(); // Still used if user wants to type/paste
  final _relativePresetsPathController =
      TextEditingController(); // New controller
  final _cardNameController = TextEditingController();
  bool _isPathSelectedByPicker =
      false; // To know if path came from picker or manual input
  bool _didUserInteractWithRootPicker = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialSdCardRootPath != null) {
      _manualPathController.text = widget.initialSdCardRootPath!;
      _selectedPath = widget.initialSdCardRootPath;
      // For rescan, the initialSdCardRootPath is a String (URI or path).
      // We treat it as if it was manually entered, not picked via SAF picker initially for DocumentFile.
      _selectedIdentifier = widget.initialSdCardRootPath;
      _isPathSelectedByPicker = false; // Explicitly false for pre-filled paths
    }
    if (widget.initialCardName != null) {
      _cardNameController.text = widget.initialCardName!;
    }
  }

  @override
  void dispose() {
    _manualPathController.dispose();
    _relativePresetsPathController.dispose(); // Dispose new controller
    _cardNameController.dispose();
    super.dispose();
  }

  Future<void> _pickDirectory() async {
    final dynamic pickedIdentifier =
        await FileSystemUtils.pickSdCardRootDirectory(); // Changed to dynamic
    if (pickedIdentifier != null) {
      setState(() {
        _didUserInteractWithRootPicker =
            true; // User has now picked, overriding any initial value logic
        _selectedIdentifier = pickedIdentifier; // Store the raw identifier
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
                  labelText: 'SD Card Root Directory', // Updated label
                  hintText: _isPathSelectedByPicker ||
                          (widget.isRescan &&
                              widget.initialSdCardRootPath != null)
                      ? _manualPathController
                          .text // Show current value if pre-filled or picked
                      : 'Enter path or pick SD Card Root', // Updated hint
                  border: const OutlineInputBorder(),
                  // Optionally, add a clear button if path is selected by picker or it's a rescan and user hasn't picked a new one
                  suffixIcon: (_isPathSelectedByPicker ||
                          (widget.isRescan &&
                              widget.initialSdCardRootPath != null &&
                              !_didUserInteractWithRootPicker))
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            setState(() {
                              _selectedPath = null;
                              _selectedIdentifier = null;
                              _manualPathController.clear();
                              _isPathSelectedByPicker = false;
                              _didUserInteractWithRootPicker =
                                  true; // Treat clear as an interaction
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
                    return 'Please pick or enter an SD card root path.'; // Updated message
                  }
                  // If it's a rescan and the path is the initial (likely URI), skip complex validation.
                  if (widget.isRescan &&
                      value == widget.initialSdCardRootPath &&
                      !_didUserInteractWithRootPicker) {
                    return null;
                  }
                  // TODO: Add more robust path validation (e.g. check if directory exists)
                  return null;
                },
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                icon: const Icon(Icons.folder_open),
                label: Text(widget.isRescan &&
                        widget.initialSdCardRootPath != null &&
                        !_didUserInteractWithRootPicker
                    ? 'Change SD Card Root...'
                    : 'Choose SD Card Root Directory...'), // Updated label
                onPressed: _pickDirectory,
                style: ElevatedButton.styleFrom(
                  minimumSize:
                      const Size(double.infinity, 36), // Make button full width
                ),
              ),
              const SizedBox(height: 16),

              // Relative Presets Path
              TextFormField(
                controller: _relativePresetsPathController,
                decoration: const InputDecoration(
                  labelText: 'Relative Presets Path',
                  hintText: 'e.g., Presets or MySounds/Disting/Presets',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the relative path to your presets folder.';
                  }
                  // Basic validation: disallow leading/trailing slashes as they can cause issues with p.join or URI construction
                  if (value.startsWith('/') || value.startsWith('\\')) {
                    return 'Relative path should not start with a slash.';
                  }
                  if (value.endsWith('/') || value.endsWith('\\')) {
                    return 'Relative path should not end with a slash.';
                  }
                  return null;
                },
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
                      // Use _selectedIdentifier if path was picked, otherwise use the text field value.
                      // This ensures we pass the DocumentFile URI for Android if available and picked.
                      // For rescan, if user hasn't re-picked, pass the initial string.
                      final dynamic sdCardRootIdentifierToPass;
                      if (_didUserInteractWithRootPicker) {
                        sdCardRootIdentifierToPass =
                            _selectedIdentifier ?? _manualPathController.text;
                      } else if (widget.isRescan &&
                          widget.initialSdCardRootPath != null) {
                        sdCardRootIdentifierToPass =
                            widget.initialSdCardRootPath;
                      } else {
                        sdCardRootIdentifierToPass =
                            _selectedIdentifier ?? _manualPathController.text;
                      }

                      final String relativePresetsPath =
                          _relativePresetsPathController.text;

                      String determinedCardName = _cardNameController.text;
                      if (determinedCardName.isEmpty) {
                        if (_selectedPath != null &&
                            _selectedPath!.isNotEmpty) {
                          determinedCardName = _selectedPath!
                              .split(Platform.isWindows ? '\\' : '/')
                              .last;
                        } else if (widget.isRescan &&
                            widget.initialCardName != null) {
                          determinedCardName = widget.initialCardName!;
                        } else {
                          determinedCardName = 'Unnamed Card';
                        }
                      }

                      widget.onScanRequested?.call(sdCardRootIdentifierToPass,
                          relativePresetsPath, determinedCardName);
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
