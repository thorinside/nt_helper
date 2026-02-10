import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:nt_helper/models/app_release.dart';
import 'package:nt_helper/services/app_update_service.dart';

class MockHttpClient extends Mock implements http.Client {}

class FakeUri extends Fake implements Uri {}

const _sampleRelease = {
  'tag_name': 'v3.0.0',
  'body': '## What\'s New\n- Feature A\n- Feature B',
  'published_at': '2026-02-01T00:00:00Z',
  'assets': [
    {
      'name': 'nt_helper-3.0.0-macos.zip',
      'browser_download_url':
          'https://github.com/thorinside/nt_helper/releases/download/v3.0.0/nt_helper-3.0.0-macos.zip',
    },
    {
      'name': 'nt_helper-3.0.0-linux.zip',
      'browser_download_url':
          'https://github.com/thorinside/nt_helper/releases/download/v3.0.0/nt_helper-3.0.0-linux.zip',
    },
    {
      'name': 'nt_helper-3.0.0-windows.zip',
      'browser_download_url':
          'https://github.com/thorinside/nt_helper/releases/download/v3.0.0/nt_helper-3.0.0-windows.zip',
    },
  ],
};

void main() {
  setUpAll(() {
    registerFallbackValue(FakeUri());
  });

  group('AppRelease.fromGitHubJson', () {
    test('parses tag_name with v prefix', () {
      final release = AppRelease.fromGitHubJson(
        Map<String, dynamic>.from(_sampleRelease),
      );
      expect(release.version, '3.0.0');
      expect(release.tagName, 'v3.0.0');
    });

    test('parses tag_name without v prefix', () {
      final json = Map<String, dynamic>.from(_sampleRelease);
      json['tag_name'] = '2.5.0';
      final release = AppRelease.fromGitHubJson(json);
      expect(release.version, '2.5.0');
      expect(release.tagName, '2.5.0');
    });

    test('parses release body', () {
      final release = AppRelease.fromGitHubJson(
        Map<String, dynamic>.from(_sampleRelease),
      );
      expect(release.body, contains('Feature A'));
    });

    test('parses published date', () {
      final release = AppRelease.fromGitHubJson(
        Map<String, dynamic>.from(_sampleRelease),
      );
      expect(release.publishedAt.year, 2026);
      expect(release.publishedAt.month, 2);
    });

    test('parses platform assets', () {
      final release = AppRelease.fromGitHubJson(
        Map<String, dynamic>.from(_sampleRelease),
      );
      expect(release.platformAssets, hasLength(3));
      expect(release.platformAssets['macos'], contains('macos.zip'));
      expect(release.platformAssets['linux'], contains('linux.zip'));
      expect(release.platformAssets['windows'], contains('windows.zip'));
    });

    test('handles missing assets gracefully', () {
      final json = Map<String, dynamic>.from(_sampleRelease);
      json['assets'] = [];
      final release = AppRelease.fromGitHubJson(json);
      expect(release.platformAssets, isEmpty);
    });

    test('handles null body', () {
      final json = Map<String, dynamic>.from(_sampleRelease);
      json['body'] = null;
      final release = AppRelease.fromGitHubJson(json);
      expect(release.body, '');
    });
  });

  group('AppUpdateService', () {
    late MockHttpClient mockClient;
    late AppUpdateService service;

    setUp(() {
      mockClient = MockHttpClient();
      // Inject a current version older than sample release so update is found
      service = AppUpdateService(
        httpClient: mockClient,
        currentVersion: '2.0.0',
      );
    });

    test('returns null on HTTP error', () async {
      when(
        () => mockClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer(
        (_) async => http.Response('Not Found', 404),
      );

      final result = await service.checkForUpdate();
      expect(result, isNull);
    });

    test('returns null on network error', () async {
      when(
        () => mockClient.get(any(), headers: any(named: 'headers')),
      ).thenThrow(Exception('Network error'));

      final result = await service.checkForUpdate();
      expect(result, isNull);
    });

    test('returns release when update is available', () async {
      when(
        () => mockClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer(
        (_) async => http.Response(jsonEncode(_sampleRelease), 200),
      );

      final result = await service.checkForUpdate();
      expect(result, isNotNull);
      expect(result!.version, '3.0.0');
    });

    test('returns null when already up to date', () async {
      final upToDateService = AppUpdateService(
        httpClient: mockClient,
        currentVersion: '3.0.0',
      );

      when(
        () => mockClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer(
        (_) async => http.Response(jsonEncode(_sampleRelease), 200),
      );

      final result = await upToDateService.checkForUpdate();
      expect(result, isNull);
    });

    test('caches result for subsequent calls', () async {
      when(
        () => mockClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer(
        (_) async => http.Response(jsonEncode(_sampleRelease), 200),
      );

      // First call hits API
      await service.checkForUpdate();
      // Second call should use cache
      await service.checkForUpdate();

      verify(
        () => mockClient.get(any(), headers: any(named: 'headers')),
      ).called(1);
    });

    test('forceRefresh bypasses cache', () async {
      when(
        () => mockClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer(
        (_) async => http.Response(jsonEncode(_sampleRelease), 200),
      );

      await service.checkForUpdate();
      await service.checkForUpdate(forceRefresh: true);

      verify(
        () => mockClient.get(any(), headers: any(named: 'headers')),
      ).called(2);
    });
  });
}
