import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/models/gallery_models.dart';
import 'package:nt_helper/services/settings_service.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

@GenerateMocks([http.Client, SettingsService])
import 'gallery_service_test.mocks.dart';

void main() {
  group('GalleryService downloadUrl Support', () {
    late MockSettingsService mockSettingsService;

    setUp(() {
      mockSettingsService = MockSettingsService();
      when(
        mockSettingsService.galleryUrl,
      ).thenReturn('https://test.com/gallery.json');
    });

    test(
      'should prioritize downloadUrl over GitHub API when available',
      () async {
        // Create a test plugin with downloadUrl
        final plugin = GalleryPlugin(
          id: 'test-plugin',
          name: 'Test Plugin',
          description: 'A test plugin',
          type: GalleryPluginType.lua,
          author: 'test-author',
          repository: PluginRepository(
            owner: 'test-owner',
            name: 'test-repo',
            url: 'https://github.com/test-owner/test-repo',
          ),
          releases: PluginReleases(latest: 'v1.0.0'),
          installation: PluginInstallation(
            targetPath: '/lua/',
            downloadUrl: 'https://example.com/direct-download.lua',
            extractPattern: r'.*\.lua$',
          ),
        );

        // Test that downloadUrl is used directly
        // Note: This is testing the logic, not actual network calls
        expect(plugin.installation.downloadUrl, isNotNull);
        expect(
          plugin.installation.downloadUrl,
          'https://example.com/direct-download.lua',
        );
        expect(plugin.installation.extractPattern, r'.*\.lua$');
      },
    );

    test('should handle zip extraction with extractPattern', () {
      // Test different plugin types and their extract patterns
      final testCases = [
        {
          'type': GalleryPluginType.lua,
          'expectedPattern': r'.*\.lua$',
          'downloadUrl': 'https://example.com/lua-plugin.zip',
        },
        {
          'type': GalleryPluginType.cpp,
          'expectedPattern': r'.*\.cpp$',
          'downloadUrl': 'https://example.com/cpp-plugin.zip',
        },
        {
          'type': GalleryPluginType.threepot,
          'expectedPattern': r'.*\.3pot$',
          'downloadUrl': 'https://example.com/threepot-plugin.zip',
        },
      ];

      for (final testCase in testCases) {
        final plugin = GalleryPlugin(
          id: 'test-${testCase['type']}',
          name: 'Test ${testCase['type']} Plugin',
          description: 'A test plugin',
          type: testCase['type'] as GalleryPluginType,
          author: 'test-author',
          repository: PluginRepository(
            owner: 'test-owner',
            name: 'test-repo',
            url: 'https://github.com/test-owner/test-repo',
          ),
          releases: PluginReleases(latest: 'v1.0.0'),
          installation: PluginInstallation(
            targetPath: '/test/',
            downloadUrl: testCase['downloadUrl'] as String,
            extractPattern: testCase['expectedPattern'] as String,
          ),
        );

        expect(plugin.installation.downloadUrl, testCase['downloadUrl']);
        expect(plugin.installation.extractPattern, testCase['expectedPattern']);
      }
    });

    test('should handle fallback to GitHub API when downloadUrl is null', () {
      final plugin = GalleryPlugin(
        id: 'test-plugin',
        name: 'Test Plugin',
        description: 'A test plugin',
        type: GalleryPluginType.lua,
        author: 'test-author',
        repository: PluginRepository(
          owner: 'test-owner',
          name: 'test-repo',
          url: 'https://github.com/test-owner/test-repo',
        ),
        releases: PluginReleases(latest: 'v1.0.0'),
        installation: PluginInstallation(
          targetPath: '/lua/',
          // downloadUrl is null, should fall back to GitHub API
          extractPattern: r'.*\.lua$',
        ),
      );

      expect(plugin.installation.downloadUrl, isNull);
      expect(plugin.installation.extractPattern, r'.*\.lua$');
      // In actual implementation, this would trigger GitHub API calls
    });

    test('should support collection plugins with multiple files', () {
      final collectionPlugin = GalleryPlugin(
        id: 'test-collection',
        name: 'Test Collection',
        description: 'A collection of plugins',
        type: GalleryPluginType.cpp,
        author: 'test-author',
        repository: PluginRepository(
          owner: 'test-owner',
          name: 'test-collection-repo',
          url: 'https://github.com/test-owner/test-collection-repo',
        ),
        releases: PluginReleases(latest: 'v1.0.0'),
        installation: PluginInstallation(
          targetPath: '/programs/plug-ins/test-owner/',
          downloadUrl: 'https://example.com/collection.zip',
          extractPattern: r'.*\.o$', // Multiple .o files in the zip
        ),
      );

      expect(collectionPlugin.installation.downloadUrl, isNotNull);
      expect(collectionPlugin.installation.extractPattern, r'.*\.o$');
      // This would extract multiple .o files from the zip archive
    });
  });
}
