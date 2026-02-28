// Chat message types for the UI layer.
//
// These are distinct from LlmMessage — they represent what the user sees,
// including tool execution details and thinking indicators.

enum ChatMessageRole { user, assistant, toolCall, toolResult, thinking }

class ChatMessage {
  final String id;
  final ChatMessageRole role;
  final String content;
  final String? toolName;
  final String? toolCallId;
  final Map<String, dynamic>? toolArguments;
  final DateTime timestamp;

  const ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    this.toolName,
    this.toolCallId,
    this.toolArguments,
    required this.timestamp,
  });

  factory ChatMessage.user(String content) => ChatMessage(
        id: _generateId(),
        role: ChatMessageRole.user,
        content: content,
        timestamp: DateTime.now(),
      );

  factory ChatMessage.assistant(String content) => ChatMessage(
        id: _generateId(),
        role: ChatMessageRole.assistant,
        content: content,
        timestamp: DateTime.now(),
      );

  factory ChatMessage.toolCall({
    required String toolName,
    required String toolCallId,
    required Map<String, dynamic> arguments,
  }) =>
      ChatMessage(
        id: _generateId(),
        role: ChatMessageRole.toolCall,
        content: 'Calling $toolName...',
        toolName: toolName,
        toolCallId: toolCallId,
        toolArguments: arguments,
        timestamp: DateTime.now(),
      );

  factory ChatMessage.toolResult({
    required String toolName,
    required String toolCallId,
    required String result,
  }) =>
      ChatMessage(
        id: _generateId(),
        role: ChatMessageRole.toolResult,
        content: result,
        toolName: toolName,
        toolCallId: toolCallId,
        timestamp: DateTime.now(),
      );

  factory ChatMessage.thinking() => ChatMessage(
        id: _generateId(),
        role: ChatMessageRole.thinking,
        content: 'Thinking...',
        timestamp: DateTime.now(),
      );

  static int _counter = 0;
  static String _generateId() => 'msg_${DateTime.now().millisecondsSinceEpoch}_${_counter++}';
}
