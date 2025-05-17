import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

/// Application theme with Material 3 enabled
ThemeData appTheme() {
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
  );
}

/// A service to manage application settings
class SettingsService {
  // Singleton instance
  static final SettingsService _instance = SettingsService._internal();
  factory SettingsService() => _instance;
  SettingsService._internal();

  // SharedPreferences instance
  SharedPreferences? _prefs;

  // Keys for storing settings
  static const String _requestTimeoutKey = 'request_timeout_ms';
  static const String _interMessageDelayKey = 'inter_message_delay_ms';
  static const String _hapticsEnabledKey = 'haptics_enabled';
  static const String _mcpEnabledKey = 'mcp_enabled';

  // Default values
  static const int defaultRequestTimeout = 300;
  static const int defaultInterMessageDelay = 50;
  static const bool defaultHapticsEnabled = true;
  static const bool defaultMcpEnabled = false;

  /// Initialize the settings service
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Get the request timeout in milliseconds
  int get requestTimeout =>
      _prefs?.getInt(_requestTimeoutKey) ?? defaultRequestTimeout;

  /// Set the request timeout in milliseconds
  Future<bool> setRequestTimeout(int value) async {
    return await _prefs?.setInt(_requestTimeoutKey, value) ?? false;
  }

  /// Get the inter-message delay in milliseconds
  int get interMessageDelay =>
      _prefs?.getInt(_interMessageDelayKey) ?? defaultInterMessageDelay;

  /// Set the inter-message delay in milliseconds
  Future<bool> setInterMessageDelay(int value) async {
    return await _prefs?.setInt(_interMessageDelayKey, value) ?? false;
  }

  /// Check if haptics are enabled
  bool get hapticsEnabled =>
      _prefs?.getBool(_hapticsEnabledKey) ?? defaultHapticsEnabled;

  /// Set whether haptics are enabled
  Future<bool> setHapticsEnabled(bool value) async {
    return await _prefs?.setBool(_hapticsEnabledKey, value) ?? false;
  }

  /// Check if MCP service is enabled
  bool get mcpEnabled => _prefs?.getBool(_mcpEnabledKey) ?? defaultMcpEnabled;

  /// Set whether MCP service is enabled
  Future<bool> setMcpEnabled(bool value) async {
    return await _prefs?.setBool(_mcpEnabledKey, value) ?? false;
  }

  /// Reset all settings to their default values
  Future<void> resetToDefaults() async {
    await setRequestTimeout(defaultRequestTimeout);
    await setInterMessageDelay(defaultInterMessageDelay);
    await setHapticsEnabled(defaultHapticsEnabled);
    await setMcpEnabled(defaultMcpEnabled);
  }
}

/// A dialog to edit application settings
class SettingsDialog extends StatefulWidget {
  const SettingsDialog({super.key});

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  final _formKey = GlobalKey<FormState>();
  final _requestTimeoutController = TextEditingController();
  final _interMessageDelayController = TextEditingController();
  late bool _hapticsEnabled;
  late bool _mcpEnabled;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = SettingsService();
    _requestTimeoutController.text = settings.requestTimeout.toString();
    _interMessageDelayController.text = settings.interMessageDelay.toString();
    setState(() {
      _hapticsEnabled = settings.hapticsEnabled;
      _mcpEnabled = settings.mcpEnabled;
    });
  }

  Future<void> _saveSettings() async {
    if (_formKey.currentState!.validate()) {
      final settings = SettingsService();
      await settings
          .setRequestTimeout(int.parse(_requestTimeoutController.text));
      await settings
          .setInterMessageDelay(int.parse(_interMessageDelayController.text));
      await settings.setHapticsEnabled(_hapticsEnabled);
      await settings.setMcpEnabled(_mcpEnabled);

      if (mounted) {
        Navigator.of(context)
            .pop(true); // Return true to indicate settings were saved
      }
    }
  }

  @override
  void dispose() {
    _requestTimeoutController.dispose();
    _interMessageDelayController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Manage Settings'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Settings content
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 400),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Request timeout setting
                    _SettingSection(
                      title: 'Request Timeout',
                      subtitle: 'Default timeout for requests',
                      child: TextFormField(
                        controller: _requestTimeoutController,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          suffixText: 'ms',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a value';
                          }
                          final number = int.tryParse(value);
                          if (number == null) {
                            return 'Please enter a valid number';
                          }
                          if (number <= 0) {
                            return 'Value must be greater than 0';
                          }
                          return null;
                        },
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Inter-message delay setting
                    _SettingSection(
                      title: 'Inter-Message Delay',
                      subtitle: 'Minimum time between messages',
                      child: TextFormField(
                        controller: _interMessageDelayController,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          suffixText: 'ms',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a value';
                          }
                          final number = int.tryParse(value);
                          if (number == null) {
                            return 'Please enter a valid number';
                          }
                          if (number < 0) {
                            return 'Value must be 0 or greater';
                          }
                          return null;
                        },
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Haptics enabled setting
                    SwitchListTile(
                      title: Text(
                        'Enable Haptics',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      subtitle: const Text(
                          'Provide tactile feedback when interacting with the app'),
                      value: _hapticsEnabled,
                      onChanged: (value) {
                        setState(() {
                          _hapticsEnabled = value;
                        });
                      },
                      contentPadding: EdgeInsets.zero,
                    ),

                    // MCP enabled setting (desktop only)
                    if (Platform.isMacOS || Platform.isWindows)
                      SwitchListTile(
                        title: Text(
                          'Enable MCP Service',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        subtitle: const Text(
                            'Enable the MCP server for desktop integrations (Windows/MacOS only)'),
                        value: _mcpEnabled,
                        onChanged: (value) {
                          setState(() {
                            _mcpEnabled = value;
                          });
                        },
                        contentPadding: EdgeInsets.zero,
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context)
                        .pop(false); // Return false to indicate cancel
                  },
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _saveSettings,
                  child: const Text('Save'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Helper widget for consistent setting sections
class _SettingSection extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;

  const _SettingSection({
    required this.title,
    this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        if (subtitle != null)
          Padding(
            padding: const EdgeInsets.only(top: 4.0, bottom: 12.0),
            child: Text(
              subtitle!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          )
        else
          const SizedBox(height: 12),
        child,
      ],
    );
  }
}

/// Extension method to easily show the settings dialog
extension SettingsDialogExtension on BuildContext {
  Future<bool?> showSettingsDialog() {
    return showDialog<bool>(
      context: this,
      builder: (context) => const SettingsDialog(),
    );
  }
}

class _SettingsStatusCard extends StatefulWidget {
  const _SettingsStatusCard();

  @override
  State<_SettingsStatusCard> createState() => _SettingsStatusCardState();
}

class _SettingsStatusCardState extends State<_SettingsStatusCard> {
  late SettingsService _settings;

  @override
  void initState() {
    super.initState();
    _settings = SettingsService();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current Settings',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _SettingListTile(
              icon: Icons.timer,
              title: 'Request Timeout',
              value: '${_settings.requestTimeout} ms',
            ),
            const Divider(),
            _SettingListTile(
              icon: Icons.message,
              title: 'Inter-Message Delay',
              value: '${_settings.interMessageDelay} ms',
            ),
            const Divider(),
            _SettingListTile(
              icon: Icons.vibration,
              title: 'Haptics',
              value: _settings.hapticsEnabled ? 'Enabled' : 'Disabled',
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () {
                  setState(() {
                    // This will refresh the widget to show updated settings
                  });
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingListTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _SettingListTile({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(
            icon,
            color: Theme.of(context).colorScheme.secondary,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
        ],
      ),
    );
  }
}
