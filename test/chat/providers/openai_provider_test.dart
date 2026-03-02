import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nt_helper/chat/models/llm_types.dart';
import 'package:nt_helper/chat/providers/openai_provider.dart';

void main() {
  group('OpenAIProvider parsing', () {
    test('accepts tool arguments returned as an object', () async {
      final provider = OpenAIProvider(
        apiKey: 'test-key',
        model: 'gpt-5-nano',
        client: MockClient((_) async {
          return http.Response(
            jsonEncode({
              'choices': [
                {
                  'message': {
                    'role': 'assistant',
                    'content': null,
                    'tool_calls': [
                      {
                        'id': 'call_1',
                        'type': 'function',
                        'function': {
                          'name': 'search_algorithms',
                          'arguments': {'query': 'lfo'},
                        },
                      },
                    ],
                  },
                  'finish_reason': 'tool_calls',
                },
              ],
              'usage': {'prompt_tokens': 12, 'completion_tokens': 5},
            }),
            200,
          );
        }),
      );

      final response = await provider.sendMessages(
        messages: [LlmMessage.user('Find LFO algorithms')],
        tools: const [],
      );

      expect(response.hasToolCalls, isTrue);
      expect(response.toolCalls, hasLength(1));
      expect(response.toolCalls.single.name, 'search_algorithms');
      expect(response.toolCalls.single.arguments, {'query': 'lfo'});
      expect(response.isComplete, isFalse);
    });

    test('concatenates text when content is returned as parts array', () async {
      final provider = OpenAIProvider(
        apiKey: 'test-key',
        model: 'gpt-5-nano',
        client: MockClient((_) async {
          return http.Response(
            jsonEncode({
              'choices': [
                {
                  'message': {
                    'role': 'assistant',
                    'content': [
                      {'type': 'text', 'text': 'Hello '},
                      {'type': 'text', 'text': 'world'},
                    ],
                  },
                  'finish_reason': 'stop',
                },
              ],
              'usage': {'prompt_tokens': 3, 'completion_tokens': 2},
            }),
            200,
          );
        }),
      );

      final response = await provider.sendMessages(
        messages: [LlmMessage.user('Say hello')],
        tools: const [],
      );

      expect(response.content, 'Hello world');
      expect(response.hasToolCalls, isFalse);
      expect(response.isComplete, isTrue);
    });

    test('treats non-object decoded tool arguments as empty object', () async {
      final provider = OpenAIProvider(
        apiKey: 'test-key',
        model: 'gpt-5-nano',
        client: MockClient((_) async {
          return http.Response(
            jsonEncode({
              'choices': [
                {
                  'message': {
                    'role': 'assistant',
                    'tool_calls': [
                      {
                        'id': 'call_2',
                        'type': 'function',
                        'function': {'name': 'show_preset', 'arguments': '[]'},
                      },
                    ],
                  },
                  'finish_reason': 'tool_calls',
                },
              ],
            }),
            200,
          );
        }),
      );

      final response = await provider.sendMessages(
        messages: [LlmMessage.user('Show preset')],
        tools: const [],
      );

      expect(response.hasToolCalls, isTrue);
      expect(response.toolCalls.single.arguments, isEmpty);
    });
  });
}
