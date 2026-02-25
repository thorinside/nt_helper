import 'dart:async';
import 'dart:typed_data';

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
  static const String _lastPathKey = 'fileBrowserLastPath';
  static const String _sortByDateKey = 'fileBrowserSortByDate';
  static const int _maxHistoryItems = 20;

  PresetBrowserCubit({required this.midiManager, required this.prefs})
    : super(const PresetBrowserState.initial());

  Future<void> loadRootDirectory() async {
    emit(const PresetBrowserState.loading());

    final savedSortByDate = prefs.getBool(_sortByDateKey) ?? false;
    final savedPath = prefs.getString(_lastPathKey);

    try {
      final listing = await midiManager.requestDirectoryListing('/');

      if (listing != null) {
        final sortedEntries = _sortEntries(
          listing.entries,
          savedSortByDate,
          currentPath: '/',
          addParentEntry: false,
        );
        _directoryCache['/'] = sortedEntries;

        emit(
          PresetBrowserState.loaded(
            currentPath: '/',
            leftPanelItems: sortedEntries,
            centerPanelItems: const [],
            rightPanelItems: const [],
            selectedLeftItem: null,
            selectedCenterItem: null,
            selectedRightItem: null,
            navigationHistory: [],
            sortByDate: savedSortByDate,
            directoryCache: Map.from(_directoryCache),
            drillPath: '/',
            breadcrumbs: const [],
            currentDrillItems: sortedEntries,
            selectedDrillItem: null,
          ),
        );

        // Restore saved path if available and not root
        if (savedPath != null && savedPath != '/' && savedPath.isNotEmpty) {
          await _restoreSavedPath(savedPath);
        }
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

  /// Attempts to restore navigation to a previously saved path.
  /// Falls back silently to root if the path no longer exists.
  Future<void> _restoreSavedPath(String targetPath) async {
    try {
      final listing = await midiManager.requestDirectoryListing(targetPath);
      if (listing == null) return;

      final sortByDate = state.maybeMap(
        loaded: (s) => s.sortByDate,
        orElse: () => false,
      );

      final entries = _sortEntries(
        listing.entries,
        sortByDate,
        currentPath: targetPath,
        addParentEntry: targetPath != '/',
      );
      _directoryCache[targetPath] = entries;

      emit(
        PresetBrowserState.loaded(
          currentPath: targetPath,
          leftPanelItems: entries,
          centerPanelItems: const [],
          rightPanelItems: const [],
          selectedLeftItem: null,
          selectedCenterItem: null,
          selectedRightItem: null,
          navigationHistory: [],
          sortByDate: sortByDate,
          directoryCache: Map.from(_directoryCache),
          drillPath: targetPath,
          breadcrumbs: _getBreadcrumbsFromPath(targetPath),
          currentDrillItems: entries,
          selectedDrillItem: null,
        ),
      );
    } catch (_) {
      // Path no longer exists — stay at root
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
          // Handle parent directory navigation
          if (entry.name == '..') {
            final parentPath = _getParentPath(currentState.currentPath);
            if (parentPath != null) {
              await _navigateToPath(parentPath, currentState);
            }
            return;
          }

          // When selecting a directory in the right panel, advance deeper
          if (panel == PanelPosition.right) {
            await _advanceDeeper(currentState, entry);
            return;
          }

          final path = _buildPath(currentState, entry.name, panel);

          // Check cache first
          List<DirectoryEntry>? entries = _directoryCache[path];

          if (entries == null) {
            final listing = await midiManager.requestDirectoryListing(path);
            if (listing != null) {
              entries = _sortEntries(
                listing.entries,
                currentState.sortByDate,
                currentPath: path,
              );
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

  Future<void> _advanceDeeper(
    dynamic currentState,
    DirectoryEntry rightEntry,
  ) async {
    // Build the path for the center panel's selected directory
    final centerEntry = currentState.selectedCenterItem as DirectoryEntry?;
    final leftEntry = currentState.selectedLeftItem as DirectoryEntry?;

    if (centerEntry == null || leftEntry == null) return;

    // The new currentPath becomes: currentPath + leftEntry
    final leftClean = _cleanName(leftEntry.name);
    final centerClean = _cleanName(centerEntry.name);
    final rightClean = _cleanName(rightEntry.name);

    final currentPath = currentState.currentPath as String;
    final newCurrentPath = _joinPath(currentPath, leftClean);

    // Load center directory contents (what was the right panel's parent)
    final centerPath = _joinPath(newCurrentPath, centerClean);
    List<DirectoryEntry>? centerEntries = _directoryCache[centerPath];
    if (centerEntries == null) {
      final listing = await midiManager.requestDirectoryListing(centerPath);
      if (listing != null) {
        centerEntries = _sortEntries(
          listing.entries,
          currentState.sortByDate,
          currentPath: centerPath,
        );
        _directoryCache[centerPath] = centerEntries;
      } else {
        centerEntries = [];
      }
    }

    // Load right panel contents (the newly selected directory)
    final rightPath = _joinPath(centerPath, rightClean);
    List<DirectoryEntry>? rightEntries = _directoryCache[rightPath];
    if (rightEntries == null) {
      final listing = await midiManager.requestDirectoryListing(rightPath);
      if (listing != null) {
        rightEntries = _sortEntries(
          listing.entries,
          currentState.sortByDate,
          currentPath: rightPath,
        );
        _directoryCache[rightPath] = rightEntries;
      } else {
        rightEntries = [];
      }
    }

    // Load left panel (new currentPath)
    List<DirectoryEntry>? leftEntries = _directoryCache[newCurrentPath];
    if (leftEntries == null) {
      final listing = await midiManager.requestDirectoryListing(newCurrentPath);
      if (listing != null) {
        leftEntries = _sortEntries(
          listing.entries,
          currentState.sortByDate,
          currentPath: newCurrentPath,
          addParentEntry: newCurrentPath != '/',
        );
        _directoryCache[newCurrentPath] = leftEntries;
      } else {
        leftEntries = [];
      }
    }

    _saveLastPath(newCurrentPath);

    emit(
      PresetBrowserState.loaded(
        currentPath: newCurrentPath,
        leftPanelItems: leftEntries,
        centerPanelItems: centerEntries,
        rightPanelItems: rightEntries,
        selectedLeftItem: _findEntry(leftEntries, centerEntry.name),
        selectedCenterItem: _findEntry(centerEntries, rightEntry.name),
        selectedRightItem: null,
        navigationHistory: [
          ...List<String>.from(currentState.navigationHistory),
          currentState.currentPath as String,
        ],
        sortByDate: currentState.sortByDate as bool,
        directoryCache: Map.from(_directoryCache),
        drillPath: newCurrentPath,
        breadcrumbs: _getBreadcrumbsFromPath(newCurrentPath),
        currentDrillItems: leftEntries,
        selectedDrillItem: null,
      ),
    );
  }

  DirectoryEntry? _findEntry(List<DirectoryEntry> entries, String name) {
    final clean = _cleanName(name);
    for (final e in entries) {
      if (_cleanName(e.name) == clean) return e;
    }
    return null;
  }

  Future<void> selectFile(DirectoryEntry entry, PanelPosition panel) async {
    await state.maybeMap(
      loaded: (currentState) async {
        if (entry.isDirectory) return;

        final newState = _updateFileSelection(currentState, panel, entry);
        emit(newState);

        final path = _buildPath(currentState, entry.name, panel);

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
        prefs.setBool(_sortByDateKey, newSortByDate);

        final leftFiltered = currentState.leftPanelItems
            .where((e) => e.name != '..')
            .toList();
        final centerFiltered = currentState.centerPanelItems
            .where((e) => e.name != '..')
            .toList();
        final rightFiltered = currentState.rightPanelItems
            .where((e) => e.name != '..')
            .toList();

        emit(
          currentState.copyWith(
            sortByDate: newSortByDate,
            leftPanelItems: _sortEntries(
              leftFiltered,
              newSortByDate,
              currentPath: currentState.currentPath,
              addParentEntry: currentState.currentPath != '/',
            ),
            centerPanelItems: _sortEntries(
              centerFiltered,
              newSortByDate,
              currentPath: currentState.currentPath,
            ),
            rightPanelItems: _sortEntries(
              rightFiltered,
              newSortByDate,
              currentPath: currentState.currentPath,
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

          List<DirectoryEntry>? entries = _directoryCache[previousPath];

          if (entries == null) {
            final listing = await midiManager.requestDirectoryListing(
              previousPath,
            );
            if (listing != null) {
              entries = _sortEntries(
                listing.entries,
                currentState.sortByDate,
                currentPath: previousPath,
                addParentEntry: previousPath != '/',
              );
              _directoryCache[previousPath] = entries;
            } else {
              entries = [];
            }
          }

          _saveLastPath(previousPath);

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

  Future<void> navigateToAbsolutePath(String path) async {
    await state.maybeMap(
      loaded: (currentState) async {
        await _navigateToPath(path, currentState);
      },
      orElse: () async {},
    );
  }

  Future<List<String>> loadRecentPresets() async {
    return prefs.getStringList(_historyKey) ?? [];
  }

  Future<void> addToHistory(String presetPath) async {
    final history = await loadRecentPresets();

    history.remove(presetPath);
    history.insert(0, presetPath);

    if (history.length > _maxHistoryItems) {
      history.removeRange(_maxHistoryItems, history.length);
    }

    await prefs.setStringList(_historyKey, history);
  }

  Future<void> clearCache() async {
    _directoryCache.clear();
  }

  // File operation methods

  Future<void> deleteEntry(String fullPath) async {
    final result = await midiManager.requestFileDelete(fullPath);
    if (result == null) {
      throw Exception('Failed to delete: $fullPath');
    }

    final parentDir = _getParentPath(fullPath) ?? '/';
    _directoryCache.remove(parentDir);
    await _refreshDirectory(parentDir);
  }

  Future<void> createDirectory(String parentPath, String name) async {
    final fullPath = _joinPath(parentPath, name);
    final result = await midiManager.requestDirectoryCreate(fullPath);
    if (result == null) {
      throw Exception('Failed to create directory: $fullPath');
    }

    _directoryCache.remove(parentPath);
    await _refreshDirectory(parentPath);
  }

  Future<void> renameEntry(String fullPath, String newName) async {
    final parentDir = _getParentPath(fullPath) ?? '/';
    final newPath = _joinPath(parentDir, newName);
    final result = await midiManager.requestFileRename(fullPath, newPath);
    if (result == null) {
      throw Exception('Failed to rename: $fullPath');
    }

    _directoryCache.remove(parentDir);
    await _refreshDirectory(parentDir);
  }

  Future<Uint8List?> downloadFile(String fullPath) async {
    return await midiManager.requestFileDownload(fullPath);
  }

  Future<void> uploadFile(
    String targetDirectory,
    String fileName,
    Uint8List data, {
    void Function(double progress)? onProgress,
  }) async {
    final targetPath = _joinPath(targetDirectory, fileName);

    // Upload in 512-byte chunks
    const chunkSize = 512;
    int uploadPos = 0;

    while (uploadPos < data.length) {
      final remainingBytes = data.length - uploadPos;
      final currentChunkSize =
          remainingBytes < chunkSize ? remainingBytes : chunkSize;
      final chunk = data.sublist(uploadPos, uploadPos + currentChunkSize);

      final result = await midiManager.requestFileUploadChunk(
        targetPath,
        chunk,
        uploadPos,
        createAlways: uploadPos == 0,
      );

      if (result == null) {
        throw Exception('Upload failed at position $uploadPos');
      }

      uploadPos += currentChunkSize;
      onProgress?.call(uploadPos / data.length);

      if (uploadPos < data.length) {
        await Future.delayed(const Duration(milliseconds: 50));
      }
    }

    _directoryCache.remove(targetDirectory);
    await _refreshDirectory(targetDirectory);
  }

  /// Returns the deepest selected directory path for context menu operations.
  String getSelectedDirectoryPath() {
    return state.maybeMap(
      loaded: (currentState) {
        // For mobile drill-down: use drillPath only if it differs from
        // currentPath (meaning we've navigated deeper on mobile)
        if (currentState.drillPath != null &&
            currentState.drillPath!.isNotEmpty &&
            currentState.drillPath != currentState.currentPath) {
          return currentState.drillPath!;
        }

        String dirPath = currentState.currentPath;

        if (currentState.selectedLeftItem != null &&
            currentState.selectedLeftItem!.isDirectory &&
            currentState.selectedLeftItem!.name != '..') {
          dirPath = _joinPath(
            dirPath,
            _cleanName(currentState.selectedLeftItem!.name),
          );

          if (currentState.selectedCenterItem != null &&
              currentState.selectedCenterItem!.isDirectory) {
            dirPath = _joinPath(
              dirPath,
              _cleanName(currentState.selectedCenterItem!.name),
            );

            if (currentState.selectedRightItem != null &&
                currentState.selectedRightItem!.isDirectory) {
              dirPath = _joinPath(
                dirPath,
                _cleanName(currentState.selectedRightItem!.name),
              );
            }
          }
        }

        return dirPath;
      },
      orElse: () => '/',
    );
  }

  /// Returns the current navigated directory (for drag-and-drop uploads).
  /// On mobile this is drillPath; on desktop this is currentPath.
  String getCurrentDirectory() {
    return state.maybeMap(
      loaded: (currentState) =>
          currentState.drillPath ?? currentState.currentPath,
      orElse: () => '/',
    );
  }

  /// Returns the full path to the selected file/directory given its entry and panel directory.
  String getEntryPath(DirectoryEntry entry, String panelDirectory) {
    return _joinPath(panelDirectory, _cleanName(entry.name));
  }

  /// Returns the directory path for a given panel position.
  String getPanelDirectory(PanelPosition panel) {
    return state.maybeMap(
      loaded: (currentState) {
        switch (panel) {
          case PanelPosition.left:
            return currentState.currentPath;
          case PanelPosition.center:
            if (currentState.selectedLeftItem != null &&
                currentState.selectedLeftItem!.isDirectory) {
              return _joinPath(
                currentState.currentPath,
                _cleanName(currentState.selectedLeftItem!.name),
              );
            }
            return currentState.currentPath;
          case PanelPosition.right:
            if (currentState.selectedLeftItem != null &&
                currentState.selectedLeftItem!.isDirectory &&
                currentState.selectedCenterItem != null &&
                currentState.selectedCenterItem!.isDirectory) {
              return _joinPath(
                _joinPath(
                  currentState.currentPath,
                  _cleanName(currentState.selectedLeftItem!.name),
                ),
                _cleanName(currentState.selectedCenterItem!.name),
              );
            }
            return currentState.currentPath;
        }
      },
      orElse: () => '/',
    );
  }

  // Helper methods

  /// Refreshes the listing for [dirPath], updating whichever panel shows it
  /// while preserving the rest of the state.
  Future<void> _refreshDirectory(String dirPath) async {
    await state.maybeMap(
      loaded: (currentState) async {
        // Fetch fresh listing
        final listing = await midiManager.requestDirectoryListing(dirPath);
        final entries = listing != null
            ? _sortEntries(
                listing.entries,
                currentState.sortByDate,
                currentPath: dirPath,
                addParentEntry: dirPath != '/' &&
                    dirPath == currentState.currentPath,
              )
            : <DirectoryEntry>[];
        _directoryCache[dirPath] = entries;

        // Determine which panel(s) this directory corresponds to
        final leftPath = currentState.currentPath;

        String? centerPath;
        if (currentState.selectedLeftItem != null &&
            currentState.selectedLeftItem!.isDirectory) {
          centerPath = _joinPath(
            leftPath,
            _cleanName(currentState.selectedLeftItem!.name),
          );
        }

        String? rightPath;
        if (centerPath != null &&
            currentState.selectedCenterItem != null &&
            currentState.selectedCenterItem!.isDirectory) {
          rightPath = _joinPath(
            centerPath,
            _cleanName(currentState.selectedCenterItem!.name),
          );
        }

        if (dirPath == leftPath) {
          // Refresh left panel; clear center/right if selected items no longer exist
          final leftStillExists = currentState.selectedLeftItem != null &&
              entries.any((e) => e.name == currentState.selectedLeftItem!.name);

          emit(currentState.copyWith(
            leftPanelItems: entries,
            selectedLeftItem: leftStillExists
                ? currentState.selectedLeftItem
                : null,
            centerPanelItems:
                leftStillExists ? currentState.centerPanelItems : const [],
            rightPanelItems:
                leftStillExists ? currentState.rightPanelItems : const [],
            selectedCenterItem:
                leftStillExists ? currentState.selectedCenterItem : null,
            selectedRightItem:
                leftStillExists ? currentState.selectedRightItem : null,
            // Also refresh mobile drill-down if viewing same dir
            currentDrillItems:
                (currentState.drillPath ?? currentState.currentPath) == dirPath
                    ? entries
                    : currentState.currentDrillItems,
            selectedDrillItem:
                (currentState.drillPath ?? currentState.currentPath) == dirPath
                    ? null
                    : currentState.selectedDrillItem,
          ));
        } else if (dirPath == centerPath) {
          final centerStillExists =
              currentState.selectedCenterItem != null &&
                  entries.any(
                      (e) => e.name == currentState.selectedCenterItem!.name);

          emit(currentState.copyWith(
            centerPanelItems: entries,
            selectedCenterItem:
                centerStillExists ? currentState.selectedCenterItem : null,
            rightPanelItems:
                centerStillExists ? currentState.rightPanelItems : const [],
            selectedRightItem:
                centerStillExists ? currentState.selectedRightItem : null,
          ));
        } else if (dirPath == rightPath) {
          emit(currentState.copyWith(
            rightPanelItems: entries,
            selectedRightItem: null,
          ));
        } else {
          // dirPath is the mobile drill path or doesn't match any panel —
          // refresh mobile view and left panel as fallback
          if ((currentState.drillPath ?? currentState.currentPath) == dirPath) {
            emit(currentState.copyWith(
              currentDrillItems: entries,
              selectedDrillItem: null,
            ));
          }
        }
      },
      orElse: () async {},
    );
  }

  List<DirectoryEntry> _sortEntries(
    List<DirectoryEntry> entries,
    bool byDate, {
    String? currentPath,
    bool addParentEntry = false,
  }) {
    final sorted = List<DirectoryEntry>.from(entries);

    if (byDate) {
      sorted.sort((a, b) {
        if (a.isDirectory != b.isDirectory) {
          return a.isDirectory ? -1 : 1;
        }
        final dateCompare = b.date.compareTo(a.date);
        if (dateCompare != 0) return dateCompare;
        return b.time.compareTo(a.time);
      });
    } else {
      sorted.sort((a, b) {
        if (a.isDirectory != b.isDirectory) {
          return a.isDirectory ? -1 : 1;
        }
        final aName = a.name.endsWith('/')
            ? a.name.substring(0, a.name.length - 1)
            : a.name;
        final bName = b.name.endsWith('/')
            ? b.name.substring(0, b.name.length - 1)
            : b.name;
        return aName.toLowerCase().compareTo(bName.toLowerCase());
      });
    }

    if (addParentEntry && currentPath != null && currentPath != '/') {
      final parentEntry = DirectoryEntry(
        name: '..',
        attributes: 0x10,
        date: 0,
        time: 0,
        size: 0,
      );
      sorted.insert(0, parentEntry);
    }

    return sorted;
  }

  String _buildPath(
    dynamic currentState,
    String entryName,
    PanelPosition panel,
  ) {
    final cleanName = _cleanName(entryName);
    final currentPath = currentState.currentPath as String;

    switch (panel) {
      case PanelPosition.left:
        return _joinPath(currentPath, cleanName);

      case PanelPosition.center:
        final leftItem = currentState.selectedLeftItem as DirectoryEntry?;
        if (leftItem != null && leftItem.isDirectory) {
          final leftDir = _joinPath(currentPath, _cleanName(leftItem.name));
          return _joinPath(leftDir, cleanName);
        }
        return _joinPath(currentPath, cleanName);

      case PanelPosition.right:
        final leftItem = currentState.selectedLeftItem as DirectoryEntry?;
        final centerItem = currentState.selectedCenterItem as DirectoryEntry?;
        if (leftItem != null &&
            leftItem.isDirectory &&
            centerItem != null &&
            centerItem.isDirectory) {
          final leftDir = _joinPath(currentPath, _cleanName(leftItem.name));
          final centerDir = _joinPath(leftDir, _cleanName(centerItem.name));
          return _joinPath(centerDir, cleanName);
        }
        return _joinPath(currentPath, cleanName);
    }
  }

  PresetBrowserState _updatePanelState(
    dynamic currentState,
    PanelPosition panel,
    DirectoryEntry selectedEntry,
    List<DirectoryEntry> newEntries,
  ) {
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
    dynamic currentState,
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
        // For mobile drill-down mode
        if (currentState.selectedDrillItem != null &&
            !currentState.selectedDrillItem!.isDirectory) {
          final drillPath = currentState.drillPath ?? currentState.currentPath;
          return _joinPath(drillPath, currentState.selectedDrillItem!.name);
        }

        // Walk panels to find deepest selected file
        final currentPath = currentState.currentPath;

        if (currentState.selectedLeftItem != null &&
            currentState.selectedLeftItem!.isDirectory) {
          final leftDir = _joinPath(
            currentPath,
            _cleanName(currentState.selectedLeftItem!.name),
          );

          if (currentState.selectedCenterItem != null &&
              currentState.selectedCenterItem!.isDirectory) {
            final centerDir = _joinPath(
              leftDir,
              _cleanName(currentState.selectedCenterItem!.name),
            );

            if (currentState.selectedRightItem != null &&
                !currentState.selectedRightItem!.isDirectory) {
              return _joinPath(
                centerDir,
                currentState.selectedRightItem!.name,
              );
            }
          } else if (currentState.selectedCenterItem != null &&
              !currentState.selectedCenterItem!.isDirectory) {
            return _joinPath(
              leftDir,
              currentState.selectedCenterItem!.name,
            );
          }
        } else if (currentState.selectedLeftItem != null &&
            !currentState.selectedLeftItem!.isDirectory) {
          return _joinPath(
            currentPath,
            currentState.selectedLeftItem!.name,
          );
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
          final currentDrillPath =
              currentState.drillPath ?? currentState.currentPath;

          String newPath;
          if (entry.name == '..') {
            final parentPath = _getParentPath(currentDrillPath);
            if (parentPath == null) return;
            newPath = parentPath;
          } else {
            final cleanName = _cleanName(entry.name);
            newPath = _joinPath(currentDrillPath, cleanName);
          }

          List<DirectoryEntry>? entries = _directoryCache[newPath];

          if (entries == null) {
            final listing = await midiManager.requestDirectoryListing(newPath);
            if (listing != null) {
              entries = _sortEntries(
                listing.entries,
                currentState.sortByDate,
                currentPath: newPath,
                addParentEntry: newPath != '/',
              );
              _directoryCache[newPath] = entries;
            } else {
              entries = [];
            }
          }

          _saveLastPath(newPath);

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
          final pathSegments = breadcrumbs.take(index + 1).toList();
          final newPath = pathSegments.isEmpty
              ? '/'
              : '/${pathSegments.join('/')}';

          List<DirectoryEntry>? entries = _directoryCache[newPath];

          if (entries == null) {
            final listing = await midiManager.requestDirectoryListing(newPath);
            if (listing != null) {
              entries = _sortEntries(
                listing.entries,
                currentState.sortByDate,
                currentPath: newPath,
                addParentEntry: newPath != '/',
              );
              _directoryCache[newPath] = entries;
            } else {
              entries = [];
            }
          }

          _saveLastPath(newPath);

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
        emit(currentState.copyWith(selectedDrillItem: entry));

        if (!entry.isDirectory && entry.name.toLowerCase().endsWith('.json')) {
          final drillPath = currentState.drillPath ?? currentState.currentPath;
          final fullPath = _joinPath(drillPath, entry.name);
          addToHistory(fullPath);
        }
      },
      orElse: () {},
    );
  }

  List<String> _getBreadcrumbsFromPath(String path) {
    if (path == '/' || path.isEmpty) return [];
    return path.split('/').where((s) => s.isNotEmpty).toList();
  }

  void _saveLastPath(String path) {
    prefs.setString(_lastPathKey, path);
  }

  String? _getParentPath(String currentPath) {
    if (currentPath == '/') return null;

    final segments = currentPath.split('/').where((s) => s.isNotEmpty).toList();
    if (segments.isEmpty) return '/';
    if (segments.length == 1) return '/';

    segments.removeLast();
    return '/${segments.join('/')}';
  }

  String _cleanName(String name) {
    return name.endsWith('/') ? name.substring(0, name.length - 1) : name;
  }

  String _joinPath(String base, String child) {
    if (base.endsWith('/')) return '$base$child';
    return '$base/$child';
  }

  Future<void> _navigateToPath(String path, dynamic currentState) async {
    try {
      List<DirectoryEntry>? entries = _directoryCache[path];

      if (entries == null) {
        final listing = await midiManager.requestDirectoryListing(path);
        if (listing != null) {
          entries = _sortEntries(
            listing.entries,
            currentState.sortByDate,
            currentPath: path,
            addParentEntry: path != '/',
          );
          _directoryCache[path] = entries;
        } else {
          entries = [];
        }
      }

      _saveLastPath(path);

      emit(
        PresetBrowserState.loaded(
          currentPath: path,
          leftPanelItems: entries,
          centerPanelItems: const [],
          rightPanelItems: const [],
          selectedLeftItem: null,
          selectedCenterItem: null,
          selectedRightItem: null,
          navigationHistory: [],
          sortByDate: currentState.sortByDate,
          directoryCache: Map.from(_directoryCache),
          drillPath: path,
          breadcrumbs: _getBreadcrumbsFromPath(path),
          currentDrillItems: entries,
          selectedDrillItem: null,
        ),
      );
    } catch (e) {
      emit(
        PresetBrowserState.error(
          message: 'Error navigating to path: $e',
          lastPath: currentState.currentPath,
        ),
      );
    }
  }
}
