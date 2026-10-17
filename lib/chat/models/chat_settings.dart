// Chat configuration models.
import 'package:nt_helper/chat/models/additional_provider_config.dart';

enum LlmProviderType {
  anthropic,
  anthropicSubscription,
  openai,
  openaiSubscription,
  gemini,
  openrouter,
  local;

  bool get isAdditional =>
      this == gemini || this == openrouter || this == local;
  String get label => switch (this) {
    anthropic => 'Anthropic',
    anthropicSubscription => 'Claude subscription',
    openai => 'OpenAI',
    openaiSubscription => 'ChatGPT / Codex',
    gemini => 'Google Gemini',
    openrouter => 'OpenRouter',
    local => 'Local / OpenAI-compatible',
  };
}

enum VoiceInputMethod { platform, whisper, elevenlabs }

class ChatSettings {
  final LlmProviderType provider;
  final String? anthropicApiKey;
  final String? openaiApiKey;
  final String anthropicModel;
  final String openaiModel;
  final String openaiSubscriptionModel;
  final String? openaiBaseUrl;
  final bool allowCodexAuthRefresh;
  final bool chatEnabled;
  final VoiceInputMethod voiceInputMethod;
  final String? elevenlabsApiKey;
  final Map<LlmProviderType, AdditionalProviderConfig> additionalProviders;
  AdditionalProviderConfig configFor(LlmProviderType type) =>
      additionalProviders[type] ?? const AdditionalProviderConfig();

  const ChatSettings({
    this.provider = LlmProviderType.anthropic,
    this.anthropicApiKey,
    this.openaiApiKey,
    this.anthropicModel = 'claude-haiku-4-5-20251001',
    this.openaiModel = 'gpt-5-nano',
    this.openaiSubscriptionModel = 'gpt-5.4-mini',
    this.openaiBaseUrl,
    this.allowCodexAuthRefresh = false,
    this.chatEnabled = false,
    this.voiceInputMethod = VoiceInputMethod.platform,
    this.elevenlabsApiKey,
    this.additionalProviders = const {},
  });

  bool get hasApiKey {
    switch (provider) {
      case LlmProviderType.anthropic:
      case LlmProviderType.anthropicSubscription:
        return anthropicApiKey != null && anthropicApiKey!.trim().isNotEmpty;
      case LlmProviderType.openai:
        return openaiApiKey != null && openaiApiKey!.trim().isNotEmpty;
      case LlmProviderType.openaiSubscription:
        return true;
      case LlmProviderType.gemini:
      case LlmProviderType.openrouter:
        final config = configFor(provider);
        return config.apiKey.trim().isNotEmpty &&
            config.model.trim().isNotEmpty;
      case LlmProviderType.local:
        return configFor(provider).model.trim().isNotEmpty;
    }
  }

  ChatSettings copyWith({
    LlmProviderType? provider,
    String? anthropicApiKey,
    String? openaiApiKey,
    String? anthropicModel,
    String? openaiModel,
    String? openaiSubscriptionModel,
    String? openaiBaseUrl,
    bool? allowCodexAuthRefresh,
    bool? chatEnabled,
    VoiceInputMethod? voiceInputMethod,
    String? elevenlabsApiKey,
    Map<LlmProviderType, AdditionalProviderConfig>? additionalProviders,
  }) {
    return ChatSettings(
      provider: provider ?? this.provider,
      anthropicApiKey: anthropicApiKey ?? this.anthropicApiKey,
      openaiApiKey: openaiApiKey ?? this.openaiApiKey,
      anthropicModel: anthropicModel ?? this.anthropicModel,
      openaiModel: openaiModel ?? this.openaiModel,
      openaiSubscriptionModel:
          openaiSubscriptionModel ?? this.openaiSubscriptionModel,
      openaiBaseUrl: openaiBaseUrl ?? this.openaiBaseUrl,
      allowCodexAuthRefresh:
          allowCodexAuthRefresh ?? this.allowCodexAuthRefresh,
      chatEnabled: chatEnabled ?? this.chatEnabled,
      voiceInputMethod: voiceInputMethod ?? this.voiceInputMethod,
      elevenlabsApiKey: elevenlabsApiKey ?? this.elevenlabsApiKey,
      additionalProviders: additionalProviders ?? this.additionalProviders,
    );
  }
}
