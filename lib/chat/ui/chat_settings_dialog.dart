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
  late final TextEditingController _openaiBaseUrlController;
  bool _showAdvanced = false;

  bool get _isOpenAI => _provider == LlmProviderType.openai;

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
    _openaiBaseUrlController =
        TextEditingController(text: _settings.openaiBaseUrl);
    _showAdvanced = _settings.openaiBaseUrl != null &&
        _settings.openaiBaseUrl!.isNotEmpty;
  }

  @override
  void dispose() {
    _anthropicKeyController.dispose();
    _openaiKeyController.dispose();
    _anthropicModelController.dispose();
    _openaiModelController.dispose();
    _openaiBaseUrlController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    await _settings.setChatLlmProvider(_provider);
    await _settings.setAnthropicApiKey(_anthropicKeyController.text.trim());
    await _settings.setOpenaiApiKey(_openaiKeyController.text.trim());
    await _settings.setAnthropicModel(_anthropicModelController.text.trim());
    await _settings.setOpenaiModel(_openaiModelController.text.trim());
    await _settings.setOpenaiBaseUrl(
        _showAdvanced ? _openaiBaseUrlController.text.trim() : '');
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
      content: SizedBox(
        width: 400,
        height: 420,
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
              Text('API Key', style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              TextField(
                key: ValueKey('apikey_${_provider.name}'),
                controller: _isOpenAI
                    ? _openaiKeyController
                    : _anthropicKeyController,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  hintText: _isOpenAI ? 'sk-...' : 'sk-ant-...',
                  isDense: true,
                ),
                obscureText: true,
              ),
              const SizedBox(height: 16),
              Text('Model', style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              TextField(
                key: ValueKey('model_${_provider.name}'),
                controller: _isOpenAI
                    ? _openaiModelController
                    : _anthropicModelController,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  hintText: _isOpenAI
                      ? 'gpt-5-nano'
                      : 'claude-haiku-4-5-20251001',
                  isDense: true,
                ),
              ),
              if (_isOpenAI) ...[
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () => setState(() => _showAdvanced = !_showAdvanced),
                  child: Row(
                    children: [
                      Icon(
                        _showAdvanced
                            ? Icons.expand_less
                            : Icons.expand_more,
                        size: 20,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Advanced',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_showAdvanced) ...[
                  const SizedBox(height: 12),
                  Text('Base URL', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _openaiBaseUrlController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText:
                          'https://api.openai.com/v1/chat/completions',
                      isDense: true,
                    ),
                    keyboardType: TextInputType.url,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'For LM Studio, OpenRouter, or other OpenAI-compatible APIs.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
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
