import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:nt_helper/db/database.dart';
import 'package:nt_helper/db/tables.dart';
import 'package:nt_helper/models/gallery_models.dart';

part 'plugin_installations_dao.g.dart';

@DriftAccessor(tables: [PluginInstallations])
class PluginInstallationsDao extends DatabaseAccessor<AppDatabase>
    with _$PluginInstallationsDaoMixin {
  PluginInstallationsDao(super.db);

  /// Get all installed plugins
  Future<List<PluginInstallationEntry>> getAllInstalledPlugins() =>
      select(pluginInstallations).get();

  /// Get installed plugins by type
  Future<List<PluginInstallationEntry>> getInstalledPluginsByType(
    String type,
  ) => (select(
    pluginInstallations,
  )..where((tbl) => tbl.pluginType.equals(type))).get();

  /// Get installed plugins by status
  Future<List<PluginInstallationEntry>> getInstalledPluginsByStatus(
    String status,
  ) => (select(
    pluginInstallations,
  )..where((tbl) => tbl.installationStatus.equals(status))).get();

  /// Get a specific installed plugin by plugin ID and version
  Future<PluginInstallationEntry?> getInstalledPlugin(
    String pluginId,
    String version,
  ) =>
      (select(pluginInstallations)
            ..where((tbl) => tbl.pluginId.equals(pluginId))
            ..where((tbl) => tbl.pluginVersion.equals(version)))
          .getSingleOrNull();

  /// Get all versions of a specific plugin
  Future<List<PluginInstallationEntry>> getPluginVersions(String pluginId) =>
      (select(pluginInstallations)
            ..where((tbl) => tbl.pluginId.equals(pluginId))
            ..orderBy([(tbl) => OrderingTerm.desc(tbl.installedAt)]))
          .get();

  /// Check if a specific plugin version is installed
  Future<bool> isPluginInstalled(String pluginId, String version) async {
    final result = await getInstalledPlugin(pluginId, version);
    return result != null && result.installationStatus == 'completed';
  }

  /// Check if any version of a plugin is installed
  Future<bool> isAnyVersionInstalled(String pluginId) async {
    final versions = await getPluginVersions(pluginId);
    return versions.any((plugin) => plugin.installationStatus == 'completed');
  }

  /// Get the latest installed version of a plugin
  Future<PluginInstallationEntry?> getLatestInstalledVersion(
    String pluginId,
  ) async {
    final versions = await getPluginVersions(pluginId);
    return versions
        .where((plugin) => plugin.installationStatus == 'completed')
        .firstOrNull;
  }

  /// Record a successful plugin installation
  Future<int> recordPluginInstallation({
    required GalleryPlugin plugin,
    required String installedVersion,
    required String installationPath,
    int? fileCount,
    int? totalBytes,
    String? installationNotes,
  }) async {
    final marketplaceMetadata = jsonEncode(plugin.toJson());

    final companion = PluginInstallationsCompanion.insert(
      pluginId: plugin.id,
      pluginName: plugin.name,
      pluginVersion: installedVersion,
      pluginType: plugin.type.name,
      pluginAuthor: plugin.author,
      installationPath: installationPath,
      installationStatus: const Value('completed'),
      marketplaceMetadata: Value(marketplaceMetadata),
      repositoryUrl: Value(plugin.repository.url),
      repositoryOwner: Value(plugin.repository.owner),
      repositoryName: Value(plugin.repository.name),
      fileCount: Value(fileCount),
      totalBytes: Value(totalBytes),
      installationNotes: Value(installationNotes),
    );

    return into(
      pluginInstallations,
    ).insert(companion, mode: InsertMode.insertOrReplace);
  }

  /// Record a plugin installation by artifact path
  /// Works for all plugin types (gallery and local installs)
  /// Uses installation path as the primary identifier for upsert
  Future<int> recordPluginByPath({
    required String installationPath,
    required String pluginName,
    required String pluginType,
    int? totalBytes,
    String? pluginId,
    String? pluginVersion,
  }) async {
    // Use path directly for local installs (not hashCode which is unstable across sessions).
    // For gallery installs, pluginId is provided by the caller.
    final companion = PluginInstallationsCompanion.insert(
      pluginId: pluginId ?? 'local:$installationPath',
      pluginName: pluginName,
      pluginVersion: pluginVersion ?? 'unknown',
      pluginType: pluginType,
      // Gallery installs get author from GalleryPlugin; local installs are marked as such
      pluginAuthor: pluginId != null ? '' : 'Local Install',
      installationPath: installationPath,
      installationStatus: const Value('completed'),
      totalBytes: Value(totalBytes),
    );

    // Wrap delete+insert in a transaction for atomicity.
    // We can't rely on InsertMode.insertOrReplace because the unique constraint
    // is on (plugin_id, plugin_version), not installation_path. This means a
    // gallery install (with its own plugin_id) wouldn't replace a local install
    // (with a different plugin_id) at the same path.
    return transaction(() async {
      await removeByInstallationPath(installationPath);
      return into(pluginInstallations).insert(companion);
    });
  }

  /// Record a failed plugin installation
  Future<int> recordPluginInstallationFailure({
    required GalleryPlugin plugin,
    required String attemptedVersion,
    required String installationPath,
    required String errorMessage,
    int? fileCount,
    int? totalBytes,
  }) async {
    final marketplaceMetadata = jsonEncode(plugin.toJson());

    final companion = PluginInstallationsCompanion.insert(
      pluginId: plugin.id,
      pluginName: plugin.name,
      pluginVersion: attemptedVersion,
      pluginType: plugin.type.name,
      pluginAuthor: plugin.author,
      installationPath: installationPath,
      installationStatus: const Value('failed'),
      marketplaceMetadata: Value(marketplaceMetadata),
      repositoryUrl: Value(plugin.repository.url),
      repositoryOwner: Value(plugin.repository.owner),
      repositoryName: Value(plugin.repository.name),
      fileCount: Value(fileCount),
      totalBytes: Value(totalBytes),
      errorMessage: Value(errorMessage),
    );

    return into(
      pluginInstallations,
    ).insert(companion, mode: InsertMode.insertOrReplace);
  }

  /// Update installation status
  Future<bool> updateInstallationStatus(
    int installationId,
    String newStatus,
  ) async {
    final update = this.update(pluginInstallations)
      ..where((tbl) => tbl.id.equals(installationId));

    final rowsAffected = await update.write(
      PluginInstallationsCompanion(installationStatus: Value(newStatus)),
    );

    return rowsAffected > 0;
  }

  /// Remove a plugin installation record
  Future<int> removePluginInstallation(String pluginId, String version) =>
      (delete(pluginInstallations)
            ..where((tbl) => tbl.pluginId.equals(pluginId))
            ..where((tbl) => tbl.pluginVersion.equals(version)))
          .go();

  /// Remove all installation records for a plugin
  Future<int> removeAllPluginVersions(String pluginId) => (delete(
    pluginInstallations,
  )..where((tbl) => tbl.pluginId.equals(pluginId))).go();

  /// Remove plugin installation records by installation path
  /// This is useful when deleting plugins from the device without knowing their plugin ID
  Future<int> removeByInstallationPath(String installationPath) => (delete(
    pluginInstallations,
  )..where((tbl) => tbl.installationPath.equals(installationPath))).go();

  /// Get installation statistics
  Future<Map<String, int>> getInstallationStats() async {
    final total = await (selectOnly(
      pluginInstallations,
    )..addColumns([pluginInstallations.id.count()])).getSingle();

    final completed =
        await (selectOnly(pluginInstallations)
              ..addColumns([pluginInstallations.id.count()])
              ..where(
                pluginInstallations.installationStatus.equals('completed'),
              ))
            .getSingle();

    final failed =
        await (selectOnly(pluginInstallations)
              ..addColumns([pluginInstallations.id.count()])
              ..where(pluginInstallations.installationStatus.equals('failed')))
            .getSingle();

    return {
      'total': total.read(pluginInstallations.id.count()) ?? 0,
      'completed': completed.read(pluginInstallations.id.count()) ?? 0,
      'failed': failed.read(pluginInstallations.id.count()) ?? 0,
    };
  }

  /// Get recently installed plugins (last 30 days)
  Future<List<PluginInstallationEntry>> getRecentlyInstalledPlugins() {
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));

    return (select(pluginInstallations)
          ..where((tbl) => tbl.installedAt.isBiggerThanValue(thirtyDaysAgo))
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.installedAt)]))
        .get();
  }

  // --- Version Tracking Methods ---

  /// Update version tracking information for a plugin
  Future<bool> updatePluginVersionInfo({
    required String pluginId,
    required String installedVersion,
    required String availableVersion,
    required bool updateAvailable,
  }) async {
    final update = this.update(pluginInstallations)
      ..where((tbl) => tbl.pluginId.equals(pluginId))
      ..where((tbl) => tbl.pluginVersion.equals(installedVersion));

    final rowsAffected = await update.write(
      PluginInstallationsCompanion(
        availableVersion: Value(availableVersion),
        updateAvailable: Value(updateAvailable.toString()),
        lastChecked: Value(DateTime.now()),
      ),
    );

    return rowsAffected > 0;
  }

  /// Get plugins that have updates available
  Future<List<PluginInstallationEntry>> getPluginsWithUpdates() =>
      (select(pluginInstallations)
            ..where((tbl) => tbl.updateAvailable.equals('true'))
            ..where((tbl) => tbl.installationStatus.equals('completed'))
            ..orderBy([(tbl) => OrderingTerm.desc(tbl.lastChecked)]))
          .get();

  /// Get plugins that need update checking (never checked or > 1 hour old)
  Future<List<PluginInstallationEntry>> getPluginsNeedingUpdateCheck() {
    final oneHourAgo = DateTime.now().subtract(const Duration(hours: 1));

    return (select(pluginInstallations)
          ..where((tbl) => tbl.installationStatus.equals('completed'))
          ..where(
            (tbl) =>
                tbl.lastChecked.isNull() |
                tbl.lastChecked.isSmallerThanValue(oneHourAgo),
          )
          ..orderBy([(tbl) => OrderingTerm.asc(tbl.lastChecked)]))
        .get();
  }

  /// Get update status for all installed plugins
  Future<Map<String, PluginUpdateInfo>> getPluginUpdateStatus() async {
    final plugins = await getAllInstalledPlugins();
    final updateInfo = <String, PluginUpdateInfo>{};

    for (final plugin in plugins) {
      if (plugin.installationStatus == 'completed') {
        updateInfo[plugin.pluginId] = PluginUpdateInfo(
          pluginId: plugin.pluginId,
          pluginName: plugin.pluginName,
          installedVersion: plugin.pluginVersion,
          availableVersion: plugin.availableVersion,
          updateAvailable: plugin.updateAvailable == 'true',
          lastChecked: plugin.lastChecked,
        );
      }
    }

    return updateInfo;
  }

  /// Clear update flags for all plugins (useful for testing or cache invalidation)
  Future<int> clearAllUpdateFlags() async {
    final update = this.update(pluginInstallations);

    return await update.write(
      PluginInstallationsCompanion(
        updateAvailable: const Value('false'),
        availableVersion: const Value.absent(),
        lastChecked: const Value.absent(),
      ),
    );
  }

  /// Remove installation records that have channel names ('latest', 'stable', 'beta')
  /// instead of actual version tags. These are artifacts from a bug where the
  /// resolved version wasn't being recorded.
  Future<int> cleanupChannelVersionRecords() async {
    const channelNames = ['latest', 'stable', 'beta'];

    return (delete(pluginInstallations)..where(
      (tbl) => tbl.pluginVersion.isIn(channelNames),
    )).go();
  }
}

/// Data class for plugin update information
class PluginUpdateInfo {
  final String pluginId;
  final String pluginName;
  final String installedVersion;
  final String? availableVersion;
  final bool updateAvailable;
  final DateTime? lastChecked;

  const PluginUpdateInfo({
    required this.pluginId,
    required this.pluginName,
    required this.installedVersion,
    this.availableVersion,
    required this.updateAvailable,
    this.lastChecked,
  });

  bool get hasUpdate => updateAvailable && availableVersion != null;

  bool get needsCheck =>
      lastChecked == null ||
      DateTime.now().difference(lastChecked!).inHours >= 1;

  @override
  String toString() =>
      'PluginUpdateInfo($pluginId: $installedVersion -> $availableVersion, update: $updateAvailable)';
}
