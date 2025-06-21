import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:nt_helper/db/database.dart';
import 'package:nt_helper/db/tables.dart';
import 'package:nt_helper/models/marketplace_models.dart';

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
          String type) =>
      (select(pluginInstallations)..where((tbl) => tbl.pluginType.equals(type)))
          .get();

  /// Get installed plugins by status
  Future<List<PluginInstallationEntry>> getInstalledPluginsByStatus(
          String status) =>
      (select(pluginInstallations)
            ..where((tbl) => tbl.installationStatus.equals(status)))
          .get();

  /// Get a specific installed plugin by plugin ID and version
  Future<PluginInstallationEntry?> getInstalledPlugin(
          String pluginId, String version) =>
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
      String pluginId) async {
    final versions = await getPluginVersions(pluginId);
    return versions
        .where((plugin) => plugin.installationStatus == 'completed')
        .firstOrNull;
  }

  /// Record a successful plugin installation
  Future<int> recordPluginInstallation({
    required MarketplacePlugin plugin,
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

    return into(pluginInstallations).insert(
      companion,
      mode: InsertMode.insertOrReplace,
    );
  }

  /// Record a failed plugin installation
  Future<int> recordPluginInstallationFailure({
    required MarketplacePlugin plugin,
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

    return into(pluginInstallations).insert(
      companion,
      mode: InsertMode.insertOrReplace,
    );
  }

  /// Update installation status
  Future<bool> updateInstallationStatus(
      int installationId, String newStatus) async {
    final update = this.update(pluginInstallations)
      ..where((tbl) => tbl.id.equals(installationId));

    final rowsAffected = await update.write(
      PluginInstallationsCompanion(
        installationStatus: Value(newStatus),
      ),
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
  Future<int> removeAllPluginVersions(String pluginId) =>
      (delete(pluginInstallations)
            ..where((tbl) => tbl.pluginId.equals(pluginId)))
          .go();

  /// Get installation statistics
  Future<Map<String, int>> getInstallationStats() async {
    final total = await (selectOnly(pluginInstallations)
          ..addColumns([pluginInstallations.id.count()]))
        .getSingle();

    final completed = await (selectOnly(pluginInstallations)
          ..addColumns([pluginInstallations.id.count()])
          ..where(pluginInstallations.installationStatus.equals('completed')))
        .getSingle();

    final failed = await (selectOnly(pluginInstallations)
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
}
