import 'dart:async';

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

  // Accumulated LLM message history for the agentic loop
  final List<LlmMessage> _llmHistory = [];

  ChatCubit({required ToolRegistry toolRegistry})
      : _toolRegistry = toolRegistry,
        super(const ChatReady());

  void sendMessage(String text, ChatSettings settings) {
    if (text.trim().isEmpty) return;

    final currentState = state;
    if (currentState is! ChatReady || currentState.isProcessing) return;

    if (!settings.hasApiKey) {
      emit(const ChatError('No API key configured. Open chat settings to add one.'));
      return;
    }

    // Add user message to UI
    final userMessage = ChatMessage.user(text.trim());
    final messages = [...currentState.messages, userMessage];
    emit(currentState.copyWith(messages: messages, isProcessing: true));

    // Add to LLM history
    _llmHistory.add(LlmMessage.user(text.trim()));

    // Create provider
    final provider = _createProvider(settings);
    final toolBridge = ToolBridgeService(_toolRegistry);
    final chatService = ChatService(
      provider: provider,
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
      case ChatLoopAssistantMessage(content: final content, usage: final usage):
        final msg = ChatMessage.assistant(content);
        // Add to LLM history
        _llmHistory.add(LlmMessage.assistant(content));
        emit(currentState.copyWith(
          messages: [...currentState.messages, msg],
          isProcessing: false,
          clearToolName: true,
          totalInputTokens:
              currentState.totalInputTokens + (usage?.inputTokens ?? 0),
          totalOutputTokens:
              currentState.totalOutputTokens + (usage?.outputTokens ?? 0),
        ));
      case ChatLoopError(message: final message):
        final msg = ChatMessage.assistant('Error: $message');
        emit(currentState.copyWith(
          messages: [...currentState.messages, msg],
          isProcessing: false,
          clearToolName: true,
        ));
    }
  }

  void clearChat() {
    _loopSubscription?.cancel();
    _llmHistory.clear();
    emit(const ChatReady());
  }

  void cancelProcessing() {
    _loopSubscription?.cancel();
    final currentState = state;
    if (currentState is ChatReady) {
      emit(currentState.copyWith(
        isProcessing: false,
        clearToolName: true,
      ));
    }
  }

  void dismissError() {
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
    return super.close();
  }
}
