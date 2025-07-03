import 'dart:typed_data';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:nt_helper/models/gallery_models.dart';
import 'package:nt_helper/services/gallery_service.dart';

part 'gallery_cubit.freezed.dart';
part 'gallery_state.dart';

class GalleryCubit extends Cubit<GalleryState> {
  final GalleryService _galleryService;

  GalleryCubit(this._galleryService) : super(const GalleryState.initial()) {
    // Listen to queue changes from the service
    _galleryService.queueStream.listen((queue) {
      if (state is GalleryLoaded) {
        emit((state as GalleryLoaded).copyWith(queue: queue));
      }
    });
  }

  Future<void> loadGallery({bool forceRefresh = false}) async {
    emit(const GalleryState.loading());

    try {
      final gallery = await _galleryService.fetchGallery(
        forceRefresh: forceRefresh,
      );

      final queue = _galleryService.installQueue;

      emit(GalleryState.loaded(
        gallery: gallery,
        filteredPlugins: gallery.plugins,
        queue: queue,
        selectedCategory: null,
        selectedType: null,
        showFeaturedOnly: false,
        showVerifiedOnly: false,
        searchQuery: '',
      ));
    } catch (e) {
      emit(GalleryState.error(e.toString()));
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

    emit(currentState.copyWith(
      filteredPlugins: filteredPlugins,
      searchQuery: newSearchQuery,
      selectedCategory: newCategory,
      selectedType: newType,
      showFeaturedOnly: newFeatured,
      showVerifiedOnly: newVerified,
    ));
  }

  void clearFilters() {
    final currentState = state;
    if (currentState is! GalleryLoaded) return;

    emit(currentState.copyWith(
      filteredPlugins: currentState.gallery.plugins,
      searchQuery: '',
      selectedCategory: null,
      selectedType: null,
      showFeaturedOnly: false,
      showVerifiedOnly: false,
    ));
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
    required Function(String fileName, Uint8List fileData,
            {Function(double)? onProgress})
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

  void updateQueuedPluginSelection(String pluginId, List<CollectionPlugin> selectedPlugins) {
    _galleryService.updateQueuedPluginSelection(pluginId, selectedPlugins);
    // State will be updated automatically via the stream listener
  }

  /// Get a reference to the gallery service for direct access to download methods
  GalleryService get galleryService => _galleryService;
}
