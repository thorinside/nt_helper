import 'package:http/http.dart' as http;
import 'package:nt_helper/chat/models/chat_settings.dart';
import 'package:nt_helper/chat/providers/anthropic_provider.dart';
import 'package:nt_helper/chat/providers/anthropic_subscription_provider.dart';
import 'package:nt_helper/chat/providers/llm_provider.dart';
import 'package:nt_helper/chat/providers/openai_endpoint.dart';
import 'package:nt_helper/chat/providers/openai_provider.dart';
import 'package:nt_helper/chat/providers/openai_subscription_provider.dart';

/// Authentication is explicit per provider. Genkit owns the common agent loop;
/// these transports retain their own wire/authentication contracts.
LlmProvider createChatProvider(
  ChatSettings settings, {
  required String promptCacheKey,
  http.Client? client,
}) {
  switch (settings.provider) {
    case LlmProviderType.anthropic:
      return AnthropicProvider(
        apiKey: settings.anthropicApiKey!,
        model: settings.anthropicModel,
        client: client,
      );
    case LlmProviderType.anthropicSubscription:
      return AnthropicSubscriptionProvider(
        token: settings.anthropicApiKey!,
        model: settings.anthropicModel,
        client: client,
      );
    case LlmProviderType.openai:
      return OpenAIProvider(
        apiKey: settings.openaiApiKey!,
        model: settings.openaiModel,
        baseUrl: settings.openaiBaseUrl,
        promptCacheKey: promptCacheKey,
        client: client,
      );
    case LlmProviderType.openaiSubscription:
      return OpenAISubscriptionProvider(
        model: settings.openaiSubscriptionModel,
        allowAuthRefresh: settings.allowCodexAuthRefresh,
        promptCacheKey: promptCacheKey,
        client: client,
      );
    case LlmProviderType.gemini:
    case LlmProviderType.openrouter:
    case LlmProviderType.local:
      final type = settings.provider;
      final config = settings.configFor(type);
      final endpoint = switch (type) {
        LlmProviderType.gemini => geminiChatUrl,
        LlmProviderType.openrouter => openRouterChatUrl,
        _ => chatCompletionsUri(
          config.baseUrl.trim().isEmpty ? defaultLocalBaseUrl : config.baseUrl,
        ).toString(),
      };
      return OpenAIProvider(
        apiKey: config.apiKey,
        model: config.model.trim(),
        baseUrl: endpoint,
        providerLabel: type.label,
        client: client,
        requestOptions: type == LlmProviderType.openrouter
            ? const {
                'provider': {'require_parameters': true},
              }
            : const {},
        contextWindowTokens:
            config.contextWindowTokens ??
            (type == LlmProviderType.local ? 8192 : 32768),
      );
  }
}
