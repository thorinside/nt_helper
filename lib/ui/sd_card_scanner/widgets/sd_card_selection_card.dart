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
    _relativePresetsPathController.text = 'presets'; // Default to 'presets'
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
              if (Platform.isIOS) ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text(
                    'SD Card Root Directory',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Theme.of(context).hintColor,
                          fontWeight: FontWeight.normal,
                        ),
                  ),
                ),
                if (_selectedIdentifier == null &&
                    _manualPathController.text.isEmpty)
                  ElevatedButton.icon(
                    icon: const Icon(Icons.folder_open),
                    label: const Text('Choose SD Card Root Directory...'),
                    onPressed: _pickDirectory,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12.0, vertical: 8.0),
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: Theme.of(context)
                                  .inputDecorationTheme
                                  .border
                                  ?.borderSide
                                  .color ??
                              Colors.grey),
                      borderRadius: BorderRadius.circular(4.0),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _manualPathController.text.isNotEmpty
                                ? _manualPathController.text
                                    .split('/')
                                    .last // Show only last part for brevity
                                : 'No directory selected',
                            style: const TextStyle(fontSize: 16),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.folder_open),
                          tooltip: 'Change SD Card Root',
                          onPressed: _pickDirectory,
                        ),
                        IconButton(
                          icon: const Icon(Icons.clear),
                          tooltip: 'Clear Selection',
                          onPressed: () {
                            setState(() {
                              _selectedPath = null;
                              _selectedIdentifier = null;
                              _manualPathController.clear();
                              _isPathSelectedByPicker = false;
                              _didUserInteractWithRootPicker = true;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),
              ] else ...[
                // Non-iOS: Row with TextFormField and Button
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _manualPathController,
                        decoration: InputDecoration(
                          labelText: 'SD Card Root Directory',
                          hintText: _isPathSelectedByPicker ||
                                  (widget.isRescan &&
                                      widget.initialSdCardRootPath != null)
                              ? _manualPathController.text
                              : 'Enter path or pick SD Card Root',
                          border: const OutlineInputBorder(),
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
                                      _didUserInteractWithRootPicker = true;
                                    });
                                  },
                                )
                              : null,
                        ),
                        onChanged: (value) {
                          setState(() {
                            _selectedPath = value;
                            _selectedIdentifier = value;
                            _isPathSelectedByPicker = false;
                            _didUserInteractWithRootPicker = true;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please pick or enter an SD card root path.';
                          }
                          if (widget.isRescan &&
                              value == widget.initialSdCardRootPath &&
                              !_didUserInteractWithRootPicker) {
                            return null;
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.folder_open),
                      label: const Text('Browse...'),
                      onPressed: _pickDirectory,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 15), // Ensure decent height
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16), // Spacing after the row
              ],
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
                    bool isRootPathValidOnIOS = true;
                    if (Platform.isIOS) {
                      // On iOS, _manualPathController.text should reflect the picked/initial path.
                      // _selectedIdentifier also holds the picked object.
                      if (_manualPathController.text.isEmpty &&
                          _selectedIdentifier == null) {
                        isRootPathValidOnIOS = false;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  'Please choose an SD card root directory.')),
                        );
                      }
                    }

                    if (_formKey.currentState!.validate() &&
                        isRootPathValidOnIOS) {
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
