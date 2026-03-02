import 'dart:async';
import 'dart:convert';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nt_helper/chat/cubit/chat_state.dart';
import 'package:nt_helper/chat/models/chat_message.dart';
import 'package:nt_helper/chat/models/chat_settings.dart';
import 'package:nt_helper/chat/models/llm_types.dart';
import 'package:nt_helper/chat/providers/anthropic_provider.dart';
import 'package:nt_helper/chat/providers/llm_provider.dart';
import 'package:nt_helper/chat/providers/openai_provider.dart';
import 'package:nt_helper/chat/services/chat_service.dart';
import 'package:nt_helper/chat/services/system_prompt.dart';
import 'package:nt_helper/chat/services/tool_bridge_service.dart';
import 'package:nt_helper/mcp/tool_registry.dart';

class ChatCubit extends Cubit<ChatState> {
  final ToolRegistry _toolRegistry;
  StreamSubscription<dynamic>? _loopSubscription;
  LlmProvider? _activeProvider;

  // Accumulated LLM message history for the agentic loop
  final List<LlmMessage> _llmHistory = [];

  // Length of _llmHistory before the current loop started, used to restore
  // clean state if the loop is cancelled mid-execution.
  int _historyLengthBeforeLoop = 0;

  ChatCubit({required ToolRegistry toolRegistry})
      : _toolRegistry = toolRegistry,
        super(const ChatReady());

  void sendMessage(String text, ChatSettings settings) {
    if (text.trim().isEmpty) return;

    final currentState = state;
    if (currentState is! ChatReady || currentState.isProcessing) return;

    // Handle /context command locally — no API call needed
    if (text.trim().toLowerCase() == '/context') {
      _handleContextCommand(currentState);
      return;
    }

    if (!settings.hasApiKey) {
      emit(const ChatError('No API key configured. Open chat settings to add one.'));
      return;
    }

    // Add user message to UI
    final userMessage = ChatMessage.user(text.trim());
    final messages = [...currentState.messages, userMessage];
    emit(currentState.copyWith(messages: messages, isProcessing: true));

    // Add to LLM history
    _historyLengthBeforeLoop = _llmHistory.length;
    _llmHistory.add(LlmMessage.user(text.trim()));

    // Create provider (disposing the previous one first)
    _activeProvider?.dispose();
    _activeProvider = _createProvider(settings);
    final toolBridge = ToolBridgeService(_toolRegistry);
    final chatService = ChatService(
      provider: _activeProvider!,
      toolBridge: toolBridge,
      systemPrompt: distingNtSystemPrompt,
    );

    // Run agentic loop
    _loopSubscription?.cancel();
    _loopSubscription =
        chatService.runAgenticLoop(_llmHistory).listen(_handleLoopEvent);
  }

  void _handleLoopEvent(ChatLoopEvent event) {
    final currentState = state;
    if (currentState is! ChatReady) return;

    switch (event) {
      case ChatLoopThinking():
        // Don't add duplicate thinking indicators
        break;
      case ChatLoopToolCall(toolCall: final tc):
        final msg = ChatMessage.toolCall(
          toolName: tc.name,
          toolCallId: tc.id,
          arguments: tc.arguments,
        );
        emit(currentState.copyWith(
          messages: [...currentState.messages, msg],
          currentToolName: tc.name,
        ));
      case ChatLoopToolResult(
          toolCallId: final id,
          toolName: final name,
          result: final result
        ):
        final msg = ChatMessage.toolResult(
          toolName: name,
          toolCallId: id,
          result: result,
        );
        emit(currentState.copyWith(
          messages: [...currentState.messages, msg],
          clearToolName: true,
        ));
      case ChatLoopAssistantMessage(
          content: final content,
          usage: final usage,
          isFinal: final isFinal,
          finalHistory: final finalHistory,
        ):
        final messages = content.isNotEmpty
            ? [...currentState.messages, ChatMessage.assistant(content)]
            : currentState.messages;
        // On final message, replace history atomically with the complete
        // snapshot from the service (includes all tool calls/results and the
        // final assistant message).
        if (isFinal) {
          final newHistory = finalHistory ?? [LlmMessage.assistant(content)];
          _llmHistory.clear();
          _llmHistory.addAll(newHistory);
        }
        emit(currentState.copyWith(
          messages: messages,
          isProcessing: isFinal ? false : null,
          clearToolName: isFinal,
          totalInputTokens:
              currentState.totalInputTokens + (usage?.inputTokens ?? 0),
          totalOutputTokens:
              currentState.totalOutputTokens + (usage?.outputTokens ?? 0),
        ));
      case ChatLoopError(message: final message):
        _llmHistory.removeRange(_historyLengthBeforeLoop, _llmHistory.length);
        final msg = ChatMessage.assistant('Error: $message');
        emit(currentState.copyWith(
          messages: [...currentState.messages, msg],
          isProcessing: false,
          clearToolName: true,
        ));
    }
  }

  void _handleContextCommand(ChatReady currentState) {
    final contextDump = _serializeContext();
    final userMsg = ChatMessage.user('/context');
    final systemMsg = ChatMessage.system(contextDump);
    emit(currentState.copyWith(
      messages: [...currentState.messages, userMsg, systemMsg],
    ));
  }

  String _serializeContext() {
    final buffer = StringBuffer();
    buffer.writeln('=== LLM Context (${_llmHistory.length} messages) ===');
    buffer.writeln();

    for (int i = 0; i < _llmHistory.length; i++) {
      final msg = _llmHistory[i];
      buffer.writeln('--- Message ${i + 1}: ${msg.role.name.toUpperCase()} ---');

      if (msg.toolCalls != null && msg.toolCalls!.isNotEmpty) {
        if (msg.content != null && msg.content!.isNotEmpty) {
          buffer.writeln('Text: ${msg.content}');
        }
        for (final tc in msg.toolCalls!) {
          buffer.writeln('Tool Call: ${tc.name} (id: ${tc.id})');
          buffer.writeln('Arguments: ${_prettyJson(tc.arguments)}');
        }
      } else if (msg.role == LlmRole.tool) {
        buffer.writeln('Tool: ${msg.toolName} (id: ${msg.toolCallId})');
        buffer.writeln('Result: ${_truncateToolResult(msg.content ?? '')}');
      } else {
        buffer.writeln(msg.content ?? '(empty)');
      }
      buffer.writeln();
    }

    buffer.writeln('=== End Context ===');
    return buffer.toString();
  }

  static String _prettyJson(Map<String, dynamic> json) {
    try {
      const encoder = JsonEncoder.withIndent('  ');
      return encoder.convert(json);
    } catch (_) {
      return json.toString();
    }
  }

  static String _truncateToolResult(String result) {
    if (result.length <= 2000) return result;
    return '${result.substring(0, 2000)}\n... (${result.length} chars total, truncated for display)';
  }

  void clearChat() {
    _loopSubscription?.cancel();
    _llmHistory.clear();
    emit(const ChatReady());
  }

  void cancelProcessing() {
    _loopSubscription?.cancel();
    _llmHistory.removeRange(_historyLengthBeforeLoop, _llmHistory.length);
    final currentState = state;
    if (currentState is ChatReady) {
      emit(currentState.copyWith(
        isProcessing: false,
        clearToolName: true,
      ));
    }
  }

  void dismissError() {
    _llmHistory.clear();
    emit(const ChatReady());
  }

  LlmProvider _createProvider(ChatSettings settings) {
    switch (settings.provider) {
      case LlmProviderType.anthropic:
        return AnthropicProvider(
          apiKey: settings.anthropicApiKey!,
          model: settings.anthropicModel,
        );
      case LlmProviderType.openai:
        return OpenAIProvider(
          apiKey: settings.openaiApiKey!,
          model: settings.openaiModel,
          baseUrl: settings.openaiBaseUrl,
        );
    }
  }

  @override
  Future<void> close() {
    _loopSubscription?.cancel();
    _activeProvider?.dispose();
    return super.close();
  }
}
