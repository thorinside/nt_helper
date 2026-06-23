import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:nt_helper/chat/models/allowed_file_root.dart';
import 'package:nt_helper/chat/models/chat_settings.dart';
import 'package:nt_helper/chat/services/codex_auth_service.dart';
import 'package:nt_helper/services/settings_service.dart';
import 'package:nt_helper/ui/widgets/digit_shortcut_blocker.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';

class ChatSettingsDialog extends StatefulWidget {
  const ChatSettingsDialog({super.key});

  @override
  State<ChatSettingsDialog> createState() => _ChatSettingsDialogState();
}

class _ChatSettingsDialogState extends State<ChatSettingsDialog> {
  static const _openaiSubscriptionModels = [
    'gpt-5.5',
    'gpt-5.4',
    'gpt-5.4-mini',
    'gpt-5.3-codex',
    'gpt-5.3-codex-spark',
    'gpt-5.2',
  ];

  final _settings = SettingsService();
  final _codexAuthService = CodexAuthService();
  final _uuid = const Uuid();
  late LlmProviderType _provider;
  late bool _useAnthropicSubscription;
  late bool _useOpenaiSubscription;
  late bool _allowCodexAuthRefresh;
  late List<AllowedFileRoot> _allowedRoots;
  late final TextEditingController _anthropicKeyController;
  late final TextEditingController _openaiKeyController;
  late final TextEditingController _anthropicModelController;
  late final TextEditingController _openaiModelController;
  late final TextEditingController _openaiSubscriptionModelController;
  late final TextEditingController _openaiBaseUrlController;
  bool _showAdvanced = false;
  bool? _codexAuthFound;
  String? _codexAuthError;

  bool get _isOpenAI => _provider == LlmProviderType.openai;
  bool get _isOpenaiSubscription => _isOpenAI && _useOpenaiSubscription;

  /// The effective provider type, factoring in subscription toggles.
  LlmProviderType get _effectiveProvider {
    if (_isOpenaiSubscription) return LlmProviderType.openaiSubscription;
    if (!_isOpenAI && _useAnthropicSubscription) {
      return LlmProviderType.anthropicSubscription;
    }
    return _provider;
  }

  @override
  void initState() {
    super.initState();
    final savedProvider = _settings.chatLlmProvider;
    _useAnthropicSubscription =
        savedProvider == LlmProviderType.anthropicSubscription;
    _useOpenaiSubscription =
        savedProvider == LlmProviderType.openaiSubscription;
    _allowCodexAuthRefresh = _settings.allowCodexAuthRefresh;
    // Collapse subscription providers back to their provider tabs.
    _provider = savedProvider == LlmProviderType.anthropicSubscription
        ? LlmProviderType.anthropic
        : savedProvider == LlmProviderType.openaiSubscription
        ? LlmProviderType.openai
        : savedProvider;
    _anthropicKeyController = TextEditingController(
      text: _settings.anthropicApiKey,
    );
    _openaiKeyController = TextEditingController(text: _settings.openaiApiKey);
    _anthropicModelController = TextEditingController(
      text: _settings.anthropicModel,
    );
    _openaiModelController = TextEditingController(text: _settings.openaiModel);
    _openaiSubscriptionModelController = TextEditingController(
      text: _settings.openaiSubscriptionModel,
    );
    _openaiBaseUrlController = TextEditingController(
      text: _settings.openaiBaseUrl,
    );
    _allowedRoots = _settings.allowedFileRoots.toList();
    _showAdvanced =
        _settings.openaiBaseUrl != null && _settings.openaiBaseUrl!.isNotEmpty;
    if (_isOpenaiSubscription) {
      _validateCodexAuth();
    }
  }

  @override
  void dispose() {
    _anthropicKeyController.dispose();
    _openaiKeyController.dispose();
    _anthropicModelController.dispose();
    _openaiModelController.dispose();
    _openaiSubscriptionModelController.dispose();
    _openaiBaseUrlController.dispose();
    _codexAuthService.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_effectiveProvider == LlmProviderType.openaiSubscription) {
      final authFound = await _codexAuthService.authFound();
      if (!mounted) return;
      if (!authFound) {
        setState(() {
          _codexAuthFound = false;
          _codexAuthError =
              'Codex auth not found. Run `codex login` in a terminal.';
        });
        return;
      }
    }

    await _settings.setChatLlmProvider(_effectiveProvider);
    await _settings.setAnthropicApiKey(_anthropicKeyController.text.trim());
    await _settings.setOpenaiApiKey(_openaiKeyController.text.trim());
    await _settings.setAnthropicModel(_anthropicModelController.text.trim());
    await _settings.setOpenaiModel(_openaiModelController.text.trim());
    await _settings.setOpenaiSubscriptionModel(
      _openaiSubscriptionModelController.text.trim(),
    );
    await _settings.setAllowCodexAuthRefresh(_allowCodexAuthRefresh);
    await _settings.setOpenaiBaseUrl(
      _showAdvanced && !_isOpenaiSubscription
          ? _openaiBaseUrlController.text.trim()
          : '',
    );
    await _settings.setAllowedFileRoots(_allowedRoots);
    if (mounted) Navigator.of(context).pop(true);
  }

  Future<void> _addAllowedRoot() async {
    final selected = await FilePicker.getDirectoryPath(
      dialogTitle: 'Choose Allowed Root',
    );
    if (selected == null || !mounted) return;
    final baseName = path.basename(selected);
    setState(() {
      _allowedRoots = [
        ..._allowedRoots,
        AllowedFileRoot.chatReadSearch(
          id: _uuid.v4(),
          label: baseName.isEmpty ? 'Allowed Root' : baseName,
          path: selected,
        ),
      ];
    });
  }

  Future<void> _chooseAllowedRootDirectory(int index) async {
    final current = _allowedRoots[index];
    final selected = await FilePicker.getDirectoryPath(
      dialogTitle: 'Choose Allowed Root',
      initialDirectory: current.path.trim().isEmpty ? null : current.path,
    );
    if (selected == null || !mounted) return;
    setState(() {
      _allowedRoots[index] = current.copyWith(path: selected);
    });
  }

  void _updateRoot(int index, AllowedFileRoot root) {
    setState(() => _allowedRoots[index] = root);
  }

  void _removeRoot(int index) {
    setState(() {
      _allowedRoots = [
        ..._allowedRoots.take(index),
        ..._allowedRoots.skip(index + 1),
      ];
    });
  }

  void _setPermission(
    int index,
    FileRootActor actor,
    FileRootPermission permission,
    bool enabled,
  ) {
    final root = _allowedRoots[index];
    final permissions = {...root.permissionsFor(actor)};
    if (enabled) {
      permissions.add(permission);
    } else {
      permissions.remove(permission);
    }
    final acl = {
      for (final entry in root.acl.entries) entry.key: {...entry.value},
      actor: permissions,
    };
    _updateRoot(index, root.copyWith(acl: acl));
  }

  Future<void> _validateCodexAuth() async {
    setState(() {
      _codexAuthFound = null;
      _codexAuthError = null;
    });
    final found = await _codexAuthService.authFound();
    if (!mounted) return;
    setState(() {
      _codexAuthFound = found;
      _codexAuthError = found
          ? null
          : 'Codex auth not found. Run `codex login` in a terminal.';
    });
  }

  Future<void> _setOpenaiSubscription(bool value) async {
    setState(() => _useOpenaiSubscription = value);
    if (value) await _validateCodexAuth();
  }

  Future<void> _setAllowCodexAuthRefresh(bool value) async {
    if (!value) {
      setState(() => _allowCodexAuthRefresh = false);
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Semantics(
          header: true,
          child: const Text('Allow Codex Auth Refresh?'),
        ),
        content: const Text(
          'nt_helper will refresh your Codex ChatGPT credentials when a '
          'request is rejected as unauthorized. Refresh can rotate tokens, so '
          'nt_helper may update ~/.codex/auth.json.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Allow'),
          ),
        ],
      ),
    );

    if (!mounted) return;
    setState(() => _allowCodexAuthRefresh = confirmed ?? false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: Semantics(header: true, child: const Text('Chat Settings')),
      content: SizedBox(
        width: 400,
        height: 520,
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
                onSelectionChanged: (s) => setState(() => _provider = s.first),
              ),
              if (_isOpenAI) ..._buildOpenAISettings(theme),
              if (!_isOpenAI) ..._buildAnthropicSettings(theme),
              ..._buildLocalContextSettings(theme),
              const SizedBox(height: 16),
              Text(
                _isOpenaiSubscription
                    ? 'Codex auth is stored locally by Codex CLI.'
                    : 'API keys are stored locally on this device.',
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
        FilledButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }

  List<Widget> _buildAnthropicSettings(ThemeData theme) => [
    const SizedBox(height: 12),
    SwitchListTile(
      title: Text('Use Subscription', style: theme.textTheme.titleSmall),
      subtitle: Text(
        'Authenticate with Claude subscription OAuth token',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      value: _useAnthropicSubscription,
      onChanged: (v) => setState(() => _useAnthropicSubscription = v),
      contentPadding: EdgeInsets.zero,
      dense: true,
    ),
    const SizedBox(height: 16),
    Text(
      _useAnthropicSubscription ? 'OAuth Token' : 'API Key',
      style: theme.textTheme.titleSmall,
    ),
    const SizedBox(height: 8),
    DigitShortcutBlocker(
      child: TextField(
        key: ValueKey('apikey_${_effectiveProvider.name}'),
        controller: _anthropicKeyController,
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          hintText: _useAnthropicSubscription ? 'sk-ant-oat...' : 'sk-ant...',
          isDense: true,
        ),
        obscureText: true,
      ),
    ),
    if (_useAnthropicSubscription) ...[
      const SizedBox(height: 4),
      Text(
        'Run "claude setup-key" in a terminal to get your token.',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    ],
    const SizedBox(height: 16),
    Text('Model', style: theme.textTheme.titleSmall),
    const SizedBox(height: 8),
    DigitShortcutBlocker(
      child: TextField(
        key: const ValueKey('model_anthropic'),
        controller: _anthropicModelController,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          hintText: 'claude-haiku-4-5-20251001',
          isDense: true,
        ),
      ),
    ),
  ];

  List<Widget> _buildOpenAISettings(ThemeData theme) => [
    const SizedBox(height: 12),
    SwitchListTile(
      title: Text(
        'Use Subscription (Codex)',
        style: theme.textTheme.titleSmall,
      ),
      subtitle: Text(
        'Use ChatGPT subscription auth from Codex CLI',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      value: _useOpenaiSubscription,
      onChanged: (v) => _setOpenaiSubscription(v),
      contentPadding: EdgeInsets.zero,
      dense: true,
    ),
    if (_isOpenaiSubscription) ..._buildOpenAISubscriptionSettings(theme),
    if (!_isOpenaiSubscription) ..._buildOpenAIApiKeySettings(theme),
  ];

  List<Widget> _buildOpenAISubscriptionSettings(ThemeData theme) => [
    const SizedBox(height: 8),
    Semantics(
      liveRegion: true,
      child: Text(
        _codexAuthFound == null
            ? 'Codex auth: checking...'
            : _codexAuthFound!
            ? 'Codex auth: found'
            : 'Codex auth: not found',
        style: theme.textTheme.bodySmall?.copyWith(
          color: _codexAuthFound == false
              ? theme.colorScheme.error
              : theme.colorScheme.onSurfaceVariant,
        ),
      ),
    ),
    if (_codexAuthError != null) ...[
      const SizedBox(height: 4),
      Text(
        _codexAuthError!,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.error,
        ),
      ),
    ],
    const SizedBox(height: 16),
    Text('Model', style: theme.textTheme.titleSmall),
    const SizedBox(height: 8),
    _buildOpenAISubscriptionModelDropdown(),
    const SizedBox(height: 12),
    SwitchListTile(
      title: Text(
        'Allow nt_helper to refresh Codex auth',
        style: theme.textTheme.titleSmall,
      ),
      value: _allowCodexAuthRefresh,
      onChanged: (v) => _setAllowCodexAuthRefresh(v),
      contentPadding: EdgeInsets.zero,
      dense: true,
    ),
  ];

  Widget _buildOpenAISubscriptionModelDropdown() {
    final current = _openaiSubscriptionModelController.text.trim();
    final models =
        current.isNotEmpty && !_openaiSubscriptionModels.contains(current)
        ? [current, ..._openaiSubscriptionModels]
        : _openaiSubscriptionModels;

    return DropdownButtonFormField<String>(
      key: const ValueKey('model_openai_subscription'),
      initialValue: models.contains(current) ? current : 'gpt-5.4-mini',
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        isDense: true,
      ),
      items: models
          .map(
            (model) =>
                DropdownMenuItem<String>(value: model, child: Text(model)),
          )
          .toList(),
      onChanged: (model) {
        if (model == null) return;
        _openaiSubscriptionModelController.text = model;
      },
    );
  }

  List<Widget> _buildOpenAIApiKeySettings(ThemeData theme) => [
    const SizedBox(height: 16),
    Text('API Key', style: theme.textTheme.titleSmall),
    const SizedBox(height: 8),
    DigitShortcutBlocker(
      child: TextField(
        key: const ValueKey('apikey_openai'),
        controller: _openaiKeyController,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          hintText: 'sk-...',
          isDense: true,
        ),
        obscureText: true,
      ),
    ),
    const SizedBox(height: 16),
    Text('Model', style: theme.textTheme.titleSmall),
    const SizedBox(height: 8),
    DigitShortcutBlocker(
      child: TextField(
        key: const ValueKey('model_openai'),
        controller: _openaiModelController,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          hintText: 'gpt-5-nano',
          isDense: true,
        ),
      ),
    ),
    const SizedBox(height: 12),
    GestureDetector(
      onTap: () => setState(() => _showAdvanced = !_showAdvanced),
      child: Row(
        children: [
          Icon(
            _showAdvanced ? Icons.expand_less : Icons.expand_more,
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
            hintText: 'https://api.openai.com/v1/chat/completions',
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
  ];

  List<Widget> _buildLocalContextSettings(ThemeData theme) => [
    const SizedBox(height: 24),
    Semantics(
      header: true,
      child: Text('Allowed File Roots', style: theme.textTheme.titleSmall),
    ),
    const SizedBox(height: 8),
    if (_allowedRoots.isEmpty)
      Text(
        'No folders are available to chat or MCP file tools.',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    for (var i = 0; i < _allowedRoots.length; i++) ...[
      _buildAllowedRootEditor(theme, i),
      const SizedBox(height: 16),
    ],
    OutlinedButton.icon(
      onPressed: _addAllowedRoot,
      icon: const Icon(Icons.create_new_folder_outlined),
      label: const Text('Add Folder'),
    ),
    const SizedBox(height: 4),
    Text(
      'Each folder grants separate read, write, and search permissions for chat and external MCP.',
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    ),
  ];

  Widget _buildAllowedRootEditor(ThemeData theme, int index) {
    final root = _allowedRoots[index];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: DigitShortcutBlocker(
                  child: TextFormField(
                    key: ValueKey('file_root_label_${root.id}'),
                    initialValue: root.label,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Label',
                      isDense: true,
                    ),
                    onChanged: (value) =>
                        _updateRoot(index, root.copyWith(label: value.trim())),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Remove allowed root',
                icon: const Icon(Icons.delete_outline),
                onPressed: () => _removeRoot(index),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: DigitShortcutBlocker(
                  child: TextFormField(
                    key: ValueKey('file_root_path_${root.id}'),
                    initialValue: root.path,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Path',
                      isDense: true,
                    ),
                    onChanged: (value) =>
                        _updateRoot(index, root.copyWith(path: value.trim())),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Choose folder',
                icon: const Icon(Icons.folder_open),
                onPressed: () => _chooseAllowedRootDirectory(index),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildPermissionTable(theme, index),
        ],
      ),
    );
  }

  Widget _buildPermissionTable(ThemeData theme, int index) {
    final headerStyle = theme.textTheme.labelSmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    return Table(
      columnWidths: const {
        0: FixedColumnWidth(64),
        1: FixedColumnWidth(72),
        2: FixedColumnWidth(72),
        3: FixedColumnWidth(80),
      },
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        TableRow(
          children: [
            const SizedBox.shrink(),
            _permissionHeader('Read', headerStyle),
            _permissionHeader('Write', headerStyle),
            _permissionHeader('Search', headerStyle),
          ],
        ),
        _permissionTableRow(theme, index, FileRootActor.chat, 'Chat'),
        _permissionTableRow(theme, index, FileRootActor.mcp, 'MCP'),
      ],
    );
  }

  TableRow _permissionTableRow(
    ThemeData theme,
    int index,
    FileRootActor actor,
    String label,
  ) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(label, style: theme.textTheme.bodySmall),
        ),
        _buildPermissionCheckbox(index, actor, FileRootPermission.read, 'Read'),
        _buildPermissionCheckbox(
          index,
          actor,
          FileRootPermission.write,
          'Write',
        ),
        _buildPermissionCheckbox(
          index,
          actor,
          FileRootPermission.search,
          'Search',
        ),
      ],
    );
  }

  Widget _permissionHeader(String label, TextStyle? style) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Center(child: Text(label, style: style)),
    );
  }

  Widget _buildPermissionCheckbox(
    int index,
    FileRootActor actor,
    FileRootPermission permission,
    String label,
  ) {
    final checked = _allowedRoots[index].allows(actor, permission);
    return Semantics(
      label: '${actor.storageKey} ${permission.storageKey} permission',
      checked: checked,
      button: true,
      child: Center(
        child: Checkbox(
          value: checked,
          onChanged: (value) =>
              _setPermission(index, actor, permission, value ?? false),
          semanticLabel: '$label permission for ${actor.storageKey}',
        ),
      ),
    );
  }
}
