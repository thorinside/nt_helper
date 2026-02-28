// Chat configuration models.

enum LlmProviderType { anthropic, openai }

enum VoiceInputMethod { platform, whisper, elevenlabs }

class ChatSettings {
  final LlmProviderType provider;
  final String? anthropicApiKey;
  final String? openaiApiKey;
  final String anthropicModel;
  final String openaiModel;
  final String? openaiBaseUrl;
  final bool chatEnabled;
  final VoiceInputMethod voiceInputMethod;
  final String? elevenlabsApiKey;

  const ChatSettings({
    this.provider = LlmProviderType.anthropic,
    this.anthropicApiKey,
    this.openaiApiKey,
    this.anthropicModel = 'claude-haiku-4-5-20251001',
    this.openaiModel = 'gpt-5-nano',
    this.openaiBaseUrl,
    this.chatEnabled = false,
    this.voiceInputMethod = VoiceInputMethod.platform,
    this.elevenlabsApiKey,
  });

  bool get hasApiKey {
    switch (provider) {
      case LlmProviderType.anthropic:
        return anthropicApiKey != null && anthropicApiKey!.isNotEmpty;
      case LlmProviderType.openai:
        return openaiApiKey != null && openaiApiKey!.isNotEmpty;
    }
  }

  ChatSettings copyWith({
    LlmProviderType? provider,
    String? anthropicApiKey,
    String? openaiApiKey,
    String? anthropicModel,
    String? openaiModel,
    String? openaiBaseUrl,
    bool? chatEnabled,
    VoiceInputMethod? voiceInputMethod,
    String? elevenlabsApiKey,
  }) {
    return ChatSettings(
      provider: provider ?? this.provider,
      anthropicApiKey: anthropicApiKey ?? this.anthropicApiKey,
      openaiApiKey: openaiApiKey ?? this.openaiApiKey,
      anthropicModel: anthropicModel ?? this.anthropicModel,
      openaiModel: openaiModel ?? this.openaiModel,
      openaiBaseUrl: openaiBaseUrl ?? this.openaiBaseUrl,
      chatEnabled: chatEnabled ?? this.chatEnabled,
      voiceInputMethod: voiceInputMethod ?? this.voiceInputMethod,
      elevenlabsApiKey: elevenlabsApiKey ?? this.elevenlabsApiKey,
    );
  }
}
