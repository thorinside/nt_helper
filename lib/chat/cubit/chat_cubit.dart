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
import 'package:nt_helper/chat/services/memory_service.dart';
import 'package:nt_helper/chat/services/system_prompt.dart';
import 'package:nt_helper/chat/services/tool_bridge_service.dart';
import 'package:nt_helper/mcp/tool_registry.dart';

class ChatCubit extends Cubit<ChatState> {
  final ToolRegistry _toolRegistry;
  final MemoryService _memoryService;
  StreamSubscription<dynamic>? _loopSubscription;
  LlmProvider? _activeProvider;

  // Accumulated LLM message history for the agentic loop
  final List<LlmMessage> _llmHistory = [];

  // Length of _llmHistory before the current loop started, used to restore
  // clean state if the loop is cancelled mid-execution.
  int _historyLengthBeforeLoop = 0;

  // Memory state
  bool _bootstrapped = false;
  String? _memoryContent;
  String? _dailyLogs;
  String? _currentModel;
  bool _needsCompaction = false;

  static const _contextLimits = <String, int>{
    'claude-haiku-4-5-20251001': 200000,
    'claude-sonnet-4-5-20250514': 200000,
    'gpt-5-nano': 128000,
  };
  static const _defaultContextLimit = 100000;

  ChatCubit({
    required ToolRegistry toolRegistry,
    required MemoryService memoryService,
  })  : _toolRegistry = toolRegistry,
        _memoryService = memoryService,
        super(const ChatReady());

  Future<void> sendMessage(String text, ChatSettings settings) async {
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

    // Show processing state immediately
    final userMessage = ChatMessage.user(text.trim());
    final messages = [...currentState.messages, userMessage];
    emit(currentState.copyWith(messages: messages, isProcessing: true));

    // Bootstrap memory on first send
    if (!_bootstrapped) {
      _memoryContent = await _memoryService.readMemory();
      _dailyLogs = await _memoryService.readDailyLogs();
      _bootstrapped = true;
    }

    // Track current model for context limits
    _currentModel = _resolveModel(settings);

    // Handle compaction if needed
    if (_needsCompaction) {
      await _performCompaction(settings);
    }

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
      systemPrompt: distingNtSystemPrompt(
        memoryContent: _memoryContent,
        dailyLogs: _dailyLogs,
      ),
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
        // Refresh memory after memory_write tool
        if (name == 'memory_write') {
          _refreshMemory();
        }
      case ChatLoopAssistantMessage(
          content: final content,
          usage: final usage,
          isFinal: final isFinal,
          finalHistory: final finalHistory,
        ):
        final uiMessages = content.isNotEmpty
            ? [...currentState.messages, ChatMessage.assistant(content)]
            : currentState.messages;

        if (isFinal) {
          final newHistory = finalHistory ?? [LlmMessage.assistant(content)];
          _llmHistory.clear();
          _llmHistory.addAll(newHistory);

          // Summarize large tool results in background
          _summarizeLargeToolResults();

          // Check if compaction is needed
          final totalInput =
              currentState.totalInputTokens + (usage?.inputTokens ?? 0);
          final limit =
              _contextLimits[_currentModel] ?? _defaultContextLimit;
          if (totalInput > limit ~/ 2) {
            _needsCompaction = true;
          }
        }

        emit(currentState.copyWith(
          messages: uiMessages,
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

  Future<void> _refreshMemory() async {
    _memoryContent = await _memoryService.readMemory();
  }

  Future<void> _summarizeLargeToolResults() async {
    if (_activeProvider == null) return;

    for (int i = 0; i < _llmHistory.length; i++) {
      final msg = _llmHistory[i];
      if (msg.role != LlmRole.tool) continue;
      final content = msg.content;
      if (content == null || content.length <= 4096) continue;

      final toolName = msg.toolName ?? 'unknown';
      try {
        final response = await _activeProvider!.sendMessages(
          messages: [
            LlmMessage.user(
              'Condense this $toolName result to key facts '
              '(names, IDs, values, bus assignments, errors). '
              'Omit empty/default entries and verbose structure. '
              'One paragraph max.\n\n$content',
            ),
          ],
          tools: [],
        );

        final summary = response.content;
        if (summary != null && summary.isNotEmpty) {
          _llmHistory[i] = LlmMessage.toolResult(
            toolCallId: msg.toolCallId!,
            toolName: toolName,
            content: summary,
          );
        }
      } catch (_) {
        // Best-effort: keep original on failure
      }
    }
  }

  Future<void> _performCompaction(ChatSettings settings) async {
    // Save snapshot of current state
    await _memoryService.saveSessionSnapshot(_llmHistory);

    // Inject compaction request
    _llmHistory.add(LlmMessage.user(
      '[SYSTEM: Context is large. Use memory_append_daily to save important '
      'session context before continuing.]',
    ));

    // Run one agentic loop turn for the LLM to save context
    _activeProvider?.dispose();
    _activeProvider = _createProvider(settings);
    final toolBridge = ToolBridgeService(_toolRegistry);
    final chatService = ChatService(
      provider: _activeProvider!,
      toolBridge: toolBridge,
      systemPrompt: distingNtSystemPrompt(
        memoryContent: _memoryContent,
        dailyLogs: _dailyLogs,
      ),
    );

    final completer = Completer<void>();
    final sub = chatService.runAgenticLoop(_llmHistory).listen(
      (event) {
        if (event is ChatLoopAssistantMessage && event.isFinal) {
          if (event.finalHistory != null) {
            _llmHistory.clear();
            _llmHistory.addAll(event.finalHistory!);
          }
        }
      },
      onDone: () => completer.complete(),
      onError: (e) => completer.complete(),
    );

    await completer.future;
    await sub.cancel();

    // Trim to last 10 messages
    if (_llmHistory.length > 10) {
      _llmHistory.removeRange(0, _llmHistory.length - 10);
    }

    // Refresh daily logs since compaction may have appended
    _dailyLogs = await _memoryService.readDailyLogs();

    // Reset compaction state and token counters
    _needsCompaction = false;

    // Add compaction notice to UI
    final currentState = state;
    if (currentState is ChatReady) {
      emit(currentState.copyWith(
        messages: [
          ...currentState.messages,
          ChatMessage.system(
            'Earlier context was compacted to stay within limits.',
          ),
        ],
        totalInputTokens: 0,
        totalOutputTokens: 0,
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

  Future<void> clearChat() async {
    _loopSubscription?.cancel();
    if (_llmHistory.isNotEmpty) {
      await _memoryService.saveSessionSnapshot(_llmHistory.toList());
    }
    _llmHistory.clear();
    _bootstrapped = false;
    _needsCompaction = false;
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

  String _resolveModel(ChatSettings settings) {
    switch (settings.provider) {
      case LlmProviderType.anthropic:
        return settings.anthropicModel;
      case LlmProviderType.openai:
        return settings.openaiModel;
    }
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
  Future<void> close() async {
    _loopSubscription?.cancel();
    if (_llmHistory.isNotEmpty) {
      await _memoryService.saveSessionSnapshot(_llmHistory.toList());
    }
    _activeProvider?.dispose();
    return super.close();
  }
}
