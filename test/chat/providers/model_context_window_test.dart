import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nt_helper/chat/providers/anthropic_provider.dart';
import 'package:nt_helper/chat/providers/model_context_window.dart';
import 'package:nt_helper/chat/providers/openai_provider.dart';
import 'package:nt_helper/chat/providers/openai_subscription_provider.dart';

void main() {
  group('Model context window resolution', () {
    test(
      'OpenAI provider uses compatible model metadata when available',
      () async {
        late http.Request capturedRequest;
        final provider = OpenAIProvider(
          apiKey: 'test-key',
          model: 'custom-model',
          baseUrl: 'https://example.test/v1/chat/completions',
          client: MockClient((request) async {
            capturedRequest = request;
            return http.Response(
              jsonEncode({'id': 'custom-model', 'context_window': 222000}),
              200,
            );
          }),
        );

        final contextWindow = await provider.resolveContextWindowTokens();

        expect(contextWindow, 222000);
        expect(capturedRequest.method, 'GET');
        expect(
          capturedRequest.url.toString(),
          'https://example.test/v1/models/custom-model',
        );
        expect(capturedRequest.headers['Authorization'], 'Bearer test-key');
      },
    );

    test('OpenAI subscription provider infers known model families', () async {
      final provider = OpenAISubscriptionProvider(
        model: 'gpt-5.4-mini',
        allowAuthRefresh: false,
      );

      expect(await provider.resolveContextWindowTokens(), 400000);
      provider.dispose();
    });

    test('Anthropic provider uses Models API max input tokens', () async {
      late http.Request capturedRequest;
      final provider = AnthropicProvider(
        apiKey: 'test-key',
        model: 'claude-test-model',
        client: MockClient((request) async {
          capturedRequest = request;
          return http.Response(
            jsonEncode({
              'id': 'claude-test-model',
              'max_input_tokens': 333000,
              'max_tokens': 64000,
            }),
            200,
          );
        }),
      );

      final contextWindow = await provider.resolveContextWindowTokens();

      expect(contextWindow, 333000);
      expect(capturedRequest.method, 'GET');
      expect(
        capturedRequest.url.toString(),
        'https://api.anthropic.com/v1/models/claude-test-model',
      );
      expect(capturedRequest.headers['x-api-key'], 'test-key');
      expect(capturedRequest.headers['anthropic-version'], '2023-06-01');
      provider.dispose();
    });

    test('Anthropic resolver falls back by provider model family', () {
      expect(
        AnthropicContextWindowResolver.infer('claude-sonnet-4-6'),
        1000000,
      );
      expect(
        AnthropicContextWindowResolver.infer('claude-haiku-4-5-20251001'),
        200000,
      );
    });
  });
}
