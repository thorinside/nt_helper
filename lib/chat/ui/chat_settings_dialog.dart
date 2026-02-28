import 'package:flutter/material.dart';
import 'package:nt_helper/chat/models/chat_settings.dart';
import 'package:nt_helper/services/settings_service.dart';

class ChatSettingsDialog extends StatefulWidget {
  const ChatSettingsDialog({super.key});

  @override
  State<ChatSettingsDialog> createState() => _ChatSettingsDialogState();
}

class _ChatSettingsDialogState extends State<ChatSettingsDialog> {
  final _settings = SettingsService();
  late LlmProviderType _provider;
  late final TextEditingController _anthropicKeyController;
  late final TextEditingController _openaiKeyController;
  late final TextEditingController _anthropicModelController;
  late final TextEditingController _openaiModelController;

  @override
  void initState() {
    super.initState();
    _provider = _settings.chatLlmProvider;
    _anthropicKeyController =
        TextEditingController(text: _settings.anthropicApiKey);
    _openaiKeyController =
        TextEditingController(text: _settings.openaiApiKey);
    _anthropicModelController =
        TextEditingController(text: _settings.anthropicModel);
    _openaiModelController =
        TextEditingController(text: _settings.openaiModel);
  }

  @override
  void dispose() {
    _anthropicKeyController.dispose();
    _openaiKeyController.dispose();
    _anthropicModelController.dispose();
    _openaiModelController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    await _settings.setChatLlmProvider(_provider);
    await _settings.setAnthropicApiKey(_anthropicKeyController.text.trim());
    await _settings.setOpenaiApiKey(_openaiKeyController.text.trim());
    await _settings.setAnthropicModel(_anthropicModelController.text.trim());
    await _settings.setOpenaiModel(_openaiModelController.text.trim());
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: Semantics(
        header: true,
        child: const Text('Chat Settings'),
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 500),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('LLM Provider', style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              SegmentedButton<LlmProviderType>(
                segments: const [
                  ButtonSegment(
                    value: LlmProviderType.anthropic,
                    label: Text('Anthropic'),
                  ),
                  ButtonSegment(
                    value: LlmProviderType.openai,
                    label: Text('OpenAI'),
                  ),
                ],
                selected: {_provider},
                onSelectionChanged: (s) =>
                    setState(() => _provider = s.first),
              ),
              const SizedBox(height: 24),
              if (_provider == LlmProviderType.anthropic) ...[
                Text('Anthropic API Key', style: theme.textTheme.titleSmall),
                const SizedBox(height: 8),
                TextField(
                  controller: _anthropicKeyController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'sk-ant-...',
                    isDense: true,
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 16),
                Text('Model', style: theme.textTheme.titleSmall),
                const SizedBox(height: 8),
                TextField(
                  controller: _anthropicModelController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'claude-sonnet-4-20250514',
                    isDense: true,
                  ),
                ),
              ] else ...[
                Text('OpenAI API Key', style: theme.textTheme.titleSmall),
                const SizedBox(height: 8),
                TextField(
                  controller: _openaiKeyController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'sk-...',
                    isDense: true,
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 16),
                Text('Model', style: theme.textTheme.titleSmall),
                const SizedBox(height: 8),
                TextField(
                  controller: _openaiModelController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'gpt-4o',
                    isDense: true,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Text(
                'API keys are stored locally on this device.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _save,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
