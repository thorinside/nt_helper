import 'package:freezed_annotation/freezed_annotation.dart';

part 'gallery_models.freezed.dart';
part 'gallery_models.g.dart';

/// Gallery metadata and configuration
@freezed
sealed class GalleryMetadata with _$GalleryMetadata {
  const factory GalleryMetadata({
    required String name,
    required String description,
    required GalleryMaintainer maintainer,
  }) = _GalleryMetadata;

  factory GalleryMetadata.fromJson(Map<String, dynamic> json) =>
      _$GalleryMetadataFromJson(json);
}

/// Gallery maintainer information
@freezed
sealed class GalleryMaintainer with _$GalleryMaintainer {
  const factory GalleryMaintainer({
    required String name,
    String? email,
    String? url,
  }) = _GalleryMaintainer;

  factory GalleryMaintainer.fromJson(Map<String, dynamic> json) =>
      _$GalleryMaintainerFromJson(json);
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

/// Repository information for a gallery plugin
@freezed
sealed class PluginRepository with _$PluginRepository {
  const factory PluginRepository({
    required String owner,
    required String name,
    required String url,
    String? branch,
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
    String? assetPattern,
    String? extractPattern,
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

/// Plugin type enum for gallery plugins
enum GalleryPluginType {
  @JsonValue('lua')
  lua,
  @JsonValue('threepot')
  threepot,
  @JsonValue('cpp')
  cpp;

  String get displayName {
    switch (this) {
      case GalleryPluginType.lua:
        return 'Lua Script';
      case GalleryPluginType.threepot:
        return '3pot Plugin';
      case GalleryPluginType.cpp:
        return 'C++ Plugin';
    }
  }

  String get description {
    switch (this) {
      case GalleryPluginType.lua:
        return 'User-programmable algorithms in Lua';
      case GalleryPluginType.threepot:
        return 'Three-parameter control plugins';
      case GalleryPluginType.cpp:
        return 'Compiled native algorithms';
    }
  }
}

/// A gallery plugin with all metadata
@freezed
sealed class GalleryPlugin with _$GalleryPlugin {
  const factory GalleryPlugin({
    required String id,
    required String name,
    required String description,
    String? longDescription,
    required GalleryPluginType type,
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
  }) = _GalleryPlugin;

  factory GalleryPlugin.fromJson(Map<String, dynamic> json) =>
      _$GalleryPluginFromJson(json);
}

/// Complete gallery data structure
@freezed
sealed class Gallery with _$Gallery {
  const factory Gallery({
    required String version,
    required DateTime lastUpdated,
    required GalleryMetadata metadata,
    @Default([]) List<PluginCategory> categories,
    @Default({}) Map<String, PluginAuthor> authors,
    @Default([]) List<GalleryPlugin> plugins,
  }) = _Gallery;

  factory Gallery.fromJson(Map<String, dynamic> json) =>
      _$GalleryFromJson(json);
}

/// Plugin in the user's install queue
@freezed
sealed class QueuedPlugin with _$QueuedPlugin {
  const factory QueuedPlugin({
    required GalleryPlugin plugin,
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

/// Extension methods for gallery plugins
extension GalleryPluginExtension on GalleryPlugin {
  /// Get the author information from the gallery
  PluginAuthor? getAuthor(Gallery gallery) {
    return gallery.authors[author];
  }

  /// Get the category information from the gallery
  PluginCategory? getCategory(Gallery gallery) {
    return gallery.categories.where((cat) => cat.id == category).firstOrNull;
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
