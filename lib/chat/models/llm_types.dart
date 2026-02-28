// Types for LLM provider abstraction.
//
// These types are provider-neutral — both Anthropic and OpenAI providers
// convert to/from these types.

enum LlmRole { user, assistant, tool }

/// A message in the LLM conversation.
class LlmMessage {
  final LlmRole role;
  final String? content;
  final List<LlmToolCall>? toolCalls;
  final String? toolCallId;
  final String? toolName;

  const LlmMessage({
    required this.role,
    this.content,
    this.toolCalls,
    this.toolCallId,
    this.toolName,
  });

  factory LlmMessage.user(String content) =>
      LlmMessage(role: LlmRole.user, content: content);

  factory LlmMessage.assistant(String content) =>
      LlmMessage(role: LlmRole.assistant, content: content);

  factory LlmMessage.assistantWithToolCalls(List<LlmToolCall> toolCalls,
          {String? content}) =>
      LlmMessage(
          role: LlmRole.assistant, content: content, toolCalls: toolCalls);

  factory LlmMessage.toolResult({
    required String toolCallId,
    required String toolName,
    required String content,
  }) =>
      LlmMessage(
        role: LlmRole.tool,
        content: content,
        toolCallId: toolCallId,
        toolName: toolName,
      );
}

/// A tool call requested by the LLM.
class LlmToolCall {
  final String id;
  final String name;
  final Map<String, dynamic> arguments;

  const LlmToolCall({
    required this.id,
    required this.name,
    required this.arguments,
  });
}

/// A tool definition sent to the LLM.
class LlmToolDefinition {
  final String name;
  final String description;
  final Map<String, dynamic> inputSchema;

  const LlmToolDefinition({
    required this.name,
    required this.description,
    required this.inputSchema,
  });
}

/// Response from an LLM provider.
class LlmResponse {
  final String? content;
  final List<LlmToolCall> toolCalls;
  final bool isComplete;
  final LlmUsage? usage;

  const LlmResponse({
    this.content,
    this.toolCalls = const [],
    required this.isComplete,
    this.usage,
  });

  bool get hasToolCalls => toolCalls.isNotEmpty;
}

/// Token usage information.
class LlmUsage {
  final int inputTokens;
  final int outputTokens;

  const LlmUsage({required this.inputTokens, required this.outputTokens});

  int get totalTokens => inputTokens + outputTokens;
}
