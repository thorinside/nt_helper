import 'package:nt_helper/chat/models/llm_types.dart';

/// Returns a provider-safe copy containing only complete, adjacent tool groups.
///
/// A cancelled or partially restored conversation can contain a tool result
/// without its assistant call, or a call whose result was never recorded.
/// OpenAI-compatible providers reject orphan IDs, and retaining an incomplete
/// group is unsafe for Anthropic as well. Ordinary text remains intact while
/// unmatched calls/results are omitted from the request history.
List<LlmMessage> providerSafeToolHistory(List<LlmMessage> messages) {
  final safe = <LlmMessage>[];

  for (var index = 0; index < messages.length; index++) {
    final message = messages[index];
    if (message.role == LlmRole.tool) continue;

    final calls = message.role == LlmRole.assistant
        ? message.toolCalls ?? const <LlmToolCall>[]
        : const <LlmToolCall>[];
    if (calls.isEmpty) {
      safe.add(message);
      continue;
    }

    final callIds = calls.map((call) => call.id).toSet();
    final results = <LlmMessage>[];
    var nextIndex = index + 1;
    while (nextIndex < messages.length &&
        messages[nextIndex].role == LlmRole.tool) {
      results.add(messages[nextIndex]);
      nextIndex++;
    }

    final matchedIds = results
        .map((result) => result.toolCallId)
        .whereType<String>()
        .where(callIds.contains)
        .toSet();
    final matchedCalls = calls
        .where((call) => matchedIds.contains(call.id))
        .toList(growable: false);

    if (matchedCalls.isNotEmpty || (message.content?.isNotEmpty ?? false)) {
      safe.add(
        LlmMessage(
          role: LlmRole.assistant,
          content: message.content,
          providerMetadata: message.providerMetadata,
          toolCalls: matchedCalls.isEmpty ? null : matchedCalls,
        ),
      );
    }

    final emittedIds = <String>{};
    for (final result in results) {
      final id = result.toolCallId;
      if (id != null && matchedIds.contains(id) && emittedIds.add(id)) {
        safe.add(result);
      }
    }
    index = nextIndex - 1;
  }

  return safe;
}
