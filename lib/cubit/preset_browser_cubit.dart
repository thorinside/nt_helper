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

  PresetBrowserCubit({required this.midiManager, required this.prefs})
    : super(const PresetBrowserState.initial());

  Future<void> loadRootDirectory() async {
    emit(const PresetBrowserState.loading());

    try {
      // Try /presets first
      DirectoryListing? listing = await midiManager.requestDirectoryListing(
        '/presets',
      );
      String rootPath = '/presets';

      // If /presets doesn't exist, fall back to root
      if (listing == null) {
        listing = await midiManager.requestDirectoryListing('/');
        rootPath = '/';
      }

      if (listing != null) {
        final sortedEntries = _sortEntries(listing.entries, false);
        _directoryCache[rootPath] = sortedEntries;

        emit(
          PresetBrowserState.loaded(
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
            // Initialize mobile fields
            drillPath: rootPath,
            breadcrumbs: _getBreadcrumbsFromPath(rootPath),
            currentDrillItems: sortedEntries,
            selectedDrillItem: null,
          ),
        );
      } else {
        emit(
          const PresetBrowserState.error(
            message: 'Failed to load directory listing',
          ),
        );
      }
    } catch (e) {
      emit(PresetBrowserState.error(message: 'Error loading directory: $e'));
    }
  }

  Future<void> selectDirectory(
    DirectoryEntry entry,
    PanelPosition panel,
  ) async {
    await state.maybeMap(
      loaded: (currentState) async {
        if (!entry.isDirectory) return;

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
          final newState = _updatePanelState(
            currentState,
            panel,
            entry,
            entries,
          );
          emit(newState);
        } catch (e) {
          emit(
            PresetBrowserState.error(
              message: 'Error loading directory: $e',
              lastPath: currentState.currentPath,
            ),
          );
        }
      },
      orElse: () async {},
    );
  }

  Future<void> selectFile(DirectoryEntry entry, PanelPosition panel) async {
    await state.maybeMap(
      loaded: (currentState) async {
        if (entry.isDirectory) return;

        // Update the state to mark the file as selected
        final newState = _updateFileSelection(currentState, panel, entry);
        emit(newState);

        // Build full path for the selected file
        final path = _buildPath(currentState.currentPath, entry.name, panel);

        // Add to history only if it's a JSON preset file
        if (entry.name.toLowerCase().endsWith('.json')) {
          await addToHistory(path);
        }
      },
      orElse: () async {},
    );
  }

  void toggleSortMode() {
    state.maybeMap(
      loaded: (currentState) {
        final newSortByDate = !currentState.sortByDate;

        emit(
          currentState.copyWith(
            sortByDate: newSortByDate,
            leftPanelItems: _sortEntries(
              currentState.leftPanelItems,
              newSortByDate,
            ),
            centerPanelItems: _sortEntries(
              currentState.centerPanelItems,
              newSortByDate,
            ),
            rightPanelItems: _sortEntries(
              currentState.rightPanelItems,
              newSortByDate,
            ),
          ),
        );
      },
      orElse: () {},
    );
  }

  Future<void> navigateBack() async {
    await state.maybeMap(
      loaded: (currentState) async {
        if (currentState.navigationHistory.isEmpty) return;

        try {
          final previousPath = currentState.navigationHistory.last;
          final newHistory = List<String>.from(currentState.navigationHistory)
            ..removeLast();

          // Load directory from cache or device
          List<DirectoryEntry>? entries = _directoryCache[previousPath];

          if (entries == null) {
            final listing = await midiManager.requestDirectoryListing(
              previousPath,
            );
            if (listing != null) {
              entries = _sortEntries(listing.entries, currentState.sortByDate);
              _directoryCache[previousPath] = entries;
            } else {
              entries = [];
            }
          }

          emit(
            PresetBrowserState.loaded(
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
            ),
          );
        } catch (e) {
          emit(
            PresetBrowserState.error(
              message: 'Error navigating back: $e',
              lastPath: currentState.currentPath,
            ),
          );
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
        final aName = a.name.endsWith('/')
            ? a.name.substring(0, a.name.length - 1)
            : a.name;
        final bName = b.name.endsWith('/')
            ? b.name.substring(0, b.name.length - 1)
            : b.name;
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

    final pathSegments = currentPath
        .split('/')
        .where((s) => s.isNotEmpty)
        .toList();

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
        return currentState.copyWith(selectedRightItem: selectedEntry);
    }
  }

  PresetBrowserState _updateFileSelection(
    dynamic currentState, // Will be _Loaded but can't reference it directly
    PanelPosition panel,
    DirectoryEntry selectedFile,
  ) {
    switch (panel) {
      case PanelPosition.left:
        return currentState.copyWith(
          selectedLeftItem: selectedFile,
          selectedCenterItem: null,
          selectedRightItem: null,
        );

      case PanelPosition.center:
        return currentState.copyWith(
          selectedCenterItem: selectedFile,
          selectedRightItem: null,
        );

      case PanelPosition.right:
        return currentState.copyWith(selectedRightItem: selectedFile);
    }
  }

  String getSelectedPath() {
    return state.maybeMap(
      loaded: (currentState) {
        // For mobile drill-down mode, use the drill path
        if (currentState.selectedDrillItem != null &&
            !currentState.selectedDrillItem!.isDirectory) {
          final drillPath = currentState.drillPath ?? currentState.currentPath;
          return drillPath.endsWith('/')
              ? '$drillPath${currentState.selectedDrillItem!.name}'
              : '$drillPath/${currentState.selectedDrillItem!.name}';
        }

        // Build the complete path from the base path and selected items
        String fullPath = currentState.currentPath;

        // If we have a selected directory in the left panel, add it to the path
        if (currentState.selectedLeftItem != null &&
            currentState.selectedLeftItem!.isDirectory) {
          final cleanName = currentState.selectedLeftItem!.name.endsWith('/')
              ? currentState.selectedLeftItem!.name.substring(
                  0,
                  currentState.selectedLeftItem!.name.length - 1,
                )
              : currentState.selectedLeftItem!.name;
          fullPath = fullPath.endsWith('/')
              ? '$fullPath$cleanName'
              : '$fullPath/$cleanName';

          // If we have a selected directory in the center panel, add it too
          if (currentState.selectedCenterItem != null &&
              currentState.selectedCenterItem!.isDirectory) {
            final cleanCenterName =
                currentState.selectedCenterItem!.name.endsWith('/')
                ? currentState.selectedCenterItem!.name.substring(
                    0,
                    currentState.selectedCenterItem!.name.length - 1,
                  )
                : currentState.selectedCenterItem!.name;
            fullPath = '$fullPath/$cleanCenterName';

            // Check if we have a JSON file selected in the right panel
            if (currentState.selectedRightItem != null &&
                !currentState.selectedRightItem!.isDirectory &&
                currentState.selectedRightItem!.name.toLowerCase().endsWith(
                  '.json',
                )) {
              return '$fullPath/${currentState.selectedRightItem!.name}';
            }
          }
          // Check if we have a JSON file selected in the center panel (no directory selected)
          else if (currentState.selectedCenterItem != null &&
              !currentState.selectedCenterItem!.isDirectory &&
              currentState.selectedCenterItem!.name.toLowerCase().endsWith(
                '.json',
              )) {
            return '$fullPath/${currentState.selectedCenterItem!.name}';
          }
        }
        // Check if we have a JSON file selected in the left panel (no directory selected)
        else if (currentState.selectedLeftItem != null &&
            !currentState.selectedLeftItem!.isDirectory &&
            currentState.selectedLeftItem!.name.toLowerCase().endsWith(
              '.json',
            )) {
          return fullPath.endsWith('/')
              ? '$fullPath${currentState.selectedLeftItem!.name}'
              : '$fullPath/${currentState.selectedLeftItem!.name}';
        }

        return '';
      },
      orElse: () => '',
    );
  }

  // Mobile drill-down navigation methods

  Future<void> navigateIntoDirectory(DirectoryEntry entry) async {
    await state.maybeMap(
      loaded: (currentState) async {
        if (!entry.isDirectory) return;

        try {
          final currentDrillPath = currentState.drillPath ?? currentState.currentPath;
          final cleanName = entry.name.endsWith('/')
              ? entry.name.substring(0, entry.name.length - 1)
              : entry.name;
          final newPath = currentDrillPath.endsWith('/')
              ? '$currentDrillPath$cleanName'
              : '$currentDrillPath/$cleanName';

          // Check cache first
          List<DirectoryEntry>? entries = _directoryCache[newPath];

          if (entries == null) {
            // Load from device
            final listing = await midiManager.requestDirectoryListing(newPath);
            if (listing != null) {
              entries = _sortEntries(listing.entries, currentState.sortByDate);
              _directoryCache[newPath] = entries;
            } else {
              entries = [];
            }
          }

          emit(
            currentState.copyWith(
              drillPath: newPath,
              breadcrumbs: _getBreadcrumbsFromPath(newPath),
              currentDrillItems: entries,
              selectedDrillItem: null,
            ),
          );
        } catch (e) {
          emit(
            PresetBrowserState.error(
              message: 'Error loading directory: $e',
              lastPath: currentState.drillPath ?? currentState.currentPath,
            ),
          );
        }
      },
      orElse: () async {},
    );
  }

  Future<void> navigateToPathSegment(int index) async {
    await state.maybeMap(
      loaded: (currentState) async {
        final breadcrumbs = currentState.breadcrumbs ?? [];
        if (index < 0 || index >= breadcrumbs.length) return;

        try {
          // Build path up to the selected segment
          final pathSegments = breadcrumbs.take(index + 1).toList();
          final newPath = pathSegments.isEmpty ? '/' : '/${pathSegments.join('/')}';

          // Check cache first
          List<DirectoryEntry>? entries = _directoryCache[newPath];

          if (entries == null) {
            // Load from device
            final listing = await midiManager.requestDirectoryListing(newPath);
            if (listing != null) {
              entries = _sortEntries(listing.entries, currentState.sortByDate);
              _directoryCache[newPath] = entries;
            } else {
              entries = [];
            }
          }

          emit(
            currentState.copyWith(
              drillPath: newPath,
              breadcrumbs: _getBreadcrumbsFromPath(newPath),
              currentDrillItems: entries,
              selectedDrillItem: null,
            ),
          );
        } catch (e) {
          emit(
            PresetBrowserState.error(
              message: 'Error navigating to path: $e',
              lastPath: currentState.drillPath ?? currentState.currentPath,
            ),
          );
        }
      },
      orElse: () async {},
    );
  }

  void selectDrillItem(DirectoryEntry entry) {
    state.maybeMap(
      loaded: (currentState) {
        emit(
          currentState.copyWith(
            selectedDrillItem: entry,
          ),
        );

        // Add to history if it's a JSON preset file
        if (!entry.isDirectory && entry.name.toLowerCase().endsWith('.json')) {
          final drillPath = currentState.drillPath ?? currentState.currentPath;
          final fullPath = drillPath.endsWith('/')
              ? '$drillPath${entry.name}'
              : '$drillPath/${entry.name}';
          addToHistory(fullPath);
        }
      },
      orElse: () {},
    );
  }

  List<String> _getBreadcrumbsFromPath(String path) {
    if (path == '/' || path.isEmpty) return [];

    final segments = path.split('/').where((s) => s.isNotEmpty).toList();
    return segments;
  }
}
