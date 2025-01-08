import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoadPresetDialog extends StatefulWidget {
  final String initialName;

  const LoadPresetDialog({
    super.key,
    required this.initialName,
  });

  @override
  State<LoadPresetDialog> createState() => _LoadPresetDialogState();
}

class _LoadPresetDialogState extends State<LoadPresetDialog> {
  /// This controller is bound to the DropdownMenu's internal text field.
  final TextEditingController _controller = TextEditingController();

  /// The list of known preset names (loaded from SharedPreferences).
  List<String> _history = [];

  @override
  void initState() {
    super.initState();
    _controller.text = widget.initialName.trim();
    _loadHistoryFromPrefs();
  }

  /// Loads the preset names from SharedPreferences.
  Future<void> _loadHistoryFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _history = prefs.getStringList('presetHistory') ?? [];
    });
  }

  /// Persists the updated history list back to SharedPreferences.
  Future<void> _saveHistoryToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('presetHistory', _history);
  }

  /// Adds a new name to the local history list (if not present) and saves it.
  Future<void> _addNameToHistory(String name) async {
    name = name.trim();
    if (name.isNotEmpty && !_history.contains(name)) {
      setState(() {
        _history.add(name);
      });
      await _saveHistoryToPrefs();
    }
  }

  void _onCancel() {
    Navigator.of(context).pop(null); // Indicate “load was cancelled”
  }

  Future<void> _onAppend() async {
    final trimmed = _controller.text.trim();
    await _addNameToHistory(trimmed);
    Navigator.of(context).pop({"name": trimmed, "append": true});
  }

  Future<void> _onLoad() async {
    final trimmed = _controller.text.trim();
    await _addNameToHistory(trimmed);
    Navigator.of(context).pop({"name": trimmed, "append": false});
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      // Ensure your app’s theme is set to Material 3:
      // MaterialApp(theme: ThemeData(useMaterial3: true), ...)
      title: const Text('Load Preset'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          DropdownMenu<String>(
            // Ties our external controller to the internal text field.
            controller: _controller,
            // Let the text field be editable/filterable.
            enableFilter: true,
            width: 250,
            // Provide the “initial selection” so the dropdown text
            // starts with the initial name if it’s in the list.
            initialSelection: _history.contains(widget.initialName.trim())
                ? widget.initialName.trim()
                : null,

            label: const Text('Preset Name'),

            // Convert each history item into an entry for the dropdown.
            dropdownMenuEntries: _history
                .map((name) => DropdownMenuEntry(value: name, label: name))
                .toList(),

            // When user picks an item from the dropdown list:
            onSelected: (String? value) {
              if (value != null) {
                setState(() => _controller.text = value);
              }
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _onCancel,
          child: const Text('CANCEL'),
        ),
        ElevatedButton(
          onPressed: _onAppend,
          child: const Text('APPEND'),
        ),
        ElevatedButton(
          onPressed: _onLoad,
          child: const Text('LOAD'),
        ),
      ],
    );
  }
}
