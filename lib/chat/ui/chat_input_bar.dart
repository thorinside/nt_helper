import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nt_helper/services/key_binding_service.dart';

class ChatInputBar extends StatefulWidget {
  final bool isProcessing;
  final ValueChanged<String> onSend;
  final VoidCallback onCancel;
  final VoidCallback onSettings;
  final FocusNode? focusNode;

  const ChatInputBar({
    super.key,
    required this.isProcessing,
    required this.onSend,
    required this.onCancel,
    required this.onSettings,
    this.focusNode,
  });

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
  final _controller = TextEditingController();
  FocusNode? _ownedFocusNode;

  FocusNode get _focusNode => widget.focusNode ?? (_ownedFocusNode ??= FocusNode());

  void _handleSend() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    widget.onSend(text);
    _controller.clear();
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _controller.dispose();
    _ownedFocusNode?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Semantics(
              label: 'Chat settings',
              button: true,
              child: IconButton(
                icon: const Icon(Icons.settings_outlined, size: 20),
                tooltip: 'Chat settings',
                onPressed: widget.onSettings,
                visualDensity: VisualDensity.compact,
              ),
            ),
            Expanded(
              child: Shortcuts(
                shortcuts: {
                  LogicalKeySet(LogicalKeyboardKey.enter): const _SendIntent(),
                  // Block bare digit keys from triggering page jumps
                  for (final key in _digitKeys)
                    SingleActivator(key):
                        const DoNothingAndStopPropagationTextIntent(),
                  // Block global shortcuts from firing while typing
                  for (final activator in KeyBindingService().globalShortcuts.keys)
                    activator: const DoNothingAndStopPropagationTextIntent(),
                },
                child: Actions(
                  actions: {
                    _SendIntent: CallbackAction<_SendIntent>(
                      onInvoke: (_) {
                        if (!widget.isProcessing) _handleSend();
                        return null;
                      },
                    ),
                  },
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    decoration: InputDecoration(
                      hintText: 'Ask about your preset...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: theme.colorScheme.surfaceContainerHighest,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      isDense: true,
                    ),
                    enabled: !widget.isProcessing,
                    textInputAction: TextInputAction.send,
                    onSubmitted: widget.isProcessing ? null : (_) => _handleSend(),
                    maxLines: 3,
                    minLines: 1,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),
            if (widget.isProcessing)
              Semantics(
                label: 'Cancel',
                button: true,
                child: IconButton(
                  icon: Icon(
                    Icons.stop_circle_outlined,
                    color: theme.colorScheme.error,
                  ),
                  tooltip: 'Cancel',
                  onPressed: widget.onCancel,
                ),
              )
            else
              Semantics(
                label: 'Send message',
                button: true,
                child: IconButton(
                  icon: Icon(
                    Icons.send_rounded,
                    color: theme.colorScheme.primary,
                  ),
                  tooltip: 'Send',
                  onPressed: _handleSend,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SendIntent extends Intent {
  const _SendIntent();
}

const _digitKeys = [
  LogicalKeyboardKey.digit0,
  LogicalKeyboardKey.digit1,
  LogicalKeyboardKey.digit2,
  LogicalKeyboardKey.digit3,
  LogicalKeyboardKey.digit4,
  LogicalKeyboardKey.digit5,
  LogicalKeyboardKey.digit6,
  LogicalKeyboardKey.digit7,
  LogicalKeyboardKey.digit8,
  LogicalKeyboardKey.digit9,
];
