import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nt_helper/db/database.dart';
import 'package:collection/collection.dart';

class LoadPresetDialog extends StatefulWidget {
  final String initialName;
  final SharedPreferences? preferences;
  final AppDatabase db;

  const LoadPresetDialog({
    super.key,
    required this.initialName,
    required this.db,
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

  // New state for SD Cards and Presets
  List<SdCardEntry> _scannedCards = [];
  SdCardEntry? _selectedSdCard;
  List<IndexedPresetFileEntry> _presetsForSelectedCard = [];
  String?
      _currentPresetSearchText; // To hold text from autocomplete for filtering

  @override
  void initState() {
    super.initState();
    _controller.text = widget.initialName.trim();
    _loadScannedCards();
    _loadHistoryFromPrefs(); // Load history for autocomplete
  }

  Future<void> _loadScannedCards() async {
    final cards = await widget.db.sdCardsDao.getAllSdCards();
    if (mounted) {
      setState(() {
        _scannedCards = cards;
        if (_scannedCards.isNotEmpty) {
          _selectedSdCard = _scannedCards.first;
          _loadPresetsForCard(_selectedSdCard!);
        } else {
          _selectedSdCard = null;
          _presetsForSelectedCard = [];
        }
      });
    }
  }

  Future<void> _loadPresetsForCard(SdCardEntry? card) async {
    if (card == null) {
      if (mounted) {
        setState(() {
          _presetsForSelectedCard = [];
          _selectedSdCard = null;
          _controller.clear(); // Clear preset name when card is unselected
        });
      }
      return;
    }
    final presets = await widget.db.indexedPresetFilesDao
        .getIndexedPresetFilesBySdCardId(card.id);
    if (mounted) {
      setState(() {
        _selectedSdCard = card;
        _presetsForSelectedCard = presets;
        _controller.clear(); // Clear preset name when card changes
      });
    }
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

  /// Adds a new name to the local history list (if not present) and saves it.
  /// Ensures the list remains sorted after adding.
  Future<void> _addNameToHistory(String name) async {
    name = name.trim();
    if (name.isNotEmpty) {
      final prefs = widget.preferences ?? await SharedPreferences.getInstance();
      setState(() {
        // Remove if exists to avoid duplicates, then add and re-sort
        _history.remove(name);
        _history.add(name);
        _history.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      });
      await prefs.setStringList('presetHistory', _history);
    }
  }

  Future<void> _removeNameFromHistory(String name) async {
    final prefs = widget.preferences ?? await SharedPreferences.getInstance();
    setState(() {
      _history.remove(name);
      // List remains sorted after removal
    });
    await prefs.setStringList('presetHistory', _history);
  }

  void _onCancel() {
    Navigator.of(context).pop(null); // Indicate "load was cancelled"
  }

  Future<void> _onAppend() async {
    await _handlePresetSelection(isAppending: true);
  }

  Future<void> _onLoad() async {
    await _handlePresetSelection(isAppending: false);
  }

  Future<void> _handlePresetSelection({required bool isAppending}) async {
    final trimmed = _controller.text.trim();
    if (trimmed.isEmpty) return;

    // Attempt 1: Match on Currently Selected SD Card
    if (_selectedSdCard != null) {
      final presetOnCurrentCard = _presetsForSelectedCard.firstWhereOrNull(
          (p) => _getDisplayPath(p) == trimmed || p.fileName == trimmed);
      if (presetOnCurrentCard != null) {
        // presetOnCurrentCard.relativePath is now e.g., "presets/BankA/file.json"
        String pathForEngine = "/${presetOnCurrentCard.relativePath}";
        await _addNameToHistory(trimmed);
        Navigator.of(context).pop({
          "sdCardPath":
              pathForEngine, // Key indicating path relative to SD root, starting with /
          "append": isAppending,
          "displayName": trimmed
        });
        return;
      }
    }

    // Attempt 2: Resolve History Item or General Text Input Across All SD Cards
    bool isKnownHistoryItem = _history.contains(trimmed);

    for (final cardEntry in _scannedCards) {
      List<IndexedPresetFileEntry> presetsOnThisCard;
      if (_selectedSdCard != null && cardEntry.id == _selectedSdCard!.id) {
        presetsOnThisCard = _presetsForSelectedCard;
      } else {
        presetsOnThisCard = await widget.db.indexedPresetFilesDao
            .getIndexedPresetFilesBySdCardId(cardEntry.id);
      }

      final matchedPreset = presetsOnThisCard.firstWhereOrNull((p) {
        if (isKnownHistoryItem && p.fileName == trimmed) {
          return true; // History item matched by filename
        }
        // General match for typed text or if history item didn't match filename directly
        return _getDisplayPath(p) == trimmed || p.fileName == trimmed;
      });

      if (matchedPreset != null) {
        // matchedPreset.relativePath is now e.g., "presets/BankA/file.json"
        String pathForEngine = "/${matchedPreset.relativePath}";
        await _addNameToHistory(trimmed);
        Navigator.of(context).pop({
          "sdCardPath":
              pathForEngine, // Key indicating path relative to SD root, starting with /
          "append": isAppending,
          "displayName": trimmed
        });
        return;
      }
    }

    debugPrint(
        "'$trimmed' could not be resolved to a full path on any scanned SD card.");
  }

  String _getDisplayPath(IndexedPresetFileEntry preset) {
    if (preset.relativePath.isEmpty) {
      return preset
          .fileName; // Should not happen if relativePath includes filename
    }
    final segments = preset.relativePath.split('/');
    if (segments.length > 1) {
      // Takes the last folder and the filename
      return "${segments[segments.length - 2]}/${segments.last}";
    } else {
      // It's just a filename, or in the root of 'presets'
      return segments.last;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(_isManagingHistory ? 'Manage History' : 'Load Preset'),
          if (!_isManagingHistory)
            IconButton(
              icon: const Icon(Icons.history),
              tooltip: 'Manage Preset History',
              onPressed: () {
                setState(() {
                  _isManagingHistory = true;
                });
              },
            ),
        ],
      ),
      content: SizedBox(
        width: 400, // Wider dialog
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _isManagingHistory
                  ? _buildManagementView()
                  : _buildPresetSelectionView(),
            ],
          ),
        ),
      ),
      actions: _isManagingHistory ? [_buildDoneButton()] : _buildLoadActions(),
    );
  }

  // Extracted Autocomplete view builder
  Widget _buildPresetSelectionView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_scannedCards.isNotEmpty)
          DropdownButtonFormField<SdCardEntry>(
            decoration: InputDecoration(
              labelText: 'Select SD Card',
              border: OutlineInputBorder(),
            ),
            value: _selectedSdCard,
            hint: Text('Select an SD Card'),
            isExpanded: true,
            items: _scannedCards.map((SdCardEntry card) {
              return DropdownMenuItem<SdCardEntry>(
                value: card,
                child: Text(
                    card.userLabel ?? card.systemIdentifier ?? 'Unknown Card'),
              );
            }).toList(),
            onChanged: (SdCardEntry? newValue) {
              _loadPresetsForCard(newValue);
            },
          ),
        if (_scannedCards.isEmpty)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text('No SD cards scanned yet. Please scan a card first.'),
          ),
        SizedBox(height: 16),
        Autocomplete<Object>(
          initialValue: TextEditingValue(text: _controller.text),
          fieldViewBuilder:
              (context, textEditingController, focusNode, onFieldSubmitted) {
            if (_currentPresetSearchText != textEditingController.text) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  _controller.text = textEditingController.text;
                  _currentPresetSearchText = textEditingController.text;
                }
              });
            }
            return SizedBox(
              child: TextField(
                key: ValueKey('preset-name-text-field'),
                enabled: true,
                onSubmitted: (value) {
                  _controller.text = value;
                  onFieldSubmitted();
                },
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Preset Name/Path or History',
                ),
                controller: textEditingController,
                focusNode: focusNode,
              ),
            );
          },
          optionsMaxHeight: 200,
          optionsViewBuilder: (context,
              AutocompleteOnSelected<Object> onSelected,
              Iterable<Object> options) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4.0,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: 200, maxWidth: 380),
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: options.length,
                    itemBuilder: (BuildContext context, int index) {
                      final Object option = options.elementAt(index);
                      String displayText;
                      if (option is IndexedPresetFileEntry) {
                        displayText = _getDisplayPath(option);
                      } else if (option is String) {
                        displayText = "Recent: $option";
                      } else {
                        displayText = "Unknown type";
                      }
                      return InkWell(
                        onTap: () {
                          onSelected(option);
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(displayText,
                              overflow: TextOverflow.ellipsis),
                        ),
                      );
                    },
                  ),
                ),
              ),
            );
          },
          onSelected: (Object selection) {
            String textToSet;
            if (selection is IndexedPresetFileEntry) {
              textToSet = _getDisplayPath(selection);
            } else if (selection is String) {
              textToSet = selection;
            } else {
              textToSet = '';
            }
            setState(() {
              _controller.text = textToSet;
              _currentPresetSearchText = textToSet;
            });
          },
          optionsBuilder: (TextEditingValue textEditingValue) {
            _currentPresetSearchText = textEditingValue.text;
            List<Object> combinedOptions = [];

            // 1. Add filtered history items (sorted alphabetically)
            List<String> filteredHistory = _history;
            if (textEditingValue.text.isNotEmpty) {
              filteredHistory = _history.where((String historyItem) {
                return historyItem
                    .toLowerCase()
                    .contains(textEditingValue.text.toLowerCase());
              }).toList();
            }
            filteredHistory
                .sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
            combinedOptions.addAll(filteredHistory);

            // 2. Add presets from selected card (sorted alphabetically by display path)
            if (_selectedSdCard != null) {
              List<IndexedPresetFileEntry> cardPresetsSource =
                  _presetsForSelectedCard;
              List<IndexedPresetFileEntry> filteredCardPresets;

              if (textEditingValue.text.isEmpty) {
                filteredCardPresets =
                    cardPresetsSource.toList(); // Already loaded for the card
              } else {
                filteredCardPresets =
                    cardPresetsSource.where((IndexedPresetFileEntry preset) {
                  final searchText = textEditingValue.text.toLowerCase();
                  final displayPath = _getDisplayPath(preset).toLowerCase();
                  return (displayPath.contains(searchText) ||
                      preset.fileName
                          .toLowerCase()
                          .contains(searchText) || // Keep direct filename match
                      preset.relativePath
                          .toLowerCase()
                          .contains(searchText) || // Keep relative path match
                      (preset.algorithmNameFromPreset
                              ?.toLowerCase()
                              .contains(searchText) ??
                          false) ||
                      (preset.notesFromPreset
                              ?.toLowerCase()
                              .contains(searchText) ??
                          false));
                }).toList();
              }
              filteredCardPresets.sort((a, b) => _getDisplayPath(a)
                  .toLowerCase()
                  .compareTo(_getDisplayPath(b).toLowerCase()));
              combinedOptions.addAll(filteredCardPresets);
            }
            return combinedOptions;
          },
          displayStringForOption: (Object option) {
            if (option is IndexedPresetFileEntry) {
              return _getDisplayPath(option);
            } else if (option is String) {
              return option;
            }
            return '';
          },
        ),
      ],
    );
  }

  // View for managing history
  Widget _buildManagementView() {
    // Use a fixed height container for the list to prevent dialog overflow
    return SizedBox(
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
        onPressed:
            (_selectedSdCard != null && _controller.text.trim().isNotEmpty)
                ? _onAppend
                : null,
        child: const Text('APPEND'),
      ),
      ElevatedButton(
        key: ValueKey('load_preset_dialog_load_button'),
        onPressed:
            (_selectedSdCard != null && _controller.text.trim().isNotEmpty)
                ? _onLoad
                : null,
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
