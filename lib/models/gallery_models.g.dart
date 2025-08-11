// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gallery_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_GalleryMetadata _$GalleryMetadataFromJson(Map<String, dynamic> json) =>
    _GalleryMetadata(
      name: json['name'] as String,
      description: json['description'] as String,
      maintainer: GalleryMaintainer.fromJson(
        json['maintainer'] as Map<String, dynamic>,
      ),
    );

Map<String, dynamic> _$GalleryMetadataToJson(_GalleryMetadata instance) =>
    <String, dynamic>{
      'name': instance.name,
      'description': instance.description,
      'maintainer': instance.maintainer,
    };

_GalleryMaintainer _$GalleryMaintainerFromJson(Map<String, dynamic> json) =>
    _GalleryMaintainer(
      name: json['name'] as String,
      email: json['email'] as String?,
      url: json['url'] as String?,
    );

Map<String, dynamic> _$GalleryMaintainerToJson(_GalleryMaintainer instance) =>
    <String, dynamic>{
      'name': instance.name,
      'email': instance.email,
      'url': instance.url,
    };

_PluginCategory _$PluginCategoryFromJson(Map<String, dynamic> json) =>
    _PluginCategory(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      icon: json['icon'] as String?,
    );

Map<String, dynamic> _$PluginCategoryToJson(_PluginCategory instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'icon': instance.icon,
    };

_PluginAuthor _$PluginAuthorFromJson(Map<String, dynamic> json) =>
    _PluginAuthor(
      name: json['name'] as String,
      bio: json['bio'] as String?,
      website: json['website'] as String?,
      avatar: json['avatar'] as String?,
      verified: json['verified'] as bool? ?? false,
      socialLinks: json['socialLinks'] == null
          ? null
          : PluginAuthorSocialLinks.fromJson(
              json['socialLinks'] as Map<String, dynamic>,
            ),
    );

Map<String, dynamic> _$PluginAuthorToJson(_PluginAuthor instance) =>
    <String, dynamic>{
      'name': instance.name,
      'bio': instance.bio,
      'website': instance.website,
      'avatar': instance.avatar,
      'verified': instance.verified,
      'socialLinks': instance.socialLinks,
    };

_PluginAuthorSocialLinks _$PluginAuthorSocialLinksFromJson(
  Map<String, dynamic> json,
) => _PluginAuthorSocialLinks(
  github: json['github'] as String?,
  twitter: json['twitter'] as String?,
  discord: json['discord'] as String?,
);

Map<String, dynamic> _$PluginAuthorSocialLinksToJson(
  _PluginAuthorSocialLinks instance,
) => <String, dynamic>{
  'github': instance.github,
  'twitter': instance.twitter,
  'discord': instance.discord,
};

_PluginRepository _$PluginRepositoryFromJson(Map<String, dynamic> json) =>
    _PluginRepository(
      owner: json['owner'] as String,
      name: json['name'] as String,
      url: json['url'] as String,
      branch: json['branch'] as String?,
    );

Map<String, dynamic> _$PluginRepositoryToJson(_PluginRepository instance) =>
    <String, dynamic>{
      'owner': instance.owner,
      'name': instance.name,
      'url': instance.url,
      'branch': instance.branch,
    };

_PluginReleases _$PluginReleasesFromJson(Map<String, dynamic> json) =>
    _PluginReleases(
      latest: json['latest'] as String,
      stable: json['stable'] as String?,
      beta: json['beta'] as String?,
    );

Map<String, dynamic> _$PluginReleasesToJson(_PluginReleases instance) =>
    <String, dynamic>{
      'latest': instance.latest,
      'stable': instance.stable,
      'beta': instance.beta,
    };

_PluginInstallation _$PluginInstallationFromJson(Map<String, dynamic> json) =>
    _PluginInstallation(
      targetPath: json['targetPath'] as String,
      subdirectory: json['subdirectory'] as String?,
      assetPattern: json['assetPattern'] as String?,
      extractPattern: json['extractPattern'] as String?,
      downloadUrl: json['downloadUrl'] as String?,
      preserveDirectoryStructure:
          json['preserveDirectoryStructure'] as bool? ?? false,
      sourceDirectoryPath: json['sourceDirectoryPath'] as String?,
    );

Map<String, dynamic> _$PluginInstallationToJson(_PluginInstallation instance) =>
    <String, dynamic>{
      'targetPath': instance.targetPath,
      'subdirectory': instance.subdirectory,
      'assetPattern': instance.assetPattern,
      'extractPattern': instance.extractPattern,
      'downloadUrl': instance.downloadUrl,
      'preserveDirectoryStructure': instance.preserveDirectoryStructure,
      'sourceDirectoryPath': instance.sourceDirectoryPath,
    };

_PluginCompatibility _$PluginCompatibilityFromJson(Map<String, dynamic> json) =>
    _PluginCompatibility(
      minFirmwareVersion: json['minFirmwareVersion'] as String?,
      maxFirmwareVersion: json['maxFirmwareVersion'] as String?,
      requiredFeatures:
          (json['requiredFeatures'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );

Map<String, dynamic> _$PluginCompatibilityToJson(
  _PluginCompatibility instance,
) => <String, dynamic>{
  'minFirmwareVersion': instance.minFirmwareVersion,
  'maxFirmwareVersion': instance.maxFirmwareVersion,
  'requiredFeatures': instance.requiredFeatures,
};

_PluginScreenshot _$PluginScreenshotFromJson(Map<String, dynamic> json) =>
    _PluginScreenshot(
      url: json['url'] as String,
      caption: json['caption'] as String?,
      thumbnail: json['thumbnail'] as String?,
    );

Map<String, dynamic> _$PluginScreenshotToJson(_PluginScreenshot instance) =>
    <String, dynamic>{
      'url': instance.url,
      'caption': instance.caption,
      'thumbnail': instance.thumbnail,
    };

_PluginDocumentation _$PluginDocumentationFromJson(Map<String, dynamic> json) =>
    _PluginDocumentation(
      readme: json['readme'] as String?,
      manual: json['manual'] as String?,
      examples: json['examples'] as String?,
    );

Map<String, dynamic> _$PluginDocumentationToJson(
  _PluginDocumentation instance,
) => <String, dynamic>{
  'readme': instance.readme,
  'manual': instance.manual,
  'examples': instance.examples,
};

_PluginMetrics _$PluginMetricsFromJson(Map<String, dynamic> json) =>
    _PluginMetrics(
      downloads: (json['downloads'] as num?)?.toInt() ?? 0,
      rating: (json['rating'] as num?)?.toDouble(),
      ratingCount: (json['ratingCount'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$PluginMetricsToJson(_PluginMetrics instance) =>
    <String, dynamic>{
      'downloads': instance.downloads,
      'rating': instance.rating,
      'ratingCount': instance.ratingCount,
    };

_GalleryPlugin _$GalleryPluginFromJson(Map<String, dynamic> json) =>
    _GalleryPlugin(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      longDescription: json['longDescription'] as String?,
      type: $enumDecode(_$GalleryPluginTypeEnumMap, json['type']),
      category: json['category'] as String?,
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
          const [],
      author: json['author'] as String,
      repository: PluginRepository.fromJson(
        json['repository'] as Map<String, dynamic>,
      ),
      releases: PluginReleases.fromJson(
        json['releases'] as Map<String, dynamic>,
      ),
      installation: PluginInstallation.fromJson(
        json['installation'] as Map<String, dynamic>,
      ),
      compatibility: json['compatibility'] == null
          ? null
          : PluginCompatibility.fromJson(
              json['compatibility'] as Map<String, dynamic>,
            ),
      screenshots:
          (json['screenshots'] as List<dynamic>?)
              ?.map((e) => PluginScreenshot.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      documentation: json['documentation'] == null
          ? null
          : PluginDocumentation.fromJson(
              json['documentation'] as Map<String, dynamic>,
            ),
      metrics: json['metrics'] == null
          ? null
          : PluginMetrics.fromJson(json['metrics'] as Map<String, dynamic>),
      featured: json['featured'] as bool? ?? false,
      verified: json['verified'] as bool? ?? false,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$GalleryPluginToJson(_GalleryPlugin instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'longDescription': instance.longDescription,
      'type': _$GalleryPluginTypeEnumMap[instance.type]!,
      'category': instance.category,
      'tags': instance.tags,
      'author': instance.author,
      'repository': instance.repository,
      'releases': instance.releases,
      'installation': instance.installation,
      'compatibility': instance.compatibility,
      'screenshots': instance.screenshots,
      'documentation': instance.documentation,
      'metrics': instance.metrics,
      'featured': instance.featured,
      'verified': instance.verified,
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };

const _$GalleryPluginTypeEnumMap = {
  GalleryPluginType.lua: 'lua',
  GalleryPluginType.threepot: 'threepot',
  GalleryPluginType.cpp: 'cpp',
};

_Gallery _$GalleryFromJson(Map<String, dynamic> json) => _Gallery(
  version: json['version'] as String,
  lastUpdated: DateTime.parse(json['lastUpdated'] as String),
  metadata: GalleryMetadata.fromJson(json['metadata'] as Map<String, dynamic>),
  categories:
      (json['categories'] as List<dynamic>?)
          ?.map((e) => PluginCategory.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  authors:
      (json['authors'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, PluginAuthor.fromJson(e as Map<String, dynamic>)),
      ) ??
      const {},
  plugins:
      (json['plugins'] as List<dynamic>?)
          ?.map((e) => GalleryPlugin.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
);

Map<String, dynamic> _$GalleryToJson(_Gallery instance) => <String, dynamic>{
  'version': instance.version,
  'lastUpdated': instance.lastUpdated.toIso8601String(),
  'metadata': instance.metadata,
  'categories': instance.categories,
  'authors': instance.authors,
  'plugins': instance.plugins,
};

_CollectionPlugin _$CollectionPluginFromJson(Map<String, dynamic> json) =>
    _CollectionPlugin(
      name: json['name'] as String,
      relativePath: json['relativePath'] as String,
      fileType: json['fileType'] as String,
      description: json['description'] as String?,
      fileSize: (json['fileSize'] as num?)?.toInt(),
      selected: json['selected'] as bool? ?? false,
    );

Map<String, dynamic> _$CollectionPluginToJson(_CollectionPlugin instance) =>
    <String, dynamic>{
      'name': instance.name,
      'relativePath': instance.relativePath,
      'fileType': instance.fileType,
      'description': instance.description,
      'fileSize': instance.fileSize,
      'selected': instance.selected,
    };

_QueuedPlugin _$QueuedPluginFromJson(Map<String, dynamic> json) =>
    _QueuedPlugin(
      plugin: GalleryPlugin.fromJson(json['plugin'] as Map<String, dynamic>),
      selectedVersion: json['selectedVersion'] as String,
      isCollection: json['isCollection'] as bool,
      status:
          $enumDecodeNullable(_$QueuedPluginStatusEnumMap, json['status']) ??
          QueuedPluginStatus.queued,
      errorMessage: json['errorMessage'] as String?,
      progress: (json['progress'] as num?)?.toDouble(),
      selectedPlugins:
          (json['selectedPlugins'] as List<dynamic>?)
              ?.map((e) => CollectionPlugin.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$QueuedPluginToJson(_QueuedPlugin instance) =>
    <String, dynamic>{
      'plugin': instance.plugin,
      'selectedVersion': instance.selectedVersion,
      'isCollection': instance.isCollection,
      'status': _$QueuedPluginStatusEnumMap[instance.status]!,
      'errorMessage': instance.errorMessage,
      'progress': instance.progress,
      'selectedPlugins': instance.selectedPlugins,
    };

const _$QueuedPluginStatusEnumMap = {
  QueuedPluginStatus.queued: 'queued',
  QueuedPluginStatus.analyzing: 'analyzing',
  QueuedPluginStatus.downloading: 'downloading',
  QueuedPluginStatus.extracting: 'extracting',
  QueuedPluginStatus.installing: 'installing',
  QueuedPluginStatus.completed: 'completed',
  QueuedPluginStatus.failed: 'failed',
};
