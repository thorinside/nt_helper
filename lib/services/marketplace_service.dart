import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:nt_helper/models/marketplace_models.dart';
import 'package:archive/archive.dart';
import 'package:path/path.dart' as path;

/// Service for managing the plugin marketplace
class MarketplaceService {
  static const String _defaultMarketplaceUrl =
      'https://drive.google.com/uc?export=download&id=1UhL3zdGGBG0eJmUGa_758v7XGiG1u7zF';

  String _marketplaceUrl = _defaultMarketplaceUrl;
  Marketplace? _cachedMarketplace;
  DateTime? _lastFetch;
  final Duration _cacheTimeout = const Duration(hours: 1);

  final List<QueuedPlugin> _installQueue = [];
  final StreamController<List<QueuedPlugin>> _queueController =
      StreamController<List<QueuedPlugin>>.broadcast();

  /// Stream of install queue updates
  Stream<List<QueuedPlugin>> get queueStream => _queueController.stream;

  /// Current install queue
  List<QueuedPlugin> get installQueue => List.unmodifiable(_installQueue);

  /// Current marketplace URL
  String get marketplaceUrl => _marketplaceUrl;

  /// Set the marketplace URL
  void setMarketplaceUrl(String url) {
    if (_marketplaceUrl != url) {
      _marketplaceUrl = url;
      _invalidateCache();
    }
  }

  /// Force clear the cache (useful for testing new URLs)
  void clearCache() {
    _invalidateCache();
  }

  /// Fetch marketplace data with caching
  Future<Marketplace> fetchMarketplace({bool forceRefresh = false}) async {
    // Return cached data if valid and not forcing refresh
    if (!forceRefresh &&
        _cachedMarketplace != null &&
        _lastFetch != null &&
        DateTime.now().difference(_lastFetch!) < _cacheTimeout) {
      return _cachedMarketplace!;
    }

    try {
      print('Loading marketplace from: $_marketplaceUrl');

      final response = await http.get(
        Uri.parse(_marketplaceUrl),
        headers: {
          'Accept': 'application/json',
          'User-Agent': 'Disting-NT-Helper/1.0',
          'Cache-Control': 'no-cache',
        },
      ).timeout(const Duration(seconds: 30));

      print('Response status: ${response.statusCode}');
      print('Response headers: ${response.headers}');
      print('Response content-type: ${response.headers['content-type']}');

      if (response.statusCode == 200) {
        print('Response body length: ${response.body.length}');
        print(
            'Response body preview: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}');

        // Check if the response looks like HTML (Google Drive error page)
        if (response.body.trim().startsWith('<')) {
          throw MarketplaceException(
            'Received HTML instead of JSON. This might be a Google Drive access issue or the file is not publicly accessible.',
          );
        }

        final jsonData = json.decode(response.body) as Map<String, dynamic>;
        final marketplace = Marketplace.fromJson(jsonData);

        _cachedMarketplace = marketplace;
        _lastFetch = DateTime.now();

        return marketplace;
      } else {
        throw MarketplaceException(
          'Failed to fetch marketplace: HTTP ${response.statusCode} - ${response.reasonPhrase}',
        );
      }
    } catch (e) {
      print('Error loading marketplace: $e');
      if (e is MarketplaceException) rethrow;
      throw MarketplaceException('Network error: ${e.toString()}');
    }
  }

  /// Search plugins with optional filters
  List<MarketplacePlugin> searchPlugins(
    Marketplace marketplace, {
    String? query,
    String? category,
    MarketplacePluginType? type,
    bool? featured,
    bool? verified,
  }) {
    var plugins = marketplace.plugins;

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
  void addToQueue(MarketplacePlugin plugin, {String version = 'latest'}) {
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
        await _installSinglePluginViaDisting(
          queuedPlugin,
          distingInstallPlugin,
          onProgress: onProgress,
        );

        _updateQueuedPlugin(queuedPlugin.plugin.id,
            status: QueuedPluginStatus.completed);
        onPluginComplete?.call(queuedPlugin);

        // Remove successfully completed plugin from queue
        removeFromQueue(queuedPlugin.plugin.id);
      } catch (e) {
        final errorMessage = e.toString();
        _updateQueuedPlugin(queuedPlugin.plugin.id,
            status: QueuedPluginStatus.failed, errorMessage: errorMessage);
        onPluginError?.call(queuedPlugin, errorMessage);

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
  }) async {
    final plugin = queuedPlugin.plugin;
    final version = plugin.getVersionTag(queuedPlugin.selectedVersion);

    // Update status to downloading
    _updateQueuedPlugin(plugin.id,
        status: QueuedPluginStatus.downloading, progress: 0.0);

    // Download the release archive
    final downloadUrl = await _getDownloadUrl(plugin.repository, version);
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
  }

  /// Get download URL for a GitHub release or commit
  Future<String> _getDownloadUrl(PluginRepository repo, String version) async {
    // Check if version looks like a commit hash (40 hex characters)
    final commitHashPattern = RegExp(r'^[a-f0-9]{40}$');

    if (commitHashPattern.hasMatch(version)) {
      // Direct commit hash - use archive download
      return 'https://github.com/${repo.owner}/${repo.name}/archive/$version.zip';
    }

    // Check if version is "main" or similar branch name
    if (version == 'main' || version == 'master' || version == 'develop') {
      // Use branch archive download
      return 'https://github.com/${repo.owner}/${repo.name}/archive/refs/heads/$version.zip';
    }

    // Try to get release with assets first
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
          // Find the first asset that matches the pattern (usually a .zip file)
          final asset = assets.first as Map<String, dynamic>;
          return asset['browser_download_url'] as String;
        }
        // If release exists but has no assets, fall through to source archive
      }
      // If release doesn't exist (404), fall through to source archive
    } catch (e) {
      // If API call fails, fall through to source archive
      print('Release API failed for $version, trying source archive: $e');
    }

    // Fallback: use source archive for the tag/version
    print(
        'Using source archive for ${repo.owner}/${repo.name} version $version');
    return 'https://github.com/${repo.owner}/${repo.name}/archive/refs/tags/$version.zip';
  }

  /// Download file with progress tracking
  Future<List<int>> _downloadWithProgress(
    String url,
    Function(double) onProgress,
  ) async {
    final request = http.Request('GET', Uri.parse(url));
    final response = await http.Client().send(request);

    if (response.statusCode != 200) {
      throw MarketplaceException(
          'Download failed: HTTP ${response.statusCode}');
    }

    final contentLength = response.contentLength;
    final bytes = <int>[];

    await for (final chunk in response.stream) {
      bytes.addAll(chunk);
      if (contentLength != null && contentLength > 0) {
        onProgress(bytes.length / contentLength);
      }
    }

    return bytes;
  }

  /// Extract archive and filter relevant files
  Future<List<MapEntry<String, List<int>>>> _extractArchive(
    List<int> archiveBytes,
    MarketplacePlugin plugin,
  ) async {
    final archive = ZipDecoder().decodeBytes(archiveBytes);
    final extractedFiles = <MapEntry<String, List<int>>>[];
    final installation = plugin.installation;
    final extractPattern = RegExp(installation.extractPattern);

    print(
        'Extracting archive for ${plugin.name}, looking for pattern: ${installation.extractPattern}');

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
        print('Including file: $originalPath -> $processedPath');
        extractedFiles.add(MapEntry(processedPath, file.content as List<int>));
      }
    }

    print('Extracted ${extractedFiles.length} files for ${plugin.name}');

    if (extractedFiles.isEmpty) {
      throw MarketplaceException(
          'No plugin files found in archive matching pattern: ${installation.extractPattern}');
    }

    return extractedFiles;
  }

  /// Install extracted files using Disting upload functionality
  Future<void> _installFilesViaDisting(
    List<MapEntry<String, List<int>>> files,
    MarketplacePlugin plugin,
    Function(String fileName, Uint8List fileData,
            {Function(double)? onProgress})
        distingInstallPlugin,
    Function(double)? onProgress,
  ) async {
    print(
        'Installing ${files.length} files for ${plugin.name} via Disting upload');

    int filesProcessed = 0;

    for (final fileEntry in files) {
      final fileName = path.basename(fileEntry.key);
      final fileData = Uint8List.fromList(fileEntry.value);

      print('Uploading file: $fileName (${fileData.length} bytes)');

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
        print('Successfully uploaded: $fileName');

        // Update overall progress after file completion
        onProgress?.call(filesProcessed / files.length);
      } catch (e) {
        throw MarketplaceException('Failed to upload ${fileName}: $e');
      }
    }

    print('Successfully uploaded ${files.length} files for ${plugin.name}');
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

  /// Invalidate cached marketplace data
  void _invalidateCache() {
    _cachedMarketplace = null;
    _lastFetch = null;
  }

  /// Dispose of resources
  void dispose() {
    _queueController.close();
  }
}

/// Exception thrown by marketplace operations
class MarketplaceException implements Exception {
  final String message;

  const MarketplaceException(this.message);

  @override
  String toString() => 'MarketplaceException: $message';
}
