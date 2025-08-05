// lib/services/plugin_update_checker.dart
import 'dart:async';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:nt_helper/db/database.dart';
import 'package:nt_helper/db/daos/plugin_installations_dao.dart';
import 'package:nt_helper/models/gallery_models.dart';
import 'package:nt_helper/services/gallery_service.dart';
import 'package:nt_helper/services/version_comparison_service.dart';

/// Service for checking plugin updates and managing version tracking
class PluginUpdateChecker {
  final AppDatabase _database;
  final GalleryService _galleryService;
  final Duration _cacheExpiryDuration;
  final int _maxConcurrentChecks;

  DateTime? _lastBatchCheck;
  bool _isCheckingUpdates = false;

  PluginUpdateChecker({
    required AppDatabase database,
    required GalleryService galleryService,
    Duration? cacheExpiryDuration,
    int maxConcurrentChecks = 5,
  })  : _database = database,
        _galleryService = galleryService,
        _cacheExpiryDuration = cacheExpiryDuration ?? const Duration(hours: 1),
        _maxConcurrentChecks = maxConcurrentChecks;

  /// Check for updates for all installed plugins
  Future<UpdateCheckResult> checkAllPluginUpdates({
    bool forceCheck = false,
  }) async {
    if (_isCheckingUpdates && !forceCheck) {
      debugPrint('Plugin update check already in progress, skipping');
      return UpdateCheckResult.inProgress();
    }

    _isCheckingUpdates = true;
    debugPrint('Starting batch plugin update check...');

    try {
      final startTime = DateTime.now();

      // Get plugins that need checking
      final pluginsToCheck = forceCheck
          ? await _database.pluginInstallationsDao.getAllInstalledPlugins()
          : await _database.pluginInstallationsDao
              .getPluginsNeedingUpdateCheck();

      if (pluginsToCheck.isEmpty) {
        debugPrint('No plugins need update checking');
        return UpdateCheckResult.success(
          checkedCount: 0,
          updatesFound: 0,
          errors: const [],
          duration: DateTime.now().difference(startTime),
        );
      }

      debugPrint('Checking ${pluginsToCheck.length} plugins for updates');

      // Get current gallery data
      final galleryPlugins = await _fetchGalleryPlugins();
      if (galleryPlugins.isEmpty) {
        debugPrint('No gallery plugins available, cannot check for updates');
        return UpdateCheckResult.error('Gallery data not available');
      }

      // Process plugins in batches to avoid overwhelming the system
      final results = await _procesPluginsInBatches(
        pluginsToCheck,
        galleryPlugins,
      );

      _lastBatchCheck = DateTime.now();

      final summary = _summarizeResults(results, startTime);
      debugPrint(
          'Plugin update check completed: ${summary.checkedCount} checked, '
          '${summary.updatesFound} updates found, ${summary.errors.length} errors');

      return summary;
    } catch (e) {
      debugPrint('Error during plugin update check: $e');
      return UpdateCheckResult.error(e.toString());
    } finally {
      _isCheckingUpdates = false;
    }
  }

  /// Check for updates for a specific plugin
  Future<PluginUpdateResult> checkPluginUpdate(String pluginId) async {
    try {
      debugPrint('Checking updates for plugin: $pluginId');

      // Get installed plugin info
      final installedVersions =
          await _database.pluginInstallationsDao.getPluginVersions(pluginId);

      if (installedVersions.isEmpty) {
        return PluginUpdateResult.notInstalled(pluginId);
      }

      // Get the latest successfully installed version
      final latestInstalled = installedVersions
          .where((p) => p.installationStatus == 'completed')
          .firstOrNull;

      if (latestInstalled == null) {
        return PluginUpdateResult.notInstalled(pluginId);
      }

      // Get gallery data for this plugin
      final galleryPlugins = await _fetchGalleryPlugins();
      final galleryPlugin =
          galleryPlugins.where((p) => p.id == pluginId).firstOrNull;

      if (galleryPlugin == null) {
        debugPrint('Plugin $pluginId not found in gallery');
        return PluginUpdateResult.notInGallery(pluginId);
      }

      // Compare versions
      final updateResult = await _checkSinglePluginUpdate(
        latestInstalled,
        galleryPlugin,
      );

      return updateResult;
    } catch (e) {
      debugPrint('Error checking plugin update for $pluginId: $e');
      return PluginUpdateResult.error(pluginId, e.toString());
    }
  }

  /// Get current update status for all installed plugins
  Future<Map<String, PluginUpdateInfo>> getUpdateStatus() async {
    return await _database.pluginInstallationsDao.getPluginUpdateStatus();
  }

  /// Get plugins that have updates available
  Future<List<PluginInstallationEntry>> getPluginsWithUpdates() async {
    return await _database.pluginInstallationsDao.getPluginsWithUpdates();
  }

  /// Force refresh all plugin update information
  Future<UpdateCheckResult> forceRefreshAll() async {
    await _database.pluginInstallationsDao.clearAllUpdateFlags();
    return await checkAllPluginUpdates(forceCheck: true);
  }

  /// Check if batch update check is needed
  bool get needsBatchCheck {
    if (_lastBatchCheck == null) return true;
    return DateTime.now().difference(_lastBatchCheck!) > _cacheExpiryDuration;
  }

  /// Get time since last batch check
  Duration? get timeSinceLastCheck {
    return _lastBatchCheck != null
        ? DateTime.now().difference(_lastBatchCheck!)
        : null;
  }

  // Private methods

  Future<List<GalleryPlugin>> _fetchGalleryPlugins() async {
    try {
      final galleryData = await _galleryService.getGalleryData();
      return galleryData?.plugins ?? [];
    } catch (e) {
      debugPrint('Error fetching gallery data: $e');
      return [];
    }
  }

  Future<List<PluginUpdateResult>> _procesPluginsInBatches(
    List<PluginInstallationEntry> pluginsToCheck,
    List<GalleryPlugin> galleryPlugins,
  ) async {
    final results = <PluginUpdateResult>[];

    // Create a map for faster lookup
    final galleryMap = <String, GalleryPlugin>{
      for (final plugin in galleryPlugins) plugin.id: plugin,
    };

    // Process in batches to avoid overwhelming the system
    for (int i = 0; i < pluginsToCheck.length; i += _maxConcurrentChecks) {
      final batchEnd =
          (i + _maxConcurrentChecks).clamp(0, pluginsToCheck.length);
      final batch = pluginsToCheck.sublist(i, batchEnd);

      debugPrint(
          'Processing batch ${(i ~/ _maxConcurrentChecks) + 1}: ${batch.length} plugins');

      final batchResults = await Future.wait(
        batch.map((installedPlugin) async {
          final galleryPlugin = galleryMap[installedPlugin.pluginId];
          if (galleryPlugin == null) {
            return PluginUpdateResult.notInGallery(installedPlugin.pluginId);
          }

          return await _checkSinglePluginUpdate(installedPlugin, galleryPlugin);
        }),
      );

      results.addAll(batchResults);

      // Small delay between batches to be respectful
      if (i + _maxConcurrentChecks < pluginsToCheck.length) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
    }

    return results;
  }

  Future<PluginUpdateResult> _checkSinglePluginUpdate(
    PluginInstallationEntry installedPlugin,
    GalleryPlugin galleryPlugin,
  ) async {
    try {
      final installedVersion = installedPlugin.pluginVersion;
      final availableVersion = VersionComparisonService.getBestAvailableVersion(
          galleryPlugin.releases);

      final hasUpdate = VersionComparisonService.hasUpdate(
          installedVersion, availableVersion);

      // Update database with version info
      await _database.pluginInstallationsDao.updatePluginVersionInfo(
        pluginId: installedPlugin.pluginId,
        installedVersion: installedVersion,
        availableVersion: availableVersion,
        updateAvailable: hasUpdate,
      );

      return PluginUpdateResult.success(
        pluginId: installedPlugin.pluginId,
        pluginName: installedPlugin.pluginName,
        installedVersion: installedVersion,
        availableVersion: availableVersion,
        hasUpdate: hasUpdate,
        galleryPlugin: galleryPlugin,
      );
    } catch (e) {
      debugPrint('Error checking update for ${installedPlugin.pluginId}: $e');
      return PluginUpdateResult.error(installedPlugin.pluginId, e.toString());
    }
  }

  UpdateCheckResult _summarizeResults(
    List<PluginUpdateResult> results,
    DateTime startTime,
  ) {
    final errors =
        results.where((r) => r.hasError).map((r) => r.error!).toList();

    final updatesFound = results.where((r) => r.hasUpdate == true).length;

    return UpdateCheckResult.success(
      checkedCount: results.length,
      updatesFound: updatesFound,
      errors: errors,
      duration: DateTime.now().difference(startTime),
    );
  }
}

/// Result of checking updates for all plugins
class UpdateCheckResult {
  final bool success;
  final int checkedCount;
  final int updatesFound;
  final List<String> errors;
  final Duration duration;
  final String? errorMessage;
  final bool inProgress;

  const UpdateCheckResult._({
    required this.success,
    required this.checkedCount,
    required this.updatesFound,
    required this.errors,
    required this.duration,
    this.errorMessage,
    this.inProgress = false,
  });

  factory UpdateCheckResult.success({
    required int checkedCount,
    required int updatesFound,
    required List<String> errors,
    required Duration duration,
  }) =>
      UpdateCheckResult._(
        success: true,
        checkedCount: checkedCount,
        updatesFound: updatesFound,
        errors: errors,
        duration: duration,
      );

  factory UpdateCheckResult.error(String message) => UpdateCheckResult._(
        success: false,
        checkedCount: 0,
        updatesFound: 0,
        errors: const [],
        duration: Duration.zero,
        errorMessage: message,
      );

  factory UpdateCheckResult.inProgress() => UpdateCheckResult._(
        success: false,
        checkedCount: 0,
        updatesFound: 0,
        errors: const [],
        duration: Duration.zero,
        inProgress: true,
      );

  bool get hasErrors => errors.isNotEmpty;
  bool get hasUpdates => updatesFound > 0;

  @override
  String toString() => success
      ? 'UpdateCheckResult(checked: $checkedCount, updates: $updatesFound, errors: ${errors.length}, duration: ${duration.inMilliseconds}ms)'
      : 'UpdateCheckResult(error: $errorMessage)';
}

/// Result of checking updates for a single plugin
class PluginUpdateResult {
  final String pluginId;
  final String? pluginName;
  final String? installedVersion;
  final String? availableVersion;
  final bool? hasUpdate;
  final String? error;
  final GalleryPlugin? galleryPlugin;
  final PluginUpdateResultType type;

  const PluginUpdateResult._({
    required this.pluginId,
    this.pluginName,
    this.installedVersion,
    this.availableVersion,
    this.hasUpdate,
    this.error,
    this.galleryPlugin,
    required this.type,
  });

  factory PluginUpdateResult.success({
    required String pluginId,
    required String pluginName,
    required String installedVersion,
    required String availableVersion,
    required bool hasUpdate,
    required GalleryPlugin galleryPlugin,
  }) =>
      PluginUpdateResult._(
        pluginId: pluginId,
        pluginName: pluginName,
        installedVersion: installedVersion,
        availableVersion: availableVersion,
        hasUpdate: hasUpdate,
        galleryPlugin: galleryPlugin,
        type: PluginUpdateResultType.success,
      );

  factory PluginUpdateResult.notInstalled(String pluginId) =>
      PluginUpdateResult._(
        pluginId: pluginId,
        type: PluginUpdateResultType.notInstalled,
      );

  factory PluginUpdateResult.notInGallery(String pluginId) =>
      PluginUpdateResult._(
        pluginId: pluginId,
        type: PluginUpdateResultType.notInGallery,
      );

  factory PluginUpdateResult.error(String pluginId, String error) =>
      PluginUpdateResult._(
        pluginId: pluginId,
        error: error,
        type: PluginUpdateResultType.error,
      );

  bool get isSuccess => type == PluginUpdateResultType.success;
  bool get hasError => type == PluginUpdateResultType.error;
  bool get isNotInstalled => type == PluginUpdateResultType.notInstalled;
  bool get isNotInGallery => type == PluginUpdateResultType.notInGallery;

  @override
  String toString() {
    switch (type) {
      case PluginUpdateResultType.success:
        return 'PluginUpdateResult($pluginId: $installedVersion -> $availableVersion, update: $hasUpdate)';
      case PluginUpdateResultType.error:
        return 'PluginUpdateResult($pluginId: error - $error)';
      case PluginUpdateResultType.notInstalled:
        return 'PluginUpdateResult($pluginId: not installed)';
      case PluginUpdateResultType.notInGallery:
        return 'PluginUpdateResult($pluginId: not in gallery)';
    }
  }
}

enum PluginUpdateResultType {
  success,
  error,
  notInstalled,
  notInGallery,
}
