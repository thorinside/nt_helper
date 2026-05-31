import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:nt_helper/chat/models/llm_types.dart';
import 'package:nt_helper/chat/providers/openai_subscription_provider.dart';
import 'package:nt_helper/chat/services/codex_auth_service.dart';

class _FakeAuthService extends CodexAuthService {
  int refreshCount = 0;
  CodexAuthSnapshot snapshot;

  _FakeAuthService(this.snapshot) : super(authFilePath: 'unused');

  @override
  Future<CodexAuthSnapshot> loadAuth() async => snapshot;

  @override
  Future<CodexAuthSnapshot> refreshAuth() async {
    refreshCount++;
    snapshot = const CodexAuthSnapshot(
      accessToken: 'new-token',
      refreshToken: 'new-refresh',
      accountId: 'new-account',
    );
    return snapshot;
  }

  @override
  void dispose() {}
}

class _QueueClient extends http.BaseClient {
  final List<http.StreamedResponse Function(http.BaseRequest request)>
  responses;
  final requests = <http.Request>[];

  _QueueClient(this.responses);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    if (request is http.Request) requests.add(request);
    return responses.removeAt(0)(request);
  }
}

void main() {
  group('OpenAISubscriptionProvider', () {
    test('parses text, tool calls, and usage from Responses SSE', () async {
      final auth = _FakeAuthService(
        const CodexAuthSnapshot(
          accessToken: 'token',
          refreshToken: 'refresh',
          accountId: 'account',
        ),
      );
      final client = _QueueClient([
        (_) => _sseResponse([
          {'type': 'response.output_text.delta', 'delta': 'thinking '},
          {
            'type': 'response.output_item.done',
            'item': {
              'type': 'function_call',
              'call_id': 'call_1',
              'name': 'show_preset',
              'arguments': '{"slot":1}',
            },
          },
          {
            'type': 'response.completed',
            'response': {
              'usage': {'input_tokens': 10, 'output_tokens': 2},
            },
          },
        ]),
      ]);
      final provider = OpenAISubscriptionProvider(
        model: 'gpt-5.4-mini',
        allowAuthRefresh: false,
        authService: auth,
        client: client,
      );
      addTearDown(provider.dispose);

      final response = await provider.sendMessages(
        messages: [LlmMessage.user('hello')],
        tools: const [
          LlmToolDefinition(
            name: 'show_preset',
            description: 'Show preset',
            inputSchema: {
              'properties': {
                'slot': {'type': 'integer'},
              },
            },
          ),
        ],
      );

      expect(response.content, 'thinking ');
      expect(response.isComplete, isFalse);
      expect(response.toolCalls, hasLength(1));
      expect(response.toolCalls.single.id, 'call_1');
      expect(response.toolCalls.single.name, 'show_preset');
      expect(response.toolCalls.single.arguments, {'slot': 1});
      expect(response.usage?.inputTokens, 10);
      expect(response.usage?.outputTokens, 2);

      final body =
          jsonDecode(client.requests.single.body) as Map<String, dynamic>;
      expect(body['model'], 'gpt-5.4-mini');
      expect(body['stream'], isTrue);
      expect((body['tools'] as List).single['type'], 'function');
      expect(client.requests.single.headers['Authorization'], 'Bearer token');
      expect(client.requests.single.headers['ChatGPT-Account-ID'], 'account');
    });

    test('refreshes on 401 and retries once when allowed', () async {
      final auth = _FakeAuthService(
        const CodexAuthSnapshot(
          accessToken: 'old-token',
          refreshToken: 'old-refresh',
          accountId: 'old-account',
        ),
      );
      final client = _QueueClient([
        (_) => _textResponse(401, '{"error":{"message":"expired"}}'),
        (_) => _sseResponse([
          {'type': 'response.output_text.delta', 'delta': 'ok'},
          {
            'type': 'response.completed',
            'response': {
              'usage': {'input_tokens': 1, 'output_tokens': 1},
            },
          },
        ]),
      ]);
      final provider = OpenAISubscriptionProvider(
        model: 'gpt-5.4-mini',
        allowAuthRefresh: true,
        authService: auth,
        client: client,
      );
      addTearDown(provider.dispose);

      final response = await provider.sendMessages(
        messages: [LlmMessage.user('hello')],
        tools: const [],
      );

      expect(response.content, 'ok');
      expect(auth.refreshCount, 1);
      expect(client.requests, hasLength(2));
      expect(
        client.requests.first.headers['Authorization'],
        'Bearer old-token',
      );
      expect(client.requests.last.headers['Authorization'], 'Bearer new-token');
    });
  });
}

http.StreamedResponse _sseResponse(List<Map<String, dynamic>> events) {
  final body = events.map((e) => 'data: ${jsonEncode(e)}\n\n').join();
  return _textResponse(200, body);
}

http.StreamedResponse _textResponse(int statusCode, String body) {
  return http.StreamedResponse(
    Stream.value(utf8.encode(body)),
    statusCode,
    headers: const {'content-type': 'text/event-stream'},
  );
}
