// Opt-in only: spends provider quota and reads the connected NT's screen.
// flutter test --dart-define=NT_GENKIT_LIVE=true hardware_test/genkit_chat_live_smoke_test.dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:nt_helper/chat/models/llm_types.dart';
import 'package:nt_helper/chat/providers/openai_subscription_provider.dart';
import 'package:nt_helper/chat/providers/provider_streaming.dart' show sseData;
import 'package:nt_helper/chat/services/chat_service.dart';
import 'package:nt_helper/chat/services/codex_auth_service.dart';
import 'package:nt_helper/chat/services/model_catalog_service.dart';
import 'package:nt_helper/chat/services/tool_bridge_service.dart';
import 'package:nt_helper/mcp/tool_registry.dart';

class _UnusedRegistry extends Mock implements ToolRegistry {}

/// Read-only bridge to the already-running app. Its MIDI authority remains the
/// only hardware connection. No app restart, preset write, or gesture is possible.
class _LiveBridge extends ToolBridgeService {
  _LiveBridge() : super(_UnusedRegistry());
  final client = http.Client();
  String? session;
  var nextId = 0;
  final definitions = <LlmToolDefinition>[];
  static const allowed = {'remote_state', 'show_preset', 'show_screen'};
  final endpoint = Uri.parse(
    const String.fromEnvironment(
      'NT_GENKIT_MCP_URL',
      defaultValue: 'http://127.0.0.1:3847/mcp',
    ),
  );

  Future<Map<String, dynamic>> rpc(
    String method,
    Map<String, dynamic> params, {
    bool notification = false,
  }) async {
    final request = http.Request('POST', endpoint)
      ..headers.addAll({
        'content-type': 'application/json',
        'accept': 'application/json, text/event-stream',
        'mcp-session-id': ?session,
        'mcp-protocol-version': '2025-06-18',
      })
      ..body = jsonEncode({
        'jsonrpc': '2.0',
        if (!notification) 'id': ++nextId,
        'method': method,
        'params': params,
      });
    final response = await client.send(request);
    session = response.headers['mcp-session-id'] ?? session;
    if (response.statusCode == 202) {
      await response.stream.drain<void>();
      return {};
    }
    if (response.statusCode != 200) {
      throw StateError('MCP HTTP ${response.statusCode}');
    }
    final Map<String, dynamic> message;
    if ((response.headers['content-type'] ?? '').contains(
      'text/event-stream',
    )) {
      message =
          jsonDecode(
                await sseData(
                  response.stream,
                ).where((data) => data.trim().isNotEmpty).first,
              )
              as Map<String, dynamic>;
    } else {
      message =
          jsonDecode(await response.stream.bytesToString())
              as Map<String, dynamic>;
    }
    if (message['error'] != null) throw StateError('MCP rejected $method');
    return Map<String, dynamic>.from(message['result'] as Map? ?? {});
  }

  Future<void> initialize() async {
    await rpc('initialize', {
      'protocolVersion': '2025-06-18',
      'capabilities': {},
      'clientInfo': {'name': 'nt-genkit-readonly-smoke', 'version': '1'},
    });
    await rpc('notifications/initialized', {}, notification: true);
    final listing = await rpc('tools/list', {});
    for (final tool in listing['tools'] as List) {
      if (!allowed.contains(tool['name'])) continue;
      definitions.add(
        LlmToolDefinition(
          name: tool['name'] as String,
          description: tool['description'] as String,
          inputSchema: tool['name'] == 'show_screen'
              ? {
                  'type': 'object',
                  'properties': {},
                  'additionalProperties': false,
                }
              : Map<String, dynamic>.from(tool['inputSchema'] as Map),
        ),
      );
    }
    if (definitions.length != allowed.length) {
      throw StateError('Required read-only NT tools unavailable');
    }
  }

  @override
  List<LlmToolDefinition> get toolDefinitions => definitions;
  @override
  Future<void> cancelRemoteControl() async {
    /* This bridge cannot acquire holds. */
  }
  @override
  Future<String> executeTool(
    String name,
    Map<String, dynamic> arguments,
  ) async {
    if (!allowed.contains(name)) {
      throw StateError('Only read-only NT tools are allowed');
    }
    if (name == 'show_screen' && arguments.isNotEmpty) {
      throw StateError('Screen observation must not switch display modes');
    }
    final result = await rpc('tools/call', {
      'name': name,
      'arguments': arguments,
    });
    if (result['isError'] == true) throw StateError('NT tool failed: $name');
    final content = result['content'] as List;
    final block = Map<String, dynamic>.from(content.single as Map);
    if (block['type'] == 'image') {
      return jsonEncode({'type': block['mimeType'], 'data': block['data']});
    }
    return block['text'] as String;
  }

  Future<void> close() async {
    if (session != null) {
      try {
        await client.delete(endpoint, headers: {'mcp-session-id': session!});
      } catch (_) {}
    }
    client.close();
  }
}

void main() {
  test(
    'Genkit + real Codex auth + existing app MCP read-only NT conversation',
    () async {
      final overrides = HttpOverrides.current;
      HttpOverrides.global = null;
      final bridge = _LiveBridge();
      OpenAISubscriptionProvider? provider;
      try {
        await bridge.initialize();
        var model = const String.fromEnvironment('NT_GENKIT_MODEL');
        if (model.isEmpty) {
          final auth = CodexAuthService();
          final catalog = OpenAISubscriptionModelCatalog(authService: auth);
          try {
            final models = await catalog.fetchModels(allowAuthRefresh: false);
            if (models.isEmpty) {
              throw StateError('No subscription models available');
            }
            model = models.first.id;
          } finally {
            catalog.dispose();
            auth.dispose();
          }
        }
        provider = OpenAISubscriptionProvider(
          model: model,
          allowAuthRefresh: false,
        );
        final service = ChatService(
          provider: provider,
          toolBridge: bridge,
          systemPrompt:
              'You are validating an NT assistant. Use remote_state, then show_preset, then show_screen with empty arguments, in that order. '
              'Only observe. Report the preset name/slot count and an exact phrase visible in the screenshot. '
              'Sending or commanded state is not hardware acknowledgement. Keep the answer brief.',
        );
        final events = await service
            .runAgenticLoop([
              LlmMessage.user(
                'Inspect the connected NT now using the three tools; describe what you actually see.',
              ),
            ])
            .timeout(const Duration(seconds: 90))
            .toList();
        final errors = events
            .whereType<ChatLoopError>()
            .map((e) => e.message)
            .toList();
        expect(errors, isEmpty, reason: errors.join('\n'));
        expect(
          events.whereType<ChatLoopToolCall>().map((e) => e.toolCall.name),
          containsAllInOrder(['remote_state', 'show_preset', 'show_screen']),
        );
        expect(
          events.whereType<ChatLoopToolResult>().any(
            (e) => e.imageBase64 != null,
          ),
          isTrue,
        );
        expect(events.whereType<ChatLoopTextDelta>(), isNotEmpty);
        final answer = events.whereType<ChatLoopAssistantMessage>().singleWhere(
          (e) => e.isFinal,
        );
        expect(answer.content, isNotEmpty);
        // Only the final observation, never credentials or raw screenshots.
        // ignore: avoid_print
        print('Live Genkit NT observation: ${answer.content}');
      } finally {
        await bridge.close();
        provider?.dispose();
        HttpOverrides.global = overrides;
      }
    },
    skip: !const bool.fromEnvironment('NT_GENKIT_LIVE'),
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
