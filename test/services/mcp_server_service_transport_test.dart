import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nt_helper/cubit/disting_cubit.dart';
import 'package:nt_helper/services/mcp_server_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockDistingCubit extends Mock implements DistingCubit {}

void main() {
  group('McpServerService transports', () {
    late McpServerService service;
    late HttpOverrides? previousHttpOverrides;

    setUpAll(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues({});
      previousHttpOverrides = HttpOverrides.current;
      HttpOverrides.global = null;
      McpServerService.initialize(distingCubit: MockDistingCubit());
      service = McpServerService.instance;
    });

    tearDownAll(() {
      HttpOverrides.global = previousHttpOverrides;
    });

    tearDown(() async {
      await service.stop();
    });

    test('Streamable HTTP: initialize + initialized notification', () async {
      await service.start(
        port: 0,
        bindAddress: InternetAddress.loopbackIPv4,
      );

      final port = service.boundPort;
      expect(port, isNotNull);

      final client = HttpClient();
      addTearDown(() => client.close(force: true));

      // POST initialize (server replies with JSON due to enableJsonResponse: true)
      final initRequest = await client.postUrl(
        Uri.parse('http://127.0.0.1:$port/mcp'),
      );
      initRequest.headers
        ..set(HttpHeaders.acceptHeader, 'application/json, text/event-stream')
        ..set(HttpHeaders.contentTypeHeader, 'application/json');
      initRequest.write(
        jsonEncode({
          'jsonrpc': '2.0',
          'id': 1,
          'method': 'initialize',
          'params': {
            'protocolVersion': '2025-06-18',
            'capabilities': {},
            'clientInfo': {'name': 'test-client', 'version': '0.0.0'},
          },
        }),
      );

      final initResponse = await initRequest.close().timeout(
            const Duration(seconds: 5),
          );
      expect(initResponse.statusCode, equals(HttpStatus.ok));
      // Server uses enableJsonResponse: true, so POST returns application/json
      expect(
        initResponse.headers.contentType?.mimeType,
        equals('application/json'),
      );

      final sessionId = initResponse.headers.value('mcp-session-id');
      expect(sessionId, isNotNull);

      final initBody = await utf8.decodeStream(initResponse);
      final initMessage = jsonDecode(initBody) as Map<String, dynamic>;
      expect(initMessage['jsonrpc'], equals('2.0'));
      expect(initMessage['id'], equals(1));

      // POST notifications/initialized (server should return 202 Accepted)
      final initializedRequest = await client.postUrl(
        Uri.parse('http://127.0.0.1:$port/mcp'),
      );
      initializedRequest.headers
        ..set(HttpHeaders.acceptHeader, 'application/json, text/event-stream')
        ..set(HttpHeaders.contentTypeHeader, 'application/json')
        ..set('mcp-session-id', sessionId!);
      initializedRequest.write(
        jsonEncode({'jsonrpc': '2.0', 'method': 'notifications/initialized'}),
      );

      final initializedResponse = await initializedRequest.close().timeout(
            const Duration(seconds: 5),
          );
      expect(initializedResponse.statusCode, equals(HttpStatus.accepted));
      await initializedResponse.drain<void>();
    });

    test('GET /mcp returns 405 Method Not Allowed', () async {
      await service.start(
        port: 0,
        bindAddress: InternetAddress.loopbackIPv4,
      );

      final port = service.boundPort;
      expect(port, isNotNull);

      final client = HttpClient();
      addTearDown(() => client.close(force: true));

      final getRequest = await client.getUrl(
        Uri.parse('http://127.0.0.1:$port/mcp'),
      );
      getRequest.headers.set(HttpHeaders.acceptHeader, 'text/event-stream');
      getRequest.persistentConnection = false;

      final response = await getRequest.close().timeout(
            const Duration(seconds: 5),
          );
      expect(response.statusCode, equals(HttpStatus.methodNotAllowed));
      await response.drain<void>();
    });
  });
}

