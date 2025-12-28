import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:nt_helper/models/gallery_models.dart';
import 'package:nt_helper/services/gallery_service.dart';
import 'package:nt_helper/db/daos/plugin_installations_dao.dart';

part 'gallery_cubit.freezed.dart';
part 'gallery_state.dart';

class GalleryCubit extends Cubit<GalleryState> {
  final GalleryService _galleryService;
  StreamSubscription<List<QueuedPlugin>>? _queueSubscription;

  GalleryCubit(this._galleryService) : super(const GalleryState.initial()) {
    // Listen to queue changes from the service
    _queueSubscription = _galleryService.queueStream.listen((queue) {
      if (state is GalleryLoaded) {
        emit((state as GalleryLoaded).copyWith(queue: queue));
      }
    });
  }

  @override
  Future<void> close() {
    _queueSubscription?.cancel();
    return super.close();
  }

  Future<void> loadGallery({
    bool forceRefresh = false,
    Set<String>? devicePluginGuids,
  }) async {
    // Stale-while-revalidate: show cached data immediately, refresh in background
    final currentState = state;

    // If we already have loaded data, show it with refreshing indicator
    if (currentState is GalleryLoaded && !forceRefresh) {
      emit(currentState.copyWith(isRefreshing: true));
      _refreshInBackground(devicePluginGuids: devicePluginGuids);
      return;
    }

    // Try to load cached data first (fast path)
    if (currentState is! GalleryLoaded) {
      try {
        final cachedGallery = await _galleryService.fetchGallery(
          forceRefresh: false,
        );

        final queue = _galleryService.installQueue;
        final updateInfo = await _galleryService.compareWithInstalledVersions(
          cachedGallery,
          devicePluginGuids: devicePluginGuids,
        );

        // Emit cached data immediately with refreshing flag
        emit(
          GalleryState.loaded(
            gallery: cachedGallery,
            filteredPlugins: cachedGallery.plugins,
            queue: queue,
            selectedCategory: null,
            selectedType: null,
            showFeaturedOnly: false,
            showVerifiedOnly: false,
            searchQuery: '',
            updateInfo: updateInfo,
            isRefreshing: true,
          ),
        );

        // Refresh in background
        _refreshInBackground(
          devicePluginGuids: devicePluginGuids,
          forceRefresh: true,
        );
        return;
      } catch (_) {
        // No cached data available, fall through to loading state
      }
    }

    // No cached data - show loading spinner
    emit(const GalleryState.loading());

    try {
      final gallery = await _galleryService.fetchGallery(
        forceRefresh: forceRefresh,
      );

      final queue = _galleryService.installQueue;

      // Compare gallery plugins with installed versions immediately
      // Pass device plugin GUIDs to detect manually installed plugins
      final updateInfo = await _galleryService.compareWithInstalledVersions(
        gallery,
        devicePluginGuids: devicePluginGuids,
      );

      emit(
        GalleryState.loaded(
          gallery: gallery,
          filteredPlugins: gallery.plugins,
          queue: queue,
          selectedCategory: null,
          selectedType: null,
          showFeaturedOnly: false,
          showVerifiedOnly: false,
          searchQuery: '',
          updateInfo: updateInfo,
        ),
      );
    } catch (e) {
      emit(GalleryState.error(e.toString()));
    }
  }

  /// Background refresh without blocking UI
  Future<void> _refreshInBackground({
    Set<String>? devicePluginGuids,
    bool forceRefresh = true,
  }) async {
    try {
      final gallery = await _galleryService.fetchGallery(
        forceRefresh: forceRefresh,
      );

      final queue = _galleryService.installQueue;
      final updateInfo = await _galleryService.compareWithInstalledVersions(
        gallery,
        devicePluginGuids: devicePluginGuids,
      );

      // Preserve current filters when updating with fresh data
      final currentState = state;
      if (currentState is GalleryLoaded) {
        final filteredPlugins = _galleryService.searchPlugins(
          gallery,
          query: currentState.searchQuery,
          category: currentState.selectedCategory,
          type: currentState.selectedType,
          featured: currentState.showFeaturedOnly ? true : null,
          verified: currentState.showVerifiedOnly ? true : null,
        );

        emit(
          currentState.copyWith(
            gallery: gallery,
            filteredPlugins: filteredPlugins,
            queue: queue,
            updateInfo: updateInfo,
            isRefreshing: false,
          ),
        );
      } else {
        emit(
          GalleryState.loaded(
            gallery: gallery,
            filteredPlugins: gallery.plugins,
            queue: queue,
            selectedCategory: null,
            selectedType: null,
            showFeaturedOnly: false,
            showVerifiedOnly: false,
            searchQuery: '',
            updateInfo: updateInfo,
          ),
        );
      }
    } catch (e) {
      // Background refresh failed - just clear refreshing flag
      final currentState = state;
      if (currentState is GalleryLoaded) {
        emit(currentState.copyWith(isRefreshing: false));
      }
    }
  }

  void applyFilters({
    String? searchQuery,
    String? category,
    GalleryPluginType? type,
    bool? featured,
    bool? verified,
  }) {
    final currentState = state;
    if (currentState is! GalleryLoaded) return;

    final newSearchQuery = searchQuery ?? currentState.searchQuery;
    final newCategory = category ?? currentState.selectedCategory;
    final newType = type ?? currentState.selectedType;
    final newFeatured = featured ?? currentState.showFeaturedOnly;
    final newVerified = verified ?? currentState.showVerifiedOnly;

    final filteredPlugins = _galleryService.searchPlugins(
      currentState.gallery,
      query: newSearchQuery,
      category: newCategory,
      type: newType,
      featured: newFeatured ? true : null,
      verified: newVerified ? true : null,
    );

    emit(
      currentState.copyWith(
        filteredPlugins: filteredPlugins,
        searchQuery: newSearchQuery,
        selectedCategory: newCategory,
        selectedType: newType,
        showFeaturedOnly: newFeatured,
        showVerifiedOnly: newVerified,
      ),
    );
  }

  void clearFilters() {
    final currentState = state;
    if (currentState is! GalleryLoaded) return;

    emit(
      currentState.copyWith(
        filteredPlugins: currentState.gallery.plugins,
        searchQuery: '',
        selectedCategory: null,
        selectedType: null,
        showFeaturedOnly: false,
        showVerifiedOnly: false,
      ),
    );
  }

  Future<void> addToQueue(GalleryPlugin plugin) async {
    await _galleryService.addToQueue(plugin);
    // State will be updated automatically via the stream listener
  }

  void removeFromQueue(String pluginId) {
    _galleryService.removeFromQueue(pluginId);
    // State will be updated automatically via the stream listener
  }

  void clearQueue() {
    _galleryService.clearQueue();
    // State will be updated automatically via the stream listener
  }

  Future<void> installQueue({
    required Function(
      String fileName,
      Uint8List fileData, {
      Function(double)? onProgress,
    })
    distingInstallPlugin,
  }) async {
    final currentState = state;
    if (currentState is! GalleryLoaded) return;

    try {
      await _galleryService.installQueuedPlugins(
        distingInstallPlugin: distingInstallPlugin,
      );
      // Queue will be cleared automatically and state updated via stream
    } catch (e) {
      // Handle installation errors if needed
      // For now, let the service handle error reporting
    }
  }

  bool isInQueue(String pluginId) {
    final currentState = state;
    if (currentState is! GalleryLoaded) return false;

    return currentState.queue.any((q) => q.plugin.id == pluginId);
  }

  void updateQueuedPluginSelection(
    String pluginId,
    List<CollectionPlugin> selectedPlugins,
  ) {
    _galleryService.updateQueuedPluginSelection(pluginId, selectedPlugins);
    // State will be updated automatically via the stream listener
  }

  /// Get a reference to the gallery service for direct access to download methods
  GalleryService get galleryService => _galleryService;

  // --- Update Management Methods ---

  /// Refresh update information by reloading gallery data
  Future<void> refreshUpdates({Set<String>? devicePluginGuids}) async {
    await loadGallery(
      forceRefresh: true,
      devicePluginGuids: devicePluginGuids,
    );
  }

  /// Get update info for a specific plugin
  PluginUpdateInfo? getPluginUpdateInfo(String pluginId) {
    final currentState = state;
    if (currentState is! GalleryLoaded) return null;

    return currentState.updateInfo[pluginId];
  }

  /// Check if any plugins have updates available
  bool get hasUpdatesAvailable {
    final currentState = state;
    if (currentState is! GalleryLoaded) return false;

    return currentState.updateInfo.values.any((info) => info.updateAvailable);
  }

  /// Get count of plugins with updates available
  int get updateCount {
    final currentState = state;
    if (currentState is! GalleryLoaded) return 0;

    return currentState.updateInfo.values
        .where((info) => info.updateAvailable)
        .length;
  }

  // --- README Documentation Methods ---

  /// Check if README documentation is available for a plugin
}
