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
  bool _isManagingHistory = false; // State for toggling view

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
      // Sort history alphabetically for management view
      _history = prefs.getStringList('presetHistory') ?? [];
      _history.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    });
  }

  /// Persists the updated history list back to SharedPreferences.
  Future<void> _saveHistoryToPrefs() async {
    final prefs = widget.preferences ?? await SharedPreferences.getInstance();
    // Ensure we save the potentially re-ordered history
    await prefs.setStringList('presetHistory', _history);
  }

  /// Adds a new name to the local history list (if not present) and saves it.
  /// Ensures the list remains sorted after adding.
  Future<void> _addNameToHistory(String name) async {
    name = name.trim();
    if (name.isNotEmpty) {
      setState(() {
        // Remove if exists to avoid duplicates, then add and re-sort
        _history.remove(name);
        _history.add(name);
        _history.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      });
      await _saveHistoryToPrefs();
    }
  }

  Future<void> _removeNameFromHistory(String name) async {
    setState(() {
      _history.remove(name);
      // List remains sorted after removal
    });
    await _saveHistoryToPrefs();
  }

  void _onCancel() {
    Navigator.of(context).pop(null); // Indicate "load was cancelled"
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
      // Ensure your app's theme is set to Material 3:
      // MaterialApp(theme: ThemeData(useMaterial3: true), ...)
      title: Text(_isManagingHistory ? 'Manage History' : 'Load Preset'),
      content: SingleChildScrollView(
        // Use scrollable content to prevent overflow if management list is long
        child: SizedBox(
          width: 325,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _isManagingHistory
                  ? _buildManagementView()
                  : _buildAutocompleteView(),
            ],
          ),
        ),
      ),
      actions: _isManagingHistory ? [_buildDoneButton()] : _buildLoadActions(),
    );
  }

  // Extracted Autocomplete view builder
  Widget _buildAutocompleteView() {
    return Autocomplete(
      initialValue: TextEditingValue(text: _controller.text),
      fieldViewBuilder:
          (context, textEditingController, focusNode, onFieldSubmitted) {
        // Use _controller here if needed, or sync them
        // For simplicity, let Autocomplete manage its internal controller
        return SizedBox(
          width: 325,
          child: TextField(
            key: ValueKey('preset-name-text-field'),
            onSubmitted: (value) {
              _controller.text = value;
              onFieldSubmitted();
              _onLoad(); // Trigger load on submit
            },
            onChanged: (value) {
              _controller.text = value;
            },
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Preset Path',
              // Add button to enter management mode
              suffixIcon: IconButton(
                icon: Icon(Icons.edit_note_rounded),
                tooltip: 'Manage History',
                onPressed: () => setState(() {
                  _isManagingHistory = true;
                }),
              ),
            ),
            controller: textEditingController, // Use Autocomplete's controller
            focusNode: focusNode,
          ),
        );
      },
      optionsMaxHeight: 200, // Adjusted height
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4.0,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                  maxHeight: 200, maxWidth: 325), // Max width for options
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (BuildContext context, int index) {
                  final String option = options.elementAt(index);
                  return InkWell(
                    onTap: () {
                      onSelected(option);
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(option),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
      onSelected: (option) {
        setState(() => _controller.text = option);
      },
      optionsBuilder: (textEditingValue) {
        if (textEditingValue.text == '') {
          return _history; // Show full sorted history if empty
        }
        // Filter sorted history
        return _history.where(
          (element) => element
              .toLowerCase()
              .contains(textEditingValue.text.toLowerCase()),
        );
      },
    );
  }

  // View for managing history
  Widget _buildManagementView() {
    // Use a fixed height container for the list to prevent dialog overflow
    return Container(
      height: 300, // Adjust height as needed
      child: _history.isEmpty
          ? Center(child: Text('No preset history.'))
          : Scrollbar(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _history.length,
                itemBuilder: (context, index) {
                  final presetName = _history[index];
                  return ListTile(
                    dense: true,
                    title: Text(presetName, overflow: TextOverflow.ellipsis),
                    trailing: IconButton(
                      icon: Icon(Icons.delete_outline, size: 20),
                      tooltip: 'Remove from history',
                      onPressed: () {
                        _removeNameFromHistory(presetName);
                      },
                    ),
                  );
                },
              ),
            ),
    );
  }

  // Extracted Load/Append actions
  List<Widget> _buildLoadActions() {
    return [
      TextButton(
        key: ValueKey('load_preset_dialog_cancel_button'),
        onPressed: _onCancel,
        child: const Text('CANCEL'),
      ),
      ElevatedButton(
        key: ValueKey('load_preset_dialog_append_button'),
        onPressed: _controller.text.trim().isEmpty
            ? null
            : _onAppend, // Disable if empty
        child: const Text('APPEND'),
      ),
      ElevatedButton(
        key: ValueKey('load_preset_dialog_load_button'),
        onPressed: _controller.text.trim().isEmpty
            ? null
            : _onLoad, // Disable if empty
        child: const Text('LOAD'),
      ),
    ];
  }

  // Renamed from _buildCloseButton
  Widget _buildDoneButton() {
    return TextButton(
      onPressed: () => setState(() {
        _isManagingHistory = false;
      }),
      child: const Text('Done'),
    );
  }
}
