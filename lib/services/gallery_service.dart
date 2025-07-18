import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:nt_helper/models/gallery_models.dart';
import 'package:nt_helper/services/settings_service.dart';
import 'package:nt_helper/services/plugin_metadata_extractor.dart';
import 'package:archive/archive.dart';
import 'package:path/path.dart' as path;

/// Service for managing the plugin gallery
class GalleryService {
  final SettingsService _settingsService;
  Gallery? _cachedGallery;
  DateTime? _lastFetch;
  final Duration _cacheTimeout = const Duration(hours: 1);

  final List<QueuedPlugin> _installQueue = [];
  final StreamController<List<QueuedPlugin>> _queueController =
      StreamController<List<QueuedPlugin>>.broadcast();

  /// Constructor with optional database for installation tracking
  GalleryService({
    required SettingsService settingsService,
  }) : _settingsService = settingsService;

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

        // Log basic gallery information
        debugPrint('Gallery parsed successfully:');
        debugPrint('  Version: ${jsonData['version']}');
        debugPrint('  Plugins: ${(jsonData['plugins'] as List?)?.length ?? 0}');
        debugPrint(
            '  Categories: ${(jsonData['categories'] as List?)?.length ?? 0}');

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

  /// Add plugin to install queue with metadata extraction
  Future<void> addToQueue(GalleryPlugin plugin,
      {String version = 'latest'}) async {
    // Check if already in queue
    final existingIndex =
        _installQueue.indexWhere((q) => q.plugin.id == plugin.id);

    QueuedPlugin queuedPlugin;

    if (existingIndex >= 0) {
      // Update existing entry
      queuedPlugin = _installQueue[existingIndex].copyWith(
        selectedVersion: version,
        status: QueuedPluginStatus.queued,
        errorMessage: null,
        progress: null,
      );
      _installQueue[existingIndex] = queuedPlugin;
    } else {
      // Add new entry
      final bool isCollection =
          await isActualCollection(plugin, downloadPluginArchive);
      queuedPlugin = QueuedPlugin(
        plugin: plugin,
        selectedVersion: version,
        isCollection: isCollection,
      );
      _installQueue.add(queuedPlugin);
    }

    _notifyQueueChanged();

    // Extract metadata asynchronously to determine if it's a collection
    _extractPluginMetadata(queuedPlugin);
  }

  /// Extract plugin metadata to determine if it's a collection
  Future<void> _extractPluginMetadata(QueuedPlugin queuedPlugin) async {
    try {
      final plugin = queuedPlugin.plugin;
      debugPrint('Extracting metadata for plugin: ${plugin.name}');

      // Skip if already processed or if it's clearly not a collection
      if (queuedPlugin.selectedPlugins.isNotEmpty ||
          !queuedPlugin.isCollection) {
        debugPrint(
            'Plugin ${plugin.name} already processed or not a collection');
        return;
      }

      // Update status to analyzing
      final queueIndex =
          _installQueue.indexWhere((q) => q.plugin.id == plugin.id);
      if (queueIndex >= 0) {
        _installQueue[queueIndex] = _installQueue[queueIndex].copyWith(
          status: QueuedPluginStatus.analyzing,
        );
        _notifyQueueChanged();
      }

      // Download the plugin archive
      final archiveBytes =
          await downloadPluginArchive(plugin, queuedPlugin.selectedVersion);

      // Count installable plugins to determine if it's a collection
      final pluginCount = await PluginMetadataExtractor.countInstallablePlugins(
        archiveBytes,
        plugin,
      );

      debugPrint('Plugin ${plugin.name} has $pluginCount installable files');

      if (pluginCount > 1) {
        // This is a collection - extract the plugin list
        debugPrint('Extracting collection plugins for ${plugin.name}');
        final collectionPlugins =
            await PluginMetadataExtractor.extractPluginsFromArchive(
          archiveBytes,
          plugin,
        );

        // Filter to only include installable plugins (.o, .lua, .3pot files)
        final installablePlugins = collectionPlugins
            .where((p) => const ['o', 'lua', '3pot'].contains(p.fileType))
            .map((p) => p.copyWith(selected: true)) // Default to all selected
            .toList();

        // Update the queued plugin with the collection data
        final queueIndex =
            _installQueue.indexWhere((q) => q.plugin.id == plugin.id);
        if (queueIndex >= 0) {
          _installQueue[queueIndex] = _installQueue[queueIndex].copyWith(
            selectedPlugins: installablePlugins,
            status: QueuedPluginStatus.queued,
          );
          _notifyQueueChanged();
          debugPrint(
              'Updated ${plugin.name} with ${installablePlugins.length} collection plugins (all selected by default)');
        }
      } else {
        debugPrint('Plugin ${plugin.name} is a singular plugin');
        // Reset status back to queued for singular plugins
        final queueIndex =
            _installQueue.indexWhere((q) => q.plugin.id == plugin.id);
        if (queueIndex >= 0) {
          _installQueue[queueIndex] = _installQueue[queueIndex].copyWith(
            status: QueuedPluginStatus.queued,
          );
          _notifyQueueChanged();
        }
      }
    } catch (e) {
      debugPrint(
          'Failed to extract metadata for ${queuedPlugin.plugin.name}: $e');
      // Don't fail the queue operation if metadata extraction fails
      // The plugin will be treated as a singular plugin
    }
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

  /// Update selected plugins for a queued plugin collection
  void updateQueuedPluginSelection(
      String pluginId, List<CollectionPlugin> selectedPlugins) {
    debugPrint(
        '[GalleryService] Updating plugin selection for $pluginId: ${selectedPlugins.where((p) => p.selected).length} of ${selectedPlugins.length} selected');
    final index = _installQueue.indexWhere((q) => q.plugin.id == pluginId);
    if (index >= 0) {
      _installQueue[index] = _installQueue[index].copyWith(
        selectedPlugins: selectedPlugins,
      );
      debugPrint('[GalleryService] Queue updated successfully');
      _notifyQueueChanged();
    } else {
      debugPrint('[GalleryService] Plugin not found in queue: $pluginId');
    }
  }

  /// Download plugin archive for a specific version
  Future<List<int>> downloadPluginArchive(
      GalleryPlugin plugin, String version) async {
    final release = plugin.getVersionTag(version);
    final downloadUrl = await _getDownloadUrl(plugin, release);

    debugPrint('Downloading plugin archive from: $downloadUrl');

    final response = await http.get(Uri.parse(downloadUrl));
    if (response.statusCode != 200) {
      throw GalleryException(
        'Failed to download plugin archive: ${response.statusCode} ${response.reasonPhrase}',
      );
    }

    return response.bodyBytes;
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

        await _installSinglePluginViaDisting(
          queuedPlugin,
          distingInstallPlugin,
          onProgress: onProgress,
          onInstallationDetails: (files, bytes) {
            // Installation details tracked
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
        'Installing ${plugin.name} v$version from ${plugin.repository.owner}/${plugin.repository.name}');

    // Update status to downloading
    _updateQueuedPlugin(plugin.id,
        status: QueuedPluginStatus.downloading, progress: 0.0);

    // Download the release file
    final downloadUrl = await _getDownloadUrl(plugin, version);
    final fileBytes = await _downloadWithProgress(
      downloadUrl,
      (progress) {
        _updateQueuedPlugin(plugin.id,
            progress: progress * 0.6); // 60% for download
        onProgress?.call(queuedPlugin, progress * 0.6);
      },
    );

    // Determine file type from download URL
    final downloadUri = Uri.parse(downloadUrl);
    final fileName = path.basename(downloadUri.path);
    final fileExtension = path.extension(fileName).toLowerCase();

    debugPrint('Downloaded file: $fileName with extension: $fileExtension');

    List<MapEntry<String, List<int>>> filesToInstall;

    if (fileExtension == '.zip') {
      // Update status to extracting for zip files
      _updateQueuedPlugin(plugin.id,
          status: QueuedPluginStatus.extracting, progress: 0.6);

      // Extract the zip archive
      filesToInstall =
          await _extractArchive(fileBytes, plugin, queuedPlugin: queuedPlugin);
    } else if (_isRawPluginFile(fileExtension)) {
      // Handle raw plugin files (.o, .lua, .3pot)
      debugPrint('Processing raw plugin file: $fileName');

      // Create a single file entry for installation
      filesToInstall = [MapEntry(fileName, fileBytes)];
    } else {
      throw GalleryException(
          'Unsupported file type: $fileExtension. Supported types are: .zip, .o, .lua, .3pot');
    }

    // Update status to installing
    _updateQueuedPlugin(plugin.id,
        status: QueuedPluginStatus.installing, progress: 0.8);

    // Install files using Disting upload functionality
    await _installFilesViaDisting(filesToInstall, plugin, distingInstallPlugin,
        (uploadProgress) {
      final totalProgress = 0.8 + (uploadProgress * 0.2); // 20% for upload
      _updateQueuedPlugin(plugin.id, progress: totalProgress);
      onProgress?.call(queuedPlugin, totalProgress);
    });

    // Update progress to complete
    _updateQueuedPlugin(plugin.id, progress: 1.0);

    // Notify installation details
    if (onInstallationDetails != null) {
      final totalBytes = fileBytes.length;
      onInstallationDetails(filesToInstall.length, totalBytes);
    }
  }

  /// Get download URL for a plugin - prioritizes downloadUrl from installation config
  Future<String> _getDownloadUrl(GalleryPlugin plugin, String version) async {
    final repo = plugin.repository;

    debugPrint('Getting download URL for ${plugin.name} v$version');

    // Priority 1: Use direct download URL from installation config if available
    if (plugin.installation.downloadUrl != null &&
        plugin.installation.downloadUrl!.isNotEmpty) {
      debugPrint(
          'Using direct downloadUrl: ${plugin.installation.downloadUrl}');
      return plugin.installation.downloadUrl!;
    }

    // Priority 2: Fall back to GitHub API release asset discovery
    debugPrint(
        'Falling back to GitHub API for ${repo.owner}/${repo.name} v$version');

    // Get release with assets
    final apiUrl =
        'https://api.github.com/repos/${repo.owner}/${repo.name}/releases/tags/$version';

    try {
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {'Accept': 'application/vnd.github.v3+json'},
      );

      if (response.statusCode == 200) {
        final releaseData = json.decode(response.body) as Map<String, dynamic>;
        final assets = releaseData['assets'] as List;

        if (assets.isNotEmpty) {
          // Filter out GitHub's automatic source code assets
          final pluginAssets = assets.where((asset) {
            final name = asset['name'] as String;
            final lowerName = name.toLowerCase();

            // Skip GitHub's automatic source code assets
            if (lowerName == 'source code (zip)' ||
                lowerName == 'source code (tar.gz)' ||
                name == 'Source code (zip)' ||
                name == 'Source code (tar.gz)') {
              return false;
            }

            // Accept plugin assets (.o, .lua, .3pot, .zip but not source.zip)
            return lowerName.endsWith('.o') ||
                lowerName.endsWith('.lua') ||
                lowerName.endsWith('.3pot') ||
                (lowerName.endsWith('.zip') && !lowerName.contains('source'));
          }).toList();

          if (pluginAssets.isNotEmpty) {
            final asset = pluginAssets.first as Map<String, dynamic>;
            final assetUrl = asset['browser_download_url'] as String;
            final assetName = asset['name'] as String;
            debugPrint('Using plugin asset: $assetName');
            return assetUrl;
          } else {
            throw GalleryException(
                'Release has no plugin assets - only source code found');
          }
        } else {
          throw GalleryException('Release has no assets');
        }
      } else {
        throw GalleryException(
            'Release $version not found for ${repo.owner}/${repo.name}');
      }
    } catch (e) {
      if (e is GalleryException) rethrow;
      throw GalleryException(
          'Failed to fetch release $version for ${repo.owner}/${repo.name}: $e');
    }
  }

  /// Download file with progress tracking
  Future<List<int>> _downloadWithProgress(
    String url,
    Function(double) onProgress,
  ) async {
    debugPrint('Downloading from: $url');

    final request = http.Request('GET', Uri.parse(url));
    final response = await http.Client().send(request);

    if (response.statusCode != 200) {
      throw GalleryException(
          'Download failed: HTTP ${response.statusCode} for URL: $url');
    }

    final contentLength = response.contentLength;
    final bytes = <int>[];

    await for (final chunk in response.stream) {
      bytes.addAll(chunk);
      if (contentLength != null && contentLength > 0) {
        final progress = bytes.length / contentLength;
        onProgress(progress);
      }
    }

    debugPrint('Downloaded ${bytes.length} bytes');
    return bytes;
  }

  /// Extract archive and filter relevant files
  Future<List<MapEntry<String, List<int>>>> _extractArchive(
    List<int> archiveBytes,
    GalleryPlugin plugin, {
    QueuedPlugin? queuedPlugin,
  }) async {
    final archive = ZipDecoder().decodeBytes(archiveBytes);
    final extractedFiles = <MapEntry<String, List<int>>>[];
    final installation = plugin.installation;

    debugPrint('Extracting archive for ${plugin.name}');

    // Compile regex pattern for file filtering if extractPattern is provided
    RegExp? extractRegex;
    if (installation.extractPattern != null &&
        installation.extractPattern!.isNotEmpty) {
      try {
        extractRegex = RegExp(installation.extractPattern!);
        debugPrint('Using extract pattern: ${installation.extractPattern}');
      } catch (e) {
        debugPrint(
            'Invalid extract pattern ${installation.extractPattern}: $e');
        // Continue without pattern filtering if regex is invalid
      }
    }

    for (final file in archive) {
      if (!file.isFile) continue;

      String filePath = file.name;
      final originalFilePath = filePath;

      // For directory-based installations, filter by source directory
      if (installation.sourceDirectoryPath != null &&
          installation.sourceDirectoryPath!.isNotEmpty) {
        final sourceDir = installation.sourceDirectoryPath!;

        // Check if file is within the source directory
        if (!filePath.startsWith('$sourceDir/') && filePath != sourceDir) {
          continue;
        }

        // Remove the source directory prefix for installation
        if (filePath.startsWith('$sourceDir/')) {
          filePath = filePath.substring(sourceDir.length + 1);
        } else if (filePath == sourceDir) {
          continue; // Skip the directory itself
        }
      }

      // Skip empty paths
      if (filePath.isEmpty) continue;

      // Apply extract pattern filtering if specified
      if (extractRegex != null) {
        // Check both the processed filePath and original file.name against the pattern
        final fileNameOnly = path.basename(filePath);
        final originalFileNameOnly = path.basename(originalFilePath);

        if (!extractRegex.hasMatch(filePath) &&
            !extractRegex.hasMatch(fileNameOnly) &&
            !extractRegex.hasMatch(originalFilePath) &&
            !extractRegex.hasMatch(originalFileNameOnly)) {
          debugPrint(
              'Skipping file (does not match extract pattern): ${file.name}');
          continue;
        }
      }

      // Check if this file should be included based on plugin selection
      if (queuedPlugin?.hasSelectedPlugins == true) {
        final selectedPaths = queuedPlugin!.selectedPlugins
            .where((p) => p.selected)
            .map((p) => p.relativePath)
            .toSet();

        if (!selectedPaths.contains(filePath)) {
          debugPrint('Skipping file (not selected): ${file.name} -> $filePath');
          continue;
        }
      }

      debugPrint('Including file: ${file.name} -> $filePath');
      extractedFiles.add(MapEntry(filePath, file.content as List<int>));
    }

    debugPrint('Extracted ${extractedFiles.length} files for ${plugin.name}');

    if (extractedFiles.isEmpty) {
      throw GalleryException(
          'No plugin files found in archive for ${plugin.name}. Extract pattern: ${installation.extractPattern ?? "none"}');
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
      final relativePath = fileEntry.key;
      final fileData = Uint8List.fromList(fileEntry.value);
      final fileName = path.basename(relativePath);

      debugPrint('Processing file: $relativePath (${fileData.length} bytes)');

      try {
        // Try to upload with directory structure first (if path contains directories)
        if (relativePath.contains('/') && relativePath != fileName) {
          debugPrint(
              'Attempting upload with directory structure: $relativePath');
          try {
            await distingInstallPlugin(
              relativePath,
              fileData,
              onProgress: (fileProgress) {
                final overallProgress =
                    (filesProcessed + fileProgress) / files.length;
                onProgress?.call(overallProgress);
              },
            );

            filesProcessed++;
            debugPrint('Successfully uploaded with path: $relativePath');
            onProgress?.call(filesProcessed / files.length);
            continue; // Success, move to next file
          } catch (pathError) {
            debugPrint('Upload with path failed: $pathError');
            debugPrint('Falling back to filename only: $fileName');
          }
        }

        // Fallback: upload to plugin root directory with just filename
        await distingInstallPlugin(
          fileName,
          fileData,
          onProgress: (fileProgress) {
            final overallProgress =
                (filesProcessed + fileProgress) / files.length;
            onProgress?.call(overallProgress);
          },
        );

        filesProcessed++;
        debugPrint('Successfully uploaded to root: $fileName');
        onProgress?.call(filesProcessed / files.length);
      } catch (e) {
        throw GalleryException('Failed to upload $fileName: $e');
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

  /// Check if a file extension corresponds to a raw plugin file
  bool _isRawPluginFile(String extension) {
    const rawPluginExtensions = {'.o', '.lua', '.3pot'};
    return rawPluginExtensions.contains(extension);
  }

}

/// Exception thrown by gallery operations
class GalleryException implements Exception {
  final String message;

  const GalleryException(this.message);

  @override
  String toString() => 'GalleryException: $message';
}
