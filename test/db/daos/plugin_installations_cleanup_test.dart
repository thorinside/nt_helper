import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/db/database.dart';

/// Tests for the cleanup logic that removes stale database records
/// when plugin files are deleted from the device.
///
/// These tests verify the behavior of the cleanup pattern used in
/// PluginManagerScreen._cleanupStaleRecords()
void main() {
  late AppDatabase database;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  /// Helper to simulate the cleanup logic from PluginManagerScreen
  Future<void> cleanupStaleRecords(
    Set<String> devicePaths,
    AppDatabase db,
  ) async {
    final dbRecords =
        await db.pluginInstallationsDao.getAllInstalledPlugins();

    for (final record in dbRecords) {
      if (!devicePaths.contains(record.installationPath)) {
        await db.pluginInstallationsDao
            .removeByInstallationPath(record.installationPath);
      }
    }
  }

  group('Plugin cleanup logic', () {
    test('removes stale records when file deleted from device', () async {
      // Setup: Add records for two plugins
      await database.pluginInstallationsDao.recordPluginByPath(
        installationPath: '/programs/lua/exists.lua',
        pluginName: 'exists.lua',
        pluginType: 'lua',
      );
      await database.pluginInstallationsDao.recordPluginByPath(
        installationPath: '/programs/lua/deleted.lua',
        pluginName: 'deleted.lua',
        pluginType: 'lua',
      );

      // Verify both records exist
      var records =
          await database.pluginInstallationsDao.getAllInstalledPlugins();
      expect(records.length, equals(2));

      // Simulate device only has 'exists.lua' (deleted.lua was removed)
      final devicePaths = {'/programs/lua/exists.lua'};
      await cleanupStaleRecords(devicePaths, database);

      // Verify only the existing file's record remains
      records = await database.pluginInstallationsDao.getAllInstalledPlugins();
      expect(records.length, equals(1));
      expect(records[0].installationPath, equals('/programs/lua/exists.lua'));
    });

    test('preserves records for files still on device', () async {
      // Setup: Add three plugins
      await database.pluginInstallationsDao.recordPluginByPath(
        installationPath: '/programs/lua/a.lua',
        pluginName: 'a.lua',
        pluginType: 'lua',
      );
      await database.pluginInstallationsDao.recordPluginByPath(
        installationPath: '/programs/three_pot/b.3pot',
        pluginName: 'b.3pot',
        pluginType: 'threepot',
      );
      await database.pluginInstallationsDao.recordPluginByPath(
        installationPath: '/programs/plug-ins/c.o',
        pluginName: 'c.o',
        pluginType: 'cpp',
      );

      // Device has all files
      final devicePaths = {
        '/programs/lua/a.lua',
        '/programs/three_pot/b.3pot',
        '/programs/plug-ins/c.o',
      };
      await cleanupStaleRecords(devicePaths, database);

      // All records should be preserved
      final records =
          await database.pluginInstallationsDao.getAllInstalledPlugins();
      expect(records.length, equals(3));
    });

    test('removes all records when device has no plugins', () async {
      // Setup: Add plugins
      await database.pluginInstallationsDao.recordPluginByPath(
        installationPath: '/programs/lua/a.lua',
        pluginName: 'a.lua',
        pluginType: 'lua',
      );
      await database.pluginInstallationsDao.recordPluginByPath(
        installationPath: '/programs/lua/b.lua',
        pluginName: 'b.lua',
        pluginType: 'lua',
      );

      // Device has no plugins
      final devicePaths = <String>{};
      await cleanupStaleRecords(devicePaths, database);

      // All records should be removed
      final records =
          await database.pluginInstallationsDao.getAllInstalledPlugins();
      expect(records, isEmpty);
    });

    test('handles empty database with plugins on device', () async {
      // Database is empty, device has plugins
      final devicePaths = {
        '/programs/lua/plugin.lua',
        '/programs/plug-ins/synth.o',
      };

      // Should not throw
      await cleanupStaleRecords(devicePaths, database);

      // Database should still be empty (no records to clean up)
      final records =
          await database.pluginInstallationsDao.getAllInstalledPlugins();
      expect(records, isEmpty);
    });

    test('removeByInstallationPath removes correct record', () async {
      // Add plugins
      await database.pluginInstallationsDao.recordPluginByPath(
        installationPath: '/programs/lua/keep.lua',
        pluginName: 'keep.lua',
        pluginType: 'lua',
      );
      await database.pluginInstallationsDao.recordPluginByPath(
        installationPath: '/programs/lua/remove.lua',
        pluginName: 'remove.lua',
        pluginType: 'lua',
      );

      // Remove specific one
      await database.pluginInstallationsDao
          .removeByInstallationPath('/programs/lua/remove.lua');

      // Only keep.lua should remain
      final records =
          await database.pluginInstallationsDao.getAllInstalledPlugins();
      expect(records.length, equals(1));
      expect(records[0].installationPath, equals('/programs/lua/keep.lua'));
    });

    test('removeByInstallationPath handles missing record gracefully', () async {
      // Add a plugin
      await database.pluginInstallationsDao.recordPluginByPath(
        installationPath: '/programs/lua/exists.lua',
        pluginName: 'exists.lua',
        pluginType: 'lua',
      );

      // Try to remove non-existent path - should not throw
      final deleted = await database.pluginInstallationsDao
          .removeByInstallationPath('/programs/lua/nonexistent.lua');

      expect(deleted, equals(0));

      // Original record should still exist
      final records =
          await database.pluginInstallationsDao.getAllInstalledPlugins();
      expect(records.length, equals(1));
    });
  });
}
