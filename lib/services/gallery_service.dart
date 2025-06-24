import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:nt_helper/models/gallery_models.dart';
import 'package:nt_helper/db/database.dart';
import 'package:nt_helper/services/settings_service.dart';
import 'package:archive/archive.dart';
import 'package:path/path.dart' as path;

/// Service for managing the plugin gallery
class GalleryService {
  final AppDatabase? _database;
  final SettingsService _settingsService;
  Gallery? _cachedGallery;
  DateTime? _lastFetch;
  final Duration _cacheTimeout = const Duration(hours: 1);

  final List<QueuedPlugin> _installQueue = [];
  final StreamController<List<QueuedPlugin>> _queueController =
      StreamController<List<QueuedPlugin>>.broadcast();

  /// Constructor with optional database for installation tracking
  GalleryService({
    AppDatabase? database,
    required SettingsService settingsService,
  })
      : _database = database,
        _settingsService = settingsService;

  /// Stream of install queue updates
  Stream<List<QueuedPlugin>> get queueStream => _queueController.stream;

  /// Current install queue
  List<QueuedPlugin> get installQueue => List.unmodifiable(_installQueue);

  /// Current gallery URL
  String get galleryUrl => _settingsService.galleryUrl;

  /// Force clear the cache (useful for testing new URLs)
  void clearCache() {
    _invalidateCache();
  }

  /// Fetch gallery data with caching
  Future<Gallery> fetchGallery({bool forceRefresh = false}) async {
    // Return cached data if valid and not forcing refresh
    if (!forceRefresh &&
        _cachedGallery != null &&
        _lastFetch != null &&
        DateTime.now().difference(_lastFetch!) < _cacheTimeout) {
      return _cachedGallery!;
    }

    try {
      final url = galleryUrl;
      debugPrint('Loading gallery from: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
          'User-Agent': 'Disting-NT-Helper/1.0',
          'Cache-Control': 'no-cache',
        },
      ).timeout(const Duration(seconds: 30));

      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response headers: ${response.headers}');
      debugPrint('Response content-type: ${response.headers['content-type']}');

      if (response.statusCode == 200) {
        debugPrint('Response body length: ${response.body.length}');
        debugPrint(
            'Response body preview: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}');

        // Check if the response looks like HTML (Google Drive error page)
        if (response.body.trim().startsWith('<')) {
          throw GalleryException(
            'Received HTML instead of JSON. This might be a Google Drive access issue or the file is not publicly accessible.',
          );
        }

        final jsonData = json.decode(response.body) as Map<String, dynamic>;

        // --- Start of added debug prints ---
        debugPrint('==== In-depth JSON Data Inspection Start ====');
        try {
          debugPrint(
              'Full jsonData (first 500 chars): ${json.encode(jsonData).substring(0, json.encode(jsonData).length > 500 ? 500 : json.encode(jsonData).length)}...');

          debugPrint('Inspecting Gallery root fields:');
          debugPrint(
              '  version: ${jsonData['version']} (type: ${jsonData['version']?.runtimeType})');
          debugPrint(
              '  lastUpdated: ${jsonData['lastUpdated']} (type: ${jsonData['lastUpdated']?.runtimeType})');

          if (jsonData['metadata'] != null && jsonData['metadata'] is Map) {
            final meta = jsonData['metadata'] as Map<String, dynamic>;
            debugPrint(
                '  metadata.name: ${meta['name']} (type: ${meta['name']?.runtimeType})');
            debugPrint(
                '  metadata.description: ${meta['description']} (type: ${meta['description']?.runtimeType})');
            if (meta['maintainer'] != null && meta['maintainer'] is Map) {
              final maintainer = meta['maintainer'] as Map<String, dynamic>;
              debugPrint(
                  '  metadata.maintainer.name: ${maintainer['name']} (type: ${maintainer['name']?.runtimeType})');
              debugPrint(
                  '  metadata.maintainer.email: ${maintainer['email']} (type: ${maintainer['email']?.runtimeType})');
              debugPrint(
                  '  metadata.maintainer.url: ${maintainer['url']} (type: ${maintainer['url']?.runtimeType})');
            } else {
              debugPrint(
                  '  metadata.maintainer is null or not a Map. Value: ${meta['maintainer']}');
            }
          } else {
            debugPrint(
                '  metadata is null or not a Map. Value: ${jsonData['metadata']}');
          }

          if (jsonData['categories'] != null &&
              jsonData['categories'] is List) {
            final categoriesList = jsonData['categories'] as List;
            if (categoriesList.isNotEmpty) {
              final category = categoriesList.first as Map<String, dynamic>;
              debugPrint('Inspecting first category:');
              debugPrint(
                  '  category.id: ${category['id']} (type: ${category['id']?.runtimeType})');
              debugPrint(
                  '  category.name: ${category['name']} (type: ${category['name']?.runtimeType})');
              debugPrint(
                  '  category.description: ${category['description']} (type: ${category['description']?.runtimeType})');
              debugPrint(
                  '  category.icon: ${category['icon']} (type: ${category['icon']?.runtimeType})');
            } else {
              debugPrint('  categories list is empty.');
            }
          } else {
            debugPrint(
                '  categories is null or not a List. Value: ${jsonData['categories']}');
          }

          if (jsonData['authors'] != null && jsonData['authors'] is Map) {
            final authorsMap = jsonData['authors'] as Map<String, dynamic>;
            if (authorsMap.isNotEmpty) {
              final firstAuthorKey = authorsMap.keys.first;
              final author = authorsMap[firstAuthorKey] as Map<String, dynamic>;
              debugPrint('Inspecting first author ("$firstAuthorKey"):');
              debugPrint(
                  '  author.name: ${author['name']} (type: ${author['name']?.runtimeType})');
              debugPrint(
                  '  author.bio: ${author['bio']} (type: ${author['bio']?.runtimeType})');
              debugPrint(
                  '  author.website: ${author['website']} (type: ${author['website']?.runtimeType})');
              debugPrint(
                  '  author.avatar: ${author['avatar']} (type: ${author['avatar']?.runtimeType})');
            } else {
              debugPrint('  authors map is empty.');
            }
          } else {
            debugPrint(
                '  authors is null or not a Map. Value: ${jsonData['authors']}');
          }

          if (jsonData['plugins'] != null && jsonData['plugins'] is List) {
            final pluginsList = jsonData['plugins'] as List;
            if (pluginsList.isNotEmpty) {
              final plugin = pluginsList.first as Map<String, dynamic>;
              debugPrint('Inspecting first plugin:');
              debugPrint(
                  '  plugin.id: ${plugin['id']} (type: ${plugin['id']?.runtimeType})');
              debugPrint(
                  '  plugin.name: ${plugin['name']} (type: ${plugin['name']?.runtimeType})');
              debugPrint(
                  '  plugin.description: ${plugin['description']} (type: ${plugin['description']?.runtimeType})');
              debugPrint(
                  '  plugin.longDescription: ${plugin['longDescription']} (type: ${plugin['longDescription']?.runtimeType})');
              debugPrint(
                  '  plugin.type: ${plugin['type']} (type: ${plugin['type']?.runtimeType})');
              debugPrint(
                  '  plugin.category: ${plugin['category']} (type: ${plugin['category']?.runtimeType})');
              debugPrint(
                  '  plugin.author: ${plugin['author']} (type: ${plugin['author']?.runtimeType})');

              // --- Start: Added prints for plugin.tags ---
              if (plugin['tags'] != null && plugin['tags'] is List) {
                final tagsList = plugin['tags'] as List;
                debugPrint('  plugin.tags (count: ${tagsList.length}):');
                for (int i = 0; i < tagsList.length; i++) {
                  debugPrint(
                      '    tag[$i]: ${tagsList[i]} (type: ${tagsList[i]?.runtimeType})');
                }
              } else {
                debugPrint(
                    '  plugin.tags is null or not a List. Value: ${plugin['tags']}');
              }
              // --- End: Added prints for plugin.tags ---

              if (plugin['repository'] != null && plugin['repository'] is Map) {
                final repo = plugin['repository'] as Map<String, dynamic>;
                debugPrint(
                    '  plugin.repository.owner: ${repo['owner']} (type: ${repo['owner']?.runtimeType})');
                debugPrint(
                    '  plugin.repository.name: ${repo['name']} (type: ${repo['name']?.runtimeType})');
                debugPrint(
                    '  plugin.repository.url: ${repo['url']} (type: ${repo['url']?.runtimeType})');
                debugPrint(
                    '  plugin.repository.branch: ${repo['branch']} (type: ${repo['branch']?.runtimeType})');
              } else {
                debugPrint(
                    '  plugin.repository is null or not a Map. Value: ${plugin['repository']}');
              }

              if (plugin['releases'] != null && plugin['releases'] is Map) {
                final releases = plugin['releases'] as Map<String, dynamic>;
                debugPrint(
                    '  plugin.releases.latest: ${releases['latest']} (type: ${releases['latest']?.runtimeType})');
                debugPrint(
                    '  plugin.releases.stable: ${releases['stable']} (type: ${releases['stable']?.runtimeType})');
                debugPrint(
                    '  plugin.releases.beta: ${releases['beta']} (type: ${releases['beta']?.runtimeType})');
              } else {
                debugPrint(
                    '  plugin.releases is null or not a Map. Value: ${plugin['releases']}');
              }

              if (plugin['installation'] != null &&
                  plugin['installation'] is Map) {
                final installation =
                    plugin['installation'] as Map<String, dynamic>;
                debugPrint(
                    '  plugin.installation.targetPath: ${installation['targetPath']} (type: ${installation['targetPath']?.runtimeType})');
                debugPrint(
                    '  plugin.installation.subdirectory: ${installation['subdirectory']} (type: ${installation['subdirectory']?.runtimeType})');
                debugPrint(
                    '  plugin.installation.assetPattern: ${installation['assetPattern']} (type: ${installation['assetPattern']?.runtimeType})');
                debugPrint(
                    '  plugin.installation.extractPattern: ${installation['extractPattern']} (type: ${installation['extractPattern']?.runtimeType})');
                debugPrint(
                    '  plugin.installation.sourceDirectoryPath: ${installation['sourceDirectoryPath']} (type: ${installation['sourceDirectoryPath']?.runtimeType})');
              } else {
                debugPrint(
                    '  plugin.installation is null or not a Map. Value: ${plugin['installation']}');
              }

              // --- Start: Added prints for plugin.compatibility.requiredFeatures ---
              if (plugin['compatibility'] != null &&
                  plugin['compatibility'] is Map) {
                final compatibility =
                    plugin['compatibility'] as Map<String, dynamic>;
                debugPrint(
                    '  plugin.compatibility.minFirmwareVersion: ${compatibility['minFirmwareVersion']} (type: ${compatibility['minFirmwareVersion']?.runtimeType})');
                debugPrint(
                    '  plugin.compatibility.maxFirmwareVersion: ${compatibility['maxFirmwareVersion']} (type: ${compatibility['maxFirmwareVersion']?.runtimeType})');
                if (compatibility['requiredFeatures'] != null &&
                    compatibility['requiredFeatures'] is List) {
                  final featuresList =
                      compatibility['requiredFeatures'] as List;
                  debugPrint(
                      '  plugin.compatibility.requiredFeatures (count: ${featuresList.length}):');
                  for (int i = 0; i < featuresList.length; i++) {
                    debugPrint(
                        '    feature[$i]: ${featuresList[i]} (type: ${featuresList[i]?.runtimeType})');
                  }
                } else {
                  debugPrint(
                      '  plugin.compatibility.requiredFeatures is null or not a List. Value: ${compatibility['requiredFeatures']}');
                }
              } else {
                debugPrint(
                    '  plugin.compatibility is null or not a Map. Value: ${plugin['compatibility']}');
              }
              // --- End: Added prints for plugin.compatibility.requiredFeatures ---

              if (plugin['screenshots'] != null &&
                  plugin['screenshots'] is List) {
                final screenshotsList = plugin['screenshots'] as List;
                if (screenshotsList.isNotEmpty) {
                  final screenshot =
                      screenshotsList.first as Map<String, dynamic>;
                  debugPrint('  Inspecting first plugin screenshot:');
                  debugPrint(
                      '    screenshot.url: ${screenshot['url']} (type: ${screenshot['url']?.runtimeType})');
                  debugPrint(
                      '    screenshot.caption: ${screenshot['caption']} (type: ${screenshot['caption']?.runtimeType})');
                  debugPrint(
                      '    screenshot.thumbnail: ${screenshot['thumbnail']} (type: ${screenshot['thumbnail']?.runtimeType})');
                } else {
                  debugPrint('  plugin.screenshots list is empty.');
                }
              } else {
                debugPrint(
                    '  plugin.screenshots is null or not a List. Value: ${plugin['screenshots']}');
              }
            } else {
              debugPrint('  plugins list is empty.');
            }
          } else {
            debugPrint(
                '  plugins is null or not a List. Value: ${jsonData['plugins']}');
          }
        } catch (e, s) {
          debugPrint('Error during detailed JSON inspection: $e\n$s');
        }
        debugPrint('==== In-depth JSON Data Inspection End ====');
        // --- End of added debug prints ---

        final gallery = Gallery.fromJson(jsonData);

        _cachedGallery = gallery;
        _lastFetch = DateTime.now();

        return gallery;
      } else {
        throw GalleryException(
          'Failed to fetch gallery: HTTP ${response.statusCode} - ${response.reasonPhrase}',
        );
      }
    } catch (e) {
      debugPrint('Error loading gallery: $e');
      if (e is GalleryException) rethrow;
      throw GalleryException('Network error: ${e.toString()}');
    }
  }

  /// Search plugins with optional filters
  List<GalleryPlugin> searchPlugins(
    Gallery gallery, {
    String? query,
    String? category,
    GalleryPluginType? type,
    bool? featured,
    bool? verified,
  }) {
    var plugins = gallery.plugins;

    // Filter by search query
    if (query != null && query.isNotEmpty) {
      final lowerQuery = query.toLowerCase();
      plugins = plugins.where((plugin) {
        return plugin.name.toLowerCase().contains(lowerQuery) ||
            plugin.description.toLowerCase().contains(lowerQuery) ||
            plugin.tags.any((tag) => tag.toLowerCase().contains(lowerQuery)) ||
            plugin.author.toLowerCase().contains(lowerQuery);
      }).toList();
    }

    // Filter by category
    if (category != null && category.isNotEmpty) {
      plugins = plugins.where((plugin) => plugin.category == category).toList();
    }

    // Filter by type
    if (type != null) {
      plugins = plugins.where((plugin) => plugin.type == type).toList();
    }

    // Filter by featured status
    if (featured == true) {
      plugins = plugins.where((plugin) => plugin.featured).toList();
    }

    // Filter by verified status
    if (verified == true) {
      plugins = plugins.where((plugin) => plugin.verified).toList();
    }

    return plugins;
  }

  /// Add plugin to install queue
  void addToQueue(GalleryPlugin plugin, {String version = 'latest'}) {
    // Check if already in queue
    final existingIndex =
        _installQueue.indexWhere((q) => q.plugin.id == plugin.id);

    if (existingIndex >= 0) {
      // Update existing entry
      _installQueue[existingIndex] = _installQueue[existingIndex].copyWith(
        selectedVersion: version,
        status: QueuedPluginStatus.queued,
        errorMessage: null,
        progress: null,
      );
    } else {
      // Add new entry
      _installQueue.add(QueuedPlugin(
        plugin: plugin,
        selectedVersion: version,
      ));
    }

    _notifyQueueChanged();
  }

  /// Remove plugin from install queue
  void removeFromQueue(String pluginId) {
    _installQueue.removeWhere((q) => q.plugin.id == pluginId);
    _notifyQueueChanged();
  }

  /// Clear all plugins from install queue
  void clearQueue() {
    _installQueue.clear();
    _notifyQueueChanged();
  }

  /// Check if plugin is in queue
  bool isInQueue(String pluginId) {
    return _installQueue.any((q) => q.plugin.id == pluginId);
  }

  /// Get queued plugin by ID
  QueuedPlugin? getQueuedPlugin(String pluginId) {
    try {
      return _installQueue.firstWhere((q) => q.plugin.id == pluginId);
    } catch (e) {
      return null;
    }
  }

  /// Install all plugins in the queue using Disting upload functionality
  Future<void> installQueuedPlugins({
    required Function(String fileName, Uint8List fileData,
            {Function(double)? onProgress})
        distingInstallPlugin,
    Function(QueuedPlugin)? onPluginStart,
    Function(QueuedPlugin, double)? onProgress,
    Function(QueuedPlugin)? onPluginComplete,
    Function(QueuedPlugin, String)? onPluginError,
  }) async {
    final pluginsToInstall = _installQueue
        .where((q) => q.status == QueuedPluginStatus.queued)
        .toList();

    for (final queuedPlugin in pluginsToInstall) {
      try {
        onPluginStart?.call(queuedPlugin);

        // Track installation details for database recording
        int fileCount = 0;
        int totalBytes = 0;

        await _installSinglePluginViaDisting(
          queuedPlugin,
          distingInstallPlugin,
          onProgress: onProgress,
          onInstallationDetails: (files, bytes) {
            fileCount = files;
            totalBytes = bytes;
          },
        );

        _updateQueuedPlugin(queuedPlugin.plugin.id,
            status: QueuedPluginStatus.completed);
        onPluginComplete?.call(queuedPlugin);

        // Record successful installation in database
        // TODO: Implement plugin installation tracking in database
        // if (_database != null) {
        //   try {
        //     final installationPath = _getInstallationPath(queuedPlugin.plugin);
        //     await _database!.pluginInstallationsDao.recordPluginInstallation(
        //       plugin: queuedPlugin.plugin,
        //       installedVersion: queuedPlugin.selectedVersion,
        //       installationPath: installationPath,
        //       fileCount: fileCount,
        //       totalBytes: totalBytes,
        //       installationNotes: 'Installed via gallery',
        //     );
        //     debugPrint(
        //         'Recorded successful installation of ${queuedPlugin.plugin.name} in database');
        //   } catch (dbError) {
        //     debugPrint('Failed to record installation in database: $dbError');
        //     // Don't fail the installation if database recording fails
        //   }
        // }

        // Remove successfully completed plugin from queue
        removeFromQueue(queuedPlugin.plugin.id);
      } catch (e) {
        final errorMessage = e.toString();
        _updateQueuedPlugin(queuedPlugin.plugin.id,
            status: QueuedPluginStatus.failed, errorMessage: errorMessage);
        onPluginError?.call(queuedPlugin, errorMessage);

        // Record failed installation in database
        // TODO: Implement plugin installation failure tracking in database
        // if (_database != null) {
        //   try {
        //     final installationPath = _getInstallationPath(queuedPlugin.plugin);
        //     await _database!.pluginInstallationsDao
        //         .recordPluginInstallationFailure(
        //       plugin: queuedPlugin.plugin,
        //       attemptedVersion: queuedPlugin.selectedVersion,
        //       installationPath: installationPath,
        //       errorMessage: errorMessage,
        //     );
        //     debugPrint(
        //         'Recorded failed installation of ${queuedPlugin.plugin.name} in database');
        //   } catch (dbError) {
        //     debugPrint(
        //         'Failed to record installation failure in database: $dbError');
        //   }
        // }

        // Keep failed plugin in queue so user can see the error message
        // They can manually remove it if desired
      }
    }
  }

  /// Install a single plugin using Disting upload functionality
  Future<void> _installSinglePluginViaDisting(
    QueuedPlugin queuedPlugin,
    Function(String fileName, Uint8List fileData,
            {Function(double)? onProgress})
        distingInstallPlugin, {
    Function(QueuedPlugin, double)? onProgress,
    Function(int, int)? onInstallationDetails,
  }) async {
    final plugin = queuedPlugin.plugin;
    final version = plugin.getVersionTag(queuedPlugin.selectedVersion);

    debugPrint(
        '🚀 _installSinglePluginViaDisting: Starting installation of ${plugin.name}');
    debugPrint('🚀 Plugin ID: ${plugin.id}');
    debugPrint('🚀 Selected version: ${queuedPlugin.selectedVersion}');
    debugPrint('🚀 Resolved version tag: $version');
    debugPrint(
        '🚀 Repository: ${plugin.repository.owner}/${plugin.repository.name}');
    debugPrint('🚀 Installation config: ${plugin.installation.toJson()}');

    // Update status to downloading
    _updateQueuedPlugin(plugin.id,
        status: QueuedPluginStatus.downloading, progress: 0.0);

    // Download the release archive
    debugPrint('🚀 _installSinglePluginViaDisting: Getting download URL...');
    final downloadUrl = await _getDownloadUrl(plugin.repository, version);
    debugPrint(
        '🚀 _installSinglePluginViaDisting: Final download URL: $downloadUrl');

    debugPrint('🚀 _installSinglePluginViaDisting: Starting download...');
    final archiveBytes = await _downloadWithProgress(
      downloadUrl,
      (progress) {
        _updateQueuedPlugin(plugin.id,
            progress: progress * 0.6); // 60% for download
        onProgress?.call(queuedPlugin, progress * 0.6);
      },
    );

    // Update status to extracting
    _updateQueuedPlugin(plugin.id,
        status: QueuedPluginStatus.extracting, progress: 0.6);

    // Extract the archive
    final extractedFiles = await _extractArchive(archiveBytes, plugin);

    // Update status to installing
    _updateQueuedPlugin(plugin.id,
        status: QueuedPluginStatus.installing, progress: 0.8);

    // Install files using Disting upload functionality
    await _installFilesViaDisting(extractedFiles, plugin, distingInstallPlugin,
        (uploadProgress) {
      final totalProgress = 0.8 + (uploadProgress * 0.2); // 20% for upload
      _updateQueuedPlugin(plugin.id, progress: totalProgress);
      onProgress?.call(queuedPlugin, totalProgress);
    });

    // Update progress to complete
    _updateQueuedPlugin(plugin.id, progress: 1.0);

    // Notify installation details
    if (onInstallationDetails != null) {
      final totalBytes = archiveBytes.length;
      onInstallationDetails(extractedFiles.length, totalBytes);
    }
  }

  /// Get download URL for a GitHub release or commit
  Future<String> _getDownloadUrl(PluginRepository repo, String version) async {
    debugPrint(
        '🔍 _getDownloadUrl: Starting URL resolution for ${repo.owner}/${repo.name} version $version');

    // Check if version looks like a commit hash (40 hex characters)
    final commitHashPattern = RegExp(r'^[a-f0-9]{40}$');

    if (commitHashPattern.hasMatch(version)) {
      // Direct commit hash - use archive download
      final url =
          'https://github.com/${repo.owner}/${repo.name}/archive/$version.zip';
      debugPrint(
          '🔍 _getDownloadUrl: Detected commit hash, using direct archive URL: $url');
      return url;
    }

    // Check if version is "main" or similar branch name
    if (version == 'main' || version == 'master' || version == 'develop') {
      // Use branch archive download
      final url =
          'https://github.com/${repo.owner}/${repo.name}/archive/refs/heads/$version.zip';
      debugPrint(
          '🔍 _getDownloadUrl: Detected branch name, using branch archive URL: $url');
      return url;
    }

    // Try to get release with assets first
    final apiUrl =
        'https://api.github.com/repos/${repo.owner}/${repo.name}/releases/tags/$version';
    debugPrint(
        '🔍 _getDownloadUrl: Checking GitHub API for release assets: $apiUrl');

    try {
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {'Accept': 'application/vnd.github.v3+json'},
      );

      debugPrint(
          '🔍 _getDownloadUrl: GitHub API response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final releaseData = json.decode(response.body) as Map<String, dynamic>;
        final assets = releaseData['assets'] as List;

        debugPrint(
            '🔍 _getDownloadUrl: Found release with ${assets.length} assets');

        if (assets.isNotEmpty) {
          // Find the first asset that matches the pattern (usually a .zip file)
          final asset = assets.first as Map<String, dynamic>;
          final assetUrl = asset['browser_download_url'] as String;
          debugPrint('🔍 _getDownloadUrl: Using release asset URL: $assetUrl');
          return assetUrl;
        } else {
          debugPrint(
              '🔍 _getDownloadUrl: Release exists but has no assets, falling back to source archive');
        }
        // If release exists but has no assets, fall through to source archive
      } else {
        debugPrint(
            '🔍 _getDownloadUrl: Release not found (${response.statusCode}), falling back to source archive');
      }
      // If release doesn't exist (404), fall through to source archive
    } catch (e) {
      // If API call fails, fall through to source archive
      debugPrint(
          '🔍 _getDownloadUrl: Release API failed for $version, trying source archive: $e');
    }

    // Fallback: use source archive for the tag/version
    final fallbackUrl =
        'https://github.com/${repo.owner}/${repo.name}/archive/refs/tags/$version.zip';
    debugPrint(
        '🔍 _getDownloadUrl: Using fallback source archive URL: $fallbackUrl');
    debugPrint(
        'Using source archive for ${repo.owner}/${repo.name} version $version');
    return fallbackUrl;
  }

  /// Download file with progress tracking
  Future<List<int>> _downloadWithProgress(
    String url,
    Function(double) onProgress,
  ) async {
    debugPrint('📥 _downloadWithProgress: Starting download from: $url');

    final request = http.Request('GET', Uri.parse(url));
    debugPrint('📥 _downloadWithProgress: Sending HTTP GET request...');

    final response = await http.Client().send(request);

    debugPrint(
        '📥 _downloadWithProgress: Response received - Status: ${response.statusCode}');
    debugPrint(
        '📥 _downloadWithProgress: Response headers: ${response.headers}');
    debugPrint(
        '📥 _downloadWithProgress: Content-Length: ${response.contentLength}');

    if (response.statusCode != 200) {
      debugPrint(
          '📥 _downloadWithProgress: Download failed with status ${response.statusCode}');

      // Try to read error response body for more details
      try {
        final errorBytes = <int>[];
        await for (final chunk in response.stream) {
          errorBytes.addAll(chunk);
          if (errorBytes.length > 1000) break; // Limit error response size
        }
        final errorBody = String.fromCharCodes(errorBytes);
        debugPrint('📥 _downloadWithProgress: Error response body: $errorBody');
      } catch (e) {
        debugPrint(
            '📥 _downloadWithProgress: Could not read error response: $e');
      }

      throw GalleryException(
          'Download failed: HTTP ${response.statusCode} for URL: $url');
    }

    final contentLength = response.contentLength;
    final bytes = <int>[];

    debugPrint('📥 _downloadWithProgress: Starting to read response stream...');

    await for (final chunk in response.stream) {
      bytes.addAll(chunk);
      if (contentLength != null && contentLength > 0) {
        final progress = bytes.length / contentLength;
        onProgress(progress);
        if (bytes.length % 50000 == 0) {
          // Log every ~50KB
          debugPrint(
              '📥 _downloadWithProgress: Downloaded ${bytes.length}/${contentLength} bytes (${(progress * 100).toStringAsFixed(1)}%)');
        }
      }
    }

    debugPrint(
        '📥 _downloadWithProgress: Download completed - Total bytes: ${bytes.length}');
    return bytes;
  }

  /// Extract archive and filter relevant files
  Future<List<MapEntry<String, List<int>>>> _extractArchive(
    List<int> archiveBytes,
    GalleryPlugin plugin,
  ) async {
    final archive = ZipDecoder().decodeBytes(archiveBytes);
    final extractedFiles = <MapEntry<String, List<int>>>[];
    final installation = plugin.installation;
    final extractPattern =
        RegExp(installation.extractPattern ?? r'.*\.(lua|3pot|o)$');

    debugPrint(
        'Extracting archive for ${plugin.name}, looking for pattern: ${installation.extractPattern ?? r'.*\.(lua|3pot|o)$'}');

    for (final file in archive) {
      if (!file.isFile) continue;

      String originalPath = file.name;
      String processedPath = originalPath;

      // Handle GitHub archive structure (removes top-level directory)
      // GitHub archives come as "repo-name-version/..." so we need to strip that
      final pathParts = originalPath.split('/');
      if (pathParts.length > 1 && pathParts[0].contains('-')) {
        // Remove the top-level directory that GitHub adds
        processedPath = pathParts.skip(1).join('/');
      }

      // For directory-based installations, filter by source directory
      if (installation.sourceDirectoryPath != null &&
          installation.sourceDirectoryPath!.isNotEmpty) {
        final sourceDir = installation.sourceDirectoryPath!;

        // Check if file is within the source directory
        if (!processedPath.startsWith('$sourceDir/') &&
            processedPath != sourceDir) {
          continue;
        }

        // Remove the source directory prefix for installation
        if (processedPath.startsWith('$sourceDir/')) {
          processedPath = processedPath.substring(sourceDir.length + 1);
        } else if (processedPath == sourceDir) {
          continue; // Skip the directory itself
        }
      }

      // Apply extract pattern filter to the original file name for compatibility
      if (extractPattern.hasMatch(originalPath) ||
          extractPattern.hasMatch(processedPath)) {
        debugPrint('Including file: $originalPath -> $processedPath');
        extractedFiles.add(MapEntry(processedPath, file.content as List<int>));
      }
    }

    debugPrint('Extracted ${extractedFiles.length} files for ${plugin.name}');

    if (extractedFiles.isEmpty) {
      throw GalleryException(
          'No plugin files found in archive matching pattern: ${installation.extractPattern ?? r'.*\.(lua|3pot|o)$'}');
    }

    return extractedFiles;
  }

  /// Install extracted files using Disting upload functionality
  Future<void> _installFilesViaDisting(
    List<MapEntry<String, List<int>>> files,
    GalleryPlugin plugin,
    Function(String fileName, Uint8List fileData,
            {Function(double)? onProgress})
        distingInstallPlugin,
    Function(double)? onProgress,
  ) async {
    debugPrint(
        'Installing ${files.length} files for ${plugin.name} via Disting upload');

    int filesProcessed = 0;

    for (final fileEntry in files) {
      final fileName = path.basename(fileEntry.key);
      final fileData = Uint8List.fromList(fileEntry.value);

      debugPrint('Uploading file: $fileName (${fileData.length} bytes)');

      try {
        await distingInstallPlugin(
          fileName,
          fileData,
          onProgress: (fileProgress) {
            // Calculate overall progress
            final overallProgress =
                (filesProcessed + fileProgress) / files.length;
            onProgress?.call(overallProgress);
          },
        );

        filesProcessed++;
        debugPrint('Successfully uploaded: $fileName');

        // Update overall progress after file completion
        onProgress?.call(filesProcessed / files.length);
      } catch (e) {
        throw GalleryException('Failed to upload ${fileName}: $e');
      }
    }

    debugPrint(
        'Successfully uploaded ${files.length} files for ${plugin.name}');
  }

  /// Update a queued plugin's status
  void _updateQueuedPlugin(
    String pluginId, {
    QueuedPluginStatus? status,
    String? errorMessage,
    double? progress,
  }) {
    final index = _installQueue.indexWhere((q) => q.plugin.id == pluginId);
    if (index >= 0) {
      _installQueue[index] = _installQueue[index].copyWith(
        status: status ?? _installQueue[index].status,
        errorMessage: errorMessage,
        progress: progress,
      );
      _notifyQueueChanged();
    }
  }

  /// Notify listeners of queue changes
  void _notifyQueueChanged() {
    _queueController.add(List.unmodifiable(_installQueue));
  }

  /// Invalidate cached gallery data
  void _invalidateCache() {
    _cachedGallery = null;
    _lastFetch = null;
  }

  /// Dispose of resources
  void dispose() {
    _queueController.close();
  }

  /// Get the installation path for a plugin based on its configuration
  String _getInstallationPath(GalleryPlugin plugin) {
    final installation = plugin.installation;
    String basePath = 'programs/${installation.targetPath}';

    if (installation.subdirectory != null &&
        installation.subdirectory!.isNotEmpty) {
      basePath = '$basePath/${installation.subdirectory}';
    }

    return basePath;
  }
}

/// Exception thrown by gallery operations
class GalleryException implements Exception {
  final String message;

  const GalleryException(this.message);

  @override
  String toString() => 'GalleryException: $message';
}
