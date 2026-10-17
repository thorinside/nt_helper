import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nt_helper/chat/models/llm_types.dart';
import 'package:nt_helper/chat/providers/llm_provider.dart';
import 'package:nt_helper/chat/services/chat_service.dart';
import 'package:nt_helper/chat/services/tool_bridge_service.dart';
import 'package:nt_helper/mcp/tool_registry.dart';

class _Registry extends Mock implements ToolRegistry {}

class _Provider implements LlmProvider {
  final requests = <List<LlmMessage>>[];
  @override
  String get displayName => 'Genkit scripted integration';
  @override
  void dispose() {}
  @override
  Future<int?> resolveContextWindowTokens() async => 100000;
  @override
  Future<LlmResponse> sendMessages({
    required List<LlmMessage> messages,
    required List<LlmToolDefinition> tools,
    String? systemPrompt,
  }) async {
    requests.add(List.of(messages));
    final name = switch (requests.length) {
      1 => 'remote_state',
      2 => 'show_screen',
      _ => null,
    };
    if (name == null) {
      return const LlmResponse(
        content: 'The screenshot is available.',
        isComplete: true,
      );
    }
    return LlmResponse(
      isComplete: false,
      toolCalls: [
        LlmToolCall(
          id: 'call-${requests.length}',
          name: name,
          namespace: 'functions',
          arguments: {},
        ),
      ],
    );
  }
}

void main() {
  test(
    'actual Genkit tool chain preserves images, namespaces, schemas and authoritative history',
    () async {
      final registry = _Registry();
      const png =
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+aR3sAAAAASUVORK5CYII=';
      when(() => registry.entries).thenReturn([
        for (final name in ['remote_state', 'show_screen'])
          ToolRegistryEntry(
            name: name,
            description: name,
            inputSchema: {
              'type': 'object',
              'properties': {},
              'additionalProperties': false,
            },
            handler: (_) async => 'unused',
          ),
      ]);
      when(() => registry.cancelRemoteControl()).thenAnswer((_) async {});
      when(
        () => registry.executeTool('remote_state', any()),
      ).thenAnswer((_) async => '{"success":true,"available":true}');
      when(
        () => registry.executeTool('show_screen', any()),
      ).thenAnswer((_) async => jsonEncode({'type': 'image/png', 'data': png}));
      final provider = _Provider();
      final service = ChatService(
        provider: provider,
        toolBridge: ToolBridgeService(registry),
        systemPrompt: 'NT assistant',
      );
      final events = await service.runAgenticLoop([
        LlmMessage.user('Inspect the screen'),
      ]).toList();
      expect(events.whereType<ChatLoopError>(), isEmpty);
      expect(events.whereType<ChatLoopToolCall>().map((e) => e.toolCall.name), [
        'remote_state',
        'show_screen',
      ]);
      final finalMessages = provider.requests.last;
      final screenshot = finalMessages.singleWhere(
        (m) => m.toolName == 'show_screen',
      );
      expect(screenshot.hasImage, isTrue);
      expect(screenshot.imageBase64, png);
      expect(screenshot.content, isNot(contains(png)));
      final call = finalMessages
          .where((m) => m.toolCalls?.isNotEmpty ?? false)
          .first
          .toolCalls!
          .single;
      expect(call.namespace, 'functions');
      final completed = events
          .whereType<ChatLoopAssistantMessage>()
          .singleWhere((e) => e.isFinal);
      expect(
        completed.finalHistory!.last.content,
        'The screenshot is available.',
      );
      expect(
        completed.finalHistory!
            .where((m) => m.toolCallId == 'call-2')
            .single
            .hasImage,
        isTrue,
      );
      verify(() => registry.cancelRemoteControl()).called(1);
    },
  );
}
