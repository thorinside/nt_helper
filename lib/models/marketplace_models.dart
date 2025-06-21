import 'package:freezed_annotation/freezed_annotation.dart';

part 'marketplace_models.freezed.dart';
part 'marketplace_models.g.dart';

/// Marketplace metadata and configuration
@freezed
sealed class MarketplaceMetadata with _$MarketplaceMetadata {
  const factory MarketplaceMetadata({
    required String name,
    required String description,
    required MarketplaceMaintainer maintainer,
  }) = _MarketplaceMetadata;

  factory MarketplaceMetadata.fromJson(Map<String, dynamic> json) =>
      _$MarketplaceMetadataFromJson(json);
}

/// Marketplace maintainer information
@freezed
sealed class MarketplaceMaintainer with _$MarketplaceMaintainer {
  const factory MarketplaceMaintainer({
    required String name,
    String? email,
    String? url,
  }) = _MarketplaceMaintainer;

  factory MarketplaceMaintainer.fromJson(Map<String, dynamic> json) =>
      _$MarketplaceMaintainerFromJson(json);
}

/// Plugin category for organization
@freezed
sealed class PluginCategory with _$PluginCategory {
  const factory PluginCategory({
    required String id,
    required String name,
    String? description,
    String? icon,
  }) = _PluginCategory;

  factory PluginCategory.fromJson(Map<String, dynamic> json) =>
      _$PluginCategoryFromJson(json);
}

/// Plugin author/developer information
@freezed
sealed class PluginAuthor with _$PluginAuthor {
  const factory PluginAuthor({
    required String name,
    String? bio,
    String? website,
    String? avatar,
    @Default(false) bool verified,
    PluginAuthorSocialLinks? socialLinks,
  }) = _PluginAuthor;

  factory PluginAuthor.fromJson(Map<String, dynamic> json) =>
      _$PluginAuthorFromJson(json);
}

/// Social media links for plugin authors
@freezed
sealed class PluginAuthorSocialLinks with _$PluginAuthorSocialLinks {
  const factory PluginAuthorSocialLinks({
    String? github,
    String? twitter,
    String? discord,
  }) = _PluginAuthorSocialLinks;

  factory PluginAuthorSocialLinks.fromJson(Map<String, dynamic> json) =>
      _$PluginAuthorSocialLinksFromJson(json);
}

/// Repository information for a marketplace plugin
@freezed
sealed class PluginRepository with _$PluginRepository {
  const factory PluginRepository({
    required String owner,
    required String name,
    required String url,
    @Default('main') String branch,
  }) = _PluginRepository;

  factory PluginRepository.fromJson(Map<String, dynamic> json) =>
      _$PluginRepositoryFromJson(json);
}

/// Release information for different channels
@freezed
sealed class PluginReleases with _$PluginReleases {
  const factory PluginReleases({
    required String latest,
    String? stable,
    String? beta,
  }) = _PluginReleases;

  factory PluginReleases.fromJson(Map<String, dynamic> json) =>
      _$PluginReleasesFromJson(json);
}

/// Installation configuration for a plugin
@freezed
sealed class PluginInstallation with _$PluginInstallation {
  const factory PluginInstallation({
    required String targetPath,
    String? subdirectory,
    @Default(r'.*\.(zip|tar\.gz)$') String assetPattern,
    @Default(r'.*\.(lua|3pot|o)$') String extractPattern,
    // For directory-based installations
    @Default(false) bool preserveDirectoryStructure,
    String? sourceDirectoryPath,
  }) = _PluginInstallation;

  factory PluginInstallation.fromJson(Map<String, dynamic> json) =>
      _$PluginInstallationFromJson(json);
}

/// Compatibility requirements for a plugin
@freezed
sealed class PluginCompatibility with _$PluginCompatibility {
  const factory PluginCompatibility({
    String? minFirmwareVersion,
    String? maxFirmwareVersion,
    @Default([]) List<String> requiredFeatures,
  }) = _PluginCompatibility;

  factory PluginCompatibility.fromJson(Map<String, dynamic> json) =>
      _$PluginCompatibilityFromJson(json);
}

/// Screenshot information for a plugin
@freezed
sealed class PluginScreenshot with _$PluginScreenshot {
  const factory PluginScreenshot({
    required String url,
    String? caption,
    String? thumbnail,
  }) = _PluginScreenshot;

  factory PluginScreenshot.fromJson(Map<String, dynamic> json) =>
      _$PluginScreenshotFromJson(json);
}

/// Documentation links for a plugin
@freezed
sealed class PluginDocumentation with _$PluginDocumentation {
  const factory PluginDocumentation({
    String? readme,
    String? manual,
    String? examples,
  }) = _PluginDocumentation;

  factory PluginDocumentation.fromJson(Map<String, dynamic> json) =>
      _$PluginDocumentationFromJson(json);
}

/// Usage metrics for a plugin
@freezed
sealed class PluginMetrics with _$PluginMetrics {
  const factory PluginMetrics({
    @Default(0) int downloads,
    double? rating,
    @Default(0) int ratingCount,
  }) = _PluginMetrics;

  factory PluginMetrics.fromJson(Map<String, dynamic> json) =>
      _$PluginMetricsFromJson(json);
}

/// Plugin type enum for marketplace plugins
enum MarketplacePluginType {
  @JsonValue('lua')
  lua,
  @JsonValue('threepot')
  threepot,
  @JsonValue('cpp')
  cpp;

  String get displayName {
    switch (this) {
      case MarketplacePluginType.lua:
        return 'Lua Script';
      case MarketplacePluginType.threepot:
        return '3pot Plugin';
      case MarketplacePluginType.cpp:
        return 'C++ Plugin';
    }
  }

  String get description {
    switch (this) {
      case MarketplacePluginType.lua:
        return 'User-programmable algorithms in Lua';
      case MarketplacePluginType.threepot:
        return 'Three-parameter control plugins';
      case MarketplacePluginType.cpp:
        return 'Compiled native algorithms';
    }
  }
}

/// A marketplace plugin with all metadata
@freezed
sealed class MarketplacePlugin with _$MarketplacePlugin {
  const factory MarketplacePlugin({
    required String id,
    required String name,
    required String description,
    String? longDescription,
    required MarketplacePluginType type,
    String? category,
    @Default([]) List<String> tags,
    required String author,
    required PluginRepository repository,
    required PluginReleases releases,
    required PluginInstallation installation,
    PluginCompatibility? compatibility,
    @Default([]) List<PluginScreenshot> screenshots,
    PluginDocumentation? documentation,
    PluginMetrics? metrics,
    @Default(false) bool featured,
    @Default(false) bool verified,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _MarketplacePlugin;

  factory MarketplacePlugin.fromJson(Map<String, dynamic> json) =>
      _$MarketplacePluginFromJson(json);
}

/// Complete marketplace data structure
@freezed
sealed class Marketplace with _$Marketplace {
  const factory Marketplace({
    required String version,
    required DateTime lastUpdated,
    required MarketplaceMetadata metadata,
    @Default([]) List<PluginCategory> categories,
    @Default({}) Map<String, PluginAuthor> authors,
    @Default([]) List<MarketplacePlugin> plugins,
  }) = _Marketplace;

  factory Marketplace.fromJson(Map<String, dynamic> json) =>
      _$MarketplaceFromJson(json);
}

/// Plugin in the user's install queue
@freezed
sealed class QueuedPlugin with _$QueuedPlugin {
  const factory QueuedPlugin({
    required MarketplacePlugin plugin,
    required String selectedVersion, // 'latest', 'stable', or 'beta'
    @Default(QueuedPluginStatus.queued) QueuedPluginStatus status,
    String? errorMessage,
    double? progress,
  }) = _QueuedPlugin;

  factory QueuedPlugin.fromJson(Map<String, dynamic> json) =>
      _$QueuedPluginFromJson(json);
}

/// Status of a queued plugin installation
enum QueuedPluginStatus {
  queued,
  downloading,
  extracting,
  installing,
  completed,
  failed,
}

/// Extension methods for marketplace plugins
extension MarketplacePluginExtension on MarketplacePlugin {
  /// Get the author information from the marketplace
  PluginAuthor? getAuthor(Marketplace marketplace) {
    return marketplace.authors[author];
  }

  /// Get the category information from the marketplace
  PluginCategory? getCategory(Marketplace marketplace) {
    return marketplace.categories
        .where((cat) => cat.id == category)
        .firstOrNull;
  }

  /// Get the selected version tag
  String getVersionTag(String selectedVersion) {
    switch (selectedVersion.toLowerCase()) {
      case 'stable':
        return releases.stable ?? releases.latest;
      case 'beta':
        return releases.beta ?? releases.latest;
      case 'latest':
      default:
        return releases.latest;
    }
  }

  /// Check if plugin has screenshots
  bool get hasScreenshots => screenshots.isNotEmpty;

  /// Check if plugin has documentation
  bool get hasDocumentation =>
      documentation?.readme != null ||
      documentation?.manual != null ||
      documentation?.examples != null;

  /// Get formatted rating display
  String get formattedRating {
    final rating = metrics?.rating;
    final count = metrics?.ratingCount ?? 0;
    if (rating == null || count == 0) return 'No ratings';
    return '${rating.toStringAsFixed(1)} ★ ($count)';
  }

  /// Get formatted download count
  String get formattedDownloads {
    final downloads = metrics?.downloads ?? 0;
    if (downloads < 1000) return '$downloads';
    if (downloads < 1000000) return '${(downloads / 1000).toStringAsFixed(1)}K';
    return '${(downloads / 1000000).toStringAsFixed(1)}M';
  }
}
