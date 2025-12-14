import 'package:flutter/foundation.dart';
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
  static const String _startPagesCollapsedKey = 'start_pages_collapsed';
  static const String _galleryUrlKey = 'gallery_url';
  static const String _graphqlEndpointKey = 'graphql_endpoint';
  static const String _includeCommunityPluginsKey =
      'include_community_plugins_in_presets';
  static const String _overlayPositionXKey = 'overlay_position_x';
  static const String _overlayPositionYKey = 'overlay_position_y';
  static const String _overlaySizeScaleKey = 'overlay_size_scale';
  static const String _showDebugPanelKey = 'show_debug_panel';

  // Default values
  static const int defaultRequestTimeout = 1000;
  static const int defaultInterMessageDelay = 50;
  static const bool defaultHapticsEnabled = true;
  static const bool defaultMcpEnabled = false;
  static const bool defaultStartPagesCollapsed = false;
  static const String defaultGalleryUrl =
      'https://nt-gallery.nosuch.dev/api/gallery.json';
  static const String defaultGraphqlEndpoint =
      'https://nt-gallery-backend.fly.dev/api/graphql';
  static const bool defaultIncludeCommunityPlugins = false;
  static const double defaultOverlayPositionX =
      -1.0; // -1 means use default positioning
  static const double defaultOverlayPositionY =
      -1.0; // -1 means use default positioning
  static const double defaultOverlaySizeScale = 1.0;
  static const bool defaultShowDebugPanel = true;

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

  /// Check if algorithm pages should start collapsed
  bool get startPagesCollapsed =>
      _prefs?.getBool(_startPagesCollapsedKey) ?? defaultStartPagesCollapsed;

  /// Set whether algorithm pages should start collapsed
  Future<bool> setStartPagesCollapsed(bool value) async {
    return await _prefs?.setBool(_startPagesCollapsedKey, value) ?? false;
  }

  /// Get the gallery URL
  String get galleryUrl =>
      _prefs?.getString(_galleryUrlKey) ?? defaultGalleryUrl;

  /// Set the gallery URL
  Future<bool> setGalleryUrl(String value) async {
    return await _prefs?.setString(_galleryUrlKey, value) ?? false;
  }

  /// Get the GraphQL endpoint URL
  String get graphqlEndpoint =>
      _prefs?.getString(_graphqlEndpointKey) ?? defaultGraphqlEndpoint;

  /// Set the GraphQL endpoint URL
  Future<bool> setGraphqlEndpoint(String value) async {
    return await _prefs?.setString(_graphqlEndpointKey, value) ?? false;
  }

  /// Check if community plugins should be included in preset packages by default
  bool get includeCommunityPlugins =>
      _prefs?.getBool(_includeCommunityPluginsKey) ??
      defaultIncludeCommunityPlugins;

  /// Set whether community plugins should be included in preset packages by default
  Future<bool> setIncludeCommunityPlugins(bool value) async {
    return await _prefs?.setBool(_includeCommunityPluginsKey, value) ?? false;
  }

  /// Get the overlay X position
  double get overlayPositionX =>
      _prefs?.getDouble(_overlayPositionXKey) ?? defaultOverlayPositionX;

  /// Set the overlay X position
  Future<bool> setOverlayPositionX(double value) async {
    return await _prefs?.setDouble(_overlayPositionXKey, value) ?? false;
  }

  /// Get the overlay Y position
  double get overlayPositionY =>
      _prefs?.getDouble(_overlayPositionYKey) ?? defaultOverlayPositionY;

  /// Set the overlay Y position
  Future<bool> setOverlayPositionY(double value) async {
    return await _prefs?.setDouble(_overlayPositionYKey, value) ?? false;
  }

  /// Get the overlay size scale
  double get overlaySizeScale =>
      _prefs?.getDouble(_overlaySizeScaleKey) ?? defaultOverlaySizeScale;

  /// Set the overlay size scale
  Future<bool> setOverlaySizeScale(double value) async {
    return await _prefs?.setDouble(_overlaySizeScaleKey, value) ?? false;
  }

  /// Check if debug panel should be shown
  bool get showDebugPanel =>
      _prefs?.getBool(_showDebugPanelKey) ?? defaultShowDebugPanel;

  /// Set whether debug panel should be shown
  Future<bool> setShowDebugPanel(bool value) async {
    return await _prefs?.setBool(_showDebugPanelKey, value) ?? false;
  }

  /// Reset all settings to their default values
  Future<void> resetToDefaults() async {
    await setRequestTimeout(defaultRequestTimeout);
    await setInterMessageDelay(defaultInterMessageDelay);
    await setHapticsEnabled(defaultHapticsEnabled);
    await setMcpEnabled(defaultMcpEnabled);
    await setStartPagesCollapsed(defaultStartPagesCollapsed);
    await setGalleryUrl(defaultGalleryUrl);
    await setGraphqlEndpoint(defaultGraphqlEndpoint);
    await setIncludeCommunityPlugins(defaultIncludeCommunityPlugins);
    await setOverlayPositionX(defaultOverlayPositionX);
    await setOverlayPositionY(defaultOverlayPositionY);
    await setOverlaySizeScale(defaultOverlaySizeScale);
    await setShowDebugPanel(defaultShowDebugPanel);
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
  final _galleryUrlController = TextEditingController();
  late bool _hapticsEnabled;
  late bool _mcpEnabled;
  late bool _startPagesCollapsed;
  late bool _showDebugPanel;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = SettingsService();
    _requestTimeoutController.text = settings.requestTimeout.toString();
    _interMessageDelayController.text = settings.interMessageDelay.toString();
    _galleryUrlController.text = settings.galleryUrl;
    setState(() {
      _hapticsEnabled = settings.hapticsEnabled;
      _mcpEnabled = settings.mcpEnabled;
      _startPagesCollapsed = settings.startPagesCollapsed;
      _showDebugPanel = settings.showDebugPanel;
    });
  }

  Future<void> _saveSettings() async {
    if (_formKey.currentState!.validate()) {
      final settings = SettingsService();
      await settings.setRequestTimeout(
        int.parse(_requestTimeoutController.text),
      );
      await settings.setInterMessageDelay(
        int.parse(_interMessageDelayController.text),
      );
      await settings.setGalleryUrl(_galleryUrlController.text.trim());
      await settings.setHapticsEnabled(_hapticsEnabled);
      await settings.setMcpEnabled(_mcpEnabled);
      await settings.setStartPagesCollapsed(_startPagesCollapsed);
      await settings.setShowDebugPanel(_showDebugPanel);

      if (mounted) {
        Navigator.of(
          context,
        ).pop(true); // Return true to indicate settings were saved
      }
    }
  }

  @override
  void dispose() {
    _requestTimeoutController.dispose();
    _interMessageDelayController.dispose();
    _galleryUrlController.dispose();
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
                            horizontal: 16,
                            vertical: 12,
                          ),
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
                            horizontal: 16,
                            vertical: 12,
                          ),
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
                        'Provide tactile feedback when interacting with the app',
                      ),
                      value: _hapticsEnabled,
                      onChanged: (value) {
                        setState(() {
                          _hapticsEnabled = value;
                        });
                      },
                      contentPadding: EdgeInsets.zero,
                    ),

                    // Start pages collapsed setting
                    SwitchListTile(
                      title: Text(
                        'Collapse Algorithm Pages by Default',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      subtitle: const Text(
                        'When viewing an algorithm, all parameter pages will start collapsed',
                      ),
                      value: _startPagesCollapsed,
                      onChanged: (value) {
                        setState(() {
                          _startPagesCollapsed = value;
                        });
                      },
                      contentPadding: EdgeInsets.zero,
                    ),

                    const SizedBox(height: 24),

                    // Gallery URL setting
                    _SettingSection(
                      title: 'Gallery URL',
                      subtitle: 'URL for the plugin gallery JSON feed',
                      child: TextFormField(
                        controller: _galleryUrlController,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          hintText: 'https://...',
                        ),
                        keyboardType: TextInputType.url,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a URL';
                          }
                          final uri = Uri.tryParse(value.trim());
                          if (uri == null || !uri.hasScheme) {
                            return 'Please enter a valid URL';
                          }
                          return null;
                        },
                      ),
                    ),

                    // MCP enabled setting (desktop only)
                    if (Platform.isMacOS || Platform.isWindows)
                      SwitchListTile(
                        title: Text(
                          'Enable MCP Service',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        subtitle: const Text(
                          'Enable the MCP server for desktop integrations (Windows/MacOS only)',
                        ),
                        value: _mcpEnabled,
                        onChanged: (value) {
                          setState(() {
                            _mcpEnabled = value;
                          });
                        },
                        contentPadding: EdgeInsets.zero,
                      ),

                    // Debug panel visibility setting (debug mode only)
                    if (kDebugMode)
                      SwitchListTile(
                        title: Text(
                          'Show USB Video Debug Panel',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        subtitle: const Text(
                          'Display debug log panel for USB video operations (debug mode only)',
                        ),
                        value: _showDebugPanel,
                        onChanged: (value) {
                          setState(() {
                            _showDebugPanel = value;
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
                    Navigator.of(
                      context,
                    ).pop(false); // Return false to indicate cancel
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
        Text(title, style: Theme.of(context).textTheme.titleMedium),
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
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
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
          Icon(icon, color: Theme.of(context).colorScheme.secondary),
          const SizedBox(width: 16),
          Expanded(
            child: Text(title, style: Theme.of(context).textTheme.bodyLarge),
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
