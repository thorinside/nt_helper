import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nt_helper/chat/models/llm_types.dart';
import 'package:nt_helper/chat/providers/anthropic_provider.dart';

void main() {
  group('AnthropicProvider', () {
    test('sends system prompt as content-block array with cache_control',
        () async {
      Map<String, dynamic>? capturedBody;

      final provider = AnthropicProvider(
        apiKey: 'test-key',
        model: 'claude-sonnet-4-20250514',
        client: MockClient((request) async {
          capturedBody = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response(
            jsonEncode({
              'content': [
                {'type': 'text', 'text': 'Hello'},
              ],
              'stop_reason': 'end_turn',
              'usage': {'input_tokens': 10, 'output_tokens': 5},
            }),
            200,
          );
        }),
      );

      await provider.sendMessages(
        messages: [LlmMessage.user('Hi')],
        tools: const [],
        systemPrompt: 'You are helpful.',
      );

      expect(capturedBody!['system'], isList);
      final systemBlocks = capturedBody!['system'] as List;
      expect(systemBlocks, hasLength(1));
      expect(systemBlocks[0]['type'], 'text');
      expect(systemBlocks[0]['text'], 'You are helpful.');
      expect(systemBlocks[0]['cache_control'], {'type': 'ephemeral'});
    });

    test('adds cache_control to last tool definition', () async {
      Map<String, dynamic>? capturedBody;

      final provider = AnthropicProvider(
        apiKey: 'test-key',
        model: 'claude-sonnet-4-20250514',
        client: MockClient((request) async {
          capturedBody = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response(
            jsonEncode({
              'content': [
                {'type': 'text', 'text': 'OK'},
              ],
              'stop_reason': 'end_turn',
              'usage': {'input_tokens': 10, 'output_tokens': 5},
            }),
            200,
          );
        }),
      );

      await provider.sendMessages(
        messages: [LlmMessage.user('Hi')],
        tools: const [
          LlmToolDefinition(
            name: 'tool_a',
            description: 'First tool',
            inputSchema: {'properties': {}},
          ),
          LlmToolDefinition(
            name: 'tool_b',
            description: 'Second tool',
            inputSchema: {'properties': {}},
          ),
        ],
      );

      final tools = capturedBody!['tools'] as List;
      expect(tools, hasLength(2));
      expect(tools[0].containsKey('cache_control'), isFalse);
      expect(tools[1]['cache_control'], {'type': 'ephemeral'});
    });

    test('parseResponse extracts cache token fields', () {
      final provider = AnthropicProvider(
        apiKey: 'test-key',
        model: 'claude-sonnet-4-20250514',
      );

      final response = provider.parseResponse({
        'content': [
          {'type': 'text', 'text': 'Hello'},
        ],
        'stop_reason': 'end_turn',
        'usage': {
          'input_tokens': 50,
          'output_tokens': 20,
          'cache_creation_input_tokens': 1000,
          'cache_read_input_tokens': 500,
        },
      });

      expect(response.usage, isNotNull);
      expect(response.usage!.inputTokens, 50);
      expect(response.usage!.outputTokens, 20);
      expect(response.usage!.cacheCreationInputTokens, 1000);
      expect(response.usage!.cacheReadInputTokens, 500);
    });

    test('parseResponse defaults cache fields to 0 when absent', () {
      final provider = AnthropicProvider(
        apiKey: 'test-key',
        model: 'claude-sonnet-4-20250514',
      );

      final response = provider.parseResponse({
        'content': [
          {'type': 'text', 'text': 'Hello'},
        ],
        'stop_reason': 'end_turn',
        'usage': {
          'input_tokens': 50,
          'output_tokens': 20,
        },
      });

      expect(response.usage, isNotNull);
      expect(response.usage!.cacheCreationInputTokens, 0);
      expect(response.usage!.cacheReadInputTokens, 0);
    });

    test('empty tools list does not add cache_control', () async {
      Map<String, dynamic>? capturedBody;

      final provider = AnthropicProvider(
        apiKey: 'test-key',
        model: 'claude-sonnet-4-20250514',
        client: MockClient((request) async {
          capturedBody = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response(
            jsonEncode({
              'content': [
                {'type': 'text', 'text': 'OK'},
              ],
              'stop_reason': 'end_turn',
              'usage': {'input_tokens': 10, 'output_tokens': 5},
            }),
            200,
          );
        }),
      );

      await provider.sendMessages(
        messages: [LlmMessage.user('Hi')],
        tools: const [],
      );

      expect(capturedBody!.containsKey('tools'), isFalse);
    });
  });
}
