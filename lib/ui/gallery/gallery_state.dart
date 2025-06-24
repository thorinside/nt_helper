part of 'gallery_cubit.dart';

@freezed
class GalleryState with _$GalleryState {
  const factory GalleryState.initial() = GalleryInitial;

  const factory GalleryState.loading() = GalleryLoading;

  const factory GalleryState.loaded({
    required Gallery gallery,
    required List<GalleryPlugin> filteredPlugins,
    required List<QueuedPlugin> queue,
    required String searchQuery,
    String? selectedCategory,
    GalleryPluginType? selectedType,
    required bool showFeaturedOnly,
    required bool showVerifiedOnly,
  }) = GalleryLoaded;

  const factory GalleryState.error(String message) = GalleryError;
}
