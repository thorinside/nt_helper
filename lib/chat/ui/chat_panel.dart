import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nt_helper/chat/cubit/chat_cubit.dart';
import 'package:nt_helper/chat/cubit/chat_state.dart';
import 'package:nt_helper/chat/models/chat_message.dart';
import 'package:nt_helper/chat/models/chat_settings.dart';
import 'package:nt_helper/chat/ui/chat_input_bar.dart';
import 'package:nt_helper/chat/ui/chat_message_bubble.dart';
import 'package:nt_helper/chat/ui/chat_settings_dialog.dart';
import 'package:nt_helper/services/settings_service.dart';

class ChatPanel extends StatefulWidget {
  final bool requestInputFocus;

  const ChatPanel({super.key, this.requestInputFocus = false});

  @override
  State<ChatPanel> createState() => _ChatPanelState();
}

class _ChatPanelState extends State<ChatPanel> {
  final _scrollController = ScrollController();
  final _inputFocusNode = FocusNode();
  int _previousMessageCount = 0;
  bool _previousIsProcessing = false;
  bool _wasProcessing = false;

  @override
  void initState() {
    super.initState();
    if (widget.requestInputFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _inputFocusNode.requestFocus();
      });
    }
  }

  @override
  void didUpdateWidget(ChatPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.requestInputFocus && !oldWidget.requestInputFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _inputFocusNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _inputFocusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  ChatSettings _loadSettings() {
    final settings = SettingsService();
    return ChatSettings(
      provider: settings.chatLlmProvider,
      anthropicApiKey: settings.anthropicApiKey,
      openaiApiKey: settings.openaiApiKey,
      anthropicModel: settings.anthropicModel,
      openaiModel: settings.openaiModel,
      openaiBaseUrl: settings.openaiBaseUrl,
      chatEnabled: settings.chatEnabled,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      label: 'Chat panel',
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(color: theme.colorScheme.outlineVariant),
          ),
        ),
        child: BlocBuilder<ChatCubit, ChatState>(
          builder: (context, state) {
            return switch (state) {
              ChatInitial() => _buildEmpty(context),
              ChatError(message: final msg) => _buildError(context, msg),
              ChatReady() => _buildChat(context, state),
            };
          },
        ),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Column(
      children: [
        _buildHeader(context),
        const Expanded(child: _EmptyState()),
        ChatInputBar(
          isProcessing: false,
          onSend: (text) => _send(context, text),
          onCancel: () {},
          onSettings: () => _openSettings(context),
          focusNode: _inputFocusNode,
        ),
      ],
    );
  }

  Widget _buildError(BuildContext context, String message) {
    final theme = Theme.of(context);
    return Column(
      children: [
        _buildHeader(context),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.error_outline,
                    color: theme.colorScheme.error,
                    size: 48,
                  ),
                  const SizedBox(height: 12),
                  Text(message, textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () {
                      context.read<ChatCubit>().dismissError();
                      _openSettings(context);
                    },
                    child: const Text('Open Settings'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChat(BuildContext context, ChatReady state) {
    final messages = state.messages;
    final messageCount = messages.length;
    final isProcessing = state.isProcessing && state.currentToolName == null;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (messageCount > _previousMessageCount ||
          (isProcessing && !_previousIsProcessing)) {
        _scrollToBottom();
      }
      if (_wasProcessing && !state.isProcessing) {
        _inputFocusNode.requestFocus();
      }
      _previousMessageCount = messageCount;
      _previousIsProcessing = isProcessing;
      _wasProcessing = state.isProcessing;
    });

    final displayItems = _groupMessages(
      messages,
      state.isProcessing,
      state.currentToolName,
    );

    return Column(
      children: [
        _buildHeader(context),
        Expanded(
          child: ExcludeFocus(
            child: messages.isEmpty
                ? const _EmptyState()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: displayItems.length,
                    itemBuilder: (context, index) {
                      final item = displayItems[index];
                      return switch (item) {
                        _SingleMessage(:final message, :final isNew) =>
                          ChatMessageBubble(message: message, isNew: isNew),
                        _ToolGroup(:final messages) => ToolGroupBubble(
                          messages: messages,
                        ),
                        _Thinking() => ChatMessageBubble(
                          message: ChatMessage.thinking(),
                        ),
                      };
                    },
                  ),
          ),
        ),
        if (state.totalInputTokens > 0 || state.totalOutputTokens > 0)
          _TokenUsageBar(
            inputTokens: state.totalInputTokens,
            outputTokens: state.totalOutputTokens,
          ),
        ChatInputBar(
          isProcessing: state.isProcessing,
          onSend: (text) => _send(context, text),
          onCancel: () => context.read<ChatCubit>().cancelProcessing(),
          onSettings: () => _openSettings(context),
          focusNode: _inputFocusNode,
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 18,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Text('Chat', style: theme.textTheme.titleSmall),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 18),
            tooltip: 'Clear chat',
            visualDensity: VisualDensity.compact,
            onPressed: () => context.read<ChatCubit>().clearChat(),
          ),
        ],
      ),
    );
  }

  void _send(BuildContext context, String text) {
    final settings = _loadSettings();
    context.read<ChatCubit>().sendMessage(text, settings);
  }

  void _openSettings(BuildContext context) {
    showDialog<bool>(
      context: context,
      builder: (_) => const ChatSettingsDialog(),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.chat_outlined,
              size: 48,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 12),
            Text(
              'Ask me about your preset',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'I can search algorithms, show routing,\nedit parameters, and more.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withValues(
                  alpha: 0.7,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TokenUsageBar extends StatelessWidget {
  final int inputTokens;
  final int outputTokens;

  const _TokenUsageBar({required this.inputTokens, required this.outputTokens});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: Text(
        'Tokens: ${_formatNumber(inputTokens)} in / ${_formatNumber(outputTokens)} out',
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  String _formatNumber(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return n.toString();
  }
}

// Display item types for grouping tool messages
sealed class _DisplayItem {}

class _SingleMessage extends _DisplayItem {
  final ChatMessage message;
  final bool isNew;
  _SingleMessage(this.message, {this.isNew = false});
}

class _ToolGroup extends _DisplayItem {
  final List<ChatMessage> messages;
  _ToolGroup(this.messages);
}

class _Thinking extends _DisplayItem {}

List<_DisplayItem> _groupMessages(
  List<ChatMessage> messages,
  bool isProcessing,
  String? currentToolName,
) {
  final items = <_DisplayItem>[];
  int i = 0;
  while (i < messages.length) {
    final msg = messages[i];
    if (msg.role == ChatMessageRole.toolCall ||
        msg.role == ChatMessageRole.toolResult) {
      final toolMessages = <ChatMessage>[];
      while (i < messages.length &&
          (messages[i].role == ChatMessageRole.toolCall ||
              messages[i].role == ChatMessageRole.toolResult)) {
        toolMessages.add(messages[i]);
        i++;
      }
      items.add(_ToolGroup(toolMessages));
    } else {
      final isLast = i == messages.length - 1;
      final hasThinking = isProcessing && currentToolName == null;
      items.add(_SingleMessage(msg, isNew: isLast && !hasThinking));
      i++;
    }
  }
  if (isProcessing && currentToolName == null) {
    items.add(_Thinking());
  }
  return items;
}
