import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nt_helper/cubit/disting_cubit.dart';
import 'package:nt_helper/services/mcp_server_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockDistingCubit extends Mock implements DistingCubit {}

Future<HttpClientResponse> _postJsonRpc(
  HttpClient client,
  int port,
  Object body, {
  String? sessionId,
}) async {
  final request = await client.postUrl(Uri.parse('http://127.0.0.1:$port/mcp'));
  request.headers
    ..set(HttpHeaders.acceptHeader, 'application/json, text/event-stream')
    ..set(HttpHeaders.contentTypeHeader, 'application/json');
  if (sessionId != null) {
    request.headers.set('mcp-session-id', sessionId);
  }
  request.write(jsonEncode(body));
  return request.close().timeout(const Duration(seconds: 5));
}

Future<Map<String, dynamic>> _readJsonRpcMessage(
  HttpClientResponse response,
) async {
  final body = await utf8
      .decodeStream(response)
      .timeout(const Duration(seconds: 5));

  if (response.headers.contentType?.mimeType == 'application/json') {
    return (jsonDecode(body) as Map).cast<String, dynamic>();
  }

  expect(response.headers.contentType?.mimeType, equals('text/event-stream'));

  for (final eventBlock in body.split(RegExp(r'\r?\n\r?\n'))) {
    final data = eventBlock
        .split(RegExp(r'\r?\n'))
        .where((line) => line.startsWith('data:'))
        .map((line) => line.substring('data:'.length).trimLeft())
        .join('\n')
        .trim();
    if (data.isEmpty) {
      continue;
    }

    final decoded = jsonDecode(data);
    if (decoded is Map && decoded['jsonrpc'] == '2.0') {
      return decoded.cast<String, dynamic>();
    }
  }

  fail('No JSON-RPC message found in SSE response: $body');
}

Future<String> _initializeSession(
  HttpClient client,
  int port, {
  int id = 1,
}) async {
  final initResponse = await _postJsonRpc(client, port, {
    'jsonrpc': '2.0',
    'id': id,
    'method': 'initialize',
    'params': {
      'protocolVersion': '2025-06-18',
      'capabilities': {},
      'clientInfo': {'name': 'test-client', 'version': '0.0.0'},
    },
  });
  expect(initResponse.statusCode, equals(HttpStatus.ok));
  expect(
    initResponse.headers.contentType?.mimeType,
    equals('text/event-stream'),
  );

  final sessionId = initResponse.headers.value('mcp-session-id');
  expect(sessionId, isNotNull);

  final initMessage = await _readJsonRpcMessage(initResponse);
  expect(initMessage['jsonrpc'], equals('2.0'));
  expect(initMessage['id'], equals(id));

  final initializedResponse = await _postJsonRpc(client, port, {
    'jsonrpc': '2.0',
    'method': 'notifications/initialized',
  }, sessionId: sessionId);
  expect(initializedResponse.statusCode, equals(HttpStatus.accepted));
  await initializedResponse.drain<void>();

  return sessionId!;
}

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
      await service.start(port: 0, bindAddress: InternetAddress.loopbackIPv4);

      final port = service.boundPort;
      expect(port, isNotNull);

      final client = HttpClient();
      addTearDown(() => client.close(force: true));

      await _initializeSession(client, port!);
    });

    test(
      'GET /mcp opens standalone SSE stream for an initialized session',
      () async {
        await service.start(port: 0, bindAddress: InternetAddress.loopbackIPv4);

        final port = service.boundPort;
        expect(port, isNotNull);

        final client = HttpClient();
        addTearDown(() => client.close(force: true));

        final sessionId = await _initializeSession(client, port!);

        final getRequest = await client.getUrl(
          Uri.parse('http://127.0.0.1:$port/mcp'),
        );
        getRequest.headers
          ..set(HttpHeaders.acceptHeader, 'text/event-stream')
          ..set('mcp-session-id', sessionId);

        final response = await getRequest.close().timeout(
          const Duration(seconds: 5),
        );
        expect(response.statusCode, equals(HttpStatus.ok));
        expect(
          response.headers.contentType?.mimeType,
          equals('text/event-stream'),
        );

        final firstChunk = await response.first.timeout(
          const Duration(seconds: 5),
        );
        expect(utf8.decode(firstChunk), contains('data:'));
      },
    );

    test(
      'add without target returns tool result and does not block subsequent calls',
      () async {
        await service.start(port: 0, bindAddress: InternetAddress.loopbackIPv4);

        final port = service.boundPort;
        expect(port, isNotNull);

        final client = HttpClient();
        addTearDown(() => client.close(force: true));

        final sessionId = await _initializeSession(client, port!);

        final addResponse = await _postJsonRpc(client, port, {
          'jsonrpc': '2.0',
          'id': 2,
          'method': 'tools/call',
          'params': {
            'name': 'add',
            'arguments': {'name': 'VCO/Multiplier'},
          },
        }, sessionId: sessionId);
        expect(addResponse.statusCode, equals(HttpStatus.ok));
        final addMessage = await _readJsonRpcMessage(addResponse);
        expect(addMessage['id'], equals(2));
        expect(addMessage.containsKey('result'), isTrue);
        expect(addMessage.containsKey('error'), isFalse);

        final removeResponse = await _postJsonRpc(client, port, {
          'jsonrpc': '2.0',
          'id': 3,
          'method': 'tools/call',
          'params': {
            'name': 'remove',
            'arguments': {'slot_index': 0},
          },
        }, sessionId: sessionId);
        expect(removeResponse.statusCode, equals(HttpStatus.ok));
        final removeMessage = await _readJsonRpcMessage(removeResponse);
        expect(removeMessage['id'], equals(3));
        expect(removeMessage.containsKey('result'), isTrue);
        expect(removeMessage.containsKey('error'), isFalse);

        final saveResponse = await _postJsonRpc(client, port, {
          'jsonrpc': '2.0',
          'id': 4,
          'method': 'tools/call',
          'params': {'name': 'save', 'arguments': <String, dynamic>{}},
        }, sessionId: sessionId);
        expect(saveResponse.statusCode, equals(HttpStatus.ok));
        final saveMessage = await _readJsonRpcMessage(saveResponse);
        expect(saveMessage['id'], equals(4));
        expect(saveMessage.containsKey('result'), isTrue);
      },
    );

    test(
      'remove out-of-range slot_index returns tool result and does not block subsequent calls',
      () async {
        await service.start(port: 0, bindAddress: InternetAddress.loopbackIPv4);

        final port = service.boundPort;
        expect(port, isNotNull);

        final client = HttpClient();
        addTearDown(() => client.close(force: true));

        final sessionId = await _initializeSession(client, port!, id: 11);

        final removeResponse = await _postJsonRpc(client, port, {
          'jsonrpc': '2.0',
          'id': 12,
          'method': 'tools/call',
          'params': {
            'name': 'remove',
            'arguments': {'slot_index': 99},
          },
        }, sessionId: sessionId);
        expect(removeResponse.statusCode, equals(HttpStatus.ok));
        final removeMessage = await _readJsonRpcMessage(removeResponse);
        expect(removeMessage['id'], equals(12));
        expect(removeMessage.containsKey('result'), isTrue);
        expect(removeMessage.containsKey('error'), isFalse);

        final saveResponse = await _postJsonRpc(client, port, {
          'jsonrpc': '2.0',
          'id': 13,
          'method': 'tools/call',
          'params': {'name': 'save', 'arguments': <String, dynamic>{}},
        }, sessionId: sessionId);
        expect(saveResponse.statusCode, equals(HttpStatus.ok));
        final saveMessage = await _readJsonRpcMessage(saveResponse);
        expect(saveMessage['id'], equals(13));
        expect(saveMessage.containsKey('result'), isTrue);
      },
    );
  });
}
