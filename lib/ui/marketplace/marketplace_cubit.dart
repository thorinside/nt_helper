import 'dart:typed_data';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:nt_helper/models/marketplace_models.dart';
import 'package:nt_helper/services/marketplace_service.dart';

part 'marketplace_cubit.freezed.dart';
part 'marketplace_state.dart';

class MarketplaceCubit extends Cubit<MarketplaceState> {
  final MarketplaceService _marketplaceService;

  MarketplaceCubit(this._marketplaceService)
      : super(const MarketplaceState.initial()) {
    // Listen to queue changes from the service
    _marketplaceService.queueStream.listen((queue) {
      if (state is MarketplaceLoaded) {
        emit((state as MarketplaceLoaded).copyWith(queue: queue));
      }
    });
  }

  Future<void> loadMarketplace({bool forceRefresh = false}) async {
    emit(const MarketplaceState.loading());

    try {
      final marketplace = await _marketplaceService.fetchMarketplace(
        forceRefresh: forceRefresh,
      );

      final queue = _marketplaceService.installQueue;

      emit(MarketplaceState.loaded(
        marketplace: marketplace,
        filteredPlugins: marketplace.plugins,
        queue: queue,
        selectedCategory: null,
        selectedType: null,
        showFeaturedOnly: false,
        showVerifiedOnly: false,
        searchQuery: '',
      ));
    } catch (e) {
      emit(MarketplaceState.error(e.toString()));
    }
  }

  void applyFilters({
    String? searchQuery,
    String? category,
    MarketplacePluginType? type,
    bool? featured,
    bool? verified,
  }) {
    final currentState = state;
    if (currentState is! MarketplaceLoaded) return;

    final newSearchQuery = searchQuery ?? currentState.searchQuery;
    final newCategory = category ?? currentState.selectedCategory;
    final newType = type ?? currentState.selectedType;
    final newFeatured = featured ?? currentState.showFeaturedOnly;
    final newVerified = verified ?? currentState.showVerifiedOnly;

    final filteredPlugins = _marketplaceService.searchPlugins(
      currentState.marketplace,
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
    if (currentState is! MarketplaceLoaded) return;

    emit(currentState.copyWith(
      filteredPlugins: currentState.marketplace.plugins,
      searchQuery: '',
      selectedCategory: null,
      selectedType: null,
      showFeaturedOnly: false,
      showVerifiedOnly: false,
    ));
  }

  void addToQueue(MarketplacePlugin plugin) {
    _marketplaceService.addToQueue(plugin);
    // State will be updated automatically via the stream listener
  }

  void removeFromQueue(String pluginId) {
    _marketplaceService.removeFromQueue(pluginId);
    // State will be updated automatically via the stream listener
  }

  void clearQueue() {
    _marketplaceService.clearQueue();
    // State will be updated automatically via the stream listener
  }

  Future<void> installQueue({
    required Function(String fileName, Uint8List fileData,
            {Function(double)? onProgress})
        distingInstallPlugin,
  }) async {
    final currentState = state;
    if (currentState is! MarketplaceLoaded) return;

    try {
      await _marketplaceService.installQueuedPlugins(
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
    if (currentState is! MarketplaceLoaded) return false;

    return currentState.queue.any((q) => q.plugin.id == pluginId);
  }
}
