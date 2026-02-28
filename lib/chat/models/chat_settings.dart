// Chat configuration models.

enum LlmProviderType { anthropic, openai }

enum VoiceInputMethod { platform, whisper, elevenlabs }

class ChatSettings {
  final LlmProviderType provider;
  final String? anthropicApiKey;
  final String? openaiApiKey;
  final String anthropicModel;
  final String openaiModel;
  final bool chatEnabled;
  final VoiceInputMethod voiceInputMethod;
  final String? elevenlabsApiKey;

  const ChatSettings({
    this.provider = LlmProviderType.anthropic,
    this.anthropicApiKey,
    this.openaiApiKey,
    this.anthropicModel = 'claude-sonnet-4-20250514',
    this.openaiModel = 'gpt-4o',
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
      chatEnabled: chatEnabled ?? this.chatEnabled,
      voiceInputMethod: voiceInputMethod ?? this.voiceInputMethod,
      elevenlabsApiKey: elevenlabsApiKey ?? this.elevenlabsApiKey,
    );
  }
}
