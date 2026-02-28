import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:nt_helper/chat/models/llm_types.dart';
import 'package:nt_helper/chat/providers/llm_provider.dart';
import 'package:nt_helper/chat/providers/anthropic_provider.dart'
    show LlmApiException;

/// OpenAI Chat Completions API provider.
class OpenAIProvider implements LlmProvider {
  final String apiKey;
  final String model;
  final String baseUrl;
  final http.Client _client;

  static const _defaultBaseUrl = 'https://api.openai.com/v1/chat/completions';

  OpenAIProvider({
    required this.apiKey,
    required this.model,
    String? baseUrl,
    http.Client? client,
  })  : baseUrl = baseUrl ?? _defaultBaseUrl,
        _client = client ?? http.Client();

  @override
  String get displayName => 'OpenAI ($model)';

  @override
  Future<LlmResponse> sendMessages({
    required List<LlmMessage> messages,
    required List<LlmToolDefinition> tools,
    String? systemPrompt,
  }) async {
    final apiMessages = <Map<String, dynamic>>[];

    if (systemPrompt != null) {
      apiMessages.add({'role': 'system', 'content': systemPrompt});
    }

    apiMessages.addAll(_convertMessages(messages));

    final body = <String, dynamic>{
      'model': model,
      'messages': apiMessages,
    };

    if (tools.isNotEmpty) {
      body['tools'] = tools
          .map((t) => {
                'type': 'function',
                'function': {
                  'name': t.name,
                  'description': t.description,
                  'parameters': {
                    'type': 'object',
                    ...t.inputSchema,
                  },
                },
              })
          .toList();
    }

    final response = await _client.post(
      Uri.parse(baseUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode != 200) {
      String errorMessage;
      try {
        final errorBody = jsonDecode(response.body);
        errorMessage =
            errorBody['error']?['message'] as String? ?? 'Unknown API error';
      } on FormatException {
        errorMessage = response.body;
      }
      throw LlmApiException(
        'OpenAI API error (${response.statusCode}): $errorMessage',
      );
    }

    return _parseResponse(jsonDecode(response.body));
  }

  List<Map<String, dynamic>> _convertMessages(List<LlmMessage> messages) {
    final result = <Map<String, dynamic>>[];

    for (final msg in messages) {
      switch (msg.role) {
        case LlmRole.user:
          result.add({'role': 'user', 'content': msg.content!});
        case LlmRole.assistant:
          if (msg.toolCalls != null && msg.toolCalls!.isNotEmpty) {
            final apiMsg = <String, dynamic>{
              'role': 'assistant',
            };
            if (msg.content != null && msg.content!.isNotEmpty) {
              apiMsg['content'] = msg.content!;
            }
            apiMsg['tool_calls'] = msg.toolCalls!
                .map((tc) => {
                      'id': tc.id,
                      'type': 'function',
                      'function': {
                        'name': tc.name,
                        'arguments': jsonEncode(tc.arguments),
                      },
                    })
                .toList();
            result.add(apiMsg);
          } else {
            result.add({'role': 'assistant', 'content': msg.content ?? ''});
          }
        case LlmRole.tool:
          result.add({
            'role': 'tool',
            'tool_call_id': msg.toolCallId!,
            'content': msg.content!,
          });
      }
    }

    return result;
  }

  LlmResponse _parseResponse(Map<String, dynamic> json) {
    final choices = json['choices'] as List<dynamic>;
    if (choices.isEmpty) {
      return const LlmResponse(isComplete: true);
    }

    final choice = choices[0] as Map<String, dynamic>;
    final message = choice['message'] as Map<String, dynamic>;
    final finishReason = choice['finish_reason'] as String?;
    final usage = json['usage'] as Map<String, dynamic>?;

    final textContent = message['content'] as String?;
    final toolCalls = <LlmToolCall>[];

    final rawToolCalls = message['tool_calls'] as List<dynamic>?;
    if (rawToolCalls != null) {
      for (final tc in rawToolCalls) {
        final function = tc['function'] as Map<String, dynamic>;
        final argsString = function['arguments'] as String;
        toolCalls.add(LlmToolCall(
          id: tc['id'] as String,
          name: function['name'] as String,
          arguments: jsonDecode(argsString) as Map<String, dynamic>,
        ));
      }
    }

    return LlmResponse(
      content: textContent,
      toolCalls: toolCalls,
      isComplete: finishReason != 'tool_calls',
      usage: usage != null
          ? LlmUsage(
              inputTokens: usage['prompt_tokens'] as int? ?? 0,
              outputTokens: usage['completion_tokens'] as int? ?? 0,
            )
          : null,
    );
  }

  @override
  void dispose() {
    _client.close();
  }
}
