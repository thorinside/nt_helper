import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoadPresetDialog extends StatefulWidget {
  final String initialName;
  final SharedPreferences? preferences;

  const LoadPresetDialog({
    super.key,
    required this.initialName,
    this.preferences,
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
    final prefs = widget.preferences ?? await SharedPreferences.getInstance();
    setState(() {
      _history = prefs.getStringList('presetHistory') ?? [];
    });
  }

  /// Persists the updated history list back to SharedPreferences.
  Future<void> _saveHistoryToPrefs() async {
    final prefs = widget.preferences ?? await SharedPreferences.getInstance();
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
          Autocomplete(
            initialValue: TextEditingValue(text: widget.initialName),
            fieldViewBuilder:
                (context, textEditingController, focusNode, onFieldSubmitted) {
              return SizedBox(
                width: 325,
                child: TextField(
                  key: ValueKey('preset-name-text-field'),
                  onSubmitted: (value) {
                    _controller.text = value;
                    onFieldSubmitted();
                  },
                  onChanged: (value) {
                    _controller.text = value;
                  },
                  decoration: InputDecoration(
                      border: OutlineInputBorder(), labelText: 'Preset Path'),
                  controller: textEditingController,
                  focusNode: focusNode,
                ),
              );
            },
            optionsMaxHeight: 400,
            optionsViewOpenDirection: OptionsViewOpenDirection.down,
            onSelected: (option) {
              setState(() => _controller.text = option);
            },
            optionsBuilder: (textEditingValue) {
              return _history.where(
                (element) => element.contains(textEditingValue.text),
              );
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          key: ValueKey('load_preset_dialog_cancel_button'),
          onPressed: _onCancel,
          child: const Text('CANCEL'),
        ),
        ElevatedButton(
          key: ValueKey('load_preset_dialog_append_button'),
          onPressed: _onAppend,
          child: const Text('APPEND'),
        ),
        ElevatedButton(
          key: ValueKey('load_preset_dialog_load_button'),
          onPressed: _onLoad,
          child: const Text('LOAD'),
        ),
      ],
    );
  }
}
