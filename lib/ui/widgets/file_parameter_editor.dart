import 'dart:async';
import 'dart:io';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nt_helper/cubit/disting_cubit.dart';
import 'package:nt_helper/domain/disting_nt_sysex.dart' show ParameterInfo;
import 'package:nt_helper/models/sd_card_file_system.dart';
import 'package:nt_helper/ui/parameter_editor_registry.dart';
import 'package:path/path.dart' as path;

/// Enhanced file parameter editor widget that provides context-aware file browsing
class FileParameterEditor extends StatefulWidget {
  final Slot slot;
  final ParameterInfo parameterInfo;
  final int parameterNumber;
  final int currentValue;
  final Function(int) onValueChanged;
  final ParameterEditorRule rule;

  const FileParameterEditor({
    super.key,
    required this.slot,
    required this.parameterInfo,
    required this.parameterNumber,
    required this.currentValue,
    required this.onValueChanged,
    required this.rule,
  });

  @override
  State<FileParameterEditor> createState() => _FileParameterEditorState();
}

enum _DevelopmentState {
  inactive,
  monitoring,
  changed, // File changed, waiting for changes to settle
  uploading,
  reloading,
  error,
}

class _FileParameterEditorState extends State<FileParameterEditor> {
  late TextEditingController _textController;
  String? _currentDisplayValue;
  bool _isEditingText = false;
  bool _isLoadingFiles = false;
  List<DirectoryEntry> _availableFiles = [];
  String? _currentDirectory;
  String? _selectedFolderName;
  String? _selectedFileName;

  // Development mode state for Lua Script
  Timer? _fileWatchTimer;
  Timer? _debounceTimer;
  String? _developmentFilePath;
  DateTime? _lastModified;
  bool _isDragOver = false;
  _DevelopmentState _devState = _DevelopmentState.inactive;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
    _currentDirectory = widget.rule.baseDirectory;
    _updateDisplayValue();
    if (widget.rule.mode != FileSelectionMode.textInput) {
      _loadDirectoryContents();
    } else {
      // For text input, initialize the controller with current value string
      final valueString = widget.slot.valueStrings.elementAtOrNull(
        widget.parameterNumber,
      );
      if (valueString != null && valueString.value.isNotEmpty) {
        _textController.text = valueString.value;
      }
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _fileWatchTimer?.cancel();
    _debounceTimer?.cancel();
    super.dispose();
  }

  /// Check if this is Lua Script Program parameter
  bool get _isLuaScriptProgram =>
      widget.slot.algorithm.guid == 'lua ' &&
      widget.parameterInfo.name == 'Program';

  @override
  void didUpdateWidget(FileParameterEditor oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.currentValue != widget.currentValue) {
      _updateSelectedNameForValue(widget.currentValue);

      // For text input, update the display value
      if (widget.rule.mode == FileSelectionMode.textInput) {
        _updateDisplayValue();
      }
    }

    // Check if this is a Sample or MIDI Player file parameter and if the folder value changed
    if (widget.rule.mode == FileSelectionMode.fileOnly &&
        (widget.parameterInfo.name.contains('Sample') ||
            widget.parameterInfo.name.contains('File'))) {
      _checkForFolderChanges(oldWidget);
    }

    // Check if value string changed for text parameters
    if (widget.rule.mode == FileSelectionMode.textInput) {
      final oldValueString =
          oldWidget.slot.valueStrings
              .elementAtOrNull(oldWidget.parameterNumber)
              ?.value ??
          '';
      final newValueString =
          widget.slot.valueStrings
              .elementAtOrNull(widget.parameterNumber)
              ?.value ??
          '';
      if (oldValueString != newValueString && !_isEditingText) {
        // Hardware confirmed the value - update our display
        setState(() {
          _currentDisplayValue = newValueString;
          _textController.text = newValueString;
        });
      }
    }
  }

  void _checkForFolderChanges(FileParameterEditor oldWidget) {
    try {
      // Find the folder parameter in both old and new slots
      final folderParamIndex = widget.slot.parameters.indexWhere(
        (p) => p.name.contains('Folder'),
      );

      if (folderParamIndex == -1) return;

      final oldFolderValue = oldWidget.slot.values.length > folderParamIndex
          ? oldWidget.slot.values[folderParamIndex].value
          : -1;
      final newFolderValue = widget.slot.values.length > folderParamIndex
          ? widget.slot.values[folderParamIndex].value
          : -1;

      // If folder changed, reload directory contents
      if (oldFolderValue != newFolderValue) {
        _loadDirectoryContents();
      }
    } catch (e) {
      // Intentionally empty
    }
  }

  void _updateDisplayValue() {
    _currentDisplayValue = _getDisplayValueForCurrentValue();

    if (widget.rule.mode == FileSelectionMode.textInput) {
      _textController.text = _currentDisplayValue ?? '';
    }
  }

  String? _getDisplayValueForCurrentValue() {
    final currentVal = widget.currentValue;
    // Use min value to determine display offset: if min=0, show currentVal+1; if min=1, show currentVal
    final displayVal = widget.parameterInfo.min == 0
        ? currentVal + 1
        : currentVal;
    // Return actual resolved names if available, otherwise show loading or fallback
    switch (widget.rule.mode) {
      case FileSelectionMode.folderOnly:
        return _selectedFolderName ??
            (_isLoadingFiles ? 'Loading...' : 'Folder $displayVal');
      case FileSelectionMode.fileOnly:
        return _selectedFileName ??
            (_isLoadingFiles ? 'Loading...' : 'File $displayVal');
      case FileSelectionMode.directFile:
        return _selectedFileName ??
            (_isLoadingFiles ? 'Loading...' : 'Program $displayVal');
      case FileSelectionMode.folderThenFile:
        return _selectedFileName ??
            (_isLoadingFiles ? 'Loading...' : 'Item $displayVal');
      case FileSelectionMode.textInput:
        // For text input, we need to get the actual string value from the slot
        final valueString = widget.slot.valueStrings.elementAtOrNull(
          widget.parameterNumber,
        );
        if (valueString != null && valueString.value.isNotEmpty) {
          return valueString.value;
        }
        // Return empty string if no value is set
        return '';
    }
  }

  Future<void> _resolveCurrentValueToName() async {
    if (_currentDirectory == null || _availableFiles.isEmpty) return;

    // Convert parameter value to array index using min value
    final paramValue = widget.currentValue;
    final index = paramValue - widget.parameterInfo.min;

    if (index >= 0 && index < _availableFiles.length) {
      final entry = _availableFiles[index];
      setState(() {
        switch (widget.rule.mode) {
          case FileSelectionMode.folderOnly:
            _selectedFolderName = _cleanDisplayName(entry.name, isFolder: true);
            break;
          case FileSelectionMode.fileOnly:
          case FileSelectionMode.directFile:
          case FileSelectionMode.folderThenFile:
            _selectedFileName = _cleanDisplayName(entry.name, isFolder: false);
            break;
          case FileSelectionMode.textInput:
            break; // Not applicable
        }
        _updateDisplayValue();
      });
    }
  }

  void _incrementValue() {
    final newValue = (widget.currentValue + 1).clamp(
      widget.parameterInfo.min,
      widget.parameterInfo.max,
    );
    // Optimistic update - immediately update UI
    _updateSelectedNameForValue(newValue);
    // Then notify parent to update hardware
    widget.onValueChanged(newValue);
  }

  void _decrementValue() {
    final newValue = (widget.currentValue - 1).clamp(
      widget.parameterInfo.min,
      widget.parameterInfo.max,
    );
    // Optimistic update - immediately update UI
    _updateSelectedNameForValue(newValue);
    // Then notify parent to update hardware
    widget.onValueChanged(newValue);
  }

  String _cleanDisplayName(String name, {required bool isFolder}) {
    String cleanName = name;

    // Remove trailing slash from folder names
    if (isFolder && cleanName.endsWith('/')) {
      cleanName = cleanName.substring(0, cleanName.length - 1);
    }

    // For recursive mode, show subdirectory structure
    if (widget.rule.recursive && cleanName.contains('/')) {
      // Keep the subdirectory path but clean up the display
      final parts = cleanName.split('/');
      if (parts.length > 1) {
        // Show as "subdir/filename" or "subdir1/subdir2/filename"
        cleanName = parts.join('/');
      }
    }

    // Remove file extensions for certain file types
    if (!isFolder && widget.rule.allowedExtensions != null) {
      for (final ext in widget.rule.allowedExtensions!) {
        if (cleanName.toLowerCase().endsWith(ext.toLowerCase())) {
          cleanName = cleanName.substring(0, cleanName.length - ext.length);
          break;
        }
      }
    }

    return cleanName;
  }

  void _updateSelectedNameForValue(int value) {
    if (_availableFiles.isEmpty) return;

    // Convert parameter value to array index using min value
    final index = value - widget.parameterInfo.min;

    if (index >= 0 && index < _availableFiles.length) {
      final entry = _availableFiles[index];
      setState(() {
        switch (widget.rule.mode) {
          case FileSelectionMode.folderOnly:
            _selectedFolderName = _cleanDisplayName(entry.name, isFolder: true);
            break;
          case FileSelectionMode.fileOnly:
          case FileSelectionMode.directFile:
          case FileSelectionMode.folderThenFile:
            _selectedFileName = _cleanDisplayName(entry.name, isFolder: false);
            break;
          case FileSelectionMode.textInput:
            break; // Not applicable
        }
        _updateDisplayValue();
      });
    }
  }

  Future<void> _loadDirectoryContents() async {
    // Get cubit first before any async operations
    final cubit = context.read<DistingCubit>();

    String? directoryToLoad = _currentDirectory;

    // For Sample and MIDI Player file parameters, we need to load from the selected folder
    if (widget.rule.mode == FileSelectionMode.fileOnly &&
        (widget.parameterInfo.name.contains('Sample') ||
            widget.parameterInfo.name.contains('File'))) {
      directoryToLoad = await _getSelectedFolderPath();
    }

    if (directoryToLoad == null) return;

    setState(() {
      _isLoadingFiles = true;
    });

    try {
      final disting = cubit.disting();

      if (disting == null) {
        if (mounted) {
          setState(() {
            _isLoadingFiles = false;
          });
        }
        return;
      }

      List<DirectoryEntry> allFiles = [];

      if (widget.rule.recursive) {
        // Recursive search for files
        allFiles = await _loadDirectoryRecursive(disting, directoryToLoad, '');
      } else {
        // Single directory listing
        final listing = await disting.requestDirectoryListing(directoryToLoad);

        if (listing != null) {
          allFiles = listing.entries;
        }
      }

      if (mounted) {
        setState(() {
          _availableFiles =
              allFiles.where((entry) {
                // Filter out hidden files and system directories
                if (entry.name.startsWith('.')) return false;

                // Filter based on mode and allowed extensions
                switch (widget.rule.mode) {
                  case FileSelectionMode.folderOnly:
                    return entry.isDirectory &&
                        !widget.rule.excludeDirs.contains(
                          entry.name.replaceAll('/', ''),
                        );
                  case FileSelectionMode.fileOnly:
                  case FileSelectionMode.directFile:
                    if (entry.isDirectory) return false;
                    if (widget.rule.allowedExtensions?.isEmpty ?? true) {
                      return true;
                    }
                    return widget.rule.allowedExtensions!.any(
                      (ext) =>
                          entry.name.toLowerCase().endsWith(ext.toLowerCase()),
                    );
                  case FileSelectionMode.folderThenFile:
                    // Show both folders and valid files
                    if (entry.isDirectory) {
                      return !widget.rule.excludeDirs.contains(
                        entry.name.replaceAll('/', ''),
                      );
                    }
                    if (widget.rule.allowedExtensions?.isEmpty ?? true) {
                      return true;
                    }
                    return widget.rule.allowedExtensions!.any(
                      (ext) =>
                          entry.name.toLowerCase().endsWith(ext.toLowerCase()),
                    );
                  case FileSelectionMode.textInput:
                    return false; // Not used for text input
                }
              }).toList()..sort((a, b) {
                // For recursive mode, sort by full path
                // For non-recursive, sort directories first, then files
                if (!widget.rule.recursive && a.isDirectory != b.isDirectory) {
                  return a.isDirectory ? -1 : 1;
                }
                // Then sort alphabetically
                return a.name.toLowerCase().compareTo(b.name.toLowerCase());
              });
          _isLoadingFiles = false;
        });

        // After loading, resolve the current value to actual name
        await _resolveCurrentValueToName();
      } else if (allFiles.isEmpty && mounted) {
        setState(() {
          _availableFiles = [];
          _isLoadingFiles = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingFiles = false;
        });
      }
    }
  }

  Future<String?> _getSelectedFolderPath() async {
    try {
      // Get cubit first before any async operations
      final cubit = context.read<DistingCubit>();
      final disting = cubit.disting();

      // Find the folder parameter in the same slot
      final folderParamIndex = widget.slot.parameters.indexWhere(
        (p) => p.name.contains('Folder'),
      );

      if (folderParamIndex == -1) {
        return _currentDirectory;
      }

      final folderValue = widget.slot.values[folderParamIndex].value;

      if (disting == null || _currentDirectory == null) {
        return _currentDirectory;
      }

      final listing = await disting.requestDirectoryListing(_currentDirectory!);
      if (listing == null) {
        return _currentDirectory;
      }

      final folders =
          listing.entries
              .where((e) => e.isDirectory && !e.name.startsWith('.'))
              .toList()
            ..sort(
              (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
            );

      // Convert folder parameter value to array index using min value
      final folderParam = widget.slot.parameters[folderParamIndex];
      final folderIndex = folderValue - folderParam.min;

      if (folderIndex >= 0 && folderIndex < folders.length) {
        final selectedFolder = folders[folderIndex].name.replaceAll('/', '');
        return '$_currentDirectory/$selectedFolder';
      } else {
      }
    } catch (e) {
      // Intentionally empty
    }

    return _currentDirectory;
  }

  Future<void> _showFileSelectionDialog() async {
    if (_availableFiles.isEmpty && !_isLoadingFiles) {
      // Try to load files first
      await _loadDirectoryContents();
      if (_availableFiles.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'No ${widget.rule.mode == FileSelectionMode.folderOnly ? "folders" : "files"} found in ${_currentDirectory ?? "directory"}',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
        return;
      }
    }

    if (_isLoadingFiles) {
      return; // Don't show dialog while loading
    }

    if (!mounted) return;
    final selectedEntry = await showDialog<DirectoryEntry>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Select ${widget.rule.mode == FileSelectionMode.folderOnly ? 'Folder' : 'File'}',
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: Column(
            children: [
              if (_currentDirectory != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text(
                    'Location: $_currentDirectory',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              Expanded(
                child: ListView.builder(
                  itemCount: _availableFiles.length,
                  itemBuilder: (context, index) {
                    final entry = _availableFiles[index];
                    final paramValue = widget.currentValue;
                    final selectedIndex = paramValue - widget.parameterInfo.min;
                    final isSelected = index == selectedIndex;
                    final displayName = _cleanDisplayName(
                      entry.name,
                      isFolder: entry.isDirectory,
                    );

                    // For recursive mode with subdirectories, show the path structure
                    Widget titleWidget;
                    if (widget.rule.recursive && displayName.contains('/')) {
                      final parts = displayName.split('/');
                      final fileName = parts.last;
                      final path = parts.sublist(0, parts.length - 1).join('/');
                      titleWidget = Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            fileName,
                            style: isSelected
                                ? const TextStyle(fontWeight: FontWeight.bold)
                                : null,
                          ),
                          Text(
                            path,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      );
                    } else {
                      titleWidget = Text(
                        displayName,
                        style: isSelected
                            ? const TextStyle(fontWeight: FontWeight.bold)
                            : null,
                      );
                    }

                    return ListTile(
                      leading: Icon(
                        entry.isDirectory
                            ? Icons.folder
                            : _getFileIcon(entry.name),
                        color: entry.isDirectory
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.secondary,
                      ),
                      title: titleWidget,
                      subtitle: entry.isDirectory
                          ? null
                          : Text(_formatFileSize(entry.size)),
                      selected: isSelected,
                      onTap: () => Navigator.of(context).pop(entry),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (selectedEntry != null) {
      // Find the index of the selected entry and set the parameter value
      final selectedIndex = _availableFiles.indexOf(selectedEntry);
      if (selectedIndex != -1) {
        // Convert array index to parameter value using min value
        final newValue = selectedIndex + widget.parameterInfo.min;
        // Update the name immediately for UI feedback
        _updateSelectedNameForValue(newValue);
        // Then notify parent to update hardware
        widget.onValueChanged(newValue);
      }
    }
  }

  Future<List<DirectoryEntry>> _loadDirectoryRecursive(
    dynamic disting,
    String basePath,
    String relativePath,
  ) async {
    final currentPath = relativePath.isEmpty
        ? basePath
        : '$basePath/$relativePath';
    final listing = await disting.requestDirectoryListing(currentPath);

    if (listing == null) return [];

    List<DirectoryEntry> results = [];
    List<DirectoryEntry> directories = [];

    // Separate files and directories, sort alphabetically
    for (final entry in listing.entries) {
      if (entry.isDirectory) {
        final dirName = entry.name.replaceAll('/', '');
        if (!widget.rule.excludeDirs.contains(dirName)) {
          directories.add(entry);
        }
      } else {
        // Add files first (breadth-first approach)
        final fileName = relativePath.isEmpty
            ? entry.name
            : '$relativePath/${entry.name}';
        results.add(
          DirectoryEntry(
            name: fileName,
            size: entry.size,
            attributes: entry.attributes,
            date: entry.date,
            time: entry.time,
          ),
        );
      }
    }

    // Sort directories alphabetically
    directories.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );

    // Then recurse into subdirectories (breadth-first)
    for (final dir in directories) {
      final dirName = dir.name.replaceAll('/', '');
      final subPath = relativePath.isEmpty ? dirName : '$relativePath/$dirName';
      final subResults = await _loadDirectoryRecursive(
        disting,
        basePath,
        subPath,
      );
      results.addAll(subResults);
    }

    return results;
  }

  IconData _getFileIcon(String fileName) {
    final ext = fileName.toLowerCase();
    if (ext.endsWith('.wav') || ext.endsWith('.aif') || ext.endsWith('.aiff')) {
      return Icons.audio_file;
    } else if (ext.endsWith('.lua')) {
      return Icons.code;
    } else if (ext.endsWith('.scl') ||
        ext.endsWith('.kbm') ||
        ext.endsWith('.syx')) {
      return Icons.music_note;
    }
    return Icons.insert_drive_file;
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  void _onTextSubmitted(String value) async {
    // Optimistic update - immediately update UI
    setState(() {
      _isEditingText = false;
      _currentDisplayValue = value;
      _textController.text = value;
    });

    // Update the parameter string value through the cubit
    final cubit = context.read<DistingCubit>();

    // Use the cubit's updateParameterString method which handles the update flow
    await cubit.updateParameterString(
      algorithmIndex: widget.slot.algorithm.algorithmIndex,
      parameterNumber: widget.parameterNumber,
      value: value,
    );

    // The cubit will handle updating the hardware and refreshing the value
    // No need for a snackbar - the optimistic update provides immediate feedback
  }

  Widget _buildTextInputEditor() {
    if (_isEditingText) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _textController,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                  hintText: 'Enter name...',
                  counterText: '', // Hide the character counter
                ),
                onSubmitted: _onTextSubmitted,
                onEditingComplete: () {
                  _onTextSubmitted(_textController.text);
                },
                autofocus: true,
                style: const TextStyle(fontSize: 16),
                maxLength: 31, // Hardware limit for text parameters
              ),
            ),
            const SizedBox(width: 4),
            IconButton(
              onPressed: () {
                _onTextSubmitted(_textController.text);
              },
              icon: const Icon(Icons.check),
              iconSize: 24,
              visualDensity: VisualDensity.compact,
              color: Theme.of(context).colorScheme.primary,
            ),
            IconButton(
              onPressed: () {
                setState(() {
                  _isEditingText = false;
                  _textController.text = _currentDisplayValue ?? '';
                });
              },
              icon: const Icon(Icons.close),
              iconSize: 24,
              visualDensity: VisualDensity.compact,
              color: Theme.of(context).colorScheme.error,
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          _isEditingText = true;
          // Make sure text controller has current value
          _textController.text = _currentDisplayValue ?? '';
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Text(
                _currentDisplayValue?.isNotEmpty == true
                    ? _currentDisplayValue!
                    : '', // Show empty when no name is set
                style: const TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.edit,
              size: 18,
              color: Theme.of(context).colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileSelectionEditor() {
    return Row(
      children: [
        // Previous button
        InkWell(
          onTap: widget.currentValue > widget.parameterInfo.min
              ? _decrementValue
              : null,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(12),
            child: Icon(
              Icons.navigate_before,
              size: 24,
              color: widget.currentValue > widget.parameterInfo.min
                  ? null
                  : Colors.grey.shade400,
            ),
          ),
        ),

        const SizedBox(width: 8),

        // Current selection display
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(_getIconForMode(), size: 18, color: Colors.grey.shade600),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _currentDisplayValue ?? 'No selection',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(width: 8),

        // Next button
        InkWell(
          onTap: widget.currentValue < widget.parameterInfo.max
              ? _incrementValue
              : null,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(12),
            child: Icon(
              Icons.navigate_next,
              size: 24,
              color: widget.currentValue < widget.parameterInfo.max
                  ? null
                  : Colors.grey.shade400,
            ),
          ),
        ),

        const SizedBox(width: 8),

        // Browse button - hide during development mode but maintain layout space
        Visibility(
          visible: _devState == _DevelopmentState.inactive,
          maintainSize: true,
          maintainAnimation: true,
          maintainState: true,
          child: InkWell(
            onTap: _isLoadingFiles ? null : _showFileSelectionDialog,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _isLoadingFiles
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.folder_open, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    _isLoadingFiles ? 'Loading...' : 'Browse',
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  IconData _getIconForMode() {
    switch (widget.rule.mode) {
      case FileSelectionMode.folderOnly:
        return Icons.folder;
      case FileSelectionMode.fileOnly:
      case FileSelectionMode.directFile:
        return Icons.insert_drive_file;
      case FileSelectionMode.folderThenFile:
        return Icons.folder_open;
      case FileSelectionMode.textInput:
        return Icons.text_fields;
    }
  }

  Widget _buildDragOverlay() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.file_upload,
              size: 20,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              'Drop .lua file for dev mode',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDevModeIndicator() {
    return Positioned(
      top: 8,
      right: 8,
      child: GestureDetector(
        onTap: _toggleDevelopmentMode,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _getStateColor().withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _getStateColor()),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildStateIcon(),
              const SizedBox(width: 4),
              Text(_getStateText(), style: const TextStyle(fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStateIcon() {
    switch (_devState) {
      case _DevelopmentState.monitoring:
        return const Icon(Icons.visibility, size: 16);
      case _DevelopmentState.changed:
        return const Icon(Icons.pending, size: 16);
      case _DevelopmentState.uploading:
      case _DevelopmentState.reloading:
        return const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        );
      case _DevelopmentState.error:
        return const Icon(Icons.error_outline, size: 16);
      default:
        return const Icon(Icons.code, size: 16);
    }
  }

  Color _getStateColor() {
    switch (_devState) {
      case _DevelopmentState.monitoring:
        return Colors.green;
      case _DevelopmentState.changed:
        return Colors.orange;
      case _DevelopmentState.uploading:
      case _DevelopmentState.reloading:
        return Colors.blue;
      case _DevelopmentState.error:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStateText() {
    switch (_devState) {
      case _DevelopmentState.monitoring:
        return 'Watching';
      case _DevelopmentState.changed:
        return 'Changed';
      case _DevelopmentState.uploading:
        return 'Uploading';
      case _DevelopmentState.reloading:
        return 'Reloading';
      case _DevelopmentState.error:
        return 'Error';
      default:
        return 'Dev Mode';
    }
  }

  Future<void> _handleScriptDrop(DropDoneDetails details) async {
    setState(() => _isDragOver = false);

    // Filter for .lua files only
    final luaFiles = details.files
        .where((file) => file.path.toLowerCase().endsWith('.lua'))
        .toList();

    if (luaFiles.isEmpty) {
      _showError('Please drop a .lua file');
      return;
    }

    if (luaFiles.length > 1) {
      _showError('Please drop only one file at a time');
      return;
    }

    final file = luaFiles.first;

    // Ask user if they want to enable development mode
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enable Development Mode?'),
        content: Text(
          'Monitor "${path.basename(file.path)}" for changes and '
          'automatically reload on the Disting NT?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Enable'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _startDevelopmentMode(file.path);
    }
  }

  void _toggleDevelopmentMode() {
    if (_devState == _DevelopmentState.inactive) {
      // Can't start without a file - this shouldn't normally happen
      return;
    } else {
      // Stop development mode
      _stopDevelopmentMode();
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _startDevelopmentMode(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        _showError('File does not exist: ${path.basename(filePath)}');
        return;
      }

      _developmentFilePath = filePath;
      _lastModified = await file.lastModified();

      setState(() {
        _devState = _DevelopmentState.monitoring;
      });

      // Start file monitoring with 1-second Timer.periodic
      _fileWatchTimer = Timer.periodic(const Duration(seconds: 1), (_) async {
        if (_developmentFilePath == null) return;

        try {
          final file = File(_developmentFilePath!);
          final currentModified = await file.lastModified();

          if (currentModified != _lastModified) {
            _lastModified = currentModified;
            _onFileChanged();
          }
        } catch (e) {
          if (mounted) {
            setState(() => _devState = _DevelopmentState.error);
          }
        }
      });

    } catch (e) {
      _showError('Failed to start development mode: $e');
    }
  }

  void _stopDevelopmentMode() {
    _fileWatchTimer?.cancel();
    _debounceTimer?.cancel();
    _fileWatchTimer = null;
    _debounceTimer = null;
    _developmentFilePath = null;
    _lastModified = null;

    setState(() {
      _devState = _DevelopmentState.inactive;
    });

  }

  void _onFileChanged() {
    // Cancel any existing debounce timer
    _debounceTimer?.cancel();

    // Set state to 'changed' to show user that changes were detected
    if (mounted) {
      setState(() => _devState = _DevelopmentState.changed);
    }

    // Start a new debounce timer - wait 3 seconds for changes to settle
    _debounceTimer = Timer(const Duration(seconds: 3), () async {
      if (mounted && _devState == _DevelopmentState.changed) {
        await _uploadAndReloadScript();
      }
    });

  }

  Future<void> _uploadAndReloadScript() async {
    if (_developmentFilePath == null) return;

    setState(() => _devState = _DevelopmentState.uploading);

    try {
      // Get current Program parameter value and cubit before async operations
      final currentValue = widget.currentValue;
      final cubit = context.read<DistingCubit>();

      // Read the modified script
      final file = File(_developmentFilePath!);
      final contents = await file.readAsBytes();
      final fileName = path.basename(_developmentFilePath!);

      // Upload to hardware using installPlugin
      await cubit.installPlugin(
        fileName,
        contents,
        onProgress: (progress) {
          // Progress is shown via the uploading state indicator
        },
      );

      if (!mounted) return;
      setState(() => _devState = _DevelopmentState.reloading);

      // Force reload using state-preserving method
      // This preserves all parameter values, routing, and mappings during reload
      await cubit.forceReloadLuaScriptWithStatePreservation(
        widget.slot.algorithm.algorithmIndex,
        widget.parameterNumber, // Program parameter number
        currentValue, // Current program value
      );

      if (mounted) {
        setState(() => _devState = _DevelopmentState.monitoring);
      }

    } catch (e) {
      if (mounted) {
        setState(() => _devState = _DevelopmentState.error);
        _showError('Upload failed: $e');
      }

      // Don't stop monitoring on upload errors, allow retry
      Timer(const Duration(seconds: 3), () {
        if (_devState == _DevelopmentState.error && mounted) {
          setState(() => _devState = _DevelopmentState.monitoring);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget content;
    if (widget.rule.mode == FileSelectionMode.textInput) {
      content = _buildTextInputEditor();
    } else {
      content = _buildFileSelectionEditor();
    }

    // Wrap with DropTarget if it's Lua Script Program on desktop
    if (_isLuaScriptProgram &&
        !kIsWeb &&
        (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
      return DropTarget(
        onDragDone: _handleScriptDrop,
        onDragEntered: (_) => setState(() => _isDragOver = true),
        onDragExited: (_) => setState(() => _isDragOver = false),
        child: Stack(
          children: [
            content,
            if (_isDragOver) _buildDragOverlay(),
            if (_devState != _DevelopmentState.inactive)
              _buildDevModeIndicator(),
          ],
        ),
      );
    }

    return content;
  }
}
