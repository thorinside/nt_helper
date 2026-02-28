import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:nt_helper/chat/models/llm_types.dart';
import 'package:nt_helper/chat/providers/llm_provider.dart';

/// Anthropic Claude Messages API provider.
class AnthropicProvider implements LlmProvider {
  final String apiKey;
  final String model;
  final http.Client _client;

  static const _baseUrl = 'https://api.anthropic.com/v1/messages';
  static const _apiVersion = '2023-06-01';

  AnthropicProvider({
    required this.apiKey,
    required this.model,
    http.Client? client,
  }) : _client = client ?? http.Client();

  @override
  String get displayName => 'Claude ($model)';

  @override
  Future<LlmResponse> sendMessages({
    required List<LlmMessage> messages,
    required List<LlmToolDefinition> tools,
    String? systemPrompt,
  }) async {
    final body = <String, dynamic>{
      'model': model,
      'max_tokens': 4096,
      'messages': _convertMessages(messages),
    };

    if (systemPrompt != null) {
      body['system'] = systemPrompt;
    }

    if (tools.isNotEmpty) {
      body['tools'] = tools
          .map((t) => {
                'name': t.name,
                'description': t.description,
                'input_schema': {
                  'type': 'object',
                  ...t.inputSchema,
                },
              })
          .toList();
    }

    final response = await _client.post(
      Uri.parse(_baseUrl),
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': apiKey,
        'anthropic-version': _apiVersion,
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
        'Anthropic API error (${response.statusCode}): $errorMessage',
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
            final content = <Map<String, dynamic>>[];
            if (msg.content != null && msg.content!.isNotEmpty) {
              content.add({'type': 'text', 'text': msg.content!});
            }
            for (final tc in msg.toolCalls!) {
              content.add({
                'type': 'tool_use',
                'id': tc.id,
                'name': tc.name,
                'input': tc.arguments,
              });
            }
            result.add({'role': 'assistant', 'content': content});
          } else {
            result.add({'role': 'assistant', 'content': msg.content ?? ''});
          }
        case LlmRole.tool:
          final toolResultBlock = {
            'type': 'tool_result',
            'tool_use_id': msg.toolCallId!,
            'content': msg.content!,
          };
          if (result.isNotEmpty && result.last['role'] == 'user') {
            final lastContent = result.last['content'];
            if (lastContent is List<dynamic>) {
              lastContent.add(toolResultBlock);
              continue;
            }
          }
          result.add({
            'role': 'user',
            'content': <dynamic>[toolResultBlock],
          });
      }
    }

    return result;
  }

  LlmResponse _parseResponse(Map<String, dynamic> json) {
    final stopReason = json['stop_reason'] as String?;
    final content = json['content'] as List<dynamic>? ?? [];
    final usage = json['usage'] as Map<String, dynamic>?;

    String? textContent;
    final toolCalls = <LlmToolCall>[];

    for (final block in content) {
      final type = block['type'] as String;
      if (type == 'text') {
        textContent = (textContent ?? '') + (block['text'] as String);
      } else if (type == 'tool_use') {
        toolCalls.add(LlmToolCall(
          id: block['id'] as String,
          name: block['name'] as String,
          arguments: block['input'] as Map<String, dynamic>,
        ));
      }
    }

    return LlmResponse(
      content: textContent,
      toolCalls: toolCalls,
      isComplete: stopReason != 'tool_use',
      usage: usage != null
          ? LlmUsage(
              inputTokens: usage['input_tokens'] as int? ?? 0,
              outputTokens: usage['output_tokens'] as int? ?? 0,
            )
          : null,
    );
  }

  @override
  void dispose() {
    _client.close();
  }
}

class LlmApiException implements Exception {
  final String message;
  LlmApiException(this.message);

  @override
  String toString() => message;
}
