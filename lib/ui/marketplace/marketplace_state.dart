part of 'marketplace_cubit.dart';

@freezed
class MarketplaceState with _$MarketplaceState {
  const factory MarketplaceState.initial() = MarketplaceInitial;

  const factory MarketplaceState.loading() = MarketplaceLoading;

  const factory MarketplaceState.loaded({
    required Marketplace marketplace,
    required List<MarketplacePlugin> filteredPlugins,
    required List<QueuedPlugin> queue,
    required String searchQuery,
    String? selectedCategory,
    MarketplacePluginType? selectedType,
    required bool showFeaturedOnly,
    required bool showVerifiedOnly,
  }) = MarketplaceLoaded;

  const factory MarketplaceState.error(String message) = MarketplaceError;
}
