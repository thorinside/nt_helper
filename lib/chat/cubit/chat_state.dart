import 'package:equatable/equatable.dart';
import 'package:nt_helper/chat/models/chat_message.dart';

class ChatContextSummary extends Equatable {
  final int messageCount;
  final int userMessages;
  final int assistantMessages;
  final int toolCalls;
  final int toolResults;
  final int imageAttachments;
  final int fileAttachments;
  final int approxCharacters;

  const ChatContextSummary({
    this.messageCount = 0,
    this.userMessages = 0,
    this.assistantMessages = 0,
    this.toolCalls = 0,
    this.toolResults = 0,
    this.imageAttachments = 0,
    this.fileAttachments = 0,
    this.approxCharacters = 0,
  });

  bool get isEmpty => messageCount == 0;

  @override
  List<Object?> get props => [
    messageCount,
    userMessages,
    assistantMessages,
    toolCalls,
    toolResults,
    imageAttachments,
    fileAttachments,
    approxCharacters,
  ];
}

sealed class ChatState extends Equatable {
  const ChatState();

  @override
  List<Object?> get props => [];
}

class ChatInitial extends ChatState {
  const ChatInitial();
}

class ChatReady extends ChatState {
  final List<ChatMessage> messages;
  final bool isProcessing;
  final String? currentToolName;
  final int totalInputTokens;
  final int totalOutputTokens;
  final int contextInputTokens;
  final int contextWindowTokens;

  const ChatReady({
    this.messages = const [],
    this.isProcessing = false,
    this.currentToolName,
    this.totalInputTokens = 0,
    this.totalOutputTokens = 0,
    this.contextInputTokens = 0,
    this.contextWindowTokens = 100000,
  });

  ChatReady copyWith({
    List<ChatMessage>? messages,
    bool? isProcessing,
    String? currentToolName,
    bool clearToolName = false,
    int? totalInputTokens,
    int? totalOutputTokens,
    int? contextInputTokens,
    int? contextWindowTokens,
  }) {
    return ChatReady(
      messages: messages ?? this.messages,
      isProcessing: isProcessing ?? this.isProcessing,
      currentToolName: clearToolName
          ? null
          : (currentToolName ?? this.currentToolName),
      totalInputTokens: totalInputTokens ?? this.totalInputTokens,
      totalOutputTokens: totalOutputTokens ?? this.totalOutputTokens,
      contextInputTokens: contextInputTokens ?? this.contextInputTokens,
      contextWindowTokens: contextWindowTokens ?? this.contextWindowTokens,
    );
  }

  @override
  List<Object?> get props => [
    messages,
    isProcessing,
    currentToolName,
    totalInputTokens,
    totalOutputTokens,
    contextInputTokens,
    contextWindowTokens,
  ];
}

class ChatError extends ChatState {
  final String message;

  const ChatError(this.message);

  @override
  List<Object?> get props => [message];
}
