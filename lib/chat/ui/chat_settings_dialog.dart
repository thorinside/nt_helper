import 'package:flutter/material.dart';
import 'package:nt_helper/chat/models/chat_settings.dart';
import 'package:nt_helper/services/settings_service.dart';
import 'package:nt_helper/ui/widgets/digit_shortcut_blocker.dart';

class ChatSettingsDialog extends StatefulWidget {
  const ChatSettingsDialog({super.key});

  @override
  State<ChatSettingsDialog> createState() => _ChatSettingsDialogState();
}

class _ChatSettingsDialogState extends State<ChatSettingsDialog> {
  final _settings = SettingsService();
  late LlmProviderType _provider;
  late bool _useSubscription;
  late final TextEditingController _anthropicKeyController;
  late final TextEditingController _openaiKeyController;
  late final TextEditingController _anthropicModelController;
  late final TextEditingController _openaiModelController;
  late final TextEditingController _openaiBaseUrlController;
  bool _showAdvanced = false;

  bool get _isOpenAI => _provider == LlmProviderType.openai;

  /// The effective provider type, factoring in the subscription toggle.
  LlmProviderType get _effectiveProvider =>
      !_isOpenAI && _useSubscription
          ? LlmProviderType.anthropicSubscription
          : _provider;

  @override
  void initState() {
    super.initState();
    final savedProvider = _settings.chatLlmProvider;
    _useSubscription =
        savedProvider == LlmProviderType.anthropicSubscription;
    // Collapse subscription back to the anthropic tab
    _provider = savedProvider == LlmProviderType.anthropicSubscription
        ? LlmProviderType.anthropic
        : savedProvider;
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
    await _settings.setChatLlmProvider(_effectiveProvider);
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
              if (!_isOpenAI) ...[
                const SizedBox(height: 12),
                SwitchListTile(
                  title: Text(
                    'Use Subscription',
                    style: theme.textTheme.titleSmall,
                  ),
                  subtitle: Text(
                    'Authenticate with Claude subscription OAuth token',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  value: _useSubscription,
                  onChanged: (v) => setState(() => _useSubscription = v),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
              ],
              const SizedBox(height: 16),
              Text(
                _useSubscription && !_isOpenAI
                    ? 'OAuth Token'
                    : 'API Key',
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              DigitShortcutBlocker(
                child: TextField(
                  key: ValueKey('apikey_${_effectiveProvider.name}'),
                  controller: _isOpenAI
                      ? _openaiKeyController
                      : _anthropicKeyController,
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    hintText: _isOpenAI
                        ? 'sk-...'
                        : _useSubscription
                            ? 'sk-ant-oat...'
                            : 'sk-ant-...',
                    isDense: true,
                  ),
                  obscureText: true,
                ),
              ),
              if (_useSubscription && !_isOpenAI) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Run "claude setup-key" in a terminal to get your token.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    Tooltip(
                      richMessage: TextSpan(
                        children: [
                          const TextSpan(
                            text: 'To get your OAuth token:\n\n',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const TextSpan(
                            text: '1. Install Claude Code (npm install -g @anthropic-ai/claude-code)\n'
                                '2. Run: claude setup-key\n'
                                '3. Copy the token (starts with sk-ant-oat)\n'
                                '4. Paste it here',
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.help_outline,
                        size: 16,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              Text('Model', style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              DigitShortcutBlocker(
                child: TextField(
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
                  DigitShortcutBlocker(
                    child: TextField(
                      controller: _openaiBaseUrlController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText:
                            'https://api.openai.com/v1/chat/completions',
                        isDense: true,
                      ),
                      keyboardType: TextInputType.url,
                    ),
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
