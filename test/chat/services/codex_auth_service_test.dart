import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:nt_helper/chat/services/codex_auth_service.dart';

class _FakeClient extends http.BaseClient {
  final Future<http.Response> Function(http.BaseRequest request, String body)
  handler;

  _FakeClient(this.handler);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final body = request is http.Request ? request.body : '';
    final response = await handler(request, body);
    return http.StreamedResponse(
      Stream.value(utf8.encode(response.body)),
      response.statusCode,
      headers: response.headers,
    );
  }
}

void main() {
  group('CodexAuthService', () {
    test('authFound validates access and refresh tokens', () async {
      final dir = await Directory.systemTemp.createTemp('codex-auth-test');
      addTearDown(() => dir.delete(recursive: true));
      final authFile = File('${dir.path}/auth.json');
      await authFile.writeAsString(
        jsonEncode({
          'tokens': {
            'access_token': 'access',
            'refresh_token': 'refresh',
            'account_id': 'acct',
          },
        }),
      );

      final service = CodexAuthService(authFilePath: authFile.path);
      addTearDown(service.dispose);

      expect(await service.authFound(), isTrue);
      final snapshot = await service.loadAuth();
      expect(snapshot.accessToken, 'access');
      expect(snapshot.refreshToken, 'refresh');
      expect(snapshot.accountId, 'acct');
    });

    test('refreshAuth rotates tokens and updates auth file', () async {
      final dir = await Directory.systemTemp.createTemp('codex-auth-test');
      addTearDown(() => dir.delete(recursive: true));
      final authFile = File('${dir.path}/auth.json');
      await authFile.writeAsString(
        jsonEncode({
          'tokens': {
            'access_token': 'old-access',
            'refresh_token': 'old-refresh',
            'account_id': 'old-account',
          },
        }),
      );

      final client = _FakeClient((request, body) async {
        expect(request.url.toString(), CodexAuthService.tokenUrl);
        final decoded = jsonDecode(body) as Map<String, dynamic>;
        expect(decoded['client_id'], CodexAuthService.clientId);
        expect(decoded['grant_type'], 'refresh_token');
        expect(decoded['refresh_token'], 'old-refresh');
        return http.Response(
          jsonEncode({
            'access_token': _jwtWithAccount('new-account'),
            'refresh_token': 'new-refresh',
            'id_token': 'new-id',
          }),
          200,
        );
      });
      final service = CodexAuthService(
        client: client,
        authFilePath: authFile.path,
      );
      addTearDown(service.dispose);

      final refreshed = await service.refreshAuth();

      expect(refreshed.refreshToken, 'new-refresh');
      expect(refreshed.idToken, 'new-id');
      expect(refreshed.accountId, 'new-account');
      final saved = jsonDecode(await authFile.readAsString()) as Map;
      final savedTokens = saved['tokens'] as Map;
      expect(savedTokens['refresh_token'], 'new-refresh');
      expect(savedTokens['id_token'], 'new-id');
      expect(savedTokens['account_id'], 'new-account');
      expect(saved['last_refresh'], isA<String>());
    });
  });
}

String _jwtWithAccount(String accountId) {
  final payload = base64UrlEncode(
    utf8.encode(
      jsonEncode({
        'https://api.openai.com/auth': {'chatgpt_account_id': accountId},
      }),
    ),
  ).replaceAll('=', '');
  return 'header.$payload.signature';
}
