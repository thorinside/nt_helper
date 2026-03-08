part of 'gallery_cubit.dart';

@freezed
class GalleryState with _$GalleryState {
  const factory GalleryState.initial() = GalleryInitial;

  const factory GalleryState.loading() = GalleryLoading;

  const factory GalleryState.loaded({
    required Gallery gallery,
    required List<GalleryPlugin> filteredPlugins,
    required String searchQuery,
    String? selectedCategory,
    GalleryPluginType? selectedType,
    required bool showFeaturedOnly,
    required bool showVerifiedOnly,
    @Default({}) Map<String, PluginUpdateInfo> updateInfo,
    @Default(false) bool isRefreshing,
    @Default({}) Map<String, PluginInstallStatus> installStatuses,
    @Default({}) Map<String, CollectionExpansion> expandedCollections,
  }) = GalleryLoaded;

  const factory GalleryState.error(String message) = GalleryError;
}
