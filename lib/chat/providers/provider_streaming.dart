import 'dart:convert';
import 'package:nt_helper/chat/providers/openai_provider_metadata.dart';

import 'package:genkit/genkit.dart' show CancellationToken;
import 'package:http/http.dart' as http;
import 'package:nt_helper/chat/models/llm_types.dart';
import 'package:nt_helper/chat/providers/anthropic_provider.dart'
    show LlmApiException;

/// Abort the actual HTTP request, not just its UI subscription. No tool or
/// hardware operation is retried here; retry policy belongs to the model layer.
Future<http.StreamedResponse> sendStreamingRequest({
  required http.Client client,
  required Uri url,
  required Map<String, String> headers,
  required Map<String, dynamic> body,
  CancellationToken? cancel,
}) async {
  cancel?.throwIfCancelled();
  final request =
      http.AbortableRequest('POST', url, abortTrigger: cancel?.whenCancelled)
        ..headers.addAll(headers)
        ..body = jsonEncode(body);
  final response = await client.send(request);
  cancel?.throwIfCancelled();
  if (response.statusCode < 200 || response.statusCode >= 300) {
    final text = await response.stream.bytesToString();
    String message = 'Provider request failed';
    try {
      final json = jsonDecode(text);
      if (json is Map) {
        message = json['error']?['message'] as String? ?? message;
      }
    } catch (_) {
      /* Avoid reflecting arbitrary response bodies or secrets. */
    }
    throw LlmApiException(
      message,
      statusCode: response.statusCode,
      retryAfterSeconds: int.tryParse(response.headers['retry-after'] ?? ''),
    );
  }
  return response;
}

Stream<String> sseData(Stream<List<int>> stream) async* {
  // Split only on LF/CRLF: U+2028/U+2029 can legitimately occur in JSON text.
  var pending = '';
  final data = <String>[];
  await for (final chunk in stream.transform(utf8.decoder)) {
    pending += chunk;
    while (pending.contains('\n')) {
      final end = pending.indexOf('\n');
      var line = pending.substring(0, end);
      pending = pending.substring(end + 1);
      if (line.endsWith('\r')) line = line.substring(0, line.length - 1);
      if (line.isEmpty) {
        if (data.isNotEmpty) {
          yield data.join('\n');
          data.clear();
        }
      } else if (line.startsWith('data:')) {
        final value = line.substring(5);
        data.add(value.startsWith(' ') ? value.substring(1) : value);
      }
    }
  }
  if (pending.startsWith('data:')) data.add(pending.substring(5).trimLeft());
  if (data.isNotEmpty) yield data.join('\n');
}

int streamInt(Object? value) =>
    value is num ? value.toInt() : int.tryParse('$value') ?? 0;

Future<LlmResponse> readOpenAIStream(
  http.StreamedResponse response, {
  required void Function(String) onTextDelta,
  CancellationToken? cancel,
  required LlmResponse Function(Map<String, dynamic>) parseJson,
}) async {
  if (!(response.headers['content-type'] ?? '').contains('text/event-stream')) {
    final result = parseJson(
      jsonDecode(await response.stream.bytesToString()) as Map<String, dynamic>,
    );
    cancel?.throwIfCancelled();
    if (result.content?.isNotEmpty ?? false) onTextDelta(result.content!);
    return result;
  }
  final text = StringBuffer();
  final calls = <int, Map<String, dynamic>>{};
  final messageExtras = <String, dynamic>{};
  Map<String, dynamic>? usage;
  var finished = false;
  String? finishReason;
  await for (final data in sseData(response.stream)) {
    cancel?.throwIfCancelled();
    if (data == '[DONE]') break;
    final event = jsonDecode(data) as Map<String, dynamic>;
    if (event['error'] != null) {
      throw LlmApiException('Provider stream failed.');
    }
    if (event['usage'] is Map) {
      usage = Map<String, dynamic>.from(event['usage'] as Map);
    }
    for (final choice in event['choices'] as List? ?? const []) {
      if (choice['index'] != null && choice['index'] != 0) continue;
      if (choice['finish_reason'] != null) {
        finishReason = choice['finish_reason'] as String;
        if (finishReason == 'length') {
          throw LlmApiException('Model output was truncated.');
        }
        finished = true;
      }
      final delta = Map<String, dynamic>.from(
        choice['delta'] as Map? ?? const {},
      );
      mergeOpenAIExtras(messageExtras, openAIMessageExtras(delta));
      final content = delta['content'];
      if (content is String && content.isNotEmpty) {
        text.write(content);
        onTextDelta(content);
      }
      for (final raw in delta['tool_calls'] as List? ?? const []) {
        final call = Map<String, dynamic>.from(raw as Map);
        final current = calls.putIfAbsent(
          streamInt(call['index']),
          () => {
            'id': '',
            'type': 'function',
            'function': <String, dynamic>{'name': '', 'arguments': ''},
          },
        );
        if (call['id'] is String) current['id'] = call['id'];
        mergeOpenAIExtras(current, openAIToolExtras(call));
        final function = call['function'] as Map?;
        final target = Map<String, dynamic>.from(current['function'] as Map);
        if (function?['name'] is String) {
          target['name'] = '${target['name']}${function!['name']}';
        }
        if (function?['arguments'] is String) {
          target['arguments'] =
              '${target['arguments']}${function!['arguments']}';
        }
        current['function'] = target;
      }
    }
  }
  cancel?.throwIfCancelled();
  if (!finished) {
    throw LlmApiException('Provider stream ended before completion.');
  }
  // One parser owns both buffered and streamed responses, including opaque
  // tool signatures and OpenRouter reasoning details required on later turns.
  return parseJson({
    'choices': [
      {
        'index': 0,
        'finish_reason': finishReason,
        'message': {
          'role': 'assistant',
          'content': text.isEmpty ? null : text.toString(),
          ...messageExtras,
          if (calls.isNotEmpty)
            'tool_calls': [
              for (final index in calls.keys.toList()..sort()) calls[index],
            ],
        },
      },
    ],
    'usage': ?usage,
  });
}

Future<LlmResponse> readAnthropicStream(
  http.StreamedResponse response, {
  required void Function(String) onTextDelta,
  CancellationToken? cancel,
  required LlmResponse Function(Map<String, dynamic>) parseJson,
}) async {
  if (!(response.headers['content-type'] ?? '').contains('text/event-stream')) {
    final value = parseJson(
      jsonDecode(await response.stream.bytesToString()) as Map<String, dynamic>,
    );
    cancel?.throwIfCancelled();
    if (value.content?.isNotEmpty ?? false) onTextDelta(value.content!);
    return value;
  }
  final blocks = <int, Map<String, dynamic>>{};
  final fragments = <int, StringBuffer>{};
  final text = StringBuffer();
  final usage = <String, dynamic>{};
  var finished = false;
  await for (final data in sseData(response.stream)) {
    cancel?.throwIfCancelled();
    final event = jsonDecode(data) as Map<String, dynamic>;
    switch (event['type']) {
      case 'message_start':
        usage.addAll(
          Map<String, dynamic>.from(
            event['message']?['usage'] as Map? ?? const {},
          ),
        );
      case 'content_block_start':
        final index = streamInt(event['index']);
        final block = Map<String, dynamic>.from(event['content_block'] as Map);
        blocks[index] = block;
        if (block['type'] == 'text' && block['text'] is String) {
          final initial = block['text'] as String;
          text.write(initial);
          if (initial.isNotEmpty) onTextDelta(initial);
        }
      case 'content_block_delta':
        final delta = event['delta'] as Map;
        final index = streamInt(event['index']);
        if (delta['type'] == 'text_delta') {
          final value = delta['text'] as String;
          text.write(value);
          onTextDelta(value);
        } else if (delta['type'] == 'input_json_delta') {
          fragments
              .putIfAbsent(index, StringBuffer.new)
              .write(delta['partial_json'] as String);
        }
      case 'message_delta':
        usage.addAll(
          Map<String, dynamic>.from(event['usage'] as Map? ?? const {}),
        );
        if (event['delta']?['stop_reason'] == 'max_tokens') {
          throw LlmApiException('Model output was truncated.');
        }
      case 'message_stop':
        finished = true;
      case 'error':
        throw LlmApiException('Anthropic stream failed.');
    }
  }
  cancel?.throwIfCancelled();
  if (!finished) {
    throw LlmApiException('Anthropic stream ended before completion.');
  }
  return LlmResponse(
    content: text.isEmpty ? null : text.toString(),
    isComplete: !blocks.values.any((b) => b['type'] == 'tool_use'),
    toolCalls: [
      for (final index in blocks.keys.toList()..sort())
        if (blocks[index]!['type'] == 'tool_use')
          LlmToolCall(
            id: blocks[index]!['id'] as String,
            name: blocks[index]!['name'] as String,
            arguments: Map<String, dynamic>.from(
              fragments[index]?.isNotEmpty == true
                  ? jsonDecode(fragments[index]!.toString()) as Map
                  : blocks[index]!['input'] as Map? ?? const {},
            ),
          ),
    ],
    usage: LlmUsage(
      inputTokens: streamInt(usage['input_tokens']),
      outputTokens: streamInt(usage['output_tokens']),
      cacheCreationInputTokens: streamInt(usage['cache_creation_input_tokens']),
      cacheReadInputTokens: streamInt(usage['cache_read_input_tokens']),
    ),
  );
}
