import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/db/database.dart';
import 'package:nt_helper/models/gallery_models.dart';
import 'package:nt_helper/services/gallery_service.dart';
import 'package:nt_helper/services/settings_service.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockSettingsService extends Mock implements SettingsService {}

void main() {
  group('GalleryService Installed Plugin Detection', () {
    late GalleryService galleryService;
    late MockSettingsService mockSettingsService;
    late AppDatabase database;

    setUp(() async {
      // Initialize shared preferences for testing
      SharedPreferences.setMockInitialValues({});

      // Create in-memory database for testing
      database = AppDatabase.forTesting(NativeDatabase.memory());

      mockSettingsService = MockSettingsService();

      // Mock the settings service methods
      when(() => mockSettingsService.galleryUrl).thenReturn(
        'https://example.com/gallery.json',
      );
      when(() => mockSettingsService.graphqlEndpoint).thenReturn(
        'https://example.com/graphql',
      );

      galleryService = GalleryService(
        settingsService: mockSettingsService,
        database: database,
      );
    });

    tearDown(() async {
      await database.close();
    });

    GalleryPlugin createTestPlugin({
      required String id,
      required String name,
      String? guid,
    }) {
      return GalleryPlugin(
        id: id,
        name: name,
        description: 'Test plugin',
        type: GalleryPluginType.lua,
        author: 'test-author',
        repository: const PluginRepository(
          owner: 'test-owner',
          name: 'test-repo',
          url: 'https://github.com/test-owner/test-repo',
        ),
        releases: const PluginReleases(latest: 'v1.0.0'),
        installation: const PluginInstallation(targetPath: '/programs/lua'),
        guid: guid,
      );
    }

    Gallery createTestGallery(List<GalleryPlugin> plugins) {
      return Gallery(
        version: '2.0.0',
        lastUpdated: DateTime.now(),
        metadata: const GalleryMetadata(
          name: 'Test Gallery',
          description: 'Test gallery for unit tests',
          maintainer: GalleryMaintainer(name: 'Test'),
        ),
        plugins: plugins,
      );
    }

    group('Database-based detection', () {
      test('detects plugin installed via gallery (in database)', () async {
        // Create a plugin and add it to database
        final plugin = createTestPlugin(
          id: 'test-plugin',
          name: 'Test Plugin',
          guid: 'TEST',
        );

        await database.pluginInstallationsDao.recordPluginInstallation(
          plugin: plugin,
          installedVersion: 'v1.0.0',
          installationPath: '/programs/lua',
        );

        final gallery = createTestGallery([plugin]);
        final updateInfo = await galleryService.compareWithInstalledVersions(
          gallery,
        );

        expect(updateInfo, contains('test-plugin'));
        expect(updateInfo['test-plugin']!.installedVersion, equals('v1.0.0'));
        expect(updateInfo['test-plugin']!.updateAvailable, isFalse);
      });

      test('shows update available when newer version exists', () async {
        final plugin = createTestPlugin(
          id: 'test-plugin',
          name: 'Test Plugin',
          guid: 'TEST',
        );

        // Install version 1.0.0
        await database.pluginInstallationsDao.recordPluginInstallation(
          plugin: plugin,
          installedVersion: 'v0.9.0', // Older version
          installationPath: '/programs/lua',
        );

        // Gallery has version 1.0.0
        final gallery = createTestGallery([plugin]);
        final updateInfo = await galleryService.compareWithInstalledVersions(
          gallery,
        );

        expect(updateInfo, contains('test-plugin'));
        expect(updateInfo['test-plugin']!.installedVersion, equals('v0.9.0'));
        expect(updateInfo['test-plugin']!.availableVersion, equals('v1.0.0'));
        expect(updateInfo['test-plugin']!.updateAvailable, isTrue);
      });

      test('does not detect uninstalled plugins', () async {
        final plugin = createTestPlugin(
          id: 'test-plugin',
          name: 'Test Plugin',
          guid: 'TEST',
        );

        // Plugin not in database
        final gallery = createTestGallery([plugin]);
        final updateInfo = await galleryService.compareWithInstalledVersions(
          gallery,
        );

        expect(updateInfo, isEmpty);
      });
    });

    group('Device GUID-based detection', () {
      test('detects manually installed plugin via device GUID', () async {
        final plugin = createTestPlugin(
          id: 'manual-plugin',
          name: 'Manual Plugin',
          guid: 'MNPL',
        );

        // Plugin not in database, but on device
        final gallery = createTestGallery([plugin]);
        final devicePluginGuids = {'MNPL'}; // Plugin is on device

        final updateInfo = await galleryService.compareWithInstalledVersions(
          gallery,
          devicePluginGuids: devicePluginGuids,
        );

        expect(updateInfo, contains('manual-plugin'));
        expect(
          updateInfo['manual-plugin']!.installedVersion,
          equals('unknown'),
        );
        expect(updateInfo['manual-plugin']!.updateAvailable, isFalse);
      });

      test('caches manually installed plugin in database', () async {
        final plugin = createTestPlugin(
          id: 'manual-plugin',
          name: 'Manual Plugin',
          guid: 'MNPL',
        );

        final gallery = createTestGallery([plugin]);
        final devicePluginGuids = {'MNPL'};

        // First detection - should cache in database
        await galleryService.compareWithInstalledVersions(
          gallery,
          devicePluginGuids: devicePluginGuids,
        );

        // Verify it was cached
        final cached = await database.pluginInstallationsDao
            .getAllInstalledPlugins();
        expect(cached, hasLength(1));
        expect(cached.first.pluginId, equals('manual-plugin'));
        expect(cached.first.pluginVersion, equals('unknown'));
        expect(
          cached.first.installationNotes,
          equals('Detected via device GUID matching'),
        );
      });

      test('uses database cache on subsequent checks', () async {
        final plugin = createTestPlugin(
          id: 'cached-plugin',
          name: 'Cached Plugin',
          guid: 'CACH',
        );

        final gallery = createTestGallery([plugin]);
        final devicePluginGuids = {'CACH'};

        // First detection - caches in database
        await galleryService.compareWithInstalledVersions(
          gallery,
          devicePluginGuids: devicePluginGuids,
        );

        // Second check without device GUID - should use database cache
        final updateInfo = await galleryService.compareWithInstalledVersions(
          gallery,
          devicePluginGuids: null, // No device GUIDs provided
        );

        expect(updateInfo, contains('cached-plugin'));
        expect(updateInfo['cached-plugin']!.installedVersion, equals('unknown'));
      });

      test('does not detect plugin without matching GUID', () async {
        final plugin = createTestPlugin(
          id: 'other-plugin',
          name: 'Other Plugin',
          guid: 'OTHR',
        );

        final gallery = createTestGallery([plugin]);
        final devicePluginGuids = {'DIFF'}; // Different GUID

        final updateInfo = await galleryService.compareWithInstalledVersions(
          gallery,
          devicePluginGuids: devicePluginGuids,
        );

        expect(updateInfo, isEmpty);
      });

      test('handles plugins without GUIDs gracefully', () async {
        final plugin = createTestPlugin(
          id: 'no-guid-plugin',
          name: 'No GUID Plugin',
          guid: null, // No GUID
        );

        final gallery = createTestGallery([plugin]);
        final devicePluginGuids = {'SOME'};

        final updateInfo = await galleryService.compareWithInstalledVersions(
          gallery,
          devicePluginGuids: devicePluginGuids,
        );

        expect(updateInfo, isEmpty);
      });
    });

    group('Mixed detection scenarios', () {
      test('prioritizes database version over device GUID detection', () async {
        final plugin = createTestPlugin(
          id: 'mixed-plugin',
          name: 'Mixed Plugin',
          guid: 'MIXD',
        );

        // Plugin in database with specific version
        await database.pluginInstallationsDao.recordPluginInstallation(
          plugin: plugin,
          installedVersion: 'v2.0.0',
          installationPath: '/programs/lua',
        );

        final gallery = createTestGallery([plugin]);
        final devicePluginGuids = {'MIXD'}; // Also on device

        final updateInfo = await galleryService.compareWithInstalledVersions(
          gallery,
          devicePluginGuids: devicePluginGuids,
        );

        // Should use database version, not 'unknown'
        expect(updateInfo['mixed-plugin']!.installedVersion, equals('v2.0.0'));
      });

      test('detects multiple plugins with different installation methods', () async {
        final galleryPlugin = createTestPlugin(
          id: 'gallery-plugin',
          name: 'Gallery Plugin',
          guid: 'GALL',
        );
        final manualPlugin = createTestPlugin(
          id: 'manual-plugin',
          name: 'Manual Plugin',
          guid: 'MNPL',
        );
        final unknownPlugin = createTestPlugin(
          id: 'unknown-plugin',
          name: 'Unknown Plugin',
          guid: 'UNKN',
        );

        // Gallery plugin in database
        await database.pluginInstallationsDao.recordPluginInstallation(
          plugin: galleryPlugin,
          installedVersion: 'v1.0.0',
          installationPath: '/programs/lua',
        );

        final gallery = createTestGallery([
          galleryPlugin,
          manualPlugin,
          unknownPlugin,
        ]);
        final devicePluginGuids = {'GALL', 'MNPL'}; // Manual plugin on device

        final updateInfo = await galleryService.compareWithInstalledVersions(
          gallery,
          devicePluginGuids: devicePluginGuids,
        );

        // Gallery plugin detected via database
        expect(updateInfo, contains('gallery-plugin'));
        expect(updateInfo['gallery-plugin']!.installedVersion, equals('v1.0.0'));

        // Manual plugin detected via device GUID
        expect(updateInfo, contains('manual-plugin'));
        expect(updateInfo['manual-plugin']!.installedVersion, equals('unknown'));

        // Unknown plugin not detected
        expect(updateInfo, isNot(contains('unknown-plugin')));
      });
    });

    group('Edge cases', () {
      test('handles empty gallery', () async {
        final gallery = createTestGallery([]);
        final updateInfo = await galleryService.compareWithInstalledVersions(
          gallery,
        );

        expect(updateInfo, isEmpty);
      });

      test('handles empty device GUID set', () async {
        final plugin = createTestPlugin(
          id: 'test-plugin',
          name: 'Test Plugin',
          guid: 'TEST',
        );

        final gallery = createTestGallery([plugin]);
        final updateInfo = await galleryService.compareWithInstalledVersions(
          gallery,
          devicePluginGuids: {},
        );

        expect(updateInfo, isEmpty);
      });

      test('handles null device GUID set', () async {
        final plugin = createTestPlugin(
          id: 'test-plugin',
          name: 'Test Plugin',
          guid: 'TEST',
        );

        final gallery = createTestGallery([plugin]);
        final updateInfo = await galleryService.compareWithInstalledVersions(
          gallery,
          devicePluginGuids: null,
        );

        expect(updateInfo, isEmpty);
      });
    });

    group('Date-based comparison fallback', () {
      test('uses date comparison when versions are invalid', () async {
        // Create plugin with invalid version but recent updatedAt
        final plugin = GalleryPlugin(
          id: 'date-plugin',
          name: 'Date Plugin',
          description: 'Plugin with invalid version',
          type: GalleryPluginType.lua,
          author: 'test-author',
          repository: const PluginRepository(
            owner: 'test-owner',
            name: 'test-repo',
            url: 'https://github.com/test-owner/test-repo',
          ),
          releases: const PluginReleases(latest: 'invalid-version'),
          installation: const PluginInstallation(targetPath: '/programs/lua'),
          guid: 'DATE',
          updatedAt: DateTime.now(), // Recently updated
        );

        // Install with invalid version 2 days ago
        await database.pluginInstallationsDao.recordPluginInstallation(
          plugin: plugin,
          installedVersion: 'old-invalid-version',
          installationPath: '/programs/lua',
        );

        // Manually update installedAt to 2 days ago
        final installed = await database.pluginInstallationsDao
            .getAllInstalledPlugins();
        final id = installed.first.id;
        await database.into(database.pluginInstallations).update(
              database.pluginInstallations.companion(
                installedAt: Value(DateTime.now().subtract(const Duration(days: 2))),
              ),
              where: (tbl) => tbl.id.equals(id),
            );

        final gallery = createTestGallery([plugin]);
        final updateInfo = await galleryService.compareWithInstalledVersions(
          gallery,
        );

        // Should detect update via date comparison
        expect(updateInfo, contains('date-plugin'));
        expect(updateInfo['date-plugin']!.updateAvailable, isTrue);
      });

      test('no update when gallery updatedAt is older than installation', () async {
        final plugin = GalleryPlugin(
          id: 'old-plugin',
          name: 'Old Plugin',
          description: 'Plugin with old updatedAt',
          type: GalleryPluginType.lua,
          author: 'test-author',
          repository: const PluginRepository(
            owner: 'test-owner',
            name: 'test-repo',
            url: 'https://github.com/test-owner/test-repo',
          ),
          releases: const PluginReleases(latest: 'invalid-version'),
          installation: const PluginInstallation(targetPath: '/programs/lua'),
          guid: 'OLDP',
          updatedAt: DateTime.now().subtract(const Duration(days: 5)), // Old update
        );

        // Install recently
        await database.pluginInstallationsDao.recordPluginInstallation(
          plugin: plugin,
          installedVersion: 'current-version',
          installationPath: '/programs/lua',
        );

        final gallery = createTestGallery([plugin]);
        final updateInfo = await galleryService.compareWithInstalledVersions(
          gallery,
        );

        // Should not detect update - installed version is newer
        expect(updateInfo, contains('old-plugin'));
        expect(updateInfo['old-plugin']!.updateAvailable, isFalse);
      });

      test('handles plugins with no updatedAt date gracefully', () async {
        final plugin = GalleryPlugin(
          id: 'no-date-plugin',
          name: 'No Date Plugin',
          description: 'Plugin without dates',
          type: GalleryPluginType.lua,
          author: 'test-author',
          repository: const PluginRepository(
            owner: 'test-owner',
            name: 'test-repo',
            url: 'https://github.com/test-owner/test-repo',
          ),
          releases: const PluginReleases(latest: 'invalid'),
          installation: const PluginInstallation(targetPath: '/programs/lua'),
          guid: 'NODT',
          updatedAt: null, // No date
        );

        await database.pluginInstallationsDao.recordPluginInstallation(
          plugin: plugin,
          installedVersion: 'unknown',
          installationPath: '/programs/lua',
        );

        final gallery = createTestGallery([plugin]);
        final updateInfo = await galleryService.compareWithInstalledVersions(
          gallery,
        );

        // Should not detect update - conservative approach
        expect(updateInfo, contains('no-date-plugin'));
        expect(updateInfo['no-date-plugin']!.updateAvailable, isFalse);
      });

      test('prefers version comparison over date comparison', () async {
        // Plugin with both valid version AND updatedAt
        final plugin = GalleryPlugin(
          id: 'version-priority',
          name: 'Version Priority Plugin',
          description: 'Plugin with both version and date',
          type: GalleryPluginType.lua,
          author: 'test-author',
          repository: const PluginRepository(
            owner: 'test-owner',
            name: 'test-repo',
            url: 'https://github.com/test-owner/test-repo',
          ),
          releases: const PluginReleases(latest: 'v2.0.0'),
          installation: const PluginInstallation(targetPath: '/programs/lua'),
          guid: 'VPRI',
          updatedAt: DateTime.now().subtract(const Duration(days: 10)), // Old date
        );

        // Install v1.0.0 recently
        await database.pluginInstallationsDao.recordPluginInstallation(
          plugin: plugin,
          installedVersion: 'v1.0.0',
          installationPath: '/programs/lua',
        );

        final gallery = createTestGallery([plugin]);
        final updateInfo = await galleryService.compareWithInstalledVersions(
          gallery,
        );

        // Should detect update via version comparison (v1 < v2)
        // even though date suggests no update
        expect(updateInfo, contains('version-priority'));
        expect(updateInfo['version-priority']!.updateAvailable, isTrue);
      });
    });
  });
}
