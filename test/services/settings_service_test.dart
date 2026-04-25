import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/chat/models/chat_settings.dart';
import 'package:nt_helper/services/settings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Non-default seed values keyed by storage-key string. Each value is chosen
/// to differ from the corresponding declared default, so that asserting "the
/// getter returns the default after reset" actually proves a state change.
const Map<String, Object> _nonDefaultSeeds = {
  'request_timeout_ms': 12345,
  'inter_message_delay_ms': 999,
  'haptics_enabled': false,
  'mcp_enabled': true,
  'start_pages_collapsed': true,
  'gallery_url': 'https://example.invalid/gallery.json',
  'graphql_endpoint': 'https://example.invalid/graphql',
  'include_community_plugins_in_presets': false,
  'overlay_position_x': 42.0,
  'overlay_position_y': 99.0,
  'overlay_size_scale': 2.5,
  'show_debug_panel': false,
  'show_contextual_help': false,
  'algorithm_cache_days': 17,
  'cpu_monitor_enabled': false,
  'dismissed_update_version': '99.99.99',
  'last_update_check_timestamp': 1700000000000,
  'split_divider_position': 0.123,
  'mcp_remote_connections': true,
  'chat_enabled': true,
  'chat_panel_width': 777.0,
  'chat_llm_provider': 'openai',
  'anthropic_api_key': 'sk-fake-anthropic',
  'openai_api_key': 'sk-fake-openai',
  'anthropic_model': 'fake-anthropic-model',
  'openai_model': 'fake-openai-model',
  'openai_base_url': 'https://example.invalid/v1',
  'ui_scale': 1.4,
  'auto_center_on_selection': false,
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SettingsService.resetToDefaults', () {
    late SettingsService settings;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      settings = SettingsService();
      await settings.init();
    });

    test(
      'every persisted key has a non-default seed in the test fixture',
      () {
        for (final key in SettingsService.debugPersistedKeys) {
          expect(
            _nonDefaultSeeds.containsKey(key),
            isTrue,
            reason:
                'Persisted key "$key" has no entry in _nonDefaultSeeds. Add a '
                'non-default value for it so the exhaustive-reset test '
                'actually exercises this key.',
          );
        }
      },
    );

    test(
      'after reset, every persisted key returns its declared default',
      () async {
        SharedPreferences.setMockInitialValues(_nonDefaultSeeds);
        await settings.init();

        for (final key in SettingsService.debugPersistedKeys) {
          expect(
            _nonDefaultSeeds.containsKey(key),
            isTrue,
            reason: 'seed missing for $key',
          );
        }
        expect(settings.requestTimeout, isNot(SettingsService.defaultRequestTimeout));
        expect(settings.cpuMonitorEnabled, isNot(SettingsService.defaultCpuMonitorEnabled));
        expect(settings.chatEnabled, isNot(SettingsService.defaultChatEnabled));
        expect(settings.dismissedUpdateVersion, isNotNull);
        expect(settings.lastUpdateCheckTimestamp, isNotNull);
        expect(settings.anthropicApiKey, isNotNull);
        expect(settings.openaiApiKey, isNotNull);
        expect(settings.openaiBaseUrl, isNotNull);

        await settings.resetToDefaults();

        expect(settings.requestTimeout, SettingsService.defaultRequestTimeout);
        expect(settings.interMessageDelay, SettingsService.defaultInterMessageDelay);
        expect(settings.hapticsEnabled, SettingsService.defaultHapticsEnabled);
        expect(settings.mcpEnabled, SettingsService.defaultMcpEnabled);
        expect(settings.mcpRemoteConnections, SettingsService.defaultMcpRemoteConnections);
        expect(settings.startPagesCollapsed, SettingsService.defaultStartPagesCollapsed);
        expect(settings.galleryUrl, SettingsService.defaultGalleryUrl);
        expect(settings.graphqlEndpoint, SettingsService.defaultGraphqlEndpoint);
        expect(settings.includeCommunityPlugins, SettingsService.defaultIncludeCommunityPlugins);
        expect(settings.overlayPositionX, SettingsService.defaultOverlayPositionX);
        expect(settings.overlayPositionY, SettingsService.defaultOverlayPositionY);
        expect(settings.overlaySizeScale, SettingsService.defaultOverlaySizeScale);
        expect(settings.showDebugPanel, SettingsService.defaultShowDebugPanel);
        expect(settings.showContextualHelp, SettingsService.defaultShowContextualHelp);
        expect(settings.algorithmCacheDays, SettingsService.defaultAlgorithmCacheDays);
        expect(settings.cpuMonitorEnabled, SettingsService.defaultCpuMonitorEnabled);
        expect(settings.splitDividerPosition, SettingsService.defaultSplitDividerPosition);
        expect(settings.chatEnabled, SettingsService.defaultChatEnabled);
        expect(settings.chatPanelWidth, SettingsService.defaultChatPanelWidth);
        expect(settings.chatLlmProvider, LlmProviderType.anthropic);
        expect(settings.anthropicApiKey, isNull);
        expect(settings.openaiApiKey, isNull);
        expect(settings.anthropicModel, SettingsService.defaultAnthropicModel);
        expect(settings.openaiModel, SettingsService.defaultOpenaiModel);
        expect(settings.openaiBaseUrl, isNull);
        expect(settings.dismissedUpdateVersion, isNull);
        expect(settings.lastUpdateCheckTimestamp, isNull);
        expect(settings.uiScale, SettingsService.defaultUiScale);
        expect(settings.autoCenterOnSelection, SettingsService.defaultAutoCenterOnSelection);

        final prefs = await SharedPreferences.getInstance();
        final leftoverOwnedKeys = prefs.getKeys().toSet().intersection(
              SettingsService.debugPersistedKeys.toSet(),
            );
        expect(
          leftoverOwnedKeys,
          isEmpty,
          reason:
              'resetToDefaults left behind owned keys in storage: $leftoverOwnedKeys',
        );
      },
    );

    test('resetToDefaults resyncs ValueNotifiers backed by removed keys',
        () async {
      SharedPreferences.setMockInitialValues({
        'cpu_monitor_enabled': false,
        'ui_scale': 1.4,
      });
      await settings.init();
      expect(settings.cpuMonitorEnabledNotifier.value, isFalse);
      expect(settings.uiScaleNotifier.value, closeTo(1.4, 1e-9));

      await settings.resetToDefaults();

      expect(settings.cpuMonitorEnabledNotifier.value,
          SettingsService.defaultCpuMonitorEnabled);
      expect(settings.uiScaleNotifier.value, SettingsService.defaultUiScale);
    });
  });

  group('SettingsService key registry', () {
    test(
      'every _xxxKey constant in settings_service.dart is in '
      '_persistedKeys (and vice-versa)',
      () {
        final source = File('lib/services/settings_service.dart')
            .readAsStringSync();

        final keyConstantPattern = RegExp(
          r"static\s+const\s+String\s+_\w+Key\s*=\s*'([^']+)'\s*;",
        );

        final declaredKeys = keyConstantPattern
            .allMatches(source)
            .map((m) => m.group(1)!)
            .toSet();

        expect(
          declaredKeys,
          isNotEmpty,
          reason:
              'Source-scan regex found no `static const String _xxxKey` '
              'declarations — the regex is broken or the file path is wrong.',
        );

        final registered = SettingsService.debugPersistedKeys.toSet();

        final missingFromRegistry = declaredKeys.difference(registered);
        final extraInRegistry = registered.difference(declaredKeys);

        expect(
          missingFromRegistry,
          isEmpty,
          reason:
              'These persisted setting keys are declared in '
              'lib/services/settings_service.dart but are NOT in '
              '_persistedKeys: $missingFromRegistry. Add them to the '
              '_persistedKeys list so resetToDefaults() covers them. '
              '(If you added a new persisted setting and forgot to update '
              'the registry, this is the test that caught it.)',
        );

        expect(
          extraInRegistry,
          isEmpty,
          reason:
              '_persistedKeys contains keys that are NOT declared as '
              '`static const String _xxxKey` in settings_service.dart: '
              '$extraInRegistry. Either remove them from the registry or '
              'restore the missing constants.',
        );
      },
    );
  });
}
