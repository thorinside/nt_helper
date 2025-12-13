import 'dart:async'; // Added for Timer

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nt_helper/cubit/disting_cubit.dart';

import 'package:collection/collection.dart';
import 'package:nt_helper/domain/disting_nt_sysex.dart' show AlgorithmInfo;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nt_helper/models/algorithm_metadata.dart';
import 'package:nt_helper/services/algorithm_metadata_service.dart';
import 'package:nt_helper/ui/algorithm_documentation_screen.dart';

/// View modes for displaying algorithms in the Add Algorithm screen
enum AlgorithmViewMode { chipGrid, list, column }

class AddAlgorithmScreen extends StatefulWidget {
  const AddAlgorithmScreen({super.key});

  @override
  State<AddAlgorithmScreen> createState() => _AddAlgorithmScreenState();
}

class _AddAlgorithmScreenState extends State<AddAlgorithmScreen> {
  static const _favKey = 'favorite_algorithm_guids';
  static const _showFavOnlyKey =
      'add_algo_show_fav_only'; // Key for toggle state
  static const _pluginTypeKey = 'add_algo_plugin_type';
  static const _viewModeKey = 'add_algorithm_view_mode';

  // Plugin type options
  static const String _pluginTypeAll = 'all';
  static const String _pluginTypeFactory = 'factory';
  static const String _pluginTypeCommunity = 'community';

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

  // Plugin type filter state
  String _selectedPluginType = _pluginTypeAll;

  // View mode state
  AlgorithmViewMode _selectedViewMode = AlgorithmViewMode.chipGrid;

  // Scroll controllers for algorithm views
  final ScrollController _chipScrollController = ScrollController();
  final ScrollController _listScrollController = ScrollController();
  final ScrollController _columnScrollController = ScrollController();

  // Cached metadata service instance
  final _metadataService = AlgorithmMetadataService();

  // Keyboard navigation state
  int _focusedIndex = -1;
  final FocusNode _viewFocusNode = FocusNode();

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
    if (distingState case DistingStateSynchronized(
      algorithms: final algorithms,
    )) {
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
    _debounce?.cancel();
    _chipScrollController.dispose();
    _listScrollController.dispose();
    _columnScrollController.dispose();
    _viewFocusNode.dispose();
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
    final pluginType = prefs.getString(_pluginTypeKey) ?? _pluginTypeAll;
    final modeIndex = prefs.getInt(_viewModeKey) ?? 0;
    setState(() {
      _favoriteGuids = favs.toSet();
      _showFavoritesOnly = showOnlyFavs;
      _selectedPluginType = pluginType;
      _selectedViewMode = AlgorithmViewMode.values[modeIndex.clamp(0, 2)];
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

  Future<void> _savePluginTypeState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pluginTypeKey, _selectedPluginType);
  }

  Future<void> _saveViewModeState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_viewModeKey, _selectedViewMode.index);
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
    final metadata = _metadataService.getAlgorithmByGuid(guid);
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
          content: Text(
            'Full documentation for this algorithm is not available.',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _loadCategories() {
    final allAlgos = _metadataService.getAllAlgorithms();
    final allCats = allAlgos.expand((algo) => algo.categories).toSet().toList();
    allCats.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    if (mounted) {
      setState(() {
        _allCategories = allCats;
      });
    }
  }

  // --- Plugin Type Detection ---
  String _getPluginType(String guid) {
    // Factory algorithms have all lowercase GUIDs
    // Plugins have any uppercase characters
    return guid == guid.toLowerCase()
        ? _pluginTypeFactory
        : _pluginTypeCommunity;
  }

  bool _isPlugin(String guid) {
    return guid != guid.toLowerCase();
  }

  bool _needsLoading(AlgorithmInfo algorithm) {
    return _isPlugin(algorithm.guid) && !algorithm.isLoaded;
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

    // Filter by plugin type
    if (_selectedPluginType != _pluginTypeAll) {
      baseList = baseList.where((algo) {
        final pluginType = _getPluginType(algo.guid);
        return pluginType == _selectedPluginType;
      }).toList();
    }

    // Filter by selected categories
    if (_selectedCategories.isNotEmpty) {
      baseList = baseList.where((algoInfo) {
        // Normalize GUID to lowercase for consistent lookup
        final metadata = _metadataService.getAlgorithmByGuid(algoInfo.guid.toLowerCase());
        // If no metadata, show algorithm (don't filter it out)
        if (metadata == null) return true;
        return metadata.categories.any(
          (cat) => _selectedCategories.contains(cat),
        );
      }).toList();
    }

    if (query.isEmpty) {
      _filteredAlgorithms = baseList;
    } else {
      _filteredAlgorithms = baseList
          .where((algo) => algo.name.toLowerCase().contains(query))
          .toList();
    }

    _filteredAlgorithms.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );

    // Use WidgetsBinding to ensure setState is called safely after build if needed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // If the currently selected algorithm is no longer in the filtered list, deselect it
      if (selectedAlgorithmGuid != null &&
          !_filteredAlgorithms.any(
            (algo) => algo.guid == selectedAlgorithmGuid,
          )) {
        _clearSelection(); // Calls setState internally
      } else {
        // Trigger UI rebuild with the filtered list
        setState(() {});
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
      specValues = _currentAlgoInfo?.specifications
          .map((s) => s.defaultValue)
          .toList();

      if (guid != null) {
        final metadata = _metadataService.getAlgorithmByGuid(guid);
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

  /// Load a plugin to get its full specifications
  void _loadPlugin(String algorithmGuid) async {
    final algorithm = _allAlgorithms.firstWhereOrNull(
      (algo) => algo.guid == algorithmGuid,
    );
    if (algorithm == null) return;

    // Show loading indicator
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Loading plugin ${algorithm.name}...'),
          duration: const Duration(seconds: 5),
        ),
      );
    }

    try {
      final cubit = context.read<DistingCubit>();

      final loadedInfo = await cubit.loadPlugin(algorithmGuid);

      if (loadedInfo != null && mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${loadedInfo.name} loaded with ${loadedInfo.numSpecifications} specifications',
            ),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.green,
          ),
        );

        // The cubit has already updated the global state, no need for manual local updates
        // Just update the currently selected algorithm info if it matches
        if (selectedAlgorithmGuid == algorithmGuid) {
          setState(() {
            _currentAlgoInfo = loadedInfo;
            specValues = loadedInfo.specifications
                .map((s) => s.defaultValue)
                .toList();
          });
          // Trigger filtering to update the display
          _filterAlgorithms();
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load ${algorithm.name}'),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading ${algorithm.name}: $e'),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final distingState = context.watch<DistingCubit>().state;
    final bool isOffline = switch (distingState) {
      DistingStateSynchronized(offline: final o) => o,
      _ => false,
    };

    // Update allAlgorithms if the state changes (e.g., going online/offline)
    if (distingState case DistingStateSynchronized(
      algorithms: final algorithms,
    )) {
      if (!listEquals(_allAlgorithms, algorithms)) {
        _allAlgorithms = List<AlgorithmInfo>.from(
          algorithms,
        )..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

        // If we have a currently selected algorithm, update it to reflect the latest state
        if (selectedAlgorithmGuid != null) {
          final updatedAlgo = _allAlgorithms.firstWhereOrNull(
            (a) => a.guid == selectedAlgorithmGuid,
          );
          if (updatedAlgo != null && _currentAlgoInfo != null) {
            _currentAlgoInfo = updatedAlgo;
            // Update specValues if the number of specifications changed
            if (_currentAlgoInfo!.specifications.length != (specValues?.length ?? 0)) {
              specValues = _currentAlgoInfo!.specifications
                  .map((s) => s.defaultValue)
                  .toList();
            }
          }
        }

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
        actions: [
          // Rescan Plugins button - only visible when connected to real hardware
          if (!isOffline)
            IconButton(
              icon: const Icon(Icons.sync),
              tooltip: 'Rescan Plugins on Hardware',
              onPressed: () async {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Rescanning plugins on hardware...'),
                    duration: Duration(seconds: 2),
                  ),
                );
                await context.read<DistingCubit>().rescanPlugins();
              },
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Algorithm List',
            onPressed: () {
              // Call the refresh method from DistingCubit
              context.read<DistingCubit>().refreshAlgorithms();

              // Show a brief feedback to user
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Refreshing algorithm list...'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Add Algorithm Help'),
                  content: const Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '• Long press any algorithm to add/remove from favorites',
                      ),
                      SizedBox(height: 8),
                      Text(
                        '• Select a plugin to see a "Load Plugin" button if it needs loading',
                      ),
                      SizedBox(height: 8),
                      Text(
                        '• Plugins show full specifications only after being loaded',
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: _isHelpAvailableForSelected
          ? FloatingActionButton(
              onPressed: () => _showDocumentation(selectedAlgorithmGuid!),
              child: const Icon(Icons.question_mark),
            )
          : null,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: switch (distingState) {
          DistingStateSynchronized() => () {
            if (_allAlgorithms.isEmpty && !_showFavoritesOnly) {
              // Show only if not in fav-only mode and list is truly empty
              return const Center(
                child: Text('No algorithms available in current state.'),
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // --- Top Section with padding ---
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0),
                    child: Column(
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
                              icon: Icon(
                                _showFavoritesOnly ? Icons.star : Icons.star_border,
                              ),
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
                                foregroundColor: Theme.of(
                                  context,
                                ).colorScheme.secondary,
                              ),
                              onPressed: () {
                                FocusScope.of(context).unfocus();
                                setState(() {
                                  _searchController.clear();
                                  _showFavoritesOnly = false;
                                  _selectedCategories.clear();
                                  _selectedPluginType = _pluginTypeAll;
                                  _saveShowFavoritesOnlyState();
                                  _filterAlgorithms();
                                });
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _buildPluginTypeFilterButton(),
                            const SizedBox(width: 16),
                            Expanded(child: _buildCategoryFilterButton()),
                            const SizedBox(width: 16),
                            _buildViewModeSelector(),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Showing ${_filteredAlgorithms.length} of ${_allAlgorithms.length} algorithms',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                        ),
                        const Divider(),

                        // --- Algorithm Display (Expanded to take remaining space) ---
                        Expanded(
                          child: _filteredAlgorithms.isEmpty
                              ? Center(
                                  child: Text(
                                    _showFavoritesOnly
                                        ? (_favoriteGuids.isEmpty
                                              ? 'No algorithms marked as favorite.'
                                              : 'No favorites match "${_searchController.text}".')
                                        : 'No algorithms match "${_searchController.text}".',
                                  ),
                                )
                              : _buildAlgorithmView(),
                        ),
                      ],
                    ),
                  ),
                ),

                // --- Bottom Section with background (outside padding) ---
                Container(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // --- Specification Inputs (Auto-sized to content) ---
                      if (_currentAlgoInfo != null &&
                          _currentAlgoInfo!.numSpecifications > 0) ...[
                        const Divider(),
                        const SizedBox(height: 12),
                        _buildSpecificationInputs(_currentAlgoInfo!, isOffline),
                      ],

                      // --- Action Buttons (fixed at the bottom) ---
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        padding: EdgeInsets.only(
                          top: 16.0,
                          // Add extra padding when FAB is visible to prevent overlap
                          right: _isHelpAvailableForSelected ? 72.0 : 0.0,
                        ),
                        child: _buildActionButton(isOffline),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }(),
          _ => const Center(child: CircularProgressIndicator()),
        },
      ),
    );
  }

  // --- Plugin Type Filter Button (Dialog-based Select) ---
  Widget _buildPluginTypeFilterButton() {
    return Align(
      alignment: Alignment.centerLeft,
      child: ElevatedButton.icon(
        icon: const Icon(Icons.extension),
        label: Text(
          _selectedPluginType == _pluginTypeAll
              ? 'Plugin Type'
              : _selectedPluginType == _pluginTypeFactory
              ? 'Factory'
              : 'Community',
        ),
        onPressed: () async {
          final selected = await showDialog<String>(
            context: context,
            builder: (context) {
              String tempSelected = _selectedPluginType;
              return StatefulBuilder(
                builder: (context, setStateDialog) => AlertDialog(
                  title: const Text('Select Plugin Type'),
                  content: RadioGroup<String>(
                    groupValue: tempSelected,
                    onChanged: (value) {
                      setStateDialog(() {
                        tempSelected = value!;
                      });
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(
                          leading: Radio<String>(value: _pluginTypeAll),
                          title: const Text('All Plugins'),
                          onTap: () {
                            setStateDialog(() {
                              tempSelected = _pluginTypeAll;
                            });
                          },
                        ),
                        ListTile(
                          leading: Radio<String>(value: _pluginTypeFactory),
                          title: const Text('Factory'),
                          subtitle: const Text(
                            'Algorithms with all lowercase GUIDs',
                          ),
                          onTap: () {
                            setStateDialog(() {
                              tempSelected = _pluginTypeFactory;
                            });
                          },
                        ),
                        ListTile(
                          leading: Radio<String>(value: _pluginTypeCommunity),
                          title: const Text('Community'),
                          subtitle: const Text(
                            'Algorithms with uppercase characters in GUID',
                          ),
                          onTap: () {
                            setStateDialog(() {
                              tempSelected = _pluginTypeCommunity;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () =>
                          Navigator.pop(context, _selectedPluginType),
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
              _selectedPluginType = selected;
              _savePluginTypeState();
              _filterAlgorithms();
            });
          }
        },
      ),
    );
  }

  // --- View Mode Selector ---
  Widget _buildViewModeSelector() {
    return SegmentedButton<AlgorithmViewMode>(
      segments: const [
        ButtonSegment(
          value: AlgorithmViewMode.chipGrid,
          icon: Icon(Icons.grid_view),
          tooltip: 'Chip Grid',
        ),
        ButtonSegment(
          value: AlgorithmViewMode.list,
          icon: Icon(Icons.view_list),
          tooltip: 'List',
        ),
        ButtonSegment(
          value: AlgorithmViewMode.column,
          icon: Icon(Icons.view_column),
          tooltip: 'Column',
        ),
      ],
      selected: {_selectedViewMode},
      onSelectionChanged: (selected) {
        setState(() => _selectedViewMode = selected.first);
        _saveViewModeState();
        // Scroll to selected item after view rebuilds
        if (selectedAlgorithmGuid != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _scrollToSelectedItem();
          });
        }
      },
      showSelectedIcon: false,
    );
  }

  // --- Algorithm View (Conditional Rendering) ---
  Widget _buildAlgorithmView() {
    return Focus(
      focusNode: _viewFocusNode,
      onKeyEvent: _handleKeyEvent,
      child: switch (_selectedViewMode) {
        AlgorithmViewMode.chipGrid => _buildChipGridView(),
        AlgorithmViewMode.list => _buildListView(),
        AlgorithmViewMode.column => _buildColumnView(),
      },
    );
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (_filteredAlgorithms.isEmpty) return KeyEventResult.ignored;

    // Initialize focus index if not set
    if (_focusedIndex < 0 && selectedAlgorithmGuid != null) {
      _focusedIndex = _filteredAlgorithms.indexWhere(
        (algo) => algo.guid == selectedAlgorithmGuid,
      );
    }
    if (_focusedIndex < 0) _focusedIndex = 0;

    int newIndex = _focusedIndex;

    if (event.logicalKey == LogicalKeyboardKey.arrowDown ||
        event.logicalKey == LogicalKeyboardKey.arrowRight) {
      newIndex = (_focusedIndex + 1).clamp(0, _filteredAlgorithms.length - 1);
    } else if (event.logicalKey == LogicalKeyboardKey.arrowUp ||
        event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      newIndex = (_focusedIndex - 1).clamp(0, _filteredAlgorithms.length - 1);
    } else if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.space) {
      if (_focusedIndex >= 0 && _focusedIndex < _filteredAlgorithms.length) {
        _selectAlgorithm(_filteredAlgorithms[_focusedIndex].guid);
        return KeyEventResult.handled;
      }
    } else {
      return KeyEventResult.ignored;
    }

    if (newIndex != _focusedIndex) {
      setState(() {
        _focusedIndex = newIndex;
      });
      _scrollToIndex(newIndex);
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  void _scrollToSelectedItem() {
    if (selectedAlgorithmGuid == null) return;

    final index = _filteredAlgorithms.indexWhere(
      (algo) => algo.guid == selectedAlgorithmGuid,
    );
    if (index < 0) return;

    final ScrollController controller = switch (_selectedViewMode) {
      AlgorithmViewMode.chipGrid => _chipScrollController,
      AlgorithmViewMode.list => _listScrollController,
      AlgorithmViewMode.column => _columnScrollController,
    };

    if (!controller.hasClients) return;

    final viewportHeight = controller.position.viewportDimension;
    final maxScroll = controller.position.maxScrollExtent;

    double targetOffset;

    if (_selectedViewMode == AlgorithmViewMode.column) {
      // Grid view: calculate row index based on column count
      // Get actual width from MediaQuery
      final screenWidth = MediaQuery.of(context).size.width - 32; // Account for padding
      final columnCount = screenWidth < 600 ? 2 : 3;
      final rowIndex = index ~/ columnCount;
      // Item height in grid (aspect ratio 1.5 means height = width / 1.5)
      // With spacing of 8, estimate row height
      final itemWidth = (screenWidth - (columnCount - 1) * 8) / columnCount;
      final rowHeight = itemWidth / 1.5 + 8;
      targetOffset = (rowIndex * rowHeight) - (viewportHeight / 2) + (rowHeight / 2);
    } else {
      // List views: simple index * height
      final double itemHeight = switch (_selectedViewMode) {
        AlgorithmViewMode.chipGrid => 48.0,
        AlgorithmViewMode.list => 120.0,
        AlgorithmViewMode.column => 150.0, // Won't reach here
      };
      targetOffset = (index * itemHeight) - (viewportHeight / 2) + (itemHeight / 2);
    }

    final scrollTo = targetOffset.clamp(0.0, maxScroll);

    controller.animateTo(
      scrollTo,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _scrollToIndex(int index) {
    if (_filteredAlgorithms.isEmpty) return;

    // Estimate item height based on view mode
    final double estimatedItemHeight = switch (_selectedViewMode) {
      AlgorithmViewMode.chipGrid => 40.0,
      AlgorithmViewMode.list => 72.0,
      AlgorithmViewMode.column => 120.0,
    };

    final ScrollController controller = switch (_selectedViewMode) {
      AlgorithmViewMode.chipGrid => _chipScrollController,
      AlgorithmViewMode.list => _listScrollController,
      AlgorithmViewMode.column => _columnScrollController,
    };

    if (!controller.hasClients) return;

    // For list view, we can calculate exact position
    if (_selectedViewMode == AlgorithmViewMode.list) {
      final targetOffset = index * estimatedItemHeight;
      final viewportHeight = controller.position.viewportDimension;
      final maxScroll = controller.position.maxScrollExtent;
      final scrollTo =
          (targetOffset - viewportHeight / 2 + estimatedItemHeight / 2)
              .clamp(0.0, maxScroll);
      controller.animateTo(
        scrollTo,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
      );
    }
    // For column view, we need to account for columns
    else if (_selectedViewMode == AlgorithmViewMode.column) {
      final columnCount = controller.position.viewportDimension < 600 ? 2 : 3;
      final rowIndex = index ~/ columnCount;
      final targetOffset = rowIndex * (estimatedItemHeight + 8);
      final viewportHeight = controller.position.viewportDimension;
      final maxScroll = controller.position.maxScrollExtent;
      final scrollTo = (targetOffset - viewportHeight / 2 + estimatedItemHeight / 2)
          .clamp(0.0, maxScroll);
      controller.animateTo(
        scrollTo,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
      );
    }
  }

  // --- Chip Grid View (Original View) ---
  Widget _buildChipGridView() {
    return Scrollbar(
      controller: _chipScrollController,
      child: SingleChildScrollView(
        controller: _chipScrollController,
        padding: const EdgeInsets.only(bottom: 8.0),
        child: Wrap(
          spacing: 8.0,
          runSpacing: 4.0,
          children: _filteredAlgorithms.map((algo) {
            final bool isSelected = selectedAlgorithmGuid == algo.guid;
            final bool isFavorite = _favoriteGuids.contains(algo.guid);
            final bool isCommunityPlugin =
                algo.guid != algo.guid.toLowerCase();
            return GestureDetector(
              onLongPress: () => _toggleFavorite(algo.guid),
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
                      const SizedBox(width: 4.0),
                      Icon(
                        Icons.star,
                        size: 16,
                        color: isSelected
                            ? Theme.of(context).colorScheme.onPrimaryContainer
                            : Theme.of(context).colorScheme.primary,
                      ),
                    ],
                    if (isCommunityPlugin) ...[
                      const SizedBox(width: 4.0),
                      Icon(
                        Icons.extension,
                        size: 14,
                        color: isSelected
                            ? Theme.of(context).colorScheme.onPrimaryContainer
                            : Theme.of(context).colorScheme.secondary,
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
                selectedColor: Theme.of(context).colorScheme.primaryContainer,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // --- List View ---
  Widget _buildListView() {
    return Scrollbar(
      controller: _listScrollController,
      child: ListView.separated(
        controller: _listScrollController,
        itemCount: _filteredAlgorithms.length,
        separatorBuilder: (context, index) => const Divider(height: 16),
        itemBuilder: (context, index) {
          final algo = _filteredAlgorithms[index];
          final isSelected = algo.guid == selectedAlgorithmGuid;
          final isFavorite = _favoriteGuids.contains(algo.guid);
          final isCommunityPlugin = _isPlugin(algo.guid);
          final metadata =
              _metadataService.getAlgorithmByGuid(algo.guid.toLowerCase());

          // ConstrainedBox ensures 56px minimum height for touch targets (AC 17)
          return ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: ListTile(
              selected: isSelected,
              selectedTileColor: Theme.of(context).colorScheme.primaryContainer,
              minVerticalPadding: 8,
              leading: isFavorite
                  ? const Icon(Icons.star, color: Colors.amber)
                  : const SizedBox(width: 24),
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      algo.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isCommunityPlugin)
                    Icon(
                      Icons.extension,
                      size: 16,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                ],
              ),
              subtitle: _buildListSubtitle(metadata, isCommunityPlugin),
              onTap: () => _selectAlgorithm(algo.guid),
              onLongPress: () => _toggleFavorite(algo.guid),
            ),
          );
        },
      ),
    );
  }

  Widget _buildListSubtitle(AlgorithmMetadata? metadata, bool isCommunityPlugin) {
    // For community plugins, show simplified metadata
    final categories = isCommunityPlugin
        ? ['Community Plugin']
        : (metadata?.categories ?? <String>[]);
    final description = isCommunityPlugin
        ? 'Manually installed community plugin.'
        : (metadata?.description ?? '');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (categories.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Wrap(
              spacing: 4,
              runSpacing: 2,
              children: categories.take(3).map((cat) => Chip(
                    label: Text(cat, style: const TextStyle(fontSize: 10)),
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  )).toList(),
            ),
          ),
        if (description.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
      ],
    );
  }

  // --- Column View ---
  Widget _buildColumnView() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 600px breakpoint follows Material 3 compact/medium guidelines
        final columnCount = constraints.maxWidth < 600 ? 2 : 3;

        return Scrollbar(
          controller: _columnScrollController,
          child: GridView.builder(
            controller: _columnScrollController,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columnCount,
              childAspectRatio: 1.5,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            padding: const EdgeInsets.all(8),
            itemCount: _filteredAlgorithms.length,
            itemBuilder: (context, index) =>
                _buildAlgorithmCard(context, _filteredAlgorithms[index]),
          ),
        );
      },
    );
  }

  Widget _buildAlgorithmCard(BuildContext context, AlgorithmInfo algo) {
    final isSelected = algo.guid == selectedAlgorithmGuid;
    final isFavorite = _favoriteGuids.contains(algo.guid);
    final isCommunityPlugin = _isPlugin(algo.guid);
    final metadata =
        _metadataService.getAlgorithmByGuid(algo.guid.toLowerCase());
    // For community plugins, show simplified metadata
    final categories = isCommunityPlugin
        ? ['Community Plugin']
        : (metadata?.categories ?? <String>[]);
    final description = isCommunityPlugin
        ? 'Manually installed community plugin.'
        : (metadata?.description ?? '');
    final theme = Theme.of(context);

    return Card(
      elevation: isSelected ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected
            ? BorderSide(color: theme.colorScheme.primary, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: () => _selectAlgorithm(algo.guid),
        onLongPress: () => _toggleFavorite(algo.guid),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      algo.name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isFavorite)
                    const Icon(Icons.star, color: Colors.amber, size: 18),
                  if (isCommunityPlugin)
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Icon(
                        Icons.extension,
                        color: theme.colorScheme.secondary,
                        size: 18,
                      ),
                    ),
                ],
              ),
              if (categories.isNotEmpty) ...[
                const SizedBox(height: 6),
                _buildCategoryChips(categories),
              ],
              if (description.isNotEmpty) ...[
                const SizedBox(height: 6),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final style = theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      );
                      // Estimate line height (fontSize * height factor, default ~1.2)
                      final lineHeight = (style?.fontSize ?? 12) * 1.4;
                      final maxLines = (constraints.maxHeight / lineHeight).floor().clamp(1, 100);
                      return Text(
                        description,
                        maxLines: maxLines,
                        overflow: TextOverflow.ellipsis,
                        style: style,
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChips(List<String> categories) {
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: categories.map((cat) => Chip(
            label: Text(cat, style: const TextStyle(fontSize: 10)),
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          )).toList(),
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
      return const Padding(
        padding: EdgeInsets.all(8.0),
        child: Text("Loading specifications..."),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Text(
            'Specifications:',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        ...List.generate(algorithm.numSpecifications, (index) {
          final specInfo = algorithm.specifications[index];
          if (index >= specValues!.length) {
            return const SizedBox.shrink();
          }

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
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12.0,
                vertical: 10.0,
              ),
            ),
            keyboardType: TextInputType.number,
            onChanged: isOffline
                ? null
                : (value) {
                    int parsedValue =
                        int.tryParse(value) ?? specInfo.defaultValue;
                    parsedValue = parsedValue.clamp(specInfo.min, specInfo.max);
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
              return null;
            },
            autovalidateMode: AutovalidateMode.onUserInteraction,
          );

          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: isOffline
                ? Tooltip(
                    message: 'Defaults are used in offline mode',
                    child: textField,
                  )
                : textField,
          );
        }),
      ],
    );
  }

  Widget _buildActionButton(bool isOffline) {
    if (_currentAlgoInfo == null) {
      return ElevatedButton(
        onPressed: null,
        child: const Text('Select Algorithm'),
      );
    }

    final algorithm = _currentAlgoInfo!;

    // Show Load button for unloaded plugins
    if (_needsLoading(algorithm) && !isOffline) {
      return ElevatedButton(
        onPressed: () => _loadPlugin(algorithm.guid),
        child: const Text('Load Plugin'),
      );
    }

    // Show Add button for loaded algorithms (factory or loaded plugins)
    return ElevatedButton(
      onPressed: _currentAlgoInfo != null && specValues != null
          ? () {
              Navigator.pop(context, {
                'algorithm': _currentAlgoInfo,
                'specValues': specValues,
              });
            }
          : null,
      child: const Text('Add to Preset'),
    );
  }
}
