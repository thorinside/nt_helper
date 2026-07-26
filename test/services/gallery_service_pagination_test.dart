import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nt_helper/services/gallery_service.dart';
import 'package:nt_helper/services/settings_service.dart';
import 'package:nt_helper/utils/app_directory.dart';

class MockSettingsService extends Mock implements SettingsService {}

void main() {
  group('GalleryService GraphQL pagination', () {
    late HttpServer server;
    late StreamSubscription<HttpRequest> serverSubscription;
    late MockSettingsService settingsService;
    late List<({int limit, int offset})> pluginPageRequests;
    late Directory tempRoot;
    late int totalPlugins;

    setUp(() async {
      totalPlugins = 120;
      resetAppDirectoryForTest();
      tempRoot = Directory.systemTemp.createTempSync(
        'gallery_service_pagination_test_',
      );
      await getAppDirectory(docsProvider: () async => tempRoot);

      pluginPageRequests = [];
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      serverSubscription = server.listen((request) async {
        final payload =
            jsonDecode(await utf8.decoder.bind(request).join())
                as Map<String, dynamic>;
        final query = payload['query'] as String;

        final Map<String, dynamic> responseBody;
        if (query.contains('query GetPlugins')) {
          final variables =
              payload['variables'] as Map<String, dynamic>? ??
              const <String, dynamic>{};
          final limit = variables['limit'] as int? ?? 50;
          final offset = variables['offset'] as int? ?? 0;
          pluginPageRequests.add((limit: limit, offset: offset));

          final end = offset + limit < totalPlugins
              ? offset + limit
              : totalPlugins;
          final plugins = offset >= totalPlugins
              ? <Map<String, dynamic>>[]
              : [
                  for (var index = offset; index < end; index++)
                    {
                      'slug': 'plugin-$index',
                      'name': 'Plugin $index',
                      'pluginType': 'CPP',
                      'verified': true,
                    },
                ];

          responseBody = {
            'data': {'plugins': plugins},
          };
        } else {
          responseBody = {
            'data': {'categories': <Map<String, dynamic>>[]},
          };
        }

        request.response.headers.contentType = ContentType.json;
        request.response.write(jsonEncode(responseBody));
        await request.response.close();
      });

      settingsService = MockSettingsService();
      when(
        () => settingsService.graphqlEndpoint,
      ).thenReturn('http://${server.address.host}:${server.port}/graphql');
      when(
        () => settingsService.galleryUrl,
      ).thenReturn('https://example.invalid/gallery.json');
    });

    tearDown(() async {
      await serverSubscription.cancel();
      await server.close(force: true);
      resetAppDirectoryForTest();
      tempRoot.deleteSync(recursive: true);
    });

    test('loads every plugin in batches of 50', () async {
      final service = GalleryService(settingsService: settingsService);

      final gallery = await service.fetchGallery(forceRefresh: true);

      expect(gallery.plugins, hasLength(120));
      expect(gallery.plugins.first.id, 'plugin-0');
      expect(gallery.plugins.last.id, 'plugin-119');
      expect(pluginPageRequests, [
        (limit: 50, offset: 0),
        (limit: 50, offset: 50),
        (limit: 50, offset: 100),
      ]);
    });

    test(
      'stops after an empty page when the total is a multiple of 50',
      () async {
        totalPlugins = 100;
        final service = GalleryService(settingsService: settingsService);

        final gallery = await service.fetchGallery(forceRefresh: true);

        expect(gallery.plugins, hasLength(100));
        expect(pluginPageRequests, [
          (limit: 50, offset: 0),
          (limit: 50, offset: 50),
          (limit: 50, offset: 100),
        ]);
      },
    );
  });
}
