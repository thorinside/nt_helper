import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/models/gallery_models.dart';
import 'package:nt_helper/services/gallery_service.dart';
import 'package:nt_helper/services/settings_service.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockSettingsService extends Mock implements SettingsService {}

void main() {
  group('GalleryService GUID Lookup', () {
    late GalleryService galleryService;
    late MockSettingsService mockSettingsService;

    setUp(() async {
      // Initialize shared preferences for testing
      SharedPreferences.setMockInitialValues({});

      mockSettingsService = MockSettingsService();

      // Mock the settings service methods
      when(() => mockSettingsService.galleryUrl).thenReturn(
        'https://example.com/gallery.json',
      );
      when(() => mockSettingsService.graphqlEndpoint).thenReturn(
        'https://example.com/graphql',
      );

      galleryService = GalleryService(settingsService: mockSettingsService);
    });

    GalleryPlugin createTestPlugin({
      required String id,
      required String name,
      String? guid,
      List<String> collectionGuids = const [],
      bool isCollection = false,
    }) {
      return GalleryPlugin(
        id: id,
        name: name,
        description: 'Test plugin',
        type: GalleryPluginType.cpp,
        author: 'test-author',
        repository: const PluginRepository(
          owner: 'test-owner',
          name: 'test-repo',
          url: 'https://github.com/test-owner/test-repo',
        ),
        releases: const PluginReleases(latest: 'v1.0.0'),
        installation: const PluginInstallation(targetPath: 'programs/plug-ins'),
        guid: guid,
        collectionGuids: collectionGuids,
        isCollection: isCollection,
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

    test('getPluginByGuid returns null when lookup is empty', () {
      final result = galleryService.getPluginByGuid('TEST');
      expect(result, isNull);
    });

    test('getPluginByGuid finds plugin by single GUID', () async {
      // Create a test gallery with a single plugin
      final plugin = createTestPlugin(
        id: 'tides-port',
        name: 'Tides Port',
        guid: 'TidS',
      );
      final gallery = createTestGallery([plugin]);

      // Initialize the GUID lookup
      galleryService.initializeGuidLookup(gallery);

      // Verify getPluginByGuid returns the correct plugin
      final result = galleryService.getPluginByGuid('TidS');
      expect(result, isNotNull);
      expect(result!.id, equals('tides-port'));
      expect(result.name, equals('Tides Port'));
    });

    test('getPluginByGuid finds plugin by collection GUID', () async {
      // Create a collection plugin with multiple GUIDs
      final plugin = createTestPlugin(
        id: 'airwindows',
        name: 'Airwindows Collection',
        isCollection: true,
        collectionGuids: ['Air1', 'Air2', 'Air3', 'Air4'],
      );
      final gallery = createTestGallery([plugin]);

      // Initialize the GUID lookup
      galleryService.initializeGuidLookup(gallery);

      // Verify each collection GUID returns the parent plugin
      expect(galleryService.getPluginByGuid('Air1')?.id, equals('airwindows'));
      expect(galleryService.getPluginByGuid('Air2')?.id, equals('airwindows'));
      expect(galleryService.getPluginByGuid('Air3')?.id, equals('airwindows'));
      expect(galleryService.getPluginByGuid('Air4')?.id, equals('airwindows'));
    });

    test('getPluginByGuid returns null for unknown GUID', () async {
      final plugin = createTestPlugin(
        id: 'tides-port',
        name: 'Tides Port',
        guid: 'TidS',
      );
      final gallery = createTestGallery([plugin]);

      galleryService.initializeGuidLookup(gallery);

      // Verify unknown GUID returns null
      expect(galleryService.getPluginByGuid('UNKN'), isNull);
    });

    test('getPluginByGuid handles case-insensitive matching', () async {
      final plugin = createTestPlugin(
        id: 'test-plugin',
        name: 'Test Plugin',
        guid: 'TeSt',
      );
      final gallery = createTestGallery([plugin]);

      galleryService.initializeGuidLookup(gallery);

      // Verify case-insensitive fallback works
      expect(galleryService.getPluginByGuid('test')?.id, equals('test-plugin'));
      expect(galleryService.getPluginByGuid('TEST')?.id, equals('test-plugin'));
    });

    test('GalleryPlugin model correctly stores collectionGuids', () {
      final plugin = createTestPlugin(
        id: 'airwindows',
        name: 'Airwindows Collection',
        isCollection: true,
        collectionGuids: ['Air1', 'Air2', 'Air3', 'Air4'],
      );

      expect(plugin.isCollection, isTrue);
      expect(plugin.collectionGuids, hasLength(4));
      expect(plugin.collectionGuids, contains('Air1'));
      expect(plugin.collectionGuids, contains('Air4'));
    });

    test('GalleryPlugin model correctly stores single guid', () {
      final plugin = createTestPlugin(
        id: 'tides-port',
        name: 'Tides Port',
        guid: 'TidS',
        isCollection: false,
      );

      expect(plugin.isCollection, isFalse);
      expect(plugin.guid, equals('TidS'));
      expect(plugin.collectionGuids, isEmpty);
    });

    test('GalleryPlugin model handles empty guid and collectionGuids', () {
      final plugin = createTestPlugin(id: 'lua-plugin', name: 'Lua Plugin');

      expect(plugin.guid, isNull);
      expect(plugin.collectionGuids, isEmpty);
    });

    test('Gallery correctly aggregates plugins with GUIDs', () {
      final plugins = [
        createTestPlugin(id: 'p1', name: 'Plugin 1', guid: 'GD01'),
        createTestPlugin(id: 'p2', name: 'Plugin 2', guid: 'GD02'),
        createTestPlugin(
          id: 'collection',
          name: 'Collection',
          isCollection: true,
          collectionGuids: ['COL1', 'COL2'],
        ),
      ];

      final gallery = createTestGallery(plugins);

      expect(gallery.plugins, hasLength(3));

      // Verify we can find plugins with GUIDs
      final pluginsWithGuid =
          gallery.plugins.where((p) => p.guid != null).toList();
      expect(pluginsWithGuid, hasLength(2));

      // Verify we can find plugins with collectionGuids
      final collections =
          gallery.plugins.where((p) => p.collectionGuids.isNotEmpty).toList();
      expect(collections, hasLength(1));
      expect(collections.first.collectionGuids, hasLength(2));
    });
  });

  group('GalleryPlugin JSON serialization', () {
    test('collectionGuids serializes to JSON correctly', () {
      final plugin = GalleryPlugin(
        id: 'test',
        name: 'Test',
        description: 'Test',
        type: GalleryPluginType.cpp,
        author: 'author',
        repository: const PluginRepository(
          owner: 'o',
          name: 'n',
          url: 'https://example.com',
        ),
        releases: const PluginReleases(latest: 'v1.0.0'),
        installation: const PluginInstallation(targetPath: 'path'),
        guid: 'TEST',
        collectionGuids: ['GD01', 'GD02', 'GD03'],
      );

      final json = plugin.toJson();

      expect(json['collectionGuids'], isA<List>());
      expect(json['collectionGuids'], hasLength(3));
      expect(json['collectionGuids'], contains('GD01'));
      expect(json['guid'], equals('TEST'));
    });

    test('collectionGuids deserializes from JSON correctly', () {
      final json = {
        'id': 'test',
        'name': 'Test',
        'description': 'Test',
        'type': 'cpp',
        'author': 'author',
        'repository': {
          'owner': 'o',
          'name': 'n',
          'url': 'https://example.com',
        },
        'releases': {'latest': 'v1.0.0'},
        'installation': {'targetPath': 'path'},
        'guid': 'TEST',
        'collectionGuids': ['GD01', 'GD02', 'GD03'],
      };

      final plugin = GalleryPlugin.fromJson(json);

      expect(plugin.collectionGuids, hasLength(3));
      expect(plugin.collectionGuids, contains('GD01'));
      expect(plugin.collectionGuids, contains('GD03'));
      expect(plugin.guid, equals('TEST'));
    });

    test('missing collectionGuids defaults to empty list', () {
      final json = {
        'id': 'test',
        'name': 'Test',
        'description': 'Test',
        'type': 'cpp',
        'author': 'author',
        'repository': {
          'owner': 'o',
          'name': 'n',
          'url': 'https://example.com',
        },
        'releases': {'latest': 'v1.0.0'},
        'installation': {'targetPath': 'path'},
      };

      final plugin = GalleryPlugin.fromJson(json);

      expect(plugin.collectionGuids, isEmpty);
      expect(plugin.guid, isNull);
    });
  });
}
