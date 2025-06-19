import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nt_helper/db/database.dart';
import 'package:collection/collection.dart';
import 'package:nt_helper/cubit/disting_cubit.dart';
import 'package:nt_helper/models/firmware_version.dart';

class LoadPresetDialog extends StatefulWidget {
  final String initialName;
  final SharedPreferences? preferences;
  final AppDatabase db;
  final DistingCubit distingCubit;

  const LoadPresetDialog({
    super.key,
    required this.initialName,
    required this.db,
    required this.distingCubit,
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
  bool _isLoading = false; // Add loading state

  // New state for SD Cards and Presets
  List<SdCardEntry> _scannedCards = [];
  SdCardEntry? _selectedSdCard;
  List<IndexedPresetFileEntry> _presetsForSelectedCard = [];
  String? _currentPresetSearchText;
  List<String> _liveSdCardPresets = [];

  bool get _useLiveSdScan {
    final state = widget.distingCubit.state;
    if (state is DistingStateSynchronized) {
      return FirmwareVersion(state.distingVersion).hasSdCardSupport &&
          !state.offline;
    }
    return false;
  }

  @override
  void initState() {
    super.initState();
    _controller.text = widget.initialName.trim();
    _loadScannedCards(); // Always load local DB scanned cards
    _fetchLiveSdCardPresets(); // Always attempt to fetch live presets (will check firmware/online internally)
    _loadHistoryFromPrefs(); // Load history for autocomplete
  }

  Future<void> _fetchLiveSdCardPresets() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final presets = await widget.distingCubit.fetchSdCardPresets();
      if (mounted) {
        setState(() {
          _liveSdCardPresets = presets;
        });
      }
    } catch (e, stackTrace) {
      debugPrint("Error fetching live SD card presets: $e");
      debugPrintStack(stackTrace: stackTrace);
      if (mounted) {
        setState(() {
          _liveSdCardPresets = [];
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
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

  /// Removes a name from the local history list and saves the updated list.
  Future<void> _removeNameFromHistory(String name) async {
    final prefs = widget.preferences ?? await SharedPreferences.getInstance();
    setState(() {
      _history.remove(name);
      // List remains sorted after removal
    });
    await prefs.setStringList('presetHistory', _history);
  }

  Future<void> _onCancel() {
    if (!mounted) return Future.value(); // Add mounted check
    Navigator.of(context).pop(null); // Indicate "load was cancelled"
    return Future.value();
  }

  Future<void> _onAppend() async {
    if (!mounted) return; // Add mounted check
    await _handlePresetSelection(isAppending: true);
  }

  Future<void> _onLoad() async {
    if (!mounted) return; // Add mounted check
    await _handlePresetSelection(isAppending: false);
  }

  Future<void> _handlePresetSelection({required bool isAppending}) async {
    setState(() {
      _isLoading = true; // Set loading to true
    });
    try {
      final trimmed = _controller.text.trim();
      if (trimmed.isEmpty) return;

      // Attempt 1: Match on Live SD Card Scan (if enabled and data available)
      if (_useLiveSdScan) {
        // Check against _liveSdCardPresets
        if (_liveSdCardPresets.contains(trimmed)) {
          await _addNameToHistory(trimmed);
          if (!mounted) return; // Add mounted check
          Navigator.of(context).pop({
            "sdCardPath": trimmed,
            "append": isAppending,
            "displayName": trimmed.split('/').last
          });
          return;
        }
      }

      // Attempt 2: Match on Currently Selected SD Card (from local DB)
      if (_selectedSdCard != null) {
        final presetOnCurrentCard = _presetsForSelectedCard.firstWhereOrNull(
            (p) => _getDisplayPath(p) == trimmed || p.fileName == trimmed);
        if (presetOnCurrentCard != null) {
          String pathForEngine = "/${presetOnCurrentCard.relativePath}";
          await _addNameToHistory(trimmed);
          if (!mounted) return; // Add mounted check
          Navigator.of(context).pop({
            "sdCardPath": pathForEngine,
            "append": isAppending,
            "displayName": trimmed
          });
          return;
        }
      }

      // Attempt 3: Resolve History Item or General Text Input Across All SD Cards (from local DB)
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
            return true;
          }
          return _getDisplayPath(p) == trimmed || p.fileName == trimmed;
        });

        if (matchedPreset != null) {
          String pathForEngine = "/${matchedPreset.relativePath}";
          await _addNameToHistory(trimmed);
          if (!mounted) return; // Add mounted check
          Navigator.of(context).pop({
            "sdCardPath": pathForEngine,
            "append": isAppending,
            "displayName": trimmed
          });
          return;
        }
      }

      debugPrint(
          "'$trimmed' could not be resolved to a full path on any scanned SD card.");
    } finally {
      setState(() {
        _isLoading = false; // Always set loading to false
      });
    }
  }

  String _getDisplayPath(IndexedPresetFileEntry preset) {
    if (preset.relativePath.isEmpty) {
      return preset
          .fileName; // Should not happen if relativePath includes filename
    }
    final segments = preset.relativePath.split('/');
    if (segments.length > 2) {
      // Takes the last folder and the filename
      return "${segments[segments.length - 2]}/${segments.last}";
    } else {
      // It's just a filename, or in the root of 'presets'
      return preset.relativePath;
    }
  }

  // Helper to get the display string for an option, used by optionsBuilder and for sorting.
  String _getDisplayStringForOption(Object option) {
    if (option is IndexedPresetFileEntry) {
      return _getDisplayPath(option);
    } else if (option is String) {
      // Heuristic: If it looks like a file path (contains / and ends with .prst),
      // treat it as a live SD preset path and show only the filename.
      // Otherwise, assume it's a history item and prefix it.
      if (option.contains('/') && option.toLowerCase().endsWith('.prst')) {
        return option.split('/').last;
      } else {
        return "Recent: $option";
      }
    }
    return '';
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
              if (_isLoading) LinearProgressIndicator(),
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
        if (!_useLiveSdScan && _scannedCards.isNotEmpty)
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
                child: Text(card.systemIdentifier ?? card.userLabel),
              );
            }).toList(),
            onChanged: (SdCardEntry? newValue) {
              _loadPresetsForCard(newValue);
            },
          ),
        if (!_useLiveSdScan && _scannedCards.isEmpty)
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
                      // Use the helper for display text
                      String displayText = _getDisplayStringForOption(option);
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
              // If it's a string, it could be a history item or a live SD path.
              // For live SD paths, we want the full path, not just the filename.
              // For history, it's just the name.
              if (selection.contains('/') &&
                  selection.toLowerCase().endsWith('.prst')) {
                textToSet = selection;
              } else {
                textToSet = selection;
              }
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
            final searchTextLower = textEditingValue.text.toLowerCase();
            final Set<String> uniqueDisplayTexts =
                {}; // To prevent duplicates based on display text
            final List<Object> allPotentialOptions = [];

            // Add history items
            for (final historyItem in _history) {
              allPotentialOptions.add(historyItem);
            }

            // Add live SD card presets (if enabled)
            if (_useLiveSdScan) {
              for (final path in _liveSdCardPresets) {
                allPotentialOptions.add(path);
              }
            }

            // Add presets from selected card (from local DB)
            if (_selectedSdCard != null) {
              for (final preset in _presetsForSelectedCard) {
                allPotentialOptions.add(preset);
              }
            }

            // Filter and de-duplicate
            final List<Object> filteredAndUniqueOptions = [];
            for (final option in allPotentialOptions) {
              final displayString = _getDisplayStringForOption(option);
              if (searchTextLower.isEmpty ||
                  displayString.toLowerCase().contains(searchTextLower)) {
                // For IndexedPresetFileEntry, also check other fields for a more comprehensive match
                if (option is IndexedPresetFileEntry) {
                  final searchText = textEditingValue.text.toLowerCase();
                  final displayPath = _getDisplayPath(option).toLowerCase();
                  final matchConditions = (displayPath.contains(searchText) ||
                      option.fileName.toLowerCase().contains(searchText) ||
                      option.relativePath.toLowerCase().contains(searchText) ||
                      (option.algorithmNameFromPreset?.isNotEmpty == true &&
                          option.algorithmNameFromPreset!
                              .toLowerCase()
                              .contains(searchText)) ||
                      (option.notesFromPreset?.isNotEmpty == true &&
                          option.notesFromPreset!
                              .toLowerCase()
                              .contains(searchText)));
                  if (!matchConditions && searchTextLower.isNotEmpty) {
                    continue; // Skip if it doesn't match additional criteria and search text is not empty
                  }
                }

                if (uniqueDisplayTexts.add(displayString)) {
                  filteredAndUniqueOptions.add(option);
                }
              }
            }

            // Sort the final combined options by their display string
            filteredAndUniqueOptions.sort((a, b) {
              final String displayA = _getDisplayStringForOption(a);
              final String displayB = _getDisplayStringForOption(b);
              return displayA.toLowerCase().compareTo(displayB.toLowerCase());
            });

            return filteredAndUniqueOptions;
          },
          displayStringForOption: (Object option) {
            return _getDisplayStringForOption(option);
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
      Builder(
        builder: (context) {
          final bool canEnableButtons = !_isLoading &&
              (_useLiveSdScan ||
                  (_selectedSdCard != null &&
                      _controller.text.trim().isNotEmpty));
          return ElevatedButton(
            key: ValueKey('load_preset_dialog_append_button'),
            onPressed: canEnableButtons ? _onAppend : null,
            child: const Text('APPEND'),
          );
        },
      ),
      Builder(
        builder: (context) {
          final bool canEnableButtons = !_isLoading &&
              (_useLiveSdScan ||
                  (_selectedSdCard != null &&
                      _controller.text.trim().isNotEmpty));
          return ElevatedButton(
            key: ValueKey('load_preset_dialog_load_button'),
            onPressed: canEnableButtons ? _onLoad : null,
            child: const Text('LOAD'),
          );
        },
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
