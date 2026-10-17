// Chat message types for the UI layer.
//
// These are distinct from LlmMessage — they represent what the user sees,
// including tool execution details and thinking indicators.

enum ChatMessageRole {
  user,
  assistant,
  toolCall,
  toolResult,
  thinking,
  system,
  compaction,
}

class ChatImageAttachment {
  final String data;
  final String mimeType;
  final String? name;

  const ChatImageAttachment({
    required this.data,
    required this.mimeType,
    this.name,
  });
  Map<String, dynamic> toJson() => {
    'data': data,
    'mime_type': mimeType,
    'name': name,
  };
  factory ChatImageAttachment.fromJson(Map<String, dynamic> json) =>
      ChatImageAttachment(
        data: json['data'] as String,
        mimeType: json['mime_type'] as String,
        name: json['name'] as String?,
      );
}

class ChatFileAttachment {
  final String name;
  final String data;
  final String mimeType;
  final int sizeBytes;
  final String? textContent;

  const ChatFileAttachment({
    required this.name,
    required this.data,
    required this.mimeType,
    required this.sizeBytes,
    this.textContent,
  });
  Map<String, dynamic> toJson() => {
    'name': name,
    'data': data,
    'mime_type': mimeType,
    'size_bytes': sizeBytes,
    'text_content': textContent,
  };
  factory ChatFileAttachment.fromJson(Map<String, dynamic> json) =>
      ChatFileAttachment(
        name: json['name'] as String,
        data: json['data'] as String,
        mimeType: json['mime_type'] as String,
        sizeBytes: json['size_bytes'] as int,
        textContent: json['text_content'] as String?,
      );
}

class ChatMessage {
  final String id;
  final ChatMessageRole role;
  final String content;
  final String? toolName;
  final String? toolCallId;
  final Map<String, dynamic>? toolArguments;
  final String? imageBase64;
  final String? imageMimeType;
  final List<ChatImageAttachment> imageAttachments;
  final List<ChatFileAttachment> fileAttachments;
  final DateTime timestamp;

  const ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    this.toolName,
    this.toolCallId,
    this.toolArguments,
    this.imageBase64,
    this.imageMimeType,
    this.imageAttachments = const [],
    this.fileAttachments = const [],
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'role': role.name,
    'content': content,
    'timestamp': timestamp.toIso8601String(),
    'tool_name': toolName,
    'tool_call_id': toolCallId,
    'tool_arguments': toolArguments,
    'image_base64': imageBase64,
    'image_mime_type': imageMimeType,
    'image_attachments': imageAttachments.map((a) => a.toJson()).toList(),
    'file_attachments': fileAttachments.map((a) => a.toJson()).toList(),
  };
  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    id: json['id'] as String,
    role: ChatMessageRole.values.byName(json['role'] as String),
    content: json['content'] as String,
    timestamp: DateTime.parse(json['timestamp'] as String),
    toolName: json['tool_name'] as String?,
    toolCallId: json['tool_call_id'] as String?,
    toolArguments: json['tool_arguments'] == null
        ? null
        : Map<String, dynamic>.from(json['tool_arguments'] as Map),
    imageBase64: json['image_base64'] as String?,
    imageMimeType: json['image_mime_type'] as String?,
    imageAttachments: (json['image_attachments'] as List? ?? const [])
        .map(
          (a) =>
              ChatImageAttachment.fromJson(Map<String, dynamic>.from(a as Map)),
        )
        .toList(),
    fileAttachments: (json['file_attachments'] as List? ?? const [])
        .map(
          (a) =>
              ChatFileAttachment.fromJson(Map<String, dynamic>.from(a as Map)),
        )
        .toList(),
  );

  ChatMessage withContent(String value) => ChatMessage(
    id: id,
    role: role,
    content: value,
    toolName: toolName,
    toolCallId: toolCallId,
    toolArguments: toolArguments,
    imageBase64: imageBase64,
    imageMimeType: imageMimeType,
    imageAttachments: imageAttachments,
    fileAttachments: fileAttachments,
    timestamp: timestamp,
  );

  bool get hasImage => imageBase64 != null && imageMimeType != null;
  bool get hasImageAttachments => imageAttachments.isNotEmpty;
  bool get hasFileAttachments => fileAttachments.isNotEmpty;

  factory ChatMessage.user(
    String content, {
    List<ChatImageAttachment> imageAttachments = const [],
    List<ChatFileAttachment> fileAttachments = const [],
  }) => ChatMessage(
    id: _generateId(),
    role: ChatMessageRole.user,
    content: content,
    imageAttachments: imageAttachments,
    fileAttachments: fileAttachments,
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
  }) => ChatMessage(
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
    String? imageBase64,
    String? imageMimeType,
  }) => ChatMessage(
    id: _generateId(),
    role: ChatMessageRole.toolResult,
    content: result,
    toolName: toolName,
    toolCallId: toolCallId,
    imageBase64: imageBase64,
    imageMimeType: imageMimeType,
    timestamp: DateTime.now(),
  );

  factory ChatMessage.thinking() => ChatMessage(
    id: _generateId(),
    role: ChatMessageRole.thinking,
    content: 'Working...',
    timestamp: DateTime.now(),
  );

  factory ChatMessage.system(String content) => ChatMessage(
    id: _generateId(),
    role: ChatMessageRole.system,
    content: content,
    timestamp: DateTime.now(),
  );

  factory ChatMessage.compaction() => ChatMessage(
    id: _generateId(),
    role: ChatMessageRole.compaction,
    content: 'Context compacted',
    timestamp: DateTime.now(),
  );

  static int _counter = 0;
  static String _generateId() =>
      'msg_${DateTime.now().millisecondsSinceEpoch}_${_counter++}';
}
