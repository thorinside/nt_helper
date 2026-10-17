// Pinned Genkit session schema; isolate experimental serialization here.
// ignore: experimental_member_use
import 'package:genkit/experimental.dart' as g;
import 'package:nt_helper/chat/models/chat_message.dart';
import 'package:nt_helper/chat/models/llm_types.dart';
import 'package:nt_helper/chat/services/genkit_message_codec.dart';

class ConversationSummary {
  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int? messageCount;
  const ConversationSummary({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    this.messageCount,
  });
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    'message_count': messageCount,
  };
  factory ConversationSummary.fromJson(Map<String, dynamic> json) =>
      ConversationSummary(
        id: json['id'] as String,
        title: json['title'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
        messageCount: json['message_count'] as int?,
      );
}

/// A passive local checkpoint, not a task/run to resume. Provider credentials,
/// settings and cached system prompts are deliberately not part of this format.
class StoredConversation {
  final ConversationSummary summary;
  final List<ChatMessage> messages;
  final List<LlmMessage> history;
  final List<Map<String, dynamic>> references;
  final String promptCacheKey;
  final bool interrupted;
  final int inputTokens;
  final int outputTokens;
  final int contextTokens;
  final int contextWindow;
  StoredConversation({
    required this.summary,
    required List<ChatMessage> messages,
    required List<LlmMessage> history,
    required this.promptCacheKey,
    this.references = const [],
    this.interrupted = false,
    this.inputTokens = 0,
    this.outputTokens = 0,
    this.contextTokens = 0,
    this.contextWindow = 100000,
  }) : messages = List.unmodifiable(messages),
       history = List.unmodifiable(history);

  Map<String, dynamic> toJson() => {
    'version': 1,
    'summary': summary.toJson(),
    'messages': messages.map((m) => m.toJson()).toList(),
    'genkit_state': g.SessionState(
      messages: toGenkitMessages(history),
      artifacts: [],
    ).toJson(),
    'references': references,
    'prompt_cache_key': promptCacheKey,
    'interrupted': interrupted,
    'input_tokens': inputTokens,
    'output_tokens': outputTokens,
    'context_tokens': contextTokens,
    'context_window': contextWindow,
  };
  factory StoredConversation.fromJson(Map<String, dynamic> json) {
    if (json['version'] != 1) {
      throw const FormatException('Unsupported conversation format');
    }
    final state = g.SessionState.fromJson(
      Map<String, dynamic>.from(json['genkit_state'] as Map),
    );
    return StoredConversation(
      summary: ConversationSummary.fromJson(
        Map<String, dynamic>.from(json['summary'] as Map),
      ),
      messages: (json['messages'] as List)
          .map((m) => ChatMessage.fromJson(Map<String, dynamic>.from(m as Map)))
          .toList(),
      history: fromGenkitMessages(state.messages ?? const []),
      references: (json['references'] as List? ?? const [])
          .map((r) => Map<String, dynamic>.from(r as Map))
          .toList(),
      promptCacheKey: json['prompt_cache_key'] as String,
      interrupted: json['interrupted'] as bool? ?? false,
      inputTokens: json['input_tokens'] as int? ?? 0,
      outputTokens: json['output_tokens'] as int? ?? 0,
      contextTokens: json['context_tokens'] as int? ?? 0,
      contextWindow: json['context_window'] as int? ?? 100000,
    );
  }
}
