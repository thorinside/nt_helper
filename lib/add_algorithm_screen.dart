import 'dart:async'; // Added for Timer

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:nt_helper/cubit/disting_cubit.dart';

import 'package:collection/collection.dart';
import 'package:nt_helper/domain/disting_nt_sysex.dart' show AlgorithmInfo;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nt_helper/services/algorithm_metadata_service.dart';
import 'package:nt_helper/ui/algorithm_documentation_screen.dart';

class AddAlgorithmScreen extends StatefulWidget {
  const AddAlgorithmScreen({super.key});

  @override
  State<AddAlgorithmScreen> createState() => _AddAlgorithmScreenState();
}

class _AddAlgorithmScreenState extends State<AddAlgorithmScreen> {
  static const _favKey = 'favorite_algorithm_guids';
  static const _showFavOnlyKey =
      'add_algo_show_fav_only'; // Key for toggle state

  // State for new UI
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce; // Timer for debouncing search input
  List<AlgorithmInfo> _allAlgorithms = [];
  List<AlgorithmInfo> _filteredAlgorithms = [];
  Set<String> _favoriteGuids = {}; // Store favorite GUIDs
  bool _showFavoritesOnly = false; // State for the favorite toggle
  bool _isHelpAvailableForSelected = false;

  // New state for category filters
  List<String> _allCategories = [];
  Set<String> _selectedCategories = {};

  // New scroll controllers to fix Scrollbar exception
  final ScrollController _chipScrollController = ScrollController();
  final ScrollController _specScrollController = ScrollController();

  // Original state variables
  String? selectedAlgorithmGuid;
  AlgorithmInfo? _currentAlgoInfo;
  List<int>? specValues;

  @override
  void initState() {
    super.initState();
    _loadSettings(); // Load both favorites and toggle state
    _loadCategories();
    _searchController.addListener(_onSearchChanged); // Use debounced listener

    // Initialize algorithm lists based on current DistingCubit state
    final distingState = context.read<DistingCubit>().state;
    if (distingState
        case DistingStateSynchronized(algorithms: final algorithms)) {
      _allAlgorithms = List<AlgorithmInfo>.from(algorithms)
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      // Initial filter
      _filterAlgorithms();
    } else {
      _allAlgorithms = [];
      _filteredAlgorithms = [];
    }
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounce?.cancel(); // Cancel timer on dispose
    _chipScrollController.dispose();
    _specScrollController.dispose();
    super.dispose();
  }

  // --- Debounced Search Handler ---
  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      // Check if mounted before calling _filterAlgorithms, as timer might fire after dispose
      if (mounted) {
        _filterAlgorithms();
      }
    });
  }

  // --- Settings Management (Favorites + Toggle State) ---

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final favs = prefs.getStringList(_favKey) ?? [];
    final showOnlyFavs = prefs.getBool(_showFavOnlyKey) ?? false;
    setState(() {
      _favoriteGuids = favs.toSet();
      _showFavoritesOnly = showOnlyFavs;
      // Re-filter after loading settings
      _filterAlgorithms();
    });
  }

  Future<void> _saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_favKey, _favoriteGuids.toList());
  }

  Future<void> _saveShowFavoritesOnlyState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_showFavOnlyKey, _showFavoritesOnly);
  }

  void _toggleFavorite(String guid) {
    setState(() {
      if (_favoriteGuids.contains(guid)) {
        _favoriteGuids.remove(guid);
      } else {
        _favoriteGuids.add(guid);
      }
      _saveFavorites(); // Save favorite list changes
      _filterAlgorithms(); // Re-filter to update list if needed (e.g., if showFavOnly is true) and update chip icon
    });
  }

  void _toggleShowFavoritesOnly() {
    // Unfocus search field when toggling favorites
    FocusScope.of(context).unfocus();
    setState(() {
      _showFavoritesOnly = !_showFavoritesOnly;
      _saveShowFavoritesOnlyState(); // Save toggle state changes
      _filterAlgorithms(); // Re-filter based on new toggle state
    });
  }

  // --- Documentation Navigation ---
  void _showDocumentation(String guid) async {
    // Unfocus search field when showing docs
    FocusScope.of(context).unfocus();
    final metadata = AlgorithmMetadataService().getAlgorithmByGuid(guid);
    if (metadata != null && mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) =>
              AlgorithmDocumentationScreen(metadata: metadata),
        ),
      );
    } else {
      // Optional: Show a snackbar or dialog if metadata is not found
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Full documentation for this algorithm is not available.'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _loadCategories() {
    final allAlgos = AlgorithmMetadataService().getAllAlgorithms();
    final allCats = allAlgos.expand((algo) => algo.categories).toSet().toList();
    allCats.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    if (mounted) {
      setState(() {
        _allCategories = allCats;
      });
    }
  }

  // --- Filtering Logic ---

  void _filterAlgorithms() {
    final query = _searchController.text.toLowerCase();
    // No need for setState here if only called from debounced handler or initState/load
    // setState is handled in the calling methods (_onSearchChanged, _loadSettings, etc.)

    List<AlgorithmInfo> baseList;
    if (_showFavoritesOnly) {
      baseList = _allAlgorithms
          .where((algo) => _favoriteGuids.contains(algo.guid))
          .toList();
    } else {
      baseList = List.from(_allAlgorithms);
    }

    // Filter by selected categories
    if (_selectedCategories.isNotEmpty) {
      final service = AlgorithmMetadataService();
      baseList = baseList.where((algoInfo) {
        final metadata = service.getAlgorithmByGuid(algoInfo.guid);
        if (metadata == null) return false;
        return metadata.categories
            .any((cat) => _selectedCategories.contains(cat));
      }).toList();
    }

    if (query.isEmpty) {
      _filteredAlgorithms = baseList;
    } else {
      _filteredAlgorithms = baseList
          .where((algo) => algo.name.toLowerCase().contains(query))
          .toList();
    }

    _filteredAlgorithms
        .sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    // Use WidgetsBinding to ensure setState is called safely after build if needed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          // If the currently selected algorithm is no longer in the filtered list, deselect it
          if (selectedAlgorithmGuid != null &&
              !_filteredAlgorithms
                  .any((algo) => algo.guid == selectedAlgorithmGuid)) {
            _clearSelection(); // This already calls setState
          } else {
            // Ensure UI rebuilds with the filtered list
            // This setState might be redundant if _clearSelection was called, but safe to include.
            setState(() {});
          }
        });
      }
    });
  }

  // --- Selection Logic ---
  void _selectAlgorithm(String? guid) {
    // Unfocus search field when selecting an algorithm
    FocusScope.of(context).unfocus();
    setState(() {
      selectedAlgorithmGuid = guid;
      _currentAlgoInfo = _allAlgorithms.firstWhereOrNull((a) => a.guid == guid);
      specValues =
          _currentAlgoInfo?.specifications.map((s) => s.defaultValue).toList();

      if (guid != null) {
        final metadata = AlgorithmMetadataService().getAlgorithmByGuid(guid);
        _isHelpAvailableForSelected = metadata != null;
      } else {
        _isHelpAvailableForSelected = false;
      }
    });
  }

  void _clearSelection() {
    // No need to unfocus here as it happens when list updates remove selection
    setState(() {
      selectedAlgorithmGuid = null;
      _currentAlgoInfo = null;
      specValues = null;
      _isHelpAvailableForSelected = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final distingState = context.watch<DistingCubit>().state;
    final bool isOffline = switch (distingState) {
      DistingStateSynchronized(offline: final o) => o,
      _ => false,
    };

    // Update allAlgorithms if the state changes (e.g., going online/offline)
    if (distingState
        case DistingStateSynchronized(algorithms: final algorithms)) {
      if (!listEquals(_allAlgorithms, algorithms)) {
        _allAlgorithms = List<AlgorithmInfo>.from(algorithms)
          ..sort(
              (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _filterAlgorithms();
          }
        });
      }
    } else {
      if (_allAlgorithms.isNotEmpty) {
        _allAlgorithms = [];
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _filterAlgorithms();
          }
        });
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Algorithm'),
      ),
      floatingActionButton: _isHelpAvailableForSelected
          ? FloatingActionButton(
              onPressed: () => _showDocumentation(selectedAlgorithmGuid!),
              child: const Icon(Icons.question_mark),
            )
          : null,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: switch (distingState) {
            DistingStateSynchronized() => () {
                if (_allAlgorithms.isEmpty && !_showFavoritesOnly) {
                  // Show only if not in fav-only mode and list is truly empty
                  return const Center(
                      child: Text('No algorithms available in current state.'));
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // --- Search Row ---
                    Row(
                      // Align items vertically center
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              labelText: 'Search Algorithms',
                              hintText: _showFavoritesOnly
                                  ? 'Search within favorites...'
                                  : 'Enter algorithm name...',
                              prefixIcon: const Icon(Icons.search),
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear),
                                      onPressed: () {
                                        _searchController.clear();
                                      },
                                    )
                                  : null,
                              border: const OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: Icon(_showFavoritesOnly
                              ? Icons.star
                              : Icons.star_border),
                          tooltip: 'Show Favorites Only',
                          color: _showFavoritesOnly
                              ? Theme.of(context).colorScheme.primary
                              : null,
                          onPressed: _toggleShowFavoritesOnly,
                          constraints: const BoxConstraints(),
                          padding: const EdgeInsets.all(12),
                        ),
                        const SizedBox(width: 4),
                        TextButton.icon(
                          icon: const Icon(Icons.filter_alt_off),
                          label: const Text('Clear Filters'),
                          style: TextButton.styleFrom(
                            foregroundColor:
                                Theme.of(context).colorScheme.secondary,
                          ),
                          onPressed: () {
                            FocusScope.of(context).unfocus();
                            setState(() {
                              _searchController.clear();
                              _showFavoritesOnly = false;
                              _selectedCategories.clear();
                              _saveShowFavoritesOnlyState();
                              _filterAlgorithms();
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildCategoryFilterButton(),
                    const Divider(),

                    // --- Algorithm Chips (Expanded to allow scrolling) ---
                    Expanded(
                      flex: 3, // Give more space to chips
                      child: _filteredAlgorithms.isEmpty
                          ? Center(
                              child: Text(_showFavoritesOnly
                                  ? (_favoriteGuids.isEmpty
                                      ? 'No algorithms marked as favorite.'
                                      : 'No favorites match "${_searchController.text}".')
                                  : 'No algorithms match "${_searchController.text}".'))
                          : Scrollbar(
                              controller: _chipScrollController,
                              // Add scrollbar for chip area
                              child: SingleChildScrollView(
                                controller: _chipScrollController,
                                // Inner scroll view for chips
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: Wrap(
                                  spacing: 8.0,
                                  runSpacing: 4.0,
                                  children: _filteredAlgorithms.map((algo) {
                                    final bool isSelected =
                                        selectedAlgorithmGuid == algo.guid;
                                    final bool isFavorite =
                                        _favoriteGuids.contains(algo.guid);
                                    return GestureDetector(
                                      onLongPress: () =>
                                          _toggleFavorite(algo.guid),
                                      child: ChoiceChip(
                                        label: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Flexible(
                                              child: Text(
                                                algo.name,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            if (isFavorite) ...[
                                              const SizedBox(width: 8.0),
                                              Icon(
                                                Icons.star,
                                                size: 16,
                                                color: isSelected
                                                    ? Theme.of(context)
                                                        .colorScheme
                                                        .onPrimaryContainer
                                                    : Theme.of(context)
                                                        .colorScheme
                                                        .primary,
                                              ),
                                            ],
                                          ],
                                        ),
                                        selected: isSelected,
                                        onSelected: (bool selected) {
                                          if (selected) {
                                            _selectAlgorithm(algo.guid);
                                          } else {
                                            if (isSelected) {
                                              _selectAlgorithm(null);
                                            }
                                          }
                                        },
                                        selectedColor: Theme.of(context)
                                            .colorScheme
                                            .primaryContainer,
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                    ),

                    const Divider(),
                    const SizedBox(height: 12),

                    // --- Specification Inputs (Flexible) ---
                    if (_currentAlgoInfo != null &&
                        _currentAlgoInfo!.numSpecifications > 0)
                      Flexible(
                        flex: 2, // Give less space to specs, but still flexible
                        child: _buildSpecificationInputs(
                            _currentAlgoInfo!, isOffline),
                      ),

                    // --- Action Buttons (at the bottom) ---
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
                      child: ElevatedButton(
                        onPressed:
                            _currentAlgoInfo != null && specValues != null
                                ? () {
                                    Navigator.pop(context, {
                                      'algorithm': _currentAlgoInfo,
                                      'specValues': specValues,
                                    });
                                  }
                                : null,
                        child: const Text('Add to Preset'),
                      ),
                    ),
                  ],
                );
              }(),
            _ => const Center(child: CircularProgressIndicator()),
          },
        ),
      ),
    );
  }

  // --- Category Filter Button (Dialog-based Multi-Select) ---
  Widget _buildCategoryFilterButton() {
    return Align(
      alignment: Alignment.centerLeft,
      child: ElevatedButton.icon(
        icon: const Icon(Icons.filter_list),
        label: Text(
          _selectedCategories.isEmpty
              ? 'Filter by Category'
              : 'Categories (${_selectedCategories.length})',
        ),
        onPressed: () async {
          final selected = await showDialog<Set<String>>(
            context: context,
            builder: (context) {
              final tempSelected = Set<String>.from(_selectedCategories);
              return StatefulBuilder(
                builder: (context, setStateDialog) => AlertDialog(
                  title: const Text('Select Categories'),
                  content: SizedBox(
                    width: 320,
                    height: 300,
                    child: ListView(
                      shrinkWrap: true,
                      children: _allCategories.map((category) {
                        return CheckboxListTile(
                          value: tempSelected.contains(category),
                          title: Text(category),
                          onChanged: (checked) {
                            setStateDialog(() {
                              if (checked == true) {
                                tempSelected.add(category);
                              } else {
                                tempSelected.remove(category);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        setStateDialog(() {
                          tempSelected.clear();
                        });
                      },
                      child: const Text('Clear'),
                    ),
                    TextButton(
                      onPressed: () =>
                          Navigator.pop(context, _selectedCategories),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, tempSelected),
                      child: const Text('Apply'),
                    ),
                  ],
                ),
              );
            },
          );
          if (selected != null) {
            setState(() {
              _selectedCategories = selected;
              _filterAlgorithms();
            });
          }
        },
      ),
    );
  }

  Widget _buildSpecificationInputs(AlgorithmInfo algorithm, bool isOffline) {
    if (specValues == null ||
        specValues!.length != algorithm.numSpecifications ||
        _currentAlgoInfo?.guid != algorithm.guid) {
      specValues = algorithm.specifications.map((s) => s.defaultValue).toList();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {});
        }
      });
      return const Center(
          child: Padding(
        padding: EdgeInsets.all(8.0),
        child: Text("Loading specifications..."),
      ));
    }

    return Scrollbar(
      controller: _specScrollController,
      child: SingleChildScrollView(
        controller: _specScrollController,
        child: Column(
          mainAxisSize: MainAxisSize.min, // Specs column takes minimum height
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text(
                'Specifications:',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            ...List.generate(algorithm.numSpecifications, (index) {
              final specInfo = algorithm.specifications[index];
              if (index >= specValues!.length) {
                return const SizedBox.shrink(); // Avoid index error
              }
              // Define the TextFormField
              final textField = TextFormField(
                key: ValueKey('${algorithm.guid}_spec_$index'),
                initialValue: specValues![index].toString(),
                readOnly: isOffline,
                decoration: InputDecoration(
                  labelText: specInfo.name.isNotEmpty
                      ? specInfo.name
                      : 'Specification ${index + 1}',
                  hintText: '(${specInfo.min} to ${specInfo.max})',
                  border: const OutlineInputBorder(),
                  // Reduce density for specs section
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12.0, vertical: 10.0),
                ),
                keyboardType: TextInputType.number,
                onChanged: isOffline
                    ? null
                    : (value) {
                        int parsedValue =
                            int.tryParse(value) ?? specInfo.defaultValue;
                        parsedValue =
                            parsedValue.clamp(specInfo.min, specInfo.max);
                        if (index < specValues!.length &&
                            specValues![index] != parsedValue) {
                          setState(() {
                            specValues![index] = parsedValue;
                          });
                        }
                      },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a value';
                  }
                  final int? parsed = int.tryParse(value);
                  if (parsed == null) {
                    return 'Please enter a number';
                  }
                  if (parsed < specInfo.min || parsed > specInfo.max) {
                    return 'Value must be between ${specInfo.min} and ${specInfo.max}';
                  }
                  return null; // Valid
                },
                autovalidateMode: AutovalidateMode.onUserInteraction,
              );

              // Wrap with Tooltip only if offline
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: isOffline
                    ? Tooltip(
                        message: 'Defaults are used in offline mode',
                        child: textField,
                      )
                    : textField,
              );
            }),
          ],
        ),
      ),
    );
  }
}
