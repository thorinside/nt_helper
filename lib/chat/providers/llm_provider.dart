import 'package:nt_helper/chat/models/llm_types.dart';

/// Abstract LLM provider interface.
///
/// Implementations handle the specifics of each API (Anthropic, OpenAI)
/// while exposing a uniform interface for the chat service.
abstract class LlmProvider {
  /// Send messages to the LLM and get a response.
  ///
  /// [messages] is the full conversation history.
  /// [tools] is the list of available tools the LLM can call.
  /// [systemPrompt] is an optional system message prepended to the conversation.
  Future<LlmResponse> sendMessages({
    required List<LlmMessage> messages,
    required List<LlmToolDefinition> tools,
    String? systemPrompt,
  });

  /// The provider name for display purposes.
  String get displayName;

  /// Release HTTP client resources.
  void dispose();
}
