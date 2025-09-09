import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nt_helper/cubit/preset_browser_state.dart';
import 'package:nt_helper/domain/i_disting_midi_manager.dart';
import 'package:nt_helper/models/sd_card_file_system.dart';
import 'package:shared_preferences/shared_preferences.dart';

export 'preset_browser_state.dart';

class PresetBrowserCubit extends Cubit<PresetBrowserState> {
  final IDistingMidiManager midiManager;
  final SharedPreferences prefs;
  final Map<String, List<DirectoryEntry>> _directoryCache = {};
  
  static const String _historyKey = 'presetHistory';
  static const int _maxHistoryItems = 20;

  PresetBrowserCubit({
    required this.midiManager,
    required this.prefs,
  }) : super(const PresetBrowserState.initial());

  Future<void> loadRootDirectory() async {
    emit(const PresetBrowserState.loading());

    try {
      // Try /presets first
      DirectoryListing? listing = await midiManager.requestDirectoryListing('/presets');
      String rootPath = '/presets';

      // If /presets doesn't exist, fall back to root
      if (listing == null) {
        listing = await midiManager.requestDirectoryListing('/');
        rootPath = '/';
      }

      if (listing != null) {
        final sortedEntries = _sortEntries(listing.entries, false);
        _directoryCache[rootPath] = sortedEntries;

        emit(PresetBrowserState.loaded(
          currentPath: rootPath,
          leftPanelItems: sortedEntries,
          centerPanelItems: const [],
          rightPanelItems: const [],
          selectedLeftItem: null,
          selectedCenterItem: null,
          selectedRightItem: null,
          navigationHistory: [],
          sortByDate: false,
          directoryCache: Map.from(_directoryCache),
        ));
      } else {
        emit(const PresetBrowserState.error(
          message: 'Failed to load directory listing',
        ));
      }
    } catch (e) {
      emit(PresetBrowserState.error(
        message: 'Error loading directory: $e',
      ));
    }
  }

  Future<void> selectDirectory(DirectoryEntry entry, PanelPosition panel) async {
    await state.maybeMap(
      loaded: (currentState) async {
        if (!entry.isDirectory) return;

        emit(const PresetBrowserState.loading());

        try {
          final path = _buildPath(currentState.currentPath, entry.name, panel);
          
          // Check cache first
          List<DirectoryEntry>? entries = _directoryCache[path];
          
          if (entries == null) {
            // Load from device
            final listing = await midiManager.requestDirectoryListing(path);
            if (listing != null) {
              entries = _sortEntries(listing.entries, currentState.sortByDate);
              _directoryCache[path] = entries;
            } else {
              entries = [];
            }
          }

          // Update panels based on which panel was clicked
          final newState = _updatePanelState(currentState, panel, entry, entries);
          emit(newState);
        } catch (e) {
          emit(PresetBrowserState.error(
            message: 'Error loading directory: $e',
            lastPath: currentState.currentPath,
          ));
        }
      },
      orElse: () async {},
    );
  }

  Future<void> selectFile(DirectoryEntry entry, PanelPosition panel) async {
    await state.maybeMap(
      loaded: (currentState) async {
        if (entry.isDirectory) return;

        // Build full path for the selected file
        final path = _buildPath(currentState.currentPath, entry.name, panel);
        
        // Add to history
        await addToHistory(path);
        
        // Return the selected preset path to the dialog
        // This will be handled by the dialog widget
      },
      orElse: () async {},
    );
  }

  void toggleSortMode() {
    state.maybeMap(
      loaded: (currentState) {
        final newSortByDate = !currentState.sortByDate;
        
        emit(currentState.copyWith(
          sortByDate: newSortByDate,
          leftPanelItems: _sortEntries(currentState.leftPanelItems, newSortByDate),
          centerPanelItems: _sortEntries(currentState.centerPanelItems, newSortByDate),
          rightPanelItems: _sortEntries(currentState.rightPanelItems, newSortByDate),
        ));
      },
      orElse: () {},
    );
  }

  Future<void> navigateBack() async {
    await state.maybeMap(
      loaded: (currentState) async {
        if (currentState.navigationHistory.isEmpty) return;

        emit(const PresetBrowserState.loading());

        try {
          final previousPath = currentState.navigationHistory.last;
          final newHistory = List<String>.from(currentState.navigationHistory)
            ..removeLast();

          // Load directory from cache or device
          List<DirectoryEntry>? entries = _directoryCache[previousPath];
          
          if (entries == null) {
            final listing = await midiManager.requestDirectoryListing(previousPath);
            if (listing != null) {
              entries = _sortEntries(listing.entries, currentState.sortByDate);
              _directoryCache[previousPath] = entries;
            } else {
              entries = [];
            }
          }

          emit(PresetBrowserState.loaded(
            currentPath: previousPath,
            leftPanelItems: entries,
            centerPanelItems: const [],
            rightPanelItems: const [],
            selectedLeftItem: null,
            selectedCenterItem: null,
            selectedRightItem: null,
            navigationHistory: newHistory,
            sortByDate: currentState.sortByDate,
            directoryCache: Map.from(_directoryCache),
          ));
        } catch (e) {
          emit(PresetBrowserState.error(
            message: 'Error navigating back: $e',
            lastPath: currentState.currentPath,
          ));
        }
      },
      orElse: () async {},
    );
  }

  Future<List<String>> loadRecentPresets() async {
    return prefs.getStringList(_historyKey) ?? [];
  }

  Future<void> addToHistory(String presetPath) async {
    final history = await loadRecentPresets();
    
    // Remove if already exists and add to front
    history.remove(presetPath);
    history.insert(0, presetPath);
    
    // Limit history size
    if (history.length > _maxHistoryItems) {
      history.removeRange(_maxHistoryItems, history.length);
    }
    
    await prefs.setStringList(_historyKey, history);
  }

  Future<void> clearCache() async {
    _directoryCache.clear();
  }

  // Helper methods
  
  List<DirectoryEntry> _sortEntries(List<DirectoryEntry> entries, bool byDate) {
    final sorted = List<DirectoryEntry>.from(entries);
    
    if (byDate) {
      sorted.sort((a, b) {
        // Folders first, then by date/time
        if (a.isDirectory != b.isDirectory) {
          return a.isDirectory ? -1 : 1;
        }
        // Compare by date first, then time
        final dateCompare = b.date.compareTo(a.date);
        if (dateCompare != 0) return dateCompare;
        return b.time.compareTo(a.time);
      });
    } else {
      sorted.sort((a, b) {
        // Folders first, then alphabetically
        if (a.isDirectory != b.isDirectory) {
          return a.isDirectory ? -1 : 1;
        }
        // Remove trailing slash for directories when comparing
        final aName = a.name.endsWith('/') ? a.name.substring(0, a.name.length - 1) : a.name;
        final bName = b.name.endsWith('/') ? b.name.substring(0, b.name.length - 1) : b.name;
        return aName.toLowerCase().compareTo(bName.toLowerCase());
      });
    }
    
    return sorted;
  }

  String _buildPath(String currentPath, String entryName, PanelPosition panel) {
    // Remove trailing slash from entry name if present (directories have it)
    final cleanName = entryName.endsWith('/') 
        ? entryName.substring(0, entryName.length - 1) 
        : entryName;
    
    final pathSegments = currentPath.split('/').where((s) => s.isNotEmpty).toList();
    
    switch (panel) {
      case PanelPosition.left:
        // Replace entire path with new selection
        if (currentPath == '/' || currentPath == '/presets') {
          final base = currentPath == '/' ? '' : currentPath;
          return '$base/$cleanName';
        }
        return '/${pathSegments.first}/$cleanName';
        
      case PanelPosition.center:
        // Build path up to second level
        if (pathSegments.isNotEmpty) {
          return '/${pathSegments[0]}/$cleanName';
        }
        return '/$cleanName';
        
      case PanelPosition.right:
        // Build path up to third level
        if (pathSegments.length >= 2) {
          return '/${pathSegments[0]}/${pathSegments[1]}/$cleanName';
        }
        return currentPath.endsWith('/') 
            ? '$currentPath$cleanName' 
            : '$currentPath/$cleanName';
    }
  }

  PresetBrowserState _updatePanelState(
    dynamic currentState, // Will be _Loaded but can't reference it directly
    PanelPosition panel,
    DirectoryEntry selectedEntry,
    List<DirectoryEntry> newEntries,
  ) {
    // Cast the navigation history properly
    final navHistory = currentState.navigationHistory as List;
    final currentPath = currentState.currentPath as String;
    
    switch (panel) {
      case PanelPosition.left:
        return currentState.copyWith(
          selectedLeftItem: selectedEntry,
          centerPanelItems: newEntries,
          rightPanelItems: <DirectoryEntry>[],
          selectedCenterItem: null,
          selectedRightItem: null,
          navigationHistory: [...navHistory.cast<String>(), currentPath],
        );
        
      case PanelPosition.center:
        return currentState.copyWith(
          selectedCenterItem: selectedEntry,
          rightPanelItems: newEntries,
          selectedRightItem: null,
        );
        
      case PanelPosition.right:
        return currentState.copyWith(
          selectedRightItem: selectedEntry,
        );
    }
  }

  String getSelectedPath() {
    return state.maybeMap(
      loaded: (currentState) {
        // Build path from selections
        if (currentState.selectedRightItem != null && !currentState.selectedRightItem!.isDirectory) {
          return _buildPath(currentState.currentPath, currentState.selectedRightItem!.name, PanelPosition.right);
        }
        if (currentState.selectedCenterItem != null && !currentState.selectedCenterItem!.isDirectory) {
          return _buildPath(currentState.currentPath, currentState.selectedCenterItem!.name, PanelPosition.center);
        }
        if (currentState.selectedLeftItem != null && !currentState.selectedLeftItem!.isDirectory) {
          return _buildPath(currentState.currentPath, currentState.selectedLeftItem!.name, PanelPosition.left);
        }
        
        return '';
      },
      orElse: () => '',
    );
  }
}